-- BATCH 3: Atomic POS Sale Processing RPC

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
    -- STEP 1: Idempotency Protection
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

    -- STEP 2: Shift Verification
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

    -- STEP 3: Payment Verification
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

    -- STEP 4: Inventory & Cart Items
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

        SELECT id, quantity_on_hand, quantity_reserved
        INTO v_branch_inv
        FROM public.branch_inventory
        WHERE branch_id = p_branch_id AND product_id = v_product_id
        FOR UPDATE;

        IF NOT FOUND THEN
            INSERT INTO public.branch_inventory (
                branch_id, product_id, quantity_on_hand, quantity_reserved, bin_location
            ) VALUES (
                p_branch_id, v_product_id, GREATEST(0, v_product.stock_quantity - v_qty), 0, 'رف-POS-01'
            );
        ELSE
            UPDATE public.branch_inventory
            SET quantity_on_hand = GREATEST(0, quantity_on_hand - v_qty),
                updated_at = timezone('utc'::text, now())
            WHERE id = v_branch_inv.id;
        END IF;

        UPDATE public.products
        SET stock_quantity = GREATEST(0, stock_quantity - v_qty::integer),
            sales_count = sales_count + v_qty::integer,
            updated_at = timezone('utc'::text, now())
        WHERE id = v_product_id;

        INSERT INTO public.inventory_movements (
            movement_number, branch_id, product_id, movement_type,
            quantity_change, quantity_reserved_change, resulting_on_hand, resulting_reserved,
            reference_type, reference_id, actor_id, actor_name, actor_role, notes
        ) VALUES (
            'MOV-POS-' || to_char(CURRENT_DATE, 'YYYYMMDD') || '-' || substring(gen_random_uuid()::text, 1, 8),
            p_branch_id, v_product_id, 'sale',
            -v_qty, 0, COALESCE(v_branch_inv.quantity_on_hand, v_product.stock_quantity) - v_qty, 0,
            'order', p_receipt_number, v_shift.cashier_id, v_shift.cashier_name, 'cashier',
            'بيع كاشير مباشر POS • الوردية: ' || v_shift.shift_number
        );
    END LOOP;

    -- STEP 5: Loyalty Customer
    IF p_customer_phone IS NOT NULL AND trim(p_customer_phone) != '' THEN
        SELECT id, loyalty_points INTO v_customer
        FROM public.profiles
        WHERE phone = p_customer_phone 
           OR phone = regexp_replace(p_customer_phone, '[^0-9+]', '', 'g')
        FOR UPDATE;

        IF FOUND THEN
            v_customer_id := v_customer.id;
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

    -- STEP 6: Insert Order
    INSERT INTO public.orders (
        order_number, user_id, customer_name, customer_phone,
        branch_id, branch_name, status, delivery_slot, payment_method, payment_status,
        subtotal, delivery_fee, discount_amount, loyalty_points_used, loyalty_discount,
        total_amount, notes, idempotency_key, shift_id, cashier_id, delivered_at
    ) VALUES (
        p_receipt_number, v_customer_id,
        COALESCE(NULLIF(trim(p_customer_name), ''), 'عميل نقدي مباشر'),
        COALESCE(NULLIF(trim(p_customer_phone), ''), '+966 50 000 0000'),
        p_branch_id, v_shift.branch_name, 'delivered',
        'كاشير مباشر - ' || v_shift.branch_name, p_payment_method, 'paid',
        p_subtotal, 0, COALESCE(p_discount_amount, 0),
        COALESCE(p_loyalty_points_used, 0), COALESCE(p_loyalty_discount, 0),
        p_total_amount,
        'نقطة بيع POS • الكاشير: ' || v_shift.cashier_name || ' • وردية: ' || v_shift.shift_number ||
            CASE WHEN p_card_auth_code IS NOT NULL AND p_card_auth_code != '' THEN ' • مرجع الشبكة: ' || p_card_auth_code ELSE '' END ||
            ' • ' || COALESCE(p_notes, ''),
        v_effective_idempotency_key, v_shift.id, v_shift.cashier_id, timezone('utc'::text, now())
    ) RETURNING id INTO v_new_order_id;

    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        INSERT INTO public.order_items (
            order_id, product_id, product_name_ar, product_name_en,
            unit, unit_price, quantity, total_price
        ) VALUES (
            v_new_order_id, (v_item->>'product_id')::uuid,
            v_item->>'name_ar', COALESCE(v_item->>'name_en', v_item->>'name_ar'),
            COALESCE(v_item->>'unit', 'piece'), (v_item->>'price')::numeric,
            (v_item->>'quantity')::numeric,
            COALESCE((v_item->>'total')::numeric, (v_item->>'price')::numeric * (v_item->>'quantity')::numeric)
        );
    END LOOP;

    -- STEP 7: Aggregate Shift
    UPDATE public.cashier_shifts
    SET cash_sales = cash_sales + v_cash_applied,
        card_sales = card_sales + v_card_applied,
        total_sales = total_sales + p_total_amount,
        expected_cash = expected_cash + v_cash_applied,
        transactions_count = transactions_count + 1,
        updated_at = timezone('utc'::text, now())
    WHERE id = v_shift.id;

    INSERT INTO public.cashier_shift_movements (
        shift_id, movement_type, amount, payment_method,
        order_id, receipt_number, card_auth_code, actor_id, actor_name, notes
    ) VALUES (
        v_shift.id,
        CASE WHEN p_payment_method = 'split' THEN 'sale_split' WHEN p_payment_method = 'card' THEN 'sale_card' ELSE 'sale_cash' END,
        p_total_amount, p_payment_method, v_new_order_id, p_receipt_number, p_card_auth_code,
        v_shift.cashier_id, v_shift.cashier_name,
        'فاتورة بيع كاشير POS • ' || p_payment_method
    );

    RETURN jsonb_build_object(
        'success', true,
        'order_id', v_new_order_id,
        'receipt_number', p_receipt_number,
        'status', 'delivered',
        'points_earned', v_points_earned,
        'total_amount', p_total_amount,
        'created_at', now()
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.process_pos_sale_atomic(
    text, text, text, text, text, uuid, text, text, text, numeric, numeric, text, numeric, numeric, numeric, integer, numeric, numeric, jsonb, text
) TO anon, authenticated, service_role;

-- Seed initial open shift for POS-01 on Riyadh Main Branch
INSERT INTO public.cashier_shifts (
    id, shift_number, branch_id, branch_name, terminal_code,
    cashier_id, cashier_name, opened_at, status, opening_balance,
    cash_sales, card_sales, total_sales, expected_cash, transactions_count, notes
) VALUES (
    'a1000000-0000-4000-a000-000000000001',
    'SHF-20261104-BRUH01-POS01-1001',
    'b-ruh-01',
    'هايبرماركت الرياض الرئيسي (المركز الفاخر)',
    'POS-01',
    (SELECT id::text FROM public.staff_members WHERE username = 'cashier_omar' LIMIT 1),
    'عمر الدوسري',
    now(),
    'open',
    500.00,
    0.00,
    0.00,
    0.00,
    500.00,
    0,
    'وردية إنتاجية أولية معتمدة'
) ON CONFLICT (shift_number) DO NOTHING;

NOTIFY pgrst, 'reload schema';
