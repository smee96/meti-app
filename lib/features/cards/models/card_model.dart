class SnsLink {
  final int? id;
  final String platform;
  final String url;
  final int sortOrder;

  SnsLink({
    this.id,
    required this.platform,
    required this.url,
    this.sortOrder = 0,
  });

  factory SnsLink.fromJson(Map<String, dynamic> json) => SnsLink(
        id: json['id'] as int?,
        platform: json['platform'] as String? ?? '',
        url: json['url'] as String? ?? '',
        sortOrder: json['sort_order'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'platform': platform,
        'url': url,
        'sort_order': sortOrder,
      };
}

class CardTag {
  final String tagType;
  final String tagValue;

  CardTag({required this.tagType, required this.tagValue});

  factory CardTag.fromJson(Map<String, dynamic> json) => CardTag(
        tagType: json['tag_type'] as String? ?? '',
        tagValue: json['tag_value'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'tag_type': tagType,
        'tag_value': tagValue,
      };
}

class CardModel {
  final int id;
  final int userId;
  final int? groupId;
  final String cardType;
  final String name;
  final String? title;
  final String? company;
  final String? email;
  final String? phone;
  final String? website;
  final String? bio;
  final String? avatarUrl;
  final String templateId;
  final int isPrimary;
  final int isPublic;
  final int isActive;
  final String? createdAt;
  final String? updatedAt;
  final int snsCount;
  final List<SnsLink> snsLinks;
  final List<CardTag> tags;

  CardModel({
    required this.id,
    required this.userId,
    this.groupId,
    required this.cardType,
    required this.name,
    this.title,
    this.company,
    this.email,
    this.phone,
    this.website,
    this.bio,
    this.avatarUrl,
    required this.templateId,
    required this.isPrimary,
    required this.isPublic,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
    this.snsCount = 0,
    this.snsLinks = const [],
    this.tags = const [],
  });

  factory CardModel.fromJson(Map<String, dynamic> json) => CardModel(
        id: json['id'] as int? ?? 0,
        userId: json['user_id'] as int? ?? 0,
        groupId: json['group_id'] as int?,
        cardType: json['card_type'] as String? ?? 'personal',
        name: json['name'] as String? ?? '',
        title: json['title'] as String?,
        company: json['company'] as String?,
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        website: json['website'] as String?,
        bio: json['bio'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        templateId: json['template_id'] as String? ?? 'default',
        isPrimary: json['is_primary'] as int? ?? 0,
        isPublic: json['is_public'] as int? ?? 1,
        isActive: json['is_active'] as int? ?? 1,
        createdAt: json['created_at'] as String?,
        updatedAt: json['updated_at'] as String?,
        snsCount: json['sns_count'] as int? ?? 0,
        snsLinks: (json['sns_links'] as List<dynamic>?)
                ?.map((e) => SnsLink.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        tags: (json['tags'] as List<dynamic>?)
                ?.map((e) => CardTag.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

  bool get isPrimaryCard => isPrimary == 1;
  bool get isPublicCard => isPublic == 1;
}
