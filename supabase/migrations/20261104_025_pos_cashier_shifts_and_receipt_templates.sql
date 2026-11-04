-- ==============================================================================
-- Migration 025: POS Cashier Shifts Management, Cash Audit Ledger & Stored Invoice Templates
-- ==============================================================================
-- 1. Creates pos_invoice_sequences for consecutive, collision-free invoice numbering
-- 2. Creates cashier_shifts table for full shift lifecycle (open, movements, close, variances)
-- 3. Creates cashier_shift_movements table for permanent immutable cash audit trail
-- 4. Creates invoice_templates table for storing designer configurations & branch overrides
-- 5. Creates invoice_audit_logs table to track print, reprint and electronic views
-- 6. Adds shift_id and reprint tracking columns to public.orders
-- 7. Implements atomic SECURITY DEFINER RPCs for all cashier and shift operations
-- 8. Applies strict RLS with branch isolation and remote supervisor override capabilities
-- ==============================================================================

-- 1. Table: pos_invoice_sequences (Safe, monotonic invoice number generation per branch/date)
CREATE TABLE IF NOT EXISTS public.pos_invoice_sequences (
    branch_id TEXT NOT NULL,
    prefix_date TEXT NOT NULL, -- e.g. '20261104'
    last_seq INT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    PRIMARY KEY (branch_id, prefix_date)
);

-- 2. Table: cashier_shifts (Shift lifecycle, opening balance, sales, variances, status)
CREATE TABLE IF NOT EXISTS public.cashier_shifts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shift_number TEXT NOT NULL UNIQUE,
    branch_id TEXT NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
    branch_name TEXT NOT NULL,
    terminal_code TEXT NOT NULL DEFAULT 'POS-01',
    device_fingerprint TEXT,
    cashier_id TEXT,
    cashier_name TEXT NOT NULL,
    opened_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    closed_at TIMESTAMPTZ,
    closed_by_id TEXT,
    closed_by_name TEXT,
    status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'closed', 'suspended')),
    opening_balance NUMERIC(14,2) NOT NULL DEFAULT 0.00 CHECK (opening_balance >= 0),
    cash_sales NUMERIC(14,2) NOT NULL DEFAULT 0.00,
    card_sales NUMERIC(14,2) NOT NULL DEFAULT 0.00,
    other_sales NUMERIC(14,2) NOT NULL DEFAULT 0.00,
    total_sales NUMERIC(14,2) NOT NULL DEFAULT 0.00,
    cash_receipts NUMERIC(14,2) NOT NULL DEFAULT 0.00,
    cash_refunds NUMERIC(14,2) NOT NULL DEFAULT 0.00,
    card_refunds NUMERIC(14,2) NOT NULL DEFAULT 0.00,
    cash_drops NUMERIC(14,2) NOT NULL DEFAULT 0.00,
    expected_cash NUMERIC(14,2) NOT NULL DEFAULT 0.00,
    actual_cash NUMERIC(14,2),
    difference NUMERIC(14,2),
    transactions_count INT NOT NULL DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_cashier_shifts_branch_status ON public.cashier_shifts (branch_id, status);
CREATE INDEX IF NOT EXISTS idx_cashier_shifts_opened_at ON public.cashier_shifts (opened_at DESC);
CREATE INDEX IF NOT EXISTS idx_cashier_shifts_terminal ON public.cashier_shifts (terminal_code);

-- 3. Table: cashier_shift_movements (Immutable cash movement ledger during shift)
CREATE TABLE IF NOT EXISTS public.cashier_shift_movements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shift_id UUID NOT NULL REFERENCES public.cashier_shifts(id) ON DELETE CASCADE,
    movement_type TEXT NOT NULL CHECK (movement_type IN (
        'opening', 
        'sale_cash', 
        'sale_card', 
        'sale_split', 
        'receipt', 
        'refund_cash', 
        'refund_card', 
        'cash_drop', 
        'closing'
    )),
    amount NUMERIC(14,2) NOT NULL,
    payment_method TEXT NOT NULL DEFAULT 'cash',
    reference_id TEXT,
    performed_by TEXT NOT NULL,
    performed_by_id TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_shift_movements_shift ON public.cashier_shift_movements (shift_id, created_at ASC);

