import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/cart_provider.dart';
import '../cart_screen.dart';

/// Luxury Floating Cart Bar
/// ظهر في أسفل الشاشة عند وجود منتجات في السلة بتصميم ملكي أزرق وتفاعل سلس
class FloatingCartBar extends StatelessWidget {
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const FloatingCartBar({
    super.key,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    if (cart.itemCount == 0) {
      return const SizedBox.shrink();
    }

    final void Function() handleTap = onTap ??
        () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CartScreen()),
          );
        };

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Container(
          margin: margin ?? const EdgeInsets.fromLTRB(14, 4, 14, 12),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: handleTap,
              borderRadius: BorderRadius.circular(20),
              splashColor: Colors.white12,
              child: Ink(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF0A3678), // Deep Royal Navy
                      AppColors.primary,  // 0xFF0D47A1
                      Color(0xFF1565C0), // Vibrant Blue
                    ],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.42),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Cart Icon with Notification Badge
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Badge(
                        label: Text(
                          '${cart.itemCount}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: AppColors.secondary,
                        offset: const Offset(-4, -4),
                        child: const Icon(
                          Icons.shopping_cart_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Price and Summary Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${cart.totalAmount.toStringAsFixed(2)} ل.س',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: cart.isFreeDelivery
                                        ? AppColors.freshGreen.withValues(alpha: 0.25)
                                        : Colors.amberAccent.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: cart.isFreeDelivery
                                          ? AppColors.freshGreen.withValues(alpha: 0.5)
                                          : Colors.amberAccent.withValues(alpha: 0.5),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    cart.isFreeDelivery ? 'توصيل مجاني 🛵' : 'توصيل فوري ⚡',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: cart.isFreeDelivery
                                          ? const Color(0xFF6EE7B7)
                                          : const Color(0xFFFDE68A),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            cart.isFreeDelivery
                                ? '${cart.itemCount} أصناف بالسلة • جاهز لإتمام الطلب'
                                : 'متبقي ${cart.remainingForFreeDelivery.toStringAsFixed(0)} ل.س للتوصيل المجاني',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Gold Action Button "عرض السلة / إتمام الطلب"
                    ElevatedButton(
                      onPressed: handleTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent, // Gold 0xFFFFB300
                        foregroundColor: AppColors.textPrimary,
                        elevation: 2,
                        shadowColor: Colors.black38,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'عرض السلة',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_back_rounded,
                            size: 15,
                            color: Color(0xFF0F172A),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
