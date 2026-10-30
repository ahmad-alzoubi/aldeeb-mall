class BannerModel {
  final String id;
  final String titleAr;
  final String titleEn;
  final String? subtitleAr;
  final String? subtitleEn;
  final String imageUrl;
  final String targetType; // 'category', 'product', 'deal', 'external'
  final String? targetId;
  final String? badgeAr;

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
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] as String,
      titleAr: json['title_ar'] as String? ?? '',
      titleEn: json['title_en'] as String? ?? '',
      subtitleAr: json['subtitle_ar'] as String?,
      subtitleEn: json['subtitle_en'] as String?,
      imageUrl: json['image_url'] as String? ?? '',
      targetType: json['target_type'] as String? ?? 'deal',
      targetId: json['target_id'] as String?,
      badgeAr: json['badge_ar'] as String?,
    );
  }
}
