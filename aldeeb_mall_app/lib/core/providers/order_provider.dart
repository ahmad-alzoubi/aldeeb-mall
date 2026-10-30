import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../models/cart_item_model.dart';
import '../services/supabase_service.dart';

class OrderProvider extends ChangeNotifier {
  final List<OrderModel> _orders = [];
  OrderModel? _currentTrackedOrder;
  bool _isPlacingOrder = false;

  List<OrderModel> get orders => [..._orders];
  OrderModel? get currentTrackedOrder => _currentTrackedOrder;
  bool get isPlacingOrder => _isPlacingOrder;

  OrderProvider() {
    _initSampleOrders();
  }

  void _initSampleOrders() {
    _orders.add(
      OrderModel(
        id: 'ord-101',
        orderNumber: 'DEEB-8842',
        status: 'out_for_delivery',
        deliverySlot: 'توصيل فوري (خلال 60 دقيقة)',
        paymentMethod: 'الدفع عند الاستلام',
        paymentStatus: 'pending',
        subtotal: 145.50,
        deliveryFee: 0.0, // Free delivery
        discountAmount: 14.55,
        loyaltyPointsUsed: 50,
        loyaltyDiscount: 0.50,
        totalAmount: 130.45,
        createdAt: DateTime.now().subtract(const Duration(minutes: 35)),
        driverName: 'عمر القواسمي',
        driverPhone: '+971501234567',
        items: [
          CartItemModel(
            product: SupabaseService.defaultProducts[0],
            quantity: 2.0,
          ),
          CartItemModel(
            product: SupabaseService.defaultProducts[3],
            quantity: 1.0,
          ),
        ],
      ),
    );
    _currentTrackedOrder = _orders.first;
  }

  void setTrackedOrder(OrderModel order) {
    _currentTrackedOrder = order;
    notifyListeners();
  }

  Future<OrderModel?> placeOrder({
    required List<CartItemModel> items,
    required double subtotal,
    required double deliveryFee,
    required double discountAmount,
    required int loyaltyPointsUsed,
    required double loyaltyDiscount,
    required double totalAmount,
    required String deliverySlot,
    required String paymentMethod,
    String? notes,
  }) async {
    _isPlacingOrder = true;
    notifyListeners();

    try {
      final orderNumber = 'DEEB-${(1000 + _orders.length * 17 + DateTime.now().millisecond)}';

      final createdOrder = await SupabaseService().createOrder(
        orderNumber: orderNumber,
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        discountAmount: discountAmount,
        loyaltyPointsUsed: loyaltyPointsUsed,
        loyaltyDiscount: loyaltyDiscount,
        totalAmount: totalAmount,
        deliverySlot: deliverySlot,
        paymentMethod: paymentMethod,
        notes: notes,
      );

      final fullOrder = OrderModel(
        id: createdOrder.id,
        orderNumber: createdOrder.orderNumber,
        status: 'confirmed',
        deliverySlot: deliverySlot,
        paymentMethod: paymentMethod,
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        discountAmount: discountAmount,
        loyaltyPointsUsed: loyaltyPointsUsed,
        loyaltyDiscount: loyaltyDiscount,
        totalAmount: totalAmount,
        items: items,
        createdAt: DateTime.now(),
        notes: notes,
        driverName: 'محمد كمال (فريق التوصيل السريع)',
        driverPhone: '+971505551234',
      );

      _orders.insert(0, fullOrder);
      _currentTrackedOrder = fullOrder;
      _isPlacingOrder = false;
      notifyListeners();
      return fullOrder;
    } catch (e) {
      _isPlacingOrder = false;
      notifyListeners();
      return null;
    }
  }
}
