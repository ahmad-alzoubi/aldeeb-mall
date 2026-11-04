import 'package:flutter_test/flutter_test.dart';
import 'package:aldeeb_mall_app/core/models/coupon_model.dart';
import 'package:aldeeb_mall_app/core/services/supabase_service.dart';
import 'package:aldeeb_mall_app/core/providers/cart_provider.dart';
import 'package:aldeeb_mall_app/core/models/product_model.dart';

void main() {
  group('Coupon Model & Validation Unit Tests', () {
    test('Coupon 5555 percentage calculation and threshold checks', () {
      const coupon5555 = CouponModel(
        id: 'ca000000-0000-0000-0000-000000005555',
        code: '5555',
        discountType: 'percentage',
        discountValue: 15.0,
        minOrderAmount: 0.0,
        maxDiscount: 50.0,
        isActive: true,
      );

      expect(coupon5555.isValidForSubtotal(0.0), isTrue);
      expect(coupon5555.isValidForSubtotal(100.0), isTrue);

      // 15% of 100 = 15.0
      expect(coupon5555.calculateDiscount(100.0), equals(15.0));

      // 15% of 500 = 75.0, capped at maxDiscount 50.0
      expect(coupon5555.calculateDiscount(500.0), equals(50.0));
    });

    test('Support both percentage and percent synonyms', () {
      const c1 = CouponModel(
        id: 'c1',
        code: 'TEST1',
        discountType: 'percentage',
        discountValue: 10.0,
      );
      const c2 = CouponModel(
        id: 'c2',
        code: 'TEST2',
        discountType: 'percent',
        discountValue: 10.0,
      );

      expect(c1.isPercentage, isTrue);
      expect(c2.isPercentage, isTrue);
      expect(c1.calculateDiscount(100.0), equals(10.0));
      expect(c2.calculateDiscount(100.0), equals(10.0));
    });

    test('SupabaseService offline fallback validates coupon 5555', () async {
      final service = SupabaseService();
      final result = await service.validateCouponDetailed('5555', 80.0);

      expect(result.isValid, isTrue);
      expect(result.coupon, isNotNull);
      expect(result.coupon!.code, equals('5555'));
      expect(result.calculatedDiscount, equals(12.0)); // 15% of 80 = 12
    });

    test('SupabaseService case-insensitive and trimmed code match', () async {
      final service = SupabaseService();
      final result = await service.validateCouponDetailed('  5555  ', 50.0);

      expect(result.isValid, isTrue);
      expect(result.coupon!.code, equals('5555'));
    });

    test('CartProvider successfully applies coupon 5555 and updates totals', () async {
      final cart = CartProvider();
      
      const product = ProductModel(
        id: 'prod-01',
        nameAr: 'أرز بسمتي فاخر',
        nameEn: 'Basmati Rice',
        brand: 'العائلة',
        price: 100.0,
        stockQuantity: 50,
      );

      cart.addItem(product, quantity: 1.0);
      expect(cart.subtotal, equals(100.0));

      // Apply coupon 5555
      final error = await cart.applyCoupon('5555');
      expect(error, isNull);
      expect(cart.appliedCoupon, isNotNull);
      expect(cart.appliedCoupon!.code, equals('5555'));
      expect(cart.couponDiscount, equals(15.0)); // 15% of 100
      expect(cart.totalAmount, equals(5085.0)); // 100 - 15 + 5000 base delivery fee below threshold
    });
  });
}
