import React from 'react';
import { 
  LayoutDashboard, 
  ShoppingBag, 
  Package, 
  Layers, 
  TicketPercent, 
  Award, 
  Settings, 
  Store,
  ChevronLeft,
  Boxes,
  Zap,
  Bike,
  Building2,
  Headset,
  BarChart3,
  Bell,
  Compass,
  RotateCcw,
  Split,
  ArrowLeftRight,
  BrainCircuit,
  TowerControl,
  Crown,
  Megaphone,
  Receipt,
  Users,
  Calculator,
  Lock,
  ShieldCheck,
  Briefcase
} from 'lucide-react';
import { StaffRole } from '../types';
import { checkRoleAccess } from '../lib/staffData';

interface SidebarProps {
  activeTab: string;
  setActiveTab: (tab: string) => void;
  isStoreOpen: boolean;
  setIsStoreOpen: (open: boolean) => void;
  pendingOrdersCount: number;
  isOpenMobile?: boolean;
  onCloseMobile?: () => void;
  currentRole?: StaffRole;
  currentBranchName?: string;
}

export const Sidebar: React.FC<SidebarProps> = ({
  activeTab,
  setActiveTab,
  isStoreOpen,
  setIsStoreOpen,
  pendingOrdersCount,
  isOpenMobile = false,
  onCloseMobile,
  currentRole = 'super_admin',
  currentBranchName = 'هايبرماركت الرياض الرئيسي',
}) => {
  const allMenuItems = [
    { id: 'dashboard', label: 'لوحة التحكم والعمليات', icon: LayoutDashboard },
    { 
      id: 'pos_terminal', 
      label: 'نقطة بيع الكاشير (POS)', 
      icon: Store, 
      badge: 'POS' 
    },
    { 
      id: 'staff_management', 
      label: 'إدارة الموظفين والصلاحيات', 
      icon: Users, 
      badge: 'RBAC' 
    },
    { 
      id: 'accounting_payroll', 
      label: 'المحاسبة والرواتب والخصومات', 
      icon: Calculator, 
      badge: 'WPS' 
    },
    { id: 'analytics', label: 'ذكاء الأعمال والتحليلات', icon: BarChart3, badge: 'BI' },
    { id: 'forecasting', label: 'التنبؤ بالطلب والمخزون', icon: BrainCircuit, badge: 'AI' },
    { 
      id: 'orders', 
      label: 'إدارة الطلبات الفورية', 
      icon: ShoppingBag, 
      badge: pendingOrdersCount > 0 ? pendingOrdersCount : null 
    },
    { 
      id: 'operations_tower', 
      label: 'برج مراقبة العمليات المؤتمت', 
      icon: TowerControl, 
      badge: 'Ops' 
    },
    { 
      id: 'fulfillment', 
      label: 'المستودعات الذكية والفرز', 
      icon: Boxes,
      badge: 'WMS'
    },
    { 
      id: 'branches', 
      label: 'إدارة الفروع وتخصيصها', 
      icon: Building2,
      badge: 'Multi'
    },
    { 
      id: 'inventory_transfer', 
      label: 'مناقلات الفروع والمستودعات', 
      icon: ArrowLeftRight,
      badge: 'Hub'
    },
    { 
      id: 'products', 
      label: 'كتالوج المنتجات والباركود', 
      icon: Package 
    },
    { 
      id: 'categories', 
      label: 'أقسام وتصنيفات المول', 
      icon: Layers 
    },
    { 
      id: 'suppliers', 
      label: 'الموردون وفواتير الشراء', 
      icon: Building2 
    },
    { 
      id: 'corporate_b2b', 
      label: 'مبيعات الشركات والتوريد B2B', 
      icon: Briefcase, 
      badge: 'B2B' 
    },
    { 
      id: 'fleet', 
      label: 'منظومة التوصيل والأسطول', 
      icon: Bike 
    },
    { 
      id: 'courier_portal', 
      label: 'بوابة كابتن التوصيل (Captain)', 
      icon: Compass, 
      badge: 'Live' 
    },
    { 
      id: 'flash_deals', 
      label: 'عروض الفلاش والتخفيضات', 
      icon: Zap 
    },
    { 
      id: 'coupons', 
      label: 'الكوبونات وقواعد الخصم', 
      icon: TicketPercent 
    },
    { 
      id: 'banners', 
      label: 'البنرات والعروض التفاعلية', 
      icon: Megaphone 
    },
    { 
      id: 'merchandising', 
      label: 'هندسة العرض وترتيب الواجهة', 
      icon: Split 
    },
    { 
      id: 'campaigns', 
      label: 'التسويق والإشعارات الموجهة', 
      icon: Bell 
    },
    { 
      id: 'zones', 
      label: 'نطاقات التغطية (درعا وسوريا)', 
      icon: Compass 
    },
    { 
      id: 'subscriptions', 
      label: 'باقات الاشتراكات وشام كاش', 
      icon: Crown, 
      badge: 'VIP' 
    },
    { 
      id: 'loyalty', 
      label: 'العملاء ومكافآت النقاط', 
      icon: Award 
    },
    { 
      id: 'returns', 
      label: 'المرتجعات والنزاعات المالية', 
      icon: RotateCcw 
    },
    { 
      id: 'support', 
      label: 'خدمة العملاء والشكاوى', 
      icon: Headset 
    },
    { 
      id: 'invoice_designer', 
      label: 'تصميم الفواتير والباركود', 
      icon: Receipt, 
      badge: 'QR' 
    },
    { 
      id: 'settings', 
      label: 'إعدادات المول والثيم والمظهر', 
      icon: Settings 
    },
  ];

  // Filter menu items by current role permissions
  const menuItems = allMenuItems.filter(item => {
    // Staff management is accessible to super_admin and general_manager
    if (item.id === 'staff_management') {
      return currentRole === 'super_admin' || currentRole === 'general_manager';
    }
    // Accounting & Payroll is accessible to super_admin, general_manager, accountant, and auditor (audit view)
    if (item.id === 'accounting_payroll') {
      return ['super_admin', 'general_manager', 'accountant', 'auditor'].includes(currentRole);
    }
    return checkRoleAccess(currentRole, item.id);
  });

  return (
    <>
      {/* Mobile Backdrop Overlay */}
      {isOpenMobile && (
        <div
          onClick={onCloseMobile}
          className="fixed inset-0 bg-black/60 backdrop-blur-xs z-40 lg:hidden transition-opacity"
        />
      )}

      <aside
        className={`fixed lg:static top-0 right-0 z-50 w-72 bg-slate-900 text-white min-h-screen flex flex-col justify-between border-l border-slate-800 shadow-2xl lg:shadow-xl select-none transition-transform duration-300 ease-in-out ${
          isOpenMobile ? 'translate-x-0' : 'translate-x-full lg:translate-x-0'
        }`}
      >
      <div>
        {/* Brand Logo & Name */}
        <div className="p-6 border-b border-slate-800 flex items-center space-x-3 space-x-reverse">
          <div className="w-12 h-12 bg-black rounded-2xl flex items-center justify-center overflow-hidden border border-cyan-500/40 shadow-lg shadow-cyan-950/50 shrink-0">
            <img
              src={`${import.meta.env.BASE_URL}logo.png`}
              alt="شعار الديب مول DEB"
              className="w-full h-full object-cover"
            />
          </div>
          <div>
            <h1 className="text-xl font-extrabold tracking-wide text-white flex items-center gap-2">
              الديب مول
              <span className="text-[10px] bg-red-600 text-white px-2 py-0.5 rounded-full font-bold">Admin</span>
            </h1>
            <p className="text-xs text-slate-400 font-medium">Hypermarket Control Center</p>
          </div>
        </div>

        {/* Live Store Status Switch */}
        <div className="p-4 mx-4 my-3 bg-slate-800/80 rounded-2xl border border-slate-700/60">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <span className={`w-3 h-3 rounded-full ${isStoreOpen ? 'bg-emerald-500 animate-pulse' : 'bg-rose-500'}`} />
              <span className="text-xs font-bold text-slate-200">
                {isStoreOpen ? 'المتجر متاح لاستقبال الطلبات' : 'المتجر مغلق حالياً'}
              </span>
            </div>
            <button
              onClick={() => setIsStoreOpen(!isStoreOpen)}
              className={`text-xs px-2.5 py-1 rounded-lg font-bold transition-all ${
                isStoreOpen ? 'bg-emerald-600/30 text-emerald-300 hover:bg-emerald-600/40' : 'bg-rose-600/30 text-rose-300 hover:bg-rose-600/40'
              }`}
            >
              {isStoreOpen ? 'إغلاق' : 'فتح'}
            </button>
          </div>
        </div>

        {/* Locked Assigned Branch Notice */}
        <div className="mx-4 mb-2 p-3 bg-gradient-to-r from-amber-950/40 to-slate-800/80 rounded-2xl border border-amber-600/30">
          <div className="flex items-center gap-1.5 text-amber-400 font-bold text-[11px] mb-1">
            <Lock className="w-3.5 h-3.5" />
            <span>الفرع المخصص (مقيد إدارياً 🔒)</span>
          </div>
          <p className="text-slate-200 text-xs font-extrabold truncate">{currentBranchName}</p>
        </div>

        {/* Nav Items */}
        <nav className="px-3 space-y-1 mt-2 max-h-[calc(100vh-280px)] overflow-y-auto pr-1">
          {menuItems.map((item) => {
            const Icon = item.icon;
            const isActive = activeTab === item.id;
            return (
              <button
                key={item.id}
                onClick={() => {
                  setActiveTab(item.id);
                  if (onCloseMobile) onCloseMobile();
                }}
                className={`w-full flex items-center justify-between px-3.5 py-2.5 rounded-xl font-bold text-xs transition-all duration-200 ${
                  isActive
                    ? 'bg-blue-600 text-white shadow-lg shadow-blue-600/30'
                    : 'text-slate-400 hover:text-slate-200 hover:bg-slate-800/60'
                }`}
              >
                <div className="flex items-center space-x-3 space-x-reverse">
                  <Icon className={`w-4 h-4 ${isActive ? 'text-white' : 'text-slate-400'}`} />
                  <span>{item.label}</span>
                </div>

                <div className="flex items-center space-x-1.5 space-x-reverse">
                  {item.badge && (
                    <span
                      className={`text-[10px] px-2 py-0.5 rounded-full font-bold ${
                        isActive 
                          ? 'bg-white text-blue-700' 
                          : item.badge === 'Noon' || item.badge === '15-Min'
                          ? 'bg-amber-500/20 text-amber-300 border border-amber-500/30'
                          : item.badge === 'WPS' || item.badge === 'RBAC'
                          ? 'bg-emerald-500/20 text-emerald-300 border border-emerald-500/30'
                          : 'bg-red-500 text-white'
                      }`}
                    >
                      {item.badge}
                    </span>
                  )}
                  {isActive && <ChevronLeft className="w-3.5 h-3.5 text-blue-200" />}
                </div>
              </button>
            );
          })}
        </nav>
      </div>

      {/* Footer Info */}
      <div className="p-4 border-t border-slate-800 text-[11px] text-slate-500">
        <p className="font-bold text-slate-400">نظام إدارة الهايبرماركت v2.5</p>
        <p>متصل بقاعدة Supabase Cloud ⚡</p>
      </div>
    </aside>
    </>
  );
};
