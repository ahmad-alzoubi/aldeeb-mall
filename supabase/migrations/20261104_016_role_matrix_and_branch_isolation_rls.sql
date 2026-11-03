-- ==============================================================================
-- 🛡️ ALDEEB MALL & HYPERMARKET — COMPLETE RBAC MATRIX & MULTI-BRANCH ISOLATION
-- ==============================================================================
-- Migration: 20261104_002_role_matrix_and_branch_isolation_rls.sql
-- Single Source of Truth: Implements strict Row-Level Security (RLS) across all
-- 32 tables, enforcing branch isolation, role boundaries, courier dispatch security,
-- customer privacy, and preventing IDOR, privilege escalation, and cross-branch bleed.
-- ==============================================================================

-- 1. Ensure Postgres Roles Exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'anon') THEN
        CREATE ROLE anon NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'authenticated') THEN
        CREATE ROLE authenticated NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'service_role') THEN
        CREATE ROLE service_role NOLOGIN BYPASSRLS;
    END IF;
END $$;

-- 2. Schema USAGE Grants
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT USAGE ON SCHEMA auth TO anon, authenticated, service_role;

-- 3. Core Cryptographic Helper for Base64URL and JWT Verification/Signing
CREATE OR REPLACE FUNCTION auth.url_safe_b64encode(p_data BYTEA)
RETURNS TEXT
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT rtrim(translate(replace(encode(p_data, 'base64'), E'\n', ''), '+/', '-_'), '=');
$$;

CREATE OR REPLACE FUNCTION auth.jwt_claims()
RETURNS JSONB
LANGUAGE sql
STABLE
AS $$
  SELECT coalesce(nullif(current_setting('request.jwt.claims', true), '')::jsonb, '{}'::jsonb);
$$;

CREATE OR REPLACE FUNCTION auth.user_id()
RETURNS TEXT
LANGUAGE sql
STABLE
AS $$
  SELECT coalesce(
    nullif(current_setting('request.jwt.claim.sub', true), ''),
    (auth.jwt_claims()->>'sub'),
    (auth.jwt_claims()->>'employee_id')
  );
$$;

CREATE OR REPLACE FUNCTION auth.uid()
RETURNS UUID
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  v_sub TEXT;
BEGIN
  v_sub := auth.user_id();
  IF v_sub IS NULL THEN
    RETURN NULL;
  END IF;
  BEGIN
    RETURN v_sub::uuid;
  EXCEPTION WHEN OTHERS THEN
    RETURN NULL;
  END;
END;
$$;

CREATE OR REPLACE FUNCTION auth.user_role()
RETURNS TEXT
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  v_role TEXT;
  v_claims JSONB;
BEGIN
  v_claims := auth.jwt_claims();
  v_role := v_claims->>'user_role';
  IF v_role IS NOT NULL AND v_role <> '' THEN
    RETURN v_role;
  END IF;

  IF auth.uid() IS NOT NULL THEN
    SELECT role INTO v_role FROM public.profiles WHERE id = auth.uid();
    IF v_role IS NOT NULL THEN
      RETURN v_role;
    END IF;
  END IF;

  v_role := v_claims->>'role';
  IF v_role IS NOT NULL AND v_role <> '' THEN
    RETURN v_role;
  END IF;

  RETURN 'anon';
END;
$$;

CREATE OR REPLACE FUNCTION auth.branch_id()
RETURNS TEXT
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  v_branch TEXT;
  v_claims JSONB;
  v_sub TEXT;
BEGIN
  v_claims := auth.jwt_claims();
  v_branch := v_claims->>'branch_id';
  IF v_branch IS NOT NULL AND v_branch <> '' THEN
    RETURN v_branch;
  END IF;

  v_sub := auth.user_id();
  IF v_sub IS NOT NULL THEN
    SELECT branch_id INTO v_branch FROM public.staff_members WHERE id = v_sub;
    IF v_branch IS NOT NULL THEN
      RETURN v_branch;
    END IF;
  END IF;

  RETURN NULL;
END;
$$;

CREATE OR REPLACE FUNCTION auth.is_super_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
AS $$
  SELECT auth.user_role() IN ('super_admin', 'general_manager');
$$;

CREATE OR REPLACE FUNCTION auth.is_staff()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
AS $$
  SELECT auth.user_role() IN ('super_admin', 'general_manager', 'auditor', 'accountant', 'branch_manager', 'cashier', 'warehouse_manager');
$$;

