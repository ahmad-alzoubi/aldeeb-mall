import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/coupon_model.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/responsive.dart';
import '../subscriptions/subscriptions_screen.dart';

class RewardCouponItem {
  final String id;
  final String titleAr;
  final String descriptionAr;
  final String code;
  final int pointsCost;
  final double discountAmount;
  final double minOrderAmount;

  const RewardCouponItem({
    required this.id,
    required this.titleAr,
    required this.descriptionAr,
    required this.code,
    required this.pointsCost,
    required this.discountAmount,
    required this.minOrderAmount,
  });
}

class RewardProductItem {
  final String id;
  final String titleAr;
  final String titleEn;
  final String imageUrl;
  final String categoryAr;
  final int pointsCost;
  final int stockQuota;

  const RewardProductItem({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.imageUrl,
    required this.categoryAr,
    required this.pointsCost,
    required this.stockQuota,
  });
}

class LoyaltyScreen extends StatefulWidget {
  const LoyaltyScreen({super.key});

  @override
  State<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends State<LoyaltyScreen> with SingleTickerProviderStateMixin {
  int _totpCountdown = 30;
  Timer? _totpTimer;
  double _convertSliderValue = 100;
  late TabController _tabController;

  // Selected Tier Card Preview ('Silver', 'Gold VIP', 'Platinum Elite', 'Royal Crown')
  String _selectedCardTier = 'Gold VIP';

  // Claimed user coupons in session
  final List<String> _claimedCouponCodes = [];

  final List<RewardCouponItem> _rewardCoupons = const [
    RewardCouponItem(
      id: 'rc-1',
      titleAr: 'قسيمة خصم 15 ل.س فوري',
      descriptionAr: 'وفر 15 ل.س على أي طلب فوق 60 ل.س',
      code: 'REWARD15',
      pointsCost: 1200,
      discountAmount: 15.00,
      minOrderAmount: 60.00,
    ),
    RewardCouponItem(
      id: 'rc-2',
      titleAr: 'قسيمة خصم 30 ل.س كبرى',
      descriptionAr: 'وفر 30 ل.س على مشتريات الهايبرماركت فوق 120 ل.س',
      code: 'REWARD30',
      pointsCost: 2200,
      discountAmount: 30.00,
      minOrderAmount: 120.00,
    ),
    RewardCouponItem(
      id: 'rc-3',
      titleAr: 'قسيمة خصم 50 ل.س VIP النخبة',
      descriptionAr: 'وفر 50 ل.س على الطلبيات العائلية فوق 200 ل.س',
      code: 'REWARD50',
      pointsCost: 3500,
      discountAmount: 50.00,
      minOrderAmount: 200.00,
    ),
    RewardCouponItem(
      id: 'rc-4',
      titleAr: 'قسيمة توصيل فوري مجاني',
      descriptionAr: 'توصيل مجاني 15 دقيقة بدون أي حد أدنى لـ 3 طلبيات',
      code: 'FREESHIP',
      pointsCost: 500,
      discountAmount: 10.00,
      minOrderAmount: 0.00,
    ),
  ];

  final List<RewardProductItem> _rewardProducts = const [
    RewardProductItem(
      id: 'rp-1',
      titleAr: 'سلة فواكه طازجة عضوية مختارة (3 كجم)',
      titleEn: 'Organic Fresh Fruit Basket 3kg',
      imageUrl: 'https://images.unsplash.com/photo-1610832958506-aa56368176cf?auto=format&fit=crop&w=600&q=80',
      categoryAr: 'فواكه وخضار طازجة',
      pointsCost: 1100,
      stockQuota: 45,
    ),
    RewardProductItem(
      id: 'rp-2',
      titleAr: 'زيت زيتون فلسطيني بكر ممتاز 1 لتر',
      titleEn: 'Extra Virgin Cold-Pressed Olive Oil 1L',
      imageUrl: 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?auto=format&fit=crop&w=600&q=80',
      categoryAr: 'مؤن وتموين فاخر',
      pointsCost: 850,
      stockQuota: 60,
    ),
    RewardProductItem(
      id: 'rp-3',
      titleAr: 'بوكس شوكولاتة بلجيكية فاخرة محشوة 500غ',
      titleEn: 'Belgian Luxury Artisan Chocolates 500g',
      imageUrl: 'https://images.unsplash.com/photo-1549007994-cb92caebd54b?auto=format&fit=crop&w=600&q=80',
      categoryAr: 'حلويات وسكاكر',
      pointsCost: 950,
      stockQuota: 30,
    ),
    RewardProductItem(
      id: 'rp-4',
      titleAr: 'كرتونة مياه أروى معدنية نقية (24 × 500 مل)',
      titleEn: 'Arwa Mineral Water 24x500ml',
      imageUrl: 'https://images.unsplash.com/photo-1559839914-1b346d6d3764?auto=format&fit=crop&w=600&q=80',
      categoryAr: 'مشروبات ومياه',
      pointsCost: 350,
      stockQuota: 120,
    ),
    RewardProductItem(
      id: 'rp-5',
      titleAr: 'كعكة كراميل وفراولة طازجة من المخبز',
      titleEn: 'Artisan Strawberry Caramel Fresh Cake',
      imageUrl: 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?auto=format&fit=crop&w=600&q=80',
      categoryAr: 'المخبز والحلويات',
      pointsCost: 1400,
      stockQuota: 25,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _startTotpTimer();
  }

  void _startTotpTimer() {
    _totpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_totpCountdown > 1) {
            _totpCountdown--;
          } else {
            _totpCountdown = 30; // auto-refresh TOTP barcode
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _totpTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  // Redeem Coupon Action
  void _redeemCoupon(RewardCouponItem coupon, AuthService auth, CartProvider cart) {
    final userPoints = auth.currentUser?.loyaltyPoints ?? 0;
    if (userPoints < coupon.pointsCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ رصيدك ($userPoints نقطة) غير كافٍ لاستبدال هذا الكوبون (${coupon.pointsCost} نقطة). تسوق واكسب المزيد!'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    // Deduct points
    auth.deductLoyaltyPoints(coupon.pointsCost);
    final generatedCode = '${coupon.code}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    setState(() {
      _claimedCouponCodes.add(generatedCode);
    });

    // Show Confirmation Dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.freshGreen, size: 28),
            SizedBox(width: 8),
            Text('تم استبدال الكوبون بنجاح!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('تم خصم ${coupon.pointsCost} نقطة من رصيدك وحصلت على ${coupon.titleAr}.'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.secondaryLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    generatedCode,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.secondary, letterSpacing: 1.2),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, color: AppColors.secondary, size: 20),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: generatedCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم نسخ كود الكوبون إلى الحافظة!'), duration: Duration(seconds: 2)),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق'),
          ),
          ElevatedButton(
            onPressed: () {
              // Apply directly to cart
              final newCouponModel = CouponModel(
                id: coupon.id,
                code: generatedCode,
                discountType: 'fixed',
                discountValue: coupon.discountAmount,
                minOrderAmount: coupon.minOrderAmount,
              );
              cart.applyCouponDirectly(newCouponModel);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✓ تم تطبيق كود الخصم ($generatedCode) مباشرة في سلتك!'),
                  backgroundColor: AppColors.freshGreen,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('تطبيق فوري بالسلة', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Redeem Free Product Action
  void _redeemProduct(RewardProductItem product, AuthService auth, CartProvider cart) {
    final userPoints = auth.currentUser?.loyaltyPoints ?? 0;
    if (userPoints < product.pointsCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ رصيد نقاطك ($userPoints نقطة) لا يكفي للحصول على هذا المنتج الهدية (${product.pointsCost} نقطة).'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    // Deduct points
    auth.deductLoyaltyPoints(product.pointsCost);

    // Add free reward item to cart
    cart.addFreeRewardProduct(
      id: product.id,
      nameAr: product.titleAr,
      nameEn: product.titleEn,
      imageUrl: product.imageUrl,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.celebration_rounded, color: Colors.white, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'مبروك! تم استبدال ${product.pointsCost} نقطة وإضافة (${product.titleAr}) مجاناً بـ 0.00 ل.س لسلتك!',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.freshGreen,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final cart = Provider.of<CartProvider>(context);
    final user = auth.currentUser;
    final points = user?.loyaltyPoints ?? 480;

    // Actual user tier
    final actualTier = points >= 3000
        ? 'Royal Crown'
        : points >= 1000
            ? 'Platinum Elite'
            : points >= 300
                ? 'Gold VIP'
                : 'Silver';

    final pointsToNextTier = points >= 3000
        ? 0
        : points >= 1000
            ? (3000 - points)
            : points >= 300
                ? (1000 - points)
                : (300 - points);

    final nextTierName = points >= 1000
        ? 'التاج الملكي Royal Crown'
        : points >= 300
            ? 'البلاتينية النخبة'
            : 'الذهبية VIP';

    final progressPercent = points >= 3000 ? 1.0 : (points / 3000.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('نادي مكافآت ونقاط الديب (VIP Club)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.workspace_premium_rounded, color: AppColors.accent),
            tooltip: 'باقات الاشتراكات الشهرية',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionsScreen()));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: MaxWidthContainer(
          maxWidth: 960,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // VIP Prime Subscriptions Highlight Banner
              InkWell(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionsScreen()));
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F172A)],
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'اشترك في باقات الديب برايم الشهرية (Aldeeb Prime)',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'توصيل فوري 15 دقيقة مجاني بدون حد أدنى + عروض خاصة ونقاط مضاعفة 2.5x',
                              style: TextStyle(color: Colors.white70, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.amber, size: 14),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tier Cards Preview Switcher Chips
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'بطاقات عضوية الديب الرقمية:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                  ),
                  Wrap(
                    spacing: 6,
                    children: ['Silver', 'Gold VIP', 'Platinum Elite', 'Royal Crown'].map((t) {
                      final isSelected = _selectedCardTier == t;
                      return ChoiceChip(
                        label: Text(
                          t == 'Royal Crown' ? '👑 الملكية' : t == 'Platinum Elite' ? '💎 بلاتين' : t == 'Gold VIP' ? '⭐ ذهبية' : 'فضية',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: t == 'Royal Crown'
                            ? const Color(0xFF7C3AED)
                            : t == 'Platinum Elite'
                                ? const Color(0xFF0F172A)
                                : t == 'Gold VIP'
                                    ? const Color(0xFFB45309)
                                    : AppColors.primary,
                        backgroundColor: Colors.white,
                        onSelected: (val) {
                          if (val) setState(() => _selectedCardTier = t);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 1. Digital Metallic Loyalty Card
              _buildDigitalMembershipCard(
                tier: _selectedCardTier,
                actualUserTier: actualTier,
                points: points,
                user: user,
              ),
              const SizedBox(height: 16),

              // 2. VIP Tier Progress Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppColors.cardShadow,
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.military_tech_rounded, color: AppColors.accent, size: 20),
                            const SizedBox(width: 6),
                            Text(
                              'مستواك الحالي: $actualTier',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                        if (pointsToNextTier > 0)
                          Text(
                            'متبقي $pointsToNextTier نقطة للترقية إلى $nextTierName',
                            style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
                          )
                        else
                          const Text(
                            '👑 وصلت إلى الفئة الملكية العليا!',
                            style: TextStyle(fontSize: 11, color: AppColors.freshGreen, fontWeight: FontWeight.bold),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progressPercent,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFE2E8F0),
                        color: actualTier == 'Royal Crown'
                            ? const Color(0xFF7C3AED)
                            : actualTier == 'Platinum Elite'
                                ? const Color(0xFF0F172A)
                                : actualTier == 'Gold VIP'
                                    ? const Color(0xFFD97706)
                                    : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 3. Three Core Redemption Modes (Tabs)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Column(
                  children: [
                    TabBar(
                      controller: _tabController,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textMuted,
                      indicatorColor: AppColors.accent,
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      tabs: const [
                        Tab(
                          icon: Icon(Icons.confirmation_number_outlined, size: 20),
                          text: 'كوبونات الخصم',
                        ),
                        Tab(
                          icon: Icon(Icons.card_giftcard_rounded, size: 20),
                          text: 'منتجات مجانية',
                        ),
                        Tab(
                          icon: Icon(Icons.calculate_outlined, size: 20),
                          text: 'محول الفاتورة',
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 440,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Tab 1: Reward Coupons
                          _buildRewardCouponsTab(auth, cart),

                          // Tab 2: Free Reward Products
                          _buildRewardProductsTab(auth, cart),

                          // Tab 3: Points to Invoice Calculator
                          _buildPointsCalculatorTab(points, auth, cart),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 4. VIP Perks & Privileges
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppColors.cardShadow,
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('مزايا عضويتك الحصرية في الديب مول', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 14),
                    _perkRow(Icons.bolt_rounded, 'توصيل فائق السرعة مجاني دائم', 'توصيل خلال 15 دقيقة مجاناً على جميع طلبيات السوبرماركت.'),
                    const Divider(height: 18),
                    _perkRow(Icons.percent_rounded, 'كاش باك نقدي حتى 8% في المحفظة', 'استرداد نقدي مباشر يضاف لمحفظتك مع كل طلب.'),
                    const Divider(height: 18),
                    _perkRow(Icons.stars_rounded, 'نقاط ولاء مضاعفة تصل إلى 3X', 'اكسب نقاطاً ثلاثية عند التسوق من الأقسام الطازجة واللحوم والمؤن.'),
                    const Divider(height: 18),
                    _perkRow(Icons.support_agent_rounded, 'أولوية الفرز والكونسيرج الشخصي', 'تجهيز سلتك بأعلى أولوية ودعم مخصص VIP على مدار الساعة.'),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // Digital Membership Card Widget
  Widget _buildDigitalMembershipCard({
    required String tier,
    required String actualUserTier,
    required int points,
    required dynamic user,
  }) {
    List<Color> gradientColors;
    Color shadowColor;

    switch (tier) {
      case 'Royal Crown':
        gradientColors = [const Color(0xFF1E1B4B), const Color(0xFF4C1D95), const Color(0xFF1E1B4B)];
        shadowColor = const Color(0xFF7C3AED);
        break;
      case 'Platinum Elite':
        gradientColors = [const Color(0xFF0F172A), const Color(0xFF334155), const Color(0xFF1E293B)];
        shadowColor = const Color(0xFF0F172A);
        break;
      case 'Gold VIP':
        gradientColors = [const Color(0xFF78350F), const Color(0xFFB45309), const Color(0xFFD97706)];
        shadowColor = const Color(0xFFB45309);
        break;
      case 'Silver':
      default:
        gradientColors = [AppColors.primaryDark, AppColors.primary, const Color(0xFF1E3A8A)];
        shadowColor = AppColors.primary;
        break;
    }

    return Container(
      height: 235,
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Card Top Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      tier == 'Royal Crown' ? Icons.workspace_premium_rounded : Icons.stars_rounded,
                      color: AppColors.accent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'بطاقة عضوية الديب $tier',
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'برنامج مكافآت ونقاط الهايبرماركت الفوري',
                        style: TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  actualUserTier == tier ? 'فئتك النشطة' : 'معاينة الفئة',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),

          // Points Balance Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('رصيد نقاط الولاء المتاحة', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$points',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text('نقطة', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'تعادل ${(points * 0.01).toStringAsFixed(2)} ل.س رصيد فوري',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // In-Store Cashier Barcode with 30s TOTP Countdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'كود الكاشير: DEEB-${user?.id.substring(0, 4).toUpperCase() ?? "7789"}-$_totpCountdown',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        value: _totpCountdown / 30.0,
                        strokeWidth: 2,
                        color: AppColors.primary,
                        backgroundColor: const Color(0xFFE2E8F0),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$_totpCountdown ث',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Tab 1: Reward Coupons
  Widget _buildRewardCouponsTab(AuthService auth, CartProvider cart) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _rewardCoupons.length,
      itemBuilder: (ctx, index) {
        final coupon = _rewardCoupons[index];
        final canAfford = (auth.currentUser?.loyaltyPoints ?? 0) >= coupon.pointsCost;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: canAfford ? AppColors.secondary.withValues(alpha: 0.4) : AppColors.border),
            boxShadow: AppColors.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.secondaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.confirmation_number_rounded, color: AppColors.secondary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          coupon.titleAr,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accentLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${coupon.pointsCost} نقطة',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      coupon.descriptionAr,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _redeemCoupon(coupon, auth, cart),
                style: ElevatedButton.styleFrom(
                  backgroundColor: canAfford ? AppColors.secondary : Colors.grey.shade300,
                  foregroundColor: canAfford ? Colors.white : Colors.grey.shade600,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: canAfford ? 1 : 0,
                ),
                child: Text(
                  canAfford ? 'استبدال' : 'نقاط غير كافية',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Tab 2: Free Reward Products
  Widget _buildRewardProductsTab(AuthService auth, CartProvider cart) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _rewardProducts.length,
      itemBuilder: (ctx, index) {
        final prod = _rewardProducts[index];
        final canAfford = (auth.currentUser?.loyaltyPoints ?? 0) >= prod.pointsCost;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: canAfford ? AppColors.freshGreen.withValues(alpha: 0.4) : AppColors.border),
            boxShadow: AppColors.cardShadow,
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: prod.imageUrl,
                  width: 58,
                  height: 58,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prod.titleAr,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      prod.categoryAr,
                      style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${prod.pointsCost} نقطة',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.freshGreen),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'هدية مجانية (0 ل.س)',
                          style: TextStyle(fontSize: 10, color: Colors.amber.shade800, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _redeemProduct(prod, auth, cart),
                style: ElevatedButton.styleFrom(
                  backgroundColor: canAfford ? AppColors.freshGreen : Colors.grey.shade300,
                  foregroundColor: canAfford ? Colors.white : Colors.grey.shade600,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: canAfford ? 1 : 0,
                ),
                child: Text(
                  canAfford ? 'احصل مجاناً' : 'نقاط ناقصة',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Tab 3: Points to Invoice Calculator
  Widget _buildPointsCalculatorTab(int points, AuthService auth, CartProvider cart) {
    final maxCash = (points * 0.01);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.currency_exchange_rounded, color: AppColors.freshGreen, size: 22),
              SizedBox(width: 8),
              Text(
                'استخدام النقاط المباشر في الفاتورة والسلة',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'يمكنك تحويل أي كمية من نقاطك لخصم فوري مباشر من إجمالي فاتورة مشترياتك في السلة وصفحة الدفع.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.freshGreenLight.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.freshGreen.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('النقاط المراد استبدالها: ${_convertSliderValue.toInt()} نقطة',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    Text(
                      '= ${(_convertSliderValue * 0.01).toStringAsFixed(2)} ل.س خصم',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.freshGreen),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Slider(
                  value: _convertSliderValue.clamp(50.0, points > 50 ? points.toDouble() : 100.0),
                  min: 50,
                  max: points > 50 ? points.toDouble() : 100,
                  divisions: 10,
                  activeColor: AppColors.freshGreen,
                  onChanged: (val) {
                    setState(() => _convertSliderValue = val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              cart.setLoyaltyPointsUsed(_convertSliderValue.toInt(), points);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '✓ تم تفعيل خصم ${_convertSliderValue.toInt()} نقطة (= ${(_convertSliderValue * 0.01).toStringAsFixed(2)} ل.س) على فاتورتك في السلة!',
                  ),
                  backgroundColor: AppColors.freshGreen,
                ),
              );
            },
            icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 18),
            label: const Text('تطبيق الخصم على الفاتورة في السلة الآن', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.freshGreen,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'أقصى رصيد نقدي متاح لنقاطك حالياً هو ${maxCash.toStringAsFixed(2)} ل.س.',
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _perkRow(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }
}
