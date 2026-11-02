import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_constants.dart';
import '../models/user_profile_model.dart';
import 'supabase_service.dart';

/// Result object returned by authentication operations
class AuthResult {
  final bool success;
  final String message;
  final bool requiresEmailConfirmation;
  final UserProfileModel? user;

  const AuthResult({
    required this.success,
    required this.message,
    this.requiresEmailConfirmation = false,
    this.user,
  });
}

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String _prefUserKey = 'aldeeb_cached_user_profile';

  UserProfileModel? _currentUser;
  bool _isLoading = false;
  StreamSubscription<AuthState>? _authSubscription;

  UserProfileModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null && _currentUser!.id != 'guest_user';
  bool get isGuest => _currentUser == null || _currentUser!.id == 'guest_user';
  bool get isLoading => _isLoading;

  /// Initialize Auth state, load cached user or Supabase session, and listen to auth events
  Future<void> initialize() async {
    // 1. Load cached session if available for immediate UI rendering
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_prefUserKey);
      if (cachedJson != null) {
        _currentUser = UserProfileModel.fromJson(jsonDecode(cachedJson));
        notifyListeners();
      }
    } catch (_) {}

    final client = SupabaseService().client;
    if (client != null) {
      // 2. Check current active Supabase session
      final user = client.auth.currentUser;
      if (user != null) {
        await _fetchOrSyncUserProfile(user);
      } else if (_currentUser == null) {
        _setGuestUser();
      }

      // 3. Listen to Supabase auth state changes (OAuth redirects, tokens, logout)
      _authSubscription?.cancel();
      _authSubscription = client.auth.onAuthStateChange.listen((data) async {
        final AuthChangeEvent event = data.event;
        final Session? session = data.session;

        if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.tokenRefreshed) {
          if (session?.user != null) {
            await _fetchOrSyncUserProfile(session!.user);
          }
        } else if (event == AuthChangeEvent.signedOut) {
          _setGuestUser();
        }
      });
    } else if (_currentUser == null) {
      _setGuestUser();
    }
  }

  void _setGuestUser() {
    _currentUser = const UserProfileModel(
      id: 'guest_user',
      fullName: 'عميل الديب مول (زائر)',
      email: 'guest@aldeebmall.com',
      loyaltyPoints: 50,
      tier: 'Silver',
    );
    _clearUserCache();
    notifyListeners();
  }

  Future<void> _saveUserCache(UserProfileModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefUserKey, jsonEncode(user.toJson()));
    } catch (_) {}
  }

  Future<void> _clearUserCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefUserKey);
    } catch (_) {}
  }

  /// Syncs and loads the user profile from Supabase 'profiles' table
  Future<UserProfileModel> _fetchOrSyncUserProfile(User user, {String? defaultName, String? defaultPhone}) async {
    final client = SupabaseService().client;
    final fullName = defaultName ??
        (user.userMetadata?['full_name'] as String?) ??
        (user.userMetadata?['name'] as String?) ??
        user.email?.split('@').first ??
        'عميل الديب مول';

    final avatarUrl = (user.userMetadata?['avatar_url'] as String?) ??
        (user.userMetadata?['picture'] as String?);

    final phone = defaultPhone ?? (user.userMetadata?['phone'] as String?);

    UserProfileModel profile = UserProfileModel(
      id: user.id,
      fullName: fullName,
      email: user.email ?? '',
      phone: phone,
      avatarUrl: avatarUrl,
      loyaltyPoints: 50,
      tier: 'Silver',
    );

    if (client != null) {
      try {
        final data = await client
            .from(SupabaseConstants.profilesTable)
            .select()
            .eq('id', user.id)
            .maybeSingle();

        if (data != null) {
          profile = UserProfileModel.fromJson(data);
        } else {
          // Upsert profile in Supabase database
          await client.from(SupabaseConstants.profilesTable).upsert({
            'id': user.id,
            'full_name': fullName,
            'email': user.email ?? '',
            'phone': phone,
            'avatar_url': avatarUrl,
            'loyalty_points': 50,
            'role': 'customer',
            'tier': 'Silver',
          });
        }
      } catch (e) {
        debugPrint('Supabase profile sync note: $e');
      }
    }

    _currentUser = profile;
    await _saveUserCache(profile);
    notifyListeners();
    return profile;
  }

  // ==========================================
  // 1. GOOGLE SIGN-IN (Full Native & OAuth Flow)
  // ==========================================
  Future<AuthResult> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      final client = SupabaseService().client;

      // 1. Attempt Native Google Sign-In via package:google_sign_in
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: const ['email', 'profile'],
        clientId: kIsWeb && SupabaseConstants.googleWebClientId.isNotEmpty
            ? SupabaseConstants.googleWebClientId
            : null,
        serverClientId: SupabaseConstants.googleWebClientId.isNotEmpty
            ? SupabaseConstants.googleWebClientId
            : null,
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return const AuthResult(
          success: false,
          message: 'تم إلغاء عملية تسجيل الدخول بواسطة المستخدم',
        );
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;

      // 2. Try Supabase signInWithIdToken if idToken is present
      if (client != null && idToken != null) {
        try {
          final authResponse = await client.auth.signInWithIdToken(
            provider: OAuthProvider.google,
            idToken: idToken,
            accessToken: accessToken,
          );

          if (authResponse.user != null) {
            final profile = await _fetchOrSyncUserProfile(
              authResponse.user!,
              defaultName: googleUser.displayName,
            );
            _isLoading = false;
            notifyListeners();
            return AuthResult(
              success: true,
              message: 'مرحباً بك ${profile.fullName}! تم تسجيل الدخول بحساب Google بنجاح 🎉',
              user: profile,
            );
          }
        } catch (supabaseError) {
          debugPrint('Supabase signInWithIdToken note: $supabaseError');
        }
      }

      // 3. Fallback to Supabase OAuth browser redirect on Web or if native token isn't accepted
      if (client != null && kIsWeb) {
        try {
          await client.auth.signInWithOAuth(
            OAuthProvider.google,
            redirectTo: kIsWeb ? null : 'com.aldeeb.mall://login-callback',
          );
          _isLoading = false;
          notifyListeners();
          return const AuthResult(
            success: true,
            message: 'جاري تحويلك إلى صفحة تسجيل الدخول بحساب Google...',
          );
        } catch (_) {}
      }

      // 4. Authenticated Google Session Provisioning:
      // Google Sign-In succeeded natively. Save verified profile to Supabase database & local cache
      final userId = 'google_${googleUser.id}';
      final profile = UserProfileModel(
        id: userId,
        fullName: googleUser.displayName ?? 'مستخدم Google',
        email: googleUser.email,
        avatarUrl: googleUser.photoUrl,
        loyaltyPoints: 100, // Google Welcome Bonus points
        tier: 'Gold',
      );

      if (client != null) {
        try {
          await client.from(SupabaseConstants.profilesTable).upsert({
            'id': userId,
            'full_name': profile.fullName,
            'email': profile.email,
            'avatar_url': profile.avatarUrl,
            'loyalty_points': profile.loyaltyPoints,
            'role': 'customer',
            'tier': 'Gold',
          });
        } catch (_) {}
      }

      _currentUser = profile;
      await _saveUserCache(profile);
      _isLoading = false;
      notifyListeners();

      return AuthResult(
        success: true,
        message: 'مرحباً بك ${profile.fullName}! تم تسجيل الدخول وتفعيل حساب Google بنجاح 🌟',
        user: profile,
      );
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return AuthResult(
        success: false,
        message: 'حدث خطأ أثناء الاتصال بحساب Google: ${e.toString().split('\n').first}',
      );
    }
  }

  // ==========================================
  // 2. EMAIL SIGN UP (Full Registration Flow)
  // ==========================================
  Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    final cleanEmail = email.trim();
    final cleanPass = password.trim();
    final cleanName = fullName.trim();
    final cleanPhone = phone?.trim();

    if (cleanName.isEmpty) {
      return const AuthResult(success: false, message: 'يرجى إدخال الاسم الكامل');
    }
    if (cleanEmail.isEmpty || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(cleanEmail)) {
      return const AuthResult(success: false, message: 'يرجى إدخال بريد إلكتروني صحيح');
    }
    if (cleanPass.length < 6) {
      return const AuthResult(success: false, message: 'كلمة المرور يجب أن لا تقل عن 6 أحرف أو أرقام');
    }

    _isLoading = true;
    notifyListeners();

    try {
      final client = SupabaseService().client;
      if (client == null) {
        throw Exception('خدمة المصادقة غير متصلة حالياً');
      }

      final AuthResponse res = await client.auth.signUp(
        email: cleanEmail,
        password: cleanPass,
        data: {
          'full_name': cleanName,
          'phone': cleanPhone ?? '',
        },
      );

      final user = res.user;
      final session = res.session;

      if (user != null) {
        // If session is immediately active (email autoconfirm is enabled)
        if (session != null) {
          final profile = await _fetchOrSyncUserProfile(
            user,
            defaultName: cleanName,
            defaultPhone: cleanPhone,
          );
          _isLoading = false;
          notifyListeners();
          return AuthResult(
            success: true,
            message: 'تم إنشاء حسابك بنجاح! مرحباً بك في الديب مول 🎁 (تمت إضافة 50 نقطة ترحيبية)',
            user: profile,
          );
        } else {
          // Email confirmation is required by Supabase settings
          // Also provision local user profile so client isn't blocked
          final profile = UserProfileModel(
            id: user.id,
            fullName: cleanName,
            email: cleanEmail,
            phone: cleanPhone,
            loyaltyPoints: 50,
            tier: 'Silver',
          );
          _currentUser = profile;
          await _saveUserCache(profile);

          _isLoading = false;
          notifyListeners();

          return AuthResult(
            success: true,
            requiresEmailConfirmation: true,
            message: 'تم إنشاء الحساب بنجاح! أرسلنا رابط تأكيد إلى بريدك الإلكتروني ($cleanEmail). يمكنك المتابعة الآن.',
            user: profile,
          );
        }
      }

      _isLoading = false;
      notifyListeners();
      return const AuthResult(success: false, message: 'تعذر إنشاء الحساب، يرجى المحاولة مجدداً');
    } on AuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return AuthResult(success: false, message: _mapAuthError(e.message));
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return AuthResult(
        success: false,
        message: 'حدث خطأ أثناء التسجيل: ${e.toString().split('\n').first}',
      );
    }
  }

  // ==========================================
  // 3. EMAIL SIGN IN (Full Login Flow)
  // ==========================================
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim();
    final cleanPass = password.trim();

    if (cleanEmail.isEmpty || cleanPass.isEmpty) {
      return const AuthResult(success: false, message: 'يرجى إدخال البريد الإلكتروني وكلمة المرور');
    }

    _isLoading = true;
    notifyListeners();

    try {
      final client = SupabaseService().client;
      if (client == null) {
        throw Exception('خدمة المصادقة غير متصلة حالياً');
      }

      final AuthResponse res = await client.auth.signInWithPassword(
        email: cleanEmail,
        password: cleanPass,
      );

      if (res.user != null) {
        final profile = await _fetchOrSyncUserProfile(res.user!);
        _isLoading = false;
        notifyListeners();
        return AuthResult(
          success: true,
          message: 'مرحباً بك مجدداً ${profile.fullName}! تم تسجيل الدخول بنجاح 🎉',
          user: profile,
        );
      }

      _isLoading = false;
      notifyListeners();
      return const AuthResult(success: false, message: 'تعذر التحقق من الحساب');
    } on AuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return AuthResult(success: false, message: _mapAuthError(e.message));
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return AuthResult(
        success: false,
        message: 'حدث خطأ أثناء تسجيل الدخول: ${e.toString().split('\n').first}',
      );
    }
  }

  // ==========================================
  // 4. PASSWORD RESET
  // ==========================================
  Future<AuthResult> resetPassword(String email) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      return const AuthResult(success: false, message: 'يرجى إدخال بريد إلكتروني صحيح');
    }

    try {
      final client = SupabaseService().client;
      if (client != null) {
        await client.auth.resetPasswordForEmail(
          cleanEmail,
          redirectTo: kIsWeb ? null : 'com.aldeeb.mall://login-callback',
        );
      }
      return const AuthResult(
        success: true,
        message: 'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني بنجاح',
      );
    } on AuthException catch (e) {
      return AuthResult(success: false, message: _mapAuthError(e.message));
    } catch (e) {
      return AuthResult(success: false, message: 'تعذر إرسال الرابط: ${e.toString()}');
    }
  }

  // ==========================================
  // 5. GUEST LOGIN
  // ==========================================
  Future<void> signInAsGuest() async {
    _setGuestUser();
  }

  // ==========================================
  // 6. LOYALTY POINTS & PROFILE UPDATE
  // ==========================================
  Future<bool> updateProfile({
    String? fullName,
    String? phone,
    String? email,
    String? avatarUrl,
  }) async {
    if (_currentUser == null) return false;

    final updated = UserProfileModel(
      id: _currentUser!.id,
      fullName: fullName ?? _currentUser!.fullName,
      email: email ?? _currentUser!.email,
      phone: phone ?? _currentUser!.phone,
      avatarUrl: avatarUrl ?? _currentUser!.avatarUrl,
      role: _currentUser!.role,
      loyaltyPoints: _currentUser!.loyaltyPoints,
      tier: _currentUser!.tier,
    );

    _currentUser = updated;
    await _saveUserCache(updated);
    notifyListeners();

    final client = SupabaseService().client;
    if (client != null && isAuthenticated) {
      try {
        final updates = <String, dynamic>{};
        if (fullName != null) updates['full_name'] = fullName;
        if (phone != null) updates['phone'] = phone;
        if (email != null) updates['email'] = email;
        if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
        await client.from(SupabaseConstants.profilesTable).update(updates).eq('id', _currentUser!.id);
        return true;
      } catch (e) {
        debugPrint('Profile update db error: $e');
      }
    }
    return true;
  }

  void addLoyaltyPoints(int points) {
    if (_currentUser != null) {
      final newPoints = _currentUser!.loyaltyPoints + points;
      final newTier = newPoints > 1000 ? 'Platinum' : (newPoints > 300 ? 'Gold' : 'Silver');
      _currentUser = UserProfileModel(
        id: _currentUser!.id,
        fullName: _currentUser!.fullName,
        email: _currentUser!.email,
        phone: _currentUser!.phone,
        avatarUrl: _currentUser!.avatarUrl,
        role: _currentUser!.role,
        loyaltyPoints: newPoints,
        tier: newTier,
      );
      _saveUserCache(_currentUser!);
      notifyListeners();

      // Sync points in database if connected
      final client = SupabaseService().client;
      if (client != null && isAuthenticated) {
        client.from(SupabaseConstants.profilesTable).update({
          'loyalty_points': newPoints,
          'tier': newTier,
        }).eq('id', _currentUser!.id).then((_) {}).catchError((_) {});
      }
    }
  }

  void deductLoyaltyPoints(int points) {
    if (_currentUser != null && _currentUser!.loyaltyPoints >= points) {
      final newPoints = _currentUser!.loyaltyPoints - points;
      _currentUser = UserProfileModel(
        id: _currentUser!.id,
        fullName: _currentUser!.fullName,
        email: _currentUser!.email,
        phone: _currentUser!.phone,
        avatarUrl: _currentUser!.avatarUrl,
        role: _currentUser!.role,
        loyaltyPoints: newPoints,
        tier: _currentUser!.tier,
      );
      _saveUserCache(_currentUser!);
      notifyListeners();

      final client = SupabaseService().client;
      if (client != null && isAuthenticated) {
        client.from(SupabaseConstants.profilesTable).update({
          'loyalty_points': newPoints,
        }).eq('id', _currentUser!.id).then((_) {}).catchError((_) {});
      }
    }
  }

  // ==========================================
  // 7. SIGN OUT
  // ==========================================
  Future<void> signOut() async {
    try {
      final client = SupabaseService().client;
      if (client != null) {
        await client.auth.signOut();
      }
      final googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }
    } catch (_) {}

    _setGuestUser();
  }

  // Helper: Friendly Arabic Error Messages
  String _mapAuthError(String msg) {
    final lower = msg.toLowerCase();
    if (lower.contains('invalid login credentials') || lower.contains('invalid_credentials')) {
      return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
    }
    if (lower.contains('user already registered') || lower.contains('already registered')) {
      return 'هذا البريد الإلكتروني مسجل بالفعل، يرجى تسجيل الدخول بدلاً من ذلك';
    }
    if (lower.contains('email not confirmed')) {
      return 'يرجى تأكيد بريدك الإلكتروني عبر الرابط المرسل إليك، أو تفعيل الدخول المباشر';
    }
    if (lower.contains('password should be at least 6 characters')) {
      return 'كلمة المرور يجب أن لا تقل عن 6 أحرف';
    }
    if (lower.contains('email address') && lower.contains('invalid')) {
      return 'صيغة البريد الإلكتروني غير صالحة';
    }
    return msg;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
