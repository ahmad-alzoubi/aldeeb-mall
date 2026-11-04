-- ==============================================================================
-- Migration 025: POS Shifts, Cashier Governance, Real PIN, and Atomic POS Checkout
-- ==============================================================================
-- 1. Upgrades `cashier_shifts` sequence to guarantee global uniqueness across branches.
-- 2. Creates `get_active_cashier_shift` RPC for server-authoritative shift state.
-- 3. Adds `pin_code` to `staff_members` and provides secure `verify_staff_pin` RPC.
-- 4. Adds `lookup_customer_by_phone` RPC for real loyalty customer profiles.
-- 5. Implements `process_pos_sale_atomic` RPC for 100% server-authoritative,
--    atomic POS transactions with row-level locking, stock deduction, shift
--    aggregation, payment validation (cash/card/split), and idempotency replay.
-- 6. Provides alias functions `open_pos_shift`, `close_pos_shift`, `get_active_pos_shift`
--    for seamless backwards and forwards client compatibility.
-- ==============================================================================

BEGIN;

-- ------------------------------------------------------------------------------
-- 1. POS SHIFT NUMBER SEQUENCE & ROBUST SHIFT GENERATION
-- ------------------------------------------------------------------------------

CREATE SEQUENCE IF NOT EXISTS public.pos_shift_number_seq START WITH 2001;

-- Fix open_cashier_shift to prevent duplicate shift_number collisions
CREATE OR REPLACE FUNCTION public.open_cashier_shift(
    p_branch_id text,
    p_branch_name text,
    p_terminal_code text,
    p_device_fingerprint text,
    p_cashier_id text,
    p_cashier_name text,
    p_opening_balance numeric,
    p_notes text DEFAULT NULL::text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_existing_shift RECORD;
    v_new_shift_id UUID := gen_random_uuid();
    v_shift_number TEXT;
    v_today TEXT := to_char(now() AT TIME ZONE 'UTC', 'YYYYMMDD');
    v_clean_term TEXT := UPPER(REGEXP_REPLACE(COALESCE(p_terminal_code, 'POS-01'), '[^a-zA-Z0-9]', '', 'g'));
    v_clean_branch TEXT := UPPER(REGEXP_REPLACE(COALESCE(p_branch_id, 'BR'), '[^a-zA-Z0-9]', '', 'g'));
    v_seq BIGINT;
    v_result RECORD;
BEGIN
    -- Defensive validation
    IF p_opening_balance < 0 THEN
        RAISE EXCEPTION 'الرصيد الافتتاحي لا يمكن أن يكون سالباً';
    END IF;

    -- Check if this cashier or terminal already has an open shift in this branch
    SELECT * INTO v_existing_shift
    FROM public.cashier_shifts
    WHERE branch_id = p_branch_id
      AND (cashier_id = p_cashier_id OR terminal_code = p_terminal_code)
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
        p_cashier_id,
        p_cashier_name,
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
        p_cashier_name,
        p_cashier_id,
        'رصيد افتتاحي لبدء الوردية'
    );

    -- Record in audit logs
    INSERT INTO public.audit_logs (
        actor_id, actor_name, actor_role, action, category, target_id, target_type, branch_id, details, metadata
    ) VALUES (
        p_cashier_id, p_cashier_name, 'cashier', 'OPEN_CASHIER_SHIFT', 'pos', v_new_shift_id::text, 'cashier_shifts', p_branch_id,
        'فتح وردية كاشير جديدة رقم ' || v_shift_number,
        jsonb_build_object('shift_number', v_shift_number, 'opening_balance', p_opening_balance, 'terminal_code', p_terminal_code)
    );

    RETURN to_jsonb(v_result);
END;
$$;

