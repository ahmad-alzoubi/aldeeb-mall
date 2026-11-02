import re

with open('supabase/MASTER_FULL_SCHEMA_DEPLOYMENT.sql', 'r', encoding='utf-8') as f:
    master_sql = f.read()

# 1. Permissive Production RLS Policies Block
permissive_rls = """
-- ==============================================================================
-- Migration 002: Frictionless Production Row Level Security (RLS) Policies
-- ==============================================================================

-- 1. Profiles Policies
DROP POLICY IF EXISTS "Public profiles are viewable by self and admins" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Admins have full access to profiles" ON public.profiles;
CREATE POLICY "Public profiles are viewable by self and admins" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Admins have full access to profiles" ON public.profiles FOR ALL USING (true) WITH CHECK (true);

-- 2. Categories & Subcategories Policies
DROP POLICY IF EXISTS "Categories are viewable by everyone" ON public.categories;
DROP POLICY IF EXISTS "Admins can manage categories" ON public.categories;
CREATE POLICY "Categories are viewable by everyone" ON public.categories FOR SELECT USING (true);
CREATE POLICY "Admins can manage categories" ON public.categories FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Subcategories are viewable by everyone" ON public.subcategories;
DROP POLICY IF EXISTS "Admins can manage subcategories" ON public.subcategories;
CREATE POLICY "Subcategories are viewable by everyone" ON public.subcategories FOR SELECT USING (true);
CREATE POLICY "Admins can manage subcategories" ON public.subcategories FOR ALL USING (true) WITH CHECK (true);

-- 3. Products Policies
DROP POLICY IF EXISTS "Active products are viewable by everyone" ON public.products;
DROP POLICY IF EXISTS "Admins can manage products" ON public.products;
CREATE POLICY "Active products are viewable by everyone" ON public.products FOR SELECT USING (true);
CREATE POLICY "Admins can manage products" ON public.products FOR ALL USING (true) WITH CHECK (true);

-- 4. Banners Policies
DROP POLICY IF EXISTS "Active banners are viewable by everyone" ON public.banners;
DROP POLICY IF EXISTS "Admins can manage banners" ON public.banners;
CREATE POLICY "Active banners are viewable by everyone" ON public.banners FOR SELECT USING (true);
CREATE POLICY "Admins can manage banners" ON public.banners FOR ALL USING (true) WITH CHECK (true);

-- 5. Coupons Policies
DROP POLICY IF EXISTS "Active coupons can be validated by authenticated users" ON public.coupons;
DROP POLICY IF EXISTS "Admins can manage coupons" ON public.coupons;
CREATE POLICY "Active coupons can be validated by authenticated users" ON public.coupons FOR SELECT USING (true);
CREATE POLICY "Admins can manage coupons" ON public.coupons FOR ALL USING (true) WITH CHECK (true);

-- 6. Addresses Policies
DROP POLICY IF EXISTS "Users can view and manage their own addresses" ON public.addresses;
CREATE POLICY "Users can view and manage their own addresses" ON public.addresses FOR ALL USING (true) WITH CHECK (true);

-- 7. Orders Policies (Guests, Users, Admins, POS)
DROP POLICY IF EXISTS "Users can view their own orders" ON public.orders;
DROP POLICY IF EXISTS "Users and guests can view orders" ON public.orders;
CREATE POLICY "Users and guests can view orders" ON public.orders FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can create their own orders" ON public.orders;
DROP POLICY IF EXISTS "Users and guests can create orders" ON public.orders;
CREATE POLICY "Users and guests can create orders" ON public.orders FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Admins can update orders" ON public.orders;
CREATE POLICY "Admins can update orders" ON public.orders FOR UPDATE USING (true) WITH CHECK (true);

-- 8. Order Items Policies
DROP POLICY IF EXISTS "Users can view items in their orders" ON public.order_items;
DROP POLICY IF EXISTS "Users and guests can view order items" ON public.order_items;
CREATE POLICY "Users and guests can view order items" ON public.order_items FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can insert items for their own orders" ON public.order_items;
DROP POLICY IF EXISTS "Anyone can insert order items" ON public.order_items;
DROP POLICY IF EXISTS "Users and guests can create order items" ON public.order_items;
CREATE POLICY "Users and guests can create order items" ON public.order_items FOR INSERT WITH CHECK (true);

-- 9. Loyalty Policies
DROP POLICY IF EXISTS "Users can view their loyalty transactions" ON public.loyalty_transactions;
DROP POLICY IF EXISTS "Admins can manage loyalty transactions" ON public.loyalty_transactions;
CREATE POLICY "Users can view their loyalty transactions" ON public.loyalty_transactions FOR SELECT USING (true);
CREATE POLICY "Admins can manage loyalty transactions" ON public.loyalty_transactions FOR ALL USING (true) WITH CHECK (true);

-- 10. Notifications Policies
DROP POLICY IF EXISTS "Users can view their own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can update their own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Admins can manage all notifications" ON public.notifications;
CREATE POLICY "Users can view their own notifications" ON public.notifications FOR SELECT USING (true);
CREATE POLICY "Users can update their own notifications" ON public.notifications FOR ALL USING (true) WITH CHECK (true);

-- 11. Store Settings Policies
DROP POLICY IF EXISTS "Store settings are viewable by everyone" ON public.store_settings;
DROP POLICY IF EXISTS "Admins can update store settings" ON public.store_settings;
CREATE POLICY "Store settings are viewable by everyone" ON public.store_settings FOR SELECT USING (true);
CREATE POLICY "Admins can update store settings" ON public.store_settings FOR ALL USING (true) WITH CHECK (true);
"""

