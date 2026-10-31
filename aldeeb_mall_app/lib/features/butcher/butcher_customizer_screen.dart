import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/product_model.dart';
import '../../core/providers/cart_provider.dart';

class ButcherCustomizerScreen extends StatefulWidget {
  const ButcherCustomizerScreen({super.key});

  @override
  State<ButcherCustomizerScreen> createState() => _ButcherCustomizerScreenState();
}

class _ButcherCustomizerScreenState extends State<ButcherCustomizerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Selected Meat/Seafood Options
  String _selectedCutStyle = 'تفصيل ثلاجة (قطع متوسطة للطبخ المنزلي)';
  String _selectedFatRatio = 'قليل الدسم 10% (Medium Lean)';
  String _selectedPackaging = 'تغليف سحب هواء مفرغ بالوجبة (Vacuum 1kg)';
  bool _includeOffalCleaned = true; // كرشة ورأس وكراعين منظفة
  bool _addChefSpiceRub = false; // تتبيلة الديب الخاصة
  int _carcassPortion = 1; // 1 = Whole, 2 = Half, 4 = Quarter

  final List<Map<String, dynamic>> _meats = [
    {
      'id': 'meat-naemi',
      'name': 'خروف نعيمي بلدي طازج (جذع فاخر)',
      'pricePerKg': 68.0,
      'wholeCarcassPrice': 1450.0,
      'weightApprox': '18 - 22 كجم',
      'image': 'https://images.unsplash.com/photo-1603048588665-791ca8aea617?w=500',
      'origin': 'مراعي القصيم وحائل • ذبح اليوم فجراً',
      'category': 'ذبيحة كاملة أو أجزاء',
    },
    {
      'id': 'meat-teess',
      'name': 'تيس بلدي عارضي لباني طازج',
      'pricePerKg': 72.0,
      'wholeCarcassPrice': 1150.0,
      'weightApprox': '12 - 15 كجم',
      'image': 'https://images.unsplash.com/photo-1544025162-d76694265947?w=500',
      'origin': 'مزارع الخرج والرياض • لحم طري وسريع النضج',
      'category': 'ذبيحة كاملة أو أجزاء',
    },
    {
      'id': 'meat-hashee',
      'name': 'لحم حاشي بلدي صغير (مفرود طازج)',
      'pricePerKg': 62.0,
      'wholeCarcassPrice': null,
      'weightApprox': 'بالكيلو حسب الطلب',
      'image': 'https://images.unsplash.com/photo-1588347818036-558601350947?w=500',
      'origin': 'حواشي نجدية محلية صغيرة • لحم هبر أحمر بدون دهون زائدة',
      'category': 'بالكيلو',
    },
    {
      'id': 'meat-wagyu',
      'name': 'ستيك ريب آي واغيو ياباني A5 معتق 28 يوماً',
      'pricePerKg': 390.0,
      'wholeCarcassPrice': null,
      'weightApprox': 'قطعة ستيك 350 - 450 جم',
      'image': 'https://images.unsplash.com/photo-1558030006-450675393462?w=500',
      'origin': 'محافظة ميازاكي اليابان • رخامية لحم Marbling BMS 11+',
      'category': 'لحوم فاخرة معتقة',
    },
  ];

  final List<Map<String, dynamic>> _seafood = [
    {
      'id': 'fish-hamoor',
      'name': 'سمك هامور أحمر طازج (بحر أحمر)',
      'pricePerKg': 85.0,
      'image': 'https://images.unsplash.com/photo-1534939561126-855b8675edd7?w=500',
      'cleaning': 'تنظيف قشور + خياشيم + تقطيع جزل',
    },
    {
      'id': 'fish-shrimp',
      'name': 'روبيان جامبو طازج بحري مقاس 10-15',
      'pricePerKg': 95.0,
      'image': 'https://images.unsplash.com/photo-1565680018434-b513d5e5fd47?w=500',
      'cleaning': 'تقشير مع إبقاء الذيل + إزالة خيط الرمل',
    },
    {
      'id': 'fish-salmon',
      'name': 'فيليه سالمون نرويجي طازج سوبريم',
      'pricePerKg': 92.0,
      'image': 'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?w=500',
      'cleaning': 'فيليه خالص بدون حسك منزوع الجلد',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        backgroundColor: const Color(0xFF881337), // Luxury Maroon Butcher Red
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
              child: const Icon(Icons.restaurant_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ملحمة وبحريات الديب الفاخرة',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'ذبائح طازجة • تفصيل مخصص • إشراف بيطري MEWA 100%',
                  style: TextStyle(fontSize: 10, color: Color(0xFFFECDD3)),
                ),
              ],
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.kebab_dining_rounded, size: 18), text: 'الذبائح واللحوم البلدية'),
            Tab(icon: Icon(Icons.set_meal_rounded, size: 18), text: 'سوق الأسماك الطازجة'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMeatsTab(cart),
          _buildSeafoodTab(cart),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1: MEATS & CARCASSES WITH CUSTOM CUTTING WORKBEN
  // ===========================================================================
  Widget _buildMeatsTab(CartProvider cart) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Halal & Health Inspection Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF881337), Color(0xFF9F1239)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.15),
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
                child: const Icon(Icons.verified_user_rounded, color: Colors.amber, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'ذبح حلال محلي تحت إشراف وزارة البيئة والمياه والزراعة MEWA',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'مسلخ الرياض الآلي النموذجي • فحص بيطري دقيق لكل ذبيحة وتوصيل مبرد 2°C إلى باب منزلك.',
                      style: TextStyle(color: Color(0xFFFECDD3), fontSize: 11, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Customization Options Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.tune_rounded, color: Color(0xFF881337), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'خيارات التقطيع والتفصيل حسب رغبتك:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Cutting Style Dropdown
              const Text('طريقة التقطيع:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedCutStyle,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'تفصيل ثلاجة (قطع متوسطة للطبخ المنزلي)',
                    child: Text('تفصيل ثلاجة (قطع متوسطة للطبخ المنزلي)'),
                  ),
                  DropdownMenuItem(
                    value: 'تفصيل كبسة ومفطح (قطع كبيرة للعزائم)',
                    child: Text('تفصيل كبسة ومفطح (قطع كبيرة للعزائم)'),
                  ),
                  DropdownMenuItem(
                    value: 'تفصيل مشاوي وشيش كباب مع تقطيع الريش',
                    child: Text('تفصيل مشاوي وشيش كباب مع تقطيع الريش'),
                  ),
                  DropdownMenuItem(
                    value: 'مفروم ناعم للكفتة والبرجر',
                    child: Text('مفروم ناعم للكفتة والبرجر'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCutStyle = val);
                },
              ),
              const SizedBox(height: 14),

              // Fat Ratio Selector
              const Text('نسبة الشحم المفضلة:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedFatRatio,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'قليل الدسم 10% (Medium Lean)',
                    child: Text('قليل الدسم 10% (Medium Lean - متوازن)'),
                  ),
                  DropdownMenuItem(
                    value: 'هبر صافي بدون شحم 0% (Extra Lean)',
                    child: Text('هبر صافي بدون شحم 0% (Extra Lean للدايت)'),
                  ),
                  DropdownMenuItem(
                    value: 'دسم كلاسيك للمشاوي 25% (Rich BBQ Fat)',
                    child: Text('دسم كلاسيك للمشاوي 25% (نكهة مشاوي غنية)'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedFatRatio = val);
                },
              ),
              const SizedBox(height: 14),

              // Packaging Style
              const Text('نوع التغليف والحفظ:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedPackaging,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'تغليف سحب هواء مفرغ بالوجبة (Vacuum 1kg)',
                    child: Text('تغليف سحب هواء مفرغ بالوجبة (Vacuum 1kg) ⭐'),
                  ),
                  DropdownMenuItem(
                    value: 'أطباق لحام حراري مبردة',
                    child: Text('أطباق لحام حراري مبردة'),
                  ),
                  DropdownMenuItem(
                    value: 'كرتون الذبيحة الفاخر مع الثلج الجاف',
                    child: Text('كرتون الذبيحة الفاخر مع الثلج الجاف'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedPackaging = val);
                },
              ),
              const SizedBox(height: 14),

              // Toggles for Extras
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeTrackColor: const Color(0xFF881337).withValues(alpha: 0.5),
                activeThumbColor: const Color(0xFF881337),
                title: const Text('إرفاق الرأس والكراعين والكرشة منظفة ومغلفة مجاناً', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                subtitle: const Text('تنظيف معقم وسحب هواء للأحشاء', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                value: _includeOffalCleaned,
                onChanged: (val) => setState(() => _includeOffalCleaned = val),
              ),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeTrackColor: const Color(0xFF881337).withValues(alpha: 0.5),
                activeThumbColor: const Color(0xFF881337),
                title: const Text('إضافة تتبيلة الشواء النجدية الخاصة من الشيف مجاناً', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                subtitle: const Text('بهارات نجدية طازجة، ليمون أسود، وزيت زيتون الجوف', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                value: _addChefSpiceRub,
                onChanged: (val) => setState(() => _addChefSpiceRub = val),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Meats Catalog
        const Text(
          'قائمة اللحوم والذبائح الطازجة المتوفرة اليوم:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 10),

        ..._meats.map((meat) {
          final isWhole = meat['wholeCarcassPrice'] != null;
          final double finalPrice = isWhole
              ? (meat['wholeCarcassPrice'] as double) / _carcassPortion
              : (meat['pricePerKg'] as double);

          return Card(
            margin: const EdgeInsets.only(bottom: 14),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          meat['image'] as String,
                          width: 85,
                          height: 85,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 85,
                            height: 85,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.restaurant_rounded, color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              meat['name'] as String,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              meat['origin'] as String,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'الوزن التقديري: ${meat['weightApprox']}',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${finalPrice.toStringAsFixed(2)} ل.س',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF881337),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Portion Selector for Whole Carcasses (Full / Half / Quarter)
                  if (isWhole) ...[
                    Row(
                      children: [
                        const Text('حجم الحصة:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('ذبيحة كاملة'),
                          selected: _carcassPortion == 1,
                          onSelected: (sel) => setState(() => _carcassPortion = 1),
                          selectedColor: const Color(0xFFFECDD3),
                        ),
                        const SizedBox(width: 6),
                        ChoiceChip(
                          label: const Text('نصف ذبيحة'),
                          selected: _carcassPortion == 2,
                          onSelected: (sel) => setState(() => _carcassPortion = 2),
                          selectedColor: const Color(0xFFFECDD3),
                        ),
                        const SizedBox(width: 6),
                        ChoiceChip(
                          label: const Text('ربع ذبيحة'),
                          selected: _carcassPortion == 4,
                          onSelected: (sel) => setState(() => _carcassPortion = 4),
                          selectedColor: const Color(0xFFFECDD3),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Add to Cart Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF881337),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                      label: Text(
                        'إضافة للسلة مع التفصيل المخصص ($_selectedCutStyle)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      onPressed: () {
                        final product = ProductModel(
                          id: meat['id'] as String,
                          nameAr: '${meat['name']} ($_selectedCutStyle - $_selectedFatRatio)',
                          nameEn: meat['name'] as String,
                          price: finalPrice,
                          images: [meat['image'] as String],
                          unit: isWhole ? 'piece' : 'kg',
                        );
                        cart.addToCart(product);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('تمت إضافة ${product.nameAr} إلى السلة مع خيارات التفصيل والتغليف'),
                            backgroundColor: AppColors.freshGreen,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ===========================================================================
  // TAB 2: SEAFOOD & CLEANING
  // ===========================================================================
  Widget _buildSeafoodTab(CartProvider cart) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Fishery Freshness Notice
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFECFEFF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFA5F3FC)),
          ),
          child: const Row(
            children: [
              Icon(Icons.water_drop_rounded, color: Color(0xFF0891B2), size: 24),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'صيد يومي طازج من مرافئ البحر الأحمر والخليج العربي. تنظيف وسحب شوك مجاني حسب رغبتك.',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0E7490)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        ..._seafood.map((fish) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      fish['image'] as String,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.set_meal_rounded, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fish['name'] as String,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'التنظيف: ${fish['cleaning']}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF0284C7)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(fish['pricePerKg'] as double).toStringAsFixed(2)} ل.س / كجم',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0E7490)),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0891B2),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    onPressed: () {
                      final product = ProductModel(
                        id: fish['id'] as String,
                        nameAr: '${fish['name']} (${fish['cleaning']})',
                        nameEn: fish['name'] as String,
                        price: fish['pricePerKg'] as double,
                        images: [fish['image'] as String],
                        unit: 'kg',
                      );
                      cart.addToCart(product);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('تمت إضافة 1 كجم من ${product.nameAr} إلى السلة'),
                          backgroundColor: AppColors.freshGreen,
                        ),
                      );
                    },
                    child: const Text('طلب 1 كجم', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
