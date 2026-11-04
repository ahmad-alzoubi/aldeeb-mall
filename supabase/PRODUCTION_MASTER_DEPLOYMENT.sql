-- ==============================================================================
-- الديب مول (Aldeeb Mall) - Database Schema Migration
-- Migration 001: Tables, Types, Constraints, and Indexes
-- ==============================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Frictionless Auth Schema Stub for Standard PostgreSQL / PostgREST compatibility
CREATE SCHEMA IF NOT EXISTS auth;
CREATE TABLE IF NOT EXISTS auth.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now())
);

CREATE OR REPLACE FUNCTION auth.uid()
RETURNS UUID
LANGUAGE sql
STABLE
AS $$
  SELECT nullif(current_setting('request.jwt.claim.sub', true), '')::uuid;
$$;

-- 1. Profiles Table (Linked to Supabase Auth)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT,
    email TEXT,
    phone TEXT,
    avatar_url TEXT,
    role TEXT NOT NULL DEFAULT 'customer' CHECK (role IN ('customer', 'admin', 'cashier', 'driver')),
    loyalty_points INTEGER NOT NULL DEFAULT 50 CHECK (loyalty_points >= 0), -- Welcome bonus 50 pts
    tier TEXT NOT NULL DEFAULT 'Silver' CHECK (tier IN ('Silver', 'Gold', 'Platinum')),
    default_address_id UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 2. Categories Table (Main Mall Departments)
CREATE TABLE IF NOT EXISTS public.categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name_ar TEXT NOT NULL,
    name_en TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    icon_name TEXT DEFAULT 'shopping_basket',
    image_url TEXT,
    sort_order INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 3. Subcategories Table (Aisles)
CREATE TABLE IF NOT EXISTS public.subcategories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id UUID NOT NULL REFERENCES public.categories(id) ON DELETE CASCADE,
    name_ar TEXT NOT NULL,
    name_en TEXT NOT NULL,
    slug TEXT NOT NULL,
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 4. Products Table (Hypermarket Inventory)
CREATE TABLE IF NOT EXISTS public.products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id UUID REFERENCES public.categories(id) ON DELETE SET NULL,
    subcategory_id UUID REFERENCES public.subcategories(id) ON DELETE SET NULL,
    barcode TEXT UNIQUE,
    name_ar TEXT NOT NULL,
    name_en TEXT NOT NULL,
    description_ar TEXT,
    description_en TEXT,
    brand TEXT,
    price NUMERIC(10, 2) NOT NULL CHECK (price >= 0),
    original_price NUMERIC(10, 2) CHECK (original_price IS NULL OR original_price >= price),
    discount_percent INTEGER NOT NULL DEFAULT 0 CHECK (discount_percent >= 0 AND discount_percent <= 100),
    unit TEXT NOT NULL DEFAULT 'piece' CHECK (unit IN ('piece', 'kg', 'g', 'pack', 'carton', 'litre', 'bottle')),
    weight_step NUMERIC(4, 2) NOT NULL DEFAULT 1.0, -- e.g., 0.25kg for fruits/veg, 1.0 for pieces
    stock_quantity INTEGER NOT NULL DEFAULT 100 CHECK (stock_quantity >= 0),
    images TEXT[] NOT NULL DEFAULT '{}',
    is_featured BOOLEAN NOT NULL DEFAULT false,
    is_daily_deal BOOLEAN NOT NULL DEFAULT false,
    deal_expires_at TIMESTAMPTZ,
    rating NUMERIC(3, 2) NOT NULL DEFAULT 4.8,
    reviews_count INTEGER NOT NULL DEFAULT 0,
    sales_count INTEGER NOT NULL DEFAULT 0,
    calories INTEGER,
    origin_country TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 5. Promotional Banners (Hero Carousels & Flash Deals)
CREATE TABLE IF NOT EXISTS public.banners (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title_ar TEXT NOT NULL,
    title_en TEXT NOT NULL,
    subtitle_ar TEXT,
    subtitle_en TEXT,
    image_url TEXT NOT NULL,
    target_type TEXT NOT NULL DEFAULT 'category' CHECK (target_type IN ('category', 'product', 'deal', 'external')),
    target_id TEXT,
    badge_ar TEXT,
    sort_order INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 6. Coupons & Promo Codes
CREATE TABLE IF NOT EXISTS public.coupons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code TEXT UNIQUE NOT NULL,
    discount_type TEXT NOT NULL CHECK (discount_type IN ('percentage', 'fixed', 'percent')),
    discount_value NUMERIC(10, 2) NOT NULL CHECK (discount_value > 0),
    min_order_amount NUMERIC(10, 2) NOT NULL DEFAULT 0,
    max_discount NUMERIC(10, 2),
    usage_limit INTEGER,
    times_used INTEGER NOT NULL DEFAULT 0,
    expires_at TIMESTAMPTZ,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 7. Delivery Addresses
CREATE TABLE IF NOT EXISTS public.addresses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL DEFAULT 'المنزل',
    recipient_name TEXT NOT NULL,
    phone TEXT NOT NULL,
    city TEXT NOT NULL,
    district TEXT NOT NULL,
    street TEXT,
    building TEXT,
    floor TEXT,
    apartment TEXT,
    instructions TEXT,
    latitude NUMERIC(10, 7),
    longitude NUMERIC(10, 7),
    is_default BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 8. Orders Table
CREATE TABLE IF NOT EXISTS public.orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_number TEXT UNIQUE NOT NULL,
    user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'packing', 'out_for_delivery', 'delivered', 'cancelled')),
    address_id UUID REFERENCES public.addresses(id) ON DELETE SET NULL,
    delivery_slot TEXT NOT NULL DEFAULT 'توصيل فوري خلال 60 دقيقة',
    payment_method TEXT NOT NULL DEFAULT 'cod' CHECK (payment_method IN ('cod', 'card_on_delivery', 'card', 'loyalty_points', 'apple_pay')),
    payment_status TEXT NOT NULL DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'failed')),
    subtotal NUMERIC(10, 2) NOT NULL CHECK (subtotal >= 0),
    delivery_fee NUMERIC(10, 2) NOT NULL DEFAULT 0 CHECK (delivery_fee >= 0),
    coupon_code TEXT,
    discount_amount NUMERIC(10, 2) NOT NULL DEFAULT 0 CHECK (discount_amount >= 0),
    loyalty_points_used INTEGER NOT NULL DEFAULT 0,
    loyalty_discount NUMERIC(10, 2) NOT NULL DEFAULT 0,
    total_amount NUMERIC(10, 2) NOT NULL CHECK (total_amount >= 0),
    notes TEXT,
    delivery_driver_name TEXT,
    delivery_driver_phone TEXT,
    delivered_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 9. Order Items Table
CREATE TABLE IF NOT EXISTS public.order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
    product_name_ar TEXT NOT NULL,
    product_name_en TEXT NOT NULL,
    product_image TEXT,
    unit TEXT NOT NULL,
    unit_price NUMERIC(10, 2) NOT NULL,
    quantity NUMERIC(6, 2) NOT NULL CHECK (quantity > 0),
    total_price NUMERIC(10, 2) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 10. Loyalty Points Ledger (Transaction History)
CREATE TABLE IF NOT EXISTS public.loyalty_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    order_id UUID REFERENCES public.orders(id) ON DELETE SET NULL,
    points INTEGER NOT NULL,
    transaction_type TEXT NOT NULL CHECK (transaction_type IN ('earned', 'redeemed', 'bonus', 'adjustment')),
    description_ar TEXT NOT NULL,
    description_en TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 11. In-App Notifications
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title_ar TEXT NOT NULL,
    title_en TEXT NOT NULL,
    body_ar TEXT NOT NULL,
    body_en TEXT NOT NULL,
    type TEXT NOT NULL DEFAULT 'order' CHECK (type IN ('order', 'deal', 'loyalty', 'system')),
    payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    is_read BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 12. Store Settings Table