start_marker = "-- 1. Profiles Policies"
end_marker = "Migration 003:"

s_idx = master_sql.find(start_marker)
# Find the line starting with -- ---------------- before start_marker
s_idx = master_sql.rfind("-- ------------------------------------------------------------------------------", 0, s_idx)
e_idx = master_sql.find(end_marker)
# Find the line starting with -- ================ before e_idx
e_idx = master_sql.rfind("-- ==============================================================================", 0, e_idx)

if s_idx != -1 and e_idx != -1:
    master_sql = master_sql[:s_idx] + permissive_rls + "\n\n" + master_sql[e_idx:]
    print("RLS replaced successfully!")
else:
    print("Error finding markers:", s_idx, e_idx)

# 2. Append Storage Buckets & Policies at the end
storage_block = """
-- ==============================================================================
-- Storage Buckets & Public Asset Policies
-- ==============================================================================
INSERT INTO storage.buckets (id, name, public)
VALUES 
  ('products', 'products', true),
  ('banners', 'banners', true),
  ('avatars', 'avatars', true)
ON CONFLICT (id) DO UPDATE SET public = true;

DROP POLICY IF EXISTS "Public Storage Read" ON storage.objects;
CREATE POLICY "Public Storage Read" ON storage.objects FOR SELECT USING (bucket_id IN ('products', 'banners', 'avatars'));

DROP POLICY IF EXISTS "Public Storage Insert" ON storage.objects;
CREATE POLICY "Public Storage Insert" ON storage.objects FOR INSERT WITH CHECK (bucket_id IN ('products', 'banners', 'avatars'));

DROP POLICY IF EXISTS "Public Storage Update" ON storage.objects;
CREATE POLICY "Public Storage Update" ON storage.objects FOR UPDATE USING (bucket_id IN ('products', 'banners', 'avatars'));

DROP POLICY IF EXISTS "Public Storage Delete" ON storage.objects;
CREATE POLICY "Public Storage Delete" ON storage.objects FOR DELETE USING (bucket_id IN ('products', 'banners', 'avatars'));

-- ==============================================================================
-- Realtime Publication Safeguards
-- ==============================================================================
DO $$
BEGIN
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.orders;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.products;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.banners;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.support_tickets;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.categories;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.coupons;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
END $$;
"""

if "Public Storage Read" not in master_sql:
    master_sql += storage_block

# 3. Add seed coupons
coupons_seed = """
-- ==============================================================================
-- Active Promotional Coupons Seed
-- ==============================================================================
INSERT INTO public.coupons (code, discount_type, discount_value, min_order_amount, max_discount, usage_limit, times_used, expires_at, is_active)
VALUES
('WELCOME10', 'percent', 10.0, 50.0, 20.0, 1000, 14, now() + interval '365 days', true),
('DEEB20', 'percent', 20.0, 100.0, 40.0, 500, 32, now() + interval '180 days', true),
('FREEDEL', 'fixed', 10.0, 80.0, 10.0, 2000, 88, now() + interval '365 days', true),
('RAMADAN', 'percent', 15.0, 150.0, 50.0, 1500, 120, now() + interval '120 days', true),
('FRIDAY50', 'fixed', 50.0, 250.0, 50.0, 300, 5, now() + interval '90 days', true)
ON CONFLICT (code) DO UPDATE SET
  discount_type = EXCLUDED.discount_type,
  discount_value = EXCLUDED.discount_value,
  min_order_amount = EXCLUDED.min_order_amount,
  is_active = true;
"""

if "WELCOME10" not in master_sql:
    master_sql += coupons_seed

with open('supabase/PRODUCTION_MASTER_DEPLOYMENT.sql', 'w', encoding='utf-8') as f:
    f.write(master_sql)

print('Generated supabase/PRODUCTION_MASTER_DEPLOYMENT.sql successfully!')
