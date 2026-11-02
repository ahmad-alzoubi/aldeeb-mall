import { StaffMember, StaffRole, PayrollTransaction, PasswordChangeRequest } from '../types';

export const INITIAL_STAFF: StaffMember[] = [
  {
    id: 'staff-admin-01',
    employee_code: 'EMP-001',
    full_name: 'م. حسام الديب',
    username: 'admin',
    email: 'hussam.aldeeb@aldeebmall.com',
    phone: '+966 50 111 2233',
    role: 'super_admin',
    branch_id: 'b-ruh-01',
    branch_name: 'هايبرماركت الرياض الرئيسي (المركز الفاخر)',
    password: 'admin',
    can_change_password: true,
    basic_salary: 28000,
    allowances: 4000,
    shift_start: '08:00',
    shift_end: '17:00',
    avatar_url: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=150&q=80',
    is_active: true,
    joined_date: '2024-01-01',
  },
  {
    id: 'staff-gm-01',
    employee_code: 'EMP-002',
    full_name: 'د. خالد العمري',
    username: 'gm_khaled',
    email: 'k.omari@aldeebmall.com',
    phone: '+966 55 222 3344',
    role: 'general_manager',
    branch_id: 'b-ruh-01',
    branch_name: 'هايبرماركت الرياض الرئيسي (المركز الفاخر)',
    password: 'gm123',
    can_change_password: false, // مقفل لا يمكن تغييره إلا بإذن الإدارة
    basic_salary: 22000,
    allowances: 3500,
    shift_start: '08:30',
    shift_end: '16:30',
    avatar_url: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?auto=format&fit=crop&w=150&q=80',
    is_active: true,
    joined_date: '2024-06-15',
  },
  {
    id: 'staff-auditor-01',
    employee_code: 'EMP-003',
    full_name: 'أ. زياد السالم',
    username: 'auditor_ziad',
    email: 'z.salem@aldeebmall.com',
    phone: '+966 54 333 4455',
    role: 'auditor',
    branch_id: 'b-dmm-01',
    branch_name: 'فرع الدمام الشاطئ ومول الشرقية',
    password: 'audit123',
    can_change_password: false, // مقفل
    basic_salary: 14500,
    allowances: 2000,
    shift_start: '08:00',
    shift_end: '16:00',
    avatar_url: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=150&q=80',
    is_active: true,
    joined_date: '2025-02-01',
  },
  {
    id: 'staff-acc-01',
    employee_code: 'EMP-004',
    full_name: 'أ. طارق الشامي',
    username: 'accountant_tareq',
    email: 't.shami@aldeebmall.com',
    phone: '+966 56 444 5566',
    role: 'accountant',
    branch_id: 'b-jed-01',
    branch_name: 'فرع جدة الكورنيش (واجهة البحر)',
    password: 'acc123',
    can_change_password: false, // مقفل لا يغيره إلا بإذن
    basic_salary: 12000,
    allowances: 1500,
    shift_start: '09:00',
    shift_end: '17:00',
    avatar_url: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=150&q=80',
    is_active: true,
    joined_date: '2025-03-10',
  },
  {
    id: 'staff-cashier-01',
    employee_code: 'EMP-005',
    full_name: 'عمر الدوسري',
    username: 'cashier_omar',
    email: 'o.dossari@aldeebmall.com',
    phone: '+966 53 555 6677',
    role: 'cashier',
    branch_id: 'b-ruh-01',
    branch_name: 'هايبرماركت الرياض الرئيسي (المركز الفاخر)',
    password: 'pos123',
    can_change_password: false, // مقفل تماماً
    basic_salary: 5800,
    allowances: 800,
    shift_start: '08:00',
    shift_end: '16:00',
    avatar_url: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=150&q=80',
    is_active: true,
    joined_date: '2025-08-01',
  },
  {
    id: 'staff-mgr-02',
    employee_code: 'EMP-006',
    full_name: 'رامي القحطاني',
    username: 'manager_rami',
    email: 'r.qahtani@aldeebmall.com',
    phone: '+966 51 666 7788',
    role: 'branch_manager',
    branch_id: 'b-jed-01',
    branch_name: 'فرع جدة الكورنيش (واجهة البحر)',
    password: 'jed123',
    can_change_password: false,
    basic_salary: 10500,
    allowances: 1500,
    shift_start: '08:30',
    shift_end: '17:30',
    avatar_url: 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?auto=format&fit=crop&w=150&q=80',
    is_active: true,
    joined_date: '2025-04-12',
  }
];

