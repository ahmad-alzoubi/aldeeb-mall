-- ==============================================================================
-- Migration: 20261104_025_warehouse_fulfillment_and_order_dispatch.sql
-- Description: Task 14: Comprehensive Warehouse Fulfillment, Wave Picking,
--              Sorting & Packing, Barcode Verification, Substitutions, Shortages,
--              Weighed Items, and Order-to-Driver Readiness Pipeline.
-- ==============================================================================

-- 1. Upgrade orders table status check constraint to support 'ready_for_driver'
ALTER TABLE public.orders 
    DROP CONSTRAINT IF EXISTS orders_status_check;

ALTER TABLE public.orders 
    ADD CONSTRAINT orders_status_check 
    CHECK (status = ANY (ARRAY['pending'::text, 'confirmed'::text, 'processing'::text, 'packing'::text, 'ready_for_driver'::text, 'shipped'::text, 'out_for_delivery'::text, 'delivered'::text, 'cancelled'::text, 'failed'::text, 'returned'::text]));

-- 2. Upgrade picker_tasks table structure
ALTER TABLE public.picker_tasks 
    ALTER COLUMN wave_id DROP NOT NULL;

ALTER TABLE public.picker_tasks 
    ALTER COLUMN quantity_required TYPE NUMERIC(8, 2);

ALTER TABLE public.picker_tasks 
    ALTER COLUMN quantity_picked TYPE NUMERIC(8, 2);

-- Add comprehensive fulfillment tracking columns
ALTER TABLE public.picker_tasks 
    ADD COLUMN IF NOT EXISTS order_item_id UUID REFERENCES public.order_items(id) ON DELETE CASCADE,
    ADD COLUMN IF NOT EXISTS branch_id VARCHAR(64) DEFAULT 'b-ruh-01',
    ADD COLUMN IF NOT EXISTS branch_name VARCHAR(255),
    ADD COLUMN IF NOT EXISTS assigned_staff_id VARCHAR(64),
    ADD COLUMN IF NOT EXISTS assigned_staff_name VARCHAR(128),
    ADD COLUMN IF NOT EXISTS stage VARCHAR(32) NOT NULL DEFAULT 'picking',
    ADD COLUMN IF NOT EXISTS item_type VARCHAR(32) NOT NULL DEFAULT 'unit',
    ADD COLUMN IF NOT EXISTS unit VARCHAR(32) DEFAULT 'piece',
    ADD COLUMN IF NOT EXISTS expected_weight NUMERIC(8, 3),
    ADD COLUMN IF NOT EXISTS actual_weight NUMERIC(8, 3),
    ADD COLUMN IF NOT EXISTS verification_method VARCHAR(32) DEFAULT 'pending',
    ADD COLUMN IF NOT EXISTS scanned_barcode VARCHAR(64),
    ADD COLUMN IF NOT EXISTS is_substituted BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS substitute_product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS substitute_product_name VARCHAR(255),
    ADD COLUMN IF NOT EXISTS substitute_barcode VARCHAR(64),
    ADD COLUMN IF NOT EXISTS substitution_reason TEXT,
    ADD COLUMN IF NOT EXISTS price_difference NUMERIC(10, 2) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS is_shortage BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS shortage_qty NUMERIC(8, 2) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS shortage_reason TEXT,
    ADD COLUMN IF NOT EXISTS notes TEXT,
    ADD COLUMN IF NOT EXISTS packing_box_id VARCHAR(64),
    ADD COLUMN IF NOT EXISTS sorted_bin VARCHAR(64),
    ADD COLUMN IF NOT EXISTS sorted_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS packed_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now());

-- Constraints on picker_tasks
ALTER TABLE public.picker_tasks 
    DROP CONSTRAINT IF EXISTS picker_tasks_status_check;

ALTER TABLE public.picker_tasks 
    ADD CONSTRAINT picker_tasks_status_check 
    CHECK (status IN ('pending', 'picked', 'sorted', 'packed', 'verified', 'out_of_stock', 'substituted', 'completed'));

ALTER TABLE public.picker_tasks 
    DROP CONSTRAINT IF EXISTS picker_tasks_stage_check;

ALTER TABLE public.picker_tasks 
    ADD CONSTRAINT picker_tasks_stage_check 
    CHECK (stage IN ('picking', 'sorting', 'packing', 'completed'));

ALTER TABLE public.picker_tasks 
    DROP CONSTRAINT IF EXISTS picker_tasks_item_type_check;

ALTER TABLE public.picker_tasks 
    ADD CONSTRAINT picker_tasks_item_type_check 
    CHECK (item_type IN ('unit', 'weighed'));

