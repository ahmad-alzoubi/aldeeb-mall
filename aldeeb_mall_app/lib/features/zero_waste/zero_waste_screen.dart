import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/product_model.dart';
import '../../core/providers/cart_provider.dart';

class NearExpiryItem {
  final ProductModel product;
  final int daysLeft;
  final double rescueDiscountPercent;
  final double clearancePrice;
  final String conditionNote;
  final int unitsRemaining;

  const NearExpiryItem({
    required this.product,
    required this.daysLeft,
    required this.rescueDiscountPercent,
    required this.clearancePrice,
    required this.conditionNote,
    required this.unitsRemaining,
  });
}

class ZeroWasteScreen extends StatefulWidget {
  const ZeroWasteScreen({super.key});

  @override
  State<ZeroWasteScreen> createState() => _ZeroWasteScreenState();
}

class _ZeroWasteScreenState extends State<ZeroWasteScreen> {
  String _selectedCategory = 'الكل';
  final List<String> _categories = [
    'الكل',
    'مخبوزات طازجة',
    'ألبان وأجبان',
    'فواكه وخضار',
    'لحوم ودواجن',
    'عصائر طازجة',
  ];

  late final List<NearExpiryItem> _rescueItems;

  @override
  void initState() {
    super.initState();
    _initRescueItems();
  }

