import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api_client.dart';
import '../../core/session/session_controller.dart';
import '../../core/widgets/max_width_box.dart';
import '../../core/widgets/user_avatar.dart';
import '../../models/job.dart';
import 'jobs_repository.dart';

const _applicationStatuses = ['PENDING', 'SHORTLISTED', 'HIRED', 'REJECTED'];

Color _appStatusColor(String s) => switch (s) {
      'SHORTLISTED' => Colors.blue,
      'HIRED' => Colors.green,
      'REJECTED' => Colors.red,
      _ => Colors.orange,
    };

class JobDetailScreen extends ConsumerStatefulWidget {
  const JobDetailScreen({super.key, required this.jobId});

  final String jobId;

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen> {
  bool _loading = true;
  bool _applying = false;
  String? _error;
  JobPosting? _job;
  List<JobApplication> _applications = [];

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
      final job = await ref.read(jobsRepositoryProvider).findOne(widget.jobId);
      final userId = ref.read(sessionControllerProvider).value?.user?.id;
      List<JobApplication> applications = [];
      if (job.poster?.id == userId) {
        applications = await ref.read(jobsRepositoryProvider).listApplications(widget.jobId);
      }
      setState(() {
        _job = job;
        _applications = applications;
      });
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _apply() async {
    final message = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Apply to this job'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Add a short message (optional)'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
    if (message == null) return;

    setState(() => _applying = true);
    try {
      await ref.read(jobsRepositoryProvider).apply(widget.jobId, message: message);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application sent!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _updateApplicationStatus(JobApplication app, String status) async {
    try {
      await ref.read(jobsRepositoryProvider).updateApplicationStatus(widget.jobId, app.id, status);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(sessionControllerProvider).value?.user?.id;
    final isPoster = _job?.poster?.id == userId;

    return Scaffold(
      appBar: AppBar(title: Text(_job?.title ?? 'Job')),
      body: MaxWidthBox(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Chip(label: Text(jobTypeLabel(_job!.jobType))),
                        const SizedBox(height: 12),
                        Text(_job!.title, style: Theme.of(context).textTheme.headlineSmall),
                        if (_job!.companyName != null) ...[
                          const SizedBox(height: 4),
                          Text(_job!.companyName!, style: Theme.of(context).textTheme.titleMedium),
                        ],
                        const SizedBox(height: 12),
                        Text(_job!.description),
                        if (_job!.salaryMin != null || _job!.salaryMax != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.payments_outlined, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                '₹${_job!.salaryMin ?? ''}${_job!.salaryMax != null ? '–₹${_job!.salaryMax}' : ''}'
                                '${_job!.salaryPeriod != null ? ' / ${_job!.salaryPeriod}' : ''}',
                              ),
                            ],
                          ),
                        ],
                        if (_job!.location != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 18),
                              const SizedBox(width: 4),
                              Expanded(child: Text(_job!.location!)),
                            ],
                          ),
                        ],
                        const SizedBox(height: 20),
                        if (!isPoster)
                          FilledButton.icon(
                            onPressed: _job!.status != 'OPEN' || _applying ? null : _apply,
                            icon: const Icon(Icons.send_outlined),
                            label: Text(_job!.status != 'OPEN' ? 'Closed' : 'Apply'),
                          ),
                        if (!isPoster && _job!.contactPhone != null) ...[
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () => _call(_job!.contactPhone!),
                            icon: const Icon(Icons.call_outlined),
                            label: const Text('Call poster'),
                          ),
                        ],
                        if (isPoster) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () async {
                                    await ref.read(jobsRepositoryProvider).setStatus(
                                          widget.jobId,
                                          _job!.status == 'OPEN' ? 'CLOSED' : 'OPEN',
                                        );
                                    _load();
                                  },
                                  child: Text(_job!.status == 'OPEN' ? 'Close job' : 'Reopen job'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Applicants (${_applications.length})',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          if (_applications.isEmpty)
                            const Text('No applications yet.')
                          else
                            ..._applications.map(
                              (app) => Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          UserAvatar(avatarUrl: app.applicant?.avatarUrl, radius: 16),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(app.applicant?.name ?? 'Applicant'),
                                          ),
                                          Text(
                                            app.status,
                                            style: TextStyle(
                                              color: _appStatusColor(app.status),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (app.message != null && app.message!.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(app.message!),
                                      ],
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        children: [
                                          for (final s in _applicationStatuses)
                                            if (s != app.status)
                                              OutlinedButton(
                                                onPressed: () => _updateApplicationStatus(app, s),
                                                child: Text('Mark $s'),
                                              ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
      ),
    );
  }
}
