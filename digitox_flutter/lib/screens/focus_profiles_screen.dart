import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/database.dart';
import 'focus_app_selector.dart';

class FocusProfilesScreen extends StatefulWidget {
  final String currentProfile;
  final ValueChanged<String> onProfileSelected;

  const FocusProfilesScreen({
    super.key,
    required this.currentProfile,
    required this.onProfileSelected,
  });

  @override
  State<FocusProfilesScreen> createState() => _FocusProfilesScreenState();
}

class _FocusProfilesScreenState extends State<FocusProfilesScreen> {
  List<Map<String, dynamic>> _profiles = [];
  bool _loading = true;

  // Preset profiles
  final List<Map<String, String>> _presets = [
    {'id': 'study', 'name': 'Study Mode', 'emoji': '📚'},
    {'id': 'work', 'name': 'Work Mode', 'emoji': '💼'},
    {'id': 'deep_work', 'name': 'Deep Work', 'emoji': '🧠'},
    {'id': 'sleep', 'name': 'Sleep Mode', 'emoji': '🌙'},
    {'id': 'exam', 'name': 'Exam Preparation', 'emoji': '📝'},
  ];

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    _profiles = await DigiToxDatabase().getAllFocusProfiles();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _createProfile(String id, String name, String emoji) async {
    await DigiToxDatabase().insertFocusProfile(id, name, emoji);
    await _loadProfiles();
  }

  Future<void> _deleteProfile(String id) async {
    if (id == 'default') return; // Can't delete default
    await DigiToxDatabase().deleteFocusProfile(id);
    if (widget.currentProfile == id) {
      widget.onProfileSelected('default');
    }
    await _loadProfiles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus Profiles', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.bgPrimary,
        elevation: 0,
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(AppTheme.spaceLg),
            children: [
              const Text('Active Profiles', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: AppTheme.spaceMd),

              ..._profiles.map((profile) {
                final isActive = profile['id'] == widget.currentProfile;
                return Container(
                  margin: const EdgeInsets.only(bottom: AppTheme.spaceSm),
                  child: ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                    tileColor: isActive ? AppTheme.primary.withValues(alpha: 0.15) : AppTheme.surface,
                    leading: Text(profile['emoji'] as String? ?? '🎯', style: const TextStyle(fontSize: 28)),
                    title: Text(profile['name'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: isActive ? const Text('Active', style: TextStyle(color: AppTheme.primaryLight, fontSize: 12)) : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20, color: AppTheme.textSecondary),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => FocusAppSelector(profile: profile['id'] as String)),
                            );
                          },
                          tooltip: 'Edit blocked apps',
                        ),
                        if (profile['id'] != 'default')
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.danger),
                            onPressed: () => _deleteProfile(profile['id'] as String),
                            tooltip: 'Delete profile',
                          ),
                      ],
                    ),
                    onTap: () {
                      widget.onProfileSelected(profile['id'] as String);
                      Navigator.pop(context);
                    },
                  ),
                );
              }),

              const SizedBox(height: AppTheme.spaceLg),
              const Text('Quick Add', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: AppTheme.spaceMd),

              // Show preset profiles that haven't been created yet
              ..._presets
                  .where((p) => !_profiles.any((existing) => existing['id'] == p['id']))
                  .map((preset) {
                return Container(
                  margin: const EdgeInsets.only(bottom: AppTheme.spaceSm),
                  child: ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                    tileColor: AppTheme.surfaceHover,
                    leading: Text(preset['emoji']!, style: const TextStyle(fontSize: 28)),
                    title: Text(preset['name']!, style: const TextStyle(fontWeight: FontWeight.w500)),
                    trailing: const Icon(Icons.add_circle_outline, color: AppTheme.primary),
                    onTap: () => _createProfile(preset['id']!, preset['name']!, preset['emoji']!),
                  ),
                );
              }),
            ],
          ),
    );
  }
}
