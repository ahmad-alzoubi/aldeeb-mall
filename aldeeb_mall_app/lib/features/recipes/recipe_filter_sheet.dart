import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/recipe_provider.dart';

class RecipeFilterSheet extends StatelessWidget {
  const RecipeFilterSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const RecipeFilterSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RecipeProvider>(context);
    final count = provider.filteredRecipes.length;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag Handle
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
                  child: const Icon(Icons.tune_rounded, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'تصفية وفلاتر الوصفات المتقدمة',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      Text(
                        'خصص خياراتك حسب السعر، الحساسية، المكونات، والوقت',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                if (provider.activeFiltersCount > 0)
                  TextButton.icon(
                    onPressed: () => provider.resetFilters(),
                    icon: const Icon(Icons.refresh, size: 16, color: AppColors.secondary),
                    label: const Text('إعادة ضبط', style: TextStyle(color: AppColors.secondary, fontSize: 12)),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Filter Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                // 1. Price Filtering
                _buildSectionHeader(Icons.payments_outlined, 'نطاق السعر لباقة المقادير (ل.س):'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _pricePresetChip(
                      label: 'الكل',
                      isActive: !provider.isPriceFilterActive,
                      onTap: () => provider.clearPriceFilter(),
                    ),
                    _pricePresetChip(
                      label: 'اقتصادية (< 30 ل.س)',
                      isActive: provider.isPriceFilterActive && provider.maxPrice == 30.0,
                      onTap: () => provider.setPriceRange(0, 30),
                    ),
                    _pricePresetChip(
                      label: 'متوسطة (30 - 60 ل.س)',
                      isActive: provider.isPriceFilterActive && provider.minPrice == 30.0 && provider.maxPrice == 60.0,
                      onTap: () => provider.setPriceRange(30, 60),
                    ),
                    _pricePresetChip(
                      label: 'عائلية فاخرة (> 60 ل.س)',
                      isActive: provider.isPriceFilterActive && provider.minPrice == 60.0,
                      onTap: () => provider.setPriceRange(60, 200),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'الحد الأقصى للسعر: ${provider.isPriceFilterActive ? provider.maxPrice.toInt() : 150} ل.س',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    if (provider.isPriceFilterActive)
                      Text(
                        'من ${provider.minPrice.toInt()} إلى ${provider.maxPrice.toInt()} ل.س',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                  ],
                ),
                Slider(
                  value: provider.isPriceFilterActive ? provider.maxPrice.clamp(15.0, 150.0) : 150.0,
                  min: 15.0,
                  max: 150.0,
                  divisions: 27,
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.border,
                  label: '${provider.maxPrice.toInt()} ل.س',
                  onChanged: (val) {
                    provider.setPriceRange(provider.minPrice, val);
                  },
                ),

                const Divider(height: 28),

                // 2. Allergies Exclusion
                _buildSectionHeader(Icons.health_and_safety_outlined, 'فلتر الحساسية (استبعاد ما يسبب حساسية):'),
                const SizedBox(height: 4),
                const Text(
                  'حدد المكونات التي ترغب باستبعاد الوصفات المحتوية عليها تماماً:',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _allergenChip(
                      label: 'لاكتوز (مشتقات حليب)',
                      allergen: 'لاكتوز',
                      isExcluded: provider.excludedAllergens.contains('لاكتوز'),
                      onTap: () => provider.toggleAllergenExclusion('لاكتوز'),
                    ),
                    _allergenChip(
                      label: 'جلوتين (قمح)',
                      allergen: 'جلوتين',
                      isExcluded: provider.excludedAllergens.contains('جلوتين'),
                      onTap: () => provider.toggleAllergenExclusion('جلوتين'),
                    ),
                    _allergenChip(
                      label: 'مكسرات',
                      allergen: 'مكسرات',
                      isExcluded: provider.excludedAllergens.contains('مكسرات'),
                      onTap: () => provider.toggleAllergenExclusion('مكسرات'),
                    ),
                    _allergenChip(
                      label: 'بيض',
                      allergen: 'بيض',
                      isExcluded: provider.excludedAllergens.contains('بيض'),
                      onTap: () => provider.toggleAllergenExclusion('بيض'),
                    ),
                    _allergenChip(
                      label: 'أسماك وبحريات',
                      allergen: 'سمك',
                      isExcluded: provider.excludedAllergens.contains('سمك'),
                      onTap: () => provider.toggleAllergenExclusion('سمك'),
                    ),
                  ],
                ),

                const Divider(height: 28),

                // 3. Dietary Requirements
                _buildSectionHeader(Icons.eco_outlined, 'الأنظمة الغذائية والدايت:'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _dietaryChip('خالٍ من الجلوتين', provider),
                    _dietaryChip('خالٍ من اللاكتوز', provider),
                    _dietaryChip('كيتو', provider),
                    _dietaryChip('نباتي', provider),
                    _dietaryChip('بروتين عالي', provider),
                    _dietaryChip('قليل السعرات', provider),
                  ],
                ),

                const Divider(height: 28),

                // 4. Products / Ingredients Filter
                _buildSectionHeader(Icons.kitchen_outlined, 'وصفات تحتوي على منتجات محددة (ما في ثلاجتك):'),
                const SizedBox(height: 4),
                const Text(
                  'اختر المكونات الأساسية المتوفرة لديك لعرض وصفات تلائمها:',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _productChip('p6', 'دجاج التنمية', provider),
                    _productChip('p11', 'سلمون نرويجي', provider),
                    _productChip('p12', 'ستيك أنجوس', provider),
                    _productChip('p13', 'بيض مزارع', provider),
                    _productChip('p26', 'أفوكادو هاس', provider),
                    _productChip('p22', 'أرز بسمتي', provider),
                    _productChip('p1', 'موز كافنديش', provider),
                    _productChip('p23', 'حليب لوز', provider),
                    _productChip('p4', 'حليب المراعي', provider),
                  ],
                ),

                const Divider(height: 28),

                // 5. Prep Time & Difficulty
                _buildSectionHeader(Icons.timer_outlined, 'وقت التحضير والصعوبة:'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _timeChip('الكل', null, provider),
                    _timeChip('⚡ حتى 15 دقيقة', 15, provider),
                    _timeChip('🕒 حتى 30 دقيقة', 30, provider),
                    _timeChip('⏳ حتى 45 دقيقة', 45, provider),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _difficultyChip('الكل', null, provider),
                    _difficultyChip('سهل جداً', 'سهل جداً', provider),
                    _difficultyChip('سهل', 'سهل', provider),
                    _difficultyChip('متوسط', 'متوسط', provider),
                  ],
                ),

