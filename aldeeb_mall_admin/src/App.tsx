import React, { useState, useEffect } from 'react';
import { Sidebar } from './components/Sidebar';
import { Header } from './components/Header';
import { DashboardPage } from './pages/DashboardPage';
import { OrdersPage } from './pages/OrdersPage';
import { ProductsPage } from './pages/ProductsPage';
import { CategoriesPage } from './pages/CategoriesPage';
import { CouponsPage } from './pages/CouponsPage';
import { LoyaltyPage } from './pages/LoyaltyPage';
import { SettingsPage } from './pages/SettingsPage';
import { FulfillmentPage } from './pages/FulfillmentPage';
import { FlashDealsPage } from './pages/FlashDealsPage';
import { FleetPage } from './pages/FleetPage';
import { SuppliersPage } from './pages/SuppliersPage';
import { SupportPage } from './pages/SupportPage';
import { AnalyticsPage } from './pages/AnalyticsPage';
import { CampaignsPage } from './pages/CampaignsPage';
import { ZonesPage } from './pages/ZonesPage';
import { ReturnsPage } from './pages/ReturnsPage';
import { MerchandisingPage } from './pages/MerchandisingPage';
import { InventoryTransferPage } from './pages/InventoryTransferPage';
import { ForecastingPage } from './pages/ForecastingPage';
import { SubscriptionsPage } from './pages/SubscriptionsPage';
import { BannersPage } from './pages/BannersPage';
import { EnterpriseOperationsTowerPage } from './pages/EnterpriseOperationsTowerPage';
import { BranchesPage } from './pages/BranchesPage';
import { PosTerminalPage } from './pages/PosTerminalPage';
import { CourierPortalPage } from './pages/CourierPortalPage';
import { InvoiceDesignerPage } from './pages/InvoiceDesignerPage';
import { ElectronicInvoicePage } from './pages/ElectronicInvoicePage';
import { StaffManagementPage } from './pages/StaffManagementPage';
import { AccountingPayrollPage } from './pages/AccountingPayrollPage';
import { 
  INITIAL_STAFF, 
  INITIAL_PAYROLL_TRANSACTIONS, 
  INITIAL_PASSWORD_REQUESTS 
} from './lib/staffData';
import { INITIAL_BRANCHES } from './lib/branchesData';
import { HelpProvider } from './components/common/InteractiveHelpSystem';
import { 
  filterOrdersByBranch, 
  filterProductsByBranch, 
  filterStaffByBranch, 
  filterCouriersByBranch,
  getActiveBranchId,
  setActiveBranchId
} from './lib/branchContext';
import { 
  initialOrders, 
  initialProducts, 
  initialCategories, 
  initialCoupons, 
  initialCustomers,
  initialDarkStores,
  initialPickerTasks,
  initialFlashDeals,
  initialCouriers,
  initialSuppliers,
  initialPurchaseOrders,
  initialSupportTickets,
  initialCampaigns,
  initialDeliveryZones,
  initialSubscriptionPlans,
  initialSubscribers,
  initialRewardCoupons,
  initialRewardProducts,
  initialSubscriptionActivity,
  initialBanners
} from './lib/supabase';
import { 
  Order, 
  Product, 
  Category, 
  Coupon, 
  Customer, 
  DarkStore, 
  PickerTask, 
  FlashDeal, 
  Courier,
  Supplier,
  PurchaseOrder,
  SupportTicket,
  MarketingCampaign,
  DeliveryZone,
  SubscriptionPlan,
  Subscriber,
  RewardCoupon,
  RewardProduct,
  SubscriptionActivityLog,
  Banner,
  StaffMember,
  PayrollTransaction,
  PasswordChangeRequest,
  Branch
} from './types';

