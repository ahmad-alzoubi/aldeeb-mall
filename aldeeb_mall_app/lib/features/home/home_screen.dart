import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/banner_model.dart';
import '../../core/models/product_model.dart';
import '../../core/utils/banner_navigator.dart';
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
import '../address/address_book_screen.dart';
import '../navigation/in_store_navigator_screen.dart';
import '../pickup/curbside_pickup_screen.dart';
import '../grocery_list/grocery_list_screen.dart';
import '../sustainability/eco_tracker_modal.dart';
import '../zero_waste/zero_waste_screen.dart';
import '../live_shopping/live_shopping_screen.dart';
import '../smart_cart_iot/smart_cart_iot_screen.dart';
import '../meal_kits/meal_kits_screen.dart';
import '../price_match/price_match_modal.dart';
import '../pharmacy/pharmacy_screen.dart';
import '../kitchen_wand/kitchen_wand_screen.dart';
import '../lockers/smart_locker_pickup_screen.dart';
import '../drone_delivery/drone_tracking_screen.dart';
import '../ai_nutritionist/ai_nutritionist_screen.dart';
import '../butcher/butcher_customizer_screen.dart';
import '../category/department_screen.dart';
import '../category/categories_screen.dart';
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
  String? _selectedSubcategory;
  String _activeSortFilter = 'all';

  static final Map<String, List<String>> _categorySubcategories = {
    'c1': ['الكل', 'ورقيات خضراء 🌱', 'فواكه موسمية 🍎', 'حمضيات وتفاح 🍊', 'طماطم وخيار 🍅', 'عضوي معتمد 🌿'],
    'c2': ['الكل', 'حليب طازج 🥛', 'أجبان بيضاء 🧀', 'أجبان صفراء 🧀', 'زبادي ولبنة 🥣', 'بيض مزارع 🥚'],
    'c3': ['الكل', 'عجل بلدي طازج 🥩', 'خروف ونعيمي 🐑', 'دواجن مبردة 🍗', 'أسماك وبحريات 🐟', 'تتبيل وشواء 🍢'],
    'c4': ['الكل', 'كرواسان ومعجنات 🥐', 'خبز طازج 🥖', 'فطائر ومناقيش 🥧', 'حلويات وكيك 🍰', 'توست وشابورة 🍞'],
    'c5': ['الكل', 'عصائر طازجة 🍹', 'مياه معدنية 💧', 'مشروبات غازية 🥤', 'شاي وقهوة ☕', 'مشروبات طاقة ⚡'],
    'c6': ['الكل', 'غسيل الملابس 🧺', 'نظافة الصحون 🧼', 'مطهرات ومعقمات 🧴', 'مناديل وورقيات 🧻', 'معطرات جو 🌸'],
    'c_ready_meals': ['الكل', 'وجبات ساخنة 🍲', 'سوشي وسلطات 🥗', 'ساندويشات طازجة 🥪', 'مقبلات وسناكس 🥟'],
    'c_chilled': ['الكل', 'أجبان معتقة 🧀', 'مرتديلا ولحوم باردة 🥓', 'عجائن مبردة 🥟', 'زبدة وقشطة 🧈'],
    'c_supermarket': ['الكل', 'أرز وحبوب 🌾', 'زيوت وسمن 🫒', 'معلبات وبقوليات 🥫', 'توابل وبهارات 🧂', 'باستا وصوصات 🍝'],
    'c_frozen': ['الكل', 'آيس كريم ومثلجات 🍦', 'خضار مجمدة 🥦', 'بطاطس مقلية 🍟', 'بيتزا ومعجنات مجمدة 🍕'],
    'c_organic': ['الكل', 'خالي من الجلوتين 🌾', 'كيتو دايت 🥑', 'عضوي معتمد 🌿', 'بذور وسوبر فود 🌰'],
    'c_pets': ['الكل', 'طعام قطط 🐱', 'طعام كلاب 🐶', 'رمل ومستلزمات نظافة 🧼', 'ألعاب ومكافآت 🎾'],
    'c_beauty': ['الكل', 'عناية بالبشرة 🧴', 'عناية بالشعر 💇', 'عطور وبخور 🌸', 'عناية بالفم 🪥'],
    'c_cars': ['الكل', 'معطرات سيارة 🌲', 'منظفات وتلميع ✨', 'شواحن وحوامل هاتف 🔌', 'مستلزمات حماية 🛡️'],
    'c_baby': ['الكل', 'حفاضات ومناديل 👶', 'حليب وأغذية رضع 🍼', 'شامبو وعناية رقيقة 🛁', 'ألعاب تعليمية 🧸'],
    'c_clothing': ['الكل', 'ملابس رجالية 👔', 'ملابس نسائية 👗', 'ملابس أطفال 🎽', 'ملابس قطنية ومنزلية 👕'],
    'c_accessories': ['الكل', 'ساعات يد ⌚', 'نظارات شمسية 🕶️', 'محافظ وحقائب 👜', 'إكسسوارات ومجوهرات 💍'],
    'c_home_garden': ['الكل', 'أواني ومطبخ 🍳', 'ديكور وإضاءة 💡', 'نباتات وحدائق 🪴', 'مفارش وأغطية 🛏️'],
    'c_paper': ['الكل', 'محارم وجه 🧻', 'مناديل مطبخ وحمام 🧻', 'قصدير ونايلون تغليف 🍱', 'أكياس صديقة للبيئة 🛍️'],
    'c_sports': ['الكل', 'أثقال ودمبلز 🏋️', 'سجاد يوغا ولياقة 🧘', 'حبال ومشدات مقاومة 🪢', 'مطارات رياضية 🥤'],
    'c_stationery': ['الكل', 'دفاتر ومفكرات 📓', 'أقلام وألوان ✒️', 'ملفات ومنظمات 📁', 'أوراق وحبر طباعة 📄'],
    'c_toys': ['الكل', 'ليغو وتركيب 🧱', 'ألعاب ذكاء وتحدي ♟️', 'دمى وشخصيات 🧸', 'ألعاب خارجية وسكوتر 🛴'],
    'c_essentials': ['الكل', 'سماعات وشواحن 🎧', 'بطاريات ومحولات 🔋', 'مستلزمات منزلية ذكية 🔌'],
  };

  static final Map<String, Map<String, String>> _categoryMeta = {
    'c1': {'badge': 'قطاف اليوم 🌿', 'tagline': 'طازج من المزارع مباشرة', 'color': '0xFF16A34A'},
    'c2': {'badge': 'يومي وطبيعي 🥛', 'tagline': 'ألبان، أجبان وبيض طازج', 'color': '0xFF2563EB'},
    'c3': {'badge': 'ذبح بلدي حلال 🥩', 'tagline': 'لحوم، دواجن وبحريات طازجة', 'color': '0xFFDC2626'},
    'c4': {'badge': 'طازج من الفرن 🥐', 'tagline': 'مخبوزات ومعجنات ساخنة', 'color': '0xFFD97706'},
    'c5': {'badge': 'انتعاش وبرودة 💧', 'tagline': 'مياه، عصائر ومشروبات', 'color': '0xFF0284C7'},
    'c6': {'badge': 'نظافة وتوفير ✨', 'tagline': 'منظفات وعناية شاملة للمنزل', 'color': '0xFF7C3AED'},
    'c_ready_meals': {'badge': 'وجبات شيف 🍲', 'tagline': 'جاهزة للأكل والتسخين الفوري', 'color': '0xFFEA580C'},
    'c_chilled': {'badge': 'سلسلة تبريد 4°C ❄️', 'tagline': 'أطعمة مبردة ومقطوعات فاخرة', 'color': '0xFF0891B2'},
    'c_supermarket': {'badge': 'مؤونة التوفير 🛒', 'tagline': 'كل احتياجات البيت الأساسية', 'color': '0xFF4F46E5'},
    'c_frozen': {'badge': 'تجميد فائق 🧊', 'tagline': 'آيس كريم وأطعمة مجمدة بأمان', 'color': '0xFF0284C7'},
    'c_organic': {'badge': 'عضوي 100% 🌿', 'tagline': 'صحة ونقاء خالي من المواد الحافظة', 'color': '0xFF059669'},
    'c_pets': {'badge': 'رعاية أليفك 🐾', 'tagline': 'أفضل أطعمة ومستلزمات الحيوانات', 'color': '0xFFD97706'},
    'c_beauty': {'badge': 'جمال وعناية 🧴', 'tagline': 'أرقى ماركات العناية الأصلية', 'color': '0xFFDB2777'},
    'c_cars': {'badge': 'عناية بالمركبة 🚗', 'tagline': 'إكسسوارات وعطور وصيانة فورية', 'color': '0xFF374151'},
    'c_baby': {'badge': 'عناية فائقة 👶', 'tagline': 'حماية وأمان لأطفالك الصغار', 'color': '0xFFF59E0B'},
    'c_clothing': {'badge': 'أناقة يومية 👕', 'tagline': 'ملابس قطنية وعصرية للجميع', 'color': '0xFF6366F1'},
    'c_accessories': {'badge': 'لمسات فاخرة ✨', 'tagline': 'ساعات، نظارات وحقائب أنيقة', 'color': '0xFF8B5CF6'},
    'c_home_garden': {'badge': 'راحة منزلك 🏡', 'tagline': 'مستلزمات المنزل والحديقة', 'color': '0xFF10B981'},
    'c_paper': {'badge': 'نعومة وتوفير 🧻', 'tagline': 'منتجات ورقية واستخدام يومي', 'color': '0xFF64748B'},
    'c_sports': {'badge': 'لياقة ونشاط 🏋️', 'tagline': 'معدات وأدوات التمارين المنزلية', 'color': '0xFFE11D48'},
    'c_stationery': {'badge': 'إبداع ودراسة 📚', 'tagline': 'أدوات مكتبية ومدرسية متكاملة', 'color': '0xFF3B82F6'},
    'c_toys': {'badge': 'مرح عائلي 🎮', 'tagline': 'ألعاب تنمية الذكاء والترفيه', 'color': '0xFFF97316'},
    'c_essentials': {'badge': 'تقنية يومية 🔌', 'tagline': 'إلكترونيات وأساسيات لا غنى عنها', 'color': '0xFF1E293B'},
    'c_dates': {'badge': 'سكري ومجدول 🌴', 'tagline': 'أجود تمور المملكة وفواكه مجففة', 'color': '0xFF92400E'},
    'c_appliances': {'badge': 'ضمان معتمد ⚡', 'tagline': 'أجهزة منزلية وقلايات ذكية', 'color': '0xFF0284C7'},
  };

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
        final list = mall.heroBanners;
        if (list.isNotEmpty) {
          final next = (_currentBannerIndex + 1) % list.length;
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

              // 2. Hero Promotional Carousel Section
              SliverToBoxAdapter(
                child: MaxWidthContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildHeroSection(mall, isDesktop),
                ),
              ),

              // 3. Quick Services & Feature Hub (Single horizontal luxury row)
              SliverToBoxAdapter(
                child: MaxWidthContainer(
                  child: _buildQuickServicesHub(context),
                ),
              ),

              // 4. Major Visual Departments Showcase & Interactive Category Explorer
              SliverToBoxAdapter(
                child: MaxWidthContainer(
                  child: _buildDepartmentsShowcase(mall, isDesktop),
                ),
              ),

              // If a category is selected, focus on its products
              if (mall.selectedCategoryId != null) ...[
                SliverToBoxAdapter(
                  child: MaxWidthContainer(
                    child: _buildAllProductsSection(mall, context, isDesktop),
                  ),
                ),
              ] else ...[
                // Themed Shoppable Shelves for the Hypermarket Experience:
                // 5. Farm Fresh Daily Produce Shelf (خضار وفواكه طازجة)
                SliverToBoxAdapter(
                  child: MaxWidthContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildFarmFreshShelf(mall, isDesktop),
                  ),
                ),

                // 6. Fresh Halal Butcher & Fishery Shelf (لحوم ودواجن وأسماك)
                SliverToBoxAdapter(
                  child: MaxWidthContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildButcherShelf(mall, isDesktop),
                  ),
                ),

                // 7. Secondary Middle Promotional Banner 1 (إعلان فاصل 1)
                SliverToBoxAdapter(
                  child: MaxWidthContainer(
                    child: _buildSecondaryBanner(mall, 0, isDesktop),
                  ),
                ),

                // 8. Weekly Deals Shelf (عروض الأسبوع التوفيرية الكبرى)
                SliverToBoxAdapter(
                  child: MaxWidthContainer(
                    child: _buildWeeklyDealsShelf(mall, isDesktop),
                  ),
                ),

                // 9. Can't-Miss Flash Deals (صفقات لا تفوت)
                SliverToBoxAdapter(
                  child: MaxWidthContainer(
                    child: _buildCantMissShelf(mall, isDesktop),
                  ),
                ),

                // 10. Secondary Middle Promotional Banner 2 (إعلان فاصل 2)
                SliverToBoxAdapter(
                  child: MaxWidthContainer(
                    child: _buildSecondaryBanner(mall, 1, isDesktop),
                  ),
                ),

                // 11. New Arrivals Shelf (منتجات جديدة وصلت حديثاً للمول)
                SliverToBoxAdapter(
                  child: MaxWidthContainer(
                    child: _buildNewArrivalsShelf(mall, isDesktop),
                  ),
                ),

                // 12. Mega Savings & Discounts Shelf (خصومات كبرى وتوفير)
                SliverToBoxAdapter(
                  child: MaxWidthContainer(
                    child: _buildMegaSavingsShelf(mall, isDesktop),
                  ),
                ),

                // 13. Quick Reorder / Buy Again Essentials
                SliverToBoxAdapter(
                  child: MaxWidthContainer(
                    child: _buildBuyAgainSection(mall, cart, isDesktop),
                  ),
                ),

                // 14. All Hypermarket Products Grid with Filter Tabs & Dietary Filter
                SliverToBoxAdapter(
                  child: MaxWidthContainer(
                    child: _buildAllProductsSection(mall, context, isDesktop),
                  ),
                ),
              ],
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
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddressBookScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
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
                              'برج فيوز B، وسط دبي ▼',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 18),
                      ],
                    ),
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
                            decoration: InputDecoration(
                              hintText: 'ابحث بين أكثر من ${mall.catalogCountText} منتج في الديب مول...',
                              hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
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
                          icon: const Icon(Icons.map_outlined, color: AppColors.primary, size: 22),
                          tooltip: 'مرشد ممرات الفرع (In-Store Navigator)',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const InStoreNavigatorScreen()),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.playlist_add_check_rounded, color: AppColors.primary, size: 22),
                          tooltip: 'مخطط المقاضي الذكي (Smart Grocery Planner)',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const GroceryListScreen()),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.eco_rounded, color: AppColors.freshGreen, size: 22),
                          tooltip: 'مبادرة الأثر البيئي والخضراء (Eco Tracker)',
                          onPressed: () => EcoTrackerModal.show(context),
                        ),
                        IconButton(
                          icon: const Icon(Icons.live_tv_rounded, color: Colors.redAccent, size: 22),
                          tooltip: 'الديب لايف (Live Video Shopping)',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const LiveShoppingScreen()),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.shopping_cart_checkout_rounded, color: Colors.teal, size: 22),
                          tooltip: 'عربة الديب الذكية (Smart Dash Cart)',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SmartCartIoTScreen()),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.restaurant_menu_rounded, color: Colors.amber, size: 22),
                          tooltip: 'بوكسات وجبات الطهي السريع (Chef Meal Kits)',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const MealKitsScreen()),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.verified_user_rounded, color: Colors.blueAccent, size: 22),
                          tooltip: 'ضمان أرخص سعر ومطابقة الأسعار (Price Match)',
                          onPressed: () => PriceMatchModal.show(context),
                        ),
                        IconButton(
                          icon: const Icon(Icons.local_pharmacy_rounded, color: Color(0xFF34D399), size: 22),
                          tooltip: 'صيدلية الديب وفاحص SFDA',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const PharmacyScreen()),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.microwave_rounded, color: Colors.amber, size: 22),
                          tooltip: 'عصا المطبخ الذكية والمؤونة (Kitchen Wand)',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const KitchenWandScreen()),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.meeting_room_rounded, color: Colors.cyanAccent, size: 22),
                          tooltip: 'خزائن الاستلام الذكية 24/7 (Smart Lockers)',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SmartLockerPickupScreen()),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.flight_takeoff_rounded, color: Colors.cyanAccent, size: 22),
                          tooltip: 'التوصيل الجوي بدرونز الديب 10 دقائق (Drone Delivery)',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const DroneTrackingScreen()),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.psychology_rounded, color: Color(0xFF34D399), size: 22),
                          tooltip: 'أخصائي التغذية الذكي بالـ AI (Smart Nutritionist)',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AiNutritionistScreen()),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.kebab_dining_rounded, color: Color(0xFFFDA4AF), size: 22),
                          tooltip: 'ملحمة وبحريات الديب الفاخرة (Smart Butcher & Fishery)',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ButcherCustomizerScreen()),
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
                          'المحفظة: 150.00 ل.س',
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
                    cart.itemCount > 0 ? '${cart.totalAmount.toStringAsFixed(2)} ل.س' : 'السلة',
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
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AddressBookScreen()),
                        );
                      },
                      child: Row(
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
                                  'برج فيوز B، دبي ▼',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
                            '150 ل.س',
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
                    decoration: InputDecoration(
                      hintText: 'ابحث بين أكثر من ${mall.catalogCountText} منتج في الديب مول...',
                      hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
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
                  icon: const Icon(Icons.playlist_add_check_rounded, color: AppColors.primary, size: 20),
                  tooltip: 'قائمتي الذكية للمقاضي',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const GroceryListScreen()),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.eco_rounded, color: AppColors.freshGreen, size: 20),
                  tooltip: 'مبادرة الديب الخضراء',
                  onPressed: () => EcoTrackerModal.show(context),
                ),
                IconButton(
                  icon: const Icon(Icons.live_tv_rounded, color: Colors.redAccent, size: 20),
                  tooltip: 'الديب لايف',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LiveShoppingScreen()),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.shopping_cart_checkout_rounded, color: Colors.teal, size: 20),
                  tooltip: 'عربة الديب الذكية',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SmartCartIoTScreen()),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.restaurant_menu_rounded, color: Colors.amber, size: 20),
                  tooltip: 'بوكسات الوجبات',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MealKitsScreen()),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.verified_user_rounded, color: Colors.blueAccent, size: 20),
                  tooltip: 'ضمان أرخص سعر',
                  onPressed: () => PriceMatchModal.show(context),
                ),
                IconButton(
                  icon: const Icon(Icons.local_pharmacy_rounded, color: Color(0xFF34D399), size: 20),
                  tooltip: 'صيدلية الديب وفاحص SFDA',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PharmacyScreen()),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.microwave_rounded, color: Colors.amber, size: 20),
                  tooltip: 'عصا المطبخ والمؤونة',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const KitchenWandScreen()),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.meeting_room_rounded, color: Colors.cyanAccent, size: 20),
                  tooltip: 'خزائن الاستلام الذكية',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SmartLockerPickupScreen()),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.flight_takeoff_rounded, color: Colors.cyanAccent, size: 20),
                  tooltip: 'توصيل بالدرونز 10 دقائق',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DroneTrackingScreen()),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.psychology_rounded, color: Color(0xFF34D399), size: 20),
                  tooltip: 'أخصائي التغذية الذكي',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AiNutritionistScreen()),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.kebab_dining_rounded, color: Color(0xFFFDA4AF), size: 20),
                  tooltip: 'ملحمة وبحريات الديب',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ButcherCustomizerScreen()),
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
  // Major Visual Departments Showcase & Interactive Category Explorer
  // ===========================================================================
  Widget _buildDepartmentsShowcase(MallProvider mall, bool isDesktop) {
    final categories = mall.categories;
    final selId = mall.selectedCategoryId;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(vertical: isDesktop ? 16 : 12),
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Department Header with Count and Reset
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                        const Text(
                          'أقسام الهايبرماركت الكبرى',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'اختر القسم لتصفح آلاف الأصناف الطازجة والموثوقة بأفضل الأسعار',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (selId != null)
                  TextButton.icon(
                    onPressed: () {
                      mall.selectCategory(null);
                      setState(() => _selectedSubcategory = null);
                    },
                    icon: const Icon(Icons.clear_all_rounded, size: 16, color: AppColors.primary),
                    label: const Text(
                      'عرض كل الأقسام',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  )
                else
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CategoriesScreen()),
                      );
                    },
                    icon: const Icon(Icons.grid_view_rounded, size: 15, color: AppColors.primary),
                    label: const Text(
                      'عرض كافة الفئات ←',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. Visual Department Cards Scroller
          SizedBox(
            height: isDesktop ? 165 : 145,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              separatorBuilder: (ctx, i) => const SizedBox(width: 12),
              itemBuilder: (ctx, index) {
                final cat = categories[index];
                final isSel = selId == cat.id;
                final meta = _categoryMeta[cat.id] ?? {
                  'badge': 'أصلي 100%',
                  'tagline': 'أفضل جودة وسعر',
                  'color': '0xFF16A34A',
                };

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DepartmentScreen(category: cat),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: isDesktop ? 175 : 138,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSel ? AppColors.primary : AppColors.border,
                        width: isSel ? 2.5 : 1.0,
                      ),
                      boxShadow: isSel
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Category Photographic Background
                          if (cat.imageUrl != null)
                            CachedNetworkImage(
                              imageUrl: cat.imageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (ctx, url) => Container(color: Colors.grey.shade100),
                            )
                          else
                            Container(
                              color: Color(int.parse(meta['color']!)).withValues(alpha: 0.1),
                              child: const Center(
                                child: Icon(Icons.shopping_basket, size: 40, color: AppColors.primary),
                              ),
                            ),

                          // Dark Gradient Overlay for readability
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.15),
                                  Colors.black.withValues(alpha: 0.45),
                                  Colors.black.withValues(alpha: 0.88),
                                ],
                                stops: const [0.0, 0.45, 1.0],
                              ),
                            ),
                          ),

                          // Active Indicator Glow Check
                          if (isSel)
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check, color: Colors.white, size: 14),
                              ),
                            ),

                          // Top Department Badge
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? AppColors.primary
                                    : Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                meta['badge']!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          // Bottom Title & Info
                          Positioned(
                            left: 10,
                            right: 10,
                            bottom: 10,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  cat.nameAr,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    height: 1.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  meta['tagline']!,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 10,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 3. Dynamic Subcategories & Dietary Filters
          if (selId != null && _categorySubcategories.containsKey(selId)) ...[
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.tune_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'تصفية سريعة لقسم "${categories.firstWhere((c) => c.id == selId, orElse: () => categories.first).nameAr}":',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categorySubcategories[selId]!.length,
                separatorBuilder: (ctx, i) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  final sub = _categorySubcategories[selId]![i];
                  final isSubSel = (_selectedSubcategory == null && i == 0) || (_selectedSubcategory == sub);

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedSubcategory = (i == 0) ? null : sub;
                      });
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSubSel ? AppColors.primary : AppColors.background,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSubSel ? AppColors.primary : AppColors.border,
                        ),
                        boxShadow: isSubSel
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          sub,
                          style: TextStyle(
                            color: isSubSel ? Colors.white : AppColors.textPrimary,
                            fontSize: 11,
                            fontWeight: isSubSel ? FontWeight.bold : FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            // Dietary Quick Filters
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
    final heroBanners = mall.heroBanners;
    if (heroBanners.isEmpty) return const SizedBox();

    final sideTop = mall.sideTopBanner ?? const BannerModel(
      id: 'b_side_top',
      titleAr: 'صفقة اليوم الطازجة 🍅',
      titleEn: 'Fresh Daily Deal 🍅',
      subtitleAr: 'طماطم مزارع محلية قطاف الصباح بخصم 25%',
      imageUrl: 'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?auto=format&fit=crop&w=600&q=80',
      targetType: 'product',
      targetId: 'p3',
      badgeAr: '3.75 د.أ / كجم',
      badgeColor: '#EF4444',
      slot: 'side_top',
    );

    final sideBottom = mall.sideBottomBanner ?? const BannerModel(
      id: 'b_side_bottom',
      titleAr: 'توصيل فوري خلال 60 دقيقة 🛵',
      titleEn: 'Instant Delivery within 60 Mins 🛵',
      subtitleAr: 'اطلب طلبات البيت واستلمها على بابك',
      imageUrl: 'https://images.unsplash.com/photo-1526367790999-0150786686a2?auto=format&fit=crop&w=600&q=80',
      targetType: 'coupon',
      targetId: 'FREE100',
      badgeAr: 'مجاناً للطلبات فوق 100 د.أ',
      badgeColor: '#0284C7',
      slot: 'side_bottom',
    );

    if (!isDesktop) {
      // Mobile Single Carousel with Quick Action Cards Below
      return Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Column(
          children: [
            SizedBox(
              height: 165,
              child: PageView.builder(
                controller: _bannerController,
                onPageChanged: (idx) => setState(() => _currentBannerIndex = idx),
                itemCount: heroBanners.length,
                itemBuilder: (ctx, index) => _buildBannerCard(heroBanners[index]),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(heroBanners.length, (idx) {
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
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 105,
                    child: _buildSideDealCard(sideTop),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 105,
                    child: _buildSideDealCard(sideBottom),
                  ),
                ),
              ],
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
                    itemCount: heroBanners.length,
                    itemBuilder: (ctx, index) => _buildBannerCard(heroBanners[index], height: 320),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 24,
                    child: Row(
                      children: List.generate(heroBanners.length, (idx) {
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

          // Side 1/3 Dynamic Promo Deal Cards
          Expanded(
            flex: 1,
            child: SizedBox(
              height: 320,
              child: Column(
                children: [
                  Expanded(
                    child: _buildSideDealCard(sideTop),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _buildSideDealCard(sideBottom),
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
    final badgeBg = _parseColor(banner.badgeColor, AppColors.secondary);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => BannerNavigator.handleTap(context, banner),
        borderRadius: BorderRadius.circular(16),
        child: Container(
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
                  errorWidget: (context, url, error) => Container(
                    color: AppColors.primaryDark,
                    child: const Icon(Icons.image, color: Colors.white24, size: 48),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.8),
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
                      if (banner.badgeAr != null && banner.badgeAr!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: badgeBg,
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
                      if (banner.subtitleAr != null && banner.subtitleAr!.isNotEmpty)
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
        ),
      ),
    );
  }

  Widget _buildSideDealCard(BannerModel banner) {
    final badgeBg = _parseColor(banner.badgeColor, AppColors.secondary);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => BannerNavigator.handleTap(context, banner),
        borderRadius: BorderRadius.circular(16),
        child: Container(
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
                  errorWidget: (context, url, error) => Container(
                    color: AppColors.primaryDark,
                    child: const Icon(Icons.image, color: Colors.white24, size: 36),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.85),
                        Colors.black.withValues(alpha: 0.25),
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
                      if (banner.badgeAr != null && banner.badgeAr!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            banner.badgeAr!,
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      Text(
                        banner.titleAr,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (banner.subtitleAr != null && banner.subtitleAr!.isNotEmpty)
                        Text(
                          banner.subtitleAr!,
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
        ),
      ),
    );
  }

  Color _parseColor(String? hexString, Color defaultColor) {
    if (hexString == null || hexString.isEmpty) return defaultColor;
    try {
      String clean = hexString.replaceAll('#', '').trim();
      if (clean.length == 6) clean = 'FF$clean';
      return Color(int.parse(clean, radix: 16));
    } catch (_) {
      return defaultColor;
    }
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

  // ===========================================================================
  // Quick Services & Feature Hub (Single Luxury Horizontal Row)
  // ===========================================================================
  Widget _buildQuickServicesHub(BuildContext context) {
    final services = [
      {
        'title': 'ملحمة وبحريات',
        'subtitle': 'تفصيل وتتبيل',
        'icon': Icons.kebab_dining_rounded,
        'gradient': const [Color(0xFFE11D48), Color(0xFF9F1239)],
        'badge': 'طازج بلدي',
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ButcherCustomizerScreen())),
      },
      {
        'title': 'صيدلية الديب',
        'subtitle': 'أدوية وفيتامينات',
        'icon': Icons.medical_services_rounded,
        'gradient': const [Color(0xFF0D9488), Color(0xFF0F766E)],
        'badge': 'صيدلي 24/7',
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PharmacyScreen())),
      },
      {
        'title': 'درونز الديب',
        'subtitle': 'توصيل 10 دقائق',
        'icon': Icons.flight_takeoff_rounded,
        'gradient': const [Color(0xFF0284C7), Color(0xFF0369A1)],
        'badge': 'جوي فوري ⚡',
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DroneTrackingScreen())),
      },
      {
        'title': 'أخصائي AI',
        'subtitle': 'تغذية وحميات',
        'icon': Icons.psychology_rounded,
        'gradient': const [Color(0xFF059669), Color(0xFF047857)],
        'badge': 'ذكاء اصطناعي',
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiNutritionistScreen())),
      },
      {
        'title': 'مجلة العروض',
        'subtitle': 'تصفح تفاعلي',
        'icon': Icons.menu_book_rounded,
        'gradient': const [Color(0xFF2563EB), Color(0xFF1D4ED8)],
        'badge': 'حسم 50%',
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FlyerScreen())),
      },
      {
        'title': 'الديب لايف',
        'subtitle': 'تسوق مباشر',
        'icon': Icons.videocam_rounded,
        'gradient': const [Color(0xFFDC2626), Color(0xFFB91C1C)],
        'badge': 'مباشر الآن 🔴',
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LiveShoppingScreen())),
      },
      {
        'title': 'خزائن 24/7',
        'subtitle': 'استلام آمن',
        'icon': Icons.meeting_room_rounded,
        'gradient': const [Color(0xFF4F46E5), Color(0xFF4338CA)],
        'badge': 'بدون انتظار',
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SmartLockerPickupScreen())),
      },
      {
        'title': 'استلام السيارة',
        'subtitle': 'خلال دقيقتين',
        'icon': Icons.directions_car_rounded,
        'gradient': const [Color(0xFFD97706), Color(0xFFB45309)],
        'badge': 'كيرب سايد',
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CurbsidePickupScreen())),
      },
      {
        'title': 'وفر دورياً',
        'subtitle': 'اشتراك مؤن',
        'icon': Icons.autorenew_rounded,
        'gradient': const [Color(0xFF10B981), Color(0xFF059669)],
        'badge': 'وفر 15%',
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionsScreen())),
      },
      {
        'title': 'شراء جماعي',
        'subtitle': 'مع الجيران',
        'icon': Icons.groups_rounded,
        'gradient': const [Color(0xFFBE123C), Color(0xFF9F1239)],
        'badge': 'وفر 40%',
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupDealsScreen())),
      },
      {
        'title': 'عصا المطبخ',
        'subtitle': 'مسح المؤونة',
        'icon': Icons.microwave_rounded,
        'gradient': const [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
        'badge': 'إنترنت الأشياء',
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KitchenWandScreen())),
      },
      {
        'title': 'صفر نفايات',
        'subtitle': 'ركن التخفيض',
        'icon': Icons.hourglass_top_rounded,
        'gradient': const [Color(0xFFEA580C), Color(0xFFC2410C)],
        'badge': 'حتى 70%',
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ZeroWasteScreen())),
      },
      {
        'title': 'عربة المتجر',
        'subtitle': 'كاشير ذاتي',
        'icon': Icons.shopping_cart_checkout_rounded,
        'gradient': const [Color(0xFF0891B2), Color(0xFF0E7490)],
        'badge': 'بلا طوابير',
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SmartCartIoTScreen())),
      },
      {
        'title': 'بوكسات الشيف',
        'subtitle': 'وجبات جاهزة',
        'icon': Icons.restaurant_menu_rounded,
        'gradient': const [Color(0xFFB45309), Color(0xFF92400E)],
        'badge': 'مقادير مسبقة',
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MealKitsScreen())),
      },
      {
        'title': 'ضمان السعر',
        'subtitle': 'الأرخص دائماً',
        'icon': Icons.verified_user_rounded,
        'gradient': const [Color(0xFF059669), Color(0xFF047857)],
        'badge': 'نعوضك الفرق',
        'onTap': () => PriceMatchModal.show(context),
      },
      {
        'title': 'قائمة البيت',
        'subtitle': 'مخطط المقاضي',
        'icon': Icons.checklist_rounded,
        'gradient': const [Color(0xFF4F46E5), Color(0xFF3730A3)],
        'badge': 'مزامنة عائلية',
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GroceryListScreen())),
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'خدمات وتجارب الديب الذكية',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                const Text(
                  'اسحب للمزيد ←',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 106,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: services.length,
              separatorBuilder: (ctx, i) => const SizedBox(width: 14),
              itemBuilder: (ctx, i) {
                final s = services[i];
                return InkWell(
                  onTap: s['onTap'] as VoidCallback,
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 76,
                    child: Column(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.topCenter,
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: s['gradient'] as List<Color>,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: (s['gradient'] as List<Color>).first.withValues(alpha: 0.35),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Icon(
                                s['icon'] as IconData,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                            if (s['badge'] != null)
                              Positioned(
                                top: -6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.88),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.white24, width: 0.5),
                                  ),
                                  child: Text(
                                    s['badge'] as String,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Text(
                          s['title'] as String,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          s['subtitle'] as String,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.textMuted,
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
    );
  }

  // ===========================================================================
  // Themed Shoppable Shelves & Secondary Banners
  // ===========================================================================

  Widget _buildSecondaryBanner(MallProvider mall, int index, bool isDesktop) {
    final banners = mall.secondaryBanners;
    if (banners.isEmpty) return const SizedBox();
    final banner = banners[index % banners.length];

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isDesktop ? 0 : 16,
        vertical: isDesktop ? 18 : 12,
      ),
      height: isDesktop ? 160 : 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
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
                    Colors.black.withValues(alpha: 0.85),
                    Colors.black.withValues(alpha: 0.35),
                    Colors.transparent,
                  ],
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (banner.badgeAr != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            margin: const EdgeInsets.only(bottom: 6),
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              banner.badgeAr!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        Text(
                          banner.titleAr,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isDesktop ? 18 : 14,
                            fontWeight: FontWeight.w900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (banner.subtitleAr != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            banner.subtitleAr!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: isDesktop ? 12 : 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      if (banner.targetId != null) {
                        mall.selectCategory(banner.targetId);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'تصفح الآن',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_back_ios_new_rounded, size: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyDealsShelf(MallProvider mall, bool isDesktop) {
    final deals = mall.weeklyDeals;
    if (deals.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.stars_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'عروض الأسبوع التوفيرية الكبرى 🌟',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: Color(0xFF92400E),
                        ),
                      ),
                      Text(
                        'أفضل أسعار الأسبوع على المواد التموينية والمقاضي العائلية',
                        style: TextStyle(fontSize: 10.5, color: Color(0xFFB45309)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_outlined, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        _formatDuration(_remainingTime),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          height: 295,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: deals.length,
            itemBuilder: (ctx, index) {
              return Container(
                width: isDesktop ? 220 : 170,
                margin: const EdgeInsetsDirectional.only(end: 12),
                child: ProductCard(product: deals[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCantMissShelf(MallProvider mall, bool isDesktop) {
    final deals = mall.cantMissDeals;
    if (deals.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'عروض لا تفوّت - صفقات خاطفة! 🔥',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'أسعار نارية تنفد سريعاً، أضفها لسلتك فوراً',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondaryLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
                ),
                child: const Text(
                  'فرصة اليوم',
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 295,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: deals.length,
            itemBuilder: (ctx, index) {
              return Container(
                width: isDesktop ? 220 : 170,
                margin: const EdgeInsetsDirectional.only(end: 12),
                child: ProductCard(product: deals[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNewArrivalsShelf(MallProvider mall, bool isDesktop) {
    final products = mall.newArrivals;
    if (products.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.new_releases_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'وصل حديثاً إلى الديب مول ✨',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'أحدث الأصناف والنكهات والمستلزمات في فروعنا',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBAE6FD)),
                ),
                child: const Text(
                  'جديد اليوم',
                  style: TextStyle(
                    color: Color(0xFF0369A1),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 295,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: products.length,
            itemBuilder: (ctx, index) {
              return Container(
                width: isDesktop ? 220 : 170,
                margin: const EdgeInsetsDirectional.only(end: 12),
                child: ProductCard(product: products[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMegaSavingsShelf(MallProvider mall, bool isDesktop) {
    final products = mall.megaDiscounts;
    if (products.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.discount_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'خصومات كبرى وتوفير العائلة 🛍️',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'وفر أكثر مع العبوات الاقتصادية وأكبر نسب خصم',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFDDD6FE)),
                ),
                child: const Text(
                  'وفر حتى 50%',
                  style: TextStyle(
                    color: Color(0xFF6D28D9),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 295,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: products.length,
            itemBuilder: (ctx, index) {
              return Container(
                width: isDesktop ? 220 : 170,
                margin: const EdgeInsetsDirectional.only(end: 12),
                child: ProductCard(product: products[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildButcherShelf(MallProvider mall, bool isDesktop) {
    final meatProducts = mall.products.where((p) => p.categoryId == 'c3').toList();
    if (meatProducts.isEmpty) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFECDD3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () {
                    final cat = mall.categories.firstWhere((c) => c.id == 'c3', orElse: () => mall.categories.first);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => DepartmentScreen(category: cat)));
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE11D48),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.kebab_dining_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'ملحمة وبحريات الديب الفاخرة 🥩🐟',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF881337),
                            ),
                          ),
                          Text(
                            'ذبح بلدي طازج يومياً، أسماك طازجة • اضغط لعرض القسم ←',
                            style: TextStyle(fontSize: 10.5, color: Color(0xFF9F1239)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ButcherCustomizerScreen()),
                    );
                  },
                  icon: const Icon(Icons.content_cut_rounded, size: 14, color: Colors.white),
                  label: const Text(
                    'فصّل ذبيحتك 🔪',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE11D48),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 295,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: meatProducts.length,
              itemBuilder: (ctx, index) {
                return Container(
                  width: isDesktop ? 220 : 170,
                  margin: const EdgeInsetsDirectional.only(end: 12),
                  child: ProductCard(product: meatProducts[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmFreshShelf(MallProvider mall, bool isDesktop) {
    final produceProducts = mall.products.where((p) => p.categoryId == 'c1').toList();
    if (produceProducts.isEmpty) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.eco_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'طازج من مزارعنا المحلية 🥦🍅',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF14532D),
                          ),
                        ),
                        Text(
                          'قطاف الصباح اليومي، نضارة مضمونة وتوصيل فوري مبرد',
                          style: TextStyle(fontSize: 10.5, color: Color(0xFF166534)),
                        ),
                      ],
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    final cat = mall.categories.firstWhere((c) => c.id == 'c1', orElse: () => mall.categories.first);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => DepartmentScreen(category: cat)));
                  },
                  child: const Text(
                    'عرض كل الخضار والفواكه ←',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 295,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: produceProducts.length,
              itemBuilder: (ctx, index) {
                return Container(
                  width: isDesktop ? 220 : 170,
                  margin: const EdgeInsetsDirectional.only(end: 12),
                  child: ProductCard(product: produceProducts[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllProductsSection(MallProvider mall, BuildContext context, bool isDesktop) {
    final list = _getFilteredProducts(mall);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
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
                    mall.selectedCategoryId != null
                        ? 'منتجات ${mall.categories.firstWhere((c) => c.id == mall.selectedCategoryId, orElse: () => mall.categories.first).nameAr}'
                        : 'كافة منتجات الهايبرماركت',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${list.length} صنف متاح',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Sort & Filter Tabs
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSortChip('all', 'الكل ✨'),
                const SizedBox(width: 8),
                _buildSortChip('top_saving', 'الأعلى توفيراً % 🔥'),
                const SizedBox(width: 8),
                _buildSortChip('best_seller', 'الأكثر طلباً 🏆'),
                const SizedBox(width: 8),
                _buildSortChip('low_price', 'الأقل سعراً 💰'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Responsive Product Grid
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
          child: list.isEmpty
              ? Container(
                  height: 200,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search_off_rounded, size: 44, color: AppColors.textMuted),
                      const SizedBox(height: 10),
                      const Text(
                        'لا توجد منتجات مطابقة لخيارات التصفية',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      TextButton(
                        onPressed: () {
                          mall.selectCategory(null);
                          mall.setDietaryFilter(null);
                          setState(() {
                            _selectedSubcategory = null;
                            _activeSortFilter = 'all';
                          });
                        },
                        child: const Text('إعادة تعيين كافة الفلاتر'),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: Responsive.gridColumns(context),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: Responsive.productCardAspectRatio(context),
                  ),
                  itemCount: list.length,
                  itemBuilder: (ctx, index) => ProductCard(product: list[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildSortChip(String id, String label) {
    final isSel = _activeSortFilter == id;
    return InkWell(
      onTap: () => setState(() => _activeSortFilter = id),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSel ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSel ? AppColors.primary : AppColors.border,
          ),
          boxShadow: isSel
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSel ? Colors.white : AppColors.textPrimary,
            fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  List<ProductModel> _getFilteredProducts(MallProvider mall) {
    var list = List<ProductModel>.from(mall.filteredProducts);

    if (_selectedSubcategory != null && _selectedSubcategory != 'الكل') {
      final cleanSub = _selectedSubcategory!.replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), '').trim();
      final tokens = cleanSub.split(' ').where((w) => w.length > 2).toList();
      if (tokens.isNotEmpty) {
        final filtered = list.where((p) {
          final text = '${p.nameAr} ${p.descriptionAr ?? ""} ${p.brand ?? ""}';
          return tokens.any((t) => text.contains(t));
        }).toList();
        if (filtered.isNotEmpty) {
          list = filtered;
        }
      }
    }

    switch (_activeSortFilter) {
      case 'top_saving':
        list.sort((a, b) => b.discountPercent.compareTo(a.discountPercent));
        break;
      case 'best_seller':
        list.sort((a, b) => b.salesCount.compareTo(a.salesCount));
        break;
      case 'low_price':
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      default:
        break;
    }

    return list;
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
                            '${item.price.toStringAsFixed(2)} ل.س',
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
                '${cart.totalAmount.toStringAsFixed(2)} ل.س',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                cart.isFreeDelivery ? 'توصيل مجاني 🛵' : 'تبقّى ${cart.remainingForFreeDelivery.toStringAsFixed(2)} ل.س للمجاني',
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
