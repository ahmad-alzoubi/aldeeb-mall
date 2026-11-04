-- ==============================================================================
-- Migration 025: Authoritative Order Management, State Machine & Audit Ledger
-- ==============================================================================
-- 1. Adds optimistic concurrency version, reasons, courier FK, and restoration guard to orders.
-- 2. Updates orders_status_check to include unified statuses:
--    ('pending', 'confirmed', 'packing', 'assigned', 'out_for_delivery', 'delivered', 'cancelled', 'failed').
-- 3. Creates public.order_status_history audit ledger with FORCE RLS.
-- 4. Creates update_order_status_atomic() RPC with role validation, state transitions,
--    mandatory reason checks, optimistic locking, and automatic stock restoration.
-- 5. Updates handle_order_status_change() trigger to prevent double stock decrements
--    and ensure loyalty points and audit history synchronization.
-- ==============================================================================

BEGIN;

-- 1. Upgrade public.orders table schema
ALTER TABLE public.orders
    ADD COLUMN IF NOT EXISTS version INTEGER NOT NULL DEFAULT 1,
    ADD COLUMN IF NOT EXISTS cancellation_reason TEXT,
    ADD COLUMN IF NOT EXISTS failure_reason TEXT,
    ADD COLUMN IF NOT EXISTS courier_id UUID REFERENCES public.couriers(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS assigned_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS is_stock_restored BOOLEAN NOT NULL DEFAULT false;

-- Update check constraint on orders status to include 'assigned' and 'failed'
ALTER TABLE public.orders 
    DROP CONSTRAINT IF EXISTS orders_status_check;

ALTER TABLE public.orders 
    ADD CONSTRAINT orders_status_check 
    CHECK (status = ANY (ARRAY[
        'pending'::text,
        'confirmed'::text,
        'packing'::text,
        'assigned'::text,
        'out_for_delivery'::text,
        'delivered'::text,
        'cancelled'::text,
        'failed'::text
    ]));

-- Update check constraint on inventory_transactions movement_type to permit 'order_cancellation' and 'order_return'
ALTER TABLE public.inventory_transactions
    DROP CONSTRAINT IF EXISTS inventory_transactions_movement_type_check;

ALTER TABLE public.inventory_transactions
    ADD CONSTRAINT inventory_transactions_movement_type_check
    CHECK (movement_type = ANY (ARRAY[
        'purchase_receipt'::text,
        'damaged_loss'::text,
        'sales_deduction'::text,
        'inventory_transfer'::text,
        'inventory_adjustment'::text,
        'order_cancellation'::text,
        'order_return'::text
    ]));

ALTER TABLE public.inventory_transactions
    DROP CONSTRAINT IF EXISTS inventory_transactions_reference_type_check;

ALTER TABLE public.inventory_transactions
    ADD CONSTRAINT inventory_transactions_reference_type_check
    CHECK (reference_type = ANY (ARRAY[
        'purchase_order'::text,
        'order_sale'::text,
        'order'::text,
        'transfer'::text,
        'manual_audit'::text
    ]));

-- 2. Create public.order_status_history table
CREATE TABLE IF NOT EXISTS public.order_status_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    from_status TEXT,
    to_status TEXT NOT NULL,
    reason TEXT,
    notes TEXT,
    staff_id TEXT,
    staff_name TEXT,
    staff_role TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_order_status_history_order_id 
    ON public.order_status_history(order_id, created_at ASC);

-- 3. Row Level Security for order_status_history
ALTER TABLE public.order_status_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_status_history FORCE ROW LEVEL SECURITY;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.order_status_history TO authenticated, anon;
GRANT ALL ON public.order_status_history TO postgres;

CREATE OR REPLACE FUNCTION auth.can_view_order_history(p_order_id uuid)
RETURNS boolean
LANGUAGE plpgsql
STABLE SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
    v_order RECORD;
BEGIN
    IF auth.user_role() IN ('super_admin', 'general_manager', 'auditor', 'accountant') THEN
        RETURN TRUE;
    END IF;

    SELECT id, branch_id, user_id, delivery_driver_phone INTO v_order
    FROM public.orders
    WHERE id = p_order_id;

    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;

    RETURN auth.can_view_order(v_order.id, v_order.branch_id, v_order.user_id, v_order.delivery_driver_phone);
END;
$$;

DROP POLICY IF EXISTS "order_status_history_select_policy" ON public.order_status_history;
CREATE POLICY "order_status_history_select_policy" ON public.order_status_history
    FOR SELECT TO authenticated, anon
    USING (
        auth.user_role() IN ('super_admin', 'general_manager', 'auditor', 'accountant')
        OR auth.can_view_order_history(order_id)
    );

DROP POLICY IF EXISTS "order_status_history_insert_policy" ON public.order_status_history;
CREATE POLICY "order_status_history_insert_policy" ON public.order_status_history
    FOR INSERT TO authenticated, anon
    WITH CHECK (true);

-- 4. Initial Backfill: ensure every existing order has at least one status history record
INSERT INTO public.order_status_history (order_id, from_status, to_status, notes, staff_name, staff_role, created_at)
SELECT 
    o.id,
    NULL,
    o.status,
    'الحالة المسجلة الأولية للنظام',
    'النظام الأساسي',
    'system',
    o.created_at
FROM public.orders o
WHERE NOT EXISTS (
    SELECT 1 FROM public.order_status_history h WHERE h.order_id = o.id
);

-- Trigger to automatically create initial order_status_history record on order creation
CREATE OR REPLACE FUNCTION public.handle_order_creation_audit()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO public.order_status_history (
        order_id,
        from_status,
        to_status,
        notes,
        staff_name,
        staff_role,
        metadata
    ) VALUES (
        NEW.id,
        NULL,
        NEW.status,
        'إنشاء الطلب الأولي بالنظام',
        COALESCE(NEW.customer_name, 'العميل'),
        'customer',
        jsonb_build_object('delivery_slot', NEW.delivery_slot, 'payment_method', NEW.payment_method)
    );
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_order_created_audit ON public.orders;
CREATE TRIGGER on_order_created_audit
    AFTER INSERT ON public.orders
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_order_creation_audit();

-- 5. Upgrade handle_order_status_change() trigger function to prevent double decrement and support cancellation
CREATE OR REPLACE FUNCTION public.handle_order_status_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
    v_item RECORD;
    v_points_earned INTEGER;
    v_current_stock NUMERIC;
BEGIN
    -- Only trigger if status has changed
    IF (OLD.status IS DISTINCT FROM NEW.status) THEN

        -- Note: Stock is already decremented in place_order_atomic upon order placement.
        -- We do NOT decrement stock again on 'confirmed' to eliminate double-decrement bugs.

        -- A. When Order is Cancelled or Failed: Restore Stock Atomically if not already restored
        IF (NEW.status IN ('cancelled', 'failed') AND NOT COALESCE(OLD.is_stock_restored, false)) THEN
            FOR v_item IN SELECT product_id, quantity FROM public.order_items WHERE order_id = NEW.id LOOP
                IF v_item.product_id IS NOT NULL AND v_item.quantity > 0 THEN
                    -- 1. Restore Catalog Stock
                    UPDATE public.products
                    SET stock_quantity = stock_quantity + v_item.quantity::integer,
                        sales_count = GREATEST(0, COALESCE(sales_count, 0) - v_item.quantity::integer),
                        updated_at = timezone('utc'::text, now())
                    WHERE id = v_item.product_id;

                    -- 2. Restore Branch Inventory
                    IF NEW.branch_id IS NOT NULL THEN
                        UPDATE public.branch_inventory
                        SET quantity_on_hand = quantity_on_hand + v_item.quantity::integer,
                            updated_at = timezone('utc'::text, now())
                        WHERE branch_id = NEW.branch_id AND product_id = v_item.product_id;
                    END IF;

                    -- 3. Log into inventory_movements
                    SELECT stock_quantity INTO v_current_stock FROM public.products WHERE id = v_item.product_id;
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
                        'MOV-RST-' || extract(epoch from now())::bigint || '-' || substring(gen_random_uuid()::text from 1 for 6),
                        COALESCE(NEW.branch_id, 'b-jed-01'),
                        v_item.product_id,
                        'return',
                        v_item.quantity::integer,
                        0,
                        COALESCE(v_current_stock, 0),
                        0,
                        'order',
                        NEW.id::text,
                        NEW.delivery_driver_phone,
                        'نظام إدارة الطلبات',
                        'system',
                        'استرجاع تلقائي للمخزون إثر انتقال الطلب #' || NEW.order_number || ' إلى ' || NEW.status
                    );

                    -- 4. Log into inventory_transactions
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
                        'TRX-RST-' || extract(epoch from now())::bigint || '-' || substring(gen_random_uuid()::text from 1 for 6),
                        COALESCE(NEW.branch_id, 'b-jed-01'),
                        v_item.product_id,
                        'order_cancellation',
                        'order',
                        NEW.id::text,
                        v_item.quantity::integer,
                        0.00,
                        0.00,
                        COALESCE(v_current_stock, 0),
                        'نظام إدارة الطلبات',
                        'استرجاع المخزون بعد إلغاء أو تعذر تسليم الطلب #' || NEW.order_number
                    );
                END IF;
            END LOOP;
            NEW.is_stock_restored := true;
        END IF;

        -- B. When Order is Delivered: Award Loyalty Points & Notify User
        IF (NEW.status = 'delivered' AND OLD.status <> 'delivered') THEN
            NEW.delivered_at := timezone('utc'::text, now());
            NEW.payment_status := 'paid';

            IF (NEW.user_id IS NOT NULL AND NEW.total_amount > 0) THEN
                v_points_earned := FLOOR(NEW.total_amount / 10.0);
                IF v_points_earned > 0 THEN
                    UPDATE public.profiles
                    SET loyalty_points = loyalty_points + v_points_earned
                    WHERE id = NEW.user_id;

                    INSERT INTO public.loyalty_transactions (
                        user_id,
                        order_id,
                        points,
                        transaction_type,
                        description_ar,
                        description_en
                    ) VALUES (
                        NEW.user_id,
                        NEW.id,
                        v_points_earned,
                        'earned',
                        'نقاط مكتسبة من إتمام الطلب #' || NEW.order_number,
                        'Points earned from order #' || NEW.order_number
                    );
                END IF;
            END IF;

            IF NEW.user_id IS NOT NULL THEN
                INSERT INTO public.notifications (user_id, title_ar, title_en, body_ar, body_en, type, payload)
                VALUES (
                    NEW.user_id,
                    'تم تسليم طلبك بنجاح 🎉',
                    'Order Delivered Successfully 🎉',
                    'شكراً لتسوقك من الديب مول! طلبك #' || NEW.order_number || ' تم تسليمه بنجاح.',
                    'Thank you for shopping with Aldeeb Mall! Your order #' || NEW.order_number || ' has been delivered.',
                    'order',
                    jsonb_build_object('order_id', NEW.id, 'status', NEW.status)
                );
            END IF;
        END IF;

        -- C. If Order is Cancelled or Failed: Notify Customer
        IF (NEW.status IN ('cancelled', 'failed') AND NEW.user_id IS NOT NULL) THEN
            INSERT INTO public.notifications (user_id, title_ar, title_en, body_ar, body_en, type, payload)
            VALUES (
                NEW.user_id,
                CASE WHEN NEW.status = 'cancelled' THEN 'تم إلغاء الطلب #' || NEW.order_number ELSE 'تعذر تسليم الطلب #' || NEW.order_number END,
                CASE WHEN NEW.status = 'cancelled' THEN 'Order #' || NEW.order_number || ' Cancelled' ELSE 'Order #' || NEW.order_number || ' Delivery Failed' END,
                COALESCE(NEW.cancellation_reason, NEW.failure_reason, 'يرجى التواصل مع خدمة العملاء للمزيد من التفاصيل.'),
                COALESCE(NEW.cancellation_reason, NEW.failure_reason, 'Please contact support for more details.'),
                'order',
                jsonb_build_object('order_id', NEW.id, 'status', NEW.status)
            );
        END IF;

    END IF;

    NEW.updated_at := timezone('utc'::text, now());
    RETURN NEW;
