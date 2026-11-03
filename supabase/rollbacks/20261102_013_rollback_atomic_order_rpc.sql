-- ==============================================================================
-- الديب مول (Aldeeb Mall) - Rollback Migration for 20261102_002
-- File: supabase/migrations/20261102_002_rollback.sql
-- Description: Cleanly reverts atomic RPC and restores baseline RLS policies
-- ==============================================================================

-- 1. Drop Atomic Function
DROP FUNCTION IF EXISTS public.place_order_atomic(
    text, uuid, text, text, numeric, numeric, numeric, int, numeric, numeric, text, jsonb
);

-- 2. Restore Standard Strict RLS Policies for Orders
DROP POLICY IF EXISTS "Users and guests can create orders" ON public.orders;
DROP POLICY IF EXISTS "Users can create their own orders" ON public.orders;

CREATE POLICY "Users can create their own orders"
    ON public.orders FOR INSERT
    WITH CHECK ((SELECT auth.uid()) = user_id OR public.is_admin());

DROP POLICY IF EXISTS "Users and guests can view orders" ON public.orders;
DROP POLICY IF EXISTS "Users can view their own orders" ON public.orders;

CREATE POLICY "Users can view their own orders"
    ON public.orders FOR SELECT
    USING ((SELECT auth.uid()) = user_id OR public.is_admin());

-- 3. Restore Standard Strict RLS Policies for Order Items
DROP POLICY IF EXISTS "Users and guests can create order items" ON public.order_items;
DROP POLICY IF EXISTS "Anyone can insert order items" ON public.order_items;
DROP POLICY IF EXISTS "Users can insert items for their own orders" ON public.order_items;

CREATE POLICY "Users can insert items for their own orders"
    ON public.order_items FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.orders o
            WHERE o.id = order_items.order_id
            AND (o.user_id = (SELECT auth.uid()) OR public.is_admin())
        )
    );

DROP POLICY IF EXISTS "Users and guests can view order items" ON public.order_items;
DROP POLICY IF EXISTS "Users can view items in their orders" ON public.order_items;

CREATE POLICY "Users can view items in their orders"
    ON public.order_items FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.orders o
            WHERE o.id = order_items.order_id
            AND (o.user_id = (SELECT auth.uid()) OR public.is_admin())
        )
    );
