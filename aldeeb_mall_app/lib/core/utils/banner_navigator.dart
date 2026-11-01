import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/banner_model.dart';
import '../models/category_model.dart';
import '../providers/cart_provider.dart';
import '../providers/mall_provider.dart';
import '../providers/order_provider.dart';
import '../../features/category/department_screen.dart';
import '../../features/category/categories_screen.dart';
import '../../features/product/product_detail_screen.dart';
import '../../features/flyer/flyer_screen.dart';
import '../../features/loyalty/loyalty_screen.dart';
import '../../features/grocery_list/grocery_list_screen.dart';
import '../../features/recipes/recipes_screen.dart';
import '../../features/group_buying/group_deals_screen.dart';
import '../../features/subscriptions/subscriptions_screen.dart';
import '../../features/ai_nutritionist/ai_nutritionist_screen.dart';
import '../../features/smart_cart_iot/smart_cart_iot_screen.dart';
import '../../features/scanner/barcode_scanner_screen.dart';
import '../../features/cart/cart_screen.dart';
import '../../features/orders/order_tracking_screen.dart';
import '../../features/navigation/in_store_navigator_screen.dart';

class BannerNavigator {
  /// Executes the navigation or action associated with a [BannerModel].
  static Future<void> handleTap(BuildContext context, BannerModel banner) async {
    final type = banner.targetType.trim().toLowerCase();
    final target = (banner.targetId ?? '').trim();

    switch (type) {
      case 'category':
        _navigateToCategory(context, target);
        break;

      case 'product':
        _navigateToProduct(context, target);
        break;

      case 'screen':
      case 'page':
        _navigateToScreen(context, target);
        break;

      case 'coupon':
        await _applyCouponAction(context, target);
        break;

      case 'deal':
      case 'deals':
        // If target corresponds to a category, product, or flyer
        if (target.startsWith('c') || target.startsWith('cat_')) {
          _navigateToCategory(context, target);
        } else if (target.startsWith('p') || target.startsWith('prod_')) {
          _navigateToProduct(context, target);
        } else {
          // Open digital deals flyer by default
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FlyerScreen()),
          );
        }
        break;

      case 'external':
        _showExternalLinkDialog(context, banner.titleAr, target);
        break;

      default:
        // Default action: if target points to a known screen or category
        if (target.isNotEmpty) {
          _navigateToScreen(context, target);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FlyerScreen()),
          );
        }
        break;
    }
  }

  static void _navigateToCategory(BuildContext context, String categoryId) {
    final mall = Provider.of<MallProvider>(context, listen: false);
    if (mall.categories.isEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CategoriesScreen()),
      );
      return;
    }

    final match = mall.categories.firstWhere(
      (c) => c.id == categoryId || c.slug == categoryId,
      orElse: () => mall.categories.first,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DepartmentScreen(category: match),
      ),
    );
  }

  static void _navigateToProduct(BuildContext context, String productId) {
    final mall = Provider.of<MallProvider>(context, listen: false);
    if (mall.products.isEmpty) {
      _showToast(context, 'جاري تحديث بيانات المنتجات...', isSuccess: false);
      return;
    }

    final match = mall.products.firstWhere(
      (p) => p.id == productId || p.barcode == productId,
      orElse: () => mall.products.first,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(product: match),
      ),
    );
  }

  static void _navigateToScreen(BuildContext context, String screenKey) {
    final key = screenKey.toLowerCase().replaceAll('-', '_');

    Widget? destination;

    switch (key) {
      case 'flyer':
      case 'deals':
      case 'flash_deals':
      case 'offers':
      case 'zero_waste':
      case 'food_rescue':
        destination = const FlyerScreen();
        break;

      case 'loyalty':
      case 'rewards':
      case 'points':
        destination = const LoyaltyScreen();
        break;

      case 'group_deals':
      case 'group_buying':
        destination = const GroupDealsScreen();
        break;

      case 'grocery_list':
      case 'smart_list':
      case 'shopping_list':
        destination = const GroceryListScreen();
        break;

      case 'meal_kits':
      case 'recipes_kits':
      case 'recipes':
      case 'cooking':
        destination = const RecipesScreen();
        break;

      case 'butcher':
      case 'meat_cutting':
      case 'meat':
        final mall = Provider.of<MallProvider>(context, listen: false);
        final meatCat = mall.categories.firstWhere(
          (c) => c.slug.contains('meat') || c.nameAr.contains('لحوم') || c.id == 'c3',
          orElse: () => const CategoryModel(
            id: 'c3',
            nameAr: 'اللحوم والدواجن والأسماك',
            nameEn: 'Fresh Meat & Poultry',
            slug: 'meat',
          ),
        );
        destination = DepartmentScreen(category: meatCat);
        break;

      case 'subscriptions':
      case 'autoship':
        destination = const SubscriptionsScreen();
        break;

      case 'ai_nutritionist':
      case 'nutrition':
        destination = const AiNutritionistScreen();
        break;

      case 'smart_cart':
        destination = const SmartCartIoTScreen();
        break;

      case 'scanner':
      case 'scan_and_go':
        destination = const BarcodeScannerScreen();
        break;

      case 'in_store':
      case 'navigator':
        destination = const InStoreNavigatorScreen();
        break;

      case 'cart':
        destination = const CartScreen();
        break;

      case 'orders':
      case 'order_tracking':
        final orderProv = Provider.of<OrderProvider>(context, listen: false);
        if (orderProv.orders.isNotEmpty) {
          destination = OrderTrackingScreen(order: orderProv.orders.first);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('لا توجد طلبات سابقة للتتبع حالياً')),
          );
          return;
        }
        break;

      case 'categories':
      case 'all_categories':
        destination = const CategoriesScreen();
        break;

      default:
        // Try category lookup if matched
        _navigateToCategory(context, screenKey);
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => destination!),
    );
  }

  static Future<void> _applyCouponAction(BuildContext context, String couponCode) async {
    final code = couponCode.isEmpty ? 'FREE100' : couponCode;
    final cart = Provider.of<CartProvider>(context, listen: false);

    final error = await cart.applyCoupon(code);
    if (!context.mounted) return;

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '🎉 تم تفعيل كود الخصم ($code) بنجاح على سلة مشترياتك!',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  );
                },
                child: const Text(
                  'عرض السلة',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      _showToast(context, 'كود الخصم ($code): $error', isSuccess: false);
    }
  }

  static void _showExternalLinkDialog(BuildContext context, String title, String url) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.link, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('رابط العرض الترويجي الخارجي:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: SelectableText(
                url.isNotEmpty ? url : 'https://aldeebmall.com/offers',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  static void _showToast(BuildContext context, String message, {bool isSuccess = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isSuccess ? AppColors.primary : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
