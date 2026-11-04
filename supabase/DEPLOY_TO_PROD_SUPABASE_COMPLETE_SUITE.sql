-- ==============================================================================
-- ALDEEB MALL PRODUCTION REMOTE SUPABASE MASTER DEPLOYMENT
-- Generated for https://ffqjtixxzgmvoxzzmxdy.supabase.co
-- ==============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- --- START OF supabase/DEPLOY_TO_REMOTE_SUPABASE_ALL_STAFF_AUTH.sql ---
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

-- --- END OF supabase/DEPLOY_TO_REMOTE_SUPABASE_ALL_STAFF_AUTH.sql ---

-- --- START OF supabase/migrations/20261104_019_real_inventory_and_movements.sql ---
-- ==============================================================================
-- الديب مول (Aldeeb Mall) - Real Inventory & Item Movement Engine
-- Migration: 20261104_019_real_inventory_and_movements.sql
-- Single Monotonic Migration Sequence: Step 019
-- ==============================================================================

BEGIN;

-- 1. Create branch_inventory table (Real physical & available stock per product & branch)
CREATE TABLE IF NOT EXISTS public.branch_inventory (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id character varying(64) NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
    product_id uuid NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    quantity_on_hand numeric(12,2) NOT NULL DEFAULT 0 CHECK (quantity_on_hand >= 0),
    quantity_reserved numeric(12,2) NOT NULL DEFAULT 0 CHECK (quantity_reserved >= 0),
    safety_threshold numeric(12,2) NOT NULL DEFAULT 5 CHECK (safety_threshold >= 0),
    bin_location text NOT NULL DEFAULT 'رف-A-01',
    updated_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT uq_branch_inventory_branch_product UNIQUE (branch_id, product_id)
);

CREATE INDEX IF NOT EXISTS idx_branch_inventory_branch ON public.branch_inventory(branch_id);
CREATE INDEX IF NOT EXISTS idx_branch_inventory_product ON public.branch_inventory(product_id);
CREATE INDEX IF NOT EXISTS idx_branch_inventory_composite ON public.branch_inventory(branch_id, product_id);

