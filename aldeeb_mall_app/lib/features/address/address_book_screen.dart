import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';

class SavedAddress {
  final String id;
  final String label; // 'المنزل', 'العمل', 'بيت العائلة'
  final String fullAddress;
  final String buildingType; // 'apartment', 'villa', 'office'
  final String details; // Floor, Apt #, Villa #
  final String instructions;
  bool isDefault;

  SavedAddress({
    required this.id,
    required this.label,
    required this.fullAddress,
    required this.buildingType,
    required this.details,
    required this.instructions,
    this.isDefault = false,
  });
}

class AddressBookScreen extends StatefulWidget {
  const AddressBookScreen({super.key});

  @override
  State<AddressBookScreen> createState() => _AddressBookScreenState();
}

class _AddressBookScreenState extends State<AddressBookScreen> {
  final List<SavedAddress> _addresses = [
    SavedAddress(
      id: 'addr-1',
      label: 'المنزل (Home)',
      fullAddress: 'برج فيوز B، بوليفارد الشيخ محمد بن راشد، وسط دبي',
      buildingType: 'apartment',
      details: 'الطابق 8، شقة 804 (رمز الدخول #1920)',
      instructions: 'اترك الطلب عند باب الشقة، لا تدق الجرس لوجود طفل نائم',
      isDefault: true,
    ),
    SavedAddress(
      id: 'addr-2',
      label: 'المكتب والعمل (Office)',
      fullAddress: 'مركز الملك عبدالله المالي (KAFD)، برج 4.08، طريق الثمامة',
      buildingType: 'office',
      details: 'الطابق 14، شركة الديب للتقنية',
      instructions: 'تسليم الطلب لموظف الاستقبال عند المدخل الرئيسي',
      isDefault: false,
    ),
    SavedAddress(
      id: 'addr-3',
      label: 'بيت الوالدة (Family House)',
      fullAddress: 'حي الياسمين، شارع القادسية، فيلا 22',
      buildingType: 'villa',
      details: 'فيلا مستقلة، البوابة الشمالية',
      instructions: 'رن الجرس وسيستلم الحارس أو أحد أفراد العائلة مباشرة',
      isDefault: false,
    ),
  ];

  bool _isGiftMode = false;
  final TextEditingController _giftRecipientName = TextEditingController();
  final TextEditingController _giftRecipientPhone = TextEditingController();
  final TextEditingController _giftCardMessage = TextEditingController();

