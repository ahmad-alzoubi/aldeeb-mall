import React, { useState } from 'react';
import { 
  ShieldCheck, 
  Lock, 
  User, 
  ArrowLeft, 
  AlertCircle, 
  Sparkles, 
  Building2, 
  Store, 
  CreditCard,
  KeyRound
} from 'lucide-react';
import { StaffMember } from '../types';
import { getRoleArabicTitle, getRoleBadgeStyle } from '../lib/staffData';
import { staffAuthApi } from '../lib/staffAuthApi';

interface AdminLoginPageProps {
  staffList?: StaffMember[];
  onLogin: (staff: StaffMember, sessionToken: string, jwtToken?: string) => void;
  initialError?: string | null;
}

export const AdminLoginPage: React.FC<AdminLoginPageProps> = ({ 
  staffList = [], 
  onLogin,
  initialError = null 
}) => {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(initialError);
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    const cleanUser = username.trim();
    const cleanPass = password.trim();

    if (!cleanUser || !cleanPass) {
      setError('يرجى إدخال اسم المستخدم وكلمة المرور');
      return;
    }

    setLoading(true);

    try {
      const res = await staffAuthApi.loginStaff(cleanUser, cleanPass);

      if (!res.success || !res.staff || !res.session_token) {
        setError(res.message || 'بيانات الدخول غير صحيحة. يرجى التحقق من اسم المستخدم وكلمة المرور.');
        setLoading(false);
        return;
      }

      // Check account freeze status confirmed by server
      if (!res.staff.is_active) {
        setError('تم تجميد هذا الحساب من قبل الإدارة المركزية.');
        setLoading(false);
        return;
      }

      onLogin(res.staff, res.session_token, res.token);
    } catch (err: any) {
      console.error('Login submit error:', err);
      setError('تعذر الاتصال بخادم المصادقة المركزي. يرجى التحقق من الاتصال بالخادم.');
    } finally {
      setLoading(false);
    }
  };

  const handleSelectPresetUsername = (demoStaff: StaffMember) => {
    setUsername(demoStaff.username);
    const demoPassword = demoStaff.username === 'admin' ? 'admin' 
      : demoStaff.username === 'gm_khaled' ? 'gm123'
      : demoStaff.username === 'cashier_omar' ? 'pos123'
      : demoStaff.username === 'auditor_ziad' ? 'audit123'
      : demoStaff.username === 'accountant_tareq' ? 'acc123'
      : 'admin';
    setPassword(demoPassword);
    setError(null);
    const passField = document.getElementById('admin-password-field');
    if (passField) {
      passField.focus();
    }
  };

  const quickStaffProfiles = [
    staffList.find(s => s.role === 'super_admin') || staffList[0],
    staffList.find(s => s.role === 'general_manager') || staffList[1],
    staffList.find(s => s.role === 'cashier') || staffList.find(s => s.username === 'cashier_omar') || staffList[4],
    staffList.find(s => s.role === 'auditor') || staffList[2],
  ].filter(Boolean) as StaffMember[];

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 flex flex-col justify-center items-center p-4 sm:p-6" dir="rtl">
      {/* Background radial glow */}
      <div className="fixed inset-0 pointer-events-none overflow-hidden">
        <div className="absolute top-1/4 left-1/2 -translate-x-1/2 w-[600px] h-[600px] bg-blue-600/10 rounded-full blur-[140px]" />
        <div className="absolute bottom-1/4 right-1/4 w-[400px] h-[400px] bg-emerald-500/10 rounded-full blur-[120px]" />
      </div>

      <div className="relative w-full max-w-md bg-slate-900/90 backdrop-blur-xl border border-slate-800 rounded-3xl p-6 sm:p-8 shadow-2xl">
        {/* Brand Header */}
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-gradient-to-tr from-blue-600 to-indigo-500 shadow-xl shadow-blue-500/20 text-white mb-4">
            <Store className="w-8 h-8" />
          </div>
          <h1 className="text-2xl font-black text-white tracking-tight">الديب مول — بوابة الإدارة</h1>
          <p className="text-xs text-slate-400 mt-1 font-medium">
            النظام المركزي الموحد لإدارة المبيعات، المخازن ونقاط البيع مع مصادقة الخادم المشفرة
          </p>
        </div>

        {/* Error Notification */}
        {error && (
          <div className="mb-5 p-3.5 bg-rose-500/15 border border-rose-500/30 rounded-2xl flex items-center gap-3 text-rose-300 text-xs font-bold animate-in fade-in duration-200">
            <AlertCircle className="w-4 h-4 text-rose-400 shrink-0" />
            <p className="leading-snug">{error}</p>
          </div>
        )}

        {/* Login Form */}
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-xs font-black text-slate-300 mb-1.5">
              اسم المستخدم أو البريد المهني
            </label>
            <div className="relative">
              <input
                type="text"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                placeholder="مثال: admin أو cashier_omar"
                required
                disabled={loading}
                className="w-full bg-slate-950 border border-slate-800 rounded-xl px-4 py-3 pl-10 text-xs text-white placeholder-slate-500 focus:outline-hidden focus:border-blue-500 focus:ring-1 focus:ring-blue-500 transition-all font-medium disabled:opacity-50"
              />
              <User className="w-4 h-4 text-slate-500 absolute left-3 top-3.5" />
            </div>
          </div>

          <div>
            <label className="block text-xs font-black text-slate-300 mb-1.5">
              كلمة المرور
            </label>
            <div className="relative">
              <input
                id="admin-password-field"
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                required
                disabled={loading}
                className="w-full bg-slate-950 border border-slate-800 rounded-xl px-4 py-3 pl-10 text-xs text-white placeholder-slate-500 focus:outline-hidden focus:border-blue-500 focus:ring-1 focus:ring-blue-500 transition-all font-mono disabled:opacity-50"
              />
              <Lock className="w-4 h-4 text-slate-500 absolute left-3 top-3.5" />
            </div>
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full mt-2 py-3.5 px-4 bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-500 hover:to-indigo-500 text-white rounded-xl font-black text-xs shadow-lg shadow-blue-600/30 transition-all flex items-center justify-center gap-2 cursor-pointer disabled:opacity-50"
          >
            {loading ? (
              <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
            ) : (
              <>
                <span>تسجيل الدخول والتحقق من الخادم</span>
                <ArrowLeft className="w-4 h-4" />
              </>
            )}
          </button>
        </form>

        {/* Preset Roles - Fill username helper (Never bypasses password verification) */}
        {quickStaffProfiles.length > 0 && (
          <div className="mt-8 pt-6 border-t border-slate-800/80">
            <div className="flex items-center justify-between mb-3">
              <span className="text-[11px] font-black text-slate-400">
                حسابات تجريبية (تعبئة اسم المستخدم تلقائياً):
              </span>
              <span className="text-[10px] text-blue-400 bg-blue-500/10 px-2 py-0.5 rounded-full font-bold">
                مصادقة الخادم إلزامية
              </span>
            </div>

            <div className="grid grid-cols-2 gap-2">
              {quickStaffProfiles.map((staff) => {
                const badge = getRoleBadgeStyle(staff.role);
                return (
                  <button
                    key={staff.id}
                    type="button"
                    onClick={() => handleSelectPresetUsername(staff)}
                    className="p-2.5 rounded-xl bg-slate-950/60 hover:bg-slate-800/80 border border-slate-800 hover:border-slate-700 transition-all text-right flex flex-col gap-1 cursor-pointer group"
                    title={`انقر لتعبئة اسم المستخدم (${staff.username})`}
                  >
                    <div className="flex items-center justify-between">
                      <span className="text-[11px] font-bold text-white group-hover:text-blue-400 transition-colors truncate max-w-[100px]">
                        {staff.full_name.split(' ')[0]} {staff.full_name.split(' ')[1] || ''}
                      </span>
                      <span className="text-[9px] px-1.5 py-0.2 rounded font-black bg-blue-900/50 text-blue-300 border border-blue-800/50">
                        {staff.username}
                      </span>
                    </div>
                    <span className="text-[10px] text-slate-400 font-medium truncate">
                      {getRoleArabicTitle(staff.role)}
                    </span>
                  </button>
                );
              })}
            </div>
            <p className="text-[10px] text-slate-500 mt-2 text-center">
              يتم إرسال كافة كلمات المرور إلى قاعدة البيانات المركزية للتحقق المشفر ولا يتم تخزينها في المتصفح.
            </p>
          </div>
        )}

        {/* Security Footer Notice */}
        <div className="mt-6 text-center text-[11px] text-slate-500 flex items-center justify-center gap-1.5 font-medium">
          <ShieldCheck className="w-3.5 h-3.5 text-emerald-500" />
          <span>مصادقة خادم مشفرة Bcrypt وجلسات قابلة للإلغاء الفوري</span>
        </div>
      </div>
    </div>
  );
};