  void _initRescueItems() {
    _rescueItems = [
      NearExpiryItem(
        product: const ProductModel(
          id: 'ZW-001',
          nameAr: 'كرواسون الزبدة الفرنسية الفاخر (علبة 4 قطع)',
          nameEn: 'Fresh French Butter Croissant (4 pcs)',
          descriptionAr: 'كرواسون طازج مخبوز اليوم فجراً في مخابز الديب، مثالي للإفطار الفوري',
          price: 18.0,
          images: ['https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=400&q=80'],
          categoryId: 'مخبوزات طازجة',
          stockQuantity: 6,
        ),
        daysLeft: 1,
        rescueDiscountPercent: 65,
        clearancePrice: 6.30,
        conditionNote: 'مخبوز اليوم فجراً - صلاحية تنتهي غداً صباحاً',
        unitsRemaining: 6,
      ),
      NearExpiryItem(
        product: const ProductModel(
          id: 'ZW-002',
          nameAr: 'حليب المراعي طازج كامل الدسم (2 لتر)',
          nameEn: 'Almarai Fresh Whole Milk 2L',
          descriptionAr: 'حليب بقر طازج مبستر، حفظ مبرد 4 درجات مئوية',
          price: 11.5,
          images: ['https://images.unsplash.com/photo-1550583724-b2692b85b150?w=400&q=80'],
          categoryId: 'ألبان وأجبان',
          stockQuantity: 12,
        ),
        daysLeft: 2,
        rescueDiscountPercent: 50,
        clearancePrice: 5.75,
        conditionNote: 'باقي يومان على الصلاحية - ممتاز للاستهلاك الفوري أو الطهي',
        unitsRemaining: 12,
      ),
      NearExpiryItem(
        product: const ProductModel(
          id: 'ZW-003',
          nameAr: 'فراولة القصيم الطازجة عالي الحلاوة (صندوق 500غ)',
          nameEn: 'Qassim Sweet Fresh Strawberries 500g',
          descriptionAr: 'فراولة ناضجة جداً وحلوة المذاق، مثالية للعصائر الفورية والحلويات',
          price: 16.0,
          images: ['https://images.unsplash.com/photo-1464965911861-746a04b4bca6?w=400&q=80'],
          categoryId: 'فواكه وخضار',
          stockQuantity: 8,
        ),
        daysLeft: 2,
        rescueDiscountPercent: 55,
        clearancePrice: 7.20,
        conditionNote: 'ناضجة 100% - مثالية للعصائر وسموذي الإفطار',
        unitsRemaining: 8,
      ),
      NearExpiryItem(
        product: const ProductModel(
          id: 'ZW-004',
          nameAr: 'لبنة تركية طازجة بينار (400غ)',
          nameEn: 'Pinar Fresh Turkish Labneh 400g',
          descriptionAr: 'لبنة كاملة الدسم ناعمة القوام',
          price: 15.5,
          images: ['https://images.unsplash.com/photo-1528750997573-59b89d56f4f7?w=400&q=80'],
          categoryId: 'ألبان وأجبان',
          stockQuantity: 5,
        ),
        daysLeft: 3,
        rescueDiscountPercent: 40,
        clearancePrice: 9.30,
        conditionNote: 'باقي 3 أيام على الصلاحية - مبردة ومحكمة الإغلاق',
        unitsRemaining: 5,
      ),
      NearExpiryItem(
        product: const ProductModel(
          id: 'ZW-005',
          nameAr: 'صدور دجاج التنمية طازجة (450غ)',
          nameEn: 'Tanmiah Fresh Chicken Breasts 450g',
          descriptionAr: 'دجاج وطني مبرد عالي البروتين',
          price: 21.0,
          images: ['https://images.unsplash.com/photo-1604503468506-a8da13d82791?w=400&q=80'],
          categoryId: 'لحوم ودواجن',
          stockQuantity: 4,
        ),
        daysLeft: 1,
        rescueDiscountPercent: 60,
        clearancePrice: 8.40,
        conditionNote: 'صلاحية 24 ساعة - صالحة للطبخ اليوم أو التجميد المنزلي فوراً',
        unitsRemaining: 4,
      ),
      NearExpiryItem(
        product: const ProductModel(
          id: 'ZW-006',
          nameAr: 'عصير برتقال معصور طازج بدون سكر (1 لتر)',
          nameEn: 'Freshly Squeezed Orange Juice 1L',
          descriptionAr: 'عصير طبيعي 100% معصور في قسم الفواكه بالديب مول',
          price: 14.0,
          images: ['https://images.unsplash.com/photo-1613478223719-2ab802602423?w=400&q=80'],
          categoryId: 'عصائر طازجة',
          stockQuantity: 9,
        ),
        daysLeft: 1,
        rescueDiscountPercent: 50,
        clearancePrice: 7.00,
        conditionNote: 'معصور اليوم - استهلاك خلال 24-48 ساعة',
        unitsRemaining: 9,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    final filteredItems = _selectedCategory == 'الكل'
        ? _rescueItems
        : _rescueItems.where((i) => i.product.categoryId == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ركن إنقاذ الغذاء والتخفيض الذكي ⏳',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'وفر حتى 70% وساهم في تقليل الهدر الغذائي Zero Food Waste',
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
          // Hero Impact Banner
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF047857), Color(0xFF065F46), Color(0xFF064E3B)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF047857).withValues(alpha: 0.3),
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.bolt_rounded, color: AppColors.textPrimary, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'عروض الإنقاذ السريعة 70% OFF',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'تحديث فوري للمخزون',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'جودة ممتازة وسعر استثنائي يحمي البيئة',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'منتجات طازجة ومفحوصة تماماً، اقترب موعد صلاحيتها (خلال 24-72 ساعة). نبيعها بنصف السعر وأقل لضمان عدم إتلافها.',
                    style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  // Guarantee Pill
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.verified_user_rounded, color: AppColors.accent, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'ضمان الديب الذهبي: جميع المنتجات صالحة وآمنة 100% تحت إشراف هيئة الغذاء والدواء SFDA.',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Categories Strip
          SliverToBoxAdapter(
            child: SizedBox(
              height: 44,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (context, idx) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final cat = _categories[idx];
                  final isSelected = cat == _selectedCategory;
                  return InkWell(
                    onTap: () => setState(() => _selectedCategory = cat),
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
                          cat,
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

          // Items List
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = filteredItems[index];
                  final isInCart = cart.items.containsKey(item.product.id);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: item.daysLeft == 1 ? Colors.red.shade200 : Colors.grey.shade200,
                      ),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image with Discount Tag
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: item.product.firstImage,
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(color: Colors.grey.shade200),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade600,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '-${item.rescueDiscountPercent.toInt()}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),

                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.product.nameAr,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),

                              // Expiry Notice
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: item.daysLeft == 1 ? Colors.red.shade50 : Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: item.daysLeft == 1 ? Colors.red.shade200 : Colors.amber.shade200,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.access_time_filled_rounded,
                                      size: 13,
                                      color: item.daysLeft == 1 ? Colors.red.shade700 : Colors.amber.shade900,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      item.daysLeft == 1 ? 'متبقي يوم واحد فقط!' : 'متبقي يومان على الصلاحية',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: item.daysLeft == 1 ? Colors.red.shade700 : Colors.amber.shade900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.conditionNote,
                                style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                              ),
                              const SizedBox(height: 8),

                              // Pricing & Add to Cart
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${item.clearancePrice.toStringAsFixed(2)} ل.س',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 15,
                                          color: Colors.green,
                                        ),
                                      ),
                                      Text(
                                        '${item.product.price.toStringAsFixed(2)} ل.س',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                          decoration: TextDecoration.lineThrough,
                                        ),
                                      ),
                                    ],
                                  ),

                                  ElevatedButton.icon(
                                    onPressed: () {
                                      final discountedProduct = item.product.copyWith(
                                        price: item.clearancePrice,
                                      );
                                      cart.addToCart(discountedProduct);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('تمت إضافة "${item.product.nameAr}" بسعر التخفيض الذكي!'),
                                          backgroundColor: AppColors.freshGreen,
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                    icon: Icon(
                                      isInCart ? Icons.check_circle_rounded : Icons.shopping_basket_rounded,
                                      size: 16,
                                      color: isInCart ? Colors.white : AppColors.textPrimary,
                                    ),
                                    label: Text(
                                      isInCart ? 'أضيف للسلة' : 'إنقاذ وشراء',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: isInCart ? Colors.white : AppColors.textPrimary,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isInCart ? AppColors.freshGreen : AppColors.accent,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      elevation: 0,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
                childCount: filteredItems.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }
}
