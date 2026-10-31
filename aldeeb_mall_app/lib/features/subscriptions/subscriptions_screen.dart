import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/product_model.dart';
import '../../core/services/supabase_service.dart';
import '../../core/utils/responsive.dart';

class PrimePackage {
  final String id;
  final String nameAr;
  final String nameEn;
  final String badgeAr;
  final double monthlyPrice;
  final double annualPrice;
  final double pointsMultiplier;
  final double cashbackPercent;
  final bool freeExpressDelivery;
  final List<String> perks;
  final Color accentColor;
  final bool isPopular;

  const PrimePackage({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.badgeAr,
    required this.monthlyPrice,
    required this.annualPrice,
    required this.pointsMultiplier,
    required this.cashbackPercent,
    required this.freeExpressDelivery,
    required this.perks,
    required this.accentColor,
    this.isPopular = false,
  });
}

class GrocerySubscriptionItem {
  final String id;
  final ProductModel product;
  String frequency; // 'كل 3 أيام', 'أسبوعياً', 'كل أسبوعين'
  String nextDelivery;
  bool isPaused;

  GrocerySubscriptionItem({
    required this.id,
    required this.product,
    required this.frequency,
    required this.nextDelivery,
    this.isPaused = false,
  });
}

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isAnnualBilling = false;

  // Active user prime subscription simulation
  String? _activeSubscribedPlanId = 'prime-ultra'; // Default active VIP subscriber for rich preview
  bool _autoRenew = true;

  late List<GrocerySubscriptionItem> _grocerySubscriptions;

  final List<PrimePackage> _packages = const [
    PrimePackage(
      id: 'prime-plus',
      nameAr: 'باقة الديب بلس (Aldeeb Plus)',
      nameEn: 'Aldeeb Prime Plus',
      badgeAr: 'الباقة الاقتصادية',
      monthlyPrice: 29.00,
      annualPrice: 290.00,
      pointsMultiplier: 1.5,
      cashbackPercent: 2.5,
      freeExpressDelivery: true,
      perks: [
        'توصيل سريع مجاني للطلبات فوق 50 ل.س',
        'عروض أسبوعية خاصة للأعضاء فقط',
        'كاش باك 2.5% نقدي يضاف لمحفظتك',
        'نقاط ولاء مضاعفة 1.5x على كل فاتورة',
        'تنبيهات مسبقة قبل نفاد عروض الفلاش',
      ],
      accentColor: Color(0xFF2563EB),
      isPopular: false,
    ),
    PrimePackage(
      id: 'prime-ultra',
      nameAr: 'باقة الترا VIP (Prime Ultra)',
      nameEn: 'Aldeeb Prime Ultra VIP',
      badgeAr: 'الأكثر اختياراً وطلباً ⭐',
      monthlyPrice: 59.00,
      annualPrice: 590.00,
      pointsMultiplier: 2.5,
      cashbackPercent: 5.0,
      freeExpressDelivery: true,
      perks: [
        'توصيل فائق السرعة 15 دقيقة مجاني بدون أي حد أدنى نهائياً',
        'عروض وتخفيضات فلاش وسرية VIP يومية قبل الجمهور',
        'بوكس هدايا وعينات منتجات متميزة مجانية شهرياً',
        'نقاط ولاء مضاعفة 2.5x على كافة أقسام الهايبرماركت',
        'كاش باك 5.0% نقدي فوري بعد استلام كل طلب',
        'أولوية قصوى وتجهيز فوري مع خط ساخن مخصص',
      ],
      accentColor: Color(0xFFD97706),
      isPopular: true,
    ),
    PrimePackage(
      id: 'prime-royal',
      nameAr: 'الباقة الملكية العائلية (Royal Crown)',
      nameEn: 'Aldeeb Royal Crown Family',
      badgeAr: 'الفخامة الملكية المطلقة 👑',
      monthlyPrice: 99.00,
      annualPrice: 990.00,
      pointsMultiplier: 3.0,
      cashbackPercent: 8.0,
      freeExpressDelivery: true,
      perks: [
        'مشاركة الاشتراك مع 4 حسابات عائلية في نفس المنزل',
        'توصيل فوري مجاني 24/7 حتى في أوقات الذروة والأعياد',
        'كاش باك 8.0% مباشر مع كل طلب يتجاوز 100 ل.س',
        'نقاط ولاء ثلاثية 3x (كل 100 ل.س تمنح 300 نقطة)',
        'بوكس شهري من المخبوزات والحلويات الفرنسية الفاخرة مجاناً',
        'استبدال فوري أو استرجاع مضمون بدون أي أسئلة',
        'مساعد مشتريات شخصي وحجز مسبق للطلبيات الضخمة',
      ],
      accentColor: Color(0xFF7C3AED),
      isPopular: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final p = SupabaseService.defaultProducts;
    _grocerySubscriptions = [
      GrocerySubscriptionItem(
        id: 'sub-1',
        product: p.length > 3 ? p[3] : p[0], // Almarai Milk
        frequency: 'كل 3 أيام',
        nextDelivery: 'غداً صباحاً (7:00 ص)',
        isPaused: false,
      ),
      GrocerySubscriptionItem(
        id: 'sub-2',
        product: p[0], // Cavendish Bananas
        frequency: 'أسبوعياً (كل سبت)',
        nextDelivery: 'السبت القادم',
        isPaused: false,
      ),
      GrocerySubscriptionItem(
        id: 'sub-3',
        product: p.length > 2 ? p[2] : p[0], // Vine Tomatoes
        frequency: 'كل أسبوعين',
        nextDelivery: '5 نوفمبر 2026',
        isPaused: true,
      ),
    ];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleGroceryPause(String subId) {
    setState(() {
      final sub = _grocerySubscriptions.firstWhere((s) => s.id == subId, orElse: () => _grocerySubscriptions.first);
      sub.isPaused = !sub.isPaused;
    });
  }

  void _changeGroceryFrequency(String subId, String newFreq) {
    setState(() {
      final sub = _grocerySubscriptions.firstWhere((s) => s.id == subId, orElse: () => _grocerySubscriptions.first);
      sub.frequency = newFreq;
    });
  }

  void _subscribeToPlan(PrimePackage package) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.workspace_premium_rounded, color: package.accentColor, size: 28),
            const SizedBox(width: 8),
            Text('تأكيد الاشتراك في ${package.nameAr}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'أنت على وشك الانضمام إلى باقة ${_isAnnualBilling ? "السنوية" : "الشهرية"} بقيمة ${_isAnnualBilling ? package.annualPrice : package.monthlyPrice} ل.س.',
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.freshGreenLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.bolt_rounded, color: AppColors.freshGreen, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'سيبدأ سريان التوصيل المجاني والعروض المضاعفة والكاش باك فوراً!',
                      style: TextStyle(color: AppColors.freshGreen, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _activeSubscribedPlanId = package.id;
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✓ مبروك! تم تفعيل ${package.nameAr} بنجاح. استمتع بمميزات VIP المطلقة!'),
                  backgroundColor: AppColors.freshGreen,
                  duration: const Duration(seconds: 4),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: package.accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('تأكيد والاشتراك الفوري', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('باقات اشتراكات الديب برايم & التموين'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: AppColors.accent,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(
              icon: Icon(Icons.workspace_premium_rounded, size: 20),
              text: 'باقات برايم VIP الشهرية',
            ),
            Tab(
              icon: Icon(Icons.autorenew_rounded, size: 20),
              text: 'اشتراكات المؤن المتكررة',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Prime VIP Subscription Packages
          _buildPrimePackagesTab(),

          // Tab 2: Subscribe & Save Groceries
          _buildGrocerySubscriptionsTab(),
        ],
      ),
    );
  }

  // ---------------- Tab 1: Prime Packages ----------------
  Widget _buildPrimePackagesTab() {
    final activePackage = _packages.firstWhere(
      (p) => p.id == _activeSubscribedPlanId,
      orElse: () => _packages[1],
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: MaxWidthContainer(
        maxWidth: 960,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active Subscription Hero Card (if subscribed)
            if (_activeSubscribedPlanId != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF0F172A),
                      activePackage.accentColor.withValues(alpha: 0.8),
                      const Color(0xFF0F172A),
                    ],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: activePackage.accentColor.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.verified_rounded, color: AppColors.accent, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              'اشتراكك النشط: ${activePackage.nameAr}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'نشط ويتجدد تلقائياً',
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 10, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('إجمالي التوفير حتى اليوم', style: TextStyle(color: Colors.white70, fontSize: 11)),
                            Text('485.50 ل.س', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('التوصيل السريع المجاني القادم', style: TextStyle(color: Colors.white70, fontSize: 11)),
                            Text('غير محدود (15 دقيقة)', style: TextStyle(color: AppColors.accent, fontSize: 14, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            setState(() => _autoRenew = !_autoRenew);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(_autoRenew ? 'تم تفعيل التجديد التلقائي' : 'تم إيقاف التجديد التلقائي'),
                              ),
                            );
                          },
                          icon: Icon(_autoRenew ? Icons.check_circle_rounded : Icons.pause_circle_rounded, color: Colors.white, size: 16),
                          label: Text(
                            _autoRenew ? 'التجديد التلقائي مفعل' : 'موقف مؤقتاً',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setState(() => _activeSubscribedPlanId = null);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تم إلغاء الاشتراك بنجاح')),
                            );
                          },
                          child: const Text('إلغاء الاشتراك', style: TextStyle(color: Colors.white60, fontSize: 11)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Billing Cycle Switcher (Monthly vs Annual)
            Center(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => setState(() => _isAnnualBilling = false),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: !_isAnnualBilling ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'فوترة شهرية',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: !_isAnnualBilling ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => setState(() => _isAnnualBilling = true),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: _isAnnualBilling ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'فوترة سنوية',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _isAnnualBilling ? Colors.white : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'وفر شهرين مجاناً',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Packages Cards List / Grid
            ..._packages.map((pkg) {
              final isCurrentActive = _activeSubscribedPlanId == pkg.id;
              final displayPrice = _isAnnualBilling ? (pkg.annualPrice / 12) : pkg.monthlyPrice;

              return Container(
                margin: const EdgeInsets.only(bottom: 18),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: pkg.isPopular ? pkg.accentColor : AppColors.border,
                    width: pkg.isPopular ? 2 : 1,
                  ),
                  boxShadow: pkg.isPopular
                      ? [BoxShadow(color: pkg.accentColor.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 6))]
                      : AppColors.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: pkg.accentColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.workspace_premium_rounded, color: pkg.accentColor, size: 24),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(pkg.nameAr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                Text(pkg.nameEn, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: pkg.accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: pkg.accentColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            pkg.badgeAr,
                            style: TextStyle(color: pkg.accentColor, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Price Line
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          displayPrice.toStringAsFixed(2),
                          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: pkg.accentColor),
                        ),
                        const SizedBox(width: 4),
                        const Text('ل.س', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                        const SizedBox(width: 4),
                        const Text('/ شهرياً', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        if (_isAnnualBilling) ...[
                          const SizedBox(width: 10),
                          Text(
                            '(${pkg.annualPrice.toStringAsFixed(0)} ل.س تُدفع سنوياً)',
                            style: const TextStyle(fontSize: 11, color: AppColors.freshGreen, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Perks Grid
                    ...pkg.perks.map((perk) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.check_circle_rounded, color: pkg.accentColor, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(perk, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),

                    // Subscribe Action Button
                    ElevatedButton(
                      onPressed: isCurrentActive ? null : () => _subscribeToPlan(pkg),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: pkg.accentColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: isCurrentActive ? 0 : 2,
                      ),
                      child: Text(
                        isCurrentActive ? '✓ باقتك النشطة حالياً' : 'اشترك الآن في ${pkg.nameAr}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ---------------- Tab 2: Grocery Recurring Subscriptions ----------------
  Widget _buildGrocerySubscriptionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: MaxWidthContainer(
        maxWidth: 900,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF047857), Color(0xFF10B981)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppColors.cardShadow,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'وفر 10% دائم مع كل تكرار',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF047857),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'لا داعي للقلق من نفاد الحليب والخبز والخضار من منزلك أبداً!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'تصلك المواد الأساسية مبردة وطازجة في المواعيد التي تختارها مع توصيل مجاني أولوية وإلغاء أو تعديل في أي وقت.',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Active Subscriptions List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'اشتراكاتك النشطة الحالية:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                ),
                Text(
                  '${_grocerySubscriptions.where((s) => !s.isPaused).length} اشتراك نشط',
                  style: const TextStyle(fontSize: 12, color: AppColors.freshGreen, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _grocerySubscriptions.length,
              itemBuilder: (ctx, index) {
                final sub = _grocerySubscriptions[index];
                final discountedPrice = sub.product.price * 0.90; // 10% Subscribe & Save discount

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppColors.cardShadow,
                    border: Border.all(
                      color: sub.isPaused ? AppColors.border : AppColors.freshGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: sub.product.firstImage,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        sub.product.nameAr,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: sub.isPaused
                                            ? const Color(0xFFF1F5F9)
                                            : AppColors.freshGreen.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        sub.isPaused ? 'إيقاف مؤقت' : 'نشط ويتكرر',
                                        style: TextStyle(
                                          color: sub.isPaused ? AppColors.textMuted : AppColors.freshGreen,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      '${discountedPrice.toStringAsFixed(2)} ل.س',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15,
                                        color: AppColors.freshGreen,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${sub.product.price.toStringAsFixed(2)} ل.س',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textMuted,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      '(خصم اشتراك 10%)',
                                      style: TextStyle(color: AppColors.freshGreen, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'التوصيل القادم: ${sub.nextDelivery}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),

                      // Frequency and Actions Bar
                      Row(
                        children: [
                          const Text('التكرار: ', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          DropdownButton<String>(
                            value: sub.frequency,
                            underline: const SizedBox(),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            items: ['كل 3 أيام', 'أسبوعياً (كل سبت)', 'كل أسبوعين'].map((freq) {
                              return DropdownMenuItem(value: freq, child: Text(freq));
                            }).toList(),
                            onChanged: (newVal) {
                              if (newVal != null) _changeGroceryFrequency(sub.id, newVal);
                            },
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () => _toggleGroceryPause(sub.id),
                            icon: Icon(
                              sub.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                              size: 16,
                              color: sub.isPaused ? AppColors.freshGreen : const Color(0xFFD97706),
                            ),
                            label: Text(
                              sub.isPaused ? 'استئناف' : 'إيقاف مؤقت',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: sub.isPaused ? AppColors.freshGreen : const Color(0xFFD97706),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
