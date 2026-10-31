import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/product_model.dart';
import '../../core/providers/cart_provider.dart';

class PharmacyScreen extends StatefulWidget {
  const PharmacyScreen({super.key});

  @override
  State<PharmacyScreen> createState() => _PharmacyScreenState();
}

class _PharmacyScreenState extends State<PharmacyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // --- Drug Interaction State ---
  final List<String> _availableDrugs = [
    'بانادول (Paracetamol)',
    'بروفين (Ibuprofen)',
    'وارفارين مسيل دم (Warfarin)',
    'أسبرين (Aspirin)',
    'ليبيتور كوليسترول (Atorvastatin)',
    'جلوكوفاج سكر (Metformin)',
    'عصير الجريب فروت (Grapefruit)',
    'كونكور ضغط (Bisoprolol)',
    'أوجمنتين مضاد (Augmentin)',
    'أوميبرازول للمعدة (Omeprazole)',
  ];
  final Set<String> _selectedDrugs = {'وارفارين مسيل دم (Warfarin)', 'بروفين (Ibuprofen)'};

  // --- Wasfaty Prescription State ---
  final _wasfatyCodeController = TextEditingController(text: 'WASF-9482-KSA');
  final _nationalIdController = TextEditingController(text: '1098234821');
  String _selectedInsurance = 'بوبا العربية (Bupa Arabia)';
  bool _requiresColdChain = true;
  bool _isSubmittingWasfaty = false;
  bool _wasfatySubmitted = false;

  // --- Chronic Refill Subscriptions ---
  final List<Map<String, dynamic>> _chronicMeds = [
    {
      'id': 'cr-1',
      'name': 'ليبيتور 20 ملجم (Lipitor Atorvastatin)',
      'dosage': 'قرص واحد يومياً قبل النوم',
      'daysRemaining': 5,
      'totalDays': 30,
      'autoRefill': true,
      'price': 64.50,
      'doctor': 'د. عبدالله القحطاني (استشاري باطنة)',
    },
    {
      'id': 'cr-2',
      'name': 'جلوكوفاج 500 ملجم (Glucophage Metformin)',
      'dosage': 'قرصان يومياً مع الوجبات الرئيسية',
      'daysRemaining': 18,
      'totalDays': 30,
      'autoRefill': true,
      'price': 22.00,
      'doctor': 'د. نورة السبيعي (استشاري غدد صماء)',
    },
    {
      'id': 'cr-3',
      'name': 'كونكور 5 ملجم (Concor Bisoprolol)',
      'dosage': 'قرص صباحاً لضبط ضغط الدم',
      'daysRemaining': 2,
      'totalDays': 30,
      'autoRefill': false,
      'price': 38.75,
      'doctor': 'د. عبدالله القحطاني (استشاري باطنة)',
    },
  ];

  // --- OTC & Healthcare Essentials ---
  final List<ProductModel> _otcProducts = [
    const ProductModel(
      id: 'otc-1',
      nameAr: 'بانادول إكسترا لتسكين الألم السريع 24 قرص',
      nameEn: 'Panadol Extra Rapid Pain Relief 24 Tablets',
      price: 15.50,
      originalPrice: 18.00,
      images: ['https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=500'],
      descriptionAr: 'مسكن آمن ومثالي للصداع وآلام الجسم مع باراسيتامول وكافيين.',
      unit: 'pack',
      discountPercent: 14,
    ),
    const ProductModel(
      id: 'otc-2',
      nameAr: 'جهاز قياس ضغط الدم الذكي بالبلوتوث أومرون M3',
      nameEn: 'Omron M3 Smart Digital Blood Pressure Monitor',
      price: 189.00,
      originalPrice: 245.00,
      images: ['https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=500'],
      descriptionAr: 'معتمد طبياً من هيئة الغذاء والدواء SFDA بدقة فائقة وذاكرة مزدوجة.',
      unit: 'piece',
      discountPercent: 23,
    ),
    const ProductModel(
      id: 'otc-3',
      nameAr: 'فيتامين د3 جرعة 50,000 وحدة دولية 12 كبسولة',
      nameEn: 'Vitamin D3 50,000 IU High Potency 12 Caps',
      price: 45.00,
      originalPrice: 55.00,
      images: ['https://images.unsplash.com/photo-1577401239170-897942555fb3?w=500'],
      descriptionAr: 'كبسولة أسبوعية لتعويض النقص وتقوية المناعة وصحة العظام.',
      unit: 'pack',
      discountPercent: 18,
    ),
    const ProductModel(
      id: 'otc-4',
      nameAr: 'بخاخ ماء البحر فيزيومير لتنظيف وفتح الأنف 135 مل',
      nameEn: 'Physiomer 100% Sea Water Nasal Spray 135ml',
      price: 38.00,
      originalPrice: 42.00,
      images: ['https://images.unsplash.com/photo-1587854692152-cbe660dbde88?w=500'],
      descriptionAr: 'طبيعي 100% وغني بالمعادن لتخفيف الاحتقان بدون كيماويات.',
      unit: 'bottle',
      discountPercent: 10,
    ),
    const ProductModel(
      id: 'otc-5',
      nameAr: 'ستريبسلز استحلاب لالتهاب الحلق بالعسل والليمون 24 حبة',
      nameEn: 'Strepsils Honey & Lemon Sore Throat Lozenges',
      price: 19.50,
      originalPrice: 22.00,
      images: ['https://images.unsplash.com/photo-1584017911766-d451b3d0e843?w=500'],
      descriptionAr: 'تأثير ثنائي مضاد للبكتيريا ومسكن فوري لاحتقان الحلق.',
      unit: 'pack',
      discountPercent: 11,
    ),
    const ProductModel(
      id: 'otc-6',
      nameAr: 'شرائط قياس سكر الدم كونتور بلس 50 شريط',
      nameEn: 'Contour Plus Blood Glucose Test Strips 50 pcs',
      price: 72.00,
      originalPrice: 85.00,
      images: ['https://images.unsplash.com/photo-1631549916768-4119b2e5f926?w=500'],
      descriptionAr: 'قراءة فورية عالية الدقة بدون ترميز ومعايرة ذاتية.',
      unit: 'pack',
      discountPercent: 15,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _wasfatyCodeController.dispose();
    _nationalIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF065F46), // Deep Emerald SFDA Medical Green
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.local_pharmacy_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'صيدلية الديب المرخصة',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'ترخيص هيئة الغذاء والدواء SFDA #48291 • صيادلة سعوديون 24/7',
                  style: TextStyle(fontSize: 10, color: Color(0xFFA7F3D0)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'استشارة صيدلي مناوب',
            icon: const Icon(Icons.support_agent_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('جارٍ تحويلك لمحادثة الصيدلي السريري المناوب (د. سارة الشهري)...'),
                  backgroundColor: Color(0xFF065F46),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF34D399),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.health_and_safety_outlined, size: 18), text: 'فاحص التداخلات SFDA'),
            Tab(icon: Icon(Icons.assignment_outlined, size: 18), text: 'صرف وصفتي الإلكترونية'),
            Tab(icon: Icon(Icons.autorenew_rounded, size: 18), text: 'أدوية الأمراض المزمنة'),
            Tab(icon: Icon(Icons.medication_outlined, size: 18), text: 'العناية والأدوية السريعة'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDrugInteractionChecker(),
          _buildWasfatyDispensing(),
          _buildChronicRefills(),
          _buildOtcCatalog(),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1: SFDA DRUG-DRUG & FOOD INTERACTION CHECKER
  // ===========================================================================
  Widget _buildDrugInteractionChecker() {
    // Determine interaction risk between selected drugs
    final hasWarfarin = _selectedDrugs.any((d) => d.contains('وارفارين'));
    final hasIbuprofen = _selectedDrugs.any((d) => d.contains('بروفين'));
    final hasAspirin = _selectedDrugs.any((d) => d.contains('أسبرين'));
    final hasGrapefruit = _selectedDrugs.any((d) => d.contains('جريب فروت'));
    final hasLipitor = _selectedDrugs.any((d) => d.contains('ليبيتور'));

    final bool isSevere = (hasWarfarin && hasIbuprofen) || (hasWarfarin && hasAspirin);
    final bool isModerate = hasGrapefruit && hasLipitor;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Notice
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user_rounded, color: Color(0xFF065F46), size: 36),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'فاحص التداخلات الدوائية والغذائية الذكي',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF065F46)),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'محرك ذكاء سريري متصل بقاعدة بيانات هيئة الغذاء والدواء السعودية SFDA لتحذيرك من التداخلات الخطيرة بين الأدوية والأطعمة.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF047857), height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Drug Selection Section
          const Text(
            'اختر أو أضف أدويتك الحالية للفحص الفوري:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableDrugs.map((drug) {
              final isSelected = _selectedDrugs.contains(drug);
              return FilterChip(
                label: Text(drug),
                selected: isSelected,
                selectedColor: const Color(0xFFD1FAE5),
                checkmarkColor: const Color(0xFF065F46),
                labelStyle: TextStyle(
                  color: isSelected ? const Color(0xFF065F46) : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isSelected ? const Color(0xFF059669) : Colors.grey.shade300,
                  ),
                ),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedDrugs.add(drug);
                    } else {
                      if (_selectedDrugs.length > 1) {
                        _selectedDrugs.remove(drug);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('يجب إبقاء دواء واحد على الأقل للمقارنة')),
                        );
                      }
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Live Risk Analysis Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: isSevere
                    ? Colors.red.shade300
                    : isModerate
                        ? Colors.amber.shade300
                        : const Color(0xFFA7F3D0),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSevere
                            ? Colors.red.shade100
                            : isModerate
                                ? Colors.amber.shade100
                                : const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSevere
                                ? Icons.dangerous_rounded
                                : isModerate
                                    ? Icons.warning_amber_rounded
                                    : Icons.check_circle_rounded,
                            size: 16,
                            color: isSevere
                                ? Colors.red.shade800
                                : isModerate
                                    ? Colors.amber.shade900
                                    : const Color(0xFF065F46),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isSevere
                                ? 'تحذير حرج: خطر شديد 🔴'
                                : isModerate
                                    ? 'تنبيه معتدل: تداخل ملحوظ 🟡'
                                    : 'توافق سريري ممتاز: آمن 🟢',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSevere
                                  ? Colors.red.shade800
                                  : isModerate
                                      ? Colors.amber.shade900
                                      : const Color(0xFF065F46),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'بروتوكول SFDA-RADAR',
                      style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                if (isSevere) ...[
                  const Text(
                    'تداخل عالي الخطورة: وارفارين + مسكنات NSAIDs (بروفين أو أسبرين)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '⚠️ تناول الإيبوبروفين أو الأسبرين مع مضادات التجلط (وارفارين) يزيد من خطر حدوث نزيف حاد في المعدة بنسبة 400%، بسبب تآزر التأثير على سيولة الدم وتثبيط الصفائح.',
                    style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Icon(Icons.medical_services_rounded, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'توصية الصيدلي الإكلينيكي: استبدل البروفين بالباراسيتامول (بانادول العادي بجرعة لا تتجاوز 2000 ملجم يومياً)، واستشر طبيبك المعالج قبل أخذ أي مسكن إضافي.',
                            style: TextStyle(fontSize: 12, color: Color(0xFF991B1B), fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (isModerate) ...[
                  const Text(
                    'تداخل غذائي-دوائي: جريب فروت + ليبيتور (Atorvastatin)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFB45309)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '⚠️ يحتوي الجريب فروت على مركبات الفورانوكومارين التي تثبط إنزيم CYP3A4 في الكبد، مما يؤدي إلى تراكم دواء الكوليسترول في الدم وزيادة احتمالية تلف العضلات.',
                    style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'توصية الصيدلي: امتنع تماماً عن تناول عصير الجريب فروت أثناء فترة علاج الستاتينات.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF92400E), fontWeight: FontWeight.w600),
                    ),
                  ),
                ] else ...[
                  const Text(
                    'لم يتم رصد أي تعارض دوائي خطير بين الأدوية المختارة',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF065F46)),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '✅ الأدوية المحددة متوافقة بشكل آمن ضمن الجرعات الطبية الموصوفة من الطبيب. احرص دائماً على الالتزام بمواعيد الجرعات وفصل أدوية المعدة بساعة عن الأدوية الأخرى.',
                    style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Request Pharmacist Review Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF065F46),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              label: const Text(
                'استشارة الصيدلي السريري حول هذه الأدوية مجاناً',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم إرسال قائمة الأدوية للصيدلي المناوب. سيتواصل معك خلال دقيقتين عبر المحادثة.'),
                    backgroundColor: Color(0xFF065F46),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 2: WASFATY & E-PRESCRIPTION DISPENSING
  // ===========================================================================
  Widget _buildWasfatyDispensing() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wasfaty Branding Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF0284C7), size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'صرف وصفات (وصفتي) والتأمين الصحي',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0369A1)),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'أدخل رقم الوصفة الإلكترونية الصادرة من المركز الصحي أو المستشفى وسيتم تجهيزها وتوصيلها مبردة إلى باب منزلك.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Wasfaty Input Form
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'بيانات الوصفة الطبية:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),

                // Wasfaty Code Field
                TextField(
                  controller: _wasfatyCodeController,
                  decoration: InputDecoration(
                    labelText: 'رقم وصفة وصفتي الإلكترونية (E-Rx Code)',
                    prefixIcon: const Icon(Icons.receipt_long_rounded, color: Color(0xFF065F46)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 12),

                // National ID / Iqama
                TextField(
                  controller: _nationalIdController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'رقم الهوية الوطنية أو الإقامة للمريض',
                    prefixIcon: const Icon(Icons.badge_rounded, color: Color(0xFF065F46)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 12),

                // Insurance Company Selector
                DropdownButtonFormField<String>(
                  initialValue: _selectedInsurance,
                  decoration: InputDecoration(
                    labelText: 'جهة التأمين الصحي أو برنامج وصفتي',
                    prefixIcon: const Icon(Icons.shield_outlined, color: Color(0xFF065F46)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'برنامج وصفتي الحكومي (وزارة الصحة)', child: Text('برنامج وصفتي الحكومي (وزارة الصحة)')),
                    DropdownMenuItem(value: 'بوبا العربية (Bupa Arabia)', child: Text('بوبا العربية (Bupa Arabia)')),
                    DropdownMenuItem(value: 'التعاونية للتأمين (Tawuniya)', child: Text('التعاونية للتأمين (Tawuniya)')),
                    DropdownMenuItem(value: 'ميدغلف (Medgulf)', child: Text('ميدغلف (Medgulf)')),
                    DropdownMenuItem(value: 'دفع نقدي مباشر (بدون تأمين)', child: Text('دفع نقدي مباشر (بدون تأمين)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedInsurance = val);
                  },
                ),
                const SizedBox(height: 14),

                // Cold Chain Indicator Switch
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _requiresColdChain,
                  activeTrackColor: const Color(0xFF065F46).withValues(alpha: 0.5),
                  activeThumbColor: const Color(0xFF065F46),
                  title: const Text(
                    'توصيل مبرد طبي حساس (2°C - 8°C)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  subtitle: const Text(
                    'للإنسولين واللقاحات والمضادات الحيوية الخاصة لضمان سلامة الدواء.',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  onChanged: (val) => setState(() => _requiresColdChain = val),
                ),
                const SizedBox(height: 14),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF065F46),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isSubmittingWasfaty
                        ? null
                        : () async {
                            setState(() => _isSubmittingWasfaty = true);
                            await Future.delayed(const Duration(milliseconds: 1200));
                            setState(() {
                              _isSubmittingWasfaty = false;
                              _wasfatySubmitted = true;
                            });
                          },
                    child: _isSubmittingWasfaty
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'التحقق من الوصفة وبدء الصرف المعتمد',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Prescription Live Status Stepper
          if (_wasfatySubmitted) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFA7F3D0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
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
                      const Text(
                        'حالة صرف الوصفة الطبية:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF065F46)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'تغطية تأمينية 100% (0.00 ر.س)',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Dispensing Steps
                  _buildDispenseStep(
                    step: 1,
                    title: 'التحقق من نظام وصفتي وربط التأمين',
                    desc: 'تم التحقق بنجاح مع وزارة الصحة وشركة التأمين.',
                    isDone: true,
                    isActive: false,
                  ),
                  _buildDispenseStep(
                    step: 2,
                    title: 'اعتماد الصيدلي السريري وفحص التداخلات',
                    desc: 'مراجعة د. سارة الشهري (ترخيص هيئة التخصصات #48190).',
                    isDone: false,
                    isActive: true,
                  ),
                  _buildDispenseStep(
                    step: 3,
                    title: 'التجهيز والختم الأمني مع حساس الحرارة',
                    desc: 'تعبئة داخل بوكس التبريد الطبي وحساس IoT.',
                    isDone: false,
                    isActive: false,
                  ),
                  _buildDispenseStep(
                    step: 4,
                    title: 'التسليم الفوري مع كابتن التوصيل الصحي (15 دقيقة)',
                    desc: 'استلام مباشر عند باب المنزل بعد مطابقة رمز PIN المريض.',
                    isDone: false,
                    isActive: false,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDispenseStep({
    required int step,
    required String title,
    required String desc,
    required bool isDone,
    required bool isActive,
  }) {
    Color iconColor = isDone
        ? const Color(0xFF059669)
        : isActive
            ? const Color(0xFF0284C7)
            : Colors.grey.shade400;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: isDone
                  ? const Color(0xFFD1FAE5)
                  : isActive
                      ? const Color(0xFFE0F2FE)
                      : Colors.grey.shade100,
              shape: BoxShape.circle,
              border: Border.all(color: iconColor, width: 1.5),
            ),
            child: Center(
              child: isDone
                  ? const Icon(Icons.check, size: 16, color: Color(0xFF059669))
                  : Text(
                      '$step',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: iconColor),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive || isDone ? FontWeight.bold : FontWeight.normal,
                    color: isActive ? const Color(0xFF0284C7) : AppColors.textPrimary,
                  ),
                ),
                Text(
                  desc,
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 3: CHRONIC MEDICATION AUTO-REFILL SUBSCRIPTIONS
  // ===========================================================================
  Widget _buildChronicRefills() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header explanation
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.calendar_month_rounded, color: Color(0xFFD97706), size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'التجديد التلقائي لأدوية الأمراض المزمنة',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'لا تقلق من نفاد أدويتك الأساسية، يقوم النظام بإعادة صرفها وتوصيلها تلقائياً قبل 3 أيام من انتهاء مخزونك المنزلي.',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // List of Chronic Meds
        ..._chronicMeds.map((med) {
          final daysLeft = med['daysRemaining'] as int;
          final totalDays = med['totalDays'] as int;
          final progress = daysLeft / totalDays;
          final isCritical = daysLeft <= 3;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: isCritical ? Colors.red.shade200 : Colors.grey.shade200,
                width: isCritical ? 1.5 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              med['name'] as String,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'الجرعة: ${med['dosage']}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF065F46)),
                            ),
                            Text(
                              'الطبيب المعالج: ${med['doctor']}',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isCritical ? Colors.red.shade50 : const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isCritical ? Colors.red.shade200 : const Color(0xFFA7F3D0),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$daysLeft يوم',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isCritical ? Colors.red : const Color(0xFF065F46),
                              ),
                            ),
                            Text(
                              'المتبقي لديك',
                              style: TextStyle(fontSize: 10, color: isCritical ? Colors.red.shade700 : const Color(0xFF047857)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isCritical ? Colors.red : const Color(0xFF059669),
                      ),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Switch(
                            value: med['autoRefill'] as bool,
                            activeTrackColor: const Color(0xFF065F46).withValues(alpha: 0.5),
                            activeThumbColor: const Color(0xFF065F46),
                            onChanged: (val) {
                              setState(() {
                                med['autoRefill'] = val;
                              });
                            },
                          ),
                          const Text(
                            'تجديد تلقائي شهري',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF065F46),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('تم جدولة إعادة صرف ${med['name']} للشحن الفوري المبرد'),
                              backgroundColor: const Color(0xFF065F46),
                            ),
                          );
                        },
                        child: const Text('صرف مبكر الآن', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ===========================================================================
  // TAB 4: OTC HEALTHCARE ESSENTIALS CATALOG
  // ===========================================================================
  Widget _buildOtcCatalog() {
    final cart = Provider.of<CartProvider>(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Fast notice
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFA7F3D0)),
          ),
          child: const Row(
            children: [
              Icon(Icons.bolt_rounded, color: Color(0xFF059669), size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'أدوية ومستلزمات فورية بدون وصفة طبية (توصيل فوري خلال 15 دقيقة مع نون مينتس)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.65,
          ),
          itemCount: _otcProducts.length,
          itemBuilder: (context, index) {
            final product = _otcProducts[index];
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  Expanded(
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                          child: Image.network(
                            product.firstImage,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: Colors.grey.shade100,
                              child: const Center(
                                child: Icon(Icons.medication_rounded, size: 40, color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                        if (product.discountPercent > 0)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '-${product.discountPercent}%',
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Info
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.nameAr,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, height: 1.2),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              '${product.price.toStringAsFixed(2)} ر.س',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFF065F46),
                              ),
                            ),
                            if (product.originalPrice != null) ...[
                              const SizedBox(width: 4),
                              Text(
                                product.originalPrice!.toStringAsFixed(2),
                                style: const TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Add to Cart Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF065F46),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.add_shopping_cart_rounded, size: 14),
                            label: const Text('إضافة للسلة', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            onPressed: () {
                              cart.addToCart(product);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('تمت إضافة ${product.nameAr} إلى السلة'),
                                  duration: const Duration(seconds: 1),
                                  backgroundColor: const Color(0xFF065F46),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
