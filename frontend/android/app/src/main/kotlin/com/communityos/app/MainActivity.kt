package com.communityos.app

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.communityos.app/calls"
    private var pendingAnswerCall: Map<String, String>? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        readIntentForAnswer(intent)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "registerPhoneAccount" -> {
                    TelecomHelper.registerPhoneAccount(applicationContext)
                    result.success(null)
                }
                "setCallActive" -> {
                    TelecomHelper.activeConnection?.setActive()
                    result.success(null)
                }
                "endCall" -> {
                    val callId = call.argument<String>("callId")
                    TelecomHelper.activeConnection?.onDisconnect()
                    if (callId != null) IncomingCallHandler.dismissNotification(applicationContext, callId)
                    result.success(null)
                }
                "getPendingAnswerCall" -> {
                    result.success(pendingAnswerCall)
                    pendingAnswerCall = null
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        readIntentForAnswer(intent)
    }

    private fun readIntentForAnswer(intent: Intent) {
        if (intent.action != CallConnection.ACTION_ANSWER) return
        val callId = intent.getStringExtra(CallConnection.EXTRA_CALL_ID) ?: return
        pendingAnswerCall = mapOf(
            "callId" to callId,
            "fromProfileId" to (intent.getStringExtra(CallConnection.EXTRA_FROM_PROFILE_ID) ?: ""),
            "fromName" to (intent.getStringExtra(CallConnection.EXTRA_FROM_NAME) ?: ""),
        )
        IncomingCallHandler.dismissNotification(applicationContext, callId)
    }
}
