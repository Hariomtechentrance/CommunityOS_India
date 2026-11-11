import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/api_client.dart';
import '../../core/media_upload_service.dart';
import '../../core/widgets/max_width_box.dart';
import '../../models/business.dart';
import 'business_repository.dart';

class CatalogItemFormScreen extends ConsumerStatefulWidget {
  final BusinessCatalogItem? item;

  const CatalogItemFormScreen({super.key, this.item});

  @override
  ConsumerState<CatalogItemFormScreen> createState() => _CatalogItemFormScreenState();
}

class _CatalogItemFormScreenState extends ConsumerState<CatalogItemFormScreen> {
  late final _nameController = TextEditingController(text: widget.item?.name ?? '');
  late final _descriptionController = TextEditingController(text: widget.item?.description ?? '');
  late final _priceController = TextEditingController(text: widget.item?.price?.toString() ?? '');
  late List<String> _imageUrls = List.of(widget.item?.imageUrls ?? const []);
  late bool _inStock = widget.item?.inStock ?? true;
  bool _submitting = false;
  bool _uploadingImage = false;

  bool get _isEditing => widget.item != null;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    setState(() => _uploadingImage = true);
    try {
      final url = await ref.read(mediaUploadServiceProvider).upload(picked);
      setState(() => _imageUrls = [..._imageUrls, url]);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item name is required.')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final repo = ref.read(businessRepositoryProvider);
      final price = num.tryParse(_priceController.text.trim());
      if (_isEditing) {
        await repo.updateCatalogItem(
          widget.item!.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          price: price,
          imageUrls: _imageUrls,
          inStock: _inStock,
        );
      } else {
        await repo.addCatalogItem(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          price: price,
          imageUrls: _imageUrls,
          inStock: _inStock,
        );
      }
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
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit item' : 'Add catalog item')),
      body: MaxWidthBox(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SizedBox(
              height: 90,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ..._imageUrls.map(
                    (url) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(url, width: 90, height: 90, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: InkWell(
                              onTap: () => setState(() => _imageUrls = _imageUrls.where((u) => u != url).toList()),
                              child: const CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.black54,
                                child: Icon(Icons.close, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: _uploadingImage ? null : _pickImage,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _uploadingImage
                          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.add_a_photo_outlined),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Alphonso Mango (1kg)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Price (₹, optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('In stock'),
              value: _inStock,
              onChanged: (v) => setState(() => _inStock = v),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_isEditing ? 'Save changes' : 'Add item'),
            ),
          ],
        ),
      ),
    );
  }
}
