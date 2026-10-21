# Flutter's own engine/plugin embedding classes - required baseline for any
# Flutter Android release build with minification on.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase (Auth, Messaging, Core) - these talk to native code via reflection
# in places; stripping/renaming breaks token handling and push delivery.
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# flutter_webrtc (and the underlying libwebrtc JNI bridge) - this app's
# calling feature depends on this; WebRTC's JNI bridge is a classic case
# where R8 renaming breaks native method resolution if not kept.
-keep class org.webrtc.** { *; }
-keep class com.cloudwebrtc.webrtc.** { *; }
-dontwarn org.webrtc.**

# google_maps_flutter
-keep class com.google.android.gms.maps.** { *; }
-keep class com.google.android.libraries.maps.** { *; }

# socket_io_client's underlying engine.io-client / okhttp - reflection-based
# WebSocket upgrade handling.
-keep class io.socket.** { *; }
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# Keep anything with a native method - covers geolocator, record, audioplayers,
# video_player and any other plugin with a JNI bridge not explicitly listed
# above, without having to enumerate every one.
-keepclasseswithmembernames class * {
    native <methods>;
}
