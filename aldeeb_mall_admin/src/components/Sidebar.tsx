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
  ThermometerSnowflake,
  RotateCcw,
  Navigation,
  Split,
  ArrowLeftRight,
  BrainCircuit,
  HeartHandshake,
  Radio,
  UtensilsCrossed,
  Scale,
  Pill,
  DoorClosed
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
    { id: 'dashboard', label: 'لوحة التحكم والعمليات', icon: LayoutDashboard },
    { id: 'analytics', label: 'ذكاء الأعمال والتحليلات', icon: BarChart3, badge: 'BI' },
    { id: 'forecasting', label: 'التنبؤ بالطلب بالـ AI', icon: BrainCircuit, badge: 'AI' },
    { 
      id: 'orders', 
      label: 'إدارة الطلبات الفورية', 
      icon: ShoppingBag, 
      badge: pendingOrdersCount > 0 ? pendingOrdersCount : null 
    },
    { 
      id: 'fulfillment', 
      label: 'المستودعات الذكية والفرز', 
      icon: Boxes,
      badge: '15-Min'
    },
    { 
      id: 'inventory_transfer', 
      label: 'مناقلات الفروع والمستودعات', 
      icon: ArrowLeftRight,
      badge: 'Hub'
    },
    { 
      id: 'flash_deals', 
      label: 'عروض الفلاش الخاطفة', 
      icon: Zap,
      badge: 'Noon'
    },
    { 
      id: 'live_shopping', 
      label: 'الديب لايف والتسوق الحي', 
      icon: Radio, 
      badge: 'Live' 
    },
    { 
      id: 'fleet', 
      label: 'أسطول التوصيل والكوريير', 
      icon: Bike 
    },
    { 
      id: 'courier_portal', 
      label: 'بوابة الكابتن والتسليم', 
      icon: Navigation, 
      badge: 'PIN' 
    },
    { id: 'products', label: 'كتالوج المنتجات والمخزون', icon: Package },
    { id: 'meal_kits', label: 'بوكسات الوجبات وتجهيز الطبخ', icon: UtensilsCrossed, badge: 'Kits' },
    { id: 'merchandising', label: 'هندسة العرض والـ A/B', icon: Split, badge: 'Opt' },
    { id: 'suppliers', label: 'الموردون وأوامر الشراء', icon: Building2 },
    { id: 'marketplace_vendors', label: 'تجار الماركت بليس والعمولات', icon: Store, badge: '3P' },
    { id: 'support', label: 'خدمة العملاء والدردشة', icon: Headset, badge: 'Live' },
    { id: 'categories', label: 'أقسام وتصنيفات المول', icon: Layers },
    { id: 'coupons', label: 'الكوبونات والعروض', icon: TicketPercent },
    { id: 'price_match', label: 'رادار مطابقة الأسعار وضمانها', icon: Scale, badge: '200%' },
    { id: 'pharmacy', label: 'صيدلية الديب ورقابة SFDA', icon: Pill, badge: 'Rx' },
    { id: 'lockers', label: 'خزائن الاستلام الذكية 24/7', icon: DoorClosed, badge: 'Hub' },
    { id: 'campaigns', label: 'الإشعارات والتسويق', icon: Bell, badge: 'Push' },
    { id: 'zones', label: 'نطاقات التغطية والذروة', icon: Compass },
    { id: 'cold_chain', label: 'سلسلة التبريد والصلاحية', icon: ThermometerSnowflake, badge: 'IoT' },
    { id: 'zero_waste', label: 'إنقاذ الغذاء والتخفيض الذكي', icon: HeartHandshake, badge: '-70%' },
    { id: 'returns', label: 'المرتجعات والنزاعات', icon: RotateCcw },
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
        <nav className="px-3 space-y-1 mt-2">
          {menuItems.map((item) => {
            const Icon = item.icon;
            const isActive = activeTab === item.id;
            return (
              <button
                key={item.id}
                onClick={() => setActiveTab(item.id)}
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
        <p>متصل بقاعدة Supabase Cloud</p>
      </div>
    </aside>
    </>
  );
};
