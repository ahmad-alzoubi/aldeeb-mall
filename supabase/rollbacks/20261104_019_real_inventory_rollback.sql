-- ==============================================================================
-- الديب مول (Aldeeb Mall) - Rollback Script for Migration 019
-- Rollback: 20261104_019_real_inventory_rollback.sql
-- ==============================================================================

BEGIN;

DROP FUNCTION IF EXISTS public.record_inventory_movement_atomic(text, uuid, text, numeric, numeric, text, text, text, text, text, text);
DROP FUNCTION IF EXISTS public.perform_inventory_transfer_step_atomic(uuid, text, text, text, text, numeric, numeric, text, text);
DROP FUNCTION IF EXISTS public.perform_stock_audit_reconciliation_atomic(text, uuid, numeric, text, text, text, text);
DROP FUNCTION IF EXISTS public.cancel_order_atomic(uuid, text, text, text, text);
DROP FUNCTION IF EXISTS public.process_order_return_atomic(uuid, jsonb, text, text, text, text);

DROP TABLE IF EXISTS public.inventory_audits CASCADE;
DROP TABLE IF EXISTS public.inventory_transfers CASCADE;
DROP TABLE IF EXISTS public.inventory_movements CASCADE;
DROP TABLE IF EXISTS public.branch_inventory CASCADE;

DELETE FROM public._schema_migrations WHERE filename = '20261104_019_real_inventory_and_movements.sql';

COMMIT;
