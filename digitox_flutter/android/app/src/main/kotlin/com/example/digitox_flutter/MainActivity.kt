package com.example.digitox_flutter

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.app.usage.UsageEvents
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.text.TextUtils
import android.app.KeyguardManager

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.digitox/device_intelligence"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {

                "checkUsagePermission" -> {
                    result.success(hasUsagePermission())
                }

                "openUsageAccessSettings" -> {
                    startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                    result.success(true)
                }

                "checkAccessibilityPermission" -> {
                    result.success(isAccessibilityServiceEnabled())
                }

                "openAccessibilitySettings" -> {
                    startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                    result.success(true)
                }

                "checkBatteryOptimization" -> {
                    val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                    result.success(pm.isIgnoringBatteryOptimizations(packageName))
                }

                "requestBatteryOptimizationExemption" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                        intent.data = Uri.parse("package:$packageName")
                        startActivity(intent)
                    }
                    result.success(true)
                }

                "getUsageStats" -> {
                    val startMs = call.argument<Long>("startMs") ?: 0L
                    val endMs = call.argument<Long>("endMs") ?: System.currentTimeMillis()
                    result.success(queryUsageStats(startMs, endMs))
                }

                "getUsageEvents" -> {
                    val startMs = call.argument<Long>("startMs") ?: 0L
                    val endMs = call.argument<Long>("endMs") ?: System.currentTimeMillis()
                    result.success(queryUsageEvents(startMs, endMs))
                }

                "getInstalledApps" -> {
                    result.success(getInstalledApps())
                }

                "getScreenStats" -> {
                    result.success(getScreenStats())
                }

                "getAccessibilityData" -> {
                    result.success(getAccessibilityData())
                }

                "resetDailyAccessibilityCounters" -> {
                    val prefs = getSharedPreferences("digitox_accessibility", MODE_PRIVATE)
                    prefs.edit()
                        .putInt("app_switch_count_today", 0)
                        .putInt("rapid_switch_count_today", 0)
                        .putString("event_log", "")
                        .apply()
                    result.success(true)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun hasUsagePermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val serviceName = "$packageName/.DigiToxAccessibilityService"
        val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        val colonSplitter = TextUtils.SimpleStringSplitter(':')
        colonSplitter.setString(enabledServices)
        while (colonSplitter.hasNext()) {
            val componentName = colonSplitter.next()
            if (componentName.equals(serviceName, ignoreCase = true)) {
                return true
            }
        }
        return false
    }

    private fun queryUsageStats(startMs: Long, endMs: Long): List<Map<String, Any?>> {
        if (!hasUsagePermission()) return emptyList()

        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, startMs, endMs)

        return stats
            .filter { it.totalTimeInForeground > 0 }
            .map { stat ->
                mapOf(
                    "packageName" to stat.packageName,
                    "totalTimeMs" to stat.totalTimeInForeground,
                    "lastTimeUsed" to stat.lastTimeUsed,
                    "firstTimeStamp" to stat.firstTimeStamp,
                    "lastTimeStamp" to stat.lastTimeStamp
                )
            }
    }

    private fun queryUsageEvents(startMs: Long, endMs: Long): List<Map<String, Any?>> {
        if (!hasUsagePermission()) return emptyList()

        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val events = usm.queryEvents(startMs, endMs)
        val eventList = mutableListOf<Map<String, Any?>>()
        val event = UsageEvents.Event()

        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            if (event.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND ||
                event.eventType == UsageEvents.Event.MOVE_TO_BACKGROUND) {
                eventList.add(mapOf(
                    "packageName" to event.packageName,
                    "eventType" to event.eventType,
                    "timestamp" to event.timeStamp
                ))
            }
        }
        return eventList
    }

    private fun getInstalledApps(): List<Map<String, Any?>> {
        val pm = packageManager
        val intent = Intent(Intent.ACTION_MAIN, null).apply {
            addCategory(Intent.CATEGORY_LAUNCHER)
        }
        val apps = pm.queryIntentActivities(intent, 0)

        return apps.map { resolveInfo ->
            val appInfo = resolveInfo.activityInfo.applicationInfo
            val appName = pm.getApplicationLabel(appInfo).toString()
            val pkgName = appInfo.packageName

            // Get category from system
            val category = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                appInfo.category
            } else {
                ApplicationInfo.CATEGORY_UNDEFINED
            }

            mapOf(
                "packageName" to pkgName,
                "appName" to appName,
                "category" to category,
                "isSystemApp" to ((appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0)
            )
        }.sortedBy { it["appName"] as String }
    }

    private fun getScreenStats(): Map<String, Any> {
        val km = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager

        return mapOf(
            "isScreenOn" to pm.isInteractive,
            "isDeviceLocked" to km.isDeviceLocked,
            "currentTimeMs" to System.currentTimeMillis()
        )
    }

    private fun getAccessibilityData(): Map<String, Any?> {
        val prefs = getSharedPreferences("digitox_accessibility", MODE_PRIVATE)
        return mapOf(
            "currentForegroundApp" to prefs.getString("current_foreground_app", ""),
            "currentForegroundTimestamp" to prefs.getLong("current_foreground_timestamp", 0),
            "appSwitchCountToday" to prefs.getInt("app_switch_count_today", 0),
            "rapidSwitchCountToday" to prefs.getInt("rapid_switch_count_today", 0),
            "eventLog" to prefs.getString("event_log", "")
        )
    }
}
