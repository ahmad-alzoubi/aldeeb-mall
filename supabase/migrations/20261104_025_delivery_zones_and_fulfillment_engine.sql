-- ==============================================================================
-- 🚚 ALDEEB MALL: DELIVERY ZONES, COVERAGE VALIDATION & FULFILLMENT ENGINE
-- Migration: 20261104_025_delivery_zones_and_fulfillment_engine.sql
-- Step 025 in the Single Monotonic Migration Sequence (Task 15)
-- ==============================================================================

BEGIN;

-- 1. Create delivery_zones table
CREATE TABLE IF NOT EXISTS public.delivery_zones (
    id VARCHAR(64) PRIMARY KEY,
    zone_name_ar VARCHAR(255) NOT NULL,
    zone_name_en VARCHAR(255),
    city VARCHAR(100) NOT NULL,
    district VARCHAR(100),
    branch_id VARCHAR(64) REFERENCES public.branches(id) ON DELETE SET NULL,
    dark_store_code VARCHAR(64) DEFAULT 'WH-DAM-HUB',
    center_latitude NUMERIC(10, 7) NOT NULL DEFAULT 33.5138,
    center_longitude NUMERIC(10, 7) NOT NULL DEFAULT 36.2765,
    radius_km NUMERIC(6, 2) NOT NULL DEFAULT 5.00,
    base_delivery_fee NUMERIC(12, 2) NOT NULL DEFAULT 5000.00,
    free_delivery_threshold NUMERIC(12, 2) NOT NULL DEFAULT 150000.00,
    estimated_minutes INTEGER NOT NULL DEFAULT 25,
    is_surge_pricing_active BOOLEAN NOT NULL DEFAULT false,
    surge_fee NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    is_active BOOLEAN NOT NULL DEFAULT true,
    opening_time TIME NOT NULL DEFAULT '08:00:00',
    closing_time TIME NOT NULL DEFAULT '23:59:59',
    max_hourly_capacity INTEGER NOT NULL DEFAULT 50,
    current_hourly_load INTEGER NOT NULL DEFAULT 0,
    delivery_options JSONB NOT NULL DEFAULT '[
        {"id": "express", "name_ar": "توصيل إكسبريس فوري ⚡", "fee_modifier": 0, "estimated_minutes": 30},
        {"id": "scheduled", "name_ar": "توصيل مجدول 📅", "fee_modifier": 0, "estimated_minutes": 120},
        {"id": "click_collect", "name_ar": "استلام من فرع المول (Click & Collect)", "fee_modifier": 0, "estimated_minutes": 30},
        {"id": "curbside", "name_ar": "استلام من السيارة (Curbside Pickup 🚗)", "fee_modifier": 0, "estimated_minutes": 15}
    ]'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT delivery_zones_radius_check CHECK (radius_km > 0),
    CONSTRAINT delivery_zones_fee_check CHECK (base_delivery_fee >= 0),
    CONSTRAINT delivery_zones_surge_check CHECK (surge_fee >= 0),
    CONSTRAINT delivery_zones_threshold_check CHECK (free_delivery_threshold >= 0),
    CONSTRAINT delivery_zones_capacity_check CHECK (max_hourly_capacity >= 0 AND current_hourly_load >= 0)
);

CREATE INDEX IF NOT EXISTS idx_delivery_zones_city ON public.delivery_zones(city);
CREATE INDEX IF NOT EXISTS idx_delivery_zones_branch ON public.delivery_zones(branch_id);
CREATE INDEX IF NOT EXISTS idx_delivery_zones_active ON public.delivery_zones(is_active);

-- 2. Force Row Level Security (RLS)
ALTER TABLE public.delivery_zones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.delivery_zones FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "delivery_zones_select_policy" ON public.delivery_zones;
CREATE POLICY "delivery_zones_select_policy" ON public.delivery_zones
    FOR SELECT TO public
    USING (true);

DROP POLICY IF EXISTS "delivery_zones_mutate_policy" ON public.delivery_zones;
CREATE POLICY "delivery_zones_mutate_policy" ON public.delivery_zones
    FOR ALL TO authenticated
    USING (auth.user_role() IN ('super_admin', 'general_manager', 'branch_manager', 'warehouse_manager', 'operations_manager', 'auditor'))
    WITH CHECK (auth.user_role() IN ('super_admin', 'general_manager', 'branch_manager', 'warehouse_manager', 'operations_manager', 'auditor'));

