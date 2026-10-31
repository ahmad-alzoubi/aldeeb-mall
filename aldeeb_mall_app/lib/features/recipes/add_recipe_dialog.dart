import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/recipe_model.dart';
import '../../core/models/product_model.dart';
import '../../core/providers/recipe_provider.dart';
import '../../core/services/supabase_service.dart';

class AddRecipeDialog extends StatefulWidget {
  final String? initialCategory;

  const AddRecipeDialog({super.key, this.initialCategory});

  static Future<void> show(BuildContext context, {String? initialCategory}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddRecipeDialog(initialCategory: initialCategory),
    );
  }

  @override
  State<AddRecipeDialog> createState() => _AddRecipeDialogState();
}

class _AddRecipeDialogState extends State<AddRecipeDialog> {
  final _formKey = GlobalKey<FormState>();

  late String _category;
  bool _isCustomCategory = false;
  final _customCategoryController = TextEditingController();

  final _titleArController = TextEditingController();
  final _titleEnController = TextEditingController();
  final _prepTimeController = TextEditingController(text: '20');
  final _servingsController = TextEditingController(text: '4 أشخاص');
  final _caloriesController = TextEditingController(text: '350');
  final _stepController = TextEditingController();

  String _difficulty = 'سهل';
  final List<String> _steps = [];
  final List<_NewRecipeIngredientItem> _selectedIngredients = [];
  final Set<String> _selectedDietaryTags = {};
  final Set<String> _selectedAllergens = {};

  final List<String> _coverImagePresets = [
    'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1553530666-ba11a7da3888?auto=format&fit=crop&w=800&q=80',
  ];
  late String _selectedImageUrl;

  @override
  void initState() {
    super.initState();
    _selectedImageUrl = _coverImagePresets.first;
    _category = widget.initialCategory ?? 'أطباق رئيسية';
  }

