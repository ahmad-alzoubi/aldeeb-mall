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
    };
  }
}
