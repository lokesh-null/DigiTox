import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/ai_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadKey();
  }

  Future<void> _loadKey() async {
    final key = await AIService().getApiKey();
    if (key != null) {
      _apiKeyController.text = key;
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveKey() async {
    await AIService().setApiKey(_apiKeyController.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('API Key saved securely.'), backgroundColor: AppTheme.primary),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.bgPrimary,
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(AppTheme.spaceLg),
            children: [
              const Text('AI Coach Configuration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryLight)),
              const SizedBox(height: AppTheme.spaceMd),
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceMd),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceHover,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.smart_toy, color: AppTheme.secondary),
                        SizedBox(width: 8),
                        Text('Google Gemini API Key', style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spaceMd),
                    const Text(
                      'DigiTox uses the Gemini API to power the Real AI Coach, daily briefings, and psychological reports. Your key is stored securely on your device.',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: AppTheme.spaceMd),
                    TextField(
                      controller: _apiKeyController,
                      decoration: InputDecoration(
                        hintText: 'Paste your API key here',
                        filled: true,
                        fillColor: AppTheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: AppTheme.spaceMd),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveKey,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Save Key', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
    );
  }
}
