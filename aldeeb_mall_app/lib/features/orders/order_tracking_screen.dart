import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/order_model.dart';
import '../../core/utils/responsive.dart';
import '../home/main_navigation_screen.dart';

class OrderTrackingScreen extends StatefulWidget {
  final OrderModel order;

  const OrderTrackingScreen({super.key, required this.order});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  late Duration _remainingEta;
  Timer? _etaTimer;

  @override
  void initState() {
    super.initState();
    _remainingEta = const Duration(minutes: 11, seconds: 45);
    _etaTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _remainingEta.inSeconds > 0) {
        setState(() {
          _remainingEta = _remainingEta - const Duration(seconds: 1);
        });
      }
    });
  }

  @override
  void dispose() {
    _etaTimer?.cancel();
    super.dispose();
  }

  String _formatEta(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s دقيقة';
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('تتبع الطلب #${order.orderNumber}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
              (route) => false,
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: MaxWidthContainer(
          maxWidth: 800,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Status Hero Card with Step Tracker
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primary],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('رقم الطلب', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            Text(
                              '#${order.orderNumber}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            order.statusTitleAr,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Horizontal Step Tracker
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _trackerStep(0, 'استلام الطلب', Icons.receipt_long, order.statusStepIndex),
                        _trackerLine(order.statusStepIndex >= 1),
                        _trackerStep(1, 'المستودع المظلم', Icons.inventory_2_outlined, order.statusStepIndex),
                        _trackerLine(order.statusStepIndex >= 2),
                        _trackerStep(2, 'مع المندوب', Icons.two_wheeler_outlined, order.statusStepIndex),
                        _trackerLine(order.statusStepIndex >= 3),
                        _trackerStep(3, 'تم التسليم', Icons.check_circle_outline, order.statusStepIndex),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Live Radar & Simulated Courier Route Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppColors.cardShadow,
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.radar, color: AppColors.primary, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'الرادار والتتبع اللحظي للمندوب',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.accent),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.timer_outlined, size: 14, color: AppColors.textPrimary),
                              const SizedBox(width: 4),
                              Text(
                                'الوصول المتوقع: ${_formatEta(_remainingEta)}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Visual Graphic Route Map
                    Container(
                      height: 140,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Stack(
                        children: [
                          // Background Grid Lines
                          Positioned.fill(
                            child: Opacity(
                              opacity: 0.15,
                              child: Image.network(
                                'https://images.unsplash.com/photo-1524661135-423995f22d0b?auto=format&fit=crop&w=800&q=80',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          // Hub Pin
                          const PositionedDirectional(
                            top: 45,
                            start: 24,
                            child: Column(
                              children: [
                                Icon(Icons.store, color: AppColors.primaryDark, size: 28),
                                SizedBox(height: 4),
                                Text('المستودع المظلم', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          // Moving Courier Marker (Animated Pulse)
                          PositionedDirectional(
                            top: 40,
                            start: 140,
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.4),
                                        blurRadius: 10,
                                        spreadRadius: 3,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.two_wheeler, color: Colors.white, size: 20),
                                ),
                                const SizedBox(height: 4),
                                const Text('المندوب بالطريق', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                              ],
                            ),
                          ),
                          // Customer Destination Pin
                          const PositionedDirectional(
                            top: 45,
                            end: 24,
                            child: Column(
                              children: [
                                Icon(Icons.home, color: AppColors.secondary, size: 28),
                                SizedBox(height: 4),
                                Text('عنوانك (المنزل)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Driver & Handover Verification Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.driverName ?? 'محمد أحمد الديب',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const Text(
                                'كابتن توصيل سريع معتمد (دراجة كهربائية سريعة DXB-4821)',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('جاري الاتصال بالكابتن: ${order.driverPhone ?? "+971501234567"}')),
                            );
                          },
                          icon: const Icon(Icons.phone, color: AppColors.freshGreen),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.freshGreenLight,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    // Handover PIN for Zero-Contact / Delivery Assurance
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('رمز التحقق وتسليم الشحنة (PIN)', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            Text('شارك هذا الرمز مع المندوب عند الوصول', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            order.orderNumber.replaceAll(RegExp(r'[^0-9]'), '').padRight(4, '8').substring(0, 4),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 4, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4. Delivery & Payment Details Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('تفاصيل التوصيل والدفع', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 12),
                    _detailRow(Icons.access_time, 'موعد التوصيل المختار', order.deliverySlot),
                    const SizedBox(height: 10),
                    _detailRow(Icons.payment, 'طريقة الدفع', order.paymentMethod),
                    if (order.notes != null && order.notes!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _detailRow(Icons.note_alt_outlined, 'تعليمات للباب', order.notes!),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 5. Order Items Checklist
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('المنتجات المطلوبة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('${order.items.length} أصناف', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      ],
                    ),
                    const Divider(height: 20),
                    ...order.items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: item.productImage,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productNameAr,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${item.quantity} ${item.unit} × ${item.unitPrice.toStringAsFixed(2)} ل.س',
                                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${item.totalPrice.toStringAsFixed(2)} ل.س',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      );
                    }),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('المبلغ الإجمالي المدفوع:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(
                          '${order.totalAmount.toStringAsFixed(2)} ل.س',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _trackerStep(int index, String title, IconData icon, int currentStep) {
    final isDone = currentStep >= index;
    final isCurrent = currentStep == index;

    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isDone ? Colors.white : Colors.white24,
            shape: BoxShape.circle,
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            size: 20,
            color: isDone ? AppColors.primary : Colors.white70,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: TextStyle(
            color: isDone ? Colors.white : Colors.white60,
            fontSize: 10,
            fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _trackerLine(bool isDone) {
    return Expanded(
      child: Container(
        height: 2,
        color: isDone ? Colors.white : Colors.white24,
        margin: const EdgeInsets.only(bottom: 20),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
