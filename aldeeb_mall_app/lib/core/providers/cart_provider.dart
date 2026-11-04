import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../models/cart_item_model.dart';
import '../models/coupon_model.dart';
import '../models/delivery_coverage_result.dart';
import '../services/supabase_service.dart';

class CartProvider extends ChangeNotifier {
  final Map<String, CartItemModel> _items = {};
  CouponModel? _appliedCoupon;
  int _loyaltyPointsUsed = 0;
  DeliveryCoverageResult? _coverageResult;

  DeliveryCoverageResult? get coverageResult => _coverageResult;

  double get freeDeliveryThreshold => _coverageResult?.freeDeliveryThreshold ?? 150000.0;
  double get baseDeliveryFee => _coverageResult?.baseDeliveryFee ?? 5000.0;
  int get estimatedDeliveryMinutes => _coverageResult?.estimatedMinutes ?? 25;
  String get assignedBranchId => _coverageResult?.branchId ?? 'b-dam-01';
  String get assignedBranchName => _coverageResult?.branchNameAr ?? 'فرع دمشق المركزي (أوتوستراد المزة)';

  Map<String, CartItemModel> get items => {..._items};
  int get itemCount => _items.length;
  CouponModel? get appliedCoupon => _appliedCoupon;
  int get loyaltyPointsUsed => _loyaltyPointsUsed;

  double get subtotal {
    double total = 0.0;
    _items.forEach((key, item) {
      total += item.totalPrice;
    });
    return total;
  }

  bool get isFreeDelivery => subtotal >= freeDeliveryThreshold && subtotal > 0;

  double get deliveryFee {
    if (subtotal == 0 || isFreeDelivery) return 0.0;
    if (_coverageResult != null) {
      return _coverageResult!.finalDeliveryFee;
    }
    return baseDeliveryFee;
  }

  void setDeliveryCoverageQuote(DeliveryCoverageResult quote) {
    _coverageResult = quote;
    notifyListeners();
  }

  void resetDeliveryQuote() {
    _coverageResult = null;
    notifyListeners();
  }

  double get remainingForFreeDelivery {
    if (isFreeDelivery || subtotal == 0) return 0.0;
    return freeDeliveryThreshold - subtotal;
  }

  double get freeDeliveryProgress {
    if (subtotal == 0) return 0.0;
    if (isFreeDelivery) return 1.0;
    return (subtotal / freeDeliveryThreshold).clamp(0.0, 1.0);
  }

  double get couponDiscount {
    if (_appliedCoupon == null) return 0.0;
    return _appliedCoupon!.calculateDiscount(subtotal);
  }

  double get loyaltyDiscount {
    // 100 points = 1.00 currency unit
    return (_loyaltyPointsUsed * 0.01).clamp(0.0, subtotal);
  }

  double get totalAmount {
    if (subtotal == 0) return 0.0;
    final total = subtotal + deliveryFee - couponDiscount - loyaltyDiscount;
    return total > 0 ? total : 0.0;
  }

  bool isInCart(String productId) => _items.containsKey(productId);

  double getProductQuantity(String productId) {
    return _items[productId]?.quantity ?? 0.0;
  }

  // 1. Add or Update Item
  void addToCart(ProductModel product, {double? quantity}) {
    final qtyToAdd = quantity ?? (product.unit == 'kg' ? product.weightStep : 1.0);

    if (_items.containsKey(product.id)) {
      _items[product.id]!.quantity += qtyToAdd;
    } else {
      _items[product.id] = CartItemModel(
        product: product,
        quantity: qtyToAdd,
      );
    }
    _revalidateDiscounts();
    notifyListeners();
  }

  // Alias for addToCart
  void addItem(ProductModel product, {double? quantity}) {
    addToCart(product, quantity: quantity);
  }

