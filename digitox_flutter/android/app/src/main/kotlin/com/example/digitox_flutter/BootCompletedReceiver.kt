package com.example.digitox_flutter

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Restores focus enforcement state after device reboot.
 * If a focus session was active before reboot and hasn't expired,
 * the enforcement will resume automatically since the AccessibilityService
 * reads from SharedPreferences on every event.
 *
 * This receiver just ensures the focus_active flag is properly restored
 * and cleans up expired sessions.
 */
class BootCompletedReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return

        val focusPrefs = context.getSharedPreferences("digitox_focus", Context.MODE_PRIVATE)
        val isActive = focusPrefs.getBoolean("focus_active", false)
        val focusEndTime = focusPrefs.getLong("focus_end_time", 0)

        if (isActive) {
            if (System.currentTimeMillis() > focusEndTime) {
                // Focus expired during reboot, clean up
                focusPrefs.edit()
                    .putBoolean("focus_active", false)
                    .putStringSet("blocked_packages", emptySet())
                    .apply()
            }
            // If still within the focus window, enforcement continues automatically
            // because AccessibilityService reads from SharedPreferences
        }

        // Reset daily counters if it's a new day
        val accessPrefs = context.getSharedPreferences("digitox_accessibility", Context.MODE_PRIVATE)
        val lastResetDate = accessPrefs.getString("last_reset_date", "") ?: ""
        val today = java.text.SimpleDateFormat("yyyy-MM-dd", java.util.Locale.US).format(java.util.Date())

        if (lastResetDate != today) {
            accessPrefs.edit()
                .putInt("app_switch_count_today", 0)
                .putInt("rapid_switch_count_today", 0)
                .putString("event_log", "")
                .putString("last_reset_date", today)
                .apply()

            focusPrefs.edit()
                .putInt("blocked_attempts_today", 0)
                .putInt("override_count_today", 0)
                .putInt("rapid_block_attempts", 0)
                .apply()
        }
    }
}
