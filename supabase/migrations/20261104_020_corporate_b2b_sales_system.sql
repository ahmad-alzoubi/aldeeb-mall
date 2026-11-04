-- ==============================================================================
-- 🏢 ALDEEB MALL & HYPERMARKET — CORPORATE B2B SALES, QUOTATIONS & INVOICES
-- ==============================================================================
-- Migration: 20261104_020_corporate_b2b_sales_system.sql
-- Description: Comprehensive production implementation of B2B Corporate Sales:
-- 1. Authorized Corporate Client Accounts & KYC (Credit Limits, Payment Terms)
-- 2. Quotations & Pricing RFQs (Wholesale discounts, Multi-tier Approvals)
-- 3. Corporate Tax Invoices with Atomic Inventory Deductions & Credit Verification
-- 4. Payment Settlements & Real-time Debt Reduction (Net-15/30/60)
-- 5. Returns, Credit Notes & Atomic Inventory Restorations
-- 6. Multi-Branch Isolation & Strict RBAC Enforcement
-- ==============================================================================

-- 1. Ensure Table Dependencies and Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Table: corporate_accounts (حسابات العملاء والشركات المفوضة)
CREATE TABLE IF NOT EXISTS public.corporate_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_name TEXT NOT NULL,
    cr_number TEXT NOT NULL UNIQUE,
    vat_number TEXT NOT NULL,
    contact_person TEXT NOT NULL,
    phone TEXT NOT NULL,
    email TEXT,
    city TEXT NOT NULL DEFAULT 'دمشق',
    address TEXT,
    branch_id VARCHAR(64) NOT NULL REFERENCES public.branches(id) ON UPDATE CASCADE,
    monthly_credit_limit NUMERIC(14,2) NOT NULL DEFAULT 5000000.00 CHECK (monthly_credit_limit >= 0),
    current_balance NUMERIC(14,2) NOT NULL DEFAULT 0.00 CHECK (current_balance >= 0),
    payment_terms TEXT NOT NULL DEFAULT 'Net-30' CHECK (payment_terms IN ('Cash', 'Net-15', 'Net-30', 'Net-60')),
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'pending_kyc', 'suspended', 'overdue')),
    recurring_schedule TEXT DEFAULT 'شحنة أسبوعية مجدولة',
    items_summary TEXT,
    notes TEXT,
    created_by TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_corporate_accounts_branch_id ON public.corporate_accounts(branch_id);
CREATE INDEX IF NOT EXISTS idx_corporate_accounts_status ON public.corporate_accounts(status);
CREATE INDEX IF NOT EXISTS idx_corporate_accounts_cr ON public.corporate_accounts(cr_number);

-- 3. Table: corporate_quotations (عروض الأسعار وطلبات الشراء B2B Quotations)
CREATE TABLE IF NOT EXISTS public.corporate_quotations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    quotation_number TEXT NOT NULL UNIQUE,
    corporate_account_id UUID NOT NULL REFERENCES public.corporate_accounts(id) ON DELETE CASCADE,
    branch_id VARCHAR(64) NOT NULL REFERENCES public.branches(id) ON UPDATE CASCADE,
    subtotal NUMERIC(14,2) NOT NULL DEFAULT 0.00 CHECK (subtotal >= 0),
    discount_percent NUMERIC(5,2) NOT NULL DEFAULT 0.00 CHECK (discount_percent >= 0 AND discount_percent <= 100),
    discount_amount NUMERIC(14,2) NOT NULL DEFAULT 0.00 CHECK (discount_amount >= 0),
    tax_amount NUMERIC(14,2) NOT NULL DEFAULT 0.00 CHECK (tax_amount >= 0),
    total_amount NUMERIC(14,2) NOT NULL DEFAULT 0.00 CHECK (total_amount >= 0),
    status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'pending_approval', 'approved', 'rejected', 'converted')),
    valid_until DATE NOT NULL DEFAULT (CURRENT_DATE + INTERVAL '30 days'),
    notes TEXT,
    approved_by TEXT,
    approved_at TIMESTAMPTZ,
    rejection_reason TEXT,
    created_by TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_corporate_quotations_account ON public.corporate_quotations(corporate_account_id);
CREATE INDEX IF NOT EXISTS idx_corporate_quotations_branch ON public.corporate_quotations(branch_id);
CREATE INDEX IF NOT EXISTS idx_corporate_quotations_status ON public.corporate_quotations(status);

