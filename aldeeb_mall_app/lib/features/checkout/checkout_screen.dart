import 'dart:async';
// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/product_model.dart';
import '../../core/models/delivery_coverage_result.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/providers/mall_provider.dart';
import '../../core/providers/order_provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/utils/responsive.dart';
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
  Timer? _reservationTimer;
  int _reservationSecondsRemaining = 15 * 60;

  DeliveryCoverageResult? _coverageResult;
  bool _isCheckingCoverage = false;
  String? _coverageError;

  @override
  void initState() {
    super.initState();
    _startReservationTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verifyDeliveryCoverage();
    });
  }

  Future<void> _verifyDeliveryCoverage() async {
    if (!mounted) return;
    setState(() {
      _isCheckingCoverage = true;
      _coverageError = null;
    });

    try {
      final addr = _addresses[_selectedAddressIndex];
      final slot = _deliverySlots[_selectedSlotIndex]['title'] as String;
      final cart = Provider.of<CartProvider>(context, listen: false);

      final result = await SupabaseService().checkDeliveryCoverage(
        latitude: double.tryParse(addr['lat'] ?? ''),
        longitude: double.tryParse(addr['lon'] ?? ''),
        city: addr['city'],
        district: addr['district'],
        subtotal: cart.subtotal,
        deliverySlot: slot,
      );

      if (mounted) {
        setState(() {
          _coverageResult = result;
          _isCheckingCoverage = false;
        });
        if (result.isCovered) {
          cart.setDeliveryCoverageQuote(result);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _coverageError = 'تعذر فحص التغطية مع الخادم';
          _isCheckingCoverage = false;
        });
      }
    }
  }

  void _startReservationTimer() {
    _reservationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_reservationSecondsRemaining > 0) {
        if (mounted) {
          setState(() => _reservationSecondsRemaining--);
        }
      } else {
        timer.cancel();
      }
    });
  }

  final List<Map<String, String>> _addresses = [
    {
      'title': 'المنزل الرئيسي (دمشق - المزة)',
      'details': 'دمشق، أوتوستراد المزة، جانب حديقة الجلاء، بناء 14',
      'city': 'دمشق',
      'district': 'المزة',
      'lat': '33.5138',
      'lon': '36.2765',
      'phone': '+963 944 123 456',
    },
    {
      'title': 'مكتب العمل (دمشق - أبو رمانة)',
      'details': 'دمشق، شارع الجلاء، بناء المهندسين، الطابق 4',
      'city': 'دمشق',
      'district': 'أبو رمانة',
      'lat': '33.5200',
      'lon': '36.2850',
      'phone': '+963 944 123 456',
    },
    {
      'title': 'بيت العائلة (حلب - الشهباء)',
      'details': 'حلب، حي الشهباء الجديدة، شارع الكندي، فيلا 8',
      'city': 'حلب',
      'district': 'الشهباء',
      'lat': '36.2021',
      'lon': '37.1343',
      'phone': '+963 944 987 654',
    },
    {
      'title': 'منزل درعا (درعا المحطة - مستبعدة)',
      'details': 'درعا المحطة، حي السبيل، جانب المجمع الحكومي',
      'city': 'درعا',
      'district': 'درعا المحطة',
      'lat': '32.6250',
      'lon': '36.1050',
      'phone': '+963 944 111 222',
    },
    {
      'title': 'موقع صحراوي (خارج نطاق التغطية)',
      'details': 'بادية الشام، تدمر السخنة، موقع خارجي',
      'city': 'تدمر',
      'district': 'البادية',
      'lat': '34.5600',
      'lon': '38.2800',
      'phone': '+963 944 000 000',
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
    {
      'title': 'استلام من السيارة (Curbside Pickup 🚗)',
      'subtitle': 'استلام مباشر عند المواقف المخصصة خلال دقيقتين بدون نزول من سيارتك',
      'badge': 'سريع ومجاني',
    },
  ];

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'title': 'محفظة الديب الذكية (Aldeeb Pay)',
      'subtitle': 'رصيد متاح 150.00 ل.س • خصم فوري بنقرة واحدة بدون OTP',
      'icon': Icons.account_balance_wallet_rounded,
      'badge': 'موصى به',
    },
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
    _reservationTimer?.cancel();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final orderProv = Provider.of<OrderProvider>(context);
    final auth = Provider.of<AuthService>(context);
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('إتمام الطلب والتوصيل'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: MaxWidthContainer(
          maxWidth: 1100,
          child: isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main 65%: Form sections
                    Expanded(
                      flex: 65,
                      child: _buildFormSections(),
                    ),
                    const SizedBox(width: 24),
                    // Sidebar 35%: Sticky Order Summary & Submit
                    Expanded(
                      flex: 35,
                      child: Column(
                        children: [
                          _buildDesktopOrderSummary(cart),
                          const SizedBox(height: 16),
                          _buildSubmitButton(cart, orderProv, auth),
                        ],
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormSections(),
                    const SizedBox(height: 20),
                    _buildDesktopOrderSummary(cart),
                    const SizedBox(height: 100),
                  ],
                ),
        ),
      ),
      bottomSheet: isDesktop
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: AppColors.floatingShadow,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: _buildSubmitButton(cart, orderProv, auth),
            ),
    );
  }

  Widget _buildStockReservationBanner() {
    final minutes = (_reservationSecondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_reservationSecondsRemaining % 60).toString().padLeft(2, '0');
    final isLowTime = _reservationSecondsRemaining < 180;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isLowTime ? const Color(0xFFFEF2F2) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isLowTime ? const Color(0xFFFCA5A5) : const Color(0xFFBFDBFE),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isLowTime ? const Color(0xFFEF4444) : AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_clock_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'حجز المخزون مؤقتاً (Stock Reserved)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isLowTime ? const Color(0xFF991B1B) : AppColors.primaryDark,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isLowTime ? const Color(0xFFDC2626) : AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$minutes:$seconds',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'تم حجز الكميات من أقرب مستودع تلقائياً لمنع نفادها أثناء إتمام الطلب.',
                  style: TextStyle(
                    fontSize: 11,
                    color: isLowTime ? const Color(0xFFB91C1C) : const Color(0xFF1E40AF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStockReservationBanner(),
        // 1. Delivery Address Section
        _sectionHeader(Icons.location_on_outlined, 'عنوان التوصيل المعتمد'),
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
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedAddressIndex = val);
                  _verifyDeliveryCoverage();
                }
              },
              title: Text(addr['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text('${addr['details']}\nهاتف: ${addr['phone']}', style: const TextStyle(fontSize: 12)),
            ),
          );
        }),
        if (_isCheckingCoverage) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: const [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
                SizedBox(width: 8),
                Text('جاري التحقق من التغطية وحساب الرسوم من الخادم...', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ] else if (_coverageError != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text('⚠️ $_coverageError', style: const TextStyle(fontSize: 11, color: Colors.deepOrange)),
          ),
        ] else if (_coverageResult != null) ...[
          if (!_coverageResult!.isCovered)
            Container(
              margin: const EdgeInsets.only(top: 4, bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_off_rounded, color: Color(0xFFDC2626), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _coverageResult!.message,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              margin: const EdgeInsets.only(top: 4, bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'العنوان مشمول بالتغطية اللوجستية (${_coverageResult!.zoneNameAr ?? ""})',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _coverageResult!.isFreeDelivery ? 'توصيل مجاني' : '${_coverageResult!.finalDeliveryFee.toStringAsFixed(0)} ل.س',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'الفرع المخدم: ${_coverageResult!.branchNameAr ?? ""} • وقت الوصول التقديري: ${_coverageResult!.estimatedMinutes} دقيقة',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF14532D)),
                  ),
                  if (_coverageResult!.surgeApplied)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '⚡ تم تطبيق رسوم ذروة ${_coverageResult!.surgeFee.toStringAsFixed(0)} ل.س لضمان سرعة التوصيل',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                      ),
                    ),
                ],
              ),
            ),
        ],
        const SizedBox(height: 24),

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
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedSlotIndex = val);
                  _verifyDeliveryCoverage();
                }
              },
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
        const SizedBox(height: 24),

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
        const SizedBox(height: 24),

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
      ],
    );
  }

  Widget _buildDesktopOrderSummary(CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ملخص الطلب النهائي', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 14),
          _summaryRow('المجموع الفرعي', '${cart.subtotal.toStringAsFixed(2)} ل.س'),
          const SizedBox(height: 8),
          _summaryRow(
            'رسوم التوصيل',
            cart.isFreeDelivery ? 'مجاناً' : '${cart.deliveryFee.toStringAsFixed(2)} ل.س',
            valueColor: cart.isFreeDelivery ? AppColors.freshGreen : null,
          ),
          if (cart.couponDiscount > 0) ...[
            const SizedBox(height: 8),
            _summaryRow('خصم الكوبون', '-${cart.couponDiscount.toStringAsFixed(2)} ل.س', valueColor: AppColors.secondary),
          ],
          if (cart.loyaltyDiscount > 0) ...[
            const SizedBox(height: 8),
            _summaryRow('خصم نقاط الولاء', '-${cart.loyaltyDiscount.toStringAsFixed(2)} ل.س', valueColor: AppColors.accent),
          ],
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('المبلغ الإجمالي', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              Text(
                '${cart.totalAmount.toStringAsFixed(2)} ل.س',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(CartProvider cart, OrderProvider orderProv, AuthService auth) {
    return ElevatedButton(
      onPressed: orderProv.isPlacingOrder
          ? null
          : () async {
              if (_reservationSecondsRemaining <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Colors.deepOrange,
                    content: Text('⚠️ انتهت مهلة حجز المخزون المؤقت (15 دقيقة). يرجى مراجعة الأصناف لتأكيد الحجز مجدداً.'),
                  ),
                );
                return;
              }

              // Guardrail 6: Overselling Prevention
              final mall = Provider.of<MallProvider>(context, listen: false);
              for (final item in cart.items.values) {
                ProductModel? product;
                for (final p in mall.products) {
                  if (p.id == item.product.id) {
                    product = p;
                    break;
                  }
                }
                final availableStock = product?.stockQuantity ?? item.product.stockQuantity;
                if (item.quantity > availableStock) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.red.shade700,
                      content: Text('⚠️ نظام منع البيع فوق المخزون: الكمية المطلوبة من "${item.productNameAr}" (${item.formattedQuantity}) تتجاوز المخزون المتاح فعلياً ($availableStock).'),
                    ),
                  );
                  return;
                }
              }

              // Coverage Verification Guard
              if (_coverageResult != null && !_coverageResult!.isCovered) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.red.shade700,
                    behavior: SnackBarBehavior.floating,
                    content: Row(
                      children: [
                        const Icon(Icons.location_off_rounded, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _coverageResult!.message,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
                return;
              }

              final slot = _deliverySlots[_selectedSlotIndex]['title'] as String;
              final payment = _paymentMethods[_selectedPaymentIndex]['title'] as String;
              final idempotencyKey = 'IDEMP-${DateTime.now().millisecondsSinceEpoch}-${cart.items.length}';
              final finalFee = _coverageResult != null ? _coverageResult!.finalDeliveryFee : cart.deliveryFee;
              final effectiveBranchId = _coverageResult?.branchId ?? cart.assignedBranchId;

              final order = await orderProv.placeOrder(
                items: cart.items.values.toList(),
                subtotal: cart.subtotal,
                deliveryFee: finalFee,
                discountAmount: cart.couponDiscount,
                loyaltyPointsUsed: cart.loyaltyPointsUsed,
                loyaltyDiscount: cart.loyaltyDiscount,
                totalAmount: cart.totalAmount,
                deliverySlot: slot,
                paymentMethod: payment,
                notes: _notesController.text.trim(),
                branchId: effectiveBranchId,
                couponCode: cart.appliedCoupon?.code,
                idempotencyKey: idempotencyKey,
                customerName: auth.currentUser?.fullName,
                customerPhone: auth.currentUser?.phone,
              );

              if (!mounted) return;

              if (order != null) {
                if (cart.loyaltyPointsUsed > 0) {
                  auth.deductLoyaltyPoints(cart.loyaltyPointsUsed);
                }
                auth.addLoyaltyPoints(order.totalAmount.toInt());

                cart.clearCart();

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderTrackingScreen(order: order),
                  ),
                );
              } else {
                final err = orderProv.lastOrderError ?? '';
                String errorMsg = '⚠️ تعذر تأكيد الطلب، يرجى التحقق من اتصال الإنترنت ومراجعة البيانات والمحاولة مجدداً.';
                if (err.contains('PRODUCT_NOT_FOUND')) {
                  errorMsg = '⚠️ عذراً، أحد الأصناف المطلوبة غير متاح حالياً في النظام.';
                } else if (err.contains('PRICE_TAMPERED')) {
                  errorMsg = '⚠️ تم تعديل أسعار بعض الأصناف، يرجى تحديث السلة والمتابعة.';
                } else if (err.contains('SUBTOTAL_TAMPERED') || err.contains('TOTAL_TAMPERED')) {
                  errorMsg = '⚠️ خطأ في مطابقة إجمالي الطلب مع الخادم، يرجى إعادة المحاولة.';
                } else if (err.contains('INSUFFICIENT_STOCK')) {
                  errorMsg = '⚠️ عذراً، نفدت الكمية المتاحة في المخزون لأحد الأصناف المطلوبة.';
                } else if (err.contains('INVALID_COUPON') || err.contains('COUPON_EXPIRED')) {
                  errorMsg = '⚠️ كود الخصم غير صالح أو انتهت صلاحيته.';
                } else if (err.contains('COUPON_MIN_ORDER_NOT_MET')) {
                  errorMsg = '⚠️ لم يتم استيفاء الحد الأدنى للطلب لتطبيق كود الخصم.';
                } else if (err.contains('INSUFFICIENT_LOYALTY_POINTS')) {
                  errorMsg = '⚠️ رصيد نقاط الولاء غير كافٍ لتطبيق الخصم المطلوب.';
                } else if (err.contains('INVALID_BRANCH')) {
                  errorMsg = '⚠️ فرع المتجر المختار غير متاح حالياً.';
                } else if (err.contains('DUPLICATE_ORDER')) {
                  errorMsg = '⚠️ تم إرسال هذا الطلب مسبقاً لمنع تكرار الخصم.';
                } else if (err.contains('EMPTY_ITEMS')) {
                  errorMsg = '⚠️ السلة فارغة، يرجى إضافة منتجات أولاً.';
                } else if (err.contains('UNAUTHORIZED_POS')) {
                  errorMsg = '⚠️ طلبات الكاشير ونقاط البيع تتطلب تسجيل دخول موظف معتمد.';
                } else if (err.contains('UNAUTHORIZED')) {
                  errorMsg = '⚠️ غير مصرح: يرجى تسجيل الدخول بحسابك للمتابعة.';
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.red.shade700,
                    behavior: SnackBarBehavior.floating,
                    content: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            errorMsg,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
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
                  'تأكيد وإرسال الطلب (${cart.totalAmount.toStringAsFixed(2)} ل.س)',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
