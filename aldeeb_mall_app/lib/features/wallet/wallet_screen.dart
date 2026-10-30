import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';

class WalletTransaction {
  final String id;
  final String title;
  final String date;
  final double amount;
  final bool isCredit;
  final String type; // 'refund', 'topup', 'order', 'cashback'

  WalletTransaction({
    required this.id,
    required this.title,
    required this.date,
    required this.amount,
    required this.isCredit,
    required this.type,
  });
}

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  double _balance = 150.00;
  final double _pendingCashback = 42.50;
  final TextEditingController _voucherController = TextEditingController();
  final TextEditingController _phoneGiftController = TextEditingController();

  final List<WalletTransaction> _transactions = [
    WalletTransaction(
      id: 'tx-1',
      title: 'استرداد فوري لطلب #ORD-9024 (أفوكادو)',
      date: 'اليوم، 02:40 ص',
      amount: 24.50,
      isCredit: true,
      type: 'refund',
    ),
    WalletTransaction(
      id: 'tx-2',
      title: 'كاش باك برنامج ولاء الديب VIP الذهبي',
      date: 'أمس، 09:15 م',
      amount: 12.00,
      isCredit: true,
      type: 'cashback',
    ),
    WalletTransaction(
      id: 'tx-3',
      title: 'دفع مشتريات الديب مول #ORD-8991',
      date: '28 أكتوبر 2026',
      amount: 86.50,
      isCredit: false,
      type: 'order',
    ),
    WalletTransaction(
      id: 'tx-4',
      title: 'شحن رصيد المحفظة عبر Apple Pay',
      date: '25 أكتوبر 2026',
      amount: 200.00,
      isCredit: true,
      type: 'topup',
    ),
  ];

  void _topUp(double amount) {
    setState(() {
      _balance += amount;
      _transactions.insert(
        0,
        WalletTransaction(
          id: 'tx-${DateTime.now().millisecondsSinceEpoch}',
          title: 'شحن رصيد المحفظة عبر بطاقة مدى',
          date: 'الآن',
          amount: amount,
          isCredit: true,
          type: 'topup',
        ),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Text('تم شحن $amount ر.س بنجاح إلى محفظة الديب الخاصة بك!'),
          ],
        ),
      ),
    );
  }

  void _redeemVoucher() {
    final code = _voucherController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    if (code == 'DEEB50' || code == 'ALDEEB' || code == 'GIFT') {
      setState(() {
        _balance += 50.0;
        _transactions.insert(
          0,
          WalletTransaction(
            id: 'tx-${DateTime.now().millisecondsSinceEpoch}',
            title: 'شحن بطاقة هدية رقمية ($code)',
            date: 'الآن',
            amount: 50.00,
            isCredit: true,
            type: 'topup',
          ),
        );
      });
      _voucherController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.primaryLight,
          behavior: SnackBarBehavior.floating,
          content: Text('🎉 تهانينا! تمت إضافة 50.00 ر.س رصيد مجاني لمحفظتك بنجاح'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          content: Text('كود القسيمة غير صالح أو منتهي الصلاحية (جرب كود: DEEB50)'),
        ),
      );
    }
  }

  void _sendGiftBalance() {
    final phone = _phoneGiftController.text.trim();
    if (phone.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text('يرجى إدخال رقم جوال صحيح لتحويل الرصيد'),
        ),
      );
      return;
    }

    if (_balance < 25) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text('الرصيد غير كافٍ. الحد الأدنى للإهداء 25 ر.س'),
        ),
      );
      return;
    }

    setState(() {
      _balance -= 25.0;
      _transactions.insert(
        0,
        WalletTransaction(
          id: 'tx-${DateTime.now().millisecondsSinceEpoch}',
          title: 'إهداء رصيد لرقم $phone',
          date: 'الآن',
          amount: 25.00,
          isCredit: false,
          type: 'order',
        ),
      );
    });

    _phoneGiftController.clear();
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        content: Text('🎁 تم إرسال هدية 25 ر.س بنجاح إلى $phone مع رسالة مباركة!'),
      ),
    );
  }

  @override
  void dispose() {
    _voucherController.dispose();
    _phoneGiftController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('محفظة الديب الذكية (Aldeeb Pay)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: 'كيف تعمل المحفظة وتقسيم الدفع؟',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('مميزات محفظة الديب'),
                  content: const Text(
                    '• دفع فوري بنقرة واحدة بدون إدخال رمز التحقق OTP لكل طلب.\n'
                    '• تقسيم الدفع الذكي (Split Payment): ادفع جزءاً من رصيد المحفظة والباقي عبر Apple Pay أو مدى.\n'
                    '• كاش باك فوري 5% على جميع عمليات إعادة الشحن.\n'
                    '• استرداد مالي فوري خلال دقيقة واحدة في حال وجود أي مرتجع.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('فهمت ذلك'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: MaxWidthContainer(
          maxWidth: 900,
          child: Padding(
            padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Digital VIP Wallet Card
                _buildDigitalCard(),

                const SizedBox(height: 24),

                // Quick Top-up buttons
                _buildQuickTopUpSection(),

                const SizedBox(height: 24),

                // Split Payment & Gift Card tools
                _buildInteractiveTools(),

                const SizedBox(height: 28),

                // Transactions Ledger
                _buildTransactionHistory(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDigitalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F3A2A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F3A2A).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.accent, size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'ALDEEB PAY • VIP WALLET',
                    style: TextStyle(
                      color: Colors.white70,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const Icon(Icons.contactless_rounded, color: Colors.white60, size: 28),
            ],
          ),
          const SizedBox(height: 28),
          const Text(
            'الرصيد المتاح للاستخدام الفوري',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _balance.toStringAsFixed(2),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'ر.س',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: AppColors.accent, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'كاش باك معلق: +${_pendingCashback.toStringAsFixed(2)} ر.س',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Text(
                  '•••• 7719',
                  style: TextStyle(color: Colors.white60, letterSpacing: 2, fontFamily: 'monospace', fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTopUpSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'شحن سريع للمحفظة مع مكافأة كاش باك +5%',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '+5% فوري',
                style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildTopUpButton(50),
            const SizedBox(width: 10),
            _buildTopUpButton(100),
            const SizedBox(width: 10),
            _buildTopUpButton(250),
          ],
        ),
      ],
    );
  }

  Widget _buildTopUpButton(double amount) {
    return Expanded(
      child: InkWell(
        onTap: () => _topUp(amount),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                '+$amount ر.س',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'كاش باك ${(amount * 0.05).toStringAsFixed(1)} ر.س',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInteractiveTools() {
    return Row(
      children: [
        // Redeem Gift Voucher
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.card_giftcard_rounded, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'شحن بطاقة هدية',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _voucherController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText: 'أدخل الكود (مثال: DEEB50)',
                          hintStyle: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          filled: true,
                          fillColor: AppColors.background,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _redeemVoucher,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('تفعيل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 14),

        // Send Gift to Friend
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.send_rounded, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'إهداء رصيد لصديق',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) => Container(
                          padding: EdgeInsets.only(
                            top: 20,
                            left: 20,
                            right: 20,
                            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                          ),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('إهداء رصيد من محفظتك', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              const Text('أدخل رقم جوال المستلم، وسيتم تحويل 25 ر.س فوراً مع بطاقة تهنئة رقمية.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                              const SizedBox(height: 14),
                              TextField(
                                controller: _phoneGiftController,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  hintText: '+966 5X XXX XXXX',
                                  prefixIcon: const Icon(Icons.phone_iphone_rounded),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _sendGiftBalance,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text('تأكيد إرسال الهدية (25 ر.س)', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.favorite_rounded, color: AppColors.secondary, size: 16),
                    label: const Text('إرسال هدية فورية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'سجل العمليات وحركات المحفظة',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _transactions.length,
            separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.border),
            itemBuilder: (context, index) {
              final tx = _transactions[index];
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: tx.isCredit ? Colors.green.shade50 : Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    tx.isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                    color: tx.isCredit ? Colors.green.shade700 : Colors.red.shade700,
                    size: 20,
                  ),
                ),
                title: Text(
                  tx.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                subtitle: Text(
                  tx.date,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                trailing: Text(
                  '${tx.isCredit ? '+' : '-'}${tx.amount.toStringAsFixed(2)} ر.س',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: tx.isCredit ? Colors.green.shade700 : Colors.red.shade700,
                    fontFamily: 'monospace',
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