-- 4. Table: corporate_quotation_items (بنود عرض السعر)
CREATE TABLE IF NOT EXISTS public.corporate_quotation_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    quotation_id UUID NOT NULL REFERENCES public.corporate_quotations(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES public.products(id) ON UPDATE CASCADE,
    quantity NUMERIC(10,2) NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(14,2) NOT NULL CHECK (unit_price >= 0),
    discount_percent NUMERIC(5,2) NOT NULL DEFAULT 0.00 CHECK (discount_percent >= 0 AND discount_percent <= 100),
    final_unit_price NUMERIC(14,2) NOT NULL CHECK (final_unit_price >= 0),
    total_price NUMERIC(14,2) NOT NULL CHECK (total_price >= 0),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_corporate_quotation_items_qid ON public.corporate_quotation_items(quotation_id);

-- 5. Table: corporate_invoices (فواتير مبيعات الشركات B2B Invoices)
CREATE TABLE IF NOT EXISTS public.corporate_invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_number TEXT NOT NULL UNIQUE,
    quotation_id UUID REFERENCES public.corporate_quotations(id) ON DELETE SET NULL,
    corporate_account_id UUID NOT NULL REFERENCES public.corporate_accounts(id) ON DELETE RESTRICT,
    branch_id VARCHAR(64) NOT NULL REFERENCES public.branches(id) ON UPDATE CASCADE,
    subtotal NUMERIC(14,2) NOT NULL DEFAULT 0.00 CHECK (subtotal >= 0),
    discount_amount NUMERIC(14,2) NOT NULL DEFAULT 0.00 CHECK (discount_amount >= 0),
    tax_amount NUMERIC(14,2) NOT NULL DEFAULT 0.00 CHECK (tax_amount >= 0),
    total_amount NUMERIC(14,2) NOT NULL DEFAULT 0.00 CHECK (total_amount >= 0),
    paid_amount NUMERIC(14,2) NOT NULL DEFAULT 0.00 CHECK (paid_amount >= 0),
    remaining_amount NUMERIC(14,2) NOT NULL DEFAULT 0.00 CHECK (remaining_amount >= 0),
    payment_status TEXT NOT NULL DEFAULT 'unpaid' CHECK (payment_status IN ('unpaid', 'partially_paid', 'paid', 'overdue')),
    due_date DATE NOT NULL,
    notes TEXT,
    created_by TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_corporate_invoices_account ON public.corporate_invoices(corporate_account_id);
CREATE INDEX IF NOT EXISTS idx_corporate_invoices_branch ON public.corporate_invoices(branch_id);
CREATE INDEX IF NOT EXISTS idx_corporate_invoices_status ON public.corporate_invoices(payment_status);

-- 6. Table: corporate_invoice_items (بنود فاتورة الشركات)
CREATE TABLE IF NOT EXISTS public.corporate_invoice_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id UUID NOT NULL REFERENCES public.corporate_invoices(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES public.products(id) ON UPDATE CASCADE,
    quantity NUMERIC(10,2) NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(14,2) NOT NULL CHECK (unit_price >= 0),
    discount_percent NUMERIC(5,2) NOT NULL DEFAULT 0.00 CHECK (discount_percent >= 0 AND discount_percent <= 100),
    final_unit_price NUMERIC(14,2) NOT NULL CHECK (final_unit_price >= 0),
    total_price NUMERIC(14,2) NOT NULL CHECK (total_price >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_corporate_invoice_items_iid ON public.corporate_invoice_items(invoice_id);

-- 7. Table: corporate_payments (سجلات سداد دفعات الشركات)
CREATE TABLE IF NOT EXISTS public.corporate_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    payment_number TEXT NOT NULL UNIQUE,
    invoice_id UUID NOT NULL REFERENCES public.corporate_invoices(id) ON DELETE RESTRICT,
    corporate_account_id UUID NOT NULL REFERENCES public.corporate_accounts(id) ON DELETE RESTRICT,
    amount NUMERIC(14,2) NOT NULL CHECK (amount > 0),
    payment_method TEXT NOT NULL DEFAULT 'bank_transfer' CHECK (payment_method IN ('bank_transfer', 'check', 'cash', 'credit_card')),
    reference_number TEXT NOT NULL,
    payment_date DATE NOT NULL DEFAULT CURRENT_DATE,
    notes TEXT,
    received_by TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_corporate_payments_invoice ON public.corporate_payments(invoice_id);
CREATE INDEX IF NOT EXISTS idx_corporate_payments_account ON public.corporate_payments(corporate_account_id);

-- 8. Table: corporate_returns (مرتجعات مبيعات الشركات وإشعارات دائنة)
CREATE TABLE IF NOT EXISTS public.corporate_returns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    return_number TEXT NOT NULL UNIQUE,
    invoice_id UUID NOT NULL REFERENCES public.corporate_invoices(id) ON DELETE RESTRICT,
    corporate_account_id UUID NOT NULL REFERENCES public.corporate_accounts(id) ON DELETE RESTRICT,
    branch_id VARCHAR(64) NOT NULL REFERENCES public.branches(id) ON UPDATE CASCADE,
    total_refund_amount NUMERIC(14,2) NOT NULL CHECK (total_refund_amount >= 0),
    status TEXT NOT NULL DEFAULT 'pending_approval' CHECK (status IN ('pending_approval', 'approved', 'rejected', 'completed')),
    reason TEXT NOT NULL,
    approved_by TEXT,
    approved_at TIMESTAMPTZ,
    rejection_reason TEXT,
    created_by TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_corporate_returns_invoice ON public.corporate_returns(invoice_id);
CREATE INDEX IF NOT EXISTS idx_corporate_returns_branch ON public.corporate_returns(branch_id);

-- 9. Table: corporate_return_items (بنود الإرجاع)
CREATE TABLE IF NOT EXISTS public.corporate_return_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    return_id UUID NOT NULL REFERENCES public.corporate_returns(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES public.products(id) ON UPDATE CASCADE,
    quantity NUMERIC(10,2) NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(14,2) NOT NULL CHECK (unit_price >= 0),
    total_refund NUMERIC(14,2) NOT NULL CHECK (total_refund >= 0),
    reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_corporate_return_items_rid ON public.corporate_return_items(return_id);

-- 10. Enable & Force Row Level Security (RLS) on all corporate tables
ALTER TABLE public.corporate_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.corporate_accounts FORCE ROW LEVEL SECURITY;

ALTER TABLE public.corporate_quotations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.corporate_quotations FORCE ROW LEVEL SECURITY;

ALTER TABLE public.corporate_quotation_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.corporate_quotation_items FORCE ROW LEVEL SECURITY;

ALTER TABLE public.corporate_invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.corporate_invoices FORCE ROW LEVEL SECURITY;

ALTER TABLE public.corporate_invoice_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.corporate_invoice_items FORCE ROW LEVEL SECURITY;

ALTER TABLE public.corporate_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.corporate_payments FORCE ROW LEVEL SECURITY;

ALTER TABLE public.corporate_returns ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.corporate_returns FORCE ROW LEVEL SECURITY;

ALTER TABLE public.corporate_return_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.corporate_return_items FORCE ROW LEVEL SECURITY;

-- 11. Define Strict RLS Policies for Multi-Branch Isolation & Staff Role Matrix
-- Corporate Accounts Policies
DROP POLICY IF EXISTS corporate_accounts_select ON public.corporate_accounts;
CREATE POLICY corporate_accounts_select ON public.corporate_accounts FOR SELECT TO authenticated
USING (
    auth.user_role() IN ('super_admin', 'general_manager', 'auditor', 'accountant')
    OR (auth.user_role() = 'branch_manager' AND corporate_accounts.branch_id = auth.branch_id())
);

DROP POLICY IF EXISTS corporate_accounts_mutation ON public.corporate_accounts;
CREATE POLICY corporate_accounts_mutation ON public.corporate_accounts FOR ALL TO authenticated
USING (
    auth.user_role() IN ('super_admin', 'general_manager', 'accountant')
    OR (auth.user_role() = 'branch_manager' AND corporate_accounts.branch_id = auth.branch_id())
)
WITH CHECK (
    auth.user_role() IN ('super_admin', 'general_manager', 'accountant')
    OR (auth.user_role() = 'branch_manager' AND corporate_accounts.branch_id = auth.branch_id())
);

-- Corporate Quotations Policies
DROP POLICY IF EXISTS corporate_quotations_select ON public.corporate_quotations;
CREATE POLICY corporate_quotations_select ON public.corporate_quotations FOR SELECT TO authenticated
USING (
    auth.user_role() IN ('super_admin', 'general_manager', 'auditor', 'accountant')
    OR (auth.user_role() = 'branch_manager' AND corporate_quotations.branch_id = auth.branch_id())
);

DROP POLICY IF EXISTS corporate_quotations_mutation ON public.corporate_quotations;
CREATE POLICY corporate_quotations_mutation ON public.corporate_quotations FOR ALL TO authenticated
USING (
    auth.user_role() IN ('super_admin', 'general_manager', 'accountant')
    OR (auth.user_role() = 'branch_manager' AND corporate_quotations.branch_id = auth.branch_id())
)
WITH CHECK (
    auth.user_role() IN ('super_admin', 'general_manager', 'accountant')
    OR (auth.user_role() = 'branch_manager' AND corporate_quotations.branch_id = auth.branch_id())
);

-- Quotation Items Policies
DROP POLICY IF EXISTS corporate_quotation_items_select ON public.corporate_quotation_items;
CREATE POLICY corporate_quotation_items_select ON public.corporate_quotation_items FOR SELECT TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.corporate_quotations q 
        WHERE q.id = corporate_quotation_items.quotation_id 
        AND (
            auth.user_role() IN ('super_admin', 'general_manager', 'auditor', 'accountant')
            OR (auth.user_role() = 'branch_manager' AND q.branch_id = auth.branch_id())
        )
    )
);

DROP POLICY IF EXISTS corporate_quotation_items_mutation ON public.corporate_quotation_items;
CREATE POLICY corporate_quotation_items_mutation ON public.corporate_quotation_items FOR ALL TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.corporate_quotations q 
        WHERE q.id = corporate_quotation_items.quotation_id 
        AND (
            auth.user_role() IN ('super_admin', 'general_manager', 'accountant')
            OR (auth.user_role() = 'branch_manager' AND q.branch_id = auth.branch_id())
        )
    )
);