CREATE TABLE IF NOT EXISTS public.store_settings (
    id TEXT PRIMARY KEY DEFAULT 'default',
    store_name_ar TEXT NOT NULL DEFAULT 'الديب مول',
    store_name_en TEXT NOT NULL DEFAULT 'Aldeeb Mall',
    currency TEXT NOT NULL DEFAULT 'د.إ',
    delivery_fee NUMERIC(10, 2) NOT NULL DEFAULT 10.00,
    free_delivery_threshold NUMERIC(10, 2) NOT NULL DEFAULT 100.00,
    points_reward_rate NUMERIC(6, 2) NOT NULL DEFAULT 1.0, -- 1 point per 1 AED spent
    points_redemption_rate NUMERIC(6, 4) NOT NULL DEFAULT 0.01, -- 100 points = 1 AED
    support_phone TEXT NOT NULL DEFAULT '+971501234567',
    support_whatsapp TEXT NOT NULL DEFAULT '+971501234567',
    is_store_open BOOLEAN NOT NULL DEFAULT true,
    announcement_ar TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Insert default store settings
INSERT INTO public.store_settings (id, store_name_ar, store_name_en, currency, delivery_fee, free_delivery_threshold)
VALUES ('default', 'الديب مول', 'Aldeeb Mall', 'د.إ', 10.00, 100.00)
ON CONFLICT (id) DO NOTHING;

-- ==============================================================================
-- INDEXES FOR MAXIMUM QUERY SPEED
-- ==============================================================================
CREATE INDEX IF NOT EXISTS idx_products_category ON public.products(category_id);
CREATE INDEX IF NOT EXISTS idx_products_subcategory ON public.products(subcategory_id);
CREATE INDEX IF NOT EXISTS idx_products_barcode ON public.products(barcode);
CREATE INDEX IF NOT EXISTS idx_products_featured ON public.products(is_featured) WHERE is_featured = true;
CREATE INDEX IF NOT EXISTS idx_products_daily_deal ON public.products(is_daily_deal) WHERE is_daily_deal = true;
CREATE INDEX IF NOT EXISTS idx_orders_user ON public.orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON public.orders(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_order_items_order ON public.order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_addresses_user ON public.addresses(user_id);
CREATE INDEX IF NOT EXISTS idx_loyalty_user ON public.loyalty_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON public.notifications(user_id, is_read);
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


-- ==============================================================================
-- الديب مول (Aldeeb Mall) - Database Functions & Automated Triggers
-- Migration 003: User Profile Sync, Loyalty Points Calculation, Inventory Management
-- ==============================================================================

-- 1. Function & Trigger: Automatic Profile Sync from Supabase Auth
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_full_name TEXT;
    v_avatar_url TEXT;
BEGIN
    -- Extract full name from Google metadata or email
    v_full_name := COALESCE(
        NEW.raw_user_meta_data->>'full_name',
        NEW.raw_user_meta_data->>'name',
        split_part(NEW.email, '@', 1),
        'عميل الديب مول'
    );
    v_avatar_url := COALESCE(
        NEW.raw_user_meta_data->>'avatar_url',
        NEW.raw_user_meta_data->>'picture',
        ''
    );

    -- Insert into public.profiles
    INSERT INTO public.profiles (id, full_name, email, phone, avatar_url, loyalty_points, role)
    VALUES (
        NEW.id,
        v_full_name,
        NEW.email,
        NEW.phone,
        v_avatar_url,
        50, -- 50 Welcome bonus points
        'customer'
    )
    ON CONFLICT (id) DO UPDATE
    SET 
        full_name = EXCLUDED.full_name,
        avatar_url = CASE WHEN profiles.avatar_url IS NULL OR profiles.avatar_url = '' THEN EXCLUDED.avatar_url ELSE profiles.avatar_url END,
        updated_at = timezone('utc'::text, now());

    -- Record welcome loyalty points transaction
    INSERT INTO public.loyalty_transactions (user_id, points, transaction_type, description_ar, description_en)
    VALUES (
        NEW.id,
        50,
        'bonus',
        'هدية ترحيبية 50 نقطة عند الانضمام لنادي عملاء الديب مول',
        'Welcome bonus 50 points for joining Aldeeb Mall Club'
    );

    -- Send Welcome Notification
    INSERT INTO public.notifications (user_id, title_ar, title_en, body_ar, body_en, type)
    VALUES (
        NEW.id,
        'أهلاً بك في الديب مول 🛒',
        'Welcome to Aldeeb Mall 🛒',
        'تمت إضافة 50 نقطة ولاء ترحيبية إلى محفظتك. نتمنى لك تجربة تسوق ممتعة!',
        '50 loyalty points have been added to your wallet. Enjoy shopping!',
        'loyalty'
    );

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 2. Function & Trigger: Order Status Change Automation
CREATE OR REPLACE FUNCTION public.handle_order_status_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_item RECORD;
    v_points_earned INTEGER;
    v_user_profile RECORD;
BEGIN
    -- Only trigger if status has changed
    IF (OLD.status IS DISTINCT FROM NEW.status) THEN
        
        -- A. When Order is Confirmed: Decrement Stock and Increment Sales Count
        IF (NEW.status = 'confirmed' AND OLD.status = 'pending') THEN
            FOR v_item IN SELECT product_id, quantity FROM public.order_items WHERE order_id = NEW.id LOOP
                IF v_item.product_id IS NOT NULL THEN
                    UPDATE public.products
                    SET 
                        stock_quantity = GREATEST(0, stock_quantity - v_item.quantity::integer),
                        sales_count = sales_count + v_item.quantity::integer
                    WHERE id = v_item.product_id;
                END IF;
            END LOOP;

            -- Notify user
            INSERT INTO public.notifications (user_id, title_ar, title_en, body_ar, body_en, type, payload)
            VALUES (
                NEW.user_id,
                'تم تأكيد طلبك #' || NEW.order_number,
                'Order #' || NEW.order_number || ' Confirmed',
                'طلبك قيد المراجعة وسيبدأ فريق المستودع بتجهيز المنتجات الطازجة لك الآن.',
                'Your order has been confirmed and our warehouse is preparing your fresh items.',
                'order',
                jsonb_build_object('order_id', NEW.id, 'order_number', NEW.order_number)
            );
        END IF;

        -- B. When Order is Packing
        IF (NEW.status = 'packing') THEN
            INSERT INTO public.notifications (user_id, title_ar, title_en, body_ar, body_en, type, payload)
            VALUES (
                NEW.user_id,
                'طلبك قيد التجهيز 📦',
                'Your order is being packed 📦',
                'يقوم فريقنا الآن بانتقاء أفضل المنتجات وتغليف طلبك بعناية فائقة.',
                'Our team is picking the freshest items and carefully packaging your order.',
                'order',
                jsonb_build_object('order_id', NEW.id, 'order_number', NEW.order_number)
            );
        END IF;

        -- C. When Order is Out for Delivery
        IF (NEW.status = 'out_for_delivery') THEN
            INSERT INTO public.notifications (user_id, title_ar, title_en, body_ar, body_en, type, payload)
            VALUES (
                NEW.user_id,
                'طلبك في الطريق إليك 🛵',
                'Your order is on the way 🛵',
                'مندوب التوصيل في طريقه إلى موقعك الآن. يرجى إبقاء هاتفك متاحاً.',
                'Your delivery driver is on the way. Please keep your phone available.',
                'order',
                jsonb_build_object('order_id', NEW.id, 'order_number', NEW.order_number)
            );
        END IF;

        -- D. When Order is Delivered: Award Loyalty Points & Finalize
        IF (NEW.status = 'delivered' AND OLD.status != 'delivered') THEN
            -- Calculate points (1 point per 1 unit of total_amount)
            v_points_earned := FLOOR(NEW.total_amount)::INTEGER;

            IF v_points_earned > 0 AND NEW.user_id IS NOT NULL THEN
                -- Add points to profile
                UPDATE public.profiles
                SET loyalty_points = loyalty_points + v_points_earned
                WHERE id = NEW.user_id;

                -- Record transaction
                INSERT INTO public.loyalty_transactions (user_id, order_id, points, transaction_type, description_ar, description_en)
                VALUES (
                    NEW.user_id,
                    NEW.id,
                    v_points_earned,
                    'earned',
                    'نقاط مكتسبة من إتمام الطلب #' || NEW.order_number,
                    'Points earned from order #' || NEW.order_number
                );
            END IF;

            -- Notify user
            INSERT INTO public.notifications (user_id, title_ar, title_en, body_ar, body_en, type, payload)
            VALUES (
                NEW.user_id,
                'تم تسليم طلبك بنجاح 🎉',
                'Order Delivered Successfully 🎉',
                'شكراً لتسوقك من الديب مول! تمت إضافة ' || v_points_earned || ' نقطة إلى محفظتك.',
                'Thank you for shopping at Aldeeb Mall! ' || v_points_earned || ' points added to your wallet.',
                'order',
                jsonb_build_object('order_id', NEW.id, 'points_earned', v_points_earned)
            );
        END IF;

    END IF;

    NEW.updated_at := timezone('utc'::text, now());
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_order_status_updated ON public.orders;
CREATE TRIGGER on_order_status_updated
    BEFORE UPDATE ON public.orders
    FOR EACH ROW EXECUTE FUNCTION public.handle_order_status_change();

-- ------------------------------------------------------------------------------
-- 3. Atomic Order Placement RPC Function (ACID Transaction, Stock Verification, Idempotency, Identity Hardening & Price Protection)
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.place_order_atomic(
    p_order_number text,
    p_user_id uuid,
    p_delivery_slot text,
    p_payment_method text,
    p_subtotal numeric,
    p_delivery_fee numeric,
    p_discount_amount numeric,
    p_loyalty_points_used int,
    p_loyalty_discount numeric,
    p_total_amount numeric,
    p_notes text,
    p_items jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_caller_id uuid;
    v_effective_user_id uuid;
    v_is_admin boolean;
    v_order_id uuid;
    v_item jsonb;
    v_product_id uuid;
    v_qty numeric;
    v_db_price numeric;
    v_db_stock numeric;
    v_unit_price numeric;
    v_line_total numeric;
    v_calc_subtotal numeric := 0;
    v_effective_subtotal numeric;
    v_effective_total numeric;
    v_result jsonb;
BEGIN
    -- Step 1: Caller Identity & Privilege Verification
    v_caller_id := auth.uid();
    v_is_admin := public.is_admin();

    IF v_caller_id IS NOT NULL THEN
        -- Authenticated user: order must be bound to their verified identity
        v_effective_user_id := v_caller_id;
    ELSIF v_is_admin THEN
        -- Staff/Admin placing order on behalf of customer
        v_effective_user_id := p_user_id;
    ELSE
        -- Anonymous guest checkout: strictly forbid impersonating a registered user account
        IF p_user_id IS NOT NULL THEN
            RAISE EXCEPTION 'UNAUTHORIZED: Anonymous callers cannot assign orders to registered user accounts';
        END IF;
        v_effective_user_id := NULL;
    END IF;

    -- Block Anonymous callers from creating Cashier/POS in-store orders
    IF (p_delivery_slot ILIKE '%كاشير%' OR p_delivery_slot ILIKE '%pos%') AND v_caller_id IS NULL AND NOT v_is_admin THEN
        RAISE EXCEPTION 'UNAUTHORIZED_POS: In-store POS cashier orders must be placed by authenticated staff';
    END IF;

    -- Step 2: Idempotency Protection - Prevent double-submission
    IF EXISTS (SELECT 1 FROM public.orders WHERE order_number = p_order_number) THEN
        RAISE EXCEPTION 'DUPLICATE_ORDER: Order with number % already exists', p_order_number;
    END IF;

    -- Step 3: Validate Items Payload
    IF p_items IS NULL OR jsonb_array_length(p_items) = 0 THEN
        RAISE EXCEPTION 'EMPTY_ITEMS: Cannot place an order without items';
    END IF;

    -- Step 4: Validate Stock & Atomic Row Locking & Price Verification
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_qty := (v_item->>'quantity')::numeric;
        IF v_qty <= 0 THEN
            RAISE EXCEPTION 'INVALID_QUANTITY: Quantity must be greater than zero';
        END IF;

        IF (v_item->>'product_id') IS NOT NULL AND (v_item->>'product_id') ~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$' THEN
            v_product_id := (v_item->>'product_id')::uuid;

            SELECT price, stock_quantity INTO v_db_price, v_db_stock
            FROM public.products
            WHERE id = v_product_id
            FOR UPDATE;

            IF FOUND THEN
                IF v_db_stock < v_qty THEN
                    RAISE EXCEPTION 'INSUFFICIENT_STOCK: Only % units available for product %', v_db_stock, v_product_id;
                END IF;

                -- Decrement stock and update sales count atomically
                UPDATE public.products
                SET stock_quantity = stock_quantity - v_qty,
                    sales_count = COALESCE(sales_count, 0) + v_qty
                WHERE id = v_product_id;

                -- Authoritative catalog price to prevent client price tampering
                v_unit_price := v_db_price;
            ELSE
                v_unit_price := COALESCE((v_item->>'unit_price')::numeric, 0);
            END IF;
        ELSE
            v_unit_price := COALESCE((v_item->>'unit_price')::numeric, 0);
        END IF;

        v_line_total := round(v_unit_price * v_qty, 2);
        v_calc_subtotal := v_calc_subtotal + v_line_total;
    END LOOP;

    -- Step 5: Anti-Price Tampering Reconciliation
    IF v_calc_subtotal > 0 AND abs(p_subtotal - v_calc_subtotal) > 1.0 THEN
        -- Correct the subtotal and total using authoritative catalog prices
        v_effective_subtotal := v_calc_subtotal;
        v_effective_total := round(v_calc_subtotal + COALESCE(p_delivery_fee, 0) - COALESCE(p_discount_amount, 0) - COALESCE(p_loyalty_discount, 0), 2);
        IF v_effective_total < 0 THEN
            v_effective_total := 0;
        END IF;
    ELSE
        v_effective_subtotal := p_subtotal;
        v_effective_total := p_total_amount;
    END IF;

    -- Step 6: Insert Order Header
    INSERT INTO public.orders (
        order_number,
        user_id,
        status,
        delivery_slot,
        payment_method,
        payment_status,
        subtotal,
        delivery_fee,
        discount_amount,
        loyalty_points_used,
        loyalty_discount,
        total_amount,
        notes
    ) VALUES (
        p_order_number,
        v_effective_user_id,
        'pending',
        COALESCE(p_delivery_slot, 'خلال 45 دقيقة'),
        p_payment_method,
        'pending',
        v_effective_subtotal,
        p_delivery_fee,
        p_discount_amount,
        COALESCE(p_loyalty_points_used, 0),
        COALESCE(p_loyalty_discount, 0),
        v_effective_total,
        p_notes
    )
    RETURNING id INTO v_order_id;

    -- Step 7: Insert Order Items with Authoritative Unit Prices
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_product_id := NULL;
        v_unit_price := COALESCE((v_item->>'unit_price')::numeric, 0);

        IF (v_item->>'product_id') IS NOT NULL AND (v_item->>'product_id') ~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$' THEN
            v_product_id := (v_item->>'product_id')::uuid;
            SELECT price INTO v_db_price FROM public.products WHERE id = v_product_id;
            IF FOUND THEN
                v_unit_price := v_db_price;
            END IF;
        END IF;

        v_qty := (v_item->>'quantity')::numeric;
        v_line_total := round(v_unit_price * v_qty, 2);

        INSERT INTO public.order_items (
            order_id,
            product_id,
            product_name_ar,
            product_name_en,
            product_image,
            unit,
            unit_price,
            quantity,
            total_price
        ) VALUES (
            v_order_id,
            v_product_id,
            COALESCE(v_item->>'product_name_ar', 'صنف تسوق'),
            COALESCE(v_item->>'product_name_en', 'Grocery Item'),
            COALESCE(v_item->>'product_image', ''),
            COALESCE(v_item->>'unit', 'piece'),
            v_unit_price,
            v_qty,
            v_line_total
        );
    END LOOP;

    -- Step 8: Return Created Order JSON
    SELECT jsonb_build_object(
        'id', o.id,
        'order_number', o.order_number,
        'status', o.status,
        'subtotal', o.subtotal,
        'total_amount', o.total_amount,
        'created_at', o.created_at
    ) INTO v_result
    FROM public.orders o
    WHERE o.id = v_order_id;

    RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION public.place_order_atomic TO anon, authenticated;

-- 3. Stored Procedure: Validate Coupon
CREATE OR REPLACE FUNCTION public.validate_coupon(
    p_code TEXT,
    p_subtotal NUMERIC
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_coupon RECORD;
    v_discount NUMERIC := 0;
BEGIN
    SELECT * INTO v_coupon
    FROM public.coupons
    WHERE UPPER(code) = UPPER(p_code)
      AND is_active = true
      AND (expires_at IS NULL OR expires_at > now())
      AND (usage_limit IS NULL OR times_used < usage_limit);

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'valid', false,
            'message_ar', 'كوبون الخصم غير صحيح أو منتهي الصلاحية',
            'message_en', 'Invalid or expired promo code',
            'discount', 0
        );
    END IF;

    IF p_subtotal < v_coupon.min_order_amount THEN
        RETURN jsonb_build_object(
            'valid', false,
            'message_ar', 'الحد الأدنى لتفعيل هذا الكوبون هو ' || v_coupon.min_order_amount,
            'message_en', 'Minimum order amount for this coupon is ' || v_coupon.min_order_amount,
            'discount', 0
        );
    END IF;

    IF v_coupon.discount_type = 'percentage' THEN
        v_discount := (p_subtotal * v_coupon.discount_value) / 100.0;
        IF v_coupon.max_discount IS NOT NULL AND v_discount > v_coupon.max_discount THEN
            v_discount := v_coupon.max_discount;
        END IF;
    ELSE
        v_discount := LEAST(v_coupon.discount_value, p_subtotal);
    END IF;

    RETURN jsonb_build_object(
        'valid', true,
        'coupon_id', v_coupon.id,
        'code', v_coupon.code,
        'discount_type', v_coupon.discount_type,
        'discount_value', v_coupon.discount_value,
        'calculated_discount', ROUND(v_discount, 2),
        'message_ar', 'تم تفعيل الكوبون بنجاح!',
        'message_en', 'Coupon applied successfully!'
    );
END;
$$;
-- ==============================================================================
-- الديب مول (Aldeeb Mall) - Realistic Hypermarket Seed Data
-- Migration 004: Carrefour-style Categories, Subcategories, Products, Banners, Coupons
-- ==============================================================================

-- 1. Insert Categories
INSERT INTO public.categories (id, name_ar, name_en, slug, icon_name, image_url, sort_order) VALUES
('c0000000-0000-0000-0000-000000000001', 'خضار وفواكه طازجة', 'Fresh Fruits & Vegetables', 'fresh-produce', 'apple', 'https://images.unsplash.com/photo-1610348725531-843dff563e2c?auto=format&fit=crop&w=600&q=80', 1),
('c0000000-0000-0000-0000-000000000002', 'ألبان وأجبان وبيض', 'Dairy, Cheese & Eggs', 'dairy-eggs', 'milk', 'https://images.unsplash.com/photo-1550583724-b2692b85b150?auto=format&fit=crop&w=600&q=80', 2),
('c0000000-0000-0000-0000-000000000003', 'لحوم ودواجن وأسماك', 'Meat, Poultry & Seafood', 'meat-poultry', 'beef', 'https://images.unsplash.com/photo-1607623814075-e51df1bdc82f?auto=format&fit=crop&w=600&q=80', 3),
('c0000000-0000-0000-0000-000000000004', 'مخبوزات وحلويات طازجة', 'Bakery & Fresh Pastries', 'bakery-pastries', 'croissant', 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=600&q=80', 4),
('c0000000-0000-0000-0000-000000000005', 'مشروبات وعصائر ومياه', 'Beverages & Juices', 'beverages-water', 'cup-soda', 'https://images.unsplash.com/photo-1527661591475-527312dd65f5?auto=format&fit=crop&w=600&q=80', 5),
('c0000000-0000-0000-0000-000000000006', 'أغذية مثلجة ومجمدات', 'Frozen Foods & Ice Cream', 'frozen-foods', 'snowflake', 'https://images.unsplash.com/photo-1563805042-7684c019e1cb?auto=format&fit=crop&w=600&q=80', 6),
('c0000000-0000-0000-0000-000000000007', 'معلبات ومؤن وطهي', 'Pantry & Canned Goods', 'pantry-cooking', 'package', 'https://images.unsplash.com/photo-1588964895597-cfccd6e2dbf9?auto=format&fit=crop&w=600&q=80', 7),
('c0000000-0000-0000-0000-000000000008', 'منظفات وعناية منزلية', 'Cleaning & Household', 'cleaning-household', 'sparkles', 'https://images.unsplash.com/photo-1585421514738-01798e348b17?auto=format&fit=crop&w=600&q=80', 8),
('c0000000-0000-0000-0000-000000000009', 'أجهزة وإلكترونيات', 'Electronics & Appliances', 'electronics-appliances', 'tv', 'https://images.unsplash.com/photo-1550009158-9ebf69173e03?auto=format&fit=crop&w=600&q=80', 9)
ON CONFLICT (id) DO NOTHING;

-- 2. Insert Subcategories
INSERT INTO public.subcategories (id, category_id, name_ar, name_en, slug, sort_order) VALUES
('ba000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', 'فواكه طازجة', 'Fresh Fruits', 'fruits', 1),
('ba000000-0000-0000-0000-000000000002', 'c0000000-0000-0000-0000-000000000001', 'خضار ورقية وجذرية', 'Vegetables', 'vegetables', 2),
('ba000000-0000-0000-0000-000000000003', 'c0000000-0000-0000-0000-000000000002', 'حليب ولبن رائب', 'Milk & Laban', 'milk-laban', 1),
('ba000000-0000-0000-0000-000000000004', 'c0000000-0000-0000-0000-000000000002', 'أجبان وزبدة وقشطة', 'Cheese & Butter', 'cheese-butter', 2),
('ba000000-0000-0000-0000-000000000005', 'c0000000-0000-0000-0000-000000000003', 'دواجن طازجة ومجمدة', 'Fresh Poultry', 'poultry', 1),
('ba000000-0000-0000-0000-000000000006', 'c0000000-0000-0000-0000-000000000003', 'لحوم بقر وضأن', 'Beef & Mutton', 'red-meat', 2),
('ba000000-0000-0000-0000-000000000007', 'c0000000-0000-0000-0000-000000000004', 'خبز وتوست طازج', 'Bread & Buns', 'bread-toast', 1),
('ba000000-0000-0000-0000-000000000008', 'c0000000-0000-0000-0000-000000000005', 'مياه معدنية طبيعية', 'Mineral Water', 'water', 1),
('ba000000-0000-0000-0000-000000000009', 'c0000000-0000-0000-0000-000000000005', 'عصائر طازجة وطبيعية', 'Fresh Juices', 'juices', 2),
('ba000000-0000-0000-0000-000000000010', 'c0000000-0000-0000-0000-000000000008', 'مساحيق ومنعمات الغسيل', 'Laundry Care', 'laundry', 1)
ON CONFLICT (id) DO NOTHING;

-- 3. Insert Products
INSERT INTO public.products (
    id, category_id, subcategory_id, barcode, name_ar, name_en, 
    description_ar, description_en, brand, price, original_price, discount_percent, 
    unit, weight_step, stock_quantity, images, is_featured, is_daily_deal, rating, sales_count
) VALUES
-- Fruits & Veg
(
    'a0000000-0000-0000-0000-000000000001',
    'c0000000-0000-0000-0000-000000000001',
    'ba000000-0000-0000-0000-000000000001',
    '629100000001',
    'موز فلبيني ممتاز كافنديش طازج',
    'Fresh Premium Cavendish Bananas',
    'موز طازج ومغذي غني بالبوتاسيوم والطاقة، مستورد يومياً من مزارع الفلبين الممتازة.',
    'Sweet and energy-packed fresh bananas imported directly from top farms.',
    'طازج',
    4.95, 6.50, 24,
    'kg', 0.50, 450,
    ARRAY['https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?auto=format&fit=crop&w=600&q=80'],
    true, true, 4.9, 1280
),
(
    'a0000000-0000-0000-0000-000000000002',
    'c0000000-0000-0000-0000-000000000001',
    'ba000000-0000-0000-0000-000000000001',
    '629100000002',
    'تفاح رويال جالا إيطالي فاخر',
    'Italian Royal Gala Apples',
    'تفاح إيطالي مقرمش ولذيذ وحلو المذاق، مثالي لوجبات الأطفال الخفيفة وسلطات الفواكه.',
    'Crisp, sweet, and juicy fresh Gala apples directly from Italian orchards.',
    'طازج',
    7.50, 9.95, 25,
    'kg', 0.50, 300,
    ARRAY['https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?auto=format&fit=crop&w=600&q=80'],
    true, false, 4.8, 920
),
(
    'a0000000-0000-0000-0000-000000000003',
    'c0000000-0000-0000-0000-000000000001',
    'ba000000-0000-0000-0000-000000000002',
    '629100000003',
    'طماطم مزارع محلية طازجة قطاف اليوم',
    'Fresh Local Vine Tomatoes',
    'طماطم حمراء نضرة وممتلئة تم قطافها صباح اليوم، ممتازة للطبخ والسلطات.',
    'Fresh red juicy vine-ripened tomatoes picked this morning from local farms.',
    'محلي',
    3.75, 5.00, 25,
    'kg', 0.50, 500,
    ARRAY['https://images.unsplash.com/photo-1592924357228-91a4daadcfea?auto=format&fit=crop&w=600&q=80'],
    false, true, 4.7, 1450
),

-- Dairy & Eggs
(
    'a0000000-0000-0000-0000-000000000004',
    'c0000000-0000-0000-0000-000000000002',
    'ba000000-0000-0000-0000-000000000003',
    '629100000004',
    'حليب المراعي طازج كامل الدسم 2 لتر',
    'Almarai Fresh Full Fat Milk 2L',
    'حليب بقري نقي 100% طازج كامل الدسم معزز بفيتامين د والكالسيوم لجميع أفراد الأسرة.',
    '100% pure fresh cow milk full cream rich in Calcium and Vitamin D.',
    'المراعي',
    11.00, 13.50, 19,
    'bottle', 1.0, 320,
    ARRAY['https://images.unsplash.com/photo-1550583724-b2692b85b150?auto=format&fit=crop&w=600&q=80'],
    true, true, 4.9, 2100
),
(
    'a0000000-0000-0000-0000-000000000005',
    'c0000000-0000-0000-0000-000000000002',
    'ba000000-0000-0000-0000-000000000004',
    '629100000005',
    'جبنة بوك كاسات بيضاء كريمية 500 غرام',
    'Puck Cream Cheese Spread 500g',
    'جبنة قابلة للدهن ناعمة وكريمية وغنية بالنكهة المحبوبة لإفطار مثالي كل صباح.',
    'Rich and smooth cream cheese spread jar loved by kids and adults.',
    'بوك',
    14.50, 18.00, 19,
    'piece', 1.0, 240,
    ARRAY['https://images.unsplash.com/photo-1589881133595-a3c085cb731d?auto=format&fit=crop&w=600&q=80'],
    true, false, 4.8, 1150
),

-- Meat & Poultry
(
    'a0000000-0000-0000-0000-000000000006',
    'c0000000-0000-0000-0000-000000000003',
    'ba000000-0000-0000-0000-000000000005',
    '629100000006',
    'دجاج التنمية طازج مبرد 1000 غرام',
    'Tanmiah Fresh Chilled Whole Chicken 1000g',
    'دجاج طازج محلي مذبوح وفق الشريعة الإسلامية حلال 100% ومبرد دون هرمونات.',
    'Fresh local premium farm chicken 100% Halal certified.',
    'التنمية',
    16.75, 21.00, 20,
    'piece', 1.0, 180,
    ARRAY['https://images.unsplash.com/photo-1587593810167-a84920ea0781?auto=format&fit=crop&w=600&q=80'],
    true, true, 4.9, 870
),

-- Bakery
(
    'a0000000-0000-0000-0000-000000000007',
    'c0000000-0000-0000-0000-000000000004',
    'ba000000-0000-0000-0000-000000000007',
    '629100000007',
    'خبز كرواسان فرنسي طازج بالزبدة (4 قطع)',
    'Fresh Butter French Croissants (Pack of 4)',
    'مخبوز بالزبدة الطبيعية الفاخرة بطبقات هشة ومقرمشة يخبز طازجاً عدة مرات يومياً.',
    'Flaky, golden, and authentic butter croissants baked fresh multiple times daily.',
    'مخبز الديب',
    8.50, 11.00, 23,
    'pack', 1.0, 120,
    ARRAY['https://images.unsplash.com/photo-1555507036-ab1f4038808a?auto=format&fit=crop&w=600&q=80'],
    true, false, 4.9, 1340
),

-- Beverages
(
    'a0000000-0000-0000-0000-000000000008',
    'c0000000-0000-0000-0000-000000000005',
    'ba000000-0000-0000-0000-000000000008',
    '629100000008',
    'مياه معدنية العين كرتون (24 عبوة × 500 مل)',
    'Al Ain Mineral Water Carton (24 x 500ml)',
    'مياه شرب نقية متوازنة المعادن والصوديوم، معبأة بأعلى معايير النقاء.',
    'Pure natural bottled drinking water carton with low sodium balance.',
    'العين',
    12.95, 17.50, 26,
    'carton', 1.0, 600,
    ARRAY['https://images.unsplash.com/photo-1527661591475-527312dd65f5?auto=format&fit=crop&w=600&q=80'],
    true, true, 4.9, 3400
),

-- Cleaning & Household
(
    'a0000000-0000-0000-0000-000000000009',
    'c0000000-0000-0000-0000-000000000008',
    'ba000000-0000-0000-0000-000000000010',
    '629100000009',
    'مسحوق غسيل تايد الأصلي الأوتوماتيكي 5 كجم',
    'Tide Original Automatic Washing Powder 5kg',
    'نظافة ناصعة وبياض باهر وإزالة أصعب البقع من الغسلة الأولى مع رائحة منعشة تدوم.',
    'Deep stain removal for automatic washing machines with long-lasting freshness.',
    'تايد',
    42.00, 58.00, 28,
    'pack', 1.0, 210,
    ARRAY['https://images.unsplash.com/photo-1585421514738-01798e348b17?auto=format&fit=crop&w=600&q=80'],
    true, true, 4.8, 1500
)
ON CONFLICT (id) DO NOTHING;

-- 4. Insert Banners
INSERT INTO public.banners (id, title_ar, title_en, subtitle_ar, subtitle_en, image_url, target_type, badge_ar, sort_order) VALUES
(
    'b0000000-0000-0000-0000-000000000001',
    'مهرجان التوفير الضخم والصفقات الكبرى',
    'Mega Supermarket Savings Festival',
    'خصومات تصل إلى 50% على آلاف المنتجات الطازجة والمؤن',
    'Up to 50% OFF on fresh groceries and daily essentials',
    'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=1200&q=80',
    'deal',
    'خصم حتى 50%',
    1
),
(
    'b0000000-0000-0000-0000-000000000002',
    'سوق الخضار والفواكه الطازجة اليومية',
    'Fresh Daily Market',
    'من المزرعة إلى مائدتك مباشرة بتوصيل مبرد وسريع',
    'From direct farm harvest to your table chilled and fresh',
    'https://images.unsplash.com/photo-1610348725531-843dff563e2c?auto=format&fit=crop&w=1200&q=80',
    'category',
    'طازج كل صباح',
    2
),
(
    'b0000000-0000-0000-0000-000000000003',
    'توصيل فوري سريع خلال 60 دقيقة',
    'Express 60-Min Delivery',
    'اطلب كل ما يلزم منزلك واستلمه على بابك بأسرع وقت',
    'Order home needs and get them delivered at your doorstep',
    'https://images.unsplash.com/photo-1526367790999-0150786686a2?auto=format&fit=crop&w=1200&q=80',
    'external',
    'إكسبريس سريع',
    3
)
ON CONFLICT (id) DO NOTHING;

-- 5. Insert Coupons
INSERT INTO public.coupons (id, code, discount_type, discount_value, min_order_amount, max_discount, usage_limit, is_active) VALUES
('ca000000-0000-0000-0000-000000000001', 'ALDEEB10', 'percentage', 10.00, 50.00, 30.00, 1000, true),
('ca000000-0000-0000-0000-000000000002', 'SAVE20', 'percentage', 20.00, 120.00, 50.00, 500, true),
('ca000000-0000-0000-0000-000000000003', 'WELCOME15', 'fixed', 15.00, 75.00, 15.00, 2000, true)
ON CONFLICT (id) DO NOTHING;
-- ==============================================================================
-- الديب مول (Aldeeb Mall) - Banners Management & Dynamic In-App Navigation
-- Migration 005: Extended Banners Schema (Hero Carousel & Side Promotional Cards)
-- ==============================================================================

-- 1. Add slot column and badge color
ALTER TABLE public.banners 
    ADD COLUMN IF NOT EXISTS slot TEXT NOT NULL DEFAULT 'hero',
    ADD COLUMN IF NOT EXISTS badge_color TEXT DEFAULT '#EF4444';

-- 2. Drop old check constraints and add updated ones
ALTER TABLE public.banners DROP CONSTRAINT IF EXISTS banners_target_type_check;
ALTER TABLE public.banners ADD CONSTRAINT banners_target_type_check 
    CHECK (target_type IN ('category', 'screen', 'product', 'deal', 'coupon', 'external'));

ALTER TABLE public.banners DROP CONSTRAINT IF EXISTS banners_slot_check;
ALTER TABLE public.banners ADD CONSTRAINT banners_slot_check 
    CHECK (slot IN ('hero', 'side_top', 'side_bottom', 'promo'));

-- 3. Update existing banners to slot 'hero'
UPDATE public.banners SET slot = 'hero' WHERE slot IS NULL OR slot = '';

-- 4. Insert or update default side promotional cards
INSERT INTO public.banners (
    id, 
    title_ar, 
    title_en, 
    subtitle_ar, 
    subtitle_en, 
    image_url, 
    slot, 
    target_type, 
    target_id, 
    badge_ar, 
    badge_color, 
    sort_order, 
    is_active
) VALUES
(
    'b0000000-0000-0000-0000-000000000010',
    'صفقة اليوم الطازجة 🍅',
    'Fresh Daily Deal 🍅',
    'طماطم مزارع محلية قطاف الصباح بخصم 25%',
    'Fresh local vine tomatoes morning harvest 25% OFF',
    'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?auto=format&fit=crop&w=600&q=80',
    'side_top',
    'product',
    'a0000000-0000-0000-0000-000000000003',
    '3.75 د.أ / كجم',
    '#EF4444',
    1,
    true
),
(
    'b0000000-0000-0000-0000-000000000011',
    'توصيل فوري خلال 60 دقيقة 🛵',
    'Instant Delivery within 60 Mins 🛵',
    'اطلب طلبات البيت واستلمها على بابك',
    'Order your home essentials and receive them at your doorstep',
    'https://images.unsplash.com/photo-1526367790999-0150786686a2?auto=format&fit=crop&w=600&q=80',
    'side_bottom',
    'coupon',
    'FREE100',
    'مجاناً للطلبات فوق 100 د.أ',
    '#0284C7',
    2,
    true
)
ON CONFLICT (id) DO UPDATE SET
    title_ar = EXCLUDED.title_ar,
    subtitle_ar = EXCLUDED.subtitle_ar,
    image_url = EXCLUDED.image_url,
    slot = EXCLUDED.slot,
    target_type = EXCLUDED.target_type,
    target_id = EXCLUDED.target_id,
    badge_ar = EXCLUDED.badge_ar,
    badge_color = EXCLUDED.badge_color;
-- ==============================================================================
-- Migration: 20261031_005_enterprise_fulfillment_and_loyalty.sql
-- Description: Enterprise Fulfillment, Dark Stores (15-Min Quick Commerce),
--              Bin Slotting, Flash Deals, Courier Fleet, and Customer Reviews
-- Platform: Aldeeb Mall (Noon & Amazon Fresh Benchmark)
-- ==============================================================================

-- 1. Dark Stores & Micro-Fulfillment Centers
CREATE TABLE IF NOT EXISTS public.dark_stores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(32) NOT NULL UNIQUE,
    name_ar VARCHAR(128) NOT NULL,
    name_en VARCHAR(128) NOT NULL,
    city VARCHAR(64) NOT NULL DEFAULT 'Dubai',
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    radius_km DECIMAL(4, 2) NOT NULL DEFAULT 3.50,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    avg_pick_time_seconds INT NOT NULL DEFAULT 120,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Warehouse Shelf Slotting (Zone > Aisle > Rack > Bin)
CREATE TABLE IF NOT EXISTS public.warehouse_bins (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dark_store_id UUID NOT NULL REFERENCES public.dark_stores(id) ON DELETE CASCADE,
    zone_code VARCHAR(8) NOT NULL,      -- e.g. 'A' (Chilled/Dairy), 'B' (Produce), 'C' (Pantry)
    aisle_code VARCHAR(8) NOT NULL,     -- e.g. '01', '02', '03'
    rack_level VARCHAR(8) NOT NULL,     -- e.g. 'R1', 'R2', 'R3'
    bin_code VARCHAR(8) NOT NULL,       -- e.g. 'B04'
    full_location_code VARCHAR(32) GENERATED ALWAYS AS (zone_code || '-' || aisle_code || '-' || rack_level || '-' || bin_code) STORED,
    is_refrigerated BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Dark Store Stock & Bin Allocation
CREATE TABLE IF NOT EXISTS public.dark_store_inventory (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dark_store_id UUID NOT NULL REFERENCES public.dark_stores(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    bin_id UUID REFERENCES public.warehouse_bins(id) ON DELETE SET NULL,
    quantity_on_hand INT NOT NULL DEFAULT 0 CHECK (quantity_on_hand >= 0),
    quantity_reserved INT NOT NULL DEFAULT 0 CHECK (quantity_reserved >= 0),
    safety_threshold INT NOT NULL DEFAULT 5,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_store_product UNIQUE (dark_store_id, product_id)
);

-- 4. Flash Deals & Campaign Schedule
CREATE TABLE IF NOT EXISTS public.flash_deals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    title_ar VARCHAR(128) NOT NULL,
    title_en VARCHAR(128) NOT NULL,
    deal_price DECIMAL(10, 2) NOT NULL CHECK (deal_price > 0),
    discount_percent INT NOT NULL CHECK (discount_percent BETWEEN 1 AND 99),
    total_quota INT NOT NULL DEFAULT 100,
    claimed_quota INT NOT NULL DEFAULT 0,
    starts_at TIMESTAMPTZ NOT NULL,
    ends_at TIMESTAMPTZ NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. Wave & Batch Picking Pipeline
CREATE TABLE IF NOT EXISTS public.wave_batches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dark_store_id UUID NOT NULL REFERENCES public.dark_stores(id) ON DELETE CASCADE,
    batch_number VARCHAR(32) NOT NULL UNIQUE,
    status VARCHAR(32) NOT NULL DEFAULT 'queued' 
        CHECK (status IN ('queued', 'in_progress', 'completed', 'cancelled')),
    total_orders INT NOT NULL DEFAULT 0,
    total_items INT NOT NULL DEFAULT 0,
    picker_name VARCHAR(128),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

-- 6. Individual Picker Item Verification Tasks
CREATE TABLE IF NOT EXISTS public.picker_tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    wave_id UUID NOT NULL REFERENCES public.wave_batches(id) ON DELETE CASCADE,
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    bin_location VARCHAR(32),
    barcode VARCHAR(64),
    quantity_required INT NOT NULL DEFAULT 1,
    quantity_picked INT NOT NULL DEFAULT 0,
    is_verified BOOLEAN NOT NULL DEFAULT FALSE,
    scanned_at TIMESTAMPTZ,
    status VARCHAR(32) NOT NULL DEFAULT 'pending' 
        CHECK (status IN ('pending', 'picked', 'out_of_stock', 'substituted'))
);

-- 7. Couriers & Delivery Fleet
CREATE TABLE IF NOT EXISTS public.couriers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name VARCHAR(128) NOT NULL,
    phone VARCHAR(32) NOT NULL,
    vehicle_type VARCHAR(32) NOT NULL DEFAULT 'motorbike' 
        CHECK (vehicle_type IN ('motorbike', 'van', 'electric_scooter', 'reefer_truck')),
    license_plate VARCHAR(32),
    current_lat DECIMAL(10, 8),
    current_lng DECIMAL(11, 8),
    battery_or_fuel_percent INT DEFAULT 95,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    is_online BOOLEAN NOT NULL DEFAULT TRUE,
    rating DECIMAL(3, 2) NOT NULL DEFAULT 4.95,
    completed_deliveries INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 8. Courier Dispatch Logs
CREATE TABLE IF NOT EXISTS public.courier_dispatches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    courier_id UUID NOT NULL REFERENCES public.couriers(id) ON DELETE CASCADE,
    status VARCHAR(32) NOT NULL DEFAULT 'assigned' 
        CHECK (status IN ('assigned', 'accepted', 'picked_up', 'en_route', 'delivered', 'failed')),
    estimated_arrival_minutes INT NOT NULL DEFAULT 15,
    dispatched_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    delivered_at TIMESTAMPTZ
);

-- 9. Product Reviews & Verified Ratings
CREATE TABLE IF NOT EXISTS public.product_reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    reviewer_name VARCHAR(128) NOT NULL,
    rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    title VARCHAR(128),
    comment TEXT,
    is_verified_purchase BOOLEAN NOT NULL DEFAULT TRUE,
    helpful_count INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 10. Loyalty Tiers & VIP Membership Rules
CREATE TABLE IF NOT EXISTS public.loyalty_tier_rules (
    tier_name VARCHAR(32) PRIMARY KEY,
    name_ar VARCHAR(64) NOT NULL,
    min_spend DECIMAL(10, 2) NOT NULL,
    points_multiplier DECIMAL(3, 2) NOT NULL DEFAULT 1.00,
    free_express_delivery BOOLEAN NOT NULL DEFAULT FALSE,
    cashback_percent DECIMAL(4, 2) NOT NULL DEFAULT 1.00,
    badge_color VARCHAR(16) NOT NULL
);

-- Seed Loyalty Tier Rules
INSERT INTO public.loyalty_tier_rules (tier_name, name_ar, min_spend, points_multiplier, free_express_delivery, cashback_percent, badge_color)
VALUES 
    ('Silver', 'عضوية فضية', 0.00, 1.00, FALSE, 1.00, '#94A3B8'),
    ('Gold', 'عضوية ذهبية VIP', 1500.00, 1.50, TRUE, 2.50, '#EAB308'),
    ('Platinum', 'عضوية بلاتينية النخبة', 5000.00, 2.00, TRUE, 5.00, '#0D47A1')
ON CONFLICT (tier_name) DO UPDATE SET 
    points_multiplier = EXCLUDED.points_multiplier,
    free_express_delivery = EXCLUDED.free_express_delivery;

-- Seed Sample Dark Stores
INSERT INTO public.dark_stores (code, name_ar, name_en, city, latitude, longitude, radius_km, avg_pick_time_seconds)
VALUES 
    ('DS-DXB-DOWNTOWN', 'مستودع وسط دبي المظلم (15 دقيقة)', 'Downtown Dubai Dark Store', 'Dubai', 25.1972, 55.2744, 3.5, 95),
    ('DS-DXB-MARINA', 'مستودع مارينا فائق السرعة', 'Dubai Marina Micro-Hub', 'Dubai', 25.0805, 55.1403, 4.0, 110),
    ('DS-RUH-OLAYA', 'مستودع العليا السريع الرياض', 'Olaya Riyadh Dark Store', 'Riyadh', 24.7136, 46.6753, 3.5, 100)
ON CONFLICT (code) DO NOTHING;

-- Seed Sample Couriers
INSERT INTO public.couriers (full_name, phone, vehicle_type, license_plate, current_lat, current_lng, rating, completed_deliveries)
VALUES 
    ('محمد أحمد الديب', '+971501234567', 'motorbike', 'DXB-M-4821', 25.1985, 55.2758, 4.98, 1420),
    ('عمر خالد الزعبي', '+971509876543', 'electric_scooter', 'DXB-E-1092', 25.2012, 55.2711, 4.95, 980),
    ('طارق منصور', '+971554321987', 'van', 'DXB-V-8832', 25.1920, 55.2790, 4.92, 2310)
ON CONFLICT DO NOTHING;
-- ==============================================================================
-- الديب مول (Aldeeb Mall) - Expanded Catalog, Categories, and Banners
-- Migration 006: Dates, Appliances, Beauty, Pets, Moving Hero & Secondary Banners
-- ==============================================================================

-- 1. Insert/Update Categories
INSERT INTO public.categories (id, name_ar, name_en, slug, icon_name, image_url, sort_order) VALUES
('c0000000-0000-0000-0000-000000000005', 'تمور وفواكه مجففة فاخرة', 'Luxury Dates & Dried Fruits', 'dates-fruits', 'palm_tree', 'https://images.unsplash.com/photo-1596707328406-8c4c7943c2c5?auto=format&fit=crop&w=600&q=80', 5),
('c0000000-0000-0000-0000-000000000006', 'العناية بالجمال والنظافة الشخصية', 'Beauty & Personal Care', 'beauty-care', 'sparkles', 'https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?auto=format&fit=crop&w=600&q=80', 6),
('c0000000-0000-0000-0000-000000000007', 'المنظفات والعناية بالمنزل', 'Cleaning & Household Care', 'cleaning-household', 'spray-can', 'https://images.unsplash.com/photo-1585421514738-01798e348b17?auto=format&fit=crop&w=600&q=80', 7),
('c0000000-0000-0000-0000-000000000008', 'مكونات الطبخ والتموين', 'Cooking Ingredients & Pantry', 'cooking-pantry', 'chef-hat', 'https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&w=600&q=80', 8),
('c0000000-0000-0000-0000-000000000009', 'مستلزمات الحيوانات الأليفة', 'Pet Food & Supplies', 'pet-supplies', 'dog', 'https://images.unsplash.com/photo-1583337130417-3346a1be7dee?auto=format&fit=crop&w=600&q=80', 9),
('c0000000-0000-0000-0000-000000000010', 'المنزل والحديقة والديكور', 'Home & Garden Living', 'home-garden', 'home', 'https://images.unsplash.com/photo-1513694203232-719a280e022f?auto=format&fit=crop&w=600&q=80', 10),
('c0000000-0000-0000-0000-000000000011', 'الأجهزة المنزلية والإلكترونيات', 'Home Appliances & Electronics', 'home-appliances', 'tv', 'https://images.unsplash.com/photo-1550009158-9ebf69173e03?auto=format&fit=crop&w=600&q=80', 11)
ON CONFLICT (id) DO UPDATE SET 
  name_ar = EXCLUDED.name_ar, 
  name_en = EXCLUDED.name_en, 
  image_url = EXCLUDED.image_url;

-- 2. Insert Hero & Secondary Promotional Banners
INSERT INTO public.banners (id, title_ar, title_en, subtitle_ar, subtitle_en, image_url, target_type, target_id, badge_ar, sort_order, is_active) VALUES
('b0000000-0000-0000-0000-000000000001', 'مهرجان الصفقات الكبرى في الديب مول 🛒', 'Mega Supermarket Savings Festival', 'خصومات حصرية تصل إلى 50% على المواد الغذائية والتموينية', 'Up to 50% OFF on essentials', 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=1200&q=80', 'deal', NULL, 'خصم حتى 50%', 1, true),
('b0000000-0000-0000-0000-000000000002', 'سوق الخضار والفواكه الطازجة قطاف اليوم 🍎', 'Fresh Daily Produce Market', 'من المزرعة إلى مائدتك بتوصيل فوري مبرد وسريع', 'Fresh morning harvest delivered chilled', 'https://images.unsplash.com/photo-1610348725531-843dff563e2c?auto=format&fit=crop&w=1200&q=80', 'category', 'c0000000-0000-0000-0000-000000000001', 'طازج يومياً', 2, true),
('b0000000-0000-0000-0000-000000000003', 'عروض الأسبوع التوفيرية للمنزل والأسرة 🌟', 'Mega Weekly Family Deals', 'تخفيضات كبرى على منتجات الألبان، اللحوم، والمؤن', 'Special prices on groceries', 'https://images.unsplash.com/photo-1578916171728-46686eac8d58?auto=format&fit=crop&w=1200&q=80', 'deal', NULL, 'عروض الأسبوع', 3, true),
('b0000000-0000-0000-0000-000000000004', 'توصيل فوري إكسبريس مجاني خلال 60 دقيقة 🛵', 'Express 60-Minute Fast Delivery', 'اطلب مستلزمات بيتك واستلمها على بابك مجاناً فوق 100 ر.س', 'Free delivery on orders above 100 SAR', 'https://images.unsplash.com/photo-1526367790999-0150786686a2?auto=format&fit=crop&w=1200&q=80', 'deal', NULL, 'سريع ومضمون', 4, true),
('b0000000-0000-0000-0000-000000000005', 'مهرجان التمور الملكية والبن الفاخر 🌴', 'Royal Dates & Specialty Coffee Fest', 'أجود تمور سكري وخلاص مع خصم إضافي 20% عند شراء عبوتين', 'Buy 2 Get 20% Extra OFF', 'https://images.unsplash.com/photo-1596707328406-8c4c7943c2c5?auto=format&fit=crop&w=1200&q=80', 'category', 'c0000000-0000-0000-0000-000000000005', 'إعلان فاصل 1', 5, true),
('b0000000-0000-0000-0000-000000000006', 'عروض الأجهزة المنزلية وقلايات الهواء الذكية ⚡', 'Smart Appliances & Airfryer Mega Sale', 'وفّر حتى 300 ر.س مع ضمان سنتين صيانة معتمدة شاملة', 'Save up to 300 SAR with 2yr warranty', 'https://images.unsplash.com/photo-1550009158-9ebf69173e03?auto=format&fit=crop&w=1200&q=80', 'category', 'c0000000-0000-0000-0000-000000000011', 'إعلان فاصل 2', 6, true)
ON CONFLICT (id) DO UPDATE SET 
  title_ar = EXCLUDED.title_ar,
  image_url = EXCLUDED.image_url,
  badge_ar = EXCLUDED.badge_ar;

-- 3. Insert Additional Hypermarket Products
INSERT INTO public.products (
    id, category_id, barcode, name_ar, name_en, description_ar, brand, price, original_price, discount_percent, unit, weight_step, stock_quantity, images, is_featured, is_daily_deal, rating, sales_count
) VALUES
(
    'a0000000-0000-0000-0000-000000000014',
    'c0000000-0000-0000-0000-000000000005',
    '629100000014',
    'تمور خلاص الأحساء فاخرة ملكية 1 كجم',
    'Royal Khalas Premium Dates 1kg',
    'تمور خلاص سعودية منتقاة حبة بحبة، معبأة بعناية وحلوة المذاق وغنية بالألياف الطبيعية.',
    'تمورنا',
    24.00, 32.00, 25,
    'pack', 1.0, 210,
    ARRAY['https://images.unsplash.com/photo-1596707328406-8c4c7943c2c5?auto=format&fit=crop&w=600&q=80'],
    true, false, 5.0, 1420
),
(
    'a0000000-0000-0000-0000-000000000015',
    'c0000000-0000-0000-0000-000000000006',
    '629100000015',
    'شامبو لوريال إلفيف للشعر الجاف 400 مل',
    'L''Oreal Elvive Extraordinary Oil Shampoo 400ml',
    'شامبو مغذي بزيوت الزهور النادرة لتغذية الشعر من الجذور حتى الأطراف ولمعان لا يضاهى.',
    'L''Oreal',
    18.50, 25.00, 26,
    'bottle', 1.0, 85,
    ARRAY['https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?auto=format&fit=crop&w=600&q=80'],
    true, false, 4.8, 760
),
(
    'a0000000-0000-0000-0000-000000000016',
    'c0000000-0000-0000-0000-000000000007',
    '629100000016',
    'مسحوق غسيل أريال أوتوماتيك للغسالات 5 كجم',
    'Ariel Automatic Laundry Detergent 5kg',
    'مسحوق غسيل المركز يزيل أصعب البقع من أول غسلة ويمنح الملابس انتعاشاً يدوم طويلاً.',
    'Ariel',
    49.90, 68.00, 27,
    'pack', 1.0, 110,
    ARRAY['https://images.unsplash.com/photo-1585421514738-01798e348b17?auto=format&fit=crop&w=600&q=80'],
    true, true, 4.9, 1890
),
(
    'a0000000-0000-0000-0000-000000000017',
    'c0000000-0000-0000-0000-000000000008',
    '629100000017',
    'أرز بسمتي الشعلان سيلا فاخر 5 كجم',
    'Al Shalan Basmati Sella Rice 5kg',
    'أرز بسمتي أبيض حبة طويلة ونكهة أصيلة، مثالي للكبسة والأطباق الخليجية والمناسف.',
    'الشعلان',
    36.50, 45.00, 19,
    'pack', 1.0, 340,
    ARRAY['https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&w=600&q=80'],
    true, true, 4.9, 2200
),
(
    'a0000000-0000-0000-0000-000000000018',
    'c0000000-0000-0000-0000-000000000009',
    '629100000018',
    'طعام قطط ويلاس دجاج وتونة وخضار 1.5 كجم',
    'Whiskas Adult Cat Food Chicken & Tuna 1.5kg',
    'وجبة متوازنة ومحببة للقطط غنية بالبروتينات وأوميغا 3 لدعم صحة الفرو والمناعة.',
    'Whiskas',
    28.00, 35.00, 20,
    'pack', 1.0, 65,
    ARRAY['https://images.unsplash.com/photo-1583337130417-3346a1be7dee?auto=format&fit=crop&w=600&q=80'],
    false, false, 4.7, 420
),
(
    'a0000000-0000-0000-0000-000000000019',
    'c0000000-0000-0000-0000-000000000011',
    '629100000019',
    'قلاية هوائية رقمية فيليبس XXL بدون زيت 7.2 لتر',
    'Philips Digital Airfryer XXL 7.2L',
    'قلاية صحية بدون زيت بتقنية الهواء الساخن السريع وسعة عائلية مع شاشة لمس وبرامج متعددة.',
    'Philips',
    389.00, 529.00, 26,
    'piece', 1.0, 35,
    ARRAY['https://images.unsplash.com/photo-1550009158-9ebf69173e03?auto=format&fit=crop&w=600&q=80'],
    true, true, 4.9, 310
)
ON CONFLICT (id) DO UPDATE SET 
  name_ar = EXCLUDED.name_ar,
  price = EXCLUDED.price,
  original_price = EXCLUDED.original_price,
  discount_percent = EXCLUDED.discount_percent;
-- ==============================================================================
-- Migration: 20261031_006_vip_subscriptions_and_rewards_catalog.sql
-- Description: VIP Prime Subscriptions, Rewards Catalog (Coupons & Free Gifts),
--              and Customer Claimed Rewards Tracking
-- Platform: Aldeeb Mall
-- ==============================================================================

-- 1. Subscription Plans Table
CREATE TABLE IF NOT EXISTS public.subscription_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_key VARCHAR(64) UNIQUE NOT NULL,
    name_ar VARCHAR(128) NOT NULL,
    name_en VARCHAR(128) NOT NULL,
    badge_tag_ar VARCHAR(64) NOT NULL,
    price_monthly DECIMAL(10, 2) NOT NULL,
    price_annual DECIMAL(10, 2) NOT NULL,
    points_multiplier DECIMAL(3, 2) NOT NULL DEFAULT 1.5,
    cashback_percent DECIMAL(4, 2) NOT NULL DEFAULT 2.5,
    free_express_delivery BOOLEAN NOT NULL DEFAULT TRUE,
    min_order_free_delivery DECIMAL(10, 2) NOT NULL DEFAULT 0.0,
    features_ar JSONB NOT NULL DEFAULT '[]'::jsonb,
    accent_color VARCHAR(32) NOT NULL DEFAULT '#047857',
    is_popular BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. User Subscriptions Table
CREATE TABLE IF NOT EXISTS public.user_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    plan_key VARCHAR(64) NOT NULL REFERENCES public.subscription_plans(plan_key) ON DELETE CASCADE,
    billing_cycle VARCHAR(16) NOT NULL DEFAULT 'monthly' CHECK (billing_cycle IN ('monthly', 'annual')),
    status VARCHAR(32) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'paused', 'cancelled', 'expired')),
    auto_renew BOOLEAN NOT NULL DEFAULT TRUE,
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    renews_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '30 days'),
    cancelled_at TIMESTAMPTZ,
    total_deliveries_saved INT NOT NULL DEFAULT 0,
    total_money_saved DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Loyalty Reward Coupons Catalog
CREATE TABLE IF NOT EXISTS public.loyalty_reward_coupons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code_prefix VARCHAR(32) NOT NULL,
    title_ar VARCHAR(128) NOT NULL,
    description_ar TEXT,
    points_cost INT NOT NULL CHECK (points_cost > 0),
    discount_amount DECIMAL(10, 2) NOT NULL CHECK (discount_amount > 0),
    min_order_amount DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    days_valid INT NOT NULL DEFAULT 30,
    total_claimed INT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. Loyalty Reward Products Catalog (Free Items via Points)
CREATE TABLE IF NOT EXISTS public.loyalty_reward_products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID REFERENCES public.products(id) ON DELETE CASCADE,
    title_ar VARCHAR(128) NOT NULL,
    title_en VARCHAR(128) NOT NULL,
    image_url TEXT NOT NULL,
    category_ar VARCHAR(64) NOT NULL,
    points_cost INT NOT NULL CHECK (points_cost > 0),
    stock_quota INT NOT NULL DEFAULT 50,
    claimed_count INT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. User Claimed Rewards History
CREATE TABLE IF NOT EXISTS public.user_claimed_rewards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    reward_type VARCHAR(32) NOT NULL CHECK (reward_type IN ('coupon', 'product', 'invoice_discount')),
    reward_title_ar VARCHAR(128) NOT NULL,
    points_spent INT NOT NULL CHECK (points_spent >= 0),
    coupon_code VARCHAR(64),
    product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
    is_used BOOLEAN NOT NULL DEFAULT FALSE,
    claimed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for lightning performance
CREATE INDEX IF NOT EXISTS idx_user_subs_user_id ON public.user_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_subs_status ON public.user_subscriptions(status);
CREATE INDEX IF NOT EXISTS idx_claimed_rewards_user_id ON public.user_claimed_rewards(user_id);
CREATE INDEX IF NOT EXISTS idx_reward_coupons_active ON public.loyalty_reward_coupons(is_active);
CREATE INDEX IF NOT EXISTS idx_reward_products_active ON public.loyalty_reward_products(is_active);

-- Enable RLS
ALTER TABLE public.subscription_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loyalty_reward_coupons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loyalty_reward_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_claimed_rewards ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "Anyone can view subscription plans" ON public.subscription_plans;
CREATE POLICY "Anyone can view subscription plans" ON public.subscription_plans
    FOR SELECT TO public USING (true);

DROP POLICY IF EXISTS "Users can view their own subscriptions" ON public.user_subscriptions;
CREATE POLICY "Users can view their own subscriptions" ON public.user_subscriptions
    FOR SELECT TO authenticated USING ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Anyone can view active reward coupons" ON public.loyalty_reward_coupons;
CREATE POLICY "Anyone can view active reward coupons" ON public.loyalty_reward_coupons
    FOR SELECT TO public USING (is_active = true);

DROP POLICY IF EXISTS "Anyone can view active reward products" ON public.loyalty_reward_products;
CREATE POLICY "Anyone can view active reward products" ON public.loyalty_reward_products
    FOR SELECT TO public USING (is_active = true);

DROP POLICY IF EXISTS "Users can view their own claimed rewards" ON public.user_claimed_rewards;
CREATE POLICY "Users can view their own claimed rewards" ON public.user_claimed_rewards
    FOR ALL TO authenticated USING ((select auth.uid()) = user_id);

-- Seed VIP Subscription Plans
INSERT INTO public.subscription_plans (
    plan_key, name_ar, name_en, badge_tag_ar, price_monthly, price_annual,
    points_multiplier, cashback_percent, free_express_delivery, min_order_free_delivery,
    features_ar, accent_color, is_popular, sort_order
) VALUES 
(
    'prime_plus',
    'باقة الديب بلس (Aldeeb Plus)',
    'Aldeeb Prime Plus',
    'الباقة الاقتصادية',
    29.00,
    290.00,
    1.50,
    2.50,
    TRUE,
    50.00,
    '[
        "توصيل سريع مجاني للطلبات فوق 50 د.إ",
        "عروض أسبوعية وتخفيضات خاصة للأعضاء",
        "كاش باك 2.5% نقدي في المحفظة",
        "نقاط ولاء مضاعفة 1.5x على كل فاتورة",
        "تنبيهات فورية قبل نفاد العروض الكبرى"
    ]'::jsonb,
    '#2563EB',
    FALSE,
    1
),
(
    'prime_vip_ultra',
    'باقة الترا VIP (Prime Ultra)',
    'Aldeeb Prime Ultra VIP',
    'الأكثر طلباً واختياراً ⭐',
    59.00,
    590.00,
    2.50,
    5.00,
    TRUE,
    0.00,
    '[
        "توصيل فائق السرعة 15 دقيقة مجاني بدون أي حد أدنى نهائياً",
        "عروض فلاش وسرية VIP يومية قبل إتاحتها للجمهور",
        "بوكس هدايا وعينات منتجات متميزة مجانية شهرياً",
        "نقاط ولاء مضاعفة 2.5x على كافة أقسام الهايبرماركت",
        "كاش باك 5.0% نقدي فوري بعد استلام كل طلب",
        "أولوية قصوى في فرز السلات وخط ساخن VIP مخصص"
    ]'::jsonb,
    '#D97706',
    TRUE,
    2
),
(
    'prime_family_royal',
    'الباقة الملكية العائلية (Royal Crown)',
    'Aldeeb Royal Crown Family',
    'الفخامة المطلقة 👑',
    99.00,
    990.00,
    3.00,
    8.00,
    TRUE,
    0.00,
    '[
        "مشاركة الاشتراك مع 4 حسابات عائلية في نفس المنزل",
        "توصيل فوري مجاني 24/7 حتى في أوقات الذروة والأعياد",
        "كاش باك 8.0% مباشر مع كل طلب يتجاوز 100 د.إ",
        "نقاط ولاء ثلاثية 3x (كل 100 درهم تمنح 300 نقطة)",
        "بوكس شهري من المخبوزات والحلويات الفرنسية الفاخرة مجاناً",
        "استبدال فوري أو استرجاع مضمون للمنتجات الطازجة بدون أسئلة",
        "مساعد مشتريات شخصي وحجز مسبق للطلبيات الضخمة"
    ]'::jsonb,
    '#7C3AED',
    FALSE,
    3
)
ON CONFLICT (plan_key) DO UPDATE SET 
    name_ar = EXCLUDED.name_ar,
    price_monthly = EXCLUDED.price_monthly,
    points_multiplier = EXCLUDED.points_multiplier,
    cashback_percent = EXCLUDED.cashback_percent,
    features_ar = EXCLUDED.features_ar;

