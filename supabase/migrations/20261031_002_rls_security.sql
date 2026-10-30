-- ==============================================================================
-- الديب مول (Aldeeb Mall) - Row-Level Security (RLS) Policies
-- Migration 002: Security policies with optimized (SELECT auth.uid()) subqueries
-- ==============================================================================

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subcategories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.banners ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.coupons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loyalty_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.store_settings ENABLE ROW LEVEL SECURITY;

-- Helper function: Check if current authenticated user is an admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = (SELECT auth.uid()) AND role = 'admin'
  );
$$;

-- ------------------------------------------------------------------------------
-- 1. Profiles Policies
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS "Public profiles are viewable by self and admins" ON public.profiles;
CREATE POLICY "Public profiles are viewable by self and admins"
    ON public.profiles FOR SELECT
    USING ((SELECT auth.uid()) = id OR public.is_admin());

DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
CREATE POLICY "Users can update their own profile"
    ON public.profiles FOR UPDATE
    USING ((SELECT auth.uid()) = id)
    WITH CHECK ((SELECT auth.uid()) = id);

DROP POLICY IF EXISTS "Admins have full access to profiles" ON public.profiles;
CREATE POLICY "Admins have full access to profiles"
    ON public.profiles FOR ALL
    USING (public.is_admin());

-- ------------------------------------------------------------------------------
-- 2. Categories & Subcategories Policies (Public Read, Admin Write)
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS "Categories are viewable by everyone" ON public.categories;
CREATE POLICY "Categories are viewable by everyone"
    ON public.categories FOR SELECT
    USING (is_active = true OR public.is_admin());

DROP POLICY IF EXISTS "Admins can manage categories" ON public.categories;
CREATE POLICY "Admins can manage categories"
    ON public.categories FOR ALL
    USING (public.is_admin());

DROP POLICY IF EXISTS "Subcategories are viewable by everyone" ON public.subcategories;
CREATE POLICY "Subcategories are viewable by everyone"
    ON public.subcategories FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "Admins can manage subcategories" ON public.subcategories;
CREATE POLICY "Admins can manage subcategories"
    ON public.subcategories FOR ALL
    USING (public.is_admin());

-- ------------------------------------------------------------------------------
-- 3. Products Policies (Public Read, Admin Write)
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS "Active products are viewable by everyone" ON public.products;
CREATE POLICY "Active products are viewable by everyone"
    ON public.products FOR SELECT
    USING (is_active = true OR public.is_admin());

DROP POLICY IF EXISTS "Admins can manage products" ON public.products;
CREATE POLICY "Admins can manage products"
    ON public.products FOR ALL
    USING (public.is_admin());

-- ------------------------------------------------------------------------------
-- 4. Banners Policies (Public Read, Admin Write)
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS "Active banners are viewable by everyone" ON public.banners;
CREATE POLICY "Active banners are viewable by everyone"
    ON public.banners FOR SELECT
    USING (is_active = true OR public.is_admin());

DROP POLICY IF EXISTS "Admins can manage banners" ON public.banners;
CREATE POLICY "Admins can manage banners"
    ON public.banners FOR ALL
    USING (public.is_admin());

-- ------------------------------------------------------------------------------
-- 5. Coupons Policies (Public Read Active, Admin Full)
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS "Active coupons can be validated by authenticated users" ON public.coupons;
CREATE POLICY "Active coupons can be validated by authenticated users"
    ON public.coupons FOR SELECT
    USING (is_active = true OR public.is_admin());

DROP POLICY IF EXISTS "Admins can manage coupons" ON public.coupons;
CREATE POLICY "Admins can manage coupons"
    ON public.coupons FOR ALL
    USING (public.is_admin());

-- ------------------------------------------------------------------------------
-- 6. Addresses Policies (User Owns, Admin Views)
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS "Users can view and manage their own addresses" ON public.addresses;
CREATE POLICY "Users can view and manage their own addresses"
    ON public.addresses FOR ALL
    USING ((SELECT auth.uid()) = user_id OR public.is_admin())
    WITH CHECK ((SELECT auth.uid()) = user_id OR public.is_admin());

-- ------------------------------------------------------------------------------
-- 7. Orders Policies
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS "Users can view their own orders" ON public.orders;
CREATE POLICY "Users can view their own orders"
    ON public.orders FOR SELECT
    USING ((SELECT auth.uid()) = user_id OR public.is_admin());

DROP POLICY IF EXISTS "Users can create their own orders" ON public.orders;
CREATE POLICY "Users can create their own orders"
    ON public.orders FOR INSERT
    WITH CHECK ((SELECT auth.uid()) = user_id OR public.is_admin());

DROP POLICY IF EXISTS "Admins can update orders" ON public.orders;
CREATE POLICY "Admins can update orders"
    ON public.orders FOR UPDATE
    USING (public.is_admin());

-- ------------------------------------------------------------------------------
-- 8. Order Items Policies
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS "Users can view items in their orders" ON public.order_items;
CREATE POLICY "Users can view items in their orders"
    ON public.order_items FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.orders
            WHERE orders.id = order_items.order_id
            AND (orders.user_id = (SELECT auth.uid()) OR public.is_admin())
        )
    );

DROP POLICY IF EXISTS "Users can insert items for their own orders" ON public.order_items;
CREATE POLICY "Users can insert items for their own orders"
    ON public.order_items FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.orders
            WHERE orders.id = order_items.order_id
            AND (orders.user_id = (SELECT auth.uid()) OR public.is_admin())
        )
    );

-- ------------------------------------------------------------------------------
-- 9. Loyalty Transactions Policies
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS "Users can view their own loyalty transactions" ON public.loyalty_transactions;
CREATE POLICY "Users can view their own loyalty transactions"
    ON public.loyalty_transactions FOR SELECT
    USING ((SELECT auth.uid()) = user_id OR public.is_admin());

DROP POLICY IF EXISTS "Admins can insert loyalty transactions" ON public.loyalty_transactions;
CREATE POLICY "Admins can insert loyalty transactions"
    ON public.loyalty_transactions FOR ALL
    USING (public.is_admin());

-- ------------------------------------------------------------------------------
-- 10. Notifications Policies
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS "Users can view their own notifications" ON public.notifications;
CREATE POLICY "Users can view their own notifications"
    ON public.notifications FOR SELECT
    USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can mark notifications as read" ON public.notifications;
CREATE POLICY "Users can mark notifications as read"
    ON public.notifications FOR UPDATE
    USING ((SELECT auth.uid()) = user_id)
    WITH CHECK ((SELECT auth.uid()) = user_id);

-- ------------------------------------------------------------------------------
-- 11. Store Settings Policies
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS "Store settings are viewable by everyone" ON public.store_settings;
CREATE POLICY "Store settings are viewable by everyone"
    ON public.store_settings FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "Only admins can update store settings" ON public.store_settings;
CREATE POLICY "Only admins can update store settings"
    ON public.store_settings FOR UPDATE
    USING (public.is_admin());