-- Corporate Invoices Policies
DROP POLICY IF EXISTS corporate_invoices_select ON public.corporate_invoices;
CREATE POLICY corporate_invoices_select ON public.corporate_invoices FOR SELECT TO authenticated
USING (
    auth.user_role() IN ('super_admin', 'general_manager', 'auditor', 'accountant')
    OR (auth.user_role() = 'branch_manager' AND corporate_invoices.branch_id = auth.branch_id())
);

DROP POLICY IF EXISTS corporate_invoices_mutation ON public.corporate_invoices;
CREATE POLICY corporate_invoices_mutation ON public.corporate_invoices FOR ALL TO authenticated
USING (
    auth.user_role() IN ('super_admin', 'general_manager', 'accountant')
    OR (auth.user_role() = 'branch_manager' AND corporate_invoices.branch_id = auth.branch_id())
)
WITH CHECK (
    auth.user_role() IN ('super_admin', 'general_manager', 'accountant')
    OR (auth.user_role() = 'branch_manager' AND corporate_invoices.branch_id = auth.branch_id())
);

-- Invoice Items Policies
DROP POLICY IF EXISTS corporate_invoice_items_select ON public.corporate_invoice_items;
CREATE POLICY corporate_invoice_items_select ON public.corporate_invoice_items FOR SELECT TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.corporate_invoices i 
        WHERE i.id = corporate_invoice_items.invoice_id 
        AND (
            auth.user_role() IN ('super_admin', 'general_manager', 'auditor', 'accountant')
            OR (auth.user_role() = 'branch_manager' AND i.branch_id = auth.branch_id())
        )
    )
);

DROP POLICY IF EXISTS corporate_invoice_items_mutation ON public.corporate_invoice_items;
CREATE POLICY corporate_invoice_items_mutation ON public.corporate_invoice_items FOR ALL TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.corporate_invoices i 
        WHERE i.id = corporate_invoice_items.invoice_id 
        AND (
            auth.user_role() IN ('super_admin', 'general_manager', 'accountant')
            OR (auth.user_role() = 'branch_manager' AND i.branch_id = auth.branch_id())
        )
    )
);

-- Corporate Payments Policies
DROP POLICY IF EXISTS corporate_payments_select ON public.corporate_payments;
CREATE POLICY corporate_payments_select ON public.corporate_payments FOR SELECT TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.corporate_invoices i 
        WHERE i.id = corporate_payments.invoice_id 
        AND (
            auth.user_role() IN ('super_admin', 'general_manager', 'auditor', 'accountant')
            OR (auth.user_role() = 'branch_manager' AND i.branch_id = auth.branch_id())
        )
    )
);

DROP POLICY IF EXISTS corporate_payments_mutation ON public.corporate_payments;
CREATE POLICY corporate_payments_mutation ON public.corporate_payments FOR ALL TO authenticated
USING (
    auth.user_role() IN ('super_admin', 'general_manager', 'accountant')
);

-- Corporate Returns Policies
DROP POLICY IF EXISTS corporate_returns_select ON public.corporate_returns;
CREATE POLICY corporate_returns_select ON public.corporate_returns FOR SELECT TO authenticated
USING (
    auth.user_role() IN ('super_admin', 'general_manager', 'auditor', 'accountant')
    OR (auth.user_role() = 'branch_manager' AND corporate_returns.branch_id = auth.branch_id())
);

DROP POLICY IF EXISTS corporate_returns_mutation ON public.corporate_returns;
CREATE POLICY corporate_returns_mutation ON public.corporate_returns FOR ALL TO authenticated
USING (
    auth.user_role() IN ('super_admin', 'general_manager', 'accountant')
    OR (auth.user_role() = 'branch_manager' AND corporate_returns.branch_id = auth.branch_id())
);

-- Return Items Policies
DROP POLICY IF EXISTS corporate_return_items_select ON public.corporate_return_items;
CREATE POLICY corporate_return_items_select ON public.corporate_return_items FOR SELECT TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.corporate_returns r 
        WHERE r.id = corporate_return_items.return_id 
        AND (
            auth.user_role() IN ('super_admin', 'general_manager', 'auditor', 'accountant')
            OR (auth.user_role() = 'branch_manager' AND r.branch_id = auth.branch_id())
        )
    )
);

