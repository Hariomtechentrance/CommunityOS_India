package com.communityos.app

import android.content.ComponentName
import android.content.Context
import android.os.Build
import android.telecom.PhoneAccount
import android.telecom.PhoneAccountHandle
import android.telecom.TelecomManager

/**
 * Shared registration/state for our self-managed Telecom ConnectionService -
 * a VoIP-only account (no SIM, no real phone number) registered purely so
 * incoming NIKAT calls can ring with a real system call screen and proper
 * audio-focus/Bluetooth handling, even from a fully closed app. Self-managed
 * accounts need MANAGE_OWN_CALLS (a normal permission, no runtime prompt) -
 * not the older READ_PHONE_STATE/CALL_PHONE dangerous permissions that
 * pre-Android-9 telephony integrations required.
 */
object TelecomHelper {
    private const val ACCOUNT_ID = "nikat_calling"

    /** The one call this app supports at a time - set when a connection is
     * created, cleared when it's destroyed. Both IncomingCallActivity and
     * MainActivity's method channel need to reach the same instance. */
    var activeConnection: CallConnection? = null

    fun phoneAccountHandle(context: Context): PhoneAccountHandle {
        return PhoneAccountHandle(
            ComponentName(context, CallConnectionService::class.java),
            ACCOUNT_ID,
        )
    }

    fun registerPhoneAccount(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val telecomManager = context.getSystemService(Context.TELECOM_SERVICE) as TelecomManager
        val handle = phoneAccountHandle(context)
        val account = PhoneAccount.builder(handle, "NIKAT")
            .setCapabilities(PhoneAccount.CAPABILITY_SELF_MANAGED)
            .build()
        telecomManager.registerPhoneAccount(account)
    }
}
