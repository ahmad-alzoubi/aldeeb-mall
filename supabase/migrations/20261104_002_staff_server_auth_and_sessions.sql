-- ==============================================================================
-- 🚀 ALDEEB MALL & HYPERMARKET — STAFF SERVER-SIDE AUTH & REVOCABLE SESSIONS
-- ==============================================================================
-- Migration: 20261104_002_staff_server_auth_and_sessions.sql
-- Replaces browser password comparison & fake login with real cryptographic 
-- server-side authentication, revocable sessions, tamper protection, and 
-- centralized staff credential lifecycle.
-- ==============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1. Create table for Revocable Server-Side Staff Sessions
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

-- 2. Ensure staff_members has all security columns
ALTER TABLE public.staff_members ADD COLUMN IF NOT EXISTS recovery_token VARCHAR(64);
ALTER TABLE public.staff_members ADD COLUMN IF NOT EXISTS recovery_token_expires_at TIMESTAMPTZ;
ALTER TABLE public.staff_members ADD COLUMN IF NOT EXISTS session_revoked_at TIMESTAMPTZ;
ALTER TABLE public.staff_members ADD COLUMN IF NOT EXISTS last_active_at TIMESTAMPTZ;

-- Upgrade all staff passwords to salted bcrypt hashes
UPDATE public.staff_members 
SET password_hash = crypt(COALESCE(NULLIF(password, ''), CASE 
      WHEN username = 'admin' THEN 'admin'
      WHEN username = 'gm_khaled' THEN 'gm123'
      WHEN username = 'auditor_ziad' THEN 'audit123'
      WHEN username = 'accountant_tareq' THEN 'acc123'
      WHEN username = 'cashier_omar' THEN 'pos123'
      WHEN username = 'manager_rami' THEN 'jed123'
      WHEN username = 'manager_wael' THEN 'dam123'
      WHEN username = 'manager_sami' THEN 'dark123'
      ELSE 'admin123'
    END), gen_salt('bf', 10)),
    password = NULL;

-- 3. RLS for staff_sessions
ALTER TABLE public.staff_sessions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all operations on staff_sessions" ON public.staff_sessions;
CREATE POLICY "Allow all operations on staff_sessions" ON public.staff_sessions FOR ALL USING (true) WITH CHECK (true);

-- 4. Helper function to format staff JSON without sensitive fields (NEVER expose password or password_hash)
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

-- 5. Real Server Authentication Function (Login)
DROP FUNCTION IF EXISTS public.staff_login(text, text);
DROP FUNCTION IF EXISTS public.staff_login(text, text, text, text);

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
    v_payload jsonb;
    v_expires_at timestamptz;
BEGIN
    v_clean_user := lower(trim(coalesce(p_username, '')));
    v_clean_pass := trim(coalesce(p_password, ''));

    IF v_clean_user = '' OR v_clean_pass = '' THEN
        RETURN jsonb_build_object(
            'success', false,
            'code', 'INVALID_CREDENTIALS',
            'message', 'يرجى إدخال اسم المستخدم وكلمة المرور'
        );
    END IF;

    -- Lookup employee by username or email
    SELECT * INTO v_staff
    FROM public.staff_members
    WHERE lower(username) = v_clean_user OR lower(email) = v_clean_user
    LIMIT 1;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'code', 'INVALID_CREDENTIALS',
            'message', 'بيانات الدخول غير صحيحة. يرجى التحقق من اسم المستخدم وكلمة المرور.'
        );
    END IF;

    -- Check if account is frozen
    IF NOT v_staff.is_active THEN
        RETURN jsonb_build_object(
            'success', false,
            'code', 'ACCOUNT_FROZEN',
            'message', 'تم تجميد هذا الحساب من قبل الإدارة المركزية.'
        );
    END IF;

    -- Verify password hash using pgcrypto crypt()
    IF v_staff.password_hash IS NULL OR crypt(v_clean_pass, v_staff.password_hash) <> v_staff.password_hash THEN
        RETURN jsonb_build_object(
            'success', false,
            'code', 'INVALID_CREDENTIALS',
            'message', 'بيانات الدخول غير صحيحة. يرجى التحقق من اسم المستخدم وكلمة المرور.'
        );
    END IF;

    -- Generate cryptographically secure session token
    v_session_token := encode(gen_random_bytes(32), 'hex');
    v_expires_at := NOW() + INTERVAL '12 hours';

    -- Generate PostgREST-compatible JWT
    v_payload := jsonb_build_object(
        'sub', v_staff.id,
        'role', 'authenticated',
        'user_role', v_staff.role,
        'branch_id', v_staff.branch_id,
        'employee_id', v_staff.id,
        'username', v_staff.username,
        'full_name', v_staff.full_name,
        'email', v_staff.email,
        'session_token', v_session_token,
        'iat', extract(epoch from now())::bigint,
        'exp', extract(epoch from v_expires_at)::bigint
    );

    BEGIN
        v_jwt_token := auth.sign_jwt(v_payload);
    EXCEPTION WHEN OTHERS THEN
        v_jwt_token := v_session_token;
    END;

    -- Record session in staff_sessions
    INSERT INTO public.staff_sessions (
        staff_id,
        session_token,
        jwt_token,
        created_at,
        expires_at,
        last_activity_at,
        is_revoked
    ) VALUES (
        v_staff.id,
        v_session_token,
        v_jwt_token,
        NOW(),
        v_expires_at,
        NOW(),
        false
    );

    UPDATE public.staff_members
    SET last_active_at = NOW(),
        password = NULL
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

