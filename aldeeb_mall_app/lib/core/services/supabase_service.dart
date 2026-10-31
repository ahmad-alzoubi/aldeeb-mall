import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_constants.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/banner_model.dart';
import '../models/coupon_model.dart';
import '../models/order_model.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  bool _isInitialized = false;

  Future<void> initialize() async {
    try {
      if (SupabaseConstants.supabaseUrl.contains('YOUR_PROJECT_ID')) {
        // Not configured yet, will use offline mock store data
        _isInitialized = false;
        return;
      }
      await Supabase.initialize(
        url: SupabaseConstants.supabaseUrl,
        anonKey: SupabaseConstants.supabaseAnonKey,
      );
      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
    }
  }

  bool get isConnected => _isInitialized;

  SupabaseClient? get client => _isInitialized ? Supabase.instance.client : null;

  // 1. Fetch Categories
  Future<List<CategoryModel>> getCategories() async {
    if (_isInitialized && client != null) {
      try {
        final response = await client!
            .from(SupabaseConstants.categoriesTable)
            .select()
            .eq('is_active', true)
            .order('sort_order', ascending: true);
        return (response as List).map((e) => CategoryModel.fromJson(e)).toList();
      } catch (e) {
        // fallback to default categories
      }
    }
    return _defaultCategories;
  }

  // 2. Fetch Products
  Future<List<ProductModel>> getProducts({String? categoryId, bool? isDailyDeal, bool? isFeatured}) async {
    if (_isInitialized && client != null) {
      try {
        var query = client!
            .from(SupabaseConstants.productsTable)
            .select()
            .eq('is_active', true);

        if (categoryId != null) {
          query = query.eq('category_id', categoryId);
        }
        if (isDailyDeal == true) {
          query = query.eq('is_daily_deal', true);
        }
        if (isFeatured == true) {
          query = query.eq('is_featured', true);
        }

        final response = await query.order('sales_count', ascending: false);
        return (response as List).map((e) => ProductModel.fromJson(e)).toList();
      } catch (e) {
        // fallback
      }
    }

    var list = List<ProductModel>.from(_defaultProducts);
    if (categoryId != null) {
      list = list.where((p) => p.categoryId == categoryId).toList();
    }
    if (isDailyDeal == true) {
      list = list.where((p) => p.isDailyDeal).toList();
    }
    if (isFeatured == true) {
      list = list.where((p) => p.isFeatured).toList();
    }
    return list;
  }

  // 3. Fetch Banners
  Future<List<BannerModel>> getBanners() async {
    if (_isInitialized && client != null) {
      try {
        final response = await client!
            .from(SupabaseConstants.bannersTable)
            .select()
            .eq('is_active', true)
            .order('sort_order', ascending: true);
        return (response as List).map((e) => BannerModel.fromJson(e)).toList();
      } catch (e) {
        // fallback
      }
    }
    return _defaultBanners;
  }

  // 4. Validate Coupon
  Future<CouponModel?> validateCoupon(String code, double subtotal) async {
    final cleanCode = code.trim().toUpperCase();
    if (_isInitialized && client != null) {
      try {
        final response = await client!
            .from(SupabaseConstants.couponsTable)
            .select()
            .eq('code', cleanCode)
            .eq('is_active', true)
            .maybeSingle();

        if (response != null) {
          final coupon = CouponModel.fromJson(response);
          if (subtotal >= coupon.minOrderAmount) {
            return coupon;
          }
        }
      } catch (e) {
        // fallback
      }
    }

    final match = _defaultCoupons.where((c) => c.code == cleanCode).toList();
    if (match.isNotEmpty && subtotal >= match.first.minOrderAmount) {
      return match.first;
    }
    return null;
  }

  // 5. Place Order
  Future<OrderModel> createOrder({
    required String orderNumber,
    required double subtotal,
    required double deliveryFee,
    required double discountAmount,
    required int loyaltyPointsUsed,
    required double loyaltyDiscount,
    required double totalAmount,
    required String deliverySlot,
    required String paymentMethod,
    String? notes,
  }) async {
    final newOrder = OrderModel(
      id: 'ord-${DateTime.now().millisecondsSinceEpoch}',
      orderNumber: orderNumber,
      status: 'pending',
      deliverySlot: deliverySlot,
      paymentMethod: paymentMethod,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      discountAmount: discountAmount,
      loyaltyPointsUsed: loyaltyPointsUsed,
      loyaltyDiscount: loyaltyDiscount,
      totalAmount: totalAmount,
      createdAt: DateTime.now(),
      notes: notes,
      driverName: 'أحمد مندوب الديب مول',
      driverPhone: '+971509876543',
    );

    if (_isInitialized && client != null) {
      try {
        final userId = client!.auth.currentUser?.id;
        await client!.from(SupabaseConstants.ordersTable).insert({
          'order_number': orderNumber,
          'user_id': userId,
          'status': 'pending',
          'delivery_slot': deliverySlot,
          'payment_method': paymentMethod,
          'subtotal': subtotal,
          'delivery_fee': deliveryFee,
          'discount_amount': discountAmount,
          'loyalty_points_used': loyaltyPointsUsed,
          'loyalty_discount': loyaltyDiscount,
          'total_amount': totalAmount,
          'notes': notes,
        });
      } catch (e) {
        // Log silently
      }
    }

    return newOrder;
  }

  // ===========================================================================
  // Hyper-Realistic In-Memory Seed (Carrefour Mall Catalog)
  // ===========================================================================
  static List<ProductModel> get defaultProducts => _defaultProducts;
  static List<CategoryModel> get defaultCategories => _defaultCategories;
  static final List<CategoryModel> _defaultCategories = [
    const CategoryModel(
      id: 'c1',
      nameAr: 'خضار وفواكه طازجة',
      nameEn: 'Fresh Produce',
      slug: 'fresh-produce',
      iconName: 'apple',
      imageUrl: 'https://images.unsplash.com/photo-1610348725531-843dff563e2c?auto=format&fit=crop&w=600&q=80',
      sortOrder: 1,
    ),
    const CategoryModel(
      id: 'c2',
      nameAr: 'ألبان وأجبان وبيض',
      nameEn: 'Dairy, Cheese & Eggs',
      slug: 'dairy-eggs',
      iconName: 'milk',
      imageUrl: 'https://images.unsplash.com/photo-1550583724-b2692b85b150?auto=format&fit=crop&w=600&q=80',
      sortOrder: 2,
    ),
    const CategoryModel(
      id: 'c3',
      nameAr: 'لحوم ودواجن وأسماك',
      nameEn: 'Meat & Poultry',
      slug: 'meat-poultry',
      iconName: 'beef',
      imageUrl: 'https://images.unsplash.com/photo-1607623814075-e51df1bdc82f?auto=format&fit=crop&w=600&q=80',
      sortOrder: 3,
    ),
    const CategoryModel(
      id: 'c4',
      nameAr: 'مخبوزات وحلويات',
      nameEn: 'Bakery & Pastries',
      slug: 'bakery-pastries',
      iconName: 'croissant',
      imageUrl: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=600&q=80',
      sortOrder: 4,
    ),
    const CategoryModel(
      id: 'c5',
      nameAr: 'مشروبات ومياه وعصائر',
      nameEn: 'Beverages & Water',
      slug: 'beverages-water',
      iconName: 'cup-soda',
      imageUrl: 'https://images.unsplash.com/photo-1527661591475-527312dd65f5?auto=format&fit=crop&w=600&q=80',
      sortOrder: 5,
    ),
    const CategoryModel(
      id: 'c6',
      nameAr: 'منظفات وعناية بالمنزل',
      nameEn: 'Cleaning & Household',
      slug: 'cleaning-household',
      iconName: 'sparkles',
      imageUrl: 'https://images.unsplash.com/photo-1585421514738-01798e348b17?auto=format&fit=crop&w=600&q=80',
      sortOrder: 6,
    ),
  ];

  static final List<BannerModel> _defaultBanners = [
    const BannerModel(
      id: 'b1',
      titleAr: 'مهرجان الصفقات الكبرى في الديب مول 🛒',
      titleEn: 'Mega Supermarket Savings Festival',
      subtitleAr: 'خصومات حصرية تصل إلى 50% على المواد الغذائية والتموينية',
      imageUrl: 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=1200&q=80',
      targetType: 'deal',
      badgeAr: 'خصم حتى 50%',
    ),
    const BannerModel(
      id: 'b2',
      titleAr: 'سوق الخضار والفواكه الطازجة قطاف اليوم 🍎',
      titleEn: 'Fresh Daily Produce Market',
      subtitleAr: 'من المزرعة إلى مائدتك بتوصيل فوري مبرد وسريع',
      imageUrl: 'https://images.unsplash.com/photo-1610348725531-843dff563e2c?auto=format&fit=crop&w=1200&q=80',
      targetType: 'category',
      badgeAr: 'طازج يومياً',
    ),
    const BannerModel(
      id: 'b3',
      titleAr: 'توصيل فوري إكسبريس خلال 60 دقيقة 🛵',
      titleEn: 'Express 60-Minute Fast Delivery',
      subtitleAr: 'اطلب مستلزمات بيتك الآن واستلمها على بابك',
      imageUrl: 'https://images.unsplash.com/photo-1526367790999-0150786686a2?auto=format&fit=crop&w=1200&q=80',
      targetType: 'deal',
      badgeAr: 'سريع ومضمون',
    ),
  ];

  static final List<ProductModel> _defaultProducts = [
    const ProductModel(
      id: 'p1',
      categoryId: 'c1',
      nameAr: 'موز فلبيني طازج كافنديش درجة أولى',
      nameEn: 'Fresh Cavendish Bananas',
      descriptionAr: 'موز أصفر طازج وغني بالطاقة والبوتاسيوم، مستورد يومياً ومثالي للوجبات الصحية.',
      brand: 'طازج',
      price: 4.95,
      originalPrice: 6.50,
      discountPercent: 24,
      unit: 'kg',
      weightStep: 0.5,
      stockQuantity: 450,
      images: ['https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?auto=format&fit=crop&w=600&q=80'],
      isFeatured: true,
      isDailyDeal: true,
      rating: 4.9,
      salesCount: 1280,
    ),
    const ProductModel(
      id: 'p2',
      categoryId: 'c1',
      nameAr: 'تفاح رويال جالا إيطالي مقرمش فاخر',
      nameEn: 'Italian Royal Gala Apples',
      descriptionAr: 'تفاح أحمر إيطالي حلو المذاق ومقرمش، معبأ بعناية فائقة للحفاظ على النضارة.',
      brand: 'طازج',
      price: 7.50,
      originalPrice: 9.95,
      discountPercent: 25,
      unit: 'kg',
      weightStep: 0.5,
      stockQuantity: 320,
      images: ['https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?auto=format&fit=crop&w=600&q=80'],
      isFeatured: true,
      isDailyDeal: false,
      rating: 4.8,
      salesCount: 890,
    ),
    const ProductModel(
      id: 'p3',
      categoryId: 'c1',
      nameAr: 'طماطم مزارع محلية قطاف الصباح',
      nameEn: 'Fresh Local Vine Tomatoes',
      descriptionAr: 'طماطم حمراء نضرة تم قطافها صباح اليوم، ممتازة للطبخ والسلطات اليومية.',
      brand: 'محلي',
      price: 3.75,
      originalPrice: 5.00,
      discountPercent: 25,
      unit: 'kg',
      weightStep: 0.5,
      stockQuantity: 500,
      images: ['https://images.unsplash.com/photo-1592924357228-91a4daadcfea?auto=format&fit=crop&w=600&q=80'],
      isFeatured: false,
      isDailyDeal: true,
      rating: 4.7,
      salesCount: 1450,
    ),
    const ProductModel(
      id: 'p4',
      categoryId: 'c2',
      nameAr: 'حليب المراعي كامل الدسم طازج 2 لتر',
      nameEn: 'Almarai Fresh Milk Full Fat 2L',
      descriptionAr: 'حليب بقري نقي 100% طازج كامل الدسم معزز بفيتامين د والكالسيوم لجميع أفراد الأسرة.',
      brand: 'المراعي',
      price: 11.00,
      originalPrice: 13.50,
      discountPercent: 19,
      unit: 'bottle',
      weightStep: 1.0,
      stockQuantity: 320,
      images: ['https://images.unsplash.com/photo-1550583724-b2692b85b150?auto=format&fit=crop&w=600&q=80'],
      isFeatured: true,
      isDailyDeal: true,
      rating: 4.9,
      salesCount: 2300,
    ),
    const ProductModel(
      id: 'p5',
      categoryId: 'c2',
      nameAr: 'جبنة بوك كريمية بيضاء أصلية 500 غرام',
      nameEn: 'Puck Cream Cheese Jar 500g',
      descriptionAr: 'جبنة كريمية ناعمة وقابلة للدهن، مثالية للسندويشات والمخبوزات الصباحية.',
      brand: 'بوك',
      price: 14.50,
      originalPrice: 18.00,
      discountPercent: 19,
      unit: 'piece',
      weightStep: 1.0,
      stockQuantity: 240,
      images: ['https://images.unsplash.com/photo-1589881133595-a3c085cb731d?auto=format&fit=crop&w=600&q=80'],
      isFeatured: true,
      isDailyDeal: false,
      rating: 4.8,
      salesCount: 1150,
    ),
    const ProductModel(
      id: 'p6',
      categoryId: 'c3',
      nameAr: 'دجاج التنمية طازج مبرد 1000 غرام',
      nameEn: 'Tanmiah Fresh Chilled Chicken 1000g',
      descriptionAr: 'دجاج محلي طازج مذبوح على الشريعة الإسلامية حلال 100% دون أي مضادات حيوية.',
      brand: 'التنمية',
      price: 16.75,
      originalPrice: 21.00,
      discountPercent: 20,
      unit: 'piece',
      weightStep: 1.0,
      stockQuantity: 180,
      images: ['https://images.unsplash.com/photo-1587593810167-a84920ea0781?auto=format&fit=crop&w=600&q=80'],
      isFeatured: true,
      isDailyDeal: true,
      rating: 4.9,
      salesCount: 870,
    ),
    const ProductModel(
      id: 'p7',
      categoryId: 'c4',
      nameAr: 'كرواسان فرنسي بالزبدة الطبيعية (4 حبات)',
      nameEn: 'Fresh Butter French Croissants (Pack 4)',
      descriptionAr: 'مخبوز طازجاً كل صباح بطبقات مقرمشة وهشة غنية بطعم الزبدة الطبيعية الفاخرة.',
      brand: 'مخبز الديب',
      price: 8.50,
      originalPrice: 11.00,
      discountPercent: 23,
      unit: 'pack',
      weightStep: 1.0,
      stockQuantity: 120,
      images: ['https://images.unsplash.com/photo-1555507036-ab1f4038808a?auto=format&fit=crop&w=600&q=80'],
      isFeatured: true,
      isDailyDeal: false,
      rating: 4.9,
      salesCount: 1340,
    ),
    const ProductModel(
      id: 'p8',
      categoryId: 'c5',
      nameAr: 'مياه العين الطبيعية كرتون (24 × 500 مل)',
      nameEn: 'Al Ain Bottled Mineral Water (24 x 500ml)',
      descriptionAr: 'مياه شرب نقية متوازنة الصوديوم، معبأة بأحدث معايير الجودة العالمية.',
      brand: 'العين',
      price: 12.95,
      originalPrice: 17.50,
      discountPercent: 26,
      unit: 'carton',
      weightStep: 1.0,
      stockQuantity: 600,
      images: ['https://images.unsplash.com/photo-1527661591475-527312dd65f5?auto=format&fit=crop&w=600&q=80'],
      isFeatured: true,
      isDailyDeal: true,
      rating: 4.9,
      salesCount: 3400,
    ),
    const ProductModel(
      id: 'p9',
      categoryId: 'c6',
      nameAr: 'مسحوق غسيل تايد الأصلي الأوتوماتيكي 5 كجم',
      nameEn: 'Tide Original Automatic Detergent 5kg',
      descriptionAr: 'نظافة فائقة وبياض ناصع وإزالة لأصعب البقع مع رائحة منعشة تدوم طويلاً.',
      brand: 'تايد',
      price: 42.00,
      originalPrice: 58.00,
      discountPercent: 28,
      unit: 'pack',
      weightStep: 1.0,
      stockQuantity: 210,
      images: ['https://images.unsplash.com/photo-1585421514738-01798e348b17?auto=format&fit=crop&w=600&q=80'],
      isFeatured: true,
      isDailyDeal: true,
      rating: 4.8,
      salesCount: 1500,
    ),
    const ProductModel(
      id: 'p10',
      categoryId: 'c3',
      nameAr: 'لحم عجل بلدي طازج مفروم ناعم 1 كجم',
      nameEn: 'Fresh Local Minced Veal 1kg',
      descriptionAr: 'لحم عجل بلدي طازج مفروم يومياً حسب الطلب، نسبة دهن متوازنة ومثالي للكفتة والبرغر.',
      brand: 'ملحمة الديب',
      price: 38.00,
      originalPrice: 45.00,
      discountPercent: 15,
      unit: 'kg',
      weightStep: 0.5,
      stockQuantity: 140,
      images: ['https://images.unsplash.com/photo-1588168333986-5078d3ae3976?auto=format&fit=crop&w=600&q=80'],
      isFeatured: true,
      isDailyDeal: false,
      rating: 4.9,
      salesCount: 1100,
    ),
    const ProductModel(
      id: 'p11',
      categoryId: 'c3',
      nameAr: 'فيليه سلمون نرويجي طازج فاخر 500 غ',
      nameEn: 'Fresh Norwegian Salmon Fillet 500g',
      descriptionAr: 'سمك سلمون نرويجي طازج غني بالأوميغا 3 والبروتين، منزوع الشوك وجاهز للشواء والفرن.',
      brand: 'بحريات الديب',
      price: 44.50,
      originalPrice: 55.00,
      discountPercent: 19,
      unit: 'pack',
      weightStep: 0.5,
      stockQuantity: 95,
      images: ['https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?auto=format&fit=crop&w=600&q=80'],
      isFeatured: true,
      isDailyDeal: true,
      rating: 4.9,
      salesCount: 840,
    ),
    const ProductModel(
      id: 'p12',
      categoryId: 'c3',
      nameAr: 'ستيك ريب آي أنجوس معتق فاخر 400 غ',
      nameEn: 'Prime Dry-Aged Angus Ribeye Steak 400g',
      descriptionAr: 'ستيك عجل أنجوس معتق 28 يوماً لطراوة استثنائية ونكهة غنية للمطاعم الراقية.',
      brand: 'ملحمة الديب',
      price: 52.00,
      originalPrice: 65.00,
      discountPercent: 20,
      unit: 'piece',
      weightStep: 1.0,
      stockQuantity: 60,
      images: ['https://images.unsplash.com/photo-1603048588665-791ca8aea617?auto=format&fit=crop&w=600&q=80'],
      isFeatured: true,
      isDailyDeal: false,
      rating: 5.0,
      salesCount: 620,
    ),
    const ProductModel(
      id: 'p13',
      categoryId: 'c2',
      nameAr: 'بيض مزارع عضوي طازج كرتون 30 حبة',
      nameEn: 'Fresh Organic Farm Eggs 30-Pack',
      descriptionAr: 'بيض بني عضوي طازج مفحوص مخبرياً من دجاج مزارع متغذية على الحبوب الطبيعية 100%.',
      brand: 'مزارع الديب',
      price: 22.50,
      originalPrice: 28.00,
      discountPercent: 20,
      unit: 'carton',
      weightStep: 1.0,
      stockQuantity: 300,
      images: ['https://images.unsplash.com/photo-1506976785307-8732e854ad03?auto=format&fit=crop&w=600&q=80'],
      isFeatured: true,
      isDailyDeal: true,
      rating: 4.9,
      salesCount: 2900,
    ),
    const ProductModel(
      id: 'p14',
      categoryId: 'c2',
      nameAr: 'لبنة تركية فاخرة طازجة كاملة الدسم 500 غ',
      nameEn: 'Fresh Turkish Creamy Labneh 500g',
      descriptionAr: 'لبنة قوام كريمي غني بنكهة أصلية مع زيت الزيتون، مثالية للفطور اليومي.',
      brand: 'بينار',
      price: 12.00,
      originalPrice: 15.00,
      discountPercent: 20,
      unit: 'piece',
      weightStep: 1.0,
      stockQuantity: 180,
      images: ['https://images.unsplash.com/photo-1486297678162-eb2a19b0a32d?auto=format&fit=crop&w=600&q=80'],
      isFeatured: false,
      isDailyDeal: false,
      rating: 4.8,
      salesCount: 1420,
    ),
    const ProductModel(
      id: 'p15',
      categoryId: 'c4',
      nameAr: 'خبز ساوردو ريفيّ عضوي طازج مخبوز بالفرن',
      nameEn: 'Artisan Fresh Organic Sourdough Bread',
      descriptionAr: 'خبز خميرة طبيعية متخمر ببطء 24 ساعة، قشرة مقرمشة ولب رطب خفيف على المعدة.',
      brand: 'مخبز الديب',
      price: 9.50,
      originalPrice: 12.00,
      discountPercent: 20,
      unit: 'piece',
      weightStep: 1.0,
      stockQuantity: 80,
      images: ['https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=600&q=80'],
      isFeatured: true,
      isDailyDeal: false,
      rating: 4.9,
      salesCount: 970,
    ),
    const ProductModel(
      id: 'p16',
      categoryId: 'c4',
      nameAr: 'بقلاوة مشكلة بالفستق والكاجو الفاخر 500 غ',
      nameEn: 'Assorted Royal Pistachio Baklava 500g',
      descriptionAr: 'حلوى شرقية ملكية بالسمن البلدي والفستق الحلبي المقرمش مجهزة بعناية.',
      brand: 'حلويات الديب',
      price: 29.00,
      originalPrice: 36.00,
      discountPercent: 19,
      unit: 'pack',
      weightStep: 1.0,
      stockQuantity: 110,
      images: ['https://images.unsplash.com/photo-1519869325930-281384150729?auto=format&fit=crop&w=600&q=80'],
      isFeatured: false,
      isDailyDeal: true,
      rating: 4.9,
      salesCount: 1250,
    ),
    const ProductModel(
      id: 'p17',
      categoryId: 'c5',
      nameAr: 'عصير برتقال طبيعي معصور طازج 1 لتر',
      nameEn: 'Freshly Squeezed 100% Orange Juice 1L',
      descriptionAr: 'عصير برتقال فالنسيا نقي 100% بدون سكر مضاف أو مواد حافظة، غني بفيتامين سي.',
      brand: 'عصائر الديب',
      price: 14.00,
      originalPrice: 18.00,
      discountPercent: 22,
      unit: 'bottle',
      weightStep: 1.0,
      stockQuantity: 160,
      images: ['https://images.unsplash.com/photo-1613478223719-2ab802602423?auto=format&fit=crop&w=600&q=80'],
      isFeatured: true,
      isDailyDeal: false,
      rating: 4.8,
      salesCount: 1890,
    ),
    const ProductModel(
      id: 'p18',
      categoryId: 'c5',
      nameAr: 'قهوة عربية فاخرة بالهيل والزعفران 250 غ',
      nameEn: 'Premium Arabic Coffee with Saffron 250g',
      descriptionAr: 'خلطة قهوة شقراء مميزة بأجود أنواع البن الهرري مع الهيل الأخضر والزعفران الأصلي.',
      brand: 'الديوانية',
      price: 19.50,
      originalPrice: 25.00,
      discountPercent: 22,
      unit: 'pack',
      weightStep: 1.0,
      stockQuantity: 200,
      images: ['https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?auto=format&fit=crop&w=600&q=80'],
      isFeatured: false,
      isDailyDeal: false,
      rating: 4.9,
      salesCount: 2150,
    ),
    const ProductModel(
      id: 'p19',
      categoryId: 'c6',
      nameAr: 'سائل غسيل الصحون فيري بلس ليمون 1 لتر',
      nameEn: 'Fairy Plus Lemon Dishwashing Liquid 1L',
      descriptionAr: 'قوة مضاعفة لتفتيت الدهون الصعبة بقطرة واحدة مع رغوة كثيفة ورائحة الليمون المنعشة.',
      brand: 'فيري',
      price: 13.50,
      originalPrice: 17.00,
      discountPercent: 20,
      unit: 'bottle',
      weightStep: 1.0,
      stockQuantity: 340,
      images: ['https://images.unsplash.com/photo-1585421514738-01798e348b17?auto=format&fit=crop&w=600&q=80'],
      isFeatured: false,
      isDailyDeal: true,
      rating: 4.9,
      salesCount: 3100,
    ),
    const ProductModel(
      id: 'p20',
      categoryId: 'c6',
      nameAr: 'مطهر ومعقم ديتول الأصلي متعدد الاستعمالات 1 لتر',
      nameEn: 'Dettol Original Antiseptic Liquid 1L',
      descriptionAr: 'حماية متكاملة تقضي على 99.9% من الجراثيم والبكتيريا لتعقيم المنزل والأسطح.',
      brand: 'ديتول',
      price: 24.00,
      originalPrice: 31.00,
      discountPercent: 22,
      unit: 'bottle',
      weightStep: 1.0,
      stockQuantity: 250,
      images: ['https://images.unsplash.com/photo-1584744982491-665216d95f8b?auto=format&fit=crop&w=600&q=80'],
      isFeatured: true,
      isDailyDeal: false,
      rating: 4.9,
      salesCount: 2780,
    ),
  ];

  static final List<CouponModel> _defaultCoupons = [
    const CouponModel(
      id: 'cp1',
      code: 'ALDEEB10',
      discountType: 'percentage',
      discountValue: 10.0,
      minOrderAmount: 50.0,
      maxDiscount: 30.0,
    ),
    const CouponModel(
      id: 'cp2',
      code: 'SAVE20',
      discountType: 'percentage',
      discountValue: 20.0,
      minOrderAmount: 120.0,
      maxDiscount: 50.0,
    ),
    const CouponModel(
      id: 'cp3',
      code: 'WELCOME15',
      discountType: 'fixed',
      discountValue: 15.0,
      minOrderAmount: 75.0,
    ),
  ];
}
