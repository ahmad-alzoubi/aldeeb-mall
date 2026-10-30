import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/product_model.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/providers/mall_provider.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  double _selectedWeight = 1.0;

  @override
  void initState() {
    super.initState();
    _selectedWeight = widget.product.unit == 'kg' ? widget.product.weightStep : 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final mall = Provider.of<MallProvider>(context);
    final isFav = mall.isFavorite(widget.product.id);
    final currentQty = cart.getProductQuantity(widget.product.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.product.brand ?? 'تفاصيل المنتج'),
        actions: [
          IconButton(
            icon: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav ? AppColors.secondary : Colors.white,
            ),
            onPressed: () => mall.toggleFavorite(widget.product.id),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم نسخ رابط المنتج للمشاركة!')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section with Discount Badge
            Stack(
              children: [
                Container(
                  height: 300,
                  width: double.infinity,
                  color: Colors.white,
                  child: CachedNetworkImage(
                    imageUrl: widget.product.firstImage,
                    fit: BoxFit.contain,
                    placeholder: (ctx, url) => const Center(child: CircularProgressIndicator()),
                    errorWidget: (ctx, url, err) => const Icon(Icons.image_not_supported, size: 64, color: AppColors.textMuted),
                  ),
                ),
                if (widget.product.hasDiscount)
                  PositionedDirectional(
                    top: 16,
                    start: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'وفر ${widget.product.discountPercent}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Content Card
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand & Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.product.brand ?? 'الديب مول',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: AppColors.accent, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            widget.product.rating.toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${widget.product.salesCount} مبيعة)',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Title (Arabic & English)
                  Text(
                    widget.product.nameAr,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    widget.product.nameEn,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Price Row
                  Row(
                    children: [
                      Text(
                        '${widget.product.price.toStringAsFixed(2)} د.إ',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'لكل ${widget.product.unitLabelAr}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      if (widget.product.originalPrice != null)
                        Text(
                          '${widget.product.originalPrice!.toStringAsFixed(2)} د.إ',
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textMuted,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                    ],
                  ),
                  const Divider(height: 32),

                  // Weight / Quantity Selection for fresh produce
                  if (widget.product.unit == 'kg') ...[
                    const Text(
                      'اختر الوزن المطلوب:',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [0.5, 1.0, 2.0, 3.0].map((weight) {
                        final isSelected = _selectedWeight == weight;
                        return Padding(
                          padding: const EdgeInsetsDirectional.only(end: 8),
                          child: ChoiceChip(
                            label: Text('$weight كجم'),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (val) {
                              setState(() {
                                _selectedWeight = weight;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Description
                  const Text(
                    'تفاصيل ومواصفات المنتج:',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.descriptionAr ?? 'منتج عالي الجودة مختار بعناية فائقة لضمان أفضل تجربة تسوق.',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Hypermarket Quality Guarantees
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.verified_outlined, color: AppColors.freshGreen, size: 20),
                            SizedBox(width: 8),
                            Text('ضمان الطزاجة والجودة بنسبة 100%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.local_shipping_outlined, color: AppColors.primary, size: 20),
                            SizedBox(width: 8),
                            Text('توصيل مبرد سريع ومحافظ على درجات الحرارة', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: AppColors.floatingShadow,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  cart.addToCart(
                    widget.product,
                    quantity: widget.product.unit == 'kg' ? _selectedWeight : 1.0,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تمت إضافة ${widget.product.nameAr} إلى السلة!'),
                      backgroundColor: AppColors.primary,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                icon: const Icon(Icons.add_shopping_cart),
                label: Text(
                  currentQty > 0 ? 'إضافة المزيد إلى السلة' : 'أضف إلى السلة الآن',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