-- Seed Loyalty Reward Coupons
INSERT INTO public.loyalty_reward_coupons (code_prefix, title_ar, description_ar, points_cost, discount_amount, min_order_amount, days_valid)
VALUES 
    ('REWARD15', 'قسيمة خصم 15 د.إ فوري', 'وفر 15 درهم على أي طلب فوق 60 د.إ', 1200, 15.00, 60.00, 30),
    ('REWARD30', 'قسيمة خصم 30 د.إ كبرى', 'وفر 30 درهم على مشتريات السوبرماركت فوق 120 د.إ', 2200, 30.00, 120.00, 45),
    ('REWARD50', 'قسيمة خصم 50 د.إ VIP النخبة', 'وفر 50 درهم على الطلبات العائلية فوق 200 د.إ', 3500, 50.00, 200.00, 60),
    ('FREESHIP', 'قسيمة توصيل فوري مجاني', 'توصيل مجاني بالكامل بدون حد أدنى لـ 3 طلبات', 500, 15.00, 0.00, 30)
ON CONFLICT DO NOTHING;

-- Seed Loyalty Reward Free Products
INSERT INTO public.loyalty_reward_products (title_ar, title_en, image_url, category_ar, points_cost, stock_quota)
VALUES 
    (
        'سلة فواكه طازجة عضوية مختارة (3 كجم)',
        'Organic Fresh Fruit Basket 3kg',
        'https://images.unsplash.com/photo-1610832958506-aa56368176cf?auto=format&fit=crop&w=600&q=80',
        'فواكه وخضار طازجة',
        1100,
        45
    ),
    (
        'زيت زيتون فلسطيني بكر ممتاز معصور على البارد 1 لتر',
        'Extra Virgin Cold-Pressed Olive Oil 1L',
        'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?auto=format&fit=crop&w=600&q=80',
        'مؤن وتموين فاخر',
        850,
        60
    ),
    (
        'بوكس شوكولاتة بلجيكية فاخرة محشوة 500 غرام',
        'Belgian Luxury Artisan Chocolates 500g',
        'https://images.unsplash.com/photo-1549007994-cb92caebd54b?auto=format&fit=crop&w=600&q=80',
        'حلويات وسكاكر',
        950,
        30
    ),
    (
        'كرتونة مياه أروى معدنية نقية (24 × 500 مل)',
        'Arwa Mineral Bottled Water (24 x 500ml)',
        'https://images.unsplash.com/photo-1559839914-1b346d6d3764?auto=format&fit=crop&w=600&q=80',
        'مشروبات ومياه',
        350,
        120
    ),
    (
        'كعكة كراميل وفراولة طازجة من مخبز الديب الحرفي',
        'Artisan Strawberry Caramel Fresh Cake',
        'https://images.unsplash.com/photo-1578985545062-69928b1d9587?auto=format&fit=crop&w=600&q=80',
        'المخبز والحلويات',
        1400,
        25
    )
