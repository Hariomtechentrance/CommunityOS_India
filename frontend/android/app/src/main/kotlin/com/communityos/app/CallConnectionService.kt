package com.communityos.app

import android.telecom.Connection
import android.telecom.ConnectionRequest
import android.telecom.ConnectionService
import android.telecom.PhoneAccountHandle
import android.telecom.TelecomManager

class CallConnectionService : ConnectionService() {
    override fun onCreateIncomingConnection(
        connectionManagerPhoneAccount: PhoneAccountHandle,
        request: ConnectionRequest,
    ): Connection {
        val extras = request.extras
        val callId = extras.getString(CallConnection.EXTRA_CALL_ID) ?: ""
        val fromProfileId = extras.getString(CallConnection.EXTRA_FROM_PROFILE_ID) ?: ""
        val fromName = extras.getString(CallConnection.EXTRA_FROM_NAME) ?: "Someone"

        val connection = CallConnection(applicationContext, callId, fromProfileId, fromName)
        connection.setCallerDisplayName(fromName, TelecomManager.PRESENTATION_ALLOWED)
        connection.setRinging()
        TelecomHelper.activeConnection = connection
        return connection
    }

    override fun onCreateIncomingConnectionFailed(
        connectionManagerPhoneAccount: PhoneAccountHandle,
        request: ConnectionRequest,
    ) {
        TelecomHelper.activeConnection = null
    }
}
