-- ==============================================================================
-- 🔄 ALDEEB MALL & HYPERMARKET — ROLLBACK SCRIPT FOR MIGRATION 20261104_016
-- ==============================================================================
-- Description:
--   Emergency rollback for Role Matrix and Multi-Branch Isolation RLS.
--   Restores database access policies to previous working state while maintaining
--   full transactional safety and zero data destruction.
-- ==============================================================================

BEGIN;

-- 1. Drop Security Definer Isolation Functions
DROP FUNCTION IF EXISTS auth.can_view_order(UUID, UUID, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS auth.can_view_dispatch(UUID, UUID) CASCADE;
DROP FUNCTION IF EXISTS auth.branch_id() CASCADE;
DROP FUNCTION IF EXISTS auth.user_role() CASCADE;
DROP FUNCTION IF EXISTS auth.is_courier() CASCADE;
DROP FUNCTION IF EXISTS auth.is_staff() CASCADE;
DROP FUNCTION IF EXISTS auth.jwt_claims() CASCADE;
DROP FUNCTION IF EXISTS auth.user_id() CASCADE;
DROP FUNCTION IF EXISTS auth.uid() CASCADE;

-- 2. Drop Role Escalation Immutability Triggers
DROP TRIGGER IF EXISTS trg_protect_staff_immutability ON public.staff_members;
DROP FUNCTION IF EXISTS public.protect_staff_immutability() CASCADE;

-- 3. Restore Base RLS on Primary Tables
DROP POLICY IF EXISTS orders_select_policy ON public.orders;
DROP POLICY IF EXISTS orders_insert_policy ON public.orders;
DROP POLICY IF EXISTS orders_update_policy ON public.orders;
DROP POLICY IF EXISTS orders_delete_policy ON public.orders;

CREATE POLICY "Allow authenticated read orders" ON public.orders
    FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow authenticated insert orders" ON public.orders
    FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Allow authenticated update orders" ON public.orders
    FOR UPDATE TO authenticated USING (true);

DROP POLICY IF EXISTS staff_members_select_policy ON public.staff_members;
DROP POLICY IF EXISTS staff_members_update_policy ON public.staff_members;
CREATE POLICY "Allow authenticated read staff" ON public.staff_members
    FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS payroll_select_policy ON public.payroll_transactions;
DROP POLICY IF EXISTS payroll_insert_policy ON public.payroll_transactions;
CREATE POLICY "Allow authenticated read payroll" ON public.payroll_transactions
    FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS courier_dispatches_select_policy ON public.courier_dispatches;
DROP POLICY IF EXISTS courier_dispatches_update_policy ON public.courier_dispatches;
CREATE POLICY "Allow authenticated read dispatches" ON public.courier_dispatches
    FOR SELECT TO authenticated USING (true);

-- 4. Unregister migration record
DELETE FROM public._schema_migrations WHERE filename = '20261104_016_role_matrix_and_branch_isolation_rls.sql';

COMMIT;
