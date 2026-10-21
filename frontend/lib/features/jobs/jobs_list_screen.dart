import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import '../../core/session/session_controller.dart';
import '../../core/widgets/max_width_box.dart';
import '../../models/job.dart';
import 'jobs_repository.dart';

class JobsListScreen extends ConsumerStatefulWidget {
  const JobsListScreen({super.key});

  @override
  ConsumerState<JobsListScreen> createState() => _JobsListScreenState();
}

class _JobsListScreenState extends ConsumerState<JobsListScreen> {
  bool _loading = true;
  String? _error;
  List<JobPosting> _jobs = [];
  JobType? _filter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = ref.read(sessionControllerProvider).value?.user;
    if (user?.area == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final jobs = await ref.read(jobsRepositoryProvider).listForArea(user!.area!, jobType: _filter);
      setState(() => _jobs = jobs);
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _salaryLabel(JobPosting job) {
    if (job.salaryMin == null && job.salaryMax == null) return '';
    final period = job.salaryPeriod != null ? '/${job.salaryPeriod}' : '';
    if (job.salaryMin != null && job.salaryMax != null) {
      return '₹${job.salaryMin}–₹${job.salaryMax}$period';
    }
    return '₹${job.salaryMin ?? job.salaryMax}$period';
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionControllerProvider).value?.user;

    return Scaffold(
      appBar: AppBar(
        title: Text('Jobs · ${user?.area ?? ''}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.assignment_turned_in_outlined),
            tooltip: 'My applications',
            onPressed: () => context.push('/home/jobs/my-applications'),
          ),
        ],
      ),
      body: MaxWidthBox(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: _filter == null,
                      onSelected: (_) {
                        setState(() => _filter = null);
                        _load();
                      },
                    ),
                    const SizedBox(width: 8),
                    ...allJobTypes.map(
                      (type) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(jobTypeLabel(type)),
                          selected: _filter == type,
                          onSelected: (_) {
                            setState(() => _filter = type);
                            _load();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(child: Text(_error!))
                        : _jobs.isEmpty
                            ? ListView(
                                children: const [
                                  Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Text('No jobs posted here yet. Be the first to post one.'),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.only(bottom: 80),
                                itemCount: _jobs.length,
                                itemBuilder: (context, index) {
                                  final job = _jobs[index];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                    child: ListTile(
                                      title: Text(job.title),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(job.companyName ?? job.location ?? job.area),
                                          Text(
                                            [
                                              jobTypeLabel(job.jobType),
                                              if (_salaryLabel(job).isNotEmpty) _salaryLabel(job),
                                            ].join(' · '),
                                          ),
                                        ],
                                      ),
                                      isThreeLine: true,
                                      onTap: () => context.push('/home/jobs/${job.id}'),
                                    ),
                                  );
                                },
                              ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final posted = await context.push<bool>('/home/jobs/new');
          if (posted == true) _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('Post a job'),
      ),
    );
  }
}
