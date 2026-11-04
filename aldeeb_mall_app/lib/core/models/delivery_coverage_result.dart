class DeliveryCoverageResult {
  final bool isCovered;
  final String status;
  final String message;
  final String? rejectionReason;
  final String? zoneId;
  final String? zoneNameAr;
  final String? city;
  final String? district;
  final String? branchId;
  final String? branchNameAr;
  final String? darkStoreCode;
  final double distanceKm;
  final double radiusKm;
  final double baseDeliveryFee;
  final bool isSurgeActive;
  final double surgeFee;
  final bool surgeApplied;
  final double finalDeliveryFee;
  final double freeDeliveryThreshold;
  final bool isFreeDelivery;
  final int estimatedMinutes;
  final String? openingTime;
  final String? closingTime;
  final List<dynamic> deliveryOptions;

  const DeliveryCoverageResult({
    required this.isCovered,
    required this.status,
    required this.message,
    this.rejectionReason,
    this.zoneId,
    this.zoneNameAr,
    this.city,
    this.district,
    this.branchId,
    this.branchNameAr,
    this.darkStoreCode,
    this.distanceKm = 0.0,
    this.radiusKm = 5.0,
    this.baseDeliveryFee = 5000.0,
    this.isSurgeActive = false,
    this.surgeFee = 0.0,
    this.surgeApplied = false,
    this.finalDeliveryFee = 5000.0,
    this.freeDeliveryThreshold = 150000.0,
    this.isFreeDelivery = false,
    this.estimatedMinutes = 25,
    this.openingTime,
    this.closingTime,
    this.deliveryOptions = const [],
  });

  factory DeliveryCoverageResult.fromJson(Map<String, dynamic> json) {
    return DeliveryCoverageResult(
      isCovered: json['is_covered'] as bool? ?? false,
      status: json['status'] as String? ?? (json['is_covered'] == true ? 'ALLOWED' : 'REJECTED'),
      message: json['message'] as String? ?? '',
      rejectionReason: json['rejection_reason'] as String?,
      zoneId: json['zone_id'] as String?,
      zoneNameAr: json['zone_name_ar'] as String?,
      city: json['city'] as String?,
      district: json['district'] as String?,
      branchId: json['branch_id'] as String?,
      branchNameAr: json['branch_name_ar'] as String?,
      darkStoreCode: json['dark_store_code'] as String?,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      radiusKm: (json['radius_km'] as num?)?.toDouble() ?? 5.0,
      baseDeliveryFee: (json['base_delivery_fee'] as num?)?.toDouble() ?? 5000.0,
      isSurgeActive: json['is_surge_active'] as bool? ?? false,
      surgeFee: (json['surge_fee'] as num?)?.toDouble() ?? 0.0,
      surgeApplied: json['surge_applied'] as bool? ?? false,
      finalDeliveryFee: (json['final_delivery_fee'] as num?)?.toDouble() ?? 5000.0,
      freeDeliveryThreshold: (json['free_delivery_threshold'] as num?)?.toDouble() ?? 150000.0,
      isFreeDelivery: json['is_free_delivery'] as bool? ?? false,
      estimatedMinutes: (json['estimated_minutes'] as num?)?.toInt() ?? 25,
      openingTime: json['opening_time'] as String?,
      closingTime: json['closing_time'] as String?,
      deliveryOptions: json['delivery_options'] as List<dynamic>? ?? const [],
    );
  }

  factory DeliveryCoverageResult.offlineDefault() {
    return const DeliveryCoverageResult(
      isCovered: true,
      status: 'ALLOWED',
      message: 'تم تفعيل التغطية الافتراضية للفرع المركزي',
      zoneId: 'zn-dam-central',
      zoneNameAr: 'دمشق المركزية (المزة)',
      city: 'دمشق',
      district: 'المزة',
      branchId: 'b-dam-01',
      branchNameAr: 'فرع دمشق المركزي (أوتوستراد المزة)',
      baseDeliveryFee: 5000.0,
      finalDeliveryFee: 5000.0,
      freeDeliveryThreshold: 150000.0,
      estimatedMinutes: 20,
    );
  }
}
