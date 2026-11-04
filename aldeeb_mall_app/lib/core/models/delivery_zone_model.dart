class DeliveryZoneModel {
  final String id;
  final String zoneNameAr;
  final String? zoneNameEn;
  final String city;
  final String? district;
  final String? branchId;
  final String darkStoreCode;
  final double centerLatitude;
  final double centerLongitude;
  final double radiusKm;
  final double baseDeliveryFee;
  final double freeDeliveryThreshold;
  final int estimatedMinutes;
  final bool isSurgePricingActive;
  final double surgeFee;
  final bool isActive;
  final String openingTime;
  final String closingTime;
  final int maxHourlyCapacity;
  final List<dynamic> deliveryOptions;

  const DeliveryZoneModel({
    required this.id,
    required this.zoneNameAr,
    this.zoneNameEn,
    required this.city,
    this.district,
    this.branchId,
    required this.darkStoreCode,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.radiusKm,
    required this.baseDeliveryFee,
    required this.freeDeliveryThreshold,
    required this.estimatedMinutes,
    this.isSurgePricingActive = false,
    this.surgeFee = 0.0,
    this.isActive = true,
    this.openingTime = '08:00:00',
    this.closingTime = '23:59:59',
    this.maxHourlyCapacity = 50,
    this.deliveryOptions = const [],
  });

  factory DeliveryZoneModel.fromJson(Map<String, dynamic> json) {
    return DeliveryZoneModel(
      id: json['id'] as String? ?? '',
      zoneNameAr: json['zone_name_ar'] as String? ?? '',
      zoneNameEn: json['zone_name_en'] as String?,
      city: json['city'] as String? ?? 'دمشق',
      district: json['district'] as String?,
      branchId: json['branch_id'] as String?,
      darkStoreCode: json['dark_store_code'] as String? ?? 'WH-DAM-HUB',
      centerLatitude: (json['center_latitude'] as num?)?.toDouble() ?? 33.5138,
      centerLongitude: (json['center_longitude'] as num?)?.toDouble() ?? 36.2765,
      radiusKm: (json['radius_km'] as num?)?.toDouble() ?? 5.0,
      baseDeliveryFee: (json['base_delivery_fee'] as num?)?.toDouble() ?? 5000.0,
      freeDeliveryThreshold: (json['free_delivery_threshold'] as num?)?.toDouble() ?? 150000.0,
      estimatedMinutes: (json['estimated_minutes'] as num?)?.toInt() ?? 25,
      isSurgePricingActive: json['is_surge_pricing_active'] as bool? ?? false,
      surgeFee: (json['surge_fee'] as num?)?.toDouble() ?? 0.0,
      isActive: json['is_active'] as bool? ?? true,
      openingTime: json['opening_time'] as String? ?? '08:00:00',
      closingTime: json['closing_time'] as String? ?? '23:59:59',
      maxHourlyCapacity: (json['max_hourly_capacity'] as num?)?.toInt() ?? 50,
      deliveryOptions: json['delivery_options'] as List<dynamic>? ?? const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'zone_name_ar': zoneNameAr,
      'zone_name_en': zoneNameEn,
      'city': city,
      'district': district,
      'branch_id': branchId,
      'dark_store_code': darkStoreCode,
      'center_latitude': centerLatitude,
      'center_longitude': centerLongitude,
      'radius_km': radiusKm,
      'base_delivery_fee': baseDeliveryFee,
      'free_delivery_threshold': freeDeliveryThreshold,
      'estimated_minutes': estimatedMinutes,
      'is_surge_pricing_active': isSurgePricingActive,
      'surge_fee': surgeFee,
      'is_active': isActive,
      'opening_time': openingTime,
      'closing_time': closingTime,
      'max_hourly_capacity': maxHourlyCapacity,
      'delivery_options': deliveryOptions,
    };
  }
}