  void _setDefault(String id) {
    setState(() {
      for (var a in _addresses) {
        a.isDefault = (a.id == id);
      }
    });

    final selected = _addresses.firstWhere((a) => a.id == id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Text('تم تعيين "${selected.label}" كعنوان التوصيل المعتمد لطلباتك!'),
          ],
        ),
      ),
    );
  }

  void _addNewAddressModal() {
    final labelCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final detailsCtrl = TextEditingController();
    final instructionsCtrl = TextEditingController();
    String buildingType = 'apartment';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.add_location_alt_rounded, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text('إضافة عنوان توصيل ذكي جديد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: labelCtrl,
                  decoration: InputDecoration(
                    labelText: 'اسم العنوان (مثال: الاستراحة، شقة الشاطئ)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressCtrl,
                  decoration: InputDecoration(
                    labelText: 'الشارع والحي والمدينة',
                    prefixIcon: const Icon(Icons.map_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildBuildingTypeChoice('apartment', 'شقة 🏢', buildingType, (v) => setSheetState(() => buildingType = v)),
                    const SizedBox(width: 8),
                    _buildBuildingTypeChoice('villa', 'فيلا 🏡', buildingType, (v) => setSheetState(() => buildingType = v)),
                    const SizedBox(width: 8),
                    _buildBuildingTypeChoice('office', 'مكتب 💼', buildingType, (v) => setSheetState(() => buildingType = v)),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: detailsCtrl,
                  decoration: InputDecoration(
                    labelText: 'رقم الشقة / الفيلا / الطابق',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: instructionsCtrl,
                  decoration: InputDecoration(
                    labelText: 'تعليمات دقيقة للكابتن (اختياري)',
                    hintText: 'مثال: لا تدق الجرس، رن على الجوال عند البوابة',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (labelCtrl.text.trim().isEmpty || addressCtrl.text.trim().isEmpty) return;
                      setState(() {
                        _addresses.add(
                          SavedAddress(
                            id: 'addr-${DateTime.now().millisecondsSinceEpoch}',
                            label: labelCtrl.text.trim(),
                            fullAddress: addressCtrl.text.trim(),
                            buildingType: buildingType,
                            details: detailsCtrl.text.trim(),
                            instructions: instructionsCtrl.text.trim(),
                            isDefault: false,
                          ),
                        );
                      });
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: AppColors.primary,
                          content: Text('تمت إضافة العنوان الجديد بنجاح!'),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('حفظ العنوان', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBuildingTypeChoice(String value, String label, String current, Function(String) onSelect) {
    final isSel = value == current;
    return Expanded(
      child: InkWell(
        onTap: () => onSelect(value),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSel ? AppColors.primary : AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSel ? AppColors.primary : AppColors.border),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSel ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('دفتر العناوين ومواقع التوصيل (Delivery Addresses)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location_alt_outlined),
            tooltip: 'إضافة عنوان جديد',
            onPressed: _addNewAddressModal,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: MaxWidthContainer(
          maxWidth: 880,
          child: Padding(
            padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gift Mode Switcher Banner
                _buildGiftModeCard(),

                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'العناوين المحفوظة في حسابك:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                    ),
                    TextButton.icon(
                      onPressed: _addNewAddressModal,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('إضافة عنوان جديد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Address List
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _addresses.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final addr = _addresses[index];
                    return _buildAddressCard(addr);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGiftModeCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _isGiftMode ? Colors.purple.shade200 : AppColors.border),
        boxShadow: [
          BoxShadow(
            color: (_isGiftMode ? Colors.purple : Colors.black).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.card_giftcard_rounded, color: Colors.purple, size: 22),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إرسال هذا الطلب كهدية مفاجئة لشخص آخر 🎁',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'سنقوم بتوصيل المقاضي أو باقة الفواكه مباشرة لعنوان المستلم مع بطاقة إهداء رقمية وبدون إظهار الفاتورة السعرية.',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isGiftMode,
                activeThumbColor: Colors.purple,
                onChanged: (v) => setState(() => _isGiftMode = v),
              ),
            ],
          ),

          if (_isGiftMode) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _giftRecipientName,
                    decoration: InputDecoration(
                      labelText: 'اسم المستلم المحظوظ',
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _giftRecipientPhone,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'رقم جوال المستلم',
                      prefixIcon: const Icon(Icons.phone_iphone_rounded),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _giftCardMessage,
              decoration: InputDecoration(
                labelText: 'رسالة الإهداء المطبوعة مع الطلب',
                hintText: 'مثال: ألف مبروك المنزل الجديد! من عائلة فهد ومريم 🌸',
                prefixIcon: const Icon(Icons.chat_bubble_outline_rounded),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddressCard(SavedAddress addr) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: addr.isDefault ? AppColors.primary : AppColors.border,
          width: addr.isDefault ? 1.5 : 1.0,
        ),
        boxShadow: addr.isDefault
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    addr.buildingType == 'villa' ? Icons.home_rounded :
                    addr.buildingType == 'office' ? Icons.business_rounded :
                    Icons.apartment_rounded,
                    color: addr.isDefault ? AppColors.primary : AppColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    addr.label,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                  ),
                  if (addr.isDefault) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'العنوان الافتراضي الحاكم',
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                    ),
                  ],
                ],
              ),
              if (!addr.isDefault)
                TextButton(
                  onPressed: () => _setDefault(addr.id),
                  child: const Text('تعيين كافتراضي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                )
              else
                const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
            ],
          ),

          const SizedBox(height: 8),
          Text(
            addr.fullAddress,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.3),
          ),
          const SizedBox(height: 4),
          Text(
            addr.details,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600),
          ),

          if (addr.instructions.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.directions_bike_rounded, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'ملاحظة الكابتن: ${addr.instructions}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
