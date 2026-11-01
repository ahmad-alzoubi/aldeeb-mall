import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../services/supabase_service.dart';

class ThemePreset {
  final String key;
  final String nameAr;
  final Color primary;
  final Color primaryDark;
  final Color secondary;
  final Color accent;
  final Color background;
  final Color surface;
  final Color textPrimary;

  const ThemePreset({
    required this.key,
    required this.nameAr,
    required this.primary,
    required this.primaryDark,
    required this.secondary,
    required this.accent,
    required this.background,
    required this.surface,
    required this.textPrimary,
  });
}

class StoreSettingsProvider extends ChangeNotifier {
  static const String _prefKey = 'aldeeb_store_theme_settings_v1';

  // Available Presets
  static final List<ThemePreset> presets = [
    const ThemePreset(
      key: 'royal_blue',
      nameAr: 'أزرق كارفور رويال الملكي (الافتراضي)',
      primary: Color(0xFF0D47A1),
      primaryDark: Color(0xFF0A2E6B),
      secondary: Color(0xFFE53935),
      accent: Color(0xFFFFB300),
      background: Color(0xFFF8FAFC),
      surface: Color(0xFFFFFFFF),
      textPrimary: Color(0xFF0F172A),
    ),
    const ThemePreset(
      key: 'emerald_green',
      nameAr: 'أخضر الديب الزمردي العضوي',
      primary: Color(0xFF059669),
      primaryDark: Color(0xFF064E3B),
      secondary: Color(0xFFEA580C),
      accent: Color(0xFFF59E0B),
      background: Color(0xFFF0FDF4),
      surface: Color(0xFFFFFFFF),
      textPrimary: Color(0xFF064E3B),
    ),
    const ThemePreset(
      key: 'ruby_red',
      nameAr: 'عنابي نون إكسبريس الحصري',
      primary: Color(0xFFBE123C),
      primaryDark: Color(0xFF881337),
      secondary: Color(0xFF2563EB),
      accent: Color(0xFFFBBF24),
      background: Color(0xFFFFF1F2),
      surface: Color(0xFFFFFFFF),
      textPrimary: Color(0xFF1E1E24),
    ),
    const ThemePreset(
      key: 'purple_luxury',
      nameAr: 'أرجواني الديب بريميوم الفاخر',
      primary: Color(0xFF6D28D9),
      primaryDark: Color(0xFF4C1D95),
      secondary: Color(0xFF059669),
      accent: Color(0xFFF59E0B),
      background: Color(0xFFF5F3FF),
      surface: Color(0xFFFFFFFF),
      textPrimary: Color(0xFF1F1D2B),
    ),
  ];

  // Colors
  Color _primaryColor = const Color(0xFF0D47A1);
  Color _primaryDarkColor = const Color(0xFF0A2E6B);
  Color _secondaryColor = const Color(0xFFE53935);
  Color _accentColor = const Color(0xFFFFB300);
  Color _backgroundColor = const Color(0xFFF8FAFC);
  Color _surfaceColor = const Color(0xFFFFFFFF);
  Color _textPrimaryColor = const Color(0xFF0F172A);
  Color _textSecondaryColor = const Color(0xFF64748B);

  // Store Brand Texts
  String _storeNameAr = 'الديب مول';
  String _storeNameEn = 'Aldeeb Mall';
  String _taglineAr = 'هايبرماركت العائلة الأول - جودة وتوفير بلا حدود';
  String _announcementBarText = '🚚 توصيل مجاني للطلبات فوق 100 ل.س | صفقات حصرية يومياً';
  String _expressDeliveryText = 'توصيل إكسبريس فوري خلال 15 دقيقة ⚡';
  String _smartExperiencesTitle = 'تجارب الديب الذكية';
  String _smartExperiencesSubtitle = 'وفّر مع الجيران، ونظّم مقاضيك الشهرية بذكاء وسرعة';
  String _groupDealsTitle = 'الشراء الجماعي الذكي';
  String _groupDealsSubtitle = 'وفّر حتى 40% مع عروض الجيران التشاركية الحية';
  String _groceryListTitle = 'القائمة الذكية ومخطط المقاضي';
  String _groceryListSubtitle = 'تنظيم ومزامنة المقاضي العائلية بذكاء';
  String _currency = 'ل.س';
  bool _enableProductBundles = true;

