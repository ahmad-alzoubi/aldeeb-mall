import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../catalog/catalog_screen.dart';
import '../loyalty/loyalty_screen.dart';
import '../profile/profile_screen.dart';
import 'home_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    CatalogScreen(),
    LoyaltyScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    if (isDesktop) {
      // Desktop View: Top navigation bar with persistent header & content
      return Scaffold(
        body: Column(
          children: [
            // Desktop secondary navigation strip
            Container(
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.primaryDark,
                border: Border(bottom: BorderSide(color: Color(0x1AFFFFFF))),
              ),
              child: MaxWidthContainer(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    _desktopTabButton(0, 'الرئيسية والعروض', Icons.storefront),
                    const SizedBox(width: 8),
                    _desktopTabButton(1, 'تصفح كافة الأقسام', Icons.grid_view_rounded),
                    const SizedBox(width: 8),
                    _desktopTabButton(2, 'نادي مكافآت الديب (نقاط الولاء)', Icons.stars_rounded),
                    const SizedBox(width: 8),
                    _desktopTabButton(3, 'حسابي والطلبات السابقة', Icons.person),
                    const Spacer(),
                    const Row(
                      children: [
                        Icon(Icons.headset_mic_outlined, color: Colors.white70, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'خدمة العملاء: +971 50 123 4567',
                          style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Screen Content
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: _screens,
              ),
            ),
          ],
        ),
      );
    }

    // Mobile View: Modern NavigationBar
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        backgroundColor: Colors.white,
        elevation: 8,
        indicatorColor: AppColors.primary.withValues(alpha: 0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront, color: AppColors.primary),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded, color: AppColors.primary),
            label: 'الأقسام',
          ),
          NavigationDestination(
            icon: Icon(Icons.stars_outlined),
            selectedIcon: Icon(Icons.stars_rounded, color: AppColors.accent),
            label: 'نقاطي',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppColors.primary),
            label: 'حسابي',
          ),
        ],
      ),
    );
  }

  Widget _desktopTabButton(int index, String label, IconData icon) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.accent : Colors.white70, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
