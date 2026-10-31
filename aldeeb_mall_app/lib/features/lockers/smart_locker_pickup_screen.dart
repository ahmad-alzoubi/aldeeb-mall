import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class SmartLockerPickupScreen extends StatefulWidget {
  const SmartLockerPickupScreen({super.key});

  @override
  State<SmartLockerPickupScreen> createState() => _SmartLockerPickupScreenState();
}

class _SmartLockerPickupScreenState extends State<SmartLockerPickupScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Active Locker Order State
  bool _isUnlocking = false;
  bool _doorOpened = false;
  bool _orderCompleted = false;

  final Map<String, dynamic> _activeLockerOrder = {
    'orderId': '#ORD-88219',
    'hubName': 'محطة خزائن كافد الذكية (مركز الملك عبدالله المالي)',
    'hubAddress': 'الرياض - طريق الثمامة - بوابة 4 بجانب برج تمكين',
    'compartmentNo': 14,
    'zone': 'مبرد (Chilled 3.4°C)',
    'zoneType': 'chilled',
    'pickupPin': '849 201',
    'qrCodeData': 'ALDEEB-LOCKER-88219-KAFD-14',
    'expiresInHours': 18,
    'totalItems': 6,
    'itemsList': [
      'حليب المراعي طازج 2 لتر (مبرد)',
      'زبادي يوناني نادك خالي الدسم x3',
      'جبنة فيتا يونانية أصلية 400 جم',
      'فراولة طازجة دريسكول علبة 250 جم',
    ],
  };

  // Locker Hubs Network
  final List<Map<String, dynamic>> _lockerHubs = [
    {
      'id': 'hub-kafd',
      'name': 'محطة كافد المالية (KAFD Hub)',
      'city': 'الرياض',
      'distance': '1.2 كم',
      'totalDoors': 24,
      'freeChilled': 4,
      'freeFrozen': 2,
      'freeAmbient': 7,
      'isOpen247': true,
      'status': 'نشطة وتعمل 24/7',
    },
    {
      'id': 'hub-nakheel',
      'name': 'محطة النخيل مول (Gate 3 Hub)',
      'city': 'الرياض',
      'distance': '4.5 كم',
      'totalDoors': 32,
      'freeChilled': 6,
      'freeFrozen': 3,
      'freeAmbient': 12,
      'isOpen247': true,
      'status': 'نشطة وتعمل 24/7',
    },
    {
      'id': 'hub-digital-city',
      'name': 'محطة المدينة الرقمية (Digital City)',
      'city': 'الرياض',
      'distance': '6.8 كم',
      'totalDoors': 24,
      'freeChilled': 2,
      'freeFrozen': 1,
      'freeAmbient': 8,
      'isOpen247': true,
      'status': 'نشطة وتعمل 24/7',
    },
    {
      'id': 'hub-jeddah-corniche',
      'name': 'محطة كورنيش جدة الشمالي',
      'city': 'جدة',
      'distance': 'جدة',
      'totalDoors': 20,
      'freeChilled': 5,
      'freeFrozen': 2,
      'freeAmbient': 6,
      'isOpen247': true,
      'status': 'نشطة وتعمل 24/7',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _triggerProximityUnlock() async {
    setState(() => _isUnlocking = true);

    // Simulate BLE Proximity handshake
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    setState(() {
      _isUnlocking = false;
      _doorOpened = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.lock_open_rounded, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text('طقطقة الفتح! تم فتح باب الخزينة رقم #14 تلقائياً عبر البلوتوث.'),
            ),
          ],
        ),
        backgroundColor: AppColors.freshGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.cyan.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.meeting_room_rounded, color: Colors.cyanAccent, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'خزائن الديب الذكية 24/7',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Aldeeb Smart Lockers • استلام ذاتي بدون انتظار',
                  style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.cyanAccent,
          indicatorWeight: 3,
          labelColor: Colors.cyanAccent,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.qr_code_2_rounded, size: 18), text: 'طلبي في الخزينة الآن'),
            Tab(icon: Icon(Icons.map_rounded, size: 18), text: 'شبكة محطات الخزائن بالمملكة'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveOrderTab(),
          _buildHubsNetworkTab(),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1: ACTIVE LOCKER PICKUP ORDER
  // ===========================================================================
  Widget _buildActiveOrderTab() {
    if (_orderCompleted) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFA7F3D0), width: 2),
                ),
                child: const Icon(Icons.verified_rounded, color: Color(0xFF059669), size: 64),
              ),
              const SizedBox(height: 20),
              const Text(
                'تم استلام طلبك بنجاح!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                'شكراً لاستخدامك خزائن الديب الذكية ذاتية الخدمة. تم إغلاق باب الخزينة رقم #14 وإرسال الفاتورة الضريبية إلى بريدك.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.home_rounded),
                label: const Text('العودة للمول الرئيسي', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Hub Info Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.cyan.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.ac_unit_rounded, size: 14, color: Colors.cyanAccent),
                          const SizedBox(width: 6),
                          Text(
                            _activeLockerOrder['zone'] as String,
                            style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _activeLockerOrder['orderId'] as String,
                      style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _activeLockerOrder['hubName'] as String,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  _activeLockerOrder['hubAddress'] as String,
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, color: Colors.amber, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'متاح للاستلام لمدة: ${_activeLockerOrder['expiresInHours']} ساعة قادمة',
                      style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Locker Compartment & PIN Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _doorOpened ? AppColors.freshGreen : Colors.grey.shade200,
                width: _doorOpened ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'رقم الخلية المخصصة:',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        Text(
                          'بوابة رقم #${_activeLockerOrder['compartmentNo']}',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _doorOpened ? const Color(0xFFECFDF5) : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        _doorOpened ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                        color: _doorOpened ? AppColors.freshGreen : AppColors.primary,
                        size: 36,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 30),

                // PIN Code Display
                const Text(
                  'رمز الفتح السري (PIN Code):',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _activeLockerOrder['pickupPin'] as String,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                      fontFamily: 'monospace',
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // QR Code Representation
                Container(
                  width: 130,
                  height: 130,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Center(
                    child: Icon(Icons.qr_code_2_rounded, size: 106, color: Color(0xFF0F172A)),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'امسح الـ QR عند شاشة الخزانة أو استخدم زر الفتح الذكي أدناه',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),

                // Proximity Unlock Action
                if (!_doorOpened)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 1,
                      ),
                      icon: _isUnlocking
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.bluetooth_audio_rounded),
                      label: Text(
                        _isUnlocking ? 'جارٍ الاتصال بالخزانة عبر البلوتوث...' : 'أنا عند الخزائن الآن (افتح الباب الذكي)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      onPressed: _isUnlocking ? null : _triggerProximityUnlock,
                    ),
                  )
                else
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'باب الخلية مفتوح الآن! خذ أكياس مقاضيك المبردة وتأكد من فراغ الخلية.',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.freshGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.done_all_rounded),
                          label: const Text(
                            'أخذت طلبي • أغلق الباب وأنهِ الاستلام',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          onPressed: () {
                            setState(() => _orderCompleted = true);
                          },
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Groceries inside the locker
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
                  'محتويات طلبك داخل الخلية:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 10),
                ...((_activeLockerOrder['itemsList'] as List<String>).map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, size: 16, color: Color(0xFF059669)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(item, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                          ),
                        ],
                      ),
                    ))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 2: LOCKER HUBS NETWORK
  // ===========================================================================
  Widget _buildHubsNetworkTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _lockerHubs.length,
      itemBuilder: (context, index) {
        final hub = _lockerHubs[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hub['name'] as String,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${hub['city']} • المسافة: ${hub['distance']}',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'متاحة 24/7 🟢',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Locker Compartments capacity badges
                Row(
                  children: [
                    _buildHubCapacityBadge(
                      label: 'مبرد (2°C-8°C)',
                      count: hub['freeChilled'] as int,
                      color: Colors.cyan,
                    ),
                    const SizedBox(width: 8),
                    _buildHubCapacityBadge(
                      label: 'مجمد (-18°C)',
                      count: hub['freeFrozen'] as int,
                      color: Colors.indigo,
                    ),
                    const SizedBox(width: 8),
                    _buildHubCapacityBadge(
                      label: 'جاف معتدل',
                      count: hub['freeAmbient'] as int,
                      color: Colors.blueGrey,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHubCapacityBadge({
    required String label,
    required int count,
    required MaterialColor color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.shade200),
      ),
      child: Text(
        '$label: $count فارغة',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color.shade900),
      ),
    );
  }
}
