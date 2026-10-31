import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/product_model.dart';
import '../../core/providers/cart_provider.dart';
import '../wallet/wallet_screen.dart';

class SmartCartItem {
  final ProductModel product;
  final double measuredWeightKg;
  final double expectedWeightKg;
  final DateTime scannedAt;
  final bool isWeightVerified;

  const SmartCartItem({
    required this.product,
    required this.measuredWeightKg,
    required this.expectedWeightKg,
    required this.scannedAt,
    this.isWeightVerified = true,
  });
}

class SmartCartIoTScreen extends StatefulWidget {
  const SmartCartIoTScreen({super.key});

  @override
  State<SmartCartIoTScreen> createState() => _SmartCartIoTScreenState();
}

class _SmartCartIoTScreenState extends State<SmartCartIoTScreen> {
  final String _cartId = 'CART-ALDEEB-882';
  final int _batteryLevel = 87;
  bool _isSimulatingScan = false;

  late final List<SmartCartItem> _itemsInCart;

  @override
  void initState() {
    super.initState();
    _initInitialItems();
  }

  void _initInitialItems() {
    _itemsInCart = [
      SmartCartItem(
        product: const ProductModel(
          id: 'SC-01',
          nameAr: 'حليب المراعي كامل الدسم (2 لتر)',
          nameEn: 'Almarai Fresh Whole Milk 2L',
          price: 11.5,
          images: ['https://images.unsplash.com/photo-1550583724-b2692b85b150?w=400&q=80'],
          categoryId: 'ألبان',
        ),
        measuredWeightKg: 2.06,
        expectedWeightKg: 2.05,
        scannedAt: DateTime.now().subtract(const Duration(minutes: 6)),
      ),
      SmartCartItem(
        product: const ProductModel(
          id: 'SC-02',
          nameAr: 'موز إكوادوري نخب أول طازج (1 كجم)',
          nameEn: 'Ecuadorian Fresh Bananas 1kg',
          price: 6.95,
          images: ['https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=400&q=80'],
          categoryId: 'فواكه',
        ),
        measuredWeightKg: 1.12,
        expectedWeightKg: 1.10,
        scannedAt: DateTime.now().subtract(const Duration(minutes: 3)),
      ),
      SmartCartItem(
        product: const ProductModel(
          id: 'SC-03',
          nameAr: 'خبز التوست الأبيض الفاخر لوزين (600غ)',
          nameEn: 'Lusine White Toast Bread 600g',
          price: 5.5,
          images: ['https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400&q=80'],
          categoryId: 'مخبوزات',
        ),
        measuredWeightKg: 0.62,
        expectedWeightKg: 0.60,
        scannedAt: DateTime.now().subtract(const Duration(minutes: 1)),
      ),
    ];
  }

  double get _totalWeightKg => _itemsInCart.fold(0.0, (acc, item) => acc + item.measuredWeightKg);
  double get _totalPrice => _itemsInCart.fold(0.0, (acc, item) => acc + item.product.price);

