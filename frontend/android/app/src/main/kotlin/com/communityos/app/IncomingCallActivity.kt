package com.communityos.app

import android.app.Activity
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.view.Gravity
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

/**
 * Native (non-Flutter) full-screen call UI - shown via a full-screen-intent
 * notification when an incoming-call push arrives and the app isn't already
 * in the foreground. Deliberately not a Flutter screen: this needs to appear
 * instantly over the lock screen without waiting on a Flutter engine to boot.
 * Decline is handled entirely here; Accept hands off to MainActivity (see
 * CallConnection.onAnswer) since actually joining the call needs the real
 * app - its socket, WebRTC stack, session.
 */
class IncomingCallActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                    WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
            )
        }

        val fromName = intent.getStringExtra(CallConnection.EXTRA_FROM_NAME) ?: "Someone"

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(Color.parseColor("#0B2447"))
            setPadding(48, 48, 48, 48)
        }

        root.addView(
            TextView(this).apply {
                text = "Incoming NIKAT call"
                setTextColor(Color.WHITE)
                textSize = 16f
                gravity = Gravity.CENTER
            },
        )
        root.addView(
            TextView(this).apply {
                text = fromName
                setTextColor(Color.WHITE)
                textSize = 28f
                gravity = Gravity.CENTER
                setPadding(0, 24, 0, 96)
            },
        )

        val buttonRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
        }
        buttonRow.addView(
            Button(this).apply {
                text = "Decline"
                setBackgroundColor(Color.parseColor("#C62828"))
                setTextColor(Color.WHITE)
                setOnClickListener { decline() }
            },
            LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f).apply {
                marginEnd = 24
            },
        )
        buttonRow.addView(
            Button(this).apply {
                text = "Accept"
                setBackgroundColor(Color.parseColor("#2E7D32"))
                setTextColor(Color.WHITE)
                setOnClickListener { accept() }
            },
            LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f),
        )
        root.addView(buttonRow)

        setContentView(root)
    }

    private fun accept() {
        dismissNotification()
        TelecomHelper.activeConnection?.onAnswer()
        finish()
    }

    private fun dismissNotification() {
        val callId = intent.getStringExtra(CallConnection.EXTRA_CALL_ID) ?: return
        IncomingCallHandler.dismissNotification(applicationContext, callId)
    }

    private fun decline() {
        dismissNotification()
        TelecomHelper.activeConnection?.onReject()
        finish()
    }
}
