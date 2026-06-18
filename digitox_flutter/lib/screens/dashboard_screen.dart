import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/time_split_bar.dart';
import '../widgets/app_usage_item.dart';
import '../widgets/dopamine_gauge.dart';
import '../widgets/identity_badge.dart';
import '../data/data_provider.dart';
import '../data/behavioral_engine.dart';
import '../utils/tracker.dart';
import '../utils/storage.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onStartFocus;
  final VoidCallback onEmergencyLock;

  const DashboardScreen({
    super.key,
    required this.onStartFocus,
    required this.onEmergencyLock,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<AppUsageInfo> todayUsage = [];
  int productive = 0;
  int addictive = 0;
  int neutral = 0;
  int total = 0;
  int streak = 0;
  bool _loading = true;

  // Behavioral Intelligence data
  DopamineDebtResult? _dopamineDebt;
  FocusIdentityResult? _focusIdentity;
  LifeRecoveryResult? _lifeRecovery;
  AlterEgoResult? _alterEgo;
  RelapseResult? _relapse;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final stats = await DataProvider().getTodayStats();
      todayUsage = await DataProvider().getTodayUsage();
      productive = stats.productive;
      addictive = stats.addictive;
      neutral = stats.neutral;
      total = stats.total;
      streak = await Storage.load(StorageKeys.streak, fallback: 0) as int;

      // Load behavioral intelligence data
      _dopamineDebt = await BehavioralEngine().computeDopamineDebt();
      _focusIdentity = await BehavioralEngine().computeFocusIdentity();
      _lifeRecovery = await BehavioralEngine().computeLifeRecovery();
      _alterEgo = await BehavioralEngine().computeAlterEgo();
      _relapse = await BehavioralEngine().computeRelapsePrediction();

      // Save daily scores
      await BehavioralEngine().computeAndSaveDailyScores();
    } catch (e) {
      // If data isn't available yet, show zeros
    }
    if (mounted) setState(() => _loading = false);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final prodPercent = total > 0 ? (productive / total) : 0.0;
    final addPercent = total > 0 ? (addictive / total) : 0.0;
    final neutPercent = total > 0 ? (neutral / total) : 0.0;

    final topApps = todayUsage.take(5).toList();
    final maxMinutes = topApps.isNotEmpty ? topApps.first.minutes : 1;
    final realities = DataProvider().getTimeRealities(addictive);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          Text('${_getGreeting()} 👋', style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 26)),
          const SizedBox(height: 4),
          const Text('Here\'s your digital wellness report for today', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: AppTheme.spaceLg),

          // ═══════════════════════════════════════
          // FEATURE 2: Digital Alter Ego
          // ═══════════════════════════════════════
          if (_alterEgo != null) ...[
            _buildAlterEgoCard(),
            const SizedBox(height: AppTheme.spaceLg),
          ],

          // Live Timer Card
          _buildLiveTimerCard(),
          const SizedBox(height: AppTheme.spaceLg),

          // ═══════════════════════════════════════
          // FEATURE 1: Dopamine Debt Meter
          // ═══════════════════════════════════════
          if (_dopamineDebt != null) ...[
            _buildDopamineDebtCard(),
            const SizedBox(height: AppTheme.spaceLg),
          ],

          // ═══════════════════════════════════════
          // FEATURE 9: Digital Relapse Predictor
          // ═══════════════════════════════════════
          if (_relapse != null) ...[
            _buildRelapseCard(),
            const SizedBox(height: AppTheme.spaceLg),
          ],

          // Stats Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppTheme.spaceMd,
            crossAxisSpacing: AppTheme.spaceMd,
            childAspectRatio: 1.8,
            children: [
              StatCard(value: UsageTracker().formatTimeShort(productive), label: 'Time Invested', type: StatCardType.productive),
              StatCard(value: UsageTracker().formatTimeShort(addictive), label: 'Time Wasted', type: StatCardType.addictive),
              StatCard(value: '🔥 ${_focusIdentity?.streak ?? streak}', label: 'Day Streak', type: StatCardType.streak),
              StatCard(value: '${(prodPercent * 100).toStringAsFixed(0)}%', label: 'Focus Score', type: StatCardType.score),
            ],
          ),
          const SizedBox(height: AppTheme.spaceLg),

          // ═══════════════════════════════════════
          // FEATURE 4: Focus Identity System
          // ═══════════════════════════════════════
          if (_focusIdentity != null) ...[
            _buildSectionTitle('🏆', 'Focus Identity'),
            IdentityBadge(
              level: _focusIdentity!.level,
              title: _focusIdentity!.title,
              emoji: _focusIdentity!.emoji,
              totalXP: _focusIdentity!.totalXP,
              xpForCurrentLevel: _focusIdentity!.xpForCurrentLevel,
              xpForNextLevel: _focusIdentity!.xpForNextLevel,
              progressPercent: _focusIdentity!.progressPercent,
              streak: _focusIdentity!.streak,
            ),
            const SizedBox(height: AppTheme.spaceLg),
          ],

          // Time Split
          GlassCard(
            isSmall: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('📊', 'Time Distribution'),
                TimeSplitBar(
                  productivePercent: prodPercent,
                  neutralPercent: neutPercent,
                  addictivePercent: addPercent,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spaceLg),

          // Quick Actions
          Row(
            children: [
              Expanded(
                child: _buildQuickAction(
                  icon: Icons.filter_center_focus,
                  label: 'Start Focus',
                  gradient: AppTheme.gradientPrimary,
                  onTap: widget.onStartFocus,
                ),
              ),
              const SizedBox(width: AppTheme.spaceMd),
              Expanded(
                child: _buildQuickAction(
                  icon: Icons.lock_outline,
                  label: 'Emergency Lock',
                  color: AppTheme.surface,
                  textColor: AppTheme.danger,
                  borderColor: AppTheme.border,
                  onTap: widget.onEmergencyLock,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceLg),

          // Top Apps
          _buildSectionTitle('📱', 'Most Used Today'),
          if (topApps.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceLg),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                border: Border.all(color: AppTheme.border),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: const Center(
                child: Text(
                  'No usage data yet.\nGrant Usage Access permission to see real app data.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
              ),
            ),
          ...topApps.map((app) => Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spaceSm),
            child: AppUsageItem(
              appName: app.appName,
              emoji: app.emoji,
              category: app.category,
              color: app.color,
              minutes: app.minutes,
              maxMinutes: maxMinutes,
              formattedTime: UsageTracker().formatTimeShort(app.minutes),
            ),
          )),
          const SizedBox(height: AppTheme.spaceLg),

          // ═══════════════════════════════════════
          // FEATURE 6: Life Recovery Calculator
          // ═══════════════════════════════════════
          if (_lifeRecovery != null) ...[
            _buildLifeRecoverySection(),
            const SizedBox(height: AppTheme.spaceLg),
          ],

          // Reality Check
          _buildSectionTitle('💡', 'Time Reality Check'),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: realities.length,
              itemBuilder: (context, index) {
                final r = realities[index];
                return Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: AppTheme.spaceMd),
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r['emoji']!, style: const TextStyle(fontSize: 32)),
                        const SizedBox(height: AppTheme.spaceSm),
                        Expanded(
                          child: Text(
                            r['text']!,
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppTheme.spaceXl),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // FEATURE 1: Dopamine Debt Card
  // ═══════════════════════════════════════
  Widget _buildDopamineDebtCard() {
    final debt = _dopamineDebt!;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('🧠', 'Dopamine Debt'),
          DopamineGauge(
            score: debt.score,
            severity: debt.severity,
            label: debt.label,
          ),
          const SizedBox(height: AppTheme.spaceMd),
          // Factor breakdown (show top 3)
          ...debt.factors.take(3).map((factor) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(
                  factor.startsWith('-') ? Icons.trending_down : Icons.trending_up,
                  size: 14,
                  color: factor.startsWith('-') ? AppTheme.secondary : AppTheme.danger,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    factor,
                    style: TextStyle(
                      fontSize: 11,
                      color: factor.startsWith('-') ? AppTheme.secondary : AppTheme.textSecondary,
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

  // ═══════════════════════════════════════
  // FEATURE 6: Life Recovery Section
  // ═══════════════════════════════════════
  Widget _buildLifeRecoverySection() {
    final recovery = _lifeRecovery!;
    final isImproving = recovery.recoveredMinutes > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('🌱', 'Life Recovery'),
        // Recovery summary card
        Container(
          padding: const EdgeInsets.all(AppTheme.spaceLg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isImproving
                ? [const Color(0x2600CEC9), const Color(0x0D00CEC9)]
                : [const Color(0x26FF6B6B), const Color(0x0DFF6B6B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: isImproving
                ? AppTheme.secondary.withValues(alpha: 0.3)
                : AppTheme.danger.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          child: Row(
            children: [
              // Arrow icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (isImproving ? AppTheme.secondary : AppTheme.danger).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isImproving ? Icons.trending_up : Icons.trending_down,
                  color: isImproving ? AppTheme.secondary : AppTheme.danger,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isImproving
                        ? '${recovery.recoveredMinutes} min recovered'
                        : recovery.recoveredMinutes == 0
                          ? 'Building baseline...'
                          : '${recovery.recoveredMinutes.abs()} min more than last week',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isImproving
                        ? '${recovery.improvementPercent}% less addictive usage vs last week'
                        : recovery.recoveredMinutes == 0
                          ? 'We\'re collecting your first week of data'
                          : 'Addictive screen time increased',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Recovery scenarios
        if (recovery.dailyAddictiveAvg > 0) ...[
          const SizedBox(height: AppTheme.spaceMd),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: recovery.scenarios.length,
              itemBuilder: (context, index) {
                final s = recovery.scenarios[index];
                return Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: AppTheme.spaceSm),
                  padding: const EdgeInsets.all(AppTheme.spaceMd),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    border: Border.all(color: AppTheme.border),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.emoji, style: const TextStyle(fontSize: 20)),
                      const SizedBox(height: 4),
                      Text(s.value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(s.label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLiveTimerCard() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0x266C5CE7), Color(0x1A00CEC9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Center(
        child: Column(
          children: [
            const Text(
              'TODAY\'S SCREEN TIME',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, letterSpacing: 1.5, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppTheme.spaceSm),
            StreamBuilder<int>(
              stream: UsageTracker().onTick,
              initialData: UsageTracker().getTodayTime(),
              builder: (context, snapshot) {
                return ShaderMask(
                  shaderCallback: (bounds) => AppTheme.gradientMixed.createShader(bounds),
                  child: Text(
                    UsageTracker().formatTime(snapshot.data ?? 0),
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 48, color: Colors.white),
                  ),
                );
              },
            ),
            const SizedBox(height: AppTheme.spaceSm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(color: AppTheme.secondary, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                const Text('Tracking live', style: TextStyle(color: AppTheme.secondary, fontSize: 12)),
              ],
            )
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // FEATURE 2: Digital Alter Ego Card
  // ═══════════════════════════════════════
  Widget _buildAlterEgoCard() {
    final ego = _alterEgo!;
    Color auraColor;
    switch (ego.aura) {
      case 'golden': auraColor = const Color(0xFFFFD700); break;
      case 'green': auraColor = AppTheme.secondary; break;
      case 'yellow': auraColor = AppTheme.warning; break;
      case 'orange': auraColor = const Color(0xFFFF8C00); break;
      case 'red': auraColor = AppTheme.danger; break;
      default: auraColor = AppTheme.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [auraColor.withValues(alpha: 0.15), auraColor.withValues(alpha: 0.03)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: auraColor.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Row(
        children: [
          // Avatar with aura glow
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: auraColor.withValues(alpha: 0.15),
              boxShadow: [BoxShadow(color: auraColor.withValues(alpha: 0.3), blurRadius: 16, spreadRadius: 2)],
            ),
            child: Center(child: Text(ego.emoji, style: const TextStyle(fontSize: 30))),
          ),
          const SizedBox(width: AppTheme.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(ego.state, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: auraColor)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: auraColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${ego.moodScore}%', style: TextStyle(fontSize: 11, color: auraColor, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(ego.message, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // FEATURE 9: Relapse Predictor Card
  // ═══════════════════════════════════════
  Widget _buildRelapseCard() {
    final r = _relapse!;
    Color riskColor;
    switch (r.riskLevel) {
      case 'Low': riskColor = AppTheme.secondary; break;
      case 'Moderate': riskColor = AppTheme.warning; break;
      case 'High': riskColor = const Color(0xFFFF8C00); break;
      default: riskColor = AppTheme.danger;
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('🔮', 'Relapse Risk'),
          // Risk level bar
          Row(
            children: [
              Text(r.riskEmoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: AppTheme.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(r.riskLevel, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: riskColor)),
                        const Spacer(),
                        Text('${r.riskScore}/100', style: TextStyle(color: riskColor, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 6,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: (r.riskScore / 100).clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: riskColor,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMd),
          // Advice
          Text(r.advice, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          // Risk factors
          if (r.factors.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spaceMd),
            ...r.factors.take(3).map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 12, color: riskColor.withValues(alpha: 0.7)),
                  const SizedBox(width: 6),
                  Expanded(child: Text(f, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary))),
                ],
              ),
            )),
          ],
          // Trend
          if (r.trendDirection != 'stable') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  r.trendDirection == 'rising' ? Icons.trending_up : Icons.trending_down,
                  size: 14,
                  color: r.trendDirection == 'rising' ? AppTheme.danger : AppTheme.secondary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Recent: ${r.recent3DayAvg}m/day vs ${r.baseline7DayAvg}m/day baseline',
                  style: TextStyle(fontSize: 10, color: r.trendDirection == 'rising' ? AppTheme.danger : AppTheme.secondary),
                ),
              ],
            ),
          ],
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
          Text(title, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    LinearGradient? gradient,
    Color? color,
    Color textColor = Colors.white,
    Color? borderColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceMd),
        decoration: BoxDecoration(
          gradient: gradient,
          color: color,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: borderColor != null ? Border.all(color: borderColor) : null,
          boxShadow: gradient != null ? [BoxShadow(color: AppTheme.primaryGlow, blurRadius: 12)] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 18),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