export const INITIAL_PAYROLL_TRANSACTIONS: PayrollTransaction[] = [
  {
    id: 'pay-tx-001',
    transaction_number: 'PR-2026-1001',
    employee_id: 'staff-cashier-01',
    employee_name: 'عمر الدوسري',
    employee_role: 'cashier',
    branch_id: 'b-ruh-01',
    branch_name: 'هايبرماركت الرياض الرئيسي (المركز الفاخر)',
    type: 'deduction',
    amount: 150,
    reason: 'خصم تأخير 3 ساعات وتكرار التأخر الصباحي',
    created_by_name: 'أ. طارق الشامي (المحاسب)',
    created_by_role: 'accountant',
    date: '2026-10-25T11:30:00Z',
    status: 'completed',
    notes: 'تم الخصم بناء على سجل الحضور البصري للفرع',
  },
  {
    id: 'pay-tx-002',
    transaction_number: 'PR-2026-1002',
    employee_id: 'staff-acc-01',
    employee_name: 'أ. طارق الشامي',
    employee_role: 'accountant',
    branch_id: 'b-jed-01',
    branch_name: 'فرع جدة الكورنيش (واجهة البحر)',
    type: 'advance_withdrawal',
    amount: 1500,
    reason: 'سحب سلفة طارئة من الراتب',
    created_by_name: 'د. خالد العمري (المدير العام)',
    created_by_role: 'general_manager',
    date: '2026-10-18T14:15:00Z',
    status: 'approved',
    notes: 'تم تحويل السلفة للحساب البنكي مباشرة',
  },
  {
    id: 'pay-tx-003',
    transaction_number: 'PR-2026-1003',
    employee_id: 'staff-auditor-01',
    employee_name: 'أ. زياد السالم',
    employee_role: 'auditor',
    branch_id: 'b-dmm-01',
    branch_name: 'فرع الدمام الشاطئ ومول الشرقية',
    type: 'bonus',
    amount: 1000,
    reason: 'مكافأة إنجاز التدقيق الشامل لمخازن الشرقية',
    created_by_name: 'م. حسام الديب (مسؤول النظام)',
    created_by_role: 'super_admin',
    date: '2026-10-28T16:00:00Z',
    status: 'completed',
    notes: 'كفاءة عالية في رصد فروقات الجرد وحماية الأصول',
  },
  {
    id: 'pay-tx-004',
    transaction_number: 'PR-2026-1004',
    employee_id: 'staff-cashier-01',
    employee_name: 'عمر الدوسري',
    employee_role: 'cashier',
    branch_id: 'b-ruh-01',
    branch_name: 'هايبرماركت الرياض الرئيسي (المركز الفاخر)',
    type: 'advance_withdrawal',
    amount: 500,
    reason: 'سحب مالي نقدي (سلفة سريعة)',
    created_by_name: 'أ. طارق الشامي (المحاسب)',
    created_by_role: 'accountant',
    date: '2026-10-22T10:00:00Z',
    status: 'completed',
    notes: 'تم تسليم المبلغ نقداً من الصندوق',
  },
  {
    id: 'pay-tx-005',
    transaction_number: 'PR-2026-1005',
    employee_id: 'staff-mgr-02',
    employee_name: 'رامي القحطاني',
    employee_role: 'branch_manager',
    branch_id: 'b-jed-01',
    branch_name: 'فرع جدة الكورنيش (واجهة البحر)',
    type: 'salary_payment',
    amount: 12000,
    reason: 'صرف راتب دورة أكتوبر 2026 بالكامل',
    created_by_name: 'أ. طارق الشامي (المحاسب)',
    created_by_role: 'accountant',
    date: '2026-10-30T09:30:00Z',
    status: 'completed',
    notes: 'تحويل عبر نظام حماية الأجور (WPS)',
  }
];

export const INITIAL_PASSWORD_REQUESTS: PasswordChangeRequest[] = [
  {
    id: 'pwr-001',
    employee_id: 'staff-cashier-01',
    employee_name: 'عمر الدوسري',
    role: 'cashier',
    branch_name: 'هايبرماركت الرياض الرئيسي (المركز الفاخر)',
    requested_at: '2026-10-31T14:20:00Z',
    reason: 'اشتباه بمشاهدة أحد الموظفين المؤقتين لكلمة المرور أثناء تسجيل الدخول بنقطة البيع',
    status: 'pending',
  }
];

export function getRoleArabicTitle(role: StaffRole): string {
  switch (role) {
    case 'super_admin':
      return 'مسؤول النظام (Super Admin)';
    case 'general_manager':
      return 'مدير عام (CEO)';
    case 'auditor':
      return 'مدقق عام (Auditor)';
    case 'accountant':
      return 'محاسب مالي (Accountant)';
    case 'branch_manager':
      return 'مدير فرع (Branch Manager)';
    case 'cashier':
      return 'كاشير ومبيعات (Cashier)';
    default:
      return role;
  }
}

