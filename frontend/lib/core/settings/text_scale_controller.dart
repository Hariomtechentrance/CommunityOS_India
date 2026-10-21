import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide text scale, independent of the device's own system font size -
/// mirrors LocaleController's persistence pattern. Kept to a few discrete
/// presets (not a free slider) so every screen's hand-tuned layout stays
/// predictable rather than needing to handle arbitrary scale factors.
class TextScaleController extends AsyncNotifier<double> {
  static const _key = 'text_scale_factor';
  static const defaultScale = 1.0;

  @override
  Future<double> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_key) ?? defaultScale;
  }

  Future<void> setScale(double scale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_key, scale);
    state = AsyncData(scale);
  }
}

final textScaleControllerProvider = AsyncNotifierProvider<TextScaleController, double>(
  TextScaleController.new,
);
