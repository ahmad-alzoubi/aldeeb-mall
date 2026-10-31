import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/recipe_model.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/providers/recipe_provider.dart';
import '../../core/utils/responsive.dart';
import '../cart/cart_screen.dart';
import 'recipe_detail_sheet.dart';
import 'recipe_filter_sheet.dart';
import 'add_recipe_dialog.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _quickAddedRecipeIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showNewCategoryDialog(BuildContext context, RecipeProvider recipeProvider) {
    final catController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.create_new_folder_outlined, color: AppColors.primary),
              SizedBox(width: 8),
              Text('إضافة قسم وتصنيف جديد', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'أدخل اسم القسم الجديد الذي ترغب بإضافته لقسم الوصفات (مثال: وصفات كيتو، حلويات العيد، عصائر صيفية):',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: catController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'اسم القسم الجديد...',
                  hintStyle: const TextStyle(fontSize: 12),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                final text = catController.text.trim();
                if (text.isNotEmpty) {
                  recipeProvider.addNewCategory(text);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✓ تم إضافة قسم "$text" بنجاح!'),
                      backgroundColor: AppColors.freshGreen,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('إضافة القسم'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final recipeProvider = Provider.of<RecipeProvider>(context);
    final isDesktop = Responsive.isDesktop(context);
    final filteredRecipes = recipeProvider.filteredRecipes;
    final categories = recipeProvider.categories;
    final activeFiltersCount = recipeProvider.activeFiltersCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.soup_kitchen_rounded, color: AppColors.accent, size: 24),
            SizedBox(width: 8),
            Text('طباخ الديب الذكي | وصفات ومقادير'),
          ],
        ),
        actions: [
          // Add custom recipe button in AppBar
          TextButton.icon(
            onPressed: () => AddRecipeDialog.show(context),
            icon: const Icon(Icons.add_circle_outline, size: 16, color: Colors.white),
            label: const Text('ابتكار وصفة', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
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
          maxWidth: 1200,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
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
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'توصيل مبرد خلال 15 دقيقة ⚡',
                                  style: TextStyle(fontSize: 11, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'اختر وصفتك، خصص مقاديرها، وبدّل أي منتج بلمسة واحدة!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'تصفح وصفات الطبخ، المشروبات، الحلويات، والفطور. أزل ما لديك في البيت واستبدل أي منتج ببديل نباتي أو صحي بخصم باقة يصل إلى 20%.',
                            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => RecipeFilterSheet.show(context),
                                icon: const Icon(Icons.tune_rounded, size: 16),
                                label: Text(
                                  activeFiltersCount > 0 ? 'الفلاتر النشطة ($activeFiltersCount)' : 'تصفية ذكية للمقادير',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  foregroundColor: AppColors.textPrimary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => AddRecipeDialog.show(context),
                                icon: const Icon(Icons.add, size: 16, color: Colors.white),
                                label: const Text('إضافة وصفة جديدة', style: TextStyle(color: Colors.white, fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.white54),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (isDesktop) ...[
                      const SizedBox(width: 24),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.soup_kitchen_rounded, size: 80, color: AppColors.accent),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Search Bar with Filter Button
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => recipeProvider.setSearchQuery(val),
                      decoration: InputDecoration(
                        hintText: 'ابحث عن وصفة، مكون (دجاج، سلمون، أرز...)، أو تصنيف...',
                        hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
                        suffixIcon: recipeProvider.searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  recipeProvider.setSearchQuery('');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: activeFiltersCount > 0 ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: activeFiltersCount > 0 ? AppColors.primary : AppColors.border,
                          ),
                          boxShadow: AppColors.cardShadow,
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.tune_rounded,
                            color: activeFiltersCount > 0 ? Colors.white : AppColors.textPrimary,
                          ),
                          tooltip: 'فلاتر متقدمة',
                          onPressed: () => RecipeFilterSheet.show(context),
                        ),
                      ),
                      if (activeFiltersCount > 0)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: CircleAvatar(
                            radius: 9,
                            backgroundColor: AppColors.secondary,
                            child: Text(
                              '$activeFiltersCount',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Categories Row (with + Add Category Button at the end)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...categories.map((cat) {
                      final isSel = recipeProvider.selectedCategory == cat;
                      final count = cat == 'الكل'
                          ? recipeProvider.allRecipes.length
                          : recipeProvider.allRecipes.where((r) => r.category == cat).length;

                      return Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_getCategoryIcon(cat), size: 14, color: isSel ? Colors.white : AppColors.primary),
                              const SizedBox(width: 6),
                              Text('$cat ($count)'),
                            ],
                          ),
                          selected: isSel,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          onSelected: (val) {
                            if (val) recipeProvider.setSelectedCategory(cat);
                          },
                        ),
                      );
                    }),

                    // "+ Add Category" Chip
                    ActionChip(
                      avatar: const Icon(Icons.add_circle, size: 16, color: AppColors.primary),
                      label: const Text('قسم جديد +', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.primary, width: 1.2),
                      onPressed: () => _showNewCategoryDialog(context, recipeProvider),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Active Filters Dismissable Chips Row
              if (activeFiltersCount > 0) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text('الفلاتر النشطة:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                    if (recipeProvider.isPriceFilterActive)
                      _activeFilterPill(
                        'السعر: حتى ${recipeProvider.maxPrice.toInt()} ل.س',
                        onClear: () => recipeProvider.clearPriceFilter(),
                      ),
                    ...recipeProvider.excludedAllergens.map((alg) => _activeFilterPill(
                          'بدون $alg',
                          onClear: () => recipeProvider.toggleAllergenExclusion(alg),
                        )),
                    ...recipeProvider.selectedDietaryTags.map((tag) => _activeFilterPill(
                          tag,
                          onClear: () => recipeProvider.toggleDietaryTag(tag),
                        )),
                    if (recipeProvider.maxPrepTimeMinutes != null)
                      _activeFilterPill(
                        'أقل من ${recipeProvider.maxPrepTimeMinutes} دقيقة',
                        onClear: () => recipeProvider.setMaxPrepTime(null),
                      ),
                    if (recipeProvider.selectedDifficulty != null)
                      _activeFilterPill(
                        recipeProvider.selectedDifficulty!,
                        onClear: () => recipeProvider.setDifficulty(null),
                      ),
                    TextButton(
                      onPressed: () => recipeProvider.resetFilters(),
                      child: const Text('مسح الكل', style: TextStyle(fontSize: 11, color: AppColors.secondary)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ],

              // Count & Quick Sort Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'عرض ${filteredRecipes.length} وصفة متوفرة',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                  ),
                  InkWell(
                    onTap: () => RecipeFilterSheet.show(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.sort_rounded, size: 16, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            _getSortLabel(recipeProvider.sortBy),
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Empty State
              if (filteredRecipes.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
                  margin: const EdgeInsets.only(top: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.soup_kitchen_outlined, size: 56, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      const Text(
                        'لا توجد وصفات تطابق خيارات البحث أو التصفية الحالية',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'جرّب مسح الفلاتر أو كتابة اسم وصفة أخرى.',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => recipeProvider.resetFilters(),
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('إعادة ضبط الفلاتر'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              else
                // Recipes Cards Grid
                LayoutBuilder(
                  builder: (ctx, constraints) {
                    final isWide = constraints.maxWidth >= 900;
                    if (isWide) {
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredRecipes.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 24,
                          childAspectRatio: 0.88,
                        ),
                        itemBuilder: (ctx, idx) => _buildRecipeCard(ctx, filteredRecipes[idx], cart),
                      );
                    } else {
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredRecipes.length,
                        itemBuilder: (ctx, idx) => Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: _buildRecipeCard(ctx, filteredRecipes[idx], cart),
                        ),
                      );
                    }
                  },
                ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecipeCard(BuildContext context, RecipeModel recipe, CartProvider cart) {
    final isQuickAdded = _quickAddedRecipeIds.contains(recipe.id);

    return Container(
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
          // Recipe Header Image with Badges
          GestureDetector(
            onTap: () => RecipeDetailSheet.show(context, recipe),
            child: Stack(
              children: [
                SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: CachedNetworkImage(
                    imageUrl: recipe.imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.75),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.3),
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),

                // Top Discount Badge
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

                // Category & Rating
                PositionedDirectional(
                  top: 14,
                  end: 14,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: AppColors.accent, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              '${recipe.rating}',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          recipe.category,
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

                // Title & Subtitle at bottom of image
                Positioned(
                  bottom: 12,
                  left: 14,
                  right: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.titleAr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        recipe.titleEn,
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Badges: Time, Servings, Difficulty, Calories
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                _infoBadge(Icons.timer_outlined, recipe.prepTime),
                const SizedBox(width: 6),
                _infoBadge(Icons.group_outlined, recipe.servings),
                const SizedBox(width: 6),
                _infoBadge(Icons.local_fire_department_outlined, '${recipe.calories} كالوري'),
                const Spacer(),
                Text(
                  '${recipe.ingredients.length} مقادير',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // Ingredients Avatars Row Preview
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Row(
              children: [
                ...recipe.ingredients.take(4).map((ing) {
                  return Container(
                    margin: const EdgeInsetsDirectional.only(end: 6),
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: CachedNetworkImage(
                        imageUrl: ing.product.firstImage,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                }),
                if (recipe.ingredients.length > 4)
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '+${recipe.ingredients.length - 4}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                    ),
                  ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => RecipeDetailSheet.show(context, recipe),
                  icon: const Icon(Icons.tune, size: 14, color: AppColors.primary),
                  label: const Text('تخصيص وبدائل', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Bottom Pricing & Actions Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                          '${recipe.bundlePrice.toStringAsFixed(2)} ل.س',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${recipe.originalTotalPrice.toStringAsFixed(2)} ل.س',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ),
                    const Text('سعر باقة المقادير بالكامل', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                  ],
                ),
                Row(
                  children: [
                    // Customize / Order Button
                    ElevatedButton(
                      onPressed: () => RecipeDetailSheet.show(context, recipe),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        elevation: 0,
                        side: const BorderSide(color: AppColors.primary, width: 1.2),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('تخصيص وطلب', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),

                    // 1-Click Fast Add or Complete Order Button
                    ElevatedButton.icon(
                      onPressed: isQuickAdded
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const CartScreen()),
                              );
                            }
                          : () {
                              for (final ing in recipe.ingredients) {
                                if (ing.isSelected) {
                                  cart.addToCart(ing.product, quantity: ing.selectedQuantity);
                                }
                              }
                              setState(() => _quickAddedRecipeIds.add(recipe.id));
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('✓ أضيفت جميع مقادير "${recipe.titleAr}" إلى السلة!'),
                                  backgroundColor: AppColors.primary,
                                  action: SnackBarAction(
                                    label: 'إتمام الطلب 🛒',
                                    textColor: AppColors.accent,
                                    onPressed: () {
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
                      icon: Icon(isQuickAdded ? Icons.shopping_bag_outlined : Icons.add_shopping_cart, size: 16),
                      label: Text(
                        isQuickAdded ? 'إتمام الطلب 🛒' : 'إضافة سريعة',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isQuickAdded ? AppColors.freshGreen : AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
  }

  Widget _infoBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _activeFilterPill(String text, {required VoidCallback onClear}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onClear,
            child: const Icon(Icons.close, size: 12, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'أطباق رئيسية':
        return Icons.dinner_dining_outlined;
      case 'مشروبات وعصائر':
        return Icons.local_drink_outlined;
      case 'فطور ومخبوزات':
        return Icons.breakfast_dining_outlined;
      case 'سلطات ومقبلات':
        return Icons.eco_outlined;
      case 'حلويات ومعجنات':
        return Icons.cake_outlined;
      default:
        return Icons.restaurant_menu_rounded;
    }
  }

  String _getSortLabel(String key) {
    switch (key) {
      case 'price_asc':
        return 'السعر: الأقل أولاً';
      case 'price_desc':
        return 'السعر: الأعلى أولاً';
      case 'rating':
        return 'الأعلى تقييماً';
      case 'time':
        return 'الأسرع تحضيراً';
      case 'discount':
        return 'أعلى توفير';
      case 'popular':
      default:
        return 'الأكثر طلباً';
    }
  }
}
