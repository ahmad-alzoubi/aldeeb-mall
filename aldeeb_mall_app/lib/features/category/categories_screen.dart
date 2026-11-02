import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/category_model.dart';
import '../../core/providers/mall_provider.dart';
import '../../core/utils/responsive.dart';
import '../catalog/catalog_screen.dart';
import 'department_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedGroup = 'all';
  String _searchQuery = '';

  final List<Map<String, String>> _categoryGroups = const [
    {'id': 'all', 'title': 'كافة الأقسام 🗂️'},
    {'id': 'food_fresh', 'title': 'أطعمة وطازج 🥗'},
    {'id': 'groceries', 'title': 'مؤونة وسوبرماركت 🛒'},
    {'id': 'care', 'title': 'عناية وأطفال 👶'},
    {'id': 'home_tech', 'title': 'منزل وتنظيف وسيارات 🏡'},
    {'id': 'fashion', 'title': 'أزياء وإكسسوارات 👕'},
    {'id': 'lifestyle', 'title': 'رياضة وقرطاسية وألعاب ⚽'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mall = Provider.of<MallProvider>(context);
    final isDesktop = Responsive.isDesktop(context);
    final isTablet = Responsive.isTablet(context);
    final isMobile = Responsive.isMobile(context);

    // Filter categories based on search and group
    final categories = mall.categories.where((cat) {
      final matchesGroup = _selectedGroup == 'all' || cat.groupTag == _selectedGroup;
      if (!matchesGroup) return false;

      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase().trim();
      return cat.nameAr.toLowerCase().contains(q) ||
          cat.nameEn.toLowerCase().contains(q) ||
          cat.slug.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'أقسام وتصنيفات الهايبرماركت',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            Text(
              '${mall.categories.length} قسماً متكاملاً • تسوق سريع وتوصيل فوري',
              style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(66),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: MaxWidthContainer(
              maxWidth: 1360,
              child: Row(
                children: [
                  // Search Bar
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: 'ابحث عن أي قسم أو فئة (خضار، ألبان، ملابس، سيارات...)...',
                          hintStyle: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: MaxWidthContainer(
        maxWidth: 1360,
        child: Column(
          children: [
            // Controls Bar: Category Groups Filter + Display Style Switcher
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  // Row with View Style Switcher + Jump to flat catalog
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Display Style Switcher: صورة مع عنوان VS صورة فقط
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildViewModeOption(
                                title: isMobile ? 'عناوين' : 'صورة مع عنوان',
                                icon: Icons.view_agenda_outlined,
                                isSelected: mall.categoryDisplayMode == CategoryDisplayMode.withTitle,
                                onTap: () => mall.setCategoryDisplayMode(CategoryDisplayMode.withTitle),
                              ),
                              const SizedBox(width: 4),
                              _buildViewModeOption(
                                title: isMobile ? 'صور' : 'صورة فقط',
                                icon: Icons.grid_view_rounded,
                                isSelected: mall.categoryDisplayMode == CategoryDisplayMode.imageOnly,
                                onTap: () => mall.setCategoryDisplayMode(CategoryDisplayMode.imageOnly),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Jump to Product Catalog Link
                        Flexible(
                          child: TextButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const CatalogScreen()),
                              );
                            },
                            icon: const Icon(Icons.shopping_bag_outlined, size: 16, color: AppColors.primary),
                            label: Text(
                              isMobile ? 'الأصناف ←' : 'تصفح كقائمة أصناف ←',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Horizontal Group Filter Chips
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _categoryGroups.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (ctx, index) {
                        final grp = _categoryGroups[index];
                        final isSel = _selectedGroup == grp['id'];
                        return FilterChip(
                          label: Text(grp['title']!),
                          selected: isSel,
                          showCheckmark: false,
                          backgroundColor: Colors.white,
                          selectedColor: AppColors.primary.withValues(alpha: 0.12),
                          side: BorderSide(
                            color: isSel ? AppColors.primary : AppColors.border,
                            width: isSel ? 1.5 : 1,
                          ),
                          labelStyle: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                            color: isSel ? AppColors.primary : AppColors.textPrimary,
                          ),
                          onSelected: (_) {
                            setState(() => _selectedGroup = grp['id']!);
                          },
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: AppColors.border),

            // Categories Grid
            Expanded(
              child: categories.isEmpty
                  ? _buildEmptyState(mall)
                  : RefreshIndicator(
                      onRefresh: () => mall.loadMallData(),
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isDesktop ? 6 : (isTablet ? 4 : 2),
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: mall.categoryDisplayMode == CategoryDisplayMode.withTitle
                              ? (isMobile ? 0.72 : 0.78)
                              : 0.95,
                        ),
                        itemCount: categories.length,
                        itemBuilder: (ctx, index) {
                          final cat = categories[index];
                          return _buildCategoryCard(context, mall, cat);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewModeOption({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, MallProvider mall, CategoryModel cat) {
    // Individual category showTitle overrides or respects global display mode
    final isImageOnly = mall.categoryDisplayMode == CategoryDisplayMode.imageOnly || !cat.showTitle;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          mall.selectCategory(cat.id);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DepartmentScreen(category: cat),
            ),
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: isImageOnly
              ? _buildImageOnlyContent(cat)
              : _buildImageWithTitleContent(cat),
        ),
      ),
    );
  }

  // Visual Card Mode 1: صورة بس لحال (Minimalist Full-Bleed Image Card)
  Widget _buildImageOnlyContent(CategoryModel cat) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Category High-Resolution Image
        CachedNetworkImage(
          imageUrl: cat.imageUrl ?? 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=600&q=80',
          fit: BoxFit.cover,
          placeholder: (ctx, url) => Container(
            color: Colors.grey.shade100,
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              ),
            ),
          ),
          errorWidget: (ctx, url, err) => Container(
            color: AppColors.primary.withValues(alpha: 0.08),
            child: const Icon(Icons.broken_image_outlined, color: AppColors.textSecondary),
          ),
        ),

        // Subtle gradient overlay for luxury feel and gentle depth
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.15),
                ],
              ),
            ),
          ),
        ),

        // Top Subtle Badge
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt_rounded, size: 11, color: AppColors.accent),
                const SizedBox(width: 3),
                Text(
                  '${cat.itemCount > 0 ? cat.itemCount : 50}+ صنف',
                  style: const TextStyle(fontSize: 9.5, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Visual Card Mode 2: صورة مع عنوان تحتيها (Card with Image & Title Underneath)
  Widget _buildImageWithTitleContent(CategoryModel cat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Image Part
        Expanded(
          flex: 62,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: cat.imageUrl ?? 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=600&q=80',
                fit: BoxFit.cover,
                placeholder: (ctx, url) => Container(
                  color: Colors.grey.shade100,
                  child: const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                  ),
                ),
                errorWidget: (ctx, url, err) => Container(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  child: const Icon(Icons.category_rounded, color: AppColors.primary),
                ),
              ),

              // Corner Item Count Tag
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Text(
                    '${cat.itemCount > 0 ? cat.itemCount : 60}+ صنف',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Bottom Title & Details Part
        Expanded(
          flex: 38,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  cat.nameAr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        cat.nameEn,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 11,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(MallProvider mall) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_off_rounded, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            const Text(
              'لا توجد أقسام مطابقة للبحث أو التصفية',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'جرّب البحث باسم آخر أو اختر تصنيفاً مختلفاً من شريط التصفية أعلاه',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _selectedGroup = 'all';
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('عرض جميع الأقسام', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
