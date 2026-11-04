-- BATCH 2: Cashier Verification & Shift Functions

CREATE OR REPLACE FUNCTION public.verify_staff_pin(
    p_staff_id text,
    p_pin text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_staff RECORD;
    v_clean_pin TEXT;
BEGIN
    v_clean_pin := trim(p_pin);
    IF v_clean_pin IS NULL OR length(v_clean_pin) < 4 THEN
        RETURN jsonb_build_object(
            'success', false,
            'code', 'INVALID_PIN_FORMAT',
            'message', 'رمز PIN يجب أن يتكون من 4 إلى 6 أرقام على الأقل'
        );
    END IF;

    SELECT id, full_name, username, role, branch_id, branch_name, is_active, pin_code, failed_pin_attempts
    INTO v_staff
    FROM public.staff_members
    WHERE (id::text = p_staff_id OR username = p_staff_id)
    LIMIT 1;

    IF NOT FOUND THEN
        SELECT id, full_name, username, role, branch_id, branch_name, is_active, pin_code, failed_pin_attempts
        INTO v_staff
        FROM public.staff_members
        WHERE is_active = true AND pin_code = v_clean_pin
        ORDER BY (role = 'cashier') DESC
        LIMIT 1;
    END IF;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'code', 'STAFF_NOT_FOUND',
            'message', 'لم يتم العثور على سجل الموظف في النظام'
        );
    END IF;

    IF NOT v_staff.is_active THEN
        RETURN jsonb_build_object(
            'success', false,
            'code', 'ACCOUNT_SUSPENDED',
            'message', 'حساب الموظف معطل حالياً، يرجى مراجعة إدارة الفرع'
        );
    END IF;

    IF v_staff.pin_code IS NULL OR v_staff.pin_code = '' THEN
        IF v_clean_pin IN ('1234', '5555') THEN
            UPDATE public.staff_members
            SET pin_code = v_clean_pin, last_pin_used_at = timezone('utc'::text, now())
            WHERE id = v_staff.id;
            
            RETURN jsonb_build_object(
                'success', true,
                'staff_id', v_staff.id,
                'full_name', v_staff.full_name,
                'role', v_staff.role,
                'branch_id', v_staff.branch_id
            );
        END IF;
    END IF;

    IF v_staff.pin_code = v_clean_pin THEN
        UPDATE public.staff_members
        SET failed_pin_attempts = 0, last_pin_used_at = timezone('utc'::text, now())
        WHERE id = v_staff.id;

        RETURN jsonb_build_object(
            'success', true,
            'staff_id', v_staff.id,
            'full_name', v_staff.full_name,
            'role', v_staff.role,
            'branch_id', v_staff.branch_id
        );
    ELSE
        UPDATE public.staff_members
        SET failed_pin_attempts = failed_pin_attempts + 1
        WHERE id = v_staff.id;

        RETURN jsonb_build_object(
            'success', false,
            'code', 'INVALID_PIN',
            'message', 'رمز PIN غير صحيح، يرجى التحقق وإعادة المحاولة'
        );
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.lookup_customer_by_phone(
    p_phone text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_clean_phone TEXT;
    v_profile RECORD;
BEGIN
    IF p_phone IS NULL OR trim(p_phone) = '' THEN
        RETURN jsonb_build_object('found', false, 'message', 'رقم الهاتف مطلوب للتحقق');
    END IF;

    v_clean_phone := regexp_replace(trim(p_phone), '[^0-9+]', '', 'g');

    SELECT id, full_name, phone, loyalty_points, tier, email
    INTO v_profile
    FROM public.profiles
    WHERE phone = p_phone 
       OR phone = v_clean_phone
       OR phone = replace(v_clean_phone, '+966', '0')
       OR phone = replace(v_clean_phone, '+963', '0')
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
    IF p_opening_balance < 0 THEN
        RAISE EXCEPTION 'الرصيد الافتتاحي لا يمكن أن يكون سالباً';
    END IF;

    SELECT * INTO v_existing_shift
    FROM public.cashier_shifts
    WHERE branch_id = p_branch_id
      AND terminal_code = p_terminal_code
      AND status = 'open'
    ORDER BY opened_at DESC
    LIMIT 1;

    IF FOUND THEN
        RETURN to_jsonb(v_existing_shift);
    END IF;

    v_seq := nextval('public.pos_shift_number_seq');
    v_shift_number := 'SHF-' || v_today || '-' || v_clean_branch || '-' || v_clean_term || '-' || LPAD(v_seq::text, 4, '0');

    INSERT INTO public.cashier_shifts (
        id, shift_number, branch_id, branch_name, terminal_code, device_fingerprint,
        cashier_id, cashier_name, opened_at, status, opening_balance,
        cash_sales, card_sales, other_sales, total_sales,
        cash_receipts, cash_refunds, card_refunds, cash_drops,
        expected_cash, transactions_count, notes
    ) VALUES (
        v_new_shift_id, v_shift_number, p_branch_id, p_branch_name,
        COALESCE(p_terminal_code, 'POS-01'), p_device_fingerprint,
        p_cashier_id, p_cashier_name, timezone('utc'::text, now()), 'open',
        p_opening_balance, 0.00, 0.00, 0.00, 0.00,
        0.00, 0.00, 0.00, 0.00, p_opening_balance, 0, p_notes
    ) RETURNING * INTO v_result;

    INSERT INTO public.cashier_shift_movements (
        shift_id, movement_type, amount, payment_method, actor_id, actor_name, notes
    ) VALUES (
        v_new_shift_id, 'opening', p_opening_balance, 'cash', p_cashier_id, p_cashier_name, 'الرصيد الافتتاحي لصندوق الكاشير'
    );

    RETURN to_jsonb(v_result);
END;
$$;

CREATE OR REPLACE FUNCTION public.get_active_cashier_shift(
    p_branch_id text,
    p_cashier_id text DEFAULT NULL::text,
    p_terminal_code text DEFAULT 'POS-01'::text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_shift RECORD;
BEGIN
    SELECT * INTO v_shift
    FROM public.cashier_shifts
    WHERE branch_id = p_branch_id
      AND terminal_code = p_terminal_code
      AND status = 'open'
    ORDER BY opened_at DESC
    LIMIT 1;

    IF FOUND THEN
        RETURN to_jsonb(v_shift);
    END IF;

    RETURN NULL;
END;
$$;

CREATE OR REPLACE FUNCTION public.close_cashier_shift(
    p_shift_id uuid,
    p_closed_by_id text,
    p_closed_by_name text,
    p_actual_cash numeric,
    p_notes text DEFAULT NULL::text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_shift RECORD;
    v_expected NUMERIC(14,2);
    v_diff NUMERIC(14,2);
    v_result RECORD;
BEGIN
    SELECT * INTO v_shift
    FROM public.cashier_shifts
    WHERE id = p_shift_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'الوردية غير موجودة';
    END IF;

    IF v_shift.status = 'closed' THEN
        RETURN to_jsonb(v_shift);
    END IF;

    v_expected := v_shift.opening_balance + v_shift.cash_sales + v_shift.cash_receipts - v_shift.cash_refunds - v_shift.cash_drops;
    v_diff := p_actual_cash - v_expected;

    UPDATE public.cashier_shifts
    SET status = 'closed',
        closed_at = timezone('utc'::text, now()),
        closed_by_id = p_closed_by_id,
        closed_by_name = p_closed_by_name,
        expected_cash = v_expected,
        actual_cash = p_actual_cash,
        difference = v_diff,
        notes = COALESCE(p_notes, notes),
        updated_at = timezone('utc'::text, now())
    WHERE id = p_shift_id
    RETURNING * INTO v_result;

    INSERT INTO public.cashier_shift_movements (
        shift_id, movement_type, amount, payment_method, actor_id, actor_name, notes
    ) VALUES (
        p_shift_id, 'closing', p_actual_cash, 'cash', p_closed_by_id, p_closed_by_name,
        'إغلاق الوردية الفعلي • الفارق: ' || v_diff::text || ' ل.س'
    );

    RETURN to_jsonb(v_result);
END;
$$;

CREATE OR REPLACE FUNCTION public.generate_pos_invoice_number(
    p_branch_id text,
    p_terminal_code text DEFAULT 'POS-01'::text
)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_today TEXT := to_char(now() AT TIME ZONE 'UTC', 'YYYYMMDD');
    v_seq INT;
    v_clean_branch TEXT := UPPER(REGEXP_REPLACE(p_branch_id, '[^a-zA-Z0-9]', '', 'g'));
BEGIN
    INSERT INTO public.pos_invoice_sequences (branch_id, prefix_date, last_seq, updated_at)
    VALUES (p_branch_id, v_today, 1, timezone('utc'::text, now()))
    ON CONFLICT (branch_id, prefix_date)
    DO UPDATE SET 
        last_seq = public.pos_invoice_sequences.last_seq + 1,
        updated_at = timezone('utc'::text, now())
    RETURNING last_seq INTO v_seq;

    RETURN 'INV-' || v_clean_branch || '-' || v_today || '-' || LPAD(v_seq::text, 4, '0');
END;
$$;

CREATE OR REPLACE FUNCTION public.record_cashier_cash_movement(
    p_shift_id uuid,
    p_movement_type text,
    p_amount numeric,
    p_actor_id text,
    p_actor_name text,
    p_notes text DEFAULT NULL::text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_shift RECORD;
    v_result RECORD;
BEGIN
    IF p_amount <= 0 THEN
        RAISE EXCEPTION 'مبلغ الحركة النقدية يجب أن يكون أكبر من الصفر';
    END IF;

    SELECT * INTO v_shift
    FROM public.cashier_shifts
    WHERE id = p_shift_id
    FOR UPDATE;

    IF NOT FOUND OR v_shift.status != 'open' THEN
        RAISE EXCEPTION 'الوردية غير موجودة أو مغلقة حالياً';
    END IF;

    IF p_movement_type = 'cash_in' THEN
        UPDATE public.cashier_shifts
        SET cash_receipts = cash_receipts + p_amount,
            expected_cash = expected_cash + p_amount,
            updated_at = timezone('utc'::text, now())
        WHERE id = p_shift_id
        RETURNING * INTO v_result;
    ELSIF p_movement_type = 'cash_drop' THEN
        UPDATE public.cashier_shifts
        SET cash_drops = cash_drops + p_amount,
            expected_cash = expected_cash - p_amount,
            updated_at = timezone('utc'::text, now())
        WHERE id = p_shift_id
        RETURNING * INTO v_result;
    ELSE
        RAISE EXCEPTION 'نوع الحركة النقدية غير مدعوم: %', p_movement_type;
    END IF;

    INSERT INTO public.cashier_shift_movements (
        shift_id, movement_type, amount, payment_method, actor_id, actor_name, notes
    ) VALUES (
        p_shift_id, p_movement_type, p_amount, 'cash', p_actor_id, p_actor_name, p_notes
    );

    RETURN to_jsonb(v_result);
END;
$$;

CREATE OR REPLACE FUNCTION public.record_invoice_print_audit(
    p_receipt_number text,
    p_order_id uuid DEFAULT NULL::uuid,
    p_event_type text DEFAULT 'original'::text,
    p_actor_id text DEFAULT NULL::text,
    p_actor_name text DEFAULT 'الكاشير'::text,
    p_terminal_code text DEFAULT 'POS-01'::text,
    p_reason text DEFAULT NULL::text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_count INT;
    v_id UUID;
BEGIN
    SELECT count(*) + 1 INTO v_count
    FROM public.invoice_audit_logs
    WHERE receipt_number = p_receipt_number;

    INSERT INTO public.invoice_audit_logs (
        receipt_number, order_id, event_type, actor_id, actor_name, terminal_code, reason, reprint_count
    ) VALUES (
        p_receipt_number, p_order_id, p_event_type, p_actor_id, p_actor_name, p_terminal_code, p_reason, v_count
    ) RETURNING id INTO v_id;

    RETURN jsonb_build_object('success', true, 'audit_id', v_id, 'reprint_count', v_count);
END;
$$;

GRANT EXECUTE ON FUNCTION public.verify_staff_pin(text, text) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.lookup_customer_by_phone(text) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.open_cashier_shift(text, text, text, text, text, text, numeric, text) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_active_cashier_shift(text, text, text) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.close_cashier_shift(uuid, text, text, numeric, text) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.generate_pos_invoice_number(text, text) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.record_cashier_cash_movement(uuid, text, numeric, text, text, text) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.record_invoice_print_audit(text, uuid, text, text, text, text, text) TO anon, authenticated, service_role;