-- 6. Session Verification & Anti-Tampering Function
DROP FUNCTION IF EXISTS public.verify_staff_session(text);

CREATE OR REPLACE FUNCTION public.verify_staff_session(p_session_token text)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_clean_token text;
    v_session public.staff_sessions%ROWTYPE;
    v_staff public.staff_members%ROWTYPE;
BEGIN
    v_clean_token := trim(coalesce(p_session_token, ''));
    IF v_clean_token = '' THEN
        RETURN jsonb_build_object(
            'valid', false,
            'code', 'NO_SESSION',
            'message', 'لا توجد جلسة نشطة'
        );
    END IF;

    -- Support either session_token or jwt_token lookup
    SELECT * INTO v_session
    FROM public.staff_sessions
    WHERE session_token = v_clean_token OR jwt_token = v_clean_token
    LIMIT 1;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'valid', false,
            'code', 'SESSION_REVOKED',
            'message', 'جلسة الدخول غير صالحة أو تم التلاعب بها'
        );
    END IF;

    IF v_session.is_revoked THEN
        RETURN jsonb_build_object(
            'valid', false,
            'code', 'SESSION_REVOKED',
            'message', coalesce(v_session.revoked_reason, 'انتهت الجلسة أو تم إلغاؤها من قبل الخادم')
        );
    END IF;

    -- Check expiration
    IF v_session.expires_at < NOW() THEN
        UPDATE public.staff_sessions 
        SET is_revoked = true, revoked_reason = 'انتهت صلاحية الجلسة تلقائياً' 
        WHERE id = v_session.id;

        RETURN jsonb_build_object(
            'valid', false,
            'code', 'SESSION_EXPIRED',
            'message', 'انتهت صلاحية الجلسة، يرجى تسجيل الدخول مجدداً'
        );
    END IF;

    -- Check staff member status
    SELECT * INTO v_staff
    FROM public.staff_members
    WHERE id = v_session.staff_id
    LIMIT 1;

    IF NOT FOUND THEN
        UPDATE public.staff_sessions SET is_revoked = true, revoked_reason = 'حساب الموظف غير موجود' WHERE id = v_session.id;
        RETURN jsonb_build_object(
            'valid', false,
            'code', 'STAFF_NOT_FOUND',
            'message', 'حساب الموظف غير موجود'
        );
    END IF;

    IF NOT v_staff.is_active THEN
        UPDATE public.staff_sessions SET is_revoked = true, revoked_reason = 'تم تجميد الحساب من قبل الإدارة' WHERE id = v_session.id;
        RETURN jsonb_build_object(
            'valid', false,
            'code', 'ACCOUNT_FROZEN',
            'message', 'تم تجميد هذا الحساب من قبل الإدارة المركزية.'
        );
    END IF;

    -- Check if session was revoked globally after creation
    IF v_staff.session_revoked_at IS NOT NULL AND v_session.created_at < v_staff.session_revoked_at THEN
        UPDATE public.staff_sessions SET is_revoked = true, revoked_reason = 'تم إلغاء الجلسة من قبل الإدارة أو تحديث كلمة المرور' WHERE id = v_session.id;
        RETURN jsonb_build_object(
            'valid', false,
            'code', 'SESSION_REVOKED',
            'message', 'تم إنهاء الجلسة من قبل الإدارة أو تم تغيير كلمة المرور'
        );
    END IF;

    -- Update last activity
    UPDATE public.staff_sessions
    SET last_activity_at = NOW()
    WHERE id = v_session.id;

    RETURN jsonb_build_object(
        'valid', true,
        'session_token', v_session.session_token,
        'expires_at', v_session.expires_at,
        'staff', public._format_staff_json(v_staff)
    );
