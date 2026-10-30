class SupabaseConstants {
  // Replace these with your Supabase Project details from Project Settings -> API
  static const String supabaseUrl = 'https://YOUR_PROJECT_ID.supabase.co';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

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
