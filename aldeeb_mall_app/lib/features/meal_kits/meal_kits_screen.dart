import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/product_model.dart';
import '../../core/providers/cart_provider.dart';

class MealKit {
  final String id;
  final String titleAr;
  final String titleEn;
  final String cuisine;
  final int prepTimeMinutes;
  final String difficulty;
  final int caloriesPerServing;
  final double basePriceForTwo;
  final String imageUrl;
  final String chefName;
  final String descriptionAr;
  final List<String> ingredients;
  final List<String> cookingSteps;

  const MealKit({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.cuisine,
    required this.prepTimeMinutes,
    required this.difficulty,
    required this.caloriesPerServing,
    required this.basePriceForTwo,
    required this.imageUrl,
    required this.chefName,
    required this.descriptionAr,
    required this.ingredients,
    required this.cookingSteps,
  });
}

class MealKitsScreen extends StatefulWidget {
  const MealKitsScreen({super.key});

  @override
  State<MealKitsScreen> createState() => _MealKitsScreenState();
}

class _MealKitsScreenState extends State<MealKitsScreen> {
  String _selectedCuisine = 'الكل';
  int _selectedServings = 2; // 2, 4, 6

  final List<String> _cuisines = [
    'الكل',
    'أطباق سعودية',
    'أطباق إيطالية وعالمية',
    'صحي وكيتو',
    'أطباق بحرية',
  ];

  late final List<MealKit> _mealKits;

  @override
  void initState() {
    super.initState();
    _initKits();
  }

