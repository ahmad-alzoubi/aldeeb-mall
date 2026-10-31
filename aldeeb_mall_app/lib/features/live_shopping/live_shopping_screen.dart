import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/product_model.dart';
import '../../core/providers/cart_provider.dart';

class LiveChatMessage {
  final String id;
  final String userName;
  final String text;
  final bool isHostOrMod;
  final String time;

  const LiveChatMessage({
    required this.id,
    required this.userName,
    required this.text,
    this.isHostOrMod = false,
    required this.time,
  });
}

class LiveShoppingScreen extends StatefulWidget {
  const LiveShoppingScreen({super.key});

  @override
  State<LiveShoppingScreen> createState() => _LiveShoppingScreenState();
}

class _LiveShoppingScreenState extends State<LiveShoppingScreen> with SingleTickerProviderStateMixin {
  int _viewerCount = 1842;
  int _likesCount = 9420;
  bool _isFollowing = false;
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  late final List<ProductModel> _streamProducts;
  int _activeProductIndex = 0;

  final List<LiveChatMessage> _chatMessages = [
    const LiveChatMessage(
      id: 'c1',
      userName: 'أم خالد',
      text: 'ما شاء الله، اللحم طازج وواضح جودته! هل التوصيل اليوم؟',
      time: '10:02',
    ),
    const LiveChatMessage(
      id: 'c2',
      userName: 'مشرف الديب مول',
      text: 'أهلاً أم خالد، نعم التوصيل خلال 15 دقيقة فقط في الرياض عبر أسطولنا المبرد!',
      isHostOrMod: true,
      time: '10:02',
    ),
    const LiveChatMessage(
      id: 'c3',
      userName: 'سعود التميمي',
      text: 'كوبون LIVE30 شغال على اللحوم والفواكه؟',
      time: '10:03',
    ),
    const LiveChatMessage(
      id: 'c4',
      userName: 'الشيف نورة',
      text: 'نعم يا سعود، استخدم كود LIVE30 لتحصل على خصم 30% فوري طوال فترة البث فقط!',
      isHostOrMod: true,
      time: '10:03',
    ),
    const LiveChatMessage(
      id: 'c5',
      userName: 'سارة العتيبي',
      text: 'طلبت الآن صينية اللحم والبهارات وصلتني رسالة تأكيد فورا 👏',
      time: '10:04',
    ),
  ];

  Timer? _simulatedChatTimer;
  Timer? _viewersFluctuationTimer;

  // Floating Reactions
  final List<Key> _reactionKeys = [];

  @override
  void initState() {
    super.initState();
    _initStreamProducts();
    _startSimulations();
  }