ALTER TABLE public.picker_tasks 
    DROP CONSTRAINT IF EXISTS picker_tasks_verification_method_check;

ALTER TABLE public.picker_tasks 
    ADD CONSTRAINT picker_tasks_verification_method_check 
    CHECK (verification_method IN ('pending', 'barcode_scan', 'verified_manual'));

-- Performance indexes for picker tasks
CREATE INDEX IF NOT EXISTS idx_picker_tasks_order_id ON public.picker_tasks(order_id);
CREATE INDEX IF NOT EXISTS idx_picker_tasks_branch_id ON public.picker_tasks(branch_id);
CREATE INDEX IF NOT EXISTS idx_picker_tasks_stage ON public.picker_tasks(stage);
CREATE INDEX IF NOT EXISTS idx_picker_tasks_status ON public.picker_tasks(status);
CREATE INDEX IF NOT EXISTS idx_picker_tasks_assigned_staff ON public.picker_tasks(assigned_staff_id);

-- 3. Upgrade trigger function handle_order_status_change for notifications and atomic stock restoration
CREATE OR REPLACE FUNCTION public.handle_order_status_change()
RETURNS TRIGGER AS $$
DECLARE
    v_item RECORD;
    v_points_earned INTEGER;
    v_current_stock NUMERIC;
BEGIN
    -- Only trigger if status has changed
    IF (OLD.status IS DISTINCT FROM NEW.status) THEN

        -- Note: Stock is already decremented in place_order_atomic upon order placement.
        -- We do NOT decrement stock again on 'confirmed' to eliminate double-decrement bugs.

        -- A. When Order is Confirmed: Notify User
        IF (NEW.status = 'confirmed' AND OLD.status = 'pending') THEN
            IF NEW.user_id IS NOT NULL THEN
                INSERT INTO public.notifications (user_id, title_ar, title_en, body_ar, body_en, type, payload)
                VALUES (
                    NEW.user_id,
                    'تم تأكيد طلبك #' || NEW.order_number,
                    'Order #' || NEW.order_number || ' Confirmed',
                    'طلبك قيد المراجعة وسيبدأ فريق المستودع بتجهيز المنتجات الطازجة لك الآن.',
                    'Your order has been confirmed and our warehouse is preparing your fresh items.',
                    'order',
                    jsonb_build_object('order_id', NEW.id, 'order_number', NEW.order_number)
                );
            END IF;
        END IF;

        -- B. When Order is Cancelled or Failed: Restore Stock Atomically if not already restored
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

        -- C. When Order status changes to 'packing' (Warehouse Picking Started)
        IF (NEW.status = 'packing' AND OLD.status IS DISTINCT FROM 'packing') THEN
            IF NEW.user_id IS NOT NULL THEN
                INSERT INTO public.notifications (user_id, title_ar, title_en, body_ar, body_en, type, payload)
                VALUES (
                    NEW.user_id,
                    'جاري تجهيز طلبك في المستودع #' || NEW.order_number || ' 🛒',
                    'Order #' || NEW.order_number || ' is being packed 🛒',
                    'بدأ فريق التجهيز في المستودع بجمع وفرز وتعبئة منتجات طلبك بعناية فائقة.',
                    'Warehouse staff is picking and packing your items with top care.',
                    'order',
                    jsonb_build_object('order_id', NEW.id, 'order_number', NEW.order_number, 'status', 'packing')
                );
            END IF;
        END IF;

        -- D. When Order is Ready For Driver (Packing Complete)
        IF (NEW.status = 'ready_for_driver' AND OLD.status IS DISTINCT FROM 'ready_for_driver') THEN
            IF NEW.user_id IS NOT NULL THEN
                INSERT INTO public.notifications (user_id, title_ar, title_en, body_ar, body_en, type, payload)
                VALUES (
                    NEW.user_id,
                    'طلبك #' || NEW.order_number || ' جاهز للتوصيل 📦',
                    'Order #' || NEW.order_number || ' Ready For Driver 📦',
                    'تم الانتهاء من جمع وتعبئة طلبك بنجاح وهو الآن في منطقة التسليم بانتظار سائق التوصيل.',
                    'Your order has been picked and packed and is waiting for the delivery driver.',
                    'order',
                    jsonb_build_object('order_id', NEW.id, 'order_number', NEW.order_number, 'status', 'ready_for_driver')
                );
            END IF;
        END IF;

        -- E. When Order is Out for Delivery
        IF (NEW.status = 'out_for_delivery' AND OLD.status != 'out_for_delivery') THEN
            IF NEW.user_id IS NOT NULL THEN
                INSERT INTO public.notifications (user_id, title_ar, title_en, body_ar, body_en, type, payload)
                VALUES (
                    NEW.user_id,
                    'طلبك في الطريق إليك 🛵',
                    'Order Out for Delivery 🛵',
                    'السائق ' || COALESCE(NEW.delivery_driver_name, 'المعتمد') || ' في طريقه لتسليم طلبك #' || NEW.order_number || '.',
                    'Driver ' || COALESCE(NEW.delivery_driver_name, 'assigned') || ' is on the way with your order #' || NEW.order_number || '.',
                    'order',
                    jsonb_build_object('order_id', NEW.id, 'order_number', NEW.order_number, 'driver_phone', NEW.delivery_driver_phone)
                );
            END IF;
        END IF;

        -- F. When Order is Delivered
        IF (NEW.status = 'delivered' AND OLD.status != 'delivered') THEN
            NEW.delivered_at := timezone('utc'::text, now());
            NEW.payment_status := 'paid';

            -- Calculate loyalty points (1 point per 10 currency units)
            v_points_earned := FLOOR(NEW.total_amount / 10.0);

            IF (NEW.user_id IS NOT NULL AND v_points_earned > 0) THEN
                UPDATE public.profiles
                SET loyalty_points = loyalty_points + v_points_earned
                WHERE id = NEW.user_id;

                INSERT INTO public.loyalty_transactions (user_id, order_id, points, transaction_type, description_ar, description_en)
                VALUES (
                    NEW.user_id,
                    NEW.id,
                    v_points_earned,
                    'earned',
                    'نقاط مكتسبة من إتمام الطلب #' || NEW.order_number,
                    'Points earned from order #' || NEW.order_number
                );

                INSERT INTO public.notifications (user_id, title_ar, title_en, body_ar, body_en, type, payload)
                VALUES (
                    NEW.user_id,
                    'تم تسليم طلبك بنجاح 🎉',
                    'Order Delivered Successfully 🎉',
                    'شكراً لتسوقك من الديب مول! تمت إضافة ' || v_points_earned || ' نقطة إلى محفظتك.',
                    'Thank you for shopping at Aldeeb Mall! ' || v_points_earned || ' points added to your wallet.',
                    'order',
                    jsonb_build_object('order_id', NEW.id, 'points_earned', v_points_earned)
                );
            END IF;
        END IF;

        -- G. If Order is Cancelled or Failed: Notify Customer
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
$$ LANGUAGE plpgsql;

