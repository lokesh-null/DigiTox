import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/focus_timer_ring.dart';
import '../widgets/toggle_switch.dart';
import '../data/mock_data.dart';
import '../utils/storage.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  final List<int> durations = [15, 25, 45, 60, 90];
  int selectedDuration = 25;
  bool isFocusActive = false;
  int focusRemaining = 0;
  Timer? _timer;
  int completedSessions = 0;
  String currentTask = '';

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    completedSessions = await Storage.load(StorageKeys.focusSessions, fallback: 0) as int;
    currentTask = await Storage.load('digitox_current_task', fallback: '') as String;
    setState(() {});
  }

  void _startFocus() {
    setState(() {
      isFocusActive = true;
      focusRemaining = selectedDuration * 60;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (focusRemaining > 0) {
        setState(() {
          focusRemaining--;
        });
      } else {
        _completeFocus();
      }
    });
  }

  void _stopFocus() {
    _timer?.cancel();
    setState(() {
      isFocusActive = false;
    });
  }

  void _completeFocus() async {
    _timer?.cancel();
    completedSessions++;
    int streak = await Storage.load(StorageKeys.streak, fallback: 0) as int;
    await Storage.save(StorageKeys.focusSessions, completedSessions);
    await Storage.save(StorageKeys.streak, streak + 1);

    setState(() {
      isFocusActive = false;
    });

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.bgSecondary,
          title: const Text('🎉 Session Complete!'),
          content: Text('Amazing focus! You just completed $selectedDuration minutes of deep work. Your streak is growing — keep it up!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTimer(int seconds) {
    final m = (seconds / 60).floor();
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    double progress = isFocusActive ? ((selectedDuration * 60) - focusRemaining) / (selectedDuration * 60) : 0;

    return Container(
      decoration: BoxDecoration(
        border: isFocusActive ? Border.all(color: AppTheme.primary.withOpacity(0.5), width: 4) : null,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spaceLg),
        child: Column(
          children: [
            const SizedBox(height: AppTheme.spaceMd),
            Text('Focus Mode', style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 4),
            const Text('Deep work starts here', style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: AppTheme.spaceXl),

            FocusTimerRing(
              progress: progress,
              timeText: isFocusActive ? _formatTimer(focusRemaining) : _formatTimer(selectedDuration * 60),
              labelText: isFocusActive ? 'Remaining' : 'Ready',
            ),
            const SizedBox(height: AppTheme.spaceXl),

            TextField(
              controller: TextEditingController(text: currentTask)..selection = TextSelection.collapsed(offset: currentTask.length),
              enabled: !isFocusActive,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'What are you working on?',
                filled: true,
                fillColor: AppTheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                currentTask = val;
                Storage.save('digitox_current_task', val);
              },
            ),
            const SizedBox(height: AppTheme.spaceLg),

            if (!isFocusActive)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: durations.map((d) {
                  final isSelected = d == selectedDuration;
                  return InkWell(
                    onTap: () => setState(() => selectedDuration = d),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primary : AppTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.border),
                      ),
                      child: Text('$d min', style: TextStyle(color: isSelected ? Colors.white : AppTheme.textSecondary)),
                    ),
                  );
                }).toList(),
              ),
            
            const SizedBox(height: AppTheme.spaceXl),

            ElevatedButton.icon(
              onPressed: isFocusActive ? _stopFocus : _startFocus,
              style: ElevatedButton.styleFrom(
                backgroundColor: isFocusActive ? AppTheme.surface : null,
                foregroundColor: isFocusActive ? AppTheme.danger : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ).copyWith(
                backgroundBuilder: isFocusActive ? null : (context, states, child) {
                  return Container(
                    decoration: const BoxDecoration(
                      gradient: AppTheme.gradientPrimary,
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                    ),
                    child: child,
                  );
                },
              ),
              icon: Icon(isFocusActive ? Icons.stop : Icons.play_arrow),
              label: Text(isFocusActive ? 'Stop Session' : 'Start Focus', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),

            const SizedBox(height: AppTheme.spaceXl),

            GlassCard(
              isSmall: true,
              child: Column(
                children: [
                  const Text('Completed Sessions', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  Text(completedSessions.toString(), style: Theme.of(context).textTheme.displayMedium?.copyWith(color: AppTheme.primaryLight)),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spaceLg),

            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  const Text('🚫', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text('Blocked During Focus', style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spaceMd),

            ...mockApps.where((app) => app.category == AppCategories.addictive).map((app) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spaceSm),
                child: Row(
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                      child: Center(child: Text(app.emoji)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(app.name)),
                    ToggleSwitch(
                      value: app.blocked,
                      disabled: isFocusActive,
                      onChanged: (val) {
                        setState(() => app.blocked = val);
                      },
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
