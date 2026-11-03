-- ==============================================================================
-- الديب مول (Aldeeb Mall) - Atomic Order RPC & Guest Checkout Security Hardening
-- Migration: 20261102_002_atomic_order_rpc_and_guest_rls.sql
-- ==============================================================================

-- 1. Update RLS Policies to Securely Allow Guest Checkout & Order Item Creation
DROP POLICY IF EXISTS "Users can create their own orders" ON public.orders;
DROP POLICY IF EXISTS "Users and guests can create orders" ON public.orders;

CREATE POLICY "Users and guests can create orders"
    ON public.orders FOR INSERT
    WITH CHECK (
        -- Authenticated user must set their own user_id
        ((SELECT auth.uid()) IS NOT NULL AND (SELECT auth.uid()) = user_id)
        -- Or guest order where user_id IS NULL and not a cashier/POS sale
        OR (user_id IS NULL AND (delivery_slot IS NULL OR NOT (delivery_slot ILIKE '%كاشير%' OR delivery_slot ILIKE '%pos%')))
        -- Or staff / admin
        OR public.is_admin()
    );

DROP POLICY IF EXISTS "Users can view their own orders" ON public.orders;
DROP POLICY IF EXISTS "Users and guests can view orders" ON public.orders;

CREATE POLICY "Users and guests can view orders"
    ON public.orders FOR SELECT
    USING (
        -- Authenticated user can see their own orders
        ((SELECT auth.uid()) IS NOT NULL AND (SELECT auth.uid()) = user_id)
        -- Staff / admin can see all orders
        OR public.is_admin()
    );

DROP POLICY IF EXISTS "Users can insert items for their own orders" ON public.order_items;
DROP POLICY IF EXISTS "Anyone can insert order items" ON public.order_items;
DROP POLICY IF EXISTS "Users and guests can create order items" ON public.order_items;

CREATE POLICY "Users and guests can create order items"
    ON public.order_items FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.orders o
            WHERE o.id = order_items.order_id
            AND (
                o.user_id = (SELECT auth.uid())
                OR o.user_id IS NULL
                OR public.is_admin()
            )
        )
        OR public.is_admin()
    );

DROP POLICY IF EXISTS "Users can view items in their orders" ON public.order_items;
DROP POLICY IF EXISTS "Users and guests can view order items" ON public.order_items;

CREATE POLICY "Users and guests can view order items"
    ON public.order_items FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.orders o
            WHERE o.id = order_items.order_id
            AND (
                o.user_id = (SELECT auth.uid())
                OR public.is_admin()
            )
        )
        OR public.is_admin()
    );

-- 2. Atomic Order Placement RPC Function (ACID Transaction, Stock Verification, Idempotency, Identity Hardening & Price Protection)
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

-- Grant execution to anon and authenticated roles
GRANT EXECUTE ON FUNCTION public.place_order_atomic TO anon, authenticated;