-- 4. Update RLS policies on picker_tasks
ALTER TABLE public.picker_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.picker_tasks FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "picker_tasks_policy" ON public.picker_tasks;
DROP POLICY IF EXISTS "picker_tasks_select_policy" ON public.picker_tasks;
DROP POLICY IF EXISTS "picker_tasks_mutate_policy" ON public.picker_tasks;

CREATE POLICY "picker_tasks_select_policy" ON public.picker_tasks
    FOR SELECT TO authenticated
    USING (
        auth.user_role() IN ('super_admin', 'general_manager', 'auditor', 'accountant')
        OR (branch_id = auth.branch_id())
        OR (branch_id IS NULL)
        OR auth.is_staff()
    );

CREATE POLICY "picker_tasks_mutate_policy" ON public.picker_tasks
    FOR ALL TO authenticated
    USING (
        auth.user_role() IN ('super_admin', 'general_manager', 'warehouse_manager', 'branch_manager', 'cashier')
        OR (branch_id = auth.branch_id())
        OR auth.is_staff()
    )
    WITH CHECK (
        auth.user_role() IN ('super_admin', 'general_manager', 'warehouse_manager', 'branch_manager', 'cashier')
        OR (branch_id = auth.branch_id())
        OR auth.is_staff()
    );

-- Allow anon to select and update for development/testing if anon role active
DROP POLICY IF EXISTS "picker_tasks_anon_policy" ON public.picker_tasks;
CREATE POLICY "picker_tasks_anon_policy" ON public.picker_tasks
    FOR ALL TO anon
    USING (true)
    WITH CHECK (true);

-- Update orders update policy to include warehouse managers
DROP POLICY IF EXISTS "orders_update_policy" ON public.orders;

