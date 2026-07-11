import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/api_client.dart';
import '../../core/session/session_controller.dart';
import '../../models/area_post.dart';
import '../area/area_repository.dart';
import '../users/user_repository.dart';

/// Focused, minimal-friction emergency posting flow - not the generic New
/// Post form. Alerts everyone in the same pincode in real time the moment
/// this is submitted (see EmergencyAlertService on the backend).
class EmergencySosScreen extends ConsumerStatefulWidget {
  const EmergencySosScreen({super.key});

  @override
  ConsumerState<EmergencySosScreen> createState() => _EmergencySosScreenState();
}

class _EmergencySosScreenState extends ConsumerState<EmergencySosScreen> {
  final _descriptionController = TextEditingController();
  EmergencyCategory _category = EmergencyCategory.accident;
  String? _area;
  bool _locating = false;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _area = ref.read(sessionControllerProvider).value?.user?.area;
  }

  Future<void> _useMyLocation() async {
    setState(() {
      _locating = true;
      _error = null;
    });
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location services are disabled on this device.');
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission denied.');
      }
      final position = await Geolocator.getCurrentPosition();
      final area = await ref
          .read(userRepositoryProvider)
          .detectArea(lat: position.latitude, lng: position.longitude);
      if (area != null) setState(() => _area = area);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _submit() async {
    if (_area == null || _area!.isEmpty) {
      setState(() => _error = 'We need an area/locality to alert people nearby.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(areaRepositoryProvider).create(
            area: _area!,
            kind: AreaPostKind.emergencySos,
            title: '${emergencyCategoryLabel(_category)} - urgent help needed',
            description: _descriptionController.text.trim().isEmpty
                ? 'No further details provided.'
                : _descriptionController.text.trim(),
            emergencyCategory: _category,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency SOS'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: const [
                    Icon(Icons.emergency, color: Colors.red, size: 32),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This instantly alerts everyone nearby (same pincode) with a '
                        'real-time alert and a push notification.',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text('What kind of emergency?', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: EmergencyCategory.values
                      .map(
                        (category) => ChoiceChip(
                          label: Text(emergencyCategoryLabel(category)),
                          selected: _category == category,
                          onSelected: (_) => setState(() => _category = category),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Details (optional)',
                    hintText: 'Where exactly, what happened, what help is needed',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _area == null || _area!.isEmpty
                            ? 'No area set'
                            : 'Alerting: $_area',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _locating ? null : _useMyLocation,
                      icon: _locating
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location, size: 18),
                      label: const Text('Use current location'),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'SEND EMERGENCY ALERT',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
