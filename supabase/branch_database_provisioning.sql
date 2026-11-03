-- ==============================================================================
-- 🏬 ALDEEB MALL: MULTI-BRANCH INDEPENDENT DATABASE & SCHEMA PROVISIONING ENGINE
-- ==============================================================================
-- Idempotent script for provisioning an isolated operational database or schema
-- for any new branch, enforcing strict cross-branch isolation.
-- ==============================================================================

-- 1. Function to provision a new branch isolated operational schema
CREATE OR REPLACE FUNCTION public.provision_isolated_branch_schema(
    p_branch_code TEXT,
    p_branch_name TEXT,
    p_city TEXT,
    p_currency TEXT DEFAULT 'ل.س'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_schema_name TEXT;
    v_result JSONB;
BEGIN
    -- Standardize schema name (e.g., branch_br_dam_01)
    v_schema_name := 'branch_' || lower(regexp_replace(p_branch_code, '[^a-zA-Z0-9]', '_', 'g'));

    -- 1. Create Isolated Branch Schema
    EXECUTE format('CREATE SCHEMA IF NOT EXISTS %I', v_schema_name);

    -- 2. Create Branch Operational Tables inside the isolated schema
    -- Branch Product Catalog (References Central Product UUID with branch-specific pricing & stock)
    EXECUTE format('
        CREATE TABLE IF NOT EXISTS %I.products (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            catalog_product_id UUID NOT NULL,
            barcode TEXT,
            name_ar TEXT NOT NULL,
            name_en TEXT,
            branch_price NUMERIC(14,2) NOT NULL,
            cost_price NUMERIC(14,2) NOT NULL DEFAULT 0.00,
            stock_quantity INTEGER NOT NULL DEFAULT 0,
            reserved_quantity INTEGER NOT NULL DEFAULT 0,
            in_transit_quantity INTEGER NOT NULL DEFAULT 0,
            damaged_quantity INTEGER NOT NULL DEFAULT 0,
            min_stock_alert INTEGER NOT NULL DEFAULT 5,
            is_available BOOLEAN NOT NULL DEFAULT true,
            updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone(''utc''::text, now())
        )', v_schema_name);

    -- Branch Orders
    EXECUTE format('
        CREATE TABLE IF NOT EXISTS %I.orders (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            order_number TEXT UNIQUE NOT NULL,
            customer_name TEXT,
            customer_phone TEXT,
            status TEXT NOT NULL DEFAULT ''pending'',
            total_amount NUMERIC(14,2) NOT NULL,
            tax_amount NUMERIC(14,2) NOT NULL DEFAULT 0.00,
            payment_method TEXT NOT NULL,
            payment_status TEXT NOT NULL DEFAULT ''unpaid'',
            created_at TIMESTAMPTZ NOT NULL DEFAULT timezone(''utc''::text, now()),
            completed_at TIMESTAMPTZ
        )', v_schema_name);

    -- Branch POS Transactions (Cashier sales)
    EXECUTE format('
        CREATE TABLE IF NOT EXISTS %I.pos_transactions (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            receipt_number TEXT UNIQUE NOT NULL,
            terminal_code TEXT NOT NULL,
            cashier_name TEXT NOT NULL,
            subtotal NUMERIC(14,2) NOT NULL,
            tax_amount NUMERIC(14,2) NOT NULL,
            grand_total NUMERIC(14,2) NOT NULL,
            payment_method TEXT NOT NULL,
            cash_received NUMERIC(14,2),
            change_given NUMERIC(14,2),
            idempotency_key TEXT UNIQUE NOT NULL,
            created_at TIMESTAMPTZ NOT NULL DEFAULT timezone(''utc''::text, now())
        )', v_schema_name);

    -- Branch Inventory Movement Ledger
    EXECUTE format('
        CREATE TABLE IF NOT EXISTS %I.inventory_movements (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            product_id UUID NOT NULL,
            movement_type TEXT NOT NULL, -- ''sale'', ''return'', ''transfer_in'', ''transfer_out'', ''adjustment''
            quantity INTEGER NOT NULL,
            balance_after INTEGER NOT NULL,
            reference_id TEXT,
            reason TEXT,
            created_by TEXT,
            created_at TIMESTAMPTZ NOT NULL DEFAULT timezone(''utc''::text, now())
        )', v_schema_name);

    -- Branch Outbox for Asynchronous Central Aggregation
    EXECUTE format('
        CREATE TABLE IF NOT EXISTS %I.event_outbox (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            event_type TEXT NOT NULL,
            payload JSONB NOT NULL,
            status TEXT NOT NULL DEFAULT ''pending'', -- ''pending'', ''synced'', ''failed''
            retry_count INTEGER NOT NULL DEFAULT 0,
            last_error TEXT,
            created_at TIMESTAMPTZ NOT NULL DEFAULT timezone(''utc''::text, now()),
            synced_at TIMESTAMPTZ
        )', v_schema_name);

    -- Build result descriptor
    v_result := jsonb_build_object(
        'status', 'success',
        'branch_code', p_branch_code,
        'schema_name', v_schema_name,
        'provisioned_at', now(),
        'isolation_level', 'physical_schema_isolation'
    );

    RETURN v_result;
END;
$$;
