-- ==============================================================================
-- 🚀 ALDEEB MALL & HYPERMARKET — STAFF, BRANCHES & SECURITY LIVE SYNC MIGRATION
-- ==============================================================================
-- Idempotent schema migration to support persistent staff management, branch isolation,
-- password requests workflow, and real-time synchronization between Admin Dashboard & PostgreSQL.
-- ==============================================================================

-- 1. Ensure public.branches table exists with full enterprise metadata
CREATE TABLE IF NOT EXISTS public.branches (
    id VARCHAR(64) PRIMARY KEY,
    code VARCHAR(32) NOT NULL UNIQUE,
    name_ar VARCHAR(128) NOT NULL,
    name_en VARCHAR(128) NOT NULL,
    city VARCHAR(64) NOT NULL,
    district VARCHAR(128),
    address TEXT,
    phone VARCHAR(32),
    manager_name VARCHAR(128),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    terminals_count INT NOT NULL DEFAULT 4,
    daily_sales NUMERIC(14, 2) NOT NULL DEFAULT 0.00,
    currency VARCHAR(16) NOT NULL DEFAULT 'ل.س',
    type VARCHAR(32) NOT NULL DEFAULT 'supermarket',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Adjust Foreign Keys & Column Types for staff_members, payroll, and password_requests
ALTER TABLE IF EXISTS public.payroll_transactions DROP CONSTRAINT IF EXISTS payroll_transactions_employee_id_fkey;
ALTER TABLE IF EXISTS public.password_change_requests DROP CONSTRAINT IF EXISTS password_change_requests_employee_id_fkey;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = 'staff_members' 
      AND column_name = 'id' 
      AND data_type <> 'character varying'
  ) THEN
    ALTER TABLE public.staff_members ALTER COLUMN id TYPE VARCHAR(64);
  END IF;

  ALTER TABLE public.staff_members ALTER COLUMN id SET DEFAULT gen_random_uuid()::text;

  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = 'payroll_transactions' 
      AND column_name = 'employee_id' 
      AND data_type <> 'character varying'
  ) THEN
    ALTER TABLE public.payroll_transactions ALTER COLUMN employee_id TYPE VARCHAR(64);
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = 'payroll_transactions' 
      AND column_name = 'id' 
      AND data_type <> 'character varying'
  ) THEN
    ALTER TABLE public.payroll_transactions ALTER COLUMN id TYPE VARCHAR(64);
  END IF;

  ALTER TABLE public.payroll_transactions ALTER COLUMN id SET DEFAULT gen_random_uuid()::text;

  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = 'password_change_requests' 
      AND column_name = 'employee_id' 
      AND data_type <> 'character varying'
  ) THEN
    ALTER TABLE public.password_change_requests ALTER COLUMN employee_id TYPE VARCHAR(64);
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = 'password_change_requests' 
      AND column_name = 'id' 
      AND data_type <> 'character varying'
  ) THEN
    ALTER TABLE public.password_change_requests ALTER COLUMN id TYPE VARCHAR(64);
  END IF;

  ALTER TABLE public.password_change_requests ALTER COLUMN id SET DEFAULT gen_random_uuid()::text;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'payroll_transactions_employee_id_fkey'
  ) THEN
    ALTER TABLE public.payroll_transactions 
      ADD CONSTRAINT payroll_transactions_employee_id_fkey 
      FOREIGN KEY (employee_id) REFERENCES public.staff_members(id) ON DELETE CASCADE;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'password_change_requests_employee_id_fkey'
  ) THEN
    ALTER TABLE public.password_change_requests 
      ADD CONSTRAINT password_change_requests_employee_id_fkey 
      FOREIGN KEY (employee_id) REFERENCES public.staff_members(id) ON DELETE CASCADE;
  END IF;
END $$;

ALTER TABLE IF EXISTS public.staff_members ADD COLUMN IF NOT EXISTS password TEXT;
ALTER TABLE IF EXISTS public.staff_members ADD COLUMN IF NOT EXISTS session_revoked_at TIMESTAMPTZ;

-- 3. Row Level Security (RLS) Permissive Policies for Central Administration
ALTER TABLE public.branches ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all operations on branches" ON public.branches;
CREATE POLICY "Allow all operations on branches" ON public.branches FOR ALL USING (true) WITH CHECK (true);

ALTER TABLE public.staff_members ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow authenticated read staff" ON public.staff_members;
DROP POLICY IF EXISTS "Allow all operations on staff_members" ON public.staff_members;
CREATE POLICY "Allow all operations on staff_members" ON public.staff_members FOR ALL USING (true) WITH CHECK (true);

