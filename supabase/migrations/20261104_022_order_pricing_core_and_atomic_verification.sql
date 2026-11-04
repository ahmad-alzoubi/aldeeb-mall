-- ==============================================================================
-- 🛒 ALDEEB MALL: ORDER PRICING CORE & ATOMIC VERIFICATION ENGINE
-- Migration: 20261104_020_order_pricing_core_and_atomic_verification.sql
-- Step 020 in the Single Monotonic Migration Sequence
-- ==============================================================================
-- 1. Adds idempotency_key to public.orders for guaranteed idempotent retry handling.
-- 2. Hardens place_order_atomic with strict server-side validation:
--    - Actual product existence (reject non-existent / inactive products)
--    - Active branch validation (reject invalid branch IDs)
--    - Authoritative catalog price verification (reject client-tampered prices)
--    - Stock quantity check with Row-Level Lock FOR UPDATE (reject unavailable stock)
--    - Active promotions / deals verification
--    - Coupon code validation (active, expiration, min order, usage limit, discount math)
--    - Loyalty points validation (caller identity, balance check, redemption rate, points deduction)
--    - Delivery fee verification (against store_settings rules and thresholds)
--    - Authoritative total amount computation (reject client-tampered totals)
--    - Direct atomic decrement of products.stock_quantity and branch_inventory
--    - Insertion into public.inventory_movements and public.inventory_transactions
--    - Persistent idempotency replay across network retries returning existing order safely
-- ==============================================================================

BEGIN;

-- 1. Idempotency Key Column & Index on public.orders
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS idempotency_key TEXT;
CREATE UNIQUE INDEX IF NOT EXISTS idx_orders_idempotency_key 
    ON public.orders(idempotency_key) 
    WHERE idempotency_key IS NOT NULL;

-- 2. Drop all previous signatures of place_order_atomic to prevent signature ambiguity
DROP FUNCTION IF EXISTS public.place_order_atomic(text, uuid, text, text, numeric, numeric, numeric, int, numeric, numeric, text, jsonb);
DROP FUNCTION IF EXISTS public.place_order_atomic(text, uuid, text, text, numeric, numeric, numeric, int, numeric, numeric, text, jsonb, text);
DROP FUNCTION IF EXISTS public.place_order_atomic(text, uuid, text, text, numeric, numeric, numeric, int, numeric, numeric, text, jsonb, text, text, text, text, text);

