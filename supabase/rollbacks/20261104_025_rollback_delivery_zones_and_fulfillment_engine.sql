-- ==============================================================================
-- 🚚 ROLLBACK: 20261104_025_delivery_zones_and_fulfillment_engine.sql
-- Step 025 Monotonic Rollback File (Task 15)
-- ==============================================================================

BEGIN;

DROP FUNCTION IF EXISTS public.check_delivery_coverage(numeric, numeric, text, text, numeric, text);
DROP FUNCTION IF EXISTS public.haversine_distance_km(numeric, numeric, numeric, numeric);
DROP TABLE IF EXISTS public.delivery_zones CASCADE;

DELETE FROM public._schema_migrations 
WHERE filename = '20261104_025_delivery_zones_and_fulfillment_engine.sql';

COMMIT;