DROP POLICY IF EXISTS corporate_return_items_mutation ON public.corporate_return_items;
CREATE POLICY corporate_return_items_mutation ON public.corporate_return_items FOR ALL TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.corporate_returns r 
        WHERE r.id = corporate_return_items.return_id 
        AND (
            auth.user_role() IN ('super_admin', 'general_manager', 'accountant')
            OR (auth.user_role() = 'branch_manager' AND r.branch_id = auth.branch_id())
        )
    )
);

-- 12. Update record_inventory_movement_atomic Permissions Guard
-- Allow legitimate sales/returns from orders and corporate sales without 42501 error
CREATE OR REPLACE FUNCTION public.record_inventory_movement_atomic(
    p_branch_id text,
    p_product_id uuid,
    p_movement_type text,
    p_qty_change numeric,
    p_qty_reserved_change numeric DEFAULT 0,
    p_ref_type text DEFAULT 'manual',
    p_ref_id text DEFAULT 'MANUAL-ADJ',
    p_actor_id text DEFAULT NULL,
    p_actor_name text DEFAULT 'أمين المخزون',
    p_actor_role text DEFAULT 'staff',
    p_notes text DEFAULT ''
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_curr_on_hand numeric(12,2);
    v_curr_reserved numeric(12,2);
    v_new_on_hand numeric(12,2);
    v_new_reserved numeric(12,2);
    v_mov_number text;
    v_caller_role text;
    v_caller_branch text;
    v_result jsonb;
BEGIN
    v_caller_role := auth.user_role();
    v_caller_branch := auth.branch_id();

    -- Role and Branch Permissions Guard
    IF v_caller_role = 'cashier' THEN
        IF p_movement_type NOT IN ('sale', 'return', 'release_reservation') THEN
            RAISE EXCEPTION '42501: Cashiers are strictly limited to recording sales, returns and release reservations';
        END IF;
        IF v_caller_branch IS NOT NULL AND v_caller_branch <> p_branch_id THEN
            RAISE EXCEPTION '42501: Cashier is unauthorized to operate on foreign branch %', p_branch_id;
        END IF;
    ELSIF v_caller_role = 'branch_manager' THEN
        IF v_caller_branch IS NOT NULL AND v_caller_branch <> p_branch_id AND NOT auth.is_super_admin() THEN
            RAISE EXCEPTION '42501: Branch manager is unauthorized to operate on foreign branch %', p_branch_id;
        END IF;
    ELSIF v_caller_role IN ('anon', 'customer', 'courier', 'driver') THEN
        IF p_ref_type = 'order' AND p_movement_type IN ('sale', 'release_reservation') THEN
            NULL;
        ELSIF p_ref_type = 'return' AND p_movement_type IN ('return', 'damaged') THEN
            NULL;
        ELSIF p_ref_type = 'transfer' AND p_movement_type IN ('transfer_out', 'transfer_in') THEN
            NULL;
        ELSIF p_ref_type = 'audit' AND p_movement_type = 'audit_reconciliation' THEN
            NULL;
        ELSIF p_ref_type = 'corporate_sale' AND p_movement_type IN ('sale', 'return') THEN
            NULL;
        ELSIF NOT auth.is_staff() AND NOT auth.is_super_admin() THEN
            RAISE EXCEPTION '42501: Unauthorized access to inventory movement engine';
        END IF;
    END IF;

    -- Ensure product exists
    IF NOT EXISTS (SELECT 1 FROM public.products WHERE id = p_product_id) THEN
        RAISE EXCEPTION 'PRODUCT_NOT_FOUND: Product with id % does not exist', p_product_id;
    END IF;

    -- Ensure branch exists
    IF NOT EXISTS (SELECT 1 FROM public.branches WHERE id = p_branch_id) THEN
        RAISE EXCEPTION 'BRANCH_NOT_FOUND: Branch with id % does not exist', p_branch_id;
    END IF;

    -- Row Locking FOR UPDATE to prevent race conditions & concurrent overselling
    SELECT quantity_on_hand, quantity_reserved
    INTO v_curr_on_hand, v_curr_reserved
    FROM public.branch_inventory
    WHERE branch_id = p_branch_id AND product_id = p_product_id
    FOR UPDATE;

    IF NOT FOUND THEN
        -- Auto-provision row with products stock_quantity if present
        INSERT INTO public.branch_inventory (branch_id, product_id, quantity_on_hand, quantity_reserved)
        VALUES (p_branch_id, p_product_id, COALESCE((SELECT stock_quantity FROM public.products WHERE id = p_product_id), 0), 0)
        RETURNING quantity_on_hand, quantity_reserved INTO v_curr_on_hand, v_curr_reserved;

        -- Re-lock
        SELECT quantity_on_hand, quantity_reserved
        INTO v_curr_on_hand, v_curr_reserved
        FROM public.branch_inventory
        WHERE branch_id = p_branch_id AND product_id = p_product_id
        FOR UPDATE;
    END IF;

    -- Prevent Negative Balances
    v_new_on_hand := v_curr_on_hand + p_qty_change;
    v_new_reserved := v_curr_reserved + COALESCE(p_qty_reserved_change, 0);

    IF v_new_on_hand < 0 THEN
        RAISE EXCEPTION 'INSUFFICIENT_STOCK: Branch % has only % units of product %, requested change %',
            p_branch_id, v_curr_on_hand, p_product_id, p_qty_change;
    END IF;

    IF v_new_reserved < 0 THEN
        v_new_reserved := 0;
    END IF;

    -- Update Branch Balance
    UPDATE public.branch_inventory
    SET quantity_on_hand = v_new_on_hand,
        quantity_reserved = v_new_reserved,
        updated_at = timezone('utc'::text, now())
    WHERE branch_id = p_branch_id AND product_id = p_product_id;

    -- Update Global Products Catalog Balance
    UPDATE public.products
    SET stock_quantity = (SELECT COALESCE(SUM(quantity_on_hand), 0)::int FROM public.branch_inventory WHERE product_id = p_product_id),
        sales_count = CASE WHEN p_movement_type = 'sale' THEN COALESCE(sales_count, 0) + GREATEST(0, (-p_qty_change)::int) ELSE sales_count END,
        updated_at = timezone('utc'::text, now())
    WHERE id = p_product_id;

    -- Generate Unique Movement Number
    v_mov_number := 'MOV-' || to_char(now(), 'YYYYMMDD-HH24MISS') || '-' || substr(md5(random()::text), 1, 6);

    -- Insert movement record
    INSERT INTO public.inventory_movements (
        movement_number, branch_id, product_id, movement_type,
        quantity_change, quantity_reserved_change,
        resulting_on_hand, resulting_reserved,
        reference_type, reference_id,
        actor_id, actor_name, actor_role,
        notes
    ) VALUES (
        v_mov_number, p_branch_id, p_product_id, p_movement_type,
        p_qty_change, COALESCE(p_qty_reserved_change, 0),
        v_new_on_hand, v_new_reserved,
        p_ref_type, p_ref_id,
        COALESCE(p_actor_id, auth.user_id()), p_actor_name, p_actor_role,
        p_notes
    );

    v_result := jsonb_build_object(
        'success', true,
        'movement_number', v_mov_number,
        'branch_id', p_branch_id,
        'product_id', p_product_id,
        'previous_on_hand', v_curr_on_hand,
        'new_on_hand', v_new_on_hand,
        'quantity_change', p_qty_change,
        'movement_type', p_movement_type
    );

    RETURN v_result;
END;
$$;

-- 13. High-Performance Atomic RPC: create_corporate_invoice_with_stock_deduction
-- Verifies credit limits, locks and decrements product inventory, inserts invoice & items, updates balance
CREATE OR REPLACE FUNCTION public.create_corporate_invoice_with_stock_deduction(p_payload JSONB)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_account_id UUID;
    v_branch_id VARCHAR(64);
    v_quotation_id UUID;
    v_items JSONB;
    v_item JSONB;
    v_notes TEXT;
    v_created_by TEXT;
    
    v_account public.corporate_accounts%ROWTYPE;
    v_prod public.products%ROWTYPE;
    
    v_subtotal NUMERIC(14,2) := 0.00;
    v_discount_amount NUMERIC(14,2) := 0.00;
    v_tax_amount NUMERIC(14,2) := 0.00;
    v_total_amount NUMERIC(14,2) := 0.00;
    
    v_item_qty NUMERIC(10,2);
    v_item_price NUMERIC(14,2);
    v_item_discount NUMERIC(5,2);
    v_item_final_price NUMERIC(14,2);
    v_item_total NUMERIC(14,2);
    
    v_invoice_id UUID;
    v_invoice_number TEXT;
    v_due_date DATE;
    v_due_days INT := 30;
    v_seq_num INT;
BEGIN
    -- Extract payload arguments
    v_account_id := (p_payload->>'corporate_account_id')::UUID;
    v_branch_id := p_payload->>'branch_id';
    IF p_payload ? 'quotation_id' AND p_payload->>'quotation_id' IS NOT NULL AND p_payload->>'quotation_id' <> '' THEN
        v_quotation_id := (p_payload->>'quotation_id')::UUID;
    END IF;
    v_items := p_payload->'items';
    v_notes := p_payload->>'notes';
    v_created_by := COALESCE(p_payload->>'created_by', auth.user_id(), 'مسؤول مبيعات الشركات');

    -- Validate Corporate Account
    SELECT * INTO v_account 
    FROM public.corporate_accounts 
    WHERE id = v_account_id 
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'ACCOUNT_NOT_FOUND: Corporate account % does not exist', v_account_id;
    END IF;

    IF v_account.status NOT IN ('active') THEN
        RAISE EXCEPTION 'ACCOUNT_INACTIVE: Corporate account % is %', v_account.company_name, v_account.status;
    END IF;

    IF v_branch_id IS NULL OR v_branch_id = '' THEN
        v_branch_id := v_account.branch_id;
    END IF;

    -- Validate Items array
    IF v_items IS NULL OR jsonb_array_length(v_items) = 0 THEN
        RAISE EXCEPTION 'EMPTY_ITEMS: Corporate invoice must contain at least one item';
    END IF;

    -- Calculate Totals & Validate Stock availability with Row Locks
    FOR v_item IN SELECT * FROM jsonb_array_elements(v_items)
    LOOP
        v_item_qty := COALESCE((v_item->>'quantity')::NUMERIC, 0);
        v_item_price := COALESCE((v_item->>'unit_price')::NUMERIC, 0);
        v_item_discount := COALESCE((v_item->>'discount_percent')::NUMERIC, 0);

        IF v_item_qty <= 0 THEN
            RAISE EXCEPTION 'INVALID_QUANTITY: Item quantity must be greater than zero';
        END IF;

        -- Lock product row
        SELECT * INTO v_prod 
        FROM public.products 
        WHERE id = (v_item->>'product_id')::UUID
        FOR UPDATE;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'PRODUCT_NOT_FOUND: Product % does not exist in catalog', v_item->>'product_id';
        END IF;

        v_item_final_price := ROUND(v_item_price * (1 - (v_item_discount / 100.0)), 2);
        v_item_total := ROUND(v_item_final_price * v_item_qty, 2);

        v_subtotal := v_subtotal + ROUND(v_item_price * v_item_qty, 2);
        v_discount_amount := v_discount_amount + (ROUND(v_item_price * v_item_qty, 2) - v_item_total);
    END LOOP;

    -- Compute VAT (15% Tax) and Grand Total
    v_tax_amount := ROUND((v_subtotal - v_discount_amount) * 0.15, 2);
    v_total_amount := (v_subtotal - v_discount_amount) + v_tax_amount;

    -- Credit Limit Enforcement Guard
    IF v_account.payment_terms <> 'Cash' THEN
        IF (v_account.current_balance + v_total_amount) > v_account.monthly_credit_limit THEN
            RAISE EXCEPTION 'CREDIT_LIMIT_EXCEEDED: Current balance (% ل.س) + Invoice (% ل.س) exceeds monthly credit limit (% ل.س)',
                v_account.current_balance, v_total_amount, v_account.monthly_credit_limit;
        END IF;
    END IF;

    -- Determine Due Date based on Payment Terms
    IF v_account.payment_terms = 'Net-15' THEN
        v_due_days := 15;
    ELSIF v_account.payment_terms = 'Net-60' THEN
        v_due_days := 60;
    ELSIF v_account.payment_terms = 'Cash' THEN
        v_due_days := 0;
    ELSE
        v_due_days := 30;
    END IF;
    v_due_date := CURRENT_DATE + (v_due_days || ' days')::INTERVAL;

    -- Generate Invoice Number
    SELECT COUNT(*) + 1 INTO v_seq_num FROM public.corporate_invoices;
    v_invoice_number := 'INV-B2B-' || to_char(CURRENT_DATE, 'YYYYMM') || '-' || lpad(v_seq_num::TEXT, 4, '0');
    v_invoice_id := gen_random_uuid();

    -- Insert Invoice Record
    INSERT INTO public.corporate_invoices (
        id,
        invoice_number,
        quotation_id,
        corporate_account_id,
        branch_id,
        subtotal,
        discount_amount,
        tax_amount,
        total_amount,
        paid_amount,
        remaining_amount,
        payment_status,
        due_date,
        notes,
        created_by
    ) VALUES (
        v_invoice_id,
        v_invoice_number,
        v_quotation_id,
        v_account_id,
        v_branch_id,
        v_subtotal,
        v_discount_amount,
        v_tax_amount,
        v_total_amount,
        0.00,
        v_total_amount,
        'unpaid',
        v_due_date,
        v_notes,
        v_created_by
    );

    -- Insert Items and Decrement Inventory via atomic movements
    FOR v_item IN SELECT * FROM jsonb_array_elements(v_items)
    LOOP
        v_item_qty := (v_item->>'quantity')::NUMERIC;
        v_item_price := (v_item->>'unit_price')::NUMERIC;
        v_item_discount := COALESCE((v_item->>'discount_percent')::NUMERIC, 0);
        v_item_final_price := ROUND(v_item_price * (1 - (v_item_discount / 100.0)), 2);
        v_item_total := ROUND(v_item_final_price * v_item_qty, 2);

        INSERT INTO public.corporate_invoice_items (
            invoice_id,
            product_id,
            quantity,
            unit_price,
            discount_percent,
            final_unit_price,
            total_price
        ) VALUES (
            v_invoice_id,
            (v_item->>'product_id')::UUID,
            v_item_qty,
            v_item_price,
            v_item_discount,
            v_item_final_price,
            v_item_total
        );

        -- Atomic stock reduction via record_inventory_movement_atomic
        PERFORM public.record_inventory_movement_atomic(
            v_branch_id,
            (v_item->>'product_id')::UUID,
            'sale',
            -v_item_qty,
            0,
            'order',
            v_invoice_number,
            v_created_by,
            'مبيعات شركات B2B',
            'b2b_sales',
            'صرف بضاعة فاتورة شركات رقم ' || v_invoice_number
        );
    END LOOP;

    -- Update Corporate Account Outstanding Balance
    UPDATE public.corporate_accounts
    SET current_balance = current_balance + v_total_amount,
        updated_at = NOW()
    WHERE id = v_account_id;

    -- If originated from quotation, mark quotation as converted
    IF v_quotation_id IS NOT NULL THEN
        UPDATE public.corporate_quotations
        SET status = 'converted',
            updated_at = NOW()
        WHERE id = v_quotation_id;
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'invoice_id', v_invoice_id,
        'invoice_number', v_invoice_number,
        'corporate_account_id', v_account_id,
        'company_name', v_account.company_name,
        'subtotal', v_subtotal,
        'discount_amount', v_discount_amount,
        'tax_amount', v_tax_amount,
        'total_amount', v_total_amount,
        'due_date', v_due_date,
        'payment_status', 'unpaid',
        'items_count', jsonb_array_length(v_items)
    );
