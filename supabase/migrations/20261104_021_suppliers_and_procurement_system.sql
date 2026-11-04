-- ==============================================================================
-- Aldeeb Mall & Hypermarket - Migration 019: Suppliers & Procurement System
-- ==============================================================================
-- 1. Sequences for Server-Generated Unique Monotonic Identifiers
-- 2. Tables: suppliers, purchase_orders, purchase_order_items, inventory_transactions, supplier_payments
-- 3. Product Table Alterations (cost_price, is_draft, status)
-- 4. Atomic Stored Procedures / RPCs:
--    - create_purchase_order
--    - receive_purchase_order_items
--    - record_supplier_payment
--    - cancel_purchase_order
--    - approve_draft_product
-- 5. Row Level Security & RBAC Enforcement
-- 6. Initial Certified Suppliers Seed
-- ==============================================================================

-- 1. Sequences
CREATE SEQUENCE IF NOT EXISTS public.po_number_seq START WITH 1001 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS public.inv_trx_seq START WITH 1001 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS public.sup_pay_seq START WITH 1001 INCREMENT BY 1;

-- 2. Enhance products table with cost and lifecycle tracking
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS cost_price NUMERIC(10,2) DEFAULT NULL;
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS is_draft BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'published';

-- 3. Suppliers Table
CREATE TABLE IF NOT EXISTS public.suppliers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name_ar TEXT NOT NULL,
    name_en TEXT,
    contact_person TEXT,
    phone TEXT,
    email TEXT,
    address TEXT,
    commercial_reg TEXT,
    tax_number TEXT,
    lead_time_days INTEGER NOT NULL DEFAULT 1,
    payment_terms TEXT NOT NULL DEFAULT 'آجل 30 يوماً',
    active_products_count INTEGER NOT NULL DEFAULT 0,
    balance NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'under_review', 'inactive')),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_suppliers_status ON public.suppliers(status);
CREATE INDEX IF NOT EXISTS idx_suppliers_name_ar ON public.suppliers(name_ar);

-- 4. Purchase Orders Table
CREATE TABLE IF NOT EXISTS public.purchase_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    po_number TEXT UNIQUE NOT NULL,
    supplier_id UUID REFERENCES public.suppliers(id) ON DELETE RESTRICT,
    supplier_name TEXT NOT NULL,
    branch_id VARCHAR(64) REFERENCES public.branches(id) ON DELETE RESTRICT,
    status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'sent', 'partially_received', 'received', 'cancelled')),
    payment_status TEXT NOT NULL DEFAULT 'unpaid' CHECK (payment_status IN ('unpaid', 'partial', 'paid')),
    total_items NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    total_cost NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    paid_amount NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    order_date DATE NOT NULL DEFAULT CURRENT_DATE,
    expected_arrival TEXT,
    notes TEXT,
    cancellation_reason TEXT,
    created_by TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_purchase_orders_supplier ON public.purchase_orders(supplier_id);
CREATE INDEX IF NOT EXISTS idx_purchase_orders_branch ON public.purchase_orders(branch_id);
CREATE INDEX IF NOT EXISTS idx_purchase_orders_status ON public.purchase_orders(status);
CREATE INDEX IF NOT EXISTS idx_purchase_orders_po_num ON public.purchase_orders(po_number);

-- 5. Purchase Order Items Table
CREATE TABLE IF NOT EXISTS public.purchase_order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    purchase_order_id UUID NOT NULL REFERENCES public.purchase_orders(id) ON DELETE CASCADE,
    product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
    name_ar TEXT NOT NULL,
    barcode TEXT,
    unit TEXT NOT NULL DEFAULT 'piece',
    quantity_ordered NUMERIC(12,2) NOT NULL CHECK (quantity_ordered > 0),
    quantity_received NUMERIC(12,2) NOT NULL DEFAULT 0.00 CHECK (quantity_received >= 0),
    quantity_damaged NUMERIC(12,2) NOT NULL DEFAULT 0.00 CHECK (quantity_damaged >= 0),
    unit_cost NUMERIC(15,2) NOT NULL CHECK (unit_cost >= 0),
    total_cost NUMERIC(15,2) NOT NULL CHECK (total_cost >= 0),
    is_new_draft_product BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_po_items_po_id ON public.purchase_order_items(purchase_order_id);
