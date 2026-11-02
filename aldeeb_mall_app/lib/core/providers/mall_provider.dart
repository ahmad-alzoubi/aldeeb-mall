import 'package:flutter/foundation.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/banner_model.dart';
import '../services/supabase_service.dart';

enum ProductSortOption {
  featured,
  priceLowToHigh,
  priceHighToLow,
  highestDiscount,
  topRated,
}

enum CategoryDisplayMode {
  withTitle, // صورة مع عنوان تحتيها
  imageOnly, // صورة بس لحالها
}

class MallProvider extends ChangeNotifier {
  final SupabaseService _service = SupabaseService();

  List<CategoryModel> _categories = [];
  List<ProductModel> _products = [];
  List<BannerModel> _banners = [];
  final Set<String> _favoriteProductIds = {};

  String? _selectedCategoryId;
  String? _selectedDietaryFilter; // 'organic', 'gluten_free', 'keto', 'high_protein'
  String _searchQuery = '';
  ProductSortOption _currentSort = ProductSortOption.featured;
  CategoryDisplayMode _categoryDisplayMode = CategoryDisplayMode.withTitle;
  bool _isExpress15Min = false;
  bool _isLoading = false;

  List<CategoryModel> get categories => _categories;
  List<ProductModel> get products => _products.where((p) => !p.isDraft && p.status == 'published').toList();
  List<BannerModel> get banners => _banners;

  List<BannerModel> get heroBanners {
    final list = _banners.where((b) => b.slot == 'hero' && b.isActive).toList();
    if (list.isEmpty) {
      // Fallback: if no banners explicitly marked as 'hero', return all active banners except side cards
      final filtered = _banners.where((b) => b.slot != 'side_top' && b.slot != 'side_bottom' && b.isActive).toList();
      return filtered.isNotEmpty ? filtered : _banners;
    }
    return list;
  }

  BannerModel? get sideTopBanner {
    try {
      return _banners.firstWhere((b) => b.slot == 'side_top' && b.isActive);
    } catch (_) {
      return null;
    }
  }

  BannerModel? get sideBottomBanner {
    try {
      return _banners.firstWhere((b) => b.slot == 'side_bottom' && b.isActive);
    } catch (_) {
      return null;
    }
  }

  List<BannerModel> get secondaryBanners {
    final list = _banners.where((b) => b.slot == 'middle_secondary' && b.isActive).toList();
    if (list.isNotEmpty) return list;
    return _banners.where((b) => b.id.startsWith('b_sec')).toList();
  }

  String get catalogCountText {
    final count = _products.length;
    if (count >= 100) return '$count';
    return '10,000';
  }

  List<ProductModel> get weeklyDeals {
    final list = _products.where((p) => p.isDailyDeal || p.discountPercent >= 20).toList();
    return list.isNotEmpty ? list : _products.take(6).toList();
  }

  List<ProductModel> get cantMissDeals {
    final list = _products.where((p) => p.stockQuantity < 100 && p.discountPercent >= 15).toList();
    return list.isNotEmpty ? list : _products.reversed.take(6).toList();
  }

  List<ProductModel> get newArrivals {
    return _products.reversed.take(8).toList();
  }

  List<ProductModel> get megaDiscounts {
    final list = List<ProductModel>.from(_products);
    list.sort((a, b) => b.discountPercent.compareTo(a.discountPercent));
    return list.take(8).toList();
  }
  String? get selectedCategoryId => _selectedCategoryId;
  String? get selectedDietaryFilter => _selectedDietaryFilter;
  String get searchQuery => _searchQuery;
  ProductSortOption get currentSort => _currentSort;
  CategoryDisplayMode get categoryDisplayMode => _categoryDisplayMode;
  bool get isLoading => _isLoading;
  bool get isExpress15Min => _isExpress15Min;
  Set<String> get favoriteProductIds => _favoriteProductIds;

  void toggleExpress15Min(bool value) {
    _isExpress15Min = value;
    notifyListeners();
  }

  void setDietaryFilter(String? filter) {
    if (_selectedDietaryFilter == filter) {
      _selectedDietaryFilter = null;
    } else {
      _selectedDietaryFilter = filter;
    }
    notifyListeners();
  }

