import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/category_model.dart';
import '../../core/models/product_model.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/providers/mall_provider.dart';
import '../../core/utils/responsive.dart';
import '../cart/cart_screen.dart';
import '../butcher/butcher_customizer_screen.dart';
import '../home/widgets/product_card.dart';

class DepartmentScreen extends StatefulWidget {
  final CategoryModel category;

  const DepartmentScreen({super.key, required this.category});

  @override
  State<DepartmentScreen> createState() => _DepartmentScreenState();
}

class _DepartmentScreenState extends State<DepartmentScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedSubcategory;
  String _activeSort = 'all'; // 'all', 'top_deal', 'best_seller', 'low_price', 'organic'

  late Duration _remainingDealTime;
  Timer? _countdownTimer;

  static final Map<String, _DepartmentTheme> _departmentThemes = {
    'c1': const _DepartmentTheme(
      primaryColor: Color(0xFF059669),
      gradientColors: [Color(0xFF064E3B), Color(0xFF047857), Color(0xFF059669)],
      accentColor: Color(0xFF34D399),
      tagline: 'طازج من المزارع لمائدتك • قطاف اليوم مبرد ومفحوص مخبرياً',
      badgeText: 'قطاف الصباح 🌿',
      subcategories: [
        'الكل',
        'ورقيات خضراء 🌱',
        'فواكه موسمية 🍎',
        'حمضيات وتفاح 🍊',
        'طماطم وخيار 🍅',
        'عضوي معتمد 🌿',
      ],
      specialFeatureTitle: 'ضمان نضارة المزرعة (Farm to Fork) 🚜',
      specialFeatureDesc: 'تم حصاد خضار وفواكه اليوم فجر اليوم ونقلها في شاحنات مبردة 4°C للحفاظ على أعلى قيمة غذائية.',
      dealBannerText: 'مهرجان الخضار والفواكه الطازجة: خصومات حتى 30%',
    ),
    'c2': const _DepartmentTheme(
      primaryColor: Color(0xFF2563EB),
      gradientColors: [Color(0xFF1E3A8A), Color(0xFF1D4ED8), Color(0xFF2563EB)],
      accentColor: Color(0xFF60A5FA),
      tagline: 'ألبان وأجبان وبيض طازج • تغذية متكاملة ونقاء 100%',
      badgeText: 'طبيعي ويومي 🥛',
      subcategories: [
        'الكل',
        'حليب طازج 🥛',
        'أجبان بيضاء 🧀',
        'أجبان صفراء 🧀',
        'زبادي ولبنة 🥣',
        'بيض مزارع 🥚',
      ],
      specialFeatureTitle: 'سلسلة التبريد الفائقة (Cold Chain Guarantee) ❄️',
      specialFeatureDesc: 'حفظ مستمر تحت درجة حرارة 4 درجات مئوية من خط الإنتاج وحتى باب ثلاجتك.',
      dealBannerText: 'عروض الفطور الصحي: وفر حتى 25% على الألبان والأجبان والبيض',
    ),
    'c3': const _DepartmentTheme(
      primaryColor: Color(0xFFE11D48),
      gradientColors: [Color(0xFF881337), Color(0xFFBE123C), Color(0xFFE11D48)],
      accentColor: Color(0xFFFDA4AF),
      tagline: 'ملحمة وبحريات الديب الفاخرة • ذبح بلدي حلال وأسماك طازجة يومياً',
      badgeText: 'ذبح بلدي حلال 🥩',
      subcategories: [
        'الكل',
        'عجل بلدي طازج 🥩',
        'خروف ونعيمي 🐑',
        'دواجن مبردة 🍗',
        'أسماك وبحريات 🐟',
        'تتبيل وشواء 🍢',
      ],
      specialFeatureTitle: 'خدمة تفصيل وتتبيل الذبائح الحصرية (Smart Butcher) 🔪',
      specialFeatureDesc: 'فصّل ذبيحتك، واختر سماكة الستيك، درجة الفرم، وتتبيلة الشواء الخاصة بنقرة واحدة.',
      dealBannerText: 'صفقات اللحوم البلدية والبحريات: خصومات تصل إلى 35%!',
    ),
    'c4': const _DepartmentTheme(
      primaryColor: Color(0xFFD97706),
      gradientColors: [Color(0xFF78350F), Color(0xFFB45309), Color(0xFFD97706)],
      accentColor: Color(0xFFFDE68A),
      tagline: 'مخبوزات ومعجنات وحلويات • مخبوزة طازجاً من الفرن كل ساعتين',
      badgeText: 'طازج من الفرن 🥐',
      subcategories: [
        'الكل',
        'كرواسان ومعجنات 🥐',
        'خبز ساخن 🥖',
        'فطائر ومناقيش 🥧',
        'حلويات وكيك 🍰',
        'توست وشابورة 🍞',
      ],
      specialFeatureTitle: 'جدول المخبوزات الساخنة (Live Oven Schedule) 🔥',
      specialFeatureDesc: 'خبز الساوردو والكرواسان يخرج طازجاً من أفراننا 4 مرات يومياً.',
      dealBannerText: 'عروض المخبوزات والحلويات: اشترِ 2 واحصل على 1 مجاناً',
    ),
    'c5': const _DepartmentTheme(
      primaryColor: Color(0xFF0284C7),
      gradientColors: [Color(0xFF0369A1), Color(0xFF0284C7), Color(0xFF38BDF8)],
      accentColor: Color(0xFF7DD3FC),
      tagline: 'مياه نقية، عصائر طبيعية طازجة ومشروبات منعشة لجميع المناسبات',
      badgeText: 'انتعاش وبرودة 💧',
      subcategories: [
        'الكل',
        'عصائر طازجة 🍹',
        'مياه معدنية 💧',
        'مشروبات غازية 🥤',
        'شاي وقهوة ☕',
        'مشروبات طاقة ⚡',
      ],
      specialFeatureTitle: 'توصيل مبرد ومثلج فوري (Chilled Express) 🧊',
      specialFeatureDesc: 'تصلك كراتين المياه والمشروبات مبردة ومحفوظة من حرارة الجو خلال 60 دقيقة.',
      dealBannerText: 'صفقات كراتين المياه والعصائر الطبيعية: وفّر حتى 30%',
    ),
    'c6': const _DepartmentTheme(
      primaryColor: Color(0xFF7C3AED),
      gradientColors: [Color(0xFF581C87), Color(0xFF7C3AED), Color(0xFFA78BFA)],
      accentColor: Color(0xFFDDD6FE),
      tagline: 'منظفات ومستلزمات العناية الشاملة بالمنزل بأكبر توفير وأعلى كفاءة',
      badgeText: 'نظافة وتوفير ✨',
      subcategories: [
        'الكل',
        'غسيل الملابس 🧺',
        'نظافة الصحون 🧼',
        'مطهرات ومعقمات 🧴',
        'مناديل وورقيات 🧻',
        'معطرات جو 🌸',
      ],
      specialFeatureTitle: 'باقات التوفير العائلية الكبرى (Mega Family Packs) 🧺',
      specialFeatureDesc: 'عبوات اقتصادية ضخمة توفر عليك حتى 40% من ميزانية المنظفات الشهرية.',
      dealBannerText: 'مهرجان النظافة الشاملة: عروض 1+1 وتخفيضات تصل 45%',
    ),
  };

  @override
  void initState() {
    super.initState();
    _remainingDealTime = const Duration(hours: 4, minutes: 48, seconds: 15);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted && _remainingDealTime.inSeconds > 0) {
        setState(() {
          _remainingDealTime = _remainingDealTime - const Duration(seconds: 1);
        });
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _searchController.dispose();
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
    final isDesktop = Responsive.isDesktop(context);

    final theme = _departmentThemes[widget.category.id] ??
        const _DepartmentTheme(
          primaryColor: AppColors.primary,
          gradientColors: [Color(0xFF064E3B), Color(0xFF047857), Color(0xFF059669)],
          accentColor: AppColors.accent,
          tagline: 'تسوق أفضل منتجات القسم بأعلى معايير الجودة والتوفير',
          badgeText: 'أصلي 100%',
          subcategories: ['الكل'],
          specialFeatureTitle: 'جودة مضمونة 100%',
          specialFeatureDesc: 'جميع المنتجات مفحوصة ومعبأة بأعلى معايير السلامة الغذائية.',
          dealBannerText: 'صفقات حصرية على منتجات هذا القسم',
        );

    // Filter department products
    final allCategoryProducts = mall.products.where((p) => p.categoryId == widget.category.id).toList();

    // 1. Department Deals Products (Deals First!)
    final dealProducts = allCategoryProducts.where((p) => p.isDailyDeal || p.discountPercent > 0).toList();

    // 2. Filtered list based on search, subcategory, and sort
    var filteredList = List<ProductModel>.from(allCategoryProducts);

    // Apply search query
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      filteredList = filteredList.where((p) {
        return p.nameAr.toLowerCase().contains(q) ||
            p.nameEn.toLowerCase().contains(q) ||
            (p.brand != null && p.brand!.toLowerCase().contains(q)) ||
            (p.descriptionAr != null && p.descriptionAr!.toLowerCase().contains(q));
      }).toList();
    }

    // Apply subcategory
    if (_selectedSubcategory != null && _selectedSubcategory != 'الكل') {
      final cleanSub = _selectedSubcategory!.replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), '').trim();
      final tokens = cleanSub.split(' ').where((w) => w.length > 2).toList();
      if (tokens.isNotEmpty) {
        final matches = filteredList.where((p) {
          final text = '${p.nameAr} ${p.descriptionAr ?? ""} ${p.brand ?? ""}';
          return tokens.any((t) => text.contains(t));
        }).toList();
        if (matches.isNotEmpty) {
          filteredList = matches;
        }
      }
    }

    // Apply sorting & dietary filters
    switch (_activeSort) {
      case 'top_deal':
        filteredList.sort((a, b) => b.discountPercent.compareTo(a.discountPercent));
        break;
      case 'best_seller':
        filteredList.sort((a, b) => b.salesCount.compareTo(a.salesCount));
        break;
      case 'low_price':
        filteredList.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'organic':
        filteredList = filteredList.where((p) => p.isOrganic).toList();
        break;
      default:
        break;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // 1. Creative Hero Department Header
              _buildSliverAppBar(context, theme, cart),

              // 2. In-Department Search Bar
              SliverToBoxAdapter(
                child: MaxWidthContainer(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                  child: _buildDepartmentSearch(theme),
                ),
              ),

              // 3. 🔥 DEALS FIRST: عروض وصفقات القسم الحصرية
              if (dealProducts.isNotEmpty)
                SliverToBoxAdapter(
                  child: MaxWidthContainer(
                    child: _buildDepartmentDealsFirstSection(dealProducts, theme, isDesktop),
                  ),
                ),

              // 4. Creative Micro-Experience Banner (Specific to this department)
              SliverToBoxAdapter(
                child: MaxWidthContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: _buildSpecialFeatureCard(theme, context),
                ),
              ),

              // 5. Interactive Subcategories Floating Pills
              SliverToBoxAdapter(
                child: MaxWidthContainer(
                  child: _buildSubcategoriesSelector(theme),
                ),
              ),

              // 6. Sort and Dietary Filter Chips
              SliverToBoxAdapter(
                child: MaxWidthContainer(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: _buildFilterChipsRow(theme),
                ),
              ),

              // 7. Products Section Header with Count
              SliverToBoxAdapter(
                child: MaxWidthContainer(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 20,
                            decoration: BoxDecoration(
                              color: theme.primaryColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _selectedSubcategory != null && _selectedSubcategory != 'الكل'
                                ? 'أصناف: $_selectedSubcategory'
                                : 'كافة أصناف ${widget.category.nameAr}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${filteredList.length} صنف متاح',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 8. Responsive Product Grid
              SliverToBoxAdapter(
                child: MaxWidthContainer(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, cart.itemCount > 0 ? 120 : 60),
                  child: filteredList.isEmpty
                      ? _buildEmptyState(theme)
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: Responsive.gridColumns(context),
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: Responsive.productCardAspectRatio(context),
                          ),
                          itemCount: filteredList.length,
                          itemBuilder: (ctx, index) => ProductCard(product: filteredList[index]),
                        ),
                ),
              ),
            ],
          ),

          // 9. Floating Sticky Cart Bar (When Cart Has Items)
          if (cart.itemCount > 0)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: MaxWidthContainer(
                maxWidth: 600,
                child: _buildFloatingCartBar(context, cart, theme),
              ),
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 1. Creative Hero Department Header
  // ===========================================================================
  Widget _buildSliverAppBar(BuildContext context, _DepartmentTheme theme, CartProvider cart) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: theme.primaryColor,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 20),
                if (cart.itemCount > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${cart.itemCount}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
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
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            if (widget.category.imageUrl != null)
              CachedNetworkImage(
                imageUrl: widget.category.imageUrl!,
                fit: BoxFit.cover,
                placeholder: (ctx, url) => Container(color: theme.primaryColor),
              )
            else
              Container(color: theme.primaryColor),

            // Gradient Tint Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.2),
                    theme.gradientColors[1].withValues(alpha: 0.8),
                    theme.gradientColors[0],
                  ],
                ),
              ),
            ),

            // Department Info
            Positioned(
              right: 20,
              left: 20,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white30, width: 0.5),
                    ),
                    child: Text(
                      theme.badgeText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.category.nameAr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    theme.tagline,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                      height: 1.3,
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

  // ===========================================================================
  // 2. In-Department Search Bar
  // ===========================================================================
  Widget _buildDepartmentSearch(_DepartmentTheme theme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          hintText: 'ابحث في أصناف ${widget.category.nameAr}...',
          hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          prefixIcon: Icon(Icons.search_rounded, color: theme.primaryColor),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  // ===========================================================================
  // 3. 🔥 DEALS FIRST SECTION: عروض وصفقات القسم الحصرية
  // ===========================================================================
  Widget _buildDepartmentDealsFirstSection(
    List<ProductModel> deals,
    _DepartmentTheme theme,
    bool isDesktop,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 14, bottom: 6),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.04),
        border: Border(
          top: BorderSide(color: theme.primaryColor.withValues(alpha: 0.15)),
          bottom: BorderSide(color: theme.primaryColor.withValues(alpha: 0.15)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Deals Header with Countdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'عروض وصفقات ${widget.category.nameAr} الكبرى 🔥',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: theme.primaryColor,
                          ),
                        ),
                        Text(
                          theme.dealBannerText,
                          style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                // Live Countdown Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer_outlined, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        _formatDuration(_remainingDealTime),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Horizontal Deals Scroller
          SizedBox(
            height: 295,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: deals.length,
              separatorBuilder: (ctx, i) => const SizedBox(width: 12),
              itemBuilder: (ctx, index) {
                return SizedBox(
                  width: isDesktop ? 220 : 170,
                  child: ProductCard(product: deals[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. Creative Micro-Experience Banner
  // ===========================================================================
  Widget _buildSpecialFeatureCard(_DepartmentTheme theme, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.gradientColors[0],
            theme.gradientColors[1],
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.category.id == 'c3' ? Icons.kebab_dining_rounded : Icons.verified_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  theme.specialFeatureTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  theme.specialFeatureDesc,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 10.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          if (widget.category.id == 'c3') ...[
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ButcherCustomizerScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: theme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(
                'فصّل ذبيحتك 🔪',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // 5. Interactive Subcategories Floating Selector
  // ===========================================================================
  Widget _buildSubcategoriesSelector(_DepartmentTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: theme.subcategories.length,
          separatorBuilder: (ctx, i) => const SizedBox(width: 8),
          itemBuilder: (ctx, index) {
            final sub = theme.subcategories[index];
            final isSel = (_selectedSubcategory == null && index == 0) || (_selectedSubcategory == sub);

            return InkWell(
              onTap: () {
                setState(() {
                  _selectedSubcategory = (index == 0) ? null : sub;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSel ? theme.primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSel ? theme.primaryColor : AppColors.border,
                    width: isSel ? 1.5 : 1.0,
                  ),
                  boxShadow: isSel
                      ? [
                          BoxShadow(
                            color: theme.primaryColor.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    sub,
                    style: TextStyle(
                      color: isSel ? Colors.white : AppColors.textPrimary,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ===========================================================================
  // 6. Sort and Dietary Filter Chips
  // ===========================================================================
  Widget _buildFilterChipsRow(_DepartmentTheme theme) {
    final chips = [
      {'id': 'all', 'label': 'كافة المنتجات ✨'},
      {'id': 'top_deal', 'label': 'الأعلى تخفيضاً % 🔥'},
      {'id': 'best_seller', 'label': 'الأكثر طلباً 🏆'},
      {'id': 'low_price', 'label': 'الأقل سعراً 💰'},
      {'id': 'organic', 'label': 'عضوي وصحي 🌱'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: chips.map((c) {
          final isSel = _activeSort == c['id'];
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: InkWell(
              onTap: () => setState(() => _activeSort = c['id']!),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSel ? theme.primaryColor.withValues(alpha: 0.12) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSel ? theme.primaryColor : AppColors.border,
                    width: isSel ? 1.5 : 1.0,
                  ),
                ),
                child: Text(
                  c['label']!,
                  style: TextStyle(
                    color: isSel ? theme.primaryColor : AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ===========================================================================
  // 7. Empty State
  // ===========================================================================
  Widget _buildEmptyState(_DepartmentTheme theme) {
    return Container(
      height: 240,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 52, color: theme.primaryColor.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          const Text(
            'لا توجد أصناف مطابقة للتصفية الحالية',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            'جرب تغيير كلمة البحث أو اختيار تصنيف فرعي آخر',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
                _selectedSubcategory = null;
                _activeSort = 'all';
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('إعادة تعيين كافة الفلاتر'),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 8. Floating Sticky Cart Bar
  // ===========================================================================
  Widget _buildFloatingCartBar(BuildContext context, CartProvider cart, _DepartmentTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.textPrimary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${cart.itemCount} أصناف في السلة',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Text(
                'الإجمالي: ${cart.subtotal.toStringAsFixed(2)} ل.س',
                style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w900, fontSize: 13),
              ),
            ],
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            },
            icon: const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.textPrimary),
            label: const Text(
              'عرض السلة',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _DepartmentTheme {
  final Color primaryColor;
  final List<Color> gradientColors;
  final Color accentColor;
  final String tagline;
  final String badgeText;
  final List<String> subcategories;
  final String specialFeatureTitle;
  final String specialFeatureDesc;
  final String dealBannerText;

  const _DepartmentTheme({
    required this.primaryColor,
    required this.gradientColors,
    required this.accentColor,
    required this.tagline,
    required this.badgeText,
    required this.subcategories,
    required this.specialFeatureTitle,
    required this.specialFeatureDesc,
    required this.dealBannerText,
  });
}