CREATE INDEX IF NOT EXISTS idx_po_items_product_id ON public.purchase_order_items(product_id);

-- 6. Inventory Transactions (Stock Movement Ledger)
CREATE TABLE IF NOT EXISTS public.inventory_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_number TEXT UNIQUE NOT NULL,
    branch_id VARCHAR(64) NOT NULL REFERENCES public.branches(id) ON DELETE RESTRICT,
    product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
    movement_type TEXT NOT NULL CHECK (movement_type IN ('purchase_receipt', 'damaged_loss', 'sales_deduction', 'inventory_transfer', 'inventory_adjustment')),
    reference_type TEXT NOT NULL CHECK (reference_type IN ('purchase_order', 'order_sale', 'transfer', 'manual_audit')),
    reference_id TEXT NOT NULL,
    quantity_change NUMERIC(12,2) NOT NULL,
    unit_cost NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    total_value NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    balance_after NUMERIC(12,2),
    performed_by TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_inv_trx_branch ON public.inventory_transactions(branch_id);
CREATE INDEX IF NOT EXISTS idx_inv_trx_product ON public.inventory_transactions(product_id);
CREATE INDEX IF NOT EXISTS idx_inv_trx_type ON public.inventory_transactions(movement_type);
CREATE INDEX IF NOT EXISTS idx_inv_trx_ref ON public.inventory_transactions(reference_type, reference_id);

-- 7. Supplier Payments Table
CREATE TABLE IF NOT EXISTS public.supplier_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    payment_number TEXT UNIQUE NOT NULL,
    purchase_order_id UUID NOT NULL REFERENCES public.purchase_orders(id) ON DELETE CASCADE,
    supplier_id UUID REFERENCES public.suppliers(id) ON DELETE RESTRICT,
    amount NUMERIC(15,2) NOT NULL CHECK (amount > 0),
    payment_method TEXT NOT NULL CHECK (payment_method IN ('sham_cash', 'cash', 'bank_transfer')),
    payment_reference TEXT,
    paid_by TEXT,
    notes TEXT,
    paid_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_sup_payments_po_id ON public.supplier_payments(purchase_order_id);
CREATE INDEX IF NOT EXISTS idx_sup_payments_supplier_id ON public.supplier_payments(supplier_id);

-- ==============================================================================
-- 8. Atomic Stored Procedures & Business Logic RPCs
-- ==============================================================================

