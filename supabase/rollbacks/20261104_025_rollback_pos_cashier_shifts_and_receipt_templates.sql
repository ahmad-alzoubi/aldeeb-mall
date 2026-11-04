-- ==============================================================================
-- Rollback Migration 025: POS Cashier Shifts Management, Cash Audit Ledger & Stored Invoice Templates
-- ==============================================================================

BEGIN;

-- Drop RPC Functions
DROP FUNCTION IF EXISTS public.save_invoice_template(TEXT, TEXT, TEXT, JSONB, BOOLEAN);
DROP FUNCTION IF EXISTS public.record_invoice_print(UUID, TEXT, UUID, TEXT, TEXT, TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS public.close_cashier_shift(UUID, NUMERIC, TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS public.record_shift_movement(UUID, TEXT, NUMERIC, TEXT, TEXT, TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS public.open_cashier_shift(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, NUMERIC, TEXT);
DROP FUNCTION IF EXISTS public.generate_pos_invoice_number(TEXT, TEXT);

-- Revert columns added to public.orders
ALTER TABLE public.orders DROP CONSTRAINT IF EXISTS orders_shift_id_fkey;
DROP INDEX IF EXISTS public.idx_orders_shift_id;
ALTER TABLE public.orders DROP COLUMN IF EXISTS shift_id;
ALTER TABLE public.orders DROP COLUMN IF EXISTS is_reprinted;
ALTER TABLE public.orders DROP COLUMN IF EXISTS reprint_count;

-- Drop Tables
DROP TABLE IF EXISTS public.invoice_audit_logs CASCADE;
DROP TABLE IF EXISTS public.invoice_templates CASCADE;
DROP TABLE IF EXISTS public.cashier_shift_movements CASCADE;
DROP TABLE IF EXISTS public.cashier_shifts CASCADE;
DROP TABLE IF EXISTS public.pos_invoice_sequences CASCADE;

-- Remove migration record
DELETE FROM public._schema_migrations WHERE filename = '20261104_025_pos_cashier_shifts_and_receipt_templates.sql';

COMMIT;
