import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/banner_model.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/providers/mall_provider.dart';
import '../../core/services/auth_service.dart';
import '../cart/cart_screen.dart';
import '../loyalty/loyalty_screen.dart';
import 'widgets/product_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _bannerController = PageController();
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;

  // Flash Sale Countdown Simulation
  late Duration _remainingTime;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _remainingTime = const Duration(hours: 5, minutes: 22, seconds: 40);
    _startTimers();
  }

  void _startTimers() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_bannerController.hasClients) {
        final mall = Provider.of<MallProvider>(context, listen: false);
        if (mall.banners.isNotEmpty) {
          final next = (_currentBannerIndex + 1) % mall.banners.length;
          _bannerController.animateToPage(
            next,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic,
          );
        }
      }
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_remainingTime.inSeconds > 0) {
            _remainingTime = _remainingTime - const Duration(seconds: 1);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _countdownTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final h = twoDigits(d.inHours);
    final m = twoDigits(d.inMinutes.remainder(60));
    final s = twoDigits(d.inSeconds.remainder(60));
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final mall = Provider.of<MallProvider>(context);
    final cart = Provider.of<CartProvider>(context);
    final auth = Provider.of<AuthService>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // 1. App Bar with Location & Brand
              SliverAppBar(
                floating: true,
                pinned: true,
                elevation: 0,
                backgroundColor: AppColors.primary,
                expandedHeight: 125,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primaryDark, AppColors.primary],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 40, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header row: Location & Points & Cart
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.location_on, color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'التوصيل إلى',
                                    style: TextStyle(color: Colors.white70, fontSize: 10),
                                  ),
                                  Text(
                                    'وسط دبي، برج فيوز B',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),

                            // Loyalty Points Pill
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const LoyaltyScreen()),
                                );
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.stars_rounded, color: AppColors.textPrimary, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${auth.currentUser?.loyaltyPoints ?? 50} نقطة',
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Notifications
                            IconButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('لديك 3 كوبونات خصم جديدة في صندوق الوارد!')),
                                );
                              },
                              icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(54),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          const Icon(Icons.search, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              onChanged: (val) => mall.setSearchQuery(val),
                              decoration: const InputDecoration(
                                hintText: 'ابحث في آلاف منتجات الديب مول...',
                                hintStyle: TextStyle(fontSize: 13, color: AppColors.textMuted),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary, size: 20),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('ماسح الباركود السريع: وجّه الكاميرا لباركود المنتج')),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 2. Hero Banners Carousel
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 160,
                        child: PageView.builder(
                          controller: _bannerController,
                          onPageChanged: (idx) => setState(() => _currentBannerIndex = idx),
                          itemCount: mall.banners.length,
                          itemBuilder: (ctx, index) {
                            final b = mall.banners[index];
                            return _buildBannerSlide(b);
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(mall.banners.length, (idx) {
                          final isSel = _currentBannerIndex == idx;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: isSel ? 18 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isSel ? AppColors.primary : AppColors.border,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Quick Categories Strip
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'أقسام الهايبرماركت',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            TextButton(
                              onPressed: () => mall.selectCategory(null),
                              child: const Text('عرض الكل', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 95,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: mall.categories.length,
                          itemBuilder: (ctx, index) {
                            final cat = mall.categories[index];
                            final isSel = mall.selectedCategoryId == cat.id;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: InkWell(
                                onTap: () {
                                  mall.selectCategory(isSel ? null : cat.id);
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 58,
                                      height: 58,
                                      decoration: BoxDecoration(
                                        color: isSel ? AppColors.primary : Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSel ? AppColors.primary : AppColors.border,
                                          width: 2,
                                        ),
                                        boxShadow: AppColors.cardShadow,
                                      ),
                                      child: ClipOval(
                                        child: cat.imageUrl != null
                                            ? CachedNetworkImage(
                                                imageUrl: cat.imageUrl!,
                                                fit: BoxFit.cover,
                                              )
                                            : const Icon(Icons.shopping_basket, color: AppColors.primary),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    SizedBox(
                                      width: 70,
                                      child: Text(
                                        cat.nameAr,
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                          color: isSel ? AppColors.primary : AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Flash Deals Section (Carrefour Mega Deals)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.flash_on_rounded, color: AppColors.secondary, size: 22),
                        const SizedBox(width: 8),
                        const Text(
                          'عروض الصفقات الكبرى',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.secondary),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _formatDuration(_remainingTime),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Flash Deals Horizontal List
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 290,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: mall.dailyDeals.length,
                    itemBuilder: (ctx, index) {
                      return Container(
                        width: 170,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        child: ProductCard(product: mall.dailyDeals[index]),
                      );
                    },
                  ),
                ),
              ),

              // 5. All Products Grid Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        mall.selectedCategoryId != null ? 'المنتجات المختارة' : 'جميع المنتجات والعروض',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      Text(
                        '${mall.filteredProducts.length} صنف',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),

              // 6. Products Grid
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.65,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (ctx, index) => ProductCard(product: mall.filteredProducts[index]),
                    childCount: mall.filteredProducts.length,
                  ),
                ),
              ),
            ],
          ),

          // Floating Smart Cart Bar (Slides up when items > 0)
          if (cart.itemCount > 0)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppColors.floatingShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${cart.itemCount}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${cart.totalAmount.toStringAsFixed(2)} د.إ',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          cart.isFreeDelivery ? 'توصيل مجاني 🛵' : 'تبقّى ${cart.remainingForFreeDelivery.toStringAsFixed(2)} د.إ للمجاني',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CartScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        minimumSize: const Size(100, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      child: const Row(
                        children: [
                          Text('عرض السلة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios_rounded, size: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBannerSlide(BannerModel banner) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: banner.imageUrl,
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (banner.badgeAr != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        banner.badgeAr!,
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  Text(
                    banner.titleAr,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  if (banner.subtitleAr != null)
                    Text(
                      banner.subtitleAr!,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