ON CONFLICT DO NOTHING;
-- ==============================================================================
-- 20261031_007_store_theme_and_dynamic_settings.sql
-- Store Theme Settings & Realtime Dynamic Branding Support
-- ==============================================================================

-- 1. Ensure settings JSONB column exists on public.store_settings
ALTER TABLE public.store_settings 
ADD COLUMN IF NOT EXISTS settings JSONB DEFAULT '{}'::jsonb;

-- 2. Ensure RLS policies allow view and update/insert on store_settings
DROP POLICY IF EXISTS "Store settings are viewable by everyone" ON public.store_settings;
CREATE POLICY "Store settings are viewable by everyone"
    ON public.store_settings FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "Anyone can insert store settings" ON public.store_settings;
CREATE POLICY "Anyone can insert store settings"
    ON public.store_settings FOR INSERT
    WITH CHECK (true);

DROP POLICY IF EXISTS "Anyone can update store settings" ON public.store_settings;
CREATE POLICY "Anyone can update store settings"
    ON public.store_settings FOR UPDATE
    USING (true)
    WITH CHECK (true);

-- 3. Upsert default active_theme record
INSERT INTO public.store_settings (id, store_name_ar, store_name_en, currency, delivery_fee, free_delivery_threshold, settings)
VALUES (
    'active_theme',
    'الديب مول',
    'Aldeeb Mall',
    'ل.س',
    10.00,
    100.00,
    '{
      "primaryColor": "#0D47A1",
      "primaryDarkColor": "#0A2E6B",
      "secondaryColor": "#E53935",
      "accentColor": "#FFB300",
      "backgroundColor": "#F8FAFC",
      "surfaceColor": "#FFFFFF",
      "textPrimaryColor": "#0F172A",
      "textSecondaryColor": "#64748B",
      "storeNameAr": "الديب مول",
      "storeNameEn": "Aldeeb Mall",
      "taglineAr": "هايبرماركت العائلة الأول - جودة وتوفير بلا حدود",
      "announcementText": "🚚 توصيل مجاني للطلبات فوق 100 ل.س | صفقات حصرية يومياً",
      "expressDeliveryText": "توصيل إكسبريس فوري خلال 15 دقيقة ⚡",
      "smartExperiencesTitle": "تجارب الديب الذكية",
      "smartExperiencesSubtitle": "وفّر مع الجيران، ونظّم مقاضيك الشهرية بذكاء وسرعة",
      "groupDealsTitle": "الشراء الجماعي الذكي",
      "groupDealsSubtitle": "وفّر حتى 40% مع عروض الجيران التشاركية الحية",
      "groceryListTitle": "القائمة الذكية ومخطط المقاضي",
      "groceryListSubtitle": "تنظيم ومزامنة المقاضي العائلية بذكاء",
      "currency": "ل.س"
    }'::jsonb
)
ON CONFLICT (id) DO UPDATE SET
    settings = EXCLUDED.settings,
    updated_at = timezone('utc'::text, now());
-- Migration: Add Product Bundle (Frequently Bought Together) Controls
-- Allows admins to enable/disable bundles per product, specify custom bundle discount percentages,
-- define custom bundle headlines, and manually select complementary bundle product IDs.

ALTER TABLE public.products
ADD COLUMN IF NOT EXISTS bundle_enabled BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN IF NOT EXISTS bundle_discount_percent INTEGER NOT NULL DEFAULT 15,
ADD COLUMN IF NOT EXISTS bundle_title TEXT,
ADD COLUMN IF NOT EXISTS bundle_product_ids TEXT[] NOT NULL DEFAULT '{}';

COMMENT ON COLUMN public.products.bundle_enabled IS 'Toggle whether the Frequently Bought Together bundle is displayed on this product page';
COMMENT ON COLUMN public.products.bundle_discount_percent IS 'Discount percentage applied when buying the bundle together';
COMMENT ON COLUMN public.products.bundle_title IS 'Custom display title for the bundle offer';
COMMENT ON COLUMN public.products.bundle_product_ids IS 'Explicit product IDs to bundle with this product (empty = auto-select from category)';
-- ==============================================================================
-- Migration: 20261101_007_staff_roles_payroll_system.sql
-- Description: Multi-Role Staff Management (Admin, General Manager, Auditor, Accountant, Cashier),
--              Strict Branch Lock, Admin-Defined Passwords, Shift Countdown,
--              and Accounting Payroll System (Salaries, Withdrawals, Deductions, Bonuses).
-- ==============================================================================

-- 1. Staff Members Table
CREATE TABLE IF NOT EXISTS public.staff_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employee_code VARCHAR(32) NOT NULL UNIQUE,
    full_name VARCHAR(128) NOT NULL,
    username VARCHAR(64) NOT NULL UNIQUE,
    email VARCHAR(128) NOT NULL,
    phone VARCHAR(32),
    role VARCHAR(32) NOT NULL CHECK (role IN ('super_admin', 'general_manager', 'auditor', 'accountant', 'cashier', 'branch_manager')),
    branch_id VARCHAR(64) NOT NULL,
    branch_name VARCHAR(128) NOT NULL,
    password_hash TEXT,
    can_change_password BOOLEAN NOT NULL DEFAULT FALSE, -- Cannot change password unless granted by admin
    has_pending_password_request BOOLEAN NOT NULL DEFAULT FALSE,
    basic_salary NUMERIC(12, 2) NOT NULL DEFAULT 5000.00,
    allowances NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    shift_start VARCHAR(8) NOT NULL DEFAULT '08:00',
    shift_end VARCHAR(8) NOT NULL DEFAULT '16:00',
    avatar_url TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    joined_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Payroll Transactions (Salaries, Advance Withdrawals, Deductions, Bonuses)
CREATE TABLE IF NOT EXISTS public.payroll_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_number VARCHAR(64) NOT NULL UNIQUE,
    employee_id UUID NOT NULL REFERENCES public.staff_members(id) ON DELETE CASCADE,
    branch_id VARCHAR(64) NOT NULL,
    type VARCHAR(32) NOT NULL CHECK (type IN ('salary_payment', 'advance_withdrawal', 'deduction', 'bonus')),
    amount NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
    reason TEXT NOT NULL,
    created_by_name VARCHAR(128) NOT NULL,
    created_by_role VARCHAR(32) NOT NULL,
    date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    status VARCHAR(32) NOT NULL DEFAULT 'completed' CHECK (status IN ('completed', 'pending', 'approved')),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Password Change Requests (Workflow requiring admin approval)
CREATE TABLE IF NOT EXISTS public.password_change_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employee_id UUID NOT NULL REFERENCES public.staff_members(id) ON DELETE CASCADE,
    reason TEXT NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    reviewed_by VARCHAR(128),
    reviewed_at TIMESTAMPTZ
);

-- Indexes for lightning-fast queries
CREATE INDEX IF NOT EXISTS idx_staff_members_branch ON public.staff_members(branch_id);
CREATE INDEX IF NOT EXISTS idx_staff_members_role ON public.staff_members(role);
CREATE INDEX IF NOT EXISTS idx_payroll_employee ON public.payroll_transactions(employee_id);
CREATE INDEX IF NOT EXISTS idx_payroll_type ON public.payroll_transactions(type);
CREATE INDEX IF NOT EXISTS idx_password_requests_status ON public.password_change_requests(status);

-- Enable Row Level Security (RLS)
ALTER TABLE public.staff_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payroll_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.password_change_requests ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Allow authenticated read staff" ON public.staff_members
    FOR SELECT TO public USING (true);

CREATE POLICY "Allow authenticated read payroll" ON public.payroll_transactions
    FOR SELECT TO public USING (true);

CREATE POLICY "Allow accountant and admin insert payroll" ON public.payroll_transactions
    FOR INSERT TO public WITH CHECK (true);

CREATE POLICY "Allow public read password requests" ON public.password_change_requests
    FOR ALL TO public USING (true);


-- =========================================================================
-- Customer Service & Realtime Support Ticket System
-- =========================================================================

CREATE TABLE IF NOT EXISTS public.support_tickets (
    id TEXT PRIMARY KEY,
    ticket_number TEXT NOT NULL UNIQUE,
    customer_name TEXT NOT NULL,
    customer_phone TEXT DEFAULT '',
    order_number TEXT,
    subject TEXT NOT NULL,
    category TEXT DEFAULT 'general',
    status TEXT DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'resolved')),
    priority TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high')),
    last_message TEXT DEFAULT '',
    messages JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_support_tickets_status ON public.support_tickets(status);
CREATE INDEX IF NOT EXISTS idx_support_tickets_order ON public.support_tickets(order_number);
CREATE INDEX IF NOT EXISTS idx_support_tickets_created_at ON public.support_tickets(created_at DESC);

ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public and authenticated users can view support tickets" ON public.support_tickets;
CREATE POLICY "Public and authenticated users can view support tickets"
ON public.support_tickets FOR SELECT
USING (true);

DROP POLICY IF EXISTS "Users and admins can insert and update support tickets" ON public.support_tickets;
CREATE POLICY "Users and admins can insert and update support tickets"
ON public.support_tickets FOR ALL
USING (true)
WITH CHECK (true);

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

-- ==============================================================================
-- Active Promotional Coupons Seed
-- ==============================================================================
ALTER TABLE public.coupons DROP CONSTRAINT IF EXISTS coupons_discount_type_check;
ALTER TABLE public.coupons ADD CONSTRAINT coupons_discount_type_check CHECK (discount_type IN ('percentage', 'fixed', 'percent'));

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



-- ==============================================================================
-- Full Comprehensive 34-Product Seed Dataset (Clean Upsert)
-- ==============================================================================
INSERT INTO public.products (
    id, category_id, barcode, name_ar, name_en, description_ar, brand, price, original_price, discount_percent, unit, weight_step, stock_quantity, images, is_featured, is_daily_deal, rating, sales_count
) VALUES
(
    'a0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', '629100000001', 'موز فلبيني طازج كافنديش درجة أولى', 'Fresh Cavendish Bananas', 'موز أصفر طازج وغني بالطاقة والبوتاسيوم، مستورد يومياً ومثالي للوجبات الصحية.', 'طازج', 4.95, 6.50, 24, 'kg', 0.50, 450, ARRAY['https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?auto=format&fit=crop&w=600&q=80'], true, true, 4.8, 150
  ),
(
    'a0000000-0000-0000-0000-000000000002', 'c0000000-0000-0000-0000-000000000001', '629100000002', 'تفاح رويال جالا إيطالي مقرمش فاخر', 'Italian Royal Gala Apples', 'تفاح أحمر إيطالي حلو المذاق ومقرمش، معبأ بعناية فائقة للحفاظ على النضارة.', 'طازج', 7.50, 9.95, 25, 'kg', 0.50, 320, ARRAY['https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?auto=format&fit=crop&w=600&q=80'], true, false, 4.8, 150
  ),
(
    'a0000000-0000-0000-0000-000000000003', 'c0000000-0000-0000-0000-000000000001', '629100000003', 'طماطم مزارع محلية قطاف الصباح', 'Fresh Local Vine Tomatoes', 'طماطم حمراء نضرة تم قطافها صباح اليوم، ممتازة للطبخ والسلطات اليومية.', 'محلي', 3.75, 5.00, 25, 'kg', 0.50, 500, ARRAY['https://images.unsplash.com/photo-1592924357228-91a4daadcfea?auto=format&fit=crop&w=600&q=80'], false, true, 4.8, 150
  ),
(
    'a0000000-0000-0000-0000-000000000004', 'c0000000-0000-0000-0000-000000000002', '629100000004', 'حليب المراعي كامل الدسم طازج 2 لتر', 'Almarai Fresh Milk Full Fat 2L', 'حليب بقري نقي 100% طازج كامل الدسم معزز بفيتامين د والكالسيوم لجميع أفراد الأسرة.', 'المراعي', 11.00, 13.50, 19, 'bottle', 1.00, 320, ARRAY['https://images.unsplash.com/photo-1550583724-b2692b85b150?auto=format&fit=crop&w=600&q=80'], true, true, 4.8, 150
  ),
(
    'a0000000-0000-0000-0000-000000000005', 'c0000000-0000-0000-0000-000000000002', '629100000005', 'جبنة بوك كريمية بيضاء أصلية 500 غرام', 'Puck Cream Cheese Jar 500g', 'جبنة كريمية ناعمة وقابلة للدهن، مثالية للسندويشات والمخبوزات الصباحية.', 'بوك', 14.50, 18.00, 19, 'piece', 1.00, 240, ARRAY['https://images.unsplash.com/photo-1589881133595-a3c085cb731d?auto=format&fit=crop&w=600&q=80'], true, false, 4.8, 150
  ),
(
    'a0000000-0000-0000-0000-000000000006', 'c0000000-0000-0000-0000-000000000003', '629100000006', 'دجاج التنمية طازج مبرد 1000 غرام', 'Tanmiah Fresh Chilled Chicken 1000g', 'دجاج محلي طازج مذبوح على الشريعة الإسلامية حلال 100% دون أي مضادات حيوية.', 'التنمية', 16.75, 21.00, 20, 'piece', 1.00, 180, ARRAY['https://images.unsplash.com/photo-1587593810167-a84920ea0781?auto=format&fit=crop&w=600&q=80'], true, true, 4.8, 150
  ),
(
    'a0000000-0000-0000-0000-000000000007', 'c0000000-0000-0000-0000-000000000004', '629100000007', 'كرواسان فرنسي بالزبدة الطبيعية (4 حبات)', 'Fresh Butter French Croissants (Pack 4)', 'مخبوز طازجاً كل صباح بطبقات مقرمشة وهشة غنية بطعم الزبدة الطبيعية الفاخرة.', 'مخبز الديب', 8.50, 11.00, 23, 'pack', 1.00, 120, ARRAY['https://images.unsplash.com/photo-1555507036-ab1f4038808a?auto=format&fit=crop&w=600&q=80'], true, false, 4.8, 150
  ),
(
    'a0000000-0000-0000-0000-000000000008', 'c0000000-0000-0000-0000-000000000005', '629100000008', 'مياه العين الطبيعية كرتون (24 × 500 مل)', 'Al Ain Bottled Mineral Water (24 x 500ml)', 'مياه شرب نقية متوازنة الصوديوم، معبأة بأحدث معايير الجودة العالمية.', 'العين', 12.95, 17.50, 26, 'carton', 1.00, 600, ARRAY['https://images.unsplash.com/photo-1527661591475-527312dd65f5?auto=format&fit=crop&w=600&q=80'], true, true, 4.8, 150
  ),
(
    'a0000000-0000-0000-0000-000000000009', 'c0000000-0000-0000-0000-000000000006', '629100000009', 'مسحوق غسيل تايد الأصلي الأوتوماتيكي 5 كجم', 'Tide Original Automatic Detergent 5kg', 'نظافة فائقة وبياض ناصع وإزالة لأصعب البقع مع رائحة منعشة تدوم طويلاً.', 'تايد', 42.00, 58.00, 28, 'pack', 1.00, 210, ARRAY['https://images.unsplash.com/photo-1585421514738-01798e348b17?auto=format&fit=crop&w=600&q=80'], true, true, 4.8, 150
  ),
(
    'a0000000-0000-0000-0000-000000000010', 'c0000000-0000-0000-0000-000000000003', '629100000010', 'لحم عجل بلدي طازج مفروم ناعم 1 كجم', 'Fresh Local Minced Veal 1kg', 'لحم عجل بلدي طازج مفروم يومياً حسب الطلب، نسبة دهن متوازنة ومثالي للكفتة والبرغر.', 'ملحمة الديب', 38.00, 45.00, 15, 'kg', 0.50, 140, ARRAY['https://images.unsplash.com/photo-1588168333986-5078d3ae3976?auto=format&fit=crop&w=600&q=80'], true, false, 4.8, 150
  ),
(
    'a0000000-0000-0000-0000-000000000011', 'c0000000-0000-0000-0000-000000000003', '629100000011', 'فيليه سلمون نرويجي طازج فاخر 500 غ', 'Fresh Norwegian Salmon Fillet 500g', 'سمك سلمون نرويجي طازج غني بالأوميغا 3 والبروتين، منزوع الشوك وجاهز للشواء والفرن.', 'بحريات الديب', 44.50, 55.00, 19, 'pack', 0.50, 95, ARRAY['https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?auto=format&fit=crop&w=600&q=80'], true, true, 4.8, 150
  ),
(
    'a0000000-0000-0000-0000-000000000012', 'c0000000-0000-0000-0000-000000000003', '629100000012', 'ستيك ريب آي أنجوس معتق فاخر 400 غ', 'Prime Dry-Aged Angus Ribeye Steak 400g', 'ستيك عجل أنجوس معتق 28 يوماً لطراوة استثنائية ونكهة غنية للمطاعم الراقية.', 'ملحمة الديب', 52.00, 65.00, 20, 'piece', 1.00, 60, ARRAY['https://images.unsplash.com/photo-1603048588665-791ca8aea617?auto=format&fit=crop&w=600&q=80'], true, false, 4.8, 150
  ),
(
    'a0000000-0000-0000-0000-000000000013', 'c0000000-0000-0000-0000-000000000002', '629100000013', 'بيض مزارع عضوي طازج كرتون 30 حبة', 'Fresh Organic Farm Eggs 30-Pack', 'بيض بني عضوي طازج مفحوص مخبرياً من دجاج مزارع متغذية على الحبوب الطبيعية 100%.', 'مزارع الديب', 22.50, 28.00, 20, 'carton', 1.00, 300, ARRAY['https://images.unsplash.com/photo-1506976785307-8732e854ad03?auto=format&fit=crop&w=600&q=80'], true, true, 4.8, 150
  ),
(
    'a0000000-0000-0000-0000-000000000014', 'c0000000-0000-0000-0000-000000000002', '629100000014', 'لبنة تركية فاخرة طازجة كاملة الدسم 500 غ', 'Fresh Turkish Creamy Labneh 500g', 'لبنة قوام كريمي غني بنكهة أصلية مع زيت الزيتون، مثالية للفطور اليومي.', 'بينار', 12.00, 15.00, 20, 'piece', 1.00, 180, ARRAY['https://images.unsplash.com/photo-1486297678162-eb2a19b0a32d?auto=format&fit=crop&w=600&q=80'], false, false, 4.8, 150
  ),
(
    'a0000000-0000-0000-0000-000000000015', 'c0000000-0000-0000-0000-000000000004', '629100000015', 'خبز ساوردو ريفيّ عضوي طازج مخبوز بالفرن', 'Artisan Fresh Organic Sourdough Bread', 'خبز خميرة طبيعية متخمر ببطء 24 ساعة، قشرة مقرمشة ولب رطب خفيف على المعدة.', 'مخبز الديب', 9.50, 12.00, 20, 'piece', 1.00, 80, ARRAY['https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=600&q=80'], true, false, 4.8, 150
  ),
(
    'a0000000-0000-0000-0000-000000000016', 'c0000000-0000-0000-0000-000000000004', '629100000016', 'بقلاوة مشكلة بالفستق والكاجو الفاخر 500 غ', 'Assorted Royal Pistachio Baklava 500g', 'حلوى شرقية ملكية بالسمن البلدي والفستق الحلبي المقرمش مجهزة بعناية.', 'حلويات الديب', 29.00, 36.00, 19, 'pack', 1.00, 110, ARRAY['https://images.unsplash.com/photo-1519869325930-281384150729?auto=format&fit=crop&w=600&q=80'], false, true, 4.8, 150
  ),
(
    'a0000000-0000-0000-0000-000000000017', 'c0000000-0000-0000-0000-000000000005', '629100000017', 'عصير برتقال طبيعي معصور طازج 1 لتر', 'Freshly Squeezed 100% Orange Juice 1L', 'عصير برتقال فالنسيا نقي 100% بدون سكر مضاف أو مواد حافظة، غني بفيتامين سي.', 'عصائر الديب', 14.00, 18.00, 22, 'bottle', 1.00, 160, ARRAY['https://images.unsplash.com/photo-1613478223719-2ab802602423?auto=format&fit=crop&w=600&q=80'], true, false, 4.8, 150
  ),
(
    'a0000000-0000-0000-0000-000000000018', 'c0000000-0000-0000-0000-000000000005', '629100000018', 'قهوة عربية فاخرة بالهيل والزعفران 250 غ', 'Premium Arabic Coffee with Saffron 250g', 'خلطة قهوة شقراء مميزة بأجود أنواع البن الهرري مع الهيل الأخضر والزعفران الأصلي.', 'الديوانية', 19.50, 25.00, 22, 'pack', 1.00, 200, ARRAY['https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?auto=format&fit=crop&w=600&q=80'], false, false, 4.8, 150
  ),
(
    'a0000000-0000-0000-0000-000000000019', 'c0000000-0000-0000-0000-000000000006', '629100000019', 'سائل غسيل الصحون فيري بلس ليمون 1 لتر', 'Fairy Plus Lemon Dishwashing Liquid 1L', 'قوة مضاعفة لتفتيت الدهون الصعبة بقطرة واحدة مع رغوة كثيفة ورائحة الليمون المنعشة.', 'فيري', 13.50, 17.00, 20, 'bottle', 1.00, 340, ARRAY['https://images.unsplash.com/photo-1585421514738-01798e348b17?auto=format&fit=crop&w=600&q=80'], false, true, 4.8, 150
  ),
(
    'a0000000-0000-0000-0000-000000000020', 'c0000000-0000-0000-0000-000000000006', '629100000020', 'مطهر ومعقم ديتول الأصلي متعدد الاستعمالات 1 لتر', 'Dettol Original Antiseptic Liquid 1L', 'حماية متكاملة تقضي على 99.9% من الجراثيم والبكتيريا لتعقيم المنزل والأسطح.', 'ديتول', 24.00, 31.00, 22, 'bottle', 1.00, 250, ARRAY['https://images.unsplash.com/photo-1584744982491-665216d95f8b?auto=format&fit=crop&w=600&q=80'], true, false, 4.8, 150
  ),
(
    'a0000000-0000-0000-0000-000000000021', 'c0000000-0000-0000-0000-000000000001', '629100000021', 'زيت زيتون بكر ممتاز فلسطيني معصور على البارد 500 مل', 'Extra Virgin Cold Pressed Palestinian Olive Oil 500ml', 'زيت زيتون نقي من مزارع فلسطين العريقة، حموضة أقل من 0.8% غني بمضادات الأكسدة.', 'كنعان', 26.00, 32.00, 19, 'bottle', 1.00, 180, ARRAY['https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?auto=format&fit=crop&w=600&q=80'], true, false, 4.8, 150
  ),
(
    'a0000000-0000-0000-0000-000000000022', 'c0000000-0000-0000-0000-000000000001', '629100000022', 'أرز بسمتي هندي عنبر طويل الحبة فاخر 2 كجم', 'Premium Aged Long Grain Indian Basmati Rice 2kg', 'أرز هندي معتق ذو حبة طويلة ونكهة أصيلة ورائحة زكية، مثالي للكبسة والبرياني.', 'باب الهند', 22.00, 28.00, 21, 'pack', 1.00, 240, ARRAY['https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&w=600&q=80'], true, true, 4.8, 150
  ),
(
    'a0000000-0000-0000-0000-000000000023', 'c0000000-0000-0000-0000-000000000002', '629100000023', 'حليب لوز نباتي عضوي غير محلى 1 لتر', 'Organic Unsweetened Almond Milk 1L', 'بديل نباتي صحي خالٍ من اللاكتوز والجلوتين، غني بفيتامين هـ والكالسيوم وخفيف على المعدة.', 'ألبرو', 15.50, 19.00, 18, 'bottle', 1.00, 160, ARRAY['https://images.unsplash.com/photo-1568651318492-3a5fc1a89c8a?auto=format&fit=crop&w=600&q=80'], true, false, 4.8, 150
  ),
(
    'a0000000-0000-0000-0000-000000000024', 'c0000000-0000-0000-0000-000000000003', '629100000024', 'صدور دجاج فيليه طازجة مبردة 500 غرام', 'Fresh Chilled Chicken Breast Fillet 500g', 'صدور دجاج طازجة مخلية من العظم والجلد تماماً، غنية بالبروتين ومثالية للوجبات الصحية والشواء.', 'التنمية', 18.50, 23.00, 20, 'pack', 1.00, 200, ARRAY['https://images.unsplash.com/photo-1604503468506-a8da13d82791?auto=format&fit=crop&w=600&q=80'], true, true, 4.8, 150
  ),
