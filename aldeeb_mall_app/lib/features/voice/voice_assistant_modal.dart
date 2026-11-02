import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/product_model.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/providers/mall_provider.dart';
import '../../core/providers/store_settings_provider.dart';
import '../cart/cart_screen.dart';

class VoiceAssistantModal extends StatefulWidget {
  const VoiceAssistantModal({super.key});

  /// Shows the voice modal and returns a search query if selected
  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
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
  late final AnimationController _rippleCtrl;
  final TextEditingController _textCtrl = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isSpeechAvailable = false;
  bool _isListening = false;
  String _statusMessage = 'جاري تهيئة الميكروفون الذكي...';
  String _currentQuery = '';
  List<ProductModel> _matchedProducts = [];
  bool _hasSearched = false;
  bool _isPermissionDenied = false;
  Timer? _stopTimer;

  @override
  void initState() {
    super.initState();
    _rippleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _initSpeechRecognizer();
  }

  @override
  void dispose() {
    _stopTimer?.cancel();
    _rippleCtrl.dispose();
    _textCtrl.dispose();
    if (_isListening) {
      _speech.stop();
    }
    super.dispose();
  }

  Future<void> _initSpeechRecognizer() async {
    try {
      final micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) {
        if (mounted) {
          setState(() {
            _isPermissionDenied = true;
            _statusMessage = 'يرجى منح إذن الميكروفون لاستخدام البحث الصوتي المباشر';
          });
        }
        return;
      }

      final available = await _speech.initialize(
        onError: _handleSpeechError,
        onStatus: _handleSpeechStatus,
      );

      if (mounted) {
        setState(() {
          _isSpeechAvailable = available;
          if (available) {
            _statusMessage = 'الميكروفون جاهز! اضغط على الميكروفون للتحدث';
            _startListening();
          } else {
            _statusMessage = 'التعرف على الصوت غير مدعوم على جهازك حالياً. يمكنك استخدام الأوامر الجاهزة أو الكتابة';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSpeechAvailable = false;
          _statusMessage = 'تعذر تشغيل خدمة الصوت. يمكنك استخدام الأوامر السريعة أو الكتابة أدناه';
        });
      }
    }
  }

  void _handleSpeechError(SpeechRecognitionError error) {
    if (!mounted) return;
    setState(() {
      _isListening = false;
      if (error.errorMsg == 'error_no_match') {
        _statusMessage = 'لم يتم تمييز الكلمات، يرجى إعادة التحدث بوضوح';
      } else {
        _statusMessage = 'توقف الاستماع: ${error.errorMsg}';
      }
    });
  }

  void _handleSpeechStatus(String status) {
    if (!mounted) return;
    if (status == 'listening') {
      setState(() {
        _isListening = true;
        _statusMessage = 'جاري الاستماع لصوتك الآن... قل ما تريده';
      });
    } else if (status == 'notListening' || status == 'done') {
      setState(() => _isListening = false);
      if (_currentQuery.trim().isNotEmpty) {
        _executeSearch(_currentQuery);
      }
    }
  }

