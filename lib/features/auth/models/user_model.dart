class UserModel {
  final int id;
  final String email;
  final String name;
  final String role; // 'user' | 'group_admin' | 'super_admin'
  final String accountType;
  final String plan;
  final String? planExpiresAt;
  final String? avatarUrl;
  final int isVerified;
  final String? createdAt;
  final int pointBalance; // 포인트 잔액 (1P = 1원)

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.role = 'user',
    required this.accountType,
    required this.plan,
    this.planExpiresAt,
    this.avatarUrl,
    required this.isVerified,
    this.createdAt,
    this.pointBalance = 0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int? ?? 0,
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
      accountType: json['account_type'] as String? ?? 'personal',
      plan: json['plan'] as String? ?? 'free',
      planExpiresAt: json['plan_expires_at'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      isVerified: json['is_verified'] as int? ?? 0,
      createdAt: json['created_at'] as String?,
      pointBalance: json['point_balance'] as int? ?? 0,
    );
  }

  // v2.9: 부분 업데이트용 copyWith
  UserModel copyWith({
    String? name,
    String? avatarUrl,
    String? plan,
    String? planExpiresAt,
    int?    pointBalance,
  }) {
    return UserModel(
      id:             id,
      email:          email,
      name:           name          ?? this.name,
      role:           role,
      accountType:    accountType,
      plan:           plan          ?? this.plan,
      planExpiresAt:  planExpiresAt ?? this.planExpiresAt,
      avatarUrl:      avatarUrl     ?? this.avatarUrl,
      isVerified:     isVerified,
      createdAt:      createdAt,
      pointBalance:   pointBalance  ?? this.pointBalance,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'role': role,
    'account_type': accountType,
    'plan': plan,
    'plan_expires_at': planExpiresAt,
    'avatar_url': avatarUrl,
    'is_verified': isVerified,
    'created_at': createdAt,
    'point_balance': pointBalance,
  };

  bool get isPro => plan == 'pro' || plan == 'business';
  bool get isFree => plan == 'free';
  bool get isSuperAdmin => role == 'super_admin';
  bool get isGroupAdmin => role == 'group_admin' || role == 'super_admin';

  String get planLabel {
    switch (plan) {
      case 'pro': return 'Pro';
      case 'business': return 'Business';
      default: return 'Free';
    }
  }

  String get roleLabel {
    switch (role) {
      case 'super_admin': return '슈퍼어드민';
      case 'group_admin': return '그룹관리자';
      default: return '일반';
    }
  }

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (name.isNotEmpty) return name[0].toUpperCase();
    return '?';
  }
}