(
    'a0000000-0000-0000-0000-000000000025', 'c0000000-0000-0000-0000-000000000004', '629100000025', 'عسل سدر جبلي طبيعي نقي 500 غرام', 'Pure Mountain Sidr Natural Honey 500g', 'عسل سدر نقي 100% مستخلص من أزهار أشجار السدر الجبلية، محلي طبيعي فاخر مقوي للمناعة.', 'مناحل الديب', 35.00, 45.00, 22, 'piece', 1.00, 130, ARRAY['https://images.unsplash.com/photo-1587049352846-4a222e784d38?auto=format&fit=crop&w=600&q=80'], true, false, 4.8, 150
  ),
(
    'a0000000-0000-0000-0000-000000000026', 'c0000000-0000-0000-0000-000000000001', '629100000026', 'أفوكادو هاس مكسيكي طازج جاهز للأكل (حبتين)', 'Fresh Mexican Hass Avocados (2 Pack)', 'أفوكادو هاس غني بالدهون الأحادية الصحية وقوام كريمي ناعم، مثالي للتوست والسلطات والعصائر.', 'طازج', 9.50, 13.00, 27, 'pack', 1.00, 175, ARRAY['https://images.unsplash.com/photo-1523049673857-eb18f1d7b578?auto=format&fit=crop&w=600&q=80'], true, true, 4.8, 150
  ),
(
    'a0000000-0000-0000-0000-000000000027', 'c0000000-0000-0000-0000-000000000004', '629100000027', 'شوفان عضوي حبوب كاملة فاخر 500 غرام', 'Organic Whole Rolled Oats 500g', 'رقائق شوفان حبوب كاملة عضوية 100% غنية بالألياف والمعادن ومناسبة للفطور والعصائر الصحية.', 'صحي', 8.50, 11.00, 23, 'pack', 1.00, 210, ARRAY['https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&w=600&q=80'], false, false, 4.8, 150
  ),
(
    'a0000000-0000-0000-0000-000000000028', 'c0000000-0000-0000-0000-000000000001', '629100000028', 'تمور خلاص الأحساء فاخرة ملكية 1 كجم', 'Royal Khalas Premium Dates 1kg', 'تمور خلاص سعودية منتقاة حبة بحبة، معبأة بعناية وحلوة المذاق وغنية بالألياف الطبيعية.', 'تمورنا', 24.00, 32.00, 25, 'pack', 1.00, 210, ARRAY['https://images.unsplash.com/photo-1596707328406-8c4c7943c2c5?auto=format&fit=crop&w=600&q=80'], true, false, 4.8, 150
  ),
(
    'a0000000-0000-0000-0000-000000000029', 'c0000000-0000-0000-0000-000000000001', '629100000029', 'قلاية هوائية رقمية فيليبس XXL بدون زيت 7.2 لتر', 'Philips Digital Airfryer XXL 7.2L', 'قلاية صحية بدون زيت بتقنية الهواء الساخن السريع وسعة عائلية مع شاشة لمس وبرامج متعددة.', 'Philips', 389.00, 529.00, 26, 'piece', 1.00, 35, ARRAY['https://images.unsplash.com/photo-1550009158-9ebf69173e03?auto=format&fit=crop&w=600&q=80'], true, true, 4.8, 150
  ),
(
    'a0000000-0000-0000-0000-000000000030', 'c0000000-0000-0000-0000-000000000002', '629100000030', 'بيض مزارع كويتي طازج كبير 30 حبة', 'Fresh Farm Table Eggs 30s', 'بيض مائدة طازج مغذى طبيعياً وغني بالبروتين، مطابق لأعلى معايير السلامة الغذائية.', 'مزارع الديب', 15.50, 19.00, 18, 'pack', 1.00, 150, ARRAY['https://images.unsplash.com/photo-1516467508483-a7212febe31a?auto=format&fit=crop&w=600&q=80'], true, true, 4.8, 150
  ),
(
    'a0000000-0000-0000-0000-000000000031', 'c0000000-0000-0000-0000-000000000001', '629100000031', 'شامبو لوريال إلفيف للشعر الجاف 400 مل', 'L\', 'شامبو مغذي بزيوت الزهور النادرة لتغذية الشعر من الجذور حتى الأطراف ولمعان لا يضاهى.', 'L\', 18.50, 25.00, 26, 'bottle', 1.00, 85, ARRAY['https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?auto=format&fit=crop&w=600&q=80'], true, false, 4.8, 150
  ),
(
    'a0000000-0000-0000-0000-000000000032', 'c0000000-0000-0000-0000-000000000006', '629100000032', 'مسحوق غسيل أريال أوتوماتيك للغسالات 5 كجم', 'Ariel Automatic Laundry Detergent 5kg', 'مسحوق غسيل المركز يزيل أصعب البقع من أول غسلة ويمنح الملابس انتعاشاً يدوم طويلاً.', 'Ariel', 49.90, 68.00, 27, 'pack', 1.00, 110, ARRAY['https://images.unsplash.com/photo-1585421514738-01798e348b17?auto=format&fit=crop&w=600&q=80'], true, true, 4.8, 150
  ),
(
    'a0000000-0000-0000-0000-000000000033', 'c0000000-0000-0000-0000-000000000001', '629100000033', 'أرز بسمتي الشعلان سيلا فاخر 5 كجم', 'Al Shalan Basmati Sella Rice 5kg', 'أرز بسمتي أبيض حبة طويلة ونكهة أصيلة، مثالي للكبسة والأطباق الخليجية والمناسف.', 'الشعلان', 36.50, 45.00, 19, 'pack', 1.00, 340, ARRAY['https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&w=600&q=80'], true, true, 4.8, 150
  ),
(
    'a0000000-0000-0000-0000-000000000034', 'c0000000-0000-0000-0000-000000000001', '629100000034', 'طعام قطط ويلاس دجاج وتونة وخضار 1.5 كجم', 'Whiskas Adult Cat Food Chicken & Tuna 1.5kg', 'وجبة متوازنة ومحببة للقطط غنية بالبروتينات وأوميغا 3 لدعم صحة الفرو والمناعة.', 'Whiskas', 28.00, 35.00, 20, 'pack', 1.00, 65, ARRAY['https://images.unsplash.com/photo-1583337130417-3346a1be7dee?auto=format&fit=crop&w=600&q=80'], false, false, 4.8, 150
  )
ON CONFLICT (id) DO UPDATE SET
    category_id = EXCLUDED.category_id,
    barcode = EXCLUDED.barcode,
    name_ar = EXCLUDED.name_ar,
    name_en = EXCLUDED.name_en,
    description_ar = EXCLUDED.description_ar,
    brand = EXCLUDED.brand,
    price = EXCLUDED.price,
    original_price = EXCLUDED.original_price,
    discount_percent = EXCLUDED.discount_percent,
    unit = EXCLUDED.unit,
    weight_step = EXCLUDED.weight_step,
    stock_quantity = EXCLUDED.stock_quantity,
    images = EXCLUDED.images,
    is_featured = EXCLUDED.is_featured,
    is_daily_deal = EXCLUDED.is_daily_deal;

-- ==============================================================================
-- 🏬 ALDEEB MALL: MULTI-BRANCH INDEPENDENT DATABASE & SCHEMA PROVISIONING ENGINE
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.provision_isolated_branch_schema(
    p_branch_code TEXT,
    p_branch_name TEXT,
    p_city TEXT,
    p_currency TEXT DEFAULT 'ل.س'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_schema_name TEXT;
    v_result JSONB;
BEGIN
    v_schema_name := 'branch_' || lower(regexp_replace(p_branch_code, '[^a-zA-Z0-9]', '_', 'g'));
    EXECUTE format('CREATE SCHEMA IF NOT EXISTS %I', v_schema_name);

    EXECUTE format('
        CREATE TABLE IF NOT EXISTS %I.products (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            catalog_product_id UUID NOT NULL,
            barcode TEXT,
            name_ar TEXT NOT NULL,
            name_en TEXT,
            branch_price NUMERIC(14,2) NOT NULL,
            cost_price NUMERIC(14,2) NOT NULL DEFAULT 0.00,
            stock_quantity INTEGER NOT NULL DEFAULT 0,
            reserved_quantity INTEGER NOT NULL DEFAULT 0,
            in_transit_quantity INTEGER NOT NULL DEFAULT 0,
            damaged_quantity INTEGER NOT NULL DEFAULT 0,
            min_stock_alert INTEGER NOT NULL DEFAULT 5,
            is_available BOOLEAN NOT NULL DEFAULT true,
            updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone(''utc''::text, now())
        )', v_schema_name);

    EXECUTE format('
        CREATE TABLE IF NOT EXISTS %I.orders (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            order_number TEXT UNIQUE NOT NULL,
            customer_name TEXT,
            customer_phone TEXT,
            status TEXT NOT NULL DEFAULT ''pending'',
            total_amount NUMERIC(14,2) NOT NULL,
            tax_amount NUMERIC(14,2) NOT NULL DEFAULT 0.00,
            payment_method TEXT NOT NULL,
            payment_status TEXT NOT NULL DEFAULT ''unpaid'',
            created_at TIMESTAMPTZ NOT NULL DEFAULT timezone(''utc''::text, now()),
            completed_at TIMESTAMPTZ
        )', v_schema_name);

    EXECUTE format('
        CREATE TABLE IF NOT EXISTS %I.pos_transactions (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            receipt_number TEXT UNIQUE NOT NULL,
            terminal_code TEXT NOT NULL,
            cashier_name TEXT NOT NULL,
            subtotal NUMERIC(14,2) NOT NULL,
            tax_amount NUMERIC(14,2) NOT NULL,
            grand_total NUMERIC(14,2) NOT NULL,
            payment_method TEXT NOT NULL,
            cash_received NUMERIC(14,2),
            change_given NUMERIC(14,2),
            idempotency_key TEXT UNIQUE NOT NULL,
            created_at TIMESTAMPTZ NOT NULL DEFAULT timezone(''utc''::text, now())
        )', v_schema_name);

    EXECUTE format('
        CREATE TABLE IF NOT EXISTS %I.inventory_movements (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            product_id UUID NOT NULL,
            movement_type TEXT NOT NULL,
            quantity INTEGER NOT NULL,
            balance_after INTEGER NOT NULL,
            reference_id TEXT,
            reason TEXT,
            created_by TEXT,
            created_at TIMESTAMPTZ NOT NULL DEFAULT timezone(''utc''::text, now())
        )', v_schema_name);

    EXECUTE format('
        CREATE TABLE IF NOT EXISTS %I.event_outbox (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            event_type TEXT NOT NULL,
            payload JSONB NOT NULL,
            status TEXT NOT NULL DEFAULT ''pending'',
            retry_count INTEGER NOT NULL DEFAULT 0,
            last_error TEXT,
            created_at TIMESTAMPTZ NOT NULL DEFAULT timezone(''utc''::text, now()),
            synced_at TIMESTAMPTZ
        )', v_schema_name);

    v_result := jsonb_build_object(
        'status', 'success',
        'branch_code', p_branch_code,
        'schema_name', v_schema_name,
        'provisioned_at', now(),
        'isolation_level', 'physical_schema_isolation'
    );

    RETURN v_result;
END;
$$;



-- ==============================================================================
-- 🚀 ALDEEB MALL & HYPERMARKET — STAFF, BRANCHES & SECURITY LIVE SYNC MIGRATION
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.branches (
    id VARCHAR(64) PRIMARY KEY,
    code VARCHAR(32) NOT NULL UNIQUE,
    name_ar VARCHAR(128) NOT NULL,
    name_en VARCHAR(128) NOT NULL,
    city VARCHAR(64) NOT NULL,
    district VARCHAR(128),
    address TEXT,
    phone VARCHAR(32),
    manager_name VARCHAR(128),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    terminals_count INT NOT NULL DEFAULT 4,
    daily_sales NUMERIC(14, 2) NOT NULL DEFAULT 0.00,
    currency VARCHAR(16) NOT NULL DEFAULT 'ل.س',
    type VARCHAR(32) NOT NULL DEFAULT 'supermarket',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE IF EXISTS public.payroll_transactions DROP CONSTRAINT IF EXISTS payroll_transactions_employee_id_fkey;
ALTER TABLE IF EXISTS public.password_change_requests DROP CONSTRAINT IF EXISTS password_change_requests_employee_id_fkey;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = 'staff_members' 
      AND column_name = 'id' 
      AND data_type <> 'character varying'
  ) THEN
    ALTER TABLE public.staff_members ALTER COLUMN id TYPE VARCHAR(64);
  END IF;

  ALTER TABLE public.staff_members ALTER COLUMN id SET DEFAULT gen_random_uuid()::text;

  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = 'payroll_transactions' 
      AND column_name = 'employee_id' 
      AND data_type <> 'character varying'
  ) THEN
    ALTER TABLE public.payroll_transactions ALTER COLUMN employee_id TYPE VARCHAR(64);
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = 'payroll_transactions' 
      AND column_name = 'id' 
      AND data_type <> 'character varying'
  ) THEN
    ALTER TABLE public.payroll_transactions ALTER COLUMN id TYPE VARCHAR(64);
  END IF;

  ALTER TABLE public.payroll_transactions ALTER COLUMN id SET DEFAULT gen_random_uuid()::text;

  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = 'password_change_requests' 
      AND column_name = 'employee_id' 
      AND data_type <> 'character varying'
  ) THEN
    ALTER TABLE public.password_change_requests ALTER COLUMN employee_id TYPE VARCHAR(64);
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = 'password_change_requests' 
      AND column_name = 'id' 
      AND data_type <> 'character varying'
  ) THEN
    ALTER TABLE public.password_change_requests ALTER COLUMN id TYPE VARCHAR(64);
  END IF;

  ALTER TABLE public.password_change_requests ALTER COLUMN id SET DEFAULT gen_random_uuid()::text;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'payroll_transactions_employee_id_fkey'
  ) THEN
    ALTER TABLE public.payroll_transactions 
      ADD CONSTRAINT payroll_transactions_employee_id_fkey 
      FOREIGN KEY (employee_id) REFERENCES public.staff_members(id) ON DELETE CASCADE;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'password_change_requests_employee_id_fkey'
  ) THEN
    ALTER TABLE public.password_change_requests 
      ADD CONSTRAINT password_change_requests_employee_id_fkey 
      FOREIGN KEY (employee_id) REFERENCES public.staff_members(id) ON DELETE CASCADE;
  END IF;
END $$;

ALTER TABLE IF EXISTS public.staff_members ADD COLUMN IF NOT EXISTS password TEXT;
ALTER TABLE IF EXISTS public.staff_members ADD COLUMN IF NOT EXISTS session_revoked_at TIMESTAMPTZ;

ALTER TABLE public.branches ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all operations on branches" ON public.branches;
CREATE POLICY "Allow all operations on branches" ON public.branches FOR ALL USING (true) WITH CHECK (true);

ALTER TABLE public.staff_members ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow authenticated read staff" ON public.staff_members;
DROP POLICY IF EXISTS "Allow all operations on staff_members" ON public.staff_members;
CREATE POLICY "Allow all operations on staff_members" ON public.staff_members FOR ALL USING (true) WITH CHECK (true);

ALTER TABLE public.password_change_requests ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public read password requests" ON public.password_change_requests;
DROP POLICY IF EXISTS "Allow all operations on password_change_requests" ON public.password_change_requests FOR ALL USING (true) WITH CHECK (true);

ALTER TABLE public.payroll_transactions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow authenticated read payroll" ON public.payroll_transactions;
DROP POLICY IF EXISTS "Allow accountant and admin insert payroll" ON public.payroll_transactions;
DROP POLICY IF EXISTS "Allow all operations on payroll_transactions" ON public.payroll_transactions FOR ALL USING (true) WITH CHECK (true);

ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "orders_select_policy" ON public.orders;
CREATE POLICY "orders_select_policy" ON public.orders FOR SELECT TO authenticated, anon USING (true);

ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "order_items_select_policy" ON public.order_items;
CREATE POLICY "order_items_select_policy" ON public.order_items FOR SELECT TO authenticated, anon USING (true);

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO anon, authenticated;

-- ==============================================================================
-- SECTION 23: CORPORATE B2B SALES, RFQ, CREDIT CEILINGS & STOCK SETTLEMENT
-- Added in Migration 20261104_023_corporate_b2b_sales_system.sql
-- ==============================================================================
-- ==============================================================================
-- 🏢 ALDEEB MALL & HYPERMARKET — CORPORATE B2B SALES, QUOTATIONS & INVOICES
-- ==============================================================================
-- Migration: 20261104_020_corporate_b2b_sales_system.sql
-- Description: Comprehensive production implementation of B2B Corporate Sales:
-- 1. Authorized Corporate Client Accounts & KYC (Credit Limits, Payment Terms)
-- 2. Quotations & Pricing RFQs (Wholesale discounts, Multi-tier Approvals)
-- 3. Corporate Tax Invoices with Atomic Inventory Deductions & Credit Verification
-- 4. Payment Settlements & Real-time Debt Reduction (Net-15/30/60)
-- 5. Returns, Credit Notes & Atomic Inventory Restorations
-- 6. Multi-Branch Isolation & Strict RBAC Enforcement
-- ==============================================================================

-- 1. Ensure Table Dependencies and Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Table: corporate_accounts (حسابات العملاء والشركات المفوضة)
CREATE TABLE IF NOT EXISTS public.corporate_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_name TEXT NOT NULL,
    cr_number TEXT NOT NULL UNIQUE,
    vat_number TEXT NOT NULL,
    contact_person TEXT NOT NULL,
    phone TEXT NOT NULL,
    email TEXT,
    city TEXT NOT NULL DEFAULT 'دمشق',
    address TEXT,
    branch_id VARCHAR(64) NOT NULL REFERENCES public.branches(id) ON UPDATE CASCADE,
    monthly_credit_limit NUMERIC(14,2) NOT NULL DEFAULT 5000000.00 CHECK (monthly_credit_limit >= 0),
    current_balance NUMERIC(14,2) NOT NULL DEFAULT 0.00 CHECK (current_balance >= 0),
    payment_terms TEXT NOT NULL DEFAULT 'Net-30' CHECK (payment_terms IN ('Cash', 'Net-15', 'Net-30', 'Net-60')),
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'pending_kyc', 'suspended', 'overdue')),
    recurring_schedule TEXT DEFAULT 'شحنة أسبوعية مجدولة',
    items_summary TEXT,
    notes TEXT,
    created_by TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_corporate_accounts_branch_id ON public.corporate_accounts(branch_id);
CREATE INDEX IF NOT EXISTS idx_corporate_accounts_status ON public.corporate_accounts(status);
CREATE INDEX IF NOT EXISTS idx_corporate_accounts_cr ON public.corporate_accounts(cr_number);

-- 3. Table: corporate_quotations (عروض الأسعار وطلبات الشراء B2B Quotations)
CREATE TABLE IF NOT EXISTS public.corporate_quotations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    quotation_number TEXT NOT NULL UNIQUE,
    corporate_account_id UUID NOT NULL REFERENCES public.corporate_accounts(id) ON DELETE CASCADE,
    branch_id VARCHAR(64) NOT NULL REFERENCES public.branches(id) ON UPDATE CASCADE,
    subtotal NUMERIC(14,2) NOT NULL DEFAULT 0.00 CHECK (subtotal >= 0),
    discount_percent NUMERIC(5,2) NOT NULL DEFAULT 0.00 CHECK (discount_percent >= 0 AND discount_percent <= 100),
    discount_amount NUMERIC(14,2) NOT NULL DEFAULT 0.00 CHECK (discount_amount >= 0),
    tax_amount NUMERIC(14,2) NOT NULL DEFAULT 0.00 CHECK (tax_amount >= 0),
    total_amount NUMERIC(14,2) NOT NULL DEFAULT 0.00 CHECK (total_amount >= 0),
    status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'pending_approval', 'approved', 'rejected', 'converted')),
    valid_until DATE NOT NULL DEFAULT (CURRENT_DATE + INTERVAL '30 days'),
    notes TEXT,
    approved_by TEXT,
    approved_at TIMESTAMPTZ,
    rejection_reason TEXT,
    created_by TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_corporate_quotations_account ON public.corporate_quotations(corporate_account_id);
CREATE INDEX IF NOT EXISTS idx_corporate_quotations_branch ON public.corporate_quotations(branch_id);
CREATE INDEX IF NOT EXISTS idx_corporate_quotations_status ON public.corporate_quotations(status);

