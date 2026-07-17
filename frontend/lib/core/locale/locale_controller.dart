import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Languages with a translated ARB file - see lib/l10n/. Adding a new
/// regional language is just a new app_<code>.arb file + an entry here,
/// no other code changes needed.
const supportedAppLocales = [Locale('en'), Locale('hi')];

/// Persists the user's chosen language (SharedPreferences, same mechanism as
/// session_storage.dart). Null means "follow the device's language" -
/// MaterialApp.router falls back to it automatically via localeResolutionCallback.
class LocaleController extends AsyncNotifier<Locale?> {
  static const _key = 'app_locale';

  @override
  Future<Locale?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    return code == null ? null : Locale(code);
  }

  Future<void> setLocale(Locale? locale) async {
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, locale.languageCode);
    }
    state = AsyncData(locale);
  }
}

final localeControllerProvider = AsyncNotifierProvider<LocaleController, Locale?>(
  LocaleController.new,
);
