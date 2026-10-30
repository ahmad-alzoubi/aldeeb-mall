class CategoryModel {
  final String id;
  final String nameAr;
  final String nameEn;
  final String slug;
  final String iconName;
  final String? imageUrl;
  final int sortOrder;

  const CategoryModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.slug,
    this.iconName = 'shopping_basket',
    this.imageUrl,
    this.sortOrder = 0,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      nameAr: json['name_ar'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      iconName: json['icon_name'] as String? ?? 'shopping_basket',
      imageUrl: json['image_url'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_ar': nameAr,
      'name_en': nameEn,
      'slug': slug,
      'icon_name': iconName,
      'image_url': imageUrl,
      'sort_order': sortOrder,
    };
  }
}
