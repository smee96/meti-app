/// 상품 모델 (v2.6)
/// API: GET /products/groups/:gid/products
class Product {
  final int id;
  final int groupId;
  final String name;
  final String? description;
  final String type;        // physical | digital | service
  final int price;          // P 단위
  final int? stock;         // null = 무제한
  final int soldCount;
  final bool isActive;
  final DateTime? expiresAt;
  final String? imageUrl;
  final String? createdBy;

  const Product({
    required this.id,
    required this.groupId,
    required this.name,
    this.description,
    required this.type,
    required this.price,
    this.stock,
    this.soldCount = 0,
    this.isActive = true,
    this.expiresAt,
    this.imageUrl,
    this.createdBy,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as int,
        groupId: json['group_id'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        description: json['description'] as String?,
        type: json['type'] as String? ?? 'service',
        price: json['price'] as int? ?? 0,
        stock: json['stock'] as int?,
        soldCount: json['sold_count'] as int? ?? 0,
        isActive: json['is_active'] == true || json['is_active'] == 1,
        expiresAt: json['expires_at'] != null
            ? DateTime.tryParse(json['expires_at'] as String)
            : null,
        imageUrl: json['image_url'] as String?,
        createdBy: json['created_by'] as String?,
      );

  String get typeLabel {
    switch (type) {
      case 'physical': return '실물 상품';
      case 'digital':  return '디지털';
      case 'service':  return '서비스';
      default:         return type;
    }
  }

  bool get isSoldOut => stock != null && (stock! - soldCount) <= 0;
  int? get remaining => stock == null ? null : (stock! - soldCount).clamp(0, stock!);
  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());
  bool get canPurchase => isActive && !isSoldOut && !isExpired;
}

/// 주문 모델 (v2.6)
class Order {
  final int id;
  final int productId;
  final String productName;
  final int amount;         // 결제 금액 (P)
  final String status;      // pending | paid | cancelled | refunded
  final String paymentMethod; // points | web_payment
  final DateTime createdAt;
  final String? webPaymentUrl;

  const Order({
    required this.id,
    required this.productId,
    required this.productName,
    required this.amount,
    required this.status,
    this.paymentMethod = 'points',
    required this.createdAt,
    this.webPaymentUrl,
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'] as int,
        productId: json['product_id'] as int? ?? 0,
        productName: json['product_name'] as String? ?? '',
        amount: json['amount'] as int? ?? 0,
        status: json['status'] as String? ?? 'pending',
        paymentMethod: json['payment_method'] as String? ?? 'points',
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String) ??
                DateTime.now()
            : DateTime.now(),
        webPaymentUrl: json['web_payment_url'] as String?,
      );

  String get statusLabel {
    switch (status) {
      case 'pending':   return '결제 대기';
      case 'paid':      return '결제 완료';
      case 'cancelled': return '취소됨';
      case 'refunded':  return '환불됨';
      default:          return status;
    }
  }
}
