import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/services/supabase_service.dart';
import 'core/services/auth_service.dart';
import 'core/providers/mall_provider.dart';
import 'core/providers/cart_provider.dart';
import 'core/providers/order_provider.dart';
import 'core/providers/recipe_provider.dart';
import 'core/providers/store_settings_provider.dart';
import 'features/home/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase and Auth Services
  await SupabaseService().initialize();
  AuthService().initialize();

  runApp(const AldeebMallApp());
}

class AldeebMallApp extends StatelessWidget {
  const AldeebMallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => MallProvider()..loadMallData()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => RecipeProvider()),
        ChangeNotifierProvider(create: (_) => StoreSettingsProvider()),
      ],
      child: Consumer<StoreSettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: '${settings.storeNameAr} | ${settings.storeNameEn}',
            debugShowCheckedModeBanner: false,
            theme: settings.lightThemeData,
            darkTheme: settings.darkThemeData,
            themeMode: settings.themeMode,
            locale: const Locale('ar', 'AE'),
            builder: (context, child) {
              return Directionality(
                textDirection: TextDirection.rtl,
                child: child ?? const SizedBox(),
              );
            },
            home: const MainNavigationScreen(),
          );
        },
      ),
    );
  }
}