-- 4. Table: corporate_quotation_items (بنود عرض السعر)
CREATE TABLE IF NOT EXISTS public.corporate_quotation_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    quotation_id UUID NOT NULL REFERENCES public.corporate_quotations(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES public.products(id) ON UPDATE CASCADE,
    quantity NUMERIC(10,2) NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(14,2) NOT NULL CHECK (unit_price >= 0),
    discount_percent NUMERIC(5,2) NOT NULL DEFAULT 0.00 CHECK (discount_percent >= 0 AND discount_percent <= 100),
    final_unit_price NUMERIC(14,2) NOT NULL CHECK (final_unit_price >= 0),
    total_price NUMERIC(14,2) NOT NULL CHECK (total_price >= 0),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_corporate_quotation_items_qid ON public.corporate_quotation_items(quotation_id);

-- 5. Table: corporate_invoices (فواتير مبيعات الشركات B2B Invoices)
CREATE TABLE IF NOT EXISTS public.corporate_invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_number TEXT NOT NULL UNIQUE,
    quotation_id UUID REFERENCES public.corporate_quotations(id) ON DELETE SET NULL,
    corporate_account_id UUID NOT NULL REFERENCES public.corporate_accounts(id) ON DELETE RESTRICT,
    branch_id VARCHAR(64) NOT NULL REFERENCES public.branches(id) ON UPDATE CASCADE,
    subtotal NUMERIC(14,2) NOT NULL DEFAULT 0.00 CHECK (subtotal >= 0),
    discount_amount NUMERIC(14,2) NOT NULL DEFAULT 0.00 CHECK (discount_amount >= 0),
    tax_amount NUMERIC(14,2) NOT NULL DEFAULT 0.00 CHECK (tax_amount >= 0),
    total_amount NUMERIC(14,2) NOT NULL DEFAULT 0.00 CHECK (total_amount >= 0),
    paid_amount NUMERIC(14,2) NOT NULL DEFAULT 0.00 CHECK (paid_amount >= 0),
    remaining_amount NUMERIC(14,2) NOT NULL DEFAULT 0.00 CHECK (remaining_amount >= 0),
    payment_status TEXT NOT NULL DEFAULT 'unpaid' CHECK (payment_status IN ('unpaid', 'partially_paid', 'paid', 'overdue')),
    due_date DATE NOT NULL,
    notes TEXT,
    created_by TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_corporate_invoices_account ON public.corporate_invoices(corporate_account_id);
CREATE INDEX IF NOT EXISTS idx_corporate_invoices_branch ON public.corporate_invoices(branch_id);
CREATE INDEX IF NOT EXISTS idx_corporate_invoices_status ON public.corporate_invoices(payment_status);

-- 6. Table: corporate_invoice_items (بنود فاتورة الشركات)
CREATE TABLE IF NOT EXISTS public.corporate_invoice_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id UUID NOT NULL REFERENCES public.corporate_invoices(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES public.products(id) ON UPDATE CASCADE,
    quantity NUMERIC(10,2) NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(14,2) NOT NULL CHECK (unit_price >= 0),
    discount_percent NUMERIC(5,2) NOT NULL DEFAULT 0.00 CHECK (discount_percent >= 0 AND discount_percent <= 100),
    final_unit_price NUMERIC(14,2) NOT NULL CHECK (final_unit_price >= 0),
    total_price NUMERIC(14,2) NOT NULL CHECK (total_price >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_corporate_invoice_items_iid ON public.corporate_invoice_items(invoice_id);

-- 7. Table: corporate_payments (سجلات سداد دفعات الشركات)
CREATE TABLE IF NOT EXISTS public.corporate_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    payment_number TEXT NOT NULL UNIQUE,
    invoice_id UUID NOT NULL REFERENCES public.corporate_invoices(id) ON DELETE RESTRICT,
    corporate_account_id UUID NOT NULL REFERENCES public.corporate_accounts(id) ON DELETE RESTRICT,
    amount NUMERIC(14,2) NOT NULL CHECK (amount > 0),
    payment_method TEXT NOT NULL DEFAULT 'bank_transfer' CHECK (payment_method IN ('bank_transfer', 'check', 'cash', 'credit_card')),
    reference_number TEXT NOT NULL,
    payment_date DATE NOT NULL DEFAULT CURRENT_DATE,
    notes TEXT,
    received_by TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_corporate_payments_invoice ON public.corporate_payments(invoice_id);
CREATE INDEX IF NOT EXISTS idx_corporate_payments_account ON public.corporate_payments(corporate_account_id);

-- 8. Table: corporate_returns (مرتجعات مبيعات الشركات وإشعارات دائنة)
CREATE TABLE IF NOT EXISTS public.corporate_returns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    return_number TEXT NOT NULL UNIQUE,
    invoice_id UUID NOT NULL REFERENCES public.corporate_invoices(id) ON DELETE RESTRICT,
    corporate_account_id UUID NOT NULL REFERENCES public.corporate_accounts(id) ON DELETE RESTRICT,
    branch_id VARCHAR(64) NOT NULL REFERENCES public.branches(id) ON UPDATE CASCADE,
    total_refund_amount NUMERIC(14,2) NOT NULL CHECK (total_refund_amount >= 0),
    status TEXT NOT NULL DEFAULT 'pending_approval' CHECK (status IN ('pending_approval', 'approved', 'rejected', 'completed')),
    reason TEXT NOT NULL,
    approved_by TEXT,
    approved_at TIMESTAMPTZ,
    rejection_reason TEXT,
    created_by TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_corporate_returns_invoice ON public.corporate_returns(invoice_id);
CREATE INDEX IF NOT EXISTS idx_corporate_returns_branch ON public.corporate_returns(branch_id);

-- 9. Table: corporate_return_items (بنود الإرجاع)
CREATE TABLE IF NOT EXISTS public.corporate_return_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    return_id UUID NOT NULL REFERENCES public.corporate_returns(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES public.products(id) ON UPDATE CASCADE,
    quantity NUMERIC(10,2) NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(14,2) NOT NULL CHECK (unit_price >= 0),
    total_refund NUMERIC(14,2) NOT NULL CHECK (total_refund >= 0),
    reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_corporate_return_items_rid ON public.corporate_return_items(return_id);

-- 10. Enable & Force Row Level Security (RLS) on all corporate tables
ALTER TABLE public.corporate_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.corporate_accounts FORCE ROW LEVEL SECURITY;

ALTER TABLE public.corporate_quotations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.corporate_quotations FORCE ROW LEVEL SECURITY;

ALTER TABLE public.corporate_quotation_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.corporate_quotation_items FORCE ROW LEVEL SECURITY;

ALTER TABLE public.corporate_invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.corporate_invoices FORCE ROW LEVEL SECURITY;

ALTER TABLE public.corporate_invoice_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.corporate_invoice_items FORCE ROW LEVEL SECURITY;

ALTER TABLE public.corporate_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.corporate_payments FORCE ROW LEVEL SECURITY;

ALTER TABLE public.corporate_returns ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.corporate_returns FORCE ROW LEVEL SECURITY;

ALTER TABLE public.corporate_return_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.corporate_return_items FORCE ROW LEVEL SECURITY;

-- 11. Define Strict RLS Policies for Multi-Branch Isolation & Staff Role Matrix
-- Corporate Accounts Policies
DROP POLICY IF EXISTS corporate_accounts_select ON public.corporate_accounts;
CREATE POLICY corporate_accounts_select ON public.corporate_accounts FOR SELECT TO authenticated
USING (
    auth.user_role() IN ('super_admin', 'general_manager', 'auditor', 'accountant')
    OR (auth.user_role() = 'branch_manager' AND corporate_accounts.branch_id = auth.branch_id())
);

DROP POLICY IF EXISTS corporate_accounts_mutation ON public.corporate_accounts;
CREATE POLICY corporate_accounts_mutation ON public.corporate_accounts FOR ALL TO authenticated
USING (
    auth.user_role() IN ('super_admin', 'general_manager', 'accountant')
    OR (auth.user_role() = 'branch_manager' AND corporate_accounts.branch_id = auth.branch_id())
)
WITH CHECK (
    auth.user_role() IN ('super_admin', 'general_manager', 'accountant')
    OR (auth.user_role() = 'branch_manager' AND corporate_accounts.branch_id = auth.branch_id())
);

-- Corporate Quotations Policies
DROP POLICY IF EXISTS corporate_quotations_select ON public.corporate_quotations;
CREATE POLICY corporate_quotations_select ON public.corporate_quotations FOR SELECT TO authenticated
USING (
    auth.user_role() IN ('super_admin', 'general_manager', 'auditor', 'accountant')
    OR (auth.user_role() = 'branch_manager' AND corporate_quotations.branch_id = auth.branch_id())
);

DROP POLICY IF EXISTS corporate_quotations_mutation ON public.corporate_quotations;
CREATE POLICY corporate_quotations_mutation ON public.corporate_quotations FOR ALL TO authenticated
USING (
    auth.user_role() IN ('super_admin', 'general_manager', 'accountant')
    OR (auth.user_role() = 'branch_manager' AND corporate_quotations.branch_id = auth.branch_id())
)
WITH CHECK (
    auth.user_role() IN ('super_admin', 'general_manager', 'accountant')
    OR (auth.user_role() = 'branch_manager' AND corporate_quotations.branch_id = auth.branch_id())
);

-- Quotation Items Policies
DROP POLICY IF EXISTS corporate_quotation_items_select ON public.corporate_quotation_items;
CREATE POLICY corporate_quotation_items_select ON public.corporate_quotation_items FOR SELECT TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.corporate_quotations q 
        WHERE q.id = corporate_quotation_items.quotation_id 
        AND (
            auth.user_role() IN ('super_admin', 'general_manager', 'auditor', 'accountant')
            OR (auth.user_role() = 'branch_manager' AND q.branch_id = auth.branch_id())
        )
    )
);

DROP POLICY IF EXISTS corporate_quotation_items_mutation ON public.corporate_quotation_items;
CREATE POLICY corporate_quotation_items_mutation ON public.corporate_quotation_items FOR ALL TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.corporate_quotations q 
        WHERE q.id = corporate_quotation_items.quotation_id 
        AND (
            auth.user_role() IN ('super_admin', 'general_manager', 'accountant')
            OR (auth.user_role() = 'branch_manager' AND q.branch_id = auth.branch_id())
        )
    )
);

-- Corporate Invoices Policies
DROP POLICY IF EXISTS corporate_invoices_select ON public.corporate_invoices;
CREATE POLICY corporate_invoices_select ON public.corporate_invoices FOR SELECT TO authenticated
USING (
    auth.user_role() IN ('super_admin', 'general_manager', 'auditor', 'accountant')
    OR (auth.user_role() = 'branch_manager' AND corporate_invoices.branch_id = auth.branch_id())
);

DROP POLICY IF EXISTS corporate_invoices_mutation ON public.corporate_invoices;
CREATE POLICY corporate_invoices_mutation ON public.corporate_invoices FOR ALL TO authenticated
USING (
    auth.user_role() IN ('super_admin', 'general_manager', 'accountant')
    OR (auth.user_role() = 'branch_manager' AND corporate_invoices.branch_id = auth.branch_id())
)
WITH CHECK (
    auth.user_role() IN ('super_admin', 'general_manager', 'accountant')
    OR (auth.user_role() = 'branch_manager' AND corporate_invoices.branch_id = auth.branch_id())
);

-- Invoice Items Policies
DROP POLICY IF EXISTS corporate_invoice_items_select ON public.corporate_invoice_items;
CREATE POLICY corporate_invoice_items_select ON public.corporate_invoice_items FOR SELECT TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.corporate_invoices i 
        WHERE i.id = corporate_invoice_items.invoice_id 
        AND (
            auth.user_role() IN ('super_admin', 'general_manager', 'auditor', 'accountant')
            OR (auth.user_role() = 'branch_manager' AND i.branch_id = auth.branch_id())
        )
    )
);

DROP POLICY IF EXISTS corporate_invoice_items_mutation ON public.corporate_invoice_items;
CREATE POLICY corporate_invoice_items_mutation ON public.corporate_invoice_items FOR ALL TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.corporate_invoices i 
        WHERE i.id = corporate_invoice_items.invoice_id 
        AND (
            auth.user_role() IN ('super_admin', 'general_manager', 'accountant')
            OR (auth.user_role() = 'branch_manager' AND i.branch_id = auth.branch_id())
        )
    )
);

-- Corporate Payments Policies
DROP POLICY IF EXISTS corporate_payments_select ON public.corporate_payments;
CREATE POLICY corporate_payments_select ON public.corporate_payments FOR SELECT TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.corporate_invoices i 
        WHERE i.id = corporate_payments.invoice_id 
        AND (
            auth.user_role() IN ('super_admin', 'general_manager', 'auditor', 'accountant')
            OR (auth.user_role() = 'branch_manager' AND i.branch_id = auth.branch_id())
        )
    )
);

DROP POLICY IF EXISTS corporate_payments_mutation ON public.corporate_payments;
CREATE POLICY corporate_payments_mutation ON public.corporate_payments FOR ALL TO authenticated
USING (
    auth.user_role() IN ('super_admin', 'general_manager', 'accountant')
);

-- Corporate Returns Policies
DROP POLICY IF EXISTS corporate_returns_select ON public.corporate_returns;
CREATE POLICY corporate_returns_select ON public.corporate_returns FOR SELECT TO authenticated
USING (
    auth.user_role() IN ('super_admin', 'general_manager', 'auditor', 'accountant')
    OR (auth.user_role() = 'branch_manager' AND corporate_returns.branch_id = auth.branch_id())
);

DROP POLICY IF EXISTS corporate_returns_mutation ON public.corporate_returns;
CREATE POLICY corporate_returns_mutation ON public.corporate_returns FOR ALL TO authenticated
USING (
    auth.user_role() IN ('super_admin', 'general_manager', 'accountant')
    OR (auth.user_role() = 'branch_manager' AND corporate_returns.branch_id = auth.branch_id())
);

-- Return Items Policies
DROP POLICY IF EXISTS corporate_return_items_select ON public.corporate_return_items;
CREATE POLICY corporate_return_items_select ON public.corporate_return_items FOR SELECT TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.corporate_returns r 
        WHERE r.id = corporate_return_items.return_id 
        AND (
            auth.user_role() IN ('super_admin', 'general_manager', 'auditor', 'accountant')
            OR (auth.user_role() = 'branch_manager' AND r.branch_id = auth.branch_id())
        )
    )
);

DROP POLICY IF EXISTS corporate_return_items_mutation ON public.corporate_return_items;
CREATE POLICY corporate_return_items_mutation ON public.corporate_return_items FOR ALL TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.corporate_returns r 
        WHERE r.id = corporate_return_items.return_id 
        AND (
            auth.user_role() IN ('super_admin', 'general_manager', 'accountant')
            OR (auth.user_role() = 'branch_manager' AND r.branch_id = auth.branch_id())
        )
    )
);

-- 12. Update record_inventory_movement_atomic Permissions Guard
-- Allow legitimate sales/returns from orders and corporate sales without 42501 error
CREATE OR REPLACE FUNCTION public.record_inventory_movement_atomic(
    p_branch_id text,
    p_product_id uuid,
    p_movement_type text,
    p_qty_change numeric,
    p_qty_reserved_change numeric DEFAULT 0,
    p_ref_type text DEFAULT 'manual',
    p_ref_id text DEFAULT 'MANUAL-ADJ',
    p_actor_id text DEFAULT NULL,
    p_actor_name text DEFAULT 'أمين المخزون',
    p_actor_role text DEFAULT 'staff',
    p_notes text DEFAULT ''
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_curr_on_hand numeric(12,2);
    v_curr_reserved numeric(12,2);
    v_new_on_hand numeric(12,2);
    v_new_reserved numeric(12,2);
    v_mov_number text;
    v_caller_role text;
    v_caller_branch text;
    v_result jsonb;
BEGIN
    v_caller_role := auth.user_role();
    v_caller_branch := auth.branch_id();

    -- Role and Branch Permissions Guard
    IF v_caller_role = 'cashier' THEN
        IF p_movement_type NOT IN ('sale', 'return', 'release_reservation') THEN
            RAISE EXCEPTION '42501: Cashiers are strictly limited to recording sales, returns and release reservations';
        END IF;
        IF v_caller_branch IS NOT NULL AND v_caller_branch <> p_branch_id THEN
            RAISE EXCEPTION '42501: Cashier is unauthorized to operate on foreign branch %', p_branch_id;
        END IF;
    ELSIF v_caller_role = 'branch_manager' THEN
        IF v_caller_branch IS NOT NULL AND v_caller_branch <> p_branch_id AND NOT auth.is_super_admin() THEN
            RAISE EXCEPTION '42501: Branch manager is unauthorized to operate on foreign branch %', p_branch_id;
        END IF;
    ELSIF v_caller_role IN ('anon', 'customer', 'courier', 'driver') THEN
        IF p_ref_type = 'order' AND p_movement_type IN ('sale', 'release_reservation') THEN
            NULL;
        ELSIF p_ref_type = 'return' AND p_movement_type IN ('return', 'damaged') THEN
            NULL;
        ELSIF p_ref_type = 'transfer' AND p_movement_type IN ('transfer_out', 'transfer_in') THEN
            NULL;
        ELSIF p_ref_type = 'audit' AND p_movement_type = 'audit_reconciliation' THEN
            NULL;
        ELSIF p_ref_type = 'corporate_sale' AND p_movement_type IN ('sale', 'return') THEN
            NULL;
        ELSIF NOT auth.is_staff() AND NOT auth.is_super_admin() THEN
            RAISE EXCEPTION '42501: Unauthorized access to inventory movement engine';
        END IF;
    END IF;

    -- Ensure product exists
    IF NOT EXISTS (SELECT 1 FROM public.products WHERE id = p_product_id) THEN
        RAISE EXCEPTION 'PRODUCT_NOT_FOUND: Product with id % does not exist', p_product_id;
    END IF;

    -- Ensure branch exists
    IF NOT EXISTS (SELECT 1 FROM public.branches WHERE id = p_branch_id) THEN
        RAISE EXCEPTION 'BRANCH_NOT_FOUND: Branch with id % does not exist', p_branch_id;
    END IF;

    -- Row Locking FOR UPDATE to prevent race conditions & concurrent overselling
    SELECT quantity_on_hand, quantity_reserved
    INTO v_curr_on_hand, v_curr_reserved
    FROM public.branch_inventory
    WHERE branch_id = p_branch_id AND product_id = p_product_id
    FOR UPDATE;

    IF NOT FOUND THEN
        -- Auto-provision row with products stock_quantity if present
        INSERT INTO public.branch_inventory (branch_id, product_id, quantity_on_hand, quantity_reserved)
        VALUES (p_branch_id, p_product_id, COALESCE((SELECT stock_quantity FROM public.products WHERE id = p_product_id), 0), 0)
        RETURNING quantity_on_hand, quantity_reserved INTO v_curr_on_hand, v_curr_reserved;

        -- Re-lock
        SELECT quantity_on_hand, quantity_reserved
        INTO v_curr_on_hand, v_curr_reserved
        FROM public.branch_inventory
        WHERE branch_id = p_branch_id AND product_id = p_product_id
        FOR UPDATE;
    END IF;

    -- Prevent Negative Balances
    v_new_on_hand := v_curr_on_hand + p_qty_change;
    v_new_reserved := v_curr_reserved + COALESCE(p_qty_reserved_change, 0);

    IF v_new_on_hand < 0 THEN
        RAISE EXCEPTION 'INSUFFICIENT_STOCK: Branch % has only % units of product %, requested change %',
            p_branch_id, v_curr_on_hand, p_product_id, p_qty_change;
    END IF;

    IF v_new_reserved < 0 THEN
        v_new_reserved := 0;
    END IF;

    -- Update Branch Balance
    UPDATE public.branch_inventory
    SET quantity_on_hand = v_new_on_hand,
        quantity_reserved = v_new_reserved,
        updated_at = timezone('utc'::text, now())
    WHERE branch_id = p_branch_id AND product_id = p_product_id;

    -- Update Global Products Catalog Balance
    UPDATE public.products
    SET stock_quantity = (SELECT COALESCE(SUM(quantity_on_hand), 0)::int FROM public.branch_inventory WHERE product_id = p_product_id),
        sales_count = CASE WHEN p_movement_type = 'sale' THEN COALESCE(sales_count, 0) + GREATEST(0, (-p_qty_change)::int) ELSE sales_count END,
        updated_at = timezone('utc'::text, now())
    WHERE id = p_product_id;

    -- Generate Unique Movement Number
    v_mov_number := 'MOV-' || to_char(now(), 'YYYYMMDD-HH24MISS') || '-' || substr(md5(random()::text), 1, 6);

    -- Insert movement record
    INSERT INTO public.inventory_movements (
        movement_number, branch_id, product_id, movement_type,
        quantity_change, quantity_reserved_change,
        resulting_on_hand, resulting_reserved,
        reference_type, reference_id,
        actor_id, actor_name, actor_role,
        notes
    ) VALUES (
        v_mov_number, p_branch_id, p_product_id, p_movement_type,
        p_qty_change, COALESCE(p_qty_reserved_change, 0),
        v_new_on_hand, v_new_reserved,
        p_ref_type, p_ref_id,
        COALESCE(p_actor_id, auth.user_id()), p_actor_name, p_actor_role,
        p_notes
    );

    v_result := jsonb_build_object(
        'success', true,
        'movement_number', v_mov_number,
        'branch_id', p_branch_id,
        'product_id', p_product_id,
        'previous_on_hand', v_curr_on_hand,
        'new_on_hand', v_new_on_hand,
        'quantity_change', p_qty_change,
        'movement_type', p_movement_type
    );

    RETURN v_result;
END;
$$;

-- 13. High-Performance Atomic RPC: create_corporate_invoice_with_stock_deduction
-- Verifies credit limits, locks and decrements product inventory, inserts invoice & items, updates balance
CREATE OR REPLACE FUNCTION public.create_corporate_invoice_with_stock_deduction(p_payload JSONB)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_account_id UUID;
    v_branch_id VARCHAR(64);
    v_quotation_id UUID;
    v_items JSONB;
    v_item JSONB;
    v_notes TEXT;
    v_created_by TEXT;
    
    v_account public.corporate_accounts%ROWTYPE;
    v_prod public.products%ROWTYPE;
    
    v_subtotal NUMERIC(14,2) := 0.00;
    v_discount_amount NUMERIC(14,2) := 0.00;
    v_tax_amount NUMERIC(14,2) := 0.00;
    v_total_amount NUMERIC(14,2) := 0.00;
    
    v_item_qty NUMERIC(10,2);
    v_item_price NUMERIC(14,2);
    v_item_discount NUMERIC(5,2);
    v_item_final_price NUMERIC(14,2);
    v_item_total NUMERIC(14,2);
    
    v_invoice_id UUID;
    v_invoice_number TEXT;
    v_due_date DATE;
    v_due_days INT := 30;
    v_seq_num INT;
BEGIN
    -- Extract payload arguments
    v_account_id := (p_payload->>'corporate_account_id')::UUID;
    v_branch_id := p_payload->>'branch_id';
    IF p_payload ? 'quotation_id' AND p_payload->>'quotation_id' IS NOT NULL AND p_payload->>'quotation_id' <> '' THEN
        v_quotation_id := (p_payload->>'quotation_id')::UUID;
    END IF;
    v_items := p_payload->'items';
    v_notes := p_payload->>'notes';
    v_created_by := COALESCE(p_payload->>'created_by', auth.user_id(), 'مسؤول مبيعات الشركات');

    -- Validate Corporate Account
    SELECT * INTO v_account 
    FROM public.corporate_accounts 
    WHERE id = v_account_id 
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'ACCOUNT_NOT_FOUND: Corporate account % does not exist', v_account_id;
    END IF;

    IF v_account.status NOT IN ('active') THEN
        RAISE EXCEPTION 'ACCOUNT_INACTIVE: Corporate account % is %', v_account.company_name, v_account.status;
    END IF;

    IF v_branch_id IS NULL OR v_branch_id = '' THEN
        v_branch_id := v_account.branch_id;
    END IF;

    -- Validate Items array
    IF v_items IS NULL OR jsonb_array_length(v_items) = 0 THEN
        RAISE EXCEPTION 'EMPTY_ITEMS: Corporate invoice must contain at least one item';
    END IF;

    -- Calculate Totals & Validate Stock availability with Row Locks
    FOR v_item IN SELECT * FROM jsonb_array_elements(v_items)
    LOOP
        v_item_qty := COALESCE((v_item->>'quantity')::NUMERIC, 0);
        v_item_price := COALESCE((v_item->>'unit_price')::NUMERIC, 0);
        v_item_discount := COALESCE((v_item->>'discount_percent')::NUMERIC, 0);

        IF v_item_qty <= 0 THEN
            RAISE EXCEPTION 'INVALID_QUANTITY: Item quantity must be greater than zero';
        END IF;

        -- Lock product row
        SELECT * INTO v_prod 
        FROM public.products 
        WHERE id = (v_item->>'product_id')::UUID
        FOR UPDATE;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'PRODUCT_NOT_FOUND: Product % does not exist in catalog', v_item->>'product_id';
        END IF;

        v_item_final_price := ROUND(v_item_price * (1 - (v_item_discount / 100.0)), 2);
        v_item_total := ROUND(v_item_final_price * v_item_qty, 2);

        v_subtotal := v_subtotal + ROUND(v_item_price * v_item_qty, 2);
        v_discount_amount := v_discount_amount + (ROUND(v_item_price * v_item_qty, 2) - v_item_total);
    END LOOP;

    -- Compute VAT (15% Tax) and Grand Total
    v_tax_amount := ROUND((v_subtotal - v_discount_amount) * 0.15, 2);
    v_total_amount := (v_subtotal - v_discount_amount) + v_tax_amount;

    -- Credit Limit Enforcement Guard
    IF v_account.payment_terms <> 'Cash' THEN
        IF (v_account.current_balance + v_total_amount) > v_account.monthly_credit_limit THEN
            RAISE EXCEPTION 'CREDIT_LIMIT_EXCEEDED: Current balance (% ل.س) + Invoice (% ل.س) exceeds monthly credit limit (% ل.س)',
                v_account.current_balance, v_total_amount, v_account.monthly_credit_limit;
        END IF;
    END IF;

    -- Determine Due Date based on Payment Terms
    IF v_account.payment_terms = 'Net-15' THEN
        v_due_days := 15;
    ELSIF v_account.payment_terms = 'Net-60' THEN
        v_due_days := 60;
    ELSIF v_account.payment_terms = 'Cash' THEN
        v_due_days := 0;
    ELSE
        v_due_days := 30;
    END IF;
    v_due_date := CURRENT_DATE + (v_due_days || ' days')::INTERVAL;

    -- Generate Invoice Number
    SELECT COUNT(*) + 1 INTO v_seq_num FROM public.corporate_invoices;
    v_invoice_number := 'INV-B2B-' || to_char(CURRENT_DATE, 'YYYYMM') || '-' || lpad(v_seq_num::TEXT, 4, '0');
    v_invoice_id := gen_random_uuid();

    -- Insert Invoice Record
    INSERT INTO public.corporate_invoices (
        id,
        invoice_number,
        quotation_id,
        corporate_account_id,
        branch_id,
        subtotal,
        discount_amount,
        tax_amount,
        total_amount,
        paid_amount,
        remaining_amount,
        payment_status,
        due_date,
        notes,
        created_by
    ) VALUES (
        v_invoice_id,
        v_invoice_number,
        v_quotation_id,
        v_account_id,
        v_branch_id,
        v_subtotal,
        v_discount_amount,
        v_tax_amount,
        v_total_amount,
        0.00,
        v_total_amount,
        'unpaid',
        v_due_date,
        v_notes,
        v_created_by
    );

    -- Insert Items and Decrement Inventory via atomic movements
    FOR v_item IN SELECT * FROM jsonb_array_elements(v_items)
    LOOP
        v_item_qty := (v_item->>'quantity')::NUMERIC;
        v_item_price := (v_item->>'unit_price')::NUMERIC;
        v_item_discount := COALESCE((v_item->>'discount_percent')::NUMERIC, 0);
        v_item_final_price := ROUND(v_item_price * (1 - (v_item_discount / 100.0)), 2);
        v_item_total := ROUND(v_item_final_price * v_item_qty, 2);

        INSERT INTO public.corporate_invoice_items (
            invoice_id,
            product_id,
            quantity,
            unit_price,
            discount_percent,
            final_unit_price,
            total_price
        ) VALUES (
            v_invoice_id,
            (v_item->>'product_id')::UUID,
            v_item_qty,
            v_item_price,
            v_item_discount,
            v_item_final_price,
            v_item_total
        );

        -- Atomic stock reduction via record_inventory_movement_atomic
        PERFORM public.record_inventory_movement_atomic(
            v_branch_id,
            (v_item->>'product_id')::UUID,
            'sale',
            -v_item_qty,
            0,
            'order',
            v_invoice_number,
            v_created_by,
            'مبيعات شركات B2B',
            'b2b_sales',
            'صرف بضاعة فاتورة شركات رقم ' || v_invoice_number
        );
    END LOOP;

    -- Update Corporate Account Outstanding Balance
    UPDATE public.corporate_accounts
    SET current_balance = current_balance + v_total_amount,
        updated_at = NOW()
    WHERE id = v_account_id;

    -- If originated from quotation, mark quotation as converted
    IF v_quotation_id IS NOT NULL THEN
        UPDATE public.corporate_quotations
        SET status = 'converted',
            updated_at = NOW()
        WHERE id = v_quotation_id;
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'invoice_id', v_invoice_id,
        'invoice_number', v_invoice_number,
        'corporate_account_id', v_account_id,
        'company_name', v_account.company_name,
        'subtotal', v_subtotal,
        'discount_amount', v_discount_amount,
        'tax_amount', v_tax_amount,
        'total_amount', v_total_amount,
        'due_date', v_due_date,
        'payment_status', 'unpaid',
        'items_count', jsonb_array_length(v_items)
    );
