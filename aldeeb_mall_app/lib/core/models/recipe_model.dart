import 'product_model.dart';

class RecipeIngredient {
  final String nameAr;
  final String quantityNeeded;
  final ProductModel product;

  const RecipeIngredient({
    required this.nameAr,
    required this.quantityNeeded,
    required this.product,
  });
}

class RecipeModel {
  final String id;
  final String titleAr;
  final String titleEn;
  final String category; // 'أطباق رئيسية', 'سلطات ومقبلات', 'فطور صحي', 'عصائر'
  final String prepTime;
  final String servings;
  final String difficulty;
  final String imageUrl;
  final double discountPercent;
  final List<String> steps;
  final List<RecipeIngredient> ingredients;

  const RecipeModel({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.category,
    required this.prepTime,
    required this.servings,
    required this.difficulty,
    required this.imageUrl,
    this.discountPercent = 15.0,
    required this.steps,
    required this.ingredients,
  });

  double get originalTotalPrice =>
      ingredients.fold(0.0, (sum, ing) => sum + ing.product.price);

  double get bundlePrice =>
      originalTotalPrice * (1.0 - (discountPercent / 100.0));
}
