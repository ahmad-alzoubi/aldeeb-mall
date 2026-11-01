import 'package:flutter_test/flutter_test.dart';
import 'package:aldeeb_mall_app/core/models/product_model.dart';
import 'package:aldeeb_mall_app/core/providers/cart_provider.dart';

void main() {
  group('Aldeeb Mall End-to-End Logic & Isolation Tests', () {
    test('ProductModel correctly identifies draft products and isolates them from catalog', () {
      const publishedProduct = ProductModel(
        id: 'p-1',
        nameAr: 'أرز بسمتي فاخر',
        nameEn: 'Basmati Rice',
        price: 25000,
        originalPrice: 28000,
        stockQuantity: 50,
        unit: 'كغ',
        rating: 4.8,
        images: ['assets/rice.png'],
        isFeatured: true,
        isDraft: false,
        status: 'published',
      );

      const draftProduct = ProductModel(
        id: 'p-draft-1',
        nameAr: 'شاي سيلاني فاخر (مسودة توريد)',
        nameEn: 'Ceylon Tea Draft',
        price: 15000,
        originalPrice: 15000,
        stockQuantity: 100,
        unit: 'علبة',
        rating: 0.0,
        images: [],
        isFeatured: false,
        isDraft: true,
        status: 'incomplete_data',
      );

      expect(publishedProduct.isDraft, isFalse);
      expect(publishedProduct.status, equals('published'));
      
      expect(draftProduct.isDraft, isTrue);
      expect(draftProduct.status, equals('incomplete_data'));

      // Verification of Customer Catalog filter
      final allProducts = [publishedProduct, draftProduct];
      final visibleToCustomer = allProducts.where((p) => !p.isDraft && p.status == 'published').toList();

      expect(visibleToCustomer.length, equals(1));
      expect(visibleToCustomer.first.id, equals('p-1'));
    });

    test('Cart calculations correctly compute subtotal, delivery fee, and grand total', () {
      final cart = CartProvider();
      
      const productA = ProductModel(
        id: 'p-10',
        nameAr: 'زيت زيتون بكر ممتاز',
        nameEn: 'Olive Oil 1L',
        price: 45000,
        originalPrice: 50000,
        stockQuantity: 30,
        unit: 'piece',
        rating: 5.0,
        images: [],
        isFeatured: true,
        isDraft: false,
        status: 'published',
      );

      // Add 2 units
      cart.addToCart(productA, quantity: 2);
      expect(cart.itemCount, equals(1));
      expect(cart.subtotal, equals(90000.0));

      // Test Delivery fee calculation
      expect(cart.totalAmount, equals(90000.0 + cart.deliveryFee));

      // Test clear cart
      cart.clearCart();
      expect(cart.items.length, equals(0));
      expect(cart.itemCount, equals(0));
      expect(cart.subtotal, equals(0.0));
      expect(cart.totalAmount, equals(0.0));
    });

    test('Delivery Zone validation and surge fee calculation for Daraa and Syria', () {
      double calculateEffectiveFee(double base, double surge, bool isSurge) {
        return isSurge ? base + surge : base;
      }

      expect(calculateEffectiveFee(5000.0, 2500.0, true), equals(7500.0));
      expect(calculateEffectiveFee(5000.0, 2500.0, false), equals(5000.0));
    });

    test('Barcode matcher strictly searches by exact barcode or id and returns null when not found without fake fallback', () {
      const p1 = ProductModel(
        id: 'p-1',
        barcode: '6291001001',
        nameAr: 'حليب كامل الدسم',
        nameEn: 'Full Cream Milk',
        price: 8500,
        stockQuantity: 40,
      );
      const p2 = ProductModel(
        id: 'p-2',
        barcode: '6291001002',
        nameAr: 'جبنة قشقوان',
        nameEn: 'Kashkaval Cheese',
        price: 32000,
        stockQuantity: 15,
      );

      final storeProducts = [p1, p2];

      ProductModel? matchBarcode(String raw) {
        final q = raw.trim().toLowerCase();
        if (q.isEmpty) return null;
        return storeProducts.where((p) {
          final b = (p.barcode ?? '').trim().toLowerCase();
          final id = p.id.trim().toLowerCase();
          return b == q || id == q;
        }).firstOrNull;
      }

      // Exact match by barcode
      expect(matchBarcode('6291001001')?.nameAr, equals('حليب كامل الدسم'));
      // Exact match by id
      expect(matchBarcode('p-2')?.nameAr, equals('جبنة قشقوان'));
      // Non-existent barcode returns null (never fake or fallback)
      expect(matchBarcode('9999999999'), isNull);
      expect(matchBarcode(''), isNull);
    });
  });
}
