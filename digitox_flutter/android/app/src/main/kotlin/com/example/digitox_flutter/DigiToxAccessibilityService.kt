package com.example.digitox_flutter

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.view.accessibility.AccessibilityEvent
import android.content.SharedPreferences

class DigiToxAccessibilityService : AccessibilityService() {

    private var lastPackage: String = ""
    private var lastTimestamp: Long = 0
    private lateinit var prefs: SharedPreferences

    override fun onServiceConnected() {
        super.onServiceConnected()
        prefs = getSharedPreferences("digitox_accessibility", MODE_PRIVATE)
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

        // Only log if different app or more than 2 seconds since last event
        if (packageName != lastPackage || (timestamp - lastTimestamp) > 2000) {
            // Store the event
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

    override fun onInterrupt() {
        // Required override
    }

    override fun onDestroy() {
        super.onDestroy()
    }
}
