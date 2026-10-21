import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api_client.dart';
import '../../core/widgets/max_width_box.dart';
import '../../models/wallet.dart';
import 'wallet_repository.dart';

// ₹1 = 10 coins, matches backend/src/wallet/wallet.service.ts.
const _coinPackages = [
  (priceInPaise: 1000, label: '₹10 · 100 coins'),
  (priceInPaise: 5000, label: '₹50 · 500 coins'),
  (priceInPaise: 10000, label: '₹100 · 1,000 coins'),
  (priceInPaise: 50000, label: '₹500 · 5,000 coins'),
];

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  bool _loading = true;
  bool _purchasing = false;
  String? _error;
  WalletBalance? _balance;

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
      final balance = await ref.read(walletRepositoryProvider).getBalance();
      setState(() => _balance = balance);
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _buy(int priceInPaise) async {
    setState(() => _purchasing = true);
    try {
      final checkoutUrl = await ref.read(walletRepositoryProvider).purchase(priceInPaise);
      final uri = Uri.parse(checkoutUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete the payment in your browser, then pull to refresh here.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  String _transactionLabel(CoinTransaction t) {
    switch (t.type) {
      case 'PURCHASE':
        return t.description ?? 'Purchased coins';
      case 'GIFT_SENT':
        return t.description ?? 'Gift sent';
      case 'GIFT_RECEIVED':
        return t.description ?? 'Gift received';
      case 'PAYOUT':
        return t.description ?? 'Payout';
      default:
        return t.type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Niikat Coins')),
      body: MaxWidthBox(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                const Text('Your balance'),
                                const SizedBox(height: 4),
                                Text(
                                  '🪙 ${_balance?.balanceCoins ?? 0}',
                                  style: Theme.of(context).textTheme.headlineMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text('Buy coins', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _coinPackages
                              .map(
                                (pkg) => OutlinedButton(
                                  onPressed: _purchasing ? null : () => _buy(pkg.priceInPaise),
                                  child: Text(pkg.label),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Purchased coins are spent only inside Niikat and can\'t be withdrawn. '
                          'Coins you earn from gifts and tips can be cashed out below.',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                        const SizedBox(height: 20),
                        OutlinedButton.icon(
                          onPressed: () => context.push('/home/wallet/payout'),
                          icon: const Icon(Icons.account_balance_outlined),
                          label: const Text('Request a payout'),
                        ),
                        const SizedBox(height: 24),
                        Text('History', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        if ((_balance?.transactions ?? []).isEmpty)
                          const Text('No transactions yet.')
                        else
                          ...(_balance!.transactions.map(
                            (t) => ListTile(
                              leading: Icon(
                                t.amount >= 0 ? Icons.add_circle_outline : Icons.remove_circle_outline,
                                color: t.amount >= 0 ? Colors.green : Colors.red,
                              ),
                              title: Text(_transactionLabel(t)),
                              trailing: Text(
                                '${t.amount >= 0 ? '+' : ''}${t.amount}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: t.amount >= 0 ? Colors.green : Colors.red,
                                ),
                              ),
                            ),
                          )),
                      ],
                    ),
                  ),
      ),
    );
  }
}
