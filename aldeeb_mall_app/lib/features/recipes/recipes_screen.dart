import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/recipe_model.dart';
import '../../core/models/product_model.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/services/supabase_service.dart';
import '../../core/utils/responsive.dart';
import '../cart/cart_screen.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  String _selectedCategory = 'الكل';
  final Set<String> _addedRecipes = {};

  List<RecipeModel> _getRecipes(List<ProductModel> products) {
    final p1 = products.isNotEmpty ? products[0] : _fallbackProduct('1', 'موز كافنديش طازج', 4.95);
    final p2 = products.length > 1 ? products[1] : _fallbackProduct('2', 'تفاح رويال جالا', 7.50);
    final p3 = products.length > 2 ? products[2] : _fallbackProduct('3', 'طماطم مزارع محلية', 3.75);
    final p4 = products.length > 3 ? products[3] : _fallbackProduct('4', 'حليب المراعي 2 لتر', 11.00);
    final p5 = products.length > 4 ? products[4] : _fallbackProduct('5', 'دجاج التنمية طازج مبرد', 16.75);
    final p6 = products.length > 5 ? products[5] : _fallbackProduct('6', 'جبنة بوك كريمية', 14.50);

    return [
      RecipeModel(
        id: 'rcp-1',
        titleAr: 'كبسة الدجاج الخليجية المتبلة الفاخرة',
        titleEn: 'Traditional Gulf Spiced Chicken Kabsa',
        category: 'أطباق رئيسية',
        prepTime: '45 دقيقة',
        servings: '4 أشخاص',
        difficulty: 'سهل',
        imageUrl: 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?auto=format&fit=crop&w=600&q=80',
        discountPercent: 15,
        steps: [
          'يغسل الدجاج جيداً ويتبل بمزيج بهارات الكبسة والهيل واللومي.',
          'يشوح البصل والطماطم المفرومة في الزيت حتى تذبل وتتصاعد رائحتها.',
          'يضاف الدجاج ويقلب حتى يكتسب لوناً ذهبياً، ثم يضاف الماء الساخن حتى ينضج.',
          'يسلق أرز البسمتي في مرق الدجاج حتى يتشرب النكهة، ويقدم مزيناً بالمكسرات.',
        ],
        ingredients: [
          RecipeIngredient(nameAr: 'دجاج التنمية طازج مبرد 1000 غرام', quantityNeeded: '1 حبة', product: p5),
          RecipeIngredient(nameAr: 'طماطم مزارع محلية قطاف الصباح', quantityNeeded: '1 كجم', product: p3),
          RecipeIngredient(nameAr: 'حليب المراعي كامل الدسم طازج', quantityNeeded: '1 زجاجة للطهي', product: p4),
        ],
      ),
      RecipeModel(
        id: 'rcp-2',
        titleAr: 'سلطة الفيتا المتوسطية بالطماطم والزيتون',
        titleEn: 'Greek Mediterranean Salad with Cheese',
        category: 'سلطات ومقبلات',
        prepTime: '15 دقيقة',
        servings: '2 أشخاص',
        difficulty: 'سريع جداً',
        imageUrl: 'https://images.unsplash.com/photo-1540420773420-3366772f4999?auto=format&fit=crop&w=600&q=80',
        discountPercent: 12,
        steps: [
          'تقطع الطماطم الطازجة والخيار إلى مكعبات متساوية الحجم.',
          'توضع مكعبات الجبنة البيضاء الكريمية فوق الخضار.',
          'ترش أوراق الأوريغانو الجافة وزيت الزيتون البكر وعصير الليمون.',
        ],
        ingredients: [
          RecipeIngredient(nameAr: 'طماطم مزارع محلية قطاف الصباح', quantityNeeded: '500 غرام', product: p3),
          RecipeIngredient(nameAr: 'جبنة بوك كريمية بيضاء أصلية', quantityNeeded: '1 عبوة', product: p6),
          RecipeIngredient(nameAr: 'تفاح رويال جالا إيطالي مقرمش', quantityNeeded: '2 حبة للتحلية', product: p2),
        ],
      ),
      RecipeModel(
        id: 'rcp-3',
        titleAr: 'سموذي الموز والحليب البروتيني المنعش',
        titleEn: 'Vitality Fresh Banana Protein Shake',
        category: 'فطور ومشروبات',
        prepTime: '5 دقائق',
        servings: '2 كوب',
        difficulty: 'سهل جداً',
        imageUrl: 'https://images.unsplash.com/photo-1553530666-ba11a7da3888?auto=format&fit=crop&w=600&q=80',
        discountPercent: 20,
        steps: [
          'يقشر الموز الطازج ويقطع إلى حلقات.',
          'يوضع الموز في الخلاط الكهربائي مع حليب المراعي البارد.',
          'يخفق المزيج لمدة دقيقة واحدة حتى يتجانس ويصبح كريمياً.',
        ],
        ingredients: [
          RecipeIngredient(nameAr: 'موز فلبيني طازج كافنديش درجة أولى', quantityNeeded: '1 كجم', product: p1),
          RecipeIngredient(nameAr: 'حليب المراعي كامل الدسم طازج 2 لتر', quantityNeeded: '1 زجاجة', product: p4),
          RecipeIngredient(nameAr: 'تفاح رويال جالا إيطالي فاخر', quantityNeeded: '2 حبة مقرمشة', product: p2),
        ],
      ),
    ];
  }

  ProductModel _fallbackProduct(String id, String name, double price) {
    return ProductModel(
      id: id,
      nameAr: name,
      nameEn: name,
      price: price,
      images: const ['https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=400&q=80'],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final allProducts = SupabaseService.defaultProducts;
    final recipes = _getRecipes(allProducts);
    final isDesktop = Responsive.isDesktop(context);

    final filteredRecipes = _selectedCategory == 'الكل'
        ? recipes
        : recipes.where((r) => r.category == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('طباخ الديب الذكي | وصفات ومقادير'),
        actions: [
          IconButton(
            icon: Badge(
              label: Text('${cart.itemCount}'),
              isLabelVisible: cart.itemCount > 0,
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: MaxWidthContainer(
          maxWidth: 1100,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), AppColors.primaryDark],
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
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'ميزة حصرية | Cook with Aldeeb',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'اختر وصفتك المفضلة، وأضف جميع مقاديرها الطازجة لسلتك بضغطة زر واحدة!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'جميع المكونات متوفرة في أقرب مستودع مظلم وتصلك مبردة خلال 15 دقيقة مع خصم 15% على الباقة.',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    if (isDesktop) ...[
                      const SizedBox(width: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.soup_kitchen_rounded, size: 64, color: AppColors.accent),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Category Filter Pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['الكل', 'أطباق رئيسية', 'سلطات ومقبلات', 'فطور ومشروبات'].map((cat) {
                    final isSel = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: isSel,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isSel ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _selectedCategory = cat);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // Recipe Cards Grid
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredRecipes.length,
                itemBuilder: (ctx, index) {
                  final recipe = filteredRecipes[index];
                  final isAdded = _addedRecipes.contains(recipe.id);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppColors.cardShadow,
                      border: Border.all(color: AppColors.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Recipe Header Image with Floating Chips
                        Stack(
                          children: [
                            SizedBox(
                              height: 220,
                              width: double.infinity,
                              child: CachedNetworkImage(
                                imageUrl: recipe.imageUrl,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Container(
                              height: 220,
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
                            PositionedDirectional(
                              top: 14,
                              start: 14,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'وفر ${recipe.discountPercent.toInt()}% على الباقة',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 14,
                              left: 16,
                              right: 16,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    recipe.titleAr,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                    ),
                                  ),
                                  Text(
                                    recipe.titleEn,
                                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Badges: Time, Servings, Difficulty
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                          child: Row(
                            children: [
                              _infoBadge(Icons.timer_outlined, recipe.prepTime),
                              const SizedBox(width: 8),
                              _infoBadge(Icons.group_outlined, recipe.servings),
                              const SizedBox(width: 8),
                              _infoBadge(Icons.trending_up, recipe.difficulty),
                            ],
                          ),
                        ),

                        // Ingredients Checklist Section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'مقادير الوصفة المتوفرة بالمتجر:',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 10),
                              ...recipe.ingredients.map((ing) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: CachedNetworkImage(
                                          imageUrl: ing.product.firstImage,
                                          width: 38,
                                          height: 38,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              ing.nameAr,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              'الكمية الموصى بها: ${ing.quantityNeeded}',
                                              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '${ing.product.price.toStringAsFixed(2)} د.إ',
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.primary),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),

                        // Pricing & 1-Click Auto-Cart Action Bar
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF8FAFC),
                            border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '${recipe.bundlePrice.toStringAsFixed(2)} د.إ',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${recipe.originalTotalPrice.toStringAsFixed(2)} د.إ',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textMuted,
                                          decoration: TextDecoration.lineThrough,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Text('سعر باقة المقادير بالكامل', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                ],
                              ),
                              ElevatedButton.icon(
                                onPressed: isAdded
                                    ? null
                                    : () {
                                        for (final ing in recipe.ingredients) {
                                          cart.addToCart(ing.product);
                                        }
                                        setState(() => _addedRecipes.add(recipe.id));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('✓ تمت إضافة جميع مقادير ${recipe.titleAr} إلى السلة بخصم الباقة!'),
                                            backgroundColor: AppColors.primary,
                                            duration: const Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                icon: Icon(isAdded ? Icons.check_circle : Icons.add_shopping_cart, size: 18),
                                label: Text(
                                  isAdded ? 'تمت الإضافة للسلة' : 'أضف المقادير كاملة للسلة',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isAdded ? AppColors.freshGreen : AppColors.primary,
                                  foregroundColor: Colors.white,
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
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
