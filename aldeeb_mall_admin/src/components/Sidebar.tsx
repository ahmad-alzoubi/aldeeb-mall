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
  ChevronLeft
} from 'lucide-react';

interface SidebarProps {
  activeTab: string;
  setActiveTab: (tab: string) => void;
  isStoreOpen: boolean;
  setIsStoreOpen: (open: boolean) => void;
  pendingOrdersCount: number;
  isOpenMobile?: boolean;
  onCloseMobile?: () => void;
}

export const Sidebar: React.FC<SidebarProps> = ({
  activeTab,
  setActiveTab,
  isStoreOpen,
  setIsStoreOpen,
  pendingOrdersCount,
  isOpenMobile = false,
  onCloseMobile,
}) => {
  const menuItems = [
    { id: 'dashboard', label: 'لوحة التحكم والتحليلات', icon: LayoutDashboard },
    { 
      id: 'orders', 
      label: 'إدارة الطلبات الفورية', 
      icon: ShoppingBag, 
      badge: pendingOrdersCount > 0 ? pendingOrdersCount : null 
    },
    { id: 'products', label: 'كتالوج المنتجات والمخزون', icon: Package },
    { id: 'categories', label: 'أقسام وتصنيفات المول', icon: Layers },
    { id: 'coupons', label: 'الكوبونات والعروض', icon: TicketPercent },
    { id: 'loyalty', label: 'العملاء ونقاط الولاء', icon: Award },
    { id: 'settings', label: 'إعدادات المول والتوصيل', icon: Settings },
  ];

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
          <div className="w-12 h-12 bg-gradient-to-tr from-blue-700 to-blue-500 rounded-2xl flex items-center justify-center shadow-lg shadow-blue-900/50">
            <Store className="w-6 h-6 text-white" />
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

        {/* Nav Items */}
        <nav className="px-3 space-y-1.5 mt-2">
          {menuItems.map((item) => {
            const Icon = item.icon;
            const isActive = activeTab === item.id;
            return (
              <button
                key={item.id}
                onClick={() => setActiveTab(item.id)}
                className={`w-full flex items-center justify-between px-4 py-3 rounded-xl font-bold text-sm transition-all duration-200 ${
                  isActive
                    ? 'bg-blue-600 text-white shadow-lg shadow-blue-600/30'
                    : 'text-slate-400 hover:text-white hover:bg-slate-800/60'
                }`}
              >
                <div className="flex items-center gap-3">
                  <Icon className={`w-5 h-5 ${isActive ? 'text-white' : 'text-slate-400'}`} />
                  <span>{item.label}</span>
                </div>
                {item.badge ? (
                  <span className="bg-red-500 text-white text-[11px] font-extrabold px-2 py-0.5 rounded-full shadow-md animate-bounce">
                    {item.badge}
                  </span>
                ) : (
                  <ChevronLeft className={`w-4 h-4 opacity-0 transition-opacity ${isActive ? 'opacity-100' : ''}`} />
                )}
              </button>
            );
          })}
        </nav>
      </div>

      {/* Admin User Footer */}
      <div className="p-4 m-4 bg-slate-800/60 rounded-2xl border border-slate-700/60 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-full bg-blue-600 text-white flex items-center justify-center font-bold text-sm">
            مدير
          </div>
          <div>
            <p className="text-sm font-bold text-white">مدير العمليات</p>
            <p className="text-xs text-slate-400">admin@aldeebmall.com</p>
          </div>
        </div>
      </div>
    </aside>
    </>
  );
};