export function getRoleBadgeStyle(role: StaffRole): { bg: string, text: string, border: string } {
  switch (role) {
    case 'super_admin':
      return { bg: 'bg-red-500/10', text: 'text-red-700', border: 'border-red-200' };
    case 'general_manager':
      return { bg: 'bg-purple-500/10', text: 'text-purple-700', border: 'border-purple-200' };
    case 'auditor':
      return { bg: 'bg-emerald-500/10', text: 'text-emerald-700', border: 'border-emerald-200' };
    case 'accountant':
      return { bg: 'bg-blue-500/10', text: 'text-blue-700', border: 'border-blue-200' };
    case 'branch_manager':
      return { bg: 'bg-amber-500/10', text: 'text-amber-700', border: 'border-amber-200' };
    case 'cashier':
      return { bg: 'bg-slate-500/10', text: 'text-slate-700', border: 'border-slate-200' };
    default:
      return { bg: 'bg-gray-100', text: 'text-gray-800', border: 'border-gray-200' };
  }
}

/**
 * Calculates remaining time until shift end, live percentage and status.
 */
export function calculateShiftRemaining(shiftStart: string, shiftEnd: string): {
  remainingText: string;
  hours: number;
  minutes: number;
  seconds: number;
  percent: number;
  isOvertime: boolean;
  isBeforeShift: boolean;
  statusText: string;
} {
  const now = new Date();
  const currentMinutes = now.getHours() * 60 + now.getMinutes() + now.getSeconds() / 60;

  const [startH, startM] = shiftStart.split(':').map(Number);
  const [endH, endM] = shiftEnd.split(':').map(Number);

  const startTotalMinutes = startH * 60 + (startM || 0);
  const endTotalMinutes = endH * 60 + (endM || 0);

  // If before shift start
  if (currentMinutes < startTotalMinutes) {
    const diffM = Math.floor(startTotalMinutes - currentMinutes);
    const h = Math.floor(diffM / 60);
    const m = diffM % 60;
    return {
      remainingText: `يبدأ الدوام بعد ${h > 0 ? `${h} س ` : ''}${m} د`,
      hours: h,
      minutes: m,
      seconds: 0,
      percent: 0,
      isOvertime: false,
      isBeforeShift: true,
      statusText: 'قبل بدء الوردية',
    };
  }

  // If after shift end (overtime)
  if (currentMinutes >= endTotalMinutes) {
    const overM = Math.floor(currentMinutes - endTotalMinutes);
    const h = Math.floor(overM / 60);
    const m = overM % 60;
    return {
      remainingText: `انتهت الوردية (إضافي +${h > 0 ? `${h}س ` : ''}${m}د)`,
      hours: h,
      minutes: m,
      seconds: 0,
      percent: 100,
      isOvertime: true,
      isBeforeShift: false,
      statusText: 'انتهى الدوام الرسمي',
    };
  }

  // Currently during shift
  const totalShiftDuration = endTotalMinutes - startTotalMinutes;
  const elapsed = currentMinutes - startTotalMinutes;
  const remainingMinutesTotal = endTotalMinutes - currentMinutes;

  const hours = Math.floor(remainingMinutesTotal / 60);
  const minutes = Math.floor(remainingMinutesTotal % 60);
  const seconds = Math.floor((60 - now.getSeconds()) % 60);
  const percent = Math.min(100, Math.max(0, Math.round((elapsed / totalShiftDuration) * 100)));

  return {
    remainingText: `${hours} س و ${minutes} د و ${seconds} ث`,
    hours,
    minutes,
    seconds,
    percent,
    isOvertime: false,
    isBeforeShift: false,
    statusText: 'الدوام ساري حالياً',
  };
}

/**
 * Checks whether a given role has permissions to access a section
 */
export function checkRoleAccess(role: StaffRole, sectionId: string): boolean {
  if (role === 'super_admin' || role === 'general_manager') {
    return true; // Full access
  }

  if (role === 'auditor') {
    // Read & audit oriented sections
    const auditorAllowed = [
      'dashboard', 'analytics', 'forecasting', 'orders', 'operations_tower',
      'fulfillment', 'branches', 'accounting_payroll', 'suppliers', 'audit_logs',
      'inventory_transfer', 'returns', 'fleet', 'cold_chain', 'price_match',
      'corporate_b2b', 'marketplace_vendors'
    ];
    return auditorAllowed.includes(sectionId);
  }

  if (role === 'accountant') {
    // Financial & accounting oriented sections
    const accountantAllowed = [
      'dashboard', 'accounting_payroll', 'orders', 'pos_terminal', 
      'suppliers', 'corporate_b2b', 'marketplace_vendors', 'returns',
      'branches', 'analytics', 'price_match'
    ];
    return accountantAllowed.includes(sectionId);
  }

  if (role === 'cashier') {
    // Cashier is restricted to POS and basic dashboard
    const cashierAllowed = ['pos_terminal', 'dashboard'];
    return cashierAllowed.includes(sectionId);
  }

  if (role === 'branch_manager') {
    const managerAllowed = [
      'dashboard', 'orders', 'fulfillment', 'pos_terminal', 'branches',
      'inventory_transfer', 'fleet', 'products', 'staff_management', 'support',
      'butcher_operations', 'cold_chain', 'smart_lockers', 'zero_waste', 'meal_kits'
    ];
    return managerAllowed.includes(sectionId);
  }

  return false;
}
