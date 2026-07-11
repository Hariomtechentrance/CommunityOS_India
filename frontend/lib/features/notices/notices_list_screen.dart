import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/session/session_controller.dart';
import '../../core/widgets/max_width_box.dart';
import '../../models/membership.dart';
import '../../models/notice.dart';
import 'create_notice_screen.dart';
import 'notice_repository.dart';

class NoticesListScreen extends ConsumerStatefulWidget {
  const NoticesListScreen({super.key});

  @override
  ConsumerState<NoticesListScreen> createState() => _NoticesListScreenState();
}

class _NoticesListScreenState extends ConsumerState<NoticesListScreen> {
  bool _loading = true;
  String? _error;
  List<Notice> _notices = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final societyId = ref.read(sessionControllerProvider).value?.society?.id;
    if (societyId == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final notices = await ref.read(noticeRepositoryProvider).list(societyId);
      setState(() => _notices = notices);
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPost = isStaffRole(
      ref.watch(sessionControllerProvider).value?.membership?.role ?? MembershipRole.resident,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Notices')),
      floatingActionButton: canPost
          ? FloatingActionButton.extended(
              onPressed: () async {
                final posted = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const CreateNoticeScreen()),
                );
                if (posted == true) _load();
              },
              icon: const Icon(Icons.add),
              label: const Text('New notice'),
            )
          : null,
      body: MaxWidthBox(
        child: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : _notices.isEmpty
                    ? ListView(
                        children: const [
                          Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('No notices yet.'),
                          ),
                        ],
                      )
                    : ListView.builder(
                        itemCount: _notices.length,
                        itemBuilder: (context, index) {
                          final notice = _notices[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              leading: notice.pinned
                                  ? const Icon(Icons.push_pin, color: Colors.orange)
                                  : const Icon(Icons.notifications_none),
                              title: Text(notice.title),
                              subtitle: Text(notice.body),
                            ),
                          );
                        },
                      ),
        ),
      ),
    );
  }
}