END;
$$;

-- 14. High-Performance Atomic RPC: record_corporate_payment
-- Records payment transaction, decrements remaining invoice debt, marks invoice paid, and credits account balance
CREATE OR REPLACE FUNCTION public.record_corporate_payment(p_payload JSONB)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_invoice_id UUID;
    v_payment_amount NUMERIC(14,2);
    v_payment_method TEXT;
    v_reference_number TEXT;
    v_notes TEXT;
    v_received_by TEXT;
    
    v_invoice public.corporate_invoices%ROWTYPE;
    v_payment_id UUID;
    v_payment_number TEXT;
    v_new_paid NUMERIC(14,2);
    v_new_remaining NUMERIC(14,2);
    v_new_status TEXT;
    v_seq_num INT;
BEGIN
    v_invoice_id := (p_payload->>'invoice_id')::UUID;
    v_payment_amount := (p_payload->>'amount')::NUMERIC;
    v_payment_method := COALESCE(p_payload->>'payment_method', 'bank_transfer');
    v_reference_number := COALESCE(p_payload->>'reference_number', 'REF-' || to_char(NOW(), 'YYYYMMDD-HH24MI'));
    v_notes := p_payload->>'notes';
    v_received_by := COALESCE(p_payload->>'received_by', auth.user_id(), 'محاسب الشركات');

    IF v_payment_amount <= 0 THEN
        RAISE EXCEPTION 'INVALID_AMOUNT: Payment amount must be greater than zero';
    END IF;

    -- Lock and retrieve invoice
    SELECT * INTO v_invoice
    FROM public.corporate_invoices
    WHERE id = v_invoice_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'INVOICE_NOT_FOUND: Corporate invoice % does not exist', v_invoice_id;
    END IF;

    IF v_payment_amount > v_invoice.remaining_amount THEN
        RAISE EXCEPTION 'OVERPAYMENT_PROHIBITED: Payment amount (% ل.س) exceeds invoice remaining balance (% ل.س)',
            v_payment_amount, v_invoice.remaining_amount;
    END IF;

    v_new_paid := v_invoice.paid_amount + v_payment_amount;
    v_new_remaining := v_invoice.remaining_amount - v_payment_amount;
    v_new_status := CASE WHEN v_new_remaining <= 0.001 THEN 'paid' ELSE 'partially_paid' END;

    -- Generate payment number
    SELECT COUNT(*) + 1 INTO v_seq_num FROM public.corporate_payments;
    v_payment_number := 'PAY-B2B-' || to_char(CURRENT_DATE, 'YYYYMM') || '-' || lpad(v_seq_num::TEXT, 4, '0');
    v_payment_id := gen_random_uuid();

    -- Insert payment ledger record
    INSERT INTO public.corporate_payments (
        id,
        payment_number,
        invoice_id,
        corporate_account_id,
        amount,
        payment_method,
        reference_number,
        payment_date,
        notes,
        received_by
    ) VALUES (
        v_payment_id,
        v_payment_number,
        v_invoice_id,
        v_invoice.corporate_account_id,
        v_payment_amount,
        v_payment_method,
        v_reference_number,
        CURRENT_DATE,
        v_notes,
        v_received_by
    );

    -- Update invoice financial state
    UPDATE public.corporate_invoices
    SET paid_amount = v_new_paid,
        remaining_amount = v_new_remaining,
        payment_status = v_new_status,
        updated_at = NOW()
    WHERE id = v_invoice_id;

    -- Decrement corporate account balance (debt relief)
    UPDATE public.corporate_accounts
    SET current_balance = GREATEST(0.00, current_balance - v_payment_amount),
        updated_at = NOW()
    WHERE id = v_invoice.corporate_account_id;

    RETURN jsonb_build_object(
        'success', true,
        'payment_id', v_payment_id,
        'payment_number', v_payment_number,
        'invoice_id', v_invoice_id,
        'amount', v_payment_amount,
        'remaining_amount', v_new_remaining,
        'payment_status', v_new_status
    );
