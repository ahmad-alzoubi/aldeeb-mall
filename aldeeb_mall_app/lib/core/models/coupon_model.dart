class CouponModel {
  final String id;
  final String code;
  final String discountType; // 'percentage', 'fixed'
  final double discountValue;
  final double minOrderAmount;
  final double? maxDiscount;
  final bool isActive;

  const CouponModel({
    required this.id,
    required this.code,
    required this.discountType,
    required this.discountValue,
    this.minOrderAmount = 0.0,
    this.maxDiscount,
    this.isActive = true,
  });

  double calculateDiscount(double subtotal) {
    if (subtotal < minOrderAmount) return 0.0;
    if (discountType == 'percentage') {
      double discount = (subtotal * discountValue) / 100.0;
      if (maxDiscount != null && discount > maxDiscount!) {
        return maxDiscount!;
      }
      return discount;
    } else {
      return discountValue > subtotal ? subtotal : discountValue;
    }
  }

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    return CouponModel(
      id: json['id'] as String,
      code: json['code'] as String? ?? '',
      discountType: json['discount_type'] as String? ?? 'percentage',
      discountValue: (json['discount_value'] as num?)?.toDouble() ?? 0.0,
      minOrderAmount: (json['min_order_amount'] as num?)?.toDouble() ?? 0.0,
      maxDiscount: (json['max_discount'] as num?)?.toDouble(),
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