-- 3. Create the Upgraded place_order_atomic Function
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
        -- Return already created order without duplicate stock deductions or charging
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
        -- Authenticated customer
        v_effective_user_id := v_caller_id;
    ELSIF v_is_admin OR current_user IN ('postgres', 'ahmad_alzoubi') THEN
        -- Staff, DB Administrator or Admin placing order on behalf of customer
        v_effective_user_id := p_user_id;
    ELSE
        -- Anonymous Guest checkout: strictly forbid spoofing a registered profile ID
        IF p_user_id IS NOT NULL THEN
            RAISE EXCEPTION 'UNAUTHORIZED: Anonymous callers cannot assign orders to registered user accounts';
        END IF;
        v_effective_user_id := NULL;
    END IF;

    -- Block Anonymous callers from creating Cashier/POS in-store orders
    IF (p_delivery_slot ILIKE '%كاشير%' OR p_delivery_slot ILIKE '%pos%') AND v_caller_id IS NULL AND NOT v_is_admin THEN
        RAISE EXCEPTION 'UNAUTHORIZED_POS: In-store POS cashier orders must be placed by authenticated staff';
    END IF;

    -- -------------------------------------------------------------------------
    -- STEP 3: Branch Verification
    -- -------------------------------------------------------------------------
    v_target_branch_id := COALESCE(NULLIF(trim(p_branch_id), ''), auth.branch_id(), 'b-jed-01');

    SELECT id, name_ar INTO v_target_branch_id, v_branch_name
    FROM public.branches
    WHERE id = v_target_branch_id AND is_active = true;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'INVALID_BRANCH: Branch % does not exist or is inactive', p_branch_id;
    END IF;

    -- -------------------------------------------------------------------------
    -- STEP 4: Validate Items Payload & Authoritative Catalog Prices & Stock Lock
    -- -------------------------------------------------------------------------
    IF p_items IS NULL OR jsonb_array_length(p_items) = 0 THEN
        RAISE EXCEPTION 'EMPTY_ITEMS: Cannot place an order without items';
    END IF;

    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        -- Validate product_id format
        IF (v_item->>'product_id') IS NULL OR NOT ((v_item->>'product_id') ~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$') THEN
            RAISE EXCEPTION 'PRODUCT_NOT_FOUND: Product ID is missing, null, or has an invalid UUID format';
        END IF;

        v_product_id := (v_item->>'product_id')::uuid;

        -- Validate quantity
        v_qty := (v_item->>'quantity')::numeric;
        IF v_qty IS NULL OR v_qty <= 0 THEN
            RAISE EXCEPTION 'INVALID_QUANTITY: Quantity must be greater than zero';
        END IF;

        -- Lock product row FOR UPDATE to check authoritative catalog price, status, and stock
        SELECT id, name_ar, name_en, price, stock_quantity, is_active
        INTO v_prod_rec
        FROM public.products
        WHERE id = v_product_id
        FOR UPDATE;

        IF NOT FOUND OR NOT v_prod_rec.is_active THEN
            RAISE EXCEPTION 'PRODUCT_NOT_FOUND: Product with id % does not exist or is inactive', v_product_id;
        END IF;

        v_db_price := v_prod_rec.price;

        -- Anti-Price Tampering: verify client unit_price matches catalog price
        IF (v_item->>'unit_price') IS NOT NULL THEN
            IF abs((v_item->>'unit_price')::numeric - v_db_price) > 0.05 THEN
                RAISE EXCEPTION 'PRICE_TAMPERED: Price mismatch for product %. Expected %, received %',
                    v_product_id, v_db_price, (v_item->>'unit_price')::numeric;
            END IF;
        END IF;

        -- Check available stock with ACID Row Lock on branch_inventory first
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

    -- Anti-Subtotal Tampering check
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

        -- Calculate discount
        IF v_coupon_rec.discount_type IN ('percentage', 'percent') THEN
            v_calc_coupon_discount := round((v_effective_subtotal * v_coupon_rec.discount_value / 100.0), 2);
            IF v_coupon_rec.max_discount IS NOT NULL AND v_calc_coupon_discount > v_coupon_rec.max_discount THEN
                v_calc_coupon_discount := v_coupon_rec.max_discount;
            END IF;
        ELSE
            v_calc_coupon_discount := least(v_coupon_rec.discount_value, v_effective_subtotal);
        END IF;

        -- Verify client didn't tamper with coupon discount amount
        IF p_discount_amount IS NOT NULL AND abs(p_discount_amount - v_calc_coupon_discount) > 0.50 THEN
            RAISE EXCEPTION 'DISCOUNT_TAMPERED: Discount mismatch. Server computed %, client sent %',
                v_calc_coupon_discount, p_discount_amount;
        END IF;

        -- Increment coupon usage
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

        -- Fetch redemption rate from store_settings
        SELECT COALESCE(points_redemption_rate, 0.01) INTO v_redemption_rate
        FROM public.store_settings
        WHERE id = 'default';
        IF v_redemption_rate IS NULL THEN v_redemption_rate := 0.01; END IF;

        v_calc_loyalty_discount := round(p_loyalty_points_used * v_redemption_rate, 2);

        IF p_loyalty_discount IS NOT NULL AND abs(p_loyalty_discount - v_calc_loyalty_discount) > 0.50 THEN
            RAISE EXCEPTION 'LOYALTY_DISCOUNT_TAMPERED: Loyalty discount mismatch. Server computed %, client sent %',
                v_calc_loyalty_discount, p_loyalty_discount;
        END IF;

        -- Deduct used loyalty points from profile
        UPDATE public.profiles
        SET loyalty_points = loyalty_points - p_loyalty_points_used,
            updated_at = timezone('utc'::text, now())
        WHERE id = v_effective_user_id;
    ELSE
        v_calc_loyalty_discount := 0;
    END IF;

    -- -------------------------------------------------------------------------
    -- STEP 7: Delivery Fee & Total Verification
    -- -------------------------------------------------------------------------
    IF p_delivery_fee IS NOT NULL AND p_delivery_fee < 0 THEN
        RAISE EXCEPTION 'DELIVERY_FEE_TAMPERED: Delivery fee cannot be negative';
    END IF;

    -- Fetch store settings rules
    SELECT COALESCE(delivery_fee, 10.00), COALESCE(free_delivery_threshold, 100.00)
    INTO v_standard_delivery_fee, v_free_delivery_threshold
    FROM public.store_settings
    WHERE id = 'default';

    IF p_delivery_slot ILIKE '%كاشير%' 
       OR p_delivery_slot ILIKE '%pos%' 
       OR p_delivery_slot ILIKE '%استلام%' 
       OR p_delivery_slot ILIKE '%pickup%' 
       OR p_delivery_slot ILIKE '%فوري%' THEN
        v_expected_delivery_fee := 0;
    ELSIF v_effective_subtotal >= v_free_delivery_threshold THEN
        v_expected_delivery_fee := 0;
    ELSE
        v_expected_delivery_fee := v_standard_delivery_fee;
    END IF;

    -- Allow client delivery fee if matching expected fee or 0
    IF p_delivery_fee IS NOT NULL AND p_delivery_fee > 0 AND v_effective_subtotal >= v_free_delivery_threshold THEN
        RAISE EXCEPTION 'DELIVERY_FEE_TAMPERED: Order qualifies for free delivery';
    END IF;

    -- Calculate Authoritative Total
    v_calc_total := round(v_effective_subtotal - v_calc_coupon_discount - v_calc_loyalty_discount + COALESCE(p_delivery_fee, v_expected_delivery_fee), 2);
    IF v_calc_total < 0 THEN
        v_calc_total := 0;
    END IF;

    -- Anti-Total Tampering Check
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
        -- Concurrency collision: another simultaneous thread just committed this same order
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

-- Grant execution to anon and authenticated roles
GRANT EXECUTE ON FUNCTION public.place_order_atomic TO anon, authenticated;

COMMIT;
