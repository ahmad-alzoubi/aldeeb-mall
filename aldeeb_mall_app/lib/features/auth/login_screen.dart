import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo / Mall Brand
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppColors.floatingShadow,
              ),
              child: const Icon(Icons.shopping_bag_rounded, size: 44, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              'الديب مول',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const Text(
              'Aldeeb Hypermarket & Mall',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accentLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.stars_rounded, color: AppColors.accent, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'احصل على 50 نقطة ولاء مجانية عند التسجيل',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accent),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Google Sign In Button
            OutlinedButton(
              onPressed: auth.isLoading
                  ? null
                  : () async {
                      final success = await auth.signInWithGoogle();
                      if (context.mounted && success) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('مرحباً بك ${auth.currentUser?.fullName ?? ''} 🎉 تم تسجيل الدخول بنجاح!'),
                            backgroundColor: AppColors.freshGreen,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.network(
                    'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                    width: 22,
                    height: 22,
                    errorBuilder: (ctx, error, stack) => const Icon(Icons.g_mobiledata, color: Colors.red, size: 28),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'المتابعة باستخدام حساب Google',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Divider OR
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('أو عبر البريد الإلكتروني', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 24),

            // Email & Password Inputs
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني',
                hintText: 'name@example.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'كلمة المرور',
                hintText: '••••••••',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 20),

            // Login Button
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      final email = _emailController.text.trim();
                      final pass = _passwordController.text.trim();
                      if (email.isEmpty || pass.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('يرجى كتابة البريد الإلكتروني وكلمة المرور')),
                        );
                        return;
                      }

                      setState(() => _isLoading = true);
                      final success = await auth.signInWithEmail(email, pass);
                      setState(() => _isLoading = false);

                      if (context.mounted && success) {
                        Navigator.pop(context);
                      }
                    },
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('تسجيل الدخول'),
            ),
            const SizedBox(height: 16),

            // Skip / Guest Mode
            TextButton(
              onPressed: () async {
                await auth.signInAsGuest();
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text(
                'التسوق كزائر (المتابعة دون حساب)',
                style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
