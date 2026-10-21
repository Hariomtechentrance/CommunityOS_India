import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import 'ai_repository.dart';

const _languages = {
  'en': 'English',
  'hi': 'Hindi',
  'mr': 'Marathi',
  'kn': 'Kannada',
  'ta': 'Tamil',
  'te': 'Telugu',
  'bn': 'Bengali',
  'gu': 'Gujarati',
  'ml': 'Malayalam',
  'pa': 'Punjabi',
};

/// Pick a language, translate the given text via Gemini, show the result -
/// shared by any screen with translatable text (currently post detail).
Future<void> showTranslateSheet(BuildContext context, WidgetRef ref, String text) async {
  final language = await showModalBottomSheet<String>(
    context: context,
    builder: (context) => SafeArea(
      child: Wrap(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Translate to', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          for (final entry in _languages.entries)
            ListTile(
              title: Text(entry.value),
              onTap: () => Navigator.of(context).pop(entry.key),
            ),
        ],
      ),
    ),
  );
  if (language == null || !context.mounted) return;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(child: CircularProgressIndicator()),
  );

  try {
    final translated = await ref.read(aiRepositoryProvider).translate(text, language);
    if (!context.mounted) return;
    Navigator.of(context).pop();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Translated to ${_languages[language]}'),
        content: SingleChildScrollView(child: Text(translated)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
  }
}
