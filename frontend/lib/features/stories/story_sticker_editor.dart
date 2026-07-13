import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/curated_emoji.dart';

class _Overlay {
  Offset position;
  final String text;
  final double fontSize;

  _Overlay({required this.position, required this.text, required this.fontSize});
}

/// Lets the user drop emoji/text stickers onto a photo before sharing it as
/// a story, then bakes them directly into the image's pixels (via
/// RepaintBoundary capture) so every viewer sees identical, pixel-stable
/// placement - simpler and more robust than replaying structured overlay
/// data at view time, at the cost of the stickers not being editable after
/// the fact. Photo stories only; baking onto a moving video isn't feasible
/// without a server-side transcode step this app doesn't have.
class StoryStickerEditor extends StatefulWidget {
  final XFile image;

  const StoryStickerEditor({super.key, required this.image});

  @override
  State<StoryStickerEditor> createState() => _StoryStickerEditorState();
}

class _StoryStickerEditorState extends State<StoryStickerEditor> {
  final _boundaryKey = GlobalKey();
  final List<_Overlay> _overlays = [];
  bool _exporting = false;

  Future<void> _pickEmoji() async {
    final emoji = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 6,
        children: curatedEmoji
            .map(
              (e) => InkWell(
                onTap: () => Navigator.of(context).pop(e),
                child: Center(child: Text(e, style: const TextStyle(fontSize: 28))),
              ),
            )
            .toList(),
      ),
    );
    if (emoji == null) return;
    setState(() {
      _overlays.add(_Overlay(position: const Offset(140, 240), text: emoji, fontSize: 48));
    });
  }

  Future<void> _addText() async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add text'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (text == null || text.isEmpty) return;
    setState(() {
      _overlays.add(_Overlay(position: const Offset(80, 300), text: text, fontSize: 28));
    });
  }

  Future<void> _done() async {
    setState(() => _exporting = true);
    try {
      final boundary =
          _boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      if (mounted) Navigator.of(context).pop(bytes);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Add stickers'),
        actions: [
          TextButton(
            onPressed: _exporting ? null : () => Navigator.of(context).pop(null),
            child: const Text('Skip', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: RepaintBoundary(
                key: _boundaryKey,
                child: Stack(
                  children: [
                    Image.network(widget.image.path, fit: BoxFit.contain),
                    for (final overlay in _overlays)
                      Positioned(
                        left: overlay.position.dx,
                        top: overlay.position.dy,
                        child: GestureDetector(
                          onPanUpdate: (details) => setState(
                            () => overlay.position += details.delta,
                          ),
                          child: Text(
                            overlay.text,
                            style: TextStyle(fontSize: overlay.fontSize, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                      onPressed: _exporting ? null : _pickEmoji,
                      icon: const Icon(Icons.emoji_emotions_outlined),
                      label: const Text('Emoji'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                      onPressed: _exporting ? null : _addText,
                      icon: const Icon(Icons.text_fields),
                      label: const Text('Text'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _exporting ? null : _done,
                      child: _exporting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Done'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