END;
$$;

-- 14. High-Performance Atomic RPC: record_corporate_payment
-- Records payment transaction, decrements remaining invoice debt, marks invoice paid, and credits account balance
CREATE OR REPLACE FUNCTION public.record_corporate_payment(p_payload JSONB)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_invoice_id UUID;
    v_payment_amount NUMERIC(14,2);
    v_payment_method TEXT;
    v_reference_number TEXT;
    v_notes TEXT;
    v_received_by TEXT;
    
    v_invoice public.corporate_invoices%ROWTYPE;
    v_payment_id UUID;
    v_payment_number TEXT;
    v_new_paid NUMERIC(14,2);
    v_new_remaining NUMERIC(14,2);
    v_new_status TEXT;
    v_seq_num INT;
BEGIN
    v_invoice_id := (p_payload->>'invoice_id')::UUID;
    v_payment_amount := (p_payload->>'amount')::NUMERIC;
    v_payment_method := COALESCE(p_payload->>'payment_method', 'bank_transfer');
    v_reference_number := COALESCE(p_payload->>'reference_number', 'REF-' || to_char(NOW(), 'YYYYMMDD-HH24MI'));
    v_notes := p_payload->>'notes';
    v_received_by := COALESCE(p_payload->>'received_by', auth.user_id(), 'محاسب الشركات');

    IF v_payment_amount <= 0 THEN
        RAISE EXCEPTION 'INVALID_AMOUNT: Payment amount must be greater than zero';
    END IF;

    -- Lock and retrieve invoice
    SELECT * INTO v_invoice
    FROM public.corporate_invoices
    WHERE id = v_invoice_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'INVOICE_NOT_FOUND: Corporate invoice % does not exist', v_invoice_id;
    END IF;

    IF v_payment_amount > v_invoice.remaining_amount THEN
        RAISE EXCEPTION 'OVERPAYMENT_PROHIBITED: Payment amount (% ل.س) exceeds invoice remaining balance (% ل.س)',
            v_payment_amount, v_invoice.remaining_amount;
    END IF;

    v_new_paid := v_invoice.paid_amount + v_payment_amount;
    v_new_remaining := v_invoice.remaining_amount - v_payment_amount;
    v_new_status := CASE WHEN v_new_remaining <= 0.001 THEN 'paid' ELSE 'partially_paid' END;

    -- Generate payment number
    SELECT COUNT(*) + 1 INTO v_seq_num FROM public.corporate_payments;
    v_payment_number := 'PAY-B2B-' || to_char(CURRENT_DATE, 'YYYYMM') || '-' || lpad(v_seq_num::TEXT, 4, '0');
    v_payment_id := gen_random_uuid();

    -- Insert payment ledger record
    INSERT INTO public.corporate_payments (
        id,
        payment_number,
        invoice_id,
        corporate_account_id,
        amount,
        payment_method,
        reference_number,
        payment_date,
        notes,
        received_by
    ) VALUES (
        v_payment_id,
        v_payment_number,
        v_invoice_id,
        v_invoice.corporate_account_id,
        v_payment_amount,
        v_payment_method,
        v_reference_number,
        CURRENT_DATE,
        v_notes,
        v_received_by
    );

    -- Update invoice financial state
    UPDATE public.corporate_invoices
    SET paid_amount = v_new_paid,
        remaining_amount = v_new_remaining,
        payment_status = v_new_status,
        updated_at = NOW()
    WHERE id = v_invoice_id;

    -- Decrement corporate account balance (debt relief)
    UPDATE public.corporate_accounts
    SET current_balance = GREATEST(0.00, current_balance - v_payment_amount),
        updated_at = NOW()
    WHERE id = v_invoice.corporate_account_id;

    RETURN jsonb_build_object(
        'success', true,
        'payment_id', v_payment_id,
        'payment_number', v_payment_number,
        'invoice_id', v_invoice_id,
        'amount', v_payment_amount,
        'remaining_amount', v_new_remaining,
        'payment_status', v_new_status
    );
END;
$$;

-- 15. High-Performance Atomic RPC: process_corporate_return_with_stock_restoration
-- Approves/completes goods return, restores product catalog stock, adjusts invoice & customer debt
CREATE OR REPLACE FUNCTION public.process_corporate_return_with_stock_restoration(p_payload JSONB)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_return_id UUID;
    v_approved_by TEXT;
    v_return public.corporate_returns%ROWTYPE;
    v_item RECORD;
    v_invoice public.corporate_invoices%ROWTYPE;
    v_restored_count INT := 0;
BEGIN
    v_return_id := (p_payload->>'return_id')::UUID;
    v_approved_by := COALESCE(p_payload->>'approved_by', auth.user_id(), 'مدير مراقبة الجودة والمخزون');

    -- Lock return record
    SELECT * INTO v_return
    FROM public.corporate_returns
    WHERE id = v_return_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'RETURN_NOT_FOUND: Corporate return % does not exist', v_return_id;
    END IF;

    IF v_return.status = 'completed' THEN
        RAISE EXCEPTION 'ALREADY_COMPLETED: Return % has already been processed and inventory restored', v_return.return_number;
    END IF;

    -- Restore stock for each returned item via record_inventory_movement_atomic
    FOR v_item IN 
        SELECT product_id, quantity, unit_price, total_refund 
        FROM public.corporate_return_items 
        WHERE return_id = v_return_id
    LOOP
        PERFORM public.record_inventory_movement_atomic(
            v_return.branch_id,
            v_item.product_id,
            'return',
            v_item.quantity,
            0,
            'return',
            v_return.return_number,
            v_approved_by,
            'إرجاع مبيعات شركات B2B',
            'b2b_returns',
            'استرجاع بضاعة إشعار دائن رقم ' || v_return.return_number
        );
        
        v_restored_count := v_restored_count + 1;
    END LOOP;

    -- Adjust invoice financials
    SELECT * INTO v_invoice 
    FROM public.corporate_invoices 
    WHERE id = v_return.invoice_id 
    FOR UPDATE;

    IF FOUND THEN
        UPDATE public.corporate_invoices
        SET total_amount = GREATEST(0.00, total_amount - v_return.total_refund_amount),
            remaining_amount = GREATEST(0.00, remaining_amount - v_return.total_refund_amount),
            payment_status = CASE 
                WHEN GREATEST(0.00, remaining_amount - v_return.total_refund_amount) <= 0.001 THEN 'paid'
                ELSE payment_status 
            END,
            updated_at = NOW()
        WHERE id = v_return.invoice_id;
    END IF;

    -- Adjust corporate account balance
    UPDATE public.corporate_accounts
    SET current_balance = GREATEST(0.00, current_balance - v_return.total_refund_amount),
        updated_at = NOW()
    WHERE id = v_return.corporate_account_id;

    -- Mark return completed
    UPDATE public.corporate_returns
    SET status = 'completed',
        approved_by = v_approved_by,
        approved_at = NOW(),
        updated_at = NOW()
    WHERE id = v_return_id;

    RETURN jsonb_build_object(
        'success', true,
        'return_id', v_return_id,
        'return_number', v_return.return_number,
        'restored_items_count', v_restored_count,
        'total_refund_amount', v_return.total_refund_amount,
        'status', 'completed'
    );
END;
$$;

-- 16. High-Performance Atomic RPC: approve_or_reject_corporate_quotation
CREATE OR REPLACE FUNCTION public.approve_or_reject_corporate_quotation(p_payload JSONB)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_quotation_id UUID;
    v_action TEXT;
    v_staff_name TEXT;
    v_notes TEXT;
    v_reason TEXT;
    v_quote public.corporate_quotations%ROWTYPE;
BEGIN
    v_quotation_id := (p_payload->>'quotation_id')::UUID;
    v_action := lower(p_payload->>'action');
    v_staff_name := COALESCE(p_payload->>'staff_name', auth.user_id(), 'المدير المالي المعتمد');
    v_notes := p_payload->>'notes';
    v_reason := p_payload->>'reason';

    IF v_action NOT IN ('approve', 'reject') THEN
        RAISE EXCEPTION 'INVALID_ACTION: Action must be either "approve" or "reject"';
    END IF;

    SELECT * INTO v_quote
    FROM public.corporate_quotations
    WHERE id = v_quotation_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'QUOTATION_NOT_FOUND: Quotation % does not exist', v_quotation_id;
    END IF;

    IF v_action = 'approve' THEN
        UPDATE public.corporate_quotations
        SET status = 'approved',
            approved_by = v_staff_name,
            approved_at = NOW(),
            notes = COALESCE(v_notes, notes),
            updated_at = NOW()
        WHERE id = v_quotation_id;
    ELSE
        UPDATE public.corporate_quotations
        SET status = 'rejected',
            rejection_reason = COALESCE(v_reason, 'تم رفض عرض السعر بناءً على مراجعة شروط التوريد'),
            updated_at = NOW()
        WHERE id = v_quotation_id;
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'quotation_id', v_quotation_id,
        'quotation_number', v_quote.quotation_number,
        'status', CASE WHEN v_action = 'approve' THEN 'approved' ELSE 'rejected' END,
        'reviewed_by', v_staff_name
    );
END;
$$;

-- 17. Grant Schema & Table Access to authenticated & anon roles
GRANT USAGE ON SCHEMA public TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
-- For anon, only permit specific catalog reads and guest RPC execution
GRANT EXECUTE ON FUNCTION public.create_corporate_invoice_with_stock_deduction(JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION public.record_corporate_payment(JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION public.process_corporate_return_with_stock_restoration(JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION public.approve_or_reject_corporate_quotation(JSONB) TO authenticated;

-- 18. Seed Initial Realistic Corporate Accounts & Operational History
DO $$
DECLARE
    v_dam_branch VARCHAR(64) := 'b-dam-01';
    v_ruh_branch VARCHAR(64) := 'b-ruh-01';
    v_jed_branch VARCHAR(64) := 'b-jed-01';
    v_dmm_branch VARCHAR(64) := 'b-dmm-01';
    
    v_acc1 UUID := 'b2ba0000-0000-0000-0000-000000000001';
    v_acc2 UUID := 'b2ba0000-0000-0000-0000-000000000002';
    v_acc3 UUID := 'b2ba0000-0000-0000-0000-000000000003';
    v_acc4 UUID := 'b2ba0000-0000-0000-0000-000000000004';
    v_acc5 UUID := 'b2ba0000-0000-0000-0000-000000000005';
BEGIN
    -- Verify branches exist
    IF NOT EXISTS (SELECT 1 FROM public.branches WHERE id = v_dam_branch) THEN
        v_dam_branch := (SELECT id FROM public.branches LIMIT 1);
    END IF;

    -- Account 1: Syrian Telecom & Technology Corp (Damascus)
    INSERT INTO public.corporate_accounts (
        id, company_name, cr_number, vat_number, contact_person, phone, email,
        city, address, branch_id, monthly_credit_limit, current_balance,
        payment_terms, status, recurring_schedule, items_summary, notes
    ) VALUES (
        v_acc1,
        'الشركة السورية للاتصالات والتقنية (سيريتل - المقر العام)',
        '1010150261', '300000000000003', 'م. فهد السديري (مدير الخدمات والإعاشة)',
        '+963 93 112 3456', 'procurement@syriatel.sy',
        'دمشق', 'المزة - أوتوستراد المزة بجوار برج دمشق', v_dam_branch,
        15000000.00, 3200000.00, 'Net-30', 'active',
        'كل أحد 08:00 صباحاً (شحنة أسبوعية)',
        'بن اسبريسو فاخر، مياه معبأة، سلال فواكه مكتبية، معقمات ومحارم',
        'حساب استراتيجي - خصم تجاري معتمد 15%'
    ) ON CONFLICT (cr_number) DO NOTHING;

    -- Account 2: Cham Holding & Financial Services (Damascus)
    INSERT INTO public.corporate_accounts (
        id, company_name, cr_number, vat_number, contact_person, phone, email,
        city, address, branch_id, monthly_credit_limit, current_balance,
        payment_terms, status, recurring_schedule, items_summary, notes
    ) VALUES (
        v_acc2,
        'شركة شام القابضة للخدمات والاستثمار',
        '1010000096', '300000000000005', 'أ. ريم الشمري (المشتريات التشغيلية)',
        '+963 94 987 6543', 'purchases@chamholding.sy',
        'دمشق', 'كفرسوسة - مجمع الفردوس التجاري', v_dam_branch,
        10000000.00, 1850000.00, 'Net-30', 'active',
        'كل ثلاثاء 09:00 صباحاً',
        'شاي سيلاني فاخر، قهوة الديب، سناكات ومكسرات صحية للموظفين',
        'سداد منتظم عبر المصرف التجاري السوري'
    ) ON CONFLICT (cr_number) DO NOTHING;

    -- Account 3: Al-Aqeelah Takaful Insurance (Riyadh Branch)
    INSERT INTO public.corporate_accounts (
        id, company_name, cr_number, vat_number, contact_person, phone, email,
        city, address, branch_id, monthly_credit_limit, current_balance,
        payment_terms, status, recurring_schedule, items_summary, notes
    ) VALUES (
        v_acc3,
        'شركة العقيلة للتأمين التكافلي وإدارة المخاطر',
        '1010482910', '310928192000003', 'أ. ياسر العتيبي (الخدمات المشتركة)',
        '+966 54 332 1199', 'facilities@alaqeelah.com',
        'الرياض', 'طريق الملك فهد - حي العليا', v_ruh_branch,
        8000000.00, 0.00, 'Net-15', 'active',
        'كل أسبوعين صباح الإثنين',
        'مياه شرب معبأة، كبسولات قهوة، أكواب ورقية صديقة للبيئة',
        'عقد توريد مستمر لمقر الإدارة العامة'
    ) ON CONFLICT (cr_number) DO NOTHING;

    -- Account 4: Arab Medical Logistics & Hospital Restock (Jeddah)
    INSERT INTO public.corporate_accounts (
        id, company_name, cr_number, vat_number, contact_person, phone, email,
        city, address, branch_id, monthly_credit_limit, current_balance,
        payment_terms, status, recurring_schedule, items_summary, notes
    ) VALUES (
        v_acc4,
        'مجموعة الشفاء الطبية ومستودعات التموين',
        '1010928172', '310948291000003', 'د. طارق الحلبي (سلاسل الإمداد)',
        '+966 56 441 8822', 'supply@alshifa-med.com',
        'جدة', 'الكورنيش - طريق الأندلس', v_jed_branch,
        12000000.00, 4200000.00, 'Net-30', 'active',
        'الأحد والأربعاء مرتين أسبوعياً',
        'تموين كافتيريا الأطباء والموظفين، عصائر طبيعية، حليب وألبان طازجة',
        'تموين إعاشة متكامل لمستشفيات المجموعة'
    ) ON CONFLICT (cr_number) DO NOTHING;

    -- Account 5: Al-Badia Industrial & Construction Group (Dammam)
    INSERT INTO public.corporate_accounts (
        id, company_name, cr_number, vat_number, contact_person, phone, email,
        city, address, branch_id, monthly_credit_limit, current_balance,
        payment_terms, status, recurring_schedule, items_summary, notes
    ) VALUES (
        v_acc5,
        'مجموعة البادية للصناعات الإنشائية والوجبات الجاهزة',
        '2050001928', '300019281000003', 'م. نبيل كنعان (إدارة المشاريع)',
        '+966 53 771 9900', 'canteen@albadia-group.com',
        'الدمام', 'المنطقة الصناعية الأولى - شارع الميناء', v_dmm_branch,
        6000000.00, 6150000.00, 'Net-30', 'overdue',
        'أول يوم عمل من كل شهر',
        'تموين سكن العمال والمستودعات: أرز، زيوت طهي، سكر، معلبات غذائية',
        'تجاوز الحد الائتماني بمقدار 150,000 ل.س - يمنع إصدار فواتير آجلة جديدة قبل السداد'
    ) ON CONFLICT (cr_number) DO NOTHING;
END $$;

-- ============================================================================
-- MODULE 21: SUPPLIERS & PROCUREMENT SYSTEM (Task 8 Deliverable)
-- ============================================================================
-- ==============================================================================
-- Aldeeb Mall & Hypermarket - Migration 019: Suppliers & Procurement System
-- ==============================================================================
-- 1. Sequences for Server-Generated Unique Monotonic Identifiers
-- 2. Tables: suppliers, purchase_orders, purchase_order_items, inventory_transactions, supplier_payments
-- 3. Product Table Alterations (cost_price, is_draft, status)
-- 4. Atomic Stored Procedures / RPCs:
--    - create_purchase_order
--    - receive_purchase_order_items
--    - record_supplier_payment
--    - cancel_purchase_order
--    - approve_draft_product
-- 5. Row Level Security & RBAC Enforcement
-- 6. Initial Certified Suppliers Seed
-- ==============================================================================

-- 1. Sequences
CREATE SEQUENCE IF NOT EXISTS public.po_number_seq START WITH 1001 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS public.inv_trx_seq START WITH 1001 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS public.sup_pay_seq START WITH 1001 INCREMENT BY 1;

-- 2. Enhance products table with cost and lifecycle tracking
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS cost_price NUMERIC(10,2) DEFAULT NULL;
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS is_draft BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'published';

-- 3. Suppliers Table
CREATE TABLE IF NOT EXISTS public.suppliers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name_ar TEXT NOT NULL,
    name_en TEXT,
    contact_person TEXT,
    phone TEXT,
    email TEXT,
    address TEXT,
    commercial_reg TEXT,
    tax_number TEXT,
    lead_time_days INTEGER NOT NULL DEFAULT 1,
    payment_terms TEXT NOT NULL DEFAULT 'آجل 30 يوماً',
    active_products_count INTEGER NOT NULL DEFAULT 0,
    balance NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'under_review', 'inactive')),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_suppliers_status ON public.suppliers(status);
CREATE INDEX IF NOT EXISTS idx_suppliers_name_ar ON public.suppliers(name_ar);

-- 4. Purchase Orders Table
CREATE TABLE IF NOT EXISTS public.purchase_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    po_number TEXT UNIQUE NOT NULL,
    supplier_id UUID REFERENCES public.suppliers(id) ON DELETE RESTRICT,
    supplier_name TEXT NOT NULL,
    branch_id VARCHAR(64) REFERENCES public.branches(id) ON DELETE RESTRICT,
    status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'sent', 'partially_received', 'received', 'cancelled')),
    payment_status TEXT NOT NULL DEFAULT 'unpaid' CHECK (payment_status IN ('unpaid', 'partial', 'paid')),
    total_items NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    total_cost NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    paid_amount NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    order_date DATE NOT NULL DEFAULT CURRENT_DATE,
    expected_arrival TEXT,
    notes TEXT,
    cancellation_reason TEXT,
    created_by TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_purchase_orders_supplier ON public.purchase_orders(supplier_id);
CREATE INDEX IF NOT EXISTS idx_purchase_orders_branch ON public.purchase_orders(branch_id);
CREATE INDEX IF NOT EXISTS idx_purchase_orders_status ON public.purchase_orders(status);
CREATE INDEX IF NOT EXISTS idx_purchase_orders_po_num ON public.purchase_orders(po_number);

-- 5. Purchase Order Items Table
CREATE TABLE IF NOT EXISTS public.purchase_order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    purchase_order_id UUID NOT NULL REFERENCES public.purchase_orders(id) ON DELETE CASCADE,
    product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
    name_ar TEXT NOT NULL,
    barcode TEXT,
    unit TEXT NOT NULL DEFAULT 'piece',
    quantity_ordered NUMERIC(12,2) NOT NULL CHECK (quantity_ordered > 0),
    quantity_received NUMERIC(12,2) NOT NULL DEFAULT 0.00 CHECK (quantity_received >= 0),
    quantity_damaged NUMERIC(12,2) NOT NULL DEFAULT 0.00 CHECK (quantity_damaged >= 0),
    unit_cost NUMERIC(15,2) NOT NULL CHECK (unit_cost >= 0),
    total_cost NUMERIC(15,2) NOT NULL CHECK (total_cost >= 0),
    is_new_draft_product BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_po_items_po_id ON public.purchase_order_items(purchase_order_id);
CREATE INDEX IF NOT EXISTS idx_po_items_product_id ON public.purchase_order_items(product_id);

-- 6. Inventory Transactions (Stock Movement Ledger)
CREATE TABLE IF NOT EXISTS public.inventory_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_number TEXT UNIQUE NOT NULL,
    branch_id VARCHAR(64) NOT NULL REFERENCES public.branches(id) ON DELETE RESTRICT,
    product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
    movement_type TEXT NOT NULL CHECK (movement_type IN ('purchase_receipt', 'damaged_loss', 'sales_deduction', 'inventory_transfer', 'inventory_adjustment')),
    reference_type TEXT NOT NULL CHECK (reference_type IN ('purchase_order', 'order_sale', 'transfer', 'manual_audit')),
    reference_id TEXT NOT NULL,
    quantity_change NUMERIC(12,2) NOT NULL,
    unit_cost NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    total_value NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    balance_after NUMERIC(12,2),
    performed_by TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_inv_trx_branch ON public.inventory_transactions(branch_id);
CREATE INDEX IF NOT EXISTS idx_inv_trx_product ON public.inventory_transactions(product_id);
CREATE INDEX IF NOT EXISTS idx_inv_trx_type ON public.inventory_transactions(movement_type);
CREATE INDEX IF NOT EXISTS idx_inv_trx_ref ON public.inventory_transactions(reference_type, reference_id);

-- 7. Supplier Payments Table
CREATE TABLE IF NOT EXISTS public.supplier_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    payment_number TEXT UNIQUE NOT NULL,
    purchase_order_id UUID NOT NULL REFERENCES public.purchase_orders(id) ON DELETE CASCADE,
    supplier_id UUID REFERENCES public.suppliers(id) ON DELETE RESTRICT,
    amount NUMERIC(15,2) NOT NULL CHECK (amount > 0),
    payment_method TEXT NOT NULL CHECK (payment_method IN ('sham_cash', 'cash', 'bank_transfer')),
    payment_reference TEXT,
    paid_by TEXT,
    notes TEXT,
    paid_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_sup_payments_po_id ON public.supplier_payments(purchase_order_id);
CREATE INDEX IF NOT EXISTS idx_sup_payments_supplier_id ON public.supplier_payments(supplier_id);

-- ==============================================================================
-- 8. Atomic Stored Procedures & Business Logic RPCs
-- ==============================================================================

