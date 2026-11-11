import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import '../../core/session/session_controller.dart';
import '../../core/theme.dart';
import '../../core/widgets/max_width_box.dart';
import '../../models/business.dart';
import '../../models/follow.dart';
import '../follows/follows_repository.dart';
import 'business_repository.dart';

/// Read-only storefront a customer sees - business info, catalog, and a
/// follow button (following is what makes them a broadcast recipient).
class PublicBusinessProfileScreen extends ConsumerStatefulWidget {
  final String userId;

  const PublicBusinessProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<PublicBusinessProfileScreen> createState() => _PublicBusinessProfileScreenState();
}

class _PublicBusinessProfileScreenState extends ConsumerState<PublicBusinessProfileScreen> {
  bool _loading = true;
  String? _error;
  BusinessProfile? _profile;
  List<BusinessCatalogItem> _items = [];
  FollowStats? _stats;
  bool _acting = false;

  bool get _isSelf => widget.userId == ref.read(sessionControllerProvider).value?.user?.id;

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
      final results = await Future.wait([
        ref.read(businessRepositoryProvider).getPublicProfile(widget.userId),
        ref.read(businessRepositoryProvider).listCatalog(widget.userId),
        ref.read(followsRepositoryProvider).getStats(widget.userId),
      ]);
      setState(() {
        _profile = results[0] as BusinessProfile;
        _items = results[1] as List<BusinessCatalogItem>;
        _stats = results[2] as FollowStats;
      });
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleFollow() async {
    setState(() => _acting = true);
    try {
      final stats = _stats!.isFollowing == true
          ? await ref.read(followsRepositoryProvider).unfollow(widget.userId)
          : await ref.read(followsRepositoryProvider).follow(widget.userId);
      setState(() => _stats = stats);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _openItem(BusinessCatalogItem item) async {
    try {
      // Fire-and-forget view count increment, same pattern as reel/post views.
      ref.read(businessRepositoryProvider).getCatalogItem(item.id);
    } catch (_) {}
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            if (item.imageUrls.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(item.imageUrls.first, height: 200, fit: BoxFit.cover, width: double.infinity),
              ),
            const SizedBox(height: 12),
            Text(item.name, style: Theme.of(context).textTheme.titleLarge),
            if (item.price != null) ...[
              const SizedBox(height: 4),
              Text('₹${item.price}', style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
            if (item.description != null) ...[
              const SizedBox(height: 8),
              Text(item.description!),
            ],
            const SizedBox(height: 8),
            Text(item.inStock ? 'In stock' : 'Out of stock',
                style: TextStyle(color: item.inStock ? Colors.green : Colors.red)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_profile?.businessName ?? 'Business')),
      body: MaxWidthBox(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final profile = _profile!;
    final stats = _stats!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 44,
                backgroundImage: profile.logoUrl != null ? NetworkImage(profile.logoUrl!) : null,
                child: profile.logoUrl == null ? const Icon(Icons.storefront, size: 36) : null,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(profile.businessName, style: Theme.of(context).textTheme.headlineSmall),
                  if (profile.isVerified) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.verified, size: 18, color: nikatNavy),
                  ],
                ],
              ),
              Text(profile.category, style: const TextStyle(color: Colors.black54)),
              if (profile.user?.area != null) ...[
                const SizedBox(height: 2),
                Text(profile.user!.area!, style: const TextStyle(color: Colors.black54)),
              ],
            ],
          ),
        ),
        if (profile.description != null) ...[
          const SizedBox(height: 16),
          Text(profile.description!),
        ],
        const SizedBox(height: 16),
        if (!_isSelf)
          Row(
            children: [
              Expanded(
                child: stats.isFollowing == true
                    ? OutlinedButton(
                        onPressed: _acting ? null : _toggleFollow,
                        child: const Text('Following'),
                      )
                    : FilledButton(
                        onPressed: _acting ? null : _toggleFollow,
                        child: const Text('Follow for offers'),
                      ),
              ),
              const SizedBox(width: 12),
              IconButton.filled(
                icon: const Icon(Icons.chat_bubble_outline),
                tooltip: 'Message',
                onPressed: () => context.push('/home/messages/${widget.userId}', extra: profile.businessName),
              ),
            ],
          ),
        const Divider(height: 32),
        Text('Catalog', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (_items.isEmpty)
          const Text('No items listed yet.')
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (context, index) {
              final item = _items[index];
              return InkWell(
                onTap: () => _openItem(item),
                borderRadius: BorderRadius.circular(12),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: item.imageUrls.isNotEmpty
                            ? Image.network(item.imageUrls.first, fit: BoxFit.cover, width: double.infinity)
                            : Container(color: Colors.black12, child: const Icon(Icons.inventory_2_outlined)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                            if (item.price != null)
                              Text('₹${item.price}', style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
