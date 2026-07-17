import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Incoming-call pushes ring the phone via a native Android
  // ConnectionService, intercepted before Dart ever runs - see
  // android/.../CallFirebaseMessagingService.kt. No Dart-side background
  // message handler is needed for that; nothing else currently needs one.
  runApp(const ProviderScope(child: CommunityOsApp()));
}
