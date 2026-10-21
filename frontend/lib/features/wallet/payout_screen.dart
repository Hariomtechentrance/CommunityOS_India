import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/widgets/max_width_box.dart';
import '../../models/wallet.dart';
import 'wallet_repository.dart';

// ₹1 = 10 coins, matches backend/src/wallet/wallet.service.ts.
const _minPayoutCoins = 500;

class PayoutScreen extends ConsumerStatefulWidget {
  const PayoutScreen({super.key});

  @override
  ConsumerState<PayoutScreen> createState() => _PayoutScreenState();
}

class _PayoutScreenState extends ConsumerState<PayoutScreen> {
  final _amountController = TextEditingController();
  final _nameController = TextEditingController();
  final _upiController = TextEditingController();
  final _accountController = TextEditingController();
  final _ifscController = TextEditingController();
  bool _useUpi = true;
  bool _submitting = false;
  bool _loadingHistory = true;
  String? _error;
  int _balanceCoins = 0;
  List<PayoutRequest> _history = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _nameController.dispose();
    _upiController.dispose();
    _accountController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loadingHistory = true);
    try {
      final results = await Future.wait([
        ref.read(walletRepositoryProvider).getBalance(),
        ref.read(walletRepositoryProvider).listMyPayouts(),
      ]);
      setState(() {
        _balanceCoins = (results[0] as WalletBalance).balanceCoins;
        _history = results[1] as List<PayoutRequest>;
      });
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  Future<void> _submit() async {
    final amount = int.tryParse(_amountController.text.trim());
    if (amount == null || amount < _minPayoutCoins) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Minimum payout is $_minPayoutCoins coins (₹${_minPayoutCoins ~/ 10}).')),
      );
      return;
    }
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the name on your bank/UPI account.')),
      );
      return;
    }
    if (_useUpi && _upiController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter your UPI ID.')));
      return;
    }
    if (!_useUpi && (_accountController.text.trim().isEmpty || _ifscController.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your account number and IFSC code.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(walletRepositoryProvider).requestPayout(
            amountCoins: amount,
            payeeName: _nameController.text.trim(),
            upiId: _useUpi ? _upiController.text.trim() : null,
            bankAccountNumber: _useUpi ? null : _accountController.text.trim(),
            bankIfsc: _useUpi ? null : _ifscController.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payout requested. We\'ll process it within a few business days.')),
      );
      _amountController.clear();
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Color _statusColor(String status) => switch (status) {
        'PENDING' => Colors.orange,
        'APPROVED' => Colors.blue,
        'PAID' => Colors.green,
        'REJECTED' => Colors.red,
        _ => Colors.grey,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request a payout')),
      body: MaxWidthBox(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Available balance', style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 4),
                      Text('🪙 $_balanceCoins', style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      Text(
                        'Minimum payout is $_minPayoutCoins coins (₹${_minPayoutCoins ~/ 10}). '
                        'Payouts are reviewed and paid out by our team within a few business days.',
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount (coins)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name on account',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('UPI')),
                  ButtonSegment(value: false, label: Text('Bank account')),
                ],
                selected: {_useUpi},
                onSelectionChanged: (s) => setState(() => _useUpi = s.first),
              ),
              const SizedBox(height: 12),
              if (_useUpi)
                TextField(
                  controller: _upiController,
                  decoration: const InputDecoration(
                    labelText: 'UPI ID',
                    hintText: 'yourname@okaxis',
                    border: OutlineInputBorder(),
                  ),
                )
              else ...[
                TextField(
                  controller: _accountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Account number',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _ifscController,
                  decoration: const InputDecoration(
                    labelText: 'IFSC code',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit request'),
              ),
              const SizedBox(height: 28),
              Text('Payout history', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (_loadingHistory)
                const Center(child: CircularProgressIndicator())
              else if (_error != null)
                Text(_error!)
              else if (_history.isEmpty)
                const Text('No payout requests yet.')
              else
                ..._history.map(
                  (p) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text('🪙 ${p.amountCoins} · ₹${(p.amountInPaise / 100).toStringAsFixed(0)}'),
                      subtitle: Text(p.adminNote ?? p.createdAt.toLocal().toString().split('.').first),
                      trailing: Text(
                        p.status,
                        style: TextStyle(color: _statusColor(p.status), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