CREATE POLICY "orders_update_policy" ON public.orders FOR UPDATE
    TO authenticated
    USING (
        (auth.user_role() = ANY (ARRAY['super_admin'::text, 'general_manager'::text])) 
        OR ((auth.user_role() = ANY (ARRAY['branch_manager'::text, 'cashier'::text, 'warehouse_manager'::text])) AND (branch_id = auth.branch_id())) 
        OR (auth.is_courier() AND (id IN ( 
            SELECT cd.order_id
            FROM (courier_dispatches cd JOIN couriers c ON ((cd.courier_id = c.id)))
            WHERE (((c.phone)::text = (auth.jwt_claims() ->> 'phone'::text)) OR ((c.id)::text = auth.user_id()))
        )))
    )
    WITH CHECK (
        (auth.user_role() = ANY (ARRAY['super_admin'::text, 'general_manager'::text])) 
        OR ((auth.user_role() = ANY (ARRAY['branch_manager'::text, 'cashier'::text, 'warehouse_manager'::text])) AND (branch_id = auth.branch_id())) 
        OR auth.is_courier()
    );

-- 5. Stored Procedure 1: Generate Persistent Fulfillment Tasks for an Order
CREATE OR REPLACE FUNCTION public.generate_fulfillment_tasks_for_order(
    p_order_id UUID,
    p_staff_id VARCHAR DEFAULT NULL,
    p_branch_id VARCHAR DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_order RECORD;
    v_item RECORD;
    v_prod RECORD;
    v_task_id UUID;
    v_tasks_created INT := 0;
    v_tasks_existing INT := 0;
    v_branch VARCHAR(64);
    v_bin VARCHAR(32);
    v_item_type VARCHAR(32);
    v_staff_name VARCHAR(128);
    v_result JSONB;
BEGIN
    -- 1. Fetch order
    SELECT * INTO v_order FROM public.orders WHERE id = p_order_id;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'ORDER_NOT_FOUND', 'message_ar', 'الطلب غير موجود');
    END IF;

    v_branch := COALESCE(p_branch_id, v_order.branch_id, 'b-ruh-01');

    -- Resolve staff name if provided
    IF p_staff_id IS NOT NULL THEN
        SELECT full_name INTO v_staff_name FROM public.staff_members WHERE id = p_staff_id OR username = p_staff_id LIMIT 1;
    END IF;

    -- 2. If order status is pending or confirmed, advance to packing
    IF v_order.status IN ('pending', 'confirmed') THEN
        UPDATE public.orders SET status = 'packing', updated_at = NOW() WHERE id = p_order_id;
    END IF;

    -- 3. Loop over order_items
    FOR v_item IN SELECT * FROM public.order_items WHERE order_id = p_order_id LOOP
        -- Check if task already exists for this item
        SELECT id INTO v_task_id FROM public.picker_tasks WHERE order_item_id = v_item.id LIMIT 1;

        IF v_task_id IS NOT NULL THEN
            v_tasks_existing := v_tasks_existing + 1;
        ELSE
            -- Fetch product details
            SELECT * INTO v_prod FROM public.products WHERE id = v_item.product_id;

            -- Determine if weighed item
            IF LOWER(COALESCE(v_item.unit, v_prod.unit, 'piece')) IN ('kg', 'كغ', 'كيلو', 'g', 'جرام') THEN
                v_item_type := 'weighed';
            ELSE
                v_item_type := 'unit';
            END IF;

            -- Assign shelf location bin
            v_bin := 'A-0' || ((v_tasks_created + 1) % 5 + 1)::text || '-R1-B0' || ((v_tasks_created + 1) % 9 + 1)::text;

            INSERT INTO public.picker_tasks (
                order_id,
                order_item_id,
                product_id,
                branch_id,
                branch_name,
                assigned_staff_id,
                assigned_staff_name,
                stage,
                item_type,
                unit,
                bin_location,
                barcode,
                quantity_required,
                expected_weight,
                quantity_picked,
                actual_weight,
                status,
                is_verified,
                created_at,
                updated_at
            ) VALUES (
                p_order_id,
                v_item.id,
                v_item.product_id,
                v_branch,
                COALESCE(v_order.branch_name, 'الفرع الرئيسي'),
                p_staff_id,
                v_staff_name,
                'picking',
                v_item_type,
                COALESCE(v_item.unit, v_prod.unit, 'قطعة'),
                v_bin,
                COALESCE(v_prod.barcode, '6291000' || LPAD((v_tasks_created + 1)::text, 5, '0')),
                v_item.quantity,
                CASE WHEN v_item_type = 'weighed' THEN v_item.quantity ELSE NULL END,
                0,
                0,
                'pending',
                false,
                NOW(),
                NOW()
            );

            v_tasks_created := v_tasks_created + 1;
        END IF;
    END LOOP;

    -- Return JSON payload of all tasks for this order
    SELECT jsonb_agg(
        jsonb_build_object(
            'id', pt.id,
            'order_id', pt.order_id,
            'order_item_id', pt.order_item_id,
            'product_id', pt.product_id,
            'product_name_ar', COALESCE(oi.product_name_ar, p.name_ar, 'صنف تمويني'),
            'product_image', COALESCE(oi.product_image, p.images[1], ''),
            'bin_location', pt.bin_location,
            'barcode', pt.barcode,
            'quantity_required', pt.quantity_required,
            'quantity_picked', pt.quantity_picked,
            'item_type', pt.item_type,
            'unit', pt.unit,
            'expected_weight', pt.expected_weight,
            'actual_weight', pt.actual_weight,
            'stage', pt.stage,
            'status', pt.status,
            'is_verified', pt.is_verified,
            'verification_method', pt.verification_method,
            'is_substituted', pt.is_substituted,
            'substitute_product_name', pt.substitute_product_name,
            'substitute_barcode', pt.substitute_barcode,
            'is_shortage', pt.is_shortage,
            'shortage_qty', pt.shortage_qty,
            'branch_id', pt.branch_id,
            'assigned_staff_id', pt.assigned_staff_id
        )
    ) INTO v_result
    FROM public.picker_tasks pt
    LEFT JOIN public.order_items oi ON pt.order_item_id = oi.id
    LEFT JOIN public.products p ON pt.product_id = p.id
    WHERE pt.order_id = p_order_id;

    RETURN jsonb_build_object(
        'success', true,
        'order_id', p_order_id,
        'tasks_created', v_tasks_created,
        'tasks_existing', v_tasks_existing,
        'tasks', COALESCE(v_result, '[]'::jsonb)
    );
