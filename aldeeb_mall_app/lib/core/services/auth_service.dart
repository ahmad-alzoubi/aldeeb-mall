import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile_model.dart';
import 'supabase_service.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  UserProfileModel? _currentUser;
  bool _isLoading = false;

  UserProfileModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;

  void initialize() {
    final client = SupabaseService().client;
    if (client != null && client.auth.currentUser != null) {
      final user = client.auth.currentUser!;
      _currentUser = UserProfileModel(
        id: user.id,
        fullName: user.userMetadata?['full_name'] as String? ?? user.email?.split('@').first ?? 'عميل الديب مول',
        email: user.email ?? '',
        avatarUrl: user.userMetadata?['avatar_url'] as String?,
        loyaltyPoints: 120, // default loaded loyalty points
        tier: 'Silver',
      );
      notifyListeners();
    } else {
      // Default initial guest profile
      _currentUser = const UserProfileModel(
        id: 'guest_user',
        fullName: 'عميل الديب مول (زائر)',
        email: 'guest@aldeebmall.com',
        loyaltyPoints: 50, // Welcome gift points
        tier: 'Silver',
      );
      notifyListeners();
    }
  }

  // 1. Google Sign-In
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      final client = SupabaseService().client;
      if (client != null) {
        await client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: kIsWeb ? null : 'com.aldeeb.mall://login-callback',
        );
      }

      // Simulation/fallback for immediate responsive preview
      _currentUser = const UserProfileModel(
        id: 'google_user_01',
        fullName: 'أحمد الزعبي',
        email: 'ahmad@example.com',
        avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=200&q=80',
        loyaltyPoints: 250,
        tier: 'Gold',
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 2. Email & Password Login
  Future<bool> signInWithEmail(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final client = SupabaseService().client;
      if (client != null) {
        await client.auth.signInWithPassword(email: email, password: password);
      }

      _currentUser = UserProfileModel(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        fullName: email.split('@').first,
        email: email,
        loyaltyPoints: 100,
        tier: 'Silver',
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 3. Update Points
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
      notifyListeners();
    }
  }

  void deductLoyaltyPoints(int points) {
    if (_currentUser != null && _currentUser!.loyaltyPoints >= points) {
      _currentUser = UserProfileModel(
        id: _currentUser!.id,
        fullName: _currentUser!.fullName,
        email: _currentUser!.email,
        phone: _currentUser!.phone,
        avatarUrl: _currentUser!.avatarUrl,
        role: _currentUser!.role,
        loyaltyPoints: _currentUser!.loyaltyPoints - points,
        tier: _currentUser!.tier,
      );
      notifyListeners();
    }
  }

  // 4. Logout
  Future<void> signOut() async {
    final client = SupabaseService().client;
    if (client != null) {
      await client.auth.signOut();
    }
    _currentUser = null;
    notifyListeners();
  }
}
