import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/recipe_model.dart';
import '../../core/models/product_model.dart';
import '../../core/services/supabase_service.dart';

class RecipeSwapSheet extends StatefulWidget {
  final RecipeIngredient ingredient;
  final Function(ProductModel newProduct) onSwap;

  const RecipeSwapSheet({
    super.key,
    required this.ingredient,
    required this.onSwap,
  });

  static Future<void> show(
    BuildContext context, {
    required RecipeIngredient ingredient,
    required Function(ProductModel newProduct) onSwap,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RecipeSwapSheet(
        ingredient: ingredient,
        onSwap: onSwap,
      ),
    );
  }

  @override
  State<RecipeSwapSheet> createState() => _RecipeSwapSheetState();
}

class _RecipeSwapSheetState extends State<RecipeSwapSheet> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allProducts = SupabaseService.defaultProducts;
    final currentProduct = widget.ingredient.product;

    // Filter products
    final searchFilteredProducts = _searchQuery.trim().isEmpty
        ? <ProductModel>[]
        : allProducts.where((p) {
            if (p.id == currentProduct.id) return false;
            final q = _searchQuery.trim().toLowerCase();
            return p.nameAr.toLowerCase().contains(q) ||
                p.nameEn.toLowerCase().contains(q) ||
                (p.brand != null && p.brand!.toLowerCase().contains(q));
          }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.swap_horiz_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'تبديل المكون واختيار بديل ذكي',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'المكون الحالي: ${widget.ingredient.nameAr}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Current Item Card
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: currentProduct.firstImage,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'المكون المحدد حالياً بالوصفة',
                          style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          currentProduct.nameAr,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${currentProduct.price.toStringAsFixed(2)} ل.س',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Search Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'ابحث عن أي بديل في المتجر (مثال: حليب لوز، صدور دجاج)...',
                hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),

          // Content List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              children: [
                // Recommended Substitutes
                if (widget.ingredient.substitutes.isNotEmpty && _searchQuery.isEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, size: 16, color: AppColors.accent),
                      const SizedBox(width: 6),
                      const Text(
                        'بدائل ذكية موصى بها لهذه الوصفة:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${widget.ingredient.substitutes.length} خيارات',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...widget.ingredient.substitutes.map((sub) => _buildSubstituteCard(sub, currentProduct, isRecommended: true)),
                  const SizedBox(height: 16),
                ],

                // Search Results
                if (_searchQuery.isNotEmpty) ...[
                  Text(
                    'نتائج البحث عن "$_searchQuery" (${searchFilteredProducts.length}):',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (searchFilteredProducts.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      alignment: Alignment.center,
                      child: const Column(
                        children: [
                          Icon(Icons.search_off_rounded, size: 40, color: AppColors.textMuted),
                          SizedBox(height: 8),
                          Text('لم نجد منتجات مطابقة للبحث', style: TextStyle(color: AppColors.textMuted)),
                        ],
                      ),
                    )
                  else
                    ...searchFilteredProducts.map((p) => _buildSubstituteCard(p, currentProduct, isRecommended: false)),
                ],

                // Other Catalog Suggestions if no search
                if (_searchQuery.isEmpty && widget.ingredient.substitutes.isEmpty) ...[
                  const Text(
                    'منتجات مقترحة من نفس القسم:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ...allProducts
                      .where((p) => p.id != currentProduct.id)
                      .take(6)
                      .map((p) => _buildSubstituteCard(p, currentProduct, isRecommended: false)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubstituteCard(ProductModel product, ProductModel currentProduct, {required bool isRecommended}) {
    final priceDiff = product.price - currentProduct.price;
    final isCheaper = priceDiff < 0;
    final isSame = priceDiff == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRecommended ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border,
          width: isRecommended ? 1.5 : 1.0,
        ),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CachedNetworkImage(
              imageUrl: product.firstImage,
              width: 52,
              height: 52,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isRecommended)
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.freshGreenLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'بديل متوافق تماماً ✓',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.freshGreen),
                    ),
                  ),
                Text(
                  product.nameAr,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${product.price.toStringAsFixed(2)} ل.س',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.primary),
                    ),
                    const SizedBox(width: 8),
                    if (!isSame)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isCheaper ? AppColors.freshGreenLight : const Color(0xFFFFF1F2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isCheaper
                              ? 'يوفر ${priceDiff.abs().toStringAsFixed(2)} ل.س'
                              : '+${priceDiff.toStringAsFixed(2)} ل.س',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isCheaper ? AppColors.freshGreen : AppColors.secondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () {
              widget.onSwap(product);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✓ تم استبدال المكون بـ "${product.nameAr}" بنجاح!'),
                  backgroundColor: AppColors.freshGreen,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isRecommended ? AppColors.primary : const Color(0xFFF1F5F9),
              foregroundColor: isRecommended ? Colors.white : AppColors.textPrimary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('اختيار', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
