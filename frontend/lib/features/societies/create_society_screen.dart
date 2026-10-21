import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/session/session_controller.dart';
import '../../models/society.dart';
import '../membership/membership_repository.dart';
import 'society_repository.dart';

class CreateSocietyScreen extends ConsumerStatefulWidget {
  const CreateSocietyScreen({super.key});

  @override
  ConsumerState<CreateSocietyScreen> createState() => _CreateSocietyScreenState();
}

class _CreateSocietyScreenState extends ConsumerState<CreateSocietyScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _emailDomainController = TextEditingController();
  SocietyType _type = SocietyType.apartment;
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final society = await ref.read(societyRepositoryProvider).create(
            name: _nameController.text.trim(),
            addressLine: _addressController.text.trim(),
            city: _cityController.text.trim(),
            state: _stateController.text.trim(),
            pincode: _pincodeController.text.trim(),
            type: _type,
            emailDomain:
                _type == SocietyType.college ? _emailDomainController.text.trim() : null,
          );
      final membership =
          await ref.read(membershipRepositoryProvider).findMine(society.id);
      await ref
          .read(sessionControllerProvider.notifier)
          .selectSociety(society, membership);
      // Router redirect logic takes it from here.
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _emailDomainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create a society')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'You will become this society\'s Committee Admin automatically.',
                ),
                const SizedBox(height: 16),
                SegmentedButton<SocietyType>(
                  segments: const [
                    ButtonSegment(
                      value: SocietyType.apartment,
                      label: Text('Apartment / Society'),
                      icon: Icon(Icons.apartment),
                    ),
                    ButtonSegment(
                      value: SocietyType.college,
                      label: Text('College'),
                      icon: Icon(Icons.school),
                    ),
                    ButtonSegment(
                      value: SocietyType.business,
                      label: Text('Local community'),
                      icon: Icon(Icons.storefront),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (s) => setState(() => _type = s.first),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: switch (_type) {
                      SocietyType.college => 'College name',
                      SocietyType.business => 'Community name',
                      SocietyType.apartment => 'Society name',
                    },
                    hintText: switch (_type) {
                      SocietyType.college => 'Sandip University',
                      SocietyType.business => 'Bangalore Food Community',
                      SocietyType.apartment => 'Prestige Lakeside Habitat',
                    },
                    border: const OutlineInputBorder(),
                  ),
                ),
                if (_type == SocietyType.college) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailDomainController,
                    decoration: const InputDecoration(
                      labelText: 'College email domain (optional)',
                      hintText: 'sandipuniversity.edu.in',
                      helperText:
                          'Shown to joiners as what their college email should end with. '
                          'Not independently verified - you still approve each request.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'City',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _stateController,
                  decoration: const InputDecoration(
                    labelText: 'State',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _pincodeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Pincode',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create society'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