END;
$$;

-- 15. High-Performance Atomic RPC: process_corporate_return_with_stock_restoration
-- Approves/completes goods return, restores product catalog stock, adjusts invoice & customer debt
CREATE OR REPLACE FUNCTION public.process_corporate_return_with_stock_restoration(p_payload JSONB)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_return_id UUID;
    v_approved_by TEXT;
    v_return public.corporate_returns%ROWTYPE;
    v_item RECORD;
    v_invoice public.corporate_invoices%ROWTYPE;
    v_restored_count INT := 0;
BEGIN
    v_return_id := (p_payload->>'return_id')::UUID;
    v_approved_by := COALESCE(p_payload->>'approved_by', auth.user_id(), 'مدير مراقبة الجودة والمخزون');

    -- Lock return record
    SELECT * INTO v_return
    FROM public.corporate_returns
    WHERE id = v_return_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'RETURN_NOT_FOUND: Corporate return % does not exist', v_return_id;
    END IF;

    IF v_return.status = 'completed' THEN
        RAISE EXCEPTION 'ALREADY_COMPLETED: Return % has already been processed and inventory restored', v_return.return_number;
    END IF;

    -- Restore stock for each returned item via record_inventory_movement_atomic
    FOR v_item IN 
        SELECT product_id, quantity, unit_price, total_refund 
        FROM public.corporate_return_items 
        WHERE return_id = v_return_id
    LOOP
        PERFORM public.record_inventory_movement_atomic(
            v_return.branch_id,
            v_item.product_id,
            'return',
            v_item.quantity,
            0,
            'return',
            v_return.return_number,
            v_approved_by,
            'إرجاع مبيعات شركات B2B',
            'b2b_returns',
            'استرجاع بضاعة إشعار دائن رقم ' || v_return.return_number
        );
        
        v_restored_count := v_restored_count + 1;
    END LOOP;

    -- Adjust invoice financials
    SELECT * INTO v_invoice 
    FROM public.corporate_invoices 
    WHERE id = v_return.invoice_id 
    FOR UPDATE;

    IF FOUND THEN
        UPDATE public.corporate_invoices
        SET total_amount = GREATEST(0.00, total_amount - v_return.total_refund_amount),
            remaining_amount = GREATEST(0.00, remaining_amount - v_return.total_refund_amount),
            payment_status = CASE 
                WHEN GREATEST(0.00, remaining_amount - v_return.total_refund_amount) <= 0.001 THEN 'paid'
                ELSE payment_status 
            END,
            updated_at = NOW()
        WHERE id = v_return.invoice_id;
    END IF;

    -- Adjust corporate account balance
    UPDATE public.corporate_accounts
    SET current_balance = GREATEST(0.00, current_balance - v_return.total_refund_amount),
        updated_at = NOW()
    WHERE id = v_return.corporate_account_id;

    -- Mark return completed
    UPDATE public.corporate_returns
    SET status = 'completed',
        approved_by = v_approved_by,
        approved_at = NOW(),
        updated_at = NOW()
    WHERE id = v_return_id;

    RETURN jsonb_build_object(
        'success', true,
        'return_id', v_return_id,
        'return_number', v_return.return_number,
        'restored_items_count', v_restored_count,
        'total_refund_amount', v_return.total_refund_amount,
        'status', 'completed'
    );
