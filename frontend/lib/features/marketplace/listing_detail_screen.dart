import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/session/session_controller.dart';
import '../../core/widgets/max_width_box.dart';
import '../../models/listing.dart';
import 'listing_repository.dart';

class ListingDetailScreen extends ConsumerStatefulWidget {
  final String listingId;

  const ListingDetailScreen({super.key, required this.listingId});

  @override
  ConsumerState<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends ConsumerState<ListingDetailScreen> {
  bool _loading = true;
  String? _error;
  Listing? _listing;

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
      final listing = await ref.read(listingRepositoryProvider).getById(societyId, widget.listingId);
      setState(() => _listing = listing);
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleStatus() async {
    final societyId = ref.read(sessionControllerProvider).value?.society?.id;
    if (societyId == null || _listing == null) return;
    final newStatus =
        _listing!.status == ListingStatus.active ? ListingStatus.closed : ListingStatus.active;
    try {
      await ref.read(listingRepositoryProvider).updateStatus(societyId, widget.listingId, newStatus);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(sessionControllerProvider).value?.user?.id;
    final isOwner = _listing != null && userId != null && _listing!.seller?.id == userId;

    return Scaffold(
      appBar: AppBar(title: const Text('Listing')),
      body: MaxWidthBox(
        child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _listing == null
                  ? const SizedBox.shrink()
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (_listing!.imageUrls.isNotEmpty)
                          SizedBox(
                            height: 240,
                            child: PageView(
                              children: _listing!.imageUrls
                                  .map(
                                    (url) => ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        url,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => const ColoredBox(
                                          color: Color(0xFFEEEEEE),
                                          child: Icon(Icons.image_not_supported),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Chip(label: Text(listingCategoryLabel(_listing!.category))),
                            const SizedBox(width: 8),
                            if (_listing!.status == ListingStatus.closed)
                              const Chip(label: Text('Closed')),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(_listing!.title, style: Theme.of(context).textTheme.headlineSmall),
                        if (_listing!.price != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '₹${_listing!.price!.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                        const SizedBox(height: 12),
                        Text(_listing!.description),
                        const SizedBox(height: 16),
                        if (_listing!.seller != null)
                          Row(
                            children: [
                              const Icon(Icons.person, size: 18),
                              const SizedBox(width: 6),
                              Expanded(child: Text('Seller: ${_listing!.seller!.phone}')),
                            ],
                          ),
                        if (isOwner) ...[
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: _toggleStatus,
                            child: Text(
                              _listing!.status == ListingStatus.active
                                  ? 'Mark as closed'
                                  : 'Reactivate listing',
                            ),
                          ),
                        ],
                      ],
                    ),
      ),
    );
  }
}
