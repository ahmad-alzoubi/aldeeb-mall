import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';

class AisleInfo {
  final String code; // 'A', 'B', 'C', 'D', 'E', 'F'
  final String nameAr;
  final String categoryAr;
  final List<String> sampleItems;
  final Color themeColor;
  final IconData icon;

  const AisleInfo({
    required this.code,
    required this.nameAr,
    required this.categoryAr,
    required this.sampleItems,
    required this.themeColor,
    required this.icon,
  });
}

class InStoreNavigatorScreen extends StatefulWidget {
  const InStoreNavigatorScreen({super.key});

  @override
  State<InStoreNavigatorScreen> createState() => _InStoreNavigatorScreenState();
}

class _InStoreNavigatorScreenState extends State<InStoreNavigatorScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedAisleCode = 'B';
  String _query = '';

  final List<AisleInfo> _aisles = const [
    AisleInfo(
      code: 'A',
      nameAr: 'المخبوزات والكرواسون الطازج',
      categoryAr: 'مخبز الفرع الآلي',
      sampleItems: ['خبز بروتين', 'كرواسون زبدة', 'معمول تمر', 'توست صحي'],
      themeColor: Colors.amber,
      icon: Icons.bakery_dining_rounded,
    ),
    AisleInfo(
      code: 'B',
      nameAr: 'الألبان والأجبان والزبادي',
      categoryAr: 'سلسلة التبريد الكبرى',
      sampleItems: ['حليب المراعي 2 لتر', 'لبن يوناني ندى', 'جبنة فيتا', 'زبدة لورباك'],
      themeColor: Colors.blue,
      icon: Icons.local_drink_rounded,
    ),
    AisleInfo(
      code: 'C',
      nameAr: 'اللحوم والدواجن الطازجة',
      categoryAr: 'ملحمة الديب الفاخرة',
      sampleItems: ['دجاج اليوم طازج', 'لحم عجل مبرد', 'سمك سلمون نرويجي', 'مفروم بلدي'],
      themeColor: Colors.red,
      icon: Icons.restaurant_rounded,
    ),
    AisleInfo(
      code: 'D',
      nameAr: 'الخضار والفواكه العضوية',
      categoryAr: 'رذاذ الانتعاش الطبيعي',
      sampleItems: ['طماطم عنقودية', 'موز كافنديش', 'أفوكادو هاس', 'تفاح غالا', 'خيار محلي'],
      themeColor: Colors.green,
      icon: Icons.eco_rounded,
    ),
    AisleInfo(
      code: 'E',
      nameAr: 'المجمدات والآيس كريم',
      categoryAr: 'تجميد فائق -20°C',
      sampleItems: ['آيس كريم باسكن', 'خضار مشكلة مجمدة', 'برجر دجاج مجمد', 'فراولة'],
      themeColor: Colors.indigo,
      icon: Icons.ac_unit_rounded,
    ),
    AisleInfo(
      code: 'F',
      nameAr: 'المؤن الأساسية والزيوت والأرز',
      categoryAr: 'قسم الجملة والمؤن',
      sampleItems: ['أرز بسمتي عنبر', 'سكر ناعم', 'زيت زيتون بكر', 'طحين فاخر'],
      themeColor: Colors.orange,
      icon: Icons.inventory_2_rounded,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String q) {
    setState(() {
      _query = q.trim().toLowerCase();
      if (_query.isNotEmpty) {
        for (var a in _aisles) {
          if (a.nameAr.toLowerCase().contains(_query) ||
              a.sampleItems.any((item) => item.toLowerCase().contains(_query))) {
            _selectedAisleCode = a.code;
            break;
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final activeAisle = _aisles.firstWhere(
      (a) => a.code == _selectedAisleCode,
      orElse: () => _aisles.first,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('مرشد الممرات داخل الهايبرماركت (Aisle Navigator)'),
      ),
      body: SingleChildScrollView(
        child: MaxWidthContainer(
          maxWidth: 960,
          child: Padding(
            padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Search Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearch,
                          decoration: const InputDecoration(
                            hintText: 'ابحث عن صنف لمعرفة ممره ورفوفه فوراً (مثال: حليب، أرز، طماطم)...',
                            hintStyle: TextStyle(fontSize: 13, color: AppColors.textMuted),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      if (_query.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _onSearch('');
                          },
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Selected Aisle Walking Guidance Card
                _buildActiveAisleCard(activeAisle),

                const SizedBox(height: 24),

                // Hypermarket 2D Interactive Floorplan
                const Text(
                  'المخطط التفاعلي لممرات فروع الديب مول (انقر على الممر لاستكشافه):',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),

                _buildFloorplanVisualizer(),

                const SizedBox(height: 24),

                // Aisles Grid List
                const Text(
                  'دليل كافة الممرات والأقسام:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),

                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _aisles.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final aisle = _aisles[index];
                    final isSel = aisle.code == _selectedAisleCode;

                    return InkWell(
                      onTap: () => setState(() => _selectedAisleCode = aisle.code),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSel ? AppColors.primary : AppColors.border,
                            width: isSel ? 2 : 1,
                          ),
                          boxShadow: isSel ? AppColors.floatingShadow : null,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: isSel ? AppColors.primary : AppColors.background,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  aisle.code,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    color: isSel ? Colors.white : AppColors.textPrimary,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    aisle.nameAr,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'أبرز الأصناف: ${aisle.sampleItems.join(" • ")}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveAisleCard(AisleInfo aisle) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'الممر ${aisle.code}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      aisle.nameAr,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                    ),
                    Text(
                      aisle.categoryAr,
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  shape: BoxShape.circle,
                ),
                child: Icon(aisle.icon, color: AppColors.primary, size: 24),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),

          // Walking route guide
          Row(
            children: [
              const Icon(Icons.directions_walk_rounded, color: AppColors.freshGreen, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'إرشادات المشي: ادخل من البوابة الرئيسية ثم اتجه يساراً بعد قسم الاستقبال، ستجد الممر باللون المميز.',
                  style: TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFloorplanVisualizer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.storefront_rounded, color: AppColors.accent, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'فرع الديب مول الرئيسي (الرياض - طريق الملك فهد)',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('المخطط اللحظي 🟢', style: TextStyle(color: Colors.white70, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Simulated 2D Aisle Corridors
          LayoutBuilder(
            builder: (ctx, constraints) {
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _aisles.map((aisle) {
                  final isSel = aisle.code == _selectedAisleCode;
                  final width = (constraints.maxWidth - 16) / 3;

                  return InkWell(
                    onTap: () => setState(() => _selectedAisleCode = aisle.code),
                    child: Container(
                      width: width,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                      decoration: BoxDecoration(
                        color: isSel ? AppColors.accent : Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSel ? AppColors.accent : Colors.white.withValues(alpha: 0.15),
                          width: isSel ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'ممر ${aisle.code}',
                            style: TextStyle(
                              color: isSel ? const Color(0xFF0F172A) : Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            aisle.nameAr,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isSel ? const Color(0xFF0F172A) : Colors.white70,
                              fontSize: 10,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
