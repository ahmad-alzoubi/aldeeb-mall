import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final int initialTabIndex;
  const LoginScreen({super.key, this.initialTabIndex = 0});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Login Controllers
  final TextEditingController _loginEmailController = TextEditingController();
  final TextEditingController _loginPasswordController = TextEditingController();
  bool _obscureLoginPassword = true;

  // Register Controllers
  final TextEditingController _regFullNameController = TextEditingController();
  final TextEditingController _regPhoneController = TextEditingController();
  final TextEditingController _regEmailController = TextEditingController();
  final TextEditingController _regPasswordController = TextEditingController();
  final TextEditingController _regConfirmPasswordController = TextEditingController();
  bool _obscureRegPassword = true;
  bool _obscureRegConfirmPassword = true;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _regFullNameController.dispose();
    _regPhoneController.dispose();
    _regEmailController.dispose();
    _regPasswordController.dispose();
    _regConfirmPasswordController.dispose();
    super.dispose();
  }

  void _showNotification(String message, {bool isSuccess = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle_rounded : Icons.error_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: isSuccess ? AppColors.freshGreen : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: isSuccess ? 3 : 4),
      ),
    );
  }

  // Google Sign-In Handler
  Future<void> _handleGoogleSignIn(AuthService auth) async {
    setState(() => _isSubmitting = true);
    final result = await auth.signInWithGoogle();
    setState(() => _isSubmitting = false);

    if (result.success) {
      _showNotification(result.message, isSuccess: true);
      if (mounted) Navigator.pop(context);
    } else {
      _showNotification(result.message, isSuccess: false);
    }
  }

  // Email Login Handler
  Future<void> _handleEmailLogin(AuthService auth) async {
    final email = _loginEmailController.text.trim();
    final pass = _loginPasswordController.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      _showNotification('يرجى كتابة البريد الإلكتروني وكلمة المرور', isSuccess: false);
      return;
    }

    setState(() => _isSubmitting = true);
    final result = await auth.signInWithEmail(email: email, password: pass);
    setState(() => _isSubmitting = false);

    if (result.success) {
      _showNotification(result.message, isSuccess: true);
      if (mounted) Navigator.pop(context);
    } else {
      _showNotification(result.message, isSuccess: false);
    }
  }

  // Email Register Handler
  Future<void> _handleEmailRegister(AuthService auth) async {
    final name = _regFullNameController.text.trim();
    final phone = _regPhoneController.text.trim();
    final email = _regEmailController.text.trim();
    final pass = _regPasswordController.text.trim();
    final confirmPass = _regConfirmPasswordController.text.trim();

    if (name.isEmpty) {
      _showNotification('يرجى إدخال الاسم الكامل', isSuccess: false);
      return;
    }
    if (email.isEmpty) {
      _showNotification('يرجى إدخال البريد الإلكتروني', isSuccess: false);
      return;
    }
    if (pass.length < 6) {
      _showNotification('كلمة المرور يجب أن لا تقل عن 6 أحرف', isSuccess: false);
      return;
    }
    if (pass != confirmPass) {
      _showNotification('كلمتا المرور غير متطابقتين', isSuccess: false);
      return;
    }

    setState(() => _isSubmitting = true);
    final result = await auth.signUpWithEmail(
      email: email,
      password: pass,
      fullName: name,
      phone: phone.isNotEmpty ? phone : null,
    );
    setState(() => _isSubmitting = false);

    if (result.success) {
      _showNotification(result.message, isSuccess: true);
      if (mounted) Navigator.pop(context);
    } else {
      _showNotification(result.message, isSuccess: false);
    }
  }

  // Forgot Password Dialog
  void _showForgotPasswordDialog(AuthService auth) {
    final emailCtrl = TextEditingController(text: _loginEmailController.text.trim());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lock_reset_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('استعادة كلمة المرور', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'أدخل بريدك الإلكتروني المسجل لنرسل لك رابط إعادة تعيين كلمة المرور:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'البريد الإلكتروني',
                hintText: 'name@example.com',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailCtrl.text.trim();
              Navigator.pop(ctx);
              final res = await auth.resetPassword(email);
              _showNotification(res.message, isSuccess: res.success);
            },
            child: const Text('إرسال الرابط'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final isLoading = _isSubmitting || auth.isLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo / Brand
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFF38BDF8), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, st) => const Icon(Icons.shopping_bag_rounded, size: 40, color: Colors.white),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'الديب مول',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const Text(
                'Aldeeb Hypermarket & Mall',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 12),

              // Welcome Bonus Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.stars_rounded, color: AppColors.accent, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'احصل على 50 نقطة ولاء مجانية فور التسجيل 🎁',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Tabs: Sign In / Sign Up
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textMuted,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  tabs: const [
                    Tab(text: 'تسجيل الدخول'),
                    Tab(text: 'إنشاء حساب جديد'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Google Sign-In Button (Common Quick Action)
              OutlinedButton(
                onPressed: isLoading ? null : () => _handleGoogleSignIn(auth),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Colors.white,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.network(
                      'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                      width: 22,
                      height: 22,
                      errorBuilder: (ctx, error, stack) => const Icon(
                        Icons.g_mobiledata_rounded,
                        color: Colors.red,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'المتابعة باستخدام حساب Google',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // OR Divider
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      'أو عبر البريد الإلكتروني',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),

              // Tab Views Content
              SizedBox(
                height: 380,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Login Form
                    _buildLoginForm(auth, isLoading),

                    // Tab 2: Register Form
                    _buildRegisterForm(auth, isLoading),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Guest Mode Button
              TextButton.icon(
                onPressed: () async {
                  await auth.signInAsGuest();
                  if (context.mounted) Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back_rounded, size: 16, color: AppColors.textSecondary),
                label: const Text(
                  'المتابعة والتسوق كزائر دون تسجيل',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // 1. Login Form Tab
  Widget _buildLoginForm(AuthService auth, bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _loginEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'البريد الإلكتروني',
            hintText: 'name@example.com',
            prefixIcon: const Icon(Icons.email_outlined, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _loginPasswordController,
          obscureText: _obscureLoginPassword,
          decoration: InputDecoration(
            labelText: 'كلمة المرور',
            hintText: '••••••••',
            prefixIcon: const Icon(Icons.lock_outline, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureLoginPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
              ),
              onPressed: () => setState(() => _obscureLoginPassword = !_obscureLoginPassword),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => _showForgotPasswordDialog(auth),
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: const Text(
              'نسيت كلمة المرور؟',
              style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: isLoading ? null : () => _handleEmailLogin(auth),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text(
                  'تسجيل الدخول',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }

  // 2. Register Form Tab
  Widget _buildRegisterForm(AuthService auth, bool isLoading) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        TextField(
          controller: _regFullNameController,
          decoration: InputDecoration(
            labelText: 'الاسم الكامل *',
            hintText: 'مثال: أحمد الزعبي',
            prefixIcon: const Icon(Icons.person_outline, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _regPhoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'رقم الجوال (اختياري للتوصيل)',
            hintText: '050xxxxxxx',
            prefixIcon: const Icon(Icons.phone_outlined, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _regEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'البريد الإلكتروني *',
            hintText: 'name@example.com',
            prefixIcon: const Icon(Icons.email_outlined, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _regPasswordController,
          obscureText: _obscureRegPassword,
          decoration: InputDecoration(
            labelText: 'كلمة المرور (6 أحرف أو أكثر) *',
            hintText: '••••••••',
            prefixIcon: const Icon(Icons.lock_outline, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureRegPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
              ),
              onPressed: () => setState(() => _obscureRegPassword = !_obscureRegPassword),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _regConfirmPasswordController,
          obscureText: _obscureRegConfirmPassword,
          decoration: InputDecoration(
            labelText: 'تأكيد كلمة المرور *',
            hintText: '••••••••',
            prefixIcon: const Icon(Icons.lock_outline, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureRegConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
              ),
              onPressed: () => setState(() => _obscureRegConfirmPassword = !_obscureRegConfirmPassword),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: isLoading ? null : () => _handleEmailRegister(auth),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: AppColors.primary,
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text(
                  'إنشاء حساب جديد والحصول على الهدية 🎁',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
