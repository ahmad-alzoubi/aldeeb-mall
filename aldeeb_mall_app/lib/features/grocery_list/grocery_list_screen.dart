import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/product_model.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/providers/mall_provider.dart';
import '../../core/utils/responsive.dart';
import '../cart/cart_screen.dart';

class GroceryItem {
  final String id;
  final String title;
  final String department; // 'الألبان والأجبان', 'الخضار والفواكه', 'المخبوزات', 'اللحوم', 'المؤن'
  bool isChecked;
  ProductModel? matchedProduct;

  GroceryItem({
    required this.id,
    required this.title,
    required this.department,
    this.isChecked = false,
    this.matchedProduct,
  });
}

class GroceryListScreen extends StatefulWidget {
  const GroceryListScreen({super.key});

  @override
  State<GroceryListScreen> createState() => _GroceryListScreenState();
}

class _GroceryListScreenState extends State<GroceryListScreen> {
  final TextEditingController _itemInputController = TextEditingController();

  late List<GroceryItem> _items;

  @override
  void initState() {
    super.initState();
    final mall = Provider.of<MallProvider>(context, listen: false);
    final p = mall.products;

    _items = [
      GroceryItem(
        id: '1',
        title: 'حليب كامل الدسم',
        department: 'الألبان والأجبان 🥛',
        matchedProduct: p.isNotEmpty ? p[0] : null,
      ),
      GroceryItem(
        id: '2',
        title: 'جبنة فيتا يونانية',
        department: 'الألبان والأجبان 🥛',
        matchedProduct: p.length > 1 ? p[1] : null,
      ),
      GroceryItem(
        id: '3',
        title: 'طماطم مزارع طازجة',
        department: 'الخضار والفواكه 🍅',
        matchedProduct: p.length > 2 ? p[2] : null,
      ),
      GroceryItem(
        id: '4',
        title: 'موز إكوادوري كرتون',
        department: 'الخضار والفواكه 🍅',
        matchedProduct: p.length > 3 ? p[3] : null,
      ),
      GroceryItem(
        id: '5',
        title: 'خبز بروتين وتوست',
        department: 'المخبوزات والحلويات 🍞',
      ),
      GroceryItem(
        id: '6',
        title: 'دجاج مبرد طازج 1000 غم',
        department: 'اللحوم والدواجن 🍗',
      ),
    ];
  }

  @override
  void dispose() {
    _itemInputController.dispose();
    super.dispose();
  }

  String _detectDepartment(String text) {
    final t = text.toLowerCase();
    if (t.contains('حليب') || t.contains('جبن') || t.contains('لبن') || t.contains('زبادي') || t.contains('زبدة')) {
      return 'الألبان والأجبان 🥛';
    }
    if (t.contains('طماطم') || t.contains('خيار') || t.contains('موز') || t.contains('تفاح') || t.contains('بصل') || t.contains('بطاطس') || t.contains('أفوكادو')) {
      return 'الخضار والفواكه 🍅';
    }
    if (t.contains('خبز') || t.contains('توست') || t.contains('صمولي') || t.contains('كرواسون') || t.contains('كيك')) {
      return 'المخبوزات والحلويات 🍞';
    }
    if (t.contains('دجاج') || t.contains('لحم') || t.contains('مفروم') || t.contains('سمك') || t.contains('شاورما')) {
      return 'اللحوم والدواجن 🍗';
    }
    return 'المؤن والأساسيات 🛒';
  }

  void _addItem() {
    final text = _itemInputController.text.trim();
    if (text.isEmpty) return;

    final mall = Provider.of<MallProvider>(context, listen: false);
    ProductModel? match;
    for (var p in mall.products) {
      if (p.nameAr.contains(text) || text.contains(p.nameAr)) {
        match = p;
        break;
      }
    }

    setState(() {
      _items.add(
        GroceryItem(
          id: 'item-${DateTime.now().millisecondsSinceEpoch}',
          title: text,
          department: _detectDepartment(text),
          matchedProduct: match,
        ),
      );
    });

    _itemInputController.clear();
  }

  void _addAllToCart() {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final mall = Provider.of<MallProvider>(context, listen: false);
    int addedCount = 0;

    for (var item in _items) {
      if (!item.isChecked) {
        ProductModel target = item.matchedProduct ?? (mall.products.isNotEmpty ? mall.products.first : _dummyProduct(item.title));
        cart.addToCart(target);
        addedCount++;
        item.isChecked = true;
      }
    }

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        content: Text('🎉 تمت إضافة $addedCount أصناف من قائمة مقاضيك إلى سلة الشراء بنجاح!'),
        action: SnackBarAction(
          label: 'عرض السلة',
          textColor: AppColors.accent,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartScreen()),
            );
          },
        ),
      ),
    );
  }

  ProductModel _dummyProduct(String name) {
    return ProductModel(
      id: 'dummy-${name.hashCode}',
      nameAr: name,
      nameEn: 'Grocery Item',
      price: 15.0,
      images: const ['https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=600&q=80'],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    // Group items by department
    final Map<String, List<GroceryItem>> grouped = {};
    for (var item in _items) {
      grouped.putIfAbsent(item.department, () => []).add(item);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('منظم وقائمة المقاضي الذكية (Smart Grocery List)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'مسح الأصناف المكتملة',
            onPressed: () {
              setState(() => _items.removeWhere((i) => i.isChecked));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: MaxWidthContainer(
          maxWidth: 900,
          child: Padding(
            padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick Input Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add_shopping_cart_rounded, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _itemInputController,
                          onSubmitted: (_) => _addItem(),
                          decoration: const InputDecoration(
                            hintText: 'اكتب الصنف المطلوب (مثال: حليب، بيض، أفوكادو، طحين)...',
                            hintStyle: TextStyle(fontSize: 13, color: AppColors.textMuted),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 28),
                        onPressed: _addItem,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Top Actions: Convert all to cart
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'المقاضي المجدولة (${_items.where((i) => !i.isChecked).length} صنف متبقٍ)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                    ),
                    ElevatedButton.icon(
                      onPressed: _items.isEmpty ? null : _addAllToCart,
                      icon: const Icon(Icons.shopping_bag_outlined, size: 16),
                      label: const Text('نقل الكل للسلة بضغطة واحدة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Grouped Department Shelves
                ...grouped.entries.map((entry) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                entry.key,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${entry.value.length} عناصر',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Divider(height: 1, color: AppColors.border),
                        const SizedBox(height: 6),

                        ...entry.value.map((item) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Checkbox(
                              value: item.isChecked,
                              activeColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                              onChanged: (v) {
                                setState(() => item.isChecked = v ?? false);
                              },
                            ),
                            title: Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                decoration: item.isChecked ? TextDecoration.lineThrough : null,
                                color: item.isChecked ? AppColors.textMuted : AppColors.textPrimary,
                              ),
                            ),
                            subtitle: item.matchedProduct != null
                                ? Text(
                                    'مطابق في الكتالوج: ${item.matchedProduct!.price.toStringAsFixed(2)} ر.س',
                                    style: const TextStyle(fontSize: 11, color: AppColors.freshGreen, fontWeight: FontWeight.bold),
                                  )
                                : null,
                            trailing: IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                              onPressed: () {
                                setState(() => _items.removeWhere((i) => i.id == item.id));
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
