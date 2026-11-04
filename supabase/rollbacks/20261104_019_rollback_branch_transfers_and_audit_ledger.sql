-- ==============================================================================
-- 🏬 ALDEEB MALL: ROLLBACK SCRIPT FOR MIGRATION 019
-- File: supabase/rollbacks/20261104_019_rollback_branch_transfers_and_audit_ledger.sql
-- Safely rolls back RPCs, policies, and tables introduced in migration 019.
-- ==============================================================================

BEGIN;

-- Drop RPC Functions
DROP FUNCTION IF EXISTS public.rpc_create_branch_atomic(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, INT, TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS public.rpc_compensate_transfer(UUID, TEXT, TEXT, TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS public.rpc_cancel_transfer(UUID, TEXT, TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS public.rpc_receive_and_close_transfer(UUID, INT, INT, TEXT, TEXT, TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS public.rpc_dispatch_transfer(UUID, TEXT, TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS public.rpc_approve_and_reserve_transfer(UUID, TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS public.rpc_create_inventory_transfer(UUID, UUID, UUID, INT, TEXT, TEXT, TEXT, TEXT, TEXT);

-- Drop Tables
DROP TABLE IF EXISTS public.inventory_compensations CASCADE;
DROP TABLE IF EXISTS public.inventory_transfers CASCADE;
DROP TABLE IF EXISTS public.inventory_movements CASCADE;
DROP TABLE IF EXISTS public.audit_logs CASCADE;

-- Remove added columns from dark_store_inventory if required
ALTER TABLE public.dark_store_inventory DROP COLUMN IF EXISTS quantity_damaged;
ALTER TABLE public.dark_store_inventory DROP COLUMN IF EXISTS quantity_in_transit;
ALTER TABLE public.dark_store_inventory DROP COLUMN IF EXISTS bin_location;

-- Remove branch_id from dark_stores if required
ALTER TABLE public.dark_stores DROP COLUMN IF EXISTS branch_id;

-- Remove from _schema_migrations
DELETE FROM public._schema_migrations WHERE filename = '20261104_019_branch_transfers_and_audit_ledger.sql';

COMMIT;