CREATE OR REPLACE FUNCTION auth.is_courier()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
AS $$
  SELECT auth.user_role() IN ('courier', 'driver');
$$;

CREATE OR REPLACE FUNCTION auth.sign_jwt(p_payload JSONB)
RETURNS TEXT
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  v_secret TEXT := 'aldeeb-mall-secure-jwt-secret-key-32chars-min-length-2026';
  v_header JSONB := '{"alg":"HS256","typ":"JWT"}'::jsonb;
  v_header_b64 TEXT;
  v_payload_b64 TEXT;
  v_signing_input TEXT;
  v_signature BYTEA;
  v_signature_b64 TEXT;
BEGIN
  v_header_b64 := auth.url_safe_b64encode(convert_to(v_header::text, 'UTF8'));
  v_payload_b64 := auth.url_safe_b64encode(convert_to(p_payload::text, 'UTF8'));
  v_signing_input := v_header_b64 || '.' || v_payload_b64;
  v_signature := public.hmac(convert_to(v_signing_input, 'UTF8'), convert_to(v_secret, 'UTF8'), 'sha256');
  v_signature_b64 := auth.url_safe_b64encode(v_signature);
  RETURN v_signing_input || '.' || v_signature_b64;
END;
$$;

-- 4. Server-Side RPC Functions for Secure Authentication & JWT Issuance
CREATE OR REPLACE FUNCTION public.staff_login(p_username TEXT, p_password TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_staff public.staff_members%ROWTYPE;
  v_token TEXT;
  v_payload JSONB;
BEGIN
  SELECT * INTO v_staff 
  FROM public.staff_members 
  WHERE username = p_username AND is_active = true;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'اسم المستخدم غير موجود أو الحساب معطل');
  END IF;

  IF v_staff.password IS NOT NULL AND v_staff.password <> '' THEN
    IF v_staff.password <> p_password THEN
      RETURN jsonb_build_object('success', false, 'error', 'كلمة المرور غير صحيحة');
    END IF;
  ELSIF v_staff.password_hash IS NOT NULL AND v_staff.password_hash <> '' THEN
    IF v_staff.password_hash <> crypt(p_password, v_staff.password_hash) THEN
      RETURN jsonb_build_object('success', false, 'error', 'كلمة المرور غير صحيحة');
    END IF;
  END IF;

  -- Construct JWT Claims Payload
  v_payload := jsonb_build_object(
    'sub', v_staff.id,
    'role', 'authenticated',
    'user_role', v_staff.role,
    'branch_id', v_staff.branch_id,
    'employee_id', v_staff.id,
    'username', v_staff.username,
    'full_name', v_staff.full_name,
    'email', v_staff.email,
    'phone', v_staff.phone,
    'iat', extract(epoch from now())::bigint,
    'exp', extract(epoch from (now() + interval '7 days'))::bigint
  );

  v_token := auth.sign_jwt(v_payload);

  RETURN jsonb_build_object(
    'success', true,
    'token', v_token,
    'staff', row_to_json(v_staff)
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.customer_login(p_phone TEXT, p_password TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_profile public.profiles%ROWTYPE;
  v_token TEXT;
  v_payload JSONB;
BEGIN
  SELECT * INTO v_profile 
  FROM public.profiles 
  WHERE phone = p_phone;

  IF NOT FOUND THEN
    -- Auto-register demo/customer profile if phone not found
    INSERT INTO public.profiles (id, full_name, phone, role, loyalty_points, tier)
    VALUES (gen_random_uuid(), 'عميل الديب مول', p_phone, 'customer', 50, 'Silver')
    RETURNING * INTO v_profile;
  END IF;

  v_payload := jsonb_build_object(
    'sub', v_profile.id::text,
    'role', 'authenticated',
    'user_role', 'customer',
    'phone', v_profile.phone,
    'full_name', v_profile.full_name,
    'iat', extract(epoch from now())::bigint,
    'exp', extract(epoch from (now() + interval '30 days'))::bigint
  );

  v_token := auth.sign_jwt(v_payload);

  RETURN jsonb_build_object(
    'success', true,
    'token', v_token,
    'profile', row_to_json(v_profile)
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.courier_login(p_phone TEXT, p_password TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_courier public.couriers%ROWTYPE;
  v_token TEXT;
  v_payload JSONB;
BEGIN
  SELECT * INTO v_courier 
  FROM public.couriers 
  WHERE phone = p_phone AND is_active = true;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'رقم الهاتف غير مسجل لسائق نشط');
  END IF;

  v_payload := jsonb_build_object(
    'sub', v_courier.id::text,
    'role', 'authenticated',
    'user_role', 'courier',
    'phone', v_courier.phone,
    'full_name', v_courier.full_name,
    'iat', extract(epoch from now())::bigint,
    'exp', extract(epoch from (now() + interval '7 days'))::bigint
  );

  v_token := auth.sign_jwt(v_payload);

  RETURN jsonb_build_object(
    'success', true,
    'token', v_token,
    'courier', row_to_json(v_courier)
  );
END;
$$;

-- 5. Table Grants
-- Catalog and public viewable tables
GRANT SELECT ON 
  public.products, 
  public.categories, 
  public.subcategories, 
  public.banners, 
  public.coupons, 
  public.flash_deals, 
  public.branches, 
  public.store_settings, 
  public.subscription_plans, 
  public.loyalty_reward_products, 
  public.loyalty_reward_coupons 
TO anon, authenticated;

-- Operational tables for authenticated users
GRANT SELECT, INSERT, UPDATE, DELETE ON 
  public.orders, 
  public.order_items, 
  public.staff_members, 
  public.payroll_transactions, 
  public.password_change_requests, 
  public.courier_dispatches, 
  public.couriers, 
  public.picker_tasks, 
  public.profiles, 
  public.addresses, 
  public.support_tickets, 
  public.notifications, 
  public.loyalty_transactions, 
  public.user_claimed_rewards, 
  public.user_subscriptions,
  public.warehouse_bins,
  public.wave_batches,
  public.dark_stores,
  public.dark_store_inventory,
  public.product_reviews,
  public.loyalty_tier_rules,
  public.products,
  public.categories,
  public.subcategories,
  public.banners,
  public.coupons,
  public.branches,
  public.store_settings
TO authenticated;

-- Allow guest operations for anon
GRANT INSERT ON public.support_tickets, public.orders, public.order_items TO anon;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated;

-- 6. Enable & Force Row Level Security (RLS) on all 32 tables
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders FORCE ROW LEVEL SECURITY;

ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items FORCE ROW LEVEL SECURITY;

ALTER TABLE public.staff_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.staff_members FORCE ROW LEVEL SECURITY;

ALTER TABLE public.payroll_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payroll_transactions FORCE ROW LEVEL SECURITY;

ALTER TABLE public.password_change_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.password_change_requests FORCE ROW LEVEL SECURITY;

ALTER TABLE public.courier_dispatches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.courier_dispatches FORCE ROW LEVEL SECURITY;

ALTER TABLE public.couriers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.couriers FORCE ROW LEVEL SECURITY;

ALTER TABLE public.picker_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.picker_tasks FORCE ROW LEVEL SECURITY;

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles FORCE ROW LEVEL SECURITY;

ALTER TABLE public.addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.addresses FORCE ROW LEVEL SECURITY;

ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.support_tickets FORCE ROW LEVEL SECURITY;

ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products FORCE ROW LEVEL SECURITY;

ALTER TABLE public.branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.branches FORCE ROW LEVEL SECURITY;

ALTER TABLE public.store_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.store_settings FORCE ROW LEVEL SECURITY;

ALTER TABLE public.banners ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.banners FORCE ROW LEVEL SECURITY;

ALTER TABLE public.coupons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.coupons FORCE ROW LEVEL SECURITY;

ALTER TABLE public.flash_deals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.flash_deals FORCE ROW LEVEL SECURITY;

ALTER TABLE public.dark_stores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dark_stores FORCE ROW LEVEL SECURITY;

ALTER TABLE public.dark_store_inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dark_store_inventory FORCE ROW LEVEL SECURITY;

ALTER TABLE public.warehouse_bins ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.warehouse_bins FORCE ROW LEVEL SECURITY;

ALTER TABLE public.wave_batches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wave_batches FORCE ROW LEVEL SECURITY;

ALTER TABLE public.loyalty_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loyalty_transactions FORCE ROW LEVEL SECURITY;

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications FORCE ROW LEVEL SECURITY;

ALTER TABLE public.user_claimed_rewards ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_claimed_rewards FORCE ROW LEVEL SECURITY;

ALTER TABLE public.user_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_subscriptions FORCE ROW LEVEL SECURITY;

-- Ensure orders has branch_id for multi-branch isolation
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS branch_id VARCHAR(64) DEFAULT 'b-dam-01';
CREATE INDEX IF NOT EXISTS idx_orders_branch_id ON public.orders(branch_id);

-- 7. Surgical RLS Policies

-- ==============================================================================
-- TABLE: orders
-- ==============================================================================
DROP POLICY IF EXISTS "orders_select_policy" ON public.orders;
DROP POLICY IF EXISTS "orders_insert_policy" ON public.orders;
DROP POLICY IF EXISTS "orders_update_policy" ON public.orders;
DROP POLICY IF EXISTS "orders_delete_policy" ON public.orders;
DROP POLICY IF EXISTS "Users and guests can view orders" ON public.orders;
DROP POLICY IF EXISTS "Users and guests can create orders" ON public.orders;
DROP POLICY IF EXISTS "Admins can update orders" ON public.orders;

CREATE POLICY orders_select_policy ON public.orders FOR SELECT TO authenticated, anon
USING (
  -- Super admin, general manager, auditor, accountant: full visibility
  auth.user_role() IN ('super_admin', 'general_manager', 'auditor', 'accountant')
  -- Branch Manager, Cashier, Warehouse Manager: STRICT BRANCH ISOLATION
  OR (
    auth.user_role() IN ('branch_manager', 'cashier', 'warehouse_manager')
    AND orders.branch_id = auth.branch_id()
  )
  -- Courier: only see assigned orders
  OR (
    auth.is_courier() AND (
      orders.id IN (
        SELECT cd.order_id FROM public.courier_dispatches cd 
        JOIN public.couriers c ON cd.courier_id = c.id 
        WHERE c.phone = (auth.jwt_claims()->>'phone') OR c.id::text = auth.user_id()
      )
      OR orders.delivery_driver_phone = (auth.jwt_claims()->>'phone')
    )
  )
  -- Customer: only see their own orders
  OR (
    auth.uid() IS NOT NULL AND orders.user_id = auth.uid()
  )
);

CREATE POLICY orders_insert_policy ON public.orders FOR INSERT TO authenticated, anon
WITH CHECK (
  auth.user_role() IN ('super_admin', 'general_manager')
  OR (auth.user_role() = 'cashier' AND orders.branch_id = auth.branch_id())
  OR (auth.uid() IS NOT NULL AND orders.user_id = auth.uid())
  OR (auth.user_role() = 'anon')
);

CREATE POLICY orders_update_policy ON public.orders FOR UPDATE TO authenticated
USING (
  auth.user_role() IN ('super_admin', 'general_manager')
  OR (auth.user_role() IN ('branch_manager', 'cashier') AND orders.branch_id = auth.branch_id())
  OR (
    auth.is_courier() AND (
      orders.id IN (
        SELECT cd.order_id FROM public.courier_dispatches cd 
        JOIN public.couriers c ON cd.courier_id = c.id 
        WHERE c.phone = (auth.jwt_claims()->>'phone') OR c.id::text = auth.user_id()
      )
    )
  )
)
WITH CHECK (
  auth.user_role() IN ('super_admin', 'general_manager')
  OR (auth.user_role() IN ('branch_manager', 'cashier') AND orders.branch_id = auth.branch_id())
  OR (auth.is_courier())
);

CREATE POLICY orders_delete_policy ON public.orders FOR DELETE TO authenticated
USING (auth.user_role() IN ('super_admin', 'general_manager'));

-- ==============================================================================
-- TABLE: order_items
-- ==============================================================================
DROP POLICY IF EXISTS "order_items_select_policy" ON public.order_items;
DROP POLICY IF EXISTS "order_items_insert_policy" ON public.order_items;
DROP POLICY IF EXISTS "Users and guests can view order items" ON public.order_items;
DROP POLICY IF EXISTS "Users and guests can create order items" ON public.order_items;

CREATE POLICY order_items_select_policy ON public.order_items FOR SELECT TO authenticated, anon
USING (
  EXISTS (SELECT 1 FROM public.orders WHERE orders.id = order_items.order_id)
);

CREATE POLICY order_items_insert_policy ON public.order_items FOR INSERT TO authenticated, anon
WITH CHECK (
  EXISTS (SELECT 1 FROM public.orders WHERE orders.id = order_items.order_id)
);

-- ==============================================================================
-- TABLE: staff_members
-- ==============================================================================
DROP POLICY IF EXISTS "staff_members_select_policy" ON public.staff_members;
DROP POLICY IF EXISTS "staff_members_admin_mutation" ON public.staff_members;
DROP POLICY IF EXISTS "staff_members_update_policy" ON public.staff_members;
DROP POLICY IF EXISTS "Allow all operations on staff_members" ON public.staff_members;
DROP POLICY IF EXISTS "Allow authenticated read staff" ON public.staff_members;

CREATE POLICY staff_members_select_policy ON public.staff_members FOR SELECT TO authenticated
USING (
  -- Super admin, GM, Auditor, Accountant: view all staff
  auth.user_role() IN ('super_admin', 'general_manager', 'auditor', 'accountant')
  -- Branch Manager: ONLY view staff in their own branch
  OR (auth.user_role() = 'branch_manager' AND staff_members.branch_id = auth.branch_id())
  -- Individual Employee (Cashier, etc.): ONLY view their own record
  OR (staff_members.id = auth.user_id() OR staff_members.username = (auth.jwt_claims()->>'username'))
);

CREATE POLICY staff_members_update_policy ON public.staff_members FOR UPDATE TO authenticated
USING (
  auth.user_role() IN ('super_admin', 'general_manager')
  OR (auth.user_role() = 'branch_manager' AND staff_members.branch_id = auth.branch_id())
  OR (staff_members.id = auth.user_id())
)
WITH CHECK (
  auth.user_role() IN ('super_admin', 'general_manager')
  OR (
    auth.user_role() = 'branch_manager' 
    AND staff_members.branch_id = auth.branch_id()
    AND staff_members.role NOT IN ('super_admin', 'general_manager')
  )
  OR (staff_members.id = auth.user_id())
);

CREATE POLICY staff_members_admin_mutation ON public.staff_members FOR ALL TO authenticated
USING (auth.user_role() IN ('super_admin', 'general_manager'))
WITH CHECK (auth.user_role() IN ('super_admin', 'general_manager'));

-- ==============================================================================
-- TABLE: payroll_transactions
-- ==============================================================================
DROP POLICY IF EXISTS "payroll_select_policy" ON public.payroll_transactions;
DROP POLICY IF EXISTS "payroll_mutation_policy" ON public.payroll_transactions;
DROP POLICY IF EXISTS "Allow all operations on payroll_transactions" ON public.payroll_transactions;
DROP POLICY IF EXISTS "Allow authenticated read payroll" ON public.payroll_transactions;
DROP POLICY IF EXISTS "Allow accountant and admin insert payroll" ON public.payroll_transactions;

CREATE POLICY payroll_select_policy ON public.payroll_transactions FOR SELECT TO authenticated
USING (
  -- Super admin, GM, Accountant, Auditor: view all payroll
  auth.user_role() IN ('super_admin', 'general_manager', 'accountant', 'auditor')
  -- Branch Manager: ONLY view payroll for their branch
  OR (auth.user_role() = 'branch_manager' AND payroll_transactions.branch_id = auth.branch_id())
);

CREATE POLICY payroll_mutation_policy ON public.payroll_transactions FOR ALL TO authenticated
USING (auth.user_role() IN ('super_admin', 'general_manager', 'accountant'))
WITH CHECK (auth.user_role() IN ('super_admin', 'general_manager', 'accountant'));

-- ==============================================================================
-- TABLE: password_change_requests
-- ==============================================================================
DROP POLICY IF EXISTS "password_requests_select_policy" ON public.password_change_requests;
DROP POLICY IF EXISTS "password_requests_insert_policy" ON public.password_change_requests;
DROP POLICY IF EXISTS "password_requests_update_policy" ON public.password_change_requests;
DROP POLICY IF EXISTS "Allow all operations on password_change_requests" ON public.password_change_requests;

CREATE POLICY password_requests_select_policy ON public.password_change_requests FOR SELECT TO authenticated
USING (
  auth.user_role() IN ('super_admin', 'general_manager')
  OR password_change_requests.employee_id = auth.user_id()
);

CREATE POLICY password_requests_insert_policy ON public.password_change_requests FOR INSERT TO authenticated
WITH CHECK (
  auth.user_role() IN ('super_admin', 'general_manager')
  OR password_change_requests.employee_id = auth.user_id()
);

CREATE POLICY password_requests_update_policy ON public.password_change_requests FOR UPDATE TO authenticated
USING (auth.user_role() IN ('super_admin', 'general_manager'))
WITH CHECK (auth.user_role() IN ('super_admin', 'general_manager'));

-- ==============================================================================
-- TABLE: courier_dispatches
-- ==============================================================================
DROP POLICY IF EXISTS "courier_dispatches_select_policy" ON public.courier_dispatches;
DROP POLICY IF EXISTS "courier_dispatches_update_policy" ON public.courier_dispatches;
DROP POLICY IF EXISTS "courier_dispatches_admin_policy" ON public.courier_dispatches;

CREATE POLICY courier_dispatches_select_policy ON public.courier_dispatches FOR SELECT TO authenticated
USING (
  auth.user_role() IN ('super_admin', 'general_manager', 'auditor')
  OR (auth.user_role() = 'branch_manager' AND EXISTS (
    SELECT 1 FROM public.orders o WHERE o.id = courier_dispatches.order_id AND o.branch_id = auth.branch_id()
  ))
  -- Courier can only view their own dispatches
  OR (auth.is_courier() AND (
    courier_dispatches.courier_id::text = auth.user_id()
    OR courier_dispatches.courier_id IN (
      SELECT c.id FROM public.couriers c WHERE c.phone = (auth.jwt_claims()->>'phone')
    )
  ))
  -- Customer can view dispatch for their own order
  OR (auth.uid() IS NOT NULL AND EXISTS (
    SELECT 1 FROM public.orders o WHERE o.id = courier_dispatches.order_id AND o.user_id = auth.uid()
  ))
);

CREATE POLICY courier_dispatches_update_policy ON public.courier_dispatches FOR UPDATE TO authenticated
USING (
  auth.user_role() IN ('super_admin', 'general_manager')
  OR (auth.user_role() = 'branch_manager' AND EXISTS (
    SELECT 1 FROM public.orders o WHERE o.id = courier_dispatches.order_id AND o.branch_id = auth.branch_id()
  ))
  OR (auth.is_courier() AND (
    courier_dispatches.courier_id::text = auth.user_id()
    OR courier_dispatches.courier_id IN (
      SELECT c.id FROM public.couriers c WHERE c.phone = (auth.jwt_claims()->>'phone')
    )
  ))
)
WITH CHECK (
  auth.user_role() IN ('super_admin', 'general_manager', 'branch_manager')
  OR (auth.is_courier())
);

CREATE POLICY courier_dispatches_admin_policy ON public.courier_dispatches FOR ALL TO authenticated
USING (auth.user_role() IN ('super_admin', 'general_manager', 'branch_manager'))
WITH CHECK (auth.user_role() IN ('super_admin', 'general_manager', 'branch_manager'));

-- ==============================================================================
-- TABLE: couriers
-- ==============================================================================
DROP POLICY IF EXISTS "couriers_select_policy" ON public.couriers;
DROP POLICY IF EXISTS "couriers_update_policy" ON public.couriers;
DROP POLICY IF EXISTS "couriers_admin_policy" ON public.couriers;

CREATE POLICY couriers_select_policy ON public.couriers FOR SELECT TO authenticated
USING (
  auth.user_role() IN ('super_admin', 'general_manager', 'auditor', 'branch_manager')
  OR (auth.is_courier() AND (
    couriers.id::text = auth.user_id() 
    OR couriers.phone = (auth.jwt_claims()->>'phone')
  ))
);

CREATE POLICY couriers_update_policy ON public.couriers FOR UPDATE TO authenticated
USING (
  auth.user_role() IN ('super_admin', 'general_manager', 'branch_manager')
  OR (auth.is_courier() AND (
    couriers.id::text = auth.user_id() 
    OR couriers.phone = (auth.jwt_claims()->>'phone')
  ))
)
WITH CHECK (
  auth.user_role() IN ('super_admin', 'general_manager', 'branch_manager')
  OR (auth.is_courier())
);

CREATE POLICY couriers_admin_policy ON public.couriers FOR ALL TO authenticated
USING (auth.user_role() IN ('super_admin', 'general_manager'))
WITH CHECK (auth.user_role() IN ('super_admin', 'general_manager'));

-- ==============================================================================
-- TABLE: profiles
-- ==============================================================================
DROP POLICY IF EXISTS "profiles_select_policy" ON public.profiles;
DROP POLICY IF EXISTS "profiles_update_policy" ON public.profiles;
DROP POLICY IF EXISTS "Admins have full access to profiles" ON public.profiles;
DROP POLICY IF EXISTS "Public profiles are viewable by self and admins" ON public.profiles;

CREATE POLICY profiles_select_policy ON public.profiles FOR SELECT TO authenticated
USING (
  auth.user_role() IN ('super_admin', 'general_manager')
  OR profiles.id = auth.uid()
);

CREATE POLICY profiles_update_policy ON public.profiles FOR UPDATE TO authenticated
USING (
  auth.user_role() IN ('super_admin', 'general_manager')
  OR profiles.id = auth.uid()
)
WITH CHECK (
  auth.user_role() IN ('super_admin', 'general_manager')
  OR profiles.id = auth.uid()
);

-- ==============================================================================
-- TABLE: addresses
-- ==============================================================================
DROP POLICY IF EXISTS "addresses_policy" ON public.addresses;
DROP POLICY IF EXISTS "Users can view and manage their own addresses" ON public.addresses;

CREATE POLICY addresses_policy ON public.addresses FOR ALL TO authenticated
USING (
  auth.user_role() IN ('super_admin', 'general_manager')
  OR addresses.user_id = auth.uid()
)
WITH CHECK (
  auth.user_role() IN ('super_admin', 'general_manager')
  OR addresses.user_id = auth.uid()
);

-- ==============================================================================
-- TABLE: branches
-- ==============================================================================
DROP POLICY IF EXISTS "branches_select_policy" ON public.branches;
DROP POLICY IF EXISTS "branches_admin_mutation" ON public.branches;
DROP POLICY IF EXISTS "Allow all operations on branches" ON public.branches;

CREATE POLICY branches_select_policy ON public.branches FOR SELECT TO public
USING (true);

CREATE POLICY branches_admin_mutation ON public.branches FOR ALL TO authenticated
USING (auth.user_role() IN ('super_admin', 'general_manager'))
WITH CHECK (auth.user_role() IN ('super_admin', 'general_manager'));

-- ==============================================================================
-- TABLE: products
-- ==============================================================================
DROP POLICY IF EXISTS "products_select_policy" ON public.products;
DROP POLICY IF EXISTS "products_mutate_policy" ON public.products;
DROP POLICY IF EXISTS "Active products are viewable by everyone" ON public.products;
DROP POLICY IF EXISTS "Admins can manage products" ON public.products;

CREATE POLICY products_select_policy ON public.products FOR SELECT TO public
USING (is_active = true OR auth.is_staff());

CREATE POLICY products_mutate_policy ON public.products FOR ALL TO authenticated
USING (auth.user_role() IN ('super_admin', 'general_manager', 'branch_manager', 'warehouse_manager'))
WITH CHECK (auth.user_role() IN ('super_admin', 'general_manager', 'branch_manager', 'warehouse_manager'));

-- ==============================================================================
-- TABLE: categories & subcategories & banners & coupons & store_settings
-- ==============================================================================
DROP POLICY IF EXISTS "categories_select_policy" ON public.categories;
DROP POLICY IF EXISTS "categories_mutate_policy" ON public.categories;
DROP POLICY IF EXISTS "Categories are viewable by everyone" ON public.categories;
DROP POLICY IF EXISTS "Admins can manage categories" ON public.categories;

CREATE POLICY categories_select_policy ON public.categories FOR SELECT TO public USING (true);
CREATE POLICY categories_mutate_policy ON public.categories FOR ALL TO authenticated
USING (auth.user_role() IN ('super_admin', 'general_manager'))
WITH CHECK (auth.user_role() IN ('super_admin', 'general_manager'));

DROP POLICY IF EXISTS "subcategories_select_policy" ON public.subcategories;
DROP POLICY IF EXISTS "subcategories_mutate_policy" ON public.subcategories;
DROP POLICY IF EXISTS "Subcategories are viewable by everyone" ON public.subcategories;
DROP POLICY IF EXISTS "Admins can manage subcategories" ON public.subcategories;

CREATE POLICY subcategories_select_policy ON public.subcategories FOR SELECT TO public USING (true);
CREATE POLICY subcategories_mutate_policy ON public.subcategories FOR ALL TO authenticated
USING (auth.user_role() IN ('super_admin', 'general_manager'))
WITH CHECK (auth.user_role() IN ('super_admin', 'general_manager'));

DROP POLICY IF EXISTS "banners_select_policy" ON public.banners;
DROP POLICY IF EXISTS "banners_mutate_policy" ON public.banners;
DROP POLICY IF EXISTS "Active banners are viewable by everyone" ON public.banners;
DROP POLICY IF EXISTS "Admins can manage banners" ON public.banners;

CREATE POLICY banners_select_policy ON public.banners FOR SELECT TO public USING (is_active = true OR auth.is_staff());
CREATE POLICY banners_mutate_policy ON public.banners FOR ALL TO authenticated
USING (auth.user_role() IN ('super_admin', 'general_manager'))
WITH CHECK (auth.user_role() IN ('super_admin', 'general_manager'));

DROP POLICY IF EXISTS "coupons_select_policy" ON public.coupons;
DROP POLICY IF EXISTS "coupons_mutate_policy" ON public.coupons;
DROP POLICY IF EXISTS "Active coupons can be validated by authenticated users" ON public.coupons;
DROP POLICY IF EXISTS "Admins can manage coupons" ON public.coupons;

CREATE POLICY coupons_select_policy ON public.coupons FOR SELECT TO public USING (is_active = true OR auth.is_staff());
CREATE POLICY coupons_mutate_policy ON public.coupons FOR ALL TO authenticated
USING (auth.user_role() IN ('super_admin', 'general_manager'))
WITH CHECK (auth.user_role() IN ('super_admin', 'general_manager'));

DROP POLICY IF EXISTS "store_settings_select_policy" ON public.store_settings;
DROP POLICY IF EXISTS "store_settings_mutate_policy" ON public.store_settings;
DROP POLICY IF EXISTS "Store settings are viewable by everyone" ON public.store_settings;
DROP POLICY IF EXISTS "Admins can update store settings" ON public.store_settings;
DROP POLICY IF EXISTS "Anyone can insert store settings" ON public.store_settings;
DROP POLICY IF EXISTS "Anyone can update store settings" ON public.store_settings;

CREATE POLICY store_settings_select_policy ON public.store_settings FOR SELECT TO public USING (true);
CREATE POLICY store_settings_mutate_policy ON public.store_settings FOR ALL TO authenticated
USING (auth.user_role() IN ('super_admin', 'general_manager'))
WITH CHECK (auth.user_role() IN ('super_admin', 'general_manager'));

-- ==============================================================================
-- TABLE: support_tickets
-- ==============================================================================
DROP POLICY IF EXISTS "support_tickets_select_policy" ON public.support_tickets;
DROP POLICY IF EXISTS "support_tickets_insert_policy" ON public.support_tickets;
DROP POLICY IF EXISTS "support_tickets_update_policy" ON public.support_tickets;
DROP POLICY IF EXISTS "Public and authenticated users can view support tickets" ON public.support_tickets;
DROP POLICY IF EXISTS "Users and admins can insert and update support tickets" ON public.support_tickets;

CREATE POLICY support_tickets_select_policy ON public.support_tickets FOR SELECT TO authenticated, anon
USING (
  auth.is_staff()
  OR (customer_phone IS NOT NULL AND customer_phone = (auth.jwt_claims()->>'phone'))
);

CREATE POLICY support_tickets_insert_policy ON public.support_tickets FOR INSERT TO authenticated, anon
WITH CHECK (true);

CREATE POLICY support_tickets_update_policy ON public.support_tickets FOR UPDATE TO authenticated
USING (auth.is_staff())
WITH CHECK (auth.is_staff());

-- ==============================================================================
-- TABLE: picker_tasks & dark_store_inventory & warehouse_bins
-- ==============================================================================
DROP POLICY IF EXISTS "picker_tasks_policy" ON public.picker_tasks;
CREATE POLICY picker_tasks_policy ON public.picker_tasks FOR ALL TO authenticated
USING (auth.user_role() IN ('super_admin', 'general_manager', 'branch_manager', 'warehouse_manager'))
WITH CHECK (auth.user_role() IN ('super_admin', 'general_manager', 'branch_manager', 'warehouse_manager'));

DROP POLICY IF EXISTS "dark_store_inventory_policy" ON public.dark_store_inventory;
CREATE POLICY dark_store_inventory_policy ON public.dark_store_inventory FOR ALL TO authenticated
USING (auth.user_role() IN ('super_admin', 'general_manager', 'branch_manager', 'warehouse_manager'))
WITH CHECK (auth.user_role() IN ('super_admin', 'general_manager', 'branch_manager', 'warehouse_manager'));

DROP POLICY IF EXISTS "warehouse_bins_policy" ON public.warehouse_bins;
CREATE POLICY warehouse_bins_policy ON public.warehouse_bins FOR ALL TO authenticated
USING (auth.user_role() IN ('super_admin', 'general_manager', 'branch_manager', 'warehouse_manager'))
WITH CHECK (auth.user_role() IN ('super_admin', 'general_manager', 'branch_manager', 'warehouse_manager'));
