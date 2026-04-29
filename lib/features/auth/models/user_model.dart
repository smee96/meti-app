class UserModel {
  final int id;
  final String email;
  final String name;
  final String accountType;
  final String plan;
  final String? planExpiresAt;
  final String? avatarUrl;
  final int isVerified;
  final String? createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.accountType,
    required this.plan,
    this.planExpiresAt,
    this.avatarUrl,
    required this.isVerified,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int? ?? 0,
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      accountType: json['account_type'] as String? ?? 'personal',
      plan: json['plan'] as String? ?? 'free',
      planExpiresAt: json['plan_expires_at'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      isVerified: json['is_verified'] as int? ?? 0,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'account_type': accountType,
    'plan': plan,
    'plan_expires_at': planExpiresAt,
    'avatar_url': avatarUrl,
    'is_verified': isVerified,
    'created_at': createdAt,
  };

  bool get isPro => plan == 'pro' || plan == 'business';
  bool get isFree => plan == 'free';
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (name.isNotEmpty) return name[0].toUpperCase();
    return '?';
  }
}
