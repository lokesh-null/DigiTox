import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/heatmap_grid.dart';
import '../widgets/dopamine_gauge.dart';
import '../data/data_provider.dart';
import '../data/behavioral_engine.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  List<DayUsageData> weeklyData = [];
  List<HeatmapEntry> heatmapData = [];
  List<Map<String, String>> suggestions = [];
  Map<String, String> grade = {'grade': '—', 'title': 'Loading...', 'desc': ''};
  int totalProductive = 0;
  int totalAddictive = 0;
  int totalNeutral = 0;
  bool _loading = true;

  // Behavioral Intelligence
  DopamineDebtResult? _dopamineDebt;
  AttentionPortfolioResult? _portfolio;
  RegretForecastResult? _regretForecast;
  TriggerDetectionResult? _triggers;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      weeklyData = await DataProvider().getWeeklyData();
      heatmapData = await DataProvider().getHeatmapData();
      suggestions = await DataProvider().getAISuggestions();
      grade = await DataProvider().getWeeklyGrade();

      totalProductive = weeklyData.fold(0, (s, d) => s + d.productive);
      totalAddictive = weeklyData.fold(0, (s, d) => s + d.addictive);
      totalNeutral = weeklyData.fold(0, (s, d) => s + d.neutral);

      // Behavioral features
      _dopamineDebt = await BehavioralEngine().computeDopamineDebt();
      _portfolio = await BehavioralEngine().computeAttentionPortfolio();
      _regretForecast = await BehavioralEngine().computeRegretForecast();
      _triggers = await BehavioralEngine().computeTriggerDetection();
    } catch (e) {
      // Use defaults
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Insights', style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 4),
          const Text('AI-powered behavior analysis', style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: AppTheme.spaceLg),

          // Grade Card
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceLg),
            decoration: BoxDecoration(
              gradient: AppTheme.gradientMixed,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: Row(
              children: [
                Text(grade['grade']!, style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(width: AppTheme.spaceLg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(grade['title']!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(grade['desc']!, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13)),
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spaceLg),

          // ═══════════════════════════════════════
          // FEATURE 1: Dopamine Debt Score Breakdown
          // ═══════════════════════════════════════
          if (_dopamineDebt != null) ...[
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('🧠', 'Dopamine Debt Analysis'),
                  DopamineGauge(
                    score: _dopamineDebt!.score,
                    severity: _dopamineDebt!.severity,
                    label: _dopamineDebt!.label,
                  ),
                  const SizedBox(height: AppTheme.spaceMd),
                  // All factor breakdown
                  const Text('Score Breakdown', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ..._dopamineDebt!.factors.map((factor) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: factor.startsWith('-') ? AppTheme.secondary : AppTheme.danger,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(factor, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        ),
                      ],
                    ),
                  )),
                  if (_dopamineDebt!.factors.isEmpty)
                    const Text('No activity tracked yet today', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(height: AppTheme.spaceMd),
                  // Quick stats row
                  Row(
                    children: [
                      _buildDebtStatChip('📱', '${_dopamineDebt!.addictiveMinutes}m', 'Addictive'),
                      const SizedBox(width: 8),
                      _buildDebtStatChip('🔀', '${_dopamineDebt!.rapidSwitches}', 'Rapid switches'),
                      const SizedBox(width: 8),
                      _buildDebtStatChip('🎯', '${_dopamineDebt!.completedSessions}', 'Focus sessions'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spaceLg),
          ],

          // Weekly Chart
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('📊', 'Weekly Usage'),
                SizedBox(
                  height: 200,
                  child: weeklyData.isEmpty
                    ? const Center(child: Text('No data yet', style: TextStyle(color: AppTheme.textSecondary)))
                    : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _getMaxY(),
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= weeklyData.length) return const SizedBox();
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(weeklyData[value.toInt()].day, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) => Text('${(value / 60).round()}h', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
                          ),
                        ),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 120,
                        getDrawingHorizontalLine: (value) => FlLine(color: Colors.white.withValues(alpha: 0.04), strokeWidth: 1),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: weeklyData.asMap().entries.map((e) {
                        int index = e.key;
                        var d = e.value;
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: (d.productive + d.addictive + d.neutral).toDouble(),
                              rodStackItems: [
                                BarChartRodStackItem(0, d.productive.toDouble(), const Color(0xB300CEC9)),
                                BarChartRodStackItem(d.productive.toDouble(), (d.productive + d.addictive).toDouble(), const Color(0xB3FF6B6B)),
                                BarChartRodStackItem((d.productive + d.addictive).toDouble(), (d.productive + d.addictive + d.neutral).toDouble(), const Color(0x80FDCB6E)),
                              ],
                              borderRadius: BorderRadius.circular(4),
                              width: 16,
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spaceLg),

          // Donut Chart
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('🍩', 'Time Wasted vs Invested'),
                SizedBox(
                  height: 160,
                  child: (totalProductive + totalAddictive + totalNeutral) == 0
                    ? const Center(child: Text('No data yet', style: TextStyle(color: AppTheme.textSecondary)))
                    : Row(
                    children: [
                      Expanded(
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 0,
                            centerSpaceRadius: 40,
                            sections: [
                              PieChartSectionData(value: totalProductive.toDouble(), color: const Color(0xCC00CEC9), showTitle: false, radius: 25),
                              PieChartSectionData(value: totalAddictive.toDouble(), color: const Color(0xCCFF6B6B), showTitle: false, radius: 25),
                              PieChartSectionData(value: totalNeutral.toDouble(), color: const Color(0x99FDCB6E), showTitle: false, radius: 25),
                            ],
                          ),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLegendItem(AppTheme.secondary, '${(totalProductive/60).round()}h', 'Productive'),
                          const SizedBox(height: 8),
                          _buildLegendItem(AppTheme.danger, '${(totalAddictive/60).round()}h', 'Addictive'),
                          const SizedBox(height: 8),
                          _buildLegendItem(AppTheme.warning, '${(totalNeutral/60).round()}h', 'Neutral'),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spaceLg),

          // ═══════════════════════════════════════
          // FEATURE 10: Attention Investment Portfolio
          // ═══════════════════════════════════════
          if (_portfolio != null) ...[
            _buildAttentionPortfolio(),
            const SizedBox(height: AppTheme.spaceLg),
          ],

          // ═══════════════════════════════════════
          // FEATURE 3: Regret Forecast Engine
          // ═══════════════════════════════════════
          if (_regretForecast != null && _regretForecast!.forecasts.isNotEmpty) ...[
            _buildRegretForecast(),
            const SizedBox(height: AppTheme.spaceLg),
          ],

          // ═══════════════════════════════════════
          // FEATURE 5: AI Trigger Detection
          // ═══════════════════════════════════════
          if (_triggers != null && _triggers!.triggers.isNotEmpty) ...[
            _buildTriggerDetection(),
            const SizedBox(height: AppTheme.spaceLg),
          ],

          // Heatmap
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('🔥', 'Peak Distraction Hours'),
                HeatmapGrid(data: heatmapData),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spaceLg),

          // Suggestions
          _buildSectionTitle('🤖', 'AI Recommendations'),
          ...suggestions.map((s) => Container(
            margin: const EdgeInsets.only(bottom: AppTheme.spaceSm),
            padding: const EdgeInsets.all(AppTheme.spaceMd),
            decoration: BoxDecoration(
              color: AppTheme.surfaceHover,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s['icon']!, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(child: Text(s['text']!, style: const TextStyle(fontSize: 13, height: 1.4))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // FEATURE 10: Attention Portfolio Widget
  // ═══════════════════════════════════════
  Widget _buildAttentionPortfolio() {
    final p = _portfolio!;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('💹', 'Attention Investment Portfolio'),

          // Portfolio grade
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceMd),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _gradeColor(p.grade).withValues(alpha: 0.15),
                  _gradeColor(p.grade).withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: _gradeColor(p.grade).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Text(p.grade, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _gradeColor(p.grade))),
                const SizedBox(width: AppTheme.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Portfolio Grade', style: TextStyle(color: _gradeColor(p.grade), fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(p.advice, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spaceLg),

          // Invested vs Spent bar
          Row(
            children: [
              _buildPortfolioStat('Invested', p.totalInvested, AppTheme.secondary),
              const SizedBox(width: AppTheme.spaceSm),
              _buildPortfolioStat('Spent', p.totalSpent, AppTheme.danger),
              const SizedBox(width: AppTheme.spaceSm),
              _buildPortfolioStat('Neutral', p.totalNeutral, AppTheme.warning),
            ],
          ),
          const SizedBox(height: AppTheme.spaceLg),

          // Investment ratio bar
          Container(
            height: 8,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Colors.white.withValues(alpha: 0.05),
            ),
            child: Row(
              children: [
                if (p.total > 0) ...[
                  Flexible(
                    flex: p.totalInvested.clamp(1, 9999),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.secondary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Flexible(
                    flex: p.totalNeutral.clamp(1, 9999),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppTheme.warning,
                      ),
                    ),
                  ),
                  Flexible(
                    flex: p.totalSpent.clamp(1, 9999),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.danger,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spaceLg),

          // Holdings list (top 5)
          const Text('Holdings', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...p.holdings.take(5).map((h) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Text(h.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(h.displayName, style: const TextStyle(fontSize: 13)),
                ),
                Text(
                  '${(h.minutes / 60).toStringAsFixed(1)}h',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: h.isInvested ? AppTheme.secondary : h.isSpent ? AppTheme.danger : AppTheme.warning,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (h.isInvested ? AppTheme.secondary : h.isSpent ? AppTheme.danger : AppTheme.warning).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${h.percent}%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: h.isInvested ? AppTheme.secondary : h.isSpent ? AppTheme.danger : AppTheme.warning,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildDebtStatChip(String emoji, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Text(label, style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioStat(String label, int minutes, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceSm),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text('${(minutes / 60).toStringAsFixed(1)}h', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
            Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Color _gradeColor(String grade) {
    switch (grade) {
      case 'A': return AppTheme.secondary;
      case 'B': return const Color(0xFF00CEC9);
      case 'C': return AppTheme.warning;
      case 'D': return AppTheme.danger;
      default: return AppTheme.textSecondary;
    }
  }

  double _getMaxY() {
    if (weeklyData.isEmpty) return 400;
    final maxTotal = weeklyData.map((d) => d.total).reduce((a, b) => a > b ? a : b);
    return (maxTotal * 1.2).toDouble().clamp(60, 1440);
  }

  // ═══════════════════════════════════════
  // FEATURE 3: Regret Forecast
  // ═══════════════════════════════════════
  Widget _buildRegretForecast() {
    final rf = _regretForecast!;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('⏳', 'Regret Forecast'),

          // Total projection header
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceMd),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0x26FF6B6B), Color(0x0DFF6B6B)],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.danger.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Text('💀', style: TextStyle(fontSize: 24)),
                const SizedBox(width: AppTheme.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'At your current pace, you\'ll lose ${rf.totalYearlyHours}h this year',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        'That\'s ${rf.totalYearlyDays} full days to addictive apps',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spaceMd),

          // Per-app forecasts
          ...rf.forecasts.take(5).map((f) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(AppTheme.spaceMd),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(f.emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(f.appName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${f.dailyAvgMinutes}m/day', style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('${f.yearlyHours}h/year', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  f.regretLine,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // FEATURE 5: AI Trigger Detection
  // ═══════════════════════════════════════
  Widget _buildTriggerDetection() {
    final td = _triggers!;
    Color riskColor;
    switch (td.overallRisk) {
      case 'high': riskColor = AppTheme.danger; break;
      case 'moderate': riskColor = AppTheme.warning; break;
      default: riskColor = AppTheme.secondary;
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildSectionTitle('🎯', 'Trigger Detection'),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Risk: ${td.overallRisk.toUpperCase()}',
                  style: TextStyle(color: riskColor, fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),

          // Trigger cards
          ...td.triggers.map((trigger) => Container(
            margin: const EdgeInsets.only(bottom: AppTheme.spaceSm),
            padding: const EdgeInsets.all(AppTheme.spaceMd),
            decoration: BoxDecoration(
              color: AppTheme.surfaceHover,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: _triggerColor(trigger.type).withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(trigger.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(trigger.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
                    // Confidence indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _triggerColor(trigger.type).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${(trigger.confidence * 100).round()}%',
                        style: TextStyle(fontSize: 10, color: _triggerColor(trigger.type), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(trigger.description, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Text('💡', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          trigger.suggestion,
                          style: const TextStyle(fontSize: 11, color: AppTheme.secondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Color _triggerColor(String type) {
    switch (type) {
      case 'boredom': return const Color(0xFFFDCB6E);
      case 'stress': return const Color(0xFFFF6B6B);
      case 'fatigue': return const Color(0xFF6C5CE7);
      case 'loneliness': return const Color(0xFFE84393);
      case 'procrastination': return const Color(0xFFFF8C00);
      default: return AppTheme.textSecondary;
    }
  }

  Widget _buildSectionTitle(String emoji, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceMd),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String time, String label) {
    return Row(
      children: [
        Text(time, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
      ],
    );
  }
}
