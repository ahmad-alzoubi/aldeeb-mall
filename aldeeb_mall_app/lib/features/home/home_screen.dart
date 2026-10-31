import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/banner_model.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/providers/mall_provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/responsive.dart';
import '../cart/cart_screen.dart';
import '../loyalty/loyalty_screen.dart';
import '../scanner/barcode_scanner_screen.dart';
import '../flyer/flyer_screen.dart';
import '../voice/voice_assistant_modal.dart';
import '../subscriptions/subscriptions_screen.dart';
import '../wallet/wallet_screen.dart';
import '../group_buying/group_deals_screen.dart';
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
  late Duration _remainingTime;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _remainingTime = const Duration(hours: 5, minutes: 22, seconds: 40);
    _startTimers();
  }

  void _startTimers() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
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
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // 1. Navigation App Bar (Adaptive Desktop vs Mobile)
              if (isDesktop)
                SliverToBoxAdapter(
                  child: _buildDesktopTopNav(context, cart, auth, mall),
                )
              else
                _buildMobileSliverAppBar(context, auth, mall),

              // 1.5. Quick Commerce Mode Switcher (15-Min Noon Minutes vs Hypermarket)
              SliverToBoxAdapter(
                child: MaxWidthContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildDeliveryModeSwitchBar(mall),
                      if (mall.isExpress15Min) _buildExpressActiveBanner(),
                    ],
                  ),
                ),
              ),

              // 2. Department Category Strip
              SliverToBoxAdapter(
                child: MaxWidthContainer(
                  child: _buildCategoriesStrip(mall, isDesktop),
                ),
              ),

              // 3. Hero Promo Section (Split grid on desktop, carousel on mobile)
              SliverToBoxAdapter(
                child: MaxWidthContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildHeroSection(mall, isDesktop),
                      _buildFlyerBanner(context),
                      _buildSubscribeAndSaveBanner(context),
                      _buildGroupDealsBanner(context),
                    ],
                  ),
                ),
              ),

              // 3.5. Quick Reorder / Buy Again Essentials
              SliverToBoxAdapter(
                child: MaxWidthContainer(
                  child: _buildBuyAgainSection(mall, cart, isDesktop),
                ),
              ),

              // 4. Flash Deals Header & Horizontal Scroller
              SliverToBoxAdapter(
                child: MaxWidthContainer(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: _buildFlashDealsHeader(),
                ),
              ),

              SliverToBoxAdapter(
                child: MaxWidthContainer(
                  child: SizedBox(
                    height: 295,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: mall.dailyDeals.length,
                      itemBuilder: (ctx, index) {
                        return Container(
                          width: isDesktop ? 220 : 170,
                          margin: const EdgeInsetsDirectional.only(end: 12),
                          child: ProductCard(product: mall.dailyDeals[index]),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // 5. Section Header for All Products
              SliverToBoxAdapter(
                child: MaxWidthContainer(
                  padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 20,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            mall.selectedCategoryId != null ? 'المنتجات المختارة' : 'كافة منتجات الهايبرماركت',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${mall.filteredProducts.length} صنف متاح',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 6. Responsive Products Grid
              SliverToBoxAdapter(
                child: MaxWidthContainer(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: Responsive.gridColumns(context),
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: Responsive.productCardAspectRatio(context),
                    ),
                    itemCount: mall.filteredProducts.length,
                    itemBuilder: (ctx, index) => ProductCard(product: mall.filteredProducts[index]),
                  ),
                ),
              ),
            ],
          ),

          // Floating Smart Cart Bar (Mobile Only - on Desktop it's in the top nav!)
          if (!isDesktop && cart.itemCount > 0)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _buildFloatingCartBar(cart),
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Desktop Luxury Top Header (Apple & Carrefour Web Grade)
  // ===========================================================================
  Widget _buildDesktopTopNav(
    BuildContext context,
    CartProvider cart,
    AuthService auth,
    MallProvider mall,
  ) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A0D47A1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main Top Navigation Bar
          MaxWidthContainer(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Row(
              children: [
                // Brand Logo
                InkWell(
                  onTap: () => mall.selectCategory(null),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.shopping_bag_rounded, color: AppColors.primary, size: 26),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الديب مول',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            'Aldeeb Hypermarket',
                            style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 32),

                // Delivery Location Dropdown Chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('التوصيل إلى', style: TextStyle(color: Colors.white70, fontSize: 10)),
                          Text(
                            'وسط دبي، برج فيوز B',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 18),
                    ],
                  ),
                ),
                const SizedBox(width: 24),

                // Large Search Bar (Takes remaining space)
                Expanded(
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 14),
                        const Icon(Icons.search, color: AppColors.primary, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            onChanged: (val) => mall.setSearchQuery(val),
                            decoration: const InputDecoration(
                              hintText: 'ابحث عن آلاف المنتجات، الخضار، الألبان، والمؤن في الديب مول...',
                              hintStyle: TextStyle(fontSize: 13, color: AppColors.textMuted),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary, size: 22),
                          tooltip: 'المسح الذكي للباركود (Scan & Go)',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.mic_none_rounded, color: AppColors.primary, size: 22),
                          tooltip: 'البحث الصوتي الذكي (Voice AI)',
                          onPressed: () => VoiceAssistantModal.show(context),
                        ),
                        Container(
                          margin: const EdgeInsets.all(4),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text(
                              'بحث',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),

                // Loyalty Points Star Pill
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoyaltyScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.stars_rounded, color: AppColors.textPrimary, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          '${auth.currentUser?.loyaltyPoints ?? 50} نقطة ولاء',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Aldeeb Pay Wallet Pill
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const WalletScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.account_balance_wallet_rounded, color: AppColors.accent, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'المحفظة: 150.00 ر.س',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Cart Button with Total
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CartScreen()),
                    );
                  },
                  icon: Badge(
                    label: Text('${cart.itemCount}'),
                    isLabelVisible: cart.itemCount > 0,
                    child: const Icon(Icons.shopping_cart_outlined, size: 20),
                  ),
                  label: Text(
                    cart.itemCount > 0 ? '${cart.totalAmount.toStringAsFixed(2)} د.إ' : 'السلة',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Mobile Sliver App Bar
  // ===========================================================================
  Widget _buildMobileSliverAppBar(BuildContext context, AuthService auth, MallProvider mall) {
    return SliverAppBar(
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
                        Text('التوصيل إلى', style: TextStyle(color: Colors.white70, fontSize: 10)),
                        Text(
                          'وسط دبي، برج فيوز B',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
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
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const WalletScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.account_balance_wallet_rounded, color: AppColors.accent, size: 15),
                          SizedBox(width: 4),
                          Text(
                            '150 ر.س',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                  icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary, size: 20),
                  tooltip: 'المسح الذكي للباركود',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.mic_none_rounded, color: AppColors.primary, size: 20),
                  tooltip: 'البحث الصوتي الذكي (Voice AI)',
                  onPressed: () => VoiceAssistantModal.show(context),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // Categories Strip
  // ===========================================================================
  Widget _buildCategoriesStrip(MallProvider mall, bool isDesktop) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(vertical: isDesktop ? 16 : 10),
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
            height: isDesktop ? 100 : 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: mall.categories.length,
              itemBuilder: (ctx, index) {
                final cat = mall.categories[index];
                final isSel = mall.selectedCategoryId == cat.id;
                final size = isDesktop ? 64.0 : 54.0;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: InkWell(
                    onTap: () => mall.selectCategory(isSel ? null : cat.id),
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      children: [
                        Container(
                          width: size,
                          height: size,
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
                          width: 80,
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
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildDietaryPill(mall, null, 'كافة المنتجات 🛒'),
                  const SizedBox(width: 8),
                  _buildDietaryPill(mall, 'organic', 'عضوي معتمد 🌱'),
                  const SizedBox(width: 8),
                  _buildDietaryPill(mall, 'gluten_free', 'خالي من الغلوتين 🌾'),
                  const SizedBox(width: 8),
                  _buildDietaryPill(mall, 'keto', 'دايت وكيتو 🥑'),
                  const SizedBox(width: 8),
                  _buildDietaryPill(mall, 'high_protein', 'غني بالبروتين 💪'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDietaryPill(MallProvider mall, String? tag, String label) {
    final isSelected = mall.selectedDietaryFilter == tag;
    return InkWell(
      onTap: () => mall.setDietaryFilter(tag),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.freshGreen : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.freshGreen : AppColors.border,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.freshGreen.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check_rounded, color: Colors.white, size: 14),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // Hero Section (Split on Desktop, Carousel on Mobile)
  // ===========================================================================
  Widget _buildHeroSection(MallProvider mall, bool isDesktop) {
    if (mall.banners.isEmpty) return const SizedBox();

    if (!isDesktop) {
      // Mobile Single Carousel
      return Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Column(
          children: [
            SizedBox(
              height: 165,
              child: PageView.builder(
                controller: _bannerController,
                onPageChanged: (idx) => setState(() => _currentBannerIndex = idx),
                itemCount: mall.banners.length,
                itemBuilder: (ctx, index) => _buildBannerCard(mall.banners[index]),
              ),
            ),
            const SizedBox(height: 8),
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
      );
    }

    // Desktop Split Grid (2/3 Carousel + 1/3 Side Promo Cards - Carrefour Web Style)
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main 2/3 Carousel
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 320,
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _bannerController,
                    onPageChanged: (idx) => setState(() => _currentBannerIndex = idx),
                    itemCount: mall.banners.length,
                    itemBuilder: (ctx, index) => _buildBannerCard(mall.banners[index], height: 320),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 24,
                    child: Row(
                      children: List.generate(mall.banners.length, (idx) {
                        final isSel = _currentBannerIndex == idx;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: isSel ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isSel ? Colors.white : Colors.white54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Side 1/3 Promo Deal Cards
          Expanded(
            flex: 1,
            child: SizedBox(
              height: 320,
              child: Column(
                children: [
                  Expanded(
                    child: _buildSideDealCard(
                      'صفقة اليوم الطازجة 🍅',
                      'طماطم مزارع محلية قطاف الصباح بخصم 25%',
                      '3.75 د.إ / كجم',
                      'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?auto=format&fit=crop&w=400&q=80',
                      AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _buildSideDealCard(
                      'توصيل فوري خلال 60 دقيقة 🛵',
                      'اطلب طلبات البيت واستلمها على بابك',
                      'مجاناً للطلبات فوق 100 د.إ',
                      'https://images.unsplash.com/photo-1526367790999-0150786686a2?auto=format&fit=crop&w=400&q=80',
                      AppColors.primary,
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

  Widget _buildBannerCard(BannerModel banner, {double height = 165}) {
    return Container(
      height: height,
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
                    Colors.black.withValues(alpha: 0.75),
                    Colors.transparent,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (banner.badgeAr != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        banner.badgeAr!,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  Text(
                    banner.titleAr,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                  if (banner.subtitleAr != null)
                    Text(
                      banner.subtitleAr!,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSideDealCard(
    String title,
    String subtitle,
    String tag,
    String imageUrl,
    Color tagColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.black.withValues(alpha: 0.2),
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: tagColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
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

  Widget _buildFlashDealsHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.flash_on_rounded, color: AppColors.secondary, size: 24),
          const SizedBox(width: 8),
          const Text(
            'عروض الصفقات الكبرى المؤقتة',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.secondary),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _formatDuration(_remainingTime),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryModeSwitchBar(MallProvider mall) {
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 15-Min Express Option (Noon Minutes / الديب ناو)
          Expanded(
            child: InkWell(
              onTap: () => mall.toggleExpress15Min(true),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: mall.isExpress15Min ? AppColors.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bolt,
                      size: 18,
                      color: mall.isExpress15Min ? AppColors.textPrimary : AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'الديب ناو (15 دقيقة)',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: mall.isExpress15Min ? AppColors.textPrimary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Scheduled / Hypermarket Option
          Expanded(
            child: InkWell(
              onTap: () => mall.toggleExpress15Min(false),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: !mall.isExpress15Min ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.storefront_outlined,
                      size: 18,
                      color: !mall.isExpress15Min ? Colors.white : AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'سوبرماركت مجدول',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: !mall.isExpress15Min ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpressActiveBanner() {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: const Row(
        children: [
          Icon(Icons.electric_bolt, color: Color(0xFFD97706), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'وضع التوصيل الفوري فائق السرعة نشط (Noon Minutes / 15-Min)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF92400E)),
                ),
                SizedBox(height: 2),
                Text(
                  'يتم جمع طلبك فوراً من أقرب مستودع مظلم وتوصيله خلال 15 دقيقة بسيارة مبردة.',
                  style: TextStyle(fontSize: 10, color: Color(0xFFB45309)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlyerBanner(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FlyerScreen()),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مجلة عروض وتخفيضات الديب الأسبوعية 📰',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'تصفح صفحات المجلة التفاعلية واشترِ الصفقات مباشرة بخصم 45%',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscribeAndSaveBanner(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SubscriptionsScreen()),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF065F46), Color(0xFF059669)],
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.autorenew_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'اشتراكات المؤن الدورية (Subscribe & Save) 🔄',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'توصيل دوري للحليب والخبز والخضار مع خصم دائم 10% وتوصيل مجاني',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupDealsBanner(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GroupDealsScreen()),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFB91C1C), Color(0xFFDC2626)],
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.groups_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'صفقات الشراء الجماعي مع الجيران والأصدقاء 👥',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'وفر حتى 40% فور اكتمال المجموعة في حيك وتوصيل مجاني فوري لكل منزل',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildBuyAgainSection(MallProvider mall, CartProvider cart, bool isDesktop) {
    final essentials = mall.filteredProducts.take(4).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.replay_rounded, color: AppColors.primary, size: 20),
                  SizedBox(width: 6),
                  Text(
                    'مشترياتك المعتادة (اشترِ مجدداً في 5 ثوانٍ)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                  ),
                ],
              ),
              Text(
                'طلب سريع',
                style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: essentials.length,
            itemBuilder: (ctx, idx) {
              final item = essentials[idx];
              return Container(
                width: isDesktop ? 260 : 210,
                margin: const EdgeInsetsDirectional.only(end: 10),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4),
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: item.firstImage,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.nameAr,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${item.price.toStringAsFixed(2)} د.إ',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_shopping_cart, size: 18, color: AppColors.primary),
                      onPressed: () {
                        cart.addToCart(item);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✓ أضيفت ${item.nameAr} للسلة!'),
                            duration: const Duration(seconds: 1),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingCartBar(CartProvider cart) {
    return Container(
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
    );
  }
}
