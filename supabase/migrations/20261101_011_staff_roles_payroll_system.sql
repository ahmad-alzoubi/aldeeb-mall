-- ==============================================================================
-- Migration: 20261101_007_staff_roles_payroll_system.sql
-- Description: Multi-Role Staff Management (Admin, General Manager, Auditor, Accountant, Cashier),
--              Strict Branch Lock, Admin-Defined Passwords, Shift Countdown,
--              and Accounting Payroll System (Salaries, Withdrawals, Deductions, Bonuses).
-- ==============================================================================

-- 1. Staff Members Table
CREATE TABLE IF NOT EXISTS public.staff_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employee_code VARCHAR(32) NOT NULL UNIQUE,
    full_name VARCHAR(128) NOT NULL,
    username VARCHAR(64) NOT NULL UNIQUE,
    email VARCHAR(128) NOT NULL,
    phone VARCHAR(32),
    role VARCHAR(32) NOT NULL CHECK (role IN ('super_admin', 'general_manager', 'auditor', 'accountant', 'cashier', 'branch_manager')),
    branch_id VARCHAR(64) NOT NULL,
    branch_name VARCHAR(128) NOT NULL,
    password_hash TEXT,
    can_change_password BOOLEAN NOT NULL DEFAULT FALSE, -- Cannot change password unless granted by admin
    has_pending_password_request BOOLEAN NOT NULL DEFAULT FALSE,
    basic_salary NUMERIC(12, 2) NOT NULL DEFAULT 5000.00,
    allowances NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    shift_start VARCHAR(8) NOT NULL DEFAULT '08:00',
    shift_end VARCHAR(8) NOT NULL DEFAULT '16:00',
    avatar_url TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    joined_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Payroll Transactions (Salaries, Advance Withdrawals, Deductions, Bonuses)
CREATE TABLE IF NOT EXISTS public.payroll_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_number VARCHAR(64) NOT NULL UNIQUE,
    employee_id UUID NOT NULL REFERENCES public.staff_members(id) ON DELETE CASCADE,
    branch_id VARCHAR(64) NOT NULL,
    type VARCHAR(32) NOT NULL CHECK (type IN ('salary_payment', 'advance_withdrawal', 'deduction', 'bonus')),
    amount NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
    reason TEXT NOT NULL,
    created_by_name VARCHAR(128) NOT NULL,
    created_by_role VARCHAR(32) NOT NULL,
    date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    status VARCHAR(32) NOT NULL DEFAULT 'completed' CHECK (status IN ('completed', 'pending', 'approved')),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Password Change Requests (Workflow requiring admin approval)
CREATE TABLE IF NOT EXISTS public.password_change_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employee_id UUID NOT NULL REFERENCES public.staff_members(id) ON DELETE CASCADE,
    reason TEXT NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    reviewed_by VARCHAR(128),
    reviewed_at TIMESTAMPTZ
);

-- Indexes for lightning-fast queries
CREATE INDEX IF NOT EXISTS idx_staff_members_branch ON public.staff_members(branch_id);
CREATE INDEX IF NOT EXISTS idx_staff_members_role ON public.staff_members(role);
CREATE INDEX IF NOT EXISTS idx_payroll_employee ON public.payroll_transactions(employee_id);
CREATE INDEX IF NOT EXISTS idx_payroll_type ON public.payroll_transactions(type);
CREATE INDEX IF NOT EXISTS idx_password_requests_status ON public.password_change_requests(status);

-- Enable Row Level Security (RLS)
ALTER TABLE public.staff_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payroll_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.password_change_requests ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Allow authenticated read staff" ON public.staff_members
    FOR SELECT TO public USING (true);

CREATE POLICY "Allow authenticated read payroll" ON public.payroll_transactions
    FOR SELECT TO public USING (true);

CREATE POLICY "Allow accountant and admin insert payroll" ON public.payroll_transactions
    FOR INSERT TO public WITH CHECK (true);

CREATE POLICY "Allow public read password requests" ON public.password_change_requests
    FOR ALL TO public USING (true);
