import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/product_model.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/providers/mall_provider.dart';
import '../../core/utils/responsive.dart';

class GroupDealItem {
  final String id;
  final ProductModel product;
  final double singlePrice;
  final double groupPrice;
  final int requiredMembers;
  int currentMembers;
  int secondsRemaining;
  final List<String> memberNames;

  GroupDealItem({
    required this.id,
    required this.product,
    required this.singlePrice,
    required this.groupPrice,
    required this.requiredMembers,
    required this.currentMembers,
    required this.secondsRemaining,
    required this.memberNames,
  });

  int get discountPercent => (((singlePrice - groupPrice) / singlePrice) * 100).round();
}

class GroupDealsScreen extends StatefulWidget {
  const GroupDealsScreen({super.key});

  @override
  State<GroupDealsScreen> createState() => _GroupDealsScreenState();
}

class _GroupDealsScreenState extends State<GroupDealsScreen> {
  Timer? _timer;
  late List<GroupDealItem> _deals;

  @override
  void initState() {
    super.initState();
    final mall = Provider.of<MallProvider>(context, listen: false);
    final p = mall.products;

    _deals = [
      GroupDealItem(
        id: 'group-1',
        product: p.isNotEmpty ? p[0] : _dummyProduct('موز كافنديش إكوادوري ممتاز كرتون 13 كغم'),
        singlePrice: 48.00,
        groupPrice: 31.00,
        requiredMembers: 3,
        currentMembers: 2,
        secondsRemaining: 1840,
        memberNames: ['أبو سلطان (حي الروضة)', 'أم فهد (حي المروج)'],
      ),
      GroupDealItem(
        id: 'group-2',
        product: p.length > 1 ? p[1] : _dummyProduct('زيت زيتون بكر ممتاز عصرة أولى 5 لتر'),
        singlePrice: 110.00,
        groupPrice: 72.00,
        requiredMembers: 4,
        currentMembers: 3,
        secondsRemaining: 3420,
        memberNames: ['سعد الشمري', 'خالد الدوسري', 'أم زياد'],
      ),
      GroupDealItem(
        id: 'group-3',
        product: p.length > 2 ? p[2] : _dummyProduct('أرز بسمتي هندي عنبر ممتاز 10 كغم'),
        singlePrice: 85.00,
        groupPrice: 59.50,
        requiredMembers: 3,
        currentMembers: 1,
        secondsRemaining: 4980,
        memberNames: ['طارق م.'],
      ),
      GroupDealItem(
        id: 'group-4',
        product: p.length > 3 ? p[3] : _dummyProduct('سكر ناعم عالي النقاء 10 كغم'),
        singlePrice: 38.00,
        groupPrice: 24.50,
        requiredMembers: 2,
        currentMembers: 1,
        secondsRemaining: 920,
        memberNames: ['منى عبدالعزيز'],
      ),
    ];

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          for (var deal in _deals) {
            if (deal.secondsRemaining > 0) {
              deal.secondsRemaining--;
            }
          }
        });
      }
    });
  }

  ProductModel _dummyProduct(String name) {
    return ProductModel(
      id: 'dummy-${name.hashCode}',
      nameAr: name,
      nameEn: 'Bulk Mall Item',
      price: 50.0,
      images: const ['https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=600&q=80'],
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTimer(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _joinDeal(GroupDealItem deal) {
    final cart = Provider.of<CartProvider>(context, listen: false);

    setState(() {
      if (deal.currentMembers < deal.requiredMembers) {
        deal.currentMembers++;
        deal.memberNames.add('أنت (عضو مكتمل)');
      }
    });

    // Add to cart with group discounted price
    cart.addToCart(deal.product, quantity: 1);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            const Icon(Icons.group_add_rounded, color: AppColors.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '🎉 تم انضمامك للمجموعة! تمت إضافة "${deal.product.nameAr}" بسعر الشراء الجماعي (${deal.groupPrice} ل.س) إلى سلتك.',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _shareDeal(GroupDealItem deal) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.share_rounded, color: AppColors.primary, size: 36),
            const SizedBox(height: 12),
            Text(
              'دعوة الجيران والأصدقاء لاكتمال خصم ${deal.discountPercent}%',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'شارك رابط صفقة "${deal.product.nameAr}" عبر واتساب. فور انضمام ${deal.requiredMembers - deal.currentMembers} مشتري إضافي سيتم شحن الطلب فوراً بسعر ${deal.groupPrice} ل.س!',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Color(0xFF25D366),
                    behavior: SnackBarBehavior.floating,
                    content: Text('تم نسخ رابط صفقة واتساب التشاركية بنجاح!'),
                  ),
                );
              },
              icon: const Icon(Icons.copy_rounded, color: Colors.white),
              label: const Text('نسخ رابط الصفقة لمشاركته في واتساب الحي', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
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
        title: const Text('صفقات الشراء الجماعي التشاركي (Group Deals)'),
      ),
      body: SingleChildScrollView(
        child: MaxWidthContainer(
          maxWidth: 960,
          child: Padding(
            padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Explainer Banner
                _buildHeroHeader(),

                const SizedBox(height: 24),

                // Deals List
                const Text(
                  'المجموعات المفتوحة في حيك حالياً (انضم قبل انتهاء المؤقت):',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 14),

                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _deals.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final deal = _deals[index];
                    return _buildDealCard(deal, isDesktop);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFFE53935), Color(0xFFC62828), Color(0xFF8E0000)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE53935).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'قوة الشراء الجماعي • توفير مباشر 40%',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'اشترِ مع جيرانك وأصحابك ووفر نصف السعر!',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                ),
                const SizedBox(height: 6),
                const Text(
                  'عند اكتمال عدد المشترين المطلوب في المجموعة خلال الوقت المحدد، يحصل الجميع على خصم الجملة الاستثنائي مع توصيل مجاني لكل منزل.',
                  style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.groups_rounded, color: Colors.white, size: 44),
          ),
        ],
      ),
    );
  }

  Widget _buildDealCard(GroupDealItem deal, bool isDesktop) {
    final progress = deal.currentMembers / deal.requiredMembers;
    final isFull = deal.currentMembers >= deal.requiredMembers;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: CachedNetworkImage(
                  imageUrl: deal.product.firstImage,
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Container(
                    width: 90,
                    height: 90,
                    color: AppColors.background,
                    child: const Icon(Icons.shopping_basket_outlined, color: AppColors.textMuted),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Title, Badge, Timer
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(
                            'خصم جماعي ${deal.discountPercent}%',
                            style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                        const Spacer(),
                        // Timer
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.timer_outlined, color: AppColors.accent, size: 13),
                              const SizedBox(width: 4),
                              Text(
                                _formatTimer(deal.secondsRemaining),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      deal.product.nameAr,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '${deal.groupPrice.toStringAsFixed(2)} ل.س',
                          style: const TextStyle(
                            color: Color(0xFFE53935),
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${deal.singlePrice.toStringAsFixed(2)} ل.س فردي',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            decoration: TextDecoration.lineThrough,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Member Progress Bar & Avatars
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isFull 
                        ? '🎉 اكتمل الفريق بنجاح! تم تثبيت سعر الخصم'
                        : 'انضم ${deal.currentMembers} من أصل ${deal.requiredMembers} أعضاء مطلوبين',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isFull ? Colors.green.shade700 : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(isFull ? Colors.green : const Color(0xFFE53935)),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
                const SizedBox(height: 8),
                Text(
                  'المشاركون: ${deal.memberNames.join(" • ")}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _shareDeal(deal),
                  icon: const Icon(Icons.share_outlined, size: 16),
                  label: const Text('دعوة أصدقاء', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () => _joinDeal(deal),
                  icon: const Icon(Icons.group_add_rounded, size: 18),
                  label: Text(
                    isFull ? 'شراء بسعر المجموعة' : 'انضم للفريق الآن (${deal.groupPrice} ل.س)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
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
