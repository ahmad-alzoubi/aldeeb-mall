import 'package:flutter/foundation.dart';
import '../models/recipe_model.dart';
import '../models/product_model.dart';
import '../data/default_recipes.dart';

class RecipeProvider extends ChangeNotifier {
  List<RecipeModel> _recipes = [];
  final List<String> _customCategories = [];

  // Filter & Search states
  String _selectedCategory = 'الكل';
  String _searchQuery = '';
  double _minPrice = 0.0;
  double _maxPrice = 150.0;
  bool _isPriceFilterActive = false;

  final Set<String> _excludedAllergens = {};
  final Set<String> _selectedDietaryTags = {};
  final Set<String> _selectedProductIds = {};
  String? _selectedDifficulty;
  int? _maxPrepTimeMinutes;
  String _sortBy = 'popular'; // 'popular', 'price_asc', 'price_desc', 'rating', 'time', 'discount'

  RecipeProvider() {
    _recipes = DefaultRecipes.getRecipes();
  }

  // Getters
  List<RecipeModel> get allRecipes => [..._recipes];
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  double get minPrice => _minPrice;
  double get maxPrice => _maxPrice;
  bool get isPriceFilterActive => _isPriceFilterActive;
  Set<String> get excludedAllergens => {..._excludedAllergens};
  Set<String> get selectedDietaryTags => {..._selectedDietaryTags};
  Set<String> get selectedProductIds => {..._selectedProductIds};
  String? get selectedDifficulty => _selectedDifficulty;
  int? get maxPrepTimeMinutes => _maxPrepTimeMinutes;
  String get sortBy => _sortBy;

  static const List<String> defaultCategories = [
    'أطباق رئيسية',
    'مشروبات وعصائر',
    'فطور ومخبوزات',
    'سلطات ومقبلات',
    'حلويات ومعجنات',
  ];

  List<String> get categories {
    final list = ['الكل', ...defaultCategories, ..._customCategories];
    return list.toSet().toList(); // unique
  }

  int get activeFiltersCount {
    int count = 0;
    if (_isPriceFilterActive) count++;
    count += _excludedAllergens.length;
    count += _selectedDietaryTags.length;
    count += _selectedProductIds.length;
    if (_selectedDifficulty != null && _selectedDifficulty != 'الكل') count++;
    if (_maxPrepTimeMinutes != null) count++;
    if (_sortBy != 'popular') count++;
    return count;
  }

  List<RecipeModel> get filteredRecipes {
    var result = List<RecipeModel>.from(_recipes);

    // 1. Category Filter
    if (_selectedCategory != 'الكل') {
      result = result.where((r) => r.category == _selectedCategory).toList();
    }

    // 2. Search Query
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      result = result.where((r) {
        final matchTitle = r.titleAr.toLowerCase().contains(q) ||
            r.titleEn.toLowerCase().contains(q);
        final matchCategory = r.category.toLowerCase().contains(q);
        final matchIngredient = r.ingredients.any((i) =>
            i.nameAr.toLowerCase().contains(q) ||
            i.product.nameAr.toLowerCase().contains(q));
        return matchTitle || matchCategory || matchIngredient;
      }).toList();
    }

    // 3. Price Filter
    if (_isPriceFilterActive) {
      result = result.where((r) {
        final price = r.bundlePrice;
        return price >= _minPrice && price <= _maxPrice;
      }).toList();
    }

    // 4. Allergen Exclusion Filter (e.g., exclude recipes with Lactose)
    if (_excludedAllergens.isNotEmpty) {
      result = result.where((r) {
        for (final allergen in _excludedAllergens) {
          if (r.hasAllergen(allergen)) {
            return false;
          }
        }
        return true;
      }).toList();
    }

    // 5. Dietary Tags (Must match all selected dietary tags)
    if (_selectedDietaryTags.isNotEmpty) {
      result = result.where((r) {
        for (final tag in _selectedDietaryTags) {
          if (!r.hasDietaryTag(tag)) {
            return false;
          }
        }
        return true;
      }).toList();
    }

    // 6. Products Filter (Recipes containing selected products)
    if (_selectedProductIds.isNotEmpty) {
      result = result.where((r) {
        return r.ingredients.any((ing) => _selectedProductIds.contains(ing.product.id));
      }).toList();
    }

    // 7. Difficulty Filter
    if (_selectedDifficulty != null && _selectedDifficulty != 'الكل') {
      result = result.where((r) => r.difficulty == _selectedDifficulty).toList();
    }

    // 8. Max Prep Time
    if (_maxPrepTimeMinutes != null) {
      result = result.where((r) => r.cookTimeMinutes <= _maxPrepTimeMinutes!).toList();
    }