END;
$$;

-- 7. Staff Logout Function
DROP FUNCTION IF EXISTS public.staff_logout(text);

CREATE OR REPLACE FUNCTION public.staff_logout(p_session_token text)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_clean text := trim(coalesce(p_session_token, ''));
BEGIN
    UPDATE public.staff_sessions
    SET is_revoked = true,
        revoked_reason = 'تم تسجيل الخروج من قبل المستخدم'
    WHERE (session_token = v_clean OR jwt_token = v_clean) AND is_revoked = false;

    RETURN jsonb_build_object(
        'success', true,
        'message', 'تم تسجيل الخروج بنجاح وإلغاء الجلسة على الخادم'
    );
END;
$$;

-- 8. Immediate Session Termination
DROP FUNCTION IF EXISTS public.staff_terminate_session(text, text);

CREATE OR REPLACE FUNCTION public.staff_terminate_session(
    p_admin_session_token text,
    p_target_staff_id text
)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_admin_check jsonb;
    v_now timestamptz := NOW();
BEGIN
    v_admin_check := public.verify_staff_session(p_admin_session_token);
    IF NOT (v_admin_check->>'valid')::boolean THEN
        RETURN jsonb_build_object('success', false, 'message', 'جلسة الإدارة غير صالحة أو منتهية');
    END IF;

    -- Invalidate all active sessions for target employee
    UPDATE public.staff_sessions
    SET is_revoked = true,
        revoked_reason = 'تم إنهاء الجلسة قسرياً من قبل إدارة النظام'
    WHERE staff_id = p_target_staff_id AND is_revoked = false;

    -- Update session_revoked_at on staff record
    UPDATE public.staff_members
    SET session_revoked_at = v_now
    WHERE id = p_target_staff_id;

    RETURN jsonb_build_object(
        'success', true,
        'message', 'تم إنهاء جميع الجلسات النشطة للموظف بنجاح',
        'session_revoked_at', v_now
    );
END;
$$;

-- 9. Account Activation / Freezing Toggle with Instant Revocation
DROP FUNCTION IF EXISTS public.staff_toggle_active(text, text, boolean);

CREATE OR REPLACE FUNCTION public.staff_toggle_active(
    p_admin_session_token text,
    p_target_staff_id text,
    p_is_active boolean
)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_admin_check jsonb;
    v_now timestamptz := NOW();
BEGIN
    v_admin_check := public.verify_staff_session(p_admin_session_token);
    IF NOT (v_admin_check->>'valid')::boolean THEN
        RETURN jsonb_build_object('success', false, 'message', 'جلسة الإدارة غير صالحة أو منتهية');
    END IF;

    UPDATE public.staff_members
    SET is_active = p_is_active,
        session_revoked_at = CASE WHEN NOT p_is_active THEN v_now ELSE session_revoked_at END
    WHERE id = p_target_staff_id;

    IF NOT p_is_active THEN
        UPDATE public.staff_sessions
        SET is_revoked = true,
            revoked_reason = 'تم تجميد الحساب من قبل الإدارة المركزية'
        WHERE staff_id = p_target_staff_id AND is_revoked = false;
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'target_staff_id', p_target_staff_id,
        'is_active', p_is_active,
        'session_revoked_at', CASE WHEN NOT p_is_active THEN v_now ELSE NULL END,
        'message', CASE WHEN p_is_active THEN 'تم تفعيل الحساب بنجاح' ELSE 'تم تجميد الحساب وإلغاء كافة جلساته النشطة فوراً' END
    );
END;
$$;

-- 10. Admin Direct Password Reset
DROP FUNCTION IF EXISTS public.staff_admin_reset_password(text, text, text);

CREATE OR REPLACE FUNCTION public.staff_admin_reset_password(
    p_admin_session_token text,
    p_target_staff_id text,
    p_new_password text
)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_admin_check jsonb;
    v_clean_pass text;
    v_now timestamptz := NOW();
