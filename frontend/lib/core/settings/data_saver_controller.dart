import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// When on, reels don't auto-play as they scroll into view - the user has
/// to tap to start playback. Mirrors LocaleController's persistence pattern
/// (SharedPreferences, same as session_storage.dart). Off by default since
/// auto-play is the expected reels experience; this is an opt-in saving.
class DataSaverController extends AsyncNotifier<bool> {
  static const _key = 'data_saver_enabled';

  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, enabled);
    state = AsyncData(enabled);
  }
}

final dataSaverControllerProvider = AsyncNotifierProvider<DataSaverController, bool>(
  DataSaverController.new,
);