-- Grants for PostgREST & Application Roles
GRANT ALL ON public.delivery_zones TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.check_delivery_coverage(NUMERIC, NUMERIC, TEXT, TEXT, NUMERIC, TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.haversine_distance_km(NUMERIC, NUMERIC, NUMERIC, NUMERIC) TO anon, authenticated;

-- 3. Haversine Distance Calculation Function in Kilometers
CREATE OR REPLACE FUNCTION public.haversine_distance_km(
    p_lat1 NUMERIC,
    p_lon1 NUMERIC,
    p_lat2 NUMERIC,
    p_lon2 NUMERIC
)
RETURNS NUMERIC
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
    v_r NUMERIC := 6371.0; -- Earth radius in km
    v_dlat NUMERIC;
    v_dlon NUMERIC;
    v_a NUMERIC;
    v_c NUMERIC;
    v_rad_lat1 NUMERIC;
    v_rad_lat2 NUMERIC;
BEGIN
    IF p_lat1 IS NULL OR p_lon1 IS NULL OR p_lat2 IS NULL OR p_lon2 IS NULL THEN
        RETURN NULL;
    END IF;

    -- Degrees to Radians
    v_rad_lat1 := radians(p_lat1);
    v_rad_lat2 := radians(p_lat2);
    v_dlat := radians(p_lat2 - p_lat1);
    v_dlon := radians(p_lon2 - p_lon1);

    v_a := sin(v_dlat / 2.0)^2 + cos(v_rad_lat1) * cos(v_rad_lat2) * sin(v_dlon / 2.0)^2;
    -- Clamp v_a to [0, 1] to prevent domain errors
    v_a := least(greatest(v_a, 0.0), 1.0);
    v_c := 2.0 * asin(sqrt(v_a));

    RETURN round(v_r * v_c, 3);
END;
$$;

-- 4. Server-Side Address Verification, Branch Selection, and Dynamic Fee Engine
CREATE OR REPLACE FUNCTION public.check_delivery_coverage(
    p_latitude NUMERIC DEFAULT NULL,
    p_longitude NUMERIC DEFAULT NULL,
    p_city TEXT DEFAULT NULL,
    p_district TEXT DEFAULT NULL,
    p_subtotal NUMERIC DEFAULT 0.0,
    p_delivery_slot TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
    v_zone RECORD;
    v_branch RECORD;
    v_best_zone RECORD;
    v_best_zone_found BOOLEAN := false;
    v_min_distance NUMERIC := 999999.0;
    v_calc_distance NUMERIC;
    v_current_time TIME := localtime;
    v_is_within_hours BOOLEAN := true;
    v_is_free BOOLEAN := false;
    v_final_fee NUMERIC := 0.0;
    v_surge_applied BOOLEAN := false;
    v_surge_fee NUMERIC := 0.0;
BEGIN
    -- Check if Click & Collect or Curbside (no delivery fee, bypass zone coverage)
    IF p_delivery_slot IS NOT NULL AND (
        p_delivery_slot ILIKE '%استلام%' OR 
        p_delivery_slot ILIKE '%pickup%' OR 
        p_delivery_slot ILIKE '%click%' OR 
        p_delivery_slot ILIKE '%كاشير%' OR 
        p_delivery_slot ILIKE '%pos%'
    ) THEN
        RETURN jsonb_build_object(
            'is_covered', true,
            'is_pickup', true,
            'zone_id', 'zn-pickup-direct',
            'zone_name_ar', 'استلام مباشر من الفرع',
            'branch_id', 'b-dam-01',
            'branch_name_ar', 'فرع دمشق المركزي (أوتوستراد المزة)',
            'base_delivery_fee', 0.00,
            'surge_fee', 0.00,
            'is_surge_active', false,
            'final_delivery_fee', 0.00,
            'is_free_delivery', true,
            'estimated_minutes', 15,
            'distance_km', 0.0,
            'status', 'ALLOWED',
            'message', 'خيار الاستلام المباشر متاح بدون أي رسوم توصيل'
        );
    END IF;

    -- 1. Find the best matching zone
    -- A: By GPS coordinates if provided
    IF p_latitude IS NOT NULL AND p_longitude IS NOT NULL THEN
        FOR v_zone IN 
            SELECT z.*, b.name_ar AS b_name_ar, b.is_active AS b_is_active
            FROM public.delivery_zones z
            LEFT JOIN public.branches b ON z.branch_id = b.id
        LOOP
            v_calc_distance := public.haversine_distance_km(p_latitude, p_longitude, v_zone.center_latitude, v_zone.center_longitude);
            
            -- If inside radius and closer than any previous match
            IF v_calc_distance <= v_zone.radius_km AND v_calc_distance < v_min_distance THEN
                v_min_distance := v_calc_distance;
                v_best_zone := v_zone;
                v_best_zone_found := true;
            END IF;
        END LOOP;
    END IF;

    -- B: Fallback by City / District name if GPS not provided or not matched directly
    IF NOT v_best_zone_found AND p_city IS NOT NULL AND trim(p_city) <> '' THEN
        SELECT z.*, b.name_ar AS b_name_ar, b.is_active AS b_is_active
        INTO v_best_zone
        FROM public.delivery_zones z
        LEFT JOIN public.branches b ON z.branch_id = b.id
        WHERE z.city ILIKE '%' || trim(p_city) || '%'
           OR (p_district IS NOT NULL AND (z.district ILIKE '%' || trim(p_district) || '%' OR z.zone_name_ar ILIKE '%' || trim(p_district) || '%'))
        ORDER BY z.is_active DESC, z.radius_km DESC
        LIMIT 1;

        IF FOUND THEN
            v_best_zone_found := true;
            v_min_distance := v_best_zone.radius_km * 0.5; -- approximate nominal distance
        END IF;
    END IF;

    -- 2. Verify Zone Coverage & Active Status
    IF NOT v_best_zone_found THEN
        RETURN jsonb_build_object(
            'is_covered', false,
            'rejection_reason', 'OUT_OF_COVERAGE',
            'status', 'REJECTED',
            'message', 'عذراً، العنوان المحدد يقع خارج نطاق التغطية الجغرافية لخدمة التوصيل'
        );
    END IF;

    -- Check if zone itself is deactivated (e.g. Daraa excluded by default)
    IF NOT v_best_zone.is_active THEN
        RETURN jsonb_build_object(
            'is_covered', false,
            'zone_id', v_best_zone.id,
            'zone_name_ar', v_best_zone.zone_name_ar,
            'rejection_reason', 'ZONE_INACTIVE',
            'status', 'REJECTED',
            'message', 'عذراً، نطاق التوصيل في (' || v_best_zone.zone_name_ar || ') غير متاح حالياً أو معطل من قبل الإدارة'
        );
    END IF;

    -- 3. Verify Associated Branch Operational Status
    IF v_best_zone.branch_id IS NOT NULL THEN
        SELECT * INTO v_branch FROM public.branches WHERE id = v_best_zone.branch_id;
        IF NOT FOUND OR NOT v_branch.is_active THEN
            RETURN jsonb_build_object(
                'is_covered', false,
                'zone_id', v_best_zone.id,
                'zone_name_ar', v_best_zone.zone_name_ar,
                'branch_id', v_best_zone.branch_id,
                'branch_name_ar', COALESCE(v_branch.name_ar, 'الفرع المحدد'),
                'rejection_reason', 'BRANCH_CLOSED',
                'status', 'REJECTED',
                'message', 'عذراً، فرع التوصيل المسؤول عن هذا النطاق (' || COALESCE(v_branch.name_ar, v_best_zone.branch_id) || ') مغلق حالياً للصيانة أو خارج أوقات العمل'
            );
        END IF;
    END IF;

    -- 4. Verify Operating Hours
    IF v_best_zone.opening_time IS NOT NULL AND v_best_zone.closing_time IS NOT NULL THEN
        IF v_best_zone.opening_time <= v_best_zone.closing_time THEN
            IF v_current_time < v_best_zone.opening_time OR v_current_time > v_best_zone.closing_time THEN
                v_is_within_hours := false;
            END IF;
        ELSE
            -- Spans across midnight
            IF v_current_time < v_best_zone.opening_time AND v_current_time > v_best_zone.closing_time THEN
                v_is_within_hours := false;
            END IF;
        END IF;

        IF NOT v_is_within_hours THEN
            RETURN jsonb_build_object(
                'is_covered', false,
                'zone_id', v_best_zone.id,
                'zone_name_ar', v_best_zone.zone_name_ar,
                'rejection_reason', 'OUTSIDE_OPERATING_HOURS',
                'opening_time', v_best_zone.opening_time,
                'closing_time', v_best_zone.closing_time,
                'status', 'REJECTED',
                'message', 'عذراً، خدمة التوصيل في هذا النطاق تعمل يومياً من ' || to_char(v_best_zone.opening_time, 'HH12:MI AM') || ' إلى ' || to_char(v_best_zone.closing_time, 'HH12:MI AM')
            );
        END IF;
    END IF;

    -- 5. Calculate Server-Authoritative Fee & Dynamic Surge
    IF p_subtotal >= v_best_zone.free_delivery_threshold AND p_subtotal > 0 THEN
        v_is_free := true;
        v_final_fee := 0.00;
        v_surge_applied := false;
    ELSE
        v_final_fee := v_best_zone.base_delivery_fee;
        IF v_best_zone.is_surge_pricing_active THEN
            v_surge_applied := true;
            v_surge_fee := v_best_zone.surge_fee;
            v_final_fee := v_final_fee + v_surge_fee;
        END IF;
    END IF;

    -- Return full success contract
    RETURN jsonb_build_object(
        'is_covered', true,
        'zone_id', v_best_zone.id,
        'zone_name_ar', v_best_zone.zone_name_ar,
        'city', v_best_zone.city,
        'district', v_best_zone.district,
        'branch_id', v_best_zone.branch_id,
        'branch_name_ar', COALESCE(v_best_zone.b_name_ar, 'الفرع المركزي'),
        'dark_store_code', v_best_zone.dark_store_code,
        'distance_km', v_min_distance,
        'radius_km', v_best_zone.radius_km,
        'base_delivery_fee', v_best_zone.base_delivery_fee,
        'is_surge_active', v_best_zone.is_surge_pricing_active,
        'surge_fee', v_surge_fee,
        'surge_applied', v_surge_applied,
        'final_delivery_fee', v_final_fee,
        'free_delivery_threshold', v_best_zone.free_delivery_threshold,
        'is_free_delivery', v_is_free,
        'estimated_minutes', v_best_zone.estimated_minutes,
        'opening_time', v_best_zone.opening_time,
        'closing_time', v_best_zone.closing_time,
        'delivery_options', v_best_zone.delivery_options,
        'status', 'ALLOWED',
        'message', 'النطاق مشمول بالتغطية ومتاح للتوصيل الفوري'
    );
END;
$$;

-- 5. Update place_order_atomic to respect authoritative delivery_zones table
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
    p_items jsonb,
    p_branch_id text DEFAULT 'b-jed-01',
    p_coupon_code text DEFAULT NULL,
    p_idempotency_key text DEFAULT NULL,
    p_customer_name text DEFAULT NULL,
    p_customer_phone text DEFAULT NULL
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
    v_effective_idempotency_key text;
    v_target_branch_id text;
    v_branch_name text;
    v_order_id uuid;
    v_item jsonb;
    v_product_id uuid;
    v_prod_rec record;
    v_qty numeric;
    v_db_price numeric;
    v_line_total numeric;
    v_calc_subtotal numeric := 0;
    v_effective_subtotal numeric;
    v_coupon_rec record;
    v_calc_coupon_discount numeric := 0;
    v_user_loyalty_balance int;
    v_redemption_rate numeric;
    v_calc_loyalty_discount numeric := 0;
    v_standard_delivery_fee numeric := 10.00;
    v_free_delivery_threshold numeric := 100.00;
    v_matched_zone record;
    v_expected_delivery_fee numeric := 0;
    v_calc_total numeric := 0;
    v_existing_order record;
    v_new_stock int;
    v_branch_stock numeric(12,2);
    v_inv_trx_num text;
    v_result jsonb;
BEGIN
    -- -------------------------------------------------------------------------
    -- STEP 1: Idempotency Protection — Return existing order on retry
    -- -------------------------------------------------------------------------
    v_effective_idempotency_key := COALESCE(NULLIF(trim(p_idempotency_key), ''), p_order_number);

    SELECT o.id, o.order_number, o.status, o.subtotal, o.delivery_fee, o.discount_amount,
           o.loyalty_points_used, o.loyalty_discount, o.total_amount, o.branch_id, o.branch_name, o.created_at
    INTO v_existing_order
    FROM public.orders o
    WHERE o.order_number = p_order_number
       OR (v_effective_idempotency_key IS NOT NULL AND o.idempotency_key = v_effective_idempotency_key)
    LIMIT 1;

    IF FOUND THEN
        RETURN jsonb_build_object(
            'id', v_existing_order.id,
            'order_number', v_existing_order.order_number,
            'status', v_existing_order.status,
            'subtotal', v_existing_order.subtotal,
            'delivery_fee', v_existing_order.delivery_fee,
            'discount_amount', v_existing_order.discount_amount,
            'loyalty_points_used', v_existing_order.loyalty_points_used,
            'loyalty_discount', v_existing_order.loyalty_discount,
            'total_amount', v_existing_order.total_amount,
            'branch_id', v_existing_order.branch_id,
            'branch_name', v_existing_order.branch_name,
            'created_at', v_existing_order.created_at,
            'is_idempotent_replay', true
        );
    END IF;

    -- -------------------------------------------------------------------------
    -- STEP 2: Caller Identity & Privilege Verification
    -- -------------------------------------------------------------------------
    v_caller_id := auth.uid();
    v_is_admin := public.is_admin();

    IF v_caller_id IS NOT NULL THEN
        v_effective_user_id := v_caller_id;
    ELSIF v_is_admin OR current_user IN ('postgres', 'ahmad_alzoubi') THEN
        v_effective_user_id := p_user_id;
    ELSE
        IF p_user_id IS NOT NULL THEN
            RAISE EXCEPTION 'UNAUTHORIZED: Anonymous callers cannot assign orders to registered user accounts';
        END IF;
        v_effective_user_id := NULL;
    END IF;

    IF (p_delivery_slot ILIKE '%كاشير%' OR p_delivery_slot ILIKE '%pos%') AND v_caller_id IS NULL AND NOT v_is_admin THEN
        RAISE EXCEPTION 'UNAUTHORIZED_POS: In-store POS cashier orders must be placed by authenticated staff';
    END IF;

    -- -------------------------------------------------------------------------
    -- STEP 3: Branch Verification
    -- -------------------------------------------------------------------------
    v_target_branch_id := COALESCE(NULLIF(trim(p_branch_id), ''), auth.branch_id(), 'b-dam-01');

    SELECT id, name_ar INTO v_target_branch_id, v_branch_name
    FROM public.branches
    WHERE id = v_target_branch_id AND is_active = true;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'INVALID_BRANCH: Branch % does not exist or is inactive', p_branch_id;
    END IF;

    -- -------------------------------------------------------------------------
    -- STEP 4: Authoritative Catalog Pricing & Stock Lock
    -- -------------------------------------------------------------------------
    IF p_items IS NULL OR jsonb_array_length(p_items) = 0 THEN
        RAISE EXCEPTION 'EMPTY_ITEMS: Cannot place an order without items';
    END IF;

    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        IF (v_item->>'product_id') IS NULL OR NOT ((v_item->>'product_id') ~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$') THEN
            RAISE EXCEPTION 'PRODUCT_NOT_FOUND: Product ID is missing, null, or has an invalid UUID format';
        END IF;

        v_product_id := (v_item->>'product_id')::uuid;

        v_qty := (v_item->>'quantity')::numeric;
        IF v_qty IS NULL OR v_qty <= 0 THEN
            RAISE EXCEPTION 'INVALID_QUANTITY: Quantity must be greater than zero';
        END IF;

        SELECT id, name_ar, name_en, price, stock_quantity, is_active
        INTO v_prod_rec
        FROM public.products
        WHERE id = v_product_id
        FOR UPDATE;

        IF NOT FOUND OR NOT v_prod_rec.is_active THEN
            RAISE EXCEPTION 'PRODUCT_NOT_FOUND: Product with id % does not exist or is inactive', v_product_id;
        END IF;

        v_db_price := v_prod_rec.price;

        IF (v_item->>'unit_price') IS NOT NULL THEN
            IF abs((v_item->>'unit_price')::numeric - v_db_price) > 0.05 THEN
                RAISE EXCEPTION 'PRICE_TAMPERED: Price mismatch for product %. Expected %, received %',
                    v_product_id, v_db_price, (v_item->>'unit_price')::numeric;
            END IF;
        END IF;

        SELECT quantity_on_hand INTO v_branch_stock
        FROM public.branch_inventory
        WHERE branch_id = v_target_branch_id AND product_id = v_product_id
        FOR UPDATE;

        IF FOUND THEN
            IF v_branch_stock < v_qty THEN
                RAISE EXCEPTION 'INSUFFICIENT_STOCK: Only % units available for product % in branch %',
                    v_branch_stock, v_product_id, v_target_branch_id;
            END IF;
        ELSE
            IF v_prod_rec.stock_quantity < v_qty THEN
                RAISE EXCEPTION 'INSUFFICIENT_STOCK: Only % units available for product %', v_prod_rec.stock_quantity, v_product_id;
            END IF;
        END IF;

        v_line_total := round(v_db_price * v_qty, 2);
        v_calc_subtotal := v_calc_subtotal + v_line_total;
    END LOOP;

    IF p_subtotal IS NOT NULL AND abs(p_subtotal - v_calc_subtotal) > 0.50 THEN
        RAISE EXCEPTION 'SUBTOTAL_TAMPERED: Subtotal mismatch. Server computed %, client sent %', v_calc_subtotal, p_subtotal;
    END IF;
    v_effective_subtotal := v_calc_subtotal;

    -- -------------------------------------------------------------------------
    -- STEP 5: Coupon Validation & Calculation
    -- -------------------------------------------------------------------------
    IF p_coupon_code IS NOT NULL AND trim(p_coupon_code) <> '' THEN
        SELECT id, code, discount_type, discount_value, min_order_amount, max_discount, usage_limit, times_used, expires_at, is_active
        INTO v_coupon_rec
        FROM public.coupons
        WHERE lower(code) = lower(trim(p_coupon_code))
        FOR UPDATE;

        IF NOT FOUND OR NOT v_coupon_rec.is_active THEN
            RAISE EXCEPTION 'INVALID_COUPON: Coupon % does not exist or is inactive', p_coupon_code;
        END IF;

        IF v_coupon_rec.expires_at IS NOT NULL AND v_coupon_rec.expires_at < now() THEN
            RAISE EXCEPTION 'COUPON_EXPIRED: Coupon % expired at %', p_coupon_code, v_coupon_rec.expires_at;
        END IF;

        IF v_effective_subtotal < v_coupon_rec.min_order_amount THEN
            RAISE EXCEPTION 'COUPON_MIN_ORDER_NOT_MET: Minimum order amount of % required for coupon %',
                v_coupon_rec.min_order_amount, p_coupon_code;
        END IF;

        IF v_coupon_rec.usage_limit IS NOT NULL AND v_coupon_rec.times_used >= v_coupon_rec.usage_limit THEN
            RAISE EXCEPTION 'COUPON_USAGE_LIMIT_REACHED: Coupon % has reached its maximum usage limit', p_coupon_code;
        END IF;

        IF v_coupon_rec.discount_type IN ('percentage', 'percent') THEN
            v_calc_coupon_discount := round((v_effective_subtotal * v_coupon_rec.discount_value / 100.0), 2);
            IF v_coupon_rec.max_discount IS NOT NULL AND v_calc_coupon_discount > v_coupon_rec.max_discount THEN
                v_calc_coupon_discount := v_coupon_rec.max_discount;
            END IF;
        ELSE
            v_calc_coupon_discount := least(v_coupon_rec.discount_value, v_effective_subtotal);
        END IF;

        IF p_discount_amount IS NOT NULL AND abs(p_discount_amount - v_calc_coupon_discount) > 0.50 THEN
            RAISE EXCEPTION 'DISCOUNT_TAMPERED: Discount mismatch. Server computed %, client sent %',
                v_calc_coupon_discount, p_discount_amount;
        END IF;

        UPDATE public.coupons
        SET times_used = times_used + 1
        WHERE id = v_coupon_rec.id;
    ELSE
        v_calc_coupon_discount := 0;
    END IF;

    -- -------------------------------------------------------------------------
    -- STEP 6: Loyalty Points Validation & Redemption
    -- -------------------------------------------------------------------------
    IF COALESCE(p_loyalty_points_used, 0) > 0 THEN
        IF v_effective_user_id IS NULL THEN
            RAISE EXCEPTION 'UNAUTHORIZED_LOYALTY: Guest orders cannot redeem loyalty points';
        END IF;

        SELECT loyalty_points INTO v_user_loyalty_balance
        FROM public.profiles
        WHERE id = v_effective_user_id
        FOR UPDATE;

        IF v_user_loyalty_balance IS NULL OR v_user_loyalty_balance < p_loyalty_points_used THEN
            RAISE EXCEPTION 'INSUFFICIENT_LOYALTY_POINTS: User only has % points, requested %',
                COALESCE(v_user_loyalty_balance, 0), p_loyalty_points_used;
        END IF;

        SELECT COALESCE(points_redemption_rate, 0.01) INTO v_redemption_rate
        FROM public.store_settings
        WHERE id = 'default';
        IF v_redemption_rate IS NULL THEN v_redemption_rate := 0.01; END IF;

        v_calc_loyalty_discount := round(p_loyalty_points_used * v_redemption_rate, 2);

        IF p_loyalty_discount IS NOT NULL AND abs(p_loyalty_discount - v_calc_loyalty_discount) > 0.50 THEN
            RAISE EXCEPTION 'LOYALTY_DISCOUNT_TAMPERED: Loyalty discount mismatch. Server computed %, client sent %',
                v_calc_loyalty_discount, p_loyalty_discount;
        END IF;

        UPDATE public.profiles
        SET loyalty_points = loyalty_points - p_loyalty_points_used,
            updated_at = timezone('utc'::text, now())
        WHERE id = v_effective_user_id;
    ELSE
        v_calc_loyalty_discount := 0;
    END IF;

    -- -------------------------------------------------------------------------
    -- STEP 7: Authoritative Delivery Zones & Delivery Fee Verification
    -- -------------------------------------------------------------------------
    IF p_delivery_fee IS NOT NULL AND p_delivery_fee < 0 THEN
        RAISE EXCEPTION 'DELIVERY_FEE_TAMPERED: Delivery fee cannot be negative';
    END IF;

    SELECT * INTO v_matched_zone
    FROM public.delivery_zones
    WHERE branch_id = v_target_branch_id AND is_active = true
    ORDER BY free_delivery_threshold ASC
    LIMIT 1;

    IF FOUND THEN
        v_standard_delivery_fee := v_matched_zone.base_delivery_fee;
        IF v_matched_zone.is_surge_pricing_active THEN
            v_standard_delivery_fee := v_standard_delivery_fee + v_matched_zone.surge_fee;
        END IF;
        v_free_delivery_threshold := v_matched_zone.free_delivery_threshold;
    ELSE
        SELECT COALESCE(delivery_fee, 5000.00), COALESCE(free_delivery_threshold, 150000.00)
        INTO v_standard_delivery_fee, v_free_delivery_threshold
        FROM public.store_settings
        WHERE id = 'default';
    END IF;

    IF p_delivery_slot ILIKE '%كاشير%' 
       OR p_delivery_slot ILIKE '%pos%' 
       OR p_delivery_slot ILIKE '%استلام%' 
       OR p_delivery_slot ILIKE '%pickup%' 
       OR p_delivery_slot ILIKE '%click%' THEN
        v_expected_delivery_fee := 0;
    ELSIF v_effective_subtotal >= v_free_delivery_threshold THEN
        v_expected_delivery_fee := 0;
    ELSE
        v_expected_delivery_fee := v_standard_delivery_fee;
    END IF;

    IF p_delivery_fee IS NOT NULL AND p_delivery_fee > 0 AND v_effective_subtotal >= v_free_delivery_threshold THEN
        RAISE EXCEPTION 'DELIVERY_FEE_TAMPERED: Order qualifies for free delivery';
    END IF;

    v_calc_total := round(v_effective_subtotal - v_calc_coupon_discount - v_calc_loyalty_discount + COALESCE(p_delivery_fee, v_expected_delivery_fee), 2);
    IF v_calc_total < 0 THEN
        v_calc_total := 0;
    END IF;

    IF p_total_amount IS NOT NULL AND abs(p_total_amount - v_calc_total) > 0.50 THEN
        RAISE EXCEPTION 'TOTAL_TAMPERED: Total mismatch. Server computed %, client sent %', v_calc_total, p_total_amount;
    END IF;

    -- -------------------------------------------------------------------------
    -- STEP 8: Atomic Order Insertion & Concurrency Guard
    -- -------------------------------------------------------------------------
    BEGIN
        INSERT INTO public.orders (
            order_number,
            idempotency_key,
            user_id,
            status,
            delivery_slot,
            payment_method,
            payment_status,
            subtotal,
            delivery_fee,
            coupon_code,
            discount_amount,
            loyalty_points_used,
            loyalty_discount,
            total_amount,
            notes,
            branch_id,
            branch_name,
            customer_name,
            customer_phone
        ) VALUES (
            p_order_number,
            v_effective_idempotency_key,
            v_effective_user_id,
            'pending',
            COALESCE(p_delivery_slot, 'خلال 45 دقيقة'),
            p_payment_method,
            'pending',
            v_effective_subtotal,
            COALESCE(p_delivery_fee, v_expected_delivery_fee),
            p_coupon_code,
            v_calc_coupon_discount,
            COALESCE(p_loyalty_points_used, 0),
            v_calc_loyalty_discount,
            v_calc_total,
            p_notes,
            v_target_branch_id,
            v_branch_name,
            p_customer_name,
            p_customer_phone
        )
        RETURNING id INTO v_order_id;
    EXCEPTION WHEN unique_violation THEN
        SELECT o.id, o.order_number, o.status, o.subtotal, o.delivery_fee, o.discount_amount,
               o.loyalty_points_used, o.loyalty_discount, o.total_amount, o.branch_id, o.branch_name, o.created_at
        INTO v_existing_order
        FROM public.orders o
        WHERE o.order_number = p_order_number
           OR (v_effective_idempotency_key IS NOT NULL AND o.idempotency_key = v_effective_idempotency_key)
        LIMIT 1;

        IF FOUND THEN
            RETURN jsonb_build_object(
                'id', v_existing_order.id,
                'order_number', v_existing_order.order_number,
                'status', v_existing_order.status,
                'subtotal', v_existing_order.subtotal,
                'delivery_fee', v_existing_order.delivery_fee,
                'discount_amount', v_existing_order.discount_amount,
                'loyalty_points_used', v_existing_order.loyalty_points_used,
                'loyalty_discount', v_existing_order.loyalty_discount,
                'total_amount', v_existing_order.total_amount,
                'branch_id', v_existing_order.branch_id,
                'branch_name', v_existing_order.branch_name,
                'created_at', v_existing_order.created_at,
                'is_idempotent_replay', true
            );
        END IF;
        RAISE;
    END;

    -- -------------------------------------------------------------------------
    -- STEP 9: Insert Order Items, Decrement Stock & Record Movements
    -- -------------------------------------------------------------------------
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_product_id := (v_item->>'product_id')::uuid;
        v_qty := (v_item->>'quantity')::numeric;

        SELECT name_ar, name_en, price, stock_quantity INTO v_prod_rec
        FROM public.products WHERE id = v_product_id;

        v_db_price := v_prod_rec.price;
        v_line_total := round(v_db_price * v_qty, 2);
        v_new_stock := GREATEST(0, (v_prod_rec.stock_quantity - v_qty::int));

        -- 1. Insert Order Item
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
            COALESCE(v_prod_rec.name_ar, v_item->>'product_name_ar', 'صنف تسوق'),
            COALESCE(v_prod_rec.name_en, v_item->>'product_name_en', 'Grocery Item'),
            COALESCE(v_item->>'product_image', ''),
            COALESCE(v_item->>'unit', 'piece'),
            v_db_price,
            v_qty,
            v_line_total
        );

        -- 2. Atomically Decrement Products Catalog Stock
        UPDATE public.products
        SET stock_quantity = v_new_stock,
            sales_count = COALESCE(sales_count, 0) + v_qty::int,
            updated_at = timezone('utc'::text, now())
        WHERE id = v_product_id;

        -- 3. Atomically Update Branch Inventory if row exists
        UPDATE public.branch_inventory
        SET quantity_on_hand = quantity_on_hand - v_qty,
            updated_at = timezone('utc'::text, now())
        WHERE branch_id = v_target_branch_id AND product_id = v_product_id;

        -- 4. Record in inventory_movements ledger
        INSERT INTO public.inventory_movements (
            movement_number,
            branch_id,
            product_id,
            movement_type,
            quantity_change,
            quantity_reserved_change,
            resulting_on_hand,
            resulting_reserved,
            reference_type,
            reference_id,
            actor_id,
            actor_name,
            actor_role,
            notes
        ) VALUES (
            'MOV-' || to_char(now(), 'YYYYMMDD') || '-' || substring(gen_random_uuid()::text from 1 for 8),
            v_target_branch_id,
            v_product_id,
            'sale',
            -v_qty,
            0,
            v_new_stock,
            0,
            'order',
            p_order_number,
            v_effective_user_id::text,
            COALESCE(p_customer_name, 'عميل المتجر'),
            'customer',
            'مبيعات طلب رقم: ' || p_order_number
        );

        -- 5. Record in inventory_transactions ledger
        v_inv_trx_num := 'TRX-' || extract(epoch from now())::bigint || '-' || substring(gen_random_uuid()::text from 1 for 6);
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
            balance_after,
            performed_by,
            notes
        ) VALUES (
            v_inv_trx_num,
            v_target_branch_id,
            v_product_id,
            'sales_deduction',
            'order_sale',
            p_order_number,
            -v_qty,
            round(v_db_price * 0.70, 2),
            round(v_qty * v_db_price * 0.70, 2),
            v_new_stock,
            v_effective_user_id::text,
            'مبيعات طلب رقم: ' || p_order_number
        );
    END LOOP;

    -- -------------------------------------------------------------------------
    -- STEP 10: Record Loyalty Transaction if points were redeemed
    -- -------------------------------------------------------------------------
    IF COALESCE(p_loyalty_points_used, 0) > 0 AND v_effective_user_id IS NOT NULL THEN
        INSERT INTO public.loyalty_transactions (
            user_id,
            order_id,
            points,
            transaction_type,
            description_ar,
            description_en
        ) VALUES (
            v_effective_user_id,
            v_order_id,
            -p_loyalty_points_used,
            'redeemed',
            'استبدال نقاط لخصم الطلب رقم ' || p_order_number,
            'Redeemed points for order ' || p_order_number
        );
    END IF;

    -- -------------------------------------------------------------------------
    -- STEP 11: Return Comprehensive Server-Authoritative Result
    -- -------------------------------------------------------------------------
    SELECT jsonb_build_object(
        'id', o.id,
        'order_number', o.order_number,
        'status', o.status,
        'subtotal', o.subtotal,
        'delivery_fee', o.delivery_fee,
        'discount_amount', o.discount_amount,
        'loyalty_points_used', o.loyalty_points_used,
        'loyalty_discount', o.loyalty_discount,
        'total_amount', o.total_amount,
        'branch_id', o.branch_id,
        'branch_name', o.branch_name,
        'created_at', o.created_at,
        'is_idempotent_replay', false
    ) INTO v_result
    FROM public.orders o
    WHERE o.id = v_order_id;

    RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION public.place_order_atomic TO anon, authenticated;

-- 6. Seed Syrian & Regional Delivery Zones (with real GPS centers & Syrian boundaries)
INSERT INTO public.delivery_zones (
    id, zone_name_ar, zone_name_en, city, district, branch_id, dark_store_code,
    center_latitude, center_longitude, radius_km, base_delivery_fee,
    free_delivery_threshold, estimated_minutes, is_surge_pricing_active,
    surge_fee, is_active, opening_time, closing_time, max_hourly_capacity
) VALUES
-- دمشق
('zn-dam-central', 'دمشق المركزية (المزة، أبو رمانة، المالكي)', 'Damascus Central (Mazzeh, Abu Roumaneh)', 'دمشق', 'المزة', 'b-dam-01', 'WH-DAM-HUB', 33.5138000, 36.2765000, 6.00, 5000.00, 150000.00, 20, false, 0.00, true, '08:00:00', '23:59:59', 80),
('zn-dam-midan', 'دمشق الجنوبية (كفرسوسة، الميدان، الزاهرة)', 'Damascus South (Kafarsouseh, Midan)', 'دمشق', 'الميدان', 'b-dam-01', 'WH-DAM-HUB', 33.4880000, 36.2950000, 7.00, 5500.00, 160000.00, 25, false, 0.00, true, '08:00:00', '23:59:59', 60),
('zn-dam-east', 'دمشق الشرقية (القصاع، باب توما، التجارة)', 'Damascus East (Qasaa, Bab Touma)', 'دمشق', 'القصاع', 'b-dam-01', 'WH-DAM-HUB', 33.5180000, 36.3150000, 8.00, 6000.00, 175000.00, 25, false, 0.00, true, '08:00:00', '23:59:59', 50),
('zn-dam-rif', 'ريف دمشق (جرمانا، ضاحية قدسيا، صحنايا)', 'Damascus Countryside (Jaramana, Qudsaya)', 'ريف دمشق', 'جرمانا', 'b-dam-01', 'WH-DAM-HUB', 33.4750000, 36.3400000, 15.00, 8500.00, 250000.00, 35, false, 0.00, true, '08:00:00', '23:00:00', 40),

-- حلب
('zn-alp-central', 'حلب المركزية (الشهباء، الفرقان، المارتيني)', 'Aleppo Central (Shahbaa, Forqan)', 'حلب', 'الشهباء', 'b-brale01', 'WH-ALP-HUB', 36.2021000, 37.1343000, 8.00, 6500.00, 200000.00, 25, false, 0.00, true, '08:00:00', '23:59:59', 50),

-- حمص
('zn-hms-central', 'حمص المركزية (الدبلان، الإنشاءات، المحطة)', 'Homs Central (Dablan, Inshaat)', 'حمص', 'الدبلان', 'b-dam-01', 'WH-HMS-HUB', 34.7324000, 36.7137000, 6.50, 5500.00, 180000.00, 20, false, 0.00, true, '08:00:00', '23:00:00', 40),

-- اللاذقية
('zn-lat-central', 'اللاذقية الساحلية (الكورنيش، الزراعة، الصليبة)', 'Latakia Coastal (Corniche, Ziraa)', 'اللاذقية', 'الكورنيش', 'b-brtest4871', 'WH-LAT-HUB', 35.5317000, 35.7915000, 7.00, 6000.00, 190000.00, 25, false, 0.00, true, '08:00:00', '23:59:59', 50),

-- درعا (مستبعدة افتراضياً وفق المتطلب التشغيلي مع إمكانية التفعيل الاستثنائي)
('zn-dra-station', 'درعا المحطة وشمال المدينة (مستبعدة افتراضياً)', 'Daraa Station & North (Excluded)', 'درعا', 'درعا المحطة', 'b-dam-01', 'FC-DR-CITY', 32.6250000, 36.1050000, 3.50, 5000.00, 150000.00, 15, false, 0.00, false, '09:00:00', '21:00:00', 20),
('zn-dra-balad', 'درعا البلد وحي طريق السد (مستبعدة افتراضياً)', 'Daraa Balad (Excluded)', 'درعا', 'درعا البلد', 'b-dam-01', 'FC-DR-CITY', 32.6050000, 36.1000000, 4.50, 7000.00, 175000.00, 25, false, 0.00, false, '09:00:00', '21:00:00', 20),
('zn-dra-tafas', 'طفس والمزيريب وريف درعا الغربي (مستبعدة افتراضياً)', 'Tafas & West Daraa (Excluded)', 'درعا', 'طفس', 'b-dam-01', 'FC-DR-WEST', 32.7300000, 36.0300000, 12.00, 15000.00, 300000.00, 40, false, 0.00, false, '09:00:00', '20:00:00', 15),
('zn-dra-izraa', 'إزرع والشيخ مسكين والريف الأوسط (مستبعدة افتراضياً)', 'Izraa & Central Daraa (Excluded)', 'درعا', 'إزرع', 'b-dam-01', 'WH-DR-CENTRAL', 32.8700000, 36.2500000, 18.00, 18000.00, 350000.00, 45, false, 0.00, false, '09:00:00', '20:00:00', 10),

-- الرياض وجدة والدمام
('zn-jed-corniche', 'جدة الكورنيش والشاطئ', 'Jeddah Corniche', 'جدة', 'الكورنيش', 'b-jed-01', 'DS-JED-01', 21.5433000, 39.1728000, 12.00, 15.00, 150.00, 30, false, 0.00, true, '08:00:00', '23:59:59', 100),
('zn-ruh-olaya', 'الرياض العليا والسليمانية', 'Riyadh Olaya', 'الرياض', 'العليا', 'b-ruh-01', 'DS-RUH-OLAYA', 24.7136000, 46.6753000, 12.00, 15.00, 150.00, 30, false, 0.00, true, '08:00:00', '23:59:59', 100),
('zn-dmm-shatee', 'الدمام الشاطئ ومول الشرقية', 'Dammam Shatea', 'الدمام', 'الشاطئ', 'b-dmm-01', 'DS-DMM-01', 26.4207000, 50.0888000, 10.00, 15.00, 150.00, 30, false, 0.00, true, '08:00:00', '23:59:59', 80)
ON CONFLICT (id) DO UPDATE SET
    zone_name_ar = EXCLUDED.zone_name_ar,
    zone_name_en = EXCLUDED.zone_name_en,
    city = EXCLUDED.city,
    district = EXCLUDED.district,
    branch_id = EXCLUDED.branch_id,
    dark_store_code = EXCLUDED.dark_store_code,
    center_latitude = EXCLUDED.center_latitude,
    center_longitude = EXCLUDED.center_longitude,
    radius_km = EXCLUDED.radius_km,
    base_delivery_fee = EXCLUDED.base_delivery_fee,
    free_delivery_threshold = EXCLUDED.free_delivery_threshold,
    estimated_minutes = EXCLUDED.estimated_minutes,
    is_active = EXCLUDED.is_active,
    opening_time = EXCLUDED.opening_time,
    closing_time = EXCLUDED.closing_time,
    max_hourly_capacity = EXCLUDED.max_hourly_capacity,
    updated_at = timezone('utc'::text, now());

-- Record migration in _schema_migrations
INSERT INTO public._schema_migrations (filename, applied_at)
VALUES ('20261104_025_delivery_zones_and_fulfillment_engine.sql', timezone('utc'::text, now()))
ON CONFLICT (filename) DO UPDATE SET applied_at = EXCLUDED.applied_at;

COMMIT;
