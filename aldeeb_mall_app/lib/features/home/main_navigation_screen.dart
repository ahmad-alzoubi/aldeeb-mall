import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/utils/responsive.dart';
import '../cart/cart_screen.dart';
import '../category/categories_screen.dart';
import '../loyalty/loyalty_screen.dart';
import '../profile/profile_screen.dart';
import '../recipes/recipes_screen.dart';
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
    RecipesScreen(),
    LoyaltyScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
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
                    _desktopTabButton(2, 'طباخ الديب (وصفات ومقادير)', Icons.soup_kitchen_rounded),
                    const SizedBox(width: 8),
                    _desktopTabButton(3, 'نادي مكافآت الديب (نقاط الولاء)', Icons.stars_rounded),
                    const SizedBox(width: 8),
                    _desktopTabButton(4, 'حسابي والطلبات السابقة', Icons.person),
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
            _buildFloatingCartBar(context, cart),
          NavigationBar(
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
                icon: Icon(Icons.soup_kitchen_outlined),
                selectedIcon: Icon(Icons.soup_kitchen_rounded, color: AppColors.primary),
                label: 'الوصفات',
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
        ],
      ),
    );
  }

  Widget _buildFloatingCartBar(BuildContext context, CartProvider cart) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 4, 14, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), AppColors.primaryDark],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Badge(
              label: Text('${cart.itemCount}'),
              child: const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    '${cart.totalAmount.toStringAsFixed(2)} ل.س',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.freshGreen.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'توصيل فوري ⚡',
                      style: TextStyle(color: AppColors.freshGreen, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              Text(
                '${cart.itemCount} أصناف بالسلة • جاهز لإتمام الطلب',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            },
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text(
              'إتمام الطلب',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.textPrimary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
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
