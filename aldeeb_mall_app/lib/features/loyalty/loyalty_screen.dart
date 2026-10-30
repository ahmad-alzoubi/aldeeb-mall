import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/responsive.dart';

class LoyaltyScreen extends StatefulWidget {
  const LoyaltyScreen({super.key});

  @override
  State<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends State<LoyaltyScreen> {
  int _totpCountdown = 30;
  Timer? _totpTimer;
  double _convertSliderValue = 100;

  @override
  void initState() {
    super.initState();
    _startTotpTimer();
  }

  void _startTotpTimer() {
    _totpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_totpCountdown > 1) {
            _totpCountdown--;
          } else {
            _totpCountdown = 30; // auto-refresh TOTP barcode
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _totpTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final user = auth.currentUser;
    final points = user?.loyaltyPoints ?? 480;
    final tier = points > 1000 ? 'Platinum Elite' : points >= 300 ? 'Gold VIP' : 'Silver';
    final pointsToNextTier = points >= 1000 ? 0 : points >= 300 ? (1000 - points) : (300 - points);
    final nextTierName = points >= 300 ? 'Platinum Elite' : 'Gold VIP';
    final progressPercent = points >= 1000 ? 1.0 : (points / 1000.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('نادي مكافآت ونقاط الديب (VIP Club)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: MaxWidthContainer(
          maxWidth: 900,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Digital Metallic Loyalty Card
              Container(
                height: 230,
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: tier == 'Platinum Elite'
                        ? [const Color(0xFF0F172A), const Color(0xFF334155), const Color(0xFF1E293B)]
                        : tier == 'Gold VIP'
                        ? [const Color(0xFF78350F), const Color(0xFFB45309), const Color(0xFFD97706)]
                        : [AppColors.primaryDark, AppColors.primary, const Color(0xFF1E3A8A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: (tier == 'Gold VIP' ? const Color(0xFFB45309) : AppColors.primary)
                          .withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Card Top Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.stars_rounded, color: AppColors.accent, size: 24),
                            ),
                            const SizedBox(width: 10),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'بطاقة عضوية الديب VIP',
                                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'برنامج مكافآت الهايبرماركت الفوري',
                                  style: TextStyle(color: Colors.white70, fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4),
                            ],
                          ),
                          child: Text(
                            tier,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Card Points Balance
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('رصيد النقاط المتاحة', style: TextStyle(color: Colors.white70, fontSize: 11)),
                            const SizedBox(height: 2),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '$points',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text('نقطة', style: TextStyle(color: Colors.white70, fontSize: 14)),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'تعادل ${(points * 0.01).toStringAsFixed(2)} د.إ',
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),

                    // In-Store Cashier Barcode with 30s Countdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.qr_code_scanner, color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'كود الكاشير: DEEB-${user?.id.substring(0, 4).toUpperCase() ?? "7789"}-$_totpCountdown',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  value: _totpCountdown / 30.0,
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                  backgroundColor: const Color(0xFFE2E8F0),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$_totpCountdown ث',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. VIP Tier Progress Card
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
                        Text(
                          'مستوى العضوية: $tier',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        if (pointsToNextTier > 0)
                          Text(
                            'متبقي $pointsToNextTier نقطة للترقية إلى $nextTierName',
                            style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
                          )
                        else
                          const Text(
                            'وصلت إلى الفئة العليا!',
                            style: TextStyle(fontSize: 11, color: AppColors.freshGreen, fontWeight: FontWeight.bold),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progressPercent,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFE2E8F0),
                        color: tier == 'Gold VIP' ? const Color(0xFFD97706) : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Instant Points-to-Cash Converter Tool
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppColors.cardShadow,
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.currency_exchange, color: AppColors.freshGreen, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'محول النقاط الفوري لمحفظتك (Points Calculator)',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('النقاط المراد استبدالها: ${_convertSliderValue.toInt()} نقطة',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        Text(
                          '= ${(_convertSliderValue * 0.01).toStringAsFixed(2)} د.إ رصيد فوري',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.freshGreen),
                        ),
                      ],
                    ),
                    Slider(
                      value: _convertSliderValue,
                      min: 50,
                      max: points > 50 ? points.toDouble() : 100,
                      divisions: 10,
                      activeColor: AppColors.freshGreen,
                      onChanged: (val) {
                        setState(() => _convertSliderValue = val);
                      },
                    ),
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '✓ تم تحويل ${_convertSliderValue.toInt()} نقطة إلى ${(_convertSliderValue * 0.01).toStringAsFixed(2)} د.إ في محفظتك!',
                            ),
                            backgroundColor: AppColors.freshGreen,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.freshGreen,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(42),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('تحويل الآن إلى رصيد المحفظة', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4. VIP Perks & Privileges
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
                    const Text('مزايا عضويتك الحصرية في الديب مول', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 12),
                    _perkRow(Icons.bolt, 'توصيل مجاني 15 دقيقة دائم', 'توصيل فوري مجاني على جميع طلبات السوبرماركت.'),
                    const Divider(height: 16),
                    _perkRow(Icons.percent, 'كاش باك 5% إضافي في المحفظة', 'استرداد نقدي مباشر مع كل طلب يتجاوز 150 د.إ.'),
                    const Divider(height: 16),
                    _perkRow(Icons.support_agent, 'أولوية التجهيز ودعم VIP مخصص', 'تجهيز طلبك في أول الدفعة ومتابعة شخصية.'),
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

  Widget _perkRow(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }
}
