import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageKeys {
  static const habits = 'digitox_habits';
  static const focusSessions = 'digitox_focus_sessions';
  static const streak = 'digitox_streak';
  static const weeklyData = 'digitox_weekly_data';
  static const todayUsage = 'digitox_today_usage';
  static const settings = 'digitox_settings';
  static const lastDate = 'digitox_last_date';
  static const interventionCount = 'digitox_intervention_count';
  static const blockedApps = 'digitox_blocked_apps';
}

class Storage {
  static Future<void> save(String key, dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (data is String) {
        await prefs.setString(key, data);
      } else if (data is int) {
        await prefs.setInt(key, data);
      } else if (data is bool) {
        await prefs.setBool(key, data);
      } else if (data is double) {
        await prefs.setDouble(key, data);
      } else {
        await prefs.setString(key, jsonEncode(data));
      }
    } catch (e) {
      print('Storage save failed: $e');
    }
  }

  static Future<dynamic> load(String key, {dynamic fallback}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey(key)) return fallback;

      final value = prefs.get(key);
      if (value is String) {
        try {
          return jsonDecode(value);
        } catch (_) {
          return value; // It was just a regular string
        }
      }
      return value;
    } catch (e) {
      print('Storage load failed: $e');
      return fallback;
    }
  }

  static Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