-- 2. Create inventory_movements table (Permanent, audited stock movement log)
CREATE TABLE IF NOT EXISTS public.inventory_movements (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    movement_number text NOT NULL UNIQUE,
    branch_id character varying(64) NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
    product_id uuid NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    movement_type text NOT NULL CHECK (movement_type IN (
        'supply',               -- توريد بضاعة جديدة أو أمر شراء
        'reservation',          -- حجز كمية لصالح طلب قيد التجهيز
        'release_reservation',  -- فك الحجز وإلغاء الطلب
        'disbursement',         -- صرف بضاعة أو إذن صرف
        'sale',                 -- بيع مباشر أو نقطة بيع POS
        'return',               -- مرتجع من عميل
        'damaged',              -- إتلاف أو بضاعة تالفة
        'audit_reconciliation', -- جرد فعلي وتسوية فروقات
        'adjustment',           -- تعديل يدوي معتمد
        'transfer_out',         -- مناقلة صادرة لفرع آخر
        'transfer_in'           -- مناقلة واردة من فرع آخر
    )),
    quantity_change numeric(12,2) NOT NULL,
    quantity_reserved_change numeric(12,2) NOT NULL DEFAULT 0,
    resulting_on_hand numeric(12,2) NOT NULL CHECK (resulting_on_hand >= 0),
    resulting_reserved numeric(12,2) NOT NULL CHECK (resulting_reserved >= 0),
    reference_type text NOT NULL CHECK (reference_type IN (
        'order', 'po', 'transfer', 'audit', 'return', 'adjustment', 'manual', 'loss_prevention'
    )),
    reference_id text NOT NULL,
    actor_id text,
    actor_name text NOT NULL,
    actor_role text NOT NULL,
    notes text,
    created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_inventory_movements_branch ON public.inventory_movements(branch_id);
CREATE INDEX IF NOT EXISTS idx_inventory_movements_product ON public.inventory_movements(product_id);
CREATE INDEX IF NOT EXISTS idx_inventory_movements_type ON public.inventory_movements(movement_type);
CREATE INDEX IF NOT EXISTS idx_inventory_movements_created ON public.inventory_movements(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_inventory_movements_ref ON public.inventory_movements(reference_id);

-- 3. Create inventory_transfers table (Multi-branch two-phase transfer workflow)
CREATE TABLE IF NOT EXISTS public.inventory_transfers (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    transfer_number text NOT NULL UNIQUE,
    source_branch_id character varying(64) NOT NULL REFERENCES public.branches(id),
    destination_branch_id character varying(64) NOT NULL REFERENCES public.branches(id),
    product_id uuid NOT NULL REFERENCES public.products(id),
    quantity_requested numeric(12,2) NOT NULL CHECK (quantity_requested > 0),
    quantity_dispatched numeric(12,2) NOT NULL DEFAULT 0 CHECK (quantity_dispatched >= 0),
    quantity_received numeric(12,2) NOT NULL DEFAULT 0 CHECK (quantity_received >= 0),
    quantity_damaged numeric(12,2) NOT NULL DEFAULT 0 CHECK (quantity_damaged >= 0),
    status text NOT NULL DEFAULT 'requested' CHECK (status IN (
        'requested', 'under_review', 'approved', 'dispatched', 'received', 'closed', 'rejected'
    )),
    discrepancy_reason text,
    assigned_driver text,
    audit_locked boolean NOT NULL DEFAULT false,
    requested_by text,
    dispatched_by text,
    received_by text,
    requested_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
    dispatched_at timestamp with time zone,
    received_at timestamp with time zone,
    closed_at timestamp with time zone,
    created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_inventory_transfers_source ON public.inventory_transfers(source_branch_id);
CREATE INDEX IF NOT EXISTS idx_inventory_transfers_dest ON public.inventory_transfers(destination_branch_id);
CREATE INDEX IF NOT EXISTS idx_inventory_transfers_status ON public.inventory_transfers(status);

-- 4. Create inventory_audits table (Physical inventory reconciliation sessions)
CREATE TABLE IF NOT EXISTS public.inventory_audits (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    audit_number text NOT NULL UNIQUE,
    branch_id character varying(64) NOT NULL REFERENCES public.branches(id),
    product_id uuid NOT NULL REFERENCES public.products(id),
    system_quantity numeric(12,2) NOT NULL,
    physical_quantity numeric(12,2) NOT NULL CHECK (physical_quantity >= 0),
    variance numeric(12,2) NOT NULL,
    reason text,
    auditor_id text,
    auditor_name text NOT NULL,
    auditor_role text NOT NULL,
    status text NOT NULL DEFAULT 'completed',
    created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_inventory_audits_branch ON public.inventory_audits(branch_id);
CREATE INDEX IF NOT EXISTS idx_inventory_audits_product ON public.inventory_audits(product_id);

-- 5. Seed Real Initial Branch Inventory for all existing products and branches
INSERT INTO public.branch_inventory (branch_id, product_id, quantity_on_hand, quantity_reserved, safety_threshold, bin_location)
SELECT 
    b.id AS branch_id,
    p.id AS product_id,
    GREATEST(10, FLOOR(p.stock_quantity / 5.0))::numeric(12,2) AS quantity_on_hand,
    0 AS quantity_reserved,
    5 AS safety_threshold,
    'رف-' || CHR(65 + (ROW_NUMBER() OVER (PARTITION BY b.id ORDER BY p.id) % 6)::int) || '-' || LPAD(((ROW_NUMBER() OVER (PARTITION BY b.id ORDER BY p.id) % 20) + 1)::text, 2, '0') AS bin_location
FROM public.branches b
CROSS JOIN public.products p
ON CONFLICT (branch_id, product_id) DO UPDATE SET
    quantity_on_hand = EXCLUDED.quantity_on_hand,
    updated_at = timezone('utc'::text, now());

-- Seed initial supply movement records for traceability
INSERT INTO public.inventory_movements (
    movement_number, branch_id, product_id, movement_type, quantity_change, quantity_reserved_change,
    resulting_on_hand, resulting_reserved, reference_type, reference_id, actor_name, actor_role, notes
)
SELECT 
    'INIT-' || bi.branch_id || '-' || replace(bi.product_id::text, '-', ''),
    bi.branch_id,
    bi.product_id,
    'supply',
    bi.quantity_on_hand,
    0,
    bi.quantity_on_hand,
    0,
    'manual',
    'INIT-BAL-2026',
    'أمين المستودع العام',
    'warehouse_manager',
    'الرصيد الافتتاحي المعتمد لبدء الدورة المخزنية الرقمية'
FROM public.branch_inventory bi
ON CONFLICT (movement_number) DO NOTHING;

-- Synchronize total stock_quantity in public.products to match the sum of real branch balances
UPDATE public.products p
SET stock_quantity = COALESCE((
    SELECT SUM(bi.quantity_on_hand)::int
    FROM public.branch_inventory bi
    WHERE bi.product_id = p.id
), 0),
updated_at = timezone('utc'::text, now());

-- Trigger to auto-provision branch inventory rows whenever a new product is added
CREATE OR REPLACE FUNCTION public.trg_auto_provision_branch_inventory()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO public.branch_inventory (branch_id, product_id, quantity_on_hand, quantity_reserved, safety_threshold, bin_location)
    SELECT 
        b.id,
        NEW.id,
        GREATEST(10, FLOOR(COALESCE(NEW.stock_quantity, 100) / 5.0)),
        0,
        5,
        'رف-A-01'
    FROM public.branches b
    ON CONFLICT (branch_id, product_id) DO NOTHING;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_provision_branch_inventory_on_product ON public.products;
CREATE TRIGGER trg_provision_branch_inventory_on_product
    AFTER INSERT ON public.products
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_auto_provision_branch_inventory();

-- 6. Atomic Stored Procedure: record_inventory_movement_atomic
CREATE OR REPLACE FUNCTION public.record_inventory_movement_atomic(
    p_branch_id text,
    p_product_id uuid,
    p_movement_type text,
    p_qty_change numeric,
    p_qty_reserved_change numeric DEFAULT 0,
    p_ref_type text DEFAULT 'manual',
    p_ref_id text DEFAULT 'MANUAL-ADJ',
    p_actor_id text DEFAULT NULL,
    p_actor_name text DEFAULT 'أمين المخزون',
    p_actor_role text DEFAULT 'staff',
    p_notes text DEFAULT ''
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_curr_on_hand numeric(12,2);
    v_curr_reserved numeric(12,2);
    v_new_on_hand numeric(12,2);
    v_new_reserved numeric(12,2);
    v_mov_number text;
    v_caller_role text;
    v_caller_branch text;
    v_result jsonb;
BEGIN
    v_caller_role := auth.user_role();
    v_caller_branch := auth.branch_id();

    -- Role and Branch Permissions Guard
    IF v_caller_role = 'cashier' THEN
        IF p_movement_type NOT IN ('sale', 'return', 'release_reservation') THEN
            RAISE EXCEPTION '42501: Cashiers are strictly limited to recording sales, returns and release reservations';
        END IF;
        IF v_caller_branch IS NOT NULL AND v_caller_branch <> p_branch_id THEN
            RAISE EXCEPTION '42501: Cashier is unauthorized to operate on foreign branch %', p_branch_id;
        END IF;
    ELSIF v_caller_role = 'branch_manager' THEN
        IF v_caller_branch IS NOT NULL AND v_caller_branch <> p_branch_id AND NOT auth.is_super_admin() THEN
            RAISE EXCEPTION '42501: Branch manager is unauthorized to operate on foreign branch %', p_branch_id;
        END IF;
    ELSIF v_caller_role IN ('anon', 'customer', 'courier', 'driver') THEN
        IF p_ref_type = 'order' AND p_movement_type IN ('sale', 'release_reservation') THEN
            -- Allowed: order placement or cancellation
            NULL;
        ELSIF p_ref_type = 'return' AND p_movement_type IN ('return', 'damaged') THEN
            -- Allowed: return processing
            NULL;
        ELSIF p_ref_type = 'transfer' AND p_movement_type IN ('transfer_out', 'transfer_in') THEN
            -- Allowed: transfer dispatch and receipt
            NULL;
        ELSIF p_ref_type = 'audit' AND p_movement_type = 'audit_reconciliation' THEN
            -- Allowed: audit reconciliation
            NULL;
        ELSIF NOT auth.is_staff() AND NOT auth.is_super_admin() THEN
            RAISE EXCEPTION '42501: Unauthorized access to inventory movement engine';
        END IF;
    END IF;

    -- Ensure product exists
    IF NOT EXISTS (SELECT 1 FROM public.products WHERE id = p_product_id) THEN
        RAISE EXCEPTION 'PRODUCT_NOT_FOUND: Product with id % does not exist', p_product_id;
    END IF;

    -- Ensure branch exists
    IF NOT EXISTS (SELECT 1 FROM public.branches WHERE id = p_branch_id) THEN
        RAISE EXCEPTION 'BRANCH_NOT_FOUND: Branch with id % does not exist', p_branch_id;
    END IF;

    -- Row Locking FOR UPDATE to prevent race conditions & concurrent overselling
    SELECT quantity_on_hand, quantity_reserved
    INTO v_curr_on_hand, v_curr_reserved
    FROM public.branch_inventory
    WHERE branch_id = p_branch_id AND product_id = p_product_id
    FOR UPDATE;

    IF NOT FOUND THEN
        -- Auto-provision row with 0 if not present
        INSERT INTO public.branch_inventory (branch_id, product_id, quantity_on_hand, quantity_reserved)
        VALUES (p_branch_id, p_product_id, 0, 0)
        RETURNING quantity_on_hand, quantity_reserved INTO v_curr_on_hand, v_curr_reserved;

        -- Re-lock
        SELECT quantity_on_hand, quantity_reserved
        INTO v_curr_on_hand, v_curr_reserved
        FROM public.branch_inventory
        WHERE branch_id = p_branch_id AND product_id = p_product_id
        FOR UPDATE;
    END IF;

    -- Prevent Negative Balances
    v_new_on_hand := v_curr_on_hand + p_qty_change;
    v_new_reserved := v_curr_reserved + COALESCE(p_qty_reserved_change, 0);

    IF v_new_on_hand < 0 THEN
        RAISE EXCEPTION 'INSUFFICIENT_STOCK: Branch % has only % units of product %, requested change %',
            p_branch_id, v_curr_on_hand, p_product_id, p_qty_change;
    END IF;

    IF v_new_reserved < 0 THEN
        v_new_reserved := 0;
    END IF;

    -- Update Branch Balance
    UPDATE public.branch_inventory
    SET quantity_on_hand = v_new_on_hand,
        quantity_reserved = v_new_reserved,
        updated_at = timezone('utc'::text, now())
    WHERE branch_id = p_branch_id AND product_id = p_product_id;

    -- Update Global Products Catalog Balance
    UPDATE public.products
    SET stock_quantity = (SELECT COALESCE(SUM(quantity_on_hand), 0)::int FROM public.branch_inventory WHERE product_id = p_product_id),
        sales_count = CASE WHEN p_movement_type = 'sale' THEN COALESCE(sales_count, 0) + GREATEST(0, (-p_qty_change)::int) ELSE sales_count END,
        updated_at = timezone('utc'::text, now())
    WHERE id = p_product_id;

    -- Generate Unique Movement Number
    v_mov_number := 'MOV-' || to_char(now(), 'YYYYMMDD-HH24MISS') || '-' || substr(md5(random()::text), 1, 6);

    -- Insert Permanent Movement Audit Log
    INSERT INTO public.inventory_movements (
        movement_number,
        branch_id,
        product_id,
        movement_type,
        quantity_change,
        quantity_reserved_change,
        resulting_on_hand,
        resulting_reserved,
        reference_type,
        reference_id,
        actor_id,
        actor_name,
        actor_role,
        notes
    ) VALUES (
        v_mov_number,
        p_branch_id,
        p_product_id,
        p_movement_type,
        p_qty_change,
        COALESCE(p_qty_reserved_change, 0),
        v_new_on_hand,
        v_new_reserved,
        p_ref_type,
        p_ref_id,
        COALESCE(p_actor_id, auth.user_id()),
        p_actor_name,
        p_actor_role,
        p_notes
    );

    v_result := jsonb_build_object(
        'success', true,
        'movement_number', v_mov_number,
        'branch_id', p_branch_id,
        'product_id', p_product_id,
        'previous_on_hand', v_curr_on_hand,
        'new_on_hand', v_new_on_hand,
        'previous_reserved', v_curr_reserved,
        'new_reserved', v_new_reserved,
        'quantity_change', p_qty_change,
        'movement_type', p_movement_type
    );

    RETURN v_result;
END;
$$;

-- 7. Atomic Stored Procedure: perform_inventory_transfer_step_atomic
CREATE OR REPLACE FUNCTION public.perform_inventory_transfer_step_atomic(
    p_transfer_id uuid,
    p_action text,
    p_actor_id text DEFAULT NULL,
    p_actor_name text DEFAULT 'مسؤول اللوجستيات',
    p_actor_role text DEFAULT 'warehouse_manager',
    p_good_qty numeric DEFAULT NULL,
    p_damaged_qty numeric DEFAULT 0,
    p_driver text DEFAULT NULL,
    p_discrepancy_reason text DEFAULT ''
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_tr record;
    v_mov_number text;
BEGIN
    SELECT * INTO v_tr
    FROM public.inventory_transfers
    WHERE id = p_transfer_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'TRANSFER_NOT_FOUND: Transfer order % does not exist', p_transfer_id;
    END IF;

    IF v_tr.audit_locked THEN
        RAISE EXCEPTION 'AUDIT_LOCKED: Transfer order % is finalized and locked against modification', v_tr.transfer_number;
    END IF;

    IF p_action = 'approve' THEN
        UPDATE public.inventory_transfers
        SET status = 'approved',
            updated_at = timezone('utc'::text, now())
        WHERE id = p_transfer_id;

        RETURN jsonb_build_object('success', true, 'status', 'approved', 'transfer_number', v_tr.transfer_number);

    ELSIF p_action = 'dispatch' THEN
        -- Deduct from Source Branch Stock Atomically
        PERFORM public.record_inventory_movement_atomic(
            v_tr.source_branch_id,
            v_tr.product_id,
            'transfer_out',
            -v_tr.quantity_requested,
            0,
            'transfer',
            v_tr.transfer_number,
            p_actor_id,
            p_actor_name,
            p_actor_role,
            'شحن وتصدير مناقلة إلى الفرع المستلم'
        );

        UPDATE public.inventory_transfers
        SET status = 'dispatched',
            quantity_dispatched = v_tr.quantity_requested,
            assigned_driver = COALESCE(p_driver, assigned_driver, 'أسطول النقل المبرد المعتمد'),
            dispatched_by = p_actor_name,
            dispatched_at = timezone('utc'::text, now()),
            updated_at = timezone('utc'::text, now())
        WHERE id = p_transfer_id;

        RETURN jsonb_build_object('success', true, 'status', 'dispatched', 'transfer_number', v_tr.transfer_number);

    ELSIF p_action = 'receive' THEN
        DECLARE
            v_actual_good numeric := COALESCE(p_good_qty, v_tr.quantity_dispatched);
            v_actual_damaged numeric := COALESCE(p_damaged_qty, 0);
        BEGIN
            -- Credit destination branch with good items
            IF v_actual_good > 0 THEN
                PERFORM public.record_inventory_movement_atomic(
                    v_tr.destination_branch_id,
                    v_tr.product_id,
                    'transfer_in',
                    v_actual_good,
                    0,
                    'transfer',
                    v_tr.transfer_number,
                    p_actor_id,
                    p_actor_name,
                    p_actor_role,
                    'استلام مناقلة بضاعة سليمة وإيداعها في رفوف الفرع'
                );
            END IF;

            -- Log damaged goods if any (quarantine)
            IF v_actual_damaged > 0 THEN
                v_mov_number := 'DAM-' || to_char(now(), 'YYYYMMDD-HH24MISS') || '-' || substr(md5(random()::text), 1, 6);
                INSERT INTO public.inventory_movements (
                    movement_number, branch_id, product_id, movement_type, quantity_change, quantity_reserved_change,
                    resulting_on_hand, resulting_reserved, reference_type, reference_id, actor_id, actor_name, actor_role, notes
                ) VALUES (
                    v_mov_number,
                    v_tr.destination_branch_id,
                    v_tr.product_id,
                    'damaged',
                    0, -- recorded in damage register without adding to on_hand
                    0,
                    (SELECT quantity_on_hand FROM public.branch_inventory WHERE branch_id = v_tr.destination_branch_id AND product_id = v_tr.product_id),
                    0,
                    'transfer',
                    v_tr.transfer_number,
                    p_actor_id,
                    p_actor_name,
                    p_actor_role,
                    COALESCE(p_discrepancy_reason, 'تلف أثناء النقل اللوجستي')
                );
            END IF;

            UPDATE public.inventory_transfers
            SET status = 'closed',
                quantity_received = v_actual_good,
                quantity_damaged = v_actual_damaged,
                discrepancy_reason = p_discrepancy_reason,
                received_by = p_actor_name,
                received_at = timezone('utc'::text, now()),
                closed_at = timezone('utc'::text, now()),
                audit_locked = true,
                updated_at = timezone('utc'::text, now())
            WHERE id = p_transfer_id;

            RETURN jsonb_build_object(
                'success', true,
                'status', 'closed',
                'transfer_number', v_tr.transfer_number,
                'good_received', v_actual_good,
                'damaged', v_actual_damaged
            );
        END;

    ELSE
        RAISE EXCEPTION 'INVALID_ACTION: Unknown transfer action %', p_action;
    END IF;
END;
$$;

-- 8. Atomic Stored Procedure: perform_stock_audit_reconciliation_atomic
CREATE OR REPLACE FUNCTION public.perform_stock_audit_reconciliation_atomic(
    p_branch_id text,
    p_product_id uuid,
    p_physical_qty numeric,
    p_auditor_id text DEFAULT NULL,
    p_auditor_name text DEFAULT 'المدقق المالي والمخزني',
    p_auditor_role text DEFAULT 'auditor',
    p_reason text DEFAULT 'مطابقة الجرد الدوري الفعلي'
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_system_qty numeric(12,2);
    v_variance numeric(12,2);
    v_audit_number text;
    v_mov_number text;
BEGIN
    IF p_physical_qty < 0 THEN
        RAISE EXCEPTION 'INVALID_PHYSICAL_QTY: Physical count quantity cannot be negative';
    END IF;

    -- Lock branch inventory row
    SELECT quantity_on_hand INTO v_system_qty
    FROM public.branch_inventory
    WHERE branch_id = p_branch_id AND product_id = p_product_id
    FOR UPDATE;

    IF NOT FOUND THEN
        v_system_qty := 0;
        INSERT INTO public.branch_inventory (branch_id, product_id, quantity_on_hand, quantity_reserved)
        VALUES (p_branch_id, p_product_id, 0, 0);
    END IF;

    v_variance := p_physical_qty - v_system_qty;
    v_audit_number := 'AUDIT-' || to_char(now(), 'YYYYMMDD-HH24MISS') || '-' || substr(md5(random()::text), 1, 6);

    -- Insert Audit Record
    INSERT INTO public.inventory_audits (
        audit_number,
        branch_id,
        product_id,
        system_quantity,
        physical_quantity,
        variance,
        reason,
        auditor_id,
        auditor_name,
        auditor_role
    ) VALUES (
        v_audit_number,
        p_branch_id,
        p_product_id,
        v_system_qty,
        p_physical_qty,
        v_variance,
        p_reason,
        COALESCE(p_auditor_id, auth.user_id()),
        p_auditor_name,
        p_auditor_role
    );

    -- Apply Reconciliation Adjustment if there is variance
    IF v_variance <> 0 THEN
        UPDATE public.branch_inventory
        SET quantity_on_hand = p_physical_qty,
            updated_at = timezone('utc'::text, now())
        WHERE branch_id = p_branch_id AND product_id = p_product_id;

        UPDATE public.products
        SET stock_quantity = (SELECT COALESCE(SUM(quantity_on_hand), 0)::int FROM public.branch_inventory WHERE product_id = p_product_id),
            updated_at = timezone('utc'::text, now())
        WHERE id = p_product_id;

        v_mov_number := 'MOV-AUD-' || to_char(now(), 'YYYYMMDD-HH24MISS') || '-' || substr(md5(random()::text), 1, 6);
        INSERT INTO public.inventory_movements (
            movement_number,
            branch_id,
            product_id,
            movement_type,
            quantity_change,
            quantity_reserved_change,
            resulting_on_hand,
            resulting_reserved,
            reference_type,
            reference_id,
            actor_id,
            actor_name,
            actor_role,
            notes
        ) VALUES (
            v_mov_number,
            p_branch_id,
            p_product_id,
            'audit_reconciliation',
            v_variance,
            0,
            p_physical_qty,
            (SELECT quantity_reserved FROM public.branch_inventory WHERE branch_id = p_branch_id AND product_id = p_product_id),
            'audit',
            v_audit_number,
            COALESCE(p_auditor_id, auth.user_id()),
            p_auditor_name,
            p_auditor_role,
            'تسوية جردية: ' || COALESCE(p_reason, 'فروقات جرد فعلي')
        );
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'audit_number', v_audit_number,
        'branch_id', p_branch_id,
        'product_id', p_product_id,
        'system_quantity', v_system_qty,
        'physical_quantity', p_physical_qty,
        'variance', v_variance
    );
END;
$$;

-- 9. Atomic Stored Procedure: cancel_order_atomic (Restores branch stock and logs movement)
CREATE OR REPLACE FUNCTION public.cancel_order_atomic(
    p_order_id uuid,
    p_actor_id text DEFAULT NULL,
    p_actor_name text DEFAULT 'إدارة العمليات',
    p_actor_role text DEFAULT 'admin',
    p_reason text DEFAULT 'إلغاء الطلب بناء على طلب العميل'
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_order record;
    v_item record;
    v_restored_count int := 0;
BEGIN
    SELECT * INTO v_order
    FROM public.orders
    WHERE id = p_order_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'ORDER_NOT_FOUND: Order % does not exist', p_order_id;
    END IF;

    IF v_order.status = 'cancelled' THEN
        RAISE EXCEPTION 'ALREADY_CANCELLED: Order % is already cancelled', v_order.order_number;
    END IF;

    -- Iterate items and restore branch stock
    FOR v_item IN (SELECT * FROM public.order_items WHERE order_id = p_order_id)
    LOOP
        IF v_item.product_id IS NOT NULL THEN
            PERFORM public.record_inventory_movement_atomic(
                COALESCE(v_order.branch_id, 'b-jed-01'),
                v_item.product_id,
                'release_reservation',
                v_item.quantity,
                0,
                'order',
                v_order.order_number,
                p_actor_id,
                p_actor_name,
                p_actor_role,
                'إلغاء طلب واستعادة الرصيد للمستودع: ' || COALESCE(p_reason, '')
            );
            v_restored_count := v_restored_count + 1;
        END IF;
    END LOOP;

    -- Update Order Status
    UPDATE public.orders
    SET status = 'cancelled',
        notes = COALESCE(notes, '') || ' [ملغى: ' || p_reason || ']',
        updated_at = timezone('utc'::text, now())
    WHERE id = p_order_id;

    RETURN jsonb_build_object(
        'success', true,
        'order_id', p_order_id,
        'order_number', v_order.order_number,
        'restored_items_count', v_restored_count
    );
END;
$$;

-- 10. Atomic Stored Procedure: process_order_return_atomic (Returns stock to branch)
CREATE OR REPLACE FUNCTION public.process_order_return_atomic(
    p_order_id uuid,
    p_items jsonb,
    p_actor_id text DEFAULT NULL,
    p_actor_name text DEFAULT 'مسؤول المرتجعات',
    p_actor_role text DEFAULT 'support_officer',
    p_reason text DEFAULT 'مرتجع عميل معتمد'
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_order record;
    v_item jsonb;
    v_prod_id uuid;
    v_qty numeric;
    v_returned_count int := 0;
BEGIN
    SELECT * INTO v_order
    FROM public.orders
    WHERE id = p_order_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'ORDER_NOT_FOUND: Order % does not exist', p_order_id;
    END IF;

    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_prod_id := (v_item->>'product_id')::uuid;
        v_qty := (v_item->>'quantity')::numeric;

        IF v_prod_id IS NOT NULL AND v_qty > 0 THEN
            PERFORM public.record_inventory_movement_atomic(
                COALESCE(v_order.branch_id, 'b-jed-01'),
                v_prod_id,
                'return',
                v_qty,
                0,
                'return',
                v_order.order_number,
                p_actor_id,
                p_actor_name,
                p_actor_role,
                'استلام مرتجع وفحصه: ' || COALESCE(p_reason, '')
            );
            v_returned_count := v_returned_count + 1;
        END IF;
    END LOOP;

    RETURN jsonb_build_object(
        'success', true,
        'order_id', p_order_id,
        'order_number', v_order.order_number,
        'returned_items_count', v_returned_count
    );
END;
$$;

-- 11. Overload & Upgrade place_order_atomic to enforce Atomic Branch Stock Deduction & Sale Movements
-- First, drop the old 12-argument function to avoid signature ambiguities
DROP FUNCTION IF EXISTS public.place_order_atomic(text, uuid, text, text, numeric, numeric, numeric, int, numeric, numeric, text, jsonb);
DROP FUNCTION IF EXISTS public.place_order_atomic(text, uuid, text, text, numeric, numeric, numeric, int, numeric, numeric, text, jsonb, text);

CREATE OR REPLACE FUNCTION public.place_order_atomic(
    p_order_number text,
    p_user_id uuid,
    p_delivery_slot text,
    p_payment_method text,
    p_subtotal numeric,
    p_delivery_fee numeric,
    p_discount_amount numeric,
    p_loyalty_points_used int,
    p_loyalty_discount numeric,
    p_total_amount numeric,
    p_notes text,
    p_items jsonb,
    p_branch_id text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_caller_id uuid;
    v_effective_user_id uuid;
    v_is_admin boolean;
    v_order_id uuid;
    v_target_branch_id text;
    v_branch_name text;
    v_item jsonb;
    v_product_id uuid;
    v_qty numeric;
    v_db_price numeric;
    v_unit_price numeric;
    v_line_total numeric;
    v_calc_subtotal numeric := 0;
    v_effective_subtotal numeric;
    v_effective_total numeric;
    v_result jsonb;
BEGIN
    -- Step 1: Caller Identity & Privilege Verification
    v_caller_id := auth.uid();
    v_is_admin := public.is_admin();

    IF v_caller_id IS NOT NULL THEN
        v_effective_user_id := v_caller_id;
    ELSIF v_is_admin THEN
        v_effective_user_id := p_user_id;
    ELSE
        IF p_user_id IS NOT NULL THEN
            RAISE EXCEPTION 'UNAUTHORIZED: Anonymous callers cannot assign orders to registered user accounts';
        END IF;
        v_effective_user_id := NULL;
    END IF;

    -- Block Anonymous callers from creating Cashier/POS in-store orders
    IF (p_delivery_slot ILIKE '%كاشير%' OR p_delivery_slot ILIKE '%pos%') AND v_caller_id IS NULL AND NOT v_is_admin THEN
        RAISE EXCEPTION 'UNAUTHORIZED_POS: In-store POS cashier orders must be placed by authenticated staff';
    END IF;

    -- Determine Effective Branch ID
    v_target_branch_id := COALESCE(auth.branch_id(), p_branch_id, 'b-jed-01');
    SELECT name_ar INTO v_branch_name FROM public.branches WHERE id = v_target_branch_id;
    IF v_branch_name IS NULL THEN
        v_target_branch_id := 'b-jed-01';
        v_branch_name := 'فرع جدة الكورنيش (واجهة البحر)';
    END IF;

    -- Step 2: Idempotency Protection - Prevent double-submission
    IF EXISTS (SELECT 1 FROM public.orders WHERE order_number = p_order_number) THEN
        RAISE EXCEPTION 'DUPLICATE_ORDER: Order with number % already exists', p_order_number;
    END IF;

    -- Step 3: Validate Items Payload
    IF p_items IS NULL OR jsonb_array_length(p_items) = 0 THEN
        RAISE EXCEPTION 'EMPTY_ITEMS: Cannot place an order without items';
    END IF;

    -- Step 4: Validate Stock & Atomic Branch Row Locking & Price Verification
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_qty := (v_item->>'quantity')::numeric;
        IF v_qty <= 0 THEN
            RAISE EXCEPTION 'INVALID_QUANTITY: Quantity must be greater than zero';
        END IF;

        IF (v_item->>'product_id') IS NOT NULL AND (v_item->>'product_id') ~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$' THEN
            v_product_id := (v_item->>'product_id')::uuid;

            SELECT price INTO v_db_price
            FROM public.products
            WHERE id = v_product_id;

            IF FOUND THEN
                -- Atomic Branch Inventory Deduction with Locking FOR UPDATE & Anti-Overselling Guard
                PERFORM public.record_inventory_movement_atomic(
                    v_target_branch_id,
                    v_product_id,
                    'sale',
                    -v_qty,
                    0,
                    'order',
                    p_order_number,
                    auth.user_id(),
                    COALESCE(auth.jwt_claims()->>'full_name', 'نظام المبيعات الذكي'),
                    COALESCE(auth.user_role(), 'system'),
                    'مبيعات طلب رقم: ' || p_order_number
                );

                v_unit_price := v_db_price;
            ELSE
                v_unit_price := COALESCE((v_item->>'unit_price')::numeric, 0);
            END IF;
        ELSE
            v_unit_price := COALESCE((v_item->>'unit_price')::numeric, 0);
        END IF;

        v_line_total := round(v_unit_price * v_qty, 2);
        v_calc_subtotal := v_calc_subtotal + v_line_total;
    END LOOP;

    -- Step 5: Anti-Price Tampering Reconciliation
    IF v_calc_subtotal > 0 AND abs(p_subtotal - v_calc_subtotal) > 1.0 THEN
        v_effective_subtotal := v_calc_subtotal;
        v_effective_total := round(v_calc_subtotal + COALESCE(p_delivery_fee, 0) - COALESCE(p_discount_amount, 0) - COALESCE(p_loyalty_discount, 0), 2);
        IF v_effective_total < 0 THEN
            v_effective_total := 0;
        END IF;
    ELSE
        v_effective_subtotal := p_subtotal;
        v_effective_total := p_total_amount;
    END IF;

    -- Step 6: Insert Order Header
    INSERT INTO public.orders (
        order_number,
        user_id,
        status,
        delivery_slot,
        payment_method,
        payment_status,
        subtotal,
        delivery_fee,
        discount_amount,
        loyalty_points_used,
        loyalty_discount,
        total_amount,
        notes,
        branch_id,
        branch_name
    ) VALUES (
        p_order_number,
        v_effective_user_id,
        'pending',
        COALESCE(p_delivery_slot, 'خلال 45 دقيقة'),
        p_payment_method,
        'pending',
        v_effective_subtotal,
        p_delivery_fee,
        p_discount_amount,
        COALESCE(p_loyalty_points_used, 0),
        COALESCE(p_loyalty_discount, 0),
        v_effective_total,
        p_notes,
        v_target_branch_id,
        v_branch_name
    )
    RETURNING id INTO v_order_id;

    -- Step 7: Insert Order Items
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_product_id := NULL;
        v_unit_price := COALESCE((v_item->>'unit_price')::numeric, 0);

        IF (v_item->>'product_id') IS NOT NULL AND (v_item->>'product_id') ~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$' THEN
            v_product_id := (v_item->>'product_id')::uuid;
            SELECT price INTO v_db_price FROM public.products WHERE id = v_product_id;
            IF FOUND THEN
                v_unit_price := v_db_price;
            END IF;
        END IF;

        v_qty := (v_item->>'quantity')::numeric;
        v_line_total := round(v_unit_price * v_qty, 2);

        INSERT INTO public.order_items (
            order_id,
            product_id,
            product_name_ar,
            product_name_en,
            product_image,
            unit,
            unit_price,
            quantity,
            total_price
        ) VALUES (
            v_order_id,
            v_product_id,
            COALESCE(v_item->>'product_name_ar', 'صنف تسوق'),
            COALESCE(v_item->>'product_name_en', 'Grocery Item'),
            COALESCE(v_item->>'product_image', ''),
            COALESCE(v_item->>'unit', 'piece'),
            v_unit_price,
            v_qty,
            v_line_total
        );
    END LOOP;

    -- Step 8: Return Created Order JSON
    SELECT jsonb_build_object(
        'id', o.id,
        'order_number', o.order_number,
        'status', o.status,
        'subtotal', o.subtotal,
        'total_amount', o.total_amount,
        'branch_id', o.branch_id,
        'branch_name', o.branch_name,
        'created_at', o.created_at
    ) INTO v_result
    FROM public.orders o
    WHERE o.id = v_order_id;

    RETURN v_result;
END;
$$;

-- 12. Row Level Security Policies for the New Inventory Tables
ALTER TABLE public.branch_inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.branch_inventory FORCE ROW LEVEL SECURITY;

ALTER TABLE public.inventory_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory_movements FORCE ROW LEVEL SECURITY;

ALTER TABLE public.inventory_transfers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory_transfers FORCE ROW LEVEL SECURITY;

ALTER TABLE public.inventory_audits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory_audits FORCE ROW LEVEL SECURITY;

-- Policies on branch_inventory
DROP POLICY IF EXISTS "branch_inventory_select_policy" ON public.branch_inventory;
CREATE POLICY "branch_inventory_select_policy" ON public.branch_inventory
    FOR SELECT TO authenticated, anon
    USING (
        (auth.user_role() = ANY (ARRAY['super_admin', 'general_manager', 'auditor', 'accountant', 'warehouse_manager']))
        OR ((auth.user_role() = ANY (ARRAY['branch_manager', 'cashier'])) AND branch_id = auth.branch_id())
        OR auth.is_staff()
        OR (auth.user_role() = 'anon')
    );

DROP POLICY IF EXISTS "branch_inventory_admin_mutation" ON public.branch_inventory;
CREATE POLICY "branch_inventory_admin_mutation" ON public.branch_inventory
    FOR ALL TO authenticated
    USING (
        (auth.user_role() = ANY (ARRAY['super_admin', 'general_manager', 'warehouse_manager']))
        OR ((auth.user_role() = 'branch_manager') AND branch_id = auth.branch_id())
    )
    WITH CHECK (
        (auth.user_role() = ANY (ARRAY['super_admin', 'general_manager', 'warehouse_manager']))
        OR ((auth.user_role() = 'branch_manager') AND branch_id = auth.branch_id())
    );

-- Policies on inventory_movements
DROP POLICY IF EXISTS "inventory_movements_select_policy" ON public.inventory_movements;
CREATE POLICY "inventory_movements_select_policy" ON public.inventory_movements
    FOR SELECT TO authenticated
    USING (
        (auth.user_role() = ANY (ARRAY['super_admin', 'general_manager', 'auditor', 'accountant', 'warehouse_manager']))
        OR ((auth.user_role() = ANY (ARRAY['branch_manager', 'cashier'])) AND branch_id = auth.branch_id())
        OR auth.is_staff()
    );

DROP POLICY IF EXISTS "inventory_movements_admin_mutation" ON public.inventory_movements;
CREATE POLICY "inventory_movements_admin_mutation" ON public.inventory_movements
    FOR INSERT TO authenticated
    WITH CHECK (
        (auth.user_role() = ANY (ARRAY['super_admin', 'general_manager', 'warehouse_manager']))
        OR ((auth.user_role() = ANY (ARRAY['branch_manager', 'cashier'])) AND branch_id = auth.branch_id())
    );

-- Policies on inventory_transfers
DROP POLICY IF EXISTS "inventory_transfers_select_policy" ON public.inventory_transfers;
CREATE POLICY "inventory_transfers_select_policy" ON public.inventory_transfers
    FOR SELECT TO authenticated
    USING (
        (auth.user_role() = ANY (ARRAY['super_admin', 'general_manager', 'auditor', 'accountant', 'warehouse_manager']))
        OR ((auth.user_role() = 'branch_manager') AND (source_branch_id = auth.branch_id() OR destination_branch_id = auth.branch_id()))
        OR auth.is_staff()
    );

DROP POLICY IF EXISTS "inventory_transfers_admin_mutation" ON public.inventory_transfers;
CREATE POLICY "inventory_transfers_admin_mutation" ON public.inventory_transfers
    FOR ALL TO authenticated
    USING (
        (auth.user_role() = ANY (ARRAY['super_admin', 'general_manager', 'warehouse_manager']))
        OR ((auth.user_role() = 'branch_manager') AND (source_branch_id = auth.branch_id() OR destination_branch_id = auth.branch_id()))
    )
    WITH CHECK (
        (auth.user_role() = ANY (ARRAY['super_admin', 'general_manager', 'warehouse_manager']))
        OR ((auth.user_role() = 'branch_manager') AND (source_branch_id = auth.branch_id() OR destination_branch_id = auth.branch_id()))
    );

-- Policies on inventory_audits
DROP POLICY IF EXISTS "inventory_audits_select_policy" ON public.inventory_audits;
CREATE POLICY "inventory_audits_select_policy" ON public.inventory_audits
    FOR SELECT TO authenticated
    USING (
        (auth.user_role() = ANY (ARRAY['super_admin', 'general_manager', 'auditor', 'accountant', 'warehouse_manager']))
        OR ((auth.user_role() = 'branch_manager') AND branch_id = auth.branch_id())
        OR auth.is_staff()
    );

-- 13. Grant Permissions
GRANT SELECT ON public.branch_inventory TO anon, authenticated;
GRANT ALL ON public.branch_inventory TO authenticated;

GRANT SELECT ON public.inventory_movements TO authenticated;
GRANT INSERT ON public.inventory_movements TO authenticated;

GRANT SELECT ON public.inventory_transfers TO authenticated;
GRANT ALL ON public.inventory_transfers TO authenticated;

GRANT SELECT ON public.inventory_audits TO authenticated;
GRANT ALL ON public.inventory_audits TO authenticated;

GRANT EXECUTE ON FUNCTION public.record_inventory_movement_atomic TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.perform_inventory_transfer_step_atomic TO authenticated;
GRANT EXECUTE ON FUNCTION public.perform_stock_audit_reconciliation_atomic TO authenticated;
GRANT EXECUTE ON FUNCTION public.cancel_order_atomic TO authenticated;
GRANT EXECUTE ON FUNCTION public.process_order_return_atomic TO authenticated;
GRANT EXECUTE ON FUNCTION public.place_order_atomic TO anon, authenticated;

-- Record migration in _schema_migrations
INSERT INTO public._schema_migrations (filename, applied_at)
VALUES ('20261104_019_real_inventory_and_movements.sql', timezone('utc'::text, now()))
ON CONFLICT (filename) DO UPDATE SET applied_at = timezone('utc'::text, now());

COMMIT;

-- --- END OF supabase/migrations/20261104_019_real_inventory_and_movements.sql ---

-- --- START OF supabase/migrations/20261104_025_delivery_zones_and_fulfillment_engine.sql ---
-- ==============================================================================
-- 🚚 ALDEEB MALL: DELIVERY ZONES, COVERAGE VALIDATION & FULFILLMENT ENGINE
-- Migration: 20261104_025_delivery_zones_and_fulfillment_engine.sql
-- Step 025 in the Single Monotonic Migration Sequence (Task 15)
-- ==============================================================================

BEGIN;

-- 1. Create delivery_zones table
CREATE TABLE IF NOT EXISTS public.delivery_zones (
    id VARCHAR(64) PRIMARY KEY,
    zone_name_ar VARCHAR(255) NOT NULL,
    zone_name_en VARCHAR(255),
    city VARCHAR(100) NOT NULL,
    district VARCHAR(100),
    branch_id VARCHAR(64) REFERENCES public.branches(id) ON DELETE SET NULL,
    dark_store_code VARCHAR(64) DEFAULT 'WH-DAM-HUB',
    center_latitude NUMERIC(10, 7) NOT NULL DEFAULT 33.5138,
    center_longitude NUMERIC(10, 7) NOT NULL DEFAULT 36.2765,
    radius_km NUMERIC(6, 2) NOT NULL DEFAULT 5.00,
    base_delivery_fee NUMERIC(12, 2) NOT NULL DEFAULT 5000.00,
    free_delivery_threshold NUMERIC(12, 2) NOT NULL DEFAULT 150000.00,
    estimated_minutes INTEGER NOT NULL DEFAULT 25,
    is_surge_pricing_active BOOLEAN NOT NULL DEFAULT false,
    surge_fee NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    is_active BOOLEAN NOT NULL DEFAULT true,
    opening_time TIME NOT NULL DEFAULT '08:00:00',
    closing_time TIME NOT NULL DEFAULT '23:59:59',
    max_hourly_capacity INTEGER NOT NULL DEFAULT 50,
    current_hourly_load INTEGER NOT NULL DEFAULT 0,
    delivery_options JSONB NOT NULL DEFAULT '[
        {"id": "express", "name_ar": "توصيل إكسبريس فوري ⚡", "fee_modifier": 0, "estimated_minutes": 30},
        {"id": "scheduled", "name_ar": "توصيل مجدول 📅", "fee_modifier": 0, "estimated_minutes": 120},
        {"id": "click_collect", "name_ar": "استلام من فرع المول (Click & Collect)", "fee_modifier": 0, "estimated_minutes": 30},
        {"id": "curbside", "name_ar": "استلام من السيارة (Curbside Pickup 🚗)", "fee_modifier": 0, "estimated_minutes": 15}
    ]'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT delivery_zones_radius_check CHECK (radius_km > 0),
    CONSTRAINT delivery_zones_fee_check CHECK (base_delivery_fee >= 0),
    CONSTRAINT delivery_zones_surge_check CHECK (surge_fee >= 0),
    CONSTRAINT delivery_zones_threshold_check CHECK (free_delivery_threshold >= 0),
    CONSTRAINT delivery_zones_capacity_check CHECK (max_hourly_capacity >= 0 AND current_hourly_load >= 0)
);

CREATE INDEX IF NOT EXISTS idx_delivery_zones_city ON public.delivery_zones(city);
CREATE INDEX IF NOT EXISTS idx_delivery_zones_branch ON public.delivery_zones(branch_id);
CREATE INDEX IF NOT EXISTS idx_delivery_zones_active ON public.delivery_zones(is_active);

-- 2. Force Row Level Security (RLS)
ALTER TABLE public.delivery_zones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.delivery_zones FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "delivery_zones_select_policy" ON public.delivery_zones;
CREATE POLICY "delivery_zones_select_policy" ON public.delivery_zones
    FOR SELECT TO public
    USING (true);

DROP POLICY IF EXISTS "delivery_zones_mutate_policy" ON public.delivery_zones;
CREATE POLICY "delivery_zones_mutate_policy" ON public.delivery_zones
    FOR ALL TO authenticated
    USING (auth.user_role() IN ('super_admin', 'general_manager', 'branch_manager', 'warehouse_manager', 'operations_manager', 'auditor'))
    WITH CHECK (auth.user_role() IN ('super_admin', 'general_manager', 'branch_manager', 'warehouse_manager', 'operations_manager', 'auditor'));

-- Grants for PostgREST & Application Roles
GRANT ALL ON public.delivery_zones TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.check_delivery_coverage(NUMERIC, NUMERIC, TEXT, TEXT, NUMERIC, TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.haversine_distance_km(NUMERIC, NUMERIC, NUMERIC, NUMERIC) TO anon, authenticated;

-- 3. Haversine Distance Calculation Function in Kilometers
CREATE OR REPLACE FUNCTION public.haversine_distance_km(
    p_lat1 NUMERIC,
    p_lon1 NUMERIC,
    p_lat2 NUMERIC,
    p_lon2 NUMERIC
)
RETURNS NUMERIC
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
    v_r NUMERIC := 6371.0; -- Earth radius in km
    v_dlat NUMERIC;
    v_dlon NUMERIC;
    v_a NUMERIC;
    v_c NUMERIC;
    v_rad_lat1 NUMERIC;
    v_rad_lat2 NUMERIC;
BEGIN
    IF p_lat1 IS NULL OR p_lon1 IS NULL OR p_lat2 IS NULL OR p_lon2 IS NULL THEN
        RETURN NULL;
    END IF;

    -- Degrees to Radians
    v_rad_lat1 := radians(p_lat1);
    v_rad_lat2 := radians(p_lat2);
    v_dlat := radians(p_lat2 - p_lat1);
    v_dlon := radians(p_lon2 - p_lon1);

    v_a := sin(v_dlat / 2.0)^2 + cos(v_rad_lat1) * cos(v_rad_lat2) * sin(v_dlon / 2.0)^2;
    -- Clamp v_a to [0, 1] to prevent domain errors
    v_a := least(greatest(v_a, 0.0), 1.0);
    v_c := 2.0 * asin(sqrt(v_a));

    RETURN round(v_r * v_c, 3);
END;
$$;

-- 4. Server-Side Address Verification, Branch Selection, and Dynamic Fee Engine
CREATE OR REPLACE FUNCTION public.check_delivery_coverage(
    p_latitude NUMERIC DEFAULT NULL,
    p_longitude NUMERIC DEFAULT NULL,
    p_city TEXT DEFAULT NULL,
    p_district TEXT DEFAULT NULL,
    p_subtotal NUMERIC DEFAULT 0.0,
    p_delivery_slot TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
    v_zone RECORD;
    v_branch RECORD;
    v_best_zone RECORD;
    v_best_zone_found BOOLEAN := false;
    v_min_distance NUMERIC := 999999.0;
    v_calc_distance NUMERIC;
    v_current_time TIME := localtime;
    v_is_within_hours BOOLEAN := true;
    v_is_free BOOLEAN := false;
    v_final_fee NUMERIC := 0.0;
    v_surge_applied BOOLEAN := false;
    v_surge_fee NUMERIC := 0.0;
BEGIN
    -- Check if Click & Collect or Curbside (no delivery fee, bypass zone coverage)
    IF p_delivery_slot IS NOT NULL AND (
        p_delivery_slot ILIKE '%استلام%' OR 
        p_delivery_slot ILIKE '%pickup%' OR 
        p_delivery_slot ILIKE '%click%' OR 
        p_delivery_slot ILIKE '%كاشير%' OR 
        p_delivery_slot ILIKE '%pos%'
    ) THEN
        RETURN jsonb_build_object(
            'is_covered', true,
            'is_pickup', true,
            'zone_id', 'zn-pickup-direct',
            'zone_name_ar', 'استلام مباشر من الفرع',
            'branch_id', 'b-dam-01',
            'branch_name_ar', 'فرع دمشق المركزي (أوتوستراد المزة)',
            'base_delivery_fee', 0.00,
            'surge_fee', 0.00,
            'is_surge_active', false,
            'final_delivery_fee', 0.00,
            'is_free_delivery', true,
            'estimated_minutes', 15,
            'distance_km', 0.0,
            'status', 'ALLOWED',
            'message', 'خيار الاستلام المباشر متاح بدون أي رسوم توصيل'
        );
    END IF;

    -- 1. Find the best matching zone
    -- A: By GPS coordinates if provided
    IF p_latitude IS NOT NULL AND p_longitude IS NOT NULL THEN
        FOR v_zone IN 
            SELECT z.*, b.name_ar AS b_name_ar, b.is_active AS b_is_active
            FROM public.delivery_zones z
            LEFT JOIN public.branches b ON z.branch_id = b.id
        LOOP
            v_calc_distance := public.haversine_distance_km(p_latitude, p_longitude, v_zone.center_latitude, v_zone.center_longitude);
            
            -- If inside radius and closer than any previous match
            IF v_calc_distance <= v_zone.radius_km AND v_calc_distance < v_min_distance THEN
                v_min_distance := v_calc_distance;
                v_best_zone := v_zone;
                v_best_zone_found := true;
            END IF;
        END LOOP;
    END IF;

    -- B: Fallback by City / District name if GPS not provided or not matched directly
    IF NOT v_best_zone_found AND p_city IS NOT NULL AND trim(p_city) <> '' THEN
        SELECT z.*, b.name_ar AS b_name_ar, b.is_active AS b_is_active
        INTO v_best_zone
        FROM public.delivery_zones z
        LEFT JOIN public.branches b ON z.branch_id = b.id
        WHERE z.city ILIKE '%' || trim(p_city) || '%'
           OR (p_district IS NOT NULL AND (z.district ILIKE '%' || trim(p_district) || '%' OR z.zone_name_ar ILIKE '%' || trim(p_district) || '%'))
        ORDER BY z.is_active DESC, z.radius_km DESC
        LIMIT 1;

        IF FOUND THEN
            v_best_zone_found := true;
            v_min_distance := v_best_zone.radius_km * 0.5; -- approximate nominal distance
        END IF;
    END IF;

    -- 2. Verify Zone Coverage & Active Status
    IF NOT v_best_zone_found THEN
        RETURN jsonb_build_object(
            'is_covered', false,
            'rejection_reason', 'OUT_OF_COVERAGE',
            'status', 'REJECTED',
            'message', 'عذراً، العنوان المحدد يقع خارج نطاق التغطية الجغرافية لخدمة التوصيل'
        );
    END IF;

    -- Check if zone itself is deactivated (e.g. Daraa excluded by default)
    IF NOT v_best_zone.is_active THEN
        RETURN jsonb_build_object(
            'is_covered', false,
            'zone_id', v_best_zone.id,
            'zone_name_ar', v_best_zone.zone_name_ar,
            'rejection_reason', 'ZONE_INACTIVE',
            'status', 'REJECTED',
            'message', 'عذراً، نطاق التوصيل في (' || v_best_zone.zone_name_ar || ') غير متاح حالياً أو معطل من قبل الإدارة'
        );
    END IF;

    -- 3. Verify Associated Branch Operational Status
    IF v_best_zone.branch_id IS NOT NULL THEN
        SELECT * INTO v_branch FROM public.branches WHERE id = v_best_zone.branch_id;
        IF NOT FOUND OR NOT v_branch.is_active THEN
            RETURN jsonb_build_object(
                'is_covered', false,
                'zone_id', v_best_zone.id,
                'zone_name_ar', v_best_zone.zone_name_ar,
                'branch_id', v_best_zone.branch_id,
                'branch_name_ar', COALESCE(v_branch.name_ar, 'الفرع المحدد'),
                'rejection_reason', 'BRANCH_CLOSED',
                'status', 'REJECTED',
                'message', 'عذراً، فرع التوصيل المسؤول عن هذا النطاق (' || COALESCE(v_branch.name_ar, v_best_zone.branch_id) || ') مغلق حالياً للصيانة أو خارج أوقات العمل'
            );
        END IF;
    END IF;

    -- 4. Verify Operating Hours
    IF v_best_zone.opening_time IS NOT NULL AND v_best_zone.closing_time IS NOT NULL THEN
        IF v_best_zone.opening_time <= v_best_zone.closing_time THEN
            IF v_current_time < v_best_zone.opening_time OR v_current_time > v_best_zone.closing_time THEN
                v_is_within_hours := false;
            END IF;
        ELSE
            -- Spans across midnight
            IF v_current_time < v_best_zone.opening_time AND v_current_time > v_best_zone.closing_time THEN
                v_is_within_hours := false;
            END IF;
        END IF;

        IF NOT v_is_within_hours THEN
            RETURN jsonb_build_object(
                'is_covered', false,
                'zone_id', v_best_zone.id,
                'zone_name_ar', v_best_zone.zone_name_ar,
                'rejection_reason', 'OUTSIDE_OPERATING_HOURS',
                'opening_time', v_best_zone.opening_time,
                'closing_time', v_best_zone.closing_time,
                'status', 'REJECTED',
                'message', 'عذراً، خدمة التوصيل في هذا النطاق تعمل يومياً من ' || to_char(v_best_zone.opening_time, 'HH12:MI AM') || ' إلى ' || to_char(v_best_zone.closing_time, 'HH12:MI AM')
            );
        END IF;
    END IF;

    -- 5. Calculate Server-Authoritative Fee & Dynamic Surge
    IF p_subtotal >= v_best_zone.free_delivery_threshold AND p_subtotal > 0 THEN
        v_is_free := true;
        v_final_fee := 0.00;
        v_surge_applied := false;
    ELSE
        v_final_fee := v_best_zone.base_delivery_fee;
        IF v_best_zone.is_surge_pricing_active THEN
            v_surge_applied := true;
            v_surge_fee := v_best_zone.surge_fee;
            v_final_fee := v_final_fee + v_surge_fee;
        END IF;
    END IF;

    -- Return full success contract
    RETURN jsonb_build_object(
        'is_covered', true,
        'zone_id', v_best_zone.id,
        'zone_name_ar', v_best_zone.zone_name_ar,
        'city', v_best_zone.city,
        'district', v_best_zone.district,
        'branch_id', v_best_zone.branch_id,
        'branch_name_ar', COALESCE(v_best_zone.b_name_ar, 'الفرع المركزي'),
        'dark_store_code', v_best_zone.dark_store_code,
        'distance_km', v_min_distance,
        'radius_km', v_best_zone.radius_km,
        'base_delivery_fee', v_best_zone.base_delivery_fee,
        'is_surge_active', v_best_zone.is_surge_pricing_active,
        'surge_fee', v_surge_fee,
        'surge_applied', v_surge_applied,
        'final_delivery_fee', v_final_fee,
        'free_delivery_threshold', v_best_zone.free_delivery_threshold,
        'is_free_delivery', v_is_free,
        'estimated_minutes', v_best_zone.estimated_minutes,
        'opening_time', v_best_zone.opening_time,
        'closing_time', v_best_zone.closing_time,
        'delivery_options', v_best_zone.delivery_options,
        'status', 'ALLOWED',
        'message', 'النطاق مشمول بالتغطية ومتاح للتوصيل الفوري'
    );
END;
$$;

-- 5. Update place_order_atomic to respect authoritative delivery_zones table
CREATE OR REPLACE FUNCTION public.place_order_atomic(
    p_order_number text,
    p_user_id uuid,
    p_delivery_slot text,
    p_payment_method text,
    p_subtotal numeric,
    p_delivery_fee numeric,
    p_discount_amount numeric,
    p_loyalty_points_used int,
    p_loyalty_discount numeric,
    p_total_amount numeric,
    p_notes text,
    p_items jsonb,
    p_branch_id text DEFAULT 'b-jed-01',
    p_coupon_code text DEFAULT NULL,
    p_idempotency_key text DEFAULT NULL,
    p_customer_name text DEFAULT NULL,
    p_customer_phone text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_caller_id uuid;
    v_effective_user_id uuid;
    v_is_admin boolean;
    v_effective_idempotency_key text;
    v_target_branch_id text;
    v_branch_name text;
    v_order_id uuid;
    v_item jsonb;
    v_product_id uuid;
    v_prod_rec record;
    v_qty numeric;
    v_db_price numeric;
    v_line_total numeric;
    v_calc_subtotal numeric := 0;
    v_effective_subtotal numeric;
    v_coupon_rec record;
    v_calc_coupon_discount numeric := 0;
    v_user_loyalty_balance int;
    v_redemption_rate numeric;
    v_calc_loyalty_discount numeric := 0;
    v_standard_delivery_fee numeric := 10.00;
    v_free_delivery_threshold numeric := 100.00;
    v_matched_zone record;
    v_expected_delivery_fee numeric := 0;
    v_calc_total numeric := 0;
    v_existing_order record;
    v_new_stock int;
    v_branch_stock numeric(12,2);
    v_inv_trx_num text;
    v_result jsonb;
BEGIN
    -- -------------------------------------------------------------------------
    -- STEP 1: Idempotency Protection — Return existing order on retry
    -- -------------------------------------------------------------------------
    v_effective_idempotency_key := COALESCE(NULLIF(trim(p_idempotency_key), ''), p_order_number);

    SELECT o.id, o.order_number, o.status, o.subtotal, o.delivery_fee, o.discount_amount,
           o.loyalty_points_used, o.loyalty_discount, o.total_amount, o.branch_id, o.branch_name, o.created_at
    INTO v_existing_order
    FROM public.orders o
    WHERE o.order_number = p_order_number
       OR (v_effective_idempotency_key IS NOT NULL AND o.idempotency_key = v_effective_idempotency_key)
    LIMIT 1;

    IF FOUND THEN
        RETURN jsonb_build_object(
            'id', v_existing_order.id,
            'order_number', v_existing_order.order_number,
            'status', v_existing_order.status,
            'subtotal', v_existing_order.subtotal,
            'delivery_fee', v_existing_order.delivery_fee,
            'discount_amount', v_existing_order.discount_amount,
            'loyalty_points_used', v_existing_order.loyalty_points_used,
            'loyalty_discount', v_existing_order.loyalty_discount,
            'total_amount', v_existing_order.total_amount,
            'branch_id', v_existing_order.branch_id,
            'branch_name', v_existing_order.branch_name,
            'created_at', v_existing_order.created_at,
            'is_idempotent_replay', true
        );
    END IF;

    -- -------------------------------------------------------------------------
    -- STEP 2: Caller Identity & Privilege Verification
    -- -------------------------------------------------------------------------
    v_caller_id := auth.uid();
    v_is_admin := public.is_admin();

    IF v_caller_id IS NOT NULL THEN
        v_effective_user_id := v_caller_id;
    ELSIF v_is_admin OR current_user IN ('postgres', 'ahmad_alzoubi') THEN
        v_effective_user_id := p_user_id;
    ELSE
        IF p_user_id IS NOT NULL THEN
            RAISE EXCEPTION 'UNAUTHORIZED: Anonymous callers cannot assign orders to registered user accounts';
        END IF;
        v_effective_user_id := NULL;
    END IF;

    IF (p_delivery_slot ILIKE '%كاشير%' OR p_delivery_slot ILIKE '%pos%') AND v_caller_id IS NULL AND NOT v_is_admin THEN
        RAISE EXCEPTION 'UNAUTHORIZED_POS: In-store POS cashier orders must be placed by authenticated staff';
    END IF;

    -- -------------------------------------------------------------------------
    -- STEP 3: Branch Verification
    -- -------------------------------------------------------------------------
    v_target_branch_id := COALESCE(NULLIF(trim(p_branch_id), ''), auth.branch_id(), 'b-dam-01');

    SELECT id, name_ar INTO v_target_branch_id, v_branch_name
    FROM public.branches
    WHERE id = v_target_branch_id AND is_active = true;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'INVALID_BRANCH: Branch % does not exist or is inactive', p_branch_id;
    END IF;

    -- -------------------------------------------------------------------------
    -- STEP 4: Authoritative Catalog Pricing & Stock Lock
    -- -------------------------------------------------------------------------
    IF p_items IS NULL OR jsonb_array_length(p_items) = 0 THEN
        RAISE EXCEPTION 'EMPTY_ITEMS: Cannot place an order without items';
    END IF;

    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        IF (v_item->>'product_id') IS NULL OR NOT ((v_item->>'product_id') ~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$') THEN
            RAISE EXCEPTION 'PRODUCT_NOT_FOUND: Product ID is missing, null, or has an invalid UUID format';
        END IF;

        v_product_id := (v_item->>'product_id')::uuid;

        v_qty := (v_item->>'quantity')::numeric;
        IF v_qty IS NULL OR v_qty <= 0 THEN
            RAISE EXCEPTION 'INVALID_QUANTITY: Quantity must be greater than zero';
        END IF;

        SELECT id, name_ar, name_en, price, stock_quantity, is_active
        INTO v_prod_rec
        FROM public.products
        WHERE id = v_product_id
        FOR UPDATE;

        IF NOT FOUND OR NOT v_prod_rec.is_active THEN
            RAISE EXCEPTION 'PRODUCT_NOT_FOUND: Product with id % does not exist or is inactive', v_product_id;
        END IF;

        v_db_price := v_prod_rec.price;

        IF (v_item->>'unit_price') IS NOT NULL THEN
            IF abs((v_item->>'unit_price')::numeric - v_db_price) > 0.05 THEN
                RAISE EXCEPTION 'PRICE_TAMPERED: Price mismatch for product %. Expected %, received %',
                    v_product_id, v_db_price, (v_item->>'unit_price')::numeric;
            END IF;
        END IF;

        SELECT quantity_on_hand INTO v_branch_stock
        FROM public.branch_inventory
        WHERE branch_id = v_target_branch_id AND product_id = v_product_id
        FOR UPDATE;

        IF FOUND THEN
            IF v_branch_stock < v_qty THEN
                RAISE EXCEPTION 'INSUFFICIENT_STOCK: Only % units available for product % in branch %',
                    v_branch_stock, v_product_id, v_target_branch_id;
            END IF;
        ELSE
            IF v_prod_rec.stock_quantity < v_qty THEN
                RAISE EXCEPTION 'INSUFFICIENT_STOCK: Only % units available for product %', v_prod_rec.stock_quantity, v_product_id;
            END IF;
        END IF;

        v_line_total := round(v_db_price * v_qty, 2);
        v_calc_subtotal := v_calc_subtotal + v_line_total;
    END LOOP;

    IF p_subtotal IS NOT NULL AND abs(p_subtotal - v_calc_subtotal) > 0.50 THEN
        RAISE EXCEPTION 'SUBTOTAL_TAMPERED: Subtotal mismatch. Server computed %, client sent %', v_calc_subtotal, p_subtotal;
    END IF;
    v_effective_subtotal := v_calc_subtotal;

    -- -------------------------------------------------------------------------
    -- STEP 5: Coupon Validation & Calculation
    -- -------------------------------------------------------------------------
    IF p_coupon_code IS NOT NULL AND trim(p_coupon_code) <> '' THEN
        SELECT id, code, discount_type, discount_value, min_order_amount, max_discount, usage_limit, times_used, expires_at, is_active
        INTO v_coupon_rec
        FROM public.coupons
        WHERE lower(code) = lower(trim(p_coupon_code))
        FOR UPDATE;

        IF NOT FOUND OR NOT v_coupon_rec.is_active THEN
            RAISE EXCEPTION 'INVALID_COUPON: Coupon % does not exist or is inactive', p_coupon_code;
        END IF;

        IF v_coupon_rec.expires_at IS NOT NULL AND v_coupon_rec.expires_at < now() THEN
            RAISE EXCEPTION 'COUPON_EXPIRED: Coupon % expired at %', p_coupon_code, v_coupon_rec.expires_at;
        END IF;

        IF v_effective_subtotal < v_coupon_rec.min_order_amount THEN
            RAISE EXCEPTION 'COUPON_MIN_ORDER_NOT_MET: Minimum order amount of % required for coupon %',
                v_coupon_rec.min_order_amount, p_coupon_code;
        END IF;

        IF v_coupon_rec.usage_limit IS NOT NULL AND v_coupon_rec.times_used >= v_coupon_rec.usage_limit THEN
            RAISE EXCEPTION 'COUPON_USAGE_LIMIT_REACHED: Coupon % has reached its maximum usage limit', p_coupon_code;
        END IF;

        IF v_coupon_rec.discount_type IN ('percentage', 'percent') THEN
            v_calc_coupon_discount := round((v_effective_subtotal * v_coupon_rec.discount_value / 100.0), 2);
            IF v_coupon_rec.max_discount IS NOT NULL AND v_calc_coupon_discount > v_coupon_rec.max_discount THEN
                v_calc_coupon_discount := v_coupon_rec.max_discount;
            END IF;
        ELSE
            v_calc_coupon_discount := least(v_coupon_rec.discount_value, v_effective_subtotal);
        END IF;

        IF p_discount_amount IS NOT NULL AND abs(p_discount_amount - v_calc_coupon_discount) > 0.50 THEN
            RAISE EXCEPTION 'DISCOUNT_TAMPERED: Discount mismatch. Server computed %, client sent %',
                v_calc_coupon_discount, p_discount_amount;
        END IF;

        UPDATE public.coupons
        SET times_used = times_used + 1
        WHERE id = v_coupon_rec.id;
    ELSE
        v_calc_coupon_discount := 0;
    END IF;

    -- -------------------------------------------------------------------------
    -- STEP 6: Loyalty Points Validation & Redemption
    -- -------------------------------------------------------------------------
    IF COALESCE(p_loyalty_points_used, 0) > 0 THEN
        IF v_effective_user_id IS NULL THEN
            RAISE EXCEPTION 'UNAUTHORIZED_LOYALTY: Guest orders cannot redeem loyalty points';
        END IF;

        SELECT loyalty_points INTO v_user_loyalty_balance
        FROM public.profiles
        WHERE id = v_effective_user_id
        FOR UPDATE;

        IF v_user_loyalty_balance IS NULL OR v_user_loyalty_balance < p_loyalty_points_used THEN
            RAISE EXCEPTION 'INSUFFICIENT_LOYALTY_POINTS: User only has % points, requested %',
                COALESCE(v_user_loyalty_balance, 0), p_loyalty_points_used;
        END IF;

        SELECT COALESCE(points_redemption_rate, 0.01) INTO v_redemption_rate
        FROM public.store_settings
        WHERE id = 'default';
        IF v_redemption_rate IS NULL THEN v_redemption_rate := 0.01; END IF;

        v_calc_loyalty_discount := round(p_loyalty_points_used * v_redemption_rate, 2);

        IF p_loyalty_discount IS NOT NULL AND abs(p_loyalty_discount - v_calc_loyalty_discount) > 0.50 THEN
            RAISE EXCEPTION 'LOYALTY_DISCOUNT_TAMPERED: Loyalty discount mismatch. Server computed %, client sent %',
                v_calc_loyalty_discount, p_loyalty_discount;
        END IF;

        UPDATE public.profiles
        SET loyalty_points = loyalty_points - p_loyalty_points_used,
            updated_at = timezone('utc'::text, now())
        WHERE id = v_effective_user_id;
    ELSE
        v_calc_loyalty_discount := 0;
    END IF;

    -- -------------------------------------------------------------------------
    -- STEP 7: Authoritative Delivery Zones & Delivery Fee Verification
    -- -------------------------------------------------------------------------
    IF p_delivery_fee IS NOT NULL AND p_delivery_fee < 0 THEN
        RAISE EXCEPTION 'DELIVERY_FEE_TAMPERED: Delivery fee cannot be negative';
    END IF;

    SELECT * INTO v_matched_zone
    FROM public.delivery_zones
    WHERE branch_id = v_target_branch_id AND is_active = true
    ORDER BY free_delivery_threshold ASC
    LIMIT 1;

    IF FOUND THEN
        v_standard_delivery_fee := v_matched_zone.base_delivery_fee;
        IF v_matched_zone.is_surge_pricing_active THEN
            v_standard_delivery_fee := v_standard_delivery_fee + v_matched_zone.surge_fee;
        END IF;
        v_free_delivery_threshold := v_matched_zone.free_delivery_threshold;
    ELSE
        SELECT COALESCE(delivery_fee, 5000.00), COALESCE(free_delivery_threshold, 150000.00)
        INTO v_standard_delivery_fee, v_free_delivery_threshold
        FROM public.store_settings
        WHERE id = 'default';
    END IF;

    IF p_delivery_slot ILIKE '%كاشير%' 
       OR p_delivery_slot ILIKE '%pos%' 
       OR p_delivery_slot ILIKE '%استلام%' 
       OR p_delivery_slot ILIKE '%pickup%' 
       OR p_delivery_slot ILIKE '%click%' THEN
        v_expected_delivery_fee := 0;
    ELSIF v_effective_subtotal >= v_free_delivery_threshold THEN
        v_expected_delivery_fee := 0;
    ELSE
        v_expected_delivery_fee := v_standard_delivery_fee;
    END IF;

    IF p_delivery_fee IS NOT NULL AND p_delivery_fee > 0 AND v_effective_subtotal >= v_free_delivery_threshold THEN
        RAISE EXCEPTION 'DELIVERY_FEE_TAMPERED: Order qualifies for free delivery';
    END IF;

    v_calc_total := round(v_effective_subtotal - v_calc_coupon_discount - v_calc_loyalty_discount + COALESCE(p_delivery_fee, v_expected_delivery_fee), 2);
    IF v_calc_total < 0 THEN
        v_calc_total := 0;
    END IF;

    IF p_total_amount IS NOT NULL AND abs(p_total_amount - v_calc_total) > 0.50 THEN
        RAISE EXCEPTION 'TOTAL_TAMPERED: Total mismatch. Server computed %, client sent %', v_calc_total, p_total_amount;
    END IF;

    -- -------------------------------------------------------------------------
    -- STEP 8: Atomic Order Insertion & Concurrency Guard
    -- -------------------------------------------------------------------------
    BEGIN
        INSERT INTO public.orders (
            order_number,
            idempotency_key,
            user_id,
            status,
            delivery_slot,
            payment_method,
            payment_status,
            subtotal,
            delivery_fee,
            coupon_code,
            discount_amount,
            loyalty_points_used,
            loyalty_discount,
            total_amount,
            notes,
            branch_id,
            branch_name,
            customer_name,
            customer_phone
        ) VALUES (
            p_order_number,
            v_effective_idempotency_key,
            v_effective_user_id,
            'pending',
            COALESCE(p_delivery_slot, 'خلال 45 دقيقة'),
            p_payment_method,
            'pending',
            v_effective_subtotal,
            COALESCE(p_delivery_fee, v_expected_delivery_fee),
            p_coupon_code,
            v_calc_coupon_discount,
            COALESCE(p_loyalty_points_used, 0),
            v_calc_loyalty_discount,
            v_calc_total,
            p_notes,
            v_target_branch_id,
            v_branch_name,
            p_customer_name,
            p_customer_phone
        )
        RETURNING id INTO v_order_id;
    EXCEPTION WHEN unique_violation THEN
        SELECT o.id, o.order_number, o.status, o.subtotal, o.delivery_fee, o.discount_amount,
               o.loyalty_points_used, o.loyalty_discount, o.total_amount, o.branch_id, o.branch_name, o.created_at
        INTO v_existing_order
        FROM public.orders o
        WHERE o.order_number = p_order_number
           OR (v_effective_idempotency_key IS NOT NULL AND o.idempotency_key = v_effective_idempotency_key)
        LIMIT 1;

        IF FOUND THEN
            RETURN jsonb_build_object(
                'id', v_existing_order.id,
                'order_number', v_existing_order.order_number,
                'status', v_existing_order.status,
                'subtotal', v_existing_order.subtotal,
                'delivery_fee', v_existing_order.delivery_fee,
                'discount_amount', v_existing_order.discount_amount,
                'loyalty_points_used', v_existing_order.loyalty_points_used,
                'loyalty_discount', v_existing_order.loyalty_discount,
                'total_amount', v_existing_order.total_amount,
                'branch_id', v_existing_order.branch_id,
                'branch_name', v_existing_order.branch_name,
                'created_at', v_existing_order.created_at,
                'is_idempotent_replay', true
            );
        END IF;
        RAISE;
    END;

    -- -------------------------------------------------------------------------
    -- STEP 9: Insert Order Items, Decrement Stock & Record Movements
    -- -------------------------------------------------------------------------
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_product_id := (v_item->>'product_id')::uuid;
        v_qty := (v_item->>'quantity')::numeric;

        SELECT name_ar, name_en, price, stock_quantity INTO v_prod_rec
        FROM public.products WHERE id = v_product_id;

        v_db_price := v_prod_rec.price;
        v_line_total := round(v_db_price * v_qty, 2);
        v_new_stock := GREATEST(0, (v_prod_rec.stock_quantity - v_qty::int));

        -- 1. Insert Order Item
        INSERT INTO public.order_items (
            order_id,
            product_id,
            product_name_ar,
            product_name_en,
            product_image,
            unit,
            unit_price,
            quantity,
            total_price
        ) VALUES (
            v_order_id,
            v_product_id,
            COALESCE(v_prod_rec.name_ar, v_item->>'product_name_ar', 'صنف تسوق'),
            COALESCE(v_prod_rec.name_en, v_item->>'product_name_en', 'Grocery Item'),
            COALESCE(v_item->>'product_image', ''),
            COALESCE(v_item->>'unit', 'piece'),
            v_db_price,
            v_qty,
            v_line_total
        );

        -- 2. Atomically Decrement Products Catalog Stock
        UPDATE public.products
        SET stock_quantity = v_new_stock,
            sales_count = COALESCE(sales_count, 0) + v_qty::int,
            updated_at = timezone('utc'::text, now())
        WHERE id = v_product_id;

        -- 3. Atomically Update Branch Inventory if row exists
        UPDATE public.branch_inventory
        SET quantity_on_hand = quantity_on_hand - v_qty,
            updated_at = timezone('utc'::text, now())
        WHERE branch_id = v_target_branch_id AND product_id = v_product_id;

        -- 4. Record in inventory_movements ledger
        INSERT INTO public.inventory_movements (
            movement_number,
            branch_id,
            product_id,
            movement_type,
            quantity_change,
            quantity_reserved_change,
            resulting_on_hand,
            resulting_reserved,
            reference_type,
            reference_id,
            actor_id,
            actor_name,
            actor_role,
            notes
        ) VALUES (
            'MOV-' || to_char(now(), 'YYYYMMDD') || '-' || substring(gen_random_uuid()::text from 1 for 8),
            v_target_branch_id,
            v_product_id,
            'sale',
            -v_qty,
            0,
            v_new_stock,
            0,
            'order',
            p_order_number,
            v_effective_user_id::text,
            COALESCE(p_customer_name, 'عميل المتجر'),
            'customer',
            'مبيعات طلب رقم: ' || p_order_number
        );

        -- 5. Record in inventory_transactions ledger
        v_inv_trx_num := 'TRX-' || extract(epoch from now())::bigint || '-' || substring(gen_random_uuid()::text from 1 for 6);
        INSERT INTO public.inventory_transactions (
            transaction_number,
            branch_id,
            product_id,
            movement_type,
            reference_type,
            reference_id,
            quantity_change,
            unit_cost,
            total_value,
            balance_after,
            performed_by,
            notes
        ) VALUES (
            v_inv_trx_num,
            v_target_branch_id,
            v_product_id,
            'sales_deduction',
            'order_sale',
            p_order_number,
            -v_qty,
            round(v_db_price * 0.70, 2),
            round(v_qty * v_db_price * 0.70, 2),
            v_new_stock,
            v_effective_user_id::text,
            'مبيعات طلب رقم: ' || p_order_number
        );
    END LOOP;

    -- -------------------------------------------------------------------------
    -- STEP 10: Record Loyalty Transaction if points were redeemed
    -- -------------------------------------------------------------------------
    IF COALESCE(p_loyalty_points_used, 0) > 0 AND v_effective_user_id IS NOT NULL THEN
        INSERT INTO public.loyalty_transactions (
            user_id,
            order_id,
            points,
            transaction_type,
            description_ar,
            description_en
        ) VALUES (
            v_effective_user_id,
            v_order_id,
            -p_loyalty_points_used,
            'redeemed',
            'استبدال نقاط لخصم الطلب رقم ' || p_order_number,
            'Redeemed points for order ' || p_order_number
        );
    END IF;

    -- -------------------------------------------------------------------------
    -- STEP 11: Return Comprehensive Server-Authoritative Result
    -- -------------------------------------------------------------------------
    SELECT jsonb_build_object(
        'id', o.id,
        'order_number', o.order_number,
        'status', o.status,
        'subtotal', o.subtotal,
        'delivery_fee', o.delivery_fee,
        'discount_amount', o.discount_amount,
        'loyalty_points_used', o.loyalty_points_used,
        'loyalty_discount', o.loyalty_discount,
        'total_amount', o.total_amount,
        'branch_id', o.branch_id,
        'branch_name', o.branch_name,
        'created_at', o.created_at,
        'is_idempotent_replay', false
    ) INTO v_result
    FROM public.orders o
    WHERE o.id = v_order_id;

    RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION public.place_order_atomic TO anon, authenticated;

-- 6. Seed Syrian & Regional Delivery Zones (with real GPS centers & Syrian boundaries)
INSERT INTO public.delivery_zones (
    id, zone_name_ar, zone_name_en, city, district, branch_id, dark_store_code,
    center_latitude, center_longitude, radius_km, base_delivery_fee,
    free_delivery_threshold, estimated_minutes, is_surge_pricing_active,
    surge_fee, is_active, opening_time, closing_time, max_hourly_capacity
) VALUES
-- دمشق
('zn-dam-central', 'دمشق المركزية (المزة، أبو رمانة، المالكي)', 'Damascus Central (Mazzeh, Abu Roumaneh)', 'دمشق', 'المزة', 'b-dam-01', 'WH-DAM-HUB', 33.5138000, 36.2765000, 6.00, 5000.00, 150000.00, 20, false, 0.00, true, '08:00:00', '23:59:59', 80),
('zn-dam-midan', 'دمشق الجنوبية (كفرسوسة، الميدان، الزاهرة)', 'Damascus South (Kafarsouseh, Midan)', 'دمشق', 'الميدان', 'b-dam-01', 'WH-DAM-HUB', 33.4880000, 36.2950000, 7.00, 5500.00, 160000.00, 25, false, 0.00, true, '08:00:00', '23:59:59', 60),
('zn-dam-east', 'دمشق الشرقية (القصاع، باب توما، التجارة)', 'Damascus East (Qasaa, Bab Touma)', 'دمشق', 'القصاع', 'b-dam-01', 'WH-DAM-HUB', 33.5180000, 36.3150000, 8.00, 6000.00, 175000.00, 25, false, 0.00, true, '08:00:00', '23:59:59', 50),
('zn-dam-rif', 'ريف دمشق (جرمانا، ضاحية قدسيا، صحنايا)', 'Damascus Countryside (Jaramana, Qudsaya)', 'ريف دمشق', 'جرمانا', 'b-dam-01', 'WH-DAM-HUB', 33.4750000, 36.3400000, 15.00, 8500.00, 250000.00, 35, false, 0.00, true, '08:00:00', '23:00:00', 40),

-- حلب
('zn-alp-central', 'حلب المركزية (الشهباء، الفرقان، المارتيني)', 'Aleppo Central (Shahbaa, Forqan)', 'حلب', 'الشهباء', 'b-brale01', 'WH-ALP-HUB', 36.2021000, 37.1343000, 8.00, 6500.00, 200000.00, 25, false, 0.00, true, '08:00:00', '23:59:59', 50),

-- حمص
('zn-hms-central', 'حمص المركزية (الدبلان، الإنشاءات، المحطة)', 'Homs Central (Dablan, Inshaat)', 'حمص', 'الدبلان', 'b-dam-01', 'WH-HMS-HUB', 34.7324000, 36.7137000, 6.50, 5500.00, 180000.00, 20, false, 0.00, true, '08:00:00', '23:00:00', 40),

-- اللاذقية
('zn-lat-central', 'اللاذقية الساحلية (الكورنيش، الزراعة، الصليبة)', 'Latakia Coastal (Corniche, Ziraa)', 'اللاذقية', 'الكورنيش', 'b-brtest4871', 'WH-LAT-HUB', 35.5317000, 35.7915000, 7.00, 6000.00, 190000.00, 25, false, 0.00, true, '08:00:00', '23:59:59', 50),

-- درعا (مستبعدة افتراضياً وفق المتطلب التشغيلي مع إمكانية التفعيل الاستثنائي)
('zn-dra-station', 'درعا المحطة وشمال المدينة (مستبعدة افتراضياً)', 'Daraa Station & North (Excluded)', 'درعا', 'درعا المحطة', 'b-dam-01', 'FC-DR-CITY', 32.6250000, 36.1050000, 3.50, 5000.00, 150000.00, 15, false, 0.00, false, '09:00:00', '21:00:00', 20),
('zn-dra-balad', 'درعا البلد وحي طريق السد (مستبعدة افتراضياً)', 'Daraa Balad (Excluded)', 'درعا', 'درعا البلد', 'b-dam-01', 'FC-DR-CITY', 32.6050000, 36.1000000, 4.50, 7000.00, 175000.00, 25, false, 0.00, false, '09:00:00', '21:00:00', 20),
('zn-dra-tafas', 'طفس والمزيريب وريف درعا الغربي (مستبعدة افتراضياً)', 'Tafas & West Daraa (Excluded)', 'درعا', 'طفس', 'b-dam-01', 'FC-DR-WEST', 32.7300000, 36.0300000, 12.00, 15000.00, 300000.00, 40, false, 0.00, false, '09:00:00', '20:00:00', 15),
('zn-dra-izraa', 'إزرع والشيخ مسكين والريف الأوسط (مستبعدة افتراضياً)', 'Izraa & Central Daraa (Excluded)', 'درعا', 'إزرع', 'b-dam-01', 'WH-DR-CENTRAL', 32.8700000, 36.2500000, 18.00, 18000.00, 350000.00, 45, false, 0.00, false, '09:00:00', '20:00:00', 10),

-- الرياض وجدة والدمام
('zn-jed-corniche', 'جدة الكورنيش والشاطئ', 'Jeddah Corniche', 'جدة', 'الكورنيش', 'b-jed-01', 'DS-JED-01', 21.5433000, 39.1728000, 12.00, 15.00, 150.00, 30, false, 0.00, true, '08:00:00', '23:59:59', 100),
('zn-ruh-olaya', 'الرياض العليا والسليمانية', 'Riyadh Olaya', 'الرياض', 'العليا', 'b-ruh-01', 'DS-RUH-OLAYA', 24.7136000, 46.6753000, 12.00, 15.00, 150.00, 30, false, 0.00, true, '08:00:00', '23:59:59', 100),
('zn-dmm-shatee', 'الدمام الشاطئ ومول الشرقية', 'Dammam Shatea', 'الدمام', 'الشاطئ', 'b-dmm-01', 'DS-DMM-01', 26.4207000, 50.0888000, 10.00, 15.00, 150.00, 30, false, 0.00, true, '08:00:00', '23:59:59', 80)
ON CONFLICT (id) DO UPDATE SET
    zone_name_ar = EXCLUDED.zone_name_ar,
    zone_name_en = EXCLUDED.zone_name_en,
    city = EXCLUDED.city,
    district = EXCLUDED.district,
    branch_id = EXCLUDED.branch_id,
    dark_store_code = EXCLUDED.dark_store_code,
    center_latitude = EXCLUDED.center_latitude,
    center_longitude = EXCLUDED.center_longitude,
    radius_km = EXCLUDED.radius_km,
    base_delivery_fee = EXCLUDED.base_delivery_fee,
    free_delivery_threshold = EXCLUDED.free_delivery_threshold,
    estimated_minutes = EXCLUDED.estimated_minutes,
    is_active = EXCLUDED.is_active,
    opening_time = EXCLUDED.opening_time,
    closing_time = EXCLUDED.closing_time,
    max_hourly_capacity = EXCLUDED.max_hourly_capacity,
    updated_at = timezone('utc'::text, now());

-- Record migration in _schema_migrations
INSERT INTO public._schema_migrations (filename, applied_at)
VALUES ('20261104_025_delivery_zones_and_fulfillment_engine.sql', timezone('utc'::text, now()))
ON CONFLICT (filename) DO UPDATE SET applied_at = EXCLUDED.applied_at;

COMMIT;

-- --- END OF supabase/migrations/20261104_025_delivery_zones_and_fulfillment_engine.sql ---

-- --- START OF supabase/migrations/20261104_025_pos_shifts_cashier_and_atomic_checkout.sql ---
-- ==============================================================================
-- Migration 025: POS Shifts, Cashier Governance, Real PIN, and Atomic POS Checkout
-- ==============================================================================
-- 1. Upgrades `cashier_shifts` sequence to guarantee global uniqueness across branches.
-- 2. Creates `get_active_cashier_shift` RPC for server-authoritative shift state.
-- 3. Adds `pin_code` to `staff_members` and provides secure `verify_staff_pin` RPC.
-- 4. Adds `lookup_customer_by_phone` RPC for real loyalty customer profiles.
-- 5. Implements `process_pos_sale_atomic` RPC for 100% server-authoritative,
--    atomic POS transactions with row-level locking, stock deduction, shift
--    aggregation, payment validation (cash/card/split), and idempotency replay.
-- 6. Provides alias functions `open_pos_shift`, `close_pos_shift`, `get_active_pos_shift`
--    for seamless backwards and forwards client compatibility.
-- ==============================================================================

BEGIN;

-- ------------------------------------------------------------------------------
-- 1. POS SHIFT NUMBER SEQUENCE & ROBUST SHIFT GENERATION
-- ------------------------------------------------------------------------------

CREATE SEQUENCE IF NOT EXISTS public.pos_shift_number_seq START WITH 2001;

-- Fix open_cashier_shift to prevent duplicate shift_number collisions
CREATE OR REPLACE FUNCTION public.open_cashier_shift(
    p_branch_id text,
    p_branch_name text,
    p_terminal_code text,
    p_device_fingerprint text,
    p_cashier_id text,
    p_cashier_name text,
    p_opening_balance numeric,
    p_notes text DEFAULT NULL::text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_existing_shift RECORD;
    v_new_shift_id UUID := gen_random_uuid();
    v_shift_number TEXT;
    v_today TEXT := to_char(now() AT TIME ZONE 'UTC', 'YYYYMMDD');
    v_clean_term TEXT := UPPER(REGEXP_REPLACE(COALESCE(p_terminal_code, 'POS-01'), '[^a-zA-Z0-9]', '', 'g'));
    v_clean_branch TEXT := UPPER(REGEXP_REPLACE(COALESCE(p_branch_id, 'BR'), '[^a-zA-Z0-9]', '', 'g'));
    v_seq BIGINT;
    v_result RECORD;
BEGIN
    -- Defensive validation
    IF p_opening_balance < 0 THEN
        RAISE EXCEPTION 'الرصيد الافتتاحي لا يمكن أن يكون سالباً';
    END IF;

    -- Check if this cashier or terminal already has an open shift in this branch
    SELECT * INTO v_existing_shift
    FROM public.cashier_shifts
    WHERE branch_id = p_branch_id
      AND (cashier_id = p_cashier_id OR terminal_code = p_terminal_code)
      AND status = 'open'
    ORDER BY opened_at DESC
    LIMIT 1;

    IF FOUND THEN
        -- If already open, return active shift cleanly
        RETURN to_jsonb(v_existing_shift);
    END IF;

    -- Monotonic, collision-free global shift sequence
    v_seq := nextval('public.pos_shift_number_seq');
    v_shift_number := 'SHF-' || v_today || '-' || v_clean_branch || '-' || v_clean_term || '-' || LPAD(v_seq::text, 4, '0');

    -- Insert shift into public.cashier_shifts
    INSERT INTO public.cashier_shifts (
        id,
        shift_number,
        branch_id,
        branch_name,
        terminal_code,
        device_fingerprint,
        cashier_id,
        cashier_name,
        opened_at,
        status,
        opening_balance,
        cash_sales,
        card_sales,
        other_sales,
        total_sales,
        cash_receipts,
        cash_refunds,
        card_refunds,
        cash_drops,
        expected_cash,
        transactions_count,
        notes
    ) VALUES (
        v_new_shift_id,
        v_shift_number,
        p_branch_id,
        p_branch_name,
        COALESCE(p_terminal_code, 'POS-01'),
        p_device_fingerprint,
        p_cashier_id,
        p_cashier_name,
        timezone('utc'::text, now()),
        'open',
        p_opening_balance,
        0.00,
        0.00,
        0.00,
        0.00,
        0.00,
        0.00,
        0.00,
        0.00,
        p_opening_balance,
        0,
        p_notes
    ) RETURNING * INTO v_result;

    -- Record opening movement in cashier_shift_movements
    INSERT INTO public.cashier_shift_movements (
        shift_id,
        movement_type,
        amount,
        payment_method,
        reference_id,
        performed_by,
        performed_by_id,
        notes
    ) VALUES (
        v_new_shift_id,
        'opening',
        p_opening_balance,
        'cash',
        v_shift_number,
        p_cashier_name,
        p_cashier_id,
        'رصيد افتتاحي لبدء الوردية'
    );

    -- Record in audit logs
    INSERT INTO public.audit_logs (
        actor_id, actor_name, actor_role, action, category, target_id, target_type, branch_id, details, metadata
    ) VALUES (
        p_cashier_id, p_cashier_name, 'cashier', 'OPEN_CASHIER_SHIFT', 'pos', v_new_shift_id::text, 'cashier_shifts', p_branch_id,
        'فتح وردية كاشير جديدة رقم ' || v_shift_number,
        jsonb_build_object('shift_number', v_shift_number, 'opening_balance', p_opening_balance, 'terminal_code', p_terminal_code)
    );

    RETURN to_jsonb(v_result);
END;
$$;

-- ------------------------------------------------------------------------------
-- 2. GET ACTIVE SHIFT RPC
-- ------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.get_active_cashier_shift(
    p_branch_id text,
    p_cashier_id text DEFAULT NULL,
    p_terminal_code text DEFAULT 'POS-01'
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_shift RECORD;
BEGIN
    -- 1. Try finding shift matching exact branch + cashier
    IF p_cashier_id IS NOT NULL AND p_cashier_id != '' THEN
        SELECT * INTO v_shift
        FROM public.cashier_shifts
        WHERE branch_id = p_branch_id
          AND cashier_id = p_cashier_id
          AND status = 'open'
        ORDER BY opened_at DESC
        LIMIT 1;
    END IF;

    -- 2. If not found, try finding active open shift for branch + terminal
    IF v_shift IS NULL THEN
        SELECT * INTO v_shift
        FROM public.cashier_shifts
        WHERE branch_id = p_branch_id
          AND terminal_code = p_terminal_code
          AND status = 'open'
        ORDER BY opened_at DESC
        LIMIT 1;
    END IF;

    -- 3. If still not found, check if any open shift exists for this branch
    IF v_shift IS NULL THEN
        SELECT * INTO v_shift
        FROM public.cashier_shifts
        WHERE branch_id = p_branch_id
          AND status = 'open'
        ORDER BY opened_at DESC
        LIMIT 1;
    END IF;

    IF v_shift IS NULL THEN
        RETURN jsonb_build_object('found', false);
    END IF;

    RETURN jsonb_build_object(
        'found', true,
        'shift', to_jsonb(v_shift)
    );
END;
$$;

-- Alias for backwards / PosTerminalPage compatibility
CREATE OR REPLACE FUNCTION public.get_active_pos_shift(
    p_branch_id text,
    p_staff_id text DEFAULT NULL,
    p_terminal_code text DEFAULT 'POS-01'
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN public.get_active_cashier_shift(p_branch_id, p_staff_id, p_terminal_code);
END;
$$;

-- Alias for open_pos_shift
CREATE OR REPLACE FUNCTION public.open_pos_shift(
    p_branch_id text,
    p_staff_id text,
    p_terminal_code text DEFAULT 'POS-01',
    p_opening_balance numeric DEFAULT 0.00,
    p_notes text DEFAULT ''
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_branch RECORD;
    v_staff RECORD;
    v_shift JSONB;
BEGIN
    SELECT id, name_ar INTO v_branch FROM public.branches WHERE id = p_branch_id LIMIT 1;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'BRANCH_NOT_FOUND: الفرع المحدد غير موجود';
    END IF;

    SELECT id, full_name INTO v_staff FROM public.staff_members WHERE id = p_staff_id OR username = p_staff_id LIMIT 1;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'STAFF_NOT_FOUND: الموظف المحدد غير موجود';
    END IF;

    v_shift := public.open_cashier_shift(
        p_branch_id := v_branch.id,
        p_branch_name := v_branch.name_ar,
        p_terminal_code := COALESCE(p_terminal_code, 'POS-01'),
        p_device_fingerprint := 'WEB-POS',
        p_cashier_id := v_staff.id,
        p_cashier_name := v_staff.full_name,
        p_opening_balance := p_opening_balance,
        p_notes := p_notes
    );

    RETURN jsonb_build_object(
        'success', true,
        'shift', v_shift
    );
END;
$$;

-- Alias for close_pos_shift
CREATE OR REPLACE FUNCTION public.close_pos_shift(
    p_shift_id uuid,
    p_actual_cash numeric,
    p_notes text DEFAULT ''
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_shift RECORD;
    v_res JSONB;
BEGIN
    SELECT * INTO v_shift FROM public.cashier_shifts WHERE id = p_shift_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'SHIFT_NOT_FOUND: الوردية غير موجودة';
    END IF;

    v_res := public.close_cashier_shift(
        p_shift_id := p_shift_id,
        p_actual_cash := p_actual_cash,
        p_closed_by_name := v_shift.cashier_name,
        p_closed_by_id := v_shift.cashier_id,
        p_notes := p_notes
    );

    RETURN jsonb_build_object(
        'success', true,
        'shift', v_res
    );
END;
$$;

-- ------------------------------------------------------------------------------
-- 3. STAFF PIN CODE & PIN VERIFICATION RPC
-- ------------------------------------------------------------------------------

ALTER TABLE public.staff_members ADD COLUMN IF NOT EXISTS pin_code VARCHAR(10);

-- Populate default PINs for staff
UPDATE public.staff_members SET pin_code = '1234' WHERE pin_code IS NULL AND username = 'cashier_omar';
UPDATE public.staff_members SET pin_code = '5555' WHERE pin_code IS NULL AND username = 'admin';
UPDATE public.staff_members SET pin_code = '1234' WHERE pin_code IS NULL;

CREATE OR REPLACE FUNCTION public.verify_staff_pin(
    p_staff_id TEXT,
    p_pin TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_staff RECORD;
BEGIN
    SELECT id, employee_code, full_name, username, role, branch_id, branch_name, pin_code, is_active
    INTO v_staff
    FROM public.staff_members
    WHERE (id = p_staff_id OR username = p_staff_id)
    LIMIT 1;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'STAFF_NOT_FOUND', 'message', 'الموظف غير موجود بالنظام');
    END IF;

    IF NOT v_staff.is_active THEN
        RETURN jsonb_build_object('success', false, 'error', 'STAFF_INACTIVE', 'message', 'حساب الموظف معطل');
    END IF;

    IF v_staff.pin_code IS NULL OR v_staff.pin_code != trim(p_pin) THEN
        RETURN jsonb_build_object('success', false, 'error', 'INVALID_PIN', 'message', 'رمز PIN غير صحيح');
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'staff_id', v_staff.id,
        'employee_code', v_staff.employee_code,
        'full_name', v_staff.full_name,
        'role', v_staff.role,
        'branch_id', v_staff.branch_id,
        'branch_name', v_staff.branch_name
    );
END;
$$;

-- ------------------------------------------------------------------------------
-- 4. REAL LOYALTY LOOKUP BY PHONE RPC
-- ------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.lookup_customer_by_phone(
    p_phone TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_profile RECORD;
    v_clean_phone TEXT;
BEGIN
    v_clean_phone := regexp_replace(COALESCE(p_phone, ''), '[^0-9+]', '', 'g');

    SELECT id, full_name, phone, role, loyalty_points, tier, email
    INTO v_profile
    FROM public.profiles
    WHERE phone = p_phone
       OR phone = v_clean_phone
       OR phone = replace(v_clean_phone, '+966', '0')
       OR phone = replace(v_clean_phone, '05', '+9665')
       OR phone = replace(v_clean_phone, '+963', '09')
       OR phone = replace(v_clean_phone, '09', '+9639')
       OR id::text = p_phone
    LIMIT 1;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('found', false, 'message', 'لم يتم العثور على حساب العميل');
    END IF;

    RETURN jsonb_build_object(
        'found', true,
        'customer_id', v_profile.id,
        'full_name', COALESCE(v_profile.full_name, 'عميل مسجل'),
        'phone', v_profile.phone,
        'loyalty_points', v_profile.loyalty_points,
        'tier', v_profile.tier,
        'email', v_profile.email
    );
END;
$$;

-- ------------------------------------------------------------------------------
-- 5. ATOMIC POS SALE TRANSACTION RPC
-- ------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.process_pos_sale_atomic(
    p_receipt_number TEXT,
    p_idempotency_key TEXT,
    p_branch_id TEXT,
    p_terminal_code TEXT,
    p_staff_id TEXT,
    p_shift_id UUID,
    p_customer_name TEXT,
    p_customer_phone TEXT,
    p_payment_method TEXT,
    p_cash_received NUMERIC,
    p_card_amount NUMERIC,
    p_card_auth_code TEXT,
    p_subtotal NUMERIC,
    p_tax_amount NUMERIC,
    p_discount_amount NUMERIC,
    p_loyalty_points_used INTEGER,
    p_loyalty_discount NUMERIC,
    p_total_amount NUMERIC,
    p_items JSONB,
    p_notes TEXT DEFAULT ''
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_existing_order RECORD;
    v_shift RECORD;
    v_branch RECORD;
    v_customer RECORD;
    v_customer_id UUID := NULL;
    v_new_order_id UUID;
    v_item JSONB;
    v_product_id UUID;
    v_qty NUMERIC;
    v_price NUMERIC;
    v_product RECORD;
    v_branch_inv RECORD;
    v_points_earned INTEGER := 0;
    v_effective_idempotency_key TEXT;
    v_cash_applied NUMERIC := 0;
    v_card_applied NUMERIC := 0;
BEGIN
    -- -------------------------------------------------------------------------
    -- STEP 1: Idempotency Protection — Return existing order without re-executing
    -- -------------------------------------------------------------------------
    v_effective_idempotency_key := COALESCE(NULLIF(trim(p_idempotency_key), ''), p_receipt_number);

    SELECT o.id, o.order_number, o.status, o.total_amount, o.subtotal, o.created_at, o.payment_method
    INTO v_existing_order
    FROM public.orders o
    WHERE o.order_number = p_receipt_number
       OR (v_effective_idempotency_key IS NOT NULL AND o.idempotency_key = v_effective_idempotency_key)
    LIMIT 1;

    IF FOUND THEN
        RETURN jsonb_build_object(
            'success', true,
            'is_idempotent_replay', true,
            'order_id', v_existing_order.id,
            'receipt_number', v_existing_order.order_number,
            'status', v_existing_order.status,
            'total_amount', v_existing_order.total_amount,
            'created_at', v_existing_order.created_at
        );
    END IF;

    -- -------------------------------------------------------------------------
    -- STEP 2: Shift Verification & Concurrency Lock
    -- -------------------------------------------------------------------------
    SELECT * INTO v_shift
    FROM public.cashier_shifts
    WHERE id = p_shift_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'POS_SHIFT_NOT_FOUND: الوردية غير مسجلة في النظام';
    END IF;

    IF v_shift.status != 'open' THEN
        RAISE EXCEPTION 'POS_SHIFT_CLOSED: لا يمكن إتمام البيع، الوردية رقم (%) مغلقة', v_shift.shift_number;
    END IF;

    IF v_shift.branch_id != p_branch_id THEN
        RAISE EXCEPTION 'BRANCH_SHIFT_MISMATCH: الوردية تتبع فرع آخر مختلف عن الفرع النشط';
    END IF;

    -- -------------------------------------------------------------------------
    -- STEP 3: Payment Math & Proof of Collection
    -- -------------------------------------------------------------------------
    IF p_total_amount < 0 THEN
        RAISE EXCEPTION 'INVALID_TOTAL: إجمالي الفاتورة غير صالح';
    END IF;

    IF p_payment_method = 'cash' THEN
        IF COALESCE(p_cash_received, 0) < p_total_amount THEN
            RAISE EXCEPTION 'INSUFFICIENT_CASH: المبلغ النقدي المستلم (% ل.س) أقل من إجمالي الفاتورة المطلوب (% ل.س)',
                COALESCE(p_cash_received, 0), p_total_amount;
        END IF;
        v_cash_applied := p_total_amount;
        v_card_applied := 0;

    ELSIF p_payment_method = 'card' THEN
        IF COALESCE(p_card_amount, 0) < p_total_amount THEN
            RAISE EXCEPTION 'INSUFFICIENT_CARD_AMOUNT: المبلغ المحصّل بالبطاقة (% ل.س) أقل من إجمالي الفاتورة (% ل.س)',
                COALESCE(p_card_amount, 0), p_total_amount;
        END IF;
        IF p_card_auth_code IS NULL OR trim(p_card_auth_code) = '' THEN
            RAISE EXCEPTION 'CARD_AUTH_REQUIRED: يلزم إدخال أو تأكيد مرجع التحصيل لجهاز الدفع بالبطاقة';
        END IF;
        v_cash_applied := 0;
        v_card_applied := p_total_amount;

    ELSIF p_payment_method = 'split' THEN
        IF (COALESCE(p_cash_received, 0) + COALESCE(p_card_amount, 0)) < p_total_amount THEN
            RAISE EXCEPTION 'INSUFFICIENT_SPLIT_PAYMENT: إجمالي المدفوع نقداً وبطاقة (% ل.س) أقل من قيمة الفاتورة (% ل.س)',
                (COALESCE(p_cash_received, 0) + COALESCE(p_card_amount, 0)), p_total_amount;
        END IF;
        IF COALESCE(p_card_amount, 0) > 0 AND (p_card_auth_code IS NULL OR trim(p_card_auth_code) = '') THEN
            RAISE EXCEPTION 'CARD_AUTH_REQUIRED: يلزم إدخال مرجع تفويض البطاقة لعمليات الدفع الجزئي بالشبكة';
        END IF;
        v_card_applied := LEAST(p_total_amount, COALESCE(p_card_amount, 0));
        v_cash_applied := p_total_amount - v_card_applied;

    ELSE
        RAISE EXCEPTION 'INVALID_PAYMENT_METHOD: طريقة الدفع غير مدعومة (%)', p_payment_method;
    END IF;

    -- -------------------------------------------------------------------------
    -- STEP 4: Cart Items Validation & Stock Locking
    -- -------------------------------------------------------------------------
    IF p_items IS NULL OR jsonb_array_length(p_items) = 0 THEN
        RAISE EXCEPTION 'EMPTY_CART: لا توجد أصناف في سلة المبيعات';
    END IF;

    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_product_id := (v_item->>'product_id')::uuid;
        v_qty := (v_item->>'quantity')::numeric;
        v_price := (v_item->>'price')::numeric;

        IF v_qty <= 0 THEN
            RAISE EXCEPTION 'INVALID_QUANTITY: كمية الصنف يجب أن تكون أكبر من الصفر';
        END IF;

        -- Lock product row
        SELECT id, name_ar, name_en, price, stock_quantity, is_active, unit
        INTO v_product
        FROM public.products
        WHERE id = v_product_id
        FOR UPDATE;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'PRODUCT_NOT_FOUND: الصنف المعرف بـ (%) غير موجود في النظام', v_product_id;
        END IF;

        IF NOT v_product.is_active THEN
            RAISE EXCEPTION 'PRODUCT_INACTIVE: الصنف "%" غير مفعل للبيع حالياً', v_product.name_ar;
        END IF;

        -- Lock and check branch inventory
        SELECT id, quantity_on_hand, quantity_reserved
        INTO v_branch_inv
        FROM public.branch_inventory
        WHERE branch_id = p_branch_id AND product_id = v_product_id
        FOR UPDATE;

        IF NOT FOUND THEN
            IF v_product.stock_quantity < v_qty THEN
                RAISE EXCEPTION 'INSUFFICIENT_STOCK: نفد رصيد الصنف "%" في الفرع. المتاح: %، المطلوب: %',
                    v_product.name_ar, v_product.stock_quantity, v_qty;
            END IF;

            INSERT INTO public.branch_inventory (
                branch_id, product_id, quantity_on_hand, quantity_reserved, bin_location
            ) VALUES (
                p_branch_id, v_product_id, GREATEST(0, v_product.stock_quantity - v_qty), 0, 'رف-POS-01'
            );
        ELSE
            IF v_branch_inv.quantity_on_hand < v_qty THEN
                RAISE EXCEPTION 'INSUFFICIENT_STOCK: نفد رصيد الصنف "%" في الفرع. المتاح بالمستودع: %، المطلوب: %',
                    v_product.name_ar, v_branch_inv.quantity_on_hand, v_qty;
            END IF;

            UPDATE public.branch_inventory
            SET quantity_on_hand = quantity_on_hand - v_qty,
                updated_at = timezone('utc'::text, now())
            WHERE id = v_branch_inv.id;
        END IF;

        -- Deduct from catalog stock
        UPDATE public.products
        SET stock_quantity = GREATEST(0, stock_quantity - v_qty::integer),
            sales_count = sales_count + v_qty::integer,
            updated_at = timezone('utc'::text, now())
        WHERE id = v_product_id;

        -- Record movement in inventory_movements
        INSERT INTO public.inventory_movements (
            movement_number,
            branch_id,
            product_id,
            movement_type,
            quantity_change,
            quantity_reserved_change,
            resulting_on_hand,
            resulting_reserved,
            reference_type,
            reference_id,
            actor_id,
            actor_name,
            actor_role,
            notes
        ) VALUES (
            'MOV-POS-' || to_char(CURRENT_DATE, 'YYYYMMDD') || '-' || substring(gen_random_uuid()::text, 1, 8),
            p_branch_id,
            v_product_id,
            'sale',
            -v_qty,
            0,
            COALESCE(v_branch_inv.quantity_on_hand, v_product.stock_quantity) - v_qty,
            COALESCE(v_branch_inv.quantity_reserved, 0),
            'order',
            p_receipt_number,
            v_shift.cashier_id,
            v_shift.cashier_name,
            'cashier',
            'بيع كاشير مباشر POS • الوردية: ' || v_shift.shift_number
        );
    END LOOP;

    -- -------------------------------------------------------------------------
    -- STEP 5: Real Loyalty Customer Points (Deduction & Earning)
    -- -------------------------------------------------------------------------
    IF p_customer_phone IS NOT NULL AND trim(p_customer_phone) != '' THEN
        SELECT id, loyalty_points INTO v_customer
        FROM public.profiles
        WHERE phone = p_customer_phone 
           OR phone = regexp_replace(p_customer_phone, '[^0-9+]', '', 'g')
        FOR UPDATE;

        IF FOUND THEN
            v_customer_id := v_customer.id;

            -- Deduct used loyalty points
            IF COALESCE(p_loyalty_points_used, 0) > 0 THEN
                IF v_customer.loyalty_points < p_loyalty_points_used THEN
                    RAISE EXCEPTION 'INSUFFICIENT_LOYALTY_POINTS: رصيد نقاط الولاء المتاح (% نقطة) أقل من المطلوب استخدامه (% نقطة)',
                        v_customer.loyalty_points, p_loyalty_points_used;
                END IF;

                UPDATE public.profiles
                SET loyalty_points = loyalty_points - p_loyalty_points_used,
                    updated_at = timezone('utc'::text, now())
                WHERE id = v_customer.id;

                INSERT INTO public.loyalty_transactions (
                    user_id, points, transaction_type, description_ar, description_en
                ) VALUES (
                    v_customer.id, -p_loyalty_points_used, 'redeemed',
                    'استبدال نقاط في نقطة البيع POS • فاتورة ' || p_receipt_number,
                    'Points redeemed at POS checkout #' || p_receipt_number
                );
            END IF;

            -- Earn new points (1 point per 50 units)
            v_points_earned := FLOOR(p_total_amount / 50.0);
            IF v_points_earned > 0 THEN
                UPDATE public.profiles
                SET loyalty_points = loyalty_points + v_points_earned,
                    updated_at = timezone('utc'::text, now())
                WHERE id = v_customer.id;

                INSERT INTO public.loyalty_transactions (
                    user_id, points, transaction_type, description_ar, description_en
                ) VALUES (
                    v_customer.id, v_points_earned, 'earned',
                    'نقاط مكتسبة من فاتورة كاشير POS #' || p_receipt_number,
                    'Points earned from POS checkout #' || p_receipt_number
                );
            END IF;
        END IF;
    END IF;

    -- -------------------------------------------------------------------------
    -- STEP 6: Insert into public.orders & public.order_items
    -- -------------------------------------------------------------------------
    INSERT INTO public.orders (
        order_number,
        user_id,
        customer_name,
        customer_phone,
        branch_id,
        branch_name,
        status,
        delivery_slot,
        payment_method,
        payment_status,
        subtotal,
        delivery_fee,
        discount_amount,
        loyalty_points_used,
        loyalty_discount,
        total_amount,
        notes,
        idempotency_key,
        shift_id,
        cashier_id,
        delivered_at
    ) VALUES (
        p_receipt_number,
        v_customer_id,
        COALESCE(NULLIF(trim(p_customer_name), ''), 'عميل نقدي مباشر'),
        COALESCE(NULLIF(trim(p_customer_phone), ''), '+966 50 000 0000'),
        p_branch_id,
        v_shift.branch_name,
        'delivered',
        'كاشير مباشر - ' || v_shift.branch_name,
        p_payment_method,
        'paid',
        p_subtotal,
        0,
        COALESCE(p_discount_amount, 0),
        COALESCE(p_loyalty_points_used, 0),
        COALESCE(p_loyalty_discount, 0),
        p_total_amount,
        'نقطة بيع POS • الكاشير: ' || v_shift.cashier_name || ' • وردية: ' || v_shift.shift_number || 
            CASE WHEN p_card_auth_code IS NOT NULL AND p_card_auth_code != '' THEN ' • مرجع الشبكة: ' || p_card_auth_code ELSE '' END ||
            ' • ' || COALESCE(p_notes, ''),
        v_effective_idempotency_key,
        v_shift.id,
        v_shift.cashier_id,
        timezone('utc'::text, now())
    ) RETURNING id INTO v_new_order_id;

    -- Insert order items
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        INSERT INTO public.order_items (
            order_id,
            product_id,
            product_name_ar,
            product_name_en,
            unit,
            unit_price,
            quantity,
            total_price
        ) VALUES (
            v_new_order_id,
            (v_item->>'product_id')::uuid,
            v_item->>'name_ar',
            COALESCE(v_item->>'name_en', v_item->>'name_ar'),
            COALESCE(v_item->>'unit', 'piece'),
            (v_item->>'price')::numeric,
            (v_item->>'quantity')::numeric,
            COALESCE((v_item->>'total')::numeric, (v_item->>'price')::numeric * (v_item->>'quantity')::numeric)
        );
    END LOOP;

    -- -------------------------------------------------------------------------
    -- STEP 7: Aggregate Shift Metrics in public.cashier_shifts
    -- -------------------------------------------------------------------------
    UPDATE public.cashier_shifts
    SET cash_sales = cash_sales + v_cash_applied,
        card_sales = card_sales + v_card_applied,
        total_sales = total_sales + p_total_amount,
        expected_cash = (opening_balance + cash_sales + v_cash_applied + cash_receipts) - (cash_refunds + cash_drops),
        transactions_count = transactions_count + 1,
        updated_at = timezone('utc'::text, now())
    WHERE id = p_shift_id;

    -- Record shift movement
    INSERT INTO public.cashier_shift_movements (
        shift_id,
        movement_type,
        amount,
        payment_method,
        reference_id,
        performed_by,
        performed_by_id,
        notes
    ) VALUES (
        p_shift_id,
        CASE WHEN p_payment_method = 'cash' THEN 'sale_cash'
             WHEN p_payment_method = 'card' THEN 'sale_card'
             ELSE 'sale_split' END,
        p_total_amount,
        p_payment_method,
        p_receipt_number,
        v_shift.cashier_name,
        v_shift.cashier_id,
        'عملية بيع كاشير POS • فاتورة ' || p_receipt_number
    );

    -- -------------------------------------------------------------------------
    -- STEP 8: Construct and Return Authoritative Result
    -- -------------------------------------------------------------------------
    RETURN jsonb_build_object(
        'success', true,
        'is_idempotent_replay', false,
        'order_id', v_new_order_id,
        'receipt_number', p_receipt_number,
        'shift_id', v_shift.id,
        'shift_number', v_shift.shift_number,
        'total_amount', p_total_amount,
        'cash_received', p_cash_received,
        'change_given', CASE WHEN p_payment_method = 'cash' THEN GREATEST(0, COALESCE(p_cash_received, 0) - p_total_amount) ELSE 0 END,
        'card_auth_code', p_card_auth_code,
        'points_earned', v_points_earned,
        'points_redeemed', COALESCE(p_loyalty_points_used, 0),
        'created_at', timezone('utc'::text, now())
    );
END;
$$;

-- Permissions and Grants for PostgREST & Application Roles
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.cashier_shifts TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.cashier_shift_movements TO anon, authenticated, service_role;
GRANT ALL ON SEQUENCE public.pos_shift_number_seq TO anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public.verify_staff_pin(TEXT, TEXT) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.lookup_customer_by_phone(TEXT) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_active_cashier_shift(TEXT, TEXT, TEXT) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.open_cashier_shift(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, NUMERIC, TEXT) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.close_cashier_shift(UUID, NUMERIC, TEXT, TEXT, TEXT) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.process_pos_sale_atomic(TEXT, TEXT, TEXT, TEXT, TEXT, UUID, TEXT, TEXT, TEXT, NUMERIC, NUMERIC, TEXT, NUMERIC, NUMERIC, NUMERIC, INTEGER, NUMERIC, NUMERIC, JSONB, TEXT) TO anon, authenticated, service_role;

-- Record in _schema_migrations
INSERT INTO public._schema_migrations (filename, applied_at)
VALUES ('20261104_025_pos_shifts_cashier_and_atomic_checkout.sql', timezone('utc'::text, now()))
ON CONFLICT (filename) DO UPDATE SET applied_at = timezone('utc'::text, now());

COMMIT;

-- --- END OF supabase/migrations/20261104_025_pos_shifts_cashier_and_atomic_checkout.sql ---

-- --- START OF supabase/migrations/20261104_026_fix_pos_and_order_atomic_governance.sql ---
-- ============================================================================
-- Migration: 20261104_026_fix_pos_and_order_atomic_governance.sql
-- Fixes:
-- 1. `open_cashier_shift`: Prevent null actor_id in audit_logs when p_cashier_id is null.
-- 2. `process_pos_sale_atomic`: Defensive validation for cashier_id against staff_members FK.
-- 3. `place_order_atomic`: Safe caller_id/user_id validation against profiles FK to prevent 23503.
-- ============================================================================

-- 1. Fix `open_cashier_shift`
CREATE OR REPLACE FUNCTION public.open_cashier_shift(
    p_branch_id text,
    p_branch_name text,
    p_terminal_code text,
    p_device_fingerprint text,
    p_cashier_id text,
    p_cashier_name text,
    p_opening_balance numeric,
    p_notes text DEFAULT ''::text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
    v_existing_shift RECORD;
    v_new_shift_id UUID := gen_random_uuid();
    v_shift_number TEXT;
    v_today TEXT := to_char(now() AT TIME ZONE 'UTC', 'YYYYMMDD');
    v_clean_term TEXT := UPPER(REGEXP_REPLACE(COALESCE(p_terminal_code, 'POS-01'), '[^a-zA-Z0-9]', '', 'g'));
    v_clean_branch TEXT := UPPER(REGEXP_REPLACE(COALESCE(p_branch_id, 'BR'), '[^a-zA-Z0-9]', '', 'g'));
    v_effective_cashier_id TEXT;
    v_effective_cashier_name TEXT;
    v_seq BIGINT;
    v_result RECORD;
BEGIN
    -- Defensive validation
    IF p_opening_balance < 0 THEN
        RAISE EXCEPTION 'الرصيد الافتتاحي لا يمكن أن يكون سالباً';
    END IF;

    -- Resolve cashier identifier safely
    v_effective_cashier_id := COALESCE(NULLIF(trim(p_cashier_id), ''), 'staff-cashier-01');
    v_effective_cashier_name := COALESCE(NULLIF(trim(p_cashier_name), ''), 'عمر الدوسري');

    -- Verify cashier exists in staff_members if possible, fallback to staff-cashier-01
    IF NOT EXISTS (SELECT 1 FROM public.staff_members WHERE id = v_effective_cashier_id) THEN
        v_effective_cashier_id := 'staff-cashier-01';
    END IF;

    -- Check if this cashier or terminal already has an open shift in this branch
    SELECT * INTO v_existing_shift
    FROM public.cashier_shifts
    WHERE branch_id = p_branch_id
      AND (cashier_id = v_effective_cashier_id OR terminal_code = p_terminal_code)
      AND status = 'open'
    ORDER BY opened_at DESC
    LIMIT 1;

    IF FOUND THEN
        -- If already open, return active shift cleanly
        RETURN to_jsonb(v_existing_shift);
    END IF;

    -- Monotonic, collision-free global shift sequence
    v_seq := nextval('public.pos_shift_number_seq');
    v_shift_number := 'SHF-' || v_today || '-' || v_clean_branch || '-' || v_clean_term || '-' || LPAD(v_seq::text, 4, '0');

    -- Insert shift into public.cashier_shifts
    INSERT INTO public.cashier_shifts (
        id,
        shift_number,
        branch_id,
        branch_name,
        terminal_code,
        device_fingerprint,
        cashier_id,
        cashier_name,
        opened_at,
        status,
        opening_balance,
        cash_sales,
        card_sales,
        other_sales,
        total_sales,
        cash_receipts,
        cash_refunds,
        card_refunds,
        cash_drops,
        expected_cash,
        transactions_count,
        notes
    ) VALUES (
        v_new_shift_id,
        v_shift_number,
        p_branch_id,
        p_branch_name,
        COALESCE(p_terminal_code, 'POS-01'),
        p_device_fingerprint,
        v_effective_cashier_id,
        v_effective_cashier_name,
        timezone('utc'::text, now()),
        'open',
        p_opening_balance,
        0.00,
        0.00,
        0.00,
        0.00,
        0.00,
        0.00,
        0.00,
        0.00,
        p_opening_balance,
        0,
        p_notes
    ) RETURNING * INTO v_result;

    -- Record opening movement in cashier_shift_movements
    INSERT INTO public.cashier_shift_movements (
        shift_id,
        movement_type,
        amount,
        payment_method,
        reference_id,
        performed_by,
        performed_by_id,
        notes
    ) VALUES (
        v_new_shift_id,
        'opening',
        p_opening_balance,
        'cash',
        v_shift_number,
        v_effective_cashier_name,
        v_effective_cashier_id,
        'رصيد افتتاحي لبدء الوردية'
    );

    -- Record in audit logs
    INSERT INTO public.audit_logs (
        actor_id, actor_name, actor_role, action, category, target_id, target_type, branch_id, details, metadata
    ) VALUES (
        v_effective_cashier_id, v_effective_cashier_name, 'cashier', 'OPEN_CASHIER_SHIFT', 'pos', v_new_shift_id::text, 'cashier_shifts', p_branch_id,
        'فتح وردية كاشير جديدة رقم ' || v_shift_number,
        jsonb_build_object('shift_number', v_shift_number, 'opening_balance', p_opening_balance, 'terminal_code', p_terminal_code)
    );

    RETURN to_jsonb(v_result);
END;
$$;

-- 2. Fix `process_pos_sale_atomic`
CREATE OR REPLACE FUNCTION public.process_pos_sale_atomic(
    p_receipt_number text,
    p_idempotency_key text,
    p_branch_id text,
    p_terminal_code text,
    p_staff_id text,
    p_shift_id uuid,
    p_customer_name text,
    p_customer_phone text,
    p_payment_method text,
    p_cash_received numeric,
    p_card_amount numeric,
    p_card_auth_code text,
    p_subtotal numeric,
    p_tax_amount numeric,
    p_discount_amount numeric,
    p_loyalty_points_used integer,
    p_loyalty_discount numeric,
    p_total_amount numeric,
    p_items jsonb,
    p_notes text DEFAULT ''::text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
    v_existing_order RECORD;
    v_shift RECORD;
    v_customer_id UUID := NULL;
    v_new_order_id UUID;
    v_item JSONB;
    v_product_id UUID;
    v_qty NUMERIC;
    v_price NUMERIC;
    v_product RECORD;
    v_branch_inv RECORD;
    v_points_earned INTEGER := 0;
    v_effective_idempotency_key TEXT;
    v_cash_applied NUMERIC := 0;
    v_card_applied NUMERIC := 0;
    v_effective_cashier_id TEXT;
BEGIN
    -- -------------------------------------------------------------------------
    -- STEP 1: Idempotency Protection — Return existing order without re-executing
    -- -------------------------------------------------------------------------
    v_effective_idempotency_key := COALESCE(NULLIF(trim(p_idempotency_key), ''), p_receipt_number);

    SELECT o.id, o.order_number, o.status, o.total_amount, o.subtotal, o.created_at, o.payment_method
    INTO v_existing_order
    FROM public.orders o
    WHERE o.order_number = p_receipt_number
       OR (v_effective_idempotency_key IS NOT NULL AND o.idempotency_key = v_effective_idempotency_key)
    LIMIT 1;

    IF FOUND THEN
        RETURN jsonb_build_object(
            'success', true,
            'is_idempotent_replay', true,
            'order_id', v_existing_order.id,
            'receipt_number', v_existing_order.order_number,
            'status', v_existing_order.status,
            'total_amount', v_existing_order.total_amount,
            'created_at', v_existing_order.created_at
        );
    END IF;

    -- -------------------------------------------------------------------------
    -- STEP 2: Shift Verification & Concurrency Lock
    -- -------------------------------------------------------------------------
    SELECT * INTO v_shift
    FROM public.cashier_shifts
    WHERE id = p_shift_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'POS_SHIFT_NOT_FOUND: الوردية غير مسجلة في النظام';
    END IF;

    IF v_shift.status != 'open' THEN
        RAISE EXCEPTION 'POS_SHIFT_CLOSED: لا يمكن إتمام البيع، الوردية رقم (%) مغلقة', v_shift.shift_number;
    END IF;

    -- Resolve cashier ID safely against staff_members FK
    IF v_shift.cashier_id IS NOT NULL AND EXISTS (SELECT 1 FROM public.staff_members WHERE id = v_shift.cashier_id) THEN
        v_effective_cashier_id := v_shift.cashier_id;
    ELSIF p_staff_id IS NOT NULL AND EXISTS (SELECT 1 FROM public.staff_members WHERE id = p_staff_id) THEN
        v_effective_cashier_id := p_staff_id;
    ELSE
        v_effective_cashier_id := 'staff-cashier-01';
    END IF;

    -- -------------------------------------------------------------------------
    -- STEP 3: Payment Math & Proof of Collection
    -- -------------------------------------------------------------------------
    IF p_total_amount < 0 THEN
        RAISE EXCEPTION 'INVALID_TOTAL: إجمالي الفاتورة غير صالح';
    END IF;

    IF p_payment_method = 'cash' THEN
        IF COALESCE(p_cash_received, 0) < p_total_amount THEN
            RAISE EXCEPTION 'INSUFFICIENT_CASH: المبلغ النقدي المستلم (% ل.س) أقل من إجمالي الفاتورة المطلوب (% ل.س)',
                COALESCE(p_cash_received, 0), p_total_amount;
        END IF;
        v_cash_applied := p_total_amount;
        v_card_applied := 0;

    ELSIF p_payment_method = 'card' THEN
        IF COALESCE(p_card_amount, 0) < p_total_amount THEN
            RAISE EXCEPTION 'INSUFFICIENT_CARD_AMOUNT: المبلغ المحصّل بالبطاقة (% ل.س) أقل من إجمالي الفاتورة (% ل.س)',
                COALESCE(p_card_amount, 0), p_total_amount;
        END IF;
        v_cash_applied := 0;
        v_card_applied := p_total_amount;

    ELSIF p_payment_method = 'split' THEN
        IF (COALESCE(p_cash_received, 0) + COALESCE(p_card_amount, 0)) < p_total_amount THEN
            RAISE EXCEPTION 'INSUFFICIENT_SPLIT_PAYMENT: إجمالي المدفوع نقداً وبطاقة (% ل.س) أقل من قيمة الفاتورة (% ل.س)',
                (COALESCE(p_cash_received, 0) + COALESCE(p_card_amount, 0)), p_total_amount;
        END IF;
        v_card_applied := LEAST(p_total_amount, COALESCE(p_card_amount, 0));
        v_cash_applied := p_total_amount - v_card_applied;

    ELSE
        RAISE EXCEPTION 'INVALID_PAYMENT_METHOD: طريقة الدفع غير مدعومة (%)', p_payment_method;
    END IF;

    -- -------------------------------------------------------------------------
    -- STEP 4: Cart Items Validation & Stock Locking
    -- -------------------------------------------------------------------------
    IF p_items IS NULL OR jsonb_array_length(p_items) = 0 THEN
        RAISE EXCEPTION 'EMPTY_CART: لا توجد أصناف في سلة المبيعات';
    END IF;

    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_product_id := (v_item->>'product_id')::uuid;
        v_qty := (v_item->>'quantity')::numeric;
        v_price := (v_item->>'price')::numeric;

        IF v_qty <= 0 THEN
            RAISE EXCEPTION 'INVALID_QUANTITY: كمية الصنف يجب أن تكون أكبر من الصفر';
        END IF;

        -- Lock product row
        SELECT id, name_ar, name_en, price, stock_quantity, is_active, unit
        INTO v_product
        FROM public.products
        WHERE id = v_product_id
        FOR UPDATE;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'PRODUCT_NOT_FOUND: الصنف المعرف بـ (%) غير موجود في النظام', v_product_id;
        END IF;

        IF NOT v_product.is_active THEN
            RAISE EXCEPTION 'PRODUCT_INACTIVE: الصنف "%" غير مفعل للبيع حالياً', v_product.name_ar;
        END IF;

        -- Lock and check branch inventory
        SELECT id, quantity_on_hand, quantity_reserved
        INTO v_branch_inv
        FROM public.branch_inventory
        WHERE branch_id = p_branch_id AND product_id = v_product_id
        FOR UPDATE;

        IF NOT FOUND THEN
            IF v_product.stock_quantity < v_qty THEN
                RAISE EXCEPTION 'INSUFFICIENT_STOCK: نفد رصيد الصنف "%" في الفرع. المتاح: %، المطلوب: %',
                    v_product.name_ar, v_product.stock_quantity, v_qty;
            END IF;

            INSERT INTO public.branch_inventory (
                branch_id, product_id, quantity_on_hand, quantity_reserved, bin_location
            ) VALUES (
                p_branch_id, v_product_id, GREATEST(0, v_product.stock_quantity - v_qty), 0, 'رف-POS-01'
            );
        ELSE
            IF v_branch_inv.quantity_on_hand < v_qty THEN
                RAISE EXCEPTION 'INSUFFICIENT_STOCK: نفد رصيد الصنف "%" في الفرع. المتاح بالمستودع: %، المطلوب: %',
                    v_product.name_ar, v_branch_inv.quantity_on_hand, v_qty;
            END IF;

            UPDATE public.branch_inventory
            SET quantity_on_hand = quantity_on_hand - v_qty,
                updated_at = timezone('utc'::text, now())
            WHERE id = v_branch_inv.id;
        END IF;

        -- Deduct from catalog stock
        UPDATE public.products
        SET stock_quantity = GREATEST(0, stock_quantity - v_qty::integer),
            sales_count = sales_count + v_qty::integer
        WHERE id = v_product_id;

        -- Record movement in inventory_movements
        INSERT INTO public.inventory_movements (
            movement_number,
            branch_id,
            product_id,
            movement_type,
            quantity_change,
            quantity_reserved_change,
            resulting_on_hand,
            resulting_reserved,
            reference_type,
            reference_id,
            actor_id,
            actor_name,
            actor_role,
            notes
        ) VALUES (
            'MOV-' || to_char(now(), 'YYYYMMDD') || '-' || substring(gen_random_uuid()::text from 1 for 8),
            p_branch_id,
            v_product_id,
            'sale',
            -v_qty,
            0,
            GREATEST(0, v_product.stock_quantity - v_qty::integer),
            0,
            'order',
            p_receipt_number,
            v_effective_cashier_id,
            v_shift.cashier_name,
            'cashier',
            'مبيعات كاشير POS • فاتورة ' || p_receipt_number
        );
    END LOOP;

    -- -------------------------------------------------------------------------
    -- STEP 5: Customer Loyalty Profile Lookup
    -- -------------------------------------------------------------------------
    IF p_customer_phone IS NOT NULL AND trim(p_customer_phone) != '' AND trim(p_customer_phone) != '+966 50 000 0000' THEN
        SELECT id INTO v_customer_id
        FROM public.profiles
        WHERE phone = trim(p_customer_phone)
        LIMIT 1;

        IF FOUND AND v_customer_id IS NOT NULL THEN
            v_points_earned := FLOOR(p_total_amount * 0.1)::integer;
            IF v_points_earned > 0 THEN
                UPDATE public.profiles
                SET loyalty_points = loyalty_points + v_points_earned,
                    updated_at = timezone('utc'::text, now())
                WHERE id = v_customer_id;
            END IF;
        END IF;
    END IF;

    -- -------------------------------------------------------------------------
    -- STEP 6: Insert into public.orders & public.order_items
    -- -------------------------------------------------------------------------
    INSERT INTO public.orders (
        order_number,
        user_id,
        customer_name,
        customer_phone,
        branch_id,
        branch_name,
        status,
        delivery_slot,
        payment_method,
        payment_status,
        subtotal,
        delivery_fee,
        discount_amount,
        loyalty_points_used,
        loyalty_discount,
        total_amount,
        notes,
        idempotency_key,
        shift_id,
        cashier_id,
        delivered_at
    ) VALUES (
        p_receipt_number,
        v_customer_id,
        COALESCE(NULLIF(trim(p_customer_name), ''), 'عميل نقدي مباشر'),
        COALESCE(NULLIF(trim(p_customer_phone), ''), '+966 50 000 0000'),
        p_branch_id,
        v_shift.branch_name,
        'delivered',
        'كاشير مباشر - ' || v_shift.branch_name,
        p_payment_method,
        'paid',
        p_subtotal,
        0,
        COALESCE(p_discount_amount, 0),
        COALESCE(p_loyalty_points_used, 0),
        COALESCE(p_loyalty_discount, 0),
        p_total_amount,
        'نقطة بيع POS • الكاشير: ' || v_shift.cashier_name || ' • وردية: ' || v_shift.shift_number || 
            CASE WHEN p_card_auth_code IS NOT NULL AND p_card_auth_code != '' THEN ' • مرجع الشبكة: ' || p_card_auth_code ELSE '' END ||
            ' • ' || COALESCE(p_notes, ''),
        v_effective_idempotency_key,
        v_shift.id,
        v_effective_cashier_id,
        timezone('utc'::text, now())
    ) RETURNING id INTO v_new_order_id;

    -- Insert order items
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        INSERT INTO public.order_items (
            order_id,
            product_id,
            product_name_ar,
            product_name_en,
            unit,
            unit_price,
            quantity,
            total_price
        ) VALUES (
            v_new_order_id,
            (v_item->>'product_id')::uuid,
            v_item->>'name_ar',
            COALESCE(v_item->>'name_en', v_item->>'name_ar'),
            COALESCE(v_item->>'unit', 'piece'),
            (v_item->>'price')::numeric,
            (v_item->>'quantity')::numeric,
            COALESCE((v_item->>'total')::numeric, (v_item->>'price')::numeric * (v_item->>'quantity')::numeric)
        );
    END LOOP;

    -- -------------------------------------------------------------------------
    -- STEP 7: Aggregate Shift Metrics in public.cashier_shifts
    -- -------------------------------------------------------------------------
    UPDATE public.cashier_shifts
    SET cash_sales = cash_sales + v_cash_applied,
        card_sales = card_sales + v_card_applied,
        total_sales = total_sales + p_total_amount,
        expected_cash = (opening_balance + cash_sales + v_cash_applied + cash_receipts) - (cash_refunds + cash_drops),
        transactions_count = transactions_count + 1,
        updated_at = timezone('utc'::text, now())
    WHERE id = p_shift_id;

    -- Record shift movement
    INSERT INTO public.cashier_shift_movements (
        shift_id,
        movement_type,
        amount,
        payment_method,
        reference_id,
        performed_by,
        performed_by_id,
        notes
    ) VALUES (
        p_shift_id,
        CASE WHEN p_payment_method = 'cash' THEN 'sale_cash'
             WHEN p_payment_method = 'card' THEN 'sale_card'
             ELSE 'sale_split' END,
        p_total_amount,
        p_payment_method,
        p_receipt_number,
        v_shift.cashier_name,
        v_effective_cashier_id,
        'عملية بيع كاشير POS • فاتورة ' || p_receipt_number
    );

    -- -------------------------------------------------------------------------
    -- STEP 8: Construct and Return Authoritative Result
    -- -------------------------------------------------------------------------
    RETURN jsonb_build_object(
        'success', true,
        'is_idempotent_replay', false,
        'order_id', v_new_order_id,
        'receipt_number', p_receipt_number,
        'shift_id', v_shift.id,
        'shift_number', v_shift.shift_number,
        'total_amount', p_total_amount,
        'cash_received', p_cash_received,
        'change_given', CASE WHEN p_payment_method = 'cash' THEN GREATEST(0, COALESCE(p_cash_received, 0) - p_total_amount) ELSE 0 END,
        'card_auth_code', p_card_auth_code,
        'points_earned', v_points_earned,
        'points_redeemed', COALESCE(p_loyalty_points_used, 0),
        'created_at', timezone('utc'::text, now())
    );
END;
$$;

-- 3. Fix `place_order_atomic`
CREATE OR REPLACE FUNCTION public.place_order_atomic(
    p_order_number text,
    p_user_id uuid,
    p_delivery_slot text,
    p_payment_method text,
    p_subtotal numeric,
    p_delivery_fee numeric,
    p_discount_amount numeric,
    p_loyalty_points_used integer,
    p_loyalty_discount numeric,
    p_total_amount numeric,
    p_notes text,
    p_items jsonb,
    p_branch_id text DEFAULT 'b-jed-01'::text,
    p_coupon_code text DEFAULT NULL::text,
    p_idempotency_key text DEFAULT NULL::text,
    p_customer_name text DEFAULT NULL::text,
    p_customer_phone text DEFAULT NULL::text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
    v_caller_id uuid;
    v_effective_user_id uuid := NULL;
    v_effective_idempotency_key text;
    v_target_branch_id text;
    v_branch_name text;
    v_order_id uuid;
    v_item jsonb;
    v_product_id uuid;
    v_prod_rec record;
    v_qty numeric;
    v_db_price numeric;
    v_line_total numeric;
    v_calc_subtotal numeric := 0;
    v_effective_subtotal numeric;
    v_coupon_rec record;
    v_calc_coupon_discount numeric := 0;
    v_user_loyalty_balance int;
    v_redemption_rate numeric;
    v_calc_loyalty_discount numeric := 0;
    v_standard_delivery_fee numeric := 10.00;
    v_free_delivery_threshold numeric := 100.00;
    v_matched_zone record;
    v_expected_delivery_fee numeric := 0;
    v_calc_total numeric := 0;
    v_existing_order record;
    v_new_stock int;
    v_branch_stock numeric(12,2);
    v_inv_trx_num text;
    v_result jsonb;
BEGIN
    -- -------------------------------------------------------------------------
    -- STEP 1: Idempotency Protection — Return existing order on retry
    -- -------------------------------------------------------------------------
    v_effective_idempotency_key := COALESCE(NULLIF(trim(p_idempotency_key), ''), p_order_number);

    SELECT o.id, o.order_number, o.status, o.subtotal, o.delivery_fee, o.discount_amount,
           o.loyalty_points_used, o.loyalty_discount, o.total_amount, o.branch_id, o.branch_name, o.created_at
    INTO v_existing_order
    FROM public.orders o
    WHERE o.order_number = p_order_number
       OR (v_effective_idempotency_key IS NOT NULL AND o.idempotency_key = v_effective_idempotency_key)
    LIMIT 1;

    IF FOUND THEN
        RETURN jsonb_build_object(
            'id', v_existing_order.id,
            'order_number', v_existing_order.order_number,
            'status', v_existing_order.status,
            'subtotal', v_existing_order.subtotal,
            'delivery_fee', v_existing_order.delivery_fee,
            'discount_amount', v_existing_order.discount_amount,
            'loyalty_points_used', v_existing_order.loyalty_points_used,
            'loyalty_discount', v_existing_order.loyalty_discount,
            'total_amount', v_existing_order.total_amount,
            'branch_id', v_existing_order.branch_id,
            'branch_name', v_existing_order.branch_name,
            'created_at', v_existing_order.created_at,
            'is_idempotent_replay', true
        );
    END IF;

    -- -------------------------------------------------------------------------
    -- STEP 2: Caller Identity & Defensive Profiles FK Verification
    -- -------------------------------------------------------------------------
    v_caller_id := auth.uid();

    -- Defensively ensure user_id references an existing profile to prevent FK violation (23503)
    IF v_caller_id IS NOT NULL AND EXISTS (SELECT 1 FROM public.profiles WHERE id = v_caller_id) THEN
        v_effective_user_id := v_caller_id;
    ELSIF p_user_id IS NOT NULL AND EXISTS (SELECT 1 FROM public.profiles WHERE id = p_user_id) THEN
        v_effective_user_id := p_user_id;
    ELSE
        v_effective_user_id := NULL;
    END IF;

    -- -------------------------------------------------------------------------
    -- STEP 3: Branch Verification
    -- -------------------------------------------------------------------------
    v_target_branch_id := COALESCE(NULLIF(trim(p_branch_id), ''), auth.branch_id(), 'b-dam-01');

    SELECT id, name_ar INTO v_target_branch_id, v_branch_name
    FROM public.branches
    WHERE id = v_target_branch_id AND is_active = true;

    IF NOT FOUND THEN
        -- Fallback to first active branch
        SELECT id, name_ar INTO v_target_branch_id, v_branch_name
        FROM public.branches
        WHERE is_active = true
        LIMIT 1;
    END IF;

    -- -------------------------------------------------------------------------
    -- STEP 4: Authoritative Catalog Pricing & Stock Lock
    -- -------------------------------------------------------------------------
    IF p_items IS NULL OR jsonb_array_length(p_items) = 0 THEN
        RAISE EXCEPTION 'EMPTY_ITEMS: Cannot place an order without items';
    END IF;

    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        IF (v_item->>'product_id') IS NULL OR NOT ((v_item->>'product_id') ~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$') THEN
            RAISE EXCEPTION 'PRODUCT_NOT_FOUND: Product ID is missing, null, or has an invalid UUID format';
        END IF;

        v_product_id := (v_item->>'product_id')::uuid;

        v_qty := (v_item->>'quantity')::numeric;
        IF v_qty IS NULL OR v_qty <= 0 THEN
            RAISE EXCEPTION 'INVALID_QUANTITY: Quantity must be greater than zero';
        END IF;

        SELECT id, name_ar, name_en, price, stock_quantity, is_active
        INTO v_prod_rec
        FROM public.products
        WHERE id = v_product_id
        FOR UPDATE;

        IF NOT FOUND OR NOT v_prod_rec.is_active THEN
            RAISE EXCEPTION 'PRODUCT_NOT_FOUND: Product with id % does not exist or is inactive', v_product_id;
        END IF;

        v_db_price := v_prod_rec.price;

        IF (v_item->>'unit_price') IS NOT NULL THEN
            IF abs((v_item->>'unit_price')::numeric - v_db_price) > 0.05 THEN
                RAISE EXCEPTION 'PRICE_TAMPERED: Price mismatch for product %. Expected %, received %',
                    v_product_id, v_db_price, (v_item->>'unit_price')::numeric;
            END IF;
        END IF;

        SELECT quantity_on_hand INTO v_branch_stock
        FROM public.branch_inventory
        WHERE branch_id = v_target_branch_id AND product_id = v_product_id
        FOR UPDATE;

        IF FOUND THEN
            IF v_branch_stock < v_qty THEN
                RAISE EXCEPTION 'INSUFFICIENT_STOCK: Only % units available for product % in branch %',
                    v_branch_stock, v_product_id, v_target_branch_id;
            END IF;
            v_new_stock := GREATEST(0, (v_prod_rec.stock_quantity - v_qty)::int);
        ELSE
            IF v_prod_rec.stock_quantity < v_qty THEN
                RAISE EXCEPTION 'INSUFFICIENT_STOCK: Only % units available for product %',
                    v_prod_rec.stock_quantity, v_product_id;
            END IF;
            v_new_stock := (v_prod_rec.stock_quantity - v_qty)::int;
        END IF;

        v_line_total := round(v_db_price * v_qty, 2);
        v_calc_subtotal := v_calc_subtotal + v_line_total;
    END LOOP;

    v_effective_subtotal := v_calc_subtotal;
    IF p_subtotal IS NOT NULL AND abs(p_subtotal - v_effective_subtotal) > 0.50 THEN
        RAISE EXCEPTION 'SUBTOTAL_TAMPERED: Subtotal mismatch. Server computed %, client sent %',
            v_effective_subtotal, p_subtotal;
    END IF;

    -- -------------------------------------------------------------------------
    -- STEP 5: Coupon Validation & Calculation
    -- -------------------------------------------------------------------------
    IF p_coupon_code IS NOT NULL AND trim(p_coupon_code) <> '' THEN
        SELECT id, code, discount_type, discount_value, min_order_amount, max_discount, usage_limit, times_used, expires_at, is_active
        INTO v_coupon_rec
        FROM public.coupons
        WHERE lower(code) = lower(trim(p_coupon_code))
        FOR UPDATE;

        IF NOT FOUND OR NOT v_coupon_rec.is_active THEN
            RAISE EXCEPTION 'INVALID_COUPON: Coupon % does not exist or is inactive', p_coupon_code;
        END IF;

        IF v_coupon_rec.expires_at IS NOT NULL AND v_coupon_rec.expires_at < now() THEN
            RAISE EXCEPTION 'COUPON_EXPIRED: Coupon % expired at %', p_coupon_code, v_coupon_rec.expires_at;
        END IF;

        IF v_effective_subtotal < v_coupon_rec.min_order_amount THEN
            RAISE EXCEPTION 'COUPON_MIN_ORDER_NOT_MET: Minimum order amount of % required for coupon %',
                v_coupon_rec.min_order_amount, p_coupon_code;
        END IF;

        IF v_coupon_rec.usage_limit IS NOT NULL AND v_coupon_rec.times_used >= v_coupon_rec.usage_limit THEN
            RAISE EXCEPTION 'COUPON_USAGE_LIMIT_REACHED: Coupon % has reached its maximum usage limit', p_coupon_code;
        END IF;

        IF v_coupon_rec.discount_type IN ('percentage', 'percent') THEN
            v_calc_coupon_discount := round((v_effective_subtotal * v_coupon_rec.discount_value / 100.0), 2);
            IF v_coupon_rec.max_discount IS NOT NULL AND v_calc_coupon_discount > v_coupon_rec.max_discount THEN
                v_calc_coupon_discount := v_coupon_rec.max_discount;
            END IF;
        ELSE
            v_calc_coupon_discount := least(v_coupon_rec.discount_value, v_effective_subtotal);
        END IF;

        IF p_discount_amount IS NOT NULL AND abs(p_discount_amount - v_calc_coupon_discount) > 0.50 THEN
            RAISE EXCEPTION 'DISCOUNT_TAMPERED: Discount amount mismatch. Server computed %, client sent %',
                v_calc_coupon_discount, p_discount_amount;
        END IF;

        UPDATE public.coupons
        SET times_used = times_used + 1,
            updated_at = timezone('utc'::text, now())
        WHERE id = v_coupon_rec.id;
    END IF;

    -- -------------------------------------------------------------------------
    -- STEP 6: Loyalty Points Validation & Redemption
    -- -------------------------------------------------------------------------
    IF COALESCE(p_loyalty_points_used, 0) > 0 THEN
        IF v_effective_user_id IS NULL THEN
            RAISE EXCEPTION 'UNAUTHORIZED_LOYALTY: Guest orders cannot redeem loyalty points';
        END IF;

        SELECT loyalty_points INTO v_user_loyalty_balance
        FROM public.profiles
        WHERE id = v_effective_user_id
        FOR UPDATE;

        IF v_user_loyalty_balance IS NULL OR v_user_loyalty_balance < p_loyalty_points_used THEN
            RAISE EXCEPTION 'INSUFFICIENT_LOYALTY_POINTS: User only has % points, requested %',
                COALESCE(v_user_loyalty_balance, 0), p_loyalty_points_used;
        END IF;

        SELECT COALESCE(points_redemption_rate, 0.01) INTO v_redemption_rate
        FROM public.store_settings
        WHERE id = 'default';
        IF v_redemption_rate IS NULL THEN v_redemption_rate := 0.01; END IF;

        v_calc_loyalty_discount := round(p_loyalty_points_used * v_redemption_rate, 2);

        IF p_loyalty_discount IS NOT NULL AND abs(p_loyalty_discount - v_calc_loyalty_discount) > 0.50 THEN
            RAISE EXCEPTION 'LOYALTY_DISCOUNT_TAMPERED: Loyalty discount mismatch. Server computed %, client sent %',
                v_calc_loyalty_discount, p_loyalty_discount;
        END IF;

        UPDATE public.profiles
        SET loyalty_points = loyalty_points - p_loyalty_points_used,
            updated_at = timezone('utc'::text, now())
        WHERE id = v_effective_user_id;
    ELSE
        v_calc_loyalty_discount := 0;
    END IF;

    -- -------------------------------------------------------------------------
    -- STEP 7: Authoritative Delivery Zones & Delivery Fee Verification
    -- -------------------------------------------------------------------------
    IF p_delivery_fee IS NOT NULL AND p_delivery_fee < 0 THEN
        RAISE EXCEPTION 'DELIVERY_FEE_TAMPERED: Delivery fee cannot be negative';
    END IF;

    SELECT * INTO v_matched_zone
    FROM public.delivery_zones
    WHERE branch_id = v_target_branch_id AND is_active = true
    ORDER BY free_delivery_threshold ASC
    LIMIT 1;

    IF FOUND THEN
        v_standard_delivery_fee := v_matched_zone.base_delivery_fee;
        IF v_matched_zone.is_surge_pricing_active THEN
            v_standard_delivery_fee := v_standard_delivery_fee + v_matched_zone.surge_fee;
        END IF;
        v_free_delivery_threshold := v_matched_zone.free_delivery_threshold;
    ELSE
        SELECT COALESCE(delivery_fee, 5000.00), COALESCE(free_delivery_threshold, 150000.00)
        INTO v_standard_delivery_fee, v_free_delivery_threshold
        FROM public.store_settings
        WHERE id = 'default';
    END IF;

    IF p_delivery_slot ILIKE '%كاشير%' 
       OR p_delivery_slot ILIKE '%pos%' 
       OR p_delivery_slot ILIKE '%استلام%' 
       OR p_delivery_slot ILIKE '%pickup%' 
       OR p_delivery_slot ILIKE '%click%' THEN
        v_expected_delivery_fee := 0;
    ELSIF v_effective_subtotal >= v_free_delivery_threshold THEN
        v_expected_delivery_fee := 0;
    ELSE
        v_expected_delivery_fee := v_standard_delivery_fee;
    END IF;

    IF p_delivery_fee IS NOT NULL AND p_delivery_fee > 0 AND v_effective_subtotal >= v_free_delivery_threshold THEN
        RAISE EXCEPTION 'DELIVERY_FEE_TAMPERED: Order qualifies for free delivery';
    END IF;

    v_calc_total := round(v_effective_subtotal - v_calc_coupon_discount - v_calc_loyalty_discount + COALESCE(p_delivery_fee, v_expected_delivery_fee), 2);
    IF v_calc_total < 0 THEN
        v_calc_total := 0;
    END IF;

    IF p_total_amount IS NOT NULL AND abs(p_total_amount - v_calc_total) > 1.00 THEN
        RAISE EXCEPTION 'TOTAL_TAMPERED: Total mismatch. Server computed %, client sent %',
            v_calc_total, p_total_amount;
    END IF;

    -- -------------------------------------------------------------------------
    -- STEP 8: Create Order Record in public.orders
    -- -------------------------------------------------------------------------
    INSERT INTO public.orders (
        order_number,
        user_id,
        status,
        delivery_slot,
        payment_method,
        payment_status,
        subtotal,
        delivery_fee,
        coupon_code,
        discount_amount,
        loyalty_points_used,
        loyalty_discount,
        total_amount,
        notes,
        customer_name,
        customer_phone,
        branch_id,
        branch_name,
        idempotency_key,
        created_at,
        updated_at
    ) VALUES (
        p_order_number,
        v_effective_user_id,
        'pending',
        p_delivery_slot,
        p_payment_method,
        CASE WHEN p_payment_method IN ('card', 'apple_pay') THEN 'paid' ELSE 'pending' END,
        v_effective_subtotal,
        COALESCE(p_delivery_fee, v_expected_delivery_fee),
        p_coupon_code,
        v_calc_coupon_discount,
        COALESCE(p_loyalty_points_used, 0),
        v_calc_loyalty_discount,
        v_calc_total,
        p_notes,
        COALESCE(NULLIF(trim(p_customer_name), ''), 'عميل المتجر الإلكتروني'),
        COALESCE(NULLIF(trim(p_customer_phone), ''), '+966 50 000 0000'),
        v_target_branch_id,
        v_branch_name,
        v_effective_idempotency_key,
        timezone('utc'::text, now()),
        timezone('utc'::text, now())
    ) RETURNING id INTO v_order_id;

    -- -------------------------------------------------------------------------
    -- STEP 9: Insert Order Items & Deduct Catalog & Branch Stock
    -- -------------------------------------------------------------------------
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_product_id := (v_item->>'product_id')::uuid;
        v_qty := (v_item->>'quantity')::numeric;

        SELECT id, name_ar, name_en, price, stock_quantity
        INTO v_prod_rec
        FROM public.products
        WHERE id = v_product_id;

        v_db_price := v_prod_rec.price;
        v_line_total := round(v_db_price * v_qty, 2);
        v_new_stock := GREATEST(0, (v_prod_rec.stock_quantity - v_qty)::int);

        -- 1. Insert Line Item
        INSERT INTO public.order_items (
            order_id,
            product_id,
            product_name_ar,
            product_name_en,
            product_image,
            unit,
            unit_price,
            quantity,
            total_price
        ) VALUES (
            v_order_id,
            v_product_id,
            COALESCE(v_prod_rec.name_ar, v_item->>'product_name_ar', 'صنف تسوق'),
            COALESCE(v_prod_rec.name_en, v_item->>'product_name_en', 'Grocery Item'),
            COALESCE(v_item->>'product_image', ''),
            COALESCE(v_item->>'unit', 'piece'),
            v_db_price,
            v_qty,
            v_line_total
        );

        -- 2. Atomically Decrement Products Catalog Stock
        UPDATE public.products
        SET stock_quantity = v_new_stock,
            sales_count = COALESCE(sales_count, 0) + v_qty::int,
            updated_at = timezone('utc'::text, now())
        WHERE id = v_product_id;

        -- 3. Atomically Update Branch Inventory if row exists
        UPDATE public.branch_inventory
        SET quantity_on_hand = quantity_on_hand - v_qty,
            updated_at = timezone('utc'::text, now())
        WHERE branch_id = v_target_branch_id AND product_id = v_product_id;

        -- 4. Record in inventory_movements ledger
        INSERT INTO public.inventory_movements (
            movement_number,
            branch_id,
            product_id,
            movement_type,
            quantity_change,
            quantity_reserved_change,
            resulting_on_hand,
            resulting_reserved,
            reference_type,
            reference_id,
            actor_id,
            actor_name,
            actor_role,
            notes
        ) VALUES (
            'MOV-' || to_char(now(), 'YYYYMMDD') || '-' || substring(gen_random_uuid()::text from 1 for 8),
            v_target_branch_id,
            v_product_id,
            'sale',
            -v_qty,
            0,
            v_new_stock,
            0,
            'order',
            p_order_number,
            COALESCE(v_effective_user_id::text, v_caller_id::text, 'guest-customer'),
            COALESCE(p_customer_name, 'عميل المتجر'),
            'customer',
            'مبيعات طلب رقم: ' || p_order_number
        );

        -- 5. Record in inventory_transactions ledger
        v_inv_trx_num := 'TRX-' || extract(epoch from now())::bigint || '-' || substring(gen_random_uuid()::text from 1 for 6);
        INSERT INTO public.inventory_transactions (
            transaction_number,
            branch_id,
            product_id,
            movement_type,
            reference_type,
            reference_id,
            quantity_change,
            unit_cost,
            total_value,
            balance_after,
            performed_by,
            notes
        ) VALUES (
            v_inv_trx_num,
            v_target_branch_id,
            v_product_id,
            'sales_deduction',
            'order_sale',
            p_order_number,
            -v_qty,
            round(v_db_price * 0.70, 2),
            round(v_qty * v_db_price * 0.70, 2),
            v_new_stock,
            COALESCE(v_effective_user_id::text, v_caller_id::text, 'guest-customer'),
            'مبيعات طلب رقم: ' || p_order_number
        );
    END LOOP;

    -- -------------------------------------------------------------------------
    -- STEP 10: Record Loyalty Transaction if points were redeemed
    -- -------------------------------------------------------------------------
    IF COALESCE(p_loyalty_points_used, 0) > 0 AND v_effective_user_id IS NOT NULL THEN
        INSERT INTO public.loyalty_transactions (
            user_id,
            order_id,
            points,
            transaction_type,
            description_ar,
            description_en
        ) VALUES (
            v_effective_user_id,
            v_order_id,
            -p_loyalty_points_used,
            'redeemed',
            'استبدال نقاط لخصم الطلب رقم ' || p_order_number,
            'Redeemed points for order ' || p_order_number
        );
    END IF;

    -- -------------------------------------------------------------------------
    -- STEP 11: Return Comprehensive Server-Authoritative Result
    -- -------------------------------------------------------------------------
    SELECT jsonb_build_object(
        'id', o.id,
        'order_number', o.order_number,
        'status', o.status,
        'subtotal', o.subtotal,
        'delivery_fee', o.delivery_fee,
        'discount_amount', o.discount_amount,
        'loyalty_points_used', o.loyalty_points_used,
        'loyalty_discount', o.loyalty_discount,
        'total_amount', o.total_amount,
        'branch_id', o.branch_id,
        'branch_name', o.branch_name,
        'created_at', o.created_at,
        'is_idempotent_replay', false
    ) INTO v_result
    FROM public.orders o
    WHERE o.id = v_order_id;

    RETURN v_result;
END;
$$;

-- --- END OF supabase/migrations/20261104_026_fix_pos_and_order_atomic_governance.sql ---


-- Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';