  @override
  void dispose() {
    _customCategoryController.dispose();
    _titleArController.dispose();
    _titleEnController.dispose();
    _prepTimeController.dispose();
    _servingsController.dispose();
    _caloriesController.dispose();
    _stepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recipeProvider = Provider.of<RecipeProvider>(context);
    final allProducts = SupabaseService.defaultProducts;
    final availableCategories = recipeProvider.categories.where((c) => c != 'الكل').toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Form(
        key: _formKey,
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
                    child: const Icon(Icons.soup_kitchen_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ابتكار وصفة جديدة | استوديو الشيف',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        Text(
                          'أضف تصنيفاً جديداً ومقادير من المتجر لتمكين الطلب الفوري',
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
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

            // Scrollable Form
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // 1. Category Selection / Custom Category
                  _sectionTitle(Icons.category_outlined, 'تصنيف وقسم الوصفة:'),
                  const SizedBox(height: 8),
                  if (!_isCustomCategory) ...[
                    DropdownButtonFormField<String>(
                      initialValue: availableCategories.contains(_category) ? _category : availableCategories.first,
                      items: availableCategories.map((c) {
                        return DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _category = val);
                      },
                      decoration: _inputDecoration('اختر القسم'),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => setState(() => _isCustomCategory = true),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('+ كتابة تصنيف وقسم جديد مخصص', style: TextStyle(fontSize: 12)),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _customCategoryController,
                            decoration: _inputDecoration('اكتب اسم التصنيف الجديد (مثال: عصائر رمضانية، كيتو دايت)'),
                            validator: (val) {
                              if (_isCustomCategory && (val == null || val.trim().isEmpty)) {
                                return 'يرجى كتابة اسم التصنيف';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                          tooltip: 'العودة للتصنيفات الجاهزة',
                          onPressed: () => setState(() => _isCustomCategory = false),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 20),

                  // 2. Titles
                  _sectionTitle(Icons.title, 'عنوان الوصفة:'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _titleArController,
                    decoration: _inputDecoration('اسم الوصفة بالعربية (مثال: سموذي التوت المنعش)'),
                    validator: (val) => (val == null || val.trim().isEmpty) ? 'يرجى كتابة اسم الوصفة' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _titleEnController,
                    decoration: _inputDecoration('Recipe English Name (e.g. Fresh Berry Smoothie)'),
                  ),

                  const SizedBox(height: 20),

                  // 3. Quick Metrics (Time, Servings, Difficulty, Calories)
                  _sectionTitle(Icons.info_outline, 'تفاصيل التحضير والمستوى:'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _prepTimeController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration('الوقت (بالدقائق)'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _servingsController,
                          decoration: _inputDecoration('تكفي كم شخص؟'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _difficulty,
                          items: const [
                            DropdownMenuItem(value: 'سهل جداً', child: Text('سهل جداً')),
                            DropdownMenuItem(value: 'سهل', child: Text('سهل')),
                            DropdownMenuItem(value: 'متوسط', child: Text('متوسط')),
                            DropdownMenuItem(value: 'شيف ماستر', child: Text('شيف ماستر')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _difficulty = val);
                          },
                          decoration: _inputDecoration('الصعوبة'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _caloriesController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration('السعرات (كالوري)'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 4. Cover Photo Selector
                  _sectionTitle(Icons.image_outlined, 'اختر صورة الغلاف للوصفة:'),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _coverImagePresets.length,
                      itemBuilder: (ctx, idx) {
                        final img = _coverImagePresets[idx];
                        final isSel = _selectedImageUrl == img;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedImageUrl = img),
                          child: Container(
                            margin: const EdgeInsetsDirectional.only(end: 10),
                            width: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSel ? AppColors.primary : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(9),
                              child: CachedNetworkImage(imageUrl: img, fit: BoxFit.cover),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 5. Dietary & Allergen Tags
                  _sectionTitle(Icons.health_and_safety_outlined, 'وسوم الحساسية والنظام الغذائي:'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['خالٍ من الجلوتين', 'خالٍ من اللاكتوز', 'كيتو', 'نباتي', 'بروتين عالي'].map((tag) {
                      final isSel = _selectedDietaryTags.contains(tag);
                      return FilterChip(
                        label: Text(tag, style: TextStyle(fontSize: 11, color: isSel ? Colors.white : AppColors.textPrimary)),
                        selected: isSel,
                        selectedColor: AppColors.freshGreen,
                        checkmarkColor: Colors.white,
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              _selectedDietaryTags.add(tag);
                            } else {
                              _selectedDietaryTags.remove(tag);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // 6. Ingredients Selection from Store Catalog
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _sectionTitle(Icons.shopping_basket_outlined, 'مقادير الوصفة من المتجر:'),
                      TextButton.icon(
                        onPressed: () => _showAddIngredientSheet(allProducts),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('إضافة مكون', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_selectedIngredients.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'اضغط على "+ إضافة مكون" لاختيار مقادير من المتجر لتمكين طلبها بنقرة واحدة.',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ..._selectedIngredients.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final item = entry.value;
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
                                imageUrl: item.product.firstImage,
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
                                  Text(item.product.nameAr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  Text('الكمية: ${item.quantityNeeded}', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                ],
                              ),
                            ),
                            Text(
                              '${item.product.price.toStringAsFixed(2)} ل.س',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 12),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.secondary),
                              onPressed: () {
                                setState(() => _selectedIngredients.removeAt(idx));
                              },
                            ),
                          ],
                        ),
                      );
                    }),

                  const SizedBox(height: 20),

                  // 7. Cooking Steps
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _sectionTitle(Icons.format_list_numbered, 'طريقة وخطوات التحضير:'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _stepController,
                          decoration: _inputDecoration('اكتب خطوة من خطوات التحضير ثم اضغط إضافة...'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        style: IconButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                        icon: const Icon(Icons.add, size: 20),
                        onPressed: () {
                          final step = _stepController.text.trim();
                          if (step.isNotEmpty) {
                            setState(() {
                              _steps.add(step);
                              _stepController.clear();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_steps.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text('لم تتم إضافة خطوات بعد. يمكنك كتابة الخطوة والضغط على (+).', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    )
                  else
                    ..._steps.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final stepText = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 10,
                              backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
                              child: Text('${idx + 1}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(stepText, style: const TextStyle(fontSize: 12))),
                            IconButton(
                              icon: const Icon(Icons.close, size: 14, color: AppColors.textMuted),
                              onPressed: () => setState(() => _steps.removeAt(idx)),
                            ),
                          ],
                        ),
                      );
                    }),

                  const SizedBox(height: 28),
                ],
              ),
            ),

            // Submit Button Bar
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
                      child: ElevatedButton.icon(
                        onPressed: () => _submitForm(recipeProvider),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('حفظ الوصفة ونشرها بالقسم', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddIngredientSheet(List<ProductModel> products) {
    ProductModel selectedProd = products.first;
    final qtyController = TextEditingController(text: '1 عبوة');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('اختر مكوناً من متجر الديب مول:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ProductModel>(
                    initialValue: selectedProd,
                    items: products.map((p) {
                      return DropdownMenuItem(
                        value: p,
                        child: Text('${p.nameAr} (${p.price} ل.س)', style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setSheetState(() => selectedProd = val);
                    },
                    decoration: _inputDecoration('اختر المنتج'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: qtyController,
                    decoration: _inputDecoration('الكمية المطلوبة بالوصفة (مثال: 500 غرام، 2 حبة)'),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedIngredients.add(_NewRecipeIngredientItem(
                            product: selectedProd,
                            quantityNeeded: qtyController.text.trim().isEmpty ? '1 حبة' : qtyController.text.trim(),
                          ));
                        });
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('إضافة المكون'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _submitForm(RecipeProvider provider) {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedIngredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إضافة مكون واحد على الأقل من المتجر للوصفة'),
          backgroundColor: AppColors.secondary,
        ),
      );
      return;
    }

    final targetCategory = _isCustomCategory
        ? _customCategoryController.text.trim()
        : _category;

    final cookMinutes = int.tryParse(_prepTimeController.text) ?? 20;
    final calories = int.tryParse(_caloriesController.text) ?? 350;

    final newRecipe = RecipeModel(
      id: 'custom-${const Uuid().v4().substring(0, 8)}',
      titleAr: _titleArController.text.trim(),
      titleEn: _titleEnController.text.trim().isNotEmpty
          ? _titleEnController.text.trim()
          : _titleArController.text.trim(),
      category: targetCategory,
      prepTime: '$cookMinutes دقيقة',
      cookTimeMinutes: cookMinutes,
      servings: _servingsController.text.trim().isNotEmpty ? _servingsController.text.trim() : '4 أشخاص',
      difficulty: _difficulty,
      imageUrl: _selectedImageUrl,
      discountPercent: 15.0,
      calories: calories,
      rating: 5.0,
      reviewsCount: 1,
      allergens: _selectedAllergens.toList(),
      dietaryTags: _selectedDietaryTags.toList(),
      steps: _steps.isNotEmpty
          ? _steps
          : ['تجهز المكونات وتغسل جيداً.', 'تتبع تعليمات الطبخ المعتادة وتقدم ساخنة.'],
      ingredients: _selectedIngredients.map((item) {
        return RecipeIngredient(
          id: 'ing-${const Uuid().v4().substring(0, 6)}',
          nameAr: item.product.nameAr,
          quantityNeeded: item.quantityNeeded,
          product: item.product,
          substitutes: SupabaseService.defaultProducts
              .where((p) => p.categoryId == item.product.categoryId && p.id != item.product.id)
              .take(2)
              .toList(),
        );
      }).toList(),
      isCustom: true,
    );

    provider.addCustomRecipe(newRecipe);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 تم نشر وصفة "${newRecipe.titleAr}" بقسم "${newRecipe.category}" بنجاح!'),
        backgroundColor: AppColors.freshGreen,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}

class _NewRecipeIngredientItem {
  final ProductModel product;
  final String quantityNeeded;

  _NewRecipeIngredientItem({required this.product, required this.quantityNeeded});
}
