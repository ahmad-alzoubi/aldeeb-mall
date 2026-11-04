-- ==============================================================================
-- 🏬 ALDEEB MALL: MULTI-BRANCH INDEPENDENT TRANSFERS & AUDIT LEDGER ENGINE
-- Migration: 20261104_019_branch_transfers_and_audit_ledger.sql
-- ==============================================================================

-- 1. Extend dark_stores with branch_id association
ALTER TABLE public.dark_stores 
ADD COLUMN IF NOT EXISTS branch_id VARCHAR(64) REFERENCES public.branches(id) ON DELETE SET NULL;

-- Ensure dark stores exist for all branches
DO $$
BEGIN
    -- Riyadh Flagship
    IF NOT EXISTS (SELECT 1 FROM public.dark_stores WHERE code = 'DS-RUH-01') THEN
        INSERT INTO public.dark_stores (id, code, name_ar, name_en, city, latitude, longitude, radius_km, is_active, avg_pick_time_seconds, branch_id)
        VALUES (
            '5e4c5f44-1b0b-47fc-853a-9609cff3c33a',
            'DS-RUH-01',
            'مستودع مركز الرياض اللوجستي الرئيسي',
            'Riyadh Central Logistics Warehouse',
            'الرياض',
            24.7136, 46.6753, 10.0, true, 90, 'b-ruh-01'
        )
        ON CONFLICT (id) DO UPDATE SET branch_id = 'b-ruh-01', name_ar = EXCLUDED.name_ar, city = EXCLUDED.city;
    ELSE
        UPDATE public.dark_stores SET branch_id = 'b-ruh-01' WHERE code = 'DS-RUH-01';
    END IF;

    -- Jeddah Corniche
    IF NOT EXISTS (SELECT 1 FROM public.dark_stores WHERE code = 'DS-JED-01') THEN
        INSERT INTO public.dark_stores (code, name_ar, name_en, city, latitude, longitude, radius_km, is_active, avg_pick_time_seconds, branch_id)
        VALUES (
            'DS-JED-01',
            'مستودع فرع جدة الكورنيش والساحل الغربي',
            'Jeddah Corniche Regional Hub',
            'جدة',
            21.5433, 39.1728, 8.0, true, 100, 'b-jed-01'
        );
    ELSE
        UPDATE public.dark_stores SET branch_id = 'b-jed-01' WHERE code = 'DS-JED-01';
    END IF;

    -- Dammam Eastern Province
    IF NOT EXISTS (SELECT 1 FROM public.dark_stores WHERE code = 'DS-DMM-01') THEN
        INSERT INTO public.dark_stores (code, name_ar, name_en, city, latitude, longitude, radius_km, is_active, avg_pick_time_seconds, branch_id)
        VALUES (
            'DS-DMM-01',
            'مستودع فرع الدمام ومول الشرقية',
            'Dammam Eastern Distribution Center',
            'الدمام',
            26.4207, 50.0888, 8.0, true, 110, 'b-dmm-01'
        );
    ELSE
        UPDATE public.dark_stores SET branch_id = 'b-dmm-01' WHERE code = 'DS-DMM-01';
    END IF;

    -- Damascus Central
    IF NOT EXISTS (SELECT 1 FROM public.dark_stores WHERE code = 'DS-DAM-01') THEN
        INSERT INTO public.dark_stores (code, name_ar, name_en, city, latitude, longitude, radius_km, is_active, avg_pick_time_seconds, branch_id)
        VALUES (
            'DS-DAM-01',
            'مستودع فرع دمشق المركزي (أوتوستراد المزة)',
            'Damascus Central Regional Warehouse',
            'دمشق',
            33.5138, 36.2765, 12.0, true, 95, 'b-dam-01'
        );
    ELSE
        UPDATE public.dark_stores SET branch_id = 'b-dam-01' WHERE code = 'DS-DAM-01';
    END IF;

    -- Al-Narjis Express Dark Store
    IF NOT EXISTS (SELECT 1 FROM public.dark_stores WHERE code = 'DS-RUH-DS02') THEN
        INSERT INTO public.dark_stores (code, name_ar, name_en, city, latitude, longitude, radius_km, is_active, avg_pick_time_seconds, branch_id)
        VALUES (
            'DS-RUH-DS02',
            'مركز تلبية النرجس فوري 15 دقيقة (Dark Store)',
            'Al-Narjis Express Dark Store Facility',
            'الرياض',
            24.8322, 46.6631, 3.5, true, 75, 'b-ruh-ds02'
        );
    ELSE
        UPDATE public.dark_stores SET branch_id = 'b-ruh-ds02' WHERE code = 'DS-RUH-DS02';
    END IF;
END $$;

-- 2. Extend dark_store_inventory with damaged, in-transit, and bin location
ALTER TABLE public.dark_store_inventory 
ADD COLUMN IF NOT EXISTS quantity_damaged INT NOT NULL DEFAULT 0 CHECK (quantity_damaged >= 0);

ALTER TABLE public.dark_store_inventory 
ADD COLUMN IF NOT EXISTS quantity_in_transit INT NOT NULL DEFAULT 0 CHECK (quantity_in_transit >= 0);

ALTER TABLE public.dark_store_inventory 
ADD COLUMN IF NOT EXISTS bin_location TEXT DEFAULT 'رف-A1-01';

-- Populate realistic initial stock in dark_store_inventory for all dark stores and catalog products
DO $$
DECLARE
    ds RECORD;
    prod RECORD;
BEGIN
    FOR ds IN SELECT id FROM public.dark_stores LOOP
        FOR prod IN SELECT id FROM public.products LOOP
            INSERT INTO public.dark_store_inventory (
                dark_store_id,
                product_id,
                quantity_on_hand,
                quantity_reserved,
                quantity_damaged,
                quantity_in_transit,
                safety_threshold,
                bin_location
            ) VALUES (
                ds.id,
                prod.id,
                150,
                0,
                0,
                0,
                10,
                'رف-' || chr(65 + (abs(hashtext(prod.id::text)) % 6)) || '-' || ((abs(hashtext(prod.id::text)) % 20) + 1)::text
            )
            ON CONFLICT (dark_store_id, product_id) DO NOTHING;
        END LOOP;
    END LOOP;
