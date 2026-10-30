import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/providers/order_provider.dart';
import '../../core/services/auth_service.dart';
import '../orders/order_tracking_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int _selectedAddressIndex = 0;
  int _selectedSlotIndex = 0;
  int _selectedPaymentIndex = 0;
  final TextEditingController _notesController = TextEditingController();

  final List<Map<String, String>> _addresses = [
    {
      'title': 'المنزل الرئيسي',
      'details': 'دبي، وسط المدينة، برج فيوز برج B، شقة 1402',
      'phone': '+971 50 123 4567',
    },
    {
      'title': 'مكتب العمل',
      'details': 'دبي، خليج الأعمال، برج أوبال، الطابق 8',
      'phone': '+971 50 123 4567',
    },
  ];

  final List<Map<String, dynamic>> _deliverySlots = [
    {
      'title': 'توصيل إكسبريس فوري ⚡',
      'subtitle': 'خلال 60 دقيقة إلى بابك مباشرة',
      'badge': 'أسرع خيار',
    },
    {
      'title': 'اليوم (الفترة المسائية)',
      'subtitle': 'من الساعة 4:00 عصراً إلى 7:00 مساءً',
      'badge': 'مجدول',
    },
    {
      'title': 'غداً (الفترة الصباحية)',
      'subtitle': 'من الساعة 9:00 صباحاً إلى 12:00 ظهراً',
      'badge': 'مجدول',
    },
    {
      'title': 'استلام من فرع المول (Click & Collect)',
      'subtitle': 'فرع الديب مول الرئيسي - جاهز بعد 30 دقيقة',
      'badge': 'بدون رسوم',
    },
  ];

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'title': 'الدفع نقداً عند الاستلام (COD)',
      'subtitle': 'ادفع لمندوب التوصيل عند استلام طلبك',
      'icon': Icons.payments_outlined,
    },
    {
      'title': 'الدفع بالبطاقة عند الاستلام',
      'subtitle': 'جهاز نقاط البيع المحمول مع السائق',
      'icon': Icons.credit_card_outlined,
    },
    {
      'title': 'البطاقة البنكية / Apple Pay',
      'subtitle': 'دفع إلكتروني فوري وآمن 100%',
      'icon': Icons.account_balance_wallet_outlined,
    },
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final orderProv = Provider.of<OrderProvider>(context);
    final auth = Provider.of<AuthService>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('إتمام الطلب والتوصيل'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Delivery Address Section
            _sectionHeader(Icons.location_on_outlined, 'عنوان التوصيل'),
            const SizedBox(height: 12),
            ...List.generate(_addresses.length, (index) {
              final addr = _addresses[index];
              final isSelected = _selectedAddressIndex == index;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: RadioListTile<int>(
                  value: index,
                  groupValue: _selectedAddressIndex,
                  activeColor: AppColors.primary,
                  onChanged: (val) => setState(() => _selectedAddressIndex = val!),
                  title: Text(addr['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text('${addr['details']}\nهاتف: ${addr['phone']}', style: const TextStyle(fontSize: 12)),
                ),
              );
            }),
            const SizedBox(height: 20),

            // 2. Delivery Slot Section
            _sectionHeader(Icons.access_time_rounded, 'موعد وخانة التوصيل'),
            const SizedBox(height: 12),
            ...List.generate(_deliverySlots.length, (index) {
              final slot = _deliverySlots[index];
              final isSelected = _selectedSlotIndex == index;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: RadioListTile<int>(
                  value: index,
                  groupValue: _selectedSlotIndex,
                  activeColor: AppColors.primary,
                  onChanged: (val) => setState(() => _selectedSlotIndex = val!),
                  title: Row(
                    children: [
                      Text(slot['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: index == 0 ? AppColors.secondaryLight : AppColors.background,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          slot['badge'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: index == 0 ? AppColors.secondary : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(slot['subtitle'] as String, style: const TextStyle(fontSize: 12)),
                ),
              );
            }),
            const SizedBox(height: 20),

            // 3. Payment Method Section
            _sectionHeader(Icons.payment_outlined, 'طريقة الدفع'),
            const SizedBox(height: 12),
            ...List.generate(_paymentMethods.length, (index) {
              final pay = _paymentMethods[index];
              final isSelected = _selectedPaymentIndex == index;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: RadioListTile<int>(
                  value: index,
                  groupValue: _selectedPaymentIndex,
                  activeColor: AppColors.primary,
                  onChanged: (val) => setState(() => _selectedPaymentIndex = val!),
                  secondary: Icon(pay['icon'] as IconData, color: isSelected ? AppColors.primary : AppColors.textMuted),
                  title: Text(pay['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text(pay['subtitle'] as String, style: const TextStyle(fontSize: 12)),
                ),
              );
            }),
            const SizedBox(height: 20),

            // 4. Notes for Driver
            _sectionHeader(Icons.note_alt_outlined, 'ملاحظات وتوجيهات للمندوب'),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'مثال: يرجى الاتصال عند الوصول، أو ترك الطلب أمام الباب',
              ),
            ),
            const SizedBox(height: 24),

            // 5. Total Price Reminder
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('المبلغ الإجمالي النهائي', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text('شامل الضريبة والتوصيل', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Text(
                    '${cart.totalAmount.toStringAsFixed(2)} د.إ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
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
        child: ElevatedButton(
          onPressed: orderProv.isPlacingOrder
              ? null
              : () async {
                  final slot = _deliverySlots[_selectedSlotIndex]['title'] as String;
                  final payment = _paymentMethods[_selectedPaymentIndex]['title'] as String;

                  final order = await orderProv.placeOrder(
                    items: cart.items.values.toList(),
                    subtotal: cart.subtotal,
                    deliveryFee: cart.deliveryFee,
                    discountAmount: cart.couponDiscount,
                    loyaltyPointsUsed: cart.loyaltyPointsUsed,
                    loyaltyDiscount: cart.loyaltyDiscount,
                    totalAmount: cart.totalAmount,
                    deliverySlot: slot,
                    paymentMethod: payment,
                    notes: _notesController.text.trim(),
                  );

                  if (!context.mounted) return;

                  if (order != null) {
                    // Update user loyalty points in auth service
                    if (cart.loyaltyPointsUsed > 0) {
                      auth.deductLoyaltyPoints(cart.loyaltyPointsUsed);
                    }
                    // Reward points for order
                    auth.addLoyaltyPoints(order.totalAmount.toInt());

                    cart.clearCart();

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrderTrackingScreen(order: order),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('حدث خطأ أثناء تأكيد الطلب، يرجى المحاولة ثانية'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
          child: orderProv.isPlacingOrder
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'تأكيد وإرسال الطلب (${cart.totalAmount.toStringAsFixed(2)} د.إ)',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
