import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api_client.dart';
import '../../core/media_upload_service.dart';
import '../../core/session/session_controller.dart';
import '../../models/campaign.dart';
import 'campaigns_repository.dart';
import 'indian_states.dart';

const _objectiveLabels = {
  CampaignObjective.sales: 'Sales',
  CampaignObjective.downloads: 'Downloads',
  CampaignObjective.awareness: 'Awareness',
  CampaignObjective.engagement: 'Engagement',
};

const _objectiveIcons = {
  CampaignObjective.sales: Icons.storefront_outlined,
  CampaignObjective.downloads: Icons.download_outlined,
  CampaignObjective.awareness: Icons.campaign_outlined,
  CampaignObjective.engagement: Icons.thumb_up_outlined,
};

/// Lets any registered user run a paid ad campaign (Meta/Google-Ads style):
/// pick an objective, write the creative, choose who sees it (nearby radius,
/// same pincode, hand-picked states, or all of India), set a budget, then
/// hand off to Razorpay Payment Links for the actual charge.
class CreateCampaignScreen extends ConsumerStatefulWidget {
  const CreateCampaignScreen({super.key});

  @override
  ConsumerState<CreateCampaignScreen> createState() => _CreateCampaignScreenState();
}

class _CreateCampaignScreenState extends ConsumerState<CreateCampaignScreen> {
  CampaignObjective _objective = CampaignObjective.awareness;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _ctaUrlController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _budgetController = TextEditingController(text: '500');
  CampaignTargetType _targetType = CampaignTargetType.nearby;
  double _radiusKm = 10;
  final Set<String> _selectedStates = {};
  XFile? _image;
  Uint8List? _imageBytes;
  bool _loading = false;
  String? _error;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _image = picked;
      _imageBytes = bytes;
    });
  }

  Future<void> _submit() async {
    final user = ref.read(sessionControllerProvider).value?.user;
    if (_titleController.text.trim().isEmpty || _descriptionController.text.trim().isEmpty) {
      setState(() => _error = 'Title and description are required.');
      return;
    }
    final budgetRupees = double.tryParse(_budgetController.text.trim());
    if (budgetRupees == null || budgetRupees < 100) {
      setState(() => _error = 'Minimum budget is ₹100.');
      return;
    }
    if (_targetType == CampaignTargetType.pincode && _pincodeController.text.trim().isEmpty) {
      setState(() => _error = 'Enter a pincode to target.');
      return;
    }
    if (_targetType == CampaignTargetType.states && _selectedStates.isEmpty) {
      setState(() => _error = 'Pick at least one state.');
      return;
    }
    if (_targetType == CampaignTargetType.nearby && (user?.latitude == null || user?.longitude == null)) {
      setState(() => _error = 'Set your location in your profile before targeting a nearby radius.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      String? imageUrl;
      if (_image != null) {
        imageUrl = await MediaUploadService().upload(_image!);
      }
      final campaign = await ref.read(campaignsRepositoryProvider).create(
            objective: _objective,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            imageUrl: imageUrl,
            ctaUrl: _ctaUrlController.text.trim(),
            targetType: _targetType,
            targetPincode: _targetType == CampaignTargetType.pincode
                ? _pincodeController.text.trim()
                : null,
            targetStates: _targetType == CampaignTargetType.states ? _selectedStates.toList() : null,
            targetLatitude: _targetType == CampaignTargetType.nearby ? user!.latitude : null,
            targetLongitude: _targetType == CampaignTargetType.nearby ? user!.longitude : null,
            targetRadiusKm: _targetType == CampaignTargetType.nearby ? _radiusKm : null,
            budgetInPaise: (budgetRupees * 100).round(),
          );

      if (!mounted) return;
      final checkoutUrl = await ref.read(campaignsRepositoryProvider).checkout(campaign.id);
      final uri = Uri.parse(checkoutUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create ad campaign')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Objective', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: CampaignObjective.values.map((o) {
                final selected = _objective == o;
                return ChoiceChip(
                  label: Text(_objectiveLabels[o]!),
                  avatar: Icon(_objectiveIcons[o], size: 18),
                  selected: selected,
                  onSelected: (_) => setState(() => _objective = o),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text('Creative', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(12),
                  image: _imageBytes != null
                      ? DecorationImage(image: MemoryImage(_imageBytes!), fit: BoxFit.cover)
                      : null,
                ),
                child: _image == null
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, size: 32),
                            SizedBox(height: 4),
                            Text('Add an image (optional)'),
                          ],
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Headline', border: OutlineInputBorder()),
              maxLength: 60,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
              maxLines: 3,
              maxLength: 200,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ctaUrlController,
              decoration: const InputDecoration(
                labelText: 'Link when tapped (optional)',
                hintText: 'https://...',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 24),
            Text('Who should see this?', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<CampaignTargetType>(
              segments: const [
                ButtonSegment(value: CampaignTargetType.nearby, label: Text('Nearby')),
                ButtonSegment(value: CampaignTargetType.pincode, label: Text('Pincode')),
                ButtonSegment(value: CampaignTargetType.states, label: Text('States')),
                ButtonSegment(value: CampaignTargetType.allIndia, label: Text('All India')),
              ],
              selected: {_targetType},
              onSelectionChanged: (s) => setState(() => _targetType = s.first),
            ),
            const SizedBox(height: 12),
            if (_targetType == CampaignTargetType.nearby) ...[
              Text('Radius: ${_radiusKm.round()} km around your location'),
              Slider(
                value: _radiusKm,
                min: 1,
                max: 25,
                divisions: 24,
                label: '${_radiusKm.round()} km',
                onChanged: (v) => setState(() => _radiusKm = v),
              ),
            ],
            if (_targetType == CampaignTargetType.pincode)
              TextField(
                controller: _pincodeController,
                decoration: const InputDecoration(labelText: 'Pincode', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
            if (_targetType == CampaignTargetType.states)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: indianStates.map((s) {
                  final selected = _selectedStates.contains(s);
                  return FilterChip(
                    label: Text(s),
                    selected: selected,
                    onSelected: (v) => setState(() {
                      if (v) {
                        _selectedStates.add(s);
                      } else {
                        _selectedStates.remove(s);
                      }
                    }),
                  );
                }).toList(),
              ),
            if (_targetType == CampaignTargetType.allIndia)
              const Text('This ad will be shown to users across India.'),
            const SizedBox(height: 24),
            Text('Budget', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _budgetController,
              decoration: const InputDecoration(
                labelText: 'Total budget (₹)',
                prefixText: '₹ ',
                helperText: 'Minimum ₹100. Paid once via Razorpay before the campaign goes live.',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Continue to payment'),
            ),
          ],
        ),
      ),
    );
  }
}
