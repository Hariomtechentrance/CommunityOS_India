import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import '../../core/widgets/max_width_box.dart';
import '../../core/widgets/user_avatar.dart';
import '../../models/message.dart';
import 'message_repository.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  bool _loading = true;
  String? _error;
  List<ChatThread> _threads = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final threads = await ref.read(messageRepositoryProvider).listThreads();
      setState(() => _threads = threads);
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: MaxWidthBox(
        child: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : _threads.isEmpty
                    ? ListView(
                        children: const [
                          Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('No conversations yet.'),
                          ),
                        ],
                      )
                    : ListView.builder(
                        itemCount: _threads.length,
                        itemBuilder: (context, index) {
                          final thread = _threads[index];
                          return ListTile(
                            leading: UserAvatar(avatarUrl: thread.otherUser.avatarUrl),
                            title: Text(thread.otherUser.name ?? 'Someone'),
                            subtitle: Text(
                              thread.lastMessage.body,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => context.push(
                              '/home/messages/${thread.otherUser.id}',
                              extra: thread.otherUser.name,
                            ),
                          );
                        },
                      ),
        ),
      ),
    );
  }
}