  @override
  void dispose() {
    _simulatedChatTimer?.cancel();
    _viewersFluctuationTimer?.cancel();
    _commentController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  void _initStreamProducts() {
    _streamProducts = [
      const ProductModel(
        id: 'LIVE-001',
        nameAr: 'كتف خروف نعيمي طازج مقطع كبسة (1.5 كجم)',
        nameEn: 'Fresh Nuaimi Lamb Shoulder 1.5kg',
        descriptionAr: 'لحم نعيمي بلدي طازج ذبح اليوم فجراً، بإشراف أطباء بيطريين معتمدين',
        price: 89.0,
        originalPrice: 135.0,
        discountPercent: 34,
        images: ['https://images.unsplash.com/photo-1607623814075-e51df1bdc82f?w=600&q=80'],
        categoryId: 'لحوم طازجة',
        stockQuantity: 18,
      ),
      const ProductModel(
        id: 'LIVE-002',
        nameAr: 'أرز بسمتي الشعلان عنبر كلاسيك فاخر (5 كجم)',
        nameEn: 'Al Shalan Amber Classic Basmati Rice 5kg',
        descriptionAr: 'أرز أبيض طويل الحبة برائحة عنبرية زكية، حبة نقية وممتازة للعزائم',
        price: 36.5,
        originalPrice: 52.0,
        discountPercent: 30,
        images: ['https://images.unsplash.com/photo-1586201375761-83865001e31c?w=600&q=80'],
        categoryId: 'تموين وبقالة',
        stockQuantity: 45,
      ),
      const ProductModel(
        id: 'LIVE-003',
        nameAr: 'بهارات الكبسة النجدية الأصلية المطحونة (250غ)',
        nameEn: 'Authentic Najdi Kabsa Spices Blend 250g',
        descriptionAr: 'خلطة سرية معتقة بالهيل واللومي والقرفة والقرنفل من عطارة الديب',
        price: 14.0,
        originalPrice: 22.0,
        discountPercent: 36,
        images: ['https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=600&q=80'],
        categoryId: 'بهارات وتوابل',
        stockQuantity: 30,
      ),
      const ProductModel(
        id: 'LIVE-004',
        nameAr: 'سمن بقر بري القصيم نقي فاخر (800غ)',
        nameEn: 'Pure Qassim Cow Ghee 800g',
        descriptionAr: 'سمن بلدي طبيعي 100% مستخلص من زبدة الأبقار الطازجة',
        price: 42.0,
        originalPrice: 65.0,
        discountPercent: 35,
        images: ['https://images.unsplash.com/photo-1628088062854-d1870b4553da?w=600&q=80'],
        categoryId: 'زيوت وسمن',
        stockQuantity: 22,
      ),
    ];
  }

  void _startSimulations() {
    // Fluctuating viewers
    _viewersFluctuationTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          _viewerCount += (timer.tick % 2 == 0) ? 7 : -3;
        });
      }
    });

    // Simulated new incoming messages
    final automatedResponses = [
      'روعة العرض، تم الطلب بالسلة الآن!',
      'هل يتوفر دفع عند الاستلام؟',
      'شكراً شيف نورة على النصائح الذهبية',
      'الكود LIVE30 اشتغل وخصم لي 45 ريال 🥳',
      'اللحم نعيمي بلدي مضمون؟',
      'أفضل تجربة بث حي في تطبيقات التسوق والله',
    ];
    int msgIdx = 0;
    _simulatedChatTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && msgIdx < automatedResponses.length) {
        setState(() {
          _chatMessages.add(
            LiveChatMessage(
              id: 'c_${DateTime.now().millisecondsSinceEpoch}',
              userName: ['فيصل السبيعي', 'نوف الشمري', 'سلطان الدوسري', 'ريما الحربي'][msgIdx % 4],
              text: automatedResponses[msgIdx % automatedResponses.length],
              time: '10:${05 + msgIdx}',
            ),
          );
        });
        msgIdx++;
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSendMessage() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _chatMessages.add(
        LiveChatMessage(
          id: 'my_${DateTime.now().millisecondsSinceEpoch}',
          userName: 'أنت',
          text: text,
          time: 'الآن',
        ),
      );
      _commentController.clear();
    });
    _scrollToBottom();
  }

  void _triggerLikeReaction() {
    setState(() {
      _likesCount += 1;
      _reactionKeys.add(UniqueKey());
    });
    if (_reactionKeys.length > 15) {
      _reactionKeys.removeAt(0);
    }
  }

  void _showAllProductsModal() {
    final cart = Provider.of<CartProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.shopping_bag_rounded, color: AppColors.primary, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'منتجات هذا البث المباشر (${_streamProducts.length})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'كوبون LIVE30',
                        style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _streamProducts.length,
                  separatorBuilder: (context, index) => const Divider(height: 16),
                  itemBuilder: (context, idx) {
                    final p = _streamProducts[idx];
                    final isCurrentActive = idx == _activeProductIndex;

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CachedNetworkImage(
                            imageUrl: p.firstImage,
                            width: 75,
                            height: 75,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isCurrentActive)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade600,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'يُعرض الآن على الهواء',
                                    style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              Text(
                                p.nameAr,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    '${p.price.toStringAsFixed(2)} ر.س',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                      color: AppColors.freshGreen,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (p.originalPrice != null)
                                    Text(
                                      '${p.originalPrice!.toStringAsFixed(2)} ر.س',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            cart.addToCart(p);
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('تمت إضافة "${p.nameAr}" بالسعر الحصري للبث!'),
                                backgroundColor: AppColors.freshGreen,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text(
                            'إضافة',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final activeProduct = _streamProducts[_activeProductIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Full-screen Video Stream Simulator / Animated Backdrop
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0F172A),
                  Color(0xFF1E1B4B),
                  Color(0xFF1E293B),
                  Color(0xFF0F172A),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Cooking broadcast background image with subtle darkening
                CachedNetworkImage(
                  imageUrl: 'https://images.unsplash.com/photo-1556910103-1c02745aae4d?w=1200&q=80',
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.black),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.6),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.85),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.4, 0.85],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Top Header Bar (Host info, Live pill, Viewers, Close)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Host Profile Pill
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 18,
                          backgroundImage: CachedNetworkImageProvider(
                            'https://images.unsplash.com/photo-1577219491135-ce391730fb2c?w=120&q=80',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Row(
                              children: [
                                Text(
                                  'الشيف نورة 👩‍🍳',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.verified, color: Colors.blueAccent, size: 14),
                              ],
                            ),
                            Text(
                              'مطبخ الديب الحي',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 10),
                            ),
                          ],
                        ),
                        const SizedBox(width: 10),
                        // Follow button
                        InkWell(
                          onTap: () {
                            setState(() {
                              _isFollowing = !_isFollowing;
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _isFollowing ? Colors.white24 : AppColors.accent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _isFollowing ? 'متابع' : 'متابعة +',
                              style: TextStyle(
                                color: _isFollowing ? Colors.white : AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Live & Viewers Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.fiber_manual_record, color: Colors.white, size: 10),
                        SizedBox(width: 4),
                        Text(
                          'مباشر',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.remove_red_eye_outlined, color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          _viewerCount.toString(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Close Button
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),

          // 3. Live Coupon Promotion Ribbon
          Positioned(
            top: 100,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE11D48), Color(0xFFBE123C)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 6),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.local_offer_rounded, color: AppColors.accent, size: 15),
                  SizedBox(width: 6),
                  Text(
                    'كوبون البث LIVE30: خصم 30% فوري على كل طلبات البث',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),

          // 4. Live Chat Comments Stream (Scrollable)
          Positioned(
            left: 16,
            right: 90,
            bottom: 180,
            height: 200,
            child: ShaderMask(
              shaderCallback: (bounds) {
                return const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.white],
                  stops: [0.0, 0.25],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: ListView.builder(
                controller: _chatScrollController,
                itemCount: _chatMessages.length,
                itemBuilder: (context, index) {
                  final msg = _chatMessages[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: msg.isHostOrMod
                          ? const Color(0xFF1E3A8A).withValues(alpha: 0.8)
                          : Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(12),
                      border: msg.isHostOrMod ? Border.all(color: Colors.blue.shade400) : null,
                    ),
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${msg.userName}: ',
                            style: TextStyle(
                              color: msg.isHostOrMod ? AppColors.accent : Colors.amber.shade300,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          TextSpan(
                            text: msg.text,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // 5. Floating Active Product Card (Pinned to Screen)
          Positioned(
            left: 16,
            right: 16,
            bottom: 75,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Product Image & Active Live Badge
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl: activeProduct.firstImage,
                          width: 65,
                          height: 65,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.shade600,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'مباشر',
                            style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activeProduct.nameAr,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text(
                              '${activeProduct.price.toStringAsFixed(2)} ر.س',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                color: AppColors.freshGreen,
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (activeProduct.originalPrice != null)
                              Text(
                                '${activeProduct.originalPrice!.toStringAsFixed(2)} ر.س',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '-${activeProduct.discountPercent}%',
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Next Product cycle button
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                    tooltip: 'المنتج التالي',
                    onPressed: () {
                      setState(() {
                        _activeProductIndex = (_activeProductIndex + 1) % _streamProducts.length;
                      });
                    },
                  ),

                  // 1-Tap Purchase Button
                  ElevatedButton(
                    onPressed: () {
                      cart.addToCart(activeProduct);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('تمت إضافة "${activeProduct.nameAr}" لسلتك بسعر البث المخفض!'),
                          backgroundColor: AppColors.freshGreen,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'شراء فوري',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 6. Bottom Interaction Bar
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Row(
              children: [
                // Products Catalog Bag Button
                InkWell(
                  onTap: _showAllProductsModal,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 6),
                      ],
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 22),
                        Positioned(
                          top: -6,
                          right: -6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              _streamProducts.length.toString(),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Chat Input Field
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: const InputDecoration(
                              hintText: 'اسأل الشيف نورة أو اطلب كود خصم...',
                              hintStyle: TextStyle(color: Colors.white60, fontSize: 12),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 10),
                            ),
                            onSubmitted: (_) => _handleSendMessage(),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send_rounded, color: AppColors.accent, size: 20),
                          onPressed: _handleSendMessage,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Floating Reactions Heart / Like Button
                InkWell(
                  onTap: _triggerLikeReaction,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(color: Colors.red.withValues(alpha: 0.4), blurRadius: 6),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.favorite_rounded, color: Colors.white, size: 22),
                        const SizedBox(width: 4),
                        Text(
                          _likesCount > 1000 ? '${(_likesCount / 1000).toStringAsFixed(1)}k' : '$_likesCount',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ],
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
}
