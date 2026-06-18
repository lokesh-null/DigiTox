import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database.dart';
import 'device_intelligence.dart';
import 'app_classifier.dart';

/// Replaces all mock data generators with real device data queries.
/// This is the single source of truth for all screens.
class DataProvider {
  static final DataProvider _instance = DataProvider._internal();
  factory DataProvider() => _instance;
  DataProvider._internal();

  final _db = DigiToxDatabase();
  bool _initialized = false;

  /// Initialize: sync installed apps and classify them, pull usage stats
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await syncInstalledApps();
    await syncUsageData();
  }

  /// Sync installed apps from device and classify them
  Future<void> syncInstalledApps() async {
    try {
      final apps = await DeviceIntelligence.getInstalledApps();
      for (final app in apps) {
        final packageName = app['packageName'] as String;
        final appName = app['appName'] as String;
        final androidCategory = app['category'] as int? ?? -1;

        // Check if user has manually overridden this classification
        final existingCategory = await _db.getAppCategory(packageName);
        if (existingCategory != 'unknown') {
          // Check if user override exists
          final db = await _db.database;
          final rows = await db.query('app_classifications',
            where: 'package_name = ? AND user_override = 1',
            whereArgs: [packageName]
          );
          if (rows.isNotEmpty) continue; // Don't override user classifications
        }

        final category = AppClassifier.classify(packageName, androidCategory: androidCategory);
        await _db.upsertAppClassification(packageName, appName, category);
      }
    } catch (e) {
      // Silently fail — data may not be available yet
    }
  }

  /// Pull real usage data from UsageStatsManager and store in our database
  Future<void> syncUsageData() async {
    try {
      final hasPermission = await DeviceIntelligence.hasUsagePermission();
      if (!hasPermission) return;

      final todayStr = DeviceIntelligence.todayString();
      final stats = await DeviceIntelligence.getTodayUsageStats();
      final classifications = await _db.getAllClassifications();

      for (final stat in stats) {
        final packageName = stat['packageName'] as String;
        final totalTimeMs = stat['totalTimeMs'] as int? ?? 0;
        final totalMinutes = (totalTimeMs / 60000).round();

        if (totalMinutes <= 0) continue;

        // Get app name from our classifications, or use package name
        String appName = packageName.split('.').last;
        String category = 'unknown';

        if (classifications.containsKey(packageName)) {
          category = classifications[packageName]!;
          // Get the real app name
          final db = await _db.database;
          final rows = await db.query('app_classifications',
            where: 'package_name = ?',
            whereArgs: [packageName]
          );
          if (rows.isNotEmpty) {
            appName = rows.first['app_name'] as String;
          }
        } else {
          category = AppClassifier.classify(packageName);
        }

        await _db.upsertAppUsage(
          packageName: packageName,
          appName: appName,
          category: category,
          date: todayStr,
          totalMinutes: totalMinutes,
          openCount: 0, // Will be enriched from events
        );
      }

      // Sync usage events to our database
      final events = await DeviceIntelligence.getTodayUsageEvents();
      for (final event in events) {
        await _db.insertUsageEvent(
          event['packageName'] as String,
          event['eventType'] as int,
          event['timestamp'] as int,
        );
      }

      // Sync accessibility data
      final accessData = await DeviceIntelligence.getAccessibilityData();
      final appSwitchCount = accessData['appSwitchCountToday'] as int? ?? 0;
      final rapidSwitchCount = accessData['rapidSwitchCountToday'] as int? ?? 0;

      // Get or create today's behavioral score
      var score = await _db.getBehavioralScoreForDate(todayStr);
      if (score == null) {
        await _db.upsertBehavioralScore(
          date: todayStr,
          dopamineDebt: 0,
          focusScore: 0,
          relapseRisk: 'low',
          xpTotal: 0,
          identityLevel: 1,
          appSwitchCount: appSwitchCount,
          rapidSwitchCount: rapidSwitchCount,
        );
      }
    } catch (e) {
      // Silently fail
    }
  }

  // === Data Getters (used by screens) ===

  /// Get today's app usage sorted by time spent (replaces generateTodayUsage)
  Future<List<AppUsageInfo>> getTodayUsage() async {
    await syncUsageData(); // Refresh
    final todayStr = DeviceIntelligence.todayString();
    final rows = await _db.getAppUsageForDate(todayStr);

    return rows.map((row) => AppUsageInfo(
      packageName: row['package_name'] as String,
      appName: row['app_name'] as String,
      category: row['category'] as String,
      minutes: row['total_minutes'] as int,
      openCount: row['open_count'] as int,
      emoji: AppClassifier.categoryEmoji(row['category'] as String),
      color: _getCategoryColor(row['category'] as String),
    )).toList();
  }

  /// Get today's stats aggregated by category
  Future<UsageStats> getTodayStats() async {
    final usage = await getTodayUsage();
    int productive = 0, addictive = 0, neutral = 0;

    for (final app in usage) {
      if (AppClassifier.isProductive(app.category)) {
        productive += app.minutes;
      } else if (AppClassifier.isAddictive(app.category)) {
        addictive += app.minutes;
      } else {
        neutral += app.minutes;
      }
    }

    return UsageStats(
      productive: productive,
      addictive: addictive,
      neutral: neutral,
      total: productive + addictive + neutral,
    );
  }

  /// Get weekly data (replaces generateWeeklyData)
  Future<List<DayUsageData>> getWeeklyData() async {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
    final endDate = DateTime(now.year, now.month, now.day);

    final startStr = DeviceIntelligence.formatDate(startDate);
    final endStr = DeviceIntelligence.formatDate(endDate);

    final rows = await _db.getWeeklyAggregates(startStr, endStr);
    final dateFormat = DateFormat('EEE');

    // Build a full 7-day list (filling in zeros for missing days)
    List<DayUsageData> result = [];
    for (int i = 0; i < 7; i++) {
      final date = startDate.add(Duration(days: i));
      final dateStr = DeviceIntelligence.formatDate(date);
      final dayName = dateFormat.format(date);

      final row = rows.where((r) => r['date'] == dateStr).firstOrNull;
      result.add(DayUsageData(
        day: dayName,
        date: dateStr,
        productive: (row?['productive'] as int?) ?? 0,
        addictive: (row?['addictive'] as int?) ?? 0,
        neutral: (row?['neutral'] as int?) ?? 0,
        total: (row?['total'] as int?) ?? 0,
      ));
    }
    return result;
  }

  /// Get hourly heatmap data (replaces generateHeatmapData)
  Future<List<HeatmapEntry>> getHeatmapData() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    final rows = await _db.getHourlyEventCounts(
      startOfDay.millisecondsSinceEpoch,
      now.millisecondsSinceEpoch,
    );

    // Build full 24-hour list
    List<HeatmapEntry> data = [];
    for (int h = 0; h < 24; h++) {
      final row = rows.where((r) => r['hour'] == h).firstOrNull;
      final count = (row?['count'] as int?) ?? 0;

      // Convert count to level (0-4)
      int level;
      if (count == 0) {
        level = 0;
      } else if (count <= 3) {
        level = 1;
      } else if (count <= 8) {
        level = 2;
      } else if (count <= 15) {
        level = 3;
      } else {
        level = 4;
      }

      data.add(HeatmapEntry(hour: h, level: level, count: count));
    }
    return data;
  }

  /// Get contribution data for last 28 days (replaces generateContributionData)
  Future<List<int>> getContributionData() async {
    final now = DateTime.now();
    List<int> data = [];

    for (int i = 27; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DeviceIntelligence.formatDate(date);
      final count = await _db.getHabitCompletionCountForDate(dateStr);

      // Convert to level (0-4)
      int level;
      if (count == 0) {
        level = 0;
      } else if (count <= 1) {
        level = 1;
      } else if (count <= 2) {
        level = 2;
      } else if (count <= 3) {
        level = 3;
      } else {
        level = 4;
      }
      data.add(level);
    }
    return data;
  }

  /// Get weekly grade (replaces getWeeklyGrade)
  Future<Map<String, String>> getWeeklyGrade() async {
    final weeklyData = await getWeeklyData();
    final totalProductive = weeklyData.fold(0, (s, d) => s + d.productive);
    final totalAddictive = weeklyData.fold(0, (s, d) => s + d.addictive);
    final total = totalProductive + totalAddictive;

    if (total == 0) {
      return {'grade': '—', 'title': 'No Data Yet', 'desc': 'Use your device normally and check back later for your grade.'};
    }

    final ratio = totalProductive / total;

    if (ratio >= 0.7) return {'grade': 'A', 'title': 'Excellent Focus!', 'desc': 'You\'re in the top tier of digital discipline.'};
    if (ratio >= 0.55) return {'grade': 'B+', 'title': 'Good Progress', 'desc': 'You\'re trending in the right direction. Keep pushing.'};
    if (ratio >= 0.4) return {'grade': 'B', 'title': 'Room to Grow', 'desc': 'You\'re aware, and that\'s the first step. Let\'s optimize.'};
    if (ratio >= 0.25) return {'grade': 'C', 'title': 'Needs Attention', 'desc': 'Your screen time is outpacing your goals. Try Focus Mode more.'};
    return {'grade': 'D', 'title': 'Time to Reset', 'desc': 'Consider activating Emergency Lock to break the cycle.'};
  }

  /// Get time reality equivalents
  List<Map<String, String>> getTimeRealities(int wastedMinutes) {
    return [
      {'emoji': '📚', 'text': 'You could\'ve read ${(wastedMinutes * 0.33).round()} pages of a book'},
      {'emoji': '🏃', 'text': 'That\'s ${(wastedMinutes / 30).round()} workouts you could have done'},
      {'emoji': '🧠', 'text': '${(wastedMinutes / 25).round()} lessons of a new language'},
      {'emoji': '🎸', 'text': '${(wastedMinutes / 20).round()} practice sessions on an instrument'},
      {'emoji': '📅', 'text': 'This week = ${(wastedMinutes / 60).toStringAsFixed(1)} hours lost to scrolling'},
      {'emoji': '🌍', 'text': 'In a year, that\'s ${(wastedMinutes * 52 / 60 / 24).round()} full days of your life'},
    ];
  }

  /// Get AI suggestions based on real usage patterns
  Future<List<Map<String, String>>> getAISuggestions() async {
    final heatmap = await getHeatmapData();
    final peakHours = heatmap.where((d) => d.level >= 3).map((d) => d.hour).toList();

    List<Map<String, String>> suggestions = [];

    if (peakHours.any((h) => h >= 21)) {
      suggestions.add({
        'icon': '🌙',
        'text': 'You\'re most distracted between 9 PM–12 AM. Try activating Focus Mode at 8:45 PM to build a wind-down routine.'
      });
    }
    if (peakHours.any((h) => h >= 12 && h <= 14)) {
      suggestions.add({
        'icon': '🍽️',
        'text': 'Your lunch break turns into a scroll session. Try a 15-min phone-free lunch challenge.'
      });
    }

    // Find peak productive hour
    final productiveHours = heatmap.where((d) => d.level <= 1 && d.hour >= 6 && d.hour <= 18).map((d) => d.hour).toList();
    if (productiveHours.isNotEmpty) {
      final peakStart = productiveHours.first;
      final peakEnd = productiveHours.length > 2 ? productiveHours[2] : peakStart + 2;
      suggestions.add({
        'icon': '📊',
        'text': 'Your least distracted time is ${peakStart > 12 ? "${peakStart - 12} PM" : "$peakStart AM"} – ${peakEnd > 12 ? "${peakEnd - 12} PM" : "$peakEnd AM"}. Schedule your hardest tasks here.'
      });
    }

    // Usage-based suggestions
    final todayUsage = await getTodayUsage();
    final topAddictive = todayUsage.where((a) => AppClassifier.isAddictive(a.category)).take(1).toList();
    if (topAddictive.isNotEmpty) {
      suggestions.add({
        'icon': '🎯',
        'text': '${topAddictive.first.appName} is your biggest distraction today at ${topAddictive.first.minutes} minutes. Consider setting a daily limit.'
      });
    }

    if (suggestions.isEmpty) {
      suggestions.add({
        'icon': '✨',
        'text': 'Keep using your device normally. AI recommendations will become more accurate as we collect more data.'
      });
    }

    return suggestions;
  }

  /// Get completed focus session count
  Future<int> getCompletedSessionCount() async {
    return _db.getCompletedSessionCount();
  }

  // === Helpers ===

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'social_media': return const Color(0xFFE1306C);
      case 'messaging': return const Color(0xFF25D366);
      case 'gaming': return const Color(0xFF9B59B6);
      case 'streaming': return const Color(0xFFFF0000);
      case 'productive': return const Color(0xFF007ACC);
      case 'education': return const Color(0xFF4CAF50);
      case 'development': return const Color(0xFF00BCD4);
      case 'health': return const Color(0xFF00B894);
      case 'shopping': return const Color(0xFFFF9800);
      case 'finance': return const Color(0xFF2196F3);
      case 'navigation': return const Color(0xFF4285F4);
      case 'browser': return const Color(0xFF607D8B);
      case 'utility': return const Color(0xFF78909C);
      default: return const Color(0xFF9E9E9E);
    }
  }
}

// === Data Classes ===

class AppUsageInfo {
  final String packageName;
  final String appName;
  final String category;
  final int minutes;
  final int openCount;
  final String emoji;
  final Color color;

  AppUsageInfo({
    required this.packageName,
    required this.appName,
    required this.category,
    required this.minutes,
    required this.openCount,
    required this.emoji,
    required this.color,
  });
}

class UsageStats {
  final int productive;
  final int addictive;
  final int neutral;
  final int total;

  UsageStats({required this.productive, required this.addictive, required this.neutral, required this.total});
}

class DayUsageData {
  final String day;
  final String date;
  final int productive;
  final int addictive;
  final int neutral;
  final int total;

  DayUsageData({required this.day, required this.date, required this.productive, required this.addictive, required this.neutral, required this.total});
}

class HeatmapEntry {
  final int hour;
  final int level;
  final int count;

  HeatmapEntry({required this.hour, required this.level, required this.count});
}
