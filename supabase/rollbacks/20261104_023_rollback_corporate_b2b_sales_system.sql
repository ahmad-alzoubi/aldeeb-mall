-- ==============================================================================
-- 🔄 ALDEEB MALL: ROLLBACK SCRIPT FOR MIGRATION 020 (CORPORATE B2B)
-- ==============================================================================
-- File: supabase/rollbacks/20261104_020_rollback_corporate_b2b_sales_system.sql
-- Reverts all tables, functions, and policies created by 20261104_020.
-- ==============================================================================

DROP FUNCTION IF EXISTS public.create_corporate_invoice_with_stock_deduction(JSONB);
DROP FUNCTION IF EXISTS public.record_corporate_payment(JSONB);
DROP FUNCTION IF EXISTS public.process_corporate_return_with_stock_restoration(JSONB);
DROP FUNCTION IF EXISTS public.approve_or_reject_corporate_quotation(JSONB);

DROP TABLE IF EXISTS public.corporate_return_items CASCADE;
DROP TABLE IF EXISTS public.corporate_returns CASCADE;
DROP TABLE IF EXISTS public.corporate_payments CASCADE;
DROP TABLE IF EXISTS public.corporate_invoice_items CASCADE;
DROP TABLE IF EXISTS public.corporate_invoices CASCADE;
DROP TABLE IF EXISTS public.corporate_quotation_items CASCADE;
DROP TABLE IF EXISTS public.corporate_quotations CASCADE;
DROP TABLE IF EXISTS public.corporate_accounts CASCADE;

DELETE FROM public._schema_migrations WHERE filename = '20261104_020_corporate_b2b_sales_system.sql';
