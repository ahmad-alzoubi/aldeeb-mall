import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/product_model.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/providers/mall_provider.dart';
import '../../core/providers/store_settings_provider.dart';
import '../../core/utils/responsive.dart';
import '../product/product_detail_screen.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final MobileScannerController _scannerController;
  final TextEditingController _manualBarcodeCtrl = TextEditingController();

  ProductModel? _scannedProduct;
  String _searchedCode = '';
  bool _isNotFound = false;
  bool _isTorchOn = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
      returnImage: false,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _manualBarcodeCtrl.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture, List<ProductModel> products) {
    if (_isProcessing || _scannedProduct != null) return;

    for (final barcode in capture.barcodes) {
      final code = barcode.rawValue?.trim() ?? '';
      if (code.isNotEmpty) {
        _isProcessing = true;
        HapticFeedback.mediumImpact();
        _manualBarcodeCtrl.text = code;
        _lookupBarcode(code, products);
        break;
      }
    }
  }

  void _lookupBarcode(String rawCode, List<ProductModel> products) {
    final code = rawCode.trim();
    if (code.isEmpty) {
      setState(() {
        _searchedCode = '';
        _scannedProduct = null;
        _isNotFound = false;
        _isProcessing = false;
      });
      return;
    }

    // 1. Search by exact barcode or ID
    ProductModel? match = products.where((p) {
      final b = (p.barcode ?? '').trim().toLowerCase();
      final id = p.id.trim().toLowerCase();
      final q = code.toLowerCase();
      return b == q || id == q;
    }).firstOrNull;

    // 2. Search by substring or name
    if (match == null) {
      final q = code.toLowerCase();
      match = products.where((p) {
        final b = (p.barcode ?? '').trim().toLowerCase();
        final nameAr = p.nameAr.toLowerCase();
        final nameEn = p.nameEn.toLowerCase();
        return (b.isNotEmpty && (b.contains(q) || q.contains(b))) ||
            nameAr.contains(q) ||
            nameEn.contains(q);
      }).firstOrNull;
    }

    setState(() {
      _searchedCode = code;
      _scannedProduct = match;
      _isNotFound = (match == null);
      _isProcessing = false;
    });
  }

  void _clearScan() {
    setState(() {
      _manualBarcodeCtrl.clear();
      _searchedCode = '';
      _scannedProduct = null;
      _isNotFound = false;
      _isProcessing = false;
    });
    try {
      _scannerController.start();
    } catch (_) {}
  }

  Future<void> _toggleTorch() async {
    try {
      await _scannerController.toggleTorch();
      setState(() => _isTorchOn = !_isTorchOn);
    } catch (_) {}
  }

  Future<void> _switchCamera() async {
    try {
      await _scannerController.switchCamera();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final mall = Provider.of<MallProvider>(context);
    final cart = Provider.of<CartProvider>(context);
    final settings = Provider.of<StoreSettingsProvider>(context);
    final products = mall.products.isNotEmpty ? mall.products : mall.filteredProducts;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.qr_code_scanner_rounded, color: AppColors.accent, size: 20),
                SizedBox(width: 8),
                Text(
                  'قارئ وفاحص الباركود الفعلي',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            Text(
              'مسح حي بالكاميرا ومطابقة فورية مع مخزون الديب مول',
              style: TextStyle(fontSize: 10.5, color: Colors.white60),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: _isTorchOn ? Colors.amberAccent : Colors.white60,
            ),
            onPressed: _toggleTorch,
            tooltip: 'إضاءة الكشاف',
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white60),
            onPressed: _switchCamera,
            tooltip: 'تبديل الكاميرا',
          ),
          if (_scannedProduct != null || _isNotFound)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
              onPressed: _clearScan,
              tooltip: 'مسح وإعادة الفحص',
            ),
        ],
      ),
      body: SafeArea(
        child: MaxWidthContainer(
          maxWidth: 900,
          child: Column(
            children: [
              // 1. Manual Barcode Entry Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isNotFound
                          ? Colors.redAccent.withValues(alpha: 0.6)
                          : const Color(0xFF334155),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.barcode_reader, color: AppColors.accent, size: 22),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _manualBarcodeCtrl,
                          keyboardType: TextInputType.text,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
                          decoration: InputDecoration(
                            hintText: 'أدخل الباركود يدوياً أو اختر صنفاً للتجربة...',
                            hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 13),
                            suffixIcon: _manualBarcodeCtrl.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded,
                                        size: 18, color: Colors.white60),
                                    onPressed: () {
                                      _manualBarcodeCtrl.clear();
                                      _lookupBarcode('', products);
                                    },
                                  )
                                : null,
                          ),
                          onChanged: (val) {
                            if (val.trim().isEmpty) {
                              _lookupBarcode('', products);
                            }
                          },
                          onSubmitted: (val) => _lookupBarcode(val, products),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 6, right: 6),
                        child: ElevatedButton(
                          onPressed: () => _lookupBarcode(_manualBarcodeCtrl.text, products),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('فحص السعر',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Barcode Samples Strip from Real Active Branch Products
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    const Icon(Icons.touch_app_outlined, color: AppColors.accent, size: 14),
                    const SizedBox(width: 4),
                    const Text(
                      'أصناف للتجربة المباشرة:',
                      style: TextStyle(
                          color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text(
                      '${products.length} صنف مسجل',
                      style: const TextStyle(color: Colors.white38, fontSize: 10.5),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: products.take(8).length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final p = products[index];
                    final barcode = p.barcode ?? p.id;
                    final isCurrent = _searchedCode == barcode;
                    return ActionChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            p.nameAr,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                              color: isCurrent ? AppColors.accent : Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${p.price.toStringAsFixed(0)} ${settings.currency})',
                            style: TextStyle(
                              fontSize: 10,
                              color: isCurrent ? Colors.white : Colors.white60,
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: isCurrent ? AppColors.primary : const Color(0xFF1E293B),
                      side: BorderSide(
                        color: isCurrent ? AppColors.accent : const Color(0xFF334155),
                      ),
                      onPressed: () {
                        _manualBarcodeCtrl.text = barcode;
                        _lookupBarcode(barcode, products);
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),

              // 3. Main Scanning Area or Product Card / Error Result
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // When a product is successfully matched
                      if (_scannedProduct != null)
                        _buildProductResultCard(context, _scannedProduct!, cart, settings)
                      // When a barcode was searched but not found in branch DB
                      else if (_isNotFound)
                        _buildNotFoundCard()
                      // Viewfinder default standby state with live camera
                      else
                        _buildScannerViewfinder(products),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Camera / Viewfinder Box HUD with Live MobileScanner
  Widget _buildScannerViewfinder(List<ProductModel> products) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 12),
        Container(
          width: 290,
          height: 290,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.6), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.cyanAccent.withValues(alpha: 0.2),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Live camera feed via MobileScanner
                MobileScanner(
                  controller: _scannerController,
                  onDetect: (capture) => _onDetect(capture, products),
                  errorBuilder: (ctx, err) => _buildCameraErrorWidget(),
                  fit: BoxFit.cover,
                ),

                // Animated Laser Line
                AnimatedBuilder(
                  animation: _animController,
                  builder: (ctx, child) {
                    return Positioned(
                      top: 290 * _animController.value,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: Colors.cyanAccent,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.cyanAccent.withValues(alpha: 0.9),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Corner Reticle Accents
                _cornerAccent(top: 14, right: 14, isTop: true, isRight: true),
                _cornerAccent(top: 14, left: 14, isTop: true, isRight: false),
                _cornerAccent(bottom: 14, right: 14, isTop: false, isRight: true),
                _cornerAccent(bottom: 14, left: 14, isTop: false, isRight: false),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Helper instructions
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.center_focus_strong, color: Colors.cyanAccent, size: 16),
              SizedBox(width: 8),
              Text(
                'وجّه الكاميرا نحو الباركود ليتم مسحه وتحديد السعر فورياً',
                style: TextStyle(color: Colors.white70, fontSize: 11.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCameraErrorWidget() {
    return Container(
      color: const Color(0xFF1E293B),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.camera_alt_outlined, color: Colors.amberAccent, size: 40),
          const SizedBox(height: 10),
          const Text(
            'الكاميرا غير متاحة حالياً',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 4),
          const Text(
            'يمكنك إدخال رقم الباركود يدوياً أو النقر على أحد الأصناف للتجربة',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60, fontSize: 11),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () async {
              await Permission.camera.request();
              _scannerController.start();
              setState(() {});
            },
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('إعادة المحاولة / منح الإذن',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cornerAccent({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required bool isTop,
    required bool isRight,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          border: Border(
            top: isTop ? const BorderSide(color: Colors.cyanAccent, width: 3) : BorderSide.none,
            bottom: !isTop ? const BorderSide(color: Colors.cyanAccent, width: 3) : BorderSide.none,
            right: isRight ? const BorderSide(color: Colors.cyanAccent, width: 3) : BorderSide.none,
            left: !isRight ? const BorderSide(color: Colors.cyanAccent, width: 3) : BorderSide.none,
          ),
        ),
      ),
    );
  }

  // Not Found Card
  Widget _buildNotFoundCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off_rounded, color: Colors.redAccent, size: 48),
          ),
          const SizedBox(height: 16),
          const Text(
            'لم يتم العثور على أي صنف بهذا الباركود',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'الرمز المدخل: $_searchedCode',
              style: const TextStyle(
                  fontSize: 12, color: Colors.amberAccent, fontFamily: 'monospace'),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'الصنف غير مدرج في قاعدة بيانات هذا الفرع، أو تم إدخال رقم الباركود بشكل غير صحيح.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.white60, height: 1.4),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _clearScan,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('مسح كود آخر',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context, _searchedCode);
                  },
                  icon: const Icon(Icons.search_rounded, size: 16, color: Colors.cyanAccent),
                  label: const Text('بحث بالمتجر',
                      style: TextStyle(
                          color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.cyanAccent),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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

  // Real Matched Product Card
  Widget _buildProductResultCard(
    BuildContext context,
    ProductModel product,
    CartProvider cart,
    StoreSettingsProvider settings,
  ) {
    final currency = settings.currency;
    final inStock = product.stockQuantity > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Product Image + Basic Info + Close Button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image with Unit Badge
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: product.firstImage,
                      width: 86,
                      height: 86,
                      fit: BoxFit.cover,
                      placeholder: (ctx, url) => Container(
                        width: 86,
                        height: 86,
                        color: Colors.grey.shade100,
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      errorWidget: (ctx, url, err) => Container(
                        width: 86,
                        height: 86,
                        color: AppColors.primary.withValues(alpha: 0.1),
                        child: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                      ),
                      child: Text(
                        product.unitLabelAr,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),

              // Title, Brand, Barcode
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            product.brand ?? 'الديب مول',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (product.barcode != null)
                          Expanded(
                            child: Text(
                              'باركود: ${product.barcode}',
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 9.5,
                                fontFamily: 'monospace',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      product.nameAr,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Color(0xFF0F172A),
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Price display
                    Row(
                      children: [
                        Text(
                          '${product.price.toStringAsFixed(0)} $currency',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 19,
                            color: AppColors.primary,
                          ),
                        ),
                        if (product.originalPrice != null &&
                            product.originalPrice! > product.price) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${product.originalPrice!.toStringAsFixed(0)} $currency',
                            style: const TextStyle(
                              fontSize: 12.5,
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
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Close / Reset Button
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8), size: 22),
                onPressed: _clearScan,
                tooltip: 'مسح صنف آخر',
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Stock and Location Information
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Icon(
                  inStock ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: inStock ? Colors.green.shade600 : Colors.red.shade600,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    inStock
                        ? 'متوفر في الفرع الحالي (${product.stockQuantity} قطعة جاهزة للتسوق)'
                        : 'هذا الصنف نفد حالياً من المخزون في الفرع النشط',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: inStock ? Colors.green.shade800 : Colors.red.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Action Buttons: Details + Add to Cart
          Row(
            children: [
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
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'تفاصيل الصنف',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: inStock
                      ? () {
                          cart.addToCart(product);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded,
                                      color: Colors.white, size: 18),
                                  const SizedBox(width: 8),
                                  Text('✓ تمت إضافة "${product.nameAr}" إلى سلة التسوق!'),
                                ],
                              ),
                              backgroundColor: AppColors.primaryDark,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                          _clearScan();
                        }
                      : null,
                  icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                  label: Text(
                    inStock ? 'أضف للسلة فوراً' : 'غير متوفر',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade500,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Return to Home Search
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context, product.nameAr);
              },
              icon: const Icon(Icons.search_rounded, size: 16, color: AppColors.primary),
              label: const Text(
                'عرض في نتائج بحث الصفحة الرئيسية',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
