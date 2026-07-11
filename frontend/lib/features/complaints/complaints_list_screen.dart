import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/session/session_controller.dart';
import '../../core/widgets/max_width_box.dart';
import '../../models/complaint.dart';
import '../../models/membership.dart';
import 'complaint_repository.dart';
import 'create_complaint_screen.dart';

class ComplaintsListScreen extends ConsumerStatefulWidget {
  const ComplaintsListScreen({super.key});

  @override
  ConsumerState<ComplaintsListScreen> createState() => _ComplaintsListScreenState();
}

class _ComplaintsListScreenState extends ConsumerState<ComplaintsListScreen> {
  bool _loading = true;
  String? _error;
  List<Complaint> _complaints = [];

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
      final complaints = await ref.read(complaintRepositoryProvider).list(societyId);
      setState(() => _complaints = complaints);
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changeStatus(Complaint complaint) async {
    final societyId = ref.read(sessionControllerProvider).value?.society?.id;
    if (societyId == null) return;
    final status = await showDialog<ComplaintStatus>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Update status'),
        children: ComplaintStatus.values
            .map(
              (s) => SimpleDialogOption(
                onPressed: () => Navigator.of(context).pop(s),
                child: Text(complaintStatusLabel(s)),
              ),
            )
            .toList(),
      ),
    );
    if (status == null) return;
    try {
      await ref.read(complaintRepositoryProvider).updateStatus(societyId, complaint.id, status);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isStaff = isStaffRole(
      ref.watch(sessionControllerProvider).value?.membership?.role ?? MembershipRole.resident,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Complaints')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final posted = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const CreateComplaintScreen()),
          );
          if (posted == true) _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('Raise complaint'),
      ),
      body: MaxWidthBox(
        child: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : _complaints.isEmpty
                    ? ListView(
                        children: const [
                          Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('No complaints yet.'),
                          ),
                        ],
                      )
                    : ListView.builder(
                        itemCount: _complaints.length,
                        itemBuilder: (context, index) {
                          final complaint = _complaints[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              title: Text(complaint.category),
                              subtitle: Text(complaint.description),
                              trailing: isStaff
                                  ? TextButton(
                                      onPressed: () => _changeStatus(complaint),
                                      child: Text(complaintStatusLabel(complaint.status)),
                                    )
                                  : Chip(label: Text(complaintStatusLabel(complaint.status))),
                            ),
                          );
                        },
                      ),
        ),
      ),
    );
  }
}