  // Getters
  Color get primaryColor => _primaryColor;
  Color get primaryDarkColor => _primaryDarkColor;
  Color get secondaryColor => _secondaryColor;
  Color get accentColor => _accentColor;
  Color get backgroundColor => _backgroundColor;
  Color get surfaceColor => _surfaceColor;
  Color get textPrimaryColor => _textPrimaryColor;
  Color get textSecondaryColor => _textSecondaryColor;

  String get storeNameAr => _storeNameAr;
  String get storeNameEn => _storeNameEn;
  String get taglineAr => _taglineAr;
  String get announcementBarText => _announcementBarText;
  String get expressDeliveryText => _expressDeliveryText;
  String get smartExperiencesTitle => _smartExperiencesTitle;
  String get smartExperiencesSubtitle => _smartExperiencesSubtitle;
  String get groupDealsTitle => _groupDealsTitle;
  String get groupDealsSubtitle => _groupDealsSubtitle;
  String get groceryListTitle => _groceryListTitle;
  String get groceryListSubtitle => _groceryListSubtitle;
  String get currency => _currency;
  bool get enableProductBundles => _enableProductBundles;

  Timer? _syncTimer;

  static Color _parseColor(dynamic val, Color fallback) {
    if (val == null) return fallback;
    if (val is int) return Color(val);
    if (val is String) {
      String hex = val.replaceAll('#', '').trim();
      if (hex.length == 6) {
        hex = 'FF$hex';
      }
      final intVal = int.tryParse(hex, radix: 16);
      if (intVal != null) return Color(intVal);
    }
    return fallback;
  }

  static String _colorToHex(Color color) {
    final hex = color.toARGB32().toRadixString(16).padLeft(8, '0');
    return '#${hex.substring(2).toUpperCase()}';
  }

