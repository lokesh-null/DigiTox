import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/habit_item.dart';
import '../widgets/contribution_grid.dart';
import '../data/mock_data.dart';
import '../data/data_provider.dart';
import '../data/database.dart';
import '../data/behavioral_engine.dart';
import '../data/device_intelligence.dart';
import '../utils/storage.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  List<Habit> habits = [];
  List<Map<String, dynamic>> _challenges = [];
  final List<String> emojis = ['🌅', '📚', '🚫', '🌆', '😴', '🧘', '🏃', '✍️', '🎸', '🌿', '💧', '🍎'];

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    final data = await Storage.load(StorageKeys.habits);
    if (data != null && data is List) {
      habits = data.map((e) => Habit.fromJson(e)).toList();
    } else {
      habits = List.from(defaultHabits);
      _saveHabits();
    }
    
    // Feature 7: Load daily challenges
    await BehavioralEngine().generateDailyChallenges();
    _challenges = await DigiToxDatabase().getChallengesForDate(DeviceIntelligence.todayString());
    
    if (mounted) setState(() {});
  }

  Future<void> _saveHabits() async {
    await Storage.save(StorageKeys.habits, habits.map((h) => h.toJson()).toList());
  }

  int _calculateConsistency() {
    if (habits.isEmpty) return 0;
    double avgStreak = habits.fold(0, (s, h) => s + h.streak) / habits.length;
    return ((avgStreak / 14) * 100).clamp(0, 100).round();
  }

  void _showAddHabitModal() {
    String name = '';
    String selectedEmoji = emojis.first;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgSecondary,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: AppTheme.spaceLg,
                right: AppTheme.spaceLg,
                top: AppTheme.spaceLg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceActive,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceLg),
                  Text('New Habit', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppTheme.spaceLg),
                  TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'e.g., Read for 20 minutes',
                      filled: true,
                      fillColor: AppTheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) => name = val,
                  ),
                  const SizedBox(height: AppTheme.spaceLg),
                  const Text('Choose an icon', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  const SizedBox(height: AppTheme.spaceSm),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: emojis.map((e) {
                      bool isSelected = e == selectedEmoji;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedEmoji = e),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primary.withOpacity(0.2) : AppTheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.border),
                          ),
                          child: Text(e, style: const TextStyle(fontSize: 24)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppTheme.spaceXl),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceMd),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (name.trim().isNotEmpty) {
                              setState(() {
                                habits.add(Habit(
                                  id: 'h${DateTime.now().millisecondsSinceEpoch}',
                                  name: name.trim(),
                                  emoji: selectedEmoji,
                                  streak: 0,
                                  completedToday: false,
                                ));
                                _saveHabits();
                              });
                              Navigator.pop(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Add Habit', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceXl),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Habits', style: Theme.of(context).textTheme.displayMedium),
                  const SizedBox(height: 4),
                  const Text('Build better patterns', style: TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _showAddHabitModal,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.surface,
                  foregroundColor: AppTheme.textPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppTheme.border)),
                ),
              )
            ],
          ),
          const SizedBox(height: AppTheme.spaceLg),

          // Consistency Score
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceLg),
            decoration: BoxDecoration(
              gradient: AppTheme.gradientWarm,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_calculateConsistency()}%', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
                const Text('Consistency Score', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spaceLg),

          // Habit List
          _buildSectionTitle('✅', 'Today\'s Habits'),
          ...habits.map((h) => HabitItem(
            habit: h,
            onToggle: () {
              setState(() {
                h.completedToday = !h.completedToday;
                if (h.completedToday) {
                  h.streak++;
                } else {
                  h.streak = (h.streak - 1).clamp(0, 9999);
                }
                _saveHabits();
              });
            },
          )),
          const SizedBox(height: AppTheme.spaceLg),

          // ═══════════════════════════════════════
          // FEATURE 7: Anti-Doomscroll Challenges
          // ═══════════════════════════════════════
          if (_challenges.isNotEmpty) ...[
            _buildSectionTitle('🎯', 'Daily Challenges'),
            ..._challenges.map((c) => _buildChallengeCard(c)),
            const SizedBox(height: AppTheme.spaceLg),
          ],

          // Contribution Grid
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('📅', 'Last 28 Days'),
                FutureBuilder<List<int>>(
                  future: DataProvider().getContributionData(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return ContributionGrid(data: snapshot.data!);
                    }
                    return ContributionGrid(data: List.filled(28, 0));
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spaceLg),

          // Alternatives
          _buildSectionTitle('🔄', 'Instead of Scrolling, Try...'),
          ...habitAlternatives.map((alt) => Container(
            margin: const EdgeInsets.only(bottom: AppTheme.spaceSm),
            padding: const EdgeInsets.all(AppTheme.spaceMd),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              border: Border.all(color: AppTheme.border),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Row(
              children: [
                Text(alt['emoji']!, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: AppTheme.spaceMd),
                Expanded(child: Text(alt['from']!, style: const TextStyle(color: AppTheme.textSecondary))),
                const Icon(Icons.arrow_forward, size: 16, color: AppTheme.textTertiary),
                const SizedBox(width: AppTheme.spaceSm),
                Expanded(flex: 2, child: Text(alt['to']!, style: const TextStyle(fontWeight: FontWeight.w500))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildChallengeCard(Map<String, dynamic> challenge) {
    bool isCompleted = challenge['completed'] == 1;
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceSm),
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      decoration: BoxDecoration(
        color: isCompleted ? AppTheme.primary.withValues(alpha: 0.1) : AppTheme.surfaceHover,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isCompleted ? AppTheme.primary.withValues(alpha: 0.3) : AppTheme.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isCompleted ? AppTheme.primary : AppTheme.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? Icons.check : Icons.local_fire_department,
              size: 20,
              color: isCompleted ? Colors.black : AppTheme.primary,
            ),
          ),
          const SizedBox(width: AppTheme.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  challenge['description'] as String,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    color: isCompleted ? AppTheme.textSecondary : Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text('+${challenge['xp_reward']} XP', style: const TextStyle(color: AppTheme.primaryLight, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
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
}