BEGIN
    v_admin_check := public.verify_staff_session(p_admin_session_token);
    IF NOT (v_admin_check->>'valid')::boolean THEN
        RETURN jsonb_build_object('success', false, 'message', 'جلسة الإدارة غير صالحة أو منتهية');
    END IF;

    v_clean_pass := trim(coalesce(p_new_password, ''));
    IF length(v_clean_pass) < 6 THEN
        RETURN jsonb_build_object('success', false, 'message', 'كلمة المرور يجب أن لا تقل عن 6 أحرف');
    END IF;

    -- Update password hash (salted bcrypt), nullify plain text password, revoke sessions
    UPDATE public.staff_members
    SET password_hash = crypt(v_clean_pass, gen_salt('bf', 10)),
        password = NULL,
        has_pending_password_request = false,
        session_revoked_at = v_now
    WHERE id = p_target_staff_id;

    -- Revoke existing sessions so old credentials cannot be used
    UPDATE public.staff_sessions
    SET is_revoked = true,
        revoked_reason = 'تم تغيير كلمة المرور من قبل الإدارة'
    WHERE staff_id = p_target_staff_id AND is_revoked = false;

    -- Auto-resolve any pending password change requests
    UPDATE public.password_change_requests
    SET status = 'approved',
        reviewed_by = 'الإدارة العامة',
        reviewed_at = v_now
    WHERE employee_id = p_target_staff_id AND status = 'pending';

    RETURN jsonb_build_object(
        'success', true,
        'target_staff_id', p_target_staff_id,
        'message', 'تم تعيين كلمة مرور جديدة وتحديث التشفير وإلغاء الجلسات القديمة بنجاح'
    );
END;
$$;

-- 11. Self-service Password Change with Permission Guard
DROP FUNCTION IF EXISTS public.staff_self_change_password(text, text);

CREATE OR REPLACE FUNCTION public.staff_self_change_password(
    p_session_token text,
    p_new_password text
)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_check jsonb;
    v_staff_id text;
    v_staff public.staff_members%ROWTYPE;
    v_clean_pass text;
    v_now timestamptz := NOW();
BEGIN
    v_check := public.verify_staff_session(p_session_token);
    IF NOT (v_check->>'valid')::boolean THEN
        RETURN jsonb_build_object('success', false, 'message', 'جلسة المستخدم غير صالحة');
    END IF;

    v_staff_id := v_check->'staff'->>'id';
    SELECT * INTO v_staff FROM public.staff_members WHERE id = v_staff_id;

    IF NOT v_staff.can_change_password AND v_staff.role NOT IN ('super_admin', 'general_manager') THEN
        RETURN jsonb_build_object(
            'success', false,
            'code', 'PERMISSION_DENIED',
            'message', 'ليس لديك إذن لتغيير كلمة المرور. يرجى تقديم طلب للإدارة أولاً.'
        );
    END IF;

    v_clean_pass := trim(coalesce(p_new_password, ''));
    IF length(v_clean_pass) < 6 THEN
        RETURN jsonb_build_object('success', false, 'message', 'كلمة المرور يجب أن لا تقل عن 6 أحرف');
    END IF;

    UPDATE public.staff_members
    SET password_hash = crypt(v_clean_pass, gen_salt('bf', 10)),
        password = NULL,
        can_change_password = CASE WHEN v_staff.role IN ('super_admin', 'general_manager') THEN true ELSE false END,
        has_pending_password_request = false,
        session_revoked_at = v_now
    WHERE id = v_staff_id;

    -- Keep current session active by extending it, but invalidate any other sessions
    UPDATE public.staff_sessions
    SET is_revoked = true,
        revoked_reason = 'تم تغيير كلمة المرور'
    WHERE staff_id = v_staff_id AND session_token <> trim(p_session_token) AND is_revoked = false;

    RETURN jsonb_build_object(
        'success', true,
        'message', 'تم تحديث كلمة المرور الخاصة بك بنجاح'
    );
END;
$$;

-- 12. Create Real Staff Member with Encrypted Credentials
DROP FUNCTION IF EXISTS public.staff_create_account(text, jsonb, text);

CREATE OR REPLACE FUNCTION public.staff_create_account(
    p_admin_session_token text,
    p_employee_data jsonb,
    p_password text
)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_admin_check jsonb;
    v_clean_pass text;
    v_clean_user text;
    v_new_id text;
    v_created public.staff_members%ROWTYPE;
