import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import '../../core/widgets/max_width_box.dart';
import '../../models/job.dart';
import 'jobs_repository.dart';

Color _appStatusColor(String s) => switch (s) {
      'SHORTLISTED' => Colors.blue,
      'HIRED' => Colors.green,
      'REJECTED' => Colors.red,
      _ => Colors.orange,
    };

class MyApplicationsScreen extends ConsumerStatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  ConsumerState<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends ConsumerState<MyApplicationsScreen> {
  bool _loading = true;
  String? _error;
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
      final applications = await ref.read(jobsRepositoryProvider).listMyApplications();
      setState(() => _applications = applications);
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My applications')),
      body: MaxWidthBox(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _applications.isEmpty
                        ? ListView(
                            children: const [
                              Padding(
                                padding: EdgeInsets.all(24),
                                child: Text("You haven't applied to any jobs yet."),
                              ),
                            ],
                          )
                        : ListView.builder(
                            itemCount: _applications.length,
                            itemBuilder: (context, index) {
                              final app = _applications[index];
                              return ListTile(
                                title: Text(app.job?.title ?? 'Job'),
                                subtitle: Text(app.job?.companyName ?? app.job?.area ?? ''),
                                trailing: Text(
                                  app.status,
                                  style: TextStyle(
                                    color: _appStatusColor(app.status),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                onTap: () => context.push('/home/jobs/${app.jobId}'),
                              );
                            },
                          ),
                  ),
      ),
    );
  }
}
