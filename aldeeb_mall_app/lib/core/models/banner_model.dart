class BannerModel {
  final String id;
  final String titleAr;
  final String titleEn;
  final String? subtitleAr;
  final String? subtitleEn;
  final String imageUrl;
  final String targetType; // 'category', 'screen', 'product', 'deal', 'coupon', 'external'
  final String? targetId;
  final String? badgeAr;
  final String? badgeColor;
  final String slot; // 'hero', 'side_top', 'side_bottom', 'promo'
  final int sortOrder;
  final bool isActive;

  const BannerModel({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    this.subtitleAr,
    this.subtitleEn,
    required this.imageUrl,
    this.targetType = 'deal',
    this.targetId,
    this.badgeAr,
    this.badgeColor,
    this.slot = 'hero',
    this.sortOrder = 0,
    this.isActive = true,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: (json['id'] ?? '').toString(),
      titleAr: json['title_ar'] as String? ?? '',
      titleEn: json['title_en'] as String? ?? '',
      subtitleAr: json['subtitle_ar'] as String?,
      subtitleEn: json['subtitle_en'] as String?,
      imageUrl: json['image_url'] as String? ?? '',
      targetType: json['target_type'] as String? ?? 'deal',
      targetId: json['target_id'] as String?,
      badgeAr: json['badge_ar'] as String?,
      badgeColor: json['badge_color'] as String?,
      slot: json['slot'] as String? ?? 'hero',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title_ar': titleAr,
      'title_en': titleEn,
      'subtitle_ar': subtitleAr,
      'subtitle_en': subtitleEn,
      'image_url': imageUrl,
      'target_type': targetType,
      'target_id': targetId,
      'badge_ar': badgeAr,
      'badge_color': badgeColor,
      'slot': slot,
      'sort_order': sortOrder,
      'is_active': isActive,
    };
  }

  BannerModel copyWith({
    String? id,
    String? titleAr,
    String? titleEn,
    String? subtitleAr,
    String? subtitleEn,
    String? imageUrl,
    String? targetType,
    String? targetId,
    String? badgeAr,
    String? badgeColor,
    String? slot,
    int? sortOrder,
    bool? isActive,
  }) {
    return BannerModel(
      id: id ?? this.id,
      titleAr: titleAr ?? this.titleAr,
      titleEn: titleEn ?? this.titleEn,
      subtitleAr: subtitleAr ?? this.subtitleAr,
      subtitleEn: subtitleEn ?? this.subtitleEn,
      imageUrl: imageUrl ?? this.imageUrl,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      badgeAr: badgeAr ?? this.badgeAr,
      badgeColor: badgeColor ?? this.badgeColor,
      slot: slot ?? this.slot,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
    );
  }
}
