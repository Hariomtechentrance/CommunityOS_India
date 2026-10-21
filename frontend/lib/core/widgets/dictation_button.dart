import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Android/iOS only ever run ONE speech recognition session at a time -
/// starting a second one while the first is still listening fails silently.
/// A single app-wide coordinator makes that explicit: starting a new
/// session always stops whatever was running first, so two DictationButtons
/// on the same screen (e.g. Title + Details) never fight over the mic.
class _SpeechCoordinator extends ChangeNotifier {
  _SpeechCoordinator._();
  static final instance = _SpeechCoordinator._();

  final SpeechToText speech = SpeechToText();
  bool _initialized = false;
  Future<bool>? _initializing;
  Object? activeToken;

  Future<bool> ensureInitialized() {
    if (_initialized) return Future.value(true);
    return _initializing ??= speech.initialize().then((ok) {
      _initialized = ok;
      return ok;
    });
  }

  Future<void> start(
    Object token, {
    required String localeId,
    required void Function(String text) onResult,
  }) async {
    if (activeToken != null && activeToken != token) {
      await speech.stop();
    }
    activeToken = token;
    notifyListeners();
    await speech.listen(
      onResult: (result) => onResult(result.recognizedWords),
      listenOptions: SpeechListenOptions(localeId: localeId),
    );
  }

  Future<void> stop(Object token) async {
    if (activeToken != token) return;
    await speech.stop();
    activeToken = null;
    notifyListeners();
  }
}

/// Mic button that dictates straight into a [TextEditingController] via the
/// device's own on-device speech recognizer - free, no API key, works
/// offline on most devices. Appends to whatever's already typed rather than
/// replacing it. Safe to use several of these on one screen at once (see
/// _SpeechCoordinator above).
class DictationButton extends StatefulWidget {
  final TextEditingController controller;
  final String localeId;

  const DictationButton({super.key, required this.controller, this.localeId = 'en_IN'});

  @override
  State<DictationButton> createState() => _DictationButtonState();
}

class _DictationButtonState extends State<DictationButton> {
  final _coordinator = _SpeechCoordinator.instance;
  final _token = Object();
  bool _available = false;
  String _baseText = '';

  bool get _listening => _coordinator.activeToken == _token;

  @override
  void initState() {
    super.initState();
    _coordinator.addListener(_onCoordinatorChanged);
    _coordinator.ensureInitialized().then((available) {
      if (mounted) setState(() => _available = available);
    });
  }

  void _onCoordinatorChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _toggle() async {
    if (_listening) {
      await _coordinator.stop(_token);
      return;
    }
    if (!_available) return;

    _baseText = widget.controller.text;
    await _coordinator.start(
      _token,
      localeId: widget.localeId,
      onResult: (text) {
        final separator = _baseText.isEmpty ? '' : ' ';
        widget.controller.text = '$_baseText$separator$text';
        widget.controller.selection =
            TextSelection.collapsed(offset: widget.controller.text.length);
      },
    );
  }

  @override
  void dispose() {
    _coordinator.removeListener(_onCoordinatorChanged);
    _coordinator.stop(_token);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(_listening ? Icons.mic : Icons.mic_none, color: _listening ? Colors.red : null),
      tooltip: _available ? 'Speak to type' : 'Speech recognition unavailable',
      onPressed: _available ? _toggle : null,
    );
  }
}
