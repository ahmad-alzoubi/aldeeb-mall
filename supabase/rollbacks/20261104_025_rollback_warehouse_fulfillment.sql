-- ==============================================================================
-- Rollback: 20261104_025_rollback_warehouse_fulfillment.sql
-- Description: Clean transactional reversal of Task 14 fulfillment enhancements.
-- ==============================================================================

BEGIN;

-- 1. Drop Stored Procedures
DROP FUNCTION IF EXISTS public.advance_fulfillment_stage(UUID, VARCHAR, VARCHAR, VARCHAR);
DROP FUNCTION IF EXISTS public.record_fulfillment_shortage(UUID, NUMERIC, TEXT, VARCHAR);
DROP FUNCTION IF EXISTS public.record_fulfillment_substitution(UUID, UUID, VARCHAR, NUMERIC, TEXT, VARCHAR);
DROP FUNCTION IF EXISTS public.verify_fulfillment_scan(UUID, VARCHAR, VARCHAR, NUMERIC, NUMERIC, VARCHAR);
DROP FUNCTION IF EXISTS public.generate_fulfillment_tasks_for_order(UUID, VARCHAR, VARCHAR);

-- 2. Drop Constraints & Added Columns
ALTER TABLE public.picker_tasks DROP CONSTRAINT IF EXISTS picker_tasks_verification_method_check;
ALTER TABLE public.picker_tasks DROP CONSTRAINT IF EXISTS picker_tasks_item_type_check;
ALTER TABLE public.picker_tasks DROP CONSTRAINT IF EXISTS picker_tasks_stage_check;
ALTER TABLE public.picker_tasks DROP CONSTRAINT IF EXISTS picker_tasks_status_check;

ALTER TABLE public.picker_tasks 
    ADD CONSTRAINT picker_tasks_status_check 
    CHECK (status IN ('pending', 'picked', 'out_of_stock', 'substituted'));

ALTER TABLE public.picker_tasks 
    DROP COLUMN IF EXISTS order_item_id,
    DROP COLUMN IF EXISTS branch_id,
    DROP COLUMN IF EXISTS branch_name,
    DROP COLUMN IF EXISTS assigned_staff_id,
    DROP COLUMN IF EXISTS assigned_staff_name,
    DROP COLUMN IF EXISTS stage,
    DROP COLUMN IF EXISTS item_type,
    DROP COLUMN IF EXISTS unit,
    DROP COLUMN IF EXISTS expected_weight,
    DROP COLUMN IF EXISTS actual_weight,
    DROP COLUMN IF EXISTS verification_method,
    DROP COLUMN IF EXISTS scanned_barcode,
    DROP COLUMN IF EXISTS is_substituted,
    DROP COLUMN IF EXISTS substitute_product_id,
    DROP COLUMN IF EXISTS substitute_product_name,
    DROP COLUMN IF EXISTS substitute_barcode,
    DROP COLUMN IF EXISTS substitution_reason,
    DROP COLUMN IF EXISTS price_difference,
    DROP COLUMN IF EXISTS is_shortage,
    DROP COLUMN IF EXISTS shortage_qty,
    DROP COLUMN IF EXISTS shortage_reason,
    DROP COLUMN IF EXISTS notes,
    DROP COLUMN IF EXISTS packing_box_id,
    DROP COLUMN IF EXISTS sorted_bin,
    DROP COLUMN IF EXISTS sorted_at,
    DROP COLUMN IF EXISTS packed_at;

-- 3. Revert order status check constraint
ALTER TABLE public.orders DROP CONSTRAINT IF EXISTS orders_status_check;
ALTER TABLE public.orders ADD CONSTRAINT orders_status_check 
    CHECK (status = ANY (ARRAY['pending'::text, 'confirmed'::text, 'packing'::text, 'out_for_delivery'::text, 'delivered'::text, 'cancelled'::text]));

-- 4. Notify PostgREST
NOTIFY pgrst, 'reload schema';

COMMIT;