END $$;

-- 3. Extend inventory_transfers table
ALTER TABLE public.inventory_transfers DROP CONSTRAINT IF EXISTS inventory_transfers_status_check;
ALTER TABLE public.inventory_transfers ADD CONSTRAINT inventory_transfers_status_check 
CHECK (status = ANY (ARRAY['requested'::text, 'under_review'::text, 'approved'::text, 'reserved'::text, 'dispatched'::text, 'received'::text, 'closed'::text, 'cancelled'::text, 'compensated'::text, 'rejected'::text]));

ALTER TABLE public.inventory_transfers ADD COLUMN IF NOT EXISTS manifest_number TEXT;
UPDATE public.inventory_transfers SET manifest_number = transfer_number WHERE manifest_number IS NULL;

ALTER TABLE public.inventory_transfers ADD COLUMN IF NOT EXISTS source_warehouse_id UUID REFERENCES public.dark_stores(id) ON DELETE SET NULL;
ALTER TABLE public.inventory_transfers ADD COLUMN IF NOT EXISTS source_warehouse_name TEXT;
ALTER TABLE public.inventory_transfers ADD COLUMN IF NOT EXISTS destination_warehouse_id UUID REFERENCES public.dark_stores(id) ON DELETE SET NULL;
ALTER TABLE public.inventory_transfers ADD COLUMN IF NOT EXISTS destination_warehouse_name TEXT;
ALTER TABLE public.inventory_transfers ADD COLUMN IF NOT EXISTS product_name_ar TEXT;
ALTER TABLE public.inventory_transfers ADD COLUMN IF NOT EXISTS barcode TEXT;
ALTER TABLE public.inventory_transfers ADD COLUMN IF NOT EXISTS quantity_reserved NUMERIC(12,2) NOT NULL DEFAULT 0;
ALTER TABLE public.inventory_transfers ADD COLUMN IF NOT EXISTS quantity_received_good NUMERIC(12,2) NOT NULL DEFAULT 0;
ALTER TABLE public.inventory_transfers ADD COLUMN IF NOT EXISTS discrepancy_quantity NUMERIC(12,2) NOT NULL DEFAULT 0;
ALTER TABLE public.inventory_transfers ADD COLUMN IF NOT EXISTS idempotency_key TEXT;
ALTER TABLE public.inventory_transfers ADD COLUMN IF NOT EXISTS approved_at TIMESTAMPTZ;
ALTER TABLE public.inventory_transfers ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMPTZ;
ALTER TABLE public.inventory_transfers ADD COLUMN IF NOT EXISTS compensated_at TIMESTAMPTZ;
ALTER TABLE public.inventory_transfers ADD COLUMN IF NOT EXISTS compensation_notes TEXT;
ALTER TABLE public.inventory_transfers ADD COLUMN IF NOT EXISTS notes TEXT;

CREATE UNIQUE INDEX IF NOT EXISTS idx_transfers_idempotency ON public.inventory_transfers(idempotency_key) WHERE idempotency_key IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_transfers_manifest ON public.inventory_transfers(manifest_number);

-- 4. Extend inventory_movements table
ALTER TABLE public.inventory_movements ADD COLUMN IF NOT EXISTS warehouse_id UUID REFERENCES public.dark_stores(id) ON DELETE SET NULL;

ALTER TABLE public.inventory_movements DROP CONSTRAINT IF EXISTS inventory_movements_movement_type_check;
ALTER TABLE public.inventory_movements ADD CONSTRAINT inventory_movements_movement_type_check 
CHECK (movement_type = ANY (ARRAY['supply'::text, 'reservation'::text, 'release_reservation'::text, 'disbursement'::text, 'sale'::text, 'return'::text, 'damaged'::text, 'audit_reconciliation'::text, 'adjustment'::text, 'transfer_out'::text, 'transfer_in'::text, 'reserved'::text, 'unreserved'::text, 'compensated'::text]));

-- 5. Audit Logs Table (if not exists)
CREATE TABLE IF NOT EXISTS public.audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_id TEXT NOT NULL,
    actor_name TEXT NOT NULL,
    actor_role TEXT NOT NULL,
    action TEXT NOT NULL,
    category TEXT NOT NULL DEFAULT 'inventory',
    target_id TEXT,
    target_type TEXT,
    branch_id VARCHAR(64) REFERENCES public.branches(id) ON DELETE SET NULL,
    details TEXT NOT NULL,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_category ON public.audit_logs (category);