export const App: React.FC = () => {
  const [activeTab, setActiveTab] = useState<string>(() => {
    if (typeof window !== 'undefined') {
      if (window.location.hash.startsWith('#invoice') || window.location.search.includes('invoice=')) {
        return 'electronic_invoice';
      }
      if (window.location.hash === '#pos' || window.location.search.includes('mode=pos')) {
        return 'pos_terminal';
      }
      if (window.location.hash === '#courier' || window.location.search.includes('mode=courier')) {
        return 'courier_portal';
      }
      if (window.location.hash === '#invoice_designer') {
        return 'invoice_designer';
      }
    }
    return 'dashboard';
  });

  useEffect(() => {
    const handleHash = () => {
      if (window.location.hash.startsWith('#invoice')) {
        setActiveTab('electronic_invoice');
      } else if (window.location.hash === '#pos') {
        setActiveTab('pos_terminal');
      } else if (window.location.hash === '#courier') {
        setActiveTab('courier_portal');
      } else if (window.location.hash === '#invoice_designer') {
        setActiveTab('invoice_designer');
      }
    };
    window.addEventListener('hashchange', handleHash);
    return () => window.removeEventListener('hashchange', handleHash);
  }, []);
  const [posBranchId, setPosBranchId] = useState<string | undefined>(undefined);
  const [isStoreOpen, setIsStoreOpen] = useState<boolean>(true);
  const [soundEnabled, setSoundEnabled] = useState<boolean>(true);
  const [isMobileSidebarOpen, setIsMobileSidebarOpen] = useState<boolean>(false);

  // Core Datasets
  const [orders, setOrders] = useState<Order[]>(initialOrders);
  const [products, setProducts] = useState<Product[]>(initialProducts);
  const [categories, setCategories] = useState<Category[]>(initialCategories);
  const [coupons, setCoupons] = useState<Coupon[]>(initialCoupons);
  const [customers, setCustomers] = useState<Customer[]>(initialCustomers);
  const [darkStores] = useState<DarkStore[]>(initialDarkStores);
  const [pickerTasks, setPickerTasks] = useState<PickerTask[]>(initialPickerTasks);
  const [flashDeals, setFlashDeals] = useState<FlashDeal[]>(initialFlashDeals);
  const [couriers, setCouriers] = useState<Courier[]>(initialCouriers);
  const [suppliers] = useState<Supplier[]>(initialSuppliers);
  const [purchaseOrders, setPurchaseOrders] = useState<PurchaseOrder[]>(initialPurchaseOrders);
  const [supportTickets] = useState<SupportTicket[]>(initialSupportTickets);
  const [campaigns, setCampaigns] = useState<MarketingCampaign[]>(initialCampaigns);
  const [deliveryZones] = useState<DeliveryZone[]>(initialDeliveryZones);

  // VIP Subscriptions & Rewards Datasets
  const [subscriptionPlans, setSubscriptionPlans] = useState<SubscriptionPlan[]>(initialSubscriptionPlans);
  const [subscribers, setSubscribers] = useState<Subscriber[]>(initialSubscribers);
  const [rewardCoupons, setRewardCoupons] = useState<RewardCoupon[]>(initialRewardCoupons);
  const [rewardProducts, setRewardProducts] = useState<RewardProduct[]>(initialRewardProducts);
  const [subscriptionActivities, setSubscriptionActivities] = useState<SubscriptionActivityLog[]>(initialSubscriptionActivity);
  const [banners, setBanners] = useState<Banner[]>(initialBanners);

  // Multi-branch dataset
  const [branches, setBranches] = useState<Branch[]>(INITIAL_BRANCHES);
  const [activeBranchId, setActiveBranchIdState] = useState<string>(() => getActiveBranchId());
  const [isBranchSwitching, setIsBranchSwitching] = useState<boolean>(false);

  const handleSwitchBranch = (newBranchId: string) => {
    setIsBranchSwitching(true);
    setActiveBranchId(newBranchId);
    setActiveBranchIdState(newBranchId);
    setTimeout(() => {
      setIsBranchSwitching(false);
    }, 300);
  };

  // Staff, Roles, Permissions & Shift System
  const [staffList, setStaffList] = useState<StaffMember[]>(INITIAL_STAFF);
  const [currentUser, setCurrentUser] = useState<StaffMember>(INITIAL_STAFF[0]);
  const [payrollTransactions, setPayrollTransactions] = useState<PayrollTransaction[]>(INITIAL_PAYROLL_TRANSACTIONS);
  const [passwordRequests, setPasswordRequests] = useState<PasswordChangeRequest[]>(INITIAL_PASSWORD_REQUESTS);

  // Branch-isolated reactive views
  const visibleOrders = filterOrdersByBranch(orders, activeBranchId);
  const visibleProducts = filterProductsByBranch(products, activeBranchId);
  const visibleStaff = filterStaffByBranch(staffList, activeBranchId);
  const visibleCouriers = filterCouriersByBranch(couriers, activeBranchId);

  const handleSwitchUser = (selectedStaff: StaffMember) => {
    setCurrentUser(selectedStaff);
    if (selectedStaff.role === 'cashier') {
      setActiveTab('pos_terminal');
    }
  };

  const handleRequestPasswordChange = (reason: string) => {
    const newReq: PasswordChangeRequest = {
      id: `pwr-${Date.now()}`,
      employee_id: currentUser.id,
      employee_name: currentUser.full_name,
      role: currentUser.role,
      branch_name: currentUser.branch_name,
      requested_at: new Date().toISOString(),
      reason,
      status: 'pending',
    };
    setPasswordRequests(prev => [newReq, ...prev]);
    setStaffList(prev => prev.map(s => s.id === currentUser.id ? { ...s, has_pending_password_request: true } : s));
  };

  const handleDirectChangePassword = (newPw: string) => {
    setStaffList(prev => prev.map(s => s.id === currentUser.id ? { ...s, password: newPw, can_change_password: false } : s));
    setCurrentUser(prev => ({ ...prev, password: newPw, can_change_password: false }));
  };

  // Play pleasant synthetic order chime via Web Audio API
  const playOrderChime = () => {
    if (!soundEnabled) return;
    try {
      const AudioCtx = window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
      const ctx = new AudioCtx();
      const osc1 = ctx.createOscillator();
      const osc2 = ctx.createOscillator();
      const gain = ctx.createGain();

      osc1.type = 'sine';
      osc1.frequency.setValueAtTime(587.33, ctx.currentTime); // D5
      osc1.frequency.setValueAtTime(880, ctx.currentTime + 0.12); // A5

      osc2.type = 'triangle';
      osc2.frequency.setValueAtTime(1174.66, ctx.currentTime);

      gain.gain.setValueAtTime(0.15, ctx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.5);

      osc1.connect(gain);
      osc2.connect(gain);
      gain.connect(ctx.destination);

      osc1.start();
      osc2.start();
      osc1.stop(ctx.currentTime + 0.5);
      osc2.stop(ctx.currentTime + 0.5);
    } catch {
      // Audio not permitted yet
    }
  };

  // Status & Order Updater
  const handleUpdateOrderStatus = (orderId: string, newStatus: Order['status']) => {
    setOrders((prev) =>
      prev.map((o) => (o.id === orderId ? { ...o, status: newStatus } : o))
    );
    playOrderChime();
  };

  const handleUpdateOrder = (updatedOrder: Order) => {
    setOrders((prev) =>
      prev.map((o) => (o.id === updatedOrder.id ? updatedOrder : o))
    );
  };

  const handleUpdateCourier = (updatedCourier: Courier) => {
    setCouriers((prev) =>
      prev.map((c) => (c.id === updatedCourier.id ? updatedCourier : c))
    );
  };

  // Product Actions
  const handleAddProduct = (newProduct: Product) => {
    setProducts((prev) => [newProduct, ...prev]);
  };

  const handleUpdateProduct = (updatedProduct: Product) => {
    setProducts((prev) =>
      prev.map((p) => (p.id === updatedProduct.id ? updatedProduct : p))
    );
  };

  const handleDeleteProduct = (productId: string) => {
    setProducts((prev) => prev.filter((p) => p.id !== productId));
  };

  // Category Actions
  const handleAddCategory = (newCategory: Category) => {
    setCategories((prev) => [...prev, newCategory]);
  };

  const handleUpdateCategory = (updatedCat: Category) => {
    setCategories((prev) => prev.map((c) => (c.id === updatedCat.id ? updatedCat : c)));
  };

  const handleDeleteCategory = (categoryId: string) => {
    setCategories((prev) => prev.filter((c) => c.id !== categoryId));
  };

  const handleToggleCategory = (categoryId: string) => {
    setCategories((prev) =>
      prev.map((c) => (c.id === categoryId ? { ...c, is_active: !c.is_active } : c))
    );
  };

  // Banner Actions (Hero & Middle Secondary)
  const handleAddBanner = (newBanner: Banner) => {
    setBanners((prev) => [newBanner, ...prev]);
  };

  const handleUpdateBanner = (updatedBanner: Banner) => {
    setBanners((prev) => prev.map((b) => (b.id === updatedBanner.id ? updatedBanner : b)));
  };

  const handleDeleteBanner = (bannerId: string) => {
    setBanners((prev) => prev.filter((b) => b.id !== bannerId));
  };

  const handleToggleBanner = (bannerId: string) => {
    setBanners((prev) =>
      prev.map((b) => (b.id === bannerId ? { ...b, is_active: !b.is_active } : b))
    );
  };

  // Coupon Actions
  const handleAddCoupon = (newCoupon: Coupon) => {
    setCoupons((prev) => [newCoupon, ...prev]);
  };

  const handleToggleCoupon = (couponId: string) => {
    setCoupons((prev) =>
      prev.map((c) => (c.id === couponId ? { ...c, is_active: !c.is_active } : c))
    );
  };

  const handleDeleteCoupon = (couponId: string) => {
    setCoupons((prev) => prev.filter((c) => c.id !== couponId));
  };

  // Flash Deals Actions
  const handleAddFlashDeal = (newDeal: FlashDeal) => {
    setFlashDeals((prev) => [newDeal, ...prev]);
  };

  const handleDeleteFlashDeal = (dealId: string) => {
    setFlashDeals((prev) => prev.filter((d) => d.id !== dealId));
  };

  const handleToggleFlashDeal = (dealId: string) => {
    setFlashDeals((prev) =>
      prev.map((d) => (d.id === dealId ? { ...d, is_active: !d.is_active } : d))
    );
  };

  // Customer Loyalty Actions
  const handleAddPoints = (customerId: string, points: number) => {
    setCustomers((prev) =>
      prev.map((c) => {
        if (c.id === customerId) {
          const newPts = c.loyalty_points + points;
          const newTier = newPts > 1000 ? 'Platinum' : newPts > 300 ? 'Gold' : 'Silver';
          return { ...c, loyalty_points: newPts, tier: newTier };
        }
        return c;
      })
    );

    // Also update in subscribers if present
    setSubscribers((prev) =>
      prev.map((s) => (s.customer_id === customerId ? { ...s, loyalty_points: s.loyalty_points + points } : s))
    );
  };

  // VIP Subscription Actions
  const handleAddPlan = (newPlan: SubscriptionPlan) => {
    setSubscriptionPlans((prev) => [...prev, newPlan]);
  };

  const handleUpdatePlan = (updatedPlan: SubscriptionPlan) => {
    setSubscriptionPlans((prev) => prev.map((p) => (p.id === updatedPlan.id ? updatedPlan : p)));
  };

  const handleTogglePlan = (planId: string) => {
    setSubscriptionPlans((prev) =>
      prev.map((p) => (p.id === planId ? { ...p, is_active: !p.is_active } : p))
    );
  };

  const handleExtendSubscriber = (subscriberId: string, days: number) => {
    setSubscribers((prev) =>
      prev.map((s) => {
        if (s.id === subscriberId) {
          const currentRenewal = new Date(s.renews_at);
          currentRenewal.setDate(currentRenewal.getDate() + days);
          const newDateStr = currentRenewal.toISOString().split('T')[0];
          return {
            ...s,
            renews_at: newDateStr,
            total_money_saved: s.total_money_saved + 59.00,
          };
        }
        return s;
      })
    );
    setSubscriptionActivities((prev) => [
      {
        id: `act-${Date.now()}`,
        timestamp: 'الآن',
        customer_name: 'إدارة النظام',
        activity_type: 'renewed',
        description_ar: `تم تمديد اشتراك المشترك لمدة ${days} يوماً إضافياً مجاناً كهدية تقدير`,
        badge_color: 'bg-emerald-50 text-emerald-700 border-emerald-200',
        amount_or_points: `+${days} يوم`,
      },
      ...prev,
    ]);
  };

  const handleToggleSubscriberStatus = (subscriberId: string) => {
    setSubscribers((prev) =>
      prev.map((s) =>
        s.id === subscriberId
          ? { ...s, status: s.status === 'active' ? 'paused' : 'active' }
          : s
      )
    );
  };

  const handleAddRewardCoupon = (coupon: RewardCoupon) => {
    setRewardCoupons((prev) => [coupon, ...prev]);
  };

  const handleAddRewardProduct = (product: RewardProduct) => {
    setRewardProducts((prev) => [product, ...prev]);
  };

  const handleToggleRewardItem = (type: 'coupon' | 'product', id: string) => {
    if (type === 'coupon') {
      setRewardCoupons((prev) =>
        prev.map((c) => (c.id === id ? { ...c, is_active: !c.is_active } : c))
      );
    } else {
      setRewardProducts((prev) =>
        prev.map((p) => (p.id === id ? { ...p, is_active: !p.is_active } : p))
      );
    }
  };

  const pendingCount = orders.filter((o) => o.status === 'pending').length;

  const getPageTitle = () => {
    switch (activeTab) {
      case 'branches':
        return { 
          title: 'إدارة الفروع المتعددة ومراكز التوزيع (Multi-Branch)', 
          subtitle: 'إدارة الفروع، مراكز التلبية، ونقاط البيع عبر كافة المدن' 
        };
      case 'pos_terminal':
        return { 
          title: 'بوابة الكاشير ونقاط البيع المستقلة (Enterprise POS)', 
          subtitle: 'نظام الكاشير الميداني، مسح الباركود السريع، والطباعة الحرارية' 
        };
      case 'dashboard':
        return { title: 'لوحة التحكم والعمليات', subtitle: 'نظرة شاملة ومؤشرات أداء مبيعات الديب مول' };
      case 'analytics':
        return { title: 'ذكاء الأعمال والتحليلات المالية (BI Analytics)', subtitle: 'مؤشرات الإيرادات اللحظية، ساعات الذروة، ونسب التزام التوصيل 15 دقيقة' };
      case 'orders':
        return { title: 'إدارة الطلبات الفورية والفرز', subtitle: 'متابعة الطلبات المباشرة من الاستلام حتى تسليم السائق' };
      case 'operations_tower':
        return { 
          title: 'برج مراقبة العمليات وسلسلة الإمداد الذكية (Enterprise Operations Tower)', 
          subtitle: '20 نظاماً تشغيلياً لمراقبة الطلبات المتعثرة، المخزون، الشحنات، والتسويات المالية' 
        };
      case 'fulfillment':
        return { title: 'المستودعات الذكية والجمع الفوري (15-Min)', subtitle: 'محطات الفرز الذكي ومطابقة الأصناف بالباركود الرقمي' };
      case 'flash_deals':
        return { title: 'عروض الفلاش والصفقات الخاطفة (Noon Deals)', subtitle: 'إدارة وتوقيت عروض الأسعار والكميات المحدودة' };
      case 'fleet':
        return { title: 'برج مراقبة أسطول التوصيل (Courier Dispatch)', subtitle: 'توزيع الطلبات والتتبع اللحظي لمندوبي التوصيل' };
      case 'products':
        return { title: 'كتالوج المنتجات والمخزون', subtitle: 'إدارة وتعديل الأصناف، الأسعار، العروض، ومستويات المستودع' };
      case 'suppliers':
        return { title: 'إدارة الموردين وأوامر الشراء (Procurement)', subtitle: 'تتبع سلاسل الإمداد ومستويات إعادة الطلب التلقائية' };
      case 'support':
        return { title: 'مكتب خدمة العملاء والدردشة الحية (Support Desk)', subtitle: 'معالجة استفسارات وشكاوى العملاء الفورية' };
      case 'campaigns':
        return { title: 'الحملات التسويقية والإشعارات الفورية (Push Notifications)', subtitle: 'إطلاق إشعارات العروض وسلال الشراء المعلقة' };
      case 'zones':
        return { title: 'النطاقات الجغرافية ورسوم الذروة (Geofencing & Surge)', subtitle: 'أقطار خدمة الـ 15 دقيقة والتسعير الديناميكي' };
      case 'banners':
        return { 
          title: 'إدارة البنرات والعروض التفاعلية (Hero & Promos)', 
          subtitle: 'التحكم الكامل بالسلايدر الرئيسي، البطاقات الجانبية، وإجراءات النقر المباشر (أقسام، صفحات، منتجات، وكوبونات)' 
        };
      case 'categories':
        return { title: 'أقسام وتصنيفات الهايبرماركت', subtitle: 'ترتيب وإضافة الأقسام المعروضة للعملاء' };
      case 'coupons':
        return { title: 'كوبونات الخصم والعروض الترويجية', subtitle: 'إطلاق ومتابعة فاعلية حملات الأكواد التسويقية' };
      case 'subscriptions':
        return { title: 'باقات الاشتراكات ونادي VIP (Prime & Loyalty)', subtitle: 'إدارة الاشتراكات الشهرية، الإيرادات المتكررة MRR، وكتالوج مكافآت النقاط' };
      case 'loyalty':
        return { title: 'نادي العملاء ونقاط الولاء', subtitle: 'سجل العملاء، النقاط التراكمية، ومكافآت التقدير' };
      case 'settings':
        return { title: 'إعدادات المول وسياسات التوصيل', subtitle: 'العملة، رسوم التوصيل المجاني، ومعلومات الاتصال' };
      case 'staff_management':
        return { 
          title: 'إدارة حسابات الموظفين، الصلاحيات وتحديد كلمات المرور', 
          subtitle: 'فتح حسابات الموظفين، تحديد كلمات السر وقفل تعديلها إلا بإذن، وتقييد كل موظف بفرعه الإلزامي' 
        };
      case 'accounting_payroll':
        return { 
          title: 'مشروع المحاسبة: إدارة الرواتب، السحبيات والخصومات', 
          subtitle: 'كشف مسير رواتب الموظفين، قيد السحبيات والسلف، تسجيل الخصومات والجزاءات، وصلاحيات المحاسب والمدقق' 
        };
      case 'invoice_designer':
        return { 
          title: 'مصمم ومحرر قوالب الفواتير والباركود الإلكتروني', 
          subtitle: 'تخصيص فاتورة الكاشير والطباعة الحرارية، إظهار/إخفاء الحقول، وإعداد الباركود المعتمد' 
        };
      default:
        return { title: 'الديب مول', subtitle: '' };
    }
  };

  const pageInfo = getPageTitle();

  if (activeTab === 'electronic_invoice') {
    return (
      <ElectronicInvoicePage
        onBackToApp={() => {
          window.location.hash = '';
          setActiveTab('pos_terminal');
        }}
      />
    );
  }

  if (activeTab === 'pos_terminal') {
    return (
      <PosTerminalPage
        targetBranchId={currentUser.role === 'super_admin' ? posBranchId : currentUser.branch_id}
        onExitPos={() => setActiveTab('branches')}
        onNavigateToInvoiceDesigner={() => setActiveTab('invoice_designer')}
        isBranchLocked={currentUser.role !== 'super_admin'}
        currentCashierName={currentUser.full_name}
      />
    );
  }

  if (activeTab === 'courier_portal') {
    return (
      <CourierPortalPage
        couriers={couriers}
        orders={orders}
        onUpdateOrder={handleUpdateOrder}
        onUpdateCourier={handleUpdateCourier}
        onBackToAdmin={() => {
          window.location.hash = '';
          setActiveTab('fleet');
        }}
      />
    );
  }

  if (!currentUser.is_active) {
    return (
      <div className="min-h-screen bg-slate-950 text-white flex items-center justify-center p-6 text-center" dir="rtl">
        <div className="bg-slate-900 p-8 rounded-3xl border border-rose-500/40 max-w-md w-full shadow-2xl space-y-4">
          <div className="w-16 h-16 rounded-2xl bg-rose-500/20 text-rose-500 flex items-center justify-center mx-auto text-2xl font-black border border-rose-500/30">
            ✕
          </div>
          <h2 className="text-xl font-black text-rose-400">الحساب معطل أو تم إنهاء الجلسة</h2>
          <p className="text-xs text-slate-300 leading-relaxed font-medium">
            تم تجميد هذا الحساب أو إنهاء الجلسة من قبل الإدارة المركزية للديب مول بموجب بروتوكول الحوكمة والأمان.
          </p>
          <button
            onClick={() => {
              const activeOne = staffList.find(s => s.is_active) || staffList[0];
              setCurrentUser(activeOne);
            }}
            className="w-full py-3 rounded-2xl bg-blue-600 hover:bg-blue-700 text-white font-extrabold text-xs shadow-lg shadow-blue-600/30 transition-all"
          >
            تسجيل الدخول بحساب مسؤول نشط
          </button>
        </div>
      </div>
    );
  }

  return (
    <HelpProvider>
    <div className="flex bg-slate-50 min-h-screen text-slate-800 relative">
      {/* Branch Switching Isolation Overlay */}
      {isBranchSwitching && (
        <div className="fixed inset-0 z-50 bg-slate-950/70 backdrop-blur-xs flex items-center justify-center animate-fade-in" dir="rtl">
          <div className="bg-white p-6 md:p-8 rounded-3xl shadow-2xl border border-slate-200 flex flex-col items-center gap-3.5 max-w-sm text-center">
            <div className="w-10 h-10 border-4 border-blue-600 border-t-transparent rounded-full animate-spin" />
            <p className="text-sm font-black text-slate-900">جاري عزل وتصفية بيانات الفرع النشط...</p>
            <p className="text-xs text-slate-500 font-medium">
              مزامنة فواتير المبيعات، حركات المخزون، والطلبات الخاصة بالفرع المحدد ومنع اختلاط البيانات
            </p>
          </div>
        </div>
      )}

      {/* Sidebar */}
      <Sidebar
        activeTab={activeTab}
        setActiveTab={(tab) => {
          setActiveTab(tab);
          setIsMobileSidebarOpen(false);
        }}
        isStoreOpen={isStoreOpen}
        setIsStoreOpen={setIsStoreOpen}
        pendingOrdersCount={pendingCount}
        isOpenMobile={isMobileSidebarOpen}
        onCloseMobile={() => setIsMobileSidebarOpen(false)}
        currentRole={currentUser.role}
        currentBranchName={currentUser.branch_name}
      />

      {/* Main Content Area */}
      <div className="flex-1 flex flex-col min-w-0">
        <Header
          title={pageInfo.title}
          subtitle={pageInfo.subtitle}
          soundEnabled={soundEnabled}
          setSoundEnabled={setSoundEnabled}
          onRefresh={() => playOrderChime()}
          onToggleMobileMenu={() => setIsMobileSidebarOpen(!isMobileSidebarOpen)}
          currentUser={currentUser}
          staffList={staffList}
          onSwitchUser={handleSwitchUser}
          onRequestPasswordChange={handleRequestPasswordChange}
          onDirectChangePassword={handleDirectChangePassword}
          branches={branches}
          activeBranchId={activeBranchId}
          onSwitchBranch={handleSwitchBranch}
          isBranchSwitching={isBranchSwitching}
        />

        <main className="p-8 flex-1 overflow-y-auto">
          {activeTab === 'staff_management' && (
            <StaffManagementPage
              staffList={staffList}
              setStaffList={setStaffList}
              branches={branches}
              passwordRequests={passwordRequests}
              setPasswordRequests={setPasswordRequests}
              currentAdminRole={currentUser.role}
            />
          )}

          {activeTab === 'accounting_payroll' && (
            <AccountingPayrollPage
              staffList={staffList}
              payrollTransactions={payrollTransactions}
              setPayrollTransactions={setPayrollTransactions}
              branches={branches}
              currentRole={currentUser.role}
              currentStaffName={currentUser.full_name}
            />
          )}
          {activeTab === 'branches' && (
            <BranchesPage
              onOpenPosForBranch={(branchId) => {
                setPosBranchId(branchId);
                setActiveTab('pos_terminal');
              }}
            />
          )}

          {activeTab === 'dashboard' && (
            <DashboardPage
              orders={visibleOrders}
              products={visibleProducts}
              setActiveTab={setActiveTab}
              onUpdateOrderStatus={handleUpdateOrderStatus}
            />
          )}

          {activeTab === 'analytics' && (
            <AnalyticsPage
              orders={visibleOrders}
              products={visibleProducts}
            />
          )}

          {activeTab === 'forecasting' && (
            <ForecastingPage
              products={visibleProducts}
              orders={visibleOrders}
            />
          )}

          {activeTab === 'orders' && (
            <OrdersPage
              orders={visibleOrders}
              onUpdateOrderStatus={handleUpdateOrderStatus}
            />
          )}

          {activeTab === 'operations_tower' && (
            <EnterpriseOperationsTowerPage
              orders={visibleOrders}
              products={visibleProducts}
              darkStores={darkStores}
            />
          )}

          {activeTab === 'fulfillment' && (
            <FulfillmentPage
              darkStores={darkStores}
              pickerTasks={pickerTasks}
            />
          )}

          {activeTab === 'inventory_transfer' && (
            <InventoryTransferPage
              darkStores={darkStores}
              products={products}
            />
          )}

          {activeTab === 'flash_deals' && (
            <FlashDealsPage
              deals={flashDeals}
              products={visibleProducts}
              orders={visibleOrders}
              onAddDeal={handleAddFlashDeal}
              onDeleteDeal={handleDeleteFlashDeal}
              onToggleDeal={handleToggleFlashDeal}
            />
          )}

          {activeTab === 'fleet' && (
            <FleetPage
              couriers={visibleCouriers}
              orders={visibleOrders}
              onAssignOrderToCourier={(orderId, courierId) => {
                const targetCourier = couriers.find((c) => c.id === courierId);
                setOrders((prev) =>
                  prev.map((o) =>
                    o.id === orderId
                      ? {
                          ...o,
                          courier_id: courierId,
                          courier_name: targetCourier?.full_name,
                          status: 'out_for_delivery',
                          delivery_otp: o.delivery_otp || `${Math.floor(1000 + Math.random() * 9000)}`,
                        }
                      : o
                  )
                );
                setCouriers((prev) =>
                  prev.map((c) =>
                    c.id === courierId
                      ? {
                          ...c,
                          status: 'on_delivery',
                          assigned_orders_count: (c.assigned_orders_count || 0) + 1,
                        }
                      : c
                  )
                );
              }}
            />
          )}

          {activeTab === 'merchandising' && (
            <MerchandisingPage />
          )}

          {activeTab === 'products' && (
            <ProductsPage
              products={products}
              categories={categories}
              onAddProduct={handleAddProduct}
              onUpdateProduct={handleUpdateProduct}
              onDeleteProduct={handleDeleteProduct}
            />
          )}

          {activeTab === 'suppliers' && (
            <SuppliersPage
              suppliers={suppliers}
              purchaseOrders={purchaseOrders}
              products={products}
              onAddPO={(newPO) => setPurchaseOrders((prev) => [newPO, ...prev])}
              onAddProduct={handleAddProduct}
              onUpdateProduct={handleUpdateProduct}
            />
          )}

          {activeTab === 'support' && (
            <SupportPage
              tickets={supportTickets}
            />
          )}

          {activeTab === 'campaigns' && (
            <CampaignsPage
              campaigns={campaigns}
              onAddCampaign={(newCamp) => setCampaigns((prev) => [newCamp, ...prev])}
            />
          )}

          {activeTab === 'zones' && (
            <ZonesPage
              zones={deliveryZones}
            />
          )}

          {activeTab === 'returns' && (
            <ReturnsPage />
          )}

          {activeTab === 'banners' && (
            <BannersPage
              banners={banners}
              categories={categories}
              products={products}
              coupons={coupons}
              onAddBanner={handleAddBanner}
              onUpdateBanner={handleUpdateBanner}
              onDeleteBanner={handleDeleteBanner}
              onToggleBanner={handleToggleBanner}
            />
          )}

          {activeTab === 'categories' && (
            <CategoriesPage
              categories={categories}
              onAddCategory={handleAddCategory}
              onUpdateCategory={handleUpdateCategory}
              onDeleteCategory={handleDeleteCategory}
              onToggleCategory={handleToggleCategory}
            />
          )}

          {activeTab === 'coupons' && (
            <CouponsPage
              coupons={coupons}
              onAddCoupon={handleAddCoupon}
              onToggleCoupon={handleToggleCoupon}
              onDeleteCoupon={handleDeleteCoupon}
            />
          )}

          {activeTab === 'subscriptions' && (
            <SubscriptionsPage
              plans={subscriptionPlans}
              subscribers={subscribers}
              rewardCoupons={rewardCoupons}
              rewardProducts={rewardProducts}
              activities={subscriptionActivities}
              onAddPlan={handleAddPlan}
              onUpdatePlan={handleUpdatePlan}
              onTogglePlan={handleTogglePlan}
              onExtendSubscriber={handleExtendSubscriber}
              onToggleSubscriberStatus={handleToggleSubscriberStatus}
              onGrantPoints={handleAddPoints}
              onAddRewardCoupon={handleAddRewardCoupon}
              onAddRewardProduct={handleAddRewardProduct}
              onToggleRewardItem={handleToggleRewardItem}
            />
          )}

          {activeTab === 'loyalty' && (
            <LoyaltyPage
              customers={customers}
              onAddPoints={handleAddPoints}
            />
          )}

          {activeTab === 'settings' && <SettingsPage />}

          {activeTab === 'invoice_designer' && (
            <InvoiceDesignerPage
              onOpenElectronicInvoice={() => {
                setActiveTab('electronic_invoice');
              }}
            />
          )}
        </main>
      </div>
    </div>
    </HelpProvider>
  );
};