ALTER TABLE public.password_change_requests ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public read password requests" ON public.password_change_requests;
DROP POLICY IF EXISTS "Allow all operations on password_change_requests" ON public.password_change_requests;
CREATE POLICY "Allow all operations on password_change_requests" ON public.password_change_requests FOR ALL USING (true) WITH CHECK (true);

ALTER TABLE public.payroll_transactions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow authenticated read payroll" ON public.payroll_transactions;
DROP POLICY IF EXISTS "Allow accountant and admin insert payroll" ON public.payroll_transactions;
DROP POLICY IF EXISTS "Allow all operations on payroll_transactions" ON public.payroll_transactions;
CREATE POLICY "Allow all operations on payroll_transactions" ON public.payroll_transactions FOR ALL USING (true) WITH CHECK (true);

-- 4. Seed Operational Branches
INSERT INTO public.branches (id, code, name_ar, name_en, city, district, address, phone, manager_name, is_active, terminals_count, daily_sales, currency, type)
VALUES
('b-ruh-01', 'BR-RUH-01', 'هايبرماركت الرياض الرئيسي (المركز الفاخر)', 'Riyadh Flagship Hypermarket', 'الرياض', 'العليا - طريق الملك فهد', 'تقاطع طريق الملك فهد مع شارع التحلية، الرياض', '+966 11 456 7890', 'م. حسام الديب', true, 8, 142500, 'ل.س', 'hypermarket'),
('b-jed-01', 'BR-JED-01', 'فرع جدة الكورنيش (واجهة البحر)', 'Jeddah Corniche Supermarket', 'جدة', 'الشاطئ - طريق الكورنيش', 'شارع حراء، حي الشاطئ، جدة', '+966 12 654 3210', 'رامي القحطاني', true, 5, 89400, 'ل.س', 'supermarket'),
('b-dmm-01', 'BR-DMM-01', 'فرع الدمام الشاطئ ومول الشرقية', 'Dammam Eastern Province Branch', 'الدمام', 'الشاطئ الشرقي - طريق الخليج', 'مجمع الشاطئ مول، طريق الخليج العربي، الدمام', '+966 13 888 4422', 'ناصر الشمري', true, 6, 96200, 'ل.س', 'hypermarket'),
('b-dam-01', 'BR-DAM-01', 'فرع دمشق المركزي (أوتوستراد المزة)', 'Damascus Central Supermarket', 'دمشق', 'المزة - الفيلات الشرقية', 'أوتوستراد المزة، جانب مشفى الرازي، دمشق', '+963 11 611 2233', 'وائل خوري', true, 5, 115000, 'ل.س', 'supermarket'),
('b-ruh-ds02', 'BR-RUH-DS02', 'مركز تلبية النرجس فوري 15 دقيقة (Dark Store)', 'Al-Narjis Express Dark Store', 'الرياض', 'النرجس - شمال الرياض', 'حي النرجس، مخرج 7، الرياض', '+966 11 999 0011', 'سامي العتيبي', true, 3, 62000, 'ل.س', 'dark_store')
ON CONFLICT (id) DO UPDATE SET
  name_ar = EXCLUDED.name_ar,
  name_en = EXCLUDED.name_en,
  city = EXCLUDED.city,
  district = EXCLUDED.district,
  address = EXCLUDED.address,
  phone = EXCLUDED.phone,
  manager_name = EXCLUDED.manager_name,
  is_active = EXCLUDED.is_active,
  terminals_count = EXCLUDED.terminals_count,
  daily_sales = EXCLUDED.daily_sales,
  currency = EXCLUDED.currency,
  type = EXCLUDED.type;

