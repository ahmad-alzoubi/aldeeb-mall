import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/providers/mall_provider.dart';
import '../cart/cart_screen.dart';

class VoiceAssistantModal extends StatefulWidget {
  const VoiceAssistantModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const VoiceAssistantModal(),
    );
  }

  @override
  State<VoiceAssistantModal> createState() => _VoiceAssistantModalState();
}

class _VoiceAssistantModalState extends State<VoiceAssistantModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _rippleCtrl;
  bool _isListening = true;
  String _recognizedText = 'جاري الاستماع لصوتك... قل ما تحتاجه من مقادير أو مشتريات';
  bool _hasResult = false;
  int _matchedCount = 0;

  @override
  void initState() {
    super.initState();
    _rippleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Auto-simulate prompt after 2 seconds
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        _simulateVoiceRecognition('أضف حليب المراعي وموز كافنديش لسلتي');
      }
    });
  }

  @override
  void dispose() {
    _rippleCtrl.dispose();
    super.dispose();
  }

  void _simulateVoiceRecognition(String text) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final mall = Provider.of<MallProvider>(context, listen: false);

    setState(() {
      _isListening = false;
      _recognizedText = text;
      _hasResult = true;
    });

    // Auto-add matched products
    final p = mall.filteredProducts;
    if (p.isNotEmpty) {
      cart.addToCart(p[0]); // Bananas
      if (p.length > 3) cart.addToCart(p[3]); // Milk
      setState(() => _matchedCount = 2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome, color: AppColors.accent, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'مساعد الديب الصوتي الذكي (Voice AI)',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textMuted),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Animated Voice Ripple Circle
          Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _rippleCtrl,
                builder: (ctx, child) {
                  return Container(
                    width: 100 + (_rippleCtrl.value * 25),
                    height: 100 + (_rippleCtrl.value * 25),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.15 * (1.0 - _rippleCtrl.value)),
                    ),
                  );
                },
              ),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 14,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  color: Colors.white,
                  size: 34,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Speech Output Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Text(
                  _recognizedText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: _hasResult ? FontWeight.bold : FontWeight.normal,
                    color: _hasResult ? AppColors.textPrimary : AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                if (_hasResult) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.freshGreen, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'تم التعرف على $_matchedCount أصناف وإضافتها إلى سلتك بنجاح!',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.freshGreen),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Quick Command Prompts Chips
          const Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              'أو جرّب أحد الأوامر الصوتية الجاهزة:',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _commandChip('أضف دجاج مبرد وطماطم مزارع'),
              _commandChip('بدي مقادير كبسة الدجاج كاملة'),
              _commandChip('أظهر عروض الفلاش الخاطفة'),
            ],
          ),
          const SizedBox(height: 24),

          // Actions
          if (_hasResult)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                );
              },
              icon: const Icon(Icons.shopping_cart_checkout),
              label: const Text('عرض السلة والمتابعة للدفع', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _commandChip(String prompt) {
    return InkWell(
      onTap: () => _simulateVoiceRecognition(prompt),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.record_voice_over_outlined, size: 14, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(prompt, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}