CREATE INDEX IF NOT EXISTS idx_audit_logs_branch_id ON public.audit_logs (branch_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON public.audit_logs (created_at DESC);

-- 6. Inventory Compensations Table (if not exists)
CREATE TABLE IF NOT EXISTS public.inventory_compensations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transfer_id UUID REFERENCES public.inventory_transfers(id) ON DELETE CASCADE,
    manifest_number TEXT NOT NULL,
    source_branch_id VARCHAR(64) REFERENCES public.branches(id) ON DELETE SET NULL,
    destination_branch_id VARCHAR(64) REFERENCES public.branches(id) ON DELETE SET NULL,
    compensation_type TEXT NOT NULL CHECK (compensation_type IN ('credit_note', 'replacement_dispatch', 'loss_write_off', 'supplier_claim')),
    damaged_quantity INTEGER NOT NULL DEFAULT 0,
    missing_quantity INTEGER NOT NULL DEFAULT 0,
    compensation_amount NUMERIC(14,2) NOT NULL DEFAULT 0.00,
    notes TEXT,
    settled_by TEXT NOT NULL,
    settled_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- ==============================================================================
-- 7. ATOMIC BUSINESS RPCS WITH STRICT CONCURRENCY LOCKS & IDEMPOTENCY
-- ==============================================================================

-- 7.1. Create Transfer Request
CREATE OR REPLACE FUNCTION public.rpc_create_inventory_transfer(
    p_source_warehouse_id UUID,
    p_dest_warehouse_id UUID,
    p_product_id UUID,
    p_quantity INT,
    p_actor_id TEXT DEFAULT 'system',
    p_actor_name TEXT DEFAULT 'مسؤول العمليات',
    p_actor_role TEXT DEFAULT 'warehouse_manager',
    p_idempotency_key TEXT DEFAULT NULL,
    p_notes TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_src_wh RECORD;
    v_dest_wh RECORD;
    v_prod RECORD;
    v_stock RECORD;
    v_idem_key TEXT;
    v_manifest TEXT;
    v_transfer_id UUID;
    v_result JSONB;
BEGIN
    IF p_quantity <= 0 THEN
        RAISE EXCEPTION 'INVALID_QUANTITY: Requested quantity must be greater than zero.';
    END IF;

    IF p_source_warehouse_id = p_dest_warehouse_id THEN
        RAISE EXCEPTION 'SAME_WAREHOUSE: Source and destination warehouses must be distinct.';
    END IF;

    -- Validate Warehouses
    SELECT id, name_ar, branch_id INTO v_src_wh FROM public.dark_stores WHERE id = p_source_warehouse_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'SOURCE_WH_NOT_FOUND: Source warehouse does not exist.';
    END IF;

    SELECT id, name_ar, branch_id INTO v_dest_wh FROM public.dark_stores WHERE id = p_dest_warehouse_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'DEST_WH_NOT_FOUND: Destination warehouse does not exist.';
    END IF;

    -- Validate Product
    SELECT id, name_ar, barcode, price INTO v_prod FROM public.products WHERE id = p_product_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'PRODUCT_NOT_FOUND: Product does not exist.';
    END IF;

    -- Check Source Stock
    SELECT * INTO v_stock FROM public.dark_store_inventory 
    WHERE dark_store_id = p_source_warehouse_id AND product_id = p_product_id;

    IF NOT FOUND OR (v_stock.quantity_on_hand - v_stock.quantity_reserved) < p_quantity THEN
        RAISE EXCEPTION 'INSUFFICIENT_STOCK: Source warehouse does not have enough unreserved available stock (% available, % requested).',
            COALESCE(v_stock.quantity_on_hand - v_stock.quantity_reserved, 0), p_quantity;
    END IF;

    -- Idempotency resolution
    v_idem_key := COALESCE(p_idempotency_key, 'IDEM-TRF-' || p_source_warehouse_id::text || '-' || p_dest_warehouse_id::text || '-' || extract(epoch from now())::text);

    -- Check if transfer already exists with this idempotency key
    SELECT id INTO v_transfer_id FROM public.inventory_transfers WHERE idempotency_key = v_idem_key;
    IF FOUND THEN
        SELECT to_jsonb(t.*) INTO v_result FROM public.inventory_transfers t WHERE t.id = v_transfer_id;
        RETURN v_result;
    END IF;

    -- Generate Manifest Number
    v_manifest := 'TRF-2026-' || lpad((abs(hashtext(v_idem_key)) % 90000 + 10000)::text, 5, '0');

    -- Insert Transfer
    INSERT INTO public.inventory_transfers (
        transfer_number,
        manifest_number,
        source_branch_id,
        source_warehouse_id,
        source_warehouse_name,
        destination_branch_id,
        destination_warehouse_id,
        destination_warehouse_name,
        product_id,
        product_name_ar,
        barcode,
        quantity_requested,
        status,
        idempotency_key,
        requested_by,
        notes
    ) VALUES (
        v_manifest,
        v_manifest,
        v_src_wh.branch_id,
        v_src_wh.id,
        v_src_wh.name_ar,
        v_dest_wh.branch_id,
        v_dest_wh.id,
        v_dest_wh.name_ar,
        v_prod.id,
        v_prod.name_ar,
        v_prod.barcode,
        p_quantity,
        'requested',
        v_idem_key,
        p_actor_name,
        p_notes
    ) RETURNING id INTO v_transfer_id;

    -- Record Audit Log
    INSERT INTO public.audit_logs (
        actor_id, actor_name, actor_role, action, category, target_id, target_type, branch_id, details
    ) VALUES (
        p_actor_id, p_actor_name, p_actor_role, 'TRANSFER_REQUESTED', 'inventory', v_transfer_id::text, 'inventory_transfers',
        v_src_wh.branch_id,
        'طلب مناقلة صادر رقم ' || v_manifest || ' لصنف (' || v_prod.name_ar || ') بكمية ' || p_quantity || ' من ' || v_src_wh.name_ar || ' إلى ' || v_dest_wh.name_ar
    );

    SELECT to_jsonb(t.*) INTO v_result FROM public.inventory_transfers t WHERE t.id = v_transfer_id;
    RETURN v_result;
END;
$$;

-- 7.2. Approve & Reserve Source Stock
CREATE OR REPLACE FUNCTION public.rpc_approve_and_reserve_transfer(
    p_transfer_id UUID,
    p_actor_id TEXT DEFAULT 'system',
    p_actor_name TEXT DEFAULT 'مدير المستودعات',
    p_actor_role TEXT DEFAULT 'warehouse_manager'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_tr public.inventory_transfers%ROWTYPE;
    v_stock public.dark_store_inventory%ROWTYPE;
    v_result JSONB;
BEGIN
    SELECT * INTO v_tr FROM public.inventory_transfers WHERE id = p_transfer_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'TRANSFER_NOT_FOUND: Transfer order does not exist.';
    END IF;

    IF v_tr.status != 'requested' AND v_tr.status != 'under_review' THEN
        RAISE EXCEPTION 'INVALID_STATE: Transfer is already in state "%", cannot approve.', v_tr.status;
    END IF;

    -- Lock Source Stock Row
    SELECT * INTO v_stock FROM public.dark_store_inventory 
    WHERE dark_store_id = v_tr.source_warehouse_id AND product_id = v_tr.product_id 
    FOR UPDATE;

    IF NOT FOUND OR (v_stock.quantity_on_hand - v_stock.quantity_reserved) < v_tr.quantity_requested THEN
        RAISE EXCEPTION 'INSUFFICIENT_STOCK: Source inventory unreserved stock (% available) cannot satisfy reservation (% requested).',
            COALESCE(v_stock.quantity_on_hand - v_stock.quantity_reserved, 0), v_tr.quantity_requested;
    END IF;

    -- Reserve in Source Stock
    UPDATE public.dark_store_inventory 
    SET quantity_reserved = quantity_reserved + v_tr.quantity_requested,
        updated_at = timezone('utc'::text, now())
    WHERE id = v_stock.id;

    -- Update Transfer
    UPDATE public.inventory_transfers 
    SET status = 'reserved',
        quantity_reserved = quantity_requested,
        approved_at = timezone('utc'::text, now())
    WHERE id = p_transfer_id;

    -- Log Movement
    INSERT INTO public.inventory_movements (
        movement_number, branch_id, product_id, warehouse_id, movement_type,
        quantity_change, quantity_reserved_change, resulting_on_hand, resulting_reserved,
        reference_type, reference_id, actor_id, actor_name, actor_role, notes
    ) VALUES (
        'MOV-RSV-' || floor(random()*90000 + 10000)::text,
        v_tr.source_branch_id, v_tr.product_id, v_tr.source_warehouse_id, 'reservation',
        0, v_tr.quantity_requested, v_stock.quantity_on_hand, v_stock.quantity_reserved + v_tr.quantity_requested,
        'transfer', v_tr.transfer_number, p_actor_id, p_actor_name, p_actor_role,
        'حجز كمية المناقلة في المستودع المصدر'
    );

    -- Log Audit
    INSERT INTO public.audit_logs (
        actor_id, actor_name, actor_role, action, category, target_id, target_type, branch_id, details
    ) VALUES (
        p_actor_id, p_actor_name, p_actor_role, 'TRANSFER_APPROVED_RESERVED', 'inventory', p_transfer_id::text, 'inventory_transfers',
        v_tr.source_branch_id,
        'اعتماد وحجز المناقلة ' || v_tr.transfer_number || ' لصنف (' || COALESCE(v_tr.product_name_ar, 'صنف تمويني') || ') كمية ' || v_tr.quantity_requested
    );

    SELECT to_jsonb(t.*) INTO v_result FROM public.inventory_transfers t WHERE t.id = p_transfer_id;
    RETURN v_result;
END;
$$;

-- 7.3. Dispatch Transfer (Move from Reserved to In-Transit)
CREATE OR REPLACE FUNCTION public.rpc_dispatch_transfer(
    p_transfer_id UUID,
    p_assigned_driver TEXT DEFAULT 'كابتن النقل والترحيل',
    p_actor_id TEXT DEFAULT 'system',
    p_actor_name TEXT DEFAULT 'مسؤول الشحن والتوزيع',
    p_actor_role TEXT DEFAULT 'warehouse_manager'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_tr public.inventory_transfers%ROWTYPE;
    v_stock public.dark_store_inventory%ROWTYPE;
    v_result JSONB;
BEGIN
    SELECT * INTO v_tr FROM public.inventory_transfers WHERE id = p_transfer_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'TRANSFER_NOT_FOUND: Transfer order does not exist.';
    END IF;

    IF v_tr.status != 'reserved' AND v_tr.status != 'approved' THEN
        RAISE EXCEPTION 'INVALID_STATE: Transfer is in status "%", cannot dispatch without reservation.', v_tr.status;
    END IF;

    -- Lock Source Stock
    SELECT * INTO v_stock FROM public.dark_store_inventory 
    WHERE dark_store_id = v_tr.source_warehouse_id AND product_id = v_tr.product_id 
    FOR UPDATE;

    -- Deduct from source on-hand and reserved, add to in-transit
    UPDATE public.dark_store_inventory 
    SET quantity_on_hand = quantity_on_hand - v_tr.quantity_requested,
        quantity_reserved = GREATEST(0, quantity_reserved - v_tr.quantity_requested),
        quantity_in_transit = quantity_in_transit + v_tr.quantity_requested,
        updated_at = timezone('utc'::text, now())
    WHERE id = v_stock.id;

    -- Update Transfer
    UPDATE public.inventory_transfers 
    SET status = 'dispatched',
        quantity_dispatched = quantity_requested,
        assigned_driver = p_assigned_driver,
        dispatched_by = p_actor_name,
        dispatched_at = timezone('utc'::text, now())
    WHERE id = p_transfer_id;

    -- Log Movement
    INSERT INTO public.inventory_movements (
        movement_number, branch_id, product_id, warehouse_id, movement_type,
        quantity_change, quantity_reserved_change, resulting_on_hand, resulting_reserved,
        reference_type, reference_id, actor_id, actor_name, actor_role, notes
    ) VALUES (
        'MOV-DSP-' || floor(random()*90000 + 10000)::text,
        v_tr.source_branch_id, v_tr.product_id, v_tr.source_warehouse_id, 'transfer_out',
        -v_tr.quantity_requested, -v_tr.quantity_requested, v_stock.quantity_on_hand - v_tr.quantity_requested, v_stock.quantity_reserved - v_tr.quantity_requested,
        'transfer', v_tr.transfer_number, p_actor_id, p_actor_name, p_actor_role,
        'شحن المناقلة وإخراجها مع السائق ' || p_assigned_driver
    );

    -- Log Audit
    INSERT INTO public.audit_logs (
        actor_id, actor_name, actor_role, action, category, target_id, target_type, branch_id, details
    ) VALUES (
        p_actor_id, p_actor_name, p_actor_role, 'TRANSFER_DISPATCHED', 'inventory', p_transfer_id::text, 'inventory_transfers',
        v_tr.source_branch_id,
        'شحن وتسيير المناقلة ' || v_tr.transfer_number || ' مع ' || p_assigned_driver || ' متجهة إلى ' || COALESCE(v_tr.destination_warehouse_name, v_tr.destination_branch_id)
    );

    SELECT to_jsonb(t.*) INTO v_result FROM public.inventory_transfers t WHERE t.id = p_transfer_id;
    RETURN v_result;
END;
$$;

-- 7.4. Receive, Match, Record Damage/Discrepancies, and Close with Strict Anti-Duplicate Locks
CREATE OR REPLACE FUNCTION public.rpc_receive_and_close_transfer(
    p_transfer_id UUID,
    p_good_qty INT,
    p_damaged_qty INT DEFAULT 0,
    p_discrepancy_reason TEXT DEFAULT NULL,
    p_actor_id TEXT DEFAULT 'system',
    p_actor_name TEXT DEFAULT 'أمين مستودع الاستلام والمطابقة',
    p_actor_role TEXT DEFAULT 'receiving_officer',
    p_idempotency_key TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_tr public.inventory_transfers%ROWTYPE;
    v_src_stock public.dark_store_inventory%ROWTYPE;
    v_dest_stock public.dark_store_inventory%ROWTYPE;
    v_missing INT;
    v_result JSONB;
BEGIN
    SELECT * INTO v_tr FROM public.inventory_transfers WHERE id = p_transfer_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'TRANSFER_NOT_FOUND: Transfer order does not exist.';
    END IF;

    -- Strict Anti-Duplicate Receipt Check
    IF v_tr.audit_locked = true OR v_tr.status = 'closed' OR v_tr.status = 'compensated' THEN
        RAISE EXCEPTION 'TRANSFER_ALREADY_CLOSED: Manifest % is already closed and audit locked. Duplicate receipt is strictly forbidden.', v_tr.transfer_number;
    END IF;

    IF v_tr.status != 'dispatched' AND v_tr.status != 'received' THEN
        RAISE EXCEPTION 'INVALID_STATE: Manifest % is in status "%", it must be dispatched before receiving.', v_tr.transfer_number, v_tr.status;
    END IF;

    IF p_good_qty < 0 OR p_damaged_qty < 0 THEN
        RAISE EXCEPTION 'INVALID_QUANTITIES: Received and damaged quantities cannot be negative.';
    END IF;

    -- Discrepancy Calculation
    v_missing := v_tr.quantity_dispatched - (p_good_qty + p_damaged_qty);

    IF v_missing != 0 AND (p_discrepancy_reason IS NULL OR length(trim(p_discrepancy_reason)) = 0) THEN
        RAISE EXCEPTION 'DISCREPANCY_REASON_REQUIRED: Detected discrepancy of % items. Discrepancy explanation reason is mandatory.', v_missing;
    END IF;

    -- 1. Deduct in-transit from Source Warehouse
    SELECT * INTO v_src_stock FROM public.dark_store_inventory 
    WHERE dark_store_id = v_tr.source_warehouse_id AND product_id = v_tr.product_id 
    FOR UPDATE;

    IF FOUND THEN
        UPDATE public.dark_store_inventory 
        SET quantity_in_transit = GREATEST(0, quantity_in_transit - v_tr.quantity_dispatched),
            updated_at = timezone('utc'::text, now())
        WHERE id = v_src_stock.id;
    END IF;

    -- 2. Add good quantity and damaged quantity to Destination Warehouse
    SELECT * INTO v_dest_stock FROM public.dark_store_inventory 
    WHERE dark_store_id = v_tr.destination_warehouse_id AND product_id = v_tr.product_id 
    FOR UPDATE;

    IF FOUND THEN
        UPDATE public.dark_store_inventory 
        SET quantity_on_hand = quantity_on_hand + p_good_qty,
            quantity_damaged = quantity_damaged + p_damaged_qty,
            updated_at = timezone('utc'::text, now())
        WHERE id = v_dest_stock.id;
    ELSE
        INSERT INTO public.dark_store_inventory (
            dark_store_id, product_id, quantity_on_hand, quantity_reserved, quantity_damaged, quantity_in_transit, safety_threshold, bin_location
        ) VALUES (
            v_tr.destination_warehouse_id, v_tr.product_id, p_good_qty, 0, p_damaged_qty, 0, 10, 'رف-A1-01'
        );
    END IF;

    -- 3. Close Transfer and Lock Audit Trail
    UPDATE public.inventory_transfers 
    SET status = 'closed',
        quantity_received = p_good_qty,
        quantity_received_good = p_good_qty,
        quantity_damaged = p_damaged_qty,
        discrepancy_quantity = v_missing,
        discrepancy_reason = p_discrepancy_reason,
        audit_locked = true,
        received_by = p_actor_name,
        received_at = timezone('utc'::text, now()),
        closed_at = timezone('utc'::text, now())
    WHERE id = p_transfer_id;

    -- 4. Log Movement for Inbound Good Items
    IF p_good_qty > 0 THEN
        INSERT INTO public.inventory_movements (
            movement_number, branch_id, product_id, warehouse_id, movement_type,
            quantity_change, quantity_reserved_change, resulting_on_hand, resulting_reserved,
            reference_type, reference_id, actor_id, actor_name, actor_role, notes
        ) VALUES (
            'MOV-IN-' || floor(random()*90000 + 10000)::text,
            v_tr.destination_branch_id, v_tr.product_id, v_tr.destination_warehouse_id, 'transfer_in',
            p_good_qty, 0, COALESCE(v_dest_stock.quantity_on_hand, 0) + p_good_qty, COALESCE(v_dest_stock.quantity_reserved, 0),
            'transfer', v_tr.transfer_number, p_actor_id, p_actor_name, p_actor_role,
            'استلام وإيداع سليم من مناقلة واردة'
        );
    END IF;

    -- 5. Log Movement for Inbound Damaged Items
    IF p_damaged_qty > 0 THEN
        INSERT INTO public.inventory_movements (
            movement_number, branch_id, product_id, warehouse_id, movement_type,
            quantity_change, quantity_reserved_change, resulting_on_hand, resulting_reserved,
            reference_type, reference_id, actor_id, actor_name, actor_role, notes
        ) VALUES (
            'MOV-DMG-' || floor(random()*90000 + 10000)::text,
            v_tr.destination_branch_id, v_tr.product_id, v_tr.destination_warehouse_id, 'damaged',
            0, 0, COALESCE(v_dest_stock.quantity_on_hand, 0) + p_good_qty, COALESCE(v_dest_stock.quantity_reserved, 0),
            'transfer', v_tr.transfer_number, p_actor_id, p_actor_name, p_actor_role,
            'تسجيل توالف مناقلة واردة: ' || COALESCE(p_discrepancy_reason, 'تلف أثناء الشحن')
        );
    END IF;

    -- 6. Log Comprehensive Audit Event
    INSERT INTO public.audit_logs (
        actor_id, actor_name, actor_role, action, category, target_id, target_type, branch_id, details, metadata
    ) VALUES (
        p_actor_id, p_actor_name, p_actor_role, 'TRANSFER_CLOSED_MATCHED', 'inventory', p_transfer_id::text, 'inventory_transfers',
        v_tr.destination_branch_id,
        'مطابقة وإغلاق المناقلة ' || v_tr.transfer_number || ': استلام ' || p_good_qty || ' سليم، ' || p_damaged_qty || ' تالف، ' || v_missing || ' فروقات/فواقد.',
        jsonb_build_object('good', p_good_qty, 'damaged', p_damaged_qty, 'missing', v_missing, 'reason', p_discrepancy_reason)
    );

    SELECT to_jsonb(t.*) INTO v_result FROM public.inventory_transfers t WHERE t.id = p_transfer_id;
    RETURN v_result;
END;
$$;

-- 7.5. Cancel Transfer with Automatic Stock Rollback
CREATE OR REPLACE FUNCTION public.rpc_cancel_transfer(
    p_transfer_id UUID,
    p_reason TEXT DEFAULT 'إلغاء بناءً على طلب الإدارة',
    p_actor_id TEXT DEFAULT 'system',
    p_actor_name TEXT DEFAULT 'مدير العمليات',
    p_actor_role TEXT DEFAULT 'warehouse_manager'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_tr public.inventory_transfers%ROWTYPE;
    v_stock public.dark_store_inventory%ROWTYPE;
    v_result JSONB;
BEGIN
    SELECT * INTO v_tr FROM public.inventory_transfers WHERE id = p_transfer_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'TRANSFER_NOT_FOUND: Transfer order does not exist.';
    END IF;

    IF v_tr.status = 'closed' OR v_tr.status = 'compensated' OR v_tr.status = 'cancelled' THEN
        RAISE EXCEPTION 'CANNOT_CANCEL: Transfer is in status "%", cancellation is not permitted.', v_tr.status;
    END IF;

    -- Rollback stock based on state
    IF v_tr.status = 'reserved' THEN
        -- Unreserve source stock
        SELECT * INTO v_stock FROM public.dark_store_inventory 
        WHERE dark_store_id = v_tr.source_warehouse_id AND product_id = v_tr.product_id 
        FOR UPDATE;

        IF FOUND THEN
            UPDATE public.dark_store_inventory 
            SET quantity_reserved = GREATEST(0, quantity_reserved - v_tr.quantity_requested),
                updated_at = timezone('utc'::text, now())
            WHERE id = v_stock.id;

            INSERT INTO public.inventory_movements (
                movement_number, branch_id, product_id, warehouse_id, movement_type,
                quantity_change, quantity_reserved_change, resulting_on_hand, resulting_reserved,
                reference_type, reference_id, actor_id, actor_name, actor_role, notes
            ) VALUES (
                'MOV-REL-' || floor(random()*90000 + 10000)::text,
                v_tr.source_branch_id, v_tr.product_id, v_tr.source_warehouse_id, 'release_reservation',
                0, -v_tr.quantity_requested, v_stock.quantity_on_hand, v_stock.quantity_reserved - v_tr.quantity_requested,
                'transfer', v_tr.transfer_number, p_actor_id, p_actor_name, p_actor_role,
                'فك حجز مناقلة ملغاة: ' || p_reason
            );
        END IF;

    ELSIF v_tr.status = 'dispatched' THEN
        -- Return from in-transit back to on-hand
        SELECT * INTO v_stock FROM public.dark_store_inventory 
        WHERE dark_store_id = v_tr.source_warehouse_id AND product_id = v_tr.product_id 
        FOR UPDATE;

        IF FOUND THEN
            UPDATE public.dark_store_inventory 
            SET quantity_on_hand = quantity_on_hand + v_tr.quantity_dispatched,
                quantity_in_transit = GREATEST(0, quantity_in_transit - v_tr.quantity_dispatched),
                updated_at = timezone('utc'::text, now())
            WHERE id = v_stock.id;

            INSERT INTO public.inventory_movements (
                movement_number, branch_id, product_id, warehouse_id, movement_type,
                quantity_change, quantity_reserved_change, resulting_on_hand, resulting_reserved,
                reference_type, reference_id, actor_id, actor_name, actor_role, notes
            ) VALUES (
                'MOV-RET-' || floor(random()*90000 + 10000)::text,
                v_tr.source_branch_id, v_tr.product_id, v_tr.source_warehouse_id, 'transfer_in',
                v_tr.quantity_dispatched, 0, v_stock.quantity_on_hand + v_tr.quantity_dispatched, v_stock.quantity_reserved,
                'transfer', v_tr.transfer_number, p_actor_id, p_actor_name, p_actor_role,
                'إرجاع شحنة مناقلة ملغاة إلى الرصيد: ' || p_reason
            );
        END IF;
    END IF;

    -- Update Transfer
    UPDATE public.inventory_transfers 
    SET status = 'cancelled',
        audit_locked = true,
        cancelled_at = timezone('utc'::text, now()),
        notes = COALESCE(notes, '') || ' | سبب الإلغاء: ' || p_reason
    WHERE id = p_transfer_id;

    -- Log Audit
    INSERT INTO public.audit_logs (
        actor_id, actor_name, actor_role, action, category, target_id, target_type, branch_id, details
    ) VALUES (
        p_actor_id, p_actor_name, p_actor_role, 'TRANSFER_CANCELLED', 'inventory', p_transfer_id::text, 'inventory_transfers',
        v_tr.source_branch_id,
        'إلغاء المناقلة ' || v_tr.transfer_number || ' وإرجاع الأرصدة إلى حالتها السابقة. السبب: ' || p_reason
    );

    SELECT to_jsonb(t.*) INTO v_result FROM public.inventory_transfers t WHERE t.id = p_transfer_id;
    RETURN v_result;
END;
$$;

-- 7.6. Compensate Transfer (تعويض التوالف والفروقات)
CREATE OR REPLACE FUNCTION public.rpc_compensate_transfer(
    p_transfer_id UUID,
    p_compensation_type TEXT DEFAULT 'credit_note',
    p_notes TEXT DEFAULT 'تسوية تعويض الفروقات والتوالف بين الفروع',
    p_actor_id TEXT DEFAULT 'system',
    p_actor_name TEXT DEFAULT 'المدقق المالي والمحاسب',
    p_actor_role TEXT DEFAULT 'auditor'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_tr public.inventory_transfers%ROWTYPE;
    v_prod public.products%ROWTYPE;
    v_amount NUMERIC(14,2);
    v_comp_id UUID;
    v_result JSONB;
BEGIN
    SELECT * INTO v_tr FROM public.inventory_transfers WHERE id = p_transfer_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'TRANSFER_NOT_FOUND: Transfer order does not exist.';
    END IF;

    IF v_tr.status != 'closed' THEN
        RAISE EXCEPTION 'CANNOT_COMPENSATE: Transfer must be closed before compensation settlement (current status: %).', v_tr.status;
    END IF;

    IF v_tr.quantity_damaged <= 0 AND v_tr.discrepancy_quantity <= 0 THEN
        RAISE EXCEPTION 'NO_LOSSES: Transfer has 0 damaged and 0 discrepancy items. No compensation needed.';
    END IF;

    SELECT * INTO v_prod FROM public.products WHERE id = v_tr.product_id;
    v_amount := (COALESCE(v_tr.quantity_damaged, 0) + COALESCE(v_tr.discrepancy_quantity, 0)) * COALESCE(v_prod.price, 10.00);

    -- Insert Compensation Record
    INSERT INTO public.inventory_compensations (
        transfer_id,
        manifest_number,
        source_branch_id,
        destination_branch_id,
        compensation_type,
        damaged_quantity,
        missing_quantity,
        compensation_amount,
        notes,
        settled_by
    ) VALUES (
        p_transfer_id,
        v_tr.transfer_number,
        v_tr.source_branch_id,
        v_tr.destination_branch_id,
        p_compensation_type,
        v_tr.quantity_damaged::integer,
        v_tr.discrepancy_quantity::integer,
        v_amount,
        p_notes,
        p_actor_name
    ) RETURNING id INTO v_comp_id;

    -- Update Transfer
    UPDATE public.inventory_transfers 
    SET status = 'compensated',
        compensation_notes = p_notes,
        compensated_at = timezone('utc'::text, now())
    WHERE id = p_transfer_id;

    -- Log Audit
    INSERT INTO public.audit_logs (
        actor_id, actor_name, actor_role, action, category, target_id, target_type, branch_id, details, metadata
    ) VALUES (
        p_actor_id, p_actor_name, p_actor_role, 'TRANSFER_COMPENSATED', 'financial', p_transfer_id::text, 'inventory_transfers',
        v_tr.destination_branch_id,
        'تسوية تعويض مالي/سلعي للمناقلة ' || v_tr.transfer_number || ' بمبلغ ' || v_amount || ' ل.س (' || p_compensation_type || ').',
        jsonb_build_object('compensation_id', v_comp_id, 'amount', v_amount, 'type', p_compensation_type, 'notes', p_notes)
    );

    SELECT to_jsonb(t.*) INTO v_result FROM public.inventory_transfers t WHERE t.id = p_transfer_id;
    RETURN v_result;
END;
$$;

-- 7.7. Atomic Branch Creation with Isolated Schema Provisioning and Default Warehouse
CREATE OR REPLACE FUNCTION public.rpc_create_branch_atomic(
    p_code TEXT,
    p_name_ar TEXT,
    p_name_en TEXT,
    p_city TEXT,
    p_district TEXT DEFAULT '',
    p_address TEXT DEFAULT '',
    p_phone TEXT DEFAULT '',
    p_manager_name TEXT DEFAULT '',
    p_type TEXT DEFAULT 'supermarket',
    p_terminals_count INT DEFAULT 4,
    p_currency TEXT DEFAULT 'ل.س',
    p_actor_id TEXT DEFAULT 'system',
    p_actor_name TEXT DEFAULT 'المسؤول العام'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_branch_id VARCHAR(64);
    v_schema_result JSONB;
    v_wh_id UUID;
    v_branch public.branches%ROWTYPE;
    v_prod RECORD;
BEGIN
    v_branch_id := 'b-' || lower(regexp_replace(p_code, '[^a-zA-Z0-9]', '', 'g'));

    -- 1. Insert Branch Record
    INSERT INTO public.branches (
        id, code, name_ar, name_en, city, district, address, phone, manager_name,
        is_active, terminals_count, daily_sales, currency, type
    ) VALUES (
        v_branch_id, upper(p_code), p_name_ar, p_name_en, p_city, p_district, p_address, p_phone, p_manager_name,
        true, p_terminals_count, 0.00, p_currency, p_type
    )
    ON CONFLICT (code) DO UPDATE SET
        name_ar = EXCLUDED.name_ar,
        name_en = EXCLUDED.name_en,
        city = EXCLUDED.city,
        district = EXCLUDED.district,
        address = EXCLUDED.address,
        phone = EXCLUDED.phone,
        manager_name = EXCLUDED.manager_name,
        terminals_count = EXCLUDED.terminals_count,
        type = EXCLUDED.type
    RETURNING * INTO v_branch;

    -- 2. Provision Isolated Physical Schema for Branch
    v_schema_result := public.provision_isolated_branch_schema(p_code, p_name_ar, p_city, p_currency);

    -- 3. Create Default Dark Store Warehouse for this Branch
    INSERT INTO public.dark_stores (
        code, name_ar, name_en, city, latitude, longitude, radius_km, is_active, avg_pick_time_seconds, branch_id
    ) VALUES (
        'WH-' || upper(regexp_replace(p_code, '[^a-zA-Z0-9]', '', 'g')),
        'مستودع ' || p_name_ar,
        'Warehouse ' || p_name_en,
        p_city,
        24.7136, 46.6753, 5.0, true, 90, v_branch_id
    )
    ON CONFLICT (code) DO UPDATE SET
        branch_id = v_branch_id,
        name_ar = EXCLUDED.name_ar
    RETURNING id INTO v_wh_id;

    -- 4. Seed initial stock for this branch warehouse
    FOR v_prod IN SELECT id FROM public.products LOOP
        INSERT INTO public.dark_store_inventory (
            dark_store_id, product_id, quantity_on_hand, quantity_reserved, quantity_damaged, quantity_in_transit, safety_threshold, bin_location
        ) VALUES (
            v_wh_id, v_prod.id, 100, 0, 0, 0, 10, 'رف-A1-01'
        )
        ON CONFLICT (dark_store_id, product_id) DO NOTHING;
    END LOOP;

    -- 5. Record Audit
    INSERT INTO public.audit_logs (
        actor_id, actor_name, actor_role, action, category, target_id, target_type, branch_id, details
    ) VALUES (
        p_actor_id, p_actor_name, 'super_admin', 'BRANCH_PROVISIONED', 'system', v_branch_id, 'branches',
        v_branch_id,
        'تهيئة وإنشاء الفرع ' || p_name_ar || ' (' || upper(p_code) || ') مع مستودعه وعزل الـ Schema المستقلة بنجاح.'
    );

    RETURN jsonb_build_object(
        'success', true,
        'branch', to_jsonb(v_branch),
        'warehouse_id', v_wh_id,
        'schema_provision', v_schema_result
    );
END;
$$;

-- ==============================================================================
-- 8. STRICT ROW-LEVEL SECURITY (RLS) & TWO-BRANCH ISOLATION
-- ==============================================================================

-- Audit Logs Table RLS
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "audit_logs_select_policy" ON public.audit_logs;
CREATE POLICY "audit_logs_select_policy" ON public.audit_logs
FOR SELECT USING (
    (auth.user_role() = ANY (ARRAY['super_admin'::text, 'general_manager'::text, 'auditor'::text, 'accountant'::text]))
    OR ((auth.branch_id() IS NOT NULL) AND ((branch_id)::text = auth.branch_id()))
);

DROP POLICY IF EXISTS "audit_logs_insert_policy" ON public.audit_logs;
CREATE POLICY "audit_logs_insert_policy" ON public.audit_logs
FOR INSERT TO authenticated
WITH CHECK (true);

-- Inventory Compensations Table RLS
ALTER TABLE public.inventory_compensations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory_compensations FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "compensations_select_policy" ON public.inventory_compensations;
CREATE POLICY "compensations_select_policy" ON public.inventory_compensations
FOR SELECT USING (
    (auth.user_role() = ANY (ARRAY['super_admin'::text, 'general_manager'::text, 'auditor'::text, 'accountant'::text]))
    OR ((auth.branch_id() IS NOT NULL) AND (((source_branch_id)::text = auth.branch_id()) OR ((destination_branch_id)::text = auth.branch_id())))
);

-- Grant privileges for PostgREST
GRANT ALL ON public.branches TO anon, authenticated;
GRANT ALL ON public.dark_stores TO anon, authenticated;
GRANT ALL ON public.dark_store_inventory TO anon, authenticated;
GRANT ALL ON public.inventory_transfers TO anon, authenticated;
GRANT ALL ON public.inventory_compensations TO anon, authenticated;
GRANT ALL ON public.audit_logs TO anon, authenticated;
GRANT ALL ON public.inventory_movements TO anon, authenticated;

GRANT EXECUTE ON FUNCTION public.rpc_create_inventory_transfer TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.rpc_approve_and_reserve_transfer TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.rpc_dispatch_transfer TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.rpc_receive_and_close_transfer TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.rpc_cancel_transfer TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.rpc_compensate_transfer TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.rpc_create_branch_atomic TO anon, authenticated;

-- Register migration record
INSERT INTO public._schema_migrations (filename, applied_at)
VALUES ('20261104_019_branch_transfers_and_audit_ledger.sql', timezone('utc'::text, now()))
ON CONFLICT (filename) DO UPDATE SET applied_at = timezone('utc'::text, now());