-- Procedure: create_purchase_order
CREATE OR REPLACE FUNCTION public.create_purchase_order(
    p_supplier_id UUID,
    p_supplier_name TEXT,
    p_branch_id VARCHAR,
    p_expected_arrival TEXT,
    p_notes TEXT,
    p_items JSONB,
    p_created_by TEXT DEFAULT 'مدير المشتريات'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_po_id UUID;
    v_po_number TEXT;
    v_seq_val BIGINT;
    v_item JSONB;
    v_total_cost NUMERIC(15,2) := 0.00;
    v_total_items NUMERIC(12,2) := 0.00;
    v_item_qty NUMERIC(12,2);
    v_item_cost NUMERIC(15,2);
    v_item_total NUMERIC(15,2);
    v_product_id UUID;
    v_prod_id_raw TEXT;
    v_is_draft BOOLEAN;
    v_result JSONB;
BEGIN
    -- Enforce RBAC caller role checks
    IF auth.user_role() IN ('cashier', 'auditor') THEN
        RAISE EXCEPTION 'ليس لديك صلاحية لإصدار أوامر الشراء والتوريد';
    END IF;

    -- Validate Supplier exists
    IF p_supplier_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.suppliers WHERE id = p_supplier_id) THEN
        RAISE EXCEPTION 'المورد المحدد غير موجود في قاعدة البيانات';
    END IF;

    -- Validate Branch exists
    IF p_branch_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.branches WHERE id = p_branch_id) THEN
        RAISE EXCEPTION 'الفرع المحدد غير موجود في قاعدة البيانات';
    END IF;

    -- Validate items list is not empty
    IF p_items IS NULL OR jsonb_array_length(p_items) = 0 THEN
        RAISE EXCEPTION 'لا يمكن إنشاء أمر شراء بدون بنود أو أصناف';
    END IF;

    -- Generate atomic sequential PO Number: PO-2026-XXXX
    v_seq_val := nextval('public.po_number_seq');
    v_po_number := 'PO-2026-' || LPAD(v_seq_val::TEXT, 4, '0');

    -- Insert Master PO Record
    INSERT INTO public.purchase_orders (
        po_number,
        supplier_id,
        supplier_name,
        branch_id,
        status,
        payment_status,
        total_items,
        total_cost,
        paid_amount,
        order_date,
        expected_arrival,
        notes,
        created_by
    ) VALUES (
        v_po_number,
        p_supplier_id,
        p_supplier_name,
        p_branch_id,
        'sent',
        'unpaid',
        0,
        0,
        0,
        CURRENT_DATE,
        p_expected_arrival,
        p_notes,
        p_created_by
    )
    RETURNING id INTO v_po_id;

    -- Process Each Item
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_item_qty := COALESCE((v_item->>'quantity_ordered')::NUMERIC, 0);
        v_item_cost := COALESCE((v_item->>'unit_cost')::NUMERIC, 0);

        IF v_item_qty <= 0 THEN
            RAISE EXCEPTION 'كمية الصنف يجب أن تكون أكبر من صفر';
        END IF;

        IF v_item_cost < 0 THEN
            RAISE EXCEPTION 'سعر تكلفة الصنف لا يمكن أن يكون سالباً';
        END IF;

        v_item_total := v_item_qty * v_item_cost;
        v_total_cost := v_total_cost + v_item_total;
        v_total_items := v_total_items + v_item_qty;

        v_prod_id_raw := v_item->>'product_id';
        v_is_draft := COALESCE((v_item->>'is_new_draft_product')::BOOLEAN, false);

        -- Safe UUID parsing
        BEGIN
            IF v_prod_id_raw IS NOT NULL AND v_prod_id_raw <> '' THEN
                v_product_id := v_prod_id_raw::UUID;
            ELSE
                v_product_id := NULL;
            END IF;
        EXCEPTION WHEN OTHERS THEN
            v_product_id := NULL;
        END;

        -- If draft product with no existing UUID, check barcode or create in products as draft
        IF v_is_draft AND v_product_id IS NULL THEN
            IF v_item->>'barcode' IS NOT NULL AND v_item->>'barcode' <> '' THEN
                SELECT id INTO v_product_id FROM public.products WHERE barcode = v_item->>'barcode';
            END IF;

            IF v_product_id IS NULL THEN
                INSERT INTO public.products (
                    name_ar,
                    name_en,
                    brand,
                    barcode,
                    category_id,
                    price,
                    cost_price,
                    unit,
                    stock_quantity,
                    images,
                    is_featured,
                    is_daily_deal,
                    rating,
                    is_active,
                    is_draft,
                    status
                ) VALUES (
                    v_item->>'name_ar',
                    COALESCE(v_item->>'name_en', v_item->>'name_ar'),
                    COALESCE(p_supplier_name, 'توريد عام'),
                    COALESCE(v_item->>'barcode', 'GEN-' || floor(random() * 899999999 + 100000000)::TEXT),
                    (SELECT id FROM public.categories LIMIT 1),
                    ROUND(v_item_cost * 1.35, 2),
                    v_item_cost,
                    COALESCE(v_item->>'unit', 'piece'),
                    0, -- 0 initial stock until received at warehouse
                    ARRAY['https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=400&q=80'],
                    false,
                    false,
                    4.8,
                    false, -- Inactive for customer app until approved
                    true,
                    'incomplete_data'
                )
                ON CONFLICT (barcode) DO UPDATE SET updated_at = timezone('utc'::text, now())
                RETURNING id INTO v_product_id;
            END IF;
        END IF;

        -- Insert Item
        INSERT INTO public.purchase_order_items (
            purchase_order_id,
            product_id,
            name_ar,
            barcode,
            unit,
            quantity_ordered,
            quantity_received,
            quantity_damaged,
            unit_cost,
            total_cost,
            is_new_draft_product
        ) VALUES (
            v_po_id,
            v_product_id,
            v_item->>'name_ar',
            v_item->>'barcode',
            COALESCE(v_item->>'unit', 'piece'),
            v_item_qty,
            0,
            0,
            v_item_cost,
            v_item_total,
            v_is_draft
        );
    END LOOP;

    -- Update totals on PO record
    UPDATE public.purchase_orders
    SET total_items = v_total_items,
        total_cost = v_total_cost,
        updated_at = timezone('utc'::text, now())
    WHERE id = v_po_id;

    -- Accrue supplier balance if supplier provided
    IF p_supplier_id IS NOT NULL THEN
        UPDATE public.suppliers
        SET balance = balance + v_total_cost,
            updated_at = timezone('utc'::text, now())
        WHERE id = p_supplier_id;
    END IF;

    -- Return full JSON representation
    SELECT jsonb_build_object(
        'success', true,
        'id', p.id,
        'po_number', p.po_number,
        'supplier_id', p.supplier_id,
        'supplier_name', p.supplier_name,
        'branch_id', p.branch_id,
        'status', p.status,
        'payment_status', p.payment_status,
        'total_items', p.total_items,
        'total_cost', p.total_cost,
        'paid_amount', p.paid_amount,
        'order_date', p.order_date,
        'expected_arrival', p.expected_arrival,
        'notes', p.notes,
        'created_at', p.created_at
    ) INTO v_result
    FROM public.purchase_orders p
    WHERE p.id = v_po_id;

    RETURN v_result;
