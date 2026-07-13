import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import '../../core/session/session_controller.dart';
import '../../core/widgets/max_width_box.dart';
import '../../models/area_post.dart';
import '../area/area_repository.dart';

const _businessSubCategories = ['All', 'Cafes', 'Stores', 'Medical', 'Salons'];

/// Keywords matched (contains, case-insensitive) against the free-text
/// `businessCategory` field for each sub-category chip.
const _subCategoryKeywords = {
  'Cafes': ['cafe', 'coffee', 'bakery'],
  'Stores': ['store', 'grocery', 'shop', 'mart'],
  'Medical': ['medical', 'clinic', 'pharmacy', 'doctor', 'hospital'],
  'Salons': ['salon', 'spa', 'parlour', 'parlor'],
};

/// Business/local-discovery tab - Shop posts for the user's area, filterable
/// by a lightweight sub-category chip row matched client-side against the
/// free-text `businessCategory` field (see plan for why this stays free
/// text rather than a rigid enum).
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  bool _loading = true;
  String? _error;
  List<AreaPost> _shops = [];
  String _subCategory = 'All';

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
      final shops = await ref
          .read(areaRepositoryProvider)
          .list(user!.area!, kind: AreaPostKind.shop);
      setState(() => _shops = shops);
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleSave(AreaPost shop) async {
    try {
      await ref.read(areaRepositoryProvider).toggleSave(shop.id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    }
  }

  List<AreaPost> get _filteredShops {
    if (_subCategory == 'All') return _shops;
    final keywords = _subCategoryKeywords[_subCategory] ?? const [];
    return _shops.where((shop) {
      final category = shop.businessCategory?.toLowerCase() ?? '';
      return keywords.any(category.contains);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionControllerProvider).value?.user;
    final shops = _filteredShops;

    return Scaffold(
      appBar: AppBar(
        title: Text('New to ${user?.area ?? 'your area'}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'View on map',
            onPressed: () => context.push('/home/explore-map'),
          ),
        ],
      ),
      body: MaxWidthBox(
        maxWidth: 900,
        child: RefreshIndicator(
          onRefresh: _load,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _businessSubCategories
                        .map(
                          (category) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(category),
                              selected: _subCategory == category,
                              onSelected: (_) => setState(() => _subCategory = category),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(child: Text(_error!))
                        : shops.isEmpty
                            ? ListView(
                                children: const [
                                  Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Text('No new businesses posted here yet.'),
                                  ),
                                ],
                              )
                            : GridView.builder(
                                padding: const EdgeInsets.all(16),
                                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 300,
                                  mainAxisExtent: 300,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                                itemCount: shops.length,
                                itemBuilder: (context, index) {
                                  final shop = shops[index];
                                  return Card(
                                    clipBehavior: Clip.antiAlias,
                                    child: InkWell(
                                      onTap: () => context.push('/home/posts/${shop.id}'),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          AspectRatio(
                                            aspectRatio: 1.6,
                                            child: shop.imageUrls.isNotEmpty
                                                ? Image.network(
                                                    shop.imageUrls.first,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, _, _) => const ColoredBox(
                                                      color: Color(0xFFEEEEEE),
                                                      child: Icon(Icons.storefront, size: 40),
                                                    ),
                                                  )
                                                : const ColoredBox(
                                                    color: Color(0xFFEEEEEE),
                                                    child: Icon(Icons.storefront, size: 40),
                                                  ),
                                          ),
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.all(10),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    shop.title,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: Theme.of(context).textTheme.titleSmall,
                                                  ),
                                                  if (shop.businessCategory != null)
                                                    Text(
                                                      shop.businessCategory!,
                                                      style: Theme.of(context).textTheme.bodySmall,
                                                    ),
                                                  if (shop.businessHours != null)
                                                    Text(
                                                      shop.businessHours!,
                                                      style: Theme.of(context).textTheme.bodySmall,
                                                    ),
                                                  const Spacer(),
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: OutlinedButton(
                                                          onPressed: () =>
                                                              context.push('/home/posts/${shop.id}'),
                                                          child: const Text('View Details'),
                                                        ),
                                                      ),
                                                      IconButton(
                                                        icon: Icon(
                                                          shop.mySaved
                                                              ? Icons.bookmark
                                                              : Icons.bookmark_border,
                                                        ),
                                                        onPressed: () => _toggleSave(shop),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