                const Divider(height: 28),

                // 6. Sort By
                _buildSectionHeader(Icons.sort_rounded, 'ترتيب الوصفات حسب:'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _sortChip('popular', 'الأكثر طلباً وشهرة', provider),
                    _sortChip('price_asc', 'السعر: من الأقل للأعلى', provider),
                    _sortChip('price_desc', 'السعر: من الأعلى للأقل', provider),
                    _sortChip('rating', 'الأعلى تقييماً ⭐', provider),
                    _sortChip('time', 'الأسرع تحضيراً ⏱️', provider),
                    _sortChip('discount', 'أعلى نسبة توفير %', provider),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Text(
                        count > 0 ? 'عرض $count وصفة مطابقة ✓' : 'لا توجد وصفات تطابق التحديد',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _pricePresetChip({required String label, required bool isActive, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isActive ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _allergenChip({
    required String label,
    required String allergen,
    required bool isExcluded,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isExcluded ? const Color(0xFFFEF2F2) : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isExcluded ? AppColors.secondary : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isExcluded ? Icons.block : Icons.radio_button_unchecked,
              size: 14,
              color: isExcluded ? AppColors.secondary : AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isExcluded ? AppColors.secondary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dietaryChip(String tag, RecipeProvider provider) {
    final isSelected = provider.selectedDietaryTags.contains(tag);
    return GestureDetector(
      onTap: () => provider.toggleDietaryTag(tag),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.freshGreenLight : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? AppColors.freshGreen : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) const Icon(Icons.check_circle, size: 14, color: AppColors.freshGreen),
            if (isSelected) const SizedBox(width: 4),
            Text(
              tag,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.freshGreen : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _productChip(String productId, String label, RecipeProvider provider) {
    final isSelected = provider.selectedProductIds.contains(productId);
    return GestureDetector(
      onTap: () => provider.toggleProductFilter(productId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.add_circle_outline,
              size: 14,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeChip(String label, int? minutes, RecipeProvider provider) {
    final isSelected = provider.maxPrepTimeMinutes == minutes;
    return GestureDetector(
      onTap: () => provider.setMaxPrepTime(minutes),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _difficultyChip(String label, String? difficulty, RecipeProvider provider) {
    final isSelected = provider.selectedDifficulty == difficulty;
    return GestureDetector(
      onTap: () => provider.setDifficulty(difficulty),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _sortChip(String key, String label, RecipeProvider provider) {
    final isSelected = provider.sortBy == key;
    return GestureDetector(
      onTap: () => provider.setSortBy(key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
