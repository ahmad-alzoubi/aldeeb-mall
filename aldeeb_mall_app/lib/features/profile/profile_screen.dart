import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/providers/order_provider.dart';
import '../../core/utils/responsive.dart';
import '../auth/login_screen.dart';
import '../orders/order_tracking_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final orderProv = Provider.of<OrderProvider>(context);
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('الملف الشخصي والحساب'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: MaxWidthContainer(
          maxWidth: 900,
          child: Column(
            children: [
            // User Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: AppColors.cardShadow,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primaryLight,
                    backgroundImage: user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                        ? CachedNetworkImageProvider(user.avatarUrl!)
                        : null,
                    child: user?.avatarUrl == null || user!.avatarUrl!.isEmpty
                        ? const Icon(Icons.person, size: 36, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? 'عميل الديب مول',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? 'تسجيل الدخول للاستفادة من المزايا',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accentLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'عضوية ${user?.tier ?? "Silver"} • ${user?.loyaltyPoints ?? 50} نقطة',
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!auth.isAuthenticated)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(70, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      child: const Text('دخول', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quick Stats Row
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    Icons.local_shipping_outlined,
                    'الطلبات النشطة',
                    '${orderProv.orders.length}',
                    AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    Icons.stars_rounded,
                    'رصيد النقاط',
                    '${user?.loyaltyPoints ?? 50}',
                    AppColors.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    Icons.account_balance_wallet_outlined,
                    'الرصيد النقدي',
                    '${((user?.loyaltyPoints ?? 50) * 0.01).toStringAsFixed(2)} ل.س',
                    AppColors.freshGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Menu Options
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _menuItem(
                    Icons.receipt_long_outlined,
                    'طلباتي وفواتيري السابقة',
                    subtitle: 'تتبع الطلبات وعرض الفواتير الرقمية',
                    onTap: () {
                      if (orderProv.orders.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrderTrackingScreen(order: orderProv.orders.first),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('لا توجد طلبات سابقة حالياً')),
                        );
                      }
                    },
                  ),
                  const Divider(height: 1),
                  _menuItem(
                    Icons.location_on_outlined,
                    'عناوين التوصيل المحفوظة',
                    subtitle: 'إدارة مواقع التوصيل للمنزل والعمل',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('عناوين التوصيل مفعلة ومحفوظة بنجاح')),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  _menuItem(
                    Icons.g_mobiledata_rounded,
                    'تسجيل الدخول بحساب Google',
                    subtitle: 'ربط ومزامنة السلة والنقاط عبر السحابة',
                    iconColor: Colors.red,
                    onTap: () => auth.signInWithGoogle(),
                  ),
                  const Divider(height: 1),
                  _menuItem(
                    Icons.support_agent_outlined,
                    'خدمة العملاء وواتساب الديب مول',
                    subtitle: '+971 50 123 4567 • متاحون على مدار الساعة',
                    iconColor: AppColors.freshGreen,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('الاتصال بخدمة عملاء الديب مول: +971501234567')),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  _menuItem(
                    Icons.notifications_active_outlined,
                    'إشعارات العروض وتحديثات الطلبات',
                    subtitle: 'مفعلة للحصول على كوبونات وتنبيهات الخصم',
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  _menuItem(
                    Icons.admin_panel_settings_outlined,
                    'لوحة الإدارة والتحكم (Admin Dashboard)',
                    subtitle: 'إدارة المنتجات والمخزون والطلبات الفورية',
                    iconColor: AppColors.primary,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('لوحة الإدارة متوفرة عبر المتصفح على المنفذ localhost:3000'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Sign out button
            if (auth.isAuthenticated)
              OutlinedButton.icon(
                onPressed: () => auth.signOut(),
                icon: const Icon(Icons.logout, color: AppColors.error),
                label: const Text('تسجيل الخروج', style: TextStyle(color: AppColors.error)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    ),
  );
  }

  Widget _statCard(IconData icon, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _menuItem(
    IconData icon,
    String title, {
    String? subtitle,
    VoidCallback? onTap,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor ?? AppColors.primary, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)) : null,
      trailing: const Icon(Icons.chevron_left_rounded, size: 20, color: AppColors.textMuted),
      onTap: onTap,
    );
  }
}
