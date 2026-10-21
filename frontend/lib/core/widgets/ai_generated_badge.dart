import 'package:flutter/material.dart';

/// Experimental, informational-only indicator - never a verified fact.
/// Shown when our best-effort AI detection flags a post's text as likely
/// AI-written. Tapping it explains the caveat so users don't treat it as
/// a moderation verdict.
class AiGeneratedBadge extends StatelessWidget {
  const AiGeneratedBadge({super.key, this.confidence});

  final int? confidence;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Our AI detector thinks this text may be AI-generated. '
          'This is an automated guess, not a verified fact.',
      child: Chip(
        avatar: const Icon(Icons.smart_toy_outlined, size: 16),
        label: Text(confidence != null ? 'Possibly AI-written · $confidence%' : 'Possibly AI-written'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