  void _simulateAddItem() {
    setState(() {
      _isSimulatingScan = true;
    });

    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() {
          _isSimulatingScan = false;
          _itemsInCart.insert(
            0,
            SmartCartItem(
              product: const ProductModel(
                id: 'SC-04',
                nameAr: 'قهوة عربية بالزعفران والهيل خلطة الديب (500غ)',
                nameEn: 'Aldeeb Arabic Coffee with Saffron 500g',
                price: 28.0,
                images: ['https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=400&q=80'],
                categoryId: 'تموين',
              ),
              measuredWeightKg: 0.52,
              expectedWeightKg: 0.50,
              scannedAt: DateTime.now(),
            ),
          );
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('تم رصد ووزن صنف جديد تلقائياً في العربة الذكية!'),
              ],
            ),
            backgroundColor: AppColors.freshGreen,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _removeItem(int index) {
    setState(() {
      _itemsInCart.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تمت إزالة الصنف وتحديث حساس وزن العربة تلقائياً.'),
        backgroundColor: Colors.blueGrey,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleWalkOutCheckout() {
    final cart = Provider.of<CartProvider>(context, listen: false);

    // Sync items to CartProvider
    for (final it in _itemsInCart) {
      cart.addToCart(it.product);
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.verified, color: AppColors.freshGreen, size: 26),
              SizedBox(width: 8),
              Text(
                'الدفع الفوري ومغادرة المتجر',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.freshGreenLight.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('إجمالي العربة الذكية:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(
                      '${_totalPrice.toStringAsFixed(2)} ل.س',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: AppColors.freshGreen),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'تمت مطابقة الوزن بنسبة 100% بدون أي تباين. سيتم خصم المبلغ تلقائياً من محفظة الديب الخاصة بك، ويمكنك الخروج عبر بوابة "الممر الأخضر" بدون انتظار الكاشير.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.bolt, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'كاشير ذاتي بالكامل: وفرت 12 دقيقة من وقتك في الطابور!',
                        style: TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('مواصلة التسوق'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const WalletScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('تأكيد الدفع من المحفظة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'عربة الديب الذكية (Smart Dash Cart) 🛒',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.freshGreen,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'IoT متصلة',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            Text(
              '$_cartId • بطارية $_batteryLevel%',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'إعادة مسح باركود العربة',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('العربة مقترنة بنجاح عبر البلوتوث الذكي BLE والحساسات!')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Telemetry Status Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Weight Scale
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.scale_rounded, color: Colors.blue.shade700, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ميزان العربة الحساس:', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        Text(
                          '${_totalWeightKg.toStringAsFixed(2)} كجم',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ],
                ),

                // Match Status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.shield_outlined, color: Colors.green.shade700, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'مطابقة الأوزان: 100%',
                        style: TextStyle(
                          color: Colors.green.shade800,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Simulation Button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSimulatingScan ? null : _simulateAddItem,
                    icon: _isSimulatingScan
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_shopping_cart_rounded, size: 18),
                    label: Text(
                      _isSimulatingScan ? 'جاري الرصد والوزن التلقائي...' : 'محاكاة إسقاط صنف بالعربة (AI Vision)',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Cart Items List
          Expanded(
            child: _itemsInCart.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          'عربة التسوق الذكية فارغة',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'ضع أي منتج في العربة وسيقوم الحساس بالتعرف عليه ووزنه فوراً',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _itemsInCart.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = _itemsInCart[index];

                      return Dismissible(
                        key: ValueKey(item.product.id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _removeItem(index),
                        background: Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 20),
                          decoration: BoxDecoration(
                            color: Colors.red.shade600,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.delete_sweep_rounded, color: Colors.white),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: AppColors.cardShadow,
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: CachedNetworkImage(
                                  imageUrl: item.product.firstImage,
                                  width: 65,
                                  height: 65,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.product.nameAr,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: AppColors.textPrimary,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'الوزن: ${item.measuredWeightKg} كجم',
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue.shade800,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Icon(Icons.check_circle, color: AppColors.freshGreen, size: 14),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${item.product.price.toStringAsFixed(2)} ل.س',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                                    onPressed: () => _removeItem(index),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Bottom Walk-Out Checkout Bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, -3)),
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('إجمالي الأصناف بالعربة:', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          Text(
                            '${_itemsInCart.length} أصناف • ${_totalWeightKg.toStringAsFixed(2)} كجم',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      Text(
                        '${_totalPrice.toStringAsFixed(2)} ل.س',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.freshGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _itemsInCart.isEmpty ? null : _handleWalkOutCheckout,
                      icon: const Icon(Icons.electric_bolt_rounded, color: AppColors.textPrimary),
                      label: const Text(
                        'إنهاء التسوق والمغادرة الفورية (Walk-Out Pay)',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    );
  }
}
