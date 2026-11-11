import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/api_client.dart';
import '../../core/media_upload_service.dart';
import '../../core/widgets/max_width_box.dart';
import 'business_repository.dart';

class EditBusinessProfileScreen extends ConsumerStatefulWidget {
  const EditBusinessProfileScreen({super.key});

  @override
  ConsumerState<EditBusinessProfileScreen> createState() => _EditBusinessProfileScreenState();
}

class _EditBusinessProfileScreenState extends ConsumerState<EditBusinessProfileScreen> {
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _websiteController = TextEditingController();
  String? _logoUrl;
  bool _loading = true;
  bool _submitting = false;
  bool _uploadingLogo = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final profile = await ref.read(businessRepositoryProvider).getMyProfile();
      if (profile != null) {
        _nameController.text = profile.businessName;
        _categoryController.text = profile.category;
        _descriptionController.text = profile.description ?? '';
        _websiteController.text = profile.website ?? '';
        _logoUrl = profile.logoUrl;
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickLogo() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    setState(() => _uploadingLogo = true);
    try {
      final url = await ref.read(mediaUploadServiceProvider).upload(picked);
      setState(() => _logoUrl = url);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _uploadingLogo = false);
    }
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty || _categoryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business name and category are required.')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(businessRepositoryProvider).upsertProfile(
            businessName: _nameController.text.trim(),
            category: _categoryController.text.trim(),
            description: _descriptionController.text.trim(),
            logoUrl: _logoUrl,
            website: _websiteController.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Business profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : MaxWidthBox(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Center(
                    child: InkWell(
                      onTap: _uploadingLogo ? null : _pickLogo,
                      borderRadius: BorderRadius.circular(48),
                      child: CircleAvatar(
                        radius: 48,
                        backgroundImage: _logoUrl != null ? NetworkImage(_logoUrl!) : null,
                        child: _uploadingLogo
                            ? const CircularProgressIndicator()
                            : _logoUrl == null
                                ? const Icon(Icons.add_a_photo_outlined, size: 32)
                                : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Business name',
                      hintText: 'Satpur Fresh Mart',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _categoryController,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      hintText: 'Grocery, Salon, Tuition classes...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _websiteController,
                    decoration: const InputDecoration(
                      labelText: 'Website / social link (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save'),
                  ),
                ],
              ),
            ),
    );
  }
}
