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
        actions: [
          // Add Category Button in AppBar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: SizedBox(
              height: 38,
              child: ElevatedButton.icon(
                onPressed: () => _showAddCategoryDialog(context, mall),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.primaryDark,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                label: const Text(
                  'إضافة قسم',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
        ],
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
                                title: 'صورة مع عنوان',
                                icon: Icons.view_agenda_outlined,
                                isSelected: mall.categoryDisplayMode == CategoryDisplayMode.withTitle,
                                onTap: () => mall.setCategoryDisplayMode(CategoryDisplayMode.withTitle),
                              ),
                              const SizedBox(width: 4),
                              _buildViewModeOption(
                                title: 'صورة فقط',
                                icon: Icons.grid_view_rounded,
                                isSelected: mall.categoryDisplayMode == CategoryDisplayMode.imageOnly,
                                onTap: () => mall.setCategoryDisplayMode(CategoryDisplayMode.imageOnly),
                              ),
                            ],
                          ),
                        ),

                        // Jump to Product Catalog Link
                        TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CatalogScreen()),
                            );
                          },
                          icon: const Icon(Icons.shopping_bag_outlined, size: 16, color: AppColors.primary),
                          label: const Text(
                            'تصفح كقائمة أصناف ←',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
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
                              ? 0.78
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCategoryDialog(context, mall),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text('إضافة قسم جديد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
        onLongPress: () => _showCategoryOptionsSheet(context, mall, cat),
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
              'جرّب البحث باسم آخر أو أضف هذا القسم مباشرة إلى المتجر الآن',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _showAddCategoryDialog(context, mall),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('إضافة قسم بهذا الاسم', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // Category Options Bottom Sheet
  void _showCategoryOptionsSheet(BuildContext context, MallProvider mall, CategoryModel cat) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: cat.imageUrl ?? '',
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => const Icon(Icons.category, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cat.nameAr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(cat.nameEn, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                ListTile(
                  leading: const Icon(Icons.visibility_outlined, color: AppColors.primary),
                  title: Text(cat.showTitle ? 'إخفاء العنوان (عرض كصورة فقط)' : 'إظهار العنوان تحت الصورة'),
                  onTap: () {
                    mall.toggleCategoryTitleDisplay(cat.id);
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.open_in_new_rounded, color: AppColors.primary),
                  title: const Text('فتح واجهة القسم وتصفح العروض والمنتجات'),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => DepartmentScreen(category: cat)),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  title: const Text('حذف هذا القسم', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    mall.deleteCategory(cat.id);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('تم حذف قسم "${cat.nameAr}"')),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Interactive Add Category Dialog / Modal Sheet
  void _showAddCategoryDialog(BuildContext context, MallProvider mall) {
    final nameArCtrl = TextEditingController(text: _searchQuery);
    final nameEnCtrl = TextEditingController();
    final imageUrlCtrl = TextEditingController();
    String selectedGroup = 'food_fresh';
    bool showTitle = true;

    final List<Map<String, String>> presets = const [
      {
        'label': 'طعام مجهز 🍲',
        'url': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=600&q=80',
      },
      {
        'label': 'خضار وفواكه 🍎',
        'url': 'https://images.unsplash.com/photo-1610348725531-843dff563e2c?auto=format&fit=crop&w=600&q=80',
      },
      {
        'label': 'مخبوزات 🥐',
        'url': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=600&q=80',
      },
      {
        'label': 'مشروبات 🥤',
        'url': 'https://images.unsplash.com/photo-1527661591475-527312dd65f5?auto=format&fit=crop&w=600&q=80',
      },
      {
        'label': 'عناية وجمال 🧴',
        'url': 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?auto=format&fit=crop&w=600&q=80',
      },
      {
        'label': 'ملابس وأزياء 👕',
        'url': 'https://images.unsplash.com/photo-1489987707025-afc232f7ea0f?auto=format&fit=crop&w=600&q=80',
      },
      {
        'label': 'مستلزمات أطفال 👶',
        'url': 'https://images.unsplash.com/photo-1515488042361-ee00e0ddd4e4?auto=format&fit=crop&w=600&q=80',
      },
      {
        'label': 'حيوانات أليفة 🐾',
        'url': 'https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?auto=format&fit=crop&w=600&q=80',
      },
      {
        'label': 'سيارات 🚗',
        'url': 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?auto=format&fit=crop&w=600&q=80',
      },
      {
        'label': 'رياضة ولياقة ⚽',
        'url': 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?auto=format&fit=crop&w=600&q=80',
      },
      {
        'label': 'قرطاسية وألعاب 🎮',
        'url': 'https://images.unsplash.com/photo-1558060370-d644479cb6f7?auto=format&fit=crop&w=600&q=80',
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.add_business_rounded, color: AppColors.primary, size: 24),
                            SizedBox(width: 8),
                            Text(
                              'إضافة قسم جديد للمول',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const Text(
                      'أضف أي قسم بكل سهولة وحدد صورته وخيارات ظهوره للمتسوقين',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),

                    // Arabic Name
                    const Text('اسم القسم بالعربية *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameArCtrl,
                      decoration: InputDecoration(
                        hintText: 'مثال: أواني وتحف منزلية فاخرة',
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // English Name
                    const Text('اسم القسم بالإنجليزية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameEnCtrl,
                      decoration: InputDecoration(
                        hintText: 'مثال: Luxury Kitchenware',
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Preset Image Selectors
                    const Text('اختر صورة جاهزة للقسم (أو اكتب رابط مخصص):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: presets.map((p) {
                        final isSel = imageUrlCtrl.text == p['url'];
                        return ActionChip(
                          label: Text(p['label']!),
                          backgroundColor: isSel ? AppColors.primary.withValues(alpha: 0.15) : AppColors.background,
                          side: BorderSide(color: isSel ? AppColors.primary : AppColors.border),
                          onPressed: () {
                            setModalState(() {
                              imageUrlCtrl.text = p['url']!;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),

                    // Image URL Input
                    TextField(
                      controller: imageUrlCtrl,
                      decoration: InputDecoration(
                        hintText: 'رابط الصورة (URL مباشر)',
                        prefixIcon: const Icon(Icons.image_outlined, color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Group Selector
                    const Text('المجموعة والتصنيف الرئيسي:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedGroup,
                      items: const [
                        DropdownMenuItem(value: 'food_fresh', child: Text('أطعمة وطازج 🥗')),
                        DropdownMenuItem(value: 'groceries', child: Text('مؤونة وسوبرماركت 🛒')),
                        DropdownMenuItem(value: 'care', child: Text('عناية وأطفال 👶')),
                        DropdownMenuItem(value: 'home_tech', child: Text('منزل وتنظيف وسيارات 🏡')),
                        DropdownMenuItem(value: 'fashion', child: Text('أزياء وإكسسوارات 👕')),
                        DropdownMenuItem(value: 'lifestyle', child: Text('رياضة وقرطاسية وألعاب ⚽')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedGroup = val);
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Display Style Toggle
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('إظهار العنوان أسفل الصورة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text(
                                showTitle ? 'ستظهر الصورة مع اسم القسم تحتيها' : 'ستظهر الصورة فقط كبطاقة بصرية كاملة',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          Switch.adaptive(
                            value: showTitle,
                            activeTrackColor: AppColors.primary,
                            onChanged: (v) => setModalState(() => showTitle = v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          final nameAr = nameArCtrl.text.trim();
                          if (nameAr.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('يرجى كتابة اسم القسم بالعربية')),
                            );
                            return;
                          }

                          final newCat = CategoryModel(
                            id: 'c_${DateTime.now().millisecondsSinceEpoch}',
                            nameAr: nameAr,
                            nameEn: nameEnCtrl.text.trim().isNotEmpty
                                ? nameEnCtrl.text.trim()
                                : nameAr,
                            slug: nameEnCtrl.text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '-')
                                .isNotEmpty
                                ? nameEnCtrl.text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '-')
                                : 'category-${DateTime.now().millisecondsSinceEpoch}',
                            iconName: 'category',
                            imageUrl: imageUrlCtrl.text.trim().isNotEmpty
                                ? imageUrlCtrl.text.trim()
                                : presets[0]['url'],
                            groupTag: selectedGroup,
                            showTitle: showTitle,
                            itemCount: 45,
                            sortOrder: mall.categories.length + 1,
                          );

                          mall.addCategory(newCat);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.primaryDark,
                              content: Text('تمت إضافة قسم "${newCat.nameAr}" بنجاح! 🎉'),
                              action: SnackBarAction(
                                label: 'تصفح الآن',
                                textColor: AppColors.accent,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => DepartmentScreen(category: newCat)),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                        ),
                        child: const Text(
                          'حفظ وإضافة القسم الآن ✨',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
