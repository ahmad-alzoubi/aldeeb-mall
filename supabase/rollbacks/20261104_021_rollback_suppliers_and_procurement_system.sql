-- ==============================================================================
-- Rollback for Migration 019: Suppliers & Procurement System
-- ==============================================================================

DROP FUNCTION IF EXISTS public.approve_draft_product(UUID, TEXT);
DROP FUNCTION IF EXISTS public.cancel_purchase_order(UUID, TEXT, TEXT);
DROP FUNCTION IF EXISTS public.record_supplier_payment(UUID, NUMERIC, TEXT, TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS public.receive_purchase_order_items(UUID, JSONB, TEXT, VARCHAR);
DROP FUNCTION IF EXISTS public.create_purchase_order(UUID, TEXT, VARCHAR, TEXT, TEXT, JSONB, TEXT);

DROP TABLE IF EXISTS public.supplier_payments CASCADE;
DROP TABLE IF EXISTS public.inventory_transactions CASCADE;
DROP TABLE IF EXISTS public.purchase_order_items CASCADE;
DROP TABLE IF EXISTS public.purchase_orders CASCADE;
DROP TABLE IF EXISTS public.suppliers CASCADE;

DROP SEQUENCE IF EXISTS public.sup_pay_seq;
DROP SEQUENCE IF EXISTS public.inv_trx_seq;
DROP SEQUENCE IF EXISTS public.po_number_seq;

DELETE FROM public._schema_migrations WHERE filename = '20261104_019_suppliers_and_procurement_system.sql';