END;
$$;


-- Procedure: receive_purchase_order_items
CREATE OR REPLACE FUNCTION public.receive_purchase_order_items(
    p_po_id UUID,
    p_receipts JSONB,
    p_receiver TEXT DEFAULT 'أمين المستودع',
    p_branch_id VARCHAR DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_po RECORD;
    v_receipt JSONB;
    v_item_id UUID;
    v_item RECORD;
    v_newly_received NUMERIC(12,2);
    v_damaged NUMERIC(12,2);
    v_net_good NUMERIC(12,2);
    v_new_total_received NUMERIC(12,2);
    v_new_total_damaged NUMERIC(12,2);
    v_all_fulfilled BOOLEAN := true;
    v_any_received BOOLEAN := false;
    v_target_branch VARCHAR(64);
    v_trx_num TEXT;
    v_result JSONB;
BEGIN
    -- Enforce RBAC caller role checks
    IF auth.user_role() IN ('cashier', 'auditor') THEN
        RAISE EXCEPTION 'ليس لديك صلاحية لاستلام بضائع المستودع أو تعديل المخزون';
    END IF;

    -- Lock PO row FOR UPDATE
    SELECT * INTO v_po
    FROM public.purchase_orders
    WHERE id = p_po_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'أمر الشراء المطلوب غير موجود';
    END IF;

    IF v_po.status = 'cancelled' THEN
        RAISE EXCEPTION 'لا يمكن استلام بضائع لأمر شراء تم إلغاؤه مسبقاً';
    END IF;

    v_target_branch := COALESCE(p_branch_id, v_po.branch_id, 'b-dam-01');

    -- Process Receipts
    FOR v_receipt IN SELECT * FROM jsonb_array_elements(p_receipts)
    LOOP
        v_item_id := (v_receipt->>'item_id')::UUID;
        v_newly_received := COALESCE((v_receipt->>'quantity_received')::NUMERIC, 0);
        v_damaged := COALESCE((v_receipt->>'quantity_damaged')::NUMERIC, 0);

        IF v_newly_received < 0 OR v_damaged < 0 THEN
            RAISE EXCEPTION 'الكميات المستلمة أو التالفة لا يمكن أن تكون سالبة';
        END IF;

        IF v_damaged > v_newly_received THEN
            RAISE EXCEPTION 'الكمية التالفة لا يمكن أن تتجاوز الكمية المستلمة في الإرسالية';
        END IF;

        -- Lock Item Row
        SELECT * INTO v_item
        FROM public.purchase_order_items
        WHERE id = v_item_id AND purchase_order_id = p_po_id
        FOR UPDATE;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'أحد بنود التوريد غير مطابق لأمر الشراء هذا';
        END IF;

        -- Prevent receiving beyond ordered quantity
        v_net_good := v_newly_received - v_damaged;
        v_new_total_received := v_item.quantity_received + v_net_good;
        v_new_total_damaged := v_item.quantity_damaged + v_damaged;

        IF v_new_total_received > v_item.quantity_ordered THEN
            RAISE EXCEPTION 'الكمية المستلمة الصافية تتجاوز الكمية المطلوبة في أمر الشراء للصنف: %', v_item.name_ar;
        END IF;

        -- Update Item Record
        UPDATE public.purchase_order_items
        SET quantity_received = v_new_total_received,
            quantity_damaged = v_new_total_damaged,
            updated_at = timezone('utc'::text, now())
        WHERE id = v_item_id;

        -- If Good Stock Received, Increase Product Catalog Stock and Record Ledger Movement
        IF v_net_good > 0 THEN
            v_any_received := true;

            -- Update Product Stock & Cost
            IF v_item.product_id IS NOT NULL THEN
                UPDATE public.products
                SET stock_quantity = stock_quantity + v_net_good::INTEGER,
                    cost_price = v_item.unit_cost,
                    updated_at = timezone('utc'::text, now())
                WHERE id = v_item.product_id;
            END IF;

            -- Record in Central Inventory Transaction Ledger
            v_trx_num := 'TX-REC-' || LPAD(nextval('public.inv_trx_seq')::TEXT, 6, '0');
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
                performed_by,
                notes
            ) VALUES (
                v_trx_num,
                v_target_branch,
                v_item.product_id,
                'purchase_receipt',
                'purchase_order',
                v_po.po_number,
                v_net_good,
                v_item.unit_cost,
                v_net_good * v_item.unit_cost,
                p_receiver,
                'استلام توريد رسمي لأمر الشراء ' || v_po.po_number
            );

            -- If Damasucs Branch, also log to branch_dam_01 schema if active
            IF v_target_branch = 'b-dam-01' THEN
                BEGIN
                    INSERT INTO branch_dam_01.inventory_movements (
                        product_id,
                        movement_type,
                        quantity,
                        balance_after,
                        reference_id,
                        reason,
                        created_by
                    ) VALUES (
                        v_item.product_id,
                        'transfer_in',
                        v_net_good::INTEGER,
                        (SELECT COALESCE(stock_quantity, 0) FROM public.products WHERE id = v_item.product_id),
                        v_po.po_number,
                        'توريد مستودعي معتمد من المورد: ' || v_po.supplier_name,
                        p_receiver
                    );
                EXCEPTION WHEN OTHERS THEN
                    -- Non-blocking schema isolation fallback
                    NULL;
                END;
            END IF;
        END IF;

        -- If Damaged, Record Damaged Loss Transaction
        IF v_damaged > 0 THEN
            v_trx_num := 'TX-DMG-' || LPAD(nextval('public.inv_trx_seq')::TEXT, 6, '0');
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
                performed_by,
                notes
            ) VALUES (
                v_trx_num,
                v_target_branch,
                v_item.product_id,
                'damaged_loss',
                'purchase_order',
                v_po.po_number,
                -v_damaged,
                v_item.unit_cost,
                v_damaged * v_item.unit_cost,
                p_receiver,
                'بضاعة تالفة / مرفوضة عند الفحص والاستلام لأمر الشراء ' || v_po.po_number
            );
        END IF;
    END LOOP;

    -- Evaluate All Items to Determine Final Status
    SELECT bool_and(quantity_received >= quantity_ordered),
           bool_or(quantity_received > 0)
    INTO v_all_fulfilled, v_any_received
    FROM public.purchase_order_items
    WHERE purchase_order_id = p_po_id;

    UPDATE public.purchase_orders
    SET status = CASE 
            WHEN v_all_fulfilled THEN 'received'
            WHEN v_any_received THEN 'partially_received'
            ELSE status
        END,
        updated_at = timezone('utc'::text, now())
    WHERE id = p_po_id;

    SELECT jsonb_build_object(
        'success', true,
        'po_id', p_po_id,
        'status', (SELECT status FROM public.purchase_orders WHERE id = p_po_id),
        'all_fulfilled', v_all_fulfilled
    ) INTO v_result;

    RETURN v_result;
