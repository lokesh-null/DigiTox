import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Bridge to native Android APIs via MethodChannel.
/// Provides real device usage stats, installed apps, screen stats,
/// and accessibility service data.
class DeviceIntelligence {
  static const _channel = MethodChannel('com.digitox/device_intelligence');

  // === Permission Checks ===

  static Future<bool> hasUsagePermission() async {
    try {
      return await _channel.invokeMethod<bool>('checkUsagePermission') ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<void> openUsageAccessSettings() async {
    await _channel.invokeMethod('openUsageAccessSettings');
  }

  static Future<bool> hasAccessibilityPermission() async {
    try {
      return await _channel.invokeMethod<bool>('checkAccessibilityPermission') ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<void> openAccessibilitySettings() async {
    await _channel.invokeMethod('openAccessibilitySettings');
  }

  static Future<bool> hasBatteryOptimizationExemption() async {
    try {
      return await _channel.invokeMethod<bool>('checkBatteryOptimization') ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<void> requestBatteryOptimizationExemption() async {
    await _channel.invokeMethod('requestBatteryOptimizationExemption');
  }

  // === Usage Stats (from UsageStatsManager) ===

  static Future<List<Map<String, dynamic>>> getUsageStats({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final result = await _channel.invokeMethod<List>('getUsageStats', {
        'startMs': start.millisecondsSinceEpoch,
        'endMs': end.millisecondsSinceEpoch,
      });
      return result?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getUsageEvents({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final result = await _channel.invokeMethod<List>('getUsageEvents', {
        'startMs': start.millisecondsSinceEpoch,
        'endMs': end.millisecondsSinceEpoch,
      });
      return result?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
    } catch (e) {
      return [];
    }
  }

  /// Get today's usage stats
  static Future<List<Map<String, dynamic>>> getTodayUsageStats() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return getUsageStats(start: startOfDay, end: now);
  }

  /// Get usage stats for the last N days
  static Future<List<Map<String, dynamic>>> getUsageStatsForDays(int days) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).subtract(Duration(days: days));
    return getUsageStats(start: start, end: now);
  }

  /// Get today's usage events
  static Future<List<Map<String, dynamic>>> getTodayUsageEvents() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return getUsageEvents(start: startOfDay, end: now);
  }

  // === Installed Apps ===

  static Future<List<Map<String, dynamic>>> getInstalledApps() async {
    try {
      final result = await _channel.invokeMethod<List>('getInstalledApps');
      return result?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
    } catch (e) {
      return [];
    }
  }

  // === Screen Stats ===

  static Future<Map<String, dynamic>> getScreenStats() async {
    try {
      final result = await _channel.invokeMethod<Map>('getScreenStats');
      return result != null ? Map<String, dynamic>.from(result) : {};
    } catch (e) {
      return {};
    }
  }

  // === Accessibility Service Data ===

  static Future<Map<String, dynamic>> getAccessibilityData() async {
    try {
      final result = await _channel.invokeMethod<Map>('getAccessibilityData');
      return result != null ? Map<String, dynamic>.from(result) : {};
    } catch (e) {
      return {};
    }
  }

  static Future<void> resetDailyAccessibilityCounters() async {
    try {
      await _channel.invokeMethod('resetDailyAccessibilityCounters');
    } catch (_) {}
  }

  // === Utility ===

  static String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static String todayString() {
    return formatDate(DateTime.now());
  }
}
