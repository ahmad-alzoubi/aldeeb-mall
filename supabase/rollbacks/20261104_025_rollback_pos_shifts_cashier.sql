-- ==============================================================================
-- Rollback Migration 025: POS Shifts, Cashier Governance & Atomic POS Checkout
-- ==============================================================================

BEGIN;

DROP FUNCTION IF EXISTS public.process_pos_sale_atomic(TEXT, TEXT, TEXT, TEXT, TEXT, UUID, TEXT, TEXT, TEXT, NUMERIC, NUMERIC, TEXT, NUMERIC, NUMERIC, NUMERIC, INTEGER, NUMERIC, NUMERIC, JSONB, TEXT);
DROP FUNCTION IF EXISTS public.lookup_customer_by_phone(TEXT);
DROP FUNCTION IF EXISTS public.get_active_pos_shift(TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS public.close_pos_shift(UUID, NUMERIC, TEXT);
DROP FUNCTION IF EXISTS public.open_pos_shift(TEXT, TEXT, TEXT, NUMERIC, TEXT);
DROP FUNCTION IF EXISTS public.verify_staff_pin(TEXT, TEXT);

ALTER TABLE public.orders DROP CONSTRAINT IF EXISTS orders_shift_id_fkey;
ALTER TABLE public.orders DROP CONSTRAINT IF EXISTS orders_cashier_id_fkey;
DROP INDEX IF EXISTS public.idx_orders_shift_id;
DROP INDEX IF EXISTS public.idx_orders_cashier_id;
ALTER TABLE public.orders DROP COLUMN IF EXISTS shift_id;
ALTER TABLE public.orders DROP COLUMN IF EXISTS cashier_id;

DROP TABLE IF EXISTS public.pos_shifts CASCADE;
DROP SEQUENCE IF EXISTS public.pos_shift_number_seq CASCADE;

DELETE FROM public._schema_migrations WHERE filename = '20261104_025_pos_shifts_cashier_and_atomic_checkout.sql';

COMMIT;