  void _initKits() {
    _mealKits = [
      const MealKit(
        id: 'KIT-001',
        titleAr: 'بوكس كبسة لحم الحاشي الفاخرة مع الأرز العنبر',
        titleEn: 'Premium Camel Meat Kabsa with Amber Rice',
        cuisine: 'أطباق سعودية',
        prepTimeMinutes: 30,
        difficulty: 'سهل جداً',
        caloriesPerServing: 620,
        basePriceForTwo: 54.0,
        imageUrl: 'https://images.unsplash.com/photo-1544025162-d76694265947?w=600&q=80',
        chefName: 'الشيف نورة',
        descriptionAr: 'قطع لحم حاشي بلدي طازج متبل بالبهارات النجدية، مع خضار مقطعة وأرز عنبر منقوع وموزون بدقة.',
        ingredients: [
          'لحم حاشي بلدي طازج مقطع ومسحوب العظم (600غ)',
          'أرز عنبر فاخر طويل الحبة مغسول وموزون (400غ)',
          'كيس خضار طازجة مغسولة ومقطعة (بصل، طماطم، ثوم، فلفل حار)',
          'ظرف بهارات الكبسة النجدية الخاصة وصرار حائل',
          'سمن بقر بلدي نقي للتحمير (50غ)',
        ],
        cookingSteps: [
          'سخّن قدر الضغط وضع كيس السمن والبهارات الصحيحة لمدة دقيقة حتى تفوح الرائحة.',
          'أضف قطع لحم الحاشي وقلّبها على نار عالية حتى تكتسب لوناً ذهبياً شهياً.',
          'اسكب كيس الطماطم المفرومة والماء المغلي وأغلق القدر لـ 20 دقيقة.',
          'افتح القدر وأضف أرز العنبر الموزون واتركه ينضج على نار هادئة لـ 10 دقائق حتى يتشرب المرق.',
        ],
      ),
      const MealKit(
        id: 'KIT-002',
        titleAr: 'بوكس فيليه السالمون النرويجي بالليمون والأعشاب والهليون',
        titleEn: 'Norwegian Salmon with Lemon Herb & Asparagus',
        cuisine: 'أطباق بحرية',
        prepTimeMinutes: 18,
        difficulty: 'سهل جداً',
        caloriesPerServing: 480,
        basePriceForTwo: 68.0,
        imageUrl: 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=600&q=80',
        chefName: 'الشيف كريستيان',
        descriptionAr: 'قطعتان من فيليه السالمون الطازج منزوع الشوك مع أعواد هليون غضة وزبدة الأعشاب والليمون.',
        ingredients: [
          'فيليه سالمون نرويجي مبرد منزوع الحسك (400غ)',
          'حزمة هليون طازجة منظفة ومقلمة (200غ)',
          'زبدة زكية مخلوطة بالشبت والليمون والثوم المعمر',
          'بطاطس صغيرة مسلوقة نصف سلقة للتحمير السريع',
          'ملح بحري خشن ورقائق الفلفل الوردي',
        ],
        cookingSteps: [
          'جفف فيليه السالمون بمنديل ورقي ثم تبّله برشة الملح البحري.',
          'في مقلاة ساخنة، ضع ملعقة زيت زيتون وحمّر السالمون لـ 4 دقائق على جانب الجلد حتى يصبح مقرمشاً.',
          'اقلب السالمون وأضف الهليون والبطاطس وزبدة الأعشاب بالليمون في المقلاة.',
          'اتركه لـ 3 دقائق إضافية مع توزيع الزبدة المذابة بالملعقة فوق السالمون ثم ارفعه مباشرة.',
        ],
      ),
      const MealKit(
        id: 'KIT-003',
        titleAr: 'بوكس فيتوتشيني ألفريدو بالدجاج الفاخر والفطر البري',
        titleEn: 'Creamy Chicken & Wild Mushroom Fettuccine Alfredo',
        cuisine: 'أطباق إيطالية وعالمية',
        prepTimeMinutes: 20,
        difficulty: 'سهل جداً',
        caloriesPerServing: 590,
        basePriceForTwo: 48.0,
        imageUrl: 'https://images.unsplash.com/photo-1645112411341-6c4fd023714a?w=600&q=80',
        chefName: 'الشيف أندريا',
        descriptionAr: 'باستا إيطالية طازجة مع صدور دجاج متبلة، كريمة طبخ غنية، فطر بورتوبيلو، وجبن بارميزان ريجيانو.',
        ingredients: [
          'باستا فيتوتشيني طازجة يدوية الصنع (350غ)',
          'صدور دجاج وطنية مقطعة ومتبلة بالأوريغانو وزيت الزيتون (350غ)',
          'فطر بورتوبيلو ومشروم بني طازج مقطع شرائح',
          'كريمة طبخ طازجة فرنسية كاملة الدسم (250 مل)',
          'جبن بارميزان إيطالي أصلي مبشور حديثاً (60غ)',
        ],
        cookingSteps: [
          'اغلِ ماءً وفيراً مملحاً وضع الباستا الطازجة لمدة 4 دقائق فقط حتى تصل لدرجة al dente.',
          'في مقلاة واسعة، حمّر شرائح الدجاج مع الفطر في ملعقة زبدة حتى يحمر الدجاج.',
          'اسكب كريمة الطبخ واتركها تغلي بلطف لمدة دقيقتين حتى تصبح سميكة وغنية.',
          'أضف الباستا المسلوقة ونصف كمية البارميزان وقلّب جيداً، ثم رُش باقي الجبن عند التقديم.',
        ],
      ),
      const MealKit(
        id: 'KIT-004',
        titleAr: 'بوكس مقلوبة الدجاج والخضار المشكلة مع سلطة الزبادي',
        titleEn: 'Chicken Maqluba with Mixed Veggies & Cucumber Yogurt',
        cuisine: 'أطباق سعودية',
        prepTimeMinutes: 28,
        difficulty: 'متوسط',
        caloriesPerServing: 560,
        basePriceForTwo: 46.0,
        imageUrl: 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=600&q=80',
        chefName: 'الشيف نورة',
        descriptionAr: 'طبقات الدجاج المتبل مع الباذنجان والبطاطس والزهرة والأرز المتبل، مع زبادي الخيار بالنعناع.',
        ingredients: [
          'نصف دجاجة وطنية مبردة مقطعة 4 قطع ومتبلة (500غ)',
          'شرائح باذنجان وبطاطس وزهرة مقلية نصف قلية (300غ)',
          'أرز بسمتي فاخر منقوع وموزون بدقة (350غ)',
          'بهارات المقلوبة الخاصة بالكركم والهيل والقرفة',
          'علبة زبادي نادك طازجة مع خيار مبشور وظرف نعناع مجفف',
        ],
        cookingSteps: [
          'في قاع القدر، رتّب شرائح البطاطس والباذنجان والزهرة ثم قطع الدجاج المحمرة.',
          'اسكب الأرز الموزون فوق طبقات الخضار والدجاج وساوِ السطح بلطف.',
          'صب مرق الدجاج الساخن والمتبل حتى يغطي الأرز بارتفاع 1 سم.',
          'أغلق القدر واتركه على نار هادئة لـ 20 دقيقة، ثم اقلب القدر بحذر في طبق التقديم الواسع.',
        ],
      ),
    ];
  }

  double _calculatePrice(double basePrice) {
    if (_selectedServings == 2) return basePrice;
    if (_selectedServings == 4) return (basePrice * 1.85); // 15% discount for 4
    return (basePrice * 2.65); // 20% discount for 6
  }

