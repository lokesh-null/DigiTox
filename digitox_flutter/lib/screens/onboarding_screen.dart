import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/device_intelligence.dart';
import '../utils/storage.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 0;
  bool _usageGranted = false;
  bool _accessibilityGranted = false;
  bool _batteryGranted = false;

  final List<_PermissionStep> _steps = [
    _PermissionStep(
      title: 'Welcome to DigiTox',
      description: 'DigiTox is your personal digital wellbeing coach. To provide real insights about your screen habits, we need a few permissions.\n\nYour data never leaves your device.',
      emoji: '🛡️',
      isIntro: true,
    ),
    _PermissionStep(
      title: 'Usage Access',
      description: 'This allows DigiTox to see which apps you use and for how long. Without this, we can\'t show you real screen time data.\n\nThis is the core permission that powers everything.',
      emoji: '📊',
      permissionType: 'usage',
    ),
    _PermissionStep(
      title: 'Accessibility Service',
      description: 'This lets DigiTox detect which app you\'re currently using in real-time. It enables live tracking, app-switch detection, and smart interventions.\n\nWe never read your screen content.',
      emoji: '👁️',
      permissionType: 'accessibility',
    ),
    _PermissionStep(
      title: 'Battery Optimization',
      description: 'Exempting DigiTox from battery optimization ensures your screen time tracking runs accurately in the background without being killed by the system.',
      emoji: '🔋',
      permissionType: 'battery',
    ),
    _PermissionStep(
      title: 'You\'re All Set!',
      description: 'DigiTox is now ready to help you take control of your digital life. Your real usage data will start flowing in immediately.\n\nLet\'s begin your journey.',
      emoji: '🎉',
      isComplete: true,
    ),
  ];

  Future<void> _checkPermissions() async {
    _usageGranted = await DeviceIntelligence.hasUsagePermission();
    _accessibilityGranted = await DeviceIntelligence.hasAccessibilityPermission();
    _batteryGranted = await DeviceIntelligence.hasBatteryOptimizationExemption();
    setState(() {});
  }

  Future<void> _requestPermission(String type) async {
    switch (type) {
      case 'usage':
        await DeviceIntelligence.openUsageAccessSettings();
        break;
      case 'accessibility':
        await DeviceIntelligence.openAccessibilitySettings();
        break;
      case 'battery':
        await DeviceIntelligence.requestBatteryOptimizationExemption();
        break;
    }

    // Wait a moment for user to return, then re-check
    await Future.delayed(const Duration(milliseconds: 500));
    await _checkPermissions();
  }

  bool _isCurrentStepGranted() {
    final step = _steps[_currentStep];
    if (step.isIntro || step.isComplete) return true;
    switch (step.permissionType) {
      case 'usage': return _usageGranted;
      case 'accessibility': return _accessibilityGranted;
      case 'battery': return _batteryGranted;
      default: return true;
    }
  }

  void _next() {
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    await Storage.save('digitox_onboarding_complete', true);
    widget.onComplete();
  }

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];
    final isGranted = _isCurrentStepGranted();

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceLg),
          child: Column(
            children: [
              // Progress dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_steps.length, (i) {
                  return Container(
                    width: i == _currentStep ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: i == _currentStep
                          ? AppTheme.primary
                          : i < _currentStep
                              ? AppTheme.secondary
                              : AppTheme.surfaceActive,
                    ),
                  );
                }),
              ),
              const Spacer(),

              // Emoji
              Text(step.emoji, style: const TextStyle(fontSize: 72)),
              const SizedBox(height: AppTheme.spaceXl),

              // Title
              Text(
                step.title,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 28),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spaceLg),

              // Description
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
                child: Text(
                  step.description,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15, height: 1.6),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: AppTheme.spaceXl),

              // Permission status indicator
              if (!step.isIntro && !step.isComplete)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg, vertical: AppTheme.spaceMd),
                  decoration: BoxDecoration(
                    color: isGranted
                        ? AppTheme.success.withValues(alpha: 0.1)
                        : AppTheme.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: isGranted
                          ? AppTheme.success.withValues(alpha: 0.3)
                          : AppTheme.warning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isGranted ? Icons.check_circle : Icons.warning_amber_rounded,
                        color: isGranted ? AppTheme.success : AppTheme.warning,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isGranted ? 'Permission Granted' : 'Permission Required',
                        style: TextStyle(
                          color: isGranted ? AppTheme.success : AppTheme.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

              const Spacer(),

              // Action button
              if (!step.isIntro && !step.isComplete && !isGranted)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _requestPermission(step.permissionType!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
                    ),
                    child: const Text('Grant Permission', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),

              if (!step.isIntro && !step.isComplete && !isGranted)
                const SizedBox(height: AppTheme.spaceSm),

              // Continue/Skip buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (step.isIntro || step.isComplete || isGranted) ? null : AppTheme.surface,
                    foregroundColor: (step.isIntro || step.isComplete || isGranted) ? Colors.white : AppTheme.textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
                  ).copyWith(
                    backgroundBuilder: (step.isIntro || step.isComplete || isGranted) ? (context, states, child) {
                      return Container(
                        decoration: const BoxDecoration(
                          gradient: AppTheme.gradientPrimary,
                          borderRadius: BorderRadius.all(Radius.circular(AppTheme.radiusLg)),
                        ),
                        child: child,
                      );
                    } : null,
                  ),
                  child: Text(
                    step.isComplete
                        ? 'Start Using DigiTox'
                        : step.isIntro
                            ? 'Get Started'
                            : isGranted
                                ? 'Continue'
                                : 'Skip for Now',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.spaceMd),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionStep {
  final String title;
  final String description;
  final String emoji;
  final String? permissionType;
  final bool isIntro;
  final bool isComplete;

  _PermissionStep({
    required this.title,
    required this.description,
    required this.emoji,
    this.permissionType,
    this.isIntro = false,
    this.isComplete = false,
  });
}
