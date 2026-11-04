import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_constants.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/banner_model.dart';
import '../models/coupon_model.dart';
import '../models/order_model.dart';
import '../models/cart_item_model.dart';
import '../models/delivery_zone_model.dart';
import '../models/delivery_coverage_result.dart';

class CouponValidationResult {
  final bool isValid;
  final CouponModel? coupon;
  final String? errorMessage;
  final double? calculatedDiscount;
  final double? minOrderAmount;
  final double? amountNeeded;

  const CouponValidationResult({
    required this.isValid,
    this.coupon,
    this.errorMessage,
    this.calculatedDiscount,
    this.minOrderAmount,
    this.amountNeeded,
  });

  factory CouponValidationResult.success(CouponModel coupon, double discount) {
    return CouponValidationResult(
      isValid: true,
      coupon: coupon,
      calculatedDiscount: discount,
    );
  }

  factory CouponValidationResult.failure(
    String message, {
    double? minOrderAmount,
    double? amountNeeded,
    CouponModel? coupon,
  }) {
    return CouponValidationResult(
      isValid: false,
      coupon: coupon,
      errorMessage: message,
      minOrderAmount: minOrderAmount,
      amountNeeded: amountNeeded,
    );
  }
}

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  bool _isInitialized = false;

  Future<void> initialize() async {
    try {
      String targetUrl = SupabaseConstants.supabaseUrl;
      String targetAnonKey = SupabaseConstants.supabaseAnonKey;

      if (kIsWeb) {
        final origin = Uri.base.origin;
        final host = Uri.base.host;
        final port = Uri.base.port;

        // Auto-detect local development or self-hosted hypermarket LAN environment
        if (host == 'localhost' ||
            host == '127.0.0.1' ||
            host.startsWith('192.168.') ||
            host.startsWith('10.') ||
            host.startsWith('172.') ||
            port == 8080 ||
            port == 4174 ||
            port == 3000 ||
            port == 5173) {
          targetUrl = origin;
          targetAnonKey = SupabaseConstants.localPostgrestAnonKey;
        }
      }

      if (targetUrl.contains('YOUR_PROJECT_ID')) {
        // Not configured yet, will use offline mock store data
        _isInitialized = false;
        return;
      }
      await Supabase.initialize(
        url: targetUrl,
        // ignore: deprecated_member_use
        anonKey: targetAnonKey,
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

  // Canonical ID mapping between legacy short identifiers and Supabase UUIDs
  static String mapCategoryIdToCanonical(String catId) {
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
    return map[catId] ?? catId;
  }

  // Canonical product ID mapping between short catalog codes and PostgreSQL UUIDs
  static String mapProductIdToCanonical(String prodId) {
    if (prodId.isEmpty) return prodId;
    if (RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(prodId)) {
      return prodId;
    }
    const map = {
      'p1': 'a0000000-0000-0000-0000-000000000001',
      'p2': 'a0000000-0000-0000-0000-000000000002',
      'p3': 'a0000000-0000-0000-0000-000000000003',
      'p4': 'a0000000-0000-0000-0000-000000000004',
      'p5': 'a0000000-0000-0000-0000-000000000005',
      'p6': 'a0000000-0000-0000-0000-000000000006',
      'p7': 'a0000000-0000-0000-0000-000000000007',
      'p8': 'a0000000-0000-0000-0000-000000000008',
      'p9': 'a0000000-0000-0000-0000-000000000009',
      'p10': 'a0000000-0000-0000-0000-000000000010',
      'p11': 'a0000000-0000-0000-0000-000000000011',
      'p12': 'a0000000-0000-0000-0000-000000000012',
      'p13': 'a0000000-0000-0000-0000-000000000013',
      'p14': 'a0000000-0000-0000-0000-000000000014',
      'p15': 'a0000000-0000-0000-0000-000000000015',
      'p16': 'a0000000-0000-0000-0000-000000000016',
      'p17': 'a0000000-0000-0000-0000-000000000017',
      'p18': 'a0000000-0000-0000-0000-000000000018',
      'p19': 'a0000000-0000-0000-0000-000000000019',
      'p20': 'a0000000-0000-0000-0000-000000000020',
      'p21': 'a0000000-0000-0000-0000-000000000021',
      'p22': 'a0000000-0000-0000-0000-000000000022',
      'p23': 'a0000000-0000-0000-0000-000000000023',
      'p24': 'a0000000-0000-0000-0000-000000000024',
      'p25': 'a0000000-0000-0000-0000-000000000025',
      'p26': 'a0000000-0000-0000-0000-000000000026',
      'p27': 'a0000000-0000-0000-0000-000000000027',
      'p_dates_1': 'a0000000-0000-0000-0000-000000000028',
      'p_appliances_1': 'a0000000-0000-0000-0000-000000000029',
      'p_eggs_1': 'a0000000-0000-0000-0000-000000000030',
      'p_beauty_1': 'a0000000-0000-0000-0000-000000000031',
      'p_clean_1': 'a0000000-0000-0000-0000-000000000032',
      'p_rice_1': 'a0000000-0000-0000-0000-000000000033',
      'p_pet_1': 'a0000000-0000-0000-0000-000000000034',
    };
    if (map.containsKey(prodId)) return map[prodId]!;
    if (prodId.startsWith('p') && int.tryParse(prodId.substring(1)) != null) {
      final numVal = int.parse(prodId.substring(1));
      return 'a0000000-0000-0000-0000-${numVal.toString().padLeft(12, '0')}';
    }
    return prodId;
  }

  static bool _matchesCategory(String? itemCatId, String queryCatId) {
    if (itemCatId == null) return false;
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

  // 2. Fetch Products
  Future<List<ProductModel>> getProducts({String? categoryId, bool? isDailyDeal, bool? isFeatured}) async {
    if (_isInitialized && client != null) {
      try {
        var query = client!
            .from(SupabaseConstants.productsTable)
            .select()
            .eq('is_active', true);

        if (categoryId != null) {
          final canonical = mapCategoryIdToCanonical(categoryId);
          query = query.or('category_id.eq.$canonical,category_id.eq.$categoryId');
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
      list = list.where((p) => p.categoryId == categoryId || _matchesCategory(p.categoryId, categoryId)).toList();
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

  // 4. Validate Coupon (Detailed Result with Exact Explanations)
  Future<CouponValidationResult> validateCouponDetailed(String code, double subtotal) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) {
      return CouponValidationResult.failure('يرجى إدخال رمز كود الخصم');
    }

    if (_isInitialized && client != null) {
      // 1. Try atomic RPC validate_coupon first
      try {
        final rpcRes = await client!.rpc('validate_coupon', params: {
          'p_code': cleanCode,
          'p_subtotal': subtotal,
        });

        if (rpcRes != null && rpcRes is Map) {
          final isValid = rpcRes['valid'] == true;
          if (isValid) {
            final coupon = CouponModel(
              id: rpcRes['coupon_id']?.toString() ?? '',
              code: rpcRes['code']?.toString() ?? cleanCode,
              discountType: rpcRes['discount_type']?.toString() ?? 'percentage',
              discountValue: (rpcRes['discount_value'] as num?)?.toDouble() ?? 0.0,
              minOrderAmount: (rpcRes['min_order_amount'] as num?)?.toDouble() ?? 0.0,
              maxDiscount: (rpcRes['max_discount'] as num?)?.toDouble(),
              isActive: true,
            );
            final discount = (rpcRes['calculated_discount'] as num?)?.toDouble() ?? coupon.calculateDiscount(subtotal);
            return CouponValidationResult.success(coupon, discount);
          } else {
            final msg = rpcRes['message_ar']?.toString() ?? 'كود الخصم غير صالح أو منتهي الصلاحية';
            final minAmt = (rpcRes['min_order_amount'] as num?)?.toDouble();
            final amtNeeded = (rpcRes['amount_needed'] as num?)?.toDouble();
            return CouponValidationResult.failure(msg, minOrderAmount: minAmt, amountNeeded: amtNeeded);
          }
        }
      } catch (_) {
        // Fallback to direct table query if RPC is not deployed in current schema
      }

      // 2. Direct table query
      try {
        final response = await client!
            .from(SupabaseConstants.couponsTable)
            .select()
            .eq('code', cleanCode)
            .eq('is_active', true)
            .maybeSingle();

        if (response != null) {
          final coupon = CouponModel.fromJson(response);
          if (subtotal < coupon.minOrderAmount) {
            final needed = (coupon.minOrderAmount - subtotal);
            return CouponValidationResult.failure(
              'الحد الأدنى لتفعيل كود الخصم هو ${coupon.minOrderAmount.toStringAsFixed(0)} ل.س (ينقص سلتك ${needed.toStringAsFixed(0)} ل.س)',
              minOrderAmount: coupon.minOrderAmount,
              amountNeeded: needed,
              coupon: coupon,
            );
          }
          return CouponValidationResult.success(coupon, coupon.calculateDiscount(subtotal));
        }
      } catch (e) {
        // fallback to offline dataset
      }
    }

    // 3. Fallback to resilient in-app coupons (zero downtime guaranteed)
    final match = _defaultCoupons.where((c) => c.code.toUpperCase() == cleanCode).toList();
    if (match.isNotEmpty) {
      final coupon = match.first;
      if (subtotal < coupon.minOrderAmount) {
        final needed = (coupon.minOrderAmount - subtotal);
        return CouponValidationResult.failure(
          'الحد الأدنى لتفعيل كود الخصم هو ${coupon.minOrderAmount.toStringAsFixed(0)} ل.س (ينقص سلتك ${needed.toStringAsFixed(0)} ل.س)',
          minOrderAmount: coupon.minOrderAmount,
          amountNeeded: needed,
          coupon: coupon,
        );
      }
      return CouponValidationResult.success(coupon, coupon.calculateDiscount(subtotal));
    }

    return CouponValidationResult.failure('كود الخصم "$cleanCode" غير صحيح أو غير متاح حالياً');
  }

  // Backwards-compatible validateCoupon returning CouponModel?
  Future<CouponModel?> validateCoupon(String code, double subtotal) async {
    final result = await validateCouponDetailed(code, subtotal);
    return result.isValid ? result.coupon : null;
  }

  // 6. Check Delivery Coverage & Calculate Dynamic Fee (Task 15: Server Authoritative)
  Future<DeliveryCoverageResult> checkDeliveryCoverage({
    double? latitude,
    double? longitude,
    String? city,
    String? district,
    double subtotal = 0.0,
    String? deliverySlot,
  }) async {
    if (client != null) {
      try {
        final response = await client!.rpc('check_delivery_coverage', params: {
          'p_latitude': latitude,
          'p_longitude': longitude,
          'p_city': city,
          'p_district': district,
          'p_subtotal': subtotal,
          'p_delivery_slot': deliverySlot,
        });

        if (response != null && response is Map) {
          return DeliveryCoverageResult.fromJson(Map<String, dynamic>.from(response));
        }
      } catch (e) {
        // Fallback to direct HTTP PostgREST
      }
    }

    try {
      final uri = Uri.parse('${SupabaseConstants.supabaseUrl}/rest/v1/rpc/check_delivery_coverage');
      final res = await http.post(
        uri,
        headers: {
          'apikey': SupabaseConstants.supabaseAnonKey,
          'Authorization': 'Bearer ${SupabaseConstants.supabaseAnonKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'p_latitude': latitude,
          'p_longitude': longitude,
          'p_city': city,
          'p_district': district,
          'p_subtotal': subtotal,
          'p_delivery_slot': deliverySlot,
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map) {
          return DeliveryCoverageResult.fromJson(Map<String, dynamic>.from(data));
        }
      }
    } catch (_) {}

    return DeliveryCoverageResult.offlineDefault();
  }

  // 7. Get Authoritative Delivery Zones
  Future<List<DeliveryZoneModel>> getDeliveryZones() async {
    if (client != null) {
      try {
        final response = await client!
            .from('delivery_zones')
            .select()
            .order('is_active', ascending: false)
            .order('city', ascending: true);
        return (response as List)
            .map((z) => DeliveryZoneModel.fromJson(Map<String, dynamic>.from(z)))
            .toList();
      } catch (_) {}
    }

    try {
      final uri = Uri.parse('${SupabaseConstants.supabaseUrl}/rest/v1/delivery_zones?select=*&order=is_active.desc,city.asc');
      final res = await http.get(
        uri,
        headers: {
          'apikey': SupabaseConstants.supabaseAnonKey,
          'Authorization': 'Bearer ${SupabaseConstants.supabaseAnonKey}',
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) {
          return (data)
              .map((z) => DeliveryZoneModel.fromJson(Map<String, dynamic>.from(z)))
              .toList();
        }
      }
    } catch (_) {}

    return [];
  }

  // 5. Normalizer for payment method to match SQL CHECK constraint:
  // CHECK (payment_method IN ('cod', 'card_on_delivery', 'card', 'loyalty_points', 'apple_pay'))
  String _normalizePaymentMethod(String method) {
    final clean = method.trim().toLowerCase();
    if (clean == 'cod' ||
        clean == 'card_on_delivery' ||
        clean == 'card' ||
        clean == 'loyalty_points' ||
        clean == 'apple_pay') {
      return clean;
    }
    if (clean.contains('محفظة') ||
        clean.contains('نقاط') ||
        clean.contains('wallet') ||
        clean.contains('points') ||
        clean.contains('loyalty')) {
      return 'loyalty_points';
    }
    if (clean.contains('apple') || clean.contains('آبل') || clean.contains('ابل')) {
      return 'apple_pay';
    }
    // Check delivery payment methods (card on delivery vs cash on delivery)
    if (clean.contains('عند الباب') ||
        clean.contains('عند الاستلام') ||
        clean.contains('on delivery')) {
      if (clean.contains('نقداً') || clean.contains('كاش') || clean.contains('cash')) {
        return 'cod';
      }
      return 'card_on_delivery';
    }
    if (clean.contains('بطاقة') ||
        clean.contains('مدى') ||
        clean.contains('ائتمان') ||
        clean.contains('card') ||
        clean.contains('visa') ||
        clean.contains('mastercard')) {
      return 'card';
    }
    return 'cod';
  }

  // 6. Place Order (Strict Atomic ACID transaction via RPC - Zero Fallbacks)
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
    List<CartItemModel> items = const [],
    String? branchId,
    String? couponCode,
    String? idempotencyKey,
    String? customerName,
    String? customerPhone,
  }) async {
    if (!_isInitialized || client == null) {
      throw Exception('تعذر إرسال الطلب: خادم قاعدة البيانات غير متصل. يرجى التحقق من الشبكة والمحاولة مجدداً.');
    }

    final normalizedPayment = _normalizePaymentMethod(paymentMethod);

    final itemsPayload = items.map((item) {
      final p = item.product;
      final canonicalId = mapProductIdToCanonical(p.id);
      final isUuid = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
      ).hasMatch(canonicalId);

      if (!isUuid) {
        throw Exception('⚠️ معرف المنتج غير صالح (${p.nameAr}): ${p.id}');
      }

      return {
        'product_id': canonicalId,
        'product_name_ar': p.nameAr,
        'product_name_en': p.nameEn,
        'product_image': p.images.isNotEmpty ? p.images.first : '',
        'unit': p.unit,
        'unit_price': p.price,
        'quantity': item.quantity,
        'total_price': item.totalPrice,
      };
    }).toList();

    try {
      final userId = client!.auth.currentUser?.id;
      final isValidUuid = userId != null &&
          RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')
              .hasMatch(userId);

      // Invoke server-side atomic validation RPC place_order_atomic
      final rpcResponse = await client!.rpc('place_order_atomic', params: {
        'p_order_number': orderNumber,
        'p_user_id': isValidUuid ? userId : null,
        'p_delivery_slot': deliverySlot,
        'p_payment_method': normalizedPayment,
        'p_subtotal': subtotal,
        'p_delivery_fee': deliveryFee,
        'p_discount_amount': discountAmount,
        'p_loyalty_points_used': loyaltyPointsUsed,
        'p_loyalty_discount': loyaltyDiscount,
        'p_total_amount': totalAmount,
        'p_notes': notes,
        'p_items': itemsPayload,
        'p_branch_id': branchId ?? 'b-jed-01',
        'p_coupon_code': couponCode,
        'p_idempotency_key': idempotencyKey ?? orderNumber,
        'p_customer_name': customerName,
        'p_customer_phone': customerPhone,
      });

      if (rpcResponse != null && rpcResponse['id'] != null) {
        final generatedId = rpcResponse['id'].toString();
        final confirmedOrderNumber = rpcResponse['order_number']?.toString() ?? orderNumber;
        final confirmedSubtotal = (rpcResponse['subtotal'] as num?)?.toDouble() ?? subtotal;
        final confirmedDeliveryFee = (rpcResponse['delivery_fee'] as num?)?.toDouble() ?? deliveryFee;
        final confirmedDiscount = (rpcResponse['discount_amount'] as num?)?.toDouble() ?? discountAmount;
        final confirmedLoyaltyDiscount = (rpcResponse['loyalty_discount'] as num?)?.toDouble() ?? loyaltyDiscount;
        final confirmedTotal = (rpcResponse['total_amount'] as num?)?.toDouble() ?? totalAmount;

        return OrderModel(
          id: generatedId,
          orderNumber: confirmedOrderNumber,
          status: rpcResponse['status']?.toString() ?? 'pending',
          deliverySlot: deliverySlot,
          paymentMethod: paymentMethod,
          subtotal: confirmedSubtotal,
          deliveryFee: confirmedDeliveryFee,
          discountAmount: confirmedDiscount,
          loyaltyPointsUsed: loyaltyPointsUsed,
          loyaltyDiscount: confirmedLoyaltyDiscount,
          totalAmount: confirmedTotal,
          createdAt: rpcResponse['created_at'] != null 
              ? DateTime.tryParse(rpcResponse['created_at'].toString()) ?? DateTime.now() 
              : DateTime.now(),
          notes: notes,
          driverName: 'مندوب التوصيل السريع',
          driverPhone: '+966501112233',
          items: items,
        );
      } else {
        throw Exception('فشل إنشاء الطلب: استجابة الخادم فارغة أو غير معتمدة.');
      }
    } catch (e) {
      debugPrint('🛑 Supabase createOrder failure: $e');
      rethrow; // Strictly rethrow: Zero disguise of backend failure as success!
    }
  }

  // ===========================================================================
  // Hyper-Realistic In-Memory Seed (Carrefour Mall Catalog)
  // ===========================================================================
  static List<ProductModel> get defaultProducts => _defaultProducts;
  static List<CategoryModel> get defaultCategories => _defaultCategories;
  static final List<CategoryModel> _defaultCategories = [
    const CategoryModel(
      id: 'c_ready_meals',
      nameAr: 'الأطعمة الجاهزة والطازجة',
      nameEn: 'Fresh & Ready Meals',
      slug: 'ready-meals',
      iconName: 'restaurant',
      imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=600&q=80',
      sortOrder: 1,
      groupTag: 'food_fresh',
      itemCount: 142,
    ),
    const CategoryModel(
      id: 'c_chilled',
      nameAr: 'أطعمة مبردة ومشروبات ثلاجة',
      nameEn: 'Chilled Foods & Deli',
      slug: 'chilled-foods',
      iconName: 'kitchen',
      imageUrl: 'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?auto=format&fit=crop&w=600&q=80',
      sortOrder: 2,
      groupTag: 'food_fresh',
      itemCount: 98,
    ),
    const CategoryModel(
      id: 'c2',
      nameAr: 'منتجات الألبان والبيض',
      nameEn: 'Dairy, Cheese & Eggs',
      slug: 'dairy-eggs',
      iconName: 'egg',
      imageUrl: 'https://images.unsplash.com/photo-1550583724-b2692b85b150?auto=format&fit=crop&w=600&q=80',
      sortOrder: 3,
      groupTag: 'food_fresh',
      itemCount: 165,
    ),
    const CategoryModel(
      id: 'c1',
      nameAr: 'الخضار والفواكه الطازجة',
      nameEn: 'Fresh Fruits & Vegetables',
      slug: 'fresh-produce',
      iconName: 'apple',
      imageUrl: 'https://images.unsplash.com/photo-1610348725531-843dff563e2c?auto=format&fit=crop&w=600&q=80',
      sortOrder: 4,
      groupTag: 'food_fresh',
      itemCount: 210,
    ),
    const CategoryModel(
      id: 'c_supermarket',
      nameAr: 'سوبر ماركت والمؤونة',
      nameEn: 'Supermarket & Pantry',
      slug: 'supermarket-pantry',
      iconName: 'shopping_basket',
      imageUrl: 'https://images.unsplash.com/photo-1578916171728-46686eac8d58?auto=format&fit=crop&w=600&q=80',
      sortOrder: 5,
      groupTag: 'groceries',
      itemCount: 450,
    ),
    const CategoryModel(
      id: 'c5',
      nameAr: 'المشروبات والمياه والعصائر',
      nameEn: 'Beverages, Water & Juices',
      slug: 'beverages-water',
      iconName: 'cup-soda',
      imageUrl: 'https://images.unsplash.com/photo-1527661591475-527312dd65f5?auto=format&fit=crop&w=600&q=80',
      sortOrder: 6,
      groupTag: 'groceries',
      itemCount: 180,
    ),
    const CategoryModel(
      id: 'c_frozen',
      nameAr: 'أطعمة مجمدة ومثلجات',
      nameEn: 'Frozen Foods & Ice Cream',
      slug: 'frozen-foods',
      iconName: 'ac_unit',
      imageUrl: 'https://images.unsplash.com/photo-1501443762994-82bd5dace89a?auto=format&fit=crop&w=600&q=80',
      sortOrder: 7,
      groupTag: 'groceries',
      itemCount: 120,
    ),
    const CategoryModel(
      id: 'c4',
      nameAr: 'المخبوزات والحلويات والمعجنات',
      nameEn: 'Bakery, Pastries & Sweets',
      slug: 'bakery-pastries',
      iconName: 'croissant',
      imageUrl: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=600&q=80',
      sortOrder: 8,
      groupTag: 'food_fresh',
      itemCount: 115,
    ),
    const CategoryModel(
      id: 'c_organic',
      nameAr: 'أغذية عضوية وصحية',
      nameEn: 'Organic & Bio Foods',
      slug: 'organic-health-foods',
      iconName: 'eco',
      imageUrl: 'https://images.unsplash.com/photo-1498837167922-ddd27525d352?auto=format&fit=crop&w=600&q=80',
      sortOrder: 9,
      groupTag: 'groceries',
      itemCount: 88,
    ),
    const CategoryModel(
      id: 'c3',
      nameAr: 'لحوم ودواجن وأسماك طازجة',
      nameEn: 'Fresh Meat, Poultry & Fish',
      slug: 'meat-poultry',
      iconName: 'beef',
      imageUrl: 'https://images.unsplash.com/photo-1607623814075-e51df1bdc82f?auto=format&fit=crop&w=600&q=80',
      sortOrder: 10,
      groupTag: 'food_fresh',
      itemCount: 130,
    ),
    const CategoryModel(
      id: 'c_pets',
      nameAr: 'أطعمة ومستلزمات حيوانات',
      nameEn: 'Pet Food & Supplies',
      slug: 'pet-supplies',
      iconName: 'pets',
      imageUrl: 'https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?auto=format&fit=crop&w=600&q=80',
      sortOrder: 11,
      groupTag: 'lifestyle',
      itemCount: 95,
    ),
    const CategoryModel(
      id: 'c_beauty',
      nameAr: 'منتجات جمالية وعناية شخصية',
      nameEn: 'Beauty & Personal Care',
      slug: 'beauty-personal-care',
      iconName: 'face',
      imageUrl: 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?auto=format&fit=crop&w=600&q=80',
      sortOrder: 12,
      groupTag: 'care',
      itemCount: 310,
    ),
    const CategoryModel(
      id: 'c_cars',
      nameAr: 'إكسسوارات ومستلزمات سيارات',
      nameEn: 'Car Accessories & Care',
      slug: 'car-accessories',
      iconName: 'directions_car',
      imageUrl: 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?auto=format&fit=crop&w=600&q=80',
      sortOrder: 13,
      groupTag: 'home_tech',
      itemCount: 74,
    ),
    const CategoryModel(
      id: 'c_baby',
      nameAr: 'مستلزمات أطفال ورضّع',
      nameEn: 'Baby Care & Supplies',
      slug: 'baby-care',
      iconName: 'child_care',
      imageUrl: 'https://images.unsplash.com/photo-1515488042361-ee00e0ddd4e4?auto=format&fit=crop&w=600&q=80',
      sortOrder: 14,
      groupTag: 'care',
      itemCount: 160,
    ),
    const CategoryModel(
      id: 'c6',
      nameAr: 'أدوات ومواد تنظيف',
      nameEn: 'Cleaning & Household Supplies',
      slug: 'cleaning-household',
      iconName: 'sparkles',
      imageUrl: 'https://images.unsplash.com/photo-1585421514738-01798e348b17?auto=format&fit=crop&w=600&q=80',
      sortOrder: 15,
      groupTag: 'home_tech',
      itemCount: 145,
    ),
    const CategoryModel(
      id: 'c_clothing',
      nameAr: 'ملابس وأزياء',
      nameEn: 'Clothing & Fashion',
      slug: 'clothing-fashion',
      iconName: 'checkroom',
      imageUrl: 'https://images.unsplash.com/photo-1489987707025-afc232f7ea0f?auto=format&fit=crop&w=600&q=80',
      sortOrder: 16,
      groupTag: 'fashion',
      itemCount: 220,
    ),
    const CategoryModel(
      id: 'c_accessories',
      nameAr: 'إكسسوارات ومجوهرات وساعات',
      nameEn: 'Fashion Accessories & Jewelry',
      slug: 'accessories-jewelry',
      iconName: 'watch',
      imageUrl: 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?auto=format&fit=crop&w=600&q=80',
      sortOrder: 17,
      groupTag: 'fashion',
      itemCount: 135,
    ),
    const CategoryModel(
      id: 'c_home_garden',
      nameAr: 'منتجات منزل وحديقة',
      nameEn: 'Home & Garden Living',
      slug: 'home-garden',
      iconName: 'yard',
      imageUrl: 'https://images.unsplash.com/photo-1513694203232-719a280e022f?auto=format&fit=crop&w=600&q=80',
      sortOrder: 18,
      groupTag: 'home_tech',
      itemCount: 190,
    ),
    const CategoryModel(
      id: 'c_paper',
      nameAr: 'منتجات ورقية واستهلاكية',
      nameEn: 'Paper & Disposable Goods',
      slug: 'paper-products',
      iconName: 'layers',
      imageUrl: 'https://images.unsplash.com/photo-1584556812952-905ffd0c611a?auto=format&fit=crop&w=600&q=80',
      sortOrder: 19,
      groupTag: 'home_tech',
      itemCount: 82,
    ),
    const CategoryModel(
      id: 'c_sports',
      nameAr: 'منتجات رياضة ولياقة بدنية',
      nameEn: 'Sports & Fitness Equipment',
      slug: 'sports-fitness',
      iconName: 'fitness_center',
      imageUrl: 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?auto=format&fit=crop&w=600&q=80',
      sortOrder: 20,
      groupTag: 'lifestyle',
      itemCount: 110,
    ),
    const CategoryModel(
      id: 'c_stationery',
      nameAr: 'قرطاسية ومستلزمات مكتبية ومدرسية',
      nameEn: 'Stationery & Office Supplies',
      slug: 'stationery-office',
      iconName: 'edit_note',
      imageUrl: 'https://images.unsplash.com/photo-1583485088034-697b5bc54ccd?auto=format&fit=crop&w=600&q=80',
      sortOrder: 21,
      groupTag: 'lifestyle',
      itemCount: 140,
    ),
    const CategoryModel(
      id: 'c_toys',
      nameAr: 'ألعاب أطفال وترفيه عائلي',
      nameEn: 'Toys & Family Games',
      slug: 'toys-entertainment',
      iconName: 'toys',
      imageUrl: 'https://images.unsplash.com/photo-1558060370-d644479cb6f7?auto=format&fit=crop&w=600&q=80',
      sortOrder: 22,
      groupTag: 'lifestyle',
      itemCount: 165,
    ),
    const CategoryModel(
      id: 'c_essentials',
      nameAr: 'مستلزمات وإلكترونيات عامة',
      nameEn: 'General Essentials & Tech',
      slug: 'general-essentials',
      iconName: 'devices',
      imageUrl: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?auto=format&fit=crop&w=600&q=80',
      sortOrder: 23,
      groupTag: 'home_tech',
      itemCount: 92,
    ),
    const CategoryModel(
      id: 'c_dates',
      nameAr: 'تمور فاخرة وفواكه مجففة',
      nameEn: 'Luxury Dates & Dried Fruits',
      slug: 'dates-dried-fruits',
      iconName: 'palm_tree',
      imageUrl: 'https://images.unsplash.com/photo-1596707328406-8c4c7943c2c5?auto=format&fit=crop&w=600&q=80',
      sortOrder: 24,
      groupTag: 'groceries',
      itemCount: 84,
    ),
    const CategoryModel(
      id: 'c_appliances',
      nameAr: 'الأجهزة المنزلية والإلكترونيات',
      nameEn: 'Home Appliances & Electronics',
      slug: 'home-appliances',
      iconName: 'tv',
      imageUrl: 'https://images.unsplash.com/photo-1550009158-9ebf69173e03?auto=format&fit=crop&w=600&q=80',
      sortOrder: 25,
      groupTag: 'home_tech',
      itemCount: 65,
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
      slot: 'hero',
    ),
    const BannerModel(
      id: 'b2',
      titleAr: 'سوق الخضار والفواكه الطازجة قطاف اليوم 🍎',
      titleEn: 'Fresh Daily Produce Market',
      subtitleAr: 'من المزرعة إلى مائدتك بتوصيل فوري مبرد وسريع',
      imageUrl: 'https://images.unsplash.com/photo-1610348725531-843dff563e2c?auto=format&fit=crop&w=1200&q=80',
      targetType: 'category',
      targetId: 'c1',
      badgeAr: 'طازج يومياً',
      slot: 'hero',
    ),
    const BannerModel(
      id: 'b3',
      titleAr: 'عروض الأسبوع التوفيرية للمنزل والأسرة 🌟',
      titleEn: 'Mega Weekly Family Deals',
      subtitleAr: 'تخفيضات كبرى على منتجات الألبان، اللحوم، والمؤن',
      imageUrl: 'https://images.unsplash.com/photo-1578916171728-46686eac8d58?auto=format&fit=crop&w=1200&q=80',
      targetType: 'deal',
      badgeAr: 'عروض الأسبوع',
      slot: 'hero',
    ),
    const BannerModel(
      id: 'b4',
      titleAr: 'توصيل فوري إكسبريس مجاني خلال 60 دقيقة 🛵',
      titleEn: 'Express 60-Minute Fast Delivery',
      subtitleAr: 'اطلب مستلزمات بيتك الآن واستلمها على بابك مجاناً فوق 100 ل.س',
      imageUrl: 'https://images.unsplash.com/photo-1526367790999-0150786686a2?auto=format&fit=crop&w=1200&q=80',
      targetType: 'deal',
      badgeAr: 'سريع ومضمون',
      slot: 'hero',
    ),
    const BannerModel(
      id: 'b_sec_1',
      titleAr: 'مهرجان التمور الملكية والبن الفاخر 🌴',
      titleEn: 'Royal Dates & Specialty Coffee Fest',
      subtitleAr: 'أجود تمور سكري وخلاص مع خصم إضافي 20% عند شراء عبوتين',
      imageUrl: 'https://images.unsplash.com/photo-1596707328406-8c4c7943c2c5?auto=format&fit=crop&w=1200&q=80',
      targetType: 'category',
      targetId: 'c_dates',
      badgeAr: 'إعلان فاصل 1',
      slot: 'middle_secondary',
    ),
    const BannerModel(
      id: 'b_sec_2',
      titleAr: 'عروض الأجهزة المنزلية وقلايات الهواء الذكية ⚡',
      titleEn: 'Smart Appliances & Airfryer Mega Sale',
      subtitleAr: 'وفّر حتى 300 ل.س مع ضمان سنتين صيانة معتمدة شاملة',
      imageUrl: 'https://images.unsplash.com/photo-1550009158-9ebf69173e03?auto=format&fit=crop&w=1200&q=80',
      targetType: 'category',
      targetId: 'c_appliances',
      badgeAr: 'إعلان فاصل 2',
      slot: 'middle_secondary',
    ),
    const BannerModel(
      id: 'b_side_top',
      titleAr: 'صفقة اليوم الطازجة 🍅',
      titleEn: 'Fresh Daily Deal 🍅',
      subtitleAr: 'طماطم مزارع محلية قطاف الصباح بخصم 25%',
      imageUrl: 'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?auto=format&fit=crop&w=600&q=80',
      targetType: 'product',
      targetId: 'p3',
      badgeAr: '3.75 د.أ / كجم',
      badgeColor: '#EF4444',
      slot: 'side_top',
      sortOrder: 1,
    ),
    const BannerModel(
      id: 'b_side_bottom',
      titleAr: 'توصيل فوري خلال 60 دقيقة 🛵',
      titleEn: 'Instant Delivery within 60 Mins 🛵',
      subtitleAr: 'اطلب طلبات البيت واستلمها على بابك',
      imageUrl: 'https://images.unsplash.com/photo-1526367790999-0150786686a2?auto=format&fit=crop&w=600&q=80',
      targetType: 'coupon',
      targetId: 'FREE100',
      badgeAr: 'مجاناً للطلبات فوق 100 د.أ',
      badgeColor: '#0284C7',
      slot: 'side_bottom',
      sortOrder: 2,
    ),
  ];

  static final List<ProductModel> _defaultProducts = [
    const ProductModel(
      id: 'a0000000-0000-0000-0000-000000000001',
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
      bundleEnabled: true,
      bundleDiscountPercent: 20,
      bundleTitle: 'اشترِ معاً ووفر 20% (باقة الفواكه الطازجة)',
      bundleProductIds: ['p2', 'p4'],
    ),
    const ProductModel(
      id: 'a0000000-0000-0000-0000-000000000002',
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
      id: 'a0000000-0000-0000-0000-000000000003',
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
      id: 'a0000000-0000-0000-0000-000000000004',
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
      id: 'a0000000-0000-0000-0000-000000000005',
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
      id: 'a0000000-0000-0000-0000-000000000006',
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
      id: 'a0000000-0000-0000-0000-000000000007',
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
      id: 'a0000000-0000-0000-0000-000000000008',
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
      id: 'a0000000-0000-0000-0000-000000000009',
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
      id: 'a0000000-0000-0000-0000-000000000010',
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
      id: 'a0000000-0000-0000-0000-000000000011',
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
      id: 'a0000000-0000-0000-0000-000000000012',
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
      id: 'a0000000-0000-0000-0000-000000000013',
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
      id: 'a0000000-0000-0000-0000-000000000014',
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
      id: 'a0000000-0000-0000-0000-000000000015',
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
      id: 'a0000000-0000-0000-0000-000000000016',
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
      id: 'a0000000-0000-0000-0000-000000000017',
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
      id: 'a0000000-0000-0000-0000-000000000018',
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
      id: 'a0000000-0000-0000-0000-000000000019',
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
      id: 'a0000000-0000-0000-0000-000000000020',
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
    const ProductModel(
      id: 'a0000000-0000-0000-0000-000000000021',
      categoryId: 'c1',
      nameAr: 'زيت زيتون بكر ممتاز فلسطيني معصور على البارد 500 مل',
      nameEn: 'Extra Virgin Cold Pressed Palestinian Olive Oil 500ml',
      descriptionAr: 'زيت زيتون نقي من مزارع فلسطين العريقة، حموضة أقل من 0.8% غني بمضادات الأكسدة.',
      brand: 'كنعان',
      price: 26.00,
      originalPrice: 32.00,
      discountPercent: 19,
      unit: 'bottle',
      weightStep: 1.0,
      stockQuantity: 180,
      images: ['https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?auto=format&fit=crop&w=600&q=80'],
      isFeatured: true,
      isDailyDeal: false,
      rating: 5.0,
      salesCount: 1450,
    ),
    const ProductModel(
      id: 'a0000000-0000-0000-0000-000000000022',
      categoryId: 'c1',
      nameAr: 'أرز بسمتي هندي عنبر طويل الحبة فاخر 2 كجم',
      nameEn: 'Premium Aged Long Grain Indian Basmati Rice 2kg',
      descriptionAr: 'أرز هندي معتق ذو حبة طويلة ونكهة أصيلة ورائحة زكية، مثالي للكبسة والبرياني.',
      brand: 'باب الهند',
      price: 22.00,
      originalPrice: 28.00,
      discountPercent: 21,
      unit: 'pack',
      weightStep: 1.0,
      stockQuantity: 240,
      images: ['https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&w=600&q=80'],
      isFeatured: true,
      isDailyDeal: true,
      rating: 4.9,
      salesCount: 2100,
    ),
    const ProductModel(
      id: 'a0000000-0000-0000-0000-000000000023',
      categoryId: 'c2',
      nameAr: 'حليب لوز نباتي عضوي غير محلى 1 لتر',
      nameEn: 'Organic Unsweetened Almond Milk 1L',
      descriptionAr: 'بديل نباتي صحي خالٍ من اللاكتوز والجلوتين، غني بفيتامين هـ والكالسيوم وخفيف على المعدة.',
      brand: 'ألبرو',
      price: 15.50,
      originalPrice: 19.00,
      discountPercent: 18,
      unit: 'bottle',
      weightStep: 1.0,
      stockQuantity: 160,
      images: ['https://images.unsplash.com/photo-1568651318492-3a5fc1a89c8a?auto=format&fit=crop&w=600&q=80'],
      isFeatured: true,
      isDailyDeal: false,
      rating: 4.8,
      salesCount: 780,
    ),
    const ProductModel(
      id: 'a0000000-0000-0000-0000-000000000024',
      categoryId: 'c3',
      nameAr: 'صدور دجاج فيليه طازجة مبردة 500 غرام',
      nameEn: 'Fresh Chilled Chicken Breast Fillet 500g',
      descriptionAr: 'صدور دجاج طازجة مخلية من العظم والجلد تماماً، غنية بالبروتين ومثالية للوجبات الصحية والشواء.',
      brand: 'التنمية',
      price: 18.50,
      originalPrice: 23.00,
      discountPercent: 20,
      unit: 'pack',
      weightStep: 1.0,
      stockQuantity: 200,
      images: ['https://images.unsplash.com/photo-1604503468506-a8da13d82791?auto=format&fit=crop&w=600&q=80'],
      isFeatured: true,
      isDailyDeal: true,
      rating: 4.9,
      salesCount: 1640,
    ),
    const ProductModel(
      id: 'a0000000-0000-0000-0000-000000000025',
      categoryId: 'c4',
      nameAr: 'عسل سدر جبلي طبيعي نقي 500 غرام',
      nameEn: 'Pure Mountain Sidr Natural Honey 500g',
      descriptionAr: 'عسل سدر نقي 100% مستخلص من أزهار أشجار السدر الجبلية، محلي طبيعي فاخر مقوي للمناعة.',
      brand: 'مناحل الديب',
      price: 35.00,
      originalPrice: 45.00,
      discountPercent: 22,
      unit: 'piece',
      weightStep: 1.0,
      stockQuantity: 130,
      images: ['https://images.unsplash.com/photo-1587049352846-4a222e784d38?auto=format&fit=crop&w=600&q=80'],
      isFeatured: true,
      isDailyDeal: false,
      rating: 5.0,
      salesCount: 990,
    ),
    const ProductModel(
      id: 'a0000000-0000-0000-0000-000000000026',
      categoryId: 'c1',
      nameAr: 'أفوكادو هاس مكسيكي طازج جاهز للأكل (حبتين)',
      nameEn: 'Fresh Mexican Hass Avocados (2 Pack)',
      descriptionAr: 'أفوكادو هاس غني بالدهون الأحادية الصحية وقوام كريمي ناعم، مثالي للتوست والسلطات والعصائر.',
      brand: 'طازج',
      price: 9.50,
      originalPrice: 13.00,
      discountPercent: 27,
      unit: 'pack',
      weightStep: 1.0,
      stockQuantity: 175,
      images: ['https://images.unsplash.com/photo-1523049673857-eb18f1d7b578?auto=format&fit=crop&w=600&q=80'],
      isFeatured: true,
      isDailyDeal: true,
      rating: 4.9,
      salesCount: 1820,
    ),
    const ProductModel(
      id: 'a0000000-0000-0000-0000-000000000027',
      categoryId: 'c4',
      nameAr: 'شوفان عضوي حبوب كاملة فاخر 500 غرام',
      nameEn: 'Organic Whole Rolled Oats 500g',
      descriptionAr: 'رقائق شوفان حبوب كاملة عضوية 100% غنية بالألياف والمعادن ومناسبة للفطور والعصائر الصحية.',
      brand: 'صحي',
      price: 8.50,
      originalPrice: 11.00,
      discountPercent: 23,
      unit: 'pack',
      weightStep: 1.0,
      stockQuantity: 210,
      images: ['https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&w=600&q=80'],
      isFeatured: false,
      isDailyDeal: false,
      rating: 4.8,
      salesCount: 930,
    ),
    const ProductModel(
      id: 'a0000000-0000-0000-0000-000000000028',
      categoryId: 'c_dates',
      nameAr: 'تمور خلاص الأحساء فاخرة ملكية 1 كجم',
      nameEn: 'Royal Khalas Premium Dates 1kg',
      descriptionAr: 'تمور خلاص سعودية منتقاة حبة بحبة، معبأة بعناية وحلوة المذاق وغنية بالألياف الطبيعية.',
      brand: 'تمورنا',
      price: 24.00,
      originalPrice: 32.00,
      discountPercent: 25,
      unit: 'pack',
      weightStep: 1.0,
      stockQuantity: 210,
      images: ['https://images.unsplash.com/photo-1596707328406-8c4c7943c2c5?auto=format&fit=crop&w=600&q=80'],
      isFeatured: true,
      isDailyDeal: false,
      rating: 5.0,
      salesCount: 1420,
    ),
    const ProductModel(
      id: 'a0000000-0000-0000-0000-000000000029',
      categoryId: 'c_appliances',
      nameAr: 'قلاية هوائية رقمية فيليبس XXL بدون زيت 7.2 لتر',
      nameEn: 'Philips Digital Airfryer XXL 7.2L',
      descriptionAr: 'قلاية صحية بدون زيت بتقنية الهواء الساخن السريع وسعة عائلية مع شاشة لمس وبرامج متعددة.',
      brand: 'Philips',
      price: 389.00,
      originalPrice: 529.00,
      discountPercent: 26,
      unit: 'piece',
      weightStep: 1.0,
      stockQuantity: 35,
      images: ['https://images.unsplash.com/photo-1550009158-9ebf69173e03?auto=format&fit=crop&w=600&q=80'],
      isFeatured: true,
      isDailyDeal: true,
      rating: 4.9,
      salesCount: 310,
    ),
    const ProductModel(
      id: 'a0000000-0000-0000-0000-000000000030',
      categoryId: 'c2',
      nameAr: 'بيض مزارع كويتي طازج كبير 30 حبة',
      nameEn: 'Fresh Farm Table Eggs 30s',
      descriptionAr: 'بيض مائدة طازج مغذى طبيعياً وغني بالبروتين، مطابق لأعلى معايير السلامة الغذائية.',
      brand: 'مزارع الديب',
      price: 15.50,
      originalPrice: 19.00,
      discountPercent: 18,
      unit: 'pack',
      weightStep: 1.0,
      stockQuantity: 150,
      images: ['https://images.unsplash.com/photo-1516467508483-a7212febe31a?auto=format&fit=crop&w=600&q=80'],
      isFeatured: true,
      isDailyDeal: true,
      rating: 4.9,
      salesCount: 940,
    ),
    const ProductModel(
      id: 'a0000000-0000-0000-0000-000000000031',
      categoryId: 'c_beauty',
      nameAr: 'شامبو لوريال إلفيف للشعر الجاف 400 مل',
      nameEn: 'L\'Oreal Elvive Extraordinary Oil Shampoo 400ml',
      descriptionAr: 'شامبو مغذي بزيوت الزهور النادرة لتغذية الشعر من الجذور حتى الأطراف ولمعان لا يضاهى.',
      brand: 'L\'Oreal',
      price: 18.50,
      originalPrice: 25.00,
      discountPercent: 26,
      unit: 'bottle',
      weightStep: 1.0,
      stockQuantity: 85,
      images: ['https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?auto=format&fit=crop&w=600&q=80'],
      isFeatured: true,
      isDailyDeal: false,
      rating: 4.8,
      salesCount: 760,
    ),
    const ProductModel(
      id: 'a0000000-0000-0000-0000-000000000032',
      categoryId: 'c6',
      nameAr: 'مسحوق غسيل أريال أوتوماتيك للغسالات 5 كجم',
      nameEn: 'Ariel Automatic Laundry Detergent 5kg',
      descriptionAr: 'مسحوق غسيل المركز يزيل أصعب البقع من أول غسلة ويمنح الملابس انتعاشاً يدوم طويلاً.',
      brand: 'Ariel',
      price: 49.90,
      originalPrice: 68.00,
      discountPercent: 27,
      unit: 'pack',
      weightStep: 1.0,
      stockQuantity: 110,
      images: ['https://images.unsplash.com/photo-1585421514738-01798e348b17?auto=format&fit=crop&w=600&q=80'],
      isFeatured: true,
      isDailyDeal: true,
      rating: 4.9,
      salesCount: 1890,
    ),
    const ProductModel(
      id: 'a0000000-0000-0000-0000-000000000033',
      categoryId: 'c_supermarket',
      nameAr: 'أرز بسمتي الشعلان سيلا فاخر 5 كجم',
      nameEn: 'Al Shalan Basmati Sella Rice 5kg',
      descriptionAr: 'أرز بسمتي أبيض حبة طويلة ونكهة أصيلة، مثالي للكبسة والأطباق الخليجية والمناسف.',
      brand: 'الشعلان',
      price: 36.50,
      originalPrice: 45.00,
      discountPercent: 19,
      unit: 'pack',
      weightStep: 1.0,
      stockQuantity: 340,
      images: ['https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&w=600&q=80'],
      isFeatured: true,
      isDailyDeal: true,
      rating: 4.9,
      salesCount: 2200,
    ),
    const ProductModel(
      id: 'a0000000-0000-0000-0000-000000000034',
      categoryId: 'c_pets',
      nameAr: 'طعام قطط ويلاس دجاج وتونة وخضار 1.5 كجم',
      nameEn: 'Whiskas Adult Cat Food Chicken & Tuna 1.5kg',
      descriptionAr: 'وجبة متوازنة ومحببة للقطط غنية بالبروتينات وأوميغا 3 لدعم صحة الفرو والمناعة.',
      brand: 'Whiskas',
      price: 28.00,
      originalPrice: 35.00,
      discountPercent: 20,
      unit: 'pack',
      weightStep: 1.0,
      stockQuantity: 65,
      images: ['https://images.unsplash.com/photo-1583337130417-3346a1be7dee?auto=format&fit=crop&w=600&q=80'],
      isFeatured: false,
      isDailyDeal: false,
      rating: 4.7,
      salesCount: 420,
    ),
  ];

  static final List<CouponModel> _defaultCoupons = [
    const CouponModel(
      id: 'ca000000-0000-0000-0000-000000005555',
      code: '5555',
      discountType: 'percentage',
      discountValue: 15.0,
      minOrderAmount: 0.0,
      maxDiscount: 50.0,
      isActive: true,
    ),
    const CouponModel(
      id: 'a845c641-c3f1-4105-adba-99758034e742',
      code: 'WELCOME10',
      discountType: 'percentage',
      discountValue: 10.0,
      minOrderAmount: 50.0,
      maxDiscount: 20.0,
      isActive: true,
    ),
    const CouponModel(
      id: 'ad024fee-4279-45a8-a915-451056e2cde4',
      code: 'DEEB20',
      discountType: 'percentage',
      discountValue: 20.0,
      minOrderAmount: 100.0,
      maxDiscount: 40.0,
      isActive: true,
    ),
    const CouponModel(
      id: '4e908d02-584c-452d-b8b2-0303ccb5fd4c',
      code: 'FREEDEL',
      discountType: 'fixed',
      discountValue: 10.0,
      minOrderAmount: 80.0,
      maxDiscount: 10.0,
      isActive: true,
    ),
    const CouponModel(
      id: '6f29f5a8-2e23-4e1e-bb11-69a5d24a752d',
      code: 'RAMADAN',
      discountType: 'percentage',
      discountValue: 15.0,
      minOrderAmount: 150.0,
      maxDiscount: 50.0,
      isActive: true,
    ),
    const CouponModel(
      id: '99a6fbac-3e08-4278-b7a8-481dd487c73e',
      code: 'FRIDAY50',
      discountType: 'fixed',
      discountValue: 50.0,
      minOrderAmount: 250.0,
      maxDiscount: 50.0,
      isActive: true,
    ),
    const CouponModel(
      id: 'cp1',
      code: 'ALDEEB10',
      discountType: 'percentage',
      discountValue: 10.0,
      minOrderAmount: 50.0,
      maxDiscount: 30.0,
      isActive: true,
    ),
    const CouponModel(
      id: 'cp2',
      code: 'SAVE20',
      discountType: 'percentage',
      discountValue: 20.0,
      minOrderAmount: 120.0,
      maxDiscount: 50.0,
      isActive: true,
    ),
    const CouponModel(
      id: 'cp3',
      code: 'WELCOME15',
      discountType: 'fixed',
      discountValue: 15.0,
      minOrderAmount: 75.0,
      maxDiscount: 15.0,
      isActive: true,
    ),
  ];
}
