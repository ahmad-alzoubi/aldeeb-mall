import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class EcoTrackerModal extends StatefulWidget {
  const EcoTrackerModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const EcoTrackerModal(),
    );
  }

  @override
  State<EcoTrackerModal> createState() => _EcoTrackerModalState();
}

class _EcoTrackerModalState extends State<EcoTrackerModal> {
  bool _zeroWasteDeliveryEnabled = true;
  bool _donateCrateDeposit = false;
  final int _returnedCrates = 14;
  final int _activeCrates = 2;
  final double _carbonSavedKg = 31.8;
  final int _plasticBagsAvoided = 168;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.freshGreen.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.eco_rounded, color: AppColors.freshGreen, size: 26),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مبادرة الديب الخضراء للأثر البيئي 🌱',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      Text(
                        'تسوق ذكي، بصمة كربونية صفرية، وتغليف مستدام 100%',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Top Level Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF064E3B), Color(0xFF047857), Color(0xFF059669)],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF047857).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.verified, color: AppColors.accent, size: 16),
                                SizedBox(width: 5),
                                Text(
                                  'المستوى 4: سفير الاستدامة الذهبي',
                                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          const Text(
                            '890 نقطة بيئية',
                            style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'مساهمتك في حماية كوكبنا مع الديب مول',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'بفضل خياراتك المستدامة ومركبات التوصيل الكهربائية، ساهمت في خفض الانبعاثات بنجاح.',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      // Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: 0.89,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('890 / 1000 نقطة', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          Text('باقي 110 نقطة للوصول إلى "بطل الكوكب"', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 4 Grid KPI Cards
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.35,
                  children: [
                    _buildKpiCard(
                      icon: Icons.shopping_bag_outlined,
                      iconColor: AppColors.primary,
                      title: 'أكياس وفرتها',
                      value: '$_plasticBagsAvoided كيس',
                      subtitle: 'تم استبدالها بصناديق ورقية',
                    ),
                    _buildKpiCard(
                      icon: Icons.electric_bolt_rounded,
                      iconColor: Colors.amber.shade800,
                      title: 'وفر CO2 كربوني',
                      value: '$_carbonSavedKg كغم',
                      subtitle: 'عبر أسطول الديب الكهربائي EV',
                    ),
                    _buildKpiCard(
                      icon: Icons.inventory_2_outlined,
                      iconColor: AppColors.freshGreen,
                      title: 'صناديق مسترجعة',
                      value: '$_returnedCrates صندوق',
                      subtitle: 'أعيد استخدامها وتعقيمها',
                    ),
                    _buildKpiCard(
                      icon: Icons.agriculture_rounded,
                      iconColor: Colors.teal.shade700,
                      title: 'منتجات مزارع محلية',
                      value: '68%',
                      subtitle: 'مزارع الخرج والقصيم الطازجة',
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Zero-Waste Delivery Mode Switch
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.freshGreenLight.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.freshGreen.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.freshGreen.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.all_inclusive_rounded, color: AppColors.freshGreen, size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'تفعيل التوصيل بصفر نفايات (Zero-Waste) ♻️',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                                ),
                                Text(
                                  'توصيل في صناديق حرارية معقمة بدون أكياس + 15 نقطة ولاء إضافية',
                                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _zeroWasteDeliveryEnabled,
                            activeThumbColor: AppColors.freshGreen,
                            activeTrackColor: AppColors.freshGreen.withValues(alpha: 0.3),
                            onChanged: (val) {
                              setState(() {
                                _zeroWasteDeliveryEnabled = val;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.handshake_outlined, color: Colors.blueGrey, size: 18),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'التبرع بقيمة تأمين الصناديق المستردة لحملة تشجير الرياض الخضراء',
                              style: TextStyle(fontSize: 11, color: AppColors.textPrimary),
                            ),
                          ),
                          Checkbox(
                            value: _donateCrateDeposit,
                            activeColor: AppColors.freshGreen,
                            onChanged: (val) {
                              setState(() {
                                _donateCrateDeposit = val ?? false;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Reusable Crate Management
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'صناديق الديب الحرارية لديك حالياً',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$_activeCrates صناديق نشطة',
                              style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'قيمة التأمين المحجوزة: ${(_activeCrates * 10).toStringAsFixed(2)} ل.س (تسترد فوراً إلى محفظة الديب عند تسليم الصندوق للمندوب).',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم جدولة استرجاع الصناديق تلقائياً مع أقرب مندوب يزورك أو بطلب منفصل!'),
                                backgroundColor: AppColors.freshGreen,
                              ),
                            );
                          },
                          icon: const Icon(Icons.replay_rounded, color: AppColors.freshGreen, size: 18),
                          label: const Text(
                            'طلب استلام الصناديق واسترداد التأمين بالمحفظة',
                            style: TextStyle(color: AppColors.freshGreen, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.freshGreen),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Local Farms Feature Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.wb_sunny_rounded, color: Colors.amber.shade800, size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'برنامج دعم المنتجات الوطنية 🇸🇦',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'جميع خضار وفواكه ولحوم الديب مول طازجة ويومية من المزارع والمصانع المحلية بدون وسطاء، مما يقلل المسافات والانبعاثات بنسبة 73%.',
                              style: TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 9.5, color: AppColors.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
