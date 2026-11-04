-- ==============================================================================
-- الديب مول (Aldeeb Mall) - Real Inventory & Item Movement Engine
-- Migration: 20261104_019_real_inventory_and_movements.sql
-- Single Monotonic Migration Sequence: Step 019
-- ==============================================================================

BEGIN;

-- 1. Create branch_inventory table (Real physical & available stock per product & branch)
CREATE TABLE IF NOT EXISTS public.branch_inventory (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id character varying(64) NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
    product_id uuid NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    quantity_on_hand numeric(12,2) NOT NULL DEFAULT 0 CHECK (quantity_on_hand >= 0),
    quantity_reserved numeric(12,2) NOT NULL DEFAULT 0 CHECK (quantity_reserved >= 0),
    safety_threshold numeric(12,2) NOT NULL DEFAULT 5 CHECK (safety_threshold >= 0),
    bin_location text NOT NULL DEFAULT 'رف-A-01',
    updated_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT uq_branch_inventory_branch_product UNIQUE (branch_id, product_id)
);

CREATE INDEX IF NOT EXISTS idx_branch_inventory_branch ON public.branch_inventory(branch_id);
CREATE INDEX IF NOT EXISTS idx_branch_inventory_product ON public.branch_inventory(product_id);
CREATE INDEX IF NOT EXISTS idx_branch_inventory_composite ON public.branch_inventory(branch_id, product_id);

