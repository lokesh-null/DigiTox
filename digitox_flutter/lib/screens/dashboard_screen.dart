import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/time_split_bar.dart';
import '../widgets/app_usage_item.dart';
import '../data/mock_data.dart';
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
  late List<MockApp> todayUsage;
  late int productive;
  late int addictive;
  late int neutral;
  late int total;
  int streak = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    todayUsage = generateTodayUsage();
    productive = todayUsage.where((a) => a.category == AppCategories.productive).fold(0, (s, a) => s + a.minutes);
    addictive = todayUsage.where((a) => a.category == AppCategories.addictive).fold(0, (s, a) => s + a.minutes);
    neutral = todayUsage.where((a) => a.category == AppCategories.neutral).fold(0, (s, a) => s + a.minutes);
    total = productive + addictive + neutral;
    
    streak = await Storage.load(StorageKeys.streak, fallback: 7) as int;
    setState(() {});
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    if (total == 0) return const Center(child: CircularProgressIndicator());

    final prodPercent = total > 0 ? (productive / total) : 0.0;
    final addPercent = total > 0 ? (addictive / total) : 0.0;
    final neutPercent = total > 0 ? (neutral / total) : 0.0;
    
    final topApps = todayUsage.take(5).toList();
    final maxMinutes = topApps.isNotEmpty ? topApps.first.minutes : 1;
    final realities = getTimeRealities(addictive);

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

          // Live Timer Card
          _buildLiveTimerCard(),
          const SizedBox(height: AppTheme.spaceLg),

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
              StatCard(value: '🔥 $streak', label: 'Day Streak', type: StatCardType.streak),
              StatCard(value: '${(prodPercent * 100).toStringAsFixed(0)}%', label: 'Focus Score', type: StatCardType.score),
            ],
          ),
          const SizedBox(height: AppTheme.spaceLg),

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
          ...topApps.map((app) => Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spaceSm),
            child: AppUsageItem(
              app: app,
              maxMinutes: maxMinutes,
              formattedTime: UsageTracker().formatTimeShort(app.minutes),
            ),
          )),
          const SizedBox(height: AppTheme.spaceLg),

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
                            r['text']!.replaceAll('**', ''), // Quick markdown strip for demo
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

  Widget _buildLiveTimerCard() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0x266C5CE7), Color(0x1A00CEC9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
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
