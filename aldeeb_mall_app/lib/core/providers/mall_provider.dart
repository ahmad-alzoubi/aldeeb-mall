import 'package:flutter/foundation.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/banner_model.dart';
import '../models/flash_deal_model.dart';
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
  final List<FlashDealModel> _flashDeals = [
    const FlashDealModel(
      id: 'fd-1',
      productId: 'p1',
      productNameAr: 'موز فلبيني طازج كافنديش درجة أولى',
      productImage: 'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?auto=format&fit=crop&w=400&q=80',
      originalPrice: 22000.0,
      dealPrice: 16500.0,
      discountPercent: 25,
      totalQuota: 250,
      claimedQuota: 195,
      endsAt: '03:45:20',
      isActive: true,
    ),
    const FlashDealModel(
      id: 'fd-2',
      productId: 'p3',
      productNameAr: 'طماطم مزارع محلية قطاف الصباح',
      productImage: 'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?auto=format&fit=crop&w=400&q=80',
      originalPrice: 15000.0,
      dealPrice: 9500.0,
      discountPercent: 36,
      totalQuota: 180,
      claimedQuota: 154,
      endsAt: '02:30:15',
      isActive: true,
    ),
    const FlashDealModel(
      id: 'fd-3',
      productId: 'p5',
      productNameAr: 'دجاج التنمية طازج مبرد 1000 غرام',
      productImage: 'https://images.unsplash.com/photo-1587593810167-a84920ea0781?auto=format&fit=crop&w=400&q=80',
      originalPrice: 42000.0,
      dealPrice: 31500.0,
      discountPercent: 25,
      totalQuota: 120,
      claimedQuota: 88,
      endsAt: '05:15:00',
      isActive: true,
    ),
    const FlashDealModel(
      id: 'fd-4',
      productId: 'p8',
      productNameAr: 'زيت دوار الشمس عافية نقي 2 لتر',
      productImage: 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?auto=format&fit=crop&w=400&q=80',
      originalPrice: 65000.0,
      dealPrice: 49000.0,
      discountPercent: 24,
      totalQuota: 100,
      claimedQuota: 72,
      endsAt: '04:10:45',
      isActive: true,
    ),
    const FlashDealModel(
      id: 'fd-5',
      productId: 'p12',
      productNameAr: 'أرز بسمتي هندي كلاسيك 5 كغ',
      productImage: 'https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&w=400&q=80',
      originalPrice: 110000.0,
      dealPrice: 82000.0,
      discountPercent: 25,
      totalQuota: 80,
      claimedQuota: 64,
      endsAt: '01:50:30',
      isActive: true,
    ),
  ];
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

  List<FlashDealModel> get flashDeals => _flashDeals.where((d) => d.isActive).toList();

  ProductModel getProductForFlashDeal(FlashDealModel deal) {
    try {
      return _products.firstWhere(
        (p) => p.id == deal.productId || p.nameAr == deal.productNameAr,
      );
    } catch (_) {
      return ProductModel(
        id: deal.productId.isNotEmpty ? deal.productId : deal.id,
        nameAr: deal.productNameAr,
        nameEn: 'Flash Deal',
        price: deal.dealPrice,
        originalPrice: deal.originalPrice,
        discountPercent: deal.discountPercent,
        images: [deal.productImage],
        stockQuantity: deal.remainingUnits,
        isDailyDeal: true,
      );
    }
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
