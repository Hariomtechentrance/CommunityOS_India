import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/curated_emoji.dart';
import '../../core/session/session_controller.dart';
import '../../core/widgets/max_width_box.dart';
import '../../models/message.dart';
import 'message_repository.dart';
import 'message_service.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String otherUserId;
  final String? otherUserName;

  const ChatScreen({super.key, required this.otherUserId, this.otherUserName});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _loading = true;
  String? _error;
  List<ChatMessage> _messages = [];
  MessageService? _messageService;
  bool _showEmojiPicker = false;

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _messageService = ref.read(messageServiceProvider);
      _messageService?.incoming.addListener(_onIncoming);
    });
  }

  void _onIncoming() {
    final message = _messageService?.incoming.value;
    if (message == null) return;
    final isForThisThread =
        message.senderId == widget.otherUserId || message.receiverId == widget.otherUserId;
    if (!isForThisThread) return;
    if (_messages.any((m) => m.id == message.id)) return;
    setState(() => _messages = [..._messages, message]);
    _scrollToBottom();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final messages = await ref.read(messageRepositoryProvider).getThread(widget.otherUserId);
      setState(() => _messages = messages);
      _scrollToBottom();
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  Future<void> _send({String? overrideBody, MessageKind kind = MessageKind.text}) async {
    final body = overrideBody ?? _textController.text.trim();
    if (body.isEmpty) return;
    if (overrideBody == null) _textController.clear();
    try {
      final message =
          await ref.read(messageRepositoryProvider).send(widget.otherUserId, body, kind: kind);
      setState(() => _messages = [..._messages, message]);
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    }
  }

  void _toggleEmojiPicker() {
    setState(() => _showEmojiPicker = !_showEmojiPicker);
  }

  Future<void> _showStickerPicker() async {
    final sticker = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 6,
        children: curatedEmoji
            .map(
              (sticker) => InkWell(
                onTap: () => Navigator.of(context).pop(sticker),
                child: Center(child: Text(sticker, style: const TextStyle(fontSize: 28))),
              ),
            )
            .toList(),
      ),
    );
    if (sticker != null) {
      await _send(overrideBody: sticker, kind: MessageKind.sticker);
    }
  }

  @override
  void dispose() {
    _messageService?.incoming.removeListener(_onIncoming);
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myId = ref.watch(sessionControllerProvider).value?.user?.id;

    return Scaffold(
      appBar: AppBar(title: Text(widget.otherUserName ?? 'Chat')),
      body: MaxWidthBox(
        child: Column(
          children: [
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!))
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(12),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            final isMine = message.senderId == myId;
                            final isSticker = message.kind == MessageKind.sticker;
                            return Align(
                              alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: isSticker
                                    ? const EdgeInsets.all(4)
                                    : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                constraints: const BoxConstraints(maxWidth: 420),
                                decoration: isSticker
                                    ? null
                                    : BoxDecoration(
                                        color: isMine
                                            ? Theme.of(context).colorScheme.primaryContainer
                                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                child: Text(
                                  message.body,
                                  style: isSticker ? const TextStyle(fontSize: 48) : null,
                                ),
                              ),
                            );
                          },
                        ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.emoji_emotions_outlined),
                      tooltip: 'Emoji',
                      onPressed: _toggleEmojiPicker,
                    ),
                    IconButton(
                      icon: const Icon(Icons.auto_awesome_outlined),
                      tooltip: 'Stickers',
                      onPressed: _showStickerPicker,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: const InputDecoration(
                          hintText: 'Message',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(icon: const Icon(Icons.send), onPressed: () => _send()),
                  ],
                ),
              ),
            ),
            if (_showEmojiPicker)
              SizedBox(
                height: 280,
                child: EmojiPicker(
                  onEmojiSelected: (category, emoji) {
                    _textController.text += emoji.emoji;
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
