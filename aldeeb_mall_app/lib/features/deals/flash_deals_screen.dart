import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/flash_deal_model.dart';
import '../../core/models/product_model.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/providers/mall_provider.dart';
import '../../core/utils/responsive.dart';
import '../cart/cart_screen.dart';
import '../product/product_detail_screen.dart';

class FlashDealsScreen extends StatefulWidget {
  const FlashDealsScreen({super.key});

  @override
  State<FlashDealsScreen> createState() => _FlashDealsScreenState();
}

class _FlashDealsScreenState extends State<FlashDealsScreen> {
  Timer? _countdownTimer;
  late Duration _remainingDuration;
  String _selectedFilter = 'all'; // 'all', 'high_discount', 'low_stock'

  @override
  void initState() {
    super.initState();
    // Default 3 hours, 45 minutes, 20 seconds countdown
    _remainingDuration = const Duration(hours: 3, minutes: 45, seconds: 20);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingDuration.inSeconds > 0) {
        setState(() {
          _remainingDuration = _remainingDuration - const Duration(seconds: 1);
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatTwoDigits(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final mall = Provider.of<MallProvider>(context);
    final cart = Provider.of<CartProvider>(context);
    final isDesktop = Responsive.isDesktop(context);
    final isTablet = Responsive.isTablet(context);

    final allDeals = mall.flashDeals;
    final filteredDeals = allDeals.where((deal) {
      if (_selectedFilter == 'high_discount') {
        return deal.discountPercent >= 25;
      }
      if (_selectedFilter == 'low_stock') {
        return deal.remainingUnits <= 30;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt_rounded, color: Colors.amber, size: 24),
            SizedBox(width: 8),
            Text(
              'عروض الفلاش الخاطفة (Flash Sale)',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Badge(
              label: Text('${cart.itemCount}'),
              isLabelVisible: cart.itemCount > 0,
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: CustomScrollView(
          slivers: [
            // 1. Ticking Flash Sale Header Banner
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F172A)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3), width: 1.5),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bolt_rounded, color: Colors.black, size: 18),
                              SizedBox(width: 4),
                              Text(
                                'تخفيضات كبرى محدودة الوقت',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'الأسعار مشتعلة والكميات تنفد سريعاً! 🔥',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Countdown Clock Boxes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTimerBox(_formatTwoDigits(_remainingDuration.inHours), 'ساعة'),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Text(':', style: TextStyle(color: Colors.amber, fontSize: 24, fontWeight: FontWeight.bold)),
                        ),
                        _buildTimerBox(_formatTwoDigits(_remainingDuration.inMinutes % 60), 'دقيقة'),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Text(':', style: TextStyle(color: Colors.amber, fontSize: 24, fontWeight: FontWeight.bold)),
                        ),
                        _buildTimerBox(_formatTwoDigits(_remainingDuration.inSeconds % 60), 'ثانية'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 2. Filter Chips
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _buildFilterChip('all', 'كافة العروض (${allDeals.length})'),
                    const SizedBox(width: 8),
                    _buildFilterChip('high_discount', 'خصم 25%+ فأكثر 🔥'),
                    const SizedBox(width: 8),
                    _buildFilterChip('low_stock', 'أوشكت على النفاد ⏳'),
                  ],
                ),
              ),
            ),

            // 3. Deals Grid
            if (filteredDeals.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Text(
                    'لا توجد عروض فلاش مطابقة للتصفية حالياً',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isDesktop ? 4 : (isTablet ? 3 : 2),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.65,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final deal = filteredDeals[index];
                      final product = mall.getProductForFlashDeal(deal);
                      return _buildDealCard(context, deal, product, cart);
                    },
                    childCount: filteredDeals.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerBox(String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF334155),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.amber,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = key),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.amber : AppColors.border,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.amber.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildDealCard(BuildContext context, FlashDealModel deal, ProductModel product, CartProvider cart) {
    final percent = deal.percentClaimed;
    final isAlmostGone = deal.remainingUnits <= 25;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image with Discount Badge
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: AspectRatio(
                        aspectRatio: 1.1,
                        child: CachedNetworkImage(
                          imageUrl: deal.productImage,
                          fit: BoxFit.cover,
                          placeholder: (ctx, url) => Container(color: Colors.grey.shade100),
                          errorWidget: (ctx, url, err) => const Icon(Icons.image_not_supported_outlined),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.4),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bolt_rounded, color: Colors.white, size: 12),
                            Text(
                              '-${deal.discountPercent}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Title
                Text(
                  deal.productNameAr,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),

                // Price Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${deal.dealPrice.toStringAsFixed(0)} ل.س',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${deal.originalPrice.toStringAsFixed(0)} ل.س',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Quota Progress Bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'تم حجز $percent%',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isAlmostGone ? Colors.red : Colors.grey.shade700,
                          ),
                        ),
                        Text(
                          'باقي ${deal.remainingUnits} قطع',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isAlmostGone ? Colors.red : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percent / 100.0,
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isAlmostGone ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Add to Cart Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      cart.addToCart(product);
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✓ أضيف "${deal.productNameAr}" بسعر العرض للسلة!'),
                          duration: const Duration(seconds: 2),
                          backgroundColor: Colors.black87,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      foregroundColor: Colors.black,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_shopping_cart_rounded, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'أضف للعربة',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