END;
$$;

-- 6. Stored Procedure 2: Verify Fulfillment Scan (Hardware / Laser / Camera / Verified Manual)
CREATE OR REPLACE FUNCTION public.verify_fulfillment_scan(
    p_task_id UUID,
    p_scanned_barcode VARCHAR,
    p_scan_mode VARCHAR DEFAULT 'barcode_scan',
    p_actual_qty NUMERIC DEFAULT 1,
    p_actual_weight NUMERIC DEFAULT NULL,
    p_staff_id VARCHAR DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_task RECORD;
    v_product RECORD;
    v_clean_scanned VARCHAR;
    v_clean_expected VARCHAR;
    v_clean_prod_barcode VARCHAR;
    v_assigned_name VARCHAR(128);
BEGIN
    -- 1. Fetch task row FOR UPDATE
    SELECT * INTO v_task FROM public.picker_tasks WHERE id = p_task_id FOR UPDATE;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'TASK_NOT_FOUND', 'message_ar', 'مهمة الجمع غير موجودة');
    END IF;

    -- 2. Fetch product row
    SELECT * INTO v_product FROM public.products WHERE id = v_task.product_id;

    -- 3. Barcode Matching Logic (Strict Sanitization)
    v_clean_scanned := UPPER(TRIM(COALESCE(p_scanned_barcode, '')));
    v_clean_expected := UPPER(TRIM(COALESCE(v_task.barcode, '')));
    v_clean_prod_barcode := UPPER(TRIM(COALESCE(v_product.barcode, '')));

    IF v_clean_scanned = '' THEN
        RETURN jsonb_build_object('success', false, 'error', 'EMPTY_BARCODE', 'message_ar', 'رمز الباركود فارغ، يرجى المسح مجدداً');
    END IF;

    -- Strict match check: must match task barcode OR product catalog barcode
    IF v_clean_scanned <> v_clean_expected AND v_clean_scanned <> v_clean_prod_barcode THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'WRONG_BARCODE',
            'message_ar', 'الرمز الممسوح [' || v_clean_scanned || '] غير مطابق لباركود الصنف المطلوب [' || v_clean_expected || ']!',
            'scanned_barcode', v_clean_scanned,
            'expected_barcode', v_clean_expected
        );
    END IF;

    -- Resolve staff name
    IF p_staff_id IS NOT NULL THEN
        SELECT full_name INTO v_assigned_name FROM public.staff_members WHERE id = p_staff_id OR username = p_staff_id LIMIT 1;
    END IF;

    -- 4. Apply Verified Scan Mutation
    UPDATE public.picker_tasks
    SET
        is_verified = TRUE,
        status = 'picked',
        verification_method = COALESCE(p_scan_mode, 'barcode_scan'),
        scanned_barcode = v_clean_scanned,
        quantity_picked = COALESCE(p_actual_qty, v_task.quantity_required),
        actual_weight = CASE WHEN v_task.item_type = 'weighed' THEN COALESCE(p_actual_weight, p_actual_qty) ELSE v_task.actual_weight END,
        scanned_at = NOW(),
        assigned_staff_id = COALESCE(p_staff_id, v_task.assigned_staff_id),
        assigned_staff_name = COALESCE(v_assigned_name, v_task.assigned_staff_name),
        updated_at = NOW()
    WHERE id = p_task_id;

    RETURN jsonb_build_object(
        'success', true,
        'task_id', p_task_id,
        'status', 'picked',
        'is_verified', true,
        'quantity_picked', COALESCE(p_actual_qty, v_task.quantity_required),
        'actual_weight', CASE WHEN v_task.item_type = 'weighed' THEN COALESCE(p_actual_weight, p_actual_qty) ELSE NULL END,
        'scanned_barcode', v_clean_scanned,
        'message_ar', 'تم التحقق من الصنف ومطابقة الباركود بنجاح'
    );
