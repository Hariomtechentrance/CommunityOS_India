package com.communityos.app

import com.google.firebase.messaging.RemoteMessage
import io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingService

/**
 * Incoming-call pushes need to ring the phone instantly and reliably, which
 * means handling them natively the moment FCM delivers them - not routing
 * through Dart. Flutter's own FCM background handling spins up a separate,
 * headless FlutterEngine distinct from MainActivity's, so a MethodChannel
 * registered in MainActivity is invisible to it; there's no clean way to
 * reach our calling code from that isolate. Intercepting here instead avoids
 * that entirely. Every other message type still goes through Flutter
 * normally via super() - this only short-circuits calls.
 */
class CallFirebaseMessagingService : FlutterFirebaseMessagingService() {
    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        val data = remoteMessage.data
        when (data["type"]) {
            "incoming_call" -> {
                val callId = data["callId"]
                val fromProfileId = data["fromProfileId"]
                if (callId != null && fromProfileId != null) {
                    IncomingCallHandler.show(applicationContext, callId, fromProfileId, data["fromName"] ?: "Someone")
                }
            }
            "call_cancelled" -> {
                data["callId"]?.let { IncomingCallHandler.cancelRinging(applicationContext, it) }
            }
            else -> super.onMessageReceived(remoteMessage)
        }
    }
}
