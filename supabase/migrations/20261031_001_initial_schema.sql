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