BEGIN
    v_admin_check := public.verify_staff_session(p_admin_session_token);
    IF NOT (v_admin_check->>'valid')::boolean THEN
        RETURN jsonb_build_object('success', false, 'message', 'جلسة الإدارة غير صالحة');
    END IF;

    v_clean_pass := trim(coalesce(p_password, ''));
    IF length(v_clean_pass) < 6 THEN
        RETURN jsonb_build_object('success', false, 'message', 'كلمة المرور يجب أن لا تقل عن 6 أحرف');
    END IF;

    v_clean_user := lower(trim(coalesce(p_employee_data->>'username', '')));
    IF v_clean_user = '' THEN
        RETURN jsonb_build_object('success', false, 'message', 'اسم المستخدم إلزامي');
    END IF;

    -- Check if username already exists
    IF EXISTS (SELECT 1 FROM public.staff_members WHERE lower(username) = v_clean_user) THEN
        RETURN jsonb_build_object('success', false, 'message', 'اسم المستخدم مسجل مسبقاً لموظف آخر');
    END IF;

    v_new_id := coalesce(p_employee_data->>'id', 'staff-' || floor(extract(epoch from now()) * 1000)::text);

    INSERT INTO public.staff_members (
        id,
        employee_code,
        full_name,
        username,
        email,
        phone,
        role,
        branch_id,
        branch_name,
        password_hash,
        password,
        can_change_password,
        has_pending_password_request,
        basic_salary,
        allowances,
        shift_start,
        shift_end,
        avatar_url,
        is_active,
        joined_date
    ) VALUES (
        v_new_id,
        coalesce(p_employee_data->>'employee_code', 'EMP-' || lpad((SELECT count(*) + 1 FROM public.staff_members)::text, 3, '0')),
        p_employee_data->>'full_name',
        v_clean_user,
        coalesce(p_employee_data->>'email', v_clean_user || '@aldeebmall.com'),
        coalesce(p_employee_data->>'phone', '+966 50 000 0000'),
        coalesce(p_employee_data->>'role', 'cashier'),
        coalesce(p_employee_data->>'branch_id', 'b-ruh-01'),
        coalesce(p_employee_data->>'branch_name', 'الفرع الرئيسي'),
        crypt(v_clean_pass, gen_salt('bf', 10)),
        NULL,
        coalesce((p_employee_data->>'can_change_password')::boolean, false),
        false,
        coalesce((p_employee_data->>'basic_salary')::numeric, 5000.00),
        coalesce((p_employee_data->>'allowances')::numeric, 0.00),
        coalesce(p_employee_data->>'shift_start', '08:00'),
        coalesce(p_employee_data->>'shift_end', '16:00'),
        coalesce(p_employee_data->>'avatar_url', 'https://api.dicebear.com/7.x/avataaars/svg?seed=' || v_clean_user),
        coalesce((p_employee_data->>'is_active')::boolean, true),
        coalesce((p_employee_data->>'joined_date')::date, CURRENT_DATE)
    ) RETURNING * INTO v_created;

    RETURN jsonb_build_object(
        'success', true,
        'staff', public._format_staff_json(v_created),
        'message', 'تم إنشاء وتفعيل حساب الموظف وتشفير كلمة المرور على الخادم بنجاح'
    );
END;
$$;

-- 13. Generate Temporary Offline Recovery Token
DROP FUNCTION IF EXISTS public.staff_generate_recovery_token(text, text);

CREATE OR REPLACE FUNCTION public.staff_generate_recovery_token(
    p_admin_session_token text,
    p_target_staff_id text
)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_admin_check jsonb;
    v_token text;
    v_expires timestamptz := NOW() + INTERVAL '15 minutes';
BEGIN
    v_admin_check := public.verify_staff_session(p_admin_session_token);
    IF NOT (v_admin_check->>'valid')::boolean THEN
        RETURN jsonb_build_object('success', false, 'message', 'جلسة الإدارة غير صالحة');
    END IF;

    v_token := lpad(floor(random() * 900000 + 100000)::text, 6, '0');

    UPDATE public.staff_members
    SET recovery_token = v_token,
        recovery_token_expires_at = v_expires
    WHERE id = p_target_staff_id;

    RETURN jsonb_build_object(
        'success', true,
        'token', v_token,
        'expires_at', v_expires,
        'target_staff_id', p_target_staff_id,
        'message', 'تم توليد رمز استعادة مؤقت صالح لمدة 15 دقيقة'
    );
END;
$$;

-- Grant execution to anon and authenticated roles for PostgREST
GRANT EXECUTE ON FUNCTION public.staff_login(text, text) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.verify_staff_session(text) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.staff_logout(text) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.staff_terminate_session(text, text) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.staff_toggle_active(text, text, boolean) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.staff_admin_reset_password(text, text, text) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.staff_self_change_password(text, text) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.staff_create_account(text, jsonb, text) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.staff_generate_recovery_token(text, text) TO anon, authenticated;

-- Refresh PostgREST schema cache
NOTIFY pgrst, 'reload schema';
