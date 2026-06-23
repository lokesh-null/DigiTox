import 'dart:convert';
import 'dart:typed_data';
import 'device_intelligence.dart';
import 'app_classifier.dart';

/// Repository for real installed apps with icons, classification, and search.
class InstalledAppsRepository {
  static final InstalledAppsRepository _instance = InstalledAppsRepository._internal();
  factory InstalledAppsRepository() => _instance;
  InstalledAppsRepository._internal();

  List<InstalledApp> _apps = [];
  bool _loaded = false;

  /// Load all installed apps from device. Caches result.
  Future<List<InstalledApp>> loadApps({bool forceRefresh = false}) async {
    if (_loaded && !forceRefresh) return _apps;

    final rawApps = await DeviceIntelligence.getInstalledApps();
    _apps = rawApps.map((raw) {
      final packageName = raw['packageName'] as String;
      final appName = raw['appName'] as String;
      final androidCategory = raw['category'] as int? ?? -1;
      final isSystemApp = raw['isSystemApp'] as bool? ?? false;
      final iconBase64 = raw['iconBase64'] as String?;

      // Decode icon
      Uint8List? iconBytes;
      if (iconBase64 != null && iconBase64.isNotEmpty) {
        try {
          iconBytes = base64Decode(iconBase64);
        } catch (_) {}
      }

      // Classify
      final category = AppClassifier.classify(packageName, androidCategory: androidCategory);

      return InstalledApp(
        packageName: packageName,
        appName: appName,
        iconBytes: iconBytes,
        category: category,
        isSystemApp: isSystemApp,
      );
    }).toList();

    // Filter out our own app
    _apps.removeWhere((a) => a.packageName == 'com.example.digitox_flutter');

    _loaded = true;
    return _apps;
  }

  /// Get all loaded apps
  List<InstalledApp> get allApps => _apps;

  /// Search apps by name or package name
  List<InstalledApp> searchApps(String query) {
    if (query.isEmpty) return _apps;
    final lower = query.toLowerCase();
    return _apps.where((app) =>
      app.appName.toLowerCase().contains(lower) ||
      app.packageName.toLowerCase().contains(lower)
    ).toList();
  }

  /// Filter apps by category
  List<InstalledApp> getAppsByCategory(String category) {
    if (category == 'all') return _apps;
    return _apps.where((app) => app.category == category).toList();
  }

  /// Search + filter combined
  List<InstalledApp> searchAndFilter(String query, String category) {
    var results = category == 'all' ? _apps : _apps.where((a) => a.category == category).toList();
    if (query.isNotEmpty) {
      final lower = query.toLowerCase();
      results = results.where((a) =>
        a.appName.toLowerCase().contains(lower) ||
        a.packageName.toLowerCase().contains(lower)
      ).toList();
    }
    return results;
  }

  /// Get a single app by package name
  InstalledApp? getApp(String packageName) {
    try {
      return _apps.firstWhere((a) => a.packageName == packageName);
    } catch (_) {
      return null;
    }
  }
}

/// Represents a real installed application on the device.
class InstalledApp {
  final String packageName;
  final String appName;
  final Uint8List? iconBytes;
  final String category;
  final bool isSystemApp;

  InstalledApp({
    required this.packageName,
    required this.appName,
    this.iconBytes,
    required this.category,
    required this.isSystemApp,
  });
}
