import 'cart_item_model.dart';

class OrderModel {
  final String id;
  final String orderNumber;
  final String status; // 'pending', 'confirmed', 'packing', 'out_for_delivery', 'delivered', 'cancelled'
  final String deliverySlot;
  final String paymentMethod;
  final String paymentStatus;
  final double subtotal;
  final double deliveryFee;
  final double discountAmount;
  final int loyaltyPointsUsed;
  final double loyaltyDiscount;
  final double totalAmount;
  final List<CartItemModel> items;
  final DateTime createdAt;
  final String? notes;
  final String? driverName;
  final String? driverPhone;
  final String? cancellationReason;
  final String? failureReason;

  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.deliverySlot,
    required this.paymentMethod,
    this.paymentStatus = 'pending',
    required this.subtotal,
    this.deliveryFee = 0.0,
    this.discountAmount = 0.0,
    this.loyaltyPointsUsed = 0,
    this.loyaltyDiscount = 0.0,
    required this.totalAmount,
    this.items = const [],
    required this.createdAt,
    this.notes,
    this.driverName,
    this.driverPhone,
    this.cancellationReason,
    this.failureReason,
  });

  String get statusTitleAr {
    switch (status) {
      case 'pending':
        return 'قيد المراجعة';
      case 'confirmed':
        return 'تم التأكيد';
      case 'packing':
        return 'جاري التجهيز بالمستودع';
      case 'assigned':
        return 'تم تعيين السائق';
      case 'ready_for_driver':
        return 'جاهز للاستلام مع السائق';
      case 'out_for_delivery':
        return 'في الطريق مع السائق';
      case 'delivered':
        return 'تم التسليم بنجاح';
      case 'cancelled':
        return 'ملغي';
      case 'failed':
        return 'تعذر التسليم (إخفاق)';
      default:
        return 'غير محدد';
    }
  }

  int get statusStepIndex {
    switch (status) {
      case 'pending':
        return 0;
      case 'confirmed':
      case 'packing':
        return 1;
      case 'assigned':
      case 'ready_for_driver':
      case 'out_for_delivery':
        return 2;
      case 'delivered':
        return 3;
      default:
        return 0;
    }
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      orderNumber: json['order_number'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      deliverySlot: json['delivery_slot'] as String? ?? '',
      paymentMethod: json['payment_method'] as String? ?? 'cod',
      paymentStatus: json['payment_status'] as String? ?? 'pending',
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0.0,
      loyaltyPointsUsed: (json['loyalty_points_used'] as num?)?.toInt() ?? 0,
      loyaltyDiscount: (json['loyalty_discount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      notes: json['notes'] as String?,
      driverName: json['delivery_driver_name'] as String?,
      driverPhone: json['delivery_driver_phone'] as String?,
      cancellationReason: json['cancellation_reason'] as String?,
      failureReason: json['failure_reason'] as String?,
    );
  }

  OrderModel copyWith({
    String? id,
    String? orderNumber,
    String? status,
    String? deliverySlot,
    String? paymentMethod,
    String? paymentStatus,
    double? subtotal,
    double? deliveryFee,
    double? discountAmount,
    int? loyaltyPointsUsed,
    double? loyaltyDiscount,
    double? totalAmount,
    List<CartItemModel>? items,
    DateTime? createdAt,
    String? notes,
    String? driverName,
    String? driverPhone,
    String? cancellationReason,
    String? failureReason,
  }) {
    return OrderModel(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      status: status ?? this.status,
      deliverySlot: deliverySlot ?? this.deliverySlot,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      discountAmount: discountAmount ?? this.discountAmount,
      loyaltyPointsUsed: loyaltyPointsUsed ?? this.loyaltyPointsUsed,
      loyaltyDiscount: loyaltyDiscount ?? this.loyaltyDiscount,
      totalAmount: totalAmount ?? this.totalAmount,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      failureReason: failureReason ?? this.failureReason,
    );
  }
}
