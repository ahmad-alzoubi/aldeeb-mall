import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/product_model.dart';
import '../../core/providers/cart_provider.dart';

class AiNutritionistScreen extends StatefulWidget {
  const AiNutritionistScreen({super.key});

  @override
  State<AiNutritionistScreen> createState() => _AiNutritionistScreenState();
}

class _AiNutritionistScreenState extends State<AiNutritionistScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedGoal = 'بناء عضلات ونشاط رياضي (Lean Muscle)';
  int _selectedDayIndex = 0;

  final List<String> _weekDays = [
    'السبت',
    'الأحد',
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
  ];

  // Daily Meal Plans Map
  final List<Map<String, dynamic>> _mealsForToday = [
    {
      'type': 'وجبة الإفطار (Breakfast)',
      'title': 'أومليت بياض البيض بالأفوكادو مع توست الشوفان',
      'calories': 420,
      'protein': 32,
      'carbs': 35,
      'fats': 16,
      'image': 'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=500',
    },
    {
      'type': 'سناك صباحي (Morning Snack)',
      'title': 'زبادي يوناني عالي البروتين مع توت أزرق وبذور الشيا',
      'calories': 180,
      'protein': 18,
      'carbs': 14,
      'fats': 4,
      'image': 'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=500',
    },
    {
      'type': 'وجبة الغداء (Lunch)',
      'title': 'صدر دجاج مشوي متبل بالأعشاب مع أرز بني وسلطة الكينوا',
      'calories': 640,
      'protein': 56,
      'carbs': 62,
      'fats': 18,
      'image': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500',
    },
    {
      'type': 'سناك بعد التمرين (Pre/Post Workout)',
      'title': 'موز مع حفنة لوز وجوز نيء غير محمص (30 جم)',
      'calories': 210,
      'protein': 6,
      'carbs': 28,
      'fats': 11,
      'image': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=500',
    },
    {
      'type': 'وجبة العشاء (Dinner)',
      'title': 'فيليه سالمون نرويجي مشوي مع هليون وخضار سوتيه بزيت الزيتون',
      'calories': 530,
      'protein': 46,
      'carbs': 18,
      'fats': 24,
      'image': 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=500',
    },
  ];

  // Consolidated 7-Day Groceries List calculated by AI
  final List<Map<String, dynamic>> _weeklyGroceries = [
    {
      'product': const ProductModel(
        id: 'nutri-1',
        nameAr: 'صدور دجاج طازجة بدون عظم اليوم 1.5 كجم',
        nameEn: 'Alyoum Fresh Boneless Chicken Breast 1.5kg',
        price: 52.00,
        images: ['https://images.unsplash.com/photo-1604503468506-a8da13d82791?w=500'],
        unit: 'pack',
      ),
      'planQty': '1.5 كجم (تكفي 7 وجبات غداء)',
    },
    {
      'product': const ProductModel(
        id: 'nutri-2',
        nameAr: 'فيليه سالمون نرويجي طازج 800 جم',
        nameEn: 'Fresh Norwegian Salmon Fillet 800g',
        price: 89.00,
        images: ['https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?w=500'],
        unit: 'pack',
      ),
      'planQty': '800 جم (تكفي 4 وجبات عشاء)',
    },
    {
      'product': const ProductModel(
        id: 'nutri-3',
        nameAr: 'بيض وطني عضوي مزارع فقيه 30 بيضة',
        nameEn: 'Fakieh Organic Fresh Eggs 30 Eggs',
        price: 24.50,
        images: ['https://images.unsplash.com/photo-1516448620398-c5f44bf9f441?w=500'],
        unit: 'pack',
      ),
      'planQty': 'طبق كامل 30 بيضة (أومليت صباحي يومي)',
    },
    {
      'product': const ProductModel(
        id: 'nutri-4',
        nameAr: 'أفوكادو هاس مكسيكي جاهز للأكل كيس 1 كجم',
        nameEn: 'Mexican Hass Avocado Ready to Eat 1kg',
        price: 26.00,
        images: ['https://images.unsplash.com/photo-1523049673857-eb18f1d7b578?w=500'],
        unit: 'pack',
      ),
      'planQty': 'كيس 1 كجم (6 حبات موزونة)',
    },
    {
      'product': const ProductModel(
        id: 'nutri-5',
        nameAr: 'زبادي يوناني سادة نادك خالي الدسم 160 جم x6',
        nameEn: 'Nadec Plain Greek Yogurt 0% Fat 160g x6',
        price: 36.00,
        images: ['https://images.unsplash.com/photo-1488477181946-6428a0291777?w=500'],
        unit: 'pack',
      ),
      'planQty': '6 حبات سناك يومي عالي البروتين',
    },
    {
      'product': const ProductModel(
        id: 'nutri-6',
        nameAr: 'شوفان الحبة الكاملة كويكر العضوي 500 جم',
        nameEn: 'Quaker Organic 100% Whole Grain Oats 500g',
        price: 18.00,
        images: ['https://images.unsplash.com/photo-1586201375761-83865001e31c?w=500'],
        unit: 'pack',
      ),
      'planQty': 'علبة 500 جم كربوهيدرات معقدة',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF065F46),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'أخصائي التغذية الذكي بالـ AI',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Aldeeb Smart AI Nutritionist • خطط وجبات ومقاضي الأسبوع',
                  style: TextStyle(fontSize: 10, color: Color(0xFFA7F3D0)),
                ),
              ],
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF34D399),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.track_changes_rounded, size: 18), text: 'أهدافي والماكروز'),
            Tab(icon: Icon(Icons.restaurant_menu_rounded, size: 18), text: 'وجبات الأسبوع'),
            Tab(icon: Icon(Icons.shopping_basket_rounded, size: 18), text: 'مقاضي الخطة للسلة'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGoalsAndMacrosTab(),
          _buildWeeklyMealPlanTab(),
          _buildShoppableGroceriesTab(cart),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1: GOALS & MACROS
  // ===========================================================================
  Widget _buildGoalsAndMacrosTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Personalization Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF065F46), Color(0xFF047857)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Colors.amber, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'محرك التغذية الحسابي الدقيق (AI Dietetics)',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'يحلل وزنك وهدفك الصحي، يحسب السعرات والماكروز بدقة، ويحولها لمقادير طازجة بدون هدر من الديب مول.',
                        style: TextStyle(color: Color(0xFFD1FAE5), fontSize: 11, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Goal Selector
          const Text(
            'اختر هدفك الصحي الحالي:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),

          ...[
            'بناء عضلات ونشاط رياضي (Lean Muscle)',
            'خسارة دهون صحية ونزول آمن (Fat Loss)',
            'كيتو وقليل الكاربوهيدرات (Keto & Low Carb)',
            'حمية لضبط السكر وضغط الدم (Diabetic & Heart Health)',
          ].map((goal) {
            final isSelected = _selectedGoal == goal;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF059669) : Colors.grey.shade200,
                  width: isSelected ? 2 : 1,
                ),
              ),
              color: isSelected ? const Color(0xFFECFDF5) : Colors.white,
              child: ListTile(
                onTap: () => setState(() => _selectedGoal = goal),
                leading: Icon(
                  isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: isSelected ? const Color(0xFF059669) : Colors.grey,
                ),
                title: Text(
                  goal,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? const Color(0xFF065F46) : AppColors.textPrimary,
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 20),

          // Daily Target Breakdown Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'الاحتياج اليومي المستهدف (Daily Target):',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '1,980 سعرة حرارية/يوم',
                        style: TextStyle(color: Color(0xFFB45309), fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Macros 3-Bar breakdown
                _buildMacroBar(
                  label: 'البروتين (Protein)',
                  grams: '158 جم',
                  percent: 0.32,
                  color: Colors.blue,
                ),
                const SizedBox(height: 10),
                _buildMacroBar(
                  label: 'الكاربوهيدرات المعقدة (Carbs)',
                  grams: '185 جم',
                  percent: 0.38,
                  color: Colors.amber,
                ),
                const SizedBox(height: 10),
                _buildMacroBar(
                  label: 'الدهون الصحية (Healthy Fats)',
                  grams: '58 جم',
                  percent: 0.30,
                  color: Colors.teal,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroBar({
    required String label,
    required String grams,
    required double percent,
    required MaterialColor color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Text(
              '$grams (${(percent * 100).toInt()}%)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color.shade800),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // TAB 2: 7-DAY MEAL PLAN
  // ===========================================================================
  Widget _buildWeeklyMealPlanTab() {
    return Column(
      children: [
        // Horizontal Week Days Scroller
        Container(
          height: 60,
          color: Colors.white,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            itemCount: _weekDays.length,
            itemBuilder: (context, index) {
              final isSelected = _selectedDayIndex == index;
              return GestureDetector(
                onTap: () => setState(() => _selectedDayIndex = index),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF065F46) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _weekDays[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Meals List for the selected day
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _mealsForToday.length,
            itemBuilder: (context, index) {
              final meal = _mealsForToday[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          meal['image'] as String,
                          width: 75,
                          height: 75,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 75,
                            height: 75,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.restaurant_menu_rounded, color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              meal['type'] as String,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              meal['title'] as String,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, height: 1.2),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              children: [
                                Text('${meal['calories']} kcal', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                Text('• بروتين: ${meal['protein']}g', style: const TextStyle(fontSize: 11, color: Colors.blue)),
                                Text('• كارب: ${meal['carbs']}g', style: const TextStyle(fontSize: 11, color: Colors.amber)),
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
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // TAB 3: SHOPPABLE GROCERIES CONVERSION
  // ===========================================================================
  Widget _buildShoppableGroceriesTab(CartProvider cart) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
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
                  const Text(
                    'سلة مقاضي الأسبوع الصحية بالكامل:',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'وفرت 45.00 ر.س (15%)',
                      style: TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'قام الذكاء الاصطناعي بتجميع كافة مقادير الـ 35 وجبة وسناك للأسبوع بالكامل بدون هدر غذائي وبأفضل الأسعار.',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, height: 1.3),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add_shopping_cart_rounded),
                  label: const Text(
                    'إضافة مقاضي الأسبوع بالكامل إلى السلة (6 أصناف)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  onPressed: () {
                    for (final item in _weeklyGroceries) {
                      cart.addToCart(item['product'] as ProductModel);
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تمت إضافة جميع مقاضي خطة الأسبوع الغذائية إلى سلة التسوق بنجاح!'),
                        backgroundColor: AppColors.freshGreen,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // List of consolidated items
        ..._weeklyGroceries.map((item) {
          final product = item['product'] as ProductModel;
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      product.firstImage,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey.shade200,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.nameAr,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item['planQty'] as String,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${product.price.toStringAsFixed(2)} ر.س',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