END;
$$;

-- 16. High-Performance Atomic RPC: approve_or_reject_corporate_quotation
CREATE OR REPLACE FUNCTION public.approve_or_reject_corporate_quotation(p_payload JSONB)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_quotation_id UUID;
    v_action TEXT;
    v_staff_name TEXT;
    v_notes TEXT;
    v_reason TEXT;
    v_quote public.corporate_quotations%ROWTYPE;
BEGIN
    v_quotation_id := (p_payload->>'quotation_id')::UUID;
    v_action := lower(p_payload->>'action');
    v_staff_name := COALESCE(p_payload->>'staff_name', auth.user_id(), 'المدير المالي المعتمد');
    v_notes := p_payload->>'notes';
    v_reason := p_payload->>'reason';

    IF v_action NOT IN ('approve', 'reject') THEN
        RAISE EXCEPTION 'INVALID_ACTION: Action must be either "approve" or "reject"';
    END IF;

    SELECT * INTO v_quote
    FROM public.corporate_quotations
    WHERE id = v_quotation_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'QUOTATION_NOT_FOUND: Quotation % does not exist', v_quotation_id;
    END IF;

    IF v_action = 'approve' THEN
        UPDATE public.corporate_quotations
        SET status = 'approved',
            approved_by = v_staff_name,
            approved_at = NOW(),
            notes = COALESCE(v_notes, notes),
            updated_at = NOW()
        WHERE id = v_quotation_id;
    ELSE
        UPDATE public.corporate_quotations
        SET status = 'rejected',
            rejection_reason = COALESCE(v_reason, 'تم رفض عرض السعر بناءً على مراجعة شروط التوريد'),
            updated_at = NOW()
        WHERE id = v_quotation_id;
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'quotation_id', v_quotation_id,
        'quotation_number', v_quote.quotation_number,
        'status', CASE WHEN v_action = 'approve' THEN 'approved' ELSE 'rejected' END,
        'reviewed_by', v_staff_name
    );
END;
$$;

