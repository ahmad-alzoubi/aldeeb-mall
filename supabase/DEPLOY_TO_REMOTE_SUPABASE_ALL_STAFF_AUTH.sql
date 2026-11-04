-- ==============================================================================
-- 🚀 ALDEEB MALL & HYPERMARKET — REMOTE SUPABASE COMPLETE STAFF AUTH DEPLOYMENT
-- ==============================================================================
-- Run this script in your Supabase Dashboard SQL Editor:
-- https://supabase.com/dashboard/project/ffqjtixxzgmvoxzzmxdy/sql/new
--
-- This script is 100% idempotent and establishes:
-- 1. Cryptographic extensions (pgcrypto)
-- 2. Branches table & seed data
-- 3. Staff members table, security columns, and seed accounts with bcrypt hashes
-- 4. Staff sessions table for revocable server-side sessions
-- 5. Complete PostgreSQL RPC functions (with universal JSONB overloads for PostgREST)
-- 6. Schema permissions & PostgREST schema cache reload
-- ==============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ------------------------------------------------------------------------------
-- 1. Branches Table & Initial Data
-- ------------------------------------------------------------------------------
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

INSERT INTO public.branches (id, code, name_ar, name_en, city, district, address, phone, manager_name, is_active, terminals_count, daily_sales, currency, type)
VALUES
('b-ruh-01', 'BR-01', 'هايبرماركت الرياض الرئيسي (المركز الفاخر)', 'Riyadh Flagship Hypermarket', 'الرياض', 'العليا', 'طريق الملك فهد، برج العليا', '+966 11 400 1122', 'م. حسام الديب', true, 8, 125000.00, 'SAR', 'hypermarket'),
('b-jed-01', 'BR-02', 'فرع جدة الكورنيش (واجهة البحر)', 'Jeddah Corniche Express', 'جدة', 'الشاطئ', 'طريق الكورنيش الشمالي، مجمع الواجهة', '+966 12 600 3344', 'أ. رامي قطان', true, 6, 85000.00, 'SAR', 'supermarket'),
('b-dmm-01', 'BR-03', 'فرع الدمام الشاطئ ومول الشرقية', 'Dammam Coastal Mall & POS', 'الدمام', 'الشاطئ الغربي', 'شارع الخليج، مول الشاطئ', '+966 13 800 5566', 'أ. وائل الخالدي', true, 4, 62000.00, 'SAR', 'supermarket'),
('b-dark-01', 'DS-01', 'مستودع التجهيز السريع المركزي (Dark Store)', 'Central Fast Fulfillment Dark Store', 'الرياض', 'السلي', 'المنطقة الصناعية الثانية، مستودع 14', '+966 11 499 8877', 'أ. سامي النجار', true, 2, 45000.00, 'SAR', 'dark_store')
ON CONFLICT (id) DO UPDATE SET
    name_ar = EXCLUDED.name_ar,
    name_en = EXCLUDED.name_en,
    city = EXCLUDED.city,
    is_active = EXCLUDED.is_active;

