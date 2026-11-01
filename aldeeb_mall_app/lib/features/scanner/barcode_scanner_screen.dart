import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/models/product_model.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/providers/mall_provider.dart';
import '../../core/providers/store_settings_provider.dart';
import '../../core/utils/responsive.dart';
import '../product/product_detail_screen.dart';

enum ScannerMode {
  photoSnap,    // تصوير المنتج بالكاميرا والتعرف عليه بالـ AI
  laserBarcode, // مسح الباركود المباشر
}

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final TextEditingController _manualBarcodeCtrl = TextEditingController();

  ScannerMode _mode = ScannerMode.photoSnap;
  ProductModel? _scannedProduct;
  bool _isTorchOn = false;
  bool _isAnalyzing = false;
  String _analyzingText = 'جاري تحليل الصورة والتعرف البصري بالذكاء الاصطناعي...';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    _manualBarcodeCtrl.dispose();
    super.dispose();
  }

  // Trigger simulated photo snap & AI recognition
  void _snapPhotoAndAnalyze(ProductModel targetProduct) {
    setState(() {
      _isAnalyzing = true;
      _analyzingText = 'جاري التقاط الصورة وتحليل مواصفات الصنف بالـ AI...';
    });

    Timer(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _scannedProduct = targetProduct;
      });
    });
  }

  void _onBarcodeDetected(String barcode, List<ProductModel> products) {
    setState(() {
      _isAnalyzing = true;
      _analyzingText = 'جاري مطابقة الباركود مع قاعدة بيانات المتجر...';
    });

    Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      final match = products.firstWhere(
        (p) => p.barcode == barcode || p.id == barcode,
        orElse: () => products.first,
      );

      setState(() {
        _isAnalyzing = false;
        _scannedProduct = match;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final mall = Provider.of<MallProvider>(context);
    final cart = Provider.of<CartProvider>(context);
    final settings = Provider.of<StoreSettingsProvider>(context);
    final products = mall.products.isNotEmpty ? mall.products : mall.filteredProducts;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.camera_alt_rounded, color: Colors.amberAccent, size: 20),
            const SizedBox(width: 8),
            Text(
              _mode == ScannerMode.photoSnap
                  ? 'تصوير المنتج بالـ AI لمعرفة السعر'
                  : 'مسح الباركود السريع (Scan & Go)',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: _isTorchOn ? Colors.amberAccent : Colors.white70,
            ),
            onPressed: () => setState(() => _isTorchOn = !_isTorchOn),
            tooltip: 'إضاءة الفلاش',
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Simulated Live In-Store Camera Viewfinder Background
          Positioned.fill(
            child: Opacity(
              opacity: _isTorchOn ? 0.55 : 0.35,
              child: Image.network(
                _mode == ScannerMode.photoSnap
                    ? 'https://images.unsplash.com/photo-1578916171728-46686eac8d58?auto=format&fit=crop&w=1200&q=80'
                    : 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=1200&q=80',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 2. Top Scanner Mode Switcher (Photo vs Barcode)
          Positioned(
            top: 16,
            left: 20,
            right: 20,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white24, width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildModeButton(
                      mode: ScannerMode.photoSnap,
                      icon: Icons.camera_enhance_rounded,
                      label: 'تصوير المنتج بالـ AI',
                      isActive: _mode == ScannerMode.photoSnap,
                    ),
                    _buildModeButton(
                      mode: ScannerMode.laserBarcode,
                      icon: Icons.qr_code_scanner_rounded,
                      label: 'مسح الباركود',
                      isActive: _mode == ScannerMode.laserBarcode,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Central Viewfinder HUD Area
          Align(
            alignment: const Alignment(0, -0.22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Scan Reticle Box
                Container(
                  width: 290,
                  height: 290,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: _mode == ScannerMode.photoSnap ? Colors.amberAccent : Colors.cyanAccent,
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_mode == ScannerMode.photoSnap ? Colors.amberAccent : Colors.cyanAccent)
                            .withValues(alpha: 0.25),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: Stack(
                      children: [
                        // Animated Scanning Laser Line
                        AnimatedBuilder(
                          animation: _animController,
                          builder: (ctx, child) {
                            return Positioned(
                              top: 290 * _animController.value,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 3.5,
                                decoration: BoxDecoration(
                                  color: _mode == ScannerMode.photoSnap ? Colors.amberAccent : Colors.cyanAccent,
                                  boxShadow: [
                                    BoxShadow(
                                      color: _mode == ScannerMode.photoSnap ? Colors.amberAccent : Colors.cyanAccent,
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        // Center Icon & Frame HUD
                        Center(
                          child: Icon(
                            _mode == ScannerMode.photoSnap
                                ? Icons.filter_center_focus_rounded
                                : Icons.qr_code_scanner_rounded,
                            color: Colors.white24,
                            size: 110,
                          ),
                        ),

                        // Corner Target Accents
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Colors.white, width: 3),
                                right: BorderSide(color: Colors.white, width: 3),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Colors.white, width: 3),
                                left: BorderSide(color: Colors.white, width: 3),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.white, width: 3),
                                right: BorderSide(color: Colors.white, width: 3),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 12,
                          left: 12,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.white, width: 3),
                                left: BorderSide(color: Colors.white, width: 3),
                              ),
                            ),
                          ),
                        ),

                        // Analyzing Overlay
                        if (_isAnalyzing)
                          Container(
                            color: Colors.black.withValues(alpha: 0.7),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(
                                    width: 36,
                                    height: 36,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: Colors.amberAccent,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      _analyzingText,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
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
                ),
                const SizedBox(height: 14),

                // Instruction Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24, width: 0.8),
                  ),
                  child: Text(
                    _mode == ScannerMode.photoSnap
                        ? '📸 صوّر المنتج أو اختر من النماذج لمعرفة سعره وعروضه فوراً'
                        : '⚡ وجّه الكاميرا نحو باركود الصنف لمطابقة السعر فوراً',
                    style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // 4. In-Store Live Products Simulation Chips (One-Click Camera Snap Test)
          Positioned(
            left: 16,
            right: 16,
            bottom: _scannedProduct != null ? 360 : 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _mode == ScannerMode.photoSnap
                          ? 'أصناف المتجر للتصوير السريع (Snap Samples):'
                          : 'باركود أصناف المتجر (Barcode Samples):',
                      style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const Text('اسحب للمزيد ←', style: TextStyle(color: Colors.white38, fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: products.take(6).map((prod) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _demoProductChip(prod, products),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // 5. Camera Shutter Button (For Photo Snap Mode)
          if (_scannedProduct == null && _mode == ScannerMode.photoSnap)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    if (products.isNotEmpty) {
                      _snapPhotoAndAnalyze(products.first);
                    }
                  },
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.amberAccent, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amberAccent.withValues(alpha: 0.4),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.camera_alt_rounded, color: Colors.black, size: 32),
                    ),
                  ),
                ),
              ),
            ),

          // 6. COMPREHENSIVE IN-STORE PRODUCT INTELLIGENCE CARD (When Product Identified)
          if (_scannedProduct != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: MaxWidthContainer(
                maxWidth: 620,
                child: _buildProductDetailsCard(context, _scannedProduct!, cart, settings, products),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required ScannerMode mode,
    required IconData icon,
    required String label,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _mode = mode;
          _scannedProduct = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.amberAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? Colors.black : Colors.white70,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.black : Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _demoProductChip(ProductModel product, List<ProductModel> allProducts) {
    return InkWell(
      onTap: () {
        if (_mode == ScannerMode.photoSnap) {
          _snapPhotoAndAnalyze(product);
        } else {
          _onBarcodeDetected(product.barcode ?? product.id, allProducts);
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24, width: 0.6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: product.firstImage,
                width: 22,
                height: 22,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              product.nameAr,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // Comprehensive Product Intelligence Sheet (Price, Offers, Nutrition, Alternatives)
  Widget _buildProductDetailsCard(
    BuildContext context,
    ProductModel product,
    CartProvider cart,
    StoreSettingsProvider settings,
    List<ProductModel> allProducts,
  ) {
    final currency = settings.currency;
    final hasOffers = product.hasDiscount || product.isDailyDeal;
    final relatedProducts = allProducts
        .where((p) => p.id != product.id && p.categoryId == product.categoryId)
        .take(4)
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Product Info & Dismiss
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image with In-Store Tag
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: product.firstImage,
                      width: 76,
                      height: 76,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      color: Colors.black.withValues(alpha: 0.75),
                      child: Text(
                        product.unitLabelAr,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // Title, Category, Barcode
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            product.brand ?? 'الديب مول',
                            style: TextStyle(color: Colors.blue.shade800, fontSize: 9.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (product.barcode != null)
                          Text(
                            'باركود: ${product.barcode}',
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5, fontFamily: 'monospace'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      product.nameAr,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Price and Discount Row
                    Row(
                      children: [
                        Text(
                          '${product.price.toStringAsFixed(2)} $currency',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: settings.primaryColor,
                          ),
                        ),
                        if (product.originalPrice != null && product.originalPrice! > product.price) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${product.originalPrice!.toStringAsFixed(2)} $currency',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF94A3B8),
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: Colors.red.shade600,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'وفر %${product.discountPercent > 0 ? product.discountPercent : 20}',
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Close / Scan Another Button
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8), size: 22),
                onPressed: () => setState(() => _scannedProduct = null),
                tooltip: 'إغلاق ومسح صنف آخر',
              ),
            ],
          ),

          const SizedBox(height: 10),

          // In-Store Offers & Location Pills
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: Colors.blue, size: 14),
                    const SizedBox(width: 4),
                    const Text(
                      'موقع الصنف في الفرع: ',
                      style: TextStyle(fontSize: 10.5, color: Color(0xFF475569), fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      'الممر 4 - الرف الأوسط (أصناف طازجة)',
                      style: TextStyle(fontSize: 10.5, color: Color(0xFF0F172A), fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.local_fire_department_rounded, color: Colors.deepOrange, size: 14),
                    const SizedBox(width: 4),
                    const Text(
                      'العروض الحالية: ',
                      style: TextStyle(fontSize: 10.5, color: Color(0xFF475569), fontWeight: FontWeight.bold),
                    ),
                    Text(
                      hasOffers
                        ? '🔥 عرض ترويجي نشط بنسبة حسم خاصة!'
                        : 'متاح للشراء التشاركي مع الجيران للتوفير حتى 40%',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: hasOffers ? Colors.deepOrange.shade800 : Colors.teal.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (relatedProducts.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.amber, size: 14),
                SizedBox(width: 4),
                Text(
                  'أصناف وعروض بديلة قد تهمك في نفس القسم:',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: relatedProducts.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final rel = relatedProducts[i];
                  return InkWell(
                    onTap: () => setState(() => _scannedProduct = rel),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: rel.firstImage,
                              width: 20,
                              height: 20,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${rel.nameAr} (${rel.price.toStringAsFixed(1)} $currency)',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Action Buttons: Add to Cart, Add to Grocery List, View Full Details
          Row(
            children: [
              // Details Button
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(product: product),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  side: BorderSide(color: settings.primaryColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('التفاصيل الكاملة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              ),
              const SizedBox(width: 8),

              // Add to Grocery List Button
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✓ أُضيف ${product.nameAr} إلى مخطط المقاضي الذكي!'),
                      backgroundColor: Colors.teal.shade700,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                icon: const Icon(Icons.playlist_add_check_rounded, color: Colors.teal, size: 22),
                tooltip: 'أضف لقائمتي الذكية',
              ),
              const SizedBox(width: 4),

              // Add to Cart Button (Main CTA)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    cart.addToCart(product);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text('✓ تمت إضافة ${product.nameAr} إلى السلة!'),
                          ],
                        ),
                        backgroundColor: settings.primaryColor,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                    setState(() => _scannedProduct = null);
                  },
                  icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                  label: const Text('أضف للسلة فوراً', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: settings.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
