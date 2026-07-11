import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/session/session_controller.dart';
import '../../core/widgets/max_width_box.dart';
import '../../models/membership.dart';
import 'membership_repository.dart';

class ManageMembersScreen extends ConsumerStatefulWidget {
  const ManageMembersScreen({super.key});

  @override
  ConsumerState<ManageMembersScreen> createState() => _ManageMembersScreenState();
}

class _ManageMembersScreenState extends ConsumerState<ManageMembersScreen> {
  bool _loading = true;
  String? _error;
  List<Membership> _pending = [];

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
      final pending = await ref
          .read(membershipRepositoryProvider)
          .listForSociety(societyId, status: MembershipStatus.pending);
      setState(() => _pending = pending);
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _decide(Membership membership, MembershipStatus status) async {
    final societyId = ref.read(sessionControllerProvider).value?.society?.id;
    if (societyId == null) return;
    try {
      await ref
          .read(membershipRepositoryProvider)
          .updateStatus(societyId, membership.id, status);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage members')),
      body: MaxWidthBox(
        child: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : _pending.isEmpty
                    ? ListView(
                        children: const [
                          Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('No pending join requests.'),
                          ),
                        ],
                      )
                    : ListView.builder(
                        itemCount: _pending.length,
                        itemBuilder: (context, index) {
                          final membership = _pending[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              title: Text(membership.user?.phone ?? membership.userId),
                              subtitle: Text(
                                membership.unitNumber != null
                                    ? 'Unit ${membership.unitNumber}'
                                    : 'No unit specified',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.check_circle, color: Colors.green),
                                    tooltip: 'Approve',
                                    onPressed: () =>
                                        _decide(membership, MembershipStatus.approved),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.cancel, color: Colors.red),
                                    tooltip: 'Reject',
                                    onPressed: () =>
                                        _decide(membership, MembershipStatus.rejected),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
        ),
      ),
    );
  }
}
