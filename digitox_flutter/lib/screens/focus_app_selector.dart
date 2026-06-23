import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/installed_apps_repository.dart';
import '../data/database.dart';
import '../data/app_classifier.dart';

class FocusAppSelector extends StatefulWidget {
  final String profile;
  const FocusAppSelector({super.key, this.profile = 'default'});

  @override
  State<FocusAppSelector> createState() => _FocusAppSelectorState();
}

class _FocusAppSelectorState extends State<FocusAppSelector> {
  List<InstalledApp> _allApps = [];
  List<InstalledApp> _filteredApps = [];
  Map<String, bool> _blockedMap = {};
  String _searchQuery = '';
  String _selectedCategory = 'all';
  bool _loading = true;

  final List<Map<String, String>> _categories = [
    {'id': 'all', 'label': 'All Apps', 'emoji': '📱'},
    {'id': 'social_media', 'label': 'Social', 'emoji': '📸'},
    {'id': 'streaming', 'label': 'Streaming', 'emoji': '🎬'},
    {'id': 'messaging', 'label': 'Messaging', 'emoji': '💬'},
    {'id': 'gaming', 'label': 'Gaming', 'emoji': '🎮'},
    {'id': 'productive', 'label': 'Productivity', 'emoji': '💼'},
    {'id': 'education', 'label': 'Education', 'emoji': '📚'},
    {'id': 'browser', 'label': 'Browser', 'emoji': '🌐'},
    {'id': 'shopping', 'label': 'Shopping', 'emoji': '🛒'},
    {'id': 'finance', 'label': 'Finance', 'emoji': '💰'},
    {'id': 'health', 'label': 'Health', 'emoji': '🏃'},
    {'id': 'utility', 'label': 'Utilities', 'emoji': '🔧'},
    {'id': 'unknown', 'label': 'Other', 'emoji': '📦'},
  ];

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    _allApps = await InstalledAppsRepository().loadApps();
    _blockedMap = await DigiToxDatabase().getBlockedAppsMap(profile: widget.profile);
    _applyFilter();
    if (mounted) setState(() => _loading = false);
  }

  void _applyFilter() {
    _filteredApps = InstalledAppsRepository().searchAndFilter(_searchQuery, _selectedCategory);
  }

  Future<void> _toggleBlock(InstalledApp app, bool blocked) async {
    setState(() => _blockedMap[app.packageName] = blocked);
    await DigiToxDatabase().upsertBlockedApp(app.packageName, app.appName, blocked, profile: widget.profile);
  }

  Future<void> _blockAllAddictive() async {
    for (final app in _allApps) {
      if (AppClassifier.isAddictive(app.category)) {
        setState(() => _blockedMap[app.packageName] = true);
        await DigiToxDatabase().upsertBlockedApp(app.packageName, app.appName, true, profile: widget.profile);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final blockedCount = _blockedMap.values.where((v) => v).length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Select Apps to Block ($blockedCount)', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.bgPrimary,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _blockAllAddictive,
            icon: const Icon(Icons.select_all, size: 18),
            label: const Text('Block Addictive', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(AppTheme.spaceMd),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search apps...',
                    prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                    filled: true,
                    fillColor: AppTheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                      _applyFilter();
                    });
                  },
                ),
              ),

              // Category chips
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = cat['id'] == _selectedCategory;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('${cat['emoji']} ${cat['label']}'),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = cat['id']!;
                            _applyFilter();
                          });
                        },
                        selectedColor: AppTheme.primary,
                        backgroundColor: AppTheme.surfaceHover,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppTheme.spaceSm),

              // App count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
                child: Row(
                  children: [
                    Text(
                      '${_filteredApps.length} apps found',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spaceSm),

              // App list
              Expanded(
                child: ListView.builder(
                  itemCount: _filteredApps.length,
                  itemBuilder: (context, index) {
                    final app = _filteredApps[index];
                    final isBlocked = _blockedMap[app.packageName] ?? false;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd, vertical: 3),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isBlocked ? AppTheme.danger.withValues(alpha: 0.08) : AppTheme.surface,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(
                          color: isBlocked ? AppTheme.danger.withValues(alpha: 0.3) : AppTheme.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Real app icon
                          _buildAppIcon(app.iconBytes),
                          const SizedBox(width: 12),
                          // App name + category
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(app.appName, style: const TextStyle(fontWeight: FontWeight.w500)),
                                const SizedBox(height: 2),
                                Text(
                                  AppClassifier.categoryDisplayName(app.category),
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          // Block toggle
                          Switch(
                            value: isBlocked,
                            activeColor: AppTheme.danger,
                            onChanged: (val) => _toggleBlock(app, val),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildAppIcon(Uint8List? iconBytes) {
    if (iconBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.memory(iconBytes, width: 40, height: 40, gaplessPlayback: true),
      );
    }
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.android, color: AppTheme.textSecondary, size: 24),
    );
  }
}
