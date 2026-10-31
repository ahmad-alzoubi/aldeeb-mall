import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/recipe_model.dart';
import '../../core/models/product_model.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/providers/recipe_provider.dart';
import '../cart/cart_screen.dart';
import 'recipe_swap_sheet.dart';

class RecipeDetailSheet extends StatefulWidget {
  final RecipeModel recipe;

  const RecipeDetailSheet({super.key, required this.recipe});

  static Future<void> show(BuildContext context, RecipeModel recipe) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RecipeDetailSheet(recipe: recipe),
    );
  }

  @override
  State<RecipeDetailSheet> createState() => _RecipeDetailSheetState();
}

class _RecipeDetailSheetState extends State<RecipeDetailSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late RecipeModel _activeRecipe;
  final Set<int> _completedSteps = {};
  bool _isFavorite = false;
  bool _isAddedToCart = false;

  @override
  void initState() {
    super.initState();
    _activeRecipe = widget.recipe;
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onSwapIngredient(String ingredientId, ProductModel newProduct) {
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    recipeProvider.swapIngredient(_activeRecipe.id, ingredientId, newProduct);

    setState(() {
      final updatedList = _activeRecipe.ingredients.map((ing) {
        if (ing.id == ingredientId) {
          return ing.copyWith(
            product: newProduct,
            nameAr: newProduct.nameAr,
          );
        }
        return ing;
      }).toList();
      _activeRecipe = _activeRecipe.copyWith(ingredients: updatedList);
    });
  }

  void _toggleIngredient(int index) {
    setState(() {
      final ing = _activeRecipe.ingredients[index];
      final updated = ing.copyWith(isSelected: !ing.isSelected);
      final newList = List<RecipeIngredient>.from(_activeRecipe.ingredients);
      newList[index] = updated;
      _activeRecipe = _activeRecipe.copyWith(ingredients: newList);
    });
  }

  void _updateQuantity(int index, double newQty) {
    if (newQty < 1.0) return;
    setState(() {
      final ing = _activeRecipe.ingredients[index];
      final updated = ing.copyWith(selectedQuantity: newQty);
      final newList = List<RecipeIngredient>.from(_activeRecipe.ingredients);
      newList[index] = updated;
      _activeRecipe = _activeRecipe.copyWith(ingredients: newList);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final selectedCount = _activeRecipe.selectedIngredientsCount;
    final originalPrice = _activeRecipe.originalTotalPrice;
    final bundlePrice = _activeRecipe.bundlePrice;
    final savings = _activeRecipe.savingsAmount;

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Hero Image Header
          Stack(
            children: [
              SizedBox(
                height: 240,
                width: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: _activeRecipe.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
              Container(
                height: 240,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.6),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),

              // Top action buttons (Close, Favorite, Share)
              Positioned(
                top: 14,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.black.withValues(alpha: 0.5),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.black.withValues(alpha: 0.5),
                          child: IconButton(
                            icon: Icon(
                              _isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: _isFavorite ? AppColors.secondary : Colors.white,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() => _isFavorite = !_isFavorite);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(_isFavorite ? 'تمت إضافة الوصفة للمفضلة ❤️' : 'تمت الإزالة من المفضلة'),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          backgroundColor: Colors.black.withValues(alpha: 0.5),
                          child: IconButton(
                            icon: const Icon(Icons.share_outlined, color: Colors.white, size: 20),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('تم نسخ رابط الوصفة للمشاركة!'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Discount badge & Category
              PositionedDirectional(
                bottom: 80,
                start: 16,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'وفر ${_activeRecipe.discountPercent.toInt()}% على باقة المقادير',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _activeRecipe.category,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              // Title and Rating at bottom of cover
              Positioned(
                bottom: 14,
                left: 16,
                right: 16,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _activeRecipe.titleAr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            _activeRecipe.titleEn,
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: AppColors.accent, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${_activeRecipe.rating} (${_activeRecipe.reviewsCount})',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Key Highlights Row (Time, Servings, Difficulty, Calories)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFFF8FAFC),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _metricItem(Icons.timer_outlined, 'التحضير', _activeRecipe.prepTime),
                _metricItem(Icons.group_outlined, 'الكمية', _activeRecipe.servings),
                _metricItem(Icons.trending_up, 'الصعوبة', _activeRecipe.difficulty),
                _metricItem(Icons.local_fire_department_outlined, 'السعرات', '${_activeRecipe.calories} كالوري'),
              ],
            ),
          ),

          // Dietary & Allergen Pills Banner
          if (_activeRecipe.dietaryTags.isNotEmpty || _activeRecipe.allergens.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ..._activeRecipe.dietaryTags.map((tag) => Container(
                          margin: const EdgeInsetsDirectional.only(end: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.freshGreenLight,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.freshGreen.withValues(alpha: 0.3)),
                          ),
                          child: Text(tag, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.freshGreen)),
                        )),
                    ..._activeRecipe.allergens.map((alg) => Container(
                          margin: const EdgeInsetsDirectional.only(end: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.warning_amber_rounded, size: 12, color: AppColors.secondary),
                              const SizedBox(width: 4),
                              Text('يحتوي: $alg', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ),

          // Tab Bar
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.shopping_basket_outlined, size: 16),
                    const SizedBox(width: 6),
                    Text('المقادير والتخصيص (${_activeRecipe.ingredients.length})'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.format_list_bulleted, size: 16),
                    const SizedBox(width: 6),
                    Text('خطوات الطبخ (${_activeRecipe.steps.length})'),
                  ],
                ),
              ),
            ],
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Customizer
                _buildIngredientsTab(context),

                // Tab 2: Steps
                _buildStepsTab(),
              ],
            ),
          ),

          // Sticky Bottom Checkout / Add to Cart Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Success banner if added
                  if (_isAddedToCart)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.freshGreenLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.freshGreen.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: AppColors.freshGreen, size: 18),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'تمت إضافة المقادير بنجاح إلى سلتك!',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.freshGreen),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const CartScreen()),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              backgroundColor: AppColors.freshGreen,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            child: const Text('إتمام الطلب 🛒', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),

                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${bundlePrice.toStringAsFixed(2)} ل.س',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              if (savings > 0)
                                Text(
                                  '${originalPrice.toStringAsFixed(2)} ل.س',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                            ],
                          ),
                          Text(
                            selectedCount > 0
                                ? 'باقة $selectedCount مقادير مخصصة (وفرت ${savings.toStringAsFixed(2)} ل.س)'
                                : 'لم يتم اختيار أي مكون',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: selectedCount > 0 ? AppColors.freshGreen : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),

                      // Secondary: Add to Cart & stay
                      OutlinedButton.icon(
                        onPressed: selectedCount == 0
                            ? null
                            : () {
                                for (final ing in _activeRecipe.ingredients) {
                                  if (ing.isSelected) {
                                    cart.addToCart(ing.product, quantity: ing.selectedQuantity);
                                  }
                                }
                                setState(() => _isAddedToCart = true);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('✓ تمت إضافة $selectedCount مقادير إلى سلتك!'),
                                    backgroundColor: AppColors.primary,
                                    action: SnackBarAction(
                                      label: 'إتمام الطلب 🛒',
                                      textColor: AppColors.accent,
                                      onPressed: () {
                                        Navigator.pop(context);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => const CartScreen()),
                                        );
                                      },
                                    ),
                                    duration: const Duration(seconds: 4),
                                  ),
                                );
                              },
                        icon: Icon(
                          _isAddedToCart ? Icons.check : Icons.add_shopping_cart,
                          size: 16,
                          color: _isAddedToCart ? AppColors.freshGreen : AppColors.primary,
                        ),
                        label: Text(
                          _isAddedToCart ? 'أضيفت للسلة ✓' : 'حفظ بالسلة',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _isAddedToCart ? AppColors.freshGreen : AppColors.primary,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: _isAddedToCart ? AppColors.freshGreen : AppColors.primary),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Primary: Buy Now / Instant Checkout
                      ElevatedButton.icon(
                        onPressed: selectedCount == 0
                            ? null
                            : () {
                                for (final ing in _activeRecipe.ingredients) {
                                  if (ing.isSelected) {
                                    cart.addToCart(ing.product, quantity: ing.selectedQuantity);
                                  }
                                }
                                Navigator.pop(context); // Close sheet
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const CartScreen()),
                                );
                              },
                        icon: const Icon(Icons.flash_on_rounded, size: 16),
                        label: const Text(
                          'اطلب الآن ⚡',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.textPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Helper hint banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
          ),
          child: const Row(
            children: [
              Icon(Icons.touch_app_outlined, size: 20, color: AppColors.primary),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'أزل علامة الصح عن المقادير المتوفرة لديك بالمنزل، أو اضغط "تبديل المكون 🔄" لاختيار بديل آخر!',
                  style: TextStyle(fontSize: 11, color: AppColors.textPrimary, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Ingredients List
        ..._activeRecipe.ingredients.asMap().entries.map((entry) {
          final idx = entry.key;
          final ing = entry.value;
          final isSelected = ing.isSelected;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppColors.border : Colors.grey.shade300,
              ),
              boxShadow: isSelected ? AppColors.cardShadow : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Checkbox
                    Checkbox(
                      value: isSelected,
                      activeColor: AppColors.primary,
                      onChanged: (_) => _toggleIngredient(idx),
                    ),

                    // Thumbnail
                    Opacity(
                      opacity: isSelected ? 1.0 : 0.4,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl: ing.product.firstImage,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Name and quantity
                    Expanded(
                      child: Opacity(
                        opacity: isSelected ? 1.0 : 0.5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ing.nameAr,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                decoration: isSelected ? null : TextDecoration.lineThrough,
                                color: isSelected ? AppColors.textPrimary : AppColors.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'الكمية الموصى بها: ${ing.quantityNeeded}',
                              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Price
                    Opacity(
                      opacity: isSelected ? 1.0 : 0.4,
                      child: Text(
                        '${ing.totalPrice.toStringAsFixed(2)} ل.س',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),

                if (isSelected) ...[
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Smart Swap Button
                      OutlinedButton.icon(
                        onPressed: () {
                          RecipeSwapSheet.show(
                            context,
                            ingredient: ing,
                            onSwap: (newProd) => _onSwapIngredient(ing.id, newProd),
                          );
                        },
                        icon: const Icon(Icons.swap_horiz_rounded, size: 16, color: AppColors.primary),
                        label: const Text('تبديل المكون 🔄', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary, width: 1.2),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),

                      // Quantity Stepper
                      Row(
                        children: [
                          const Text('العبوات:', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          const SizedBox(width: 8),
                          _stepperBtn(Icons.remove, () => _updateQuantity(idx, ing.selectedQuantity - 1.0)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '${ing.selectedQuantity.toInt()}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          _stepperBtn(Icons.add, () => _updateQuantity(idx, ing.selectedQuantity + 1.0)),
                        ],
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStepsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.freshGreenLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: AppColors.freshGreen, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'أثناء التحضير، يمكنك وضع علامة (✓) على كل خطوة تنهيها لتتبع مرحلتك بسهولة!',
                  style: TextStyle(fontSize: 11, color: Colors.green.shade900),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ..._activeRecipe.steps.asMap().entries.map((entry) {
          final idx = entry.key;
          final step = entry.value;
          final isDone = _completedSteps.contains(idx);

          return GestureDetector(
            onTap: () {
              setState(() {
                if (isDone) {
                  _completedSteps.remove(idx);
                } else {
                  _completedSteps.add(idx);
                }
              });
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDone ? const Color(0xFFF1F5F9) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDone ? AppColors.freshGreen : AppColors.border,
                  width: isDone ? 1.5 : 1.0,
                ),
                boxShadow: isDone ? null : AppColors.cardShadow,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: isDone ? AppColors.freshGreen : AppColors.primaryLight.withValues(alpha: 0.15),
                    child: isDone
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : Text(
                            '${idx + 1}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      step,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                        color: isDone ? AppColors.textMuted : AppColors.textPrimary,
                      ),
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

  Widget _metricItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textPrimary)),
        Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
      ],
    );
  }

  Widget _stepperBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 14, color: AppColors.textPrimary),
      ),
    );
  }
}
