package com.example.digitox_flutter

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.view.accessibility.AccessibilityEvent
import android.content.SharedPreferences

class DigiToxAccessibilityService : AccessibilityService() {

    private var lastPackage: String = ""
    private var lastTimestamp: Long = 0
    private lateinit var prefs: SharedPreferences
    private lateinit var focusPrefs: SharedPreferences

    // Anti-circumvention tracking
    private var rapidBlockAttempts = 0
    private var lastBlockTimestamp: Long = 0

    override fun onServiceConnected() {
        super.onServiceConnected()
        prefs = getSharedPreferences("digitox_accessibility", MODE_PRIVATE)
        focusPrefs = getSharedPreferences("digitox_focus", MODE_PRIVATE)
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return

        val packageName = event.packageName?.toString() ?: return
        val timestamp = System.currentTimeMillis()

        // Ignore system UI, launchers, and our own app
        if (packageName == "com.android.systemui" ||
            packageName == "com.android.launcher" ||
            packageName == "com.android.launcher3" ||
            packageName == "com.google.android.apps.nexuslauncher" ||
            packageName == "com.example.digitox_flutter") {
            return
        }

        // ═══════════════════════════════════════
        // FOCUS MODE ENFORCEMENT
        // ═══════════════════════════════════════
        val isFocusActive = focusPrefs.getBoolean("focus_active", false)
        val focusEndTime = focusPrefs.getLong("focus_end_time", 0)

        if (isFocusActive && timestamp < focusEndTime) {
            val blockedPackages = focusPrefs.getStringSet("blocked_packages", emptySet()) ?: emptySet()

            if (blockedPackages.contains(packageName)) {
                // Track blocked attempt
                val attempts = focusPrefs.getInt("blocked_attempts_today", 0)
                focusPrefs.edit()
                    .putInt("blocked_attempts_today", attempts + 1)
                    .putString("most_attempted_app", packageName)
                    .apply()

                // Anti-circumvention: track rapid attempts
                if (timestamp - lastBlockTimestamp < 5000) {
                    rapidBlockAttempts++
                    focusPrefs.edit()
                        .putInt("rapid_block_attempts", rapidBlockAttempts)
                        .apply()
                } else {
                    rapidBlockAttempts = 0
                }
                lastBlockTimestamp = timestamp

                // Check if this app has a temporary override
                val overrideEndTime = focusPrefs.getLong("override_end_${packageName}", 0)
                if (timestamp < overrideEndTime) {
                    // Override is active, allow the app
                } else {
                    // BLOCK: Launch intervention screen
                    launchInterventionScreen(packageName)
                    return // Don't log this as normal activity
                }
            }
        } else if (isFocusActive && timestamp >= focusEndTime) {
            // Focus expired, clean up
            focusPrefs.edit().putBoolean("focus_active", false).apply()
        }

        // ═══════════════════════════════════════
        // NORMAL TRACKING (existing behavior)
        // ═══════════════════════════════════════
        if (packageName != lastPackage || (timestamp - lastTimestamp) > 2000) {
            val editor = prefs.edit()

            // Current foreground app
            editor.putString("current_foreground_app", packageName)
            editor.putLong("current_foreground_timestamp", timestamp)

            // Track app switch count for dopamine scoring
            if (packageName != lastPackage && lastPackage.isNotEmpty()) {
                val switchCount = prefs.getInt("app_switch_count_today", 0)
                editor.putInt("app_switch_count_today", switchCount + 1)

                // Track rapid switches (within 30 seconds)
                if ((timestamp - lastTimestamp) < 30000 && lastPackage.isNotEmpty()) {
                    val rapidSwitches = prefs.getInt("rapid_switch_count_today", 0)
                    editor.putInt("rapid_switch_count_today", rapidSwitches + 1)
                }
            }

            // Append to event log (JSON lines format, capped at 500 events)
            val eventLog = prefs.getString("event_log", "") ?: ""
            val lines = eventLog.split("\n").filter { it.isNotEmpty() }
            val cappedLines = if (lines.size > 498) lines.takeLast(498) else lines
            val newEvent = "{\"pkg\":\"$packageName\",\"ts\":$timestamp,\"prev\":\"$lastPackage\"}"
            val updatedLog = (cappedLines + newEvent).joinToString("\n")
            editor.putString("event_log", updatedLog)

            editor.apply()

            lastPackage = packageName
            lastTimestamp = timestamp
        }
    }

    private fun launchInterventionScreen(blockedPackage: String) {
        val focusEndTime = focusPrefs.getLong("focus_end_time", 0)
        val remainingMs = (focusEndTime - System.currentTimeMillis()).coerceAtLeast(0)
        val remainingMinutes = (remainingMs / 60000).toInt()

        // Get app name for display
        val appName = try {
            val pm = packageManager
            val appInfo = pm.getApplicationInfo(blockedPackage, 0)
            pm.getApplicationLabel(appInfo).toString()
        } catch (e: Exception) {
            blockedPackage.split(".").last()
        }

        val intent = Intent(this, InterventionActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            addFlags(Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS)
            putExtra("blocked_package", blockedPackage)
            putExtra("blocked_app_name", appName)
            putExtra("remaining_minutes", remainingMinutes)
        }
        startActivity(intent)
    }

    override fun onInterrupt() {
        // Required override
    }

    override fun onDestroy() {
        super.onDestroy()
    }
}
