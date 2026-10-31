import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/mall_provider.dart';
import '../../core/utils/responsive.dart';
import '../category/department_screen.dart';
import '../home/widgets/product_card.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mall = Provider.of<MallProvider>(context);
    final categories = mall.categories;
    final products = mall.filteredProducts;
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('أقسام وتصنيفات الهايبرماركت'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: MaxWidthContainer(
              maxWidth: 1360,
              child: TextField(
                controller: _searchController,
                onChanged: (val) => mall.setSearchQuery(val),
                decoration: InputDecoration(
                  hintText: 'ابحث عن أي صنف أو ماركة تجارية...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            mall.setSearchQuery('');
                          },
                        )
                      : null,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ),
        ),
      ),
      body: MaxWidthContainer(
        maxWidth: 1360,
        child: isDesktop
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Desktop Left Sidebar: Categories & Filters (260px)
                  Container(
                    width: 280,
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'تصفية حسب القسم',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () => mall.selectCategory(null),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: mall.selectedCategoryId == null
                                  ? AppColors.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.grid_view,
                                  size: 18,
                                  color: mall.selectedCategoryId == null ? Colors.white : AppColors.textPrimary,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'كافة الأقسام',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: mall.selectedCategoryId == null ? Colors.white : AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(height: 16),
                        Expanded(
                          child: ListView.separated(
                            itemCount: categories.length,
                            separatorBuilder: (_, index) => const SizedBox(height: 4),
                            itemBuilder: (ctx, idx) {
                              final cat = categories[idx];
                              final isSel = mall.selectedCategoryId == cat.id;
                              return InkWell(
                                onTap: () => mall.selectCategory(cat.id),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSel ? AppColors.primary : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          cat.nameAr,
                                          style: TextStyle(
                                            fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                                            fontSize: 13,
                                            color: isSel ? Colors.white : AppColors.textPrimary,
                                          ),
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
                    ),
                  ),

                  // Desktop Right Area: Sort & Product Grid
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                      child: Column(
                        children: [
                          _buildSortBar(mall, products.length),
                          const SizedBox(height: 16),
                          Expanded(
                            child: _buildProductsGrid(context, products),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  // Mobile Category Pills Slider
                  Container(
                    height: 48,
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: const Text('الكل'),
                            selected: mall.selectedCategoryId == null,
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: mall.selectedCategoryId == null ? Colors.white : AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            onSelected: (_) => mall.selectCategory(null),
                          ),
                        ),
                        ...categories.map((cat) {
                          final isSelected = mall.selectedCategoryId == cat.id;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: Text(cat.nameAr),
                              selected: isSelected,
                              selectedColor: AppColors.primary,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              onSelected: (_) => mall.selectCategory(cat.id),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  // Direct Department Deals & Experience Link
                  if (mall.selectedCategoryId != null) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                      child: InkWell(
                        onTap: () {
                          final cat = categories.firstWhere(
                            (c) => c.id == mall.selectedCategoryId,
                            orElse: () => categories.first,
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => DepartmentScreen(category: cat)),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Row(
                                children: [
                                  Icon(Icons.local_fire_department_rounded, color: AppColors.secondary, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'عرض عروض وتجربة هذا القسم المتكاملة 🔥',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primary, size: 12),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],

                  // Mobile Sort & Count Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: _buildSortBar(mall, products.length),
                  ),

                  // Mobile Products Grid
                  Expanded(
                    child: _buildProductsGrid(context, products),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSortBar(MallProvider mall, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$count صنف متاح',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold),
        ),
        DropdownButton<ProductSortOption>(
          value: mall.currentSort,
          underline: const SizedBox(),
          icon: const Icon(Icons.sort, size: 18, color: AppColors.primary),
          style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
          onChanged: (val) {
            if (val != null) mall.setSortOption(val);
          },
          items: const [
            DropdownMenuItem(value: ProductSortOption.featured, child: Text('الأكثر تميزاً')),
            DropdownMenuItem(value: ProductSortOption.priceLowToHigh, child: Text('السعر: من الأقل للأعلى')),
            DropdownMenuItem(value: ProductSortOption.priceHighToLow, child: Text('السعر: من الأعلى للأقل')),
            DropdownMenuItem(value: ProductSortOption.highestDiscount, child: Text('أعلى نسبة تخفيض')),
            DropdownMenuItem(value: ProductSortOption.topRated, child: Text('الأعلى تقييماً')),
          ],
        ),
      ],
    );
  }

  Widget _buildProductsGrid(BuildContext context, List products) {
    if (products.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد منتجات مطابقة لهذا البحث',
          style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: Responsive.gridColumns(context),
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: Responsive.productCardAspectRatio(context),
      ),
      itemCount: products.length,
      itemBuilder: (ctx, index) {
        return ProductCard(product: products[index]);
      },
    );
  }
}
