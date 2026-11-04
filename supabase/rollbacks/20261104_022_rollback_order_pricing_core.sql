-- ==============================================================================
-- 🛒 ALDEEB MALL: EMERGENCY ROLLBACK FOR MIGRATION 020 (ORDER PRICING CORE)
-- File: supabase/rollbacks/20261104_020_rollback_order_pricing_core.sql
-- ==============================================================================

BEGIN;

-- 1. Remove idempotency key index if needed
DROP INDEX IF EXISTS public.idx_orders_idempotency_key;
ALTER TABLE public.orders DROP COLUMN IF EXISTS idempotency_key;

-- 2. Restore previous 13-argument signature if emergency rollback requested
DROP FUNCTION IF EXISTS public.place_order_atomic(text, uuid, text, text, numeric, numeric, numeric, int, numeric, numeric, text, jsonb, text, text, text, text, text);

-- Remove from _schema_migrations
DELETE FROM public._schema_migrations WHERE filename = '20261104_020_order_pricing_core_and_atomic_verification.sql';

COMMIT;
