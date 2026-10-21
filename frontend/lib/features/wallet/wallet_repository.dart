import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../models/wallet.dart';

class WalletRepository {
  final ApiClient _client;

  WalletRepository(this._client);

  Future<WalletBalance> getBalance() async {
    final res = await _client.dio.get('/wallet');
    return WalletBalance.fromJson(res.data as Map<String, dynamic>);
  }

  Future<String> purchase(int amountInPaise) async {
    final res = await _client.dio.post('/wallet/purchase', data: {'amountInPaise': amountInPaise});
    return res.data['checkoutUrl'] as String;
  }

  Future<WalletBalance> gift(String toUserId, int amount, {String? description}) async {
    final res = await _client.dio.post('/wallet/gift', data: {
      'toUserId': toUserId,
      'amount': amount,
      if (description != null && description.isNotEmpty) 'description': description,
    });
    return WalletBalance.fromJson(res.data as Map<String, dynamic>);
  }

  Future<PayoutRequest> requestPayout({
    required int amountCoins,
    required String payeeName,
    String? upiId,
    String? bankAccountNumber,
    String? bankIfsc,
  }) async {
    final res = await _client.dio.post('/wallet/payouts', data: {
      'amountCoins': amountCoins,
      'payeeName': payeeName,
      if (upiId != null && upiId.isNotEmpty) 'upiId': upiId,
      if (bankAccountNumber != null && bankAccountNumber.isNotEmpty) 'bankAccountNumber': bankAccountNumber,
      if (bankIfsc != null && bankIfsc.isNotEmpty) 'bankIfsc': bankIfsc,
    });
    return PayoutRequest.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<PayoutRequest>> listMyPayouts() async {
    final res = await _client.dio.get('/wallet/payouts');
    return (res.data as List).map((e) => PayoutRequest.fromJson(e as Map<String, dynamic>)).toList();
  }
}

final walletRepositoryProvider = Provider<WalletRepository>(
  (ref) => WalletRepository(ref.read(apiClientProvider)),
);
