import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/responsive.dart';
import '../checkout/checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _couponController = TextEditingController();
  bool _isApplyingCoupon = false;

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final auth = Provider.of<AuthService>(context);
    final items = cart.items.values.toList();
    final userPoints = auth.currentUser?.loyaltyPoints ?? 50;
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('سلة المشتريات'),
        actions: [
          if (items.isNotEmpty)
            TextButton.icon(
              onPressed: () => cart.clearCart(),
              icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white, size: 20),
              label: const Text('إفراغ السلة', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shopping_basket_outlined,
                      size: 72,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'سلة التسوق فارغة حالياً',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'تصفح آلاف العروض والمنتجات الطازجة وأضفها لسلتك',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(200, 48),
                    ),
                    child: const Text('ابدأ التسوق الآن'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: MaxWidthContainer(
                maxWidth: 1200,
                child: isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left / Main: Cart Items List (65%)
                          Expanded(
                            flex: 65,
                            child: Column(
                              children: [
                                _buildFreeDeliveryBanner(cart),
                                const SizedBox(height: 16),
                                _buildCartItemsList(cart, items),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),

                          // Right: Checkout Sidebar (35%)
                          Expanded(
                            flex: 35,
                            child: Column(
                              children: [
                                _buildCouponSection(cart),
                                const SizedBox(height: 16),
                                _buildLoyaltySection(cart, userPoints),
                                const SizedBox(height: 16),
                                _buildInvoiceCard(cart),
                                const SizedBox(height: 16),
                                _buildProceedButton(context, cart),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFreeDeliveryBanner(cart),
                          const SizedBox(height: 16),
                          _buildCartItemsList(cart, items),
                          const SizedBox(height: 20),
                          _buildCouponSection(cart),
                          const SizedBox(height: 16),
                          _buildLoyaltySection(cart, userPoints),
                          const SizedBox(height: 20),
                          _buildInvoiceCard(cart),
                          const SizedBox(height: 100),
                        ],
                      ),
              ),
            ),
      bottomSheet: (items.isEmpty || isDesktop)
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: AppColors.floatingShadow,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: _buildProceedButton(context, cart),
            ),
    );
  }

  Widget _buildFreeDeliveryBanner(CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cart.isFreeDelivery ? AppColors.freshGreenLight : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cart.isFreeDelivery ? AppColors.freshGreen : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                cart.isFreeDelivery ? Icons.check_circle : Icons.local_shipping_outlined,
                color: cart.isFreeDelivery ? AppColors.freshGreen : AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  cart.isFreeDelivery
                      ? 'تهانينا! حصلت على توصيل مجاني لطلبك 🎉'
                      : 'أضف منتجات بقيمة ${cart.remainingForFreeDelivery.toStringAsFixed(2)} د.إ لتحصل على توصيل مجاني!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: cart.isFreeDelivery ? AppColors.freshGreen : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: cart.freeDeliveryProgress,
              minHeight: 6,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                cart.isFreeDelivery ? AppColors.freshGreen : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemsList(CartProvider cart, List items) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, index) => const SizedBox(height: 12),
      itemBuilder: (ctx, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: AppColors.cardShadow,
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: CachedNetworkImage(
                    imageUrl: item.product.firstImage,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.nameAr,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.product.price.toStringAsFixed(2)} د.إ / ${item.product.unitLabelAr}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'الإجمالي: ${item.totalPrice.toStringAsFixed(2)} ر.س',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () => _showSubstitutionSelector(context, item),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.sync_alt_rounded, size: 12, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              'البديل: ${item.substitutionLabelAr}',
                              style: const TextStyle(fontSize: 10, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: AppColors.textMuted),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 16, color: AppColors.textPrimary),
                      onPressed: () => cart.decrementQuantity(item.product),
                      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                      padding: EdgeInsets.zero,
                    ),
                    Text(
                      item.formattedQuantity,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 16, color: AppColors.primary),
                      onPressed: () => cart.addToCart(item.product),
                      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSubstitutionSelector(BuildContext context, dynamic item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.swap_horiz_rounded, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'خيار البديل الذكي لـ "${item.product.nameAr}"',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'ماذا نفعل في حال نفاد هذا الصنف الطازج أثناء تجهيز طلبك في المستودع المظلم؟',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              const SizedBox(height: 14),
              _buildSubOption(
                ctx,
                setSheetState,
                item,
                'best_match',
                'استبدال بأفضل جودة مماثلة (Best Match)',
                'سيختار عامل الفرز أفضل ماركة بديلة بنفس السعر أو أعلى بدون تكلفة إضافية.',
                Icons.verified_rounded,
              ),
              _buildSubOption(
                ctx,
                setSheetState,
                item,
                'contact_me',
                'اتصل بي للاستشارة أولاً (Call Me First)',
                'سيتواصل معك فريق التحضير هاتفياً قبل استبدال المنتج.',
                Icons.phone_in_talk_rounded,
              ),
              _buildSubOption(
                ctx,
                setSheetState,
                item,
                'do_not_replace',
                'عدم الاستبدال واسترداد المبلغ فوراً (Refund Only)',
                'إلغاء الصنف وإعادة قيمته فوراً إلى محفظة الديب الخاصة بك.',
                Icons.cancel_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubOption(
    BuildContext ctx,
    StateSetter setSheetState,
    dynamic item,
    String value,
    String title,
    String desc,
    IconData icon,
  ) {
    final isSelected = item.substitutionPreference == value;
    return InkWell(
      onTap: () {
        setSheetState(() => item.substitutionPreference = value);
        setState(() {});
        Navigator.pop(ctx);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.textMuted, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isSelected ? AppColors.primary : AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(desc, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponSection(CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.confirmation_number_outlined, color: AppColors.secondary, size: 20),
              SizedBox(width: 8),
              Text('كوبون الخصم أو كود العرض', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          if (cart.appliedCoupon == null)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _couponController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      hintText: 'أدخل الكود (مثال: ALDEEB10)',
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isApplyingCoupon
                      ? null
                      : () async {
                          if (_couponController.text.trim().isEmpty) return;
                          setState(() => _isApplyingCoupon = true);
                          final error = await cart.applyCoupon(_couponController.text.trim());
                          setState(() => _isApplyingCoupon = false);
                          if (!context.mounted) return;
                          if (error != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error), backgroundColor: AppColors.error),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تم تطبيق الكوبون بنجاح!'), backgroundColor: AppColors.success),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(minimumSize: const Size(80, 48)),
                  child: _isApplyingCoupon
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('تطبيق'),
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'تم تفعيل: ${cart.appliedCoupon!.code} (-${cart.couponDiscount.toStringAsFixed(2)} د.إ)',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.error, size: 20),
                  onPressed: () => cart.removeCoupon(),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildLoyaltySection(CartProvider cart, int userPoints) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.stars_rounded, color: AppColors.accent, size: 22),
              const SizedBox(width: 8),
              Text(
                'رصيد نقاط الولاء: $userPoints نقطة',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'يمكنك استبدال نقاطك بخصم مالي فوري (100 نقطة = 1.00 د.إ)',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              cart.loyaltyPointsUsed > 0
                  ? 'مفعل: خصم ${cart.loyaltyDiscount.toStringAsFixed(2)} د.إ باستبدال ${cart.loyaltyPointsUsed} نقطة'
                  : 'استبدال نقاط الولاء بهذا الطلب',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            value: cart.loyaltyPointsUsed > 0,
            activeThumbColor: AppColors.accent,
            onChanged: (val) {
              if (val) {
                cart.setLoyaltyPointsUsed(userPoints, userPoints);
              } else {
                cart.setLoyaltyPointsUsed(0, userPoints);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ملخص الفاتورة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          _summaryRow('المجموع الفرعي', '${cart.subtotal.toStringAsFixed(2)} د.إ'),
          const SizedBox(height: 8),
          _summaryRow(
            'رسوم التوصيل',
            cart.isFreeDelivery ? 'مجاناً' : '${cart.deliveryFee.toStringAsFixed(2)} د.إ',
            valueColor: cart.isFreeDelivery ? AppColors.freshGreen : null,
          ),
          if (cart.couponDiscount > 0) ...[
            const SizedBox(height: 8),
            _summaryRow('خصم الكوبون', '-${cart.couponDiscount.toStringAsFixed(2)} د.إ', valueColor: AppColors.secondary),
          ],
          if (cart.loyaltyDiscount > 0) ...[
            const SizedBox(height: 8),
            _summaryRow('خصم نقاط الولاء', '-${cart.loyaltyDiscount.toStringAsFixed(2)} د.إ', valueColor: AppColors.accent),
          ],
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('المبلغ الإجمالي للدفع', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(
                '${cart.totalAmount.toStringAsFixed(2)} د.إ',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProceedButton(BuildContext context, CartProvider cart) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CheckoutScreen()),
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'المتابعة لإتمام الطلب (${cart.totalAmount.toStringAsFixed(2)} د.إ)',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: valueColor ?? AppColors.textPrimary),
        ),
      ],
    );
  }
}
