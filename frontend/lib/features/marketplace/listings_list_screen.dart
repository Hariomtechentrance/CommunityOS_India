import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import '../../core/session/session_controller.dart';
import '../../models/listing.dart';
import 'create_listing_screen.dart';
import 'listing_repository.dart';

class ListingsListScreen extends ConsumerStatefulWidget {
  const ListingsListScreen({super.key});

  @override
  ConsumerState<ListingsListScreen> createState() => _ListingsListScreenState();
}

class _ListingsListScreenState extends ConsumerState<ListingsListScreen> {
  bool _loading = true;
  String? _error;
  List<Listing> _listings = [];
  ListingCategory? _filter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final societyId = ref.read(sessionControllerProvider).value?.society?.id;
    if (societyId == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final listings = await ref.read(listingRepositoryProvider).list(societyId, category: _filter);
      setState(() => _listings = listings);
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Marketplace')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final posted = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const CreateListingScreen()),
          );
          if (posted == true) _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('Sell / Rent / Give away'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: _filter == null,
                  onSelected: (_) {
                    setState(() => _filter = null);
                    _load();
                  },
                ),
                ...ListingCategory.values.map(
                  (category) => ChoiceChip(
                    label: Text(listingCategoryLabel(category)),
                    selected: _filter == category,
                    onSelected: (_) {
                      setState(() => _filter = category);
                      _load();
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!))
                      : _listings.isEmpty
                          ? ListView(
                              children: const [
                                Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Text('No listings yet. Post the first one.'),
                                ),
                              ],
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 260,
                                mainAxisExtent: 260,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: _listings.length,
                              itemBuilder: (context, index) {
                                final listing = _listings[index];
                                return Card(
                                  clipBehavior: Clip.antiAlias,
                                  child: InkWell(
                                    onTap: () =>
                                        context.push('/home/society/marketplace/${listing.id}'),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        AspectRatio(
                                          aspectRatio: 1.4,
                                          child: listing.imageUrls.isNotEmpty
                                              ? Image.network(
                                                  listing.imageUrls.first,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, _, _) => const ColoredBox(
                                                    color: Color(0xFFEEEEEE),
                                                    child: Icon(Icons.image_not_supported),
                                                  ),
                                                )
                                              : const ColoredBox(
                                                  color: Color(0xFFEEEEEE),
                                                  child: Icon(Icons.image, size: 40),
                                                ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                listing.title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: Theme.of(context).textTheme.titleSmall,
                                              ),
                                              Text(
                                                listing.price != null
                                                    ? '₹${listing.price!.toStringAsFixed(0)}'
                                                    : listingCategoryLabel(listing.category),
                                                style: Theme.of(context).textTheme.bodySmall,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }
}
