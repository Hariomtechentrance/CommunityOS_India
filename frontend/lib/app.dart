import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'features/calls/call_overlay.dart';
import 'features/emergency/emergency_alert_overlay.dart';
import 'router.dart';

class CommunityOsApp extends ConsumerWidget {
  const CommunityOsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'NIKAT',
      debugShowCheckedModeBanner: false,
      theme: nikatTheme,
      routerConfig: router,
      builder: (context, child) => EmergencyAlertOverlay(
        child: CallOverlay(child: child),
      ),
    );
  }
}
