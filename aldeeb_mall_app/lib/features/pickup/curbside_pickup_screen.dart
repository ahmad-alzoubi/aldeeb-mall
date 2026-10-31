import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';

class CurbsidePickupScreen extends StatefulWidget {
  final String orderNumber;
  final int itemsCount;
  final double totalAmount;

  const CurbsidePickupScreen({
    super.key,
    this.orderNumber = 'ORD-9028',
    this.itemsCount = 6,
    this.totalAmount = 145.50,
  });

  @override
  State<CurbsidePickupScreen> createState() => _CurbsidePickupScreenState();
}

class _CurbsidePickupScreenState extends State<CurbsidePickupScreen> {
  int _currentStep = 1; // 1: On the way, 2: Arrived & Parked, 3: Runner dispatched, 4: Loaded & Done
  int _selectedBay = 4;
  int _runnerCountdownSeconds = 120; // 2 minutes guarantee
  Timer? _countdownTimer;

  final TextEditingController _carModelController = TextEditingController(text: 'تويوتا لاندكروزر - أبيض لؤلؤي');
  final TextEditingController _licensePlateController = TextEditingController(text: 'د ي ب 2026');

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _carModelController.dispose();
    _licensePlateController.dispose();
    super.dispose();
  }

  void _onImOnTheWay() {
    setState(() => _currentStep = 1);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        content: Text('🚗 تم إخطار فريق الديب مول بأنك في طريقك، ويجري تجهيز أكياسك عند بوابة التحميل!'),
      ),
    );
  }

  void _onArrivedAndParked() {
    setState(() {
      _currentStep = 2;
      _runnerCountdownSeconds = 120;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_runnerCountdownSeconds > 0) {
            _runnerCountdownSeconds--;
            if (_runnerCountdownSeconds == 90) {
              _currentStep = 3; // Runner dispatched
            }
          } else {
            _currentStep = 4; // Completed
            timer.cancel();
          }
        });
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        content: Text('📍 تم تأكيد وقوفك في الموقف $_selectedBay! موظف الديب مول في طريقه لسيارتك الآن.'),
      ),
    );
  }

  String _formatTimer(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('خدمة الاستلام من السيارة (Curbside Pickup)'),
      ),
      body: SingleChildScrollView(
        child: MaxWidthContainer(
          maxWidth: 850,
          child: Padding(
            padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Live Status Card
                _buildLiveStatusHero(),

                const SizedBox(height: 20),

                // Parking Bay Selector
                _buildParkingBaySelector(),

                const SizedBox(height: 20),

                // Vehicle Details Card
                _buildVehicleDetailsCard(),

                const SizedBox(height: 24),

                // Interactive Progress Actions
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLiveStatusHero() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0D3B2E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 18,
            offset: const Offset(0, 6),
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
                  color: AppColors.accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.directions_car_filled_rounded, color: AppColors.accent, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'استلام سريع بدون نزول من المركبة',
                      style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Text(
                widget.orderNumber,
                style: const TextStyle(color: Colors.white70, fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),

          const SizedBox(height: 18),

          if (_currentStep == 1) ...[
            const Text(
              'الطلب جاهز ومغلّف بانتظار وصولك للمول 🚗',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 6),
            const Text(
              'عند وصولك لمواقف الديب مول المخصصة لخدمة السيارات، اختر رقم الموقف واضغط زر "وصلت للموقف" لنحضر مشترياتك في دقيقتين.',
              style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
            ),
          ] else if (_currentStep >= 2 && _currentStep < 4) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentStep == 3 ? 'الكابتن خرج حاملاً طلبك لسيارتك 🏃‍♂️' : 'الموظف يجهّز الأكياس من الثلاجة ❄️',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'أنت تركن في الموقف رقم $_selectedBay • وقت الوصول المتبقي:',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    _formatTimer(_runnerCountdownSeconds),
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'تم تحميل مشترياتك في صندوق السيارة بنجاح! شكراً لتسوقك من الديب مول 💚',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildParkingBaySelector() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.local_parking_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'اختر رقم موقف الاستلام المخصص (Curbside Bay):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(6, (index) {
              final bayNum = index + 1;
              final isSel = _selectedBay == bayNum;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () => setState(() => _selectedBay = bayNum),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSel ? AppColors.primary : AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSel ? AppColors.primary : AppColors.border,
                          width: isSel ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'موقف',
                            style: TextStyle(
                              fontSize: 10,
                              color: isSel ? Colors.white70 : AppColors.textMuted,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$bayNum',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: isSel ? Colors.white : AppColors.textPrimary,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.directions_car_outlined, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'بيانات سيارتك (لتسهيل وصول الموظف إليها فوراً):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _carModelController,
                  decoration: InputDecoration(
                    labelText: 'موديل ولون المركبة',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _licensePlateController,
                  decoration: InputDecoration(
                    labelText: 'رقم اللوحة',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (_currentStep == 1) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _onImOnTheWay,
              icon: const Icon(Icons.navigation_rounded, color: AppColors.primary),
              label: const Text(
                'أنا في طريقي للفرع (تجهيز الأكياس مسبقاً)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _onArrivedAndParked,
              icon: const Icon(Icons.pin_drop_rounded, color: Colors.white),
              label: Text(
                'لقد وصلت وركنت في الموقف $_selectedBay (إرسال الموظف)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ] else if (_currentStep >= 2 && _currentStep < 4) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() => _currentStep = 4);
                _countdownTimer?.cancel();
              },
              icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.green),
              label: const Text(
                'تم وضع الطلب في سيارتي بنجاح',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.green, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ] else ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('العودة إلى الصفحة الرئيسية', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ],
    );
  }
}
