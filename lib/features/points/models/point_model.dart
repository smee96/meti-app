class PointWallet {
  final int balance;
  final int totalEarned;
  final int totalSpent;
  final String? updatedAt;

  PointWallet({
    required this.balance,
    required this.totalEarned,
    required this.totalSpent,
    this.updatedAt,
  });

  factory PointWallet.fromJson(Map<String, dynamic> json) {
    return PointWallet(
      balance: json['balance'] as int? ?? 0,
      totalEarned: json['total_earned'] as int? ?? 0,
      totalSpent: json['total_spent'] as int? ?? 0,
      updatedAt: json['updated_at'] as String?,
    );
  }

  PointWallet empty() => PointWallet(balance: 0, totalEarned: 0, totalSpent: 0);
}

class PointTransaction {
  final int id;
  final String type; // 'earn' | 'spend'
  final int amount;  // 음수 가능 (spend 시)
  final int balanceAfter;
  final String description;
  final String? createdAt;

  PointTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    required this.description,
    this.createdAt,
  });

  factory PointTransaction.fromJson(Map<String, dynamic> json) {
    return PointTransaction(
      id: json['id'] as int? ?? 0,
      type: json['type'] as String? ?? 'earn',
      amount: json['amount'] as int? ?? 0,
      balanceAfter: json['balance_after'] as int? ?? 0,
      description: json['description'] as String? ?? '',
      createdAt: json['created_at'] as String?,
    );
  }

  bool get isEarn => type == 'earn';
}
