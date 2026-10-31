import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/product_model.dart';
import '../wallet/wallet_screen.dart';

class PriceMatchModal extends StatefulWidget {
  final ProductModel? product;

  const PriceMatchModal({super.key, this.product});

  static void show(BuildContext context, {ProductModel? product}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PriceMatchModal(product: product),
    );
  }

  @override
  State<PriceMatchModal> createState() => _PriceMatchModalState();
}

class _PriceMatchModalState extends State<PriceMatchModal> {
  String _selectedCompetitor = 'أسواق العثيم';
  final List<String> _competitors = [
    'أسواق العثيم',
    'هايبر بندة',
    'كارفور السعودية',
    'لولو هايبرماركت',
    'الدانوب',
    'أسواق التميمي',
  ];

  final TextEditingController _competitorPriceController = TextEditingController();
  final TextEditingController _competitorUrlController = TextEditingController();
  bool _isVerifying = false;
  bool _isClaimApproved = false;
  double _refundAmount = 0.0;

  double get _aldeebPrice => widget.product?.price ?? 24.0;

  @override
  void initState() {
    super.initState();
    _competitorPriceController.text = (_aldeebPrice > 4 ? _aldeebPrice - 4 : _aldeebPrice).toStringAsFixed(2);
    _calculateRefund();
  }

  @override
  void dispose() {
    _competitorPriceController.dispose();
    _competitorUrlController.dispose();
    super.dispose();
  }

  void _calculateRefund() {
    final compPrice = double.tryParse(_competitorPriceController.text) ?? 0.0;
    if (compPrice > 0 && compPrice < _aldeebPrice) {
      final difference = _aldeebPrice - compPrice;
      setState(() {
        _refundAmount = difference * 2; // Double difference guarantee
      });
    } else {
      setState(() {
        _refundAmount = 0.0;
      });
    }
  }

  void _handleSubmitClaim() {
    if (_refundAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب أن يكون سعر المنافس أقل من سعر الديب لتطبيق الضمان!')),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    // Simulate AI Vision verification of competitor flyer/link
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _isClaimApproved = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
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
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
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
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.verified_user_rounded, color: Colors.blue.shade700, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ضمان أرخص سعر في المملكة 🇸🇦',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      Text(
                        'مطابقة ذكية للأسعار وتعويض بضعف الفرق كاش في محفظتك',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
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
            child: _isClaimApproved
                ? _buildApprovedState(context)
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Guarantee Callout Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'وعد الديب الذهبي 200%',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'تسوق وأنت مطمئن تماماً',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'إذا وجدت نفس هذا المنتج معروضاً بسعر أقل في أي هايبرماركت منافس معتمد في الرياض، نعوضك بضعف فرق السعر فورياً في محفظة الديب الخاصة بك!',
                              style: TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Product Details
                      if (widget.product != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  widget.product!.firstImage,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey.shade200),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.product!.nameAr,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Text('سعر الديب مول: ', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                        Text(
                                          '${_aldeebPrice.toStringAsFixed(2)} ر.س',
                                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.freshGreen),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Select Competitor
                      const Text(
                        '1. اختر الهايبرماركت المنافس:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _competitors.map((comp) {
                          final isSelected = _selectedCompetitor == comp;
                          return ChoiceChip(
                            label: Text(comp),
                            selected: isSelected,
                            onSelected: (_) => setState(() => _selectedCompetitor = comp),
                            selectedColor: AppColors.primary,
                            backgroundColor: Colors.white,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 11.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: isSelected ? AppColors.primary : Colors.grey.shade300,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Input Competitor Price
                      const Text(
                        '2. أدخل السعر المعروض لدى المنافس:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _competitorPriceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => _calculateRefund(),
                        decoration: InputDecoration(
                          hintText: 'مثال: 19.50',
                          suffixText: 'ر.س',
                          suffixStyle: const TextStyle(fontWeight: FontWeight.bold),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Proof Link / Upload
                      const Text(
                        '3. رابط العرض أو صورة المجلة الإعلانية (اختياري للتحقق الفوري):',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _competitorUrlController,
                        decoration: InputDecoration(
                          hintText: 'https://competitor.com/flyer-deal...',
                          prefixIcon: const Icon(Icons.link_rounded, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Live Calculation Box
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.freshGreenLight.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.freshGreen.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('سعر الديب مول:', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                Text('${_aldeebPrice.toStringAsFixed(2)} ر.س', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('سعر $_selectedCompetitor:', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                Text(
                                  '${(double.tryParse(_competitorPriceController.text) ?? 0.0).toStringAsFixed(2)} ر.س',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('مبلغ التعويض المستحق بالمحفظة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                                    Text('(ضعف الفرق 2X كاش فوري)', style: TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                                  ],
                                ),
                                Text(
                                  '${_refundAmount.toStringAsFixed(2)} ر.س',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.freshGreen,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isVerifying ? null : _handleSubmitClaim,
                          icon: _isVerifying
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.bolt_rounded, color: Colors.white),
                          label: Text(
                            _isVerifying ? 'جاري التحقق الفوري بالذكاء الاصطناعي...' : 'تقديم الطلب واسترداد التعويض فوراً',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovedState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.freshGreen.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_rounded, color: AppColors.freshGreen, size: 56),
          ),
          const SizedBox(height: 16),
          const Text(
            'تم التحقق والموافقة على التعويض بنجاح! 🎉',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'تمت مطابقة سعر $_selectedCompetitor بنجاح عبر محرك الذكاء الاصطناعي، وتم إيداع مبلغ التعويض في محفظة الديب الخاصة بك:',
            style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '+${_refundAmount.toStringAsFixed(2)} ر.س رصيد محفظة',
              style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w900, fontSize: 20),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('إغلاق ومتابعة التسوق'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const WalletScreen()),
                    );
                  },
                  icon: const Icon(Icons.account_balance_wallet_rounded, size: 16, color: Colors.white),
                  label: const Text('فتح المحفظة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