-- 5. Seed Real Staff Members
INSERT INTO public.staff_members (
    id, employee_code, full_name, username, email, phone, role, 
    branch_id, branch_name, password, password_hash, can_change_password, 
    has_pending_password_request, basic_salary, allowances, 
    shift_start, shift_end, avatar_url, is_active, joined_date
) VALUES
('staff-admin-01', 'EMP-001', 'م. حسام الديب', 'admin', 'hussam.aldeeb@aldeebmall.com', '+966 50 111 2233', 'super_admin', 'b-ruh-01', 'هايبرماركت الرياض الرئيسي (المركز الفاخر)', 'admin', 'sha256$admin', true, false, 28000.00, 4000.00, '08:00', '17:00', 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=150&q=80', true, '2024-01-01'),
('staff-gm-01', 'EMP-002', 'د. خالد العمري', 'gm_khaled', 'k.omari@aldeebmall.com', '+966 55 222 3344', 'general_manager', 'b-ruh-01', 'هايبرماركت الرياض الرئيسي (المركز الفاخر)', 'gm123', 'sha256$gm123', false, false, 22000.00, 3500.00, '08:30', '16:30', 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?auto=format&fit=crop&w=150&q=80', true, '2024-06-15'),
('staff-auditor-01', 'EMP-003', 'أ. زياد السالم', 'auditor_ziad', 'z.salem@aldeebmall.com', '+966 54 333 4455', 'auditor', 'b-dmm-01', 'فرع الدمام الشاطئ ومول الشرقية', 'audit123', 'sha256$audit123', false, false, 14500.00, 2000.00, '08:00', '16:00', 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=150&q=80', true, '2025-02-01'),
('staff-acc-01', 'EMP-004', 'أ. طارق الشامي', 'accountant_tareq', 't.shami@aldeebmall.com', '+966 56 444 5566', 'accountant', 'b-jed-01', 'فرع جدة الكورنيش (واجهة البحر)', 'acc123', 'sha256$acc123', false, false, 12000.00, 1500.00, '09:00', '17:00', 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=150&q=80', true, '2025-03-10'),
('staff-cashier-01', 'EMP-005', 'عمر الدوسري', 'cashier_omar', 'o.dossari@aldeebmall.com', '+966 53 555 6677', 'cashier', 'b-ruh-01', 'هايبرماركت الرياض الرئيسي (المركز الفاخر)', 'pos123', 'sha256$pos123', false, true, 5800.00, 800.00, '08:00', '16:00', 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=150&q=80', true, '2025-08-01'),
('staff-mgr-02', 'EMP-006', 'رامي القحطاني', 'manager_rami', 'r.qahtani@aldeebmall.com', '+966 51 666 7788', 'branch_manager', 'b-jed-01', 'فرع جدة الكورنيش (واجهة البحر)', 'jed123', 'sha256$jed123', false, false, 10500.00, 1500.00, '08:30', '17:30', 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?auto=format&fit=crop&w=150&q=80', true, '2025-04-12'),
('staff-mgr-dam', 'EMP-007', 'وائل خوري', 'manager_wael', 'w.khoury@aldeebmall.com', '+963 11 611 2233', 'branch_manager', 'b-dam-01', 'فرع دمشق المركزي (أوتوستراد المزة)', 'dam123', 'sha256$dam123', false, false, 11000.00, 1800.00, '08:30', '17:00', 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=150&q=80', true, '2025-05-15'),
('staff-mgr-darkstore', 'EMP-008', 'سامي العتيبي', 'manager_sami', 's.otaibi@aldeebmall.com', '+966 11 999 0011', 'branch_manager', 'b-ruh-ds02', 'مركز تلبية النرجس فوري 15 دقيقة (Dark Store)', 'dark123', 'sha256$dark123', false, false, 9800.00, 1200.00, '08:00', '16:30', 'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=150&q=80', true, '2025-06-01')
ON CONFLICT (id) DO UPDATE SET
  employee_code = EXCLUDED.employee_code,
  full_name = EXCLUDED.full_name,
  username = EXCLUDED.username,
  email = EXCLUDED.email,
  phone = EXCLUDED.phone,
  role = EXCLUDED.role,
  branch_id = EXCLUDED.branch_id,
  branch_name = EXCLUDED.branch_name,
  password = EXCLUDED.password,
  can_change_password = EXCLUDED.can_change_password,
  has_pending_password_request = EXCLUDED.has_pending_password_request,
  basic_salary = EXCLUDED.basic_salary,
  allowances = EXCLUDED.allowances,
  shift_start = EXCLUDED.shift_start,
  shift_end = EXCLUDED.shift_end,
  avatar_url = EXCLUDED.avatar_url,
  is_active = EXCLUDED.is_active,
  joined_date = EXCLUDED.joined_date;

-- 6. Seed Pending Password Change Request
INSERT INTO public.password_change_requests (
    id, employee_id, reason, status, requested_at
) VALUES
('pwr-001', 'staff-cashier-01', 'اشتباه بمشاهدة أحد الموظفين المؤقتين لكلمة المرور أثناء تسجيل الدخول بنقطة البيع', 'pending', '2026-10-31T14:20:00Z')
ON CONFLICT (id) DO UPDATE SET
  employee_id = EXCLUDED.employee_id,
  reason = EXCLUDED.reason,
  status = EXCLUDED.status,
  requested_at = EXCLUDED.requested_at;
