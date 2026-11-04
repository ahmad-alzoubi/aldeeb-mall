-- ============================================================================
-- Migration: 20261104_026_fix_pos_and_order_atomic_governance.sql
-- Fixes:
-- 1. `open_cashier_shift`: Prevent null actor_id in audit_logs when p_cashier_id is null.
-- 2. `process_pos_sale_atomic`: Defensive validation for cashier_id against staff_members FK.
-- 3. `place_order_atomic`: Safe caller_id/user_id validation against profiles FK to prevent 23503.
-- ============================================================================

-- 1. Fix `open_cashier_shift`
CREATE OR REPLACE FUNCTION public.open_cashier_shift(
    p_branch_id text,
    p_branch_name text,
    p_terminal_code text,
    p_device_fingerprint text,
    p_cashier_id text,
    p_cashier_name text,
    p_opening_balance numeric,
    p_notes text DEFAULT ''::text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
    v_existing_shift RECORD;
    v_new_shift_id UUID := gen_random_uuid();
    v_shift_number TEXT;
    v_today TEXT := to_char(now() AT TIME ZONE 'UTC', 'YYYYMMDD');
    v_clean_term TEXT := UPPER(REGEXP_REPLACE(COALESCE(p_terminal_code, 'POS-01'), '[^a-zA-Z0-9]', '', 'g'));
    v_clean_branch TEXT := UPPER(REGEXP_REPLACE(COALESCE(p_branch_id, 'BR'), '[^a-zA-Z0-9]', '', 'g'));
    v_effective_cashier_id TEXT;
    v_effective_cashier_name TEXT;
    v_seq BIGINT;
    v_result RECORD;
BEGIN
    -- Defensive validation
    IF p_opening_balance < 0 THEN
        RAISE EXCEPTION 'الرصيد الافتتاحي لا يمكن أن يكون سالباً';
    END IF;

    -- Resolve cashier identifier safely
    v_effective_cashier_id := COALESCE(NULLIF(trim(p_cashier_id), ''), 'staff-cashier-01');
    v_effective_cashier_name := COALESCE(NULLIF(trim(p_cashier_name), ''), 'عمر الدوسري');

    -- Verify cashier exists in staff_members if possible, fallback to staff-cashier-01
    IF NOT EXISTS (SELECT 1 FROM public.staff_members WHERE id = v_effective_cashier_id) THEN
        v_effective_cashier_id := 'staff-cashier-01';
    END IF;

    -- Check if this cashier or terminal already has an open shift in this branch
    SELECT * INTO v_existing_shift
    FROM public.cashier_shifts
    WHERE branch_id = p_branch_id
      AND (cashier_id = v_effective_cashier_id OR terminal_code = p_terminal_code)
      AND status = 'open'
    ORDER BY opened_at DESC
    LIMIT 1;

    IF FOUND THEN
        -- If already open, return active shift cleanly
        RETURN to_jsonb(v_existing_shift);
    END IF;

    -- Monotonic, collision-free global shift sequence
    v_seq := nextval('public.pos_shift_number_seq');
    v_shift_number := 'SHF-' || v_today || '-' || v_clean_branch || '-' || v_clean_term || '-' || LPAD(v_seq::text, 4, '0');

    -- Insert shift into public.cashier_shifts
    INSERT INTO public.cashier_shifts (
        id,
        shift_number,
        branch_id,
        branch_name,
        terminal_code,
        device_fingerprint,
        cashier_id,
        cashier_name,
        opened_at,
        status,
        opening_balance,
        cash_sales,
        card_sales,
        other_sales,
        total_sales,
        cash_receipts,
        cash_refunds,
        card_refunds,
        cash_drops,
        expected_cash,
        transactions_count,
        notes
    ) VALUES (
        v_new_shift_id,
        v_shift_number,
        p_branch_id,
        p_branch_name,
        COALESCE(p_terminal_code, 'POS-01'),
        p_device_fingerprint,
        v_effective_cashier_id,
        v_effective_cashier_name,
        timezone('utc'::text, now()),
        'open',
        p_opening_balance,
        0.00,
        0.00,
        0.00,
        0.00,
        0.00,
        0.00,
        0.00,
        0.00,
        p_opening_balance,
        0,
        p_notes
    ) RETURNING * INTO v_result;

    -- Record opening movement in cashier_shift_movements
    INSERT INTO public.cashier_shift_movements (
        shift_id,
        movement_type,
        amount,
        payment_method,
        reference_id,
        performed_by,
        performed_by_id,
        notes
    ) VALUES (
        v_new_shift_id,
        'opening',
        p_opening_balance,
        'cash',
        v_shift_number,
        v_effective_cashier_name,
        v_effective_cashier_id,
        'رصيد افتتاحي لبدء الوردية'
    );

    -- Record in audit logs
    INSERT INTO public.audit_logs (
        actor_id, actor_name, actor_role, action, category, target_id, target_type, branch_id, details, metadata
    ) VALUES (
        v_effective_cashier_id, v_effective_cashier_name, 'cashier', 'OPEN_CASHIER_SHIFT', 'pos', v_new_shift_id::text, 'cashier_shifts', p_branch_id,
        'فتح وردية كاشير جديدة رقم ' || v_shift_number,
        jsonb_build_object('shift_number', v_shift_number, 'opening_balance', p_opening_balance, 'terminal_code', p_terminal_code)
    );

    RETURN to_jsonb(v_result);
END;
$$;

-- 2. Fix `process_pos_sale_atomic`
CREATE OR REPLACE FUNCTION public.process_pos_sale_atomic(
    p_receipt_number text,
    p_idempotency_key text,
    p_branch_id text,
    p_terminal_code text,
    p_staff_id text,
    p_shift_id uuid,
    p_customer_name text,
    p_customer_phone text,
    p_payment_method text,
    p_cash_received numeric,
    p_card_amount numeric,
    p_card_auth_code text,
    p_subtotal numeric,
    p_tax_amount numeric,
    p_discount_amount numeric,
    p_loyalty_points_used integer,
    p_loyalty_discount numeric,
    p_total_amount numeric,
    p_items jsonb,
    p_notes text DEFAULT ''::text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
    v_existing_order RECORD;
    v_shift RECORD;
    v_customer_id UUID := NULL;
    v_new_order_id UUID;
    v_item JSONB;
    v_product_id UUID;
    v_qty NUMERIC;
    v_price NUMERIC;
    v_product RECORD;
    v_branch_inv RECORD;
    v_points_earned INTEGER := 0;
    v_effective_idempotency_key TEXT;
    v_cash_applied NUMERIC := 0;
    v_card_applied NUMERIC := 0;
    v_effective_cashier_id TEXT;
BEGIN
    -- -------------------------------------------------------------------------
    -- STEP 1: Idempotency Protection — Return existing order without re-executing
    -- -------------------------------------------------------------------------
    v_effective_idempotency_key := COALESCE(NULLIF(trim(p_idempotency_key), ''), p_receipt_number);

    SELECT o.id, o.order_number, o.status, o.total_amount, o.subtotal, o.created_at, o.payment_method
    INTO v_existing_order
    FROM public.orders o
    WHERE o.order_number = p_receipt_number
       OR (v_effective_idempotency_key IS NOT NULL AND o.idempotency_key = v_effective_idempotency_key)
    LIMIT 1;

    IF FOUND THEN
        RETURN jsonb_build_object(
            'success', true,
            'is_idempotent_replay', true,
            'order_id', v_existing_order.id,
            'receipt_number', v_existing_order.order_number,
            'status', v_existing_order.status,
            'total_amount', v_existing_order.total_amount,
            'created_at', v_existing_order.created_at
        );
    END IF;

    -- -------------------------------------------------------------------------
    -- STEP 2: Shift Verification & Concurrency Lock
    -- -------------------------------------------------------------------------
    SELECT * INTO v_shift
    FROM public.cashier_shifts
    WHERE id = p_shift_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'POS_SHIFT_NOT_FOUND: الوردية غير مسجلة في النظام';
    END IF;

    IF v_shift.status != 'open' THEN
        RAISE EXCEPTION 'POS_SHIFT_CLOSED: لا يمكن إتمام البيع، الوردية رقم (%) مغلقة', v_shift.shift_number;
    END IF;

    -- Resolve cashier ID safely against staff_members FK
    IF v_shift.cashier_id IS NOT NULL AND EXISTS (SELECT 1 FROM public.staff_members WHERE id = v_shift.cashier_id) THEN
        v_effective_cashier_id := v_shift.cashier_id;
    ELSIF p_staff_id IS NOT NULL AND EXISTS (SELECT 1 FROM public.staff_members WHERE id = p_staff_id) THEN
        v_effective_cashier_id := p_staff_id;
    ELSE
        v_effective_cashier_id := 'staff-cashier-01';
    END IF;

    -- -------------------------------------------------------------------------
    -- STEP 3: Payment Math & Proof of Collection
    -- -------------------------------------------------------------------------
    IF p_total_amount < 0 THEN
        RAISE EXCEPTION 'INVALID_TOTAL: إجمالي الفاتورة غير صالح';
    END IF;

    IF p_payment_method = 'cash' THEN
        IF COALESCE(p_cash_received, 0) < p_total_amount THEN
            RAISE EXCEPTION 'INSUFFICIENT_CASH: المبلغ النقدي المستلم (% ل.س) أقل من إجمالي الفاتورة المطلوب (% ل.س)',
                COALESCE(p_cash_received, 0), p_total_amount;
        END IF;
        v_cash_applied := p_total_amount;
        v_card_applied := 0;

    ELSIF p_payment_method = 'card' THEN
        IF COALESCE(p_card_amount, 0) < p_total_amount THEN
            RAISE EXCEPTION 'INSUFFICIENT_CARD_AMOUNT: المبلغ المحصّل بالبطاقة (% ل.س) أقل من إجمالي الفاتورة (% ل.س)',
                COALESCE(p_card_amount, 0), p_total_amount;
        END IF;
        v_cash_applied := 0;
        v_card_applied := p_total_amount;

    ELSIF p_payment_method = 'split' THEN
        IF (COALESCE(p_cash_received, 0) + COALESCE(p_card_amount, 0)) < p_total_amount THEN
            RAISE EXCEPTION 'INSUFFICIENT_SPLIT_PAYMENT: إجمالي المدفوع نقداً وبطاقة (% ل.س) أقل من قيمة الفاتورة (% ل.س)',
                (COALESCE(p_cash_received, 0) + COALESCE(p_card_amount, 0)), p_total_amount;
        END IF;
        v_card_applied := LEAST(p_total_amount, COALESCE(p_card_amount, 0));
        v_cash_applied := p_total_amount - v_card_applied;

    ELSE
        RAISE EXCEPTION 'INVALID_PAYMENT_METHOD: طريقة الدفع غير مدعومة (%)', p_payment_method;
    END IF;

    -- -------------------------------------------------------------------------
    -- STEP 4: Cart Items Validation & Stock Locking
    -- -------------------------------------------------------------------------
    IF p_items IS NULL OR jsonb_array_length(p_items) = 0 THEN
        RAISE EXCEPTION 'EMPTY_CART: لا توجد أصناف في سلة المبيعات';
    END IF;

    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_product_id := (v_item->>'product_id')::uuid;
        v_qty := (v_item->>'quantity')::numeric;
        v_price := (v_item->>'price')::numeric;

        IF v_qty <= 0 THEN
            RAISE EXCEPTION 'INVALID_QUANTITY: كمية الصنف يجب أن تكون أكبر من الصفر';
        END IF;

        -- Lock product row
        SELECT id, name_ar, name_en, price, stock_quantity, is_active, unit
        INTO v_product
        FROM public.products
        WHERE id = v_product_id
        FOR UPDATE;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'PRODUCT_NOT_FOUND: الصنف المعرف بـ (%) غير موجود في النظام', v_product_id;
        END IF;

        IF NOT v_product.is_active THEN
            RAISE EXCEPTION 'PRODUCT_INACTIVE: الصنف "%" غير مفعل للبيع حالياً', v_product.name_ar;
        END IF;

        -- Lock and check branch inventory
        SELECT id, quantity_on_hand, quantity_reserved
        INTO v_branch_inv
        FROM public.branch_inventory
        WHERE branch_id = p_branch_id AND product_id = v_product_id
        FOR UPDATE;

        IF NOT FOUND THEN
            IF v_product.stock_quantity < v_qty THEN
                RAISE EXCEPTION 'INSUFFICIENT_STOCK: نفد رصيد الصنف "%" في الفرع. المتاح: %، المطلوب: %',
                    v_product.name_ar, v_product.stock_quantity, v_qty;
            END IF;

            INSERT INTO public.branch_inventory (
                branch_id, product_id, quantity_on_hand, quantity_reserved, bin_location
            ) VALUES (
                p_branch_id, v_product_id, GREATEST(0, v_product.stock_quantity - v_qty), 0, 'رف-POS-01'
            );
        ELSE
            IF v_branch_inv.quantity_on_hand < v_qty THEN
                RAISE EXCEPTION 'INSUFFICIENT_STOCK: نفد رصيد الصنف "%" في الفرع. المتاح بالمستودع: %، المطلوب: %',
                    v_product.name_ar, v_branch_inv.quantity_on_hand, v_qty;
            END IF;

            UPDATE public.branch_inventory
            SET quantity_on_hand = quantity_on_hand - v_qty,
                updated_at = timezone('utc'::text, now())
            WHERE id = v_branch_inv.id;
        END IF;

        -- Deduct from catalog stock
        UPDATE public.products
        SET stock_quantity = GREATEST(0, stock_quantity - v_qty::integer),
            sales_count = sales_count + v_qty::integer
        WHERE id = v_product_id;

        -- Record movement in inventory_movements
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
            p_branch_id,
            v_product_id,
            'sale',
            -v_qty,
            0,
            GREATEST(0, v_product.stock_quantity - v_qty::integer),
            0,
            'order',
            p_receipt_number,
            v_effective_cashier_id,
            v_shift.cashier_name,
            'cashier',
            'مبيعات كاشير POS • فاتورة ' || p_receipt_number
        );
    END LOOP;

    -- -------------------------------------------------------------------------
    -- STEP 5: Customer Loyalty Profile Lookup
    -- -------------------------------------------------------------------------
    IF p_customer_phone IS NOT NULL AND trim(p_customer_phone) != '' AND trim(p_customer_phone) != '+966 50 000 0000' THEN
        SELECT id INTO v_customer_id
        FROM public.profiles
        WHERE phone = trim(p_customer_phone)
        LIMIT 1;

        IF FOUND AND v_customer_id IS NOT NULL THEN
            v_points_earned := FLOOR(p_total_amount * 0.1)::integer;
            IF v_points_earned > 0 THEN
                UPDATE public.profiles
                SET loyalty_points = loyalty_points + v_points_earned,
                    updated_at = timezone('utc'::text, now())
                WHERE id = v_customer_id;
            END IF;
        END IF;
    END IF;

    -- -------------------------------------------------------------------------
    -- STEP 6: Insert into public.orders & public.order_items
    -- -------------------------------------------------------------------------
    INSERT INTO public.orders (
        order_number,
        user_id,
        customer_name,
        customer_phone,
        branch_id,
        branch_name,
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
        notes,
        idempotency_key,
        shift_id,
        cashier_id,
        delivered_at
    ) VALUES (
        p_receipt_number,
        v_customer_id,
        COALESCE(NULLIF(trim(p_customer_name), ''), 'عميل نقدي مباشر'),
        COALESCE(NULLIF(trim(p_customer_phone), ''), '+966 50 000 0000'),
        p_branch_id,
        v_shift.branch_name,
        'delivered',
        'كاشير مباشر - ' || v_shift.branch_name,
        p_payment_method,
        'paid',
        p_subtotal,
        0,
        COALESCE(p_discount_amount, 0),
        COALESCE(p_loyalty_points_used, 0),
        COALESCE(p_loyalty_discount, 0),
        p_total_amount,
        'نقطة بيع POS • الكاشير: ' || v_shift.cashier_name || ' • وردية: ' || v_shift.shift_number || 
            CASE WHEN p_card_auth_code IS NOT NULL AND p_card_auth_code != '' THEN ' • مرجع الشبكة: ' || p_card_auth_code ELSE '' END ||
            ' • ' || COALESCE(p_notes, ''),
        v_effective_idempotency_key,
        v_shift.id,
        v_effective_cashier_id,
        timezone('utc'::text, now())
    ) RETURNING id INTO v_new_order_id;

    -- Insert order items
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        INSERT INTO public.order_items (
            order_id,
            product_id,
            product_name_ar,
            product_name_en,
            unit,
            unit_price,
            quantity,
            total_price
        ) VALUES (
            v_new_order_id,
            (v_item->>'product_id')::uuid,
            v_item->>'name_ar',
            COALESCE(v_item->>'name_en', v_item->>'name_ar'),
            COALESCE(v_item->>'unit', 'piece'),
            (v_item->>'price')::numeric,
            (v_item->>'quantity')::numeric,
            COALESCE((v_item->>'total')::numeric, (v_item->>'price')::numeric * (v_item->>'quantity')::numeric)
        );
    END LOOP;

    -- -------------------------------------------------------------------------
    -- STEP 7: Aggregate Shift Metrics in public.cashier_shifts
    -- -------------------------------------------------------------------------
    UPDATE public.cashier_shifts
    SET cash_sales = cash_sales + v_cash_applied,
        card_sales = card_sales + v_card_applied,
        total_sales = total_sales + p_total_amount,
        expected_cash = (opening_balance + cash_sales + v_cash_applied + cash_receipts) - (cash_refunds + cash_drops),
        transactions_count = transactions_count + 1,
        updated_at = timezone('utc'::text, now())
    WHERE id = p_shift_id;

    -- Record shift movement
    INSERT INTO public.cashier_shift_movements (
        shift_id,
        movement_type,
        amount,
        payment_method,
        reference_id,
        performed_by,
        performed_by_id,
        notes
    ) VALUES (
        p_shift_id,
        CASE WHEN p_payment_method = 'cash' THEN 'sale_cash'
             WHEN p_payment_method = 'card' THEN 'sale_card'
             ELSE 'sale_split' END,
        p_total_amount,
        p_payment_method,
        p_receipt_number,
        v_shift.cashier_name,
        v_effective_cashier_id,
        'عملية بيع كاشير POS • فاتورة ' || p_receipt_number
    );

    -- -------------------------------------------------------------------------
    -- STEP 8: Construct and Return Authoritative Result
    -- -------------------------------------------------------------------------
    RETURN jsonb_build_object(
        'success', true,
        'is_idempotent_replay', false,
        'order_id', v_new_order_id,
        'receipt_number', p_receipt_number,
        'shift_id', v_shift.id,
        'shift_number', v_shift.shift_number,
        'total_amount', p_total_amount,
        'cash_received', p_cash_received,
        'change_given', CASE WHEN p_payment_method = 'cash' THEN GREATEST(0, COALESCE(p_cash_received, 0) - p_total_amount) ELSE 0 END,
        'card_auth_code', p_card_auth_code,
        'points_earned', v_points_earned,
        'points_redeemed', COALESCE(p_loyalty_points_used, 0),
        'created_at', timezone('utc'::text, now())
    );
END;
$$;

-- 3. Fix `place_order_atomic`
CREATE OR REPLACE FUNCTION public.place_order_atomic(
    p_order_number text,
    p_user_id uuid,
    p_delivery_slot text,
    p_payment_method text,
    p_subtotal numeric,
    p_delivery_fee numeric,
    p_discount_amount numeric,
    p_loyalty_points_used integer,
    p_loyalty_discount numeric,
    p_total_amount numeric,
    p_notes text,
    p_items jsonb,
    p_branch_id text DEFAULT 'b-jed-01'::text,
    p_coupon_code text DEFAULT NULL::text,
    p_idempotency_key text DEFAULT NULL::text,
    p_customer_name text DEFAULT NULL::text,
    p_customer_phone text DEFAULT NULL::text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
    v_caller_id uuid;
    v_effective_user_id uuid := NULL;
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
    -- STEP 2: Caller Identity & Defensive Profiles FK Verification
    -- -------------------------------------------------------------------------
    v_caller_id := auth.uid();

    -- Defensively ensure user_id references an existing profile to prevent FK violation (23503)
    IF v_caller_id IS NOT NULL AND EXISTS (SELECT 1 FROM public.profiles WHERE id = v_caller_id) THEN
        v_effective_user_id := v_caller_id;
    ELSIF p_user_id IS NOT NULL AND EXISTS (SELECT 1 FROM public.profiles WHERE id = p_user_id) THEN
        v_effective_user_id := p_user_id;
    ELSE
        v_effective_user_id := NULL;
    END IF;

    -- -------------------------------------------------------------------------
    -- STEP 3: Branch Verification
    -- -------------------------------------------------------------------------
    v_target_branch_id := COALESCE(NULLIF(trim(p_branch_id), ''), 'b-dam-01');

    SELECT id, name_ar INTO v_target_branch_id, v_branch_name
    FROM public.branches
    WHERE id = v_target_branch_id AND is_active = true;

    IF NOT FOUND THEN
        -- Fallback to first active branch
        SELECT id, name_ar INTO v_target_branch_id, v_branch_name
        FROM public.branches
        WHERE is_active = true
        LIMIT 1;
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
            v_new_stock := GREATEST(0, (v_prod_rec.stock_quantity - v_qty)::int);
        ELSE
            IF v_prod_rec.stock_quantity < v_qty THEN
                RAISE EXCEPTION 'INSUFFICIENT_STOCK: Only % units available for product %',
                    v_prod_rec.stock_quantity, v_product_id;
            END IF;
            v_new_stock := (v_prod_rec.stock_quantity - v_qty)::int;
        END IF;

        v_line_total := round(v_db_price * v_qty, 2);
        v_calc_subtotal := v_calc_subtotal + v_line_total;
    END LOOP;

    v_effective_subtotal := v_calc_subtotal;
    IF p_subtotal IS NOT NULL AND abs(p_subtotal - v_effective_subtotal) > 0.50 THEN
        RAISE EXCEPTION 'SUBTOTAL_TAMPERED: Subtotal mismatch. Server computed %, client sent %',
            v_effective_subtotal, p_subtotal;
    END IF;

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
            RAISE EXCEPTION 'DISCOUNT_TAMPERED: Discount amount mismatch. Server computed %, client sent %',
                v_calc_coupon_discount, p_discount_amount;
        END IF;

        UPDATE public.coupons
        SET times_used = times_used + 1,
            updated_at = timezone('utc'::text, now())
        WHERE id = v_coupon_rec.id;
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

    IF p_total_amount IS NOT NULL AND abs(p_total_amount - v_calc_total) > 1.00 THEN
        RAISE EXCEPTION 'TOTAL_TAMPERED: Total mismatch. Server computed %, client sent %',
            v_calc_total, p_total_amount;
    END IF;

    -- -------------------------------------------------------------------------
    -- STEP 8: Create Order Record in public.orders
    -- -------------------------------------------------------------------------
    INSERT INTO public.orders (
        order_number,
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
        customer_name,
        customer_phone,
        branch_id,
        branch_name,
        idempotency_key,
        created_at,
        updated_at
    ) VALUES (
        p_order_number,
        v_effective_user_id,
        'pending',
        p_delivery_slot,
        p_payment_method,
        CASE WHEN p_payment_method IN ('card', 'apple_pay') THEN 'paid' ELSE 'pending' END,
        v_effective_subtotal,
        COALESCE(p_delivery_fee, v_expected_delivery_fee),
        p_coupon_code,
        v_calc_coupon_discount,
        COALESCE(p_loyalty_points_used, 0),
        v_calc_loyalty_discount,
        v_calc_total,
        p_notes,
        COALESCE(NULLIF(trim(p_customer_name), ''), 'عميل المتجر الإلكتروني'),
        COALESCE(NULLIF(trim(p_customer_phone), ''), '+966 50 000 0000'),
        v_target_branch_id,
        v_branch_name,
        v_effective_idempotency_key,
        timezone('utc'::text, now()),
        timezone('utc'::text, now())
    ) RETURNING id INTO v_order_id;

    -- -------------------------------------------------------------------------
    -- STEP 9: Insert Order Items & Deduct Catalog & Branch Stock
    -- -------------------------------------------------------------------------
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_product_id := (v_item->>'product_id')::uuid;
        v_qty := (v_item->>'quantity')::numeric;

        SELECT id, name_ar, name_en, price, stock_quantity
        INTO v_prod_rec
        FROM public.products
        WHERE id = v_product_id;

        v_db_price := v_prod_rec.price;
        v_line_total := round(v_db_price * v_qty, 2);
        v_new_stock := GREATEST(0, (v_prod_rec.stock_quantity - v_qty)::int);

        -- 1. Insert Line Item
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
            COALESCE(v_effective_user_id::text, v_caller_id::text, 'guest-customer'),
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
            COALESCE(v_effective_user_id::text, v_caller_id::text, 'guest-customer'),
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
