import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/focus_timer_ring.dart';
import '../data/database.dart';
import '../data/behavioral_engine.dart';
import '../data/installed_apps_repository.dart';
import '../data/device_intelligence.dart';
import '../widgets/identity_badge.dart';
import '../utils/storage.dart';
import 'focus_app_selector.dart';
import 'focus_profiles_screen.dart';

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
  bool isContractSigned = false;
  FocusIdentityResult? _identity;

  // Real blocked apps
  List<String> _blockedPackages = [];
  Map<String, InstalledApp?> _blockedAppDetails = {};
  String _selectedProfile = 'default';
  List<Map<String, dynamic>> _profiles = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    completedSessions = await DigiToxDatabase().getCompletedSessionCount();
    currentTask = await Storage.load('digitox_current_task', fallback: '') as String;
    _identity = await BehavioralEngine().computeFocusIdentity();
    _profiles = await DigiToxDatabase().getAllFocusProfiles();

    // Load installed apps + blocked list
    await InstalledAppsRepository().loadApps();
    await _loadBlockedApps();

    // Check if focus enforcement is still active (e.g., after app restart)
    try {
      final isActive = await DeviceIntelligence.isFocusEnforcementActive();
      if (isActive) {
        final remaining = await DeviceIntelligence.getFocusRemainingSeconds();
        if (remaining > 0) {
          setState(() {
            isFocusActive = true;
            focusRemaining = remaining;
          });
          _startTimer();
        }
      }
    } catch (_) {}

    setState(() {});
  }

  Future<void> _loadBlockedApps() async {
    _blockedPackages = await DigiToxDatabase().getBlockedPackages(profile: _selectedProfile);
    _blockedAppDetails = {};
    for (final pkg in _blockedPackages) {
      _blockedAppDetails[pkg] = InstalledAppsRepository().getApp(pkg);
    }
  }

  void _startFocus() async {
    setState(() {
      isFocusActive = true;
      focusRemaining = selectedDuration * 60;
    });

    // Start real enforcement
    try {
      await DeviceIntelligence.startFocusEnforcement(_blockedPackages, selectedDuration);
    } catch (_) {}

    _startTimer();
  }

  void _startTimer() {
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
    if (isContractSigned) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.bgSecondary,
          title: const Text('⚠️ Break Contract?'),
          content: const Text('You signed a commitment contract for this session. If you stop now, you will lose 30 XP.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Keep Focusing', style: TextStyle(color: AppTheme.primaryLight)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _executeStopFocus(true);
              },
              child: const Text('Break Contract', style: TextStyle(color: AppTheme.danger)),
            ),
          ],
        ),
      );
    } else {
      _executeStopFocus(false);
    }
  }

  void _executeStopFocus(bool brokeContract) async {
    _timer?.cancel();

    // Stop real enforcement
    try {
      await DeviceIntelligence.stopFocusEnforcement();
    } catch (_) {}

    // Penalize if broken contract
    if (brokeContract) {
      final now = DateTime.now();
      final startTime = now.subtract(Duration(seconds: (selectedDuration * 60) - focusRemaining)).millisecondsSinceEpoch;
      final sessionId = await DigiToxDatabase().insertFocusSession(
        startTime: startTime,
        durationMinutes: selectedDuration,
        task: currentTask.isNotEmpty ? currentTask : null,
        contractText: isContractSigned ? 'I commit to focus.' : null,
      );
      await DigiToxDatabase().completeFocusSession(sessionId, now.millisecondsSinceEpoch, -30);

      BehavioralEngine().computeFocusIdentity().then((id) {
        if (mounted) setState(() => _identity = id);
      });
    }

    setState(() {
      isFocusActive = false;
      isContractSigned = false;
    });
  }

  void _completeFocus() async {
    _timer?.cancel();
    completedSessions++;
    int streak = await Storage.load(StorageKeys.streak, fallback: 0) as int;
    await Storage.save(StorageKeys.focusSessions, completedSessions);
    await Storage.save(StorageKeys.streak, streak + 1);

    // Stop real enforcement
    try {
      await DeviceIntelligence.stopFocusEnforcement();
    } catch (_) {}

    // Calculate XP
    int xp = _xpForDuration(selectedDuration);
    if (isContractSigned) xp += 25;

    // Log to database
    final now = DateTime.now();
    final startTime = now.subtract(Duration(minutes: selectedDuration)).millisecondsSinceEpoch;
    final sessionId = await DigiToxDatabase().insertFocusSession(
      startTime: startTime,
      durationMinutes: selectedDuration,
      task: currentTask.isNotEmpty ? currentTask : null,
      contractText: isContractSigned ? 'I commit to focus.' : null,
    );
    await DigiToxDatabase().completeFocusSession(sessionId, now.millisecondsSinceEpoch, xp);

    setState(() {
      isFocusActive = false;
      isContractSigned = false;
    });

    if (mounted) {
      _identity = await BehavioralEngine().computeFocusIdentity();
      if (!mounted) return;
      setState(() {});

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.bgSecondary,
          title: const Text('🎉 Session Complete!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Amazing focus! You just completed $selectedDuration minutes of deep work.'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('✨', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text('+$xp XP earned!', style: const TextStyle(color: AppTheme.primaryLight, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
            ],
          ),
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

  int _xpForDuration(int minutes) {
    if (minutes >= 90) return 50;
    if (minutes >= 60) return 40;
    if (minutes >= 45) return 30;
    if (minutes >= 25) return 20;
    return 10;
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

  Widget _buildAppIcon(Uint8List? iconBytes) {
    if (iconBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(iconBytes, width: 32, height: 32, gaplessPlayback: true),
      );
    }
    return Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.android, color: AppTheme.textSecondary, size: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    double progress = isFocusActive ? ((selectedDuration * 60) - focusRemaining) / (selectedDuration * 60) : 0;

    return Container(
      decoration: BoxDecoration(
        border: isFocusActive ? Border.all(color: AppTheme.primary.withValues(alpha: 0.5), width: 4) : null,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spaceLg),
        child: Column(
          children: [
            const SizedBox(height: AppTheme.spaceMd),
            Text('Focus Mode', style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 4),
            const Text('Deep work starts here', style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: AppTheme.spaceMd),

            // Profile selector
            if (!isFocusActive && _profiles.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: AppTheme.spaceMd),
                child: InkWell(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => FocusProfilesScreen(
                        currentProfile: _selectedProfile,
                        onProfileSelected: (profile) async {
                          _selectedProfile = profile;
                          await _loadBlockedApps();
                          setState(() {});
                        },
                      )),
                    );
                    _profiles = await DigiToxDatabase().getAllFocusProfiles();
                    await _loadBlockedApps();
                    setState(() {});
                  },
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _profiles.firstWhere((p) => p['id'] == _selectedProfile, orElse: () => {'emoji': '🎯', 'name': 'Default'})['emoji'] as String? ?? '🎯',
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _profiles.firstWhere((p) => p['id'] == _selectedProfile, orElse: () => {'emoji': '🎯', 'name': 'Default'})['name'] as String? ?? 'Default',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: AppTheme.spaceMd),

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

            // ═══════════════════════════════════════
            // FEATURE 13: Gamified Focus Contracts
            // ═══════════════════════════════════════
            if (!isFocusActive)
              Container(
                margin: const EdgeInsets.only(bottom: AppTheme.spaceXl),
                padding: const EdgeInsets.all(AppTheme.spaceMd),
                decoration: BoxDecoration(
                  color: isContractSigned ? AppTheme.primary.withValues(alpha: 0.1) : AppTheme.surface,
                  border: Border.all(color: isContractSigned ? AppTheme.primary : AppTheme.border),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isContractSigned ? AppTheme.primary : Colors.white.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.assignment, color: isContractSigned ? Colors.black : Colors.white, size: 20),
                    ),
                    const SizedBox(width: AppTheme.spaceMd),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Sign Focus Contract', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('+25 XP if completed, -30 XP if broken.', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                    Switch(
                      value: isContractSigned,
                      activeColor: AppTheme.primary,
                      onChanged: (val) => setState(() => isContractSigned = val),
                    ),
                  ],
                ),
              ),

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

            // Focus Identity Badge
            if (_identity != null)
              IdentityBadge(
                level: _identity!.level,
                title: _identity!.title,
                emoji: _identity!.emoji,
                totalXP: _identity!.totalXP,
                xpForCurrentLevel: _identity!.xpForCurrentLevel,
                xpForNextLevel: _identity!.xpForNextLevel,
                progressPercent: _identity!.progressPercent,
                streak: _identity!.streak,
              ),
            if (_identity != null)
              const SizedBox(height: AppTheme.spaceLg),

            // ═══════════════════════════════════════
            // Blocked Apps Section (Real)
            // ═══════════════════════════════════════
            Row(
              children: [
                const Text('🚫', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Blocked During Focus (${_blockedPackages.length})', style: Theme.of(context).textTheme.titleLarge),
                ),
                if (!isFocusActive)
                  TextButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => FocusAppSelector(profile: _selectedProfile)),
                      );
                      await _loadBlockedApps();
                      setState(() {});
                    },
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMd),

            if (_blockedPackages.isEmpty)
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceLg),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    const Text('No apps blocked yet', style: TextStyle(color: AppTheme.textSecondary)),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => FocusAppSelector(profile: _selectedProfile)),
                        );
                        await _loadBlockedApps();
                        setState(() {});
                      },
                      child: const Text('Select Apps to Block'),
                    ),
                  ],
                ),
              )
            else
              ..._blockedPackages.map((pkg) {
                final app = _blockedAppDetails[pkg];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spaceSm),
                  child: Row(
                    children: [
                      _buildAppIcon(app?.iconBytes),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(app?.appName ?? pkg.split('.').last, style: const TextStyle(fontWeight: FontWeight.w500)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.danger.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('BLOCKED', style: TextStyle(fontSize: 10, color: AppTheme.danger, fontWeight: FontWeight.bold)),
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