END;
$$;

-- 7. Stored Procedure 3: Record Item Substitution with Stock Adjustment
CREATE OR REPLACE FUNCTION public.record_fulfillment_substitution(
    p_task_id UUID,
    p_substitute_product_id UUID,
    p_substitute_barcode VARCHAR,
    p_substitute_qty NUMERIC,
    p_reason TEXT,
    p_staff_id VARCHAR DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_task RECORD;
    v_orig_product RECORD;
    v_sub_product RECORD;
    v_clean_sub_barcode VARCHAR;
    v_diff NUMERIC := 0;
    v_assigned_name VARCHAR(128);
    v_order RECORD;
BEGIN
    -- 1. Fetch task row FOR UPDATE
    SELECT * INTO v_task FROM public.picker_tasks WHERE id = p_task_id FOR UPDATE;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'TASK_NOT_FOUND', 'message_ar', 'مهمة الجمع غير موجودة');
    END IF;

    -- 2. Fetch original product
    SELECT * INTO v_orig_product FROM public.products WHERE id = v_task.product_id;

    -- 3. Fetch and validate substitute product
    SELECT * INTO v_sub_product FROM public.products WHERE id = p_substitute_product_id AND is_active = TRUE;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'SUBSTITUTE_NOT_FOUND', 'message_ar', 'المنتج البديل غير متوفر أو غير مفعّل');
    END IF;

    -- Validate substitute barcode if provided
    v_clean_sub_barcode := UPPER(TRIM(COALESCE(p_substitute_barcode, '')));
    IF v_clean_sub_barcode <> '' AND UPPER(TRIM(COALESCE(v_sub_product.barcode, ''))) <> v_clean_sub_barcode THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'SUBSTITUTE_BARCODE_MISMATCH',
            'message_ar', 'الباركود المدخل [' || v_clean_sub_barcode || '] لا يطابق باركود الصنف البديل المسجل [' || v_sub_product.barcode || ']!'
        );
    END IF;

    -- Calculate price difference
    v_diff := ROUND((v_sub_product.price * p_substitute_qty) - (v_orig_product.price * v_task.quantity_required), 2);

    -- Resolve staff name
    IF p_staff_id IS NOT NULL THEN
        SELECT full_name INTO v_assigned_name FROM public.staff_members WHERE id = p_staff_id OR username = p_staff_id LIMIT 1;
    END IF;

    -- 4. Deduct stock for substitute product in branch inventory and catalog
    UPDATE public.products 
    SET stock_quantity = GREATEST(0, stock_quantity - p_substitute_qty::integer) 
    WHERE id = p_substitute_product_id;

    UPDATE public.branch_inventory
    SET quantity_on_hand = GREATEST(0, quantity_on_hand - p_substitute_qty::integer)
    WHERE branch_id = v_task.branch_id AND product_id = p_substitute_product_id;

    -- 5. Restore original product stock if it was previously deducted
    UPDATE public.products
    SET stock_quantity = stock_quantity + v_task.quantity_required::integer
    WHERE id = v_task.product_id;

    -- 6. Update picker task
    UPDATE public.picker_tasks
    SET
        is_verified = TRUE,
        status = 'substituted',
        is_substituted = TRUE,
        substitute_product_id = p_substitute_product_id,
        substitute_product_name = v_sub_product.name_ar,
        substitute_barcode = COALESCE(v_sub_product.barcode, p_substitute_barcode),
        substitution_reason = p_reason,
        price_difference = v_diff,
        quantity_picked = p_substitute_qty,
        verification_method = 'verified_manual',
        scanned_at = NOW(),
        assigned_staff_id = COALESCE(p_staff_id, v_task.assigned_staff_id),
        assigned_staff_name = COALESCE(v_assigned_name, v_task.assigned_staff_name),
        updated_at = NOW()
    WHERE id = p_task_id;

    -- 7. Notify Customer & Admin
    SELECT * INTO v_order FROM public.orders WHERE id = v_task.order_id;
    IF v_order.user_id IS NOT NULL THEN
        INSERT INTO public.notifications (user_id, title_ar, title_en, body_ar, body_en, type, payload)
        VALUES (
            v_order.user_id,
            'تنبيه استبدال صنف في طلبك #' || v_order.order_number,
            'Item Substituted in Order #' || v_order.order_number,
            'تم استبدال الصنف (' || v_orig_product.name_ar || ') بالبديل المعتمد (' || v_sub_product.name_ar || ') بناءً على: ' || p_reason,
            'Item (' || v_orig_product.name_en || ') was substituted with (' || v_sub_product.name_en || ').',
            'order',
            jsonb_build_object('order_id', v_order.id, 'task_id', p_task_id, 'diff', v_diff)
        );
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'task_id', p_task_id,
        'status', 'substituted',
        'substitute_name', v_sub_product.name_ar,
        'price_difference', v_diff,
        'message_ar', 'تم اعتماد الصنف البديل وتحديث الأرصدة وإشعار العميل بنجاح'
    );
