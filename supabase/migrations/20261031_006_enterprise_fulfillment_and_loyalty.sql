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
