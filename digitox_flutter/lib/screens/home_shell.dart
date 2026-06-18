import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'focus_screen.dart';
import 'insights_screen.dart';
import 'habits_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;
  bool isEmergencyActive = false;
  int emergencyRemaining = 0;
  Timer? _emergencyTimer;

  void _showEmergencySetup() {
    if (isEmergencyActive) {
      _showEmergencyLock();
      return;
    }

    int selectedDuration = 30;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'EmergencySetup',
      pageBuilder: (context, anim1, anim2) {
        return StatefulBuilder(builder: (context, setOverlayState) {
          return Scaffold(
            backgroundColor: Colors.black87,
            body: Center(
              child: Container(
                margin: const EdgeInsets.all(AppTheme.spaceLg),
                padding: const EdgeInsets.all(AppTheme.spaceLg),
                decoration: BoxDecoration(
                  color: AppTheme.bgSecondary,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(color: AppTheme.danger.withOpacity(0.3)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔒', style: TextStyle(fontSize: 40)),
                    const SizedBox(height: 16),
                    const Text('Emergency Lock', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text(
                      'Lock all distracting apps for a set duration. This cannot be easily bypassed — you\'ll need to type a phrase to cancel.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
                      children: [15, 30, 60, 120].map((v) {
                        bool sel = selectedDuration == v;
                        return InkWell(
                          onTap: () => setOverlayState(() => selectedDuration = v),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: sel ? AppTheme.danger.withOpacity(0.2) : AppTheme.surface,
                              border: Border.all(color: sel ? AppTheme.danger : AppTheme.border),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('$v\nmin', textAlign: TextAlign.center, style: TextStyle(color: sel ? AppTheme.danger : Colors.white)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _activateEmergency(selectedDuration);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.danger,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.lock),
                      label: const Text('Activate Emergency Lock', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }

  void _activateEmergency(int minutes) {
    setState(() {
      isEmergencyActive = true;
      emergencyRemaining = minutes * 60;
    });
    
    _emergencyTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (emergencyRemaining > 0) {
        setState(() {
          emergencyRemaining--;
        });
      } else {
        _deactivateEmergency(completed: true);
      }
    });

    _showEmergencyLock();
  }

  void _deactivateEmergency({bool completed = false}) {
    _emergencyTimer?.cancel();
    setState(() {
      isEmergencyActive = false;
    });
    if (completed && mounted) {
      // Show completion toast
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎉 Lock Complete! Great job staying focused.')),
      );
    }
  }

  void _showEmergencyLock() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      pageBuilder: (context, anim1, anim2) {
        return StatefulBuilder(builder: (context, setOverlayState) {
          final h = (emergencyRemaining / 3600).floor();
          final m = ((emergencyRemaining % 3600) / 60).floor();
          final s = emergencyRemaining % 60;
          final timeStr = h > 0 ? '$h:${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}' : '${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';

          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spaceXl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock, color: AppTheme.danger, size: 64),
                    const SizedBox(height: 16),
                    Text('LOCKED', style: Theme.of(context).textTheme.displayLarge?.copyWith(color: AppTheme.danger)),
                    const SizedBox(height: 16),
                    const Text('All distracting apps are blocked. Stay focused — you\'ve got this.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary)),
                    const SizedBox(height: 32),
                    Text(timeStr, style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 64),
                    const Text('Type "I can wait" to cancel early', style: TextStyle(color: AppTheme.textTertiary)),
                    const SizedBox(height: 8),
                    TextField(
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppTheme.surface,
                        hintText: 'Type the phrase...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      onChanged: (val) {
                        if (val.trim().toLowerCase() == 'i can wait') {
                          Navigator.pop(context);
                          _deactivateEmergency();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.bgPrimary.withOpacity(0.8),
        elevation: 0,
        centerTitle: false,
        title: ShaderMask(
          shaderCallback: (bounds) => AppTheme.gradientMixed.createShader(bounds),
          child: const Text('DigiTox', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_outline, color: AppTheme.textSecondary),
            onPressed: _showEmergencySetup,
            tooltip: 'Emergency Lock',
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppTheme.border, height: 1),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          DashboardScreen(
            onStartFocus: () => setState(() => _currentIndex = 1),
            onEmergencyLock: _showEmergencySetup,
          ),
          const FocusScreen(),
          const InsightsScreen(),
          const HabitsScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.border, width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
          backgroundColor: AppTheme.bgPrimary,
          indicatorColor: AppTheme.primary.withOpacity(0.2),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
            NavigationDestination(icon: Icon(Icons.filter_center_focus), selectedIcon: Icon(Icons.filter_center_focus), label: 'Focus'),
            NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: 'Insights'),
            NavigationDestination(icon: Icon(Icons.check_circle_outline), selectedIcon: Icon(Icons.check_circle), label: 'Habits'),
          ],
        ),
      ),
    );
  }
}
