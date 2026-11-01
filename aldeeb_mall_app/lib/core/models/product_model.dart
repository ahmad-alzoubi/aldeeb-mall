class ProductModel {
  final String id;
  final String? categoryId;
  final String? subcategoryId;
  final String? barcode;
  final String nameAr;
  final String nameEn;
  final String? descriptionAr;
  final String? descriptionEn;
  final String? brand;
  final double price;
  final double? originalPrice;
  final int discountPercent;
  final String unit; // 'kg', 'piece', 'bottle', 'pack'
  final double weightStep;
  final int stockQuantity;
  final List<String> images;
  final bool isFeatured;
  final bool isDailyDeal;
  final double rating;
  final int reviewsCount;
  final int salesCount;
  final bool bundleEnabled;
  final int bundleDiscountPercent;
  final String? bundleTitle;
  final List<String> bundleProductIds;
  final bool isDraft;
  final String status;

  const ProductModel({
    required this.id,
    this.categoryId,
    this.subcategoryId,
    this.barcode,
    required this.nameAr,
    required this.nameEn,
    this.descriptionAr,
    this.descriptionEn,
    this.brand,
    required this.price,
    this.originalPrice,
    this.discountPercent = 0,
    this.unit = 'piece',
    this.weightStep = 1.0,
    this.stockQuantity = 100,
    this.images = const [],
    this.isFeatured = false,
    this.isDailyDeal = false,
    this.rating = 4.8,
    this.reviewsCount = 0,
    this.salesCount = 0,
    this.bundleEnabled = false,
    this.bundleDiscountPercent = 15,
    this.bundleTitle,
    this.bundleProductIds = const [],
    this.isDraft = false,
    this.status = 'published',
  });

  bool get hasDiscount => discountPercent > 0 || (originalPrice != null && originalPrice! > price);

  String get firstImage {
    if (images.isNotEmpty && images.first.isNotEmpty) {
      return images.first;
    }
    return 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=600&q=80';
  }

  String get unitLabelAr {
    switch (unit) {
      case 'kg':
        return 'كجم';
      case 'g':
        return 'غرام';
      case 'pack':
        return 'علبة';
      case 'bottle':
        return 'زجاجة';
      case 'carton':
        return 'كرتون';
      case 'piece':
      default:
        return 'حبة';
    }
  }

  int get caloriesPer100g {
    if (nameAr.contains('موز')) return 89;
    if (nameAr.contains('حليب')) return 64;
    if (nameAr.contains('بيض')) return 143;
    if (nameAr.contains('طماطم')) return 18;
    if (nameAr.contains('دجاج')) return 165;
    if (nameAr.contains('تفاح')) return 52;
    if (nameAr.contains('زيت')) return 884;
    if (nameAr.contains('سكر')) return 387;
    return 112;
  }

  double get proteinPer100g {
    if (nameAr.contains('دجاج')) return 31.0;
    if (nameAr.contains('بيض')) return 12.6;
    if (nameAr.contains('حليب')) return 3.4;
    if (nameAr.contains('زبادي')) return 10.0;
    if (nameAr.contains('جبن')) return 14.2;
    return 2.4;
  }

  double get carbsPer100g {
    if (nameAr.contains('موز')) return 22.8;
    if (nameAr.contains('طماطم')) return 3.9;
    if (nameAr.contains('حليب')) return 4.8;
    if (nameAr.contains('تفاح')) return 13.8;
    if (nameAr.contains('سكر')) return 99.8;
    return 7.5;
  }

  double get fatPer100g {
    if (nameAr.contains('زيت')) return 100.0;
    if (nameAr.contains('بيض')) return 9.5;
    if (nameAr.contains('دجاج')) return 3.6;
    if (nameAr.contains('حليب')) return 3.2;
    return 1.1;
  }

  String get allergenNotice {
    if (nameAr.contains('حليب') || nameAr.contains('زبادي') || nameAr.contains('جبن')) {
      return 'يحتوي على الحليب ومشتقات الألبان (لاكتوز)';
    }
    if (nameAr.contains('بيض')) {
      return 'يحتوي على البيض ومشتقاته';
    }
    if (nameAr.contains('خبز') || nameAr.contains('كرواسون')) {
      return 'يحتوي على الغلوتين والقمح';
    }
    return 'خالي من مسببات الحساسية الشائعة';
  }

  bool get isOrganic => nameAr.contains('عضوي') || nameEn.toLowerCase().contains('organic');
  bool get isGlutenFree => nameAr.contains('خالي من الغلوتين') || !nameAr.contains('خبز');
  bool get isKeto => caloriesPer100g > 0 && carbsPer100g < 5.0;
  bool get isHighProtein => proteinPer100g >= 10.0;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedImages = [];
    if (json['images'] != null) {
      if (json['images'] is List) {
        parsedImages = (json['images'] as List).map((e) => e.toString()).toList();
      }
    }

    return ProductModel(
      id: json['id'] as String,
      categoryId: json['category_id'] as String?,
      subcategoryId: json['subcategory_id'] as String?,
      barcode: json['barcode'] as String?,
      nameAr: json['name_ar'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? '',
      descriptionAr: json['description_ar'] as String?,
      descriptionEn: json['description_en'] as String?,
      brand: json['brand'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      originalPrice: (json['original_price'] as num?)?.toDouble(),
      discountPercent: (json['discount_percent'] as num?)?.toInt() ?? 0,
      unit: json['unit'] as String? ?? 'piece',
      weightStep: (json['weight_step'] as num?)?.toDouble() ?? 1.0,
      stockQuantity: (json['stock_quantity'] as num?)?.toInt() ?? 0,
      images: parsedImages,
      isFeatured: json['is_featured'] as bool? ?? false,
      isDailyDeal: json['is_daily_deal'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
      reviewsCount: (json['reviews_count'] as num?)?.toInt() ?? 0,
      salesCount: (json['sales_count'] as num?)?.toInt() ?? 0,
      bundleEnabled: json['bundle_enabled'] as bool? ?? false,
      bundleDiscountPercent: (json['bundle_discount_percent'] as num?)?.toInt() ?? 15,
      bundleTitle: json['bundle_title'] as String?,
      bundleProductIds: json['bundle_product_ids'] != null
          ? (json['bundle_product_ids'] as List).map((e) => e.toString()).toList()
          : const [],
      isDraft: json['is_draft'] as bool? ?? false,
      status: json['status'] as String? ?? 'published',
    );
  }

  ProductModel copyWith({
    String? id,
    String? categoryId,
    String? subcategoryId,
    String? barcode,
    String? nameAr,
    String? nameEn,
    String? descriptionAr,
    String? descriptionEn,
    String? brand,
    double? price,
    double? originalPrice,
    int? discountPercent,
    String? unit,
    double? weightStep,
    int? stockQuantity,
    List<String>? images,
    bool? isFeatured,
    bool? isDailyDeal,
    double? rating,
    int? reviewsCount,
    int? salesCount,
    bool? bundleEnabled,
    int? bundleDiscountPercent,
    String? bundleTitle,
    List<String>? bundleProductIds,
    bool? isDraft,
    String? status,
  }) {
    return ProductModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      barcode: barcode ?? this.barcode,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      brand: brand ?? this.brand,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      discountPercent: discountPercent ?? this.discountPercent,
      unit: unit ?? this.unit,
      weightStep: weightStep ?? this.weightStep,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      images: images ?? this.images,
      isFeatured: isFeatured ?? this.isFeatured,
      isDailyDeal: isDailyDeal ?? this.isDailyDeal,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      salesCount: salesCount ?? this.salesCount,
      bundleEnabled: bundleEnabled ?? this.bundleEnabled,
      bundleDiscountPercent: bundleDiscountPercent ?? this.bundleDiscountPercent,
      bundleTitle: bundleTitle ?? this.bundleTitle,
      bundleProductIds: bundleProductIds ?? this.bundleProductIds,
      isDraft: isDraft ?? this.isDraft,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'subcategory_id': subcategoryId,
      'barcode': barcode,
      'name_ar': nameAr,
      'name_en': nameEn,
      'description_ar': descriptionAr,
      'description_en': descriptionEn,
      'brand': brand,
      'price': price,
      'original_price': originalPrice,
      'discount_percent': discountPercent,
      'unit': unit,
      'weight_step': weightStep,
      'stock_quantity': stockQuantity,
      'images': images,
      'is_featured': isFeatured,
      'is_daily_deal': isDailyDeal,
      'rating': rating,
      'reviews_count': reviewsCount,
      'sales_count': salesCount,
      'bundle_enabled': bundleEnabled,
      'bundle_discount_percent': bundleDiscountPercent,
      'bundle_title': bundleTitle,
      'bundle_product_ids': bundleProductIds,
      'is_draft': isDraft,
      'status': status,
    };
  }
}
