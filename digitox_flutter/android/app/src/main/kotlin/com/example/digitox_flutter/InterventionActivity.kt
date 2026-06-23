package com.example.digitox_flutter

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.os.CountDownTimer
import android.view.View
import android.view.WindowManager
import android.widget.*
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.view.Gravity

class InterventionActivity : Activity() {

    private var blockedPackage: String = ""
    private var blockedAppName: String = ""
    private var remainingMinutes: Int = 0
    private var overrideTimer: CountDownTimer? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Make it look like a full blocking screen
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        window.statusBarColor = Color.parseColor("#0D0D1A")
        window.navigationBarColor = Color.parseColor("#0D0D1A")

        blockedPackage = intent.getStringExtra("blocked_package") ?: ""
        blockedAppName = intent.getStringExtra("blocked_app_name") ?: "App"
        remainingMinutes = intent.getIntExtra("remaining_minutes", 0)

        buildUI()
    }

    private fun buildUI() {
        val bgColor = Color.parseColor("#0D0D1A")
        val primaryColor = Color.parseColor("#6C5CE7")
        val dangerColor = Color.parseColor("#FF6B6B")
        val surfaceColor = Color.parseColor("#1A1A2E")
        val textSecondary = Color.parseColor("#8B8BA3")

        // Root layout
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(bgColor)
            setPadding(64, 80, 64, 80)
        }

        // Block icon
        val blockIcon = TextView(this).apply {
            text = "🚫"
            textSize = 64f
            gravity = Gravity.CENTER
        }
        root.addView(blockIcon)

        // Spacer
        root.addView(View(this).apply {
            layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 32)
        })

        // Title
        val title = TextView(this).apply {
            text = "Blocked During Focus Mode"
            textSize = 24f
            setTextColor(Color.WHITE)
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
        }
        root.addView(title)

        // Spacer
        root.addView(View(this).apply {
            layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 24)
        })

        // App name card
        val appCard = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(32, 24, 32, 24)
            background = GradientDrawable().apply {
                setColor(surfaceColor)
                cornerRadius = 24f
                setStroke(2, dangerColor)
            }
        }
        val appNameText = TextView(this).apply {
            text = "$blockedAppName is blocked."
            textSize = 18f
            setTextColor(dangerColor)
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
        }
        appCard.addView(appNameText)
        root.addView(appCard, LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        ).apply { setMargins(0, 0, 0, 24) })

        // Commitment message
        val commitment = TextView(this).apply {
            text = "You committed to focused work.\n${remainingMinutes} minutes remaining."
            textSize = 15f
            setTextColor(textSecondary)
            gravity = Gravity.CENTER
            setLineSpacing(8f, 1f)
        }
        root.addView(commitment)

        // Motivational message
        root.addView(View(this).apply {
            layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 32)
        })
        val motivation = TextView(this).apply {
            val messages = listOf(
                "\"The ability to focus is a superpower in a world designed to distract you.\"",
                "\"Every moment of deep work compounds into extraordinary results.\"",
                "\"Discipline is choosing between what you want now and what you want most.\"",
                "\"Your future self will thank you for this moment of resistance.\"",
                "\"The craving fades in 10 minutes. The regret lasts hours.\""
            )
            text = messages.random()
            textSize = 13f
            setTextColor(primaryColor)
            gravity = Gravity.CENTER
            setTypeface(null, Typeface.ITALIC)
        }
        root.addView(motivation)

        // Spacer
        root.addView(View(this).apply {
            layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 48)
        })

        // Return to Focus button
        val returnButton = Button(this).apply {
            text = "✅  Return to Focus"
            textSize = 16f
            setTextColor(Color.WHITE)
            typeface = Typeface.DEFAULT_BOLD
            isAllCaps = false
            background = GradientDrawable().apply {
                setColor(primaryColor)
                cornerRadius = 64f
            }
            setPadding(48, 24, 48, 24)
            setOnClickListener {
                goToHome()
            }
        }
        root.addView(returnButton, LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        ).apply { setMargins(0, 0, 0, 16) })

        // Emergency Override button
        val overrideButton = Button(this).apply {
            text = "⚠️  Emergency Override"
            textSize = 14f
            setTextColor(textSecondary)
            isAllCaps = false
            background = GradientDrawable().apply {
                setColor(Color.TRANSPARENT)
                cornerRadius = 64f
                setStroke(2, Color.parseColor("#333355"))
            }
            setPadding(48, 20, 48, 20)
            setOnClickListener {
                showOverrideDialog()
            }
        }
        root.addView(overrideButton, LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        ))

        setContentView(root)
    }

    private fun showOverrideDialog() {
        val bgColor = Color.parseColor("#1A1A2E")
        val primaryColor = Color.parseColor("#6C5CE7")
        val textSecondary = Color.parseColor("#8B8BA3")

        val dialogRoot = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(48, 48, 48, 48)
            background = GradientDrawable().apply {
                setColor(bgColor)
                cornerRadius = 24f
            }
        }

        // Title
        dialogRoot.addView(TextView(this).apply {
            text = "Why do you need this app?"
            textSize = 18f
            setTextColor(Color.WHITE)
            typeface = Typeface.DEFAULT_BOLD
        })

        dialogRoot.addView(View(this).apply {
            layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 16)
        })

        // Reason selector
        val reasons = listOf("Work", "Education", "Communication", "Emergency", "Other")
        var selectedReason = "Work"
        val reasonGroup = RadioGroup(this).apply {
            orientation = RadioGroup.VERTICAL
        }
        reasons.forEachIndexed { index, reason ->
            val rb = RadioButton(this).apply {
                text = reason
                setTextColor(Color.WHITE)
                id = index
                if (index == 0) isChecked = true
            }
            reasonGroup.addView(rb)
        }
        reasonGroup.setOnCheckedChangeListener { _, checkedId ->
            selectedReason = reasons[checkedId]
        }
        dialogRoot.addView(reasonGroup)

        dialogRoot.addView(View(this).apply {
            layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 16)
        })

        // Duration selector
        dialogRoot.addView(TextView(this).apply {
            text = "Allow access for:"
            textSize = 14f
            setTextColor(textSecondary)
        })

        dialogRoot.addView(View(this).apply {
            layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 8)
        })

        val durations = listOf(1, 5, 10)
        var selectedDuration = 1
        val durationGroup = RadioGroup(this).apply {
            orientation = RadioGroup.HORIZONTAL
        }
        durations.forEachIndexed { index, mins ->
            val rb = RadioButton(this).apply {
                text = "${mins} min"
                setTextColor(Color.WHITE)
                id = 100 + index
                if (index == 0) isChecked = true
            }
            durationGroup.addView(rb)
        }
        durationGroup.setOnCheckedChangeListener { _, checkedId ->
            selectedDuration = durations[checkedId - 100]
        }
        dialogRoot.addView(durationGroup)

        dialogRoot.addView(View(this).apply {
            layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 24)
        })

        // Buttons
        val buttonRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.END
        }

        buttonRow.addView(Button(this).apply {
            text = "Cancel"
            setTextColor(textSecondary)
            setBackgroundColor(Color.TRANSPARENT)
            isAllCaps = false
            setOnClickListener {
                // Remove the dialog and stay on intervention
                buildUI()
            }
        })

        buttonRow.addView(Button(this).apply {
            text = "Allow"
            setTextColor(primaryColor)
            setBackgroundColor(Color.TRANSPARENT)
            isAllCaps = false
            typeface = Typeface.DEFAULT_BOLD
            setOnClickListener {
                grantOverride(selectedReason, selectedDuration)
            }
        })

        dialogRoot.addView(buttonRow)
        setContentView(dialogRoot)
    }

    private fun grantOverride(reason: String, durationMinutes: Int) {
        val focusPrefs = getSharedPreferences("digitox_focus", MODE_PRIVATE)
        val overrideEndTime = System.currentTimeMillis() + (durationMinutes * 60 * 1000L)

        // Grant temporary override for this specific package
        focusPrefs.edit()
            .putLong("override_end_$blockedPackage", overrideEndTime)
            .putInt("override_count_today", focusPrefs.getInt("override_count_today", 0) + 1)
            .putString("last_override_reason", reason)
            .apply()

        // Finish this activity to let the user use their app
        finish()
    }

    private fun goToHome() {
        val homeIntent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_HOME)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        startActivity(homeIntent)
        finish()
    }

    override fun onBackPressed() {
        // Go home instead of going back to the blocked app
        goToHome()
    }
}
