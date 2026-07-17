package com.communityos.app

import android.content.Context
import android.content.Intent
import android.telecom.Connection
import android.telecom.DisconnectCause

/**
 * One in-flight call. Android's self-managed Connection API doesn't show any
 * system UI on its own for these (that's only automatic for real carrier
 * calls) - IncomingCallActivity is our own full-screen replacement, and this
 * class just keeps Telecom's call state (audio focus, Bluetooth, "is a call
 * active" for other apps) in sync with whatever the user does there.
 */
class CallConnection(
    private val appContext: Context,
    val callId: String,
    val fromProfileId: String,
    val fromName: String,
) : Connection() {

    init {
        connectionProperties = PROPERTY_SELF_MANAGED
        connectionCapabilities = CAPABILITY_SUPPORT_HOLD
        audioModeIsVoip = true
    }

    /** Called by IncomingCallActivity when the user taps Accept, or by
     * Telecom itself if answered via Bluetooth/Android Auto. */
    override fun onAnswer() {
        setActive()
        val launch = Intent(appContext, MainActivity::class.java).apply {
            action = ACTION_ANSWER
            putExtra(EXTRA_CALL_ID, callId)
            putExtra(EXTRA_FROM_PROFILE_ID, fromProfileId)
            putExtra(EXTRA_FROM_NAME, fromName)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        appContext.startActivity(launch)
    }

    override fun onReject() {
        setDisconnected(DisconnectCause(DisconnectCause.REJECTED))
        destroy()
        TelecomHelper.activeConnection = null
    }

    override fun onDisconnect() {
        setDisconnected(DisconnectCause(DisconnectCause.LOCAL))
        destroy()
        TelecomHelper.activeConnection = null
    }

    override fun onAbort() {
        setDisconnected(DisconnectCause(DisconnectCause.CANCELED))
        destroy()
        TelecomHelper.activeConnection = null
    }

    companion object {
        const val ACTION_ANSWER = "com.communityos.app.action.ANSWER_CALL"
        const val EXTRA_CALL_ID = "callId"
        const val EXTRA_FROM_PROFILE_ID = "fromProfileId"
        const val EXTRA_FROM_NAME = "fromName"
    }
}
