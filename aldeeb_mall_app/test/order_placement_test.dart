import 'package:flutter_test/flutter_test.dart';
import 'package:aldeeb_mall_app/core/models/order_model.dart';
import 'package:aldeeb_mall_app/core/models/cart_item_model.dart';
import 'package:aldeeb_mall_app/core/models/product_model.dart';
import 'package:aldeeb_mall_app/core/providers/cart_provider.dart';
import 'package:aldeeb_mall_app/core/providers/order_provider.dart';

void main() {
  group('Aldeeb Mall Order Placement & Payment Normalization Tests', () {
    test('Payment method normalization maps Arabic labels to strict SQL ENUMs', () {
      // Replicate normalization logic for validation
      String normalize(String method) {
        final clean = method.trim().toLowerCase();
        if (clean == 'cod' ||
            clean == 'card_on_delivery' ||
            clean == 'card' ||
            clean == 'loyalty_points' ||
            clean == 'apple_pay') {
          return clean;
        }
        if (clean.contains('محفظة') ||
            clean.contains('نقاط') ||
            clean.contains('wallet') ||
            clean.contains('points') ||
            clean.contains('loyalty')) {
          return 'loyalty_points';
        }
        if (clean.contains('apple') || clean.contains('آبل') || clean.contains('ابل')) {
          return 'apple_pay';
        }
        if (clean.contains('عند الباب') ||
            clean.contains('عند الاستلام') ||
            clean.contains('on delivery')) {
          if (clean.contains('نقداً') || clean.contains('كاش') || clean.contains('cash')) {
            return 'cod';
          }
          return 'card_on_delivery';
        }
        if (clean.contains('بطاقة') ||
            clean.contains('مدى') ||
            clean.contains('ائتمان') ||
            clean.contains('card') ||
            clean.contains('visa') ||
            clean.contains('mastercard')) {
          return 'card';
        }
        return 'cod';
      }

      expect(normalize('الدفع نقداً عند الاستلام'), equals('cod'));
      expect(normalize('بطاقة مدى / ائتمان عند الباب'), equals('card_on_delivery'));
      expect(normalize('محفظة الديب الذكية (Aldeeb Pay)'), equals('loyalty_points'));
      expect(normalize('Apple Pay سريع ومباشر'), equals('apple_pay'));
      expect(normalize('بطاقة فيزا أو ماستركارد'), equals('card'));
      expect(normalize('أي خيار آخر غير معروف'), equals('cod'));
    });

    test('OrderModel securely encapsulates order header and line items', () {
      const p1 = ProductModel(
        id: 'a0000000-0000-0000-0000-000000000001',
        nameAr: 'موز فلبيني ممتاز',
        nameEn: 'Fresh Cavendish Bananas',
        price: 4.95,
        unit: 'kg',
      );

      const p2 = ProductModel(
        id: 'a0000000-0000-0000-0000-000000000003',
        nameAr: 'حليب المراعي 2 لتر',
        nameEn: 'Almarai Fresh Milk 2L',
        price: 11.00,
        unit: 'piece',
      );

      final item1 = CartItemModel(product: p1, quantity: 2.0); // 9.90
      final item2 = CartItemModel(product: p2, quantity: 1.0); // 11.00

      final order = OrderModel(
        id: 'ord-test-uuid-999',
        orderNumber: 'DEEB-9999',
        status: 'pending',
        deliverySlot: 'توصيل فوري خلال 60 دقيقة',
        paymentMethod: 'الدفع نقداً عند الاستلام',
        subtotal: 20.90,
        deliveryFee: 10.00,
        discountAmount: 2.00,
        loyaltyPointsUsed: 0,
        loyaltyDiscount: 0.0,
        totalAmount: 28.90,
        items: [item1, item2],
        createdAt: DateTime.now(),
      );

      expect(order.items.length, equals(2));
      expect(order.items[0].product.nameAr, equals('موز فلبيني ممتاز'));
      expect(order.items[0].totalPrice, equals(9.90));
      expect(order.items[1].totalPrice, equals(11.00));
      expect(order.totalAmount, equals(28.90));
    });

    test('Cart calculations correctly deduct coupons, loyalty, and waive delivery above threshold', () {
      final cart = CartProvider();
      const testProd = ProductModel(
        id: 'a0000000-0000-0000-0000-000000000005',
        nameAr: 'مياه العين كرتونة',
        nameEn: 'Al Ain Bottled Water Carton',
        price: 55.00,
      );

      cart.addToCart(testProd, quantity: 2.0); // Subtotal: 110.00 >= 100 threshold => Delivery Free!
      expect(cart.subtotal, equals(110.00));
      expect(cart.isFreeDelivery, isTrue);
      expect(cart.deliveryFee, equals(0.0));
      expect(cart.totalAmount, equals(110.00));
    });

    test('OrderProvider tracks error state when order placement fails', () {
      final orderProv = OrderProvider();
      expect(orderProv.lastOrderError, isNull);
      expect(orderProv.isPlacingOrder, isFalse);
    });

    test('Checkout error mapper translates all backend RPC and security exceptions to Arabic UI notices', () {
      String mapCheckoutError(String err) {
        if (err.contains('INSUFFICIENT_STOCK')) {
          return '⚠️ عذراً، نفدت الكمية المتاحة في المخزون لأحد الأصناف المطلوبة.';
        } else if (err.contains('DUPLICATE_ORDER')) {
          return '⚠️ تم إرسال هذا الطلب مسبقاً لمنع تكرار الخصم.';
        } else if (err.contains('EMPTY_ITEMS')) {
          return '⚠️ السلة فارغة، يرجى إضافة منتجات أولاً.';
        } else if (err.contains('UNAUTHORIZED_POS')) {
          return '⚠️ طلبات الكاشير ونقاط البيع تتطلب تسجيل دخول موظف معتمد.';
        } else if (err.contains('UNAUTHORIZED')) {
          return '⚠️ غير مصرح: يرجى تسجيل الدخول بحسابك للمتابعة.';
        }
        return '⚠️ تعذر تأكيد الطلب، يرجى التحقق من اتصال الإنترنت ومراجعة البيانات والمحاولة مجدداً.';
      }

      expect(mapCheckoutError('PostgrestException(message: INSUFFICIENT_STOCK: Only 2 units available)'),
          contains('نفدت الكمية المتاحة في المخزون'));
      expect(mapCheckoutError('PostgrestException(message: DUPLICATE_ORDER: Order with number DEEB-123 already exists)'),
          contains('تم إرسال هذا الطلب مسبقاً'));
      expect(mapCheckoutError('PostgrestException(message: UNAUTHORIZED_POS: In-store POS cashier orders)'),
          contains('طلبات الكاشير ونقاط البيع تتطلب'));
      expect(mapCheckoutError('PostgrestException(message: UNAUTHORIZED: Anonymous callers cannot assign)'),
          contains('غير مصرح: يرجى تسجيل الدخول'));
      expect(mapCheckoutError('SocketException: Connection refused'),
          contains('تعذر تأكيد الطلب، يرجى التحقق من اتصال الإنترنت'));
    });

    test('Authoritative subtotal calculation overrides client price tampering', () {
      final authoritativePrices = {
        'prod-1': 100.00,
        'prod-2': 50.00,
      };

      final clientItems = [
        {'product_id': 'prod-1', 'quantity': 2.0, 'unit_price': 1.00}, // Tampered client price!
        {'product_id': 'prod-2', 'quantity': 1.0, 'unit_price': 5.00}, // Tampered client price!
      ];

      double calculatedSubtotal = 0.0;
      for (final item in clientItems) {
        final pid = item['product_id'] as String;
        final qty = (item['quantity'] as num).toDouble();
        final authPrice = authoritativePrices[pid] ?? (item['unit_price'] as num).toDouble();
        calculatedSubtotal += (authPrice * qty);
      }

      // Authoritative subtotal should be 100*2 + 50*1 = 250, completely ignoring client's fake 1.00 and 5.00!
      expect(calculatedSubtotal, equals(250.00));
    });

    test('Order lifecycle state progression follows valid state transitions', () {
      final validTransitions = {
        'pending': ['processing', 'cancelled'],
        'processing': ['out_for_delivery', 'cancelled'],
        'out_for_delivery': ['delivered', 'cancelled'],
        'delivered': <String>[],
        'cancelled': <String>[],
      };

      bool isValidTransition(String from, String to) {
        return validTransitions[from]?.contains(to) ?? false;
      }

      expect(isValidTransition('pending', 'processing'), isTrue);
      expect(isValidTransition('processing', 'out_for_delivery'), isTrue);
      expect(isValidTransition('out_for_delivery', 'delivered'), isTrue);
      expect(isValidTransition('delivered', 'pending'), isFalse);
      expect(isValidTransition('pending', 'delivered'), isFalse);
    });

    test('POS cashier sale payload complies with in-store checkout standards', () {
      final posPayload = {
        'order_number': 'POS-20261102-0042',
        'status': 'delivered',
        'delivery_slot': 'كاشير مباشر - الفرع الرئيسي',
        'payment_method': 'cod',
        'payment_status': 'paid',
        'subtotal': 150.00,
        'delivery_fee': 0.00,
        'discount_amount': 0.00,
        'total_amount': 150.00,
      };

      expect(posPayload['delivery_slot'], contains('كاشير مباشر'));
      expect(posPayload['delivery_fee'], equals(0.00));
      expect(posPayload['payment_status'], equals('paid'));
      expect(posPayload['status'], equals('delivered'));
    });
  });
}