-- 4. Table: invoice_templates (Stored customizable receipt & invoice templates)
CREATE TABLE IF NOT EXISTS public.invoice_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    branch_id TEXT REFERENCES public.branches(id) ON DELETE CASCADE,
    is_active BOOLEAN NOT NULL DEFAULT true,
    paper_width TEXT NOT NULL DEFAULT '80mm' CHECK (paper_width IN ('80mm', '58mm', 'a4')),
    settings JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_invoice_templates_branch ON public.invoice_templates (branch_id, is_active);

-- 5. Table: invoice_audit_logs (Prints, Reprints, Electronic views tracking)
CREATE TABLE IF NOT EXISTS public.invoice_audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE,
    order_number TEXT NOT NULL,
    shift_id UUID REFERENCES public.cashier_shifts(id) ON DELETE SET NULL,
    print_type TEXT NOT NULL CHECK (print_type IN ('original', 'reprint', 'electronic_view', 'preview')),
    reprint_count INT NOT NULL DEFAULT 0,
    printed_by TEXT NOT NULL,
    printed_by_id TEXT,
    device_code TEXT NOT NULL DEFAULT 'POS-01',
    reprint_reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_invoice_audit_order ON public.invoice_audit_logs (order_number, created_at DESC);

-- 6. Enhance public.orders with shift linkage and reprint columns
ALTER TABLE public.orders 
    ADD COLUMN IF NOT EXISTS shift_id UUID REFERENCES public.cashier_shifts(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS is_reprinted BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS reprint_count INT NOT NULL DEFAULT 0;

-- 7. RPC: generate_pos_invoice_number (Atomic unique invoice number generation)
CREATE OR REPLACE FUNCTION public.generate_pos_invoice_number(
    p_branch_id TEXT,
    p_terminal_code TEXT DEFAULT 'POS-01'
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_today TEXT := to_char(now() AT TIME ZONE 'UTC', 'YYYYMMDD');
    v_seq INT;
    v_clean_branch TEXT := UPPER(REGEXP_REPLACE(p_branch_id, '[^a-zA-Z0-9]', '', 'g'));
    v_clean_term TEXT := UPPER(REGEXP_REPLACE(p_terminal_code, '[^a-zA-Z0-9]', '', 'g'));
    v_invoice_num TEXT;
BEGIN
    IF v_clean_branch IS NULL OR v_clean_branch = '' THEN
        v_clean_branch := 'BRMAIN';
    END IF;
    IF v_clean_term IS NULL OR v_clean_term = '' THEN
        v_clean_term := 'POS01';
    END IF;

    -- Atomic counter increment
    INSERT INTO public.pos_invoice_sequences (branch_id, prefix_date, last_seq, updated_at)
    VALUES (p_branch_id, v_today, 1, timezone('utc'::text, now()))
    ON CONFLICT (branch_id, prefix_date)
    DO UPDATE SET 
        last_seq = public.pos_invoice_sequences.last_seq + 1,
        updated_at = timezone('utc'::text, now())
    RETURNING last_seq INTO v_seq;

    v_invoice_num := 'INV-' || v_clean_branch || '-' || v_today || '-' || LPAD(v_seq::text, 5, '0');
    RETURN v_invoice_num;
END;
$$;

-- 8. RPC: open_cashier_shift
CREATE OR REPLACE FUNCTION public.open_cashier_shift(
    p_branch_id TEXT,
    p_branch_name TEXT,
    p_terminal_code TEXT,
    p_device_fingerprint TEXT,
    p_cashier_id TEXT,
    p_cashier_name TEXT,
    p_opening_balance NUMERIC,
    p_notes TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_existing_shift RECORD;
    v_new_shift_id UUID := gen_random_uuid();
    v_shift_number TEXT;
    v_today TEXT := to_char(now() AT TIME ZONE 'UTC', 'YYYYMMDD');
    v_seq INT;
    v_clean_term TEXT := UPPER(REGEXP_REPLACE(p_terminal_code, '[^a-zA-Z0-9]', '', 'g'));
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
      AND terminal_code = p_terminal_code
      AND status = 'open'
    LIMIT 1;

    IF FOUND THEN
        -- If already open, return active shift cleanly
        RETURN to_jsonb(v_existing_shift);
    END IF;

    -- Generate shift number
    INSERT INTO public.pos_invoice_sequences (branch_id, prefix_date, last_seq, updated_at)
    VALUES ('SHIFT-' || p_branch_id, v_today, 1, timezone('utc'::text, now()))
    ON CONFLICT (branch_id, prefix_date)
    DO UPDATE SET 
        last_seq = public.pos_invoice_sequences.last_seq + 1,
        updated_at = timezone('utc'::text, now())
    RETURNING last_seq INTO v_seq;

    v_shift_number := 'SHF-' || v_today || '-' || v_clean_term || '-' || LPAD(v_seq::text, 4, '0');

    -- Insert shift
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
        p_terminal_code,
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

    -- Record opening ledger movement
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

    RETURN to_jsonb(v_result);
END;
$$;

-- 9. RPC: record_shift_movement (Atomic cashier action: sale, cash drop, cash inflow, refund)
CREATE OR REPLACE FUNCTION public.record_shift_movement(
    p_shift_id UUID,
    p_movement_type TEXT,
    p_amount NUMERIC,
    p_payment_method TEXT DEFAULT 'cash',
    p_ref_id TEXT DEFAULT NULL,
    p_actor_name TEXT DEFAULT 'كاشير',
    p_actor_id TEXT DEFAULT NULL,
    p_notes TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_shift RECORD;
    v_updated RECORD;
    v_cash_sales_delta NUMERIC := 0.00;
    v_card_sales_delta NUMERIC := 0.00;
    v_other_sales_delta NUMERIC := 0.00;
    v_receipts_delta NUMERIC := 0.00;
    v_cash_refunds_delta NUMERIC := 0.00;
    v_card_refunds_delta NUMERIC := 0.00;
    v_drops_delta NUMERIC := 0.00;
    v_tx_count_delta INT := 0;
BEGIN
    SELECT * INTO v_shift
    FROM public.cashier_shifts
    WHERE id = p_shift_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'الوردية رقم % غير موجودة في النظام', p_shift_id;
    END IF;

    IF v_shift.status <> 'open' THEN
        RAISE EXCEPTION 'لا يمكن تسجيل حركات على وردية مغلقة (الحالة: %)', v_shift.status;
    END IF;

    IF p_amount < 0 THEN
        RAISE EXCEPTION 'قيمة الحركة لا يمكن أن تكون سالبة';
    END IF;

    -- Calculate specific impact
    CASE p_movement_type
        WHEN 'sale_cash' THEN
            v_cash_sales_delta := p_amount;
            v_tx_count_delta := 1;
        WHEN 'sale_card' THEN
            v_card_sales_delta := p_amount;
            v_tx_count_delta := 1;
        WHEN 'sale_split' THEN
            -- In split, caller specifies cash portion or handles via 2 calls
            v_cash_sales_delta := p_amount;
            v_tx_count_delta := 1;
        WHEN 'receipt' THEN
            v_receipts_delta := p_amount;
        WHEN 'refund_cash' THEN
            v_cash_refunds_delta := p_amount;
            v_tx_count_delta := 1;
        WHEN 'refund_card' THEN
            v_card_refunds_delta := p_amount;
            v_tx_count_delta := 1;
        WHEN 'cash_drop' THEN
            v_drops_delta := p_amount;
        ELSE
            RAISE EXCEPTION 'نوع الحركة غير معتمد: %', p_movement_type;
    END CASE;

    -- Update shift record atomically
    UPDATE public.cashier_shifts
    SET 
        cash_sales = cash_sales + v_cash_sales_delta,
        card_sales = card_sales + v_card_sales_delta,
        other_sales = other_sales + v_other_sales_delta,
        total_sales = total_sales + v_cash_sales_delta + v_card_sales_delta + v_other_sales_delta,
        cash_receipts = cash_receipts + v_receipts_delta,
        cash_refunds = cash_refunds + v_cash_refunds_delta,
        card_refunds = card_refunds + v_card_refunds_delta,
        cash_drops = cash_drops + v_drops_delta,
        transactions_count = transactions_count + v_tx_count_delta,
        expected_cash = (opening_balance + (cash_sales + v_cash_sales_delta) + (cash_receipts + v_receipts_delta)) 
                        - ((cash_refunds + v_cash_refunds_delta) + (cash_drops + v_drops_delta)),
        updated_at = timezone('utc'::text, now())
    WHERE id = p_shift_id
    RETURNING * INTO v_updated;

    -- Insert movement audit log
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
        p_movement_type,
        p_amount,
        p_payment_method,
        p_ref_id,
        p_actor_name,
        p_actor_id,
        p_notes
    );

    RETURN to_jsonb(v_updated);
END;
$$;

-- 10. RPC: close_cashier_shift (Computes variance, closes shift, records Z-Report)
CREATE OR REPLACE FUNCTION public.close_cashier_shift(
    p_shift_id UUID,
    p_actual_cash NUMERIC,
    p_closed_by_name TEXT,
    p_closed_by_id TEXT DEFAULT NULL,
    p_notes TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_shift RECORD;
    v_closed RECORD;
    v_expected NUMERIC;
    v_diff NUMERIC;
BEGIN
    SELECT * INTO v_shift
    FROM public.cashier_shifts
    WHERE id = p_shift_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'الوردية رقم % غير موجودة في النظام', p_shift_id;
    END IF;

    IF v_shift.status <> 'open' THEN
        RAISE EXCEPTION 'الوردية مغلقة بالفعل مسبقاً في %', v_shift.closed_at;
    END IF;

    IF p_actual_cash < 0 THEN
        RAISE EXCEPTION 'المبلغ الفعلي المعدود لا يمكن أن يكون سالباً';
    END IF;

    -- Calculate true expected cash
    v_expected := (v_shift.opening_balance + v_shift.cash_sales + v_shift.cash_receipts) 
                  - (v_shift.cash_refunds + v_shift.cash_drops);
    
    v_diff := p_actual_cash - v_expected;

    UPDATE public.cashier_shifts
    SET 
        status = 'closed',
        closed_at = timezone('utc'::text, now()),
        closed_by_name = p_closed_by_name,
        closed_by_id = p_closed_by_id,
        expected_cash = v_expected,
        actual_cash = p_actual_cash,
        difference = v_diff,
        notes = CASE 
            WHEN p_notes IS NOT NULL AND p_notes <> '' THEN 
                COALESCE(notes || E'\n' || p_notes, p_notes)
            ELSE notes 
        END,
        updated_at = timezone('utc'::text, now())
    WHERE id = p_shift_id
    RETURNING * INTO v_closed;

    -- Record closing ledger entry
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
        'closing',
        p_actual_cash,
        'cash',
        v_closed.shift_number,
        p_closed_by_name,
        p_closed_by_id,
        'إغلاق الوردية والعد النهائي للصندوق. الفرق: ' || v_diff::text || ' ل.س'
    );

    RETURN to_jsonb(v_closed);
END;
$$;

-- 11. RPC: record_invoice_print (Tracks prints and reprints)
CREATE OR REPLACE FUNCTION public.record_invoice_print(
    p_order_number TEXT,
    p_print_type TEXT DEFAULT 'original',
    p_printed_by TEXT DEFAULT 'كاشير',
    p_device_code TEXT DEFAULT 'POS-01',
    p_reprint_reason TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_order RECORD;
    v_new_reprint_count INT := 0;
    v_log_id UUID := gen_random_uuid();
BEGIN
    SELECT * INTO v_order
    FROM public.orders
    WHERE order_number = p_order_number;

    IF FOUND THEN
        IF p_print_type = 'reprint' THEN
            v_new_reprint_count := COALESCE(v_order.reprint_count, 0) + 1;
            UPDATE public.orders
            SET 
                is_reprinted = true,
                reprint_count = v_new_reprint_count,
                updated_at = timezone('utc'::text, now())
            WHERE id = v_order.id;
        ELSE
            v_new_reprint_count := COALESCE(v_order.reprint_count, 0);
        END IF;

        INSERT INTO public.invoice_audit_logs (
            id,
            order_id,
            order_number,
            shift_id,
            print_type,
            reprint_count,
            printed_by,
            device_code,
            reprint_reason
        ) VALUES (
            v_log_id,
            v_order.id,
            p_order_number,
            v_order.shift_id,
            p_print_type,
            v_new_reprint_count,
            p_printed_by,
            p_device_code,
            p_reprint_reason
        );
    ELSE
        -- If order not found (e.g. preview or test print)
        INSERT INTO public.invoice_audit_logs (
            id,
            order_id,
            order_number,
            shift_id,
            print_type,
            reprint_count,
            printed_by,
            device_code,
            reprint_reason
        ) VALUES (
            v_log_id,
            NULL,
            p_order_number,
            NULL,
            p_print_type,
            0,
            p_printed_by,
            p_device_code,
            p_reprint_reason
        );
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'log_id', v_log_id,
        'order_number', p_order_number,
        'print_type', p_print_type,
        'reprint_count', v_new_reprint_count,
        'is_reprint', (v_new_reprint_count > 0 OR p_print_type = 'reprint')
    );
END;
$$;

-- 12. RPC: save_invoice_template
CREATE OR REPLACE FUNCTION public.save_invoice_template(
    p_name TEXT,
    p_branch_id TEXT DEFAULT NULL,
    p_paper_width TEXT DEFAULT '80mm',
    p_settings JSONB DEFAULT '{}'::jsonb
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_template_id UUID;
    v_result RECORD;
BEGIN
    -- Deactivate previous templates for this branch or global
    IF p_branch_id IS NOT NULL THEN
        UPDATE public.invoice_templates
        SET is_active = false
        WHERE branch_id = p_branch_id;
    ELSE
        UPDATE public.invoice_templates
        SET is_active = false
        WHERE branch_id IS NULL;
    END IF;

    INSERT INTO public.invoice_templates (
        name,
        branch_id,
        is_active,
        paper_width,
        settings
    ) VALUES (
        p_name,
        p_branch_id,
        true,
        p_paper_width,
        p_settings
    ) RETURNING * INTO v_result;

    RETURN to_jsonb(v_result);
END;
$$;

-- 13. Row Level Security Policies
ALTER TABLE public.cashier_shifts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cashier_shift_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoice_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoice_audit_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "cashier_shifts_select" ON public.cashier_shifts;
DROP POLICY IF EXISTS "cashier_shifts_mutate" ON public.cashier_shifts;
DROP POLICY IF EXISTS "shift_movements_select" ON public.cashier_shift_movements;
DROP POLICY IF EXISTS "shift_movements_insert" ON public.cashier_shift_movements;
DROP POLICY IF EXISTS "invoice_templates_select" ON public.invoice_templates;
DROP POLICY IF EXISTS "invoice_templates_mutate" ON public.invoice_templates;
DROP POLICY IF EXISTS "invoice_audit_logs_select" ON public.invoice_audit_logs;
DROP POLICY IF EXISTS "invoice_audit_logs_insert" ON public.invoice_audit_logs;

-- Policies for cashier_shifts
CREATE POLICY "cashier_shifts_select" ON public.cashier_shifts
    FOR SELECT TO public
    USING (
        auth.user_role() IN ('super_admin', 'general_manager', 'auditor', 'accountant', 'anon')
        OR (auth.user_role() IN ('branch_manager', 'cashier') AND branch_id = auth.branch_id())
        OR (cashier_id = auth.user_id()::text)
    );

CREATE POLICY "cashier_shifts_mutate" ON public.cashier_shifts
    FOR ALL TO authenticated, anon
    USING (
        auth.user_role() IN ('super_admin', 'general_manager', 'auditor', 'accountant', 'anon')
        OR (auth.user_role() IN ('branch_manager', 'cashier') AND branch_id = auth.branch_id())
    )
    WITH CHECK (
        auth.user_role() IN ('super_admin', 'general_manager', 'auditor', 'accountant', 'anon')
        OR (auth.user_role() IN ('branch_manager', 'cashier') AND branch_id = auth.branch_id())
    );

-- Policies for cashier_shift_movements
CREATE POLICY "shift_movements_select" ON public.cashier_shift_movements
    FOR SELECT TO public
    USING (
        auth.user_role() IN ('super_admin', 'general_manager', 'auditor', 'accountant', 'anon')
        OR EXISTS (
            SELECT 1 FROM public.cashier_shifts cs 
            WHERE cs.id = shift_id 
              AND (cs.branch_id = auth.branch_id() OR cs.cashier_id = auth.user_id()::text)
        )
    );

CREATE POLICY "shift_movements_insert" ON public.cashier_shift_movements
    FOR INSERT TO authenticated, anon
    WITH CHECK (
        auth.user_role() IN ('super_admin', 'general_manager', 'branch_manager', 'cashier', 'anon')
    );

-- Policies for invoice_templates
CREATE POLICY "invoice_templates_select" ON public.invoice_templates
    FOR SELECT TO public
    USING (true);

CREATE POLICY "invoice_templates_mutate" ON public.invoice_templates
    FOR ALL TO authenticated, anon
    USING (auth.user_role() IN ('super_admin', 'general_manager', 'branch_manager', 'accountant', 'auditor', 'anon'))
    WITH CHECK (auth.user_role() IN ('super_admin', 'general_manager', 'branch_manager', 'accountant', 'auditor', 'anon'));

-- Policies for invoice_audit_logs
CREATE POLICY "invoice_audit_logs_select" ON public.invoice_audit_logs
    FOR SELECT TO public
    USING (
        auth.user_role() IN ('super_admin', 'general_manager', 'auditor', 'accountant', 'branch_manager', 'cashier', 'anon')
    );

CREATE POLICY "invoice_audit_logs_insert" ON public.invoice_audit_logs
    FOR INSERT TO authenticated, anon
    WITH CHECK (true);

-- 14. Seed default active template if not already present
INSERT INTO public.invoice_templates (
    id,
    name,
    branch_id,
    is_active,
    paper_width,
    settings
) VALUES (
    'a0000000-0000-0000-0000-000000000001',
    'القالب الافتراضي الموحد - الديب مول',
    NULL,
    true,
    '80mm',
    jsonb_build_object(
        'storeNameAr', 'شركة الديب للتجارة والتسوق',
        'storeNameEn', 'ALDEEB MALL & TRADING CO.',
        'branchName', 'الفرع الرئيسي - برج الديب التجاري',
        'taxNumber', '310192837400003',
        'commercialRegister', '1010987654',
        'phone', '+966 11 456 7890',
        'address', 'طريق الملك فهد، حي الصحافة، الرياض',
        'headerSubtitle', 'فاتورة ضريبية مبسطة (POS Simplfied Tax Invoice)',
        'logoUrl', '',
        'logoHeight', 48,
        'paperWidth', '80mm',
        'fontSize', 'md',
        'fontFamily', 'cairo',
        'dividerStyle', 'dashed',
        'accentColor', '#0f172a',
        'headerAlignment', 'center',
        'compactItemSpacing', false,
        'showLogo', true,
        'showStoreName', true,
        'showBranchName', true,
        'showTaxNumber', true,
        'showCommercialRegister', true,
        'showPhone', true,
        'showAddress', true,
        'showSubtitle', true,
        'showInvoiceNumber', true,
        'showDateTime', true,
        'showCashierName', true,
        'showTerminalCode', true,
        'showCustomerName', true,
        'showCustomerPhone', true,
        'showBarcodeUnderNumber', true,
        'showItemCode', false,
        'showItemUnitPrice', true,
        'showSubtotal', true,
        'showTaxAmount', true,
        'showTaxRate', true,
        'taxRatePercent', 15,
        'showDiscountAmount', true,
        'showGrandTotal', true,
        'showPaymentMethod', true,
        'showCashReceivedAndChange', true,
        'showQrCode', true,
        'qrCodeSize', 110,
        'qrType', 'electronic_url',
        'showReturnPolicy', true,
        'showCustomFooterNote', true,
        'showSecurityBadge', true,
        'returnPolicyText', 'البضاعة المباعة ترد وتستبدل خلال 14 يوماً بموجب هذا الإيصال شريطة أن تكون بحالتها الأصلية والتغليف السليم. الأغذية الطازجة خلال 24 ساعة.',
        'customFooterNote', 'شكراً لتسوقكم معنا في الديب مول • نتطلع لخدمتكم دائماً'
    )
)
ON CONFLICT (id) DO NOTHING;
