import React, { useState, useEffect } from 'react';
import { 
  Bell, 
  Volume2, 
  VolumeX, 
  RefreshCw, 
  Menu, 
  Clock, 
  Lock, 
  ShieldCheck, 
  User, 
  ChevronDown, 
  KeyRound, 
  Send, 
  CheckCircle2, 
  AlertCircle, 
  LogOut, 
  Sparkles,
  Building2,
  Calendar,
  HelpCircle
} from 'lucide-react';
import { StaffMember, StaffRole, Branch } from '../types';
import { calculateShiftRemaining, getRoleArabicTitle, getRoleBadgeStyle, INITIAL_STAFF } from '../lib/staffData';
import { useHelp } from './common/InteractiveHelpSystem';

interface HeaderProps {
  title: string;
  subtitle?: string;
  soundEnabled: boolean;
  setSoundEnabled: (val: boolean) => void;
  onRefresh: () => void;
  onToggleMobileMenu?: () => void;
  currentUser?: StaffMember;
  staffList?: StaffMember[];
  onSwitchUser?: (staff: StaffMember) => void;
  onRequestPasswordChange?: (reason: string) => void;
  onDirectChangePassword?: (newPw: string) => void;
  branches?: Branch[];
  activeBranchId?: string;
  onSwitchBranch?: (branchId: string) => void;
  isBranchSwitching?: boolean;
}

