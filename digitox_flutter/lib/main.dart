import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'data/data_provider.dart';
import 'utils/storage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DigiToxApp());
}

class DigiToxApp extends StatelessWidget {
  const DigiToxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DigiTox',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AppBootstrap(),
    );
  }
}

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  bool _loading = true;
  bool _onboardingComplete = false;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final complete = await Storage.load('digitox_onboarding_complete', fallback: false);
    setState(() {
      _onboardingComplete = complete == true;
      _loading = false;
    });
  }

  void _onOnboardingDone() async {
    // Initialize the data provider after permissions are granted
    await DataProvider().initialize();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const SplashScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0a0a0f),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_onboardingComplete) {
      return OnboardingScreen(onComplete: _onOnboardingDone);
    }

    return const SplashScreen();
  }
}
