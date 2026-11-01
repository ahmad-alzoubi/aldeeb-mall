import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/product_model.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/providers/mall_provider.dart';
import '../../core/providers/store_settings_provider.dart';
import '../../core/utils/responsive.dart';
import '../cart/cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  double _selectedWeight = 1.0;
  int _selectedImageIndex = 0;
  bool _bundleAdded = false;

  @override
  void initState() {
    super.initState();
    _selectedWeight = widget.product.unit == 'kg' ? widget.product.weightStep : 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final mall = Provider.of<MallProvider>(context);
    final storeSettings = Provider.of<StoreSettingsProvider>(context);
    final isFav = mall.isFavorite(widget.product.id);
    final currentQty = cart.getProductQuantity(widget.product.id);
    final isDesktop = Responsive.isDesktop(context);

    // Fallback images if single
    final galleryImages = widget.product.images.isNotEmpty
        ? widget.product.images
        : [widget.product.firstImage];

    // Find complementary bundle products from mall if enabled
    final isBundleAllowed = storeSettings.enableProductBundles && widget.product.bundleEnabled;
    final List<ProductModel> bundleComplementary;
    if (isBundleAllowed) {
      if (widget.product.bundleProductIds.isNotEmpty) {
        bundleComplementary = mall.products
            .where((p) => widget.product.bundleProductIds.contains(p.id) && p.id != widget.product.id)
            .toList();
      } else {
        final sameCategory = mall.products
            .where((p) => p.categoryId == widget.product.categoryId && p.id != widget.product.id)
            .take(2)
            .toList();
        bundleComplementary = sameCategory.isNotEmpty
            ? sameCategory
            : mall.products.where((p) => p.id != widget.product.id).take(2).toList();
      }
    } else {
      bundleComplementary = const [];
    }

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
      body: MaxWidthContainer(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Gallery Section (Main Image + Thumbnail Strip)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Center(
                          child: SizedBox(
                            height: isDesktop ? 360 : 280,
                            child: CachedNetworkImage(
                              imageUrl: galleryImages[_selectedImageIndex % galleryImages.length],
                              fit: BoxFit.contain,
                              placeholder: (ctx, url) =>
                                  const Center(child: CircularProgressIndicator()),
                              errorWidget: (ctx, url, err) =>
                                  const Icon(Icons.image_not_supported, size: 64, color: AppColors.textMuted),
                            ),
                          ),
                        ),
                        if (widget.product.hasDiscount)
                          PositionedDirectional(
                            top: 12,
                            start: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.secondary,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.secondary.withValues(alpha: 0.3),
                                    blurRadius: 6,
                                  ),
                                ],
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
                        // 15-Min Express Badge
                        PositionedDirectional(
                          top: 12,
                          end: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.bolt, size: 16, color: AppColors.textPrimary),
                                SizedBox(width: 4),
                                Text(
                                  '15 دقيقة',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (galleryImages.length > 1) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(galleryImages.length, (idx) {
                          final isSelected = _selectedImageIndex == idx;
                          return InkWell(
                            onTap: () => setState(() => _selectedImageIndex = idx),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : AppColors.border,
                                  width: isSelected ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: CachedNetworkImage(
                                  imageUrl: galleryImages[idx],
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ],
                ),
              ),

              // 2. Main Details Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                  boxShadow: AppColors.cardShadow,
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand & Ratings
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
                            widget.product.brand ?? 'الديب هايبرماركت',
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
                              '(${widget.product.salesCount + 142} تقييم)',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Titles
                    Text(
                      widget.product.nameAr,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1.3,
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

                    // Pricing Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${widget.product.price.toStringAsFixed(2)} ل.س',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'لكل ${widget.product.unitLabelAr}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        if (widget.product.originalPrice != null) ...[
                          Text(
                            '${widget.product.originalPrice!.toStringAsFixed(2)} ل.س',
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.textMuted,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                    const Divider(height: 28),

                    // 15-Minute Noon Minutes Delivery Promise Box
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.accent.withValues(alpha: 0.15),
                            Colors.white,
                          ],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.bolt, color: AppColors.textPrimary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'توصيل فائق السرعة خلال 15 دقيقة (الديب ناو)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'جاهز في المستودع المظلم القريب منك ويصلك مبرداً ومغلفاً بالكامل.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Weight selection for fresh produce
                    if (widget.product.unit == 'kg') ...[
                      const Text(
                        'اختر وزن المنتج:',
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
                      const SizedBox(height: 16),
                    ],

                    // Description
                    const Text(
                      'المواصفات والوصف التفصيلي:',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.product.descriptionAr ??
                          'صنف طازج عالي الجودة مختار بعناية من أفضل المزارع المعتمدة، معقم ومغلف وفق أعلى معايير سلامة الأغذية وسلسلة التبريد لضمان الجودة والطزاجة الدائمة.',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. "Frequently Bought Together" Bundle (Customizable from Admin)
              if (bundleComplementary.isNotEmpty) ...[
                Builder(
                  builder: (context) {
                    final int discount = widget.product.bundleDiscountPercent;
                    final String title = (widget.product.bundleTitle != null && widget.product.bundleTitle!.trim().isNotEmpty)
                        ? widget.product.bundleTitle!
                        : 'اشترِ معاً ووفر $discount% (باقة الديب)';
                    final double originalTotal = widget.product.price +
                        bundleComplementary.fold<double>(0.0, (sum, p) => sum + p.price);
                    final double discountedTotal = originalTotal * (1.0 - (discount / 100.0));
                    final double savings = originalTotal - discountedTotal;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppColors.cardShadow,
                        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    const Icon(Icons.auto_awesome, color: AppColors.accent, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                          color: AppColors.textPrimary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'وفر $discount%',
                                  style: const TextStyle(
                                    color: AppColors.secondary,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildBundleThumb(widget.product.firstImage),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6),
                                child: Text('+', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textMuted)),
                              ),
                              _buildBundleThumb(bundleComplementary[0].firstImage),
                              if (bundleComplementary.length > 1) ...[
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 6),
                                  child: Text('+', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textMuted)),
                                ),
                                _buildBundleThumb(bundleComplementary[1].firstImage),
                              ],
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Price Breakdown & Savings
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '${discountedTotal.toStringAsFixed(2)} ل.س',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${originalTotal.toStringAsFixed(2)} ل.س',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  'وفرت ${savings.toStringAsFixed(2)} ل.س',
                                  style: const TextStyle(
                                    color: AppColors.secondary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton.icon(
                            onPressed: _bundleAdded
                                ? null
                                : () {
                                    cart.addBundleToCart(widget.product, bundleComplementary, discount);
                                    setState(() => _bundleAdded = true);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('✓ تم إضافة الباقة كاملة بخصم $discount% إلى سلتك!'),
                                        backgroundColor: AppColors.primary,
                                      ),
                                    );
                                  },
                            icon: Icon(_bundleAdded ? Icons.check : Icons.add_shopping_cart, size: 18),
                            label: Text(
                              _bundleAdded ? 'تمت إضافة الباقة للسلة' : 'أضف المجموعة كاملة للسلة ووفر $discount%',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryDark,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(42),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],

              // 4. Product Technical Data & Nutrition Table
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'المعلومات الغذائية وبيانات الصنف:',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    _buildSpecRow('الباركود الدولي', widget.product.barcode ?? '6291000849201'),
                    _buildSpecRow('العلامة التجارية', widget.product.brand ?? 'الديب ماركت'),
                    _buildSpecRow('ظروف الحفظ والتخزين', 'حفظ مبرد بدرجة حرارة 2° - 4° مئوية'),
                    _buildSpecRow('الحالة', 'طازج قطاف الصباح'),
                    _buildSpecRow('السعرات الحرارية المقدرة', '89 سعرة حرارية / 100 غرام'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 5. Verified Customer Reviews & Star Breakdown
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'تقييمات وآراء المشترين',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: AppColors.accent, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.product.rating} من 5.0',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildReviewItem(
                      'سالم الكعبي',
                      5,
                      'منتج طازج وممتاز والتوصيل وصلني في 12 دقيقة بالضبط! شكراً الديب مول.',
                      'منذ يومين',
                    ),
                    const Divider(height: 20),
                    _buildReviewItem(
                      'مريم الشامسي',
                      5,
                      'التغليف نظيف ومرتب، وأفضل بكثير من التطبيقات الأخرى، السعر ممتاز.',
                      'منذ أسبوع',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              offset: const Offset(0, -3),
              blurRadius: 12,
            ),
          ],
          border: const Border(
            top: BorderSide(color: AppColors.border, width: 0.8),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Center(
            heightFactor: 1.0,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: Responsive.maxContentWidth),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 32 : 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    _buildBottomPriceSection(),
                    if (isDesktop) const Spacer() else const SizedBox(width: 16),
                    _buildBottomActionButton(context, cart, currentQty, isDesktop),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomPriceSection() {
    final totalPrice = widget.product.price *
        (widget.product.unit == 'kg' ? _selectedWeight : 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'المبلغ الإجمالي',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (widget.product.unit == 'kg') ...[
              const SizedBox(width: 4),
              Text(
                '($_selectedWeight كجم)',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              totalPrice.toStringAsFixed(2),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              'ل.س',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomActionButton(
    BuildContext context,
    CartProvider cart,
    double currentQty,
    bool isDesktop,
  ) {
    if (currentQty > 0) {
      return Expanded(
        child: Row(
          children: [
            SizedBox(
              width: isDesktop ? 140 : 120,
              height: 48,
              child: _buildQuantityStepper(cart, currentQty),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CartScreen()),
                    );
                  },
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: const Text(
                    'إتمام الطلب 🛒',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.freshGreen,
                    foregroundColor: Colors.white,
                    elevation: 1,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final actionWidget = _buildAddToCartButton(context, cart);

    if (isDesktop) {
      return SizedBox(
        width: 280,
        height: 48,
        child: actionWidget,
      );
    }

    return Expanded(
      child: SizedBox(
        height: 48,
        child: actionWidget,
      ),
    );
  }

  Widget _buildAddToCartButton(BuildContext context, CartProvider cart) {
    return ElevatedButton.icon(
      onPressed: () {
        final qtyToAdd = widget.product.unit == 'kg' ? _selectedWeight : 1.0;
        cart.addToCart(widget.product, quantity: qtyToAdd);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'تمت إضافة ${widget.product.nameAr} إلى السلة!',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            action: SnackBarAction(
              label: 'إتمام الطلب 🛒',
              textColor: AppColors.accent,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                );
              },
            ),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      },
      icon: const Icon(Icons.add_shopping_cart_rounded, size: 20),
      label: const Text(
        'أضف إلى السلة',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 1,
        shadowColor: AppColors.primary.withValues(alpha: 0.3),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildQuantityStepper(CartProvider cart, double currentQty) {
    final step = widget.product.unit == 'kg' ? _selectedWeight : 1.0;
    final isRemove = currentQty <= (widget.product.unit == 'kg' ? widget.product.weightStep : 1.0);
    final displayQty = widget.product.unit == 'kg'
        ? (currentQty % 1 == 0 ? '${currentQty.toInt()}' : currentQty.toStringAsFixed(1))
        : '${currentQty.toInt()}';
    final unitLabel = widget.product.unit == 'kg' ? ' كجم' : '';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25), width: 1.2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Decrement / Remove button
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                cart.decrementQuantity(widget.product);
              },
              child: Container(
                width: 42,
                height: 42,
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Icon(
                  isRemove ? Icons.delete_outline_rounded : Icons.remove_rounded,
                  color: isRemove ? AppColors.error : AppColors.primary,
                  size: 20,
                ),
              ),
            ),
          ),

          // Quantity text in cart
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$displayQty$unitLabel',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
                const Text(
                  'في السلة',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMuted,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),

          // Increment button
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                cart.addToCart(widget.product, quantity: step);
              },
              child: Container(
                width: 42,
                height: 42,
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBundleThumb(String url) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          errorWidget: (ctx, u, e) => const Icon(Icons.shopping_bag, size: 24, color: AppColors.textMuted),
        ),
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildReviewItem(String author, int rating, String comment, String time) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(author, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.freshGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified, size: 12, color: AppColors.freshGreen),
                      SizedBox(width: 2),
                      Text('مشتري معتمد', style: TextStyle(color: AppColors.freshGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            Text(time, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: List.generate(
            5,
            (idx) => Icon(
              idx < rating ? Icons.star_rounded : Icons.star_border_rounded,
              color: AppColors.accent,
              size: 16,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          comment,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
        ),
      ],
    );
  }
}
