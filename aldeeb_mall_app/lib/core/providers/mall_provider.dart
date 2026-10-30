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

class MallProvider extends ChangeNotifier {
  final SupabaseService _service = SupabaseService();

  List<CategoryModel> _categories = [];
  List<ProductModel> _products = [];
  List<BannerModel> _banners = [];
  final Set<String> _favoriteProductIds = {};

  String? _selectedCategoryId;
  String _searchQuery = '';
  ProductSortOption _currentSort = ProductSortOption.featured;
  bool _isExpress15Min = false;
  bool _isLoading = false;

  List<CategoryModel> get categories => _categories;
  List<BannerModel> get banners => _banners;
  String? get selectedCategoryId => _selectedCategoryId;
  String get searchQuery => _searchQuery;
  ProductSortOption get currentSort => _currentSort;
  bool get isLoading => _isLoading;
  bool get isExpress15Min => _isExpress15Min;
  Set<String> get favoriteProductIds => _favoriteProductIds;

  void toggleExpress15Min(bool value) {
    _isExpress15Min = value;
    notifyListeners();
  }

  // Filtered Products
  List<ProductModel> get filteredProducts {
    var list = List<ProductModel>.from(_products);

    if (_selectedCategoryId != null) {
      list = list.where((p) => p.categoryId == _selectedCategoryId).toList();
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
}
