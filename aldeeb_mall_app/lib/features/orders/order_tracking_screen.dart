import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/order_model.dart';
import '../home/main_navigation_screen.dart';

class OrderTrackingScreen extends StatelessWidget {
  final OrderModel order;

  const OrderTrackingScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Hero Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
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
                      _trackerStep(1, 'تجهيز السلة', Icons.inventory_2_outlined, order.statusStepIndex),
                      _trackerLine(order.statusStepIndex >= 2),
                      _trackerStep(2, 'في الطريق', Icons.two_wheeler_outlined, order.statusStepIndex),
                      _trackerLine(order.statusStepIndex >= 3),
                      _trackerStep(3, 'تم التسليم', Icons.check_circle_outline, order.statusStepIndex),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Driver Card
            if (order.driverName != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
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
                            order.driverName!,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const Text(
                            'مندوب توصيل الديب مول المعتمد',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('الاتصال بالسائق: ${order.driverPhone}')),
                        );
                      },
                      icon: const Icon(Icons.phone, color: AppColors.freshGreen),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.freshGreenLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Delivery & Payment Details Card
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
                  _detailRow(Icons.access_time, 'موعد التوصيل', order.deliverySlot),
                  const SizedBox(height: 10),
                  _detailRow(Icons.payment, 'طريقة الدفع', order.paymentMethod),
                  if (order.notes != null && order.notes!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _detailRow(Icons.note_alt_outlined, 'ملاحظات', order.notes!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Order Items
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
                            child: SizedBox(
                              width: 44,
                              height: 44,
                              child: CachedNetworkImage(
                                imageUrl: item.product.firstImage,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.product.nameAr,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  'الكمية: ${item.formattedQuantity} ${item.product.unitLabelAr}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${item.totalPrice.toStringAsFixed(2)} د.إ',
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
                      const Text('المبلغ الإجمالي المدفوع', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(
                        '${order.totalAmount.toStringAsFixed(2)} د.إ',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Back to Home Button
            ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
                  (route) => false,
                );
              },
              child: const Text('العودة للتسوق في الديب مول'),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _trackerStep(int index, String title, IconData icon, int currentIndex) {
    final isDone = currentIndex >= index;
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isDone ? Colors.white : Colors.white.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: isDone ? AppColors.primary : Colors.white70),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
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
        color: isDone ? Colors.white : Colors.white.withValues(alpha: 0.3),
        margin: const EdgeInsets.only(bottom: 20),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }
}
