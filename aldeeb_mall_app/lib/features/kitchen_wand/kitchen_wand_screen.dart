import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/product_model.dart';
import '../../core/providers/cart_provider.dart';

class KitchenWandScreen extends StatefulWidget {
  const KitchenWandScreen({super.key});

  @override
  State<KitchenWandScreen> createState() => _KitchenWandScreenState();
}

class _KitchenWandScreenState extends State<KitchenWandScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isWandScanning = false;
  String? _lastScannedItem;
  Timer? _laserAnimationTimer;
  double _laserPosition = 0.0;
  bool _laserMovingDown = true;

  // Household Pantry inventory items
  final List<Map<String, dynamic>> _pantryItems = [
    {
      'id': 'pantry-1',
      'product': const ProductModel(
        id: 'p-milk',
        nameAr: 'حليب المراعي طازج كامل الدسم 2 لتر',
        nameEn: 'Almarai Fresh Milk Full Fat 2L',
        price: 11.50,
        images: ['https://images.unsplash.com/photo-1550583724-b2692b85b150?w=500'],
        unit: 'bottle',
      ),
      'remainingPercent': 15,
      'daysUntilDepletion': 2,
      'autoReorder': true,
      'category': 'منتجات الألبان',
    },
    {
      'id': 'pantry-2',
      'product': const ProductModel(
        id: 'p-rice',
        nameAr: 'أرز بسمتي أبيض الشعلان سيلا 5 كجم',
        nameEn: 'Al Shalan Basmati White Rice 5kg',
        price: 42.50,
        images: ['https://images.unsplash.com/photo-1586201375761-83865001e31c?w=500'],
        unit: 'pack',
      ),
      'remainingPercent': 65,
      'daysUntilDepletion': 18,
      'autoReorder': false,
      'category': 'الأرز والحبوب',
    },
    {
      'id': 'pantry-3',
      'product': const ProductModel(
        id: 'p-oil',
        nameAr: 'زيت زيتون الجوف بكر ممتاز معصور على البارد 500 مل',
        nameEn: 'Al Jouf Extra Virgin Olive Oil 500ml',
        price: 34.00,
        images: ['https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=500'],
        unit: 'bottle',
      ),
      'remainingPercent': 20,
      'daysUntilDepletion': 3,
      'autoReorder': true,
      'category': 'الزيوت والتوابل',
    },
    {
      'id': 'pantry-4',
      'product': const ProductModel(
        id: 'p-detergent',
        nameAr: 'كبسولات غسيل إريال الكل في واحد 28 كبسولة',
        nameEn: 'Ariel All-in-1 Laundry Pods 28 Pods',
        price: 48.00,
        images: ['https://images.unsplash.com/photo-1610557892470-55d9e80c0bce?w=500'],
        unit: 'pack',
      ),
      'remainingPercent': 10,
      'daysUntilDepletion': 1,
      'autoReorder': true,
      'category': 'المنظفات والعناية',
    },
    {
      'id': 'pantry-5',
      'product': const ProductModel(
        id: 'p-coffee',
        nameAr: 'بن هرري إثيوبي فاخر محمص الديب 500 جم',
        nameEn: 'Aldeeb Premium Harari Coffee Beans 500g',
        price: 38.00,
        images: ['https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=500'],
        unit: 'pack',
      ),
      'remainingPercent': 45,
      'daysUntilDepletion': 10,
      'autoReorder': false,
      'category': 'القهوة والمشروبات',
    },
    {
      'id': 'pantry-6',
      'product': const ProductModel(
        id: 'p-eggs',
        nameAr: 'بيض وطني طازج مزارع فقيه 30 بيضة',
        nameEn: 'Fakieh Fresh Local Farm Eggs 30 Eggs',
        price: 19.50,
        images: ['https://images.unsplash.com/photo-1516448620398-c5f44bf9f441?w=500'],
        unit: 'pack',
      ),
      'remainingPercent': 15,
      'daysUntilDepletion': 2,
      'autoReorder': true,
      'category': 'البيض والألبان',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _laserAnimationTimer?.cancel();
    super.dispose();
  }

  void _triggerWandScanSimulation() {
    setState(() {
      _isWandScanning = true;
      _lastScannedItem = null;
    });

    _laserAnimationTimer?.cancel();
    _laserAnimationTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) return;
      setState(() {
        if (_laserMovingDown) {
          _laserPosition += 0.05;
          if (_laserPosition >= 1.0) _laserMovingDown = false;
        } else {
          _laserPosition -= 0.05;
          if (_laserPosition <= 0.0) _laserMovingDown = true;
        }
      });
    });

    // Simulate recognition after 2 seconds
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      _laserAnimationTimer?.cancel();
      setState(() {
        _isWandScanning = false;
        _lastScannedItem = 'حليب المراعي طازج كامل الدسم 2 لتر';
        // Reset milk level to 100%
        _pantryItems[0]['remainingPercent'] = 100;
        _pantryItems[0]['daysUntilDepletion'] = 14;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text('تم المسح بنجاح! تم تحديث مخزون الحليب في المؤونة المنزلية إلى 100%'),
              ),
            ],
          ),
          backgroundColor: AppColors.freshGreen,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final lowStockItems = _pantryItems.where((item) => (item['remainingPercent'] as int) <= 20).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.microwave_rounded, color: Colors.amber, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'عصا المطبخ الذكية والمؤونة',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Aldeeb Smart Kitchen Wand • تتبع مخزون المنزل وإعادة التعبئة',
                  style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          indicatorWeight: 3,
          labelColor: Colors.amber,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.qr_code_scanner_rounded, size: 18), text: 'مسح الباركود بالعصا'),
            Tab(icon: Icon(Icons.kitchen_rounded, size: 18), text: 'مؤونة المطبخ الذكية'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWandScannerView(),
          _buildPantryInventoryView(cart, lowStockItems),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1: SMART WAND SCANNER SIMULATOR
  // ===========================================================================
  Widget _buildWandScannerView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Wand Device Status Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.wifi_tethering_rounded, color: Colors.amber, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'عصا الديب ماغنت متصلة (Kitchen Wand)',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'مغناطيس الثلاجة الذكي • اتصال واي فاي منزلي 5G • بطارية 94%',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                  ),
                  child: const Text(
                    'متصل 🟢',
                    style: TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Virtual Scanner Viewport
          Container(
            width: double.infinity,
            height: 280,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white24, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background simulated camera preview
                Opacity(
                  opacity: 0.4,
                  child: Image.network(
                    'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=500',
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey.shade900),
                  ),
                ),

                // Barcode Guide Frame
                Container(
                  width: 220,
                  height: 140,
                  decoration: BoxDecoration(
                    border: Border.all(color: _isWandScanning ? Colors.redAccent : Colors.amber, width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    children: [
                      // Laser animation line
                      if (_isWandScanning)
                        Positioned(
                          top: 140 * _laserPosition,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.redAccent.withValues(alpha: 0.8),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Status Overlay text
                Positioned(
                  bottom: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(
                      _isWandScanning
                          ? '⚡ جارٍ قراءة الباركود عبر مستشعر الليزر...'
                          : 'وجّه باركود المنتج الفارغ إلى عدسة العصا',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Scan Trigger Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
              icon: Icon(_isWandScanning ? Icons.hourglass_top_rounded : Icons.barcode_reader),
              label: Text(
                _isWandScanning ? 'جارٍ المسح بالليزر...' : 'محاكاة ضغط زر العصا والمسح',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              onPressed: _isWandScanning ? null : _triggerWandScanSimulation,
            ),
          ),
          const SizedBox(height: 16),

          // Last Scanned Result Card
          if (_lastScannedItem != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFA7F3D0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 30),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'تم التعرف على المنتج بنجاح:',
                          style: TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _lastScannedItem!,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'المخزون 100% 🟢',
                      style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 2: SMART PANTRY INVENTORY TRACKER
  // ===========================================================================
  Widget _buildPantryInventoryView(CartProvider cart, List<Map<String, dynamic>> lowStockItems) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Low Stock Batch Re-order Banner
        if (lowStockItems.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF991B1B), Color(0xFFB91C1C)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'تنبيه: ${lowStockItems.length} منتجات في مؤونتك أوشكت على النفاد!',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'الحليب والزيت ومسحوق الغسيل والبيض بحاجة لإعادة تعبئة خلال 48 ساعة لتجنب انقطاعها.',
                  style: TextStyle(color: Color(0xFFFECACA), fontSize: 12, height: 1.3),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF991B1B),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 18),
                    label: Text(
                      'إعادة تعبئة النواقص فوراً إلى السلة (${lowStockItems.length} منتجات)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: () {
                      for (final item in lowStockItems) {
                        cart.addToCart(item['product'] as ProductModel);
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('تمت إضافة جميع النواقص (${lowStockItems.length} منتجات) إلى سلة التسوق'),
                          backgroundColor: AppColors.freshGreen,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

        // Section Title
        const Text(
          'مخزون المؤونة المنزلية التقديري (AI Smart Pantry):',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 10),

        // List of Pantry Items
        ..._pantryItems.map((item) {
          final product = item['product'] as ProductModel;
          final percent = item['remainingPercent'] as int;
          final daysLeft = item['daysUntilDepletion'] as int;
          final isLow = percent <= 20;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: isLow ? Colors.red.shade300 : Colors.grey.shade200,
                width: isLow ? 1.5 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Product Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          product.firstImage,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.kitchen_rounded, color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.nameAr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'التصنيف: ${item['category']} • السعر: ${product.price.toStringAsFixed(2)} ل.س',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),

                      // Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isLow ? Colors.red.shade50 : const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isLow ? '$percent% (ينفد بعد $daysLeft يوم ⚠️)' : '$percent% (يكفي $daysLeft يوم)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isLow ? Colors.red.shade800 : const Color(0xFF047857),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percent / 100.0,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isLow ? Colors.red : const Color(0xFF10B981),
                      ),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Manual Adjustment / Quick Add
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline_rounded, size: 20, color: Colors.grey),
                            onPressed: () {
                              setState(() {
                                if (item['remainingPercent'] > 10) {
                                  item['remainingPercent'] = (item['remainingPercent'] as int) - 10;
                                }
                              });
                            },
                          ),
                          const Text('تعديل الاستهلاك', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline_rounded, size: 20, color: Colors.grey),
                            onPressed: () {
                              setState(() {
                                if (item['remainingPercent'] < 100) {
                                  item['remainingPercent'] = (item['remainingPercent'] as int) + 10;
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.add_shopping_cart_rounded, size: 14),
                        label: const Text('إضافة للسلة', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          cart.addToCart(product);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('تمت إضافة ${product.nameAr} إلى السلة'),
                              backgroundColor: const Color(0xFF0F172A),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
