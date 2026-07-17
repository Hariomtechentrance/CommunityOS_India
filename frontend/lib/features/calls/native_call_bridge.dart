import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Talks to the hand-written Android Telecom ConnectionService integration
/// (see android/app/.../CallConnectionService.kt, CallConnection.kt,
/// IncomingCallActivity.kt, MainActivity.kt) that lets an incoming call ring
/// with a real system call screen even from a fully closed app. No-ops on
/// web/other platforms - MethodChannel calls compile everywhere, but there's
/// no native handler registered there, so every call here is guarded.
class NativeCallBridge {
  static const _channel = MethodChannel('com.communityos.app/calls');

  static Future<void> registerPhoneAccount() async {
    if (kIsWeb) return;
    await _channel.invokeMethod<void>('registerPhoneAccount');
  }

  static Future<void> setCallActive() async {
    if (kIsWeb) return;
    await _channel.invokeMethod<void>('setCallActive');
  }

  static Future<void> endCall(String callId) async {
    if (kIsWeb) return;
    await _channel.invokeMethod<void>('endCall', {'callId': callId});
  }

  /// Non-null exactly once per cold/warm start triggered by the user tapping
  /// Accept on the native incoming-call screen - MainActivity stashes the
  /// launch intent's extras and hands them over (then clears them) the first
  /// time this is called.
  static Future<Map<String, String>?> getPendingAnswerCall() async {
    if (kIsWeb) return null;
    final result = await _channel.invokeMapMethod<String, String>('getPendingAnswerCall');
    return result;
  }
}
