import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/product_model.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/providers/mall_provider.dart';
import '../../core/utils/responsive.dart';
import '../product/product_detail_screen.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final TextEditingController _manualBarcodeCtrl = TextEditingController();
  ProductModel? _scannedProduct;
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    _manualBarcodeCtrl.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(String barcode, List<ProductModel> products) {
    final match = products.firstWhere(
      (p) => p.barcode == barcode || p.id == barcode,
      orElse: () => products.first,
    );

    setState(() {
      _scannedProduct = match;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mall = Provider.of<MallProvider>(context);
    final cart = Provider.of<CartProvider>(context);
    final products = mall.filteredProducts;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('المسح الذكي والأسعار (Scan & Go)'),
        actions: [
          IconButton(
            icon: Icon(_isTorchOn ? Icons.flash_on : Icons.flash_off, color: AppColors.accent),
            onPressed: () => setState(() => _isTorchOn = !_isTorchOn),
            tooltip: 'إضاءة الفلاش',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background Simulated Camera Feed
          Positioned.fill(
            child: Opacity(
              opacity: 0.35,
              child: Image.network(
                'https://images.unsplash.com/photo-1578916171728-46686eac8d58?auto=format&fit=crop&w=1200&q=80',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Central Viewfinder Area
          Align(
            alignment: const Alignment(0, -0.2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Scan Frame
                Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.accent, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.25),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Stack(
                      children: [
                        // Animated Scanning Laser Line
                        AnimatedBuilder(
                          animation: _animController,
                          builder: (ctx, child) {
                            return Positioned(
                              top: 280 * _animController.value,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.accent,
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        // Corner Guides
                        const Center(
                          child: Icon(Icons.qr_code_scanner, color: Colors.white24, size: 100),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Text(
                    'وجّه الكاميرا نحو باركود الصنف لمعرفة السعر والمواصفات فوراً',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // Quick Demo Barcode Simulation Buttons
          Positioned(
            left: 16,
            right: 16,
            bottom: _scannedProduct != null ? 240 : 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'نماذج باركود حية للاختبار السريع (Demo Barcodes):',
                  style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _demoBarcodeChip('629100000001', 'موز كافنديش 🍌', products),
                      const SizedBox(width: 8),
                      _demoBarcodeChip('629100000004', 'حليب المراعي 🥛', products),
                      const SizedBox(width: 8),
                      _demoBarcodeChip('629100000003', 'طماطم مزارع 🍅', products),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Scanned Product Preview Bottom Sheet
          if (_scannedProduct != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 20,
              child: MaxWidthContainer(
                maxWidth: 600,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: _scannedProduct!.firstImage,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _scannedProduct!.nameAr,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      '${_scannedProduct!.price.toStringAsFixed(2)} ل.س',
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.primary),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'الباركود: ${_scannedProduct!.barcode ?? "629100000001"}',
                                      style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontFamily: 'monospace'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: AppColors.textMuted),
                            onPressed: () => setState(() => _scannedProduct = null),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProductDetailScreen(product: _scannedProduct!),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.primary),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('تفاصيل الصنف', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                cart.addToCart(_scannedProduct!);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('✓ تمت إضافة ${_scannedProduct!.nameAr} إلى السلة!'),
                                    backgroundColor: AppColors.primary,
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                                setState(() => _scannedProduct = null);
                              },
                              icon: const Icon(Icons.add_shopping_cart, size: 18),
                              label: const Text('أضف للسلة فوراً', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _demoBarcodeChip(String barcode, String label, List<ProductModel> products) {
    return InkWell(
      onTap: () => _onBarcodeDetected(barcode, products),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          children: [
            const Icon(Icons.qr_code_2, size: 16, color: AppColors.accent),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
