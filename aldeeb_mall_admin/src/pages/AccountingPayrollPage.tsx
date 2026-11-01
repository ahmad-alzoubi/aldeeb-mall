import React, { useState } from 'react';
import { 
  Calculator, 
  DollarSign, 
  TrendingDown, 
  TrendingUp, 
  Wallet, 
  PlusCircle, 
  FileText, 
  Calendar, 
  Search, 
  Filter, 
  Building2, 
  ShieldCheck, 
  CheckCircle2, 
  Clock, 
  Printer, 
  ArrowUpRight, 
  ArrowDownLeft, 
  AlertTriangle,
  Receipt,
  UserCheck
} from 'lucide-react';
import { StaffMember, PayrollTransaction, PayrollTransactionType, StaffRole, Branch } from '../types';
import { getRoleArabicTitle, getRoleBadgeStyle } from '../lib/staffData';

interface AccountingPayrollPageProps {
  staffList: StaffMember[];
  payrollTransactions: PayrollTransaction[];
  setPayrollTransactions: React.Dispatch<React.SetStateAction<PayrollTransaction[]>>;
  branches: Branch[];
  currentRole: StaffRole;
  currentStaffName: string;
}

export const AccountingPayrollPage: React.FC<AccountingPayrollPageProps> = ({
  staffList,
  payrollTransactions,
  setPayrollTransactions,
  branches,
  currentRole,
  currentStaffName,
}) => {
  const [activeTab, setActiveTab] = useState<'sheet' | 'transactions' | 'audit'>('sheet');
  const [searchQuery, setSearchQuery] = useState('');
  const [filterBranch, setFilterBranch] = useState<string>('all');
  const [filterType, setFilterType] = useState<string>('all');

  // Modals
  const [isAddTxModalOpen, setIsAddTxModalOpen] = useState(false);
  const [selectedEmployeeForTx, setSelectedEmployeeForTx] = useState<StaffMember | null>(null);
  const [txType, setTxType] = useState<PayrollTransactionType>('deduction');
  const [txAmount, setTxAmount] = useState<number>(100);
  const [txReason, setTxReason] = useState<string>('');
  const [txNotes, setTxNotes] = useState<string>('');
  const [toastMessage, setToastMessage] = useState<string | null>(null);

  // Active print slip
  const [activeSlip, setActiveSlip] = useState<PayrollTransaction | null>(null);

  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(null), 4000);
  };

  // Check if role can add/modify accounting transactions (Accountant, General Manager, Super Admin)
  const canAddTransactions = ['super_admin', 'general_manager', 'accountant'].includes(currentRole);

  // Compute stats
  const totalBaseSalaries = staffList.reduce((acc, emp) => acc + emp.basic_salary + emp.allowances, 0);

  const totalWithdrawals = payrollTransactions
    .filter(t => t.type === 'advance_withdrawal' && t.status !== 'pending')
    .reduce((acc, t) => acc + t.amount, 0);

  const totalDeductions = payrollTransactions
    .filter(t => t.type === 'deduction' && t.status !== 'pending')
    .reduce((acc, t) => acc + t.amount, 0);

  const totalBonuses = payrollTransactions
    .filter(t => t.type === 'bonus' && t.status !== 'pending')
    .reduce((acc, t) => acc + t.amount, 0);

  const totalNetPayable = totalBaseSalaries + totalBonuses - totalWithdrawals - totalDeductions;

  // Calculate per-employee totals
  const getEmployeeFinancials = (empId: string) => {
    const empTxs = payrollTransactions.filter(t => t.employee_id === empId && t.status !== 'pending');
    const withdrawals = empTxs.filter(t => t.type === 'advance_withdrawal').reduce((a, b) => a + b.amount, 0);
    const deductions = empTxs.filter(t => t.type === 'deduction').reduce((a, b) => a + b.amount, 0);
    const bonuses = empTxs.filter(t => t.type === 'bonus').reduce((a, b) => a + b.amount, 0);
    const emp = staffList.find(e => e.id === empId);
    const base = emp ? (emp.basic_salary + emp.allowances) : 0;
    const net = base + bonuses - withdrawals - deductions;
    return { withdrawals, deductions, bonuses, base, net, txCount: empTxs.length };
  };

  // Handle Add Transaction (سحب، خصم، مكافأة، صرف)
  const handleCreateTransaction = (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedEmployeeForTx || txAmount <= 0 || !txReason.trim()) {
      alert('يرجى تحديد الموظف والمبلغ والسبب بشكل صحيح');
      return;
    }

    const newTx: PayrollTransaction = {
      id: `pay-tx-${Date.now()}`,
      transaction_number: `PR-2026-${Math.floor(1000 + Math.random() * 9000)}`,
      employee_id: selectedEmployeeForTx.id,
      employee_name: selectedEmployeeForTx.full_name,
      employee_role: selectedEmployeeForTx.role,
      branch_id: selectedEmployeeForTx.branch_id,
      branch_name: selectedEmployeeForTx.branch_name,
      type: txType,
      amount: Number(txAmount),
      reason: txReason.trim(),
      created_by_name: currentStaffName,
      created_by_role: currentRole,
      date: new Date().toISOString(),
      status: 'completed',
      notes: txNotes.trim() || undefined,
    };

    setPayrollTransactions(prev => [newTx, ...prev]);
    setIsAddTxModalOpen(false);

    const typeLabels = {
      salary_payment: 'صرف راتب',
      advance_withdrawal: 'سحب سلفة',
      deduction: 'تسجيل خصم',
      bonus: 'إضافة مكافأة'
    };

    showToast(`✅ تم بنجاح ${typeLabels[txType]} بقيمة ${txAmount.toLocaleString()} ل.س للموظف [${selectedEmployeeForTx.full_name}]`);

    // Reset inputs
    setTxReason('');
    setTxNotes('');
    setTxAmount(100);
  };

  // Filtered transactions
  const filteredTransactions = payrollTransactions.filter(tx => {
    const matchesSearch = 
      tx.employee_name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      tx.transaction_number.toLowerCase().includes(searchQuery.toLowerCase()) ||
      tx.reason.toLowerCase().includes(searchQuery.toLowerCase());

    const matchesBranch = filterBranch === 'all' || tx.branch_id === filterBranch;
    const matchesType = filterType === 'all' || tx.type === filterType;

    return matchesSearch && matchesBranch && matchesType;
  });

  return (
    <div className="space-y-6 pb-12 animate-fade-in" dir="rtl">
      {/* Toast Alert */}
      {toastMessage && (
        <div className="fixed top-24 left-1/2 -translate-x-1/2 z-50 bg-slate-900 text-white px-6 py-3.5 rounded-2xl shadow-2xl border border-emerald-500/30 flex items-center gap-3 text-sm font-bold animate-bounce">
          <CheckCircle2 className="w-5 h-5 text-emerald-400" />
          <span>{toastMessage}</span>
        </div>
      )}

      {/* Header Banner */}
      <div className="bg-gradient-to-r from-slate-900 via-indigo-950 to-slate-900 text-white p-6 md:p-8 rounded-3xl shadow-xl border border-slate-800 relative overflow-hidden">
        <div className="absolute top-0 left-0 w-96 h-96 bg-indigo-500/10 rounded-full blur-3xl pointer-events-none" />

        <div className="flex flex-col md:flex-row md:items-center justify-between gap-6 relative z-10">
          <div>
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-indigo-500/20 text-indigo-300 text-xs font-bold border border-indigo-500/30 mb-3">
              <Calculator className="w-4 h-4 text-indigo-400" />
              <span>نظام المحاسبة، مسير الرواتب والسحبيات والخصومات</span>
            </div>
            <h1 className="text-2xl md:text-3xl font-black tracking-tight text-white">
              مشروع المحاسبة وإدارة الرواتب والخصومات
            </h1>
            <p className="text-slate-300 text-sm mt-2 max-w-2xl leading-relaxed">
              كشوفات الرواتب الشهرية، تقييد السحبيات والسلف، تسجيل الخصومات والجزاءات بدقة، مع صلاحيات مخصصة للمحاسب والمدقق والمدير العام.
            </p>
          </div>

          <div className="flex flex-wrap items-center gap-3">
            {canAddTransactions && (
              <button
                onClick={() => {
                  setSelectedEmployeeForTx(staffList[0] || null);
                  setIsAddTxModalOpen(true);
                }}
                className="px-5 py-3 rounded-2xl bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-700 hover:to-teal-700 text-white font-extrabold text-sm shadow-lg shadow-emerald-600/30 flex items-center gap-2.5 transition-all active:scale-95"
              >
                <PlusCircle className="w-5 h-5" />
                <span>إضافة حركة مالية (سحب / خصم / راتب)</span>
              </button>
            )}
          </div>
        </div>

        {/* Financial KPI Cards */}
        <div className="grid grid-cols-2 sm:grid-cols-5 gap-3 mt-8 pt-6 border-t border-slate-800/80">
          <div className="bg-slate-800/60 backdrop-blur-sm p-4 rounded-2xl border border-slate-700/60">
            <p className="text-xs font-medium text-slate-400">إجمالي الرواتب الأساسية</p>
            <p className="text-xl font-black text-white mt-1">{totalBaseSalaries.toLocaleString()} ل.س</p>
            <span className="text-[10px] text-slate-400 font-semibold">{staffList.length} موظف</span>
          </div>

          <div className="bg-slate-800/60 backdrop-blur-sm p-4 rounded-2xl border border-slate-700/60">
            <p className="text-xs font-medium text-amber-300 flex items-center gap-1">
              <ArrowDownLeft className="w-3.5 h-3.5" />
              إجمالي السحبيات (السلف)
            </p>
            <p className="text-xl font-black text-amber-400 mt-1">-{totalWithdrawals.toLocaleString()} ل.س</p>
            <span className="text-[10px] text-slate-400 font-semibold">مسحوبات مسجلة</span>
          </div>

          <div className="bg-slate-800/60 backdrop-blur-sm p-4 rounded-2xl border border-slate-700/60">
            <p className="text-xs font-medium text-rose-300 flex items-center gap-1">
              <TrendingDown className="w-3.5 h-3.5" />
              إجمالي الخصومات
            </p>
            <p className="text-xl font-black text-rose-400 mt-1">-{totalDeductions.toLocaleString()} ل.س</p>
            <span className="text-[10px] text-slate-400 font-semibold">تأخير، غياب، مخالفات</span>
          </div>

          <div className="bg-slate-800/60 backdrop-blur-sm p-4 rounded-2xl border border-slate-700/60">
            <p className="text-xs font-medium text-blue-300 flex items-center gap-1">
              <TrendingUp className="w-3.5 h-3.5" />
              المكافآت والحوافز
            </p>
            <p className="text-xl font-black text-blue-400 mt-1">+{totalBonuses.toLocaleString()} ل.س</p>
            <span className="text-[10px] text-slate-400 font-semibold">تميز وإنتاجية</span>
          </div>

          <div className="bg-emerald-950/40 backdrop-blur-sm p-4 rounded-2xl border border-emerald-500/40 col-span-2 sm:col-span-1">
            <p className="text-xs font-medium text-emerald-300 flex items-center gap-1">
              <Wallet className="w-3.5 h-3.5" />
              صافي المستحق النهائي
            </p>
            <p className="text-xl font-black text-emerald-400 mt-1">{totalNetPayable.toLocaleString()} ل.س</p>
            <span className="text-[10px] text-emerald-300/80 font-semibold">صافي الصرف</span>
          </div>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex flex-col sm:flex-row items-center justify-between gap-4 bg-white p-4 rounded-3xl border border-slate-200 shadow-sm">
        <div className="flex items-center gap-2 bg-slate-100 p-1.5 rounded-2xl w-full sm:w-auto">
          <button
            onClick={() => setActiveTab('sheet')}
            className={`flex items-center gap-2 px-5 py-2.5 rounded-xl font-bold text-xs transition-all ${
              activeTab === 'sheet'
                ? 'bg-white text-indigo-700 shadow-sm'
                : 'text-slate-600 hover:text-slate-900'
            }`}
          >
            <FileText className="w-4 h-4" />
            <span>كشف مسير رواتب الموظفين ({staffList.length})</span>
          </button>
          <button
            onClick={() => setActiveTab('transactions')}
            className={`flex items-center gap-2 px-5 py-2.5 rounded-xl font-bold text-xs transition-all ${
              activeTab === 'transactions'
                ? 'bg-white text-indigo-700 shadow-sm'
                : 'text-slate-600 hover:text-slate-900'
            }`}
          >
            <Receipt className="w-4 h-4" />
            <span>سجل الحركات، السحبيات والخصومات ({payrollTransactions.length})</span>
          </button>
          <button
            onClick={() => setActiveTab('audit')}
            className={`flex items-center gap-2 px-5 py-2.5 rounded-xl font-bold text-xs transition-all ${
              activeTab === 'audit'
                ? 'bg-white text-indigo-700 shadow-sm'
                : 'text-slate-600 hover:text-slate-900'
            }`}
          >
            <ShieldCheck className="w-4 h-4" />
            <span>تدقيق ومطابقة المحاسبة (Audit)</span>
          </button>
        </div>

        {/* Search */}
        <div className="relative w-full sm:w-72">
          <Search className="w-4 h-4 text-slate-400 absolute right-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            placeholder="بحث بالموظف، الحركة، السبب..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pr-10 pl-4 py-2 rounded-xl bg-slate-50 border border-slate-200 text-xs font-semibold text-slate-800 focus:outline-none focus:ring-2 focus:ring-indigo-500/20"
          />
        </div>
      </div>

      {/* TAB 1: PAYROLL SUMMARY SHEET */}
      {activeTab === 'sheet' && (
        <div className="bg-white rounded-3xl border border-slate-200 shadow-sm overflow-hidden">
          <div className="p-5 border-b border-slate-100 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
            <div>
              <h3 className="font-black text-slate-900 text-sm">كشف استحقاق الرواتب الشهري للموظفين</h3>
              <p className="text-xs text-slate-500">
                يوضح الراتب الأساسي والبدلات بعد خصم السحبيات والخصومات المعتمدة.
              </p>
            </div>
            <div className="flex items-center gap-2">
              <select
                value={filterBranch}
                onChange={(e) => setFilterBranch(e.target.value)}
                className="bg-slate-100 border border-slate-200 text-slate-700 font-bold px-3 py-1.5 rounded-xl text-xs"
              >
                <option value="all">كافة الفروع</option>
                {branches.map(b => (
                  <option key={b.id} value={b.id}>{b.name_ar}</option>
                ))}
              </select>
            </div>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-right border-collapse">
              <thead>
                <tr className="bg-slate-50/80 border-b border-slate-200 text-slate-600 text-[11px] font-black uppercase">
                  <th className="py-4 px-5">الموظف</th>
                  <th className="py-4 px-4">الصلاحية والفرع</th>
                  <th className="py-4 px-4">الأساسي + البدلات</th>
                  <th className="py-4 px-4">إجمالي السحبيات</th>
                  <th className="py-4 px-4">إجمالي الخصومات</th>
                  <th className="py-4 px-4">المكافآت</th>
                  <th className="py-4 px-4">صافي المستحق</th>
                  <th className="py-4 px-5 text-center">إجراء محاسبي سريع</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 text-xs">
                {staffList
                  .filter(emp => filterBranch === 'all' || emp.branch_id === filterBranch)
                  .filter(emp => emp.full_name.includes(searchQuery) || emp.employee_code.includes(searchQuery))
                  .map((emp) => {
                    const badge = getRoleBadgeStyle(emp.role);
                    const fin = getEmployeeFinancials(emp.id);

                    return (
                      <tr key={emp.id} className="hover:bg-slate-50/60 transition-colors">
                        <td className="py-4 px-5">
                          <div className="flex items-center gap-3">
                            <img
                              src={emp.avatar_url || 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=100&q=80'}
                              alt={emp.full_name}
                              className="w-9 h-9 rounded-xl object-cover border border-slate-200"
                            />
                            <div>
                              <p className="font-extrabold text-slate-900">{emp.full_name}</p>
                              <span className="text-[10px] text-slate-500 font-bold">{emp.employee_code}</span>
                            </div>
                          </div>
                        </td>

                        <td className="py-4 px-4">
                          <span className={`inline-block px-2.5 py-0.5 rounded-lg text-[11px] font-bold border ${badge.bg} ${badge.text} ${badge.border}`}>
                            {getRoleArabicTitle(emp.role)}
                          </span>
                          <p className="text-[10px] text-slate-500 font-bold mt-1 line-clamp-1">🔒 {emp.branch_name}</p>
                        </td>

                        <td className="py-4 px-4">
                          <p className="font-black text-slate-900">{fin.base.toLocaleString()} ل.س</p>
                          <span className="text-[10px] text-slate-400">
                            {emp.basic_salary.toLocaleString()} + {emp.allowances}
                          </span>
                        </td>

                        <td className="py-4 px-4">
                          {fin.withdrawals > 0 ? (
                            <span className="font-bold text-amber-600 bg-amber-50 px-2.5 py-1 rounded-lg border border-amber-200">
                              -{fin.withdrawals.toLocaleString()} ل.س
                            </span>
                          ) : (
                            <span className="text-slate-400 font-medium">0 ل.س</span>
                          )}
                        </td>

                        <td className="py-4 px-4">
                          {fin.deductions > 0 ? (
                            <span className="font-bold text-rose-600 bg-rose-50 px-2.5 py-1 rounded-lg border border-rose-200">
                              -{fin.deductions.toLocaleString()} ل.س
                            </span>
                          ) : (
                            <span className="text-slate-400 font-medium">0 ل.س</span>
                          )}
                        </td>

                        <td className="py-4 px-4">
                          {fin.bonuses > 0 ? (
                            <span className="font-bold text-blue-600 bg-blue-50 px-2.5 py-1 rounded-lg border border-blue-200">
                              +{fin.bonuses.toLocaleString()} ل.س
                            </span>
                          ) : (
                            <span className="text-slate-400 font-medium">0 ل.س</span>
                          )}
                        </td>

                        <td className="py-4 px-4">
                          <span className="font-black text-sm text-emerald-700 bg-emerald-50 px-3 py-1 rounded-xl border border-emerald-200 inline-block">
                            {fin.net.toLocaleString()} ل.س
                          </span>
                        </td>

                        <td className="py-4 px-5">
                          <div className="flex items-center justify-center gap-1.5">
                            {canAddTransactions ? (
                              <>
                                <button
                                  onClick={() => {
                                    setSelectedEmployeeForTx(emp);
                                    setTxType('advance_withdrawal');
                                    setTxAmount(500);
                                    setTxReason('سحب سلفة نقدية');
                                    setIsAddTxModalOpen(true);
                                  }}
                                  className="px-2.5 py-1 rounded-lg bg-amber-50 hover:bg-amber-100 text-amber-700 border border-amber-200 font-bold text-[11px] transition-all"
                                  title="إضافة سحب أو سلفة"
                                >
                                  سحب سلفة
                                </button>

                                <button
                                  onClick={() => {
                                    setSelectedEmployeeForTx(emp);
                                    setTxType('deduction');
                                    setTxAmount(150);
                                    setTxReason('خصم تأخير أو غياب');
                                    setIsAddTxModalOpen(true);
                                  }}
                                  className="px-2.5 py-1 rounded-lg bg-rose-50 hover:bg-rose-100 text-rose-700 border border-rose-200 font-bold text-[11px] transition-all"
                                  title="تسجيل خصم مالي"
                                >
                                  تسجيل خصم
                                </button>

                                <button
                                  onClick={() => {
                                    setSelectedEmployeeForTx(emp);
                                    setTxType('salary_payment');
                                    setTxAmount(fin.net);
                                    setTxReason('صرف الراتب الشهري المستحق');
                                    setIsAddTxModalOpen(true);
                                  }}
                                  className="px-2.5 py-1 rounded-lg bg-emerald-50 hover:bg-emerald-100 text-emerald-700 border border-emerald-200 font-bold text-[11px] transition-all"
                                  title="صرف الراتب"
                                >
                                  صرف الراتب
                                </button>
                              </>
                            ) : (
                              <span className="text-[11px] text-slate-400 font-bold">للاطلاع فقط</span>
                            )}
                          </div>
                        </td>
                      </tr>
                    );
                  })}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* TAB 2: TRANSACTIONS LOG */}
      {activeTab === 'transactions' && (
        <div className="bg-white rounded-3xl border border-slate-200 shadow-sm p-6 space-y-4">
          <div className="flex flex-col sm:flex-row items-center justify-between gap-4 pb-4 border-b border-slate-100">
            <div>
              <h3 className="font-black text-slate-900 text-base">سجل قيود الحركات المالية للموظفين</h3>
              <p className="text-xs text-slate-500">
                توثيق كامل لكافة عمليات الخصم، السحبيات، والمكافآت مع بيان المحاسب المعتمد.
              </p>
            </div>

            {/* Filter by Type */}
            <div className="flex items-center gap-2">
              <select
                value={filterType}
                onChange={(e) => setFilterType(e.target.value)}
                className="bg-slate-100 border border-slate-200 text-slate-700 font-bold px-3 py-1.5 rounded-xl text-xs"
              >
                <option value="all">كافة أنواع العمليات</option>
                <option value="advance_withdrawal">سحبيات وسلف فقط</option>
                <option value="deduction">خصومات وجزاءات فقط</option>
                <option value="salary_payment">صرف رواتب فقط</option>
                <option value="bonus">مكافآت فقط</option>
              </select>
            </div>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-right border-collapse">
              <thead>
                <tr className="bg-slate-50/80 border-b border-slate-200 text-slate-600 text-[11px] font-black uppercase">
                  <th className="py-4 px-4">رقم السند والتاريخ</th>
                  <th className="py-4 px-4">الموظف والفرع</th>
                  <th className="py-4 px-4">نوع الحركة</th>
                  <th className="py-4 px-4">المبلغ</th>
                  <th className="py-4 px-4">البيان والسبب</th>
                  <th className="py-4 px-4">المعتمد / المدخل</th>
                  <th className="py-4 px-4 text-center">طباعة سند</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 text-xs">
                {filteredTransactions.length === 0 ? (
                  <tr>
                    <td colSpan={7} className="py-12 text-center text-slate-400 font-bold">
                      لا توجد قيود مالية مطابقة لخيارات البحث
                    </td>
                  </tr>
                ) : (
                  filteredTransactions.map((tx) => {
                    const isDeduction = tx.type === 'deduction';
                    const isWithdrawal = tx.type === 'advance_withdrawal';
                    const isBonus = tx.type === 'bonus';
                    const isSalary = tx.type === 'salary_payment';

                    return (
                      <tr key={tx.id} className="hover:bg-slate-50/60 transition-colors">
                        <td className="py-4 px-4">
                          <p className="font-black text-slate-900">{tx.transaction_number}</p>
                          <span className="text-[10px] text-slate-400">
                            {new Date(tx.date).toLocaleDateString('ar-SA')}
                          </span>
                        </td>

                        <td className="py-4 px-4">
                          <p className="font-extrabold text-slate-900">{tx.employee_name}</p>
                          <span className="text-[10px] text-slate-500 font-bold">🔒 {tx.branch_name}</span>
                        </td>

                        <td className="py-4 px-4">
                          {isDeduction && (
                            <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg bg-rose-50 text-rose-700 border border-rose-200 font-black text-[11px]">
                              <TrendingDown className="w-3.5 h-3.5 text-rose-600" />
                              خصم مالي
                            </span>
                          )}
                          {isWithdrawal && (
                            <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg bg-amber-50 text-amber-700 border border-amber-200 font-black text-[11px]">
                              <ArrowDownLeft className="w-3.5 h-3.5 text-amber-600" />
                              سحب سلفة
                            </span>
                          )}
                          {isBonus && (
                            <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg bg-blue-50 text-blue-700 border border-blue-200 font-black text-[11px]">
                              <TrendingUp className="w-3.5 h-3.5 text-blue-600" />
                              مكافأة تميز
                            </span>
                          )}
                          {isSalary && (
                            <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg bg-emerald-50 text-emerald-700 border border-emerald-200 font-black text-[11px]">
                              <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600" />
                              صرف راتب
                            </span>
                          )}
                        </td>

                        <td className="py-4 px-4">
                          <span className={`font-black text-sm ${
                            isDeduction || isWithdrawal ? 'text-rose-600' : 'text-emerald-600'
                          }`}>
                            {isDeduction || isWithdrawal ? '-' : '+'}{tx.amount.toLocaleString()} ل.س
                          </span>
                        </td>

                        <td className="py-4 px-4 max-w-xs">
                          <p className="font-bold text-slate-800 line-clamp-2">{tx.reason}</p>
                          {tx.notes && <p className="text-[10px] text-slate-400 mt-0.5">{tx.notes}</p>}
                        </td>

                        <td className="py-4 px-4">
                          <p className="font-extrabold text-slate-700">{tx.created_by_name}</p>
                          <span className="text-[10px] text-slate-400">معتمد بالنظام</span>
                        </td>

                        <td className="py-4 px-4 text-center">
                          <button
                            onClick={() => setActiveSlip(tx)}
                            className="p-2 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 transition-all"
                            title="طباعة سند الصرف / الخصم"
                          >
                            <Printer className="w-4 h-4" />
                          </button>
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

      {/* TAB 3: AUDITING & INTEGRITY */}
      {activeTab === 'audit' && (
        <div className="bg-white rounded-3xl border border-slate-200 shadow-sm p-6 md:p-8 space-y-6">
          <div className="flex items-center gap-4 p-4 rounded-2xl bg-emerald-50 border border-emerald-200">
            <div className="w-12 h-12 rounded-2xl bg-emerald-100 text-emerald-700 flex items-center justify-center shrink-0">
              <ShieldCheck className="w-6 h-6" />
            </div>
            <div>
              <h4 className="font-black text-slate-900 text-base">شهادة المطابقة والرقابة المالية للمدقق</h4>
              <p className="text-xs text-slate-600 mt-1">
                كافة العمليات مقيدة بسجلات غير قابلة للتلاعب، مع توثيق اسم المحاسب والمدير لكل حركة مالية وسحبيات وخصومات.
              </p>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="p-5 rounded-2xl bg-slate-50 border border-slate-200">
              <p className="text-xs font-bold text-slate-500">حالة الربط المصرفي وحماية الأجور</p>
              <div className="flex items-center gap-2 mt-2">
                <CheckCircle2 className="w-5 h-5 text-emerald-600" />
                <span className="text-sm font-black text-slate-900">نظام WPS متوافق 100%</span>
              </div>
              <p className="text-[11px] text-slate-500 mt-1">مسيرات الرواتب جاهزة للتصدير المالي الموحد</p>
            </div>

            <div className="p-5 rounded-2xl bg-slate-50 border border-slate-200">
              <p className="text-xs font-bold text-slate-500">نسبة السحبيات إلى إجمالي الرواتب</p>
              <div className="flex items-center gap-2 mt-2">
                <span className="text-sm font-black text-amber-600">
                  {totalBaseSalaries > 0 ? ((totalWithdrawals / totalBaseSalaries) * 100).toFixed(1) : 0}%
                </span>
                <span className="text-xs font-bold text-slate-600">(ضمن الحد المسموح &lt; 30%)</span>
              </div>
              <p className="text-[11px] text-slate-500 mt-1">لا توجد سلف متجاوزة للسقف الائتماني</p>
            </div>

            <div className="p-5 rounded-2xl bg-slate-50 border border-slate-200">
              <p className="text-xs font-bold text-slate-500">صلاحيات الإدخال والاعتماد</p>
              <div className="flex items-center gap-2 mt-2">
                <UserCheck className="w-5 h-5 text-blue-600" />
                <span className="text-sm font-black text-slate-900">محاسب + مدير عام فقط</span>
              </div>
              <p className="text-[11px] text-slate-500 mt-1">المدقق يملك حق الرقابة والكشف المباشر</p>
            </div>
          </div>
        </div>
      )}

      {/* MODAL: ADD TRANSACTION (سحب، خصم، مكافأة، صرف) */}
      {isAddTxModalOpen && selectedEmployeeForTx && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl max-w-lg w-full p-6 md:p-8 shadow-2xl border border-slate-200 animate-scale-in">
            <div className="flex items-center justify-between pb-4 border-b border-slate-100">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-2xl bg-indigo-100 text-indigo-700 flex items-center justify-center">
                  <Calculator className="w-5 h-5" />
                </div>
                <div>
                  <h3 className="text-lg font-black text-slate-900">إضافة حركة مالية للموظف</h3>
                  <p className="text-xs text-slate-500">سحب سلفة، تسجيل خصم، أو صرف راتب</p>
                </div>
              </div>
              <button
                onClick={() => setIsAddTxModalOpen(false)}
                className="w-8 h-8 rounded-full bg-slate-100 hover:bg-slate-200 text-slate-600 flex items-center justify-center text-xs font-bold"
              >
                ✕
              </button>
            </div>

            <form onSubmit={handleCreateTransaction} className="space-y-4 mt-6">
              {/* Employee Selector */}
              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1.5">اختيار الموظف</label>
                <select
                  value={selectedEmployeeForTx.id}
                  onChange={(e) => {
                    const emp = staffList.find(x => x.id === e.target.value);
                    if (emp) setSelectedEmployeeForTx(emp);
                  }}
                  className="w-full px-4 py-2.5 rounded-xl border border-slate-200 text-xs font-bold text-slate-800 focus:outline-none focus:ring-2 focus:ring-indigo-500"
                >
                  {staffList.map(e => (
                    <option key={e.id} value={e.id}>
                      {e.full_name} ({getRoleArabicTitle(e.role)}) - {e.branch_name}
                    </option>
                  ))}
                </select>
              </div>

              {/* Transaction Type */}
              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1.5">نوع الحركة المالية</label>
                <div className="grid grid-cols-2 gap-2">
                  <button
                    type="button"
                    onClick={() => {
                      setTxType('advance_withdrawal');
                      setTxReason('سحب سلفة من الراتب');
                    }}
                    className={`py-2 px-3 rounded-xl border text-xs font-bold flex items-center justify-center gap-2 transition-all ${
                      txType === 'advance_withdrawal'
                        ? 'bg-amber-500 text-white border-amber-600 shadow-sm'
                        : 'bg-slate-50 text-slate-700 border-slate-200'
                    }`}
                  >
                    <ArrowDownLeft className="w-4 h-4" />
                    <span>سحب سلفة / سحبيات</span>
                  </button>

                  <button
                    type="button"
                    onClick={() => {
                      setTxType('deduction');
                      setTxReason('خصم غياب أو تأخير');
                    }}
                    className={`py-2 px-3 rounded-xl border text-xs font-bold flex items-center justify-center gap-2 transition-all ${
                      txType === 'deduction'
                        ? 'bg-rose-600 text-white border-rose-700 shadow-sm'
                        : 'bg-slate-50 text-slate-700 border-slate-200'
                    }`}
                  >
                    <TrendingDown className="w-4 h-4" />
                    <span>تسجيل خصم مالي</span>
                  </button>

                  <button
                    type="button"
                    onClick={() => {
                      setTxType('bonus');
                      setTxReason('مكافأة تميز وإتقان');
                    }}
                    className={`py-2 px-3 rounded-xl border text-xs font-bold flex items-center justify-center gap-2 transition-all ${
                      txType === 'bonus'
                        ? 'bg-blue-600 text-white border-blue-700 shadow-sm'
                        : 'bg-slate-50 text-slate-700 border-slate-200'
                    }`}
                  >
                    <TrendingUp className="w-4 h-4" />
                    <span>إضافة مكافأة</span>
                  </button>

                  <button
                    type="button"
                    onClick={() => {
                      setTxType('salary_payment');
                      setTxReason('صرف الراتب الشهري');
                    }}
                    className={`py-2 px-3 rounded-xl border text-xs font-bold flex items-center justify-center gap-2 transition-all ${
                      txType === 'salary_payment'
                        ? 'bg-emerald-600 text-white border-emerald-700 shadow-sm'
                        : 'bg-slate-50 text-slate-700 border-slate-200'
                    }`}
                  >
                    <CheckCircle2 className="w-4 h-4" />
                    <span>صرف راتب</span>
                  </button>
                </div>
              </div>

              {/* Amount */}
              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1.5">المبلغ بالليرة السورية (ل.س)</label>
                <div className="relative">
                  <input
                    type="number"
                    required
                    min="1"
                    value={txAmount}
                    onChange={(e) => setTxAmount(Number(e.target.value))}
                    className="w-full pr-4 pl-12 py-2.5 rounded-xl border border-slate-300 text-base font-black text-slate-900 focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  />
                  <span className="absolute left-3 top-1/2 -translate-y-1/2 text-xs font-bold text-slate-400">ل.س</span>
                </div>
              </div>

              {/* Reason */}
              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1.5">سبب القيد / البيان</label>
                <input
                  type="text"
                  required
                  placeholder="مثال: خصم تأخير 3 ساعات / سلفة طارئة..."
                  value={txReason}
                  onChange={(e) => setTxReason(e.target.value)}
                  className="w-full px-4 py-2.5 rounded-xl border border-slate-200 text-xs font-semibold focus:outline-none focus:ring-2 focus:ring-indigo-500"
                />
              </div>

              {/* Additional notes */}
              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1.5">ملاحظات إضافية (اختياري)</label>
                <textarea
                  rows={2}
                  placeholder="ملاحظات المحاسب أو السند البنكي..."
                  value={txNotes}
                  onChange={(e) => setTxNotes(e.target.value)}
                  className="w-full px-4 py-2 rounded-xl border border-slate-200 text-xs font-semibold focus:outline-none focus:ring-2 focus:ring-indigo-500"
                />
              </div>

              <div className="flex items-center justify-end gap-2 pt-4 border-t border-slate-100">
                <button
                  type="button"
                  onClick={() => setIsAddTxModalOpen(false)}
                  className="px-4 py-2 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 font-bold text-xs"
                >
                  إلغاء
                </button>
                <button
                  type="submit"
                  className="px-6 py-2 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white font-black text-xs shadow-md shadow-indigo-600/30"
                >
                  تسجيل واعتماد القيد المالي
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* PRINT SLIP MODAL */}
      {activeSlip && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl max-w-md w-full p-6 shadow-2xl border border-slate-200 text-right">
            <div className="text-center border-b border-slate-200 pb-4">
              <h2 className="text-lg font-black text-slate-900">سند حركة مالية معتمد</h2>
              <p className="text-xs text-slate-500">الديب مول - الإدارة المالية والمحاسبة</p>
              <p className="text-[11px] font-bold text-slate-400 mt-1">رقم السند: {activeSlip.transaction_number}</p>
            </div>

            <div className="py-4 space-y-2.5 text-xs">
              <div className="flex justify-between">
                <span className="text-slate-500">اسم الموظف:</span>
                <span className="font-extrabold text-slate-900">{activeSlip.employee_name}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-500">الفرع المخصص:</span>
                <span className="font-bold text-slate-800">{activeSlip.branch_name}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-500">نوع الحركة:</span>
                <span className="font-black text-slate-900">
                  {activeSlip.type === 'deduction' ? 'خصم مالي' : activeSlip.type === 'advance_withdrawal' ? 'سحب سلفة' : activeSlip.type === 'salary_payment' ? 'صرف راتب' : 'مكافأة'}
                </span>
              </div>
              <div className="flex justify-between text-base font-black border-t border-b border-slate-100 py-2">
                <span>المبلغ:</span>
                <span className="text-blue-700">{activeSlip.amount.toLocaleString()} ل.س</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-500">السبب / البيان:</span>
                <span className="font-bold text-slate-800">{activeSlip.reason}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-500">المدخل / المعتمد:</span>
                <span className="font-bold text-slate-800">{activeSlip.created_by_name}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-500">التاريخ:</span>
                <span className="font-medium text-slate-700">{new Date(activeSlip.date).toLocaleString('ar-SA')}</span>
              </div>
            </div>

            <div className="flex items-center justify-between pt-4 border-t border-slate-200">
              <button
                onClick={() => window.print()}
                className="px-4 py-2 rounded-xl bg-blue-600 hover:bg-blue-700 text-white font-bold text-xs flex items-center gap-1.5"
              >
                <Printer className="w-4 h-4" />
                <span>طباعة السند</span>
              </button>
              <button
                onClick={() => setActiveSlip(null)}
                className="px-4 py-2 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 font-bold text-xs"
              >
                إغلاق
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
