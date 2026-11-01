import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/providers/store_settings_provider.dart';
import '../../core/utils/responsive.dart';
import '../cart/cart_screen.dart';
import '../cart/widgets/floating_cart_bar.dart';
import '../category/categories_screen.dart';
import '../profile/profile_screen.dart';
import '../recipes/recipes_screen.dart';
import '../scanner/barcode_scanner_screen.dart';
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
    CategoriesScreen(),
    BarcodeScannerScreen(),
    RecipesScreen(),
    ProfileScreen(),
  ];

  @override
  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final settings = Provider.of<StoreSettingsProvider>(context);
    final isDesktop = Responsive.isDesktop(context);

    if (isDesktop) {
      // Desktop View: Top navigation bar with persistent header & content
      return Scaffold(
        body: Column(
          children: [
            // Desktop secondary navigation strip
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: settings.primaryDarkColor,
                border: const Border(bottom: BorderSide(color: Color(0x1AFFFFFF))),
              ),
              child: MaxWidthContainer(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    _desktopTabButton(0, 'الرئيسية والعروض', Icons.storefront),
                    const SizedBox(width: 8),
                    _desktopTabButton(1, 'تصفح كافة الأقسام', Icons.grid_view_rounded),
                    const SizedBox(width: 8),
                    _desktopTabButton(2, '📷 فاحص الأسعار والباركود', Icons.qr_code_scanner_rounded),
                    const SizedBox(width: 8),
                    _desktopTabButton(3, 'طباخ الديب (وصفات ومقادير)', Icons.soup_kitchen_rounded),
                    const SizedBox(width: 8),
                    _desktopTabButton(4, 'حسابي والطلبات السابقة', Icons.person),
                    const Spacer(),
                    if (cart.itemCount > 0) ...[
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CartScreen()),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: settings.accentColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.shopping_cart, size: 16, color: AppColors.textPrimary),
                              const SizedBox(width: 6),
                              Text(
                                '${cart.itemCount} في السلة (${cart.totalAmount.toStringAsFixed(2)} ${settings.currency}) - إتمام الطلب',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    Row(
                      children: [
                        const Icon(Icons.headset_mic_outlined, color: Colors.white70, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'خدمة العملاء: ${settings.storeNameAr}',
                          style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
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

    // Mobile View: Modern NavigationBar with Floating Cart Checkout Bar
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (cart.itemCount > 0)
            const FloatingCartBar(
              margin: EdgeInsets.fromLTRB(14, 4, 14, 8),
            ),
          NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() => _currentIndex = index);
            },
            backgroundColor: Colors.white,
            elevation: 8,
            indicatorColor: settings.primaryColor.withValues(alpha: 0.15),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.storefront_outlined),
                selectedIcon: Icon(Icons.storefront, color: settings.primaryColor),
                label: 'الرئيسية',
              ),
              NavigationDestination(
                icon: const Icon(Icons.grid_view_outlined),
                selectedIcon: Icon(Icons.grid_view_rounded, color: settings.primaryColor),
                label: 'الأقسام',
              ),
              NavigationDestination(
                icon: const Icon(Icons.qr_code_scanner_rounded),
                selectedIcon: Icon(Icons.camera_alt_rounded, color: settings.primaryColor),
                label: 'فاحص الأسعار',
              ),
              NavigationDestination(
                icon: const Icon(Icons.soup_kitchen_outlined),
                selectedIcon: Icon(Icons.soup_kitchen_rounded, color: settings.primaryColor),
                label: 'الوصفات',
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person, color: settings.primaryColor),
                label: 'حسابي',
              ),
            ],
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
          border: isSelected ? Border.all(color: Colors.white24) : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.white70,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
