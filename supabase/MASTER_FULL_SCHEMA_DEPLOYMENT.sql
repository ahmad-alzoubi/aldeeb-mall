-- ==============================================================================
-- الديب مول (Aldeeb Mall) - Database Schema Migration
-- Migration 001: Tables, Types, Constraints, and Indexes
-- ==============================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

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
    discount_type TEXT NOT NULL CHECK (discount_type IN ('percentage', 'fixed')),
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
('sc000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', 'فواكه طازجة', 'Fresh Fruits', 'fruits', 1),
('sc000000-0000-0000-0000-000000000002', 'c0000000-0000-0000-0000-000000000001', 'خضار ورقية وجذرية', 'Vegetables', 'vegetables', 2),
('sc000000-0000-0000-0000-000000000003', 'c0000000-0000-0000-0000-000000000002', 'حليب ولبن رائب', 'Milk & Laban', 'milk-laban', 1),
('sc000000-0000-0000-0000-000000000004', 'c0000000-0000-0000-0000-000000000002', 'أجبان وزبدة وقشطة', 'Cheese & Butter', 'cheese-butter', 2),
('sc000000-0000-0000-0000-000000000005', 'c0000000-0000-0000-0000-000000000003', 'دواجن طازجة ومجمدة', 'Fresh Poultry', 'poultry', 1),
('sc000000-0000-0000-0000-000000000006', 'c0000000-0000-0000-0000-000000000003', 'لحوم بقر وضأن', 'Beef & Mutton', 'red-meat', 2),
('sc000000-0000-0000-0000-000000000007', 'c0000000-0000-0000-0000-000000000004', 'خبز وتوست طازج', 'Bread & Buns', 'bread-toast', 1),
('sc000000-0000-0000-0000-000000000008', 'c0000000-0000-0000-0000-000000000005', 'مياه معدنية طبيعية', 'Mineral Water', 'water', 1),
('sc000000-0000-0000-0000-000000000009', 'c0000000-0000-0000-0000-000000000005', 'عصائر طازجة وطبيعية', 'Fresh Juices', 'juices', 2),
('sc000000-0000-0000-0000-000000000010', 'c0000000-0000-0000-0000-000000000008', 'مساحيق ومنعمات الغسيل', 'Laundry Care', 'laundry', 1)
ON CONFLICT (id) DO NOTHING;

-- 3. Insert Products
INSERT INTO public.products (
    id, category_id, subcategory_id, barcode, name_ar, name_en, 
    description_ar, description_en, brand, price, original_price, discount_percent, 
    unit, weight_step, stock_quantity, images, is_featured, is_daily_deal, rating, sales_count
) VALUES
-- Fruits & Veg
(
    'p0000000-0000-0000-0000-000000000001',
    'c0000000-0000-0000-0000-000000000001',
    'sc000000-0000-0000-0000-000000000001',
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
    'p0000000-0000-0000-0000-000000000002',
    'c0000000-0000-0000-0000-000000000001',
    'sc000000-0000-0000-0000-000000000001',
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
    'p0000000-0000-0000-0000-000000000003',
    'c0000000-0000-0000-0000-000000000001',
    'sc000000-0000-0000-0000-000000000002',
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
    'p0000000-0000-0000-0000-000000000004',
    'c0000000-0000-0000-0000-000000000002',
    'sc000000-0000-0000-0000-000000000003',
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
    'p0000000-0000-0000-0000-000000000005',
    'c0000000-0000-0000-0000-000000000002',
    'sc000000-0000-0000-0000-000000000004',
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
    'p0000000-0000-0000-0000-000000000006',
    'c0000000-0000-0000-0000-000000000003',
    'sc000000-0000-0000-0000-000000000005',
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
    'p0000000-0000-0000-0000-000000000007',
    'c0000000-0000-0000-0000-000000000004',
    'sc000000-0000-0000-0000-000000000007',
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
    'p0000000-0000-0000-0000-000000000008',
    'c0000000-0000-0000-0000-000000000005',
    'sc000000-0000-0000-0000-000000000008',
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
    'p0000000-0000-0000-0000-000000000009',
    'c0000000-0000-0000-0000-000000000008',
    'sc000000-0000-0000-0000-000000000010',
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
('cp000000-0000-0000-0000-000000000001', 'ALDEEB10', 'percentage', 10.00, 50.00, 30.00, 1000, true),
('cp000000-0000-0000-0000-000000000002', 'SAVE20', 'percentage', 20.00, 120.00, 50.00, 500, true),
('cp000000-0000-0000-0000-000000000003', 'WELCOME15', 'fixed', 15.00, 75.00, 15.00, 2000, true)
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
    'p0000000-0000-0000-0000-000000000003',
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
    'p0000000-0000-0000-0000-000000000008',
    'c0000000-0000-0000-0000-000000000005',
    '629100000008',
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
    'p0000000-0000-0000-0000-000000000009',
    'c0000000-0000-0000-0000-000000000006',
    '629100000009',
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
    'p0000000-0000-0000-0000-000000000010',
    'c0000000-0000-0000-0000-000000000007',
    '629100000010',
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
    'p0000000-0000-0000-0000-000000000011',
    'c0000000-0000-0000-0000-000000000008',
    '629100000011',
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
    'p0000000-0000-0000-0000-000000000012',
    'c0000000-0000-0000-0000-000000000009',
    '629100000012',
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
    'p0000000-0000-0000-0000-000000000013',
    'c0000000-0000-0000-0000-000000000011',
    '629100000013',
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
