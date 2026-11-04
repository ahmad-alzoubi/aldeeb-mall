-- ==============================================================================
-- Rollback Migration 025: Authoritative Order Management & Audit Ledger
-- ==============================================================================

BEGIN;

DROP FUNCTION IF EXISTS public.update_order_status_atomic;

DROP TABLE IF EXISTS public.order_status_history CASCADE;

-- Revert columns on orders if necessary
ALTER TABLE public.orders 
    DROP COLUMN IF EXISTS version,
    DROP COLUMN IF EXISTS cancellation_reason,
    DROP COLUMN IF EXISTS failure_reason,
    DROP COLUMN IF EXISTS courier_id,
    DROP COLUMN IF EXISTS assigned_at,
    DROP COLUMN IF EXISTS is_stock_restored;

-- Revert check constraint on orders status
ALTER TABLE public.orders 
    DROP CONSTRAINT IF EXISTS orders_status_check;

ALTER TABLE public.orders 
    ADD CONSTRAINT orders_status_check 
    CHECK (status = ANY (ARRAY[
        'pending'::text,
        'confirmed'::text,
        'packing'::text,
        'out_for_delivery'::text,
        'delivered'::text,
        'cancelled'::text
    ]));

DELETE FROM public._schema_migrations 
WHERE filename = '20261104_025_order_management_state_machine_and_audit_ledger.sql';

COMMIT;
