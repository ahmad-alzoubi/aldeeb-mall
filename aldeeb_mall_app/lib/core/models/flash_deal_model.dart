class FlashDealModel {
  final String id;
  final String productId;
  final String productNameAr;
  final String productImage;
  final double originalPrice;
  final double dealPrice;
  final int discountPercent;
  final int totalQuota;
  final int claimedQuota;
  final String endsAt;
  final bool isActive;
  final String? branchId;
  final String? branchName;

  const FlashDealModel({
    required this.id,
    required this.productId,
    required this.productNameAr,
    required this.productImage,
    required this.originalPrice,
    required this.dealPrice,
    required this.discountPercent,
    required this.totalQuota,
    required this.claimedQuota,
    required this.endsAt,
    this.isActive = true,
    this.branchId,
    this.branchName,
  });

  int get percentClaimed {
    if (totalQuota <= 0) return 0;
    return ((claimedQuota / totalQuota) * 100).clamp(0, 100).round();
  }

  int get remainingUnits {
    return (totalQuota - claimedQuota).clamp(0, totalQuota);
  }

  factory FlashDealModel.fromJson(Map<String, dynamic> json) {
    return FlashDealModel(
      id: json['id'] as String? ?? 'fd-${DateTime.now().millisecondsSinceEpoch}',
      productId: json['product_id'] as String? ?? '',
      productNameAr: json['product_name_ar'] as String? ?? 'عرض فلاش خاطف',
      productImage: json['product_image'] as String? ??
          'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=400&q=80',
      originalPrice: (json['original_price'] as num?)?.toDouble() ?? 0.0,
      dealPrice: (json['deal_price'] as num?)?.toDouble() ?? 0.0,
      discountPercent: (json['discount_percent'] as num?)?.toInt() ?? 20,
      totalQuota: (json['total_quota'] as num?)?.toInt() ?? 100,
      claimedQuota: (json['claimed_quota'] as num?)?.toInt() ?? 0,
      endsAt: json['ends_at'] as String? ?? '04:00:00',
      isActive: json['is_active'] as bool? ?? true,
      branchId: json['branch_id'] as String?,
      branchName: json['branch_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name_ar': productNameAr,
      'product_image': productImage,
      'original_price': originalPrice,
      'deal_price': dealPrice,
      'discount_percent': discountPercent,
      'total_quota': totalQuota,
      'claimed_quota': claimedQuota,
      'ends_at': endsAt,
      'is_active': isActive,
      'branch_id': branchId,
      'branch_name': branchName,
    };
  }
}