  StoreSettingsProvider() {
    loadSettings();
    _startPeriodicSync();
  }

  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      syncFromApi();
    });
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  // Load from local storage, shared LAN API, or Supabase cloud
  Future<void> loadSettings() async {
    // 1. Load cached preferences first for zero-delay startup
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_prefKey);
      if (jsonStr != null) {
        final Map<String, dynamic> data = jsonDecode(jsonStr);
        _applyMap(data);
        notifyListeners();
      }
    } catch (_) {}

    // 2. Sync from shared backend API
    await syncFromApi();

    // 3. Sync from Supabase if connected
    await syncFromSupabase();
  }

  Future<void> syncFromApi() async {
    try {
      final baseHost = kIsWeb ? (Uri.base.host.isNotEmpty ? Uri.base.host : 'localhost') : 'localhost';
      List<Uri> candidateUris = [];
      if (kIsWeb) {
        candidateUris.add(Uri.parse('/api/store_settings'));
        candidateUris.add(Uri.parse('http://$baseHost:8080/api/store_settings'));
        candidateUris.add(Uri.parse('http://$baseHost:3000/api/store_settings'));
      } else {
        candidateUris.add(Uri.parse('http://localhost:8080/api/store_settings'));
        candidateUris.add(Uri.parse('http://localhost:3000/api/store_settings'));
      }

      for (final uri in candidateUris) {
        try {
          final res = await http.get(uri).timeout(const Duration(milliseconds: 1500));
          if (res.statusCode == 200 && res.body.isNotEmpty) {
            final Map<String, dynamic> data = jsonDecode(res.body);
            if (data.isNotEmpty) {
              final changed = _applyMap(data);
              if (changed) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString(_prefKey, jsonEncode(toMap()));
                notifyListeners();
              }
              break;
            }
          }
        } catch (_) {}
      }
    } catch (_) {}
  }

  Future<void> syncFromSupabase() async {
    final supabase = SupabaseService();
    if (supabase.isConnected && supabase.client != null) {
      try {
        final res = await supabase.client!
            .from('store_settings')
            .select()
            .eq('id', 'active_theme')
            .maybeSingle();
        if (res != null && res['settings'] != null) {
          final changed = _applyMap(Map<String, dynamic>.from(res['settings']));
          if (changed) {
            notifyListeners();
          }
        }
      } catch (_) {}
    }
  }

  bool _applyMap(Map<String, dynamic> data) {
    final prevPrimary = _primaryColor;
    final prevName = _storeNameAr;

    _primaryColor = _parseColor(data['primaryColor'] ?? data['primaryColorValue'], _primaryColor);
    _primaryDarkColor = _parseColor(data['primaryDarkColor'] ?? data['primaryDarkColorValue'], _primaryDarkColor);
    _secondaryColor = _parseColor(data['secondaryColor'] ?? data['secondaryColorValue'], _secondaryColor);
    _accentColor = _parseColor(data['accentColor'] ?? data['accentColorValue'], _accentColor);
    _backgroundColor = _parseColor(data['backgroundColor'] ?? data['backgroundColorValue'], _backgroundColor);
    _surfaceColor = _parseColor(data['surfaceColor'] ?? data['surfaceColorValue'], _surfaceColor);
    _textPrimaryColor = _parseColor(data['textPrimaryColor'] ?? data['textPrimaryColorValue'], _textPrimaryColor);
    _textSecondaryColor = _parseColor(data['textSecondaryColor'] ?? data['textSecondaryColorValue'], _textSecondaryColor);

    if (data['storeNameAr'] != null) _storeNameAr = data['storeNameAr'].toString();
    if (data['storeNameEn'] != null) _storeNameEn = data['storeNameEn'].toString();
    if (data['taglineAr'] != null) _taglineAr = data['taglineAr'].toString();
    if (data['announcementText'] != null) _announcementBarText = data['announcementText'].toString();
    if (data['announcementBarText'] != null) _announcementBarText = data['announcementBarText'].toString();
    if (data['expressDeliveryText'] != null) _expressDeliveryText = data['expressDeliveryText'].toString();
    if (data['smartExperiencesTitle'] != null) _smartExperiencesTitle = data['smartExperiencesTitle'].toString();
    if (data['smartExperiencesSubtitle'] != null) _smartExperiencesSubtitle = data['smartExperiencesSubtitle'].toString();
    if (data['groupDealsTitle'] != null) _groupDealsTitle = data['groupDealsTitle'].toString();
    if (data['groupDealsSubtitle'] != null) _groupDealsSubtitle = data['groupDealsSubtitle'].toString();
    if (data['groceryListTitle'] != null) _groceryListTitle = data['groceryListTitle'].toString();
    if (data['groceryListSubtitle'] != null) _groceryListSubtitle = data['groceryListSubtitle'].toString();
    if (data['currency'] != null) _currency = data['currency'].toString();
    if (data['enableProductBundles'] != null) {
      _enableProductBundles = data['enableProductBundles'] == true || data['enableProductBundles'] == 'true';
    }

    return prevPrimary != _primaryColor || prevName != _storeNameAr;
  }

  Map<String, dynamic> toMap() {
    return {
      'primaryColor': _colorToHex(_primaryColor),
      'primaryDarkColor': _colorToHex(_primaryDarkColor),
      'secondaryColor': _colorToHex(_secondaryColor),
      'accentColor': _colorToHex(_accentColor),
      'backgroundColor': _colorToHex(_backgroundColor),
      'surfaceColor': _colorToHex(_surfaceColor),
      'textPrimaryColor': _colorToHex(_textPrimaryColor),
      'textSecondaryColor': _colorToHex(_textSecondaryColor),
      'primaryColorValue': _primaryColor.toARGB32(),
      'primaryDarkColorValue': _primaryDarkColor.toARGB32(),
      'secondaryColorValue': _secondaryColor.toARGB32(),
      'accentColorValue': _accentColor.toARGB32(),
      'backgroundColorValue': _backgroundColor.toARGB32(),
      'surfaceColorValue': _surfaceColor.toARGB32(),
      'textPrimaryColorValue': _textPrimaryColor.toARGB32(),
      'textSecondaryColorValue': _textSecondaryColor.toARGB32(),
      'storeNameAr': _storeNameAr,
      'storeNameEn': _storeNameEn,
      'taglineAr': _taglineAr,
      'announcementText': _announcementBarText,
      'announcementBarText': _announcementBarText,
      'expressDeliveryText': _expressDeliveryText,
      'smartExperiencesTitle': _smartExperiencesTitle,
      'smartExperiencesSubtitle': _smartExperiencesSubtitle,
      'groupDealsTitle': _groupDealsTitle,
      'groupDealsSubtitle': _groupDealsSubtitle,
      'groceryListTitle': _groceryListTitle,
      'groceryListSubtitle': _groceryListSubtitle,
      'currency': _currency,
      'enableProductBundles': _enableProductBundles,
    };
  }

  Future<void> updateSettings({
    Color? primaryColor,
    Color? primaryDarkColor,
    Color? secondaryColor,
    Color? accentColor,
    Color? backgroundColor,
    Color? surfaceColor,
    Color? textPrimaryColor,
    Color? textSecondaryColor,
    String? storeNameAr,
    String? storeNameEn,
    String? taglineAr,
    String? announcementBarText,
    String? expressDeliveryText,
    String? smartExperiencesTitle,
    String? smartExperiencesSubtitle,
    String? groupDealsTitle,
    String? groupDealsSubtitle,
    String? groceryListTitle,
    String? groceryListSubtitle,
    String? currency,
    bool? enableProductBundles,
  }) async {
    if (primaryColor != null) _primaryColor = primaryColor;
    if (primaryDarkColor != null) _primaryDarkColor = primaryDarkColor;
    if (secondaryColor != null) _secondaryColor = secondaryColor;
    if (accentColor != null) _accentColor = accentColor;
    if (backgroundColor != null) _backgroundColor = backgroundColor;
    if (surfaceColor != null) _surfaceColor = surfaceColor;
    if (textPrimaryColor != null) _textPrimaryColor = textPrimaryColor;
    if (textSecondaryColor != null) _textSecondaryColor = textSecondaryColor;

    if (storeNameAr != null) _storeNameAr = storeNameAr;
    if (storeNameEn != null) _storeNameEn = storeNameEn;
    if (taglineAr != null) _taglineAr = taglineAr;
    if (announcementBarText != null) _announcementBarText = announcementBarText;
    if (expressDeliveryText != null) _expressDeliveryText = expressDeliveryText;
    if (smartExperiencesTitle != null) _smartExperiencesTitle = smartExperiencesTitle;
    if (smartExperiencesSubtitle != null) _smartExperiencesSubtitle = smartExperiencesSubtitle;
    if (groupDealsTitle != null) _groupDealsTitle = groupDealsTitle;
    if (groupDealsSubtitle != null) _groupDealsSubtitle = groupDealsSubtitle;
    if (groceryListTitle != null) _groceryListTitle = groceryListTitle;
    if (groceryListSubtitle != null) _groceryListSubtitle = groceryListSubtitle;
    if (currency != null) _currency = currency;
    if (enableProductBundles != null) _enableProductBundles = enableProductBundles;

    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final mapData = toMap();
      await prefs.setString(_prefKey, jsonEncode(mapData));

      // Post to shared LAN API
      try {
        final baseHost = kIsWeb ? (Uri.base.host.isNotEmpty ? Uri.base.host : 'localhost') : 'localhost';
        final uri = Uri.parse('http://$baseHost:8080/api/store_settings');
        await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(mapData),
        ).timeout(const Duration(milliseconds: 1500));
      } catch (_) {}

      final supabase = SupabaseService();
      if (supabase.isConnected && supabase.client != null) {
        await supabase.client!.from('store_settings').upsert({
          'id': 'active_theme',
          'store_name_ar': _storeNameAr,
          'store_name_en': _storeNameEn,
          'currency': _currency,
          'settings': mapData,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (_) {}
  }

  void applyPreset(String presetKey) {
    final found = presets.firstWhere(
      (p) => p.key == presetKey,
      orElse: () => presets.first,
    );
    updateSettings(
      primaryColor: found.primary,
      primaryDarkColor: found.primaryDark,
      secondaryColor: found.secondary,
      accentColor: found.accent,
      backgroundColor: found.background,
      surfaceColor: found.surface,
      textPrimaryColor: found.textPrimary,
    );
  }

  ThemeData get themeData {
    final baseTextTheme = GoogleFonts.cairoTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: _primaryColor,
      scaffoldBackgroundColor: _backgroundColor,
      colorScheme: ColorScheme.light(
        primary: _primaryColor,
        secondary: _secondaryColor,
        surface: _surfaceColor,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSurface: _textPrimaryColor,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          color: _textPrimaryColor,
          fontWeight: FontWeight.bold,
          height: 1.4,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          color: _textPrimaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 20,
          height: 1.4,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          color: _textPrimaryColor,
          fontWeight: FontWeight.w600,
          fontSize: 16,
          height: 1.4,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: _textPrimaryColor,
          fontSize: 15,
          height: 1.5,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: _textSecondaryColor,
          fontSize: 13,
          height: 1.5,
        ),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: _surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surfaceColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 14,
        ),
      ),
    );
  }
}
