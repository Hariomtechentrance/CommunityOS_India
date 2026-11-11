import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/session/session_controller.dart';
import '../../core/widgets/max_width_box.dart';
import '../../models/business.dart';
import 'business_repository.dart';
import 'catalog_item_form_screen.dart';

/// Owner's own catalog management (add/edit/delete). The read-only, public
/// version customers browse lives in PublicBusinessProfileScreen.
class BusinessCatalogScreen extends ConsumerStatefulWidget {
  const BusinessCatalogScreen({super.key});

  @override
  ConsumerState<BusinessCatalogScreen> createState() => _BusinessCatalogScreenState();
}

class _BusinessCatalogScreenState extends ConsumerState<BusinessCatalogScreen> {
  bool _loading = true;
  String? _error;
  List<BusinessCatalogItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = ref.read(sessionControllerProvider).value?.user?.id;
    if (userId == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await ref.read(businessRepositoryProvider).listCatalog(userId);
      setState(() => _items = items);
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm({BusinessCatalogItem? item}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CatalogItemFormScreen(item: item)),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(BusinessCatalogItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove item?'),
        content: Text('Delete "${item.name}" from your catalog?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(businessRepositoryProvider).deleteCatalogItem(item.id);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My catalog')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add item'),
      ),
      body: MaxWidthBox(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : _items.isEmpty
                    ? const Center(child: Text('No catalog items yet. Add your first product or service.'))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _items.length,
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            return Card(
                              child: ListTile(
                                leading: item.imageUrls.isNotEmpty
                                    ? CircleAvatar(backgroundImage: NetworkImage(item.imageUrls.first))
                                    : const CircleAvatar(child: Icon(Icons.inventory_2_outlined)),
                                title: Text(item.name),
                                subtitle: Text([
                                  if (item.price != null) '₹${item.price}',
                                  item.inStock ? 'In stock' : 'Out of stock',
                                  '${item.viewCount} views',
                                ].join(' · ')),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'edit') _openForm(item: item);
                                    if (value == 'delete') _delete(item);
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
      ),
    );
  }
}