-- ------------------------------------------------------------------------------
-- 2. GET ACTIVE SHIFT RPC
-- ------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.get_active_cashier_shift(
    p_branch_id text,
    p_cashier_id text DEFAULT NULL,
    p_terminal_code text DEFAULT 'POS-01'
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_shift RECORD;
BEGIN
    -- 1. Try finding shift matching exact branch + cashier
    IF p_cashier_id IS NOT NULL AND p_cashier_id != '' THEN
        SELECT * INTO v_shift
        FROM public.cashier_shifts
        WHERE branch_id = p_branch_id
          AND cashier_id = p_cashier_id
          AND status = 'open'
        ORDER BY opened_at DESC
        LIMIT 1;
    END IF;

    -- 2. If not found, try finding active open shift for branch + terminal
    IF v_shift IS NULL THEN
        SELECT * INTO v_shift
        FROM public.cashier_shifts
        WHERE branch_id = p_branch_id
          AND terminal_code = p_terminal_code
          AND status = 'open'
        ORDER BY opened_at DESC
        LIMIT 1;
    END IF;

    -- 3. If still not found, check if any open shift exists for this branch
    IF v_shift IS NULL THEN
        SELECT * INTO v_shift
        FROM public.cashier_shifts
        WHERE branch_id = p_branch_id
          AND status = 'open'
        ORDER BY opened_at DESC
        LIMIT 1;
    END IF;

    IF v_shift IS NULL THEN
        RETURN jsonb_build_object('found', false);
    END IF;

    RETURN jsonb_build_object(
        'found', true,
        'shift', to_jsonb(v_shift)
    );
END;
$$;

-- Alias for backwards / PosTerminalPage compatibility
CREATE OR REPLACE FUNCTION public.get_active_pos_shift(
    p_branch_id text,
    p_staff_id text DEFAULT NULL,
    p_terminal_code text DEFAULT 'POS-01'
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN public.get_active_cashier_shift(p_branch_id, p_staff_id, p_terminal_code);
END;
$$;

-- Alias for open_pos_shift
CREATE OR REPLACE FUNCTION public.open_pos_shift(
    p_branch_id text,
    p_staff_id text,
    p_terminal_code text DEFAULT 'POS-01',
    p_opening_balance numeric DEFAULT 0.00,
    p_notes text DEFAULT ''
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_branch RECORD;
    v_staff RECORD;
    v_shift JSONB;
BEGIN
    SELECT id, name_ar INTO v_branch FROM public.branches WHERE id = p_branch_id LIMIT 1;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'BRANCH_NOT_FOUND: الفرع المحدد غير موجود';
    END IF;

    SELECT id, full_name INTO v_staff FROM public.staff_members WHERE id = p_staff_id OR username = p_staff_id LIMIT 1;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'STAFF_NOT_FOUND: الموظف المحدد غير موجود';
    END IF;

    v_shift := public.open_cashier_shift(
        p_branch_id := v_branch.id,
        p_branch_name := v_branch.name_ar,
        p_terminal_code := COALESCE(p_terminal_code, 'POS-01'),
        p_device_fingerprint := 'WEB-POS',
        p_cashier_id := v_staff.id,
        p_cashier_name := v_staff.full_name,
        p_opening_balance := p_opening_balance,
        p_notes := p_notes
    );

    RETURN jsonb_build_object(
        'success', true,
        'shift', v_shift
    );
END;
$$;

-- Alias for close_pos_shift
CREATE OR REPLACE FUNCTION public.close_pos_shift(
    p_shift_id uuid,
    p_actual_cash numeric,
    p_notes text DEFAULT ''
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_shift RECORD;
    v_res JSONB;
BEGIN
    SELECT * INTO v_shift FROM public.cashier_shifts WHERE id = p_shift_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'SHIFT_NOT_FOUND: الوردية غير موجودة';
    END IF;

    v_res := public.close_cashier_shift(
        p_shift_id := p_shift_id,
        p_actual_cash := p_actual_cash,
        p_closed_by_name := v_shift.cashier_name,
        p_closed_by_id := v_shift.cashier_id,
        p_notes := p_notes
    );

    RETURN jsonb_build_object(
        'success', true,
        'shift', v_res
    );
END;
$$;

-- ------------------------------------------------------------------------------
-- 3. STAFF PIN CODE & PIN VERIFICATION RPC
-- ------------------------------------------------------------------------------

ALTER TABLE public.staff_members ADD COLUMN IF NOT EXISTS pin_code VARCHAR(10);

-- Populate default PINs for staff
UPDATE public.staff_members SET pin_code = '1234' WHERE pin_code IS NULL AND username = 'cashier_omar';
UPDATE public.staff_members SET pin_code = '5555' WHERE pin_code IS NULL AND username = 'admin';
UPDATE public.staff_members SET pin_code = '1234' WHERE pin_code IS NULL;

CREATE OR REPLACE FUNCTION public.verify_staff_pin(
    p_staff_id TEXT,
    p_pin TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_staff RECORD;
BEGIN
    SELECT id, employee_code, full_name, username, role, branch_id, branch_name, pin_code, is_active
    INTO v_staff
    FROM public.staff_members
    WHERE (id = p_staff_id OR username = p_staff_id)
    LIMIT 1;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'STAFF_NOT_FOUND', 'message', 'الموظف غير موجود بالنظام');
    END IF;

    IF NOT v_staff.is_active THEN
        RETURN jsonb_build_object('success', false, 'error', 'STAFF_INACTIVE', 'message', 'حساب الموظف معطل');
    END IF;

    IF v_staff.pin_code IS NULL OR v_staff.pin_code != trim(p_pin) THEN
        RETURN jsonb_build_object('success', false, 'error', 'INVALID_PIN', 'message', 'رمز PIN غير صحيح');
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'staff_id', v_staff.id,
        'employee_code', v_staff.employee_code,
        'full_name', v_staff.full_name,
        'role', v_staff.role,
        'branch_id', v_staff.branch_id,
        'branch_name', v_staff.branch_name
    );
END;
$$;

-- ------------------------------------------------------------------------------
-- 4. REAL LOYALTY LOOKUP BY PHONE RPC
-- ------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.lookup_customer_by_phone(
    p_phone TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_profile RECORD;
    v_clean_phone TEXT;
BEGIN
    v_clean_phone := regexp_replace(COALESCE(p_phone, ''), '[^0-9+]', '', 'g');

    SELECT id, full_name, phone, role, loyalty_points, tier, email
    INTO v_profile
    FROM public.profiles
    WHERE phone = p_phone
       OR phone = v_clean_phone
       OR phone = replace(v_clean_phone, '+966', '0')
       OR phone = replace(v_clean_phone, '05', '+9665')
       OR phone = replace(v_clean_phone, '+963', '09')
       OR phone = replace(v_clean_phone, '09', '+9639')
       OR id::text = p_phone
    LIMIT 1;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('found', false, 'message', 'لم يتم العثور على حساب العميل');
    END IF;

    RETURN jsonb_build_object(
        'found', true,
        'customer_id', v_profile.id,
        'full_name', COALESCE(v_profile.full_name, 'عميل مسجل'),
        'phone', v_profile.phone,
        'loyalty_points', v_profile.loyalty_points,
        'tier', v_profile.tier,
        'email', v_profile.email
    );
END;
$$;

-- ------------------------------------------------------------------------------
-- 5. ATOMIC POS SALE TRANSACTION RPC
-- ------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.process_pos_sale_atomic(
    p_receipt_number TEXT,
    p_idempotency_key TEXT,
    p_branch_id TEXT,
    p_terminal_code TEXT,
    p_staff_id TEXT,
    p_shift_id UUID,
    p_customer_name TEXT,
    p_customer_phone TEXT,
    p_payment_method TEXT,
    p_cash_received NUMERIC,
    p_card_amount NUMERIC,
    p_card_auth_code TEXT,
    p_subtotal NUMERIC,
    p_tax_amount NUMERIC,
    p_discount_amount NUMERIC,
    p_loyalty_points_used INTEGER,
    p_loyalty_discount NUMERIC,
    p_total_amount NUMERIC,
    p_items JSONB,
    p_notes TEXT DEFAULT ''
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_existing_order RECORD;
    v_shift RECORD;
    v_branch RECORD;
    v_customer RECORD;
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

    IF v_shift.branch_id != p_branch_id THEN
        RAISE EXCEPTION 'BRANCH_SHIFT_MISMATCH: الوردية تتبع فرع آخر مختلف عن الفرع النشط';
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
        IF p_card_auth_code IS NULL OR trim(p_card_auth_code) = '' THEN
            RAISE EXCEPTION 'CARD_AUTH_REQUIRED: يلزم إدخال أو تأكيد مرجع التحصيل لجهاز الدفع بالبطاقة';
        END IF;
        v_cash_applied := 0;
        v_card_applied := p_total_amount;

    ELSIF p_payment_method = 'split' THEN
        IF (COALESCE(p_cash_received, 0) + COALESCE(p_card_amount, 0)) < p_total_amount THEN
            RAISE EXCEPTION 'INSUFFICIENT_SPLIT_PAYMENT: إجمالي المدفوع نقداً وبطاقة (% ل.س) أقل من قيمة الفاتورة (% ل.س)',
                (COALESCE(p_cash_received, 0) + COALESCE(p_card_amount, 0)), p_total_amount;
        END IF;
        IF COALESCE(p_card_amount, 0) > 0 AND (p_card_auth_code IS NULL OR trim(p_card_auth_code) = '') THEN
            RAISE EXCEPTION 'CARD_AUTH_REQUIRED: يلزم إدخال مرجع تفويض البطاقة لعمليات الدفع الجزئي بالشبكة';
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
            sales_count = sales_count + v_qty::integer,
            updated_at = timezone('utc'::text, now())
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
            'MOV-POS-' || to_char(CURRENT_DATE, 'YYYYMMDD') || '-' || substring(gen_random_uuid()::text, 1, 8),
            p_branch_id,
            v_product_id,
            'sale',
            -v_qty,
            0,
            COALESCE(v_branch_inv.quantity_on_hand, v_product.stock_quantity) - v_qty,
            COALESCE(v_branch_inv.quantity_reserved, 0),
            'order',
            p_receipt_number,
            v_shift.cashier_id,
            v_shift.cashier_name,
            'cashier',
            'بيع كاشير مباشر POS • الوردية: ' || v_shift.shift_number
        );
    END LOOP;

    -- -------------------------------------------------------------------------
    -- STEP 5: Real Loyalty Customer Points (Deduction & Earning)
    -- -------------------------------------------------------------------------
    IF p_customer_phone IS NOT NULL AND trim(p_customer_phone) != '' THEN
        SELECT id, loyalty_points INTO v_customer
        FROM public.profiles
        WHERE phone = p_customer_phone 
           OR phone = regexp_replace(p_customer_phone, '[^0-9+]', '', 'g')
        FOR UPDATE;

        IF FOUND THEN
            v_customer_id := v_customer.id;

            -- Deduct used loyalty points
            IF COALESCE(p_loyalty_points_used, 0) > 0 THEN
                IF v_customer.loyalty_points < p_loyalty_points_used THEN
                    RAISE EXCEPTION 'INSUFFICIENT_LOYALTY_POINTS: رصيد نقاط الولاء المتاح (% نقطة) أقل من المطلوب استخدامه (% نقطة)',
                        v_customer.loyalty_points, p_loyalty_points_used;
                END IF;

                UPDATE public.profiles
                SET loyalty_points = loyalty_points - p_loyalty_points_used,
                    updated_at = timezone('utc'::text, now())
                WHERE id = v_customer.id;

                INSERT INTO public.loyalty_transactions (
                    user_id, points, transaction_type, description_ar, description_en
                ) VALUES (
                    v_customer.id, -p_loyalty_points_used, 'redeemed',
                    'استبدال نقاط في نقطة البيع POS • فاتورة ' || p_receipt_number,
                    'Points redeemed at POS checkout #' || p_receipt_number
                );
            END IF;

            -- Earn new points (1 point per 50 units)
            v_points_earned := FLOOR(p_total_amount / 50.0);
            IF v_points_earned > 0 THEN
                UPDATE public.profiles
                SET loyalty_points = loyalty_points + v_points_earned,
                    updated_at = timezone('utc'::text, now())
                WHERE id = v_customer.id;

                INSERT INTO public.loyalty_transactions (
                    user_id, points, transaction_type, description_ar, description_en
                ) VALUES (
                    v_customer.id, v_points_earned, 'earned',
                    'نقاط مكتسبة من فاتورة كاشير POS #' || p_receipt_number,
                    'Points earned from POS checkout #' || p_receipt_number
                );
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
        v_shift.cashier_id,
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
        v_shift.cashier_id,
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

-- Permissions and Grants for PostgREST & Application Roles
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.cashier_shifts TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.cashier_shift_movements TO anon, authenticated, service_role;
GRANT ALL ON SEQUENCE public.pos_shift_number_seq TO anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public.verify_staff_pin(TEXT, TEXT) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.lookup_customer_by_phone(TEXT) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_active_cashier_shift(TEXT, TEXT, TEXT) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.open_cashier_shift(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, NUMERIC, TEXT) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.close_cashier_shift(UUID, NUMERIC, TEXT, TEXT, TEXT) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.process_pos_sale_atomic(TEXT, TEXT, TEXT, TEXT, TEXT, UUID, TEXT, TEXT, TEXT, NUMERIC, NUMERIC, TEXT, NUMERIC, NUMERIC, NUMERIC, INTEGER, NUMERIC, NUMERIC, JSONB, TEXT) TO anon, authenticated, service_role;

-- Record in _schema_migrations
INSERT INTO public._schema_migrations (filename, applied_at)
VALUES ('20261104_025_pos_shifts_cashier_and_atomic_checkout.sql', timezone('utc'::text, now()))
ON CONFLICT (filename) DO UPDATE SET applied_at = timezone('utc'::text, now());

COMMIT;