export const Header: React.FC<HeaderProps> = ({
  title,
  subtitle,
  soundEnabled,
  setSoundEnabled,
  onRefresh,
  onToggleMobileMenu,
  currentUser = INITIAL_STAFF[0],
  staffList = INITIAL_STAFF,
  onSwitchUser = () => {},
  onRequestPasswordChange = () => {},
  onDirectChangePassword = () => {},
  branches = [],
  activeBranchId = 'all',
  onSwitchBranch,
  isBranchSwitching = false,
}) => {
  const { isHelpModeActive, toggleHelpMode } = useHelp();
  // Live shift countdown state
  const [shiftStats, setShiftStats] = useState(() => 
    calculateShiftRemaining(currentUser.shift_start || '08:00', currentUser.shift_end || '16:00')
  );

  // Dropdown & Modals state
  const [isProfileMenuOpen, setIsProfileMenuOpen] = useState(false);
  const [isNotificationsOpen, setIsNotificationsOpen] = useState(false);
  const [notifications, setNotifications] = useState([
    {
      id: 'n1',
      title: 'طلب جديد #ORD-9842',
      desc: 'طلب توصيل إكسبريس (15 دقيقة) بقيمة 185.00 ل.س',
      time: 'قبل 2 دقيقة',
      type: 'order',
      unread: true,
    },
    {
      id: 'n2',
      title: 'تنبيه مخزون منخفض ⚠️',
      desc: 'متبقي 3 قطع فقط من حليب نادك 2 لتر في فرع الحمراء',
      time: 'قبل 10 دقائق',
      type: 'inventory',
      unread: true,
    },
    {
      id: 'n3',
      title: 'مزامنة Supabase سحابية',
      desc: 'تمت مزامنة الإعدادات والكتالوج السحابي بنجاح',
      time: 'قبل 25 دقيقة',
      type: 'cloud',
      unread: false,
    },
    {
      id: 'n4',
      title: 'تسجيل دخول وردية كاشير',
      desc: 'بدء وردية جديدة للموظف: سامر خليل على POS-02',
      time: 'قبل 45 دقيقة',
      type: 'staff',
      unread: false,
    },
  ]);
  const [isPasswordModalOpen, setIsPasswordModalOpen] = useState(false);
  const [passwordRequestReason, setPasswordRequestReason] = useState('');
  const [directNewPassword, setDirectNewPassword] = useState('');
  const [requestSentNotice, setRequestSentNotice] = useState(false);

  // Live timer tick every second
  useEffect(() => {
    const timer = setInterval(() => {
      setShiftStats(
        calculateShiftRemaining(currentUser.shift_start || '08:00', currentUser.shift_end || '16:00')
      );
    }, 1000);
    return () => clearInterval(timer);
  }, [currentUser.shift_start, currentUser.shift_end]);

  const badge = getRoleBadgeStyle(currentUser.role);

  // Handle password change action
  const handlePasswordAction = (e: React.FormEvent) => {
    e.preventDefault();
    if (currentUser.can_change_password) {
      if (!directNewPassword.trim()) return;
      onDirectChangePassword(directNewPassword.trim());
      setIsPasswordModalOpen(false);
      setDirectNewPassword('');
    } else {
      if (!passwordRequestReason.trim()) return;
      onRequestPasswordChange(passwordRequestReason.trim());
      setRequestSentNotice(true);
      setTimeout(() => {
        setRequestSentNotice(false);
        setIsPasswordModalOpen(false);
        setPasswordRequestReason('');
      }, 2500);
    }
  };

  return (
    <header className="h-20 bg-white border-b border-slate-200 px-4 md:px-8 flex items-center justify-between shadow-sm sticky top-0 z-30 select-none">
      {/* Right Side: Title & Mobile Menu */}
      <div className="flex items-center gap-3">
        {onToggleMobileMenu && (
          <button
            onClick={onToggleMobileMenu}
            className="lg:hidden p-2 rounded-xl text-slate-600 hover:bg-slate-100 border border-slate-200"
            title="القائمة"
          >
            <Menu className="w-5 h-5" />
          </button>
        )}
        <div>
          <h2 className="text-lg md:text-xl font-extrabold text-slate-800">{title}</h2>
          {subtitle && <p className="text-xs text-slate-500 font-medium hidden sm:block">{subtitle}</p>}
        </div>

        {/* Branch Selector with Strict Isolation */}
        {branches && branches.length > 0 && onSwitchBranch && (
          <div className="hidden md:flex items-center gap-2 bg-slate-100 hover:bg-slate-200/80 px-3 py-1.5 rounded-2xl border border-slate-200 mr-2 transition-all">
            <Building2 className="w-4 h-4 text-blue-600 shrink-0" />
            <div className="flex flex-col text-right">
              <span className="text-[10px] text-slate-400 font-bold leading-none">الفرع النشط:</span>
              <select
                value={activeBranchId}
                onChange={(e) => onSwitchBranch(e.target.value)}
                className="bg-transparent font-black text-xs text-slate-800 focus:outline-none cursor-pointer pr-0.5"
              >
                <option value="all">🌐 كافة الفروع (مؤشرات عامة)</option>
                {branches.map(b => (
                  <option key={b.id} value={b.id}>
                    📍 {b.name_ar}
                  </option>
                ))}
              </select>
            </div>
            {isBranchSwitching && (
              <span className="w-2 h-2 rounded-full bg-blue-600 animate-ping shrink-0" />
            )}
          </div>
        )}
      </div>

      {/* Center: Live Shift Countdown Widget */}
      <div className="hidden xl:flex items-center gap-3 bg-gradient-to-r from-slate-900 to-blue-950 text-white px-4 py-2 rounded-2xl border border-slate-800 shadow-md">
        <div className="w-8 h-8 rounded-xl bg-blue-600/30 border border-blue-500/40 flex items-center justify-center text-blue-400">
          <Clock className={`w-4 h-4 ${shiftStats.isOvertime ? 'text-amber-400 animate-spin' : 'animate-pulse'}`} />
        </div>
        <div>
          <div className="flex items-center gap-2">
            <span className="text-[11px] font-medium text-slate-300">
              {shiftStats.isOvertime 
                ? '⚠️ تنبيه الدوام:' 
                : shiftStats.isBeforeShift 
                ? '⏳ موعد بدء الوردية:' 
                : '⏳ كم باقي على انتهاء دوامك:'}
            </span>
            <span className="text-xs font-black tracking-wide text-amber-300 font-mono">
              {shiftStats.remainingText}
            </span>
          </div>

          <div className="flex items-center gap-2 mt-1">
            <div className="w-36 h-1.5 bg-slate-800 rounded-full overflow-hidden border border-slate-700/50">
              <div 
                className={`h-full transition-all duration-1000 ${
                  shiftStats.isOvertime ? 'bg-amber-500' : 'bg-emerald-500'
                }`}
                style={{ width: `${shiftStats.percent}%` }}
              />
            </div>
            <span className="text-[10px] text-slate-400 font-bold">
              {currentUser.shift_start} - {currentUser.shift_end}
            </span>
          </div>
        </div>
      </div>

      {/* Left Side: Audio, Refresh, and User Profile Badge */}
      <div className="flex items-center gap-3">
        {/* Interactive 3-Clicks Help Mode Toggle */}
        <button
          onClick={toggleHelpMode}
          className={`flex items-center gap-1.5 px-3 py-1.5 rounded-xl border text-xs font-bold transition-all ${
            isHelpModeActive
              ? 'bg-amber-500 text-white border-amber-600 shadow-md shadow-amber-500/30 animate-pulse'
              : 'bg-amber-50 text-amber-800 border-amber-200 hover:bg-amber-100'
          }`}
          title="تفعيل وضع المساعدة التفاعلي والشروحات (أو انقر 3 مرات على أي ميزة)"
        >
          <HelpCircle className="w-4 h-4 text-amber-600" />
          <span className="hidden sm:inline">{isHelpModeActive ? 'وضع المساعدة نشط 💡' : 'شرح الوظائف'}</span>
        </button>

        {/* Audio Ping Toggle */}
        <button
          onClick={() => setSoundEnabled(!soundEnabled)}
          className={`hidden sm:flex items-center gap-1.5 px-3 py-1.5 rounded-xl border text-xs font-bold transition-all ${
            soundEnabled
              ? 'bg-blue-50 text-blue-700 border-blue-200 hover:bg-blue-100'
              : 'bg-slate-100 text-slate-500 border-slate-200 hover:bg-slate-200'
          }`}
          title="تنبيه صوتي للطلبات"
        >
          {soundEnabled ? <Volume2 className="w-4 h-4 text-blue-600" /> : <VolumeX className="w-4 h-4" />}
          <span className="hidden md:inline">{soundEnabled ? 'تنبيه مفعل' : 'صامت'}</span>
        </button>

        {/* Refresh Button */}
        <button
          onClick={onRefresh}
          className="p-2.5 rounded-xl text-slate-600 hover:text-blue-600 hover:bg-slate-100 border border-slate-200 transition-all"
          title="تحديث البيانات"
        >
          <RefreshCw className="w-4 h-4" />
        </button>

        {/* Notifications */}
        <div className="relative">
          <button
            onClick={() => setIsNotificationsOpen(!isNotificationsOpen)}
            className="p-2.5 rounded-xl text-slate-600 hover:text-blue-600 hover:bg-slate-100 border border-slate-200 transition-all relative cursor-pointer"
            title="الإشعارات والتنبيهات الفورية"
          >
            <Bell className="w-4 h-4" />
            {notifications.some(n => n.unread) && (
              <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-red-500 rounded-full animate-ping" />
            )}
          </button>

          {isNotificationsOpen && (
            <div className="absolute left-0 sm:right-auto mt-2 w-80 sm:w-96 bg-white rounded-2xl shadow-2xl border border-slate-200 z-50 overflow-hidden animate-in fade-in slide-in-from-top-2 duration-150">
              <div className="p-3.5 bg-slate-900 text-white flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <Bell className="w-4 h-4 text-emerald-400" />
                  <span className="text-xs font-black">الإشعارات والتنبيهات السحابية</span>
                  <span className="bg-red-500 text-white text-[10px] font-bold px-1.5 py-0.5 rounded-full">
                    {notifications.filter(n => n.unread).length}
                  </span>
                </div>
                <button
                  onClick={() => setNotifications(prev => prev.map(n => ({ ...n, unread: false })))}
                  className="text-[11px] text-slate-300 hover:text-white underline cursor-pointer"
                >
                  تحديد كمقروء
                </button>
              </div>

              <div className="max-h-80 overflow-y-auto divide-y divide-slate-100">
                {notifications.map(n => (
                  <div
                    key={n.id}
                    onClick={() => setNotifications(prev => prev.map(item => item.id === n.id ? { ...item, unread: false } : item))}
                    className={`p-3 text-right hover:bg-slate-50 transition-colors cursor-pointer ${
                      n.unread ? 'bg-blue-50/50' : ''
                    }`}
                  >
                    <div className="flex items-start justify-between gap-2">
                      <div className="flex items-center gap-1.5">
                        {n.unread && <span className="w-2 h-2 rounded-full bg-blue-600" />}
                        <p className="text-xs font-bold text-slate-800">{n.title}</p>
                      </div>
                      <span className="text-[10px] text-slate-400 font-medium whitespace-nowrap">{n.time}</span>
                    </div>
                    <p className="text-[11px] text-slate-600 mt-1 leading-relaxed pr-3.5">{n.desc}</p>
                  </div>
                ))}
              </div>

              <div className="p-2.5 bg-slate-50 border-t border-slate-100 text-center text-[10px] text-slate-500 font-medium flex items-center justify-center gap-1.5">
                <Sparkles className="w-3 h-3 text-emerald-600" />
                <span>مربوطة بسحابة Supabase ومزامنة فورية للطلبات</span>
              </div>
            </div>
          )}
        </div>

        {/* USER PROFILE & SHIFT SUMMARY DROPDOWN */}
        <div className="relative">
          <button
            onClick={() => setIsProfileMenuOpen(!isProfileMenuOpen)}
            className="flex items-center gap-2.5 p-1.5 pr-2.5 bg-slate-50 hover:bg-slate-100 border border-slate-200 rounded-2xl transition-all cursor-pointer"
          >
            <img
              src={currentUser.avatar_url || 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=100&q=80'}
              alt={currentUser.full_name}
              className="w-8 h-8 rounded-xl object-cover border border-slate-200"
            />
            <div className="text-right hidden sm:block">
              <p className="text-xs font-black text-slate-900 leading-tight">{currentUser.full_name}</p>
              <div className="flex items-center gap-1 mt-0.5">
                <span className={`text-[10px] font-black px-1.5 py-0.2 rounded-md border ${badge.bg} ${badge.text} ${badge.border}`}>
                  {getRoleArabicTitle(currentUser.role)}
                </span>
                <span className="text-[10px] text-amber-700 font-bold flex items-center gap-0.5">
                  <Lock className="w-2.5 h-2.5" />
                  {currentUser.branch_name.slice(0, 16)}...
                </span>
              </div>
            </div>
            <ChevronDown className="w-4 h-4 text-slate-400" />
          </button>

          {/* DROPDOWN MENU */}
          {isProfileMenuOpen && (
            <>
              <div
                className="fixed inset-0 z-40"
                onClick={() => setIsProfileMenuOpen(false)}
              />
              <div className="absolute left-0 mt-2 w-80 bg-white rounded-3xl shadow-2xl border border-slate-200 z-50 p-4 text-right animate-scale-in">
                {/* User Header in Dropdown */}
                <div className="flex items-center gap-3 pb-3 border-b border-slate-100">
                  <img
                    src={currentUser.avatar_url || 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=100&q=80'}
                    alt={currentUser.full_name}
                    className="w-12 h-12 rounded-2xl object-cover border border-slate-200"
                  />
                  <div>
                    <h4 className="font-black text-slate-900 text-sm">{currentUser.full_name}</h4>
                    <p className="text-[11px] text-slate-500 font-medium">{currentUser.email}</p>
                    <span className={`inline-block mt-1 text-[10px] font-black px-2 py-0.5 rounded-md border ${badge.bg} ${badge.text} ${badge.border}`}>
                      {getRoleArabicTitle(currentUser.role)}
                    </span>
                  </div>
                </div>

                {/* Shift Details & Locked Branch Box */}
                <div className="my-3 p-3 bg-slate-50 rounded-2xl border border-slate-200 text-xs space-y-2">
                  <div className="flex items-center justify-between">
                    <span className="text-slate-500 font-medium">الفرع المخصص:</span>
                    <span className="font-extrabold text-amber-800 flex items-center gap-1">
                      <Lock className="w-3 h-3 text-amber-600" />
                      {currentUser.branch_name}
                    </span>
                  </div>
                  <div className="text-[10px] text-amber-700 bg-amber-50 p-1.5 rounded-lg border border-amber-200 font-bold">
                    🔒 الفرع مقيد إدارياً ولا يمكنك تغييره بنفسك
                  </div>

                  <div className="flex items-center justify-between pt-1 border-t border-slate-200">
                    <span className="text-slate-500 font-medium">ساعات الوردية:</span>
                    <span className="font-bold text-slate-800">
                      من {currentUser.shift_start} إلى {currentUser.shift_end}
                    </span>
                  </div>

                  <div className="flex items-center justify-between">
                    <span className="text-slate-500 font-medium">متبقي على نهاية الدوام:</span>
                    <span className="font-black text-blue-700 font-mono">
                      {shiftStats.remainingText}
                    </span>
                  </div>
                </div>

                {/* Password Change Action */}
                <div className="pt-2 border-t border-slate-100">
                  <button
                    onClick={() => {
                      setIsProfileMenuOpen(false);
                      setIsPasswordModalOpen(true);
                    }}
                    className="w-full flex items-center justify-between px-3 py-2 rounded-xl text-xs font-bold text-slate-700 hover:bg-slate-100 transition-colors"
                  >
                    <div className="flex items-center gap-2">
                      <KeyRound className="w-4 h-4 text-slate-500" />
                      <span>تغيير كلمة المرور</span>
                    </div>
                    {currentUser.can_change_password ? (
                      <span className="text-[10px] bg-emerald-100 text-emerald-800 px-2 py-0.5 rounded-full font-bold">
                        مسموح
                      </span>
                    ) : (
                      <span className="text-[10px] bg-amber-100 text-amber-800 px-2 py-0.5 rounded-full font-bold">
                        يتطلب إذن الإدارة 🔒
                      </span>
                    )}
                  </button>
                </div>

                {/* Quick Staff Switcher Simulator */}
                <div className="mt-3 pt-3 border-t border-slate-100">
                  <p className="text-[11px] font-black text-slate-400 mb-2">
                    محاكي تبديل الموظفين والصلاحيات (تجربة فورية):
                  </p>
                  <div className="space-y-1 max-h-44 overflow-y-auto pr-1">
                    {staffList.map((st) => (
                      <button
                        key={st.id}
                        onClick={() => {
                          onSwitchUser(st);
                          setIsProfileMenuOpen(false);
                        }}
                        className={`w-full flex items-center justify-between p-2 rounded-xl text-xs font-bold transition-all ${
                          st.id === currentUser.id
                            ? 'bg-blue-600 text-white shadow-xs'
                            : 'bg-slate-50 text-slate-700 hover:bg-slate-100'
                        }`}
                      >
                        <div className="flex items-center gap-2">
                          <img
                            src={st.avatar_url || 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=100&q=80'}
                            alt={st.full_name}
                            className="w-6 h-6 rounded-lg object-cover"
                          />
                          <div className="text-right">
                            <p className="leading-tight text-[11px]">{st.full_name}</p>
                            <span className={`text-[9px] ${st.id === currentUser.id ? 'text-blue-100' : 'text-slate-500'}`}>
                              {getRoleArabicTitle(st.role)}
                            </span>
                          </div>
                        </div>
                        <span className={`text-[9px] px-1.5 py-0.5 rounded ${
                          st.id === currentUser.id ? 'bg-blue-700 text-white' : 'bg-slate-200 text-slate-600'
                        }`}>
                          🔒 {st.branch_name.slice(0, 8)}..
                        </span>
                      </button>
                    ))}
                  </div>
                </div>
              </div>
            </>
          )}
        </div>
      </div>

      {/* PASSWORD MODAL: ALLOWED OR REQUEST PERMISSION */}
      {isPasswordModalOpen && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl max-w-md w-full p-6 shadow-2xl border border-slate-200 text-right animate-scale-in">
            <div className="flex items-center justify-between pb-4 border-b border-slate-100">
              <div className="flex items-center gap-3">
                <div className={`w-10 h-10 rounded-2xl flex items-center justify-center ${
                  currentUser.can_change_password ? 'bg-emerald-100 text-emerald-700' : 'bg-amber-100 text-amber-700'
                }`}>
                  <KeyRound className="w-5 h-5" />
                </div>
                <div>
                  <h3 className="text-base font-black text-slate-900">
                    {currentUser.can_change_password ? 'تعيين كلمة مرور جديدة' : 'طلب إذن لتغيير كلمة المرور'}
                  </h3>
                  <p className="text-xs text-slate-500">
                    {currentUser.can_change_password ? 'الصلاحية مفعلة لك من الإدارة' : 'سياسة الأمان الصارمة للديب مول'}
                  </p>
                </div>
              </div>
              <button
                onClick={() => setIsPasswordModalOpen(false)}
                className="w-7 h-7 rounded-full bg-slate-100 hover:bg-slate-200 text-slate-600 flex items-center justify-center text-xs font-bold"
              >
                ✕
              </button>
            </div>

            {requestSentNotice ? (
              <div className="py-8 text-center space-y-3">
                <CheckCircle2 className="w-12 h-12 text-emerald-600 mx-auto animate-bounce" />
                <h4 className="font-black text-slate-900 text-sm">تم إرسال طلبك للإدارة العامة بنجاح!</h4>
                <p className="text-xs text-slate-500">
                  ستتلقى الإشعار فور قيام مسؤول النظام بمراجعة الطلب والموافقة عليه.
                </p>
              </div>
            ) : (
              <form onSubmit={handlePasswordAction} className="mt-4 space-y-4">
                {currentUser.can_change_password ? (
                  // Mode 1: Directly change password because admin allowed it
                  <div>
                    <label className="block text-xs font-bold text-slate-700 mb-1.5">
                      أدخل كلمة المرور الجديدة
                    </label>
                    <input
                      type="password"
                      required
                      placeholder="كلمة المرور الجديدة..."
                      value={directNewPassword}
                      onChange={(e) => setDirectNewPassword(e.target.value)}
                      className="w-full px-4 py-2.5 rounded-xl border border-slate-300 text-xs font-bold text-slate-900 focus:outline-none focus:ring-2 focus:ring-emerald-500"
                    />
                    <p className="text-[11px] text-emerald-700 font-medium mt-1.5">
                      ✓ لديك إذن صادر من الإدارة لتغيير كلمة المرور الخاصة بك.
                    </p>
                  </div>
                ) : (
                  // Mode 2: Locked by Admin -> must request permission
                  <div className="space-y-3">
                    <div className="p-3 bg-amber-50 rounded-2xl border border-amber-200 text-xs text-amber-900 space-y-1">
                      <div className="flex items-center gap-1.5 font-bold">
                        <Lock className="w-4 h-4 text-amber-600" />
                        <span>تغيير كلمة المرور مقفل من الإدارة</span>
                      </div>
                      <p className="text-[11px] leading-relaxed">
                        بموجب سياسات الأمان والحوكمة في الديب مول، لا يستطيع الموظف تغيير كلمة المرور بنفسه إلا بعد إرسال طلب رسمي وموافقة الإدارة.
                      </p>
                    </div>

                    <div>
                      <label className="block text-xs font-bold text-slate-700 mb-1.5">
                        سبب طلب تغيير كلمة المرور <span className="text-rose-500">*</span>
                      </label>
                      <textarea
                        required
                        rows={3}
                        placeholder="اكتب سبب طلب التغيير (مثال: اشتباه باطلاع شخص آخر، تحديث دوري...)"
                        value={passwordRequestReason}
                        onChange={(e) => setPasswordRequestReason(e.target.value)}
                        className="w-full px-4 py-2.5 rounded-xl border border-slate-300 text-xs font-semibold text-slate-900 focus:outline-none focus:ring-2 focus:ring-amber-500"
                      />
                    </div>
                  </div>
                )}

                <div className="flex items-center justify-end gap-2 pt-3 border-t border-slate-100">
                  <button
                    type="button"
                    onClick={() => setIsPasswordModalOpen(false)}
                    className="px-4 py-2 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 font-bold text-xs"
                  >
                    إلغاء
                  </button>
                  <button
                    type="submit"
                    className={`px-5 py-2 rounded-xl text-white font-extrabold text-xs shadow-md ${
                      currentUser.can_change_password
                        ? 'bg-emerald-600 hover:bg-emerald-700 shadow-emerald-600/30'
                        : 'bg-amber-600 hover:bg-amber-700 shadow-amber-600/30'
                    }`}
                  >
                    {currentUser.can_change_password ? 'تحديث وحفظ كلمة المرور' : 'إرسال طلب إذن للإدارة'}
                  </button>
                </div>
              </form>
            )}
          </div>
        </div>
      )}
    </header>
  );
};