END;
$$;

-- 8. Stored Procedure 4: Record Shortage / Out of Stock
CREATE OR REPLACE FUNCTION public.record_fulfillment_shortage(
    p_task_id UUID,
    p_shortage_qty NUMERIC,
    p_reason TEXT,
    p_staff_id VARCHAR DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_task RECORD;
    v_product RECORD;
    v_order RECORD;
    v_assigned_name VARCHAR(128);
    v_new_status VARCHAR(32);
    v_actual_picked NUMERIC;
BEGIN
    -- 1. Fetch task row FOR UPDATE
    SELECT * INTO v_task FROM public.picker_tasks WHERE id = p_task_id FOR UPDATE;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'TASK_NOT_FOUND', 'message_ar', 'مهمة الجمع غير موجودة');
    END IF;

    SELECT * INTO v_product FROM public.products WHERE id = v_task.product_id;
    SELECT * INTO v_order FROM public.orders WHERE id = v_task.order_id;

    -- Determine picked qty and status
    IF p_shortage_qty >= v_task.quantity_required THEN
        v_new_status := 'out_of_stock';
        v_actual_picked := 0;
    ELSE
        v_new_status := 'picked';
        v_actual_picked := v_task.quantity_required - p_shortage_qty;
    END IF;

    -- Resolve staff name
    IF p_staff_id IS NOT NULL THEN
        SELECT full_name INTO v_assigned_name FROM public.staff_members WHERE id = p_staff_id OR username = p_staff_id LIMIT 1;
    END IF;

    -- 2. Update task
    UPDATE public.picker_tasks
    SET
        status = v_new_status,
        is_shortage = TRUE,
        shortage_qty = p_shortage_qty,
        shortage_reason = p_reason,
        quantity_picked = v_actual_picked,
        is_verified = TRUE,
        assigned_staff_id = COALESCE(p_staff_id, v_task.assigned_staff_id),
        assigned_staff_name = COALESCE(v_assigned_name, v_task.assigned_staff_name),
        updated_at = NOW()
    WHERE id = p_task_id;

    -- 3. Notify Customer
    IF v_order.user_id IS NOT NULL THEN
        INSERT INTO public.notifications (user_id, title_ar, title_en, body_ar, body_en, type, payload)
        VALUES (
            v_order.user_id,
            'تنبيه نقص في طلبك #' || v_order.order_number,
            'Item Shortage in Order #' || v_order.order_number,
            'تعذر توفير كمية (' || p_shortage_qty || ') من الصنف (' || COALESCE(v_product.name_ar, 'صنف') || ') لسبب: ' || p_reason || '. وتم تعديل الحساب.',
            'Shortage recorded for ' || COALESCE(v_product.name_en, 'item') || '.',
            'order',
            jsonb_build_object('order_id', v_order.id, 'shortage_qty', p_shortage_qty)
        );
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'task_id', p_task_id,
        'status', v_new_status,
        'shortage_qty', p_shortage_qty,
        'quantity_picked', v_actual_picked,
        'message_ar', 'تم تسجيل النقص وإشعار العميل والإدارة بنجاح'
    );
END;
$$;

