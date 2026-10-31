import 'product_model.dart';

class RecipeIngredient {
  final String id;
  final String nameAr;
  final String quantityNeeded;
  final ProductModel product;
  final List<ProductModel> substitutes;
  final bool isOptional;
  final bool isSelected;
  final double selectedQuantity;

  const RecipeIngredient({
    required this.id,
    required this.nameAr,
    required this.quantityNeeded,
    required this.product,
    this.substitutes = const [],
    this.isOptional = false,
    this.isSelected = true,
    this.selectedQuantity = 1.0,
  });

  RecipeIngredient copyWith({
    String? id,
    String? nameAr,
    String? quantityNeeded,
    ProductModel? product,
    List<ProductModel>? substitutes,
    bool? isOptional,
    bool? isSelected,
    double? selectedQuantity,
  }) {
    return RecipeIngredient(
      id: id ?? this.id,
      nameAr: nameAr ?? this.nameAr,
      quantityNeeded: quantityNeeded ?? this.quantityNeeded,
      product: product ?? this.product,
      substitutes: substitutes ?? this.substitutes,
      isOptional: isOptional ?? this.isOptional,
      isSelected: isSelected ?? this.isSelected,
      selectedQuantity: selectedQuantity ?? this.selectedQuantity,
    );
  }

  double get totalPrice => (product.price * selectedQuantity);
}

class RecipeModel {
  final String id;
  final String titleAr;
  final String titleEn;
  final String category; // 'أطباق رئيسية', 'مشروبات وعصائر', 'سلطات ومقبلات', 'حلويات ومعجنات', 'فطور صحي', 'كيتو ورشاقة'
  final String prepTime;
  final int cookTimeMinutes;
  final String servings;
  final String difficulty; // 'سهل', 'متوسط', 'شيف ماستر'
  final String imageUrl;
  final double discountPercent;
  final int calories;
  final double rating;
  final int reviewsCount;
  final List<String> allergens; // 'لاكتوز', 'جلوتين', 'مكسرات', 'بيض', 'سمك'
  final List<String> dietaryTags; // 'نباتي', 'كيتو', 'خالٍ من الجلوتين', 'خالٍ من اللاكتوز', 'بروتين عالي'
  final List<String> steps;
  final List<RecipeIngredient> ingredients;
  final bool isCustom;

  const RecipeModel({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.category,
    required this.prepTime,
    this.cookTimeMinutes = 30,
    required this.servings,
    required this.difficulty,
    required this.imageUrl,
    this.discountPercent = 15.0,
    this.calories = 450,
    this.rating = 4.9,
    this.reviewsCount = 120,
    this.allergens = const [],
    this.dietaryTags = const [],
    required this.steps,
    required this.ingredients,
    this.isCustom = false,
  });

  /// Total price of all currently selected ingredients with their quantities
  double get originalTotalPrice {
    return ingredients.where((i) => i.isSelected).fold(
          0.0,
          (sum, ing) => sum + ing.totalPrice,
        );
  }

  /// Bundle price after applying recipe discount
  double get bundlePrice {
    final original = originalTotalPrice;
    if (original == 0) return 0.0;
    return original * (1.0 - (discountPercent / 100.0));
  }

  /// Calculated bundle savings in currency
  double get savingsAmount => originalTotalPrice - bundlePrice;

  /// Number of active/checked ingredients
  int get selectedIngredientsCount =>
      ingredients.where((i) => i.isSelected).length;

  /// Check if the recipe contains an allergen
  bool hasAllergen(String allergen) {
    return allergens.any((a) => a.toLowerCase().contains(allergen.toLowerCase()));
  }

  /// Check if the recipe satisfies a dietary tag
  bool hasDietaryTag(String tag) {
    return dietaryTags.any((t) => t.toLowerCase().contains(tag.toLowerCase()));
  }

  /// Clone recipe with updated fields
  RecipeModel copyWith({
    String? id,
    String? titleAr,
    String? titleEn,
    String? category,
    String? prepTime,
    int? cookTimeMinutes,
    String? servings,
    String? difficulty,
    String? imageUrl,
    double? discountPercent,
    int? calories,
    double? rating,
    int? reviewsCount,
    List<String>? allergens,
    List<String>? dietaryTags,
    List<String>? steps,
    List<RecipeIngredient>? ingredients,
    bool? isCustom,
  }) {
    return RecipeModel(
      id: id ?? this.id,
      titleAr: titleAr ?? this.titleAr,
      titleEn: titleEn ?? this.titleEn,
      category: category ?? this.category,
      prepTime: prepTime ?? this.prepTime,
      cookTimeMinutes: cookTimeMinutes ?? this.cookTimeMinutes,
      servings: servings ?? this.servings,
      difficulty: difficulty ?? this.difficulty,
      imageUrl: imageUrl ?? this.imageUrl,
      discountPercent: discountPercent ?? this.discountPercent,
      calories: calories ?? this.calories,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      allergens: allergens ?? this.allergens,
      dietaryTags: dietaryTags ?? this.dietaryTags,
      steps: steps ?? this.steps,
      ingredients: ingredients ?? this.ingredients,
      isCustom: isCustom ?? this.isCustom,
    );
  }
}
