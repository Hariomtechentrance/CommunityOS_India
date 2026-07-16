import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb, TargetPlatform, defaultTargetPlatform;

/// Hand-written from the Firebase console's `firebaseConfig` object
/// (Project Settings -> General -> Your apps -> SDK setup and configuration),
/// rather than generated via the FlutterFire CLI (which needs an interactive
/// `firebase login`).
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return web;
    }
  }

  static const web = FirebaseOptions(
    apiKey: 'AIzaSyBTgCFvXtgTHE80uFhHPxok94OsiLB321w',
    authDomain: 'community-os-india.firebaseapp.com',
    projectId: 'community-os-india',
    storageBucket: 'community-os-india.firebasestorage.app',
    messagingSenderId: '49536469012',
    appId: '1:49536469012:web:45131259da38909064bf01',
    measurementId: 'G-6MS4JFG3PG',
  );

  static const android = FirebaseOptions(
    apiKey: 'AIzaSyAo4eBkL_0Y6ErOAWGLSQBiC6rVUYQcWgE',
    projectId: 'community-os-india',
    storageBucket: 'community-os-india.firebasestorage.app',
    messagingSenderId: '49536469012',
    appId: '1:49536469012:android:0fa9d0c231e4953f64bf01',
  );
}