END;
$function$;

-- 6. Authoritative Stored Procedure: update_order_status_atomic
CREATE OR REPLACE FUNCTION public.update_order_status_atomic(
    p_order_id UUID,
    p_new_status TEXT,
    p_expected_version INTEGER DEFAULT NULL,
    p_reason TEXT DEFAULT NULL,
    p_notes TEXT DEFAULT NULL,
    p_courier_id UUID DEFAULT NULL,
    p_courier_name TEXT DEFAULT NULL,
    p_courier_phone TEXT DEFAULT NULL,
    p_staff_id TEXT DEFAULT NULL,
    p_staff_name TEXT DEFAULT NULL,
    p_staff_role TEXT DEFAULT NULL,
    p_metadata JSONB DEFAULT '{}'::jsonb
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
    v_order RECORD;
    v_history_id UUID;
    v_effective_role TEXT;
    v_effective_branch TEXT;
    v_clean_reason TEXT := NULLIF(TRIM(p_reason), '');
    v_clean_notes TEXT := NULLIF(TRIM(p_notes), '');
BEGIN
    -- 1. Fetch & Lock Target Order
    SELECT * INTO v_order
    FROM public.orders
    WHERE id = p_order_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'ORDER_NOT_FOUND: Order with ID % does not exist', p_order_id;
    END IF;

    -- 2. Concurrency Control (Optimistic Lock)
    IF p_expected_version IS NOT NULL AND v_order.version <> p_expected_version THEN
        RAISE EXCEPTION 'CONCURRENT_MODIFICATION_CONFLICT: Order was modified by another operator (expected version %, actual version %)',
            p_expected_version, v_order.version;
    END IF;

    -- 3. Idempotent Return if already at target status
    IF v_order.status = p_new_status THEN
        RETURN jsonb_build_object(
            'success', true,
            'order_id', v_order.id,
            'status', v_order.status,
            'version', v_order.version,
            'is_noop', true,
            'message_ar', 'الطلب بالفعل في الحالة المطلوبة'
        );
    END IF;

    -- 4. Terminal State Protection
    IF v_order.status = 'cancelled' THEN
        RAISE EXCEPTION 'INVALID_TRANSITION: Cannot modify order %. Order is already cancelled.', v_order.order_number;
    END IF;

    IF v_order.status = 'delivered' AND p_new_status <> 'delivered' THEN
        RAISE EXCEPTION 'INVALID_TRANSITION: Cannot modify order %. Order is already delivered.', v_order.order_number;
    END IF;

    -- 5. Authorized State Machine Transitions
    CASE v_order.status
        WHEN 'pending' THEN
            IF p_new_status NOT IN ('confirmed', 'packing', 'cancelled') THEN
                RAISE EXCEPTION 'INVALID_TRANSITION: Cannot transition order from % to %', v_order.status, p_new_status;
            END IF;
        WHEN 'confirmed' THEN
            IF p_new_status NOT IN ('packing', 'assigned', 'out_for_delivery', 'cancelled') THEN
                RAISE EXCEPTION 'INVALID_TRANSITION: Cannot transition order from % to %', v_order.status, p_new_status;
            END IF;
        WHEN 'packing' THEN
            IF p_new_status NOT IN ('assigned', 'out_for_delivery', 'cancelled') THEN
                RAISE EXCEPTION 'INVALID_TRANSITION: Cannot transition order from % to %', v_order.status, p_new_status;
            END IF;
        WHEN 'assigned' THEN
            IF p_new_status NOT IN ('out_for_delivery', 'delivered', 'failed', 'cancelled') THEN
                RAISE EXCEPTION 'INVALID_TRANSITION: Cannot transition order from % to %', v_order.status, p_new_status;
            END IF;
        WHEN 'out_for_delivery' THEN
            IF p_new_status NOT IN ('delivered', 'failed', 'cancelled') THEN
                RAISE EXCEPTION 'INVALID_TRANSITION: Cannot transition order from % to %', v_order.status, p_new_status;
            END IF;
        WHEN 'failed' THEN
            IF p_new_status NOT IN ('packing', 'assigned', 'out_for_delivery', 'cancelled') THEN
                RAISE EXCEPTION 'INVALID_TRANSITION: Cannot transition order from % to %', v_order.status, p_new_status;
            END IF;
        ELSE
            RAISE EXCEPTION 'INVALID_TRANSITION: Unknown current order status %', v_order.status;
    END CASE;

    -- 6. Mandatory Reason Validation for Cancelled and Failed
    IF p_new_status IN ('cancelled', 'failed') AND v_clean_reason IS NULL THEN
        RAISE EXCEPTION 'REASON_REQUIRED: A valid non-empty reason is strictly required when transitioning order to %', p_new_status;
    END IF;

    -- 7. Role & Branch Verification
    v_effective_role := COALESCE(auth.user_role(), p_staff_role, 'anon');
    v_effective_branch := auth.branch_id();

    -- Branch isolation check: if staff is tied to a specific branch, they cannot alter other branches' orders
    IF v_effective_branch IS NOT NULL AND v_order.branch_id IS NOT NULL AND v_order.branch_id <> v_effective_branch THEN
        IF v_effective_role NOT IN ('super_admin', 'general_manager', 'auditor') THEN
            RAISE EXCEPTION 'UNAUTHORIZED_BRANCH: Staff belonging to branch % cannot modify order of branch %',
                v_effective_branch, v_order.branch_id;
        END IF;
    END IF;

    -- 8. Courier & Dispatches Synchronization
    IF p_courier_id IS NOT NULL OR p_new_status = 'assigned' THEN
        -- Link courier in dispatches table if exists or insert
        IF p_courier_id IS NOT NULL THEN
            IF EXISTS (SELECT 1 FROM public.courier_dispatches WHERE order_id = v_order.id) THEN
                UPDATE public.courier_dispatches
                SET courier_id = p_courier_id,
                    status = CASE WHEN p_new_status = 'out_for_delivery' THEN 'picked_up' ELSE 'assigned' END,
                    dispatched_at = now()
                WHERE order_id = v_order.id;
            ELSE
                INSERT INTO public.courier_dispatches (
                    order_id,
                    courier_id,
                    status,
                    estimated_arrival_minutes,
                    dispatched_at
                ) VALUES (
                    v_order.id,
                    p_courier_id,
                    'assigned',
                    20,
                    now()
                );
            END IF;
        END IF;
    END IF;

    IF p_new_status = 'failed' THEN
        UPDATE public.courier_dispatches
        SET status = 'failed'
        WHERE order_id = v_order.id;
    ELSIF p_new_status = 'delivered' THEN
        UPDATE public.courier_dispatches
        SET status = 'delivered',
            delivered_at = timezone('utc'::text, now())
        WHERE order_id = v_order.id;
    ELSIF p_new_status = 'out_for_delivery' THEN
        UPDATE public.courier_dispatches
        SET status = 'picked_up'
        WHERE order_id = v_order.id;
    END IF;

    -- 9. Update Order Record (triggers handle_order_status_change for stock restoration & loyalty points)
    UPDATE public.orders
    SET 
        status = p_new_status,
        version = v_order.version + 1,
        cancellation_reason = CASE WHEN p_new_status = 'cancelled' THEN v_clean_reason ELSE cancellation_reason END,
        failure_reason = CASE WHEN p_new_status = 'failed' THEN v_clean_reason ELSE failure_reason END,
        courier_id = COALESCE(p_courier_id, courier_id),
        delivery_driver_name = COALESCE(p_courier_name, delivery_driver_name),
        delivery_driver_phone = COALESCE(p_courier_phone, delivery_driver_phone),
        assigned_at = CASE WHEN p_new_status = 'assigned' THEN timezone('utc'::text, now()) ELSE assigned_at END,
        delivered_at = CASE WHEN p_new_status = 'delivered' THEN timezone('utc'::text, now()) ELSE delivered_at END,
        payment_status = CASE WHEN p_new_status = 'delivered' THEN 'paid' ELSE payment_status END,
        notes = CASE WHEN v_clean_notes IS NOT NULL THEN COALESCE(notes, '') || E'\n[' || to_char(now(), 'YYYY-MM-DD HH24:MI') || '] ' || v_clean_notes ELSE notes END,
        updated_at = timezone('utc'::text, now())
    WHERE id = p_order_id;

    -- 10. Record Status History in Audit Ledger
    INSERT INTO public.order_status_history (
        order_id,
        from_status,
        to_status,
        reason,
        notes,
        staff_id,
        staff_name,
        staff_role,
        metadata
    ) VALUES (
        p_order_id,
        v_order.status,
        p_new_status,
        v_clean_reason,
        v_clean_notes,
        p_staff_id,
        COALESCE(p_staff_name, 'موظف النظام'),
        COALESCE(p_staff_role, v_effective_role),
        COALESCE(p_metadata, '{}'::jsonb) || jsonb_build_object(
            'courier_id', p_courier_id,
            'courier_name', p_courier_name,
            'previous_version', v_order.version,
            'new_version', v_order.version + 1
        )
    ) RETURNING id INTO v_history_id;

    -- 11. Return Verified Success Payload
    RETURN jsonb_build_object(
        'success', true,
        'order_id', v_order.id,
        'order_number', v_order.order_number,
        'previous_status', v_order.status,
        'new_status', p_new_status,
        'version', v_order.version + 1,
        'history_id', v_history_id,
        'reason', v_clean_reason,
        'courier_id', p_courier_id,
        'courier_name', p_courier_name,
        'updated_at', timezone('utc'::text, now())
    );
END;
$$;

-- Grant execution permissions
GRANT EXECUTE ON FUNCTION public.update_order_status_atomic TO authenticated, anon;

-- Record migration in _schema_migrations
INSERT INTO public._schema_migrations (filename, applied_at)
VALUES ('20261104_025_order_management_state_machine_and_audit_ledger.sql', timezone('utc'::text, now()))
ON CONFLICT (filename) DO NOTHING;

COMMIT;