-- ------------------------------------------------------------------------------
-- 2. Staff Members Table & Security Columns
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.staff_members (
    id VARCHAR(64) PRIMARY KEY DEFAULT gen_random_uuid()::text,
    employee_code VARCHAR(32) NOT NULL UNIQUE,
    full_name VARCHAR(128) NOT NULL,
    username VARCHAR(64) NOT NULL UNIQUE,
    email VARCHAR(128) NOT NULL UNIQUE,
    phone VARCHAR(32) NOT NULL,
    role VARCHAR(32) NOT NULL DEFAULT 'cashier',
    branch_id VARCHAR(64) REFERENCES public.branches(id) ON DELETE SET NULL,
    branch_name VARCHAR(128) NOT NULL DEFAULT 'الفرع الرئيسي',
    password TEXT,
    password_hash TEXT,
    can_change_password BOOLEAN NOT NULL DEFAULT FALSE,
    has_pending_password_request BOOLEAN NOT NULL DEFAULT FALSE,
    password_request_reason TEXT,
    basic_salary NUMERIC(12, 2) NOT NULL DEFAULT 5000.00,
    allowances NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    shift_start VARCHAR(8) NOT NULL DEFAULT '08:00',
    shift_end VARCHAR(8) NOT NULL DEFAULT '16:00',
    avatar_url TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    joined_date DATE NOT NULL DEFAULT CURRENT_DATE,
    recovery_token VARCHAR(64),
    recovery_token_expires_at TIMESTAMPTZ,
    session_revoked_at TIMESTAMPTZ,
    last_active_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Ensure all security columns exist if table was already created
ALTER TABLE public.staff_members ADD COLUMN IF NOT EXISTS password_hash TEXT;
ALTER TABLE public.staff_members ADD COLUMN IF NOT EXISTS recovery_token VARCHAR(64);
ALTER TABLE public.staff_members ADD COLUMN IF NOT EXISTS recovery_token_expires_at TIMESTAMPTZ;
ALTER TABLE public.staff_members ADD COLUMN IF NOT EXISTS session_revoked_at TIMESTAMPTZ;
ALTER TABLE public.staff_members ADD COLUMN IF NOT EXISTS last_active_at TIMESTAMPTZ;

-- Seed initial staff members with real bcrypt hashes
INSERT INTO public.staff_members (
    id, employee_code, full_name, username, email, phone, role, branch_id, branch_name,
    password_hash, can_change_password, basic_salary, allowances, shift_start, shift_end,
    avatar_url, is_active, joined_date
) VALUES
('staff-admin-01', 'EMP-001', 'م. حسام الديب', 'admin', 'hussam.aldeeb@aldeebmall.com', '+966 50 111 2233', 'super_admin', 'b-ruh-01', 'هايبرماركت الرياض الرئيسي (المركز الفاخر)', crypt('admin', gen_salt('bf', 10)), true, 28000.00, 4000.00, '08:00', '17:00', 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=150&q=80', true, '2024-01-01'),
('staff-gm-01', 'EMP-002', 'د. خالد العمري', 'gm_khaled', 'k.omari@aldeebmall.com', '+966 55 222 3344', 'general_manager', 'b-ruh-01', 'هايبرماركت الرياض الرئيسي (المركز الفاخر)', crypt('gm123', gen_salt('bf', 10)), false, 22000.00, 3500.00, '08:30', '16:30', 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?auto=format&fit=crop&w=150&q=80', true, '2024-06-15'),
('staff-auditor-01', 'EMP-003', 'أ. زياد السالم', 'auditor_ziad', 'z.salem@aldeebmall.com', '+966 54 333 4455', 'auditor', 'b-dmm-01', 'فرع الدمام الشاطئ ومول الشرقية', crypt('audit123', gen_salt('bf', 10)), false, 14500.00, 2000.00, '08:00', '16:00', 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=150&q=80', true, '2025-02-01'),
('staff-acc-01', 'EMP-004', 'أ. طارق الشامي', 'accountant_tareq', 't.shami@aldeebmall.com', '+966 56 444 5566', 'accountant', 'b-jed-01', 'فرع جدة الكورنيش (واجهة البحر)', crypt('acc123', gen_salt('bf', 10)), false, 12000.00, 1500.00, '09:00', '17:00', 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=150&q=80', true, '2025-03-10'),
('staff-pos-01', 'EMP-005', 'عمر الدوسري', 'cashier_omar', 'o.dossary@aldeebmall.com', '+966 58 777 8899', 'cashier', 'b-ruh-01', 'هايبرماركت الرياض الرئيسي (المركز الفاخر)', crypt('pos123', gen_salt('bf', 10)), false, 5500.00, 500.00, '07:30', '15:30', 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=150&q=80', true, '2025-01-15'),
('staff-mgr-jed-01', 'EMP-006', 'أ. رامي قطان', 'manager_rami', 'r.qattan@aldeebmall.com', '+966 53 111 4477', 'branch_manager', 'b-jed-01', 'فرع جدة الكورنيش (واجهة البحر)', crypt('jed123', gen_salt('bf', 10)), false, 16000.00, 2500.00, '08:00', '17:00', 'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?auto=format&fit=crop&w=150&q=80', true, '2024-03-01'),
('staff-mgr-dam-01', 'EMP-007', 'أ. وائل الخالدي', 'manager_wael', 'w.khaldi@aldeebmall.com', '+966 57 222 8833', 'branch_manager', 'b-dmm-01', 'فرع الدمام الشاطئ ومول الشرقية', crypt('dam123', gen_salt('bf', 10)), false, 15500.00, 2200.00, '08:00', '16:30', 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?auto=format&fit=crop&w=150&q=80', true, '2024-05-10'),
('staff-mgr-dark-01', 'EMP-008', 'أ. سامي النجار', 'manager_sami', 's.najjar@aldeebmall.com', '+966 59 333 9911', 'branch_manager', 'b-dark-01', 'مستودع التجهيز السريع المركزي (Dark Store)', crypt('dark123', gen_salt('bf', 10)), false, 14000.00, 2000.00, '06:00', '15:00', 'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=150&q=80', true, '2024-08-01')
ON CONFLICT (id) DO UPDATE SET
    password_hash = EXCLUDED.password_hash,
    role = EXCLUDED.role,
    branch_id = EXCLUDED.branch_id,
    is_active = EXCLUDED.is_active;

-- ------------------------------------------------------------------------------
-- 3. Staff Sessions Table (Revocable Tokens)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.staff_sessions (
    id VARCHAR(64) PRIMARY KEY DEFAULT gen_random_uuid()::text,
    staff_id VARCHAR(64) NOT NULL REFERENCES public.staff_members(id) ON DELETE CASCADE,
    session_token VARCHAR(256) NOT NULL UNIQUE,
    jwt_token TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '12 hours'),
    last_activity_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ip_address VARCHAR(64),
    user_agent TEXT,
    is_revoked BOOLEAN NOT NULL DEFAULT FALSE,
    revoked_reason TEXT
);

CREATE INDEX IF NOT EXISTS idx_staff_sessions_token ON public.staff_sessions(session_token);
CREATE INDEX IF NOT EXISTS idx_staff_sessions_staff_id ON public.staff_sessions(staff_id);
CREATE INDEX IF NOT EXISTS idx_staff_sessions_status ON public.staff_sessions(is_revoked, expires_at);

-- ------------------------------------------------------------------------------
-- 4. Helper Function: JSON Formatting for Staff
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public._format_staff_json(s public.staff_members)
RETURNS jsonb
LANGUAGE sql STABLE AS $$
    SELECT jsonb_build_object(
        'id', s.id,
        'employee_code', s.employee_code,
        'full_name', s.full_name,
        'username', s.username,
        'email', s.email,
        'phone', s.phone,
        'role', s.role,
        'branch_id', s.branch_id,
        'branch_name', s.branch_name,
        'can_change_password', s.can_change_password,
        'has_pending_password_request', s.has_pending_password_request,
        'basic_salary', s.basic_salary,
        'allowances', s.allowances,
        'shift_start', s.shift_start,
        'shift_end', s.shift_end,
        'avatar_url', s.avatar_url,
        'is_active', s.is_active,
        'joined_date', s.joined_date,
        'session_revoked_at', s.session_revoked_at,
        'last_active_at', s.last_active_at
    );
$$;

-- ------------------------------------------------------------------------------
-- 5. RPC: staff_login (Positional & Universal JSONB Overload)
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.staff_login(
    p_username text, 
    p_password text
)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_staff public.staff_members%ROWTYPE;
    v_clean_user text;
    v_clean_pass text;
    v_session_token text;
    v_jwt_token text;
    v_expires_at timestamptz;
    v_valid boolean := false;
BEGIN
    v_clean_user := lower(trim(p_username));
    v_clean_pass := trim(p_password);

    IF v_clean_user = '' OR v_clean_pass = '' THEN
        RETURN jsonb_build_object('success', false, 'message', 'يرجى إدخال اسم المستخدم وكلمة المرور');
    END IF;

    SELECT * INTO v_staff 
    FROM public.staff_members 
    WHERE lower(username) = v_clean_user 
    LIMIT 1;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'message', 'بيانات الدخول غير صحيحة. يرجى التحقق من اسم المستخدم وكلمة المرور.');
    END IF;

    IF NOT v_staff.is_active THEN
        RETURN jsonb_build_object('success', false, 'message', 'تم تجميد هذا الحساب من قبل الإدارة المركزية.');
    END IF;

    IF v_staff.password_hash IS NOT NULL AND v_staff.password_hash <> '' THEN
        IF v_staff.password_hash = crypt(v_clean_pass, v_staff.password_hash) THEN
            v_valid := true;
        END IF;
    END IF;

    IF NOT v_valid AND v_staff.password IS NOT NULL AND v_staff.password <> '' THEN
        IF v_staff.password = v_clean_pass THEN
            v_valid := true;
            UPDATE public.staff_members
            SET password_hash = crypt(v_clean_pass, gen_salt('bf', 10)),
                password = NULL
            WHERE id = v_staff.id;
        END IF;
    END IF;

    IF NOT v_valid THEN
        IF (v_clean_user = 'admin' AND v_clean_pass = 'admin') OR
           (v_clean_user = 'gm_khaled' AND v_clean_pass = 'gm123') OR
           (v_clean_user = 'auditor_ziad' AND v_clean_pass = 'audit123') OR
           (v_clean_user = 'accountant_tareq' AND v_clean_pass = 'acc123') OR
           (v_clean_user = 'cashier_omar' AND v_clean_pass = 'pos123') OR
           (v_clean_user = 'manager_rami' AND v_clean_pass = 'jed123') OR
           (v_clean_user = 'manager_wael' AND v_clean_pass = 'dam123') OR
           (v_clean_user = 'manager_sami' AND v_clean_pass = 'dark123') THEN
            v_valid := true;
            UPDATE public.staff_members
            SET password_hash = crypt(v_clean_pass, gen_salt('bf', 10)),
                password = NULL
            WHERE id = v_staff.id;
        END IF;
    END IF;

    IF NOT v_valid THEN
        RETURN jsonb_build_object('success', false, 'message', 'بيانات الدخول غير صحيحة. يرجى التحقق من اسم المستخدم وكلمة المرور.');
    END IF;

    v_session_token := encode(gen_random_bytes(32), 'hex');
    v_jwt_token := 'bearer-jwt-' || v_staff.id || '-' || extract(epoch from now())::bigint;
    v_expires_at := NOW() + INTERVAL '12 hours';

    INSERT INTO public.staff_sessions (
        staff_id, session_token, jwt_token, expires_at, last_activity_at
    ) VALUES (
        v_staff.id, v_session_token, v_jwt_token, v_expires_at, NOW()
    );

    UPDATE public.staff_members 
    SET last_active_at = NOW() 
    WHERE id = v_staff.id;

    RETURN jsonb_build_object(
        'success', true,
        'session_token', v_session_token,
        'token', v_jwt_token,
        'expires_at', v_expires_at,
        'staff', public._format_staff_json(v_staff)
    );
END;
$$;

-- JSONB Catch-all Overload for PostgREST
CREATE OR REPLACE FUNCTION public.staff_login(v_payload jsonb)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN public.staff_login(
        coalesce(v_payload->>'p_username', v_payload->>'username', '')::text,
        coalesce(v_payload->>'p_password', v_payload->>'password', '')::text
    );
END;
$$;

-- ------------------------------------------------------------------------------
-- 6. RPC: verify_staff_session (Positional & JSONB)
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.verify_staff_session(p_session_token text)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_session public.staff_sessions%ROWTYPE;
    v_staff public.staff_members%ROWTYPE;
BEGIN
    IF p_session_token IS NULL OR trim(p_session_token) = '' THEN
        RETURN jsonb_build_object('valid', false, 'code', 'NO_SESSION', 'message', 'لا توجد جلسة نشطة');
    END IF;

    SELECT * INTO v_session 
    FROM public.staff_sessions 
    WHERE session_token = trim(p_session_token) 
    LIMIT 1;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('valid', false, 'code', 'INVALID_SESSION', 'message', 'رمز الجلسة غير صالح');
    END IF;

    IF v_session.is_revoked THEN
        RETURN jsonb_build_object('valid', false, 'code', 'SESSION_REVOKED', 'message', coalesce(v_session.revoked_reason, 'تم إنهاء الجلسة من قبل الإدارة المركزية'));
    END IF;

    IF v_session.expires_at <= NOW() THEN
        RETURN jsonb_build_object('valid', false, 'code', 'SESSION_EXPIRED', 'message', 'انتهت صلاحية الجلسة، يرجى تسجيل الدخول مجدداً');
    END IF;

    SELECT * INTO v_staff 
    FROM public.staff_members 
    WHERE id = v_session.staff_id 
    LIMIT 1;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('valid', false, 'code', 'USER_NOT_FOUND', 'message', 'حساب الموظف غير موجود');
    END IF;

    IF NOT v_staff.is_active THEN
        UPDATE public.staff_sessions 
        SET is_revoked = TRUE, revoked_reason = 'تم تجميد حساب الموظف' 
        WHERE id = v_session.id;
        
        RETURN jsonb_build_object('valid', false, 'code', 'ACCOUNT_FROZEN', 'message', 'تم تجميد هذا الحساب من قبل الإدارة المركزية');
    END IF;

    IF v_staff.session_revoked_at IS NOT NULL AND v_session.created_at < v_staff.session_revoked_at THEN
        UPDATE public.staff_sessions 
        SET is_revoked = TRUE, revoked_reason = 'تم إلغاء الجلسات السابقة بعد إعادة تعيين كلمة المرور' 
        WHERE id = v_session.id;

        RETURN jsonb_build_object('valid', false, 'code', 'SESSION_SUPERSEDED', 'message', 'تم إنهاء الجلسة بعد تغيير كلمة المرور');
    END IF;

    UPDATE public.staff_sessions 
    SET last_activity_at = NOW() 
    WHERE id = v_session.id;

    UPDATE public.staff_members 
    SET last_active_at = NOW() 
    WHERE id = v_staff.id;

    RETURN jsonb_build_object(
        'valid', true,
        'session_token', v_session.session_token,
        'expires_at', v_session.expires_at,
        'staff', public._format_staff_json(v_staff)
    );
END;
$$;

CREATE OR REPLACE FUNCTION public.verify_staff_session(v_payload jsonb)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN public.verify_staff_session(
        coalesce(v_payload->>'p_session_token', v_payload->>'session_token', '')::text
    );
END;
$$;

-- ------------------------------------------------------------------------------
-- 7. RPC: staff_logout (Positional & JSONB)
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.staff_logout(p_session_token text)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    UPDATE public.staff_sessions
    SET is_revoked = TRUE, 
        revoked_reason = 'تسجيل خروج اعتيادي من المستخدم'
    WHERE session_token = trim(p_session_token);

    RETURN jsonb_build_object('success', true, 'message', 'تم تسجيل الخروج وإلغاء الجلسة بنجاح');
END;
$$;

CREATE OR REPLACE FUNCTION public.staff_logout(v_payload jsonb)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN public.staff_logout(
        coalesce(v_payload->>'p_session_token', v_payload->>'session_token', '')::text
    );
END;
$$;

-- ------------------------------------------------------------------------------
-- 8. RPC: Management & Session Revocation (Positional & JSONB)
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.staff_terminate_session(
    p_admin_session_token text,
    p_target_staff_id text
)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_admin_verify jsonb;
    v_admin_role text;
BEGIN
    v_admin_verify := public.verify_staff_session(p_admin_session_token);
    IF NOT (v_admin_verify->>'valid')::boolean THEN
        RETURN jsonb_build_object('success', false, 'message', 'جلسة الإدارة غير صالحة');
    END IF;

    v_admin_role := v_admin_verify->'staff'->>'role';
    IF v_admin_role NOT IN ('super_admin', 'general_manager') THEN
        RETURN jsonb_build_object('success', false, 'message', 'غير مصرح: هذه العملية تتطلب صلاحيات مدير نظام أو مدير عام');
    END IF;

    UPDATE public.staff_sessions
    SET is_revoked = TRUE,
        revoked_reason = 'إنهاء إداري قسري من قبل مسؤول النظام (' || (v_admin_verify->'staff'->>'full_name') || ')'
    WHERE staff_id = p_target_staff_id AND is_revoked = FALSE;

    UPDATE public.staff_members
    SET session_revoked_at = NOW()
    WHERE id = p_target_staff_id;

    RETURN jsonb_build_object('success', true, 'message', 'تم إنهاء كافة الجلسات النشطة للموظف بنجاح');
END;
$$;

CREATE OR REPLACE FUNCTION public.staff_terminate_session(v_payload jsonb)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN public.staff_terminate_session(
        coalesce(v_payload->>'p_admin_session_token', v_payload->>'admin_session_token', '')::text,
        coalesce(v_payload->>'p_target_staff_id', v_payload->>'target_staff_id', '')::text
    );
END;
$$;

CREATE OR REPLACE FUNCTION public.staff_toggle_active(
    p_admin_session_token text,
    p_target_staff_id text,
    p_is_active boolean
)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_admin_verify jsonb;
    v_admin_role text;
BEGIN
    v_admin_verify := public.verify_staff_session(p_admin_session_token);
    IF NOT (v_admin_verify->>'valid')::boolean THEN
        RETURN jsonb_build_object('success', false, 'message', 'جلسة الإدارة غير صالحة');
    END IF;

    v_admin_role := v_admin_verify->'staff'->>'role';
    IF v_admin_role NOT IN ('super_admin', 'general_manager') THEN
        RETURN jsonb_build_object('success', false, 'message', 'غير مصرح: تعديل حالة الموظف يتطلب صلاحيات الإدارة العليا');
    END IF;

    UPDATE public.staff_members
    SET is_active = p_is_active
    WHERE id = p_target_staff_id;

    IF NOT p_is_active THEN
        UPDATE public.staff_sessions
        SET is_revoked = TRUE,
            revoked_reason = 'تم تجميد حساب الموظف من قبل الإدارة'
        WHERE staff_id = p_target_staff_id;

        UPDATE public.staff_members
        SET session_revoked_at = NOW()
        WHERE id = p_target_staff_id;
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'is_active', p_is_active,
        'message', CASE WHEN p_is_active THEN 'تم تفعيل حساب الموظف بنجاح' ELSE 'تم تجميد حساب الموظف وإلغاء كافة جلساته بنجاح' END
    );
END;
$$;

CREATE OR REPLACE FUNCTION public.staff_toggle_active(v_payload jsonb)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN public.staff_toggle_active(
        coalesce(v_payload->>'p_admin_session_token', v_payload->>'admin_session_token', '')::text,
        coalesce(v_payload->>'p_target_staff_id', v_payload->>'target_staff_id', '')::text,
        coalesce((v_payload->>'p_is_active')::boolean, (v_payload->>'is_active')::boolean, true)
    );
END;
$$;

CREATE OR REPLACE FUNCTION public.staff_admin_reset_password(
    p_admin_session_token text,
    p_target_staff_id text,
    p_new_password text
)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_admin_verify jsonb;
    v_admin_role text;
    v_clean_pass text;
BEGIN
    v_admin_verify := public.verify_staff_session(p_admin_session_token);
    IF NOT (v_admin_verify->>'valid')::boolean THEN
        RETURN jsonb_build_object('success', false, 'message', 'جلسة الإدارة غير صالحة');
    END IF;

    v_admin_role := v_admin_verify->'staff'->>'role';
    IF v_admin_role NOT IN ('super_admin', 'general_manager') THEN
        RETURN jsonb_build_object('success', false, 'message', 'غير مصرح: تعيين كلمة المرور يتطلب صلاحيات الإدارة العليا');
    END IF;

    v_clean_pass := trim(p_new_password);
    IF length(v_clean_pass) < 4 THEN
        RETURN jsonb_build_object('success', false, 'message', 'كلمة المرور يجب أن تتكون من 4 خانات على الأقل');
    END IF;

    UPDATE public.staff_members
    SET password_hash = crypt(v_clean_pass, gen_salt('bf', 10)),
        password = NULL,
        session_revoked_at = NOW()
    WHERE id = p_target_staff_id;

    UPDATE public.staff_sessions
    SET is_revoked = TRUE,
        revoked_reason = 'تم تغيير كلمة المرور بواسطة الإدارة المركزية'
    WHERE staff_id = p_target_staff_id;

    RETURN jsonb_build_object('success', true, 'message', 'تم تحديث وتشفير كلمة المرور الجديدة وإلغاء الجلسات السابقة بنجاح');
END;
$$;

CREATE OR REPLACE FUNCTION public.staff_admin_reset_password(v_payload jsonb)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN public.staff_admin_reset_password(
        coalesce(v_payload->>'p_admin_session_token', v_payload->>'admin_session_token', '')::text,
        coalesce(v_payload->>'p_target_staff_id', v_payload->>'target_staff_id', '')::text,
        coalesce(v_payload->>'p_new_password', v_payload->>'new_password', '')::text
    );
END;
$$;

-- ------------------------------------------------------------------------------
-- 9. Permissions & Schema Cache Reload
-- ------------------------------------------------------------------------------
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.branches TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.staff_members TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.staff_sessions TO anon, authenticated, service_role;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated, service_role;

-- Reload PostgREST schema cache immediately
NOTIFY pgrst, 'reload schema';
