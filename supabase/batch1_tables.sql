-- BATCH 1: Tables, Columns, and Sequences
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE IF NOT EXISTS public.branch_inventory (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id VARCHAR(64) NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    quantity_on_hand NUMERIC(12, 3) NOT NULL DEFAULT 0.000,
    quantity_reserved NUMERIC(12, 3) NOT NULL DEFAULT 0.000,
    min_stock_alert NUMERIC(12, 3) NOT NULL DEFAULT 5.000,
    max_stock_capacity NUMERIC(12, 3) NOT NULL DEFAULT 500.000,
    bin_location VARCHAR(32) DEFAULT 'A-01-رف',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT uq_branch_inventory_branch_product UNIQUE (branch_id, product_id)
);

CREATE TABLE IF NOT EXISTS public.inventory_movements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    movement_number VARCHAR(64) NOT NULL UNIQUE,
    branch_id VARCHAR(64) NOT NULL REFERENCES public.branches(id) ON DELETE RESTRICT,
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE RESTRICT,
    movement_type VARCHAR(32) NOT NULL,
    quantity_change NUMERIC(12, 3) NOT NULL,
    quantity_reserved_change NUMERIC(12, 3) NOT NULL DEFAULT 0.000,
    resulting_on_hand NUMERIC(12, 3) NOT NULL,
    resulting_reserved NUMERIC(12, 3) NOT NULL DEFAULT 0.000,
    reference_type VARCHAR(32) NOT NULL,
    reference_id VARCHAR(64),
    actor_id VARCHAR(64),
    actor_name VARCHAR(128) NOT NULL DEFAULT 'System',
    actor_role VARCHAR(32) NOT NULL DEFAULT 'cashier',
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

INSERT INTO public.branch_inventory (branch_id, product_id, quantity_on_hand, quantity_reserved, bin_location)
SELECT b.id, p.id, COALESCE(p.stock_quantity, 100)::numeric, 0.000, 'A-01-رف'
FROM public.branches b CROSS JOIN public.products p
ON CONFLICT (branch_id, product_id) DO NOTHING;

ALTER TABLE public.staff_members ADD COLUMN IF NOT EXISTS pin_code VARCHAR(16);
ALTER TABLE public.staff_members ADD COLUMN IF NOT EXISTS failed_pin_attempts INT NOT NULL DEFAULT 0;
ALTER TABLE public.staff_members ADD COLUMN IF NOT EXISTS last_pin_used_at TIMESTAMPTZ;

INSERT INTO public.staff_members (
    employee_code, full_name, username, email, role, branch_id, branch_name, is_active, pin_code, created_at, updated_at
) VALUES 
    ('EMP-001', 'م. حسام الديب', 'admin', 'admin@aldeebmall.sy', 'super_admin', 'b-ruh-01', 'هايبرماركت الرياض الرئيسي (المركز الفاخر)', true, '5555', now(), now()),
    ('EMP-005', 'عمر الدوسري', 'cashier_omar', 'omar.cashier@aldeebmall.sy', 'cashier', 'b-ruh-01', 'هايبرماركت الرياض الرئيسي (المركز الفاخر)', true, '1234', now(), now())
ON CONFLICT (username) DO UPDATE SET
    pin_code = EXCLUDED.pin_code,
    is_active = true,
    branch_id = EXCLUDED.branch_id;

CREATE SEQUENCE IF NOT EXISTS public.pos_shift_number_seq START WITH 2001;

CREATE TABLE IF NOT EXISTS public.pos_invoice_sequences (
    branch_id TEXT NOT NULL,
    prefix_date TEXT NOT NULL,
    last_seq INT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    PRIMARY KEY (branch_id, prefix_date)
);

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

CREATE TABLE IF NOT EXISTS public.cashier_shift_movements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shift_id UUID NOT NULL REFERENCES public.cashier_shifts(id) ON DELETE CASCADE,
    movement_type TEXT NOT NULL,
    amount NUMERIC(14,2) NOT NULL,
    payment_method TEXT NOT NULL DEFAULT 'cash',
    order_id UUID,
    receipt_number TEXT,
    card_auth_code TEXT,
    actor_id TEXT,
    actor_name TEXT NOT NULL,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE TABLE IF NOT EXISTS public.invoice_audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    receipt_number TEXT NOT NULL,
    order_id UUID,
    event_type TEXT NOT NULL,
    actor_id TEXT,
    actor_name TEXT NOT NULL,
    terminal_code TEXT,
    reason TEXT,
    reprint_count INT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS idempotency_key TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS shift_id UUID;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS cashier_id TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS delivered_at TIMESTAMPTZ;

ALTER TABLE public.branch_inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cashier_shifts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cashier_shift_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pos_invoice_sequences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoice_audit_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow read branch_inventory" ON public.branch_inventory;
CREATE POLICY "Allow read branch_inventory" ON public.branch_inventory FOR ALL USING (true);

DROP POLICY IF EXISTS "Allow read inventory_movements" ON public.inventory_movements;
CREATE POLICY "Allow read inventory_movements" ON public.inventory_movements FOR ALL USING (true);

DROP POLICY IF EXISTS "Allow read cashier_shifts" ON public.cashier_shifts;
CREATE POLICY "Allow read cashier_shifts" ON public.cashier_shifts FOR ALL USING (true);

DROP POLICY IF EXISTS "Allow read cashier_shift_movements" ON public.cashier_shift_movements;
CREATE POLICY "Allow read cashier_shift_movements" ON public.cashier_shift_movements FOR ALL USING (true);

DROP POLICY IF EXISTS "Allow read pos_invoice_sequences" ON public.pos_invoice_sequences;
CREATE POLICY "Allow read pos_invoice_sequences" ON public.pos_invoice_sequences FOR ALL USING (true);

DROP POLICY IF EXISTS "Allow read invoice_audit_logs" ON public.invoice_audit_logs;
CREATE POLICY "Allow read invoice_audit_logs" ON public.invoice_audit_logs FOR ALL USING (true);

GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;
