import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/locale/locale_controller.dart';
import 'core/session/session_controller.dart';
import 'core/theme.dart';
import 'features/calls/call_overlay.dart';
import 'features/emergency/emergency_alert_overlay.dart';
import 'features/users/location_visit_service.dart';
import 'features/users/user_repository.dart';
import 'l10n/generated/app_localizations.dart';
import 'router.dart';

class CommunityOsApp extends ConsumerWidget {
  const CommunityOsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeControllerProvider).value;

    // Reactive on purpose, not a one-time initState read - see the identical
    // fix in emergency_alert_overlay.dart for why that distinction matters.
    ref.listen(sessionControllerProvider, (previous, next) {
      final userId = next.value?.user?.id;
      if (userId != null) {
        recordLocationVisitOncePerLogin(userId, ref.read(userRepositoryProvider));
      }
    });
    final currentUserId = ref.read(sessionControllerProvider).value?.user?.id;
    if (currentUserId != null) {
      recordLocationVisitOncePerLogin(currentUserId, ref.read(userRepositoryProvider));
    }

    return MaterialApp.router(
      title: 'NIKAT',
      debugShowCheckedModeBanner: false,
      theme: nikatTheme,
      routerConfig: router,
      locale: locale,
      supportedLocales: supportedAppLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => EmergencyAlertOverlay(
        child: CallOverlay(child: child),
      ),
    );
  }
}
