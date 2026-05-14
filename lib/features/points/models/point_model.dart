// v2.8: expiring_soon 구조 추가, PointTransaction type 값 v2.8 스펙 반영

class PointExpiringSoon {
  final int amount;
  final String expiresAt;

  PointExpiringSoon({required this.amount, required this.expiresAt});

  factory PointExpiringSoon.fromJson(Map<String, dynamic> json) {
    return PointExpiringSoon(
      amount: json['amount'] as int? ?? 0,
      expiresAt: json['expires_at'] as String? ?? '',
    );
  }

  /// 만료까지 남은 일수 계산 (오류 시 null)
  int? get daysUntilExpiry {
    try {
      final expiry = DateTime.parse(expiresAt);
      final diff = expiry.difference(DateTime.now()).inDays;
      return diff >= 0 ? diff : 0;
    } catch (_) {
      return null;
    }
  }
}

class PointWallet {
  final int balance;
  final PointExpiringSoon? expiringSoon; // v2.8: 곧 만료 예정 포인트

  PointWallet({
    required this.balance,
    this.expiringSoon,
  });

  factory PointWallet.fromJson(Map<String, dynamic> json) {
    final expiring = json['expiring_soon'];
    return PointWallet(
      balance: json['balance'] as int? ?? 0,
      expiringSoon: expiring != null
          ? PointExpiringSoon.fromJson(expiring as Map<String, dynamic>)
          : null,
    );
  }

  PointWallet empty() => PointWallet(balance: 0);
}

// v2.8 type 값:
//   charge_subscription | charge_web | charge_admin  → 적립(+)
//   use_event | use_admin                             → 사용(-)
//   transfer_out                                      → 이전 출금(-)
//   transfer_in                                       → 이전 입금(+)
class PointTransaction {
  final int id;
  final String type;       // v2.8 스펙 type 값
  final String? pointType; // subscription | charged | reward | null
  final int amount;        // 양수=입금, 음수=출금
  final int balanceAfter;
  final String? refType;
  final String? refId;
  final String description;
  final String? createdAt;

  PointTransaction({
    required this.id,
    required this.type,
    this.pointType,
    required this.amount,
    required this.balanceAfter,
    this.refType,
    this.refId,
    required this.description,
    this.createdAt,
  });

  factory PointTransaction.fromJson(Map<String, dynamic> json) {
    return PointTransaction(
      id: json['id'] as int? ?? 0,
      type: json['type'] as String? ?? '',
      pointType: json['point_type'] as String?,
      amount: json['amount'] as int? ?? 0,
      balanceAfter: json['balance_after'] as int? ?? 0,
      refType: json['ref_type'] as String?,
      refId: json['ref_id'] as String?,
      description: json['description'] as String? ?? '',
      createdAt: json['created_at'] as String?,
    );
  }

  /// 입금 여부: amount 양수 또는 charge_*/transfer_in 타입
  bool get isEarn =>
      amount > 0 ||
      type == 'charge_subscription' ||
      type == 'charge_web' ||
      type == 'charge_admin' ||
      type == 'transfer_in';

  /// 거래 타입 한글 레이블
  String get typeLabel {
    switch (type) {
      case 'charge_subscription':
        return '구독 지급';
      case 'charge_web':
        return '직접 충전';
      case 'charge_admin':
        return '관리자 지급';
      case 'use_event':
        return '행사 사용';
      case 'use_admin':
        return '관리자 차감';
      case 'transfer_out':
        return '그룹 이전';
      case 'transfer_in':
        return '그룹 수신';
      default:
        return type;
    }
  }
}