-- 9. Stored Procedure 5: Advance Fulfillment Stage (Picking -> Sorting -> Packing -> Ready For Driver)
CREATE OR REPLACE FUNCTION public.advance_fulfillment_stage(
    p_order_id UUID,
    p_new_stage VARCHAR,
    p_staff_id VARCHAR DEFAULT NULL,
    p_box_id VARCHAR DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_order RECORD;
    v_unfulfilled_count INT := 0;
    v_total_tasks INT := 0;
    v_assigned_name VARCHAR(128);
BEGIN
    -- 1. Fetch order
    SELECT * INTO v_order FROM public.orders WHERE id = p_order_id FOR UPDATE;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'ORDER_NOT_FOUND', 'message_ar', 'الطلب غير موجود');
    END IF;

    IF p_staff_id IS NOT NULL THEN
        SELECT full_name INTO v_assigned_name FROM public.staff_members WHERE id = p_staff_id OR username = p_staff_id LIMIT 1;
    END IF;

    -- 2. Stage Handlers
    IF p_new_stage = 'sorting' THEN
        UPDATE public.picker_tasks
        SET
            stage = 'sorting',
            sorted_bin = COALESCE(p_box_id, 'SORT-STATION-01'),
            sorted_at = NOW(),
            updated_at = NOW()
        WHERE order_id = p_order_id AND status IN ('picked', 'verified', 'substituted');

        RETURN jsonb_build_object(
            'success', true,
            'stage', 'sorting',
            'sorted_bin', COALESCE(p_box_id, 'SORT-STATION-01'),
            'message_ar', 'تم تحويل بنود الطلب إلى محطة الفرز والتجميع بنجاح'
        );

    ELSIF p_new_stage = 'packing' THEN
        UPDATE public.picker_tasks
        SET
            stage = 'packing',
            packing_box_id = COALESCE(p_box_id, 'BOX-SECURE-01'),
            packed_at = NOW(),
            updated_at = NOW()
        WHERE order_id = p_order_id AND status IN ('picked', 'verified', 'substituted');

        RETURN jsonb_build_object(
            'success', true,
            'stage', 'packing',
            'packing_box_id', COALESCE(p_box_id, 'BOX-SECURE-01'),
            'message_ar', 'تم إدراج الأصناف في صناديق التعبئة والتغليف بنجاح'
        );

    ELSIF p_new_stage = 'ready_for_driver' THEN
        -- Check if any tasks are still pending (unverified)
        SELECT COUNT(*), COUNT(*) FILTER (WHERE status = 'pending')
        INTO v_total_tasks, v_unfulfilled_count
        FROM public.picker_tasks
        WHERE order_id = p_order_id;

        IF v_total_tasks = 0 THEN
            RETURN jsonb_build_object('success', false, 'error', 'NO_TASKS', 'message_ar', 'لا توجد مهام تجهيز منشأة لهذا الطلب بعد!');
        END IF;

        IF v_unfulfilled_count > 0 THEN
            RETURN jsonb_build_object(
                'success', false,
                'error', 'UNFINISHED_TASKS',
                'unfulfilled_count', v_unfulfilled_count,
                'message_ar', 'لا يمكن تسليم الطلب للسائق: يوجد ' || v_unfulfilled_count || ' صنف معلق لم يتم التحقق منه أو استبداله بعد!'
            );
        END IF;

        -- Mark all tasks as completed stage
        UPDATE public.picker_tasks
        SET
            stage = 'completed',
            packing_box_id = COALESCE(packing_box_id, p_box_id, 'BOX-READY-01'),
            packed_at = COALESCE(packed_at, NOW()),
            updated_at = NOW()
        WHERE order_id = p_order_id;

        -- Update order status to ready_for_driver
        UPDATE public.orders
        SET
            status = 'ready_for_driver',
            notes = COALESCE(notes, '') || ' [جاهز للسائق - طرد: ' || COALESCE(p_box_id, 'BOX-01') || ']',
            updated_at = NOW()
        WHERE id = p_order_id;

        RETURN jsonb_build_object(
            'success', true,
            'stage', 'ready_for_driver',
            'order_id', p_order_id,
            'order_number', v_order.order_number,
            'message_ar', 'تم إنجاز التجهيز بنجاح! الطلب الآن جاهز للاستلام بواسطة سائق التوصيل.'
        );

    ELSE
        RETURN jsonb_build_object('success', false, 'error', 'INVALID_STAGE', 'message_ar', 'المرحلة المطلوبة غير صالحة');
    END IF;
END;
$$;

-- 10. Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON public.picker_tasks TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.generate_fulfillment_tasks_for_order(UUID, VARCHAR, VARCHAR) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.verify_fulfillment_scan(UUID, VARCHAR, VARCHAR, NUMERIC, NUMERIC, VARCHAR) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.record_fulfillment_substitution(UUID, UUID, VARCHAR, NUMERIC, TEXT, VARCHAR) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.record_fulfillment_shortage(UUID, NUMERIC, TEXT, VARCHAR) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.advance_fulfillment_stage(UUID, VARCHAR, VARCHAR, VARCHAR) TO anon, authenticated;

-- Refresh PostgREST schema cache
NOTIFY pgrst, 'reload schema';