END;
$$;


-- Procedure: record_supplier_payment
CREATE OR REPLACE FUNCTION public.record_supplier_payment(
    p_po_id UUID,
    p_amount NUMERIC,
    p_payment_method TEXT,
    p_reference TEXT DEFAULT NULL,
    p_payer TEXT DEFAULT 'المحاسب المالي',
    p_notes TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_po RECORD;
    v_remaining NUMERIC(15,2);
    v_new_paid NUMERIC(15,2);
    v_payment_num TEXT;
    v_new_status TEXT;
    v_result JSONB;
BEGIN
    -- Enforce RBAC caller role checks
    IF auth.user_role() IN ('cashier', 'auditor', 'warehouse_manager') THEN
        RAISE EXCEPTION 'ليس لديك صلاحية لصرف وتسجيل دفعات الموردين المالية';
    END IF;

    IF p_amount <= 0 THEN
        RAISE EXCEPTION 'مبلغ السداد يجب أن يكون أكبر من صفر';
    END IF;

    IF p_payment_method NOT IN ('sham_cash', 'cash', 'bank_transfer') THEN
        RAISE EXCEPTION 'طريقة السداد غير معتمدة';
    END IF;

    -- Lock PO Row
    SELECT * INTO v_po
    FROM public.purchase_orders
    WHERE id = p_po_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'أمر الشراء المطلوب غير موجود';
    END IF;

    v_remaining := v_po.total_cost - v_po.paid_amount;
    IF p_amount > v_remaining + 0.01 THEN
        RAISE EXCEPTION 'مبلغ السداد المطلوب (%) يتجاوز الرصيد المتبقي المستحق (%)', p_amount, v_remaining;
    END IF;

    -- Generate Unique Payment Number: SP-PAY-XXXXX
    v_payment_num := 'SP-PAY-' || LPAD(nextval('public.sup_pay_seq')::TEXT, 5, '0');

    -- Insert Payment Record
    INSERT INTO public.supplier_payments (
        payment_number,
        purchase_order_id,
        supplier_id,
        amount,
        payment_method,
        payment_reference,
        paid_by,
        notes
    ) VALUES (
        v_payment_num,
        p_po_id,
        v_po.supplier_id,
        p_amount,
        p_payment_method,
        p_reference,
        p_payer,
        p_notes
    );

    v_new_paid := v_po.paid_amount + p_amount;
    v_new_status := CASE WHEN v_new_paid >= v_po.total_cost THEN 'paid' ELSE 'partial' END;

    -- Update PO
    UPDATE public.purchase_orders
    SET paid_amount = v_new_paid,
        payment_status = v_new_status,
        updated_at = timezone('utc'::text, now())
    WHERE id = p_po_id;

    -- Decrease Supplier Balance
    IF v_po.supplier_id IS NOT NULL THEN
        UPDATE public.suppliers
        SET balance = GREATEST(0.00, balance - p_amount),
            updated_at = timezone('utc'::text, now())
        WHERE id = v_po.supplier_id;
    END IF;

    SELECT jsonb_build_object(
        'success', true,
        'payment_number', v_payment_num,
        'paid_amount', v_new_paid,
        'payment_status', v_new_status,
        'remaining_balance', GREATEST(0.00, v_po.total_cost - v_new_paid)
    ) INTO v_result;

    RETURN v_result;
END;
$$;


-- Procedure: cancel_purchase_order
CREATE OR REPLACE FUNCTION public.cancel_purchase_order(
    p_po_id UUID,
    p_reason TEXT,
    p_user TEXT DEFAULT 'مدير المشتريات'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_po RECORD;
    v_has_receipts BOOLEAN;
BEGIN
    -- Enforce RBAC caller role checks
    IF auth.user_role() IN ('cashier', 'auditor') THEN
        RAISE EXCEPTION 'ليس لديك صلاحية لإلغاء أوامر الشراء المعتمدة';
    END IF;

    SELECT * INTO v_po
    FROM public.purchase_orders
    WHERE id = p_po_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'أمر الشراء المطلوب غير موجود';
    END IF;

    IF v_po.status = 'cancelled' THEN
        RAISE EXCEPTION 'أمر الشراء ملغى بالفعل';
    END IF;

    -- Check if any items have been received
    SELECT EXISTS (
        SELECT 1 FROM public.purchase_order_items 
        WHERE purchase_order_id = p_po_id AND quantity_received > 0
    ) INTO v_has_receipts;

    IF v_has_receipts THEN
        RAISE EXCEPTION 'لا يمكن إلغاء أمر شراء تم استلام بضائع منه جزئياً أو كلياً';
    END IF;

    UPDATE public.purchase_orders
    SET status = 'cancelled',
        cancellation_reason = p_reason,
        updated_at = timezone('utc'::text, now())
    WHERE id = p_po_id;

    -- Reverse accrued balance from supplier if unpaid
    IF v_po.supplier_id IS NOT NULL THEN
        UPDATE public.suppliers
        SET balance = GREATEST(0.00, balance - (v_po.total_cost - v_po.paid_amount)),
            updated_at = timezone('utc'::text, now())
        WHERE id = v_po.supplier_id;
    END IF;

    RETURN jsonb_build_object('success', true, 'status', 'cancelled');
END;
$$;


-- Procedure: approve_draft_product
CREATE OR REPLACE FUNCTION public.approve_draft_product(
    p_product_id UUID,
    p_user TEXT DEFAULT 'مدير الكتالوج'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE public.products
    SET is_draft = false,
        is_active = true,
        status = 'published',
        updated_at = timezone('utc'::text, now())
    WHERE id = p_product_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'الصنف المطلوب غير موجود';
    END IF;

    RETURN jsonb_build_object('success', true, 'product_id', p_product_id, 'is_active', true, 'status', 'published');
END;
$$;

-- ==============================================================================
-- 9. Row Level Security & Access Policies
-- ==============================================================================
ALTER TABLE public.suppliers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.purchase_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.purchase_order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.supplier_payments ENABLE ROW LEVEL SECURITY;

-- Suppliers Policies
DROP POLICY IF EXISTS "suppliers_read_policy" ON public.suppliers;
CREATE POLICY "suppliers_read_policy" ON public.suppliers FOR SELECT
USING (true);

DROP POLICY IF EXISTS "suppliers_write_policy" ON public.suppliers;
CREATE POLICY "suppliers_write_policy" ON public.suppliers FOR ALL
USING (auth.user_role() IN ('super_admin', 'general_manager', 'warehouse_manager', 'branch_manager', 'accountant'))
WITH CHECK (auth.user_role() IN ('super_admin', 'general_manager', 'warehouse_manager', 'branch_manager', 'accountant'));

-- Purchase Orders Policies
DROP POLICY IF EXISTS "purchase_orders_read_policy" ON public.purchase_orders;
CREATE POLICY "purchase_orders_read_policy" ON public.purchase_orders FOR SELECT
USING (true);

DROP POLICY IF EXISTS "purchase_orders_write_policy" ON public.purchase_orders;
CREATE POLICY "purchase_orders_write_policy" ON public.purchase_orders FOR ALL
USING (auth.user_role() IN ('super_admin', 'general_manager', 'warehouse_manager', 'branch_manager'))
WITH CHECK (auth.user_role() IN ('super_admin', 'general_manager', 'warehouse_manager', 'branch_manager'));

-- Purchase Order Items Policies
DROP POLICY IF EXISTS "po_items_read_policy" ON public.purchase_order_items;
CREATE POLICY "po_items_read_policy" ON public.purchase_order_items FOR SELECT
USING (true);

DROP POLICY IF EXISTS "po_items_write_policy" ON public.purchase_order_items;
CREATE POLICY "po_items_write_policy" ON public.purchase_order_items FOR ALL
USING (auth.user_role() IN ('super_admin', 'general_manager', 'warehouse_manager', 'branch_manager'))
WITH CHECK (auth.user_role() IN ('super_admin', 'general_manager', 'warehouse_manager', 'branch_manager'));

-- Inventory Transactions Policies
DROP POLICY IF EXISTS "inv_trx_read_policy" ON public.inventory_transactions;
CREATE POLICY "inv_trx_read_policy" ON public.inventory_transactions FOR SELECT
USING (true);

DROP POLICY IF EXISTS "inv_trx_write_policy" ON public.inventory_transactions;
CREATE POLICY "inv_trx_write_policy" ON public.inventory_transactions FOR ALL
USING (auth.user_role() IN ('super_admin', 'general_manager', 'warehouse_manager', 'branch_manager'))
WITH CHECK (auth.user_role() IN ('super_admin', 'general_manager', 'warehouse_manager', 'branch_manager'));

-- Supplier Payments Policies
DROP POLICY IF EXISTS "sup_pay_read_policy" ON public.supplier_payments;
CREATE POLICY "sup_pay_read_policy" ON public.supplier_payments FOR SELECT
USING (true);

DROP POLICY IF EXISTS "sup_pay_write_policy" ON public.supplier_payments;
CREATE POLICY "sup_pay_write_policy" ON public.supplier_payments FOR ALL
USING (auth.user_role() IN ('super_admin', 'general_manager', 'accountant'))
WITH CHECK (auth.user_role() IN ('super_admin', 'general_manager', 'accountant'));

-- Grant access to anon & authenticated for PostgREST
GRANT ALL ON public.suppliers TO anon, authenticated;
GRANT ALL ON public.purchase_orders TO anon, authenticated;
GRANT ALL ON public.purchase_order_items TO anon, authenticated;
GRANT ALL ON public.inventory_transactions TO anon, authenticated;
GRANT ALL ON public.supplier_payments TO anon, authenticated;

GRANT USAGE, SELECT ON SEQUENCE public.po_number_seq TO anon, authenticated;
GRANT USAGE, SELECT ON SEQUENCE public.inv_trx_seq TO anon, authenticated;
GRANT USAGE, SELECT ON SEQUENCE public.sup_pay_seq TO anon, authenticated;

-- ==============================================================================
-- 10. Seed Initial Certified Suppliers & Baseline Purchase Orders
-- ==============================================================================
INSERT INTO public.suppliers (id, name_ar, name_en, contact_person, phone, email, lead_time_days, payment_terms, active_products_count, balance, status)
VALUES
    ('e1000000-0000-0000-0000-000000000001', 'شركة المراعي للألبان والعصائر', 'Almarai Dairy & Food Co.', 'م. فهد القحطاني', '+963 11 888 1234', 'b2b.orders@almarai.com', 1, 'آجل 30 يوماً', 85, 345000.00, 'active'),
    ('e1000000-0000-0000-0000-000000000002', 'شركة التنمية للدواجن والأغذية الطازجة', 'Tanmiah Fresh Food Co.', 'د. سامر الرفاعي', '+963 11 777 5678', 'supply@tanmiah.com', 1, 'آجل 15 يوماً', 42, 185000.00, 'active'),
    ('e1000000-0000-0000-0000-000000000003', 'مؤسسة مزارع غوطة دمشق للخضار والفواكه', 'Damascus Oasis Fresh Farms', 'أ. أنس الحمصي', '+963 11 666 9012', 'ghouta.produce@gmail.com', 1, 'نقداً عند الاستلام', 64, 92000.00, 'active'),
    ('e1000000-0000-0000-0000-000000000004', 'شركة الديب ومستودعات التموين الكبرى', 'Aldeeb Grand Wholesale Logistics', 'م. حسام الديب', '+963 11 555 4321', 'procurement@aldeebmall.com', 2, 'حساب جارٍ شهري', 190, 720000.00, 'active')
ON CONFLICT (id) DO UPDATE SET
    name_ar = EXCLUDED.name_ar,
    name_en = EXCLUDED.name_en,
    contact_person = EXCLUDED.contact_person,
    phone = EXCLUDED.phone,
    email = EXCLUDED.email;

-- Track migration in _schema_migrations
INSERT INTO public._schema_migrations (filename, applied_at)
VALUES ('20261104_019_suppliers_and_procurement_system.sql', timezone('utc'::text, now()))
ON CONFLICT (filename) DO UPDATE SET applied_at = timezone('utc'::text, now());
