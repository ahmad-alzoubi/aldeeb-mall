import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class DroneTrackingScreen extends StatefulWidget {
  const DroneTrackingScreen({super.key});

  @override
  State<DroneTrackingScreen> createState() => _DroneTrackingScreenState();
}

class _DroneTrackingScreenState extends State<DroneTrackingScreen>
    with SingleTickerProviderStateMixin {
  Timer? _telemetryTimer;
  double _droneProgress = 0.45; // 45% along the flight path
  int _altitudeMeters = 64;
  int _speedKmh = 72;
  int _batteryPercent = 88;
  int _etaSeconds = 270; // 4 mins 30 secs
  bool _isWinchLowering = false;
  bool _packageDelivered = false;

  final Map<String, dynamic> _droneMission = {
    'missionId': 'GACA-DRN-2026-9041',
    'droneModel': 'Falcon X-Hexacopter Cargo (كربون فايبر 6 محركات)',
    'droneSerial': 'ALDEEB-UAV-04',
    'originHelipad': 'مهبط المستودع الذكي كافد (Helipad Darkstore #01)',
    'destination': 'فيلا 14 - حي النرجس (مهبط الحديقة Lawn Landing Zone)',
    'payloadWeightKg': 2.8,
    'flightPermit': 'تصريح هيئة الطيران المدني GACA #59102-KSA',
    'windSpeed': '11 عقدة (مثالي 🟢)',
    'itemsList': [
      'حليب عضوي طازج نادك 1 لتر',
      'فراولة هولندية فاخرة علبة 250 جم',
      'كرواسون بالزبدة مخابز الديب x4',
      'قهوة كولومبية مختصة مطحونة 250 جم',
    ],
  };

  @override
  void initState() {
    super.initState();
    _startTelemetryStream();
  }

  @override
  void dispose() {
    _telemetryTimer?.cancel();
    super.dispose();
  }

  void _startTelemetryStream() {
    _telemetryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_etaSeconds > 0) {
          _etaSeconds -= 1;
          _droneProgress += 0.003;
          if (_droneProgress > 0.98) _droneProgress = 0.98;
          if (_etaSeconds % 20 == 0 && _batteryPercent > 15) {
            _batteryPercent -= 1;
          }

          // Slight realistic telemetry jitter
          _altitudeMeters = 62 + (_etaSeconds % 5);
          _speedKmh = 70 + (_etaSeconds % 4);
        } else if (!_isWinchLowering && !_packageDelivered) {
          _isWinchLowering = true;
          _altitudeMeters = 15; // Hovering altitude for tether winch drop
          _speedKmh = 0;
        }
      });
    });
  }

  void _simulateWinchDrop() async {
    setState(() => _isWinchLowering = true);
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    setState(() {
      _isWinchLowering = false;
      _packageDelivered = true;
      _altitudeMeters = 80; // Returning altitude
      _speedKmh = 85;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text('هبوط آمن! تم إنزال الطرد بكابل الرافعة الذكي عند مهبط الحديقة بنجاح.'),
            ),
          ],
        ),
        backgroundColor: AppColors.freshGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mins = _etaSeconds ~/ 60;
    final secs = _etaSeconds % 60;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
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
              child: const Icon(Icons.flight_takeoff_rounded, color: Colors.cyanAccent, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'التوصيل الجوي بدرونز الديب 10 دقائق',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Text(
                  'GACA Airway Authorized • تتبع رحلة الطيران المباشرة',
                  style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(left: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.battery_charging_full_rounded, color: Color(0xFF34D399), size: 16),
                const SizedBox(width: 4),
                Text(
                  '$_batteryPercent%',
                  style: const TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Flight Radar Simulation Canvas
            Container(
              height: 240,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.cyan.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyan.withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Radar grid background pattern
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _RadarGridPainter(),
                    ),
                  ),

                  // Flight Corridor Path Line
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _FlightPathPainter(progress: _droneProgress),
                    ),
                  ),

                  // Origin Helipad Node
                  Positioned(
                    top: 40,
                    right: 30,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.amber, width: 2),
                          ),
                          child: const Icon(Icons.storefront_rounded, color: Colors.amber, size: 20),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'مهبط كافد H1',
                          style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  // Destination Landing Pad Node
                  Positioned(
                    bottom: 40,
                    left: 30,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF34D399), width: 2),
                          ),
                          child: const Icon(Icons.my_location_rounded, color: Color(0xFF34D399), size: 20),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'مهبط منزلك (Lawn Pad)',
                          style: TextStyle(color: Color(0xFF34D399), fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  // Live Drone Icon moving along flight path
                  Positioned(
                    top: 40 + (140 * _droneProgress),
                    right: 30 + ((MediaQuery.of(context).size.width - 120) * _droneProgress),
                    child: Transform.rotate(
                      angle: 0.6,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.cyanAccent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.cyanAccent.withValues(alpha: 0.8),
                              blurRadius: 14,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.flight_rounded, color: Color(0xFF0F172A), size: 22),
                      ),
                    ),
                  ),

                  // Telemetry HUD overlay
                  Positioned(
                    top: 12,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Text(
                        'ALT: $_altitudeMeters m • SPD: $_speedKmh km/h',
                        style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontFamily: 'monospace',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Live ETA & Status Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF334155)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'الوقت المتبقي للهبوط والإنزال:',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _packageDelivered
                          ? 'تم الهبوط والتسليم بنجاح ✅'
                          : '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')} دقيقة',
                        style: TextStyle(
                          color: _packageDelivered ? const Color(0xFF34D399) : Colors.cyanAccent,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.cyan.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'طراز الدرونز:',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                        ),
                        Text(
                          _droneMission['droneSerial'] as String,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Winch Tether Lowering Action Simulation
            if (!_packageDelivered)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.cable_rounded, color: Colors.amber, size: 24),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'رافعة الكابل الذكية (Tether Winch Drop)',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                'يحوم الدرونز على ارتفاع 15 متراً وينزل البوكس الحراري بكابل آمن بدون هبوط المحركات.',
                                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyan.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: _isWinchLowering
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.download_rounded),
                        label: Text(
                          _isWinchLowering ? 'جارٍ إنزال الطرد بالكابل الآن...' : 'محاكاة وصول الدرونز وإنزال الطرد بالكابل',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        onPressed: _isWinchLowering ? null : _simulateWinchDrop,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF064E3B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF059669)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.verified_rounded, color: Color(0xFF34D399), size: 32),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تم استلام المقاضي بنجاح!',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'تم فك ارتباط الكابل وانطلق الدرونز عائداً لمهبط المستودع الذكي. مقاضيك بحالة تبريد ممتازة.',
                            style: TextStyle(color: Color(0xFFA7F3D0), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            // Mission Specification Table
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'بيانات ترخيص الرحلة الجوية (GACA Telemetry):',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  _buildFlightDetailRow('رقم التصريح الجوي:', _droneMission['flightPermit'] as String),
                  _buildFlightDetailRow('نقطة الإقلاع:', _droneMission['originHelipad'] as String),
                  _buildFlightDetailRow('وجهة الإنزال:', _droneMission['destination'] as String),
                  _buildFlightDetailRow('وزن الحمولة المنقولة:', '${_droneMission['payloadWeightKg']} كجم'),
                  _buildFlightDetailRow('سرعة الرياح الميدانية:', _droneMission['windSpeed'] as String),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlightDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// Custom Painter for Radar Grid
class _RadarGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyan.withValues(alpha: 0.1)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, 40, paint);
    canvas.drawCircle(center, 80, paint);
    canvas.drawCircle(center, 120, paint);

    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom Painter for Flight Path
class _FlightPathPainter extends CustomPainter {
  final double progress;
  _FlightPathPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final pathPaint = Paint()
      ..color = Colors.cyan.withValues(alpha: 0.3)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final p1 = Offset(size.width - 40, 50);
    final p2 = const Offset(40, 190);

    canvas.drawLine(p1, p2, pathPaint);

    // Active path
    final activePaint = Paint()
      ..color = Colors.cyanAccent
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    final currentEnd = Offset(
      p1.dx + (p2.dx - p1.dx) * progress,
      p1.dy + (p2.dy - p1.dy) * progress,
    );
    canvas.drawLine(p1, currentEnd, activePaint);
  }

  @override
  bool shouldRepaint(covariant _FlightPathPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
