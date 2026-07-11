import 'package:firebase_core/firebase_core.dart';

/// Hand-written from the Firebase console's `firebaseConfig` object
/// (Project Settings -> General -> Your apps -> Web app -> SDK setup and
/// configuration), rather than generated via the FlutterFire CLI (which needs
/// an interactive `firebase login`). Web-only for now - mobile options will be
/// added when the mobile app is built.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => web;

  static const web = FirebaseOptions(
    apiKey: 'AIzaSyBTgCFvXtgTHE80uFhHPxok94OsiLB321w',
    authDomain: 'community-os-india.firebaseapp.com',
    projectId: 'community-os-india',
    storageBucket: 'community-os-india.firebasestorage.app',
    messagingSenderId: '49536469012',
    appId: '1:49536469012:web:45131259da38909064bf01',
    measurementId: 'G-6MS4JFG3PG',
  );
}