-- 17. Grant Schema & Table Access to authenticated & anon roles
GRANT USAGE ON SCHEMA public TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
-- For anon, only permit specific catalog reads and guest RPC execution
GRANT EXECUTE ON FUNCTION public.create_corporate_invoice_with_stock_deduction(JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION public.record_corporate_payment(JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION public.process_corporate_return_with_stock_restoration(JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION public.approve_or_reject_corporate_quotation(JSONB) TO authenticated;

-- 18. Seed Initial Realistic Corporate Accounts & Operational History
DO $$
DECLARE
    v_dam_branch VARCHAR(64) := 'b-dam-01';
    v_ruh_branch VARCHAR(64) := 'b-ruh-01';
    v_jed_branch VARCHAR(64) := 'b-jed-01';
    v_dmm_branch VARCHAR(64) := 'b-dmm-01';
    
    v_acc1 UUID := 'b2ba0000-0000-0000-0000-000000000001';
    v_acc2 UUID := 'b2ba0000-0000-0000-0000-000000000002';
    v_acc3 UUID := 'b2ba0000-0000-0000-0000-000000000003';
    v_acc4 UUID := 'b2ba0000-0000-0000-0000-000000000004';
    v_acc5 UUID := 'b2ba0000-0000-0000-0000-000000000005';
BEGIN
    -- Verify branches exist
    IF NOT EXISTS (SELECT 1 FROM public.branches WHERE id = v_dam_branch) THEN
        v_dam_branch := (SELECT id FROM public.branches LIMIT 1);
    END IF;

    -- Account 1: Syrian Telecom & Technology Corp (Damascus)
    INSERT INTO public.corporate_accounts (
        id, company_name, cr_number, vat_number, contact_person, phone, email,
        city, address, branch_id, monthly_credit_limit, current_balance,
        payment_terms, status, recurring_schedule, items_summary, notes
    ) VALUES (
        v_acc1,
        'الشركة السورية للاتصالات والتقنية (سيريتل - المقر العام)',
        '1010150261', '300000000000003', 'م. فهد السديري (مدير الخدمات والإعاشة)',
        '+963 93 112 3456', 'procurement@syriatel.sy',
        'دمشق', 'المزة - أوتوستراد المزة بجوار برج دمشق', v_dam_branch,
        15000000.00, 3200000.00, 'Net-30', 'active',
        'كل أحد 08:00 صباحاً (شحنة أسبوعية)',
        'بن اسبريسو فاخر، مياه معبأة، سلال فواكه مكتبية، معقمات ومحارم',
        'حساب استراتيجي - خصم تجاري معتمد 15%'
    ) ON CONFLICT (cr_number) DO NOTHING;

    -- Account 2: Cham Holding & Financial Services (Damascus)
    INSERT INTO public.corporate_accounts (
        id, company_name, cr_number, vat_number, contact_person, phone, email,
        city, address, branch_id, monthly_credit_limit, current_balance,
        payment_terms, status, recurring_schedule, items_summary, notes
    ) VALUES (
        v_acc2,
        'شركة شام القابضة للخدمات والاستثمار',
        '1010000096', '300000000000005', 'أ. ريم الشمري (المشتريات التشغيلية)',
        '+963 94 987 6543', 'purchases@chamholding.sy',
        'دمشق', 'كفرسوسة - مجمع الفردوس التجاري', v_dam_branch,
        10000000.00, 1850000.00, 'Net-30', 'active',
        'كل ثلاثاء 09:00 صباحاً',
        'شاي سيلاني فاخر، قهوة الديب، سناكات ومكسرات صحية للموظفين',
        'سداد منتظم عبر المصرف التجاري السوري'
    ) ON CONFLICT (cr_number) DO NOTHING;

    -- Account 3: Al-Aqeelah Takaful Insurance (Riyadh Branch)
    INSERT INTO public.corporate_accounts (
        id, company_name, cr_number, vat_number, contact_person, phone, email,
        city, address, branch_id, monthly_credit_limit, current_balance,
        payment_terms, status, recurring_schedule, items_summary, notes
    ) VALUES (
        v_acc3,
        'شركة العقيلة للتأمين التكافلي وإدارة المخاطر',
        '1010482910', '310928192000003', 'أ. ياسر العتيبي (الخدمات المشتركة)',
        '+966 54 332 1199', 'facilities@alaqeelah.com',
        'الرياض', 'طريق الملك فهد - حي العليا', v_ruh_branch,
        8000000.00, 0.00, 'Net-15', 'active',
        'كل أسبوعين صباح الإثنين',
        'مياه شرب معبأة، كبسولات قهوة، أكواب ورقية صديقة للبيئة',
        'عقد توريد مستمر لمقر الإدارة العامة'
    ) ON CONFLICT (cr_number) DO NOTHING;

    -- Account 4: Arab Medical Logistics & Hospital Restock (Jeddah)
    INSERT INTO public.corporate_accounts (
        id, company_name, cr_number, vat_number, contact_person, phone, email,
        city, address, branch_id, monthly_credit_limit, current_balance,
        payment_terms, status, recurring_schedule, items_summary, notes
    ) VALUES (
        v_acc4,
        'مجموعة الشفاء الطبية ومستودعات التموين',
        '1010928172', '310948291000003', 'د. طارق الحلبي (سلاسل الإمداد)',
        '+966 56 441 8822', 'supply@alshifa-med.com',
        'جدة', 'الكورنيش - طريق الأندلس', v_jed_branch,
        12000000.00, 4200000.00, 'Net-30', 'active',
        'الأحد والأربعاء مرتين أسبوعياً',
        'تموين كافتيريا الأطباء والموظفين، عصائر طبيعية، حليب وألبان طازجة',
        'تموين إعاشة متكامل لمستشفيات المجموعة'
    ) ON CONFLICT (cr_number) DO NOTHING;

    -- Account 5: Al-Badia Industrial & Construction Group (Dammam)
    INSERT INTO public.corporate_accounts (
        id, company_name, cr_number, vat_number, contact_person, phone, email,
        city, address, branch_id, monthly_credit_limit, current_balance,
        payment_terms, status, recurring_schedule, items_summary, notes
    ) VALUES (
        v_acc5,
        'مجموعة البادية للصناعات الإنشائية والوجبات الجاهزة',
        '2050001928', '300019281000003', 'م. نبيل كنعان (إدارة المشاريع)',
        '+966 53 771 9900', 'canteen@albadia-group.com',
        'الدمام', 'المنطقة الصناعية الأولى - شارع الميناء', v_dmm_branch,
        6000000.00, 6150000.00, 'Net-30', 'overdue',
        'أول يوم عمل من كل شهر',
        'تموين سكن العمال والمستودعات: أرز، زيوت طهي، سكر، معلبات غذائية',
        'تجاوز الحد الائتماني بمقدار 150,000 ل.س - يمنع إصدار فواتير آجلة جديدة قبل السداد'
    ) ON CONFLICT (cr_number) DO NOTHING;
END $$;
