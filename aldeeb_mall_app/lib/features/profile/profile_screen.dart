import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/order_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/providers/order_provider.dart';
import '../../core/providers/store_settings_provider.dart';
import '../../core/utils/responsive.dart';

import '../address/address_book_screen.dart';
import '../auth/login_screen.dart';
import '../grocery_list/grocery_list_screen.dart';
import '../loyalty/loyalty_screen.dart';
import '../notifications/notifications_sheet.dart';
import '../orders/order_tracking_screen.dart';
import '../subscriptions/subscriptions_screen.dart';
import '../wallet/wallet_screen.dart';
import '../customer_service/presentation/customer_service_screen.dart';
import '../pickup/curbside_pickup_screen.dart';
import '../ai_nutritionist/ai_nutritionist_screen.dart';
import '../sustainability/eco_tracker_modal.dart';
import '../group_buying/group_deals_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Preset luxury avatars for quick pick
  final List<String> _presetAvatars = [
    'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=200&q=80',
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=200&q=80',
    'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?auto=format&fit=crop&w=200&q=80',
    'https://images.unsplash.com/photo-1580489944761-15a19d654956?auto=format&fit=crop&w=200&q=80',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=200&q=80',
    'https://images.unsplash.com/photo-1628157582853-a796fa650a6a?auto=format&fit=crop&w=200&q=80',
  ];

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final orderProv = Provider.of<OrderProvider>(context);
    final settings = Provider.of<StoreSettingsProvider>(context);
    final user = auth.currentUser;
    final isDark = settings.isDarkMode;

    return Scaffold(
      backgroundColor: settings.currentBackground,
      appBar: AppBar(
        title: const Text('الملف الشخصي والحساب'),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: isDark ? 'التحويل للوضع النهاري' : 'التحويل للوضع الليلي',
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? const Color(0xFFFBBF24) : Colors.white,
            ),
            onPressed: () => settings.toggleDarkMode(),
          ),
          IconButton(
            tooltip: 'تعديل الحساب',
            icon: const Icon(Icons.edit_rounded, color: Colors.white),
            onPressed: () => _showEditProfileModal(context, auth, settings),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: MaxWidthContainer(
          maxWidth: 900,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. User Header Profile Card
              _buildUserHeaderCard(context, auth, user, settings),
              const SizedBox(height: 16),

              // 2. Creative Day / Night Theme Switcher Card
              _buildCreativeThemeSwitcher(context, settings),
              const SizedBox(height: 16),

              // 3. Quick Stats Row (Active Orders, Points, Wallet)
              _buildQuickStatsRow(context, user, orderProv, settings),
              const SizedBox(height: 16),

              // 4. All Profile Tabs / Menu Options (Fully Active & Functional)
              _buildMenuSection(context, auth, orderProv, settings),
              const SizedBox(height: 20),

              // 5. Auth / Sign out / Sign in Action
              if (auth.isAuthenticated)
                OutlinedButton.icon(
                  onPressed: () => _confirmSignOut(context, auth, settings),
                  icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                  label: const Text(
                    'تسجيل الخروج من الحساب',
                    style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('تسجيل الدخول / إنشاء حساب جديد'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: settings.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),

              const SizedBox(height: 20),

              // 6. Mehwar Signature Card
              _buildMehwarSignatureCard(context),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. User Header Card
  // ---------------------------------------------------------------------------
  Widget _buildUserHeaderCard(
    BuildContext context,
    AuthService auth,
    dynamic user,
    StoreSettingsProvider settings,
  ) {
    final hasPhone = user?.phone != null && user!.phone!.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: settings.currentCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: settings.currentBorder),
        boxShadow: [
          BoxShadow(
            color: settings.isDarkMode
                ? Colors.black.withValues(alpha: 0.35)
                : const Color(0x0C0F172A),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar with edit badge
              Stack(
                children: [
                  GestureDetector(
                    onTap: () => _showEditProfileModal(context, auth, settings),
                    child: CircleAvatar(
                      radius: 34,
                      backgroundColor: settings.primaryColor.withValues(alpha: 0.2),
                      backgroundImage: user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                          ? CachedNetworkImageProvider(user.avatarUrl!)
                          : null,
                      child: user?.avatarUrl == null || user!.avatarUrl!.isEmpty
                          ? Icon(Icons.person, size: 38, color: settings.primaryColor)
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => _showEditProfileModal(context, auth, settings),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: settings.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: settings.currentCard, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt_rounded, size: 12, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),

              // Name & Contact
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user?.fullName ?? 'عميل الديب مول',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: settings.currentTextPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: settings.accentColor.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: settings.accentColor.withValues(alpha: 0.5),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            '${user?.tier ?? "Silver"} ★',
                            style: TextStyle(
                              color: settings.isDarkMode ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),

                    // Email
                    Text(
                      user?.email ?? 'مرحباً بك في تطبيق الديب مول الذكي',
                      style: TextStyle(
                        color: settings.currentTextSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),

                    // Phone Number indicator
                    if (hasPhone)
                      Row(
                        children: [
                          Icon(Icons.phone_iphone_rounded, size: 13, color: AppColors.freshGreen),
                          const SizedBox(width: 4),
                          Text(
                            user.phone!,
                            style: TextStyle(
                              color: settings.currentTextPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    else
                      InkWell(
                        onTap: () => _showEditProfileModal(context, auth, settings),
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.freshGreen.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.freshGreen.withValues(alpha: 0.4)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_call, size: 12, color: AppColors.freshGreen),
                              SizedBox(width: 4),
                              Text(
                                'أضف رقم هاتفك للتوصيل السريع',
                                style: TextStyle(
                                  color: AppColors.freshGreen,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                ),
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
          const SizedBox(height: 12),

          // Action row: Edit account button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: settings.isDarkMode
                  ? Colors.white.withValues(alpha: 0.04)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.verified_user_rounded, size: 15, color: settings.primaryColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    hasPhone
                        ? 'البيانات مكتملة • جاهز للتوصيل السريع'
                        : 'أكمل بيانات الهاتف لتسهيل استلام طلبياتك',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: settings.currentTextSecondary,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => _showEditProfileModal(context, auth, settings),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: settings.primaryColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_outlined, size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'تعديل الحساب',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
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

  // ---------------------------------------------------------------------------
  // 2. Creative Day / Night Theme Switcher
  // ---------------------------------------------------------------------------
  Widget _buildCreativeThemeSwitcher(BuildContext context, StoreSettingsProvider settings) {
    final isDark = settings.isDarkMode;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: settings.currentCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF38BDF8).withValues(alpha: 0.3) : const Color(0xFFF59E0B).withValues(alpha: 0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? const Color(0xFF38BDF8).withValues(alpha: 0.08)
                : const Color(0xFFF59E0B).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header with animated toggle badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? const [Color(0xFF6366F1), Color(0xFF38BDF8)]
                        : const [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDark ? Icons.nights_stay_rounded : Icons.wb_sunny_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مظهر وثيمات التطبيق (Day & Night Mode)',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: settings.currentTextPrimary,
                      ),
                    ),
                    Text(
                      isDark ? 'الوضع الليلي الفاخر مفعّل ومريح للعين' : 'الوضع النهاري المشرق مفعّل للتسوق الواضح',
                      style: TextStyle(
                        fontSize: 11,
                        color: settings.currentTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Animated Quick Switch
              Switch.adaptive(
                value: isDark,
                onChanged: (val) => settings.setDarkMode(val),
                activeThumbColor: const Color(0xFF38BDF8),
                activeTrackColor: const Color(0xFF1E293B),
                inactiveThumbColor: const Color(0xFFF59E0B),
                inactiveTrackColor: const Color(0xFFFEF3C7),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Dual Visual Theme Cards (Interactive)
          Row(
            children: [
              // Light Mode Card
              Expanded(
                child: InkWell(
                  onTap: () => settings.setDarkMode(false),
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7), Color(0xFFEFF6FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: !isDark ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0),
                        width: !isDark ? 2.2 : 1,
                      ),
                      boxShadow: !isDark
                          ? [
                              BoxShadow(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF59E0B),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.wb_sunny_rounded, color: Colors.white, size: 16),
                            ),
                            if (!isDark)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'المفعّل ✓',
                                  style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'النهاري المشرق',
                          style: TextStyle(
                            color: Color(0xFF1E293B),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'سطوع ناصع وألوان واضحة',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Dark Mode Card
              Expanded(
                child: InkWell(
                  onTap: () => settings.setDarkMode(true),
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF090D16)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF334155),
                        width: isDark ? 2.2 : 1,
                      ),
                      boxShadow: isDark
                          ? [
                              BoxShadow(
                                color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFF6366F1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.nights_stay_rounded, color: Colors.white, size: 16),
                            ),
                            if (isDark)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF38BDF8),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'المفعّل ✓',
                                  style: TextStyle(color: Color(0xFF0F172A), fontSize: 9.5, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'الليلي الفاخر',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'أناقة هادئة وموفرة للبطارية',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Preset Palette Quick Selector
          Row(
            children: [
              Text(
                'نغمات البراند:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: settings.currentTextSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: StoreSettingsProvider.presets.map((preset) {
                    final isSel = settings.primaryColor.toARGB32() == preset.primary.toARGB32();
                    return InkWell(
                      onTap: () => settings.applyPreset(preset.key),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: preset.primary.withValues(alpha: isSel ? 0.2 : 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSel ? preset.primary : Colors.transparent,
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: preset.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              preset.nameAr.split(' ').first,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                color: isSel ? preset.primary : settings.currentTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Quick Stats Row (Orders, Points, Wallet)
  // ---------------------------------------------------------------------------
  Widget _buildQuickStatsRow(
    BuildContext context,
    dynamic user,
    OrderProvider orderProv,
    StoreSettingsProvider settings,
  ) {
    return Row(
      children: [
        // 1. Orders
        Expanded(
          child: _statCard(
            context: context,
            icon: Icons.local_shipping_outlined,
            title: 'الطلبات النشطة',
            value: '${orderProv.orders.length}',
            color: settings.primaryColor,
            settings: settings,
            onTap: () {
              if (orderProv.orders.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => OrderTrackingScreen(order: orderProv.orders.first)),
                );
              } else {
                _openSampleOrderTracking(context);
              }
            },
          ),
        ),
        const SizedBox(width: 10),

        // 2. Loyalty Points
        Expanded(
          child: _statCard(
            context: context,
            icon: Icons.stars_rounded,
            title: 'رصيد النقاط',
            value: '${user?.loyaltyPoints ?? 50}',
            color: settings.accentColor,
            settings: settings,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoyaltyScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 10),

        // 3. Cash Wallet
        Expanded(
          child: _statCard(
            context: context,
            icon: Icons.account_balance_wallet_outlined,
            title: 'المحفظة الرقمية',
            value: '${((user?.loyaltyPoints ?? 50) * 0.01).toStringAsFixed(2)} ${settings.currency}',
            color: AppColors.freshGreen,
            settings: settings,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WalletScreen()),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required StoreSettingsProvider settings,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: settings.currentCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: settings.currentBorder),
          boxShadow: [
            BoxShadow(
              color: settings.isDarkMode
                  ? Colors.black.withValues(alpha: 0.25)
                  : const Color(0x080F172A),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: settings.currentTextSecondary),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. All Menu Tabs (Fully Functional)
  // ---------------------------------------------------------------------------
  Widget _buildMenuSection(
    BuildContext context,
    AuthService auth,
    OrderProvider orderProv,
    StoreSettingsProvider settings,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: settings.currentCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: settings.currentBorder),
        boxShadow: [
          BoxShadow(
            color: settings.isDarkMode
                ? Colors.black.withValues(alpha: 0.25)
                : const Color(0x080F172A),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 1. عناوين التوصيل المحفوظة (Address Book)
          _menuItem(
            icon: Icons.location_on_rounded,
            title: 'عناوين التوصيل ومواقع الخرائط',
            subtitle: 'إدارة مواقع التوصيل للمنزل والمكتب وتحديد العنوان المعتمد',
            iconColor: settings.primaryColor,
            settings: settings,
            badgeText: 'مفعلة',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddressBookScreen()),
              );
            },
          ),
          _divider(settings),

          // 2. طلباتي وفواتيري السابقة (Order History & Tracking)
          _menuItem(
            icon: Icons.receipt_long_rounded,
            title: 'طلباتي وفواتيري السابقة',
            subtitle: 'تتبع مسار الكابتن وعرض الفواتير ومراحل التجهيز الحية',
            iconColor: settings.secondaryColor,
            settings: settings,
            onTap: () {
              if (orderProv.orders.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => OrderTrackingScreen(order: orderProv.orders.first)),
                );
              } else {
                _openSampleOrderTracking(context);
              }
            },
          ),
          _divider(settings),

          // 3. المحفظة الرقمية وسجل العمليات (Wallet)
          _menuItem(
            icon: Icons.account_balance_wallet_rounded,
            title: 'المحفظة الرقمية ورصيد الديب كاش',
            subtitle: 'شحن المحفظة، استرداد الكاشباك، وإدارة طرق الدفع',
            iconColor: AppColors.freshGreen,
            settings: settings,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WalletScreen()),
              );
            },
          ),
          _divider(settings),

          // 4. برنامج مكافآت ونقاط الديب (Loyalty)
          _menuItem(
            icon: Icons.stars_rounded,
            title: 'برنامج الولاء ومكافآت الديب الذهبية',
            subtitle: 'استبدال النقاط بكوبونات خصم وعروض حصرية',
            iconColor: settings.accentColor,
            settings: settings,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoyaltyScreen()),
              );
            },
          ),
          _divider(settings),

          // 5. قائمة المقاضي الذكية (Grocery List)
          _menuItem(
            icon: Icons.checklist_rtl_rounded,
            title: 'قائمة المقاضي الذكية والمخطط العائلي',
            subtitle: 'تدوين النواقص ومزامنتها بنقرة واحدة مع السلة',
            iconColor: const Color(0xFF0284C7),
            settings: settings,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GroceryListScreen()),
              );
            },
          ),
          _divider(settings),

          // 6. الاشتراكات الشهرية والتوصيل الدوري (Subscriptions)
          _menuItem(
            icon: Icons.autorenew_rounded,
            title: 'الاشتراكات الدورية وتوصيل المقاضي التلقائي',
            subtitle: 'توصيل الحليب والخبز والمياه والخضار وفق جدول مجدول',
            iconColor: const Color(0xFF7C3AED),
            settings: settings,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SubscriptionsScreen()),
              );
            },
          ),
          _divider(settings),

          // 7. إشعارات العروض وتحديثات الطلبات (Notifications)
          _menuItem(
            icon: Icons.notifications_active_rounded,
            title: 'إشعارات العروض وتحديثات الطلبات',
            subtitle: 'تنبيهات الصفقات الساخنة وتغير الأسعار وحالة الطلب',
            iconColor: const Color(0xFFEA580C),
            settings: settings,
            onTap: () => NotificationsSheet.show(context),
          ),
          _divider(settings),

          // الاستلام من السيارة (Curbside Express)
          _menuItem(
            icon: Icons.directions_car_rounded,
            title: 'الاستلام السريع من السيارة (Curbside Express)',
            subtitle: 'تصل لمواقف الديب مول ونقوم بتحميل المقاضي لسيارتك خلال دقيقتين',
            iconColor: const Color(0xFF0284C7),
            settings: settings,
            badgeText: 'دقيقتين',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CurbsidePickupScreen()),
              );
            },
          ),
          _divider(settings),

          // 12. صفقات الشراء الجماعي التشاركي (Group Deals)
          _menuItem(
            icon: Icons.group_work_rounded,
            title: 'صفقات الشراء الجماعي مع الجيران والأصدقاء',
            subtitle: 'انضم لفرق الشراء بالحي ووفر نصف السعر مع توصيل مجاني',
            iconColor: const Color(0xFFE11D48),
            settings: settings,
            badgeText: 'وفر 40%',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GroupDealsScreen()),
              );
            },
          ),
          _divider(settings),

          // أخصائي التغذية الذكي بالذكاء الاصطناعي (AI Nutritionist)
          _menuItem(
            icon: Icons.psychology_rounded,
            title: 'أخصائي التغذية الذكي وتحليل الوجبات',
            subtitle: 'توصيات غذائية تناسب أهدافك الصحية وحساب السعرات الحرارية',
            iconColor: const Color(0xFF059669),
            settings: settings,
            badgeText: 'AI',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AiNutritionistScreen()),
              );
            },
          ),
          _divider(settings),

          // 14. متتبع الأثر البيئي والصناديق الخضراء (Eco Tracker)
          _menuItem(
            icon: Icons.eco_rounded,
            title: 'الأثر البيئي والصناديق الخضراء المعاد تدويرها',
            subtitle: 'متابعة مساهمتك في خفض الانبعاثات والحد من الأكياس البلاستيكية',
            iconColor: const Color(0xFF15803D),
            settings: settings,
            onTap: () => EcoTrackerModal.show(context),
          ),
          _divider(settings),

          // 15. خدمة العملاء والشات المباشر (Customer Support & Live Chat)
          _menuItem(
            icon: Icons.support_agent_rounded,
            title: 'خدمة العملاء والشات المباشر (24/7)',
            subtitle: '${settings.phone} • شات حي وتذاكر دعم ومتابعة فورية',
            iconColor: AppColors.freshGreen,
            settings: settings,
            onTap: () => CustomerServiceScreen.show(context),
          ),
          _divider(settings),

          // 16. ربط الحساب بجوجل
          _menuItem(
            icon: Icons.g_mobiledata_rounded,
            title: 'مزامنة السحاب بحساب Google',
            subtitle: 'ربط السلة والنقاط عبر كافة أجهزتك السحابية',
            iconColor: Colors.red,
            settings: settings,
            onTap: () async {
              final result = await auth.signInWithGoogle();
              if (context.mounted && result.success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: AppColors.freshGreen,
                    content: Text('تم تسجيل الدخول وربط الحساب بجوجل بنجاح!'),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _divider(StoreSettingsProvider settings) {
    return Divider(height: 1, thickness: 1, color: settings.currentDivider);
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    String? badgeText,
    required Color iconColor,
    required StoreSettingsProvider settings,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: settings.isDarkMode ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 21),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: settings.currentTextPrimary,
              ),
            ),
          ),
          if (badgeText != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.freshGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badgeText,
                style: const TextStyle(
                  color: AppColors.freshGreen,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: settings.currentTextSecondary),
            )
          : null,
      trailing: Icon(
        Icons.chevron_left_rounded,
        size: 20,
        color: settings.currentTextSecondary,
      ),
      onTap: onTap,
    );
  }

  // ---------------------------------------------------------------------------
  // 5. Edit Profile & Add Phone Bottom Sheet Modal
  // ---------------------------------------------------------------------------
  void _showEditProfileModal(BuildContext context, AuthService auth, StoreSettingsProvider settings) {
    final user = auth.currentUser;
    final nameCtrl = TextEditingController(text: user?.fullName ?? '');
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    final phoneCtrl = TextEditingController(text: user?.phone ?? '');
    String selectedAvatar = user?.avatarUrl ?? _presetAvatars.first;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          decoration: BoxDecoration(
            color: settings.currentCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: settings.currentBorder),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top bar pill
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: settings.currentTextSecondary.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: settings.primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.manage_accounts_rounded, color: settings.primaryColor, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تعديل الحساب وإضافة رقم الهاتف',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: settings.currentTextPrimary,
                          ),
                        ),
                        Text(
                          'حدّث بياناتك للتوصيل السريع وتتبع الطلبات بدقة',
                          style: TextStyle(fontSize: 11, color: settings.currentTextSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Avatar Selector
                Text(
                  'اختر الصورة الرمزية للملف الشخصي:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: settings.currentTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 54,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _presetAvatars.length,
                    separatorBuilder: (_, index) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final url = _presetAvatars[index];
                      final isSelected = selectedAvatar == url;
                      return GestureDetector(
                        onTap: () => setSheetState(() => selectedAvatar = url),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? settings.primaryColor : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 22,
                            backgroundImage: CachedNetworkImageProvider(url),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Full Name
                TextField(
                  controller: nameCtrl,
                  style: TextStyle(color: settings.currentTextPrimary),
                  decoration: InputDecoration(
                    labelText: 'الاسم الكامل',
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),

                // Phone Number (Highlight)
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.freshGreen.withValues(alpha: 0.6),
                      width: 1.4,
                    ),
                  ),
                  child: TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(color: settings.currentTextPrimary),
                    decoration: InputDecoration(
                      labelText: 'رقم الهاتف للتوصيل والتواصل السريع *',
                      hintText: '+971 50 123 4567 أو +963 912 345 678',
                      prefixIcon: const Icon(Icons.phone_iphone_rounded, color: AppColors.freshGreen),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Email
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: settings.currentTextPrimary),
                  decoration: InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    prefixIcon: const Icon(Icons.mail_outline_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isSaving ? null : () => Navigator.pop(sheetCtx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('إلغاء'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                final name = nameCtrl.text.trim();
                                final phone = phoneCtrl.text.trim();
                                final email = emailCtrl.text.trim();

                                if (name.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('يرجى إدخال اسم صحيح')),
                                  );
                                  return;
                                }

                                setSheetState(() => isSaving = true);

                                await auth.updateProfile(
                                  fullName: name,
                                  phone: phone.isNotEmpty ? phone : null,
                                  email: email.isNotEmpty ? email : null,
                                  avatarUrl: selectedAvatar,
                                );

                                if (context.mounted) {
                                  Navigator.pop(sheetCtx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: AppColors.freshGreen,
                                      behavior: SnackBarBehavior.floating,
                                      content: Row(
                                        children: [
                                          const Icon(Icons.check_circle_rounded, color: Colors.white),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              phone.isNotEmpty
                                                  ? 'تم حفظ وتحديث الحساب ورقم الهاتف بنجاح! ✨'
                                                  : 'تم تحديث بيانات الحساب بنجاح! ✨',
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: settings.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('حفظ التعديلات', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 7. Helpers: Sample Order Tracking
  // ---------------------------------------------------------------------------

  void _openSampleOrderTracking(BuildContext context) {
    final sampleOrder = OrderModel(
      id: 'ord-demo-01',
      orderNumber: '#DB-8924',
      status: 'out_for_delivery',
      deliverySlot: 'اليوم خلال 15 دقيقة (إكسبريس ⚡)',
      paymentMethod: 'الدفع عند الاستلام (كاش)',
      paymentStatus: 'paid',
      subtotal: 185.0,
      deliveryFee: 0.0,
      discountAmount: 15.0,
      totalAmount: 170.0,
      items: const [],
      createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
      driverName: 'عمر الخالد (كابتن الديب مول)',
      driverPhone: '+971 50 888 9911',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderTrackingScreen(order: sampleOrder),
      ),
    );
  }

  void _confirmSignOut(BuildContext context, AuthService auth, StoreSettingsProvider settings) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: settings.currentCard,
        title: Text(
          'تسجيل الخروج',
          style: TextStyle(fontWeight: FontWeight.bold, color: settings.currentTextPrimary),
        ),
        content: Text(
          'هل تريد بالفعل تسجيل الخروج؟ يمكنك الدخول مجدداً في أي وقت.',
          style: TextStyle(color: settings.currentTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              auth.signOut();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('نعم، تسجيل الخروج', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 8. Mehwar Signature Card
  // ---------------------------------------------------------------------------
  Widget _buildMehwarSignatureCard(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showMehwarDetails(context),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.45),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706), Color(0xFFB45309)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Center(
                  child: Icon(Icons.hub_rounded, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'تنفيذ وتطوير: شركة محور',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFF10B981), width: 0.6),
                          ),
                          child: const Text(
                            'معتمد',
                            style: TextStyle(
                              color: Color(0xFF34D399),
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'MEHWAR Tech Solutions • حلول برمجية متكاملة',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.auto_awesome, color: Color(0xFFF59E0B), size: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showMehwarDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: Color(0xFFF59E0B), width: 1.5),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706), Color(0xFFB45309)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.hub_rounded, color: Colors.white, size: 30),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'شركة محور للحلول التقنية والبرمجية',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'MEHWAR Software & Digital Engineering',
                style: TextStyle(
                  color: Color(0xFFF59E0B),
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: const Text(
                  'تم تصميم وتطوير وهندسة البنية البرمجية المتكاملة لمشروع الديب مول بواسطة شركة محور، بما يشمل تطبيق المتجر، لوحة الإدارة المركزية، بوابة الكاشير السحابية، ونظام إدارة العمليات والتوصيل الفوري.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: const Color(0xFF0F172A),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'إغلاق',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