-- 2. Create inventory_movements table (Permanent, audited stock movement log)
CREATE TABLE IF NOT EXISTS public.inventory_movements (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    movement_number text NOT NULL UNIQUE,
    branch_id character varying(64) NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
    product_id uuid NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    movement_type text NOT NULL CHECK (movement_type IN (
        'supply',               -- توريد بضاعة جديدة أو أمر شراء
        'reservation',          -- حجز كمية لصالح طلب قيد التجهيز
        'release_reservation',  -- فك الحجز وإلغاء الطلب
        'disbursement',         -- صرف بضاعة أو إذن صرف
        'sale',                 -- بيع مباشر أو نقطة بيع POS
        'return',               -- مرتجع من عميل
        'damaged',              -- إتلاف أو بضاعة تالفة
        'audit_reconciliation', -- جرد فعلي وتسوية فروقات
        'adjustment',           -- تعديل يدوي معتمد
        'transfer_out',         -- مناقلة صادرة لفرع آخر
        'transfer_in'           -- مناقلة واردة من فرع آخر
    )),
    quantity_change numeric(12,2) NOT NULL,
    quantity_reserved_change numeric(12,2) NOT NULL DEFAULT 0,
    resulting_on_hand numeric(12,2) NOT NULL CHECK (resulting_on_hand >= 0),
    resulting_reserved numeric(12,2) NOT NULL CHECK (resulting_reserved >= 0),
    reference_type text NOT NULL CHECK (reference_type IN (
        'order', 'po', 'transfer', 'audit', 'return', 'adjustment', 'manual', 'loss_prevention'
    )),
    reference_id text NOT NULL,
    actor_id text,
    actor_name text NOT NULL,
    actor_role text NOT NULL,
    notes text,
    created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_inventory_movements_branch ON public.inventory_movements(branch_id);
CREATE INDEX IF NOT EXISTS idx_inventory_movements_product ON public.inventory_movements(product_id);
CREATE INDEX IF NOT EXISTS idx_inventory_movements_type ON public.inventory_movements(movement_type);
CREATE INDEX IF NOT EXISTS idx_inventory_movements_created ON public.inventory_movements(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_inventory_movements_ref ON public.inventory_movements(reference_id);

-- 3. Create inventory_transfers table (Multi-branch two-phase transfer workflow)
CREATE TABLE IF NOT EXISTS public.inventory_transfers (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    transfer_number text NOT NULL UNIQUE,
    source_branch_id character varying(64) NOT NULL REFERENCES public.branches(id),
    destination_branch_id character varying(64) NOT NULL REFERENCES public.branches(id),
    product_id uuid NOT NULL REFERENCES public.products(id),
    quantity_requested numeric(12,2) NOT NULL CHECK (quantity_requested > 0),
    quantity_dispatched numeric(12,2) NOT NULL DEFAULT 0 CHECK (quantity_dispatched >= 0),
    quantity_received numeric(12,2) NOT NULL DEFAULT 0 CHECK (quantity_received >= 0),
    quantity_damaged numeric(12,2) NOT NULL DEFAULT 0 CHECK (quantity_damaged >= 0),
    status text NOT NULL DEFAULT 'requested' CHECK (status IN (
        'requested', 'under_review', 'approved', 'dispatched', 'received', 'closed', 'rejected'
    )),
    discrepancy_reason text,
    assigned_driver text,
    audit_locked boolean NOT NULL DEFAULT false,
    requested_by text,
    dispatched_by text,
    received_by text,
    requested_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
    dispatched_at timestamp with time zone,
    received_at timestamp with time zone,
    closed_at timestamp with time zone,
    created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_inventory_transfers_source ON public.inventory_transfers(source_branch_id);
CREATE INDEX IF NOT EXISTS idx_inventory_transfers_dest ON public.inventory_transfers(destination_branch_id);
CREATE INDEX IF NOT EXISTS idx_inventory_transfers_status ON public.inventory_transfers(status);

-- 4. Create inventory_audits table (Physical inventory reconciliation sessions)
CREATE TABLE IF NOT EXISTS public.inventory_audits (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    audit_number text NOT NULL UNIQUE,
    branch_id character varying(64) NOT NULL REFERENCES public.branches(id),
    product_id uuid NOT NULL REFERENCES public.products(id),
    system_quantity numeric(12,2) NOT NULL,
    physical_quantity numeric(12,2) NOT NULL CHECK (physical_quantity >= 0),
    variance numeric(12,2) NOT NULL,
    reason text,
    auditor_id text,
    auditor_name text NOT NULL,
    auditor_role text NOT NULL,
    status text NOT NULL DEFAULT 'completed',
    created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_inventory_audits_branch ON public.inventory_audits(branch_id);
CREATE INDEX IF NOT EXISTS idx_inventory_audits_product ON public.inventory_audits(product_id);

-- 5. Seed Real Initial Branch Inventory for all existing products and branches
INSERT INTO public.branch_inventory (branch_id, product_id, quantity_on_hand, quantity_reserved, safety_threshold, bin_location)
SELECT 
    b.id AS branch_id,
    p.id AS product_id,
    GREATEST(10, FLOOR(p.stock_quantity / 5.0))::numeric(12,2) AS quantity_on_hand,
    0 AS quantity_reserved,
    5 AS safety_threshold,
    'رف-' || CHR(65 + (ROW_NUMBER() OVER (PARTITION BY b.id ORDER BY p.id) % 6)::int) || '-' || LPAD(((ROW_NUMBER() OVER (PARTITION BY b.id ORDER BY p.id) % 20) + 1)::text, 2, '0') AS bin_location
FROM public.branches b
CROSS JOIN public.products p
ON CONFLICT (branch_id, product_id) DO UPDATE SET
    quantity_on_hand = EXCLUDED.quantity_on_hand,
    updated_at = timezone('utc'::text, now());

-- Seed initial supply movement records for traceability
INSERT INTO public.inventory_movements (
    movement_number, branch_id, product_id, movement_type, quantity_change, quantity_reserved_change,
    resulting_on_hand, resulting_reserved, reference_type, reference_id, actor_name, actor_role, notes
)
SELECT 
    'INIT-' || bi.branch_id || '-' || replace(bi.product_id::text, '-', ''),
    bi.branch_id,
    bi.product_id,
    'supply',
    bi.quantity_on_hand,
    0,
    bi.quantity_on_hand,
    0,
    'manual',
    'INIT-BAL-2026',
    'أمين المستودع العام',
    'warehouse_manager',
    'الرصيد الافتتاحي المعتمد لبدء الدورة المخزنية الرقمية'
FROM public.branch_inventory bi
ON CONFLICT (movement_number) DO NOTHING;

-- Synchronize total stock_quantity in public.products to match the sum of real branch balances
UPDATE public.products p
SET stock_quantity = COALESCE((
    SELECT SUM(bi.quantity_on_hand)::int
    FROM public.branch_inventory bi
    WHERE bi.product_id = p.id
), 0),
updated_at = timezone('utc'::text, now());

-- Trigger to auto-provision branch inventory rows whenever a new product is added
CREATE OR REPLACE FUNCTION public.trg_auto_provision_branch_inventory()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO public.branch_inventory (branch_id, product_id, quantity_on_hand, quantity_reserved, safety_threshold, bin_location)
    SELECT 
        b.id,
        NEW.id,
        GREATEST(10, FLOOR(COALESCE(NEW.stock_quantity, 100) / 5.0)),
        0,
        5,
        'رف-A-01'
    FROM public.branches b
    ON CONFLICT (branch_id, product_id) DO NOTHING;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_provision_branch_inventory_on_product ON public.products;
CREATE TRIGGER trg_provision_branch_inventory_on_product
    AFTER INSERT ON public.products
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_auto_provision_branch_inventory();

-- 6. Atomic Stored Procedure: record_inventory_movement_atomic
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
            -- Allowed: order placement or cancellation
            NULL;
        ELSIF p_ref_type = 'return' AND p_movement_type IN ('return', 'damaged') THEN
            -- Allowed: return processing
            NULL;
        ELSIF p_ref_type = 'transfer' AND p_movement_type IN ('transfer_out', 'transfer_in') THEN
            -- Allowed: transfer dispatch and receipt
            NULL;
        ELSIF p_ref_type = 'audit' AND p_movement_type = 'audit_reconciliation' THEN
            -- Allowed: audit reconciliation
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
        -- Auto-provision row with 0 if not present
        INSERT INTO public.branch_inventory (branch_id, product_id, quantity_on_hand, quantity_reserved)
        VALUES (p_branch_id, p_product_id, 0, 0)
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

    -- Insert Permanent Movement Audit Log
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
        v_mov_number,
        p_branch_id,
        p_product_id,
        p_movement_type,
        p_qty_change,
        COALESCE(p_qty_reserved_change, 0),
        v_new_on_hand,
        v_new_reserved,
        p_ref_type,
        p_ref_id,
        COALESCE(p_actor_id, auth.user_id()),
        p_actor_name,
        p_actor_role,
        p_notes
    );

    v_result := jsonb_build_object(
        'success', true,
        'movement_number', v_mov_number,
        'branch_id', p_branch_id,
        'product_id', p_product_id,
        'previous_on_hand', v_curr_on_hand,
        'new_on_hand', v_new_on_hand,
        'previous_reserved', v_curr_reserved,
        'new_reserved', v_new_reserved,
        'quantity_change', p_qty_change,
        'movement_type', p_movement_type
    );

    RETURN v_result;
END;
$$;

-- 7. Atomic Stored Procedure: perform_inventory_transfer_step_atomic
CREATE OR REPLACE FUNCTION public.perform_inventory_transfer_step_atomic(
    p_transfer_id uuid,
    p_action text,
    p_actor_id text DEFAULT NULL,
    p_actor_name text DEFAULT 'مسؤول اللوجستيات',
    p_actor_role text DEFAULT 'warehouse_manager',
    p_good_qty numeric DEFAULT NULL,
    p_damaged_qty numeric DEFAULT 0,
    p_driver text DEFAULT NULL,
    p_discrepancy_reason text DEFAULT ''
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_tr record;
    v_mov_number text;
BEGIN
    SELECT * INTO v_tr
    FROM public.inventory_transfers
    WHERE id = p_transfer_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'TRANSFER_NOT_FOUND: Transfer order % does not exist', p_transfer_id;
    END IF;

    IF v_tr.audit_locked THEN
        RAISE EXCEPTION 'AUDIT_LOCKED: Transfer order % is finalized and locked against modification', v_tr.transfer_number;
    END IF;

    IF p_action = 'approve' THEN
        UPDATE public.inventory_transfers
        SET status = 'approved',
            updated_at = timezone('utc'::text, now())
        WHERE id = p_transfer_id;

        RETURN jsonb_build_object('success', true, 'status', 'approved', 'transfer_number', v_tr.transfer_number);

    ELSIF p_action = 'dispatch' THEN
        -- Deduct from Source Branch Stock Atomically
        PERFORM public.record_inventory_movement_atomic(
            v_tr.source_branch_id,
            v_tr.product_id,
            'transfer_out',
            -v_tr.quantity_requested,
            0,
            'transfer',
            v_tr.transfer_number,
            p_actor_id,
            p_actor_name,
            p_actor_role,
            'شحن وتصدير مناقلة إلى الفرع المستلم'
        );

        UPDATE public.inventory_transfers
        SET status = 'dispatched',
            quantity_dispatched = v_tr.quantity_requested,
            assigned_driver = COALESCE(p_driver, assigned_driver, 'أسطول النقل المبرد المعتمد'),
            dispatched_by = p_actor_name,
            dispatched_at = timezone('utc'::text, now()),
            updated_at = timezone('utc'::text, now())
        WHERE id = p_transfer_id;

        RETURN jsonb_build_object('success', true, 'status', 'dispatched', 'transfer_number', v_tr.transfer_number);

    ELSIF p_action = 'receive' THEN
        DECLARE
            v_actual_good numeric := COALESCE(p_good_qty, v_tr.quantity_dispatched);
            v_actual_damaged numeric := COALESCE(p_damaged_qty, 0);
        BEGIN
            -- Credit destination branch with good items
            IF v_actual_good > 0 THEN
                PERFORM public.record_inventory_movement_atomic(
                    v_tr.destination_branch_id,
                    v_tr.product_id,
                    'transfer_in',
                    v_actual_good,
                    0,
                    'transfer',
                    v_tr.transfer_number,
                    p_actor_id,
                    p_actor_name,
                    p_actor_role,
                    'استلام مناقلة بضاعة سليمة وإيداعها في رفوف الفرع'
                );
            END IF;

            -- Log damaged goods if any (quarantine)
            IF v_actual_damaged > 0 THEN
                v_mov_number := 'DAM-' || to_char(now(), 'YYYYMMDD-HH24MISS') || '-' || substr(md5(random()::text), 1, 6);
                INSERT INTO public.inventory_movements (
                    movement_number, branch_id, product_id, movement_type, quantity_change, quantity_reserved_change,
                    resulting_on_hand, resulting_reserved, reference_type, reference_id, actor_id, actor_name, actor_role, notes
                ) VALUES (
                    v_mov_number,
                    v_tr.destination_branch_id,
                    v_tr.product_id,
                    'damaged',
                    0, -- recorded in damage register without adding to on_hand
                    0,
                    (SELECT quantity_on_hand FROM public.branch_inventory WHERE branch_id = v_tr.destination_branch_id AND product_id = v_tr.product_id),
                    0,
                    'transfer',
                    v_tr.transfer_number,
                    p_actor_id,
                    p_actor_name,
                    p_actor_role,
                    COALESCE(p_discrepancy_reason, 'تلف أثناء النقل اللوجستي')
                );
            END IF;

            UPDATE public.inventory_transfers
            SET status = 'closed',
                quantity_received = v_actual_good,
                quantity_damaged = v_actual_damaged,
                discrepancy_reason = p_discrepancy_reason,
                received_by = p_actor_name,
                received_at = timezone('utc'::text, now()),
                closed_at = timezone('utc'::text, now()),
                audit_locked = true,
                updated_at = timezone('utc'::text, now())
            WHERE id = p_transfer_id;

            RETURN jsonb_build_object(
                'success', true,
                'status', 'closed',
                'transfer_number', v_tr.transfer_number,
                'good_received', v_actual_good,
                'damaged', v_actual_damaged
            );
        END;

    ELSE
        RAISE EXCEPTION 'INVALID_ACTION: Unknown transfer action %', p_action;
    END IF;
END;
$$;

-- 8. Atomic Stored Procedure: perform_stock_audit_reconciliation_atomic
CREATE OR REPLACE FUNCTION public.perform_stock_audit_reconciliation_atomic(
    p_branch_id text,
    p_product_id uuid,
    p_physical_qty numeric,
    p_auditor_id text DEFAULT NULL,
    p_auditor_name text DEFAULT 'المدقق المالي والمخزني',
    p_auditor_role text DEFAULT 'auditor',
    p_reason text DEFAULT 'مطابقة الجرد الدوري الفعلي'
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_system_qty numeric(12,2);
    v_variance numeric(12,2);
    v_audit_number text;
    v_mov_number text;
BEGIN
    IF p_physical_qty < 0 THEN
        RAISE EXCEPTION 'INVALID_PHYSICAL_QTY: Physical count quantity cannot be negative';
    END IF;

    -- Lock branch inventory row
    SELECT quantity_on_hand INTO v_system_qty
    FROM public.branch_inventory
    WHERE branch_id = p_branch_id AND product_id = p_product_id
    FOR UPDATE;

    IF NOT FOUND THEN
        v_system_qty := 0;
        INSERT INTO public.branch_inventory (branch_id, product_id, quantity_on_hand, quantity_reserved)
        VALUES (p_branch_id, p_product_id, 0, 0);
    END IF;

    v_variance := p_physical_qty - v_system_qty;
    v_audit_number := 'AUDIT-' || to_char(now(), 'YYYYMMDD-HH24MISS') || '-' || substr(md5(random()::text), 1, 6);

    -- Insert Audit Record
    INSERT INTO public.inventory_audits (
        audit_number,
        branch_id,
        product_id,
        system_quantity,
        physical_quantity,
        variance,
        reason,
        auditor_id,
        auditor_name,
        auditor_role
    ) VALUES (
        v_audit_number,
        p_branch_id,
        p_product_id,
        v_system_qty,
        p_physical_qty,
        v_variance,
        p_reason,
        COALESCE(p_auditor_id, auth.user_id()),
        p_auditor_name,
        p_auditor_role
    );

    -- Apply Reconciliation Adjustment if there is variance
    IF v_variance <> 0 THEN
        UPDATE public.branch_inventory
        SET quantity_on_hand = p_physical_qty,
            updated_at = timezone('utc'::text, now())
        WHERE branch_id = p_branch_id AND product_id = p_product_id;

        UPDATE public.products
        SET stock_quantity = (SELECT COALESCE(SUM(quantity_on_hand), 0)::int FROM public.branch_inventory WHERE product_id = p_product_id),
            updated_at = timezone('utc'::text, now())
        WHERE id = p_product_id;

        v_mov_number := 'MOV-AUD-' || to_char(now(), 'YYYYMMDD-HH24MISS') || '-' || substr(md5(random()::text), 1, 6);
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
            v_mov_number,
            p_branch_id,
            p_product_id,
            'audit_reconciliation',
            v_variance,
            0,
            p_physical_qty,
            (SELECT quantity_reserved FROM public.branch_inventory WHERE branch_id = p_branch_id AND product_id = p_product_id),
            'audit',
            v_audit_number,
            COALESCE(p_auditor_id, auth.user_id()),
            p_auditor_name,
            p_auditor_role,
            'تسوية جردية: ' || COALESCE(p_reason, 'فروقات جرد فعلي')
        );
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'audit_number', v_audit_number,
        'branch_id', p_branch_id,
        'product_id', p_product_id,
        'system_quantity', v_system_qty,
        'physical_quantity', p_physical_qty,
        'variance', v_variance
    );
END;
$$;

-- 9. Atomic Stored Procedure: cancel_order_atomic (Restores branch stock and logs movement)
CREATE OR REPLACE FUNCTION public.cancel_order_atomic(
    p_order_id uuid,
    p_actor_id text DEFAULT NULL,
    p_actor_name text DEFAULT 'إدارة العمليات',
    p_actor_role text DEFAULT 'admin',
    p_reason text DEFAULT 'إلغاء الطلب بناء على طلب العميل'
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_order record;
    v_item record;
    v_restored_count int := 0;
BEGIN
    SELECT * INTO v_order
    FROM public.orders
    WHERE id = p_order_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'ORDER_NOT_FOUND: Order % does not exist', p_order_id;
    END IF;

    IF v_order.status = 'cancelled' THEN
        RAISE EXCEPTION 'ALREADY_CANCELLED: Order % is already cancelled', v_order.order_number;
    END IF;

    -- Iterate items and restore branch stock
    FOR v_item IN (SELECT * FROM public.order_items WHERE order_id = p_order_id)
    LOOP
        IF v_item.product_id IS NOT NULL THEN
            PERFORM public.record_inventory_movement_atomic(
                COALESCE(v_order.branch_id, 'b-jed-01'),
                v_item.product_id,
                'release_reservation',
                v_item.quantity,
                0,
                'order',
                v_order.order_number,
                p_actor_id,
                p_actor_name,
                p_actor_role,
                'إلغاء طلب واستعادة الرصيد للمستودع: ' || COALESCE(p_reason, '')
            );
            v_restored_count := v_restored_count + 1;
        END IF;
    END LOOP;

    -- Update Order Status
    UPDATE public.orders
    SET status = 'cancelled',
        notes = COALESCE(notes, '') || ' [ملغى: ' || p_reason || ']',
        updated_at = timezone('utc'::text, now())
    WHERE id = p_order_id;

    RETURN jsonb_build_object(
        'success', true,
        'order_id', p_order_id,
        'order_number', v_order.order_number,
        'restored_items_count', v_restored_count
    );
END;
$$;

-- 10. Atomic Stored Procedure: process_order_return_atomic (Returns stock to branch)
CREATE OR REPLACE FUNCTION public.process_order_return_atomic(
    p_order_id uuid,
    p_items jsonb,
    p_actor_id text DEFAULT NULL,
    p_actor_name text DEFAULT 'مسؤول المرتجعات',
    p_actor_role text DEFAULT 'support_officer',
    p_reason text DEFAULT 'مرتجع عميل معتمد'
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_order record;
    v_item jsonb;
    v_prod_id uuid;
    v_qty numeric;
    v_returned_count int := 0;
BEGIN
    SELECT * INTO v_order
    FROM public.orders
    WHERE id = p_order_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'ORDER_NOT_FOUND: Order % does not exist', p_order_id;
    END IF;

    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_prod_id := (v_item->>'product_id')::uuid;
        v_qty := (v_item->>'quantity')::numeric;

        IF v_prod_id IS NOT NULL AND v_qty > 0 THEN
            PERFORM public.record_inventory_movement_atomic(
                COALESCE(v_order.branch_id, 'b-jed-01'),
                v_prod_id,
                'return',
                v_qty,
                0,
                'return',
                v_order.order_number,
                p_actor_id,
                p_actor_name,
                p_actor_role,
                'استلام مرتجع وفحصه: ' || COALESCE(p_reason, '')
            );
            v_returned_count := v_returned_count + 1;
        END IF;
    END LOOP;

    RETURN jsonb_build_object(
        'success', true,
        'order_id', p_order_id,
        'order_number', v_order.order_number,
        'returned_items_count', v_returned_count
    );
END;
$$;

-- 11. Overload & Upgrade place_order_atomic to enforce Atomic Branch Stock Deduction & Sale Movements
-- First, drop the old 12-argument function to avoid signature ambiguities
DROP FUNCTION IF EXISTS public.place_order_atomic(text, uuid, text, text, numeric, numeric, numeric, int, numeric, numeric, text, jsonb);
DROP FUNCTION IF EXISTS public.place_order_atomic(text, uuid, text, text, numeric, numeric, numeric, int, numeric, numeric, text, jsonb, text);

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
    p_branch_id text DEFAULT NULL
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
    v_target_branch_id text;
    v_branch_name text;
    v_item jsonb;
    v_product_id uuid;
    v_qty numeric;
    v_db_price numeric;
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
        v_effective_user_id := v_caller_id;
    ELSIF v_is_admin THEN
        v_effective_user_id := p_user_id;
    ELSE
        IF p_user_id IS NOT NULL THEN
            RAISE EXCEPTION 'UNAUTHORIZED: Anonymous callers cannot assign orders to registered user accounts';
        END IF;
        v_effective_user_id := NULL;
    END IF;

    -- Block Anonymous callers from creating Cashier/POS in-store orders
    IF (p_delivery_slot ILIKE '%كاشير%' OR p_delivery_slot ILIKE '%pos%') AND v_caller_id IS NULL AND NOT v_is_admin THEN
        RAISE EXCEPTION 'UNAUTHORIZED_POS: In-store POS cashier orders must be placed by authenticated staff';
    END IF;

    -- Determine Effective Branch ID
    v_target_branch_id := COALESCE(auth.branch_id(), p_branch_id, 'b-jed-01');
    SELECT name_ar INTO v_branch_name FROM public.branches WHERE id = v_target_branch_id;
    IF v_branch_name IS NULL THEN
        v_target_branch_id := 'b-jed-01';
        v_branch_name := 'فرع جدة الكورنيش (واجهة البحر)';
    END IF;

    -- Step 2: Idempotency Protection - Prevent double-submission
    IF EXISTS (SELECT 1 FROM public.orders WHERE order_number = p_order_number) THEN
        RAISE EXCEPTION 'DUPLICATE_ORDER: Order with number % already exists', p_order_number;
    END IF;

    -- Step 3: Validate Items Payload
    IF p_items IS NULL OR jsonb_array_length(p_items) = 0 THEN
        RAISE EXCEPTION 'EMPTY_ITEMS: Cannot place an order without items';
    END IF;

    -- Step 4: Validate Stock & Atomic Branch Row Locking & Price Verification
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_qty := (v_item->>'quantity')::numeric;
        IF v_qty <= 0 THEN
            RAISE EXCEPTION 'INVALID_QUANTITY: Quantity must be greater than zero';
        END IF;

        IF (v_item->>'product_id') IS NOT NULL AND (v_item->>'product_id') ~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$' THEN
            v_product_id := (v_item->>'product_id')::uuid;

            SELECT price INTO v_db_price
            FROM public.products
            WHERE id = v_product_id;

            IF FOUND THEN
                -- Atomic Branch Inventory Deduction with Locking FOR UPDATE & Anti-Overselling Guard
                PERFORM public.record_inventory_movement_atomic(
                    v_target_branch_id,
                    v_product_id,
                    'sale',
                    -v_qty,
                    0,
                    'order',
                    p_order_number,
                    auth.user_id(),
                    COALESCE(auth.jwt_claims()->>'full_name', 'نظام المبيعات الذكي'),
                    COALESCE(auth.user_role(), 'system'),
                    'مبيعات طلب رقم: ' || p_order_number
                );

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
        notes,
        branch_id,
        branch_name
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
        p_notes,
        v_target_branch_id,
        v_branch_name
    )
    RETURNING id INTO v_order_id;

    -- Step 7: Insert Order Items
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
        'branch_id', o.branch_id,
        'branch_name', o.branch_name,
        'created_at', o.created_at
    ) INTO v_result
    FROM public.orders o
    WHERE o.id = v_order_id;

    RETURN v_result;
END;
$$;

-- 12. Row Level Security Policies for the New Inventory Tables
ALTER TABLE public.branch_inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.branch_inventory FORCE ROW LEVEL SECURITY;

ALTER TABLE public.inventory_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory_movements FORCE ROW LEVEL SECURITY;

ALTER TABLE public.inventory_transfers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory_transfers FORCE ROW LEVEL SECURITY;

ALTER TABLE public.inventory_audits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory_audits FORCE ROW LEVEL SECURITY;

-- Policies on branch_inventory
DROP POLICY IF EXISTS "branch_inventory_select_policy" ON public.branch_inventory;
CREATE POLICY "branch_inventory_select_policy" ON public.branch_inventory
    FOR SELECT TO authenticated, anon
    USING (
        (auth.user_role() = ANY (ARRAY['super_admin', 'general_manager', 'auditor', 'accountant', 'warehouse_manager']))
        OR ((auth.user_role() = ANY (ARRAY['branch_manager', 'cashier'])) AND branch_id = auth.branch_id())
        OR auth.is_staff()
        OR (auth.user_role() = 'anon')
    );

DROP POLICY IF EXISTS "branch_inventory_admin_mutation" ON public.branch_inventory;
CREATE POLICY "branch_inventory_admin_mutation" ON public.branch_inventory
    FOR ALL TO authenticated
    USING (
        (auth.user_role() = ANY (ARRAY['super_admin', 'general_manager', 'warehouse_manager']))
        OR ((auth.user_role() = 'branch_manager') AND branch_id = auth.branch_id())
    )
    WITH CHECK (
        (auth.user_role() = ANY (ARRAY['super_admin', 'general_manager', 'warehouse_manager']))
        OR ((auth.user_role() = 'branch_manager') AND branch_id = auth.branch_id())
    );

-- Policies on inventory_movements
DROP POLICY IF EXISTS "inventory_movements_select_policy" ON public.inventory_movements;
CREATE POLICY "inventory_movements_select_policy" ON public.inventory_movements
    FOR SELECT TO authenticated
    USING (
        (auth.user_role() = ANY (ARRAY['super_admin', 'general_manager', 'auditor', 'accountant', 'warehouse_manager']))
        OR ((auth.user_role() = ANY (ARRAY['branch_manager', 'cashier'])) AND branch_id = auth.branch_id())
        OR auth.is_staff()
    );

DROP POLICY IF EXISTS "inventory_movements_admin_mutation" ON public.inventory_movements;
CREATE POLICY "inventory_movements_admin_mutation" ON public.inventory_movements
    FOR INSERT TO authenticated
    WITH CHECK (
        (auth.user_role() = ANY (ARRAY['super_admin', 'general_manager', 'warehouse_manager']))
        OR ((auth.user_role() = ANY (ARRAY['branch_manager', 'cashier'])) AND branch_id = auth.branch_id())
    );

-- Policies on inventory_transfers
DROP POLICY IF EXISTS "inventory_transfers_select_policy" ON public.inventory_transfers;
CREATE POLICY "inventory_transfers_select_policy" ON public.inventory_transfers
    FOR SELECT TO authenticated
    USING (
        (auth.user_role() = ANY (ARRAY['super_admin', 'general_manager', 'auditor', 'accountant', 'warehouse_manager']))
        OR ((auth.user_role() = 'branch_manager') AND (source_branch_id = auth.branch_id() OR destination_branch_id = auth.branch_id()))
        OR auth.is_staff()
    );

DROP POLICY IF EXISTS "inventory_transfers_admin_mutation" ON public.inventory_transfers;
CREATE POLICY "inventory_transfers_admin_mutation" ON public.inventory_transfers
    FOR ALL TO authenticated
    USING (
        (auth.user_role() = ANY (ARRAY['super_admin', 'general_manager', 'warehouse_manager']))
        OR ((auth.user_role() = 'branch_manager') AND (source_branch_id = auth.branch_id() OR destination_branch_id = auth.branch_id()))
    )
    WITH CHECK (
        (auth.user_role() = ANY (ARRAY['super_admin', 'general_manager', 'warehouse_manager']))
        OR ((auth.user_role() = 'branch_manager') AND (source_branch_id = auth.branch_id() OR destination_branch_id = auth.branch_id()))
    );

-- Policies on inventory_audits
DROP POLICY IF EXISTS "inventory_audits_select_policy" ON public.inventory_audits;
CREATE POLICY "inventory_audits_select_policy" ON public.inventory_audits
    FOR SELECT TO authenticated
    USING (
        (auth.user_role() = ANY (ARRAY['super_admin', 'general_manager', 'auditor', 'accountant', 'warehouse_manager']))
        OR ((auth.user_role() = 'branch_manager') AND branch_id = auth.branch_id())
        OR auth.is_staff()
    );

-- 13. Grant Permissions
GRANT SELECT ON public.branch_inventory TO anon, authenticated;
GRANT ALL ON public.branch_inventory TO authenticated;

GRANT SELECT ON public.inventory_movements TO authenticated;
GRANT INSERT ON public.inventory_movements TO authenticated;

GRANT SELECT ON public.inventory_transfers TO authenticated;
GRANT ALL ON public.inventory_transfers TO authenticated;

GRANT SELECT ON public.inventory_audits TO authenticated;
GRANT ALL ON public.inventory_audits TO authenticated;

GRANT EXECUTE ON FUNCTION public.record_inventory_movement_atomic TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.perform_inventory_transfer_step_atomic TO authenticated;
GRANT EXECUTE ON FUNCTION public.perform_stock_audit_reconciliation_atomic TO authenticated;
GRANT EXECUTE ON FUNCTION public.cancel_order_atomic TO authenticated;
GRANT EXECUTE ON FUNCTION public.process_order_return_atomic TO authenticated;
GRANT EXECUTE ON FUNCTION public.place_order_atomic TO anon, authenticated;

-- Record migration in _schema_migrations
INSERT INTO public._schema_migrations (filename, applied_at)
VALUES ('20261104_019_real_inventory_and_movements.sql', timezone('utc'::text, now()))
ON CONFLICT (filename) DO UPDATE SET applied_at = timezone('utc'::text, now());

COMMIT;