    // 9. Sorting
    switch (_sortBy) {
      case 'price_asc':
        result.sort((a, b) => a.bundlePrice.compareTo(b.bundlePrice));
        break;
      case 'price_desc':
        result.sort((a, b) => b.bundlePrice.compareTo(a.bundlePrice));
        break;
      case 'rating':
        result.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'time':
        result.sort((a, b) => a.cookTimeMinutes.compareTo(b.cookTimeMinutes));
        break;
      case 'discount':
        result.sort((a, b) => b.discountPercent.compareTo(a.discountPercent));
        break;
      case 'popular':
      default:
        result.sort((a, b) => b.reviewsCount.compareTo(a.reviewsCount));
        break;
    }

    return result;
  }

  // State Mutators
  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setPriceRange(double min, double max) {
    _minPrice = min;
    _maxPrice = max;
    _isPriceFilterActive = true;
    notifyListeners();
  }

  void clearPriceFilter() {
    _minPrice = 0.0;
    _maxPrice = 150.0;
    _isPriceFilterActive = false;
    notifyListeners();
  }

  void toggleAllergenExclusion(String allergen) {
    if (_excludedAllergens.contains(allergen)) {
      _excludedAllergens.remove(allergen);
    } else {
      _excludedAllergens.add(allergen);
    }
    notifyListeners();
  }

  void toggleDietaryTag(String tag) {
    if (_selectedDietaryTags.contains(tag)) {
      _selectedDietaryTags.remove(tag);
    } else {
      _selectedDietaryTags.add(tag);
    }
    notifyListeners();
  }

  void toggleProductFilter(String productId) {
    if (_selectedProductIds.contains(productId)) {
      _selectedProductIds.remove(productId);
    } else {
      _selectedProductIds.add(productId);
    }
    notifyListeners();
  }

  void setDifficulty(String? difficulty) {
    _selectedDifficulty = difficulty;
    notifyListeners();
  }

  void setMaxPrepTime(int? minutes) {
    _maxPrepTimeMinutes = minutes;
    notifyListeners();
  }

  void setSortBy(String sortBy) {
    _sortBy = sortBy;
    notifyListeners();
  }

  void resetFilters() {
    _isPriceFilterActive = false;
    _minPrice = 0.0;
    _maxPrice = 150.0;
    _excludedAllergens.clear();
    _selectedDietaryTags.clear();
    _selectedProductIds.clear();
    _selectedDifficulty = null;
    _maxPrepTimeMinutes = null;
    _sortBy = 'popular';
    notifyListeners();
  }

  // Adding new categories & recipes
  void addNewCategory(String categoryName) {
    final trimmed = categoryName.trim();
    if (trimmed.isNotEmpty && !categories.contains(trimmed)) {
      _customCategories.add(trimmed);
      _selectedCategory = trimmed;
      notifyListeners();
    }
  }

  void addCustomRecipe(RecipeModel recipe) {
    if (!categories.contains(recipe.category)) {
      _customCategories.add(recipe.category);
    }
    _recipes.insert(0, recipe);
    _selectedCategory = recipe.category;
    notifyListeners();
  }

  // Swapping ingredient product in a recipe
  void swapIngredient(String recipeId, String ingredientId, ProductModel newProduct) {
    final recipeIndex = _recipes.indexWhere((r) => r.id == recipeId);
    if (recipeIndex == -1) return;

    final recipe = _recipes[recipeIndex];
    final updatedIngredients = recipe.ingredients.map((ing) {
      if (ing.id == ingredientId) {
        return ing.copyWith(
          product: newProduct,
          nameAr: newProduct.nameAr,
        );
      }
      return ing;
    }).toList();

    _recipes[recipeIndex] = recipe.copyWith(ingredients: updatedIngredients);
    notifyListeners();
  }

  // Toggle ingredient selection in recipe
  void toggleIngredientSelection(String recipeId, String ingredientId) {
    final recipeIndex = _recipes.indexWhere((r) => r.id == recipeId);
    if (recipeIndex == -1) return;

    final recipe = _recipes[recipeIndex];
    final updatedIngredients = recipe.ingredients.map((ing) {
      if (ing.id == ingredientId) {
        return ing.copyWith(isSelected: !ing.isSelected);
      }
      return ing;
    }).toList();

    _recipes[recipeIndex] = recipe.copyWith(ingredients: updatedIngredients);
    notifyListeners();
  }

  // Update ingredient quantity in recipe
  void updateIngredientQuantity(String recipeId, String ingredientId, double newQty) {
    if (newQty <= 0) return;
    final recipeIndex = _recipes.indexWhere((r) => r.id == recipeId);
    if (recipeIndex == -1) return;

    final recipe = _recipes[recipeIndex];
    final updatedIngredients = recipe.ingredients.map((ing) {
      if (ing.id == ingredientId) {
        return ing.copyWith(selectedQuantity: newQty);
      }
      return ing;
    }).toList();

    _recipes[recipeIndex] = recipe.copyWith(ingredients: updatedIngredients);
    notifyListeners();
  }
}
