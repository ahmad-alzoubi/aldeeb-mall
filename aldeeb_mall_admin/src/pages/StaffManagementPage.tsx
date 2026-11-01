import React, { useState } from 'react';
import { 
  Users, 
  UserPlus, 
  KeyRound, 
  ShieldCheck, 
  Building2, 
  Clock, 
  Search, 
  Lock, 
  Unlock, 
  CheckCircle2, 
  XCircle, 
  AlertCircle, 
  Edit3, 
  DollarSign, 
  Check, 
  Eye, 
  EyeOff, 
  Sparkles,
  FileCheck
} from 'lucide-react';
import { StaffMember, StaffRole, PasswordChangeRequest, Branch } from '../types';
import { getRoleArabicTitle, getRoleBadgeStyle } from '../lib/staffData';

interface StaffManagementPageProps {
  staffList: StaffMember[];
  setStaffList: React.Dispatch<React.SetStateAction<StaffMember[]>>;
  branches: Branch[];
  passwordRequests: PasswordChangeRequest[];
  setPasswordRequests: React.Dispatch<React.SetStateAction<PasswordChangeRequest[]>>;
  currentAdminRole?: StaffRole;
}

export const StaffManagementPage: React.FC<StaffManagementPageProps> = ({
  staffList,
  setStaffList,
  branches,
  passwordRequests,
  setPasswordRequests,
  currentAdminRole = 'super_admin',
}) => {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedRoleFilter, setSelectedRoleFilter] = useState<string>('all');
  const [selectedBranchFilter, setSelectedBranchFilter] = useState<string>('all');
  const [activeTab, setActiveTab] = useState<'employees' | 'requests'>('employees');

  // Modals state
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [isResetPasswordModalOpen, setIsResetPasswordModalOpen] = useState(false);
  const [selectedEmployeeForPassword, setSelectedEmployeeForPassword] = useState<StaffMember | null>(null);
  const [newPasswordValue, setNewPasswordValue] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [toastMessage, setToastMessage] = useState<string | null>(null);

  // New employee form state
  const [newEmployee, setNewEmployee] = useState<Partial<StaffMember>>({
    full_name: '',
    username: '',
    email: '',
    phone: '',
    role: 'cashier',
    branch_id: branches[0]?.id || 'b-ruh-01',
    password: '',
    can_change_password: false, // لا يمكن تغيير كلمة السر إلا بإذن من الإدارة
    basic_salary: 5000,
    allowances: 500,
    shift_start: '08:00',
    shift_end: '16:00',
    is_active: true,
  });

  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(null), 4000);
  };

  // Filter staff list
  const filteredStaff = staffList.filter((emp) => {
    const matchesSearch = 
      emp.full_name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      emp.username.toLowerCase().includes(searchQuery.toLowerCase()) ||
      emp.employee_code.toLowerCase().includes(searchQuery.toLowerCase()) ||
      emp.phone.includes(searchQuery);

    const matchesRole = selectedRoleFilter === 'all' || emp.role === selectedRoleFilter;
    const matchesBranch = selectedBranchFilter === 'all' || emp.branch_id === selectedBranchFilter;

    return matchesSearch && matchesRole && matchesBranch;
  });

  // Handle open new account
  const handleCreateEmployee = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newEmployee.full_name || !newEmployee.username || !newEmployee.password) {
      alert('يرجى ملء جميع الحقول الإلزامية وكلمة المرور');
      return;
    }

    const assignedBranch = branches.find(b => b.id === newEmployee.branch_id);

    const created: StaffMember = {
      id: `staff-${Date.now()}`,
      employee_code: `EMP-${String(staffList.length + 1).padStart(3, '0')}`,
      full_name: newEmployee.full_name,
      username: newEmployee.username.trim().toLowerCase(),
      email: newEmployee.email || `${newEmployee.username}@aldeebmall.com`,
      phone: newEmployee.phone || '+966 50 000 0000',
      role: (newEmployee.role as StaffRole) || 'cashier',
      branch_id: newEmployee.branch_id || branches[0]?.id || 'b-ruh-01',
      branch_name: assignedBranch ? assignedBranch.name_ar : 'الفرع الرئيسي',
      password: newEmployee.password,
      can_change_password: !!newEmployee.can_change_password,
      basic_salary: Number(newEmployee.basic_salary) || 5000,
      allowances: Number(newEmployee.allowances) || 0,
      shift_start: newEmployee.shift_start || '08:00',
      shift_end: newEmployee.shift_end || '16:00',
      is_active: true,
      joined_date: new Date().toISOString().split('T')[0],
      avatar_url: `https://api.dicebear.com/7.x/avataaars/svg?seed=${encodeURIComponent(newEmployee.username)}`,
    };

    setStaffList(prev => [created, ...prev]);
    setIsAddModalOpen(false);
    showToast(`✅ تم إنشاء وتفعيل حساب الموظف [${created.full_name}] وتعيين كلمة المرور بنجاح!`);

    // Reset form
    setNewEmployee({
      full_name: '',
      username: '',
      email: '',
      phone: '',
      role: 'cashier',
      branch_id: branches[0]?.id || 'b-ruh-01',
      password: '',
      can_change_password: false,
      basic_salary: 5000,
      allowances: 500,
      shift_start: '08:00',
      shift_end: '16:00',
      is_active: true,
    });
  };

  // Handle direct admin password change
  const handleAdminResetPassword = () => {
    if (!selectedEmployeeForPassword || !newPasswordValue.trim()) return;

    setStaffList(prev => prev.map(emp => {
      if (emp.id === selectedEmployeeForPassword.id) {
        return {
          ...emp,
          password: newPasswordValue.trim(),
          has_pending_password_request: false,
        };
      }
      return emp;
    }));

    // If there was a pending request, resolve it
    setPasswordRequests(prev => prev.map(req => {
      if (req.employee_id === selectedEmployeeForPassword.id && req.status === 'pending') {
        return {
          ...req,
          status: 'approved',
          reviewed_by: 'الإدارة العامة',
          reviewed_at: new Date().toISOString(),
        };
      }
      return req;
    }));

    showToast(`🔒 تم تحديث وتعيين كلمة مرور جديدة للموظف (${selectedEmployeeForPassword.full_name}) بنجاح!`);
    setIsResetPasswordModalOpen(false);
    setSelectedEmployeeForPassword(null);
    setNewPasswordValue('');
  };

  // Toggle permission to change password
  const handleTogglePasswordPermission = (empId: string, currentVal: boolean) => {
    setStaffList(prev => prev.map(emp => {
      if (emp.id === empId) {
        return { ...emp, can_change_password: !currentVal };
      }
      return emp;
    }));
    showToast(!currentVal 
      ? '🔓 تم منح الموظف إذن لتغيير كلمة المرور الخاصة به' 
      : '🔒 تم قفل وتجميد إذن تغيير كلمة المرور للموظف'
    );
  };

  // Approve password request
  const handleApproveRequest = (request: PasswordChangeRequest) => {
    setPasswordRequests(prev => prev.map(r => r.id === request.id ? { ...r, status: 'approved', reviewed_at: new Date().toISOString() } : r));
    setStaffList(prev => prev.map(emp => emp.id === request.employee_id ? { ...emp, can_change_password: true, has_pending_password_request: false } : emp));
    showToast(`✅ تمت الموافقة على طلب الموظف [${request.employee_name}] وتفعيل إذن تغيير كلمة المرور له`);
  };

  // Reject password request
  const handleRejectRequest = (request: PasswordChangeRequest) => {
    setPasswordRequests(prev => prev.map(r => r.id === request.id ? { ...r, status: 'rejected', reviewed_at: new Date().toISOString() } : r));
    setStaffList(prev => prev.map(emp => emp.id === request.employee_id ? { ...emp, has_pending_password_request: false } : emp));
    showToast(`❌ تم رفض طلب الموظف [${request.employee_name}] لتغيير كلمة المرور`);
  };

  return (
    <div className="space-y-6 pb-12 animate-fade-in" dir="rtl">
      {/* Toast alert */}
      {toastMessage && (
        <div className="fixed top-24 left-1/2 -translate-x-1/2 z-50 bg-slate-900 text-white px-6 py-3.5 rounded-2xl shadow-2xl border border-blue-500/30 flex items-center gap-3 text-sm font-bold animate-bounce">
          <Sparkles className="w-5 h-5 text-amber-400" />
          <span>{toastMessage}</span>
        </div>
      )}

      {/* Top Banner and Quick Stats */}
      <div className="bg-gradient-to-r from-slate-900 via-blue-950 to-slate-900 text-white p-6 md:p-8 rounded-3xl shadow-xl border border-slate-800 relative overflow-hidden">
        <div className="absolute top-0 left-0 w-96 h-96 bg-blue-500/10 rounded-full blur-3xl pointer-events-none" />
        
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-6 relative z-10">
          <div>
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-blue-500/20 text-blue-300 text-xs font-bold border border-blue-500/30 mb-3">
              <ShieldCheck className="w-4 h-4 text-blue-400" />
              <span>منظومة الحسابات، الصلاحيات والأمان الموحد</span>
            </div>
            <h1 className="text-2xl md:text-3xl font-black tracking-tight text-white">
              إدارة حسابات الموظفين والصلاحيات والفروع
            </h1>
            <p className="text-slate-300 text-sm mt-2 max-w-2xl leading-relaxed">
              فتح حسابات الموظفين (مدير عام، مسؤول، مدقق، محاسب، كاشير)، تحديد كلمات السر من الإدارة، قفل تغيير كلمة المرور إلا بإذن، وتقييد كل موظف بفرعه الإلزامي.
            </p>
          </div>

          <div className="flex flex-wrap items-center gap-3">
            <button
              onClick={() => setIsAddModalOpen(true)}
              className="px-5 py-3 rounded-2xl bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 text-white font-extrabold text-sm shadow-lg shadow-blue-600/30 flex items-center gap-2.5 transition-all active:scale-95"
            >
              <UserPlus className="w-5 h-5" />
              <span>فتح حساب موظف جديد وتحديد كلمة السر</span>
            </button>
          </div>
        </div>

        {/* Stats Grid */}
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-4 mt-8 pt-6 border-t border-slate-800/80">
          <div className="bg-slate-800/60 backdrop-blur-sm p-4 rounded-2xl border border-slate-700/60">
            <p className="text-xs font-medium text-slate-400">إجمالي الموظفين المسجلين</p>
            <p className="text-2xl font-black text-white mt-1">{staffList.length}</p>
          </div>
          <div className="bg-slate-800/60 backdrop-blur-sm p-4 rounded-2xl border border-slate-700/60">
            <p className="text-xs font-medium text-slate-400">الفروع المغطاة بالموظفين</p>
            <p className="text-2xl font-black text-emerald-400 mt-1">{branches.length} فروع</p>
          </div>
          <div className="bg-slate-800/60 backdrop-blur-sm p-4 rounded-2xl border border-slate-700/60">
            <p className="text-xs font-medium text-slate-400">طلبات إذن كلمة المرور المعلقة</p>
            <p className="text-2xl font-black text-amber-400 mt-1">
              {passwordRequests.filter(r => r.status === 'pending').length} طلب
            </p>
          </div>
          <div className="bg-slate-800/60 backdrop-blur-sm p-4 rounded-2xl border border-slate-700/60">
            <p className="text-xs font-medium text-slate-400">حماية الفروع وكلمات السر</p>
            <div className="flex items-center gap-1.5 mt-1.5">
              <span className="w-2.5 h-2.5 rounded-full bg-emerald-500 animate-pulse" />
              <span className="text-xs font-bold text-emerald-300">مقيدة وصارمة 🔒</span>
            </div>
          </div>
        </div>
      </div>

      {/* Tabs & Filters */}
      <div className="bg-white p-5 rounded-3xl border border-slate-200 shadow-sm space-y-4">
        <div className="flex flex-col sm:flex-row items-center justify-between gap-4">
          <div className="flex items-center gap-2 bg-slate-100 p-1.5 rounded-2xl w-full sm:w-auto">
            <button
              onClick={() => setActiveTab('employees')}
              className={`flex items-center gap-2 px-5 py-2.5 rounded-xl font-bold text-xs transition-all ${
                activeTab === 'employees'
                  ? 'bg-white text-blue-700 shadow-sm'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              <Users className="w-4 h-4" />
              <span>دليل الموظفين والحسابات ({staffList.length})</span>
            </button>
            <button
              onClick={() => setActiveTab('requests')}
              className={`flex items-center gap-2 px-5 py-2.5 rounded-xl font-bold text-xs transition-all relative ${
                activeTab === 'requests'
                  ? 'bg-white text-blue-700 shadow-sm'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              <KeyRound className="w-4 h-4" />
              <span>طلبات إذن تغيير كلمة المرور</span>
              {passwordRequests.filter(r => r.status === 'pending').length > 0 && (
                <span className="bg-amber-500 text-white text-[10px] px-1.5 py-0.5 rounded-full font-black animate-pulse">
                  {passwordRequests.filter(r => r.status === 'pending').length}
                </span>
              )}
            </button>
          </div>

          {/* Search Box */}
          <div className="relative w-full sm:w-80">
            <Search className="w-4 h-4 text-slate-400 absolute right-3.5 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              placeholder="ابحث بالاسم، الكود، اسم المستخدم..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pr-10 pl-4 py-2.5 rounded-2xl bg-slate-50 border border-slate-200 text-xs font-semibold text-slate-800 focus:outline-none focus:ring-2 focus:ring-blue-500/30 focus:border-blue-500 transition-all"
            />
          </div>
        </div>

        {/* Second row filters */}
        {activeTab === 'employees' && (
          <div className="flex flex-wrap items-center gap-3 pt-3 border-t border-slate-100 text-xs">
            <span className="font-bold text-slate-500">تصفية حسب:</span>
            
            {/* Role Filter */}
            <select
              value={selectedRoleFilter}
              onChange={(e) => setSelectedRoleFilter(e.target.value)}
              className="bg-slate-100 border border-slate-200 text-slate-700 font-bold px-3 py-1.5 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500/20"
            >
              <option value="all">كافة الأدوار والصلاحيات</option>
              <option value="super_admin">مسؤول النظام (Super Admin)</option>
              <option value="general_manager">مدير عام (CEO)</option>
              <option value="auditor">مدقق عام (Auditor)</option>
              <option value="accountant">محاسب مالي (Accountant)</option>
              <option value="branch_manager">مدير فرع (Branch Manager)</option>
              <option value="cashier">كاشير ومبيعات (Cashier)</option>
            </select>

            {/* Branch Filter */}
            <select
              value={selectedBranchFilter}
              onChange={(e) => setSelectedBranchFilter(e.target.value)}
              className="bg-slate-100 border border-slate-200 text-slate-700 font-bold px-3 py-1.5 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500/20"
            >
              <option value="all">كافة الفروع</option>
              {branches.map(b => (
                <option key={b.id} value={b.id}>{b.name_ar}</option>
              ))}
            </select>

            <span className="text-slate-400 mr-auto font-medium">
              النتائج المعروضة: {filteredStaff.length} موظف
            </span>
          </div>
        )}
      </div>

      {/* TAB 1: EMPLOYEES TABLE */}
      {activeTab === 'employees' && (
        <div className="bg-white rounded-3xl border border-slate-200 shadow-sm overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-right border-collapse">
              <thead>
                <tr className="bg-slate-50/80 border-b border-slate-200 text-slate-600 text-[11px] font-black uppercase tracking-wider">
                  <th className="py-4 px-5">الموظف والكود</th>
                  <th className="py-4 px-4">الصلاحية / الدور</th>
                  <th className="py-4 px-4">الفرع المخصص (مقفل 🔒)</th>
                  <th className="py-4 px-4">مواعيد الدوام</th>
                  <th className="py-4 px-4">الراتب الأساسي</th>
                  <th className="py-4 px-4">تغيير كلمة السر</th>
                  <th className="py-4 px-5 text-center">الإجراءات والتحكم الإداري</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 text-xs">
                {filteredStaff.length === 0 ? (
                  <tr>
                    <td colSpan={7} className="py-12 text-center text-slate-400 font-bold">
                      لا يوجد موظفون مطابقون لخيارات البحث
                    </td>
                  </tr>
                ) : (
                  filteredStaff.map((emp) => {
                    const badge = getRoleBadgeStyle(emp.role);
                    return (
                      <tr key={emp.id} className="hover:bg-slate-50/60 transition-colors">
                        {/* Name & Code */}
                        <td className="py-4 px-5">
                          <div className="flex items-center gap-3">
                            <img
                              src={emp.avatar_url || 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=100&q=80'}
                              alt={emp.full_name}
                              className="w-10 h-10 rounded-2xl object-cover border border-slate-200 shadow-xs"
                            />
                            <div>
                              <p className="font-extrabold text-slate-900">{emp.full_name}</p>
                              <div className="flex items-center gap-2 mt-0.5">
                                <span className="text-[10px] font-black px-1.5 py-0.5 rounded-md bg-slate-100 text-slate-600 border border-slate-200">
                                  {emp.employee_code}
                                </span>
                                <span className="text-[11px] text-slate-500 font-medium">@{emp.username}</span>
                              </div>
                            </div>
                          </div>
                        </td>

                        {/* Role */}
                        <td className="py-4 px-4">
                          <span className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-xl text-xs font-black border ${badge.bg} ${badge.text} ${badge.border}`}>
                            <ShieldCheck className="w-3.5 h-3.5" />
                            {getRoleArabicTitle(emp.role)}
                          </span>
                        </td>

                        {/* Branch (Locked) */}
                        <td className="py-4 px-4">
                          <div className="flex items-center gap-2">
                            <div className="w-6 h-6 rounded-lg bg-amber-50 border border-amber-200 flex items-center justify-center shrink-0">
                              <Lock className="w-3 h-3 text-amber-600" />
                            </div>
                            <div>
                              <p className="font-bold text-slate-800 line-clamp-1">{emp.branch_name}</p>
                              <span className="text-[10px] text-amber-700 font-bold">مقيد بالفرع إدارياً</span>
                            </div>
                          </div>
                        </td>

                        {/* Shift Hours */}
                        <td className="py-4 px-4">
                          <div className="flex items-center gap-1.5 text-slate-700 font-bold">
                            <Clock className="w-3.5 h-3.5 text-blue-500" />
                            <span>{emp.shift_start} - {emp.shift_end}</span>
                          </div>
                          <span className="text-[10px] text-slate-400">وردية 8 ساعات</span>
                        </td>

                        {/* Salary */}
                        <td className="py-4 px-4">
                          <p className="font-black text-slate-900">{emp.basic_salary.toLocaleString()} ل.س</p>
                          {emp.allowances > 0 && (
                            <span className="text-[10px] text-emerald-600 font-bold">+{emp.allowances} ل.س بدلات</span>
                          )}
                        </td>

                        {/* Password Change Permission */}
                        <td className="py-4 px-4">
                          {emp.can_change_password ? (
                            <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg bg-emerald-50 text-emerald-700 border border-emerald-200 text-[11px] font-bold">
                              <Unlock className="w-3 h-3 text-emerald-600" />
                              مسموح بتغييرها
                            </span>
                          ) : (
                            <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg bg-rose-50 text-rose-700 border border-rose-200 text-[11px] font-bold">
                              <Lock className="w-3 h-3 text-rose-600" />
                              بإذن الإدارة فقط
                            </span>
                          )}
                        </td>

                        {/* Admin Action Buttons */}
                        <td className="py-4 px-5">
                          <div className="flex items-center justify-center gap-2">
                            {/* Set / Reset Password from Admin */}
                            <button
                              onClick={() => {
                                setSelectedEmployeeForPassword(emp);
                                setNewPasswordValue(emp.password || '');
                                setIsResetPasswordModalOpen(true);
                              }}
                              className="px-3 py-1.5 rounded-xl bg-blue-50 text-blue-700 hover:bg-blue-100 border border-blue-200 font-bold text-xs flex items-center gap-1.5 transition-all"
                              title="تحديد كلمة السر من الإدارة"
                            >
                              <KeyRound className="w-3.5 h-3.5" />
                              <span>تحديد كلمة السر</span>
                            </button>

                            {/* Toggle Permission Button */}
                            <button
                              onClick={() => handleTogglePasswordPermission(emp.id, emp.can_change_password)}
                              className={`p-2 rounded-xl border transition-all ${
                                emp.can_change_password
                                  ? 'bg-rose-50 text-rose-600 hover:bg-rose-100 border-rose-200'
                                  : 'bg-slate-100 text-slate-600 hover:bg-slate-200 border-slate-200'
                              }`}
                              title={emp.can_change_password ? 'قفل إذن تغيير كلمة السر' : 'منح إذن تغيير كلمة السر'}
                            >
                              {emp.can_change_password ? <Lock className="w-3.5 h-3.5" /> : <Unlock className="w-3.5 h-3.5" />}
                            </button>
                          </div>
                        </td>
                      </tr>
                    );
                  })
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* TAB 2: PASSWORD CHANGE REQUESTS */}
      {activeTab === 'requests' && (
        <div className="bg-white rounded-3xl border border-slate-200 shadow-sm p-6 space-y-4">
          <div className="flex items-center justify-between pb-4 border-b border-slate-100">
            <div>
              <h3 className="text-base font-black text-slate-900">طلبات إذن تعديل كلمات المرور</h3>
              <p className="text-xs text-slate-500 mt-0.5">
                الموظفون لا يستطيعون تعديل كلمات السر الخاصة بهم إلا بعد موافقة الإدارة المركزية من هنا.
              </p>
            </div>
            <span className="text-xs font-bold px-3 py-1 rounded-full bg-slate-100 text-slate-600">
              إجمالي الطلبات: {passwordRequests.length}
            </span>
          </div>

          {passwordRequests.length === 0 ? (
            <div className="py-12 text-center text-slate-400 font-bold">
              لا توجد طلبات تغيير كلمة مرور حالياً
            </div>
          ) : (
            <div className="space-y-3">
              {passwordRequests.map((req) => (
                <div 
                  key={req.id} 
                  className={`p-4 rounded-2xl border transition-all flex flex-col md:flex-row md:items-center justify-between gap-4 ${
                    req.status === 'pending'
                      ? 'bg-amber-50/60 border-amber-200 shadow-xs'
                      : req.status === 'approved'
                      ? 'bg-emerald-50/30 border-emerald-200'
                      : 'bg-slate-50 border-slate-200 opacity-60'
                  }`}
                >
                  <div className="flex items-start gap-3">
                    <div className="w-10 h-10 rounded-2xl bg-amber-100 text-amber-700 flex items-center justify-center shrink-0">
                      <KeyRound className="w-5 h-5" />
                    </div>
                    <div>
                      <div className="flex items-center gap-2">
                        <span className="font-extrabold text-slate-900 text-sm">{req.employee_name}</span>
                        <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-slate-200 text-slate-700">
                          {getRoleArabicTitle(req.role)}
                        </span>
                        <span className="text-xs text-slate-500 font-medium">({req.branch_name})</span>
                      </div>
                      <p className="text-xs text-slate-700 mt-1 font-semibold">
                        سبب الطلب: <span className="text-slate-900 font-medium">{req.reason}</span>
                      </p>
                      <p className="text-[10px] text-slate-400 mt-1">
                        تاريخ الطلب: {new Date(req.requested_at).toLocaleString('ar-SA')}
                      </p>
                    </div>
                  </div>

                  {/* Actions for request */}
                  <div className="flex items-center gap-2 mr-auto md:mr-0">
                    {req.status === 'pending' ? (
                      <>
                        <button
                          onClick={() => handleApproveRequest(req)}
                          className="px-4 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-xs flex items-center gap-1.5 shadow-sm transition-all"
                        >
                          <Check className="w-4 h-4" />
                          <span>موافقة وإتاحة التغيير للموظف</span>
                        </button>
                        <button
                          onClick={() => handleRejectRequest(req)}
                          className="px-4 py-2 rounded-xl bg-rose-100 hover:bg-rose-200 text-rose-700 font-bold text-xs flex items-center gap-1.5 transition-all"
                        >
                          <XCircle className="w-4 h-4" />
                          <span>رفض الطلب</span>
                        </button>
                      </>
                    ) : req.status === 'approved' ? (
                      <span className="inline-flex items-center gap-1 px-3 py-1 rounded-xl bg-emerald-100 text-emerald-800 text-xs font-bold">
                        <CheckCircle2 className="w-4 h-4 text-emerald-600" />
                        تمت الموافقة وتفعيل الصلاحية
                      </span>
                    ) : (
                      <span className="inline-flex items-center gap-1 px-3 py-1 rounded-xl bg-slate-200 text-slate-700 text-xs font-bold">
                        <XCircle className="w-4 h-4 text-slate-500" />
                        تم الرفض من الإدارة
                      </span>
                    )}
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {/* MODAL 1: ADD NEW EMPLOYEE & SET INITIAL PASSWORD */}
      {isAddModalOpen && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl max-w-2xl w-full p-6 md:p-8 shadow-2xl border border-slate-200 max-h-[90vh] overflow-y-auto animate-scale-in">
            <div className="flex items-center justify-between pb-4 border-b border-slate-100">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-2xl bg-blue-100 text-blue-700 flex items-center justify-center">
                  <UserPlus className="w-5 h-5" />
                </div>
                <div>
                  <h3 className="text-lg font-black text-slate-900">فتح حساب موظف وتحديد صلاحياته</h3>
                  <p className="text-xs text-slate-500">الإدارة فقط تحدد كلمة المرور والفرع المخصص</p>
                </div>
              </div>
              <button
                onClick={() => setIsAddModalOpen(false)}
                className="w-8 h-8 rounded-full bg-slate-100 hover:bg-slate-200 text-slate-600 flex items-center justify-center font-bold text-sm"
              >
                ✕
              </button>
            </div>

            <form onSubmit={handleCreateEmployee} className="space-y-4 mt-6">
              {/* Row 1: Full Name & Role */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1.5">
                    الاسم الكامل للموظف <span className="text-rose-500">*</span>
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="مثال: م. أحمد الزهراني"
                    value={newEmployee.full_name}
                    onChange={(e) => setNewEmployee({ ...newEmployee, full_name: e.target.value })}
                    className="w-full px-4 py-2.5 rounded-xl border border-slate-200 text-xs font-semibold focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1.5">
                    الصلاحية / المسمى الوظيفي <span className="text-rose-500">*</span>
                  </label>
                  <select
                    value={newEmployee.role}
                    onChange={(e) => setNewEmployee({ ...newEmployee, role: e.target.value as StaffRole })}
                    className="w-full px-4 py-2.5 rounded-xl border border-slate-200 text-xs font-bold focus:outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="super_admin">مسؤول النظام (Super Admin) - صلاحيات كاملة</option>
                    <option value="general_manager">مدير عام (General Manager) - إدارة وتشغيل</option>
                    <option value="auditor">مدقق (Auditor) - رقابة وتدقيق مالي</option>
                    <option value="accountant">محاسب (Accountant) - رواتب، سحبيات وخصومات</option>
                    <option value="branch_manager">مدير فرع (Branch Manager)</option>
                    <option value="cashier">كاشير ونقاط البيع (Cashier)</option>
                  </select>
                </div>
              </div>

              {/* Row 2: Assigned Branch (Mandatory) */}
              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1.5">
                  الفرع المخصص للموظف (مقفل إدارياً لا يستطيع تغييره) <span className="text-rose-500">*</span>
                </label>
                <div className="relative">
                  <select
                    value={newEmployee.branch_id}
                    onChange={(e) => setNewEmployee({ ...newEmployee, branch_id: e.target.value })}
                    className="w-full px-4 py-2.5 rounded-xl border border-amber-300 bg-amber-50/40 text-xs font-extrabold text-slate-900 focus:outline-none focus:ring-2 focus:ring-amber-500"
                  >
                    {branches.map(b => (
                      <option key={b.id} value={b.id}>
                        {b.name_ar} - ({b.city})
                      </option>
                    ))}
                  </select>
                  <Lock className="w-4 h-4 text-amber-600 absolute left-3 top-1/2 -translate-y-1/2" />
                </div>
                <p className="text-[11px] text-amber-700 font-bold mt-1">
                  🔒 تنبيه أمني: عند تسجيل دخول الموظف، سيكون هذا الفرع ثابتاً ولا يستطيع الانتقال لفرع آخر.
                </p>
              </div>

              {/* Row 3: Username, Email & Phone */}
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1.5">
                    اسم المستخدم (Login Username) <span className="text-rose-500">*</span>
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="مثال: ahmed_cashier"
                    value={newEmployee.username}
                    onChange={(e) => setNewEmployee({ ...newEmployee, username: e.target.value })}
                    className="w-full px-4 py-2.5 rounded-xl border border-slate-200 text-xs font-semibold focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1.5">البريد الإلكتروني</label>
                  <input
                    type="email"
                    placeholder="emp@aldeebmall.com"
                    value={newEmployee.email}
                    onChange={(e) => setNewEmployee({ ...newEmployee, email: e.target.value })}
                    className="w-full px-4 py-2.5 rounded-xl border border-slate-200 text-xs font-semibold focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1.5">رقم الهاتف</label>
                  <input
                    type="tel"
                    placeholder="+966 50 000 0000"
                    value={newEmployee.phone}
                    onChange={(e) => setNewEmployee({ ...newEmployee, phone: e.target.value })}
                    className="w-full px-4 py-2.5 rounded-xl border border-slate-200 text-xs font-semibold focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
              </div>

              {/* Row 4: Password Set By Admin */}
              <div className="bg-slate-50 p-4 rounded-2xl border border-slate-200">
                <div className="flex items-center justify-between mb-2">
                  <label className="block text-xs font-black text-slate-900">
                    كلمة المرور المحددة من الإدارة <span className="text-rose-500">*</span>
                  </label>
                  <button
                    type="button"
                    onClick={() => setNewEmployee({ ...newEmployee, password: Math.random().toString(36).slice(-8) + 'A@' })}
                    className="text-[11px] font-bold text-blue-600 hover:underline flex items-center gap-1"
                  >
                    <Sparkles className="w-3 h-3 text-amber-500" />
                    توليد كلمة سر عشوائية قوية
                  </button>
                </div>
                
                <div className="relative">
                  <input
                    type={showPassword ? 'text' : 'password'}
                    required
                    placeholder="حدد كلمة مرور للموظف..."
                    value={newEmployee.password}
                    onChange={(e) => setNewEmployee({ ...newEmployee, password: e.target.value })}
                    className="w-full pr-4 pl-10 py-2.5 rounded-xl border border-slate-300 text-xs font-bold text-slate-900 focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600"
                  >
                    {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                  </button>
                </div>

                {/* Password restriction checkbox */}
                <div className="mt-3 flex items-center gap-2">
                  <input
                    type="checkbox"
                    id="can_change_pw"
                    checked={newEmployee.can_change_password}
                    onChange={(e) => setNewEmployee({ ...newEmployee, can_change_password: e.target.checked })}
                    className="w-4 h-4 rounded text-blue-600 focus:ring-blue-500 border-slate-300"
                  />
                  <label htmlFor="can_change_pw" className="text-xs font-bold text-slate-700 cursor-pointer">
                    السماح للموظف بتغيير كلمة المرور بنفسه (افتراضياً: غير مسموح له إلا بإذن)
                  </label>
                </div>
              </div>

              {/* Row 5: Shift & Working Hours */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1.5">موعد بدء الدوام (Shift Start)</label>
                  <input
                    type="time"
                    value={newEmployee.shift_start}
                    onChange={(e) => setNewEmployee({ ...newEmployee, shift_start: e.target.value })}
                    className="w-full px-4 py-2.5 rounded-xl border border-slate-200 text-xs font-bold text-slate-800"
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1.5">موعد انتهاء الدوام (Shift End)</label>
                  <input
                    type="time"
                    value={newEmployee.shift_end}
                    onChange={(e) => setNewEmployee({ ...newEmployee, shift_end: e.target.value })}
                    className="w-full px-4 py-2.5 rounded-xl border border-slate-200 text-xs font-bold text-slate-800"
                  />
                </div>
              </div>

              {/* Row 6: Basic Salary & Allowances */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1.5">الراتب الأساسي الشهري (ل.س)</label>
                  <input
                    type="number"
                    min="1000"
                    value={newEmployee.basic_salary}
                    onChange={(e) => setNewEmployee({ ...newEmployee, basic_salary: Number(e.target.value) })}
                    className="w-full px-4 py-2.5 rounded-xl border border-slate-200 text-xs font-bold text-slate-800"
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1.5">البدلات الشهرية (ل.س)</label>
                  <input
                    type="number"
                    min="0"
                    value={newEmployee.allowances}
                    onChange={(e) => setNewEmployee({ ...newEmployee, allowances: Number(e.target.value) })}
                    className="w-full px-4 py-2.5 rounded-xl border border-slate-200 text-xs font-bold text-slate-800"
                  />
                </div>
              </div>

              {/* Submit Buttons */}
              <div className="flex items-center justify-end gap-3 pt-4 border-t border-slate-100">
                <button
                  type="button"
                  onClick={() => setIsAddModalOpen(false)}
                  className="px-5 py-2.5 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 font-bold text-xs"
                >
                  إلغاء
                </button>
                <button
                  type="submit"
                  className="px-6 py-2.5 rounded-xl bg-blue-600 hover:bg-blue-700 text-white font-extrabold text-xs shadow-md shadow-blue-600/30"
                >
                  حفظ وتفعيل الحساب فورياً
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* MODAL 2: ADMIN SET / RESET EMPLOYEE PASSWORD */}
      {isResetPasswordModalOpen && selectedEmployeeForPassword && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl max-w-md w-full p-6 shadow-2xl border border-slate-200 animate-scale-in">
            <div className="flex items-center justify-between pb-4 border-b border-slate-100">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-2xl bg-amber-100 text-amber-700 flex items-center justify-center">
                  <KeyRound className="w-5 h-5" />
                </div>
                <div>
                  <h3 className="text-base font-black text-slate-900">تحديد كلمة مرور الموظف</h3>
                  <p className="text-xs text-slate-500">تحكم إداري مباشر</p>
                </div>
              </div>
              <button
                onClick={() => setIsResetPasswordModalOpen(false)}
                className="w-7 h-7 rounded-full bg-slate-100 hover:bg-slate-200 text-slate-600 flex items-center justify-center text-xs font-bold"
              >
                ✕
              </button>
            </div>

            <div className="mt-4 space-y-4">
              <div className="p-3 bg-slate-50 rounded-xl border border-slate-200 text-xs">
                <p className="font-extrabold text-slate-900">{selectedEmployeeForPassword.full_name}</p>
                <p className="text-slate-500">اسم المستخدم: @{selectedEmployeeForPassword.username}</p>
                <p className="text-slate-500 font-medium">الفرع: {selectedEmployeeForPassword.branch_name}</p>
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1.5">
                  كلمة المرور الجديدة المحددة من الإدارة
                </label>
                <div className="relative">
                  <input
                    type={showPassword ? 'text' : 'password'}
                    value={newPasswordValue}
                    onChange={(e) => setNewPasswordValue(e.target.value)}
                    placeholder="أدخل كلمة المرور الجديدة..."
                    className="w-full pr-4 pl-10 py-2.5 rounded-xl border border-slate-300 text-xs font-black text-slate-900 focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600"
                  >
                    {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                  </button>
                </div>
              </div>

              <div className="p-3 bg-blue-50 rounded-xl border border-blue-200 text-[11px] text-blue-800 font-medium">
                💡 سيتم اعتماد كلمة المرور هذه فورياً، ولن يتمكن الموظف من تغييرها إلا بعد طلب إذن من الإدارة.
              </div>

              <div className="flex items-center justify-end gap-2 pt-3 border-t border-slate-100">
                <button
                  type="button"
                  onClick={() => setIsResetPasswordModalOpen(false)}
                  className="px-4 py-2 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 font-bold text-xs"
                >
                  إلغاء
                </button>
                <button
                  type="button"
                  onClick={handleAdminResetPassword}
                  className="px-5 py-2 rounded-xl bg-blue-600 hover:bg-blue-700 text-white font-extrabold text-xs shadow-md shadow-blue-600/30"
                >
                  حفظ وتعيين كلمة المرور
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