  // 1.1 Add Complete Bundle with Promised Discount
  void addBundleToCart(ProductModel mainProduct, List<ProductModel> complementary, int discountPercent) {
    final multiplier = (1.0 - (discountPercent / 100.0));
    final discountedMain = mainProduct.copyWith(
      price: double.parse((mainProduct.price * multiplier).toStringAsFixed(2)),
      originalPrice: mainProduct.price,
      discountPercent: discountPercent,
    );
    addToCart(discountedMain);

    for (final p in complementary) {
      final discountedComp = p.copyWith(
        price: double.parse((p.price * multiplier).toStringAsFixed(2)),
        originalPrice: p.price,
        discountPercent: discountPercent,
      );
      addToCart(discountedComp);
    }
  }

  // 2. Decrement or Remove
  void decrementQuantity(ProductModel product) {
    if (!_items.containsKey(product.id)) return;

    final step = product.unit == 'kg' ? product.weightStep : 1.0;
    if (_items[product.id]!.quantity <= step) {
      _items.remove(product.id);
    } else {
      _items[product.id]!.quantity -= step;
    }
    _revalidateDiscounts();
    notifyListeners();
  }

  // 3. Remove directly
  void removeFromCart(String productId) {
    _items.remove(productId);
    _revalidateDiscounts();
    notifyListeners();
  }

  // 4. Set exact quantity
  void setQuantity(String productId, double quantity) {
    if (_items.containsKey(productId)) {
      if (quantity <= 0) {
        _items.remove(productId);
      } else {
        _items[productId]!.quantity = quantity;
      }
      _revalidateDiscounts();
      notifyListeners();
    }
  }

  // 5. Apply Coupon
  Future<String?> applyCoupon(String code) async {
    final result = await SupabaseService().validateCouponDetailed(code, subtotal);
    if (result.isValid && result.coupon != null) {
      _appliedCoupon = result.coupon;
      notifyListeners();
      return null; // Success, no error
    } else {
      return result.errorMessage ?? 'كود الخصم غير صالح أو لم يصل للحد الأدنى للطلب';
    }
  }

  void applyCouponDirectly(CouponModel coupon) {
    _appliedCoupon = coupon;
    notifyListeners();
  }

  void removeCoupon() {
    _appliedCoupon = null;
    notifyListeners();
  }

  // 6. Add Free Reward Item (Redeemed via Loyalty Points)
  void addFreeRewardProduct({
    required String id,
    required String nameAr,
    required String nameEn,
    required String imageUrl,
  }) {
    final rewardProduct = ProductModel(
      id: id,
      nameAr: '$nameAr (هدية نقاط)',
      nameEn: nameEn,
      barcode: 'REWARD-$id',
      brand: 'نادي مكافآت الديب VIP',
      price: 0.0,
      originalPrice: 0.0,
      discountPercent: 100,
      unit: 'piece',
      weightStep: 1.0,
      images: [imageUrl],
      isFeatured: false,
      isDailyDeal: false,
      rating: 5.0,
      salesCount: 100,
      stockQuantity: 50,
    );
    _items[rewardProduct.id] = CartItemModel(product: rewardProduct, quantity: 1.0);
    _revalidateDiscounts();
    notifyListeners();
  }

  // 7. Redeem Loyalty Points
  void setLoyaltyPointsUsed(int points, int userMaxPoints) {
    final allowedMax = userMaxPoints;
    // Don't allow points discount to exceed 50% of subtotal
    final maxPointsAllowedBySubtotal = ((subtotal * 0.5) * 100).toInt();
    final effectiveMax = allowedMax < maxPointsAllowedBySubtotal ? allowedMax : maxPointsAllowedBySubtotal;

    _loyaltyPointsUsed = points.clamp(0, effectiveMax);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _appliedCoupon = null;
    _loyaltyPointsUsed = 0;
    notifyListeners();
  }

  void _revalidateDiscounts() {
    if (_appliedCoupon != null && subtotal < _appliedCoupon!.minOrderAmount) {
      _appliedCoupon = null;
    }
  }
}