  Future<void> _startListening() async {
    if (!_isSpeechAvailable) {
      await _initSpeechRecognizer();
      if (!_isSpeechAvailable) return;
    }

    HapticFeedback.lightImpact();
    setState(() {
      _isListening = true;
      _statusMessage = 'جاري الاستماع لصوتك الآن... قل ما تريده';
      _currentQuery = '';
      _textCtrl.clear();
      _matchedProducts = [];
      _hasSearched = false;
    });

    try {
      // Look for Arabic SA locale or system default
      final locales = await _speech.locales();
      final arLocale = locales.where((l) => l.localeId.toLowerCase().startsWith('ar')).firstOrNull;
      final localeId = arLocale?.localeId ?? 'ar_SA';

      await _speech.listen(
        onResult: (result) {
          if (!mounted) return;
          final words = result.recognizedWords.trim();
          setState(() {
            _currentQuery = words;
            _textCtrl.text = words;
            _statusMessage = 'أنت تقول: "$words"';
          });

          // Reset silence stop timer
          _stopTimer?.cancel();
          if (result.finalResult) {
            _executeSearch(words);
          } else {
            _stopTimer = Timer(const Duration(milliseconds: 1400), () {
              if (mounted && _isListening && _currentQuery.isNotEmpty) {
                _stopListening();
              }
            });
          }
        },
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.search,
          cancelOnError: false,
          partialResults: true,
          localeId: localeId,
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _isListening = false);
      }
    }
  }

  Future<void> _stopListening() async {
    _stopTimer?.cancel();
    try {
      await _speech.stop();
    } catch (_) {}
    if (mounted) {
      setState(() => _isListening = false);
      if (_currentQuery.trim().isNotEmpty) {
        _executeSearch(_currentQuery);
      }
    }
  }

  void _executeSearch(String rawText) {
    final mall = Provider.of<MallProvider>(context, listen: false);
    final cart = Provider.of<CartProvider>(context, listen: false);

    // Clean common vocal prefixes in Arabic
    String query = rawText.trim();
    final lower = query.toLowerCase();

    final isAddIntent = lower.contains('أضف') ||
        lower.contains('اضف') ||
        lower.contains('حط بالسل') ||
        lower.contains('للسل') ||
        lower.contains('اشتري') ||
        lower.contains('طلب');

    // Strip vocal phrases
    final stripped = query
        .replaceAll(RegExp(r'^(أضف|اضف|ابحث عن|ابحث لي عن|بدي|أريد|اشتري|دور على|شوف لي)\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s*(إلى السلة|في السلة|للسلتي|للسلة|بالسلة)\s*$', caseSensitive: false), '')
        .trim();

    final searchTerm = stripped.isNotEmpty ? stripped : query;

    // Search in loaded products
    final tokens = searchTerm.toLowerCase().split(' ').where((t) => t.length > 1).toList();
    final matches = mall.products.where((p) {
      final nameAr = p.nameAr.toLowerCase();
      final nameEn = p.nameEn.toLowerCase();
      final brand = (p.brand ?? '').toLowerCase();
      final desc = (p.descriptionAr ?? '').toLowerCase();

      if (nameAr.contains(searchTerm.toLowerCase()) ||
          nameEn.contains(searchTerm.toLowerCase()) ||
          brand.contains(searchTerm.toLowerCase())) {
        return true;
      }
      return tokens.any((t) => nameAr.contains(t) || brand.contains(t) || desc.contains(t));
    }).toList();

    // Auto-add to cart if user explicitly said "أضف" and items were found
    if (isAddIntent && matches.isNotEmpty) {
      cart.addToCart(matches.first);
      HapticFeedback.mediumImpact();
    }

    setState(() {
      _currentQuery = searchTerm;
      _textCtrl.text = searchTerm;
      _matchedProducts = matches;
      _hasSearched = true;
      if (matches.isNotEmpty) {
        _statusMessage = isAddIntent
            ? 'تمت إضافة "${matches.first.nameAr}" للسلّة، وتطابق ${matches.length} صنف!'
            : 'تم العثور على ${matches.length} صنف يطابق بحثك الصوتي';
      } else {
        _statusMessage = 'لم يتم العثور على أصناف تطابق "$searchTerm"';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<StoreSettingsProvider>(context);
    final cart = Provider.of<CartProvider>(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: settings.primaryColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.mic_rounded, color: settings.primaryColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'البحث والمساعد الصوتي الفعلي',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textPrimary),
                      ),
                      Text(
                        'تحدث باسم المنتج، الماركة، أو قل "أضف حليب للسلّة"',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Animated Voice Ripple / Mic Button
                  GestureDetector(
                    onTap: () {
                      if (_isListening) {
                        _stopListening();
                      } else {
                        _startListening();
                      }
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_isListening)
                          AnimatedBuilder(
                            animation: _rippleCtrl,
                            builder: (ctx, child) {
                              return Container(
                                width: 90 + (_rippleCtrl.value * 30),
                                height: 90 + (_rippleCtrl.value * 30),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: settings.primaryColor.withValues(alpha: 0.18 * (1.0 - _rippleCtrl.value)),
                                ),
                              );
                            },
                          ),
                        Container(
                          width: 74,
                          height: 74,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _isListening
                                  ? [settings.primaryColor, settings.accentColor]
                                  : [settings.primaryColor, AppColors.primaryDark],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: settings.primaryColor.withValues(alpha: _isListening ? 0.45 : 0.25),
                                blurRadius: _isListening ? 18 : 10,
                                spreadRadius: _isListening ? 3 : 1,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isListening ? Icons.graphic_eq_rounded : Icons.mic_rounded,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Listening Status / Action prompt
                  Text(
                    _isListening ? 'اضغط لإيقاف الاستماع والبحث فوراً' : 'اضغط على الميكروفون للتحدث من جديد',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: _isListening ? settings.primaryColor : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Speech output & Manual correction input bar
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isListening ? settings.primaryColor : AppColors.border,
                        width: 1.2,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _textCtrl,
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(
                              hintText: _isListening ? 'جاري الاستماع...' : 'اكتب أو عدّل الكلمات هنا...',
                              hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            onSubmitted: (val) {
                              if (val.trim().isNotEmpty) {
                                _executeSearch(val);
                              }
                            },
                          ),
                        ),
                        if (_textCtrl.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 18, color: AppColors.textMuted),
                            onPressed: () {
                              _textCtrl.clear();
                              setState(() {
                                _currentQuery = '';
                                _matchedProducts = [];
                                _hasSearched = false;
                                _statusMessage = 'الميكروفون جاهز! اضغط على الميكروفون للتحدث';
                              });
                            },
                          ),
                        ElevatedButton(
                          onPressed: () {
                            if (_textCtrl.text.trim().isNotEmpty) {
                              _executeSearch(_textCtrl.text);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: settings.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('بحث', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Status line
                  Text(
                    _statusMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: _hasSearched ? FontWeight.bold : FontWeight.w500,
                      color: _isPermissionDenied
                          ? Colors.redAccent
                          : (_hasSearched && _matchedProducts.isNotEmpty ? AppColors.freshGreen : AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Matched products list (if any found)
                  if (_hasSearched && _matchedProducts.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'الأصناف المتطابقة (${_matchedProducts.length}):',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                              ),
                              Text(
                                'اضغط لإضافة أي صنف',
                                style: TextStyle(fontSize: 10.5, color: settings.primaryColor, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _matchedProducts.take(4).length,
                            separatorBuilder: (ctx, i) => const Divider(height: 12),
                            itemBuilder: (ctx, i) {
                              final p = _matchedProducts[i];
                              return Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl: p.firstImage,
                                      width: 44,
                                      height: 44,
                                      fit: BoxFit.cover,
                                      errorWidget: (ctx, u, e) => Container(
                                        width: 44,
                                        height: 44,
                                        color: AppColors.background,
                                        child: const Icon(Icons.shopping_bag_outlined, size: 20),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.nameAr,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '${p.price.toStringAsFixed(0)} ${settings.currency} • ${p.unitLabelAr}',
                                          style: TextStyle(fontSize: 11, color: settings.primaryColor, fontWeight: FontWeight.w700),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      cart.addToCart(p);
                                      HapticFeedback.lightImpact();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('تمت إضافة "${p.nameAr}" للسلّة!'),
                                          duration: const Duration(seconds: 1),
                                          backgroundColor: AppColors.primaryDark,
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.add, size: 14),
                                    label: const Text('أضف', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: settings.primaryColor,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      minimumSize: Size.zero,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Quick Voice Prompts
                  const Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      'أوامر صوتية جاهزة للتجربة المباشرة:',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _commandChip('حليب المراعي طازج'),
                      _commandChip('أرز بسمتي فاخر'),
                      _commandChip('طماطم مزارع طازجة'),
                      _commandChip('دجاج مبرد وطني'),
                      _commandChip('أضف زيت زيتون للسلّة'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Primary Action Buttons
          Row(
            children: [
              // Apply search to Home Page
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _currentQuery.trim().isNotEmpty
                      ? () {
                          Navigator.pop(context, _currentQuery.trim());
                        }
                      : null,
                  icon: const Icon(Icons.search_rounded, size: 18),
                  label: Text(
                    _matchedProducts.isNotEmpty
                        ? 'عرض النتائج في الرئيسية (${_matchedProducts.length})'
                        : 'تطبيق البحث في الرئيسية',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: settings.primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade500,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              if (cart.items.isNotEmpty) ...[
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CartScreen()),
                    );
                  },
                  icon: Badge(
                    label: Text('${cart.itemCount}'),
                    child: const Icon(Icons.shopping_cart_rounded, color: Colors.white, size: 20),
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    padding: const EdgeInsets.all(12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _commandChip(String prompt) {
    return InkWell(
      onTap: () {
        _textCtrl.text = prompt;
        _executeSearch(prompt);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.record_voice_over_outlined, size: 13, color: AppColors.primary),
            const SizedBox(width: 5),
            Text(prompt, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}