  static bool _matchesCategory(String itemCatId, String queryCatId) {
    if (itemCatId == queryCatId) return true;
    const map = {
      'c1': 'c0000000-0000-0000-0000-000000000001',
      'c2': 'c0000000-0000-0000-0000-000000000002',
      'c3': 'c0000000-0000-0000-0000-000000000003',
      'c4': 'c0000000-0000-0000-0000-000000000004',
      'c5': 'c0000000-0000-0000-0000-000000000005',
      'c6': 'c0000000-0000-0000-0000-000000000006',
      'c7': 'c0000000-0000-0000-0000-000000000007',
      'c8': 'c0000000-0000-0000-0000-000000000008',
      'c9': 'c0000000-0000-0000-0000-000000000009',
    };
    return map[itemCatId] == queryCatId || map[queryCatId] == itemCatId;
  }

  // Filtered Products
  List<ProductModel> get filteredProducts {
    var list = List<ProductModel>.from(_products);

    if (_selectedCategoryId != null) {
      list = list.where((p) => p.categoryId == _selectedCategoryId || (p.categoryId != null && _matchesCategory(p.categoryId!, _selectedCategoryId!))).toList();
    }

    if (_selectedDietaryFilter != null) {
      switch (_selectedDietaryFilter) {
        case 'organic':
          list = list.where((p) => p.isOrganic).toList();
          break;
        case 'gluten_free':
          list = list.where((p) => p.isGlutenFree).toList();
          break;
        case 'keto':
          list = list.where((p) => p.isKeto).toList();
          break;
        case 'high_protein':
          list = list.where((p) => p.isHighProtein).toList();
          break;
      }
    }

    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.toLowerCase().trim();
      list = list.where((p) =>
          p.nameAr.toLowerCase().contains(query) ||
          p.nameEn.toLowerCase().contains(query) ||
          (p.brand?.toLowerCase().contains(query) ?? false) ||
          (p.barcode?.contains(query) ?? false)).toList();
    }

    switch (_currentSort) {
      case ProductSortOption.priceLowToHigh:
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case ProductSortOption.priceHighToLow:
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case ProductSortOption.highestDiscount:
        list.sort((a, b) => b.discountPercent.compareTo(a.discountPercent));
        break;
      case ProductSortOption.topRated:
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case ProductSortOption.featured:
        list.sort((a, b) => (b.isFeatured ? 1 : 0).compareTo(a.isFeatured ? 1 : 0));
        break;
    }

    return list;
  }

  // Daily Deals
  List<ProductModel> get dailyDeals {
    return _products.where((p) => p.isDailyDeal || p.hasDiscount).toList();
  }

  // Featured Products
  List<ProductModel> get featuredProducts {
    return _products.where((p) => p.isFeatured).toList();
  }

  Future<void> loadMallData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.getCategories(),
        _service.getProducts(),
        _service.getBanners(),
      ]);

      _categories = results[0] as List<CategoryModel>;
      _products = results[1] as List<ProductModel>;
      _banners = results[2] as List<BannerModel>;
    } catch (e) {
      // Keep defaults
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectCategory(String? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSortOption(ProductSortOption option) {
    _currentSort = option;
    notifyListeners();
  }

  void toggleFavorite(String productId) {
    if (_favoriteProductIds.contains(productId)) {
      _favoriteProductIds.remove(productId);
    } else {
      _favoriteProductIds.add(productId);
    }
    notifyListeners();
  }

  bool isFavorite(String productId) => _favoriteProductIds.contains(productId);

  // Category Management & Display Options
  void setCategoryDisplayMode(CategoryDisplayMode mode) {
    _categoryDisplayMode = mode;
    notifyListeners();
  }

  void addCategory(CategoryModel category) {
    // Insert at beginning or end
    _categories.insert(0, category);
    notifyListeners();
  }

  void updateCategory(CategoryModel updated) {
    final index = _categories.indexWhere((c) => c.id == updated.id);
    if (index != -1) {
      _categories[index] = updated;
      notifyListeners();
    }
  }

  void deleteCategory(String id) {
    _categories.removeWhere((c) => c.id == id);
    if (_selectedCategoryId == id) {
      _selectedCategoryId = null;
    }
    notifyListeners();
  }

  void toggleCategoryTitleDisplay(String categoryId) {
    final index = _categories.indexWhere((c) => c.id == categoryId);
    if (index != -1) {
      final current = _categories[index];
      _categories[index] = current.copyWith(showTitle: !current.showTitle);
      notifyListeners();
    }
  }
}
