import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/session/session_controller.dart';
import 'auth_repository.dart';

/// Testing/QA convenience: lists every seeded demo identity (already has a
/// location profile) and lets you switch straight into any of them - no OTP,
/// no repeated "Try live demo" taps that create a brand-new identity each
/// time. Not part of the real onboarding flow.
class DemoUserSwitcherScreen extends ConsumerStatefulWidget {
  const DemoUserSwitcherScreen({super.key});

  @override
  ConsumerState<DemoUserSwitcherScreen> createState() => _DemoUserSwitcherScreenState();
}

class _DemoUserSwitcherScreenState extends ConsumerState<DemoUserSwitcherScreen> {
  bool _loading = true;
  String? _error;
  String? _switchingId;
  List<DemoUserSummary> _users = [];

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
      final users = await ref.read(authRepositoryProvider).listDemoUsers();
      setState(() => _users = users);
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _switchTo(DemoUserSummary user) async {
    setState(() => _switchingId = user.id);
    try {
      final result = await ref.read(authRepositoryProvider).demoLoginAs(user.id);
      await ref.read(sessionControllerProvider.notifier).loginWith(result.accessToken, result.user);
      // Router redirect logic takes it from here (lands on the map home).
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
      setState(() => _switchingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Switch demo user'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _users.isEmpty
                  ? const Center(child: Text('No seeded demo users yet.'))
                  : ListView.builder(
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        final busy = _switchingId == user.id;
                        return ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.person)),
                          title: Text(user.name ?? 'Unnamed'),
                          subtitle: Text(
                            [user.area, user.pincode].where((s) => (s ?? '').isNotEmpty).join(' · '),
                          ),
                          trailing: busy
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.login),
                          onTap: _switchingId == null ? () => _switchTo(user) : null,
                        );
                      },
                    ),
    );
  }
}
