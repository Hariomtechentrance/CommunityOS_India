class CoinTransaction {
  final String id;
  final String type;
  final int amount;
  final String? description;
  final DateTime createdAt;

  CoinTransaction({
    required this.id,
    required this.type,
    required this.amount,
    this.description,
    required this.createdAt,
  });

  factory CoinTransaction.fromJson(Map<String, dynamic> json) => CoinTransaction(
        id: json['id'] as String,
        type: json['type'] as String,
        amount: json['amount'] as int,
        description: json['description'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class WalletBalance {
  final int balanceCoins;
  final List<CoinTransaction> transactions;

  WalletBalance({required this.balanceCoins, required this.transactions});

  factory WalletBalance.fromJson(Map<String, dynamic> json) => WalletBalance(
        balanceCoins: json['balanceCoins'] as int,
        transactions: (json['transactions'] as List)
            .map((e) => CoinTransaction.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class PayoutRequest {
  final String id;
  final int amountCoins;
  final int amountInPaise;
  final String payeeName;
  final String? upiId;
  final String status;
  final String? adminNote;
  final DateTime createdAt;

  PayoutRequest({
    required this.id,
    required this.amountCoins,
    required this.amountInPaise,
    required this.payeeName,
    this.upiId,
    required this.status,
    this.adminNote,
    required this.createdAt,
  });

  factory PayoutRequest.fromJson(Map<String, dynamic> json) => PayoutRequest(
        id: json['id'] as String,
        amountCoins: json['amountCoins'] as int,
        amountInPaise: json['amountInPaise'] as int,
        payeeName: json['payeeName'] as String,
        upiId: json['upiId'] as String?,
        status: json['status'] as String,
        adminNote: json['adminNote'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