  void _showKitDetailsModal(MealKit kit) {
    final cart = Provider.of<CartProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final currentPrice = _calculatePrice(kit.basePriceForTwo);

            return Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Content Scroll
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        // Image & Badges
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: CachedNetworkImage(
                                imageUrl: kit.imageUrl,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A).withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  kit.chefName,
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 10,
                              left: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '⏱️ جاهز في ${kit.prepTimeMinutes} دقيقة',
                                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w900),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Title & Cuisine
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                kit.titleAr,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          kit.descriptionAr,
                          style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.4),
                        ),
                        const SizedBox(height: 16),

                        // Servings Selector
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'اختر عدد الحصص والأشخاص (Servings):',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [2, 4, 6].map((servings) {
                                  final isSelected = _selectedServings == servings;
                                  return Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: InkWell(
                                        onTap: () {
                                          setState(() => _selectedServings = servings);
                                          setModalState(() {});
                                        },
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          decoration: BoxDecoration(
                                            color: isSelected ? AppColors.primary : Colors.white,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: isSelected ? AppColors.primary : Colors.grey.shade300,
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              Text(
                                                '$servings أشخاص',
                                                style: TextStyle(
                                                  color: isSelected ? Colors.white : AppColors.textPrimary,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              if (servings > 2)
                                                Text(
                                                  servings == 4 ? 'وفر 15%' : 'وفر 20%',
                                                  style: TextStyle(
                                                    color: isSelected ? AppColors.accent : Colors.red.shade600,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Included Ingredients
                        const Row(
                          children: [
                            Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'محتويات البوكس الموزونة والمغلفة بإحكام:',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...kit.ingredients.map((ing) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: AppColors.freshGreen, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      ing,
                                      style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                        const SizedBox(height: 20),

                        // Cooking Steps
                        const Row(
                          children: [
                            Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'طريقة الطهي السريعة خطوة بخطوة:',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...kit.cookingSteps.asMap().entries.map((entry) {
                          final idx = entry.key + 1;
                          final step = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 11,
                                  backgroundColor: AppColors.primary,
                                  child: Text(
                                    idx.toString(),
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    step,
                                    style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.4),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  // Bottom Action Bar
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Colors.grey.shade200)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, -3)),
                      ],
                    ),
                    child: SafeArea(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'السعر لـ $_selectedServings أشخاص:',
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                              Text(
                                '${currentPrice.toStringAsFixed(2)} ل.س',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.freshGreen),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              final kitProduct = ProductModel(
                                id: '${kit.id}-$_selectedServings',
                                nameAr: '${kit.titleAr} ($_selectedServings أشخاص)',
                                nameEn: '${kit.titleEn} ($_selectedServings servings)',
                                price: currentPrice,
                                images: [kit.imageUrl],
                                categoryId: 'وجبات جاهزة',
                              );
                              cart.addToCart(kitProduct);
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('تمت إضافة "${kit.titleAr}" إلى سلتك!'),
                                  backgroundColor: AppColors.freshGreen,
                                ),
                              );
                            },
                            icon: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 18),
                            label: const Text(
                              'إضافة البوكس للسلة',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredKits = _selectedCuisine == 'الكل'
        ? _mealKits
        : _mealKits.where((k) => k.cuisine == _selectedCuisine).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'بوكسات وجبات الديب للطهي السريع 🧑‍🍳',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'مقادير طازجة، مقطعة وموزونة لطبخة فاخرة في 20 دقيقة (Chef Meal Kits)',
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          // Top Hero Banner
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF3B82F6)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'طازجة يومياً 100%',
                          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 11),
                        ),
                      ),
                      const Text(
                        'بدون هدر وبدون تنظيف',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'اطبخ كالمحترفين في منزلك في دقائق',
                    style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'نحن نشتري أفضل اللحوم والخضار، ونغسلها، ونقطعها، ونزنها بدقة، ونرسلها لك في بوكس حراري جاهز للطهي الفوري.',
                    style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
          ),

          // Cuisines Strip
          SliverToBoxAdapter(
            child: SizedBox(
              height: 44,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _cuisines.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final cuisine = _cuisines[idx];
                  final isSelected = cuisine == _selectedCuisine;
                  return InkWell(
                    onTap: () => setState(() => _selectedCuisine = cuisine),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF0F172A) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF0F172A) : Colors.grey.shade300,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          cuisine,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Kits Grid / List
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final kit = filteredKits[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: AppColors.cardShadow,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _showKitDetailsModal(kit),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              CachedNetworkImage(
                                imageUrl: kit.imageUrl,
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    kit.cuisine,
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 10,
                                left: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '⏱️ ${kit.prepTimeMinutes} دقيقة',
                                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  kit.titleAr,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  kit.descriptionAr,
                                  style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('يبدأ من (لشخصين):', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                        Text(
                                          '${kit.basePriceForTwo.toStringAsFixed(2)} ل.س',
                                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.freshGreen),
                                        ),
                                      ],
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () => _showKitDetailsModal(kit),
                                      icon: const Icon(Icons.restaurant_menu_rounded, size: 16, color: Colors.white),
                                      label: const Text(
                                        'عرض وتخصيص البوكس',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.5),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: filteredKits.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }
}
