class CategoryModel {
  final String id;
  final String nameAr;
  final String nameEn;
  final String slug;
  final String iconName;
  final String? imageUrl;
  final int sortOrder;
  final bool showTitle;
  final String? groupTag;
  final int itemCount;

  const CategoryModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.slug,
    this.iconName = 'shopping_basket',
    this.imageUrl,
    this.sortOrder = 0,
    this.showTitle = true,
    this.groupTag,
    this.itemCount = 0,
  });

  CategoryModel copyWith({
    String? id,
    String? nameAr,
    String? nameEn,
    String? slug,
    String? iconName,
    String? imageUrl,
    int? sortOrder,
    bool? showTitle,
    String? groupTag,
    int? itemCount,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      slug: slug ?? this.slug,
      iconName: iconName ?? this.iconName,
      imageUrl: imageUrl ?? this.imageUrl,
      sortOrder: sortOrder ?? this.sortOrder,
      showTitle: showTitle ?? this.showTitle,
      groupTag: groupTag ?? this.groupTag,
      itemCount: itemCount ?? this.itemCount,
    );
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      nameAr: json['name_ar'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      iconName: json['icon_name'] as String? ?? 'shopping_basket',
      imageUrl: json['image_url'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      showTitle: json['show_title'] as bool? ?? true,
      groupTag: json['group_tag'] as String?,
      itemCount: (json['item_count'] as num?)?.toInt() ?? 0,
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
      'show_title': showTitle,
      'group_tag': groupTag,
      'item_count': itemCount,
    };
  }
}