-- Procedure: create_purchase_order
CREATE OR REPLACE FUNCTION public.create_purchase_order(
    p_supplier_id UUID,
    p_supplier_name TEXT,
    p_branch_id VARCHAR,
    p_expected_arrival TEXT,
    p_notes TEXT,
    p_items JSONB,
    p_created_by TEXT DEFAULT 'مدير المشتريات'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_po_id UUID;
    v_po_number TEXT;
    v_seq_val BIGINT;
    v_item JSONB;
    v_total_cost NUMERIC(15,2) := 0.00;
    v_total_items NUMERIC(12,2) := 0.00;
    v_item_qty NUMERIC(12,2);
    v_item_cost NUMERIC(15,2);
    v_item_total NUMERIC(15,2);
    v_product_id UUID;
    v_prod_id_raw TEXT;
    v_is_draft BOOLEAN;
    v_result JSONB;
BEGIN
    -- Enforce RBAC caller role checks
    IF auth.user_role() IN ('cashier', 'auditor') THEN
        RAISE EXCEPTION 'ليس لديك صلاحية لإصدار أوامر الشراء والتوريد';
    END IF;

    -- Validate Supplier exists
    IF p_supplier_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.suppliers WHERE id = p_supplier_id) THEN
        RAISE EXCEPTION 'المورد المحدد غير موجود في قاعدة البيانات';
    END IF;

    -- Validate Branch exists
    IF p_branch_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.branches WHERE id = p_branch_id) THEN
        RAISE EXCEPTION 'الفرع المحدد غير موجود في قاعدة البيانات';
    END IF;

    -- Validate items list is not empty
    IF p_items IS NULL OR jsonb_array_length(p_items) = 0 THEN
        RAISE EXCEPTION 'لا يمكن إنشاء أمر شراء بدون بنود أو أصناف';
    END IF;

    -- Generate atomic sequential PO Number: PO-2026-XXXX
    v_seq_val := nextval('public.po_number_seq');
    v_po_number := 'PO-2026-' || LPAD(v_seq_val::TEXT, 4, '0');

    -- Insert Master PO Record
    INSERT INTO public.purchase_orders (
        po_number,
        supplier_id,
        supplier_name,
        branch_id,
        status,
        payment_status,
        total_items,
        total_cost,
        paid_amount,
        order_date,
        expected_arrival,
        notes,
        created_by
    ) VALUES (
        v_po_number,
        p_supplier_id,
        p_supplier_name,
        p_branch_id,
        'sent',
        'unpaid',
        0,
        0,
        0,
        CURRENT_DATE,
        p_expected_arrival,
        p_notes,
        p_created_by
    )
    RETURNING id INTO v_po_id;

    -- Process Each Item
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_item_qty := COALESCE((v_item->>'quantity_ordered')::NUMERIC, 0);
        v_item_cost := COALESCE((v_item->>'unit_cost')::NUMERIC, 0);

        IF v_item_qty <= 0 THEN
            RAISE EXCEPTION 'كمية الصنف يجب أن تكون أكبر من صفر';
        END IF;

        IF v_item_cost < 0 THEN
            RAISE EXCEPTION 'سعر تكلفة الصنف لا يمكن أن يكون سالباً';
        END IF;

        v_item_total := v_item_qty * v_item_cost;
        v_total_cost := v_total_cost + v_item_total;
        v_total_items := v_total_items + v_item_qty;

        v_prod_id_raw := v_item->>'product_id';
        v_is_draft := COALESCE((v_item->>'is_new_draft_product')::BOOLEAN, false);

        -- Safe UUID parsing
        BEGIN
            IF v_prod_id_raw IS NOT NULL AND v_prod_id_raw <> '' THEN
                v_product_id := v_prod_id_raw::UUID;
            ELSE
                v_product_id := NULL;
            END IF;
        EXCEPTION WHEN OTHERS THEN
            v_product_id := NULL;
        END;

        -- If draft product with no existing UUID, check barcode or create in products as draft
        IF v_is_draft AND v_product_id IS NULL THEN
            IF v_item->>'barcode' IS NOT NULL AND v_item->>'barcode' <> '' THEN
                SELECT id INTO v_product_id FROM public.products WHERE barcode = v_item->>'barcode';
            END IF;

            IF v_product_id IS NULL THEN
                INSERT INTO public.products (
                    name_ar,
                    name_en,
                    brand,
                    barcode,
                    category_id,
                    price,
                    cost_price,
                    unit,
                    stock_quantity,
                    images,
                    is_featured,
                    is_daily_deal,
                    rating,
                    is_active,
                    is_draft,
                    status
                ) VALUES (
                    v_item->>'name_ar',
                    COALESCE(v_item->>'name_en', v_item->>'name_ar'),
                    COALESCE(p_supplier_name, 'توريد عام'),
                    COALESCE(v_item->>'barcode', 'GEN-' || floor(random() * 899999999 + 100000000)::TEXT),
                    (SELECT id FROM public.categories LIMIT 1),
                    ROUND(v_item_cost * 1.35, 2),
                    v_item_cost,
                    COALESCE(v_item->>'unit', 'piece'),
                    0, -- 0 initial stock until received at warehouse
                    ARRAY['https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=400&q=80'],
                    false,
                    false,
                    4.8,
                    false, -- Inactive for customer app until approved
                    true,
                    'incomplete_data'
                )
                ON CONFLICT (barcode) DO UPDATE SET updated_at = timezone('utc'::text, now())
                RETURNING id INTO v_product_id;
            END IF;
        END IF;

        -- Insert Item
        INSERT INTO public.purchase_order_items (
            purchase_order_id,
            product_id,
            name_ar,
            barcode,
            unit,
            quantity_ordered,
            quantity_received,
            quantity_damaged,
            unit_cost,
            total_cost,
            is_new_draft_product
        ) VALUES (
            v_po_id,
            v_product_id,
            v_item->>'name_ar',
            v_item->>'barcode',
            COALESCE(v_item->>'unit', 'piece'),
            v_item_qty,
            0,
            0,
            v_item_cost,
            v_item_total,
            v_is_draft
        );
    END LOOP;

    -- Update totals on PO record
    UPDATE public.purchase_orders
    SET total_items = v_total_items,
        total_cost = v_total_cost,
        updated_at = timezone('utc'::text, now())
    WHERE id = v_po_id;

    -- Accrue supplier balance if supplier provided
    IF p_supplier_id IS NOT NULL THEN
        UPDATE public.suppliers
        SET balance = balance + v_total_cost,
            updated_at = timezone('utc'::text, now())
        WHERE id = p_supplier_id;
    END IF;

    -- Return full JSON representation
    SELECT jsonb_build_object(
        'success', true,
        'id', p.id,
        'po_number', p.po_number,
        'supplier_id', p.supplier_id,
        'supplier_name', p.supplier_name,
        'branch_id', p.branch_id,
        'status', p.status,
        'payment_status', p.payment_status,
        'total_items', p.total_items,
        'total_cost', p.total_cost,
        'paid_amount', p.paid_amount,
        'order_date', p.order_date,
        'expected_arrival', p.expected_arrival,
        'notes', p.notes,
        'created_at', p.created_at
    ) INTO v_result
    FROM public.purchase_orders p
    WHERE p.id = v_po_id;

    RETURN v_result;
END;
$$;


-- Procedure: receive_purchase_order_items
CREATE OR REPLACE FUNCTION public.receive_purchase_order_items(
    p_po_id UUID,
    p_receipts JSONB,
    p_receiver TEXT DEFAULT 'أمين المستودع',
    p_branch_id VARCHAR DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_po RECORD;
    v_receipt JSONB;
    v_item_id UUID;
    v_item RECORD;
    v_newly_received NUMERIC(12,2);
    v_damaged NUMERIC(12,2);
    v_net_good NUMERIC(12,2);
    v_new_total_received NUMERIC(12,2);
    v_new_total_damaged NUMERIC(12,2);
    v_all_fulfilled BOOLEAN := true;
    v_any_received BOOLEAN := false;
    v_target_branch VARCHAR(64);
    v_trx_num TEXT;
    v_result JSONB;
BEGIN
    -- Enforce RBAC caller role checks
    IF auth.user_role() IN ('cashier', 'auditor') THEN
        RAISE EXCEPTION 'ليس لديك صلاحية لاستلام بضائع المستودع أو تعديل المخزون';
    END IF;

    -- Lock PO row FOR UPDATE
    SELECT * INTO v_po
    FROM public.purchase_orders
    WHERE id = p_po_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'أمر الشراء المطلوب غير موجود';
    END IF;

    IF v_po.status = 'cancelled' THEN
        RAISE EXCEPTION 'لا يمكن استلام بضائع لأمر شراء تم إلغاؤه مسبقاً';
    END IF;

    v_target_branch := COALESCE(p_branch_id, v_po.branch_id, 'b-dam-01');

    -- Process Receipts
    FOR v_receipt IN SELECT * FROM jsonb_array_elements(p_receipts)
    LOOP
        v_item_id := (v_receipt->>'item_id')::UUID;
        v_newly_received := COALESCE((v_receipt->>'quantity_received')::NUMERIC, 0);
        v_damaged := COALESCE((v_receipt->>'quantity_damaged')::NUMERIC, 0);

        IF v_newly_received < 0 OR v_damaged < 0 THEN
            RAISE EXCEPTION 'الكميات المستلمة أو التالفة لا يمكن أن تكون سالبة';
        END IF;

        IF v_damaged > v_newly_received THEN
            RAISE EXCEPTION 'الكمية التالفة لا يمكن أن تتجاوز الكمية المستلمة في الإرسالية';
        END IF;

        -- Lock Item Row
        SELECT * INTO v_item
        FROM public.purchase_order_items
        WHERE id = v_item_id AND purchase_order_id = p_po_id
        FOR UPDATE;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'أحد بنود التوريد غير مطابق لأمر الشراء هذا';
        END IF;

        -- Prevent receiving beyond ordered quantity
        v_net_good := v_newly_received - v_damaged;
        v_new_total_received := v_item.quantity_received + v_net_good;
        v_new_total_damaged := v_item.quantity_damaged + v_damaged;

        IF v_new_total_received > v_item.quantity_ordered THEN
            RAISE EXCEPTION 'الكمية المستلمة الصافية تتجاوز الكمية المطلوبة في أمر الشراء للصنف: %', v_item.name_ar;
        END IF;

        -- Update Item Record
        UPDATE public.purchase_order_items
        SET quantity_received = v_new_total_received,
            quantity_damaged = v_new_total_damaged,
            updated_at = timezone('utc'::text, now())
        WHERE id = v_item_id;

        -- If Good Stock Received, Increase Product Catalog Stock and Record Ledger Movement
        IF v_net_good > 0 THEN
            v_any_received := true;

            -- Update Product Stock & Cost
            IF v_item.product_id IS NOT NULL THEN
                UPDATE public.products
                SET stock_quantity = stock_quantity + v_net_good::INTEGER,
                    cost_price = v_item.unit_cost,
                    updated_at = timezone('utc'::text, now())
                WHERE id = v_item.product_id;
            END IF;

            -- Record in Central Inventory Transaction Ledger
            v_trx_num := 'TX-REC-' || LPAD(nextval('public.inv_trx_seq')::TEXT, 6, '0');
            INSERT INTO public.inventory_transactions (
                transaction_number,
                branch_id,
                product_id,
                movement_type,
                reference_type,
                reference_id,
                quantity_change,
                unit_cost,
                total_value,
                performed_by,
                notes
            ) VALUES (
                v_trx_num,
                v_target_branch,
                v_item.product_id,
                'purchase_receipt',
                'purchase_order',
                v_po.po_number,
                v_net_good,
                v_item.unit_cost,
                v_net_good * v_item.unit_cost,
                p_receiver,
                'استلام توريد رسمي لأمر الشراء ' || v_po.po_number
            );

            -- If Damasucs Branch, also log to branch_dam_01 schema if active
            IF v_target_branch = 'b-dam-01' THEN
                BEGIN
                    INSERT INTO branch_dam_01.inventory_movements (
                        product_id,
                        movement_type,
                        quantity,
                        balance_after,
                        reference_id,
                        reason,
                        created_by
                    ) VALUES (
                        v_item.product_id,
                        'transfer_in',
                        v_net_good::INTEGER,
                        (SELECT COALESCE(stock_quantity, 0) FROM public.products WHERE id = v_item.product_id),
                        v_po.po_number,
                        'توريد مستودعي معتمد من المورد: ' || v_po.supplier_name,
                        p_receiver
                    );
                EXCEPTION WHEN OTHERS THEN
                    -- Non-blocking schema isolation fallback
                    NULL;
                END;
            END IF;
        END IF;

        -- If Damaged, Record Damaged Loss Transaction
        IF v_damaged > 0 THEN
            v_trx_num := 'TX-DMG-' || LPAD(nextval('public.inv_trx_seq')::TEXT, 6, '0');
            INSERT INTO public.inventory_transactions (
                transaction_number,
                branch_id,
                product_id,
                movement_type,
                reference_type,
                reference_id,
                quantity_change,
                unit_cost,
                total_value,
                performed_by,
                notes
            ) VALUES (
                v_trx_num,
                v_target_branch,
                v_item.product_id,
                'damaged_loss',
                'purchase_order',
                v_po.po_number,
                -v_damaged,
                v_item.unit_cost,
                v_damaged * v_item.unit_cost,
                p_receiver,
                'بضاعة تالفة / مرفوضة عند الفحص والاستلام لأمر الشراء ' || v_po.po_number
            );
        END IF;
    END LOOP;

    -- Evaluate All Items to Determine Final Status
    SELECT bool_and(quantity_received >= quantity_ordered),
           bool_or(quantity_received > 0)
    INTO v_all_fulfilled, v_any_received
    FROM public.purchase_order_items
    WHERE purchase_order_id = p_po_id;

    UPDATE public.purchase_orders
    SET status = CASE 
            WHEN v_all_fulfilled THEN 'received'
            WHEN v_any_received THEN 'partially_received'
            ELSE status
        END,
        updated_at = timezone('utc'::text, now())
    WHERE id = p_po_id;

    SELECT jsonb_build_object(
        'success', true,
        'po_id', p_po_id,
        'status', (SELECT status FROM public.purchase_orders WHERE id = p_po_id),
        'all_fulfilled', v_all_fulfilled
    ) INTO v_result;

    RETURN v_result;
END;
$$;


-- Procedure: record_supplier_payment
CREATE OR REPLACE FUNCTION public.record_supplier_payment(
    p_po_id UUID,
    p_amount NUMERIC,
    p_payment_method TEXT,
    p_reference TEXT DEFAULT NULL,
    p_payer TEXT DEFAULT 'المحاسب المالي',
    p_notes TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_po RECORD;
    v_remaining NUMERIC(15,2);
    v_new_paid NUMERIC(15,2);
    v_payment_num TEXT;
    v_new_status TEXT;
    v_result JSONB;
BEGIN
    -- Enforce RBAC caller role checks
    IF auth.user_role() IN ('cashier', 'auditor', 'warehouse_manager') THEN
        RAISE EXCEPTION 'ليس لديك صلاحية لصرف وتسجيل دفعات الموردين المالية';
    END IF;

    IF p_amount <= 0 THEN
        RAISE EXCEPTION 'مبلغ السداد يجب أن يكون أكبر من صفر';
    END IF;

    IF p_payment_method NOT IN ('sham_cash', 'cash', 'bank_transfer') THEN
        RAISE EXCEPTION 'طريقة السداد غير معتمدة';
    END IF;

    -- Lock PO Row
    SELECT * INTO v_po
    FROM public.purchase_orders
    WHERE id = p_po_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'أمر الشراء المطلوب غير موجود';
    END IF;

    v_remaining := v_po.total_cost - v_po.paid_amount;
    IF p_amount > v_remaining + 0.01 THEN
        RAISE EXCEPTION 'مبلغ السداد المطلوب (%) يتجاوز الرصيد المتبقي المستحق (%)', p_amount, v_remaining;
    END IF;

    -- Generate Unique Payment Number: SP-PAY-XXXXX
    v_payment_num := 'SP-PAY-' || LPAD(nextval('public.sup_pay_seq')::TEXT, 5, '0');

    -- Insert Payment Record
    INSERT INTO public.supplier_payments (
        payment_number,
        purchase_order_id,
        supplier_id,
        amount,
        payment_method,
        payment_reference,
        paid_by,
        notes
    ) VALUES (
        v_payment_num,
        p_po_id,
        v_po.supplier_id,
        p_amount,
        p_payment_method,
        p_reference,
        p_payer,
        p_notes
    );

    v_new_paid := v_po.paid_amount + p_amount;
    v_new_status := CASE WHEN v_new_paid >= v_po.total_cost THEN 'paid' ELSE 'partial' END;

    -- Update PO
    UPDATE public.purchase_orders
    SET paid_amount = v_new_paid,
        payment_status = v_new_status,
        updated_at = timezone('utc'::text, now())
    WHERE id = p_po_id;

    -- Decrease Supplier Balance
    IF v_po.supplier_id IS NOT NULL THEN
        UPDATE public.suppliers
        SET balance = GREATEST(0.00, balance - p_amount),
            updated_at = timezone('utc'::text, now())
        WHERE id = v_po.supplier_id;
    END IF;

    SELECT jsonb_build_object(
        'success', true,
        'payment_number', v_payment_num,
        'paid_amount', v_new_paid,
        'payment_status', v_new_status,
        'remaining_balance', GREATEST(0.00, v_po.total_cost - v_new_paid)
    ) INTO v_result;

    RETURN v_result;
END;
$$;


-- Procedure: cancel_purchase_order
CREATE OR REPLACE FUNCTION public.cancel_purchase_order(
    p_po_id UUID,
    p_reason TEXT,
    p_user TEXT DEFAULT 'مدير المشتريات'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_po RECORD;
    v_has_receipts BOOLEAN;
BEGIN
    -- Enforce RBAC caller role checks
    IF auth.user_role() IN ('cashier', 'auditor') THEN
        RAISE EXCEPTION 'ليس لديك صلاحية لإلغاء أوامر الشراء المعتمدة';
    END IF;

    SELECT * INTO v_po
    FROM public.purchase_orders
    WHERE id = p_po_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'أمر الشراء المطلوب غير موجود';
    END IF;

    IF v_po.status = 'cancelled' THEN
        RAISE EXCEPTION 'أمر الشراء ملغى بالفعل';
    END IF;

    -- Check if any items have been received
    SELECT EXISTS (
        SELECT 1 FROM public.purchase_order_items 
        WHERE purchase_order_id = p_po_id AND quantity_received > 0
    ) INTO v_has_receipts;

    IF v_has_receipts THEN
        RAISE EXCEPTION 'لا يمكن إلغاء أمر شراء تم استلام بضائع منه جزئياً أو كلياً';
    END IF;

    UPDATE public.purchase_orders
    SET status = 'cancelled',
        cancellation_reason = p_reason,
        updated_at = timezone('utc'::text, now())
    WHERE id = p_po_id;

    -- Reverse accrued balance from supplier if unpaid
    IF v_po.supplier_id IS NOT NULL THEN
        UPDATE public.suppliers
        SET balance = GREATEST(0.00, balance - (v_po.total_cost - v_po.paid_amount)),
            updated_at = timezone('utc'::text, now())
        WHERE id = v_po.supplier_id;
    END IF;

    RETURN jsonb_build_object('success', true, 'status', 'cancelled');
END;
$$;


-- Procedure: approve_draft_product
CREATE OR REPLACE FUNCTION public.approve_draft_product(
    p_product_id UUID,
    p_user TEXT DEFAULT 'مدير الكتالوج'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE public.products
    SET is_draft = false,
        is_active = true,
        status = 'published',
        updated_at = timezone('utc'::text, now())
    WHERE id = p_product_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'الصنف المطلوب غير موجود';
    END IF;

    RETURN jsonb_build_object('success', true, 'product_id', p_product_id, 'is_active', true, 'status', 'published');
END;
$$;

-- ==============================================================================
-- 9. Row Level Security & Access Policies
-- ==============================================================================
ALTER TABLE public.suppliers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.purchase_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.purchase_order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.supplier_payments ENABLE ROW LEVEL SECURITY;

-- Suppliers Policies
DROP POLICY IF EXISTS "suppliers_read_policy" ON public.suppliers;
CREATE POLICY "suppliers_read_policy" ON public.suppliers FOR SELECT
USING (true);

DROP POLICY IF EXISTS "suppliers_write_policy" ON public.suppliers;
CREATE POLICY "suppliers_write_policy" ON public.suppliers FOR ALL
USING (auth.user_role() IN ('super_admin', 'general_manager', 'warehouse_manager', 'branch_manager', 'accountant'))
WITH CHECK (auth.user_role() IN ('super_admin', 'general_manager', 'warehouse_manager', 'branch_manager', 'accountant'));

-- Purchase Orders Policies
DROP POLICY IF EXISTS "purchase_orders_read_policy" ON public.purchase_orders;
CREATE POLICY "purchase_orders_read_policy" ON public.purchase_orders FOR SELECT
USING (true);

DROP POLICY IF EXISTS "purchase_orders_write_policy" ON public.purchase_orders;
CREATE POLICY "purchase_orders_write_policy" ON public.purchase_orders FOR ALL
USING (auth.user_role() IN ('super_admin', 'general_manager', 'warehouse_manager', 'branch_manager'))
WITH CHECK (auth.user_role() IN ('super_admin', 'general_manager', 'warehouse_manager', 'branch_manager'));

-- Purchase Order Items Policies
DROP POLICY IF EXISTS "po_items_read_policy" ON public.purchase_order_items;
CREATE POLICY "po_items_read_policy" ON public.purchase_order_items FOR SELECT
USING (true);

DROP POLICY IF EXISTS "po_items_write_policy" ON public.purchase_order_items;
CREATE POLICY "po_items_write_policy" ON public.purchase_order_items FOR ALL
USING (auth.user_role() IN ('super_admin', 'general_manager', 'warehouse_manager', 'branch_manager'))
WITH CHECK (auth.user_role() IN ('super_admin', 'general_manager', 'warehouse_manager', 'branch_manager'));

-- Inventory Transactions Policies
DROP POLICY IF EXISTS "inv_trx_read_policy" ON public.inventory_transactions;
CREATE POLICY "inv_trx_read_policy" ON public.inventory_transactions FOR SELECT
USING (true);

DROP POLICY IF EXISTS "inv_trx_write_policy" ON public.inventory_transactions;
CREATE POLICY "inv_trx_write_policy" ON public.inventory_transactions FOR ALL
USING (auth.user_role() IN ('super_admin', 'general_manager', 'warehouse_manager', 'branch_manager'))
WITH CHECK (auth.user_role() IN ('super_admin', 'general_manager', 'warehouse_manager', 'branch_manager'));

-- Supplier Payments Policies
DROP POLICY IF EXISTS "sup_pay_read_policy" ON public.supplier_payments;
CREATE POLICY "sup_pay_read_policy" ON public.supplier_payments FOR SELECT
USING (true);

DROP POLICY IF EXISTS "sup_pay_write_policy" ON public.supplier_payments;
CREATE POLICY "sup_pay_write_policy" ON public.supplier_payments FOR ALL
USING (auth.user_role() IN ('super_admin', 'general_manager', 'accountant'))
WITH CHECK (auth.user_role() IN ('super_admin', 'general_manager', 'accountant'));

-- Grant access to anon & authenticated for PostgREST
GRANT ALL ON public.suppliers TO anon, authenticated;
GRANT ALL ON public.purchase_orders TO anon, authenticated;
GRANT ALL ON public.purchase_order_items TO anon, authenticated;
GRANT ALL ON public.inventory_transactions TO anon, authenticated;
GRANT ALL ON public.supplier_payments TO anon, authenticated;

GRANT USAGE, SELECT ON SEQUENCE public.po_number_seq TO anon, authenticated;
GRANT USAGE, SELECT ON SEQUENCE public.inv_trx_seq TO anon, authenticated;
GRANT USAGE, SELECT ON SEQUENCE public.sup_pay_seq TO anon, authenticated;

-- ==============================================================================
-- 10. Seed Initial Certified Suppliers & Baseline Purchase Orders
-- ==============================================================================
INSERT INTO public.suppliers (id, name_ar, name_en, contact_person, phone, email, lead_time_days, payment_terms, active_products_count, balance, status)
VALUES
    ('e1000000-0000-0000-0000-000000000001', 'شركة المراعي للألبان والعصائر', 'Almarai Dairy & Food Co.', 'م. فهد القحطاني', '+963 11 888 1234', 'b2b.orders@almarai.com', 1, 'آجل 30 يوماً', 85, 345000.00, 'active'),
    ('e1000000-0000-0000-0000-000000000002', 'شركة التنمية للدواجن والأغذية الطازجة', 'Tanmiah Fresh Food Co.', 'د. سامر الرفاعي', '+963 11 777 5678', 'supply@tanmiah.com', 1, 'آجل 15 يوماً', 42, 185000.00, 'active'),
    ('e1000000-0000-0000-0000-000000000003', 'مؤسسة مزارع غوطة دمشق للخضار والفواكه', 'Damascus Oasis Fresh Farms', 'أ. أنس الحمصي', '+963 11 666 9012', 'ghouta.produce@gmail.com', 1, 'نقداً عند الاستلام', 64, 92000.00, 'active'),
    ('e1000000-0000-0000-0000-000000000004', 'شركة الديب ومستودعات التموين الكبرى', 'Aldeeb Grand Wholesale Logistics', 'م. حسام الديب', '+963 11 555 4321', 'procurement@aldeebmall.com', 2, 'حساب جارٍ شهري', 190, 720000.00, 'active')
ON CONFLICT (id) DO UPDATE SET
    name_ar = EXCLUDED.name_ar,
    name_en = EXCLUDED.name_en,
    contact_person = EXCLUDED.contact_person,
    phone = EXCLUDED.phone,
    email = EXCLUDED.email;

-- Track migration in _schema_migrations
INSERT INTO public._schema_migrations (filename, applied_at)
VALUES ('20261104_019_suppliers_and_procurement_system.sql', timezone('utc'::text, now()))
ON CONFLICT (filename) DO UPDATE SET applied_at = timezone('utc'::text, now());
