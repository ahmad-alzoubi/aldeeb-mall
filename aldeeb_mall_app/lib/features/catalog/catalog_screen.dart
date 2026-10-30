import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/mall_provider.dart';
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('أقسام وتصنيفات الهايبرماركت'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
      body: Column(
        children: [
          // Category Pills Slider
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

          // Sort & Count Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${products.length} صنف متاح',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
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
            ),
          ),

          // Products Grid
          Expanded(
            child: products.isEmpty
                ? const Center(
                    child: Text(
                      'لا توجد منتجات مطابقة لهذا البحث',
                      style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.65,
                    ),
                    itemCount: products.length,
                    itemBuilder: (ctx, index) {
                      return ProductCard(product: products[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
