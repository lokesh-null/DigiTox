import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/heatmap_grid.dart';
import '../data/mock_data.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final weeklyData = generateWeeklyData();
    final heatmapData = generateHeatmapData();
    final suggestions = getAISuggestions(heatmapData);
    final grade = getWeeklyGrade(weeklyData);
    
    final totalProductive = weeklyData.fold(0, (s, d) => s + d.productive);
    final totalAddictive = weeklyData.fold(0, (s, d) => s + d.addictive);
    final totalNeutral = weeklyData.fold(0, (s, d) => s + d.neutral);

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
                      Text(grade['desc']!, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13)),
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spaceLg),

          // Weekly Chart
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('📊', 'Weekly Usage'),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 400, // Roughly max minutes
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) => Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(weeklyData[value.toInt()].day, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
                            ),
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
                        getDrawingHorizontalLine: (value) => FlLine(color: Colors.white.withOpacity(0.04), strokeWidth: 1),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: weeklyData.asMap().entries.map((e) {
                        int index = e.key;
                        var d = e.value;
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: d.productive + d.addictive + d.neutral.toDouble(),
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
                  child: Row(
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
                Expanded(child: Text(s['text']!.replaceAll('**', ''), style: const TextStyle(fontSize: 13, height: 1.4))),
              ],
            ),
          )),
        ],
      ),
    );
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
