class SupabaseConstants {
  // Configurable via --dart-define=SUPABASE_URL=... and --dart-define=SUPABASE_ANON_KEY=...
  // or default to our live Supabase project
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ffqjtixxzgmvoxzzmxdy.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZmcWp0aXh4emdtdm94enpteGR5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTM0NzIyNzUsImV4cCI6MjEwOTA0ODI3NX0.3yzwxb6sSLF779aNqmS2f3JVsMbdx9krx38Z8nBcavE',
  );

  // Google OAuth Web Client ID (Optional for Native GIS / Google Sign-In)
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );

  // Storage Buckets
  static const String productsBucket = 'products';
  static const String bannersBucket = 'banners';
  static const String avatarsBucket = 'avatars';

  // Table Names
  static const String profilesTable = 'profiles';
  static const String categoriesTable = 'categories';
  static const String subcategoriesTable = 'subcategories';
  static const String productsTable = 'products';
  static const String bannersTable = 'banners';
  static const String couponsTable = 'coupons';
  static const String addressesTable = 'addresses';
  static const String ordersTable = 'orders';
  static const String orderItemsTable = 'order_items';
  static const String loyaltyTable = 'loyalty_transactions';
  static const String notificationsTable = 'notifications';
  static const String storeSettingsTable = 'store_settings';
}
