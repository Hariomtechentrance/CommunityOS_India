package com.communityos.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.telecom.TelecomManager
import androidx.core.app.NotificationCompat

/**
 * The actual "make the phone ring" logic - registers the call with Telecom
 * and shows a full-screen-intent notification. Called directly from
 * CallFirebaseMessagingService (native FCM interception) rather than routed
 * through Dart, since the background isolate Flutter spins up for FCM
 * messages doesn't share a MethodChannel with MainActivity's engine - two
 * separate engines, so a channel registered on one is invisible to the other.
 */
object IncomingCallHandler {
    private const val CALL_CHANNEL_ID = "com.communityos.app.calls"

    fun show(context: Context, callId: String, fromProfileId: String, fromName: String) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val telecomManager = context.getSystemService(Context.TELECOM_SERVICE) as TelecomManager
        val extras = Bundle().apply {
            putString(CallConnection.EXTRA_CALL_ID, callId)
            putString(CallConnection.EXTRA_FROM_PROFILE_ID, fromProfileId)
            putString(CallConnection.EXTRA_FROM_NAME, fromName)
            putParcelable(TelecomManager.EXTRA_INCOMING_CALL_ADDRESS, Uri.fromParts("tel", fromProfileId, null))
        }
        telecomManager.addNewIncomingCall(TelecomHelper.phoneAccountHandle(context), extras)
        showFullScreenNotification(context, callId, fromName)
    }

    /** The caller gave up before this device answered - stop ringing and
     * tear down the Telecom connection entirely. */
    fun cancelRinging(context: Context, callId: String) {
        TelecomHelper.activeConnection?.onDisconnect()
        dismissNotification(context, callId)
    }

    /** Just clears the notification - used when the user is *answering* (the
     * connection should stay active, not be torn down) as well as after a
     * decline (CallConnection.onReject already handles the Telecom side). */
    fun dismissNotification(context: Context, callId: String) {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.cancel(callId.hashCode())
    }

    private fun showFullScreenNotification(context: Context, callId: String, fromName: String) {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CALL_CHANNEL_ID,
                "Incoming calls",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = "Rings for incoming NIKAT calls"
            }
            manager.createNotificationChannel(channel)
        }

        val fullScreenIntent = Intent(context, IncomingCallActivity::class.java).apply {
            putExtra(CallConnection.EXTRA_CALL_ID, callId)
            putExtra(CallConnection.EXTRA_FROM_NAME, fromName)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            callId.hashCode(),
            fullScreenIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val notification = NotificationCompat.Builder(context, CALL_CHANNEL_ID)
            .setSmallIcon(android.R.drawable.sym_call_incoming)
            .setContentTitle("Incoming call")
            .setContentText(fromName)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setFullScreenIntent(pendingIntent, true)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setAutoCancel(true)
            .build()
        manager.notify(callId.hashCode(), notification)
    }
}
