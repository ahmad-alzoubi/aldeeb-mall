import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/product_model.dart';
import '../../core/services/supabase_service.dart';
import '../../core/utils/responsive.dart';

class SubscriptionItem {
  final String id;
  final ProductModel product;
  String frequency; // 'كل 3 أيام', 'أسبوعياً', 'كل أسبوعين'
  String nextDelivery;
  bool isPaused;

  SubscriptionItem({
    required this.id,
    required this.product,
    required this.frequency,
    required this.nextDelivery,
    this.isPaused = false,
  });
}

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  late List<SubscriptionItem> _subscriptions;

  @override
  void initState() {
    super.initState();
    final p = SupabaseService.defaultProducts;
    _subscriptions = [
      SubscriptionItem(
        id: 'sub-1',
        product: p.length > 3 ? p[3] : p[0], // Almarai Milk
        frequency: 'كل 3 أيام',
        nextDelivery: 'غداً صباحاً (7:00 ص)',
        isPaused: false,
      ),
      SubscriptionItem(
        id: 'sub-2',
        product: p[0], // Cavendish Bananas
        frequency: 'أسبوعياً (كل سبت)',
        nextDelivery: 'السبت القادم',
        isPaused: false,
      ),
      SubscriptionItem(
        id: 'sub-3',
        product: p.length > 2 ? p[2] : p[0], // Vine Tomatoes
        frequency: 'كل أسبوعين',
        nextDelivery: '5 نوفمبر 2026',
        isPaused: true,
      ),
    ];
  }

  void _togglePause(String subId) {
    setState(() {
      final sub = _subscriptions.firstWhere((s) => s.id == subId, orElse: () => _subscriptions.first);
      sub.isPaused = !sub.isPaused;
    });
  }

  void _changeFrequency(String subId, String newFreq) {
    setState(() {
      final sub = _subscriptions.firstWhere((s) => s.id == subId, orElse: () => _subscriptions.first);
      sub.frequency = newFreq;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('اشتراكات المؤن الدورية (Subscribe & Save)'),
      ),
      body: SingleChildScrollView(
        child: MaxWidthContainer(
          maxWidth: 900,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF047857), Color(0xFF10B981)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'وفر 10% دائم مع كل تكرار',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF047857),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'لا داعي للقلق من نفاد الحليب والخبز والخضار من منزلك أبداً!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'تصلك المواد الأساسية مبردة وطازجة في المواعيد التي تختارها مع توصيل مجاني أولوية وإلغاء أو تعديل في أي وقت.',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    if (isDesktop) ...[
                      const SizedBox(width: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.autorenew_rounded, size: 54, color: Colors.white),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Active Subscriptions List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'اشتراكاتك النشطة الحالية:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                  ),
                  Text(
                    '${_subscriptions.where((s) => !s.isPaused).length} اشتراك نشط',
                    style: const TextStyle(fontSize: 12, color: AppColors.freshGreen, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _subscriptions.length,
                itemBuilder: (ctx, index) {
                  final sub = _subscriptions[index];
                  final discountedPrice = sub.product.price * 0.90; // 10% Subscribe & Save discount

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppColors.cardShadow,
                      border: Border.all(
                        color: sub.isPaused ? AppColors.border : AppColors.freshGreen.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: sub.product.firstImage,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          sub.product.nameAr,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: sub.isPaused
                                              ? const Color(0xFFF1F5F9)
                                              : AppColors.freshGreen.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          sub.isPaused ? 'إيقاف مؤقت' : 'نشط ويتكرر',
                                          style: TextStyle(
                                            color: sub.isPaused ? AppColors.textMuted : AppColors.freshGreen,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        '${discountedPrice.toStringAsFixed(2)} د.إ',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 15,
                                          color: AppColors.freshGreen,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${sub.product.price.toStringAsFixed(2)} د.إ',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textMuted,
                                          decoration: TextDecoration.lineThrough,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        '(خصم اشتراك 10%)',
                                        style: TextStyle(color: AppColors.freshGreen, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'التوصيل القادم: ${sub.nextDelivery}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),

                        // Frequency and Actions Bar
                        Row(
                          children: [
                            const Text('التكرار: ', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                            DropdownButton<String>(
                              value: sub.frequency,
                              underline: const SizedBox(),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              items: ['كل 3 أيام', 'أسبوعياً (كل سبت)', 'كل أسبوعين'].map((freq) {
                                return DropdownMenuItem(value: freq, child: Text(freq));
                              }).toList(),
                              onChanged: (newVal) {
                                if (newVal != null) _changeFrequency(sub.id, newVal);
                              },
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () => _togglePause(sub.id),
                              icon: Icon(
                                sub.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                                size: 16,
                                color: sub.isPaused ? AppColors.freshGreen : const Color(0xFFD97706),
                              ),
                              label: Text(
                                sub.isPaused ? 'استئناف' : 'إيقاف مؤقت',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: sub.isPaused ? AppColors.freshGreen : const Color(0xFFD97706),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
