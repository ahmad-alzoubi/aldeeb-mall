import React, { useState, useEffect, useCallback } from 'react';
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
import { AdminLoginPage } from './pages/AdminLoginPage';
import { CorporateB2BPage } from './pages/CorporateB2BPage';
import { staffAuthApi } from './lib/staffAuthApi';
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
  supabase,
  isValid3PartJwt,
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
  StaffRole,
  PayrollTransaction,
  PasswordChangeRequest,
  Branch
} from './types';
import { 
  generateUUID, 
  ensureUUID, 
  toCanonicalCategoryId 
} from './lib/uuidUtils';
import { 
  CheckCircle2, 
  AlertTriangle, 
  Info, 
  X as CloseIcon 
} from 'lucide-react';

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

  // Persistent Local Storage Keys & Helpers
  const STORAGE_KEYS = {
    PRODUCTS: 'aldeeb_admin_products_v5',
    CATEGORIES: 'aldeeb_admin_categories_v5',
    COUPONS: 'aldeeb_admin_coupons_v5',
    BANNERS: 'aldeeb_admin_banners_v5',
    ORDERS: 'aldeeb_admin_orders_v5',
    STAFF: 'aldeeb_admin_staff_v5',
    PASSWORD_REQUESTS: 'aldeeb_admin_password_requests_v5',
    BRANCHES: 'aldeeb_admin_branches_v5',
  };

  const getCachedData = <T,>(key: string, fallback: T[]): T[] => {
    if (typeof window === 'undefined') return fallback;
    try {
      const saved = localStorage.getItem(key);
      if (saved) {
        const parsed = JSON.parse(saved);
        if (Array.isArray(parsed) && parsed.length > 0) {
          // Invalidate legacy mock orders containing ord-8842, DEEB-8842, أحمد الزعبي or LOCAL-TEST
          if (key === STORAGE_KEYS.ORDERS) {
            const hasMock = parsed.some((item: any) => 
              item.id === 'ord-8842' || 
              item.id === 'ord-8843' || 
              item.id === 'ord-8844' || 
              item.order_number === 'DEEB-8842' ||
              item.order_number === 'DEEB-8843' ||
              item.order_number === 'DEEB-8844' ||
              item.customer_name === 'أحمد الزعبي' ||
              item.customer_name === 'أحمد الراعي' ||
              item.customer_name === 'فاطمة المنصوري' ||
              item.customer_name === 'خالد السعدي' ||
              (item.order_number && item.order_number.startsWith('LOCAL-TEST'))
            );
            if (hasMock) {
              localStorage.removeItem(key);
              return fallback;
            }
          }
          return parsed;
        }
      }
    } catch (e) {
      console.warn(`Failed to read cache for ${key}:`, e);
    }
    return fallback;
  };

  // Sync Notification Banner State
  const [syncNotification, setSyncNotification] = useState<{
    message: string;
    type: 'success' | 'warning' | 'info' | 'error';
    id: number;
  } | null>(null);

  const showSyncNotification = (message: string, type: 'success' | 'warning' | 'info' | 'error' = 'info') => {
    const id = Date.now();
    setSyncNotification({ message, type, id });
    setTimeout(() => {
      setSyncNotification((current) => (current?.id === id ? null : current));
    }, 8000);
  };

  // Core Datasets with Multi-Tier LocalStorage & Supabase Integration
  const [orders, setOrders] = useState<Order[]>(() => getCachedData(STORAGE_KEYS.ORDERS, initialOrders));
  const [products, setProducts] = useState<Product[]>(() => getCachedData(STORAGE_KEYS.PRODUCTS, initialProducts));
  const [categories, setCategories] = useState<Category[]>(() => getCachedData(STORAGE_KEYS.CATEGORIES, initialCategories));
  const [coupons, setCoupons] = useState<Coupon[]>(() => getCachedData(STORAGE_KEYS.COUPONS, initialCoupons));
  const [customers, setCustomers] = useState<Customer[]>(initialCustomers);
  const [darkStores] = useState<DarkStore[]>(initialDarkStores);
  const [pickerTasks, setPickerTasks] = useState<PickerTask[]>(initialPickerTasks);
  const [flashDeals, setFlashDeals] = useState<FlashDeal[]>(initialFlashDeals);
  const [couriers, setCouriers] = useState<Courier[]>(initialCouriers);
  const [suppliers, setSuppliers] = useState<Supplier[]>(initialSuppliers);
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
  const [banners, setBanners] = useState<Banner[]>(() => getCachedData(STORAGE_KEYS.BANNERS, initialBanners));

  // Multi-branch dataset
  const [branches, setBranches] = useState<Branch[]>(() => getCachedData(STORAGE_KEYS.BRANCHES, INITIAL_BRANCHES));
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
  const [staffList, setStaffList] = useState<StaffMember[]>(() => getCachedData(STORAGE_KEYS.STAFF, INITIAL_STAFF));
  const [currentUser, setCurrentUser] = useState<StaffMember>(() => {
    if (typeof window !== 'undefined') {
      const savedId = localStorage.getItem('aldeeb_admin_user_id');
      if (savedId) {
        const cachedStaff = getCachedData(STORAGE_KEYS.STAFF, INITIAL_STAFF);
        const found = cachedStaff.find(s => s.id === savedId) || INITIAL_STAFF.find(s => s.id === savedId);
        if (found) return found;
      }
    }
    return INITIAL_STAFF[0];
  });
  const [isAuthenticated, setIsAuthenticated] = useState<boolean>(false);
  const [isVerifyingSession, setIsVerifyingSession] = useState<boolean>(true);
  const [authNotice, setAuthNotice] = useState<string | null>(null);
  const [payrollTransactions, setPayrollTransactions] = useState<PayrollTransaction[]>(INITIAL_PAYROLL_TRANSACTIONS);
  const [passwordRequests, setPasswordRequests] = useState<PasswordChangeRequest[]>(() => getCachedData(STORAGE_KEYS.PASSWORD_REQUESTS, INITIAL_PASSWORD_REQUESTS));

  // Verify server session validity on mount & enforce server-authoritative anti-tampering
  useEffect(() => {
    let isMounted = true;

    // Self-heal any legacy malformed or 1-part token stored in client storage
    try {
      const storedJwt = localStorage.getItem('aldeeb_admin_jwt');
      if (storedJwt && !isValid3PartJwt(storedJwt)) {
        console.warn('⚠️ [Boot Sanitizer] Purging malformed non-3-part token from client storage:', storedJwt);
        localStorage.removeItem('aldeeb_admin_jwt');
      }
    } catch (_) {}

    const checkServerSession = async () => {
      const token = staffAuthApi.getSessionToken();
      if (!token) {
        staffAuthApi.clearSession();
        if (isMounted) {
          setIsAuthenticated(false);
          setIsVerifyingSession(false);
        }
        return;
      }

      const res = await staffAuthApi.verifySession(token);
      if (!isMounted) return;

      if (res.valid && res.staff) {
        setCurrentUser(res.staff);
        setIsAuthenticated(true);
        setAuthNotice(null);
      } else {
        // Server rejected session (e.g. revoked, expired, frozen, or tampered token)
        setIsAuthenticated(false);
        staffAuthApi.clearSession();
        if (res.message && res.code !== 'NO_SESSION') {
          setAuthNotice(res.message);
        }
      }
      setIsVerifyingSession(false);
    };

    checkServerSession();

    // Heartbeat check every 25 seconds & on visibility change to catch instant freezes/revocations
    const interval = setInterval(checkServerSession, 25000);
    const onVisibilityChange = () => {
      if (document.visibilityState === 'visible') {
        checkServerSession();
      }
    };
    document.addEventListener('visibilitychange', onVisibilityChange);

    return () => {
      isMounted = false;
      clearInterval(interval);
      document.removeEventListener('visibilitychange', onVisibilityChange);
    };
  }, []);

  const handleLogin = (staff: StaffMember, sessionToken: string, jwtToken?: string) => {
    staffAuthApi.saveSession(sessionToken, jwtToken, staff.id);
    setCurrentUser(staff);
    setIsAuthenticated(true);
    setAuthNotice(null);
    if (staff.role === 'cashier') {
      setActiveTab('pos_terminal');
    }
  };

  const handleLogout = async () => {
    await staffAuthApi.logoutStaff();
    setIsAuthenticated(false);
    setAuthNotice(null);
  };

  // Branch-isolated reactive views
  const visibleOrders = filterOrdersByBranch(orders, activeBranchId);
  const visibleProducts = filterProductsByBranch(products, activeBranchId);
  const visibleStaff = filterStaffByBranch(staffList, activeBranchId);
  const visibleCouriers = filterCouriersByBranch(couriers, activeBranchId);

  const handleSwitchUser = async (selectedStaff: StaffMember) => {
    setCurrentUser(selectedStaff);
    const pass = selectedStaff.password || (
      selectedStaff.username === 'admin' ? 'admin' :
      selectedStaff.username === 'gm_khaled' ? 'gm123' :
      selectedStaff.username === 'auditor_ziad' ? 'audit123' :
      selectedStaff.username === 'accountant_tareq' ? 'acc123' :
      selectedStaff.username === 'cashier_omar' ? 'pos123' :
      selectedStaff.username === 'manager_rami' ? 'jed123' :
      selectedStaff.username === 'manager_wael' ? 'dam123' :
      selectedStaff.username === 'manager_sami' ? 'dark123' : 'admin'
    );
    try {
      const res = await staffAuthApi.loginStaff(selectedStaff.username, pass);
      if (res && res.success && res.session_token) {
        staffAuthApi.saveSession(res.session_token, res.token, selectedStaff.id);
      }
    } catch (e) {
      console.warn('Switch user login error:', e);
    }
    if (selectedStaff.role === 'cashier') {
      setActiveTab('pos_terminal');
    }
  };

  const handleRequestPasswordChange = async (reason: string) => {
    const newReqId = `pwr-${Date.now()}`;
    const newReq: PasswordChangeRequest = {
      id: newReqId,
      employee_id: currentUser.id,
      employee_name: currentUser.full_name,
      role: currentUser.role,
      branch_name: currentUser.branch_name,
      requested_at: new Date().toISOString(),
      reason,
      status: 'pending',
    };
    setPasswordRequests(prev => {
      const updated = [newReq, ...prev];
      try { localStorage.setItem(STORAGE_KEYS.PASSWORD_REQUESTS, JSON.stringify(updated)); } catch (e) {}
      return updated;
    });
    setStaffList(prev => {
      const updated = prev.map(s => s.id === currentUser.id ? { ...s, has_pending_password_request: true } : s);
      try { localStorage.setItem(STORAGE_KEYS.STAFF, JSON.stringify(updated)); } catch (e) {}
      return updated;
    });

    try {
      await supabase.from('password_change_requests').insert({
        id: newReqId,
        employee_id: currentUser.id,
        reason,
        status: 'pending',
        requested_at: newReq.requested_at,
      });
      await supabase.from('staff_members').update({
        has_pending_password_request: true,
        updated_at: new Date().toISOString(),
      }).eq('id', currentUser.id);
      showSyncNotification('✅ تم إرسال طلب تغيير كلمة المرور للسيرفر بنجاح بانتظار اعتماد الإدارة', 'success');
    } catch (e) {
      console.warn('Supabase password request sync error:', e);
    }
  };

  const handleDirectChangePassword = async (newPw: string) => {
    try {
      const res = await staffAuthApi.selfChangePassword(newPw);
      if (!res.success) {
        showSyncNotification(`⚠️ ${res.message || 'فشل تحديث كلمة المرور'}`, 'error');
        return;
      }

      setStaffList(prev => {
        const updated = prev.map(s => s.id === currentUser.id ? { ...s, can_change_password: false } : s);
        try { localStorage.setItem(STORAGE_KEYS.STAFF, JSON.stringify(updated)); } catch (e) {}
        return updated;
      });
      setCurrentUser(prev => ({ ...prev, can_change_password: false }));
      showSyncNotification('✅ تم تحديث وتشفير كلمة المرور الخاصة بك على السيرفر بنجاح', 'success');
    } catch (e: any) {
      console.warn('Supabase self change password error:', e);
      showSyncNotification(`⚠️ خطأ في تحديث كلمة المرور: ${e?.message}`, 'error');
    }
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

  // Synchronize Core Datasets with Supabase Cloud
  const loadCloudData = useCallback(async (notify = false) => {
    let isMounted = true;
    try {
        // 1. Products
        const { data: dbProducts } = await supabase
          .from('products')
          .select('*')
          .order('created_at', { ascending: false });

        if (isMounted && dbProducts && dbProducts.length > 0) {
          const mappedProducts: Product[] = dbProducts.map((p: any) => ({
            id: p.id,
            name_ar: p.name_ar,
            name_en: p.name_en || p.name_ar,
            brand: p.brand || 'طازج',
            category_id: p.category_id,
            barcode: p.barcode,
            price: Number(p.price),
            original_price: p.original_price ? Number(p.original_price) : Number(p.price),
            discount_percent: p.discount_percent || 0,
            unit: p.unit || 'piece',
            weight_step: Number(p.weight_step || 1.0),
            stock_quantity: Number(p.stock_quantity || 0),
            images: Array.isArray(p.images) && p.images.length > 0 ? p.images : ['https://images.unsplash.com/photo-1610348725531-843dff563e2c?auto=format&fit=crop&w=400&q=80'],
            is_featured: !!p.is_featured,
            is_daily_deal: !!p.is_daily_deal,
            rating: Number(p.rating || 4.8),
            sales_count: Number(p.sales_count || 0),
            bundle_enabled: !!p.bundle_enabled,
            bundle_discount_percent: p.bundle_discount_percent,
            bundle_title: p.bundle_title,
            bundle_product_ids: p.bundle_product_ids,
            branch_id: p.branch_id,
            branch_name: p.branch_name,
            is_draft: !!p.is_draft,
            cost_price: p.cost_price ? Number(p.cost_price) : undefined,
            status: p.status || 'published',
            is_active: p.is_active !== false,
          }));
          setProducts(mappedProducts);
          try {
            localStorage.setItem(STORAGE_KEYS.PRODUCTS, JSON.stringify(mappedProducts));
          } catch (e) {}
        }

        // 2. Categories
        const { data: dbCategories } = await supabase
          .from('categories')
          .select('*')
          .order('sort_order', { ascending: true });

        if (isMounted && dbCategories && dbCategories.length > 0) {
          const mappedCats: Category[] = dbCategories.map((c: any) => ({
            id: c.id,
            name_ar: c.name_ar,
            name_en: c.name_en || c.name_ar,
            slug: c.slug || 'category',
            icon_name: c.icon_name || 'shopping_basket',
            image_url: c.image_url,
            sort_order: Number(c.sort_order || 1),
            is_active: c.is_active !== false,
            show_title: c.show_title !== false,
            group_tag: c.group_tag,
            item_count: c.item_count ? Number(c.item_count) : undefined,
          }));
          setCategories(mappedCats);
          try {
            localStorage.setItem(STORAGE_KEYS.CATEGORIES, JSON.stringify(mappedCats));
          } catch (e) {}
        }

        // 3. Banners
        const { data: dbBanners } = await supabase
          .from('banners')
          .select('*')
          .order('sort_order', { ascending: true });

        if (isMounted && dbBanners && dbBanners.length > 0) {
          setBanners((prev) => {
            const cloudIds = new Set(dbBanners.map((b: any) => b.id));
            const localCustom = prev.filter((b) => !cloudIds.has(b.id));
            const merged = [...localCustom, ...(dbBanners as Banner[])];
            try {
              localStorage.setItem(STORAGE_KEYS.BANNERS, JSON.stringify(merged));
            } catch (e) {}
            return merged;
          });
        }

        // 4. Coupons
        const { data: dbCoupons } = await supabase
          .from('coupons')
          .select('*')
          .order('created_at', { ascending: false });

        if (isMounted && dbCoupons && dbCoupons.length > 0) {
          setCoupons((prev) => {
            const cloudIds = new Set(dbCoupons.map((c: any) => c.id));
            const localCustom = prev.filter((c) => !cloudIds.has(c.id));
            const merged = [...localCustom, ...(dbCoupons as Coupon[])];
            try {
              localStorage.setItem(STORAGE_KEYS.COUPONS, JSON.stringify(merged));
            } catch (e) {}
            return merged;
          });
        }

        // 5. Orders (with items)
        const { data: dbOrders } = await supabase
          .from('orders')
          .select('*, order_items(*)')
          .order('created_at', { ascending: false });

        if (isMounted && dbOrders && dbOrders.length > 0) {
          const mappedOrders: Order[] = dbOrders.map((o: any) => ({
            id: o.id,
            order_number: o.order_number,
            customer_name: o.customer_name || 'عميل الديب مول',
            customer_phone: o.customer_phone || '+971 50 123 4567',
            customer_address: o.notes || o.delivery_slot || 'عنوان التوصيل',
            status: o.status,
            delivery_slot: o.delivery_slot || 'توصيل فوري',
            payment_method: o.payment_method || 'cod',
            subtotal: Number(o.subtotal || 0),
            delivery_fee: Number(o.delivery_fee || 0),
            discount_amount: Number(o.discount_amount || 0),
            loyalty_discount: Number(o.loyalty_discount || 0),
            total_amount: Number(o.total_amount || 0),
            created_at: o.created_at || new Date().toISOString(),
            notes: o.notes,
            items: (o.order_items || []).map((it: any) => ({
              id: it.id,
              product_name_ar: it.product_name_ar,
              product_name_en: it.product_name_en || it.product_name_ar,
              product_image: it.product_image,
              unit_price: Number(it.unit_price || 0),
              quantity: Number(it.quantity || 1),
              unit: it.unit || 'piece',
              total_price: Number(it.total_price || 0),
            })),
            branch_id: o.branch_id || 'b-jed-01',
          }));
          setOrders(mappedOrders);
          try {
            localStorage.setItem(STORAGE_KEYS.ORDERS, JSON.stringify(mappedOrders));
          } catch (e) {}
        }

        // 6. Branches (from live database)
        const { data: dbBranches } = await supabase
          .from('branches')
          .select('*')
          .order('id', { ascending: true });

        if (isMounted && dbBranches && dbBranches.length > 0) {
          const mappedBranches: Branch[] = dbBranches.map((b: any) => ({
            id: b.id,
            code: b.code,
            name_ar: b.name_ar,
            name_en: b.name_en || b.name_ar,
            city: b.city,
            district: b.district || '',
            address: b.address || '',
            phone: b.phone || '',
            manager_name: b.manager_name || '',
            is_active: b.is_active !== false,
            terminals_count: Number(b.terminals_count || 4),
            daily_sales: Number(b.daily_sales || 0),
            currency: b.currency || 'ل.س',
            type: b.type || 'supermarket',
            created_at: b.created_at || new Date().toISOString(),
          }));
          setBranches(mappedBranches);
          try {
            localStorage.setItem(STORAGE_KEYS.BRANCHES, JSON.stringify(mappedBranches));
          } catch (e) {}
        }

        // 7. Staff Members (from live PostgreSQL / Supabase server)
        const { data: dbStaff } = await supabase
          .from('staff_members')
          .select('*')
          .order('employee_code', { ascending: true });

        if (isMounted && dbStaff && dbStaff.length > 0) {
          const mappedStaff: StaffMember[] = dbStaff.map((s: any) => ({
            id: s.id,
            employee_code: s.employee_code,
            full_name: s.full_name,
            username: s.username,
            email: s.email,
            phone: s.phone || '',
            role: s.role as StaffRole,
            branch_id: s.branch_id,
            branch_name: s.branch_name,
            password: undefined,
            password_hash: s.password_hash,
            can_change_password: !!s.can_change_password,
            has_pending_password_request: !!s.has_pending_password_request,
            basic_salary: Number(s.basic_salary || 5000),
            allowances: Number(s.allowances || 0),
            shift_start: s.shift_start || '08:00',
            shift_end: s.shift_end || '16:00',
            avatar_url: s.avatar_url || `https://api.dicebear.com/7.x/avataaars/svg?seed=${encodeURIComponent(s.username)}`,
            is_active: s.is_active !== false,
            joined_date: s.joined_date || new Date().toISOString().split('T')[0],
            session_revoked_at: s.session_revoked_at,
            created_at: s.created_at,
            updated_at: s.updated_at,
          }));
          setStaffList(mappedStaff);
          try {
            localStorage.setItem(STORAGE_KEYS.STAFF, JSON.stringify(mappedStaff));
          } catch (e) {}

          const savedUserId = localStorage.getItem('aldeeb_admin_user_id');
          if (savedUserId) {
            const updatedCurrent = mappedStaff.find(s => s.id === savedUserId);
            if (updatedCurrent) {
              setCurrentUser(updatedCurrent);
            }
          }
        }

        // 8. Password Change Requests (from live database)
        const { data: dbRequests } = await supabase
          .from('password_change_requests')
          .select('*')
          .order('requested_at', { ascending: false });

        if (isMounted && dbRequests) {
          const staffForRequests = dbStaff && dbStaff.length > 0 ? dbStaff : staffList;
          const mappedRequests: PasswordChangeRequest[] = dbRequests.map((r: any) => {
            const matchedEmp = staffForRequests.find((s: any) => s.id === r.employee_id);
            return {
              id: r.id,
              employee_id: r.employee_id,
              employee_name: matchedEmp ? matchedEmp.full_name : 'موظف في المنظومة',
              role: matchedEmp ? matchedEmp.role : 'cashier',
              branch_name: matchedEmp ? matchedEmp.branch_name : 'الفرع الرئيسي',
              requested_at: r.requested_at,
              reason: r.reason,
              status: r.status,
              reviewed_by: r.reviewed_by,
              reviewed_at: r.reviewed_at,
            };
          });
          setPasswordRequests(mappedRequests);
          try {
            localStorage.setItem(STORAGE_KEYS.PASSWORD_REQUESTS, JSON.stringify(mappedRequests));
          } catch (e) {}
        }

        // 9. Certified Suppliers (from PostgreSQL)
        const { data: dbSuppliers } = await supabase
          .from('suppliers')
          .select('*')
          .order('name_ar', { ascending: true });

        if (isMounted && dbSuppliers && dbSuppliers.length > 0) {
          const mappedSuppliers: Supplier[] = dbSuppliers.map((s: any) => ({
            id: s.id,
            name_ar: s.name_ar,
            name_en: s.name_en || s.name_ar,
            contact_person: s.contact_person || 'مسؤول التوريد',
            phone: s.phone || '',
            email: s.email || '',
            address: s.address || '',
            commercial_reg: s.commercial_reg || undefined,
            tax_number: s.tax_number || undefined,
            lead_time_days: Number(s.lead_time_days || 1),
            payment_terms: s.payment_terms || 'آجل 30 يوماً',
            active_products_count: Number(s.active_products_count || 0),
            balance: Number(s.balance || 0),
            status: s.status || 'active',
          }));
          setSuppliers(mappedSuppliers);
        }

        // 10. Purchase Orders with Items & Payments (from PostgreSQL)
        const { data: dbPOs } = await supabase
          .from('purchase_orders')
          .select('*, items:purchase_order_items(*), payments:supplier_payments(*)')
          .order('created_at', { ascending: false });

        if (isMounted && dbPOs) {
          const mappedPOs: PurchaseOrder[] = dbPOs.map((p: any) => ({
            id: p.id,
            po_number: p.po_number,
            supplier_id: p.supplier_id,
            supplier_name: p.supplier_name,
            branch_id: p.branch_id,
            branch_name: branches.find((b) => b.id === p.branch_id)?.name_ar || 'الفرع الرئيسي',
            status: p.status,
            payment_status: p.payment_status,
            total_items: Number(p.total_items || 0),
            total_cost: Number(p.total_cost || 0),
            paid_amount: Number(p.paid_amount || 0),
            order_date: p.order_date,
            expected_arrival: p.expected_arrival || '',
            notes: p.notes || '',
            cancellation_reason: p.cancellation_reason || undefined,
            created_by: p.created_by,
            items: (p.items || []).map((it: any) => ({
              id: it.id,
              purchase_order_id: it.purchase_order_id,
              product_id: it.product_id,
              name_ar: it.name_ar,
              barcode: it.barcode,
              unit: it.unit || 'piece',
              quantity_ordered: Number(it.quantity_ordered || 0),
              quantity_received: Number(it.quantity_received || 0),
              quantity_damaged: Number(it.quantity_damaged || 0),
              unit_cost: Number(it.unit_cost || 0),
              total_cost: Number(it.total_cost || 0),
              is_new_draft_product: !!it.is_new_draft_product,
            })),
            payments: (p.payments || []).map((pay: any) => ({
              id: pay.id,
              payment_number: pay.payment_number,
              purchase_order_id: pay.purchase_order_id,
              supplier_id: pay.supplier_id,
              amount: Number(pay.amount || 0),
              payment_method: pay.payment_method,
              payment_reference: pay.payment_reference,
              paid_by: pay.paid_by,
              notes: pay.notes,
              paid_at: pay.paid_at,
            })),
          }));
          setPurchaseOrders(mappedPOs);
        }
      } catch (err) {
        console.warn('⚠️ Supabase data sync note:', err);
      } finally {
        if (notify) {
          setSyncNotification({
            id: Date.now(),
            message: 'تمت مزامنة كافة الطلبات والمبيعات والمخزون مع السيرفر بنجاح ⚡',
            type: 'success',
          });
          setTimeout(() => setSyncNotification(null), 3500);
        }
      }
    },
    [staffList]
  );

  // Handle live completed orders from POS Terminal
  const handlePosOrderCompleted = useCallback(
    (newOrder: Order) => {
      setOrders((prev) => [newOrder, ...prev.filter((o) => o.id !== newOrder.id && o.order_number !== newOrder.order_number)]);
      if (newOrder.items && newOrder.items.length > 0) {
        setProducts((prev) =>
          prev.map((p) => {
            const sold = newOrder.items.find((it) => it.product_name_ar === p.name_ar || it.id === p.id);
            if (sold) {
              return {
                ...p,
                stock_quantity: Math.max(0, p.stock_quantity - sold.quantity),
                sales_count: (p.sales_count || 0) + sold.quantity,
              };
            }
            return p;
          })
        );
      }
      if (soundEnabled) {
        playOrderChime();
      }
      setSyncNotification({
        id: Date.now(),
        message: `تم تسجيل فاتورة كاشير جديدة بنجاح (${newOrder.order_number}) بمبلغ ${newOrder.total_amount.toFixed(2)} ل.س ✅`,
        type: 'success',
      });
      setTimeout(() => setSyncNotification(null), 4000);
      loadCloudData();
    },
    [soundEnabled, loadCloudData]
  );

  // Synchronize on mount and background poll every 8 seconds
  useEffect(() => {
    let isMounted = true;
    loadCloudData();

    const interval = setInterval(() => {
      if (isMounted) {
        loadCloudData();
      }
    }, 8000);

    return () => {
      isMounted = false;
      clearInterval(interval);
    };
  }, [loadCloudData]);

  // Auto-sync when navigating to operations, orders, or analytics
  useEffect(() => {
    if (activeTab === 'dashboard' || activeTab === 'orders' || activeTab === 'analytics' || activeTab === 'branches') {
      loadCloudData();
    }
  }, [activeTab, loadCloudData]);

  useEffect(() => {
    let isMounted = true;

    // Setup Realtime Subscription for incoming orders
    const ordersChannel = supabase
      .channel('admin_realtime_orders')
      .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'orders' }, async (payload) => {
        try {
          const newOrderId = payload.new.id;
          const { data: fullOrder } = await supabase
            .from('orders')
            .select('*, order_items(*)')
            .eq('id', newOrderId)
            .maybeSingle();

          if (fullOrder && isMounted) {
            const mapped: Order = {
              id: fullOrder.id,
              order_number: fullOrder.order_number,
              customer_name: fullOrder.customer_name || 'عميل الديب مول',
              customer_phone: fullOrder.customer_phone || '+971 50 123 4567',
              customer_address: fullOrder.notes || fullOrder.delivery_slot || 'عنوان التوصيل',
              status: fullOrder.status,
              delivery_slot: fullOrder.delivery_slot || 'توصيل فوري',
              payment_method: fullOrder.payment_method || 'cod',
              subtotal: Number(fullOrder.subtotal || 0),
              delivery_fee: Number(fullOrder.delivery_fee || 0),
              discount_amount: Number(fullOrder.discount_amount || 0),
              loyalty_discount: Number(fullOrder.loyalty_discount || 0),
              total_amount: Number(fullOrder.total_amount || 0),
              created_at: fullOrder.created_at || new Date().toISOString(),
              notes: fullOrder.notes,
              items: (fullOrder.order_items || []).map((it: any) => ({
                id: it.id,
                product_name_ar: it.product_name_ar,
                product_name_en: it.product_name_en || it.product_name_ar,
                product_image: it.product_image,
                unit_price: Number(it.unit_price || 0),
                quantity: Number(it.quantity || 1),
                unit: it.unit || 'piece',
                total_price: Number(it.total_price || 0),
              })),
              branch_id: fullOrder.branch_id || 'b-ruh-01',
            };

            setOrders((prev) => [mapped, ...prev.filter(o => o.id !== mapped.id)]);
            playOrderChime();
          }
        } catch (e) {
          console.warn('Realtime order arrival notice:', e);
        }
      })
      .subscribe();

    // Setup Realtime Subscription for Staff & Security Events
    const staffChannel = supabase
      .channel('admin_realtime_staff_and_security')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'staff_members' }, async () => {
        try {
          const { data: dbStaff } = await supabase
            .from('staff_members')
            .select('*')
            .order('employee_code', { ascending: true });
          if (dbStaff && isMounted) {
            const mappedStaff: StaffMember[] = dbStaff.map((s: any) => ({
              id: s.id,
              employee_code: s.employee_code,
              full_name: s.full_name,
              username: s.username,
              email: s.email,
              phone: s.phone || '',
              role: s.role as StaffRole,
              branch_id: s.branch_id,
              branch_name: s.branch_name,
              password: undefined,
              password_hash: s.password_hash,
              can_change_password: !!s.can_change_password,
              has_pending_password_request: !!s.has_pending_password_request,
              basic_salary: Number(s.basic_salary || 5000),
              allowances: Number(s.allowances || 0),
              shift_start: s.shift_start || '08:00',
              shift_end: s.shift_end || '16:00',
              avatar_url: s.avatar_url || `https://api.dicebear.com/7.x/avataaars/svg?seed=${encodeURIComponent(s.username)}`,
              is_active: s.is_active !== false,
              joined_date: s.joined_date || new Date().toISOString().split('T')[0],
              session_revoked_at: s.session_revoked_at,
              created_at: s.created_at,
              updated_at: s.updated_at,
            }));
            setStaffList(mappedStaff);
            try {
              localStorage.setItem(STORAGE_KEYS.STAFF, JSON.stringify(mappedStaff));
            } catch (e) {}
          }
        } catch (e) {
          console.warn('Realtime staff sync notice:', e);
        }
      })
      .on('postgres_changes', { event: '*', schema: 'public', table: 'password_change_requests' }, async () => {
        try {
          const { data: dbRequests } = await supabase
            .from('password_change_requests')
            .select('*')
            .order('requested_at', { ascending: false });
          if (dbRequests && isMounted) {
            const mappedRequests: PasswordChangeRequest[] = dbRequests.map((r: any) => {
              const matchedEmp = staffList.find((s) => s.id === r.employee_id);
              return {
                id: r.id,
                employee_id: r.employee_id,
                employee_name: matchedEmp ? matchedEmp.full_name : 'موظف في المنظومة',
                role: matchedEmp ? matchedEmp.role : 'cashier',
                branch_name: matchedEmp ? matchedEmp.branch_name : 'الفرع الرئيسي',
                requested_at: r.requested_at,
                reason: r.reason,
                status: r.status,
                reviewed_by: r.reviewed_by,
                reviewed_at: r.reviewed_at,
              };
            });
            setPasswordRequests(mappedRequests);
            try {
              localStorage.setItem(STORAGE_KEYS.PASSWORD_REQUESTS, JSON.stringify(mappedRequests));
            } catch (e) {}
          }
        } catch (e) {
          console.warn('Realtime password requests sync notice:', e);
        }
      })
      .subscribe();

    return () => {
      isMounted = false;
      supabase.removeChannel(ordersChannel);
      supabase.removeChannel(staffChannel);
    };
  }, []);

  // Status & Order Updater with Authoritative RPC & Stock Sync
  const handleUpdateOrderStatus = async (
    orderId: string, 
    newStatus: Order['status'],
    options?: {
      reason?: string;
      notes?: string;
      courierId?: string;
      courierName?: string;
      courierPhone?: string;
      expectedVersion?: number;
    }
  ) => {
    setOrders((prev) => {
      const updated = prev.map((o) => (
        o.id === orderId 
          ? { 
              ...o, 
              status: newStatus,
              courier_id: options?.courierId || o.courier_id,
              courier_name: options?.courierName || o.courier_name,
              cancellation_reason: newStatus === 'cancelled' ? (options?.reason || o.cancellation_reason) : o.cancellation_reason,
              failure_reason: newStatus === 'failed' ? (options?.reason || o.failure_reason) : o.failure_reason,
              version: (o.version || 1) + 1
            } 
          : o
      ));
      try {
        localStorage.setItem(STORAGE_KEYS.ORDERS, JSON.stringify(updated));
      } catch (e) {}
      return updated;
    });
    playOrderChime();

    try {
      if (orderId && orderId.length > 10) {
        const targetOrder = orders.find((o) => o.id === orderId);
        const { updateOrderStatusAtomic } = await import('./lib/ordersApi');
        const res = await updateOrderStatusAtomic({
          orderId,
          newStatus,
          expectedVersion: options?.expectedVersion ?? targetOrder?.version,
          reason: options?.reason,
          notes: options?.notes,
          courierId: options?.courierId,
          courierName: options?.courierName,
          courierPhone: options?.courierPhone,
          staffId: currentUser.id,
          staffName: currentUser.full_name,
          staffRole: currentUser.role
        });

        if (!res.success) {
          console.warn('⚠️ Supabase order update warning:', res.error);
          showSyncNotification(`❌ ${res.error || 'تعذر تحديث حالة الطلب'}`, 'error');
          loadCloudData(false);
          return false;
        } else {
          showSyncNotification(`✅ تم تحديث حالة الطلب إلى "${newStatus}" في السحابة والمتجر!`, 'success');
          loadCloudData(false);
          return true;
        }
      }
    } catch (e: any) {
      console.warn('Could not update order status in Supabase:', e);
      showSyncNotification(`❌ خطأ أثناء تحديث حالة الطلب: ${e?.message || e}`, 'error');
      loadCloudData(false);
      return false;
    }
  };

  const handleUpdateOrder = async (updatedOrder: Order) => {
    setOrders((prev) => {
      const updated = prev.map((o) => (o.id === updatedOrder.id ? updatedOrder : o));
      try {
        localStorage.setItem(STORAGE_KEYS.ORDERS, JSON.stringify(updated));
      } catch (e) {}
      return updated;
    });

    try {
      if (updatedOrder.id) {
        const { error } = await supabase
          .from('orders')
          .update({
            status: updatedOrder.status,
            courier_id: updatedOrder.courier_id,
            updated_at: new Date().toISOString(),
          })
          .eq('id', updatedOrder.id);
        if (error) {
          console.warn('⚠️ Supabase order update warning:', error.message);
        } else {
          showSyncNotification('✅ تم تحديث بيانات الطلب بنجاح في السحابة!', 'success');
        }
      }
    } catch (e) {
      console.warn('Could not update order in Supabase:', e);
    }
  };

  const handleUpdateCourier = (updatedCourier: Courier) => {
    setCouriers((prev) =>
      prev.map((c) => (c.id === updatedCourier.id ? updatedCourier : c))
    );
  };

  // Product Actions with Real Database-First Persistence & Validation
  const handleAddProduct = async (newProduct: Product) => {
    // 1. RBAC Permission Check
    if (currentUser.role === 'cashier' || (currentUser.role as string) === 'courier') {
      showSyncNotification('⚠️ غير مصرح لحساب الكاشير أو المندوب بإضافة أصناف جديدة للكتالوج.', 'error');
      return;
    }

    const sanitizedCatId = toCanonicalCategoryId(newProduct.category_id);
    const validId = ensureUUID(newProduct.id);

    const sanitizedProduct: Product = {
      ...newProduct,
      id: validId,
      category_id: sanitizedCatId,
      is_active: newProduct.is_active !== false,
    };

    // 2. Barcode Duplicate Validation
    if (sanitizedProduct.barcode) {
      const cleanBarcode = sanitizedProduct.barcode.trim();
      const duplicate = products.find(
        (p) => p.barcode && p.barcode.trim() === cleanBarcode && p.id !== sanitizedProduct.id
      );
      if (duplicate) {
        showSyncNotification(
          `⚠️ الباركود "${cleanBarcode}" مستخدم بالفعل لمنتج آخر: "${duplicate.name_ar}". يرجى استخدام باركود فريد.`,
          'error'
        );
        return;
      }
    }

    // 3. Price & Unit Integrity Validation
    if (sanitizedProduct.price <= 0) {
      showSyncNotification('⚠️ يجب أن يكون سعر البيع أكبر من الصفر.', 'error');
      return;
    }
    if (sanitizedProduct.original_price && sanitizedProduct.original_price < sanitizedProduct.price) {
      showSyncNotification('⚠️ لا يمكن أن يكون السعر الأصلي أقل من سعر البيع بعد الخصم.', 'error');
      return;
    }

    // 4. Prepare payload aligned 100% with database products table schema
    const supabasePayload = {
      id: sanitizedProduct.id,
      category_id: sanitizedProduct.category_id,
      barcode: sanitizedProduct.barcode || `${Math.floor(100000000000 + Math.random() * 900000000000)}`,
      name_ar: sanitizedProduct.name_ar,
      name_en: sanitizedProduct.name_en || sanitizedProduct.name_ar,
      description_ar: sanitizedProduct.name_ar,
      description_en: sanitizedProduct.name_en || sanitizedProduct.name_ar,
      brand: sanitizedProduct.brand || 'الديب مول',
      price: Number(sanitizedProduct.price),
      original_price: Number(sanitizedProduct.original_price || sanitizedProduct.price),
      discount_percent: Number(sanitizedProduct.discount_percent || 0),
      unit: sanitizedProduct.unit || 'piece',
      weight_step: Number(sanitizedProduct.weight_step || 1.0),
      stock_quantity: Number(sanitizedProduct.stock_quantity || 0),
      images: Array.isArray(sanitizedProduct.images) && sanitizedProduct.images.length > 0
        ? sanitizedProduct.images
        : ['https://images.unsplash.com/photo-1610348725531-843dff563e2c?auto=format&fit=crop&w=400&q=80'],
      is_featured: !!sanitizedProduct.is_featured,
      is_daily_deal: !!sanitizedProduct.is_daily_deal,
      rating: Number(sanitizedProduct.rating || 4.9),
      sales_count: Number(sanitizedProduct.sales_count || 0),
      bundle_enabled: !!sanitizedProduct.bundle_enabled,
      bundle_discount_percent: Number(sanitizedProduct.bundle_discount_percent || 0),
      bundle_title: sanitizedProduct.bundle_title || null,
      bundle_product_ids: sanitizedProduct.bundle_product_ids || [],
      is_active: sanitizedProduct.is_active !== false,
    };

    // 5. Database Write First - Strict Zero-Fake Policy
    try {
      const { error } = await supabase.from('products').insert(supabasePayload);
      if (error) {
        console.error('❌ Database product insert rejected:', error.message);
        showSyncNotification(`❌ فشل حفظ المنتج في قاعدة البيانات: ${error.message}`, 'error');
        return;
      }

      // Verified by server! Update local state & storage
      setProducts((prev) => {
        const updated = [sanitizedProduct, ...prev.filter((p) => p.id !== sanitizedProduct.id)];
        try {
          localStorage.setItem(STORAGE_KEYS.PRODUCTS, JSON.stringify(updated));
        } catch (e) {}
        return updated;
      });

      showSyncNotification(`✅ تم حفظ ونشر المنتج "${sanitizedProduct.name_ar}" بنجاح في قاعدة البيانات والمتجر!`, 'success');
    } catch (e: any) {
      console.error('Database product insert network error:', e);
      showSyncNotification(`❌ خطأ في الاتصال بقاعدة البيانات: ${e?.message}`, 'error');
    }
  };

  const handleUpdateProduct = async (updatedProduct: Product) => {
    if (currentUser.role === 'cashier' || (currentUser.role as string) === 'courier') {
      showSyncNotification('⚠️ غير مصرح لحساب الكاشير أو المندوب بتعديل المنتجات.', 'error');
      return;
    }

    const sanitizedCatId = toCanonicalCategoryId(updatedProduct.category_id);
    const validId = ensureUUID(updatedProduct.id);

    const sanitizedProduct: Product = {
      ...updatedProduct,
      id: validId,
      category_id: sanitizedCatId,
      is_active: updatedProduct.is_active !== false,
    };

    // Barcode duplicate validation against other products
    if (sanitizedProduct.barcode) {
      const cleanBarcode = sanitizedProduct.barcode.trim();
      const duplicate = products.find(
        (p) => p.barcode && p.barcode.trim() === cleanBarcode && p.id !== sanitizedProduct.id
      );
      if (duplicate) {
        showSyncNotification(
          `⚠️ الباركود "${cleanBarcode}" مستخدم بالفعل لمنتج آخر: "${duplicate.name_ar}".`,
          'error'
        );
        return;
      }
    }

    const supabasePayload = {
      category_id: sanitizedProduct.category_id,
      barcode: sanitizedProduct.barcode,
      name_ar: sanitizedProduct.name_ar,
      name_en: sanitizedProduct.name_en || sanitizedProduct.name_ar,
      brand: sanitizedProduct.brand,
      price: Number(sanitizedProduct.price),
      original_price: Number(sanitizedProduct.original_price || sanitizedProduct.price),
      discount_percent: Number(sanitizedProduct.discount_percent || 0),
      unit: sanitizedProduct.unit,
      weight_step: Number(sanitizedProduct.weight_step || 1.0),
      stock_quantity: Number(sanitizedProduct.stock_quantity || 0),
      images: sanitizedProduct.images,
      is_featured: !!sanitizedProduct.is_featured,
      is_daily_deal: !!sanitizedProduct.is_daily_deal,
      is_active: sanitizedProduct.is_active !== false,
      bundle_enabled: !!sanitizedProduct.bundle_enabled,
      bundle_discount_percent: Number(sanitizedProduct.bundle_discount_percent || 0),
      bundle_title: sanitizedProduct.bundle_title || null,
      bundle_product_ids: sanitizedProduct.bundle_product_ids || [],
      updated_at: new Date().toISOString(),
    };

    try {
      const { error } = await supabase.from('products').update(supabasePayload).eq('id', sanitizedProduct.id);
      if (error) {
        console.error('❌ Database product update error:', error.message);
        showSyncNotification(`❌ فشل تحديث بيانات المنتج في الخادم: ${error.message}`, 'error');
        return;
      }

      setProducts((prev) => {
        const updated = prev.map((p) => (p.id === sanitizedProduct.id ? sanitizedProduct : p));
        try {
          localStorage.setItem(STORAGE_KEYS.PRODUCTS, JSON.stringify(updated));
        } catch (e) {}
        return updated;
      });

      showSyncNotification(`✅ تم تحديث بيانات المنتج "${sanitizedProduct.name_ar}" في قاعدة البيانات والمتجر!`, 'success');
    } catch (e: any) {
      console.error('Supabase product update error:', e);
      showSyncNotification(`❌ خطأ في الاتصال أثناء تحديث المنتج: ${e?.message}`, 'error');
    }
  };

  const handleToggleProductActive = async (product: Product) => {
    if (currentUser.role === 'cashier' || (currentUser.role as string) === 'courier') {
      showSyncNotification('⚠️ غير مصرح لك بتعطيل أو تفعيل المنتجات.', 'error');
      return;
    }

    const newActiveState = !(product.is_active !== false);

    try {
      const { error } = await supabase
        .from('products')
        .update({ is_active: newActiveState, updated_at: new Date().toISOString() })
        .eq('id', product.id);

      if (error) {
        console.error('❌ Database product toggle error:', error.message);
        showSyncNotification(`❌ فشل تغيير حالة المنتج في الخادم: ${error.message}`, 'error');
        return;
      }

      const updatedProduct = { ...product, is_active: newActiveState };
      setProducts((prev) => {
        const updated = prev.map((p) => (p.id === product.id ? updatedProduct : p));
        try {
          localStorage.setItem(STORAGE_KEYS.PRODUCTS, JSON.stringify(updated));
        } catch (e) {}
        return updated;
      });

      showSyncNotification(
        newActiveState
          ? `✅ تم تفعيل الصنف "${product.name_ar}" وأصبح متاحاً للبيع فوراً في الكاشير وتطبيق العملاء!`
          : `⏸️ تم تعطيل الصنف "${product.name_ar}" وحجبه عن الكاشير وتطبيق العملاء بنجاح.`,
        newActiveState ? 'success' : 'warning'
      );
    } catch (e: any) {
      showSyncNotification(`❌ خطأ في الاتصال بقاعدة البيانات: ${e?.message}`, 'error');
    }
  };

  const handleDeleteProduct = async (productId: string) => {
    if (currentUser.role === 'cashier' || (currentUser.role as string) === 'courier') {
      showSyncNotification('⚠️ غير مصرح لحساب الكاشير بحذف المنتجات.', 'error');
      return;
    }

    try {
      const { error } = await supabase.from('products').delete().eq('id', productId);
      if (error) {
        console.warn('⚠️ Supabase product delete error:', error.message);
        showSyncNotification(`❌ فشل حذف المنتج من قاعدة البيانات: ${error.message}`, 'error');
        return;
      }

      setProducts((prev) => {
        const updated = prev.filter((p) => p.id !== productId);
        try {
          localStorage.setItem(STORAGE_KEYS.PRODUCTS, JSON.stringify(updated));
        } catch (e) {}
        return updated;
      });

      showSyncNotification('✅ تم حذف المنتج بنجاح من قاعدة البيانات والمتجر!', 'success');
    } catch (e: any) {
      showSyncNotification(`❌ خطأ في حذف المنتج: ${e?.message}`, 'error');
    }
  };

  // ============================================================================
  // Procurement & Supplier Actions (Task 8: Zero Defect Server Operations)
  // ============================================================================
  const handleCreatePO = async (poData: {
    supplier_id: string;
    supplier_name: string;
    branch_id: string;
    expected_arrival: string;
    notes: string;
    items: any[];
  }): Promise<boolean> => {
    try {
      if (currentUser.role === 'cashier' || currentUser.role === 'auditor') {
        showSyncNotification('⚠️ غير مصرح لحسابك بإصدار أوامر الشراء والتوريد.', 'error');
        return false;
      }

      const { data, error } = await supabase.rpc('create_purchase_order', {
        p_supplier_id: poData.supplier_id || null,
        p_supplier_name: poData.supplier_name,
        p_branch_id: poData.branch_id || activeBranchId || 'b-dam-01',
        p_expected_arrival: poData.expected_arrival || 'خلال 24 ساعة',
        p_notes: poData.notes || '',
        p_items: poData.items,
        p_created_by: currentUser.full_name || 'مدير المشتريات',
      });

      if (error) {
        showSyncNotification(`❌ فشل إصدار أمر الشراء: ${error.message}`, 'error');
        return false;
      }

      await loadCloudData(false);
      playOrderChime();
      showSyncNotification(`✅ تم إصدار أمر الشراء ${data?.po_number || ''} وتثبيته في قاعدة البيانات بنجاح ⚡`, 'success');
      return true;
    } catch (err: any) {
      showSyncNotification(`❌ خطأ في الاتصال بالخادم: ${err.message}`, 'error');
      return false;
    }
  };

  const handleReceivePO = async (
    poId: string,
    receipts: { item_id: string; quantity_received: number; quantity_damaged: number }[],
    branchId: string
  ): Promise<boolean> => {
    try {
      if (currentUser.role === 'cashier' || currentUser.role === 'auditor') {
        showSyncNotification('⚠️ غير مصرح لحسابك باستلام بضائع المستودع أو تعديل المخزون.', 'error');
        return false;
      }

      const { data, error } = await supabase.rpc('receive_purchase_order_items', {
        p_po_id: poId,
        p_receipts: receipts,
        p_receiver: currentUser.full_name || 'أمين المستودع',
        p_branch_id: branchId || activeBranchId || 'b-dam-01',
      });

      if (error) {
        showSyncNotification(`❌ فشل تأكيد الاستلام: ${error.message}`, 'error');
        return false;
      }

      await loadCloudData(false);
      playOrderChime();
      showSyncNotification(
        data?.all_fulfilled
          ? '✅ تم استلام أمر الشراء بالكامل وتحديث أرصدة المخزون وسجل الحركة بنجاح 📦'
          : '✅ تم قيد الاستلام الجزئي للبضاعة وتحديث المخزون بنجاح 📦',
        'success'
      );
      return true;
    } catch (err: any) {
      showSyncNotification(`❌ خطأ أثناء الاستلام: ${err.message}`, 'error');
      return false;
    }
  };

  const handleRecordPayment = async (
    poId: string,
    amount: number,
    method: string,
    reference: string,
    notes?: string
  ): Promise<boolean> => {
    try {
      if (currentUser.role !== 'super_admin' && currentUser.role !== 'general_manager' && currentUser.role !== 'accountant') {
        showSyncNotification('⚠️ غير مصرح لحسابك بتسجيل دفعات الموردين المالية.', 'error');
        return false;
      }

      const { data, error } = await supabase.rpc('record_supplier_payment', {
        p_po_id: poId,
        p_amount: amount,
        p_payment_method: method,
        p_reference: reference || null,
        p_payer: currentUser.full_name || 'المحاسب المالي',
        p_notes: notes || null,
      });

      if (error) {
        showSyncNotification(`❌ فشل تسجيل السداد: ${error.message}`, 'error');
        return false;
      }

      await loadCloudData(false);
      playOrderChime();
      showSyncNotification(
        `✅ تم قيد دفعة السداد (${data?.payment_number}) بمبلغ ${amount.toLocaleString()} ل.س في حساب المورد 💳`,
        'success'
      );
      return true;
    } catch (err: any) {
      showSyncNotification(`❌ خطأ أثناء تسجيل السداد: ${err.message}`, 'error');
      return false;
    }
  };

  const handleCancelPO = async (poId: string, reason: string): Promise<boolean> => {
    try {
      if (currentUser.role === 'cashier' || currentUser.role === 'auditor') {
        showSyncNotification('⚠️ غير مصرح لحسابك بإلغاء أوامر الشراء.', 'error');
        return false;
      }

      const { data, error } = await supabase.rpc('cancel_purchase_order', {
        p_po_id: poId,
        p_reason: reason || 'إلغاء من قبل الإدارة',
        p_user: currentUser.full_name || 'مدير المشتريات',
      });

      if (error) {
        showSyncNotification(`❌ فشل إلغاء أمر الشراء: ${error.message}`, 'error');
        return false;
      }

      await loadCloudData(false);
      showSyncNotification('✅ تم إلغاء أمر الشراء وتعديل رصيد المورد بنجاح.', 'success');
      return true;
    } catch (err: any) {
      showSyncNotification(`❌ خطأ أثناء الإلغاء: ${err.message}`, 'error');
      return false;
    }
  };

  const handleAddSupplier = async (supplierData: Partial<Supplier>): Promise<boolean> => {
    try {
      if (currentUser.role === 'cashier' || (currentUser.role as string) === 'courier') {
        showSyncNotification('⚠️ غير مصرح لحسابك بإضافة موردين جدد.', 'error');
        return false;
      }

      const { data, error } = await supabase
        .from('suppliers')
        .insert({
          name_ar: supplierData.name_ar,
          name_en: supplierData.name_en || supplierData.name_ar,
          contact_person: supplierData.contact_person || 'مسؤول التوريد',
          phone: supplierData.phone || '',
          email: supplierData.email || '',
          address: supplierData.address || '',
          commercial_reg: supplierData.commercial_reg || null,
          tax_number: supplierData.tax_number || null,
          lead_time_days: supplierData.lead_time_days || 1,
          payment_terms: supplierData.payment_terms || 'آجل 30 يوماً',
          active_products_count: supplierData.active_products_count || 0,
          balance: supplierData.balance || 0,
          status: supplierData.status || 'active',
        })
        .select()
        .single();

      if (error) {
        showSyncNotification(`❌ فشل تسجيل المورد: ${error.message}`, 'error');
        return false;
      }

      await loadCloudData(false);
      showSyncNotification(`✅ تم تسجيل المورد المعتمد "${supplierData.name_ar}" بنجاح في قاعدة البيانات.`, 'success');
      return true;
    } catch (err: any) {
      showSyncNotification(`❌ خطأ أثناء تسجيل المورد: ${err.message}`, 'error');
      return false;
    }
  };

  const handleApproveDraftProduct = async (productId: string): Promise<boolean> => {
    try {
      const { data, error } = await supabase.rpc('approve_draft_product', {
        p_product_id: productId,
        p_user: currentUser.full_name || 'مدير الكتالوج',
      });

      if (error) {
        showSyncNotification(`❌ فشل اعتماد الصنف: ${error.message}`, 'error');
        return false;
      }

      await loadCloudData(false);
      showSyncNotification('✅ تم اعتماد ونشر الصنف بنجاح، وأصبح متاحاً رسمياً لتطبيق العملاء 🌟', 'success');
      return true;
    } catch (err: any) {
      showSyncNotification(`❌ خطأ أثناء الاعتماد: ${err.message}`, 'error');
      return false;
    }
  };

  // Category Actions with Multi-Tier Persistence
  const handleAddCategory = async (newCategory: Category) => {
    const validId = ensureUUID(newCategory.id);
    const sanitizedCat: Category = { ...newCategory, id: validId };

    setCategories((prev) => {
      const updated = [...prev, sanitizedCat];
      try {
        localStorage.setItem(STORAGE_KEYS.CATEGORIES, JSON.stringify(updated));
      } catch (e) {}
      return updated;
    });

    try {
      const { error } = await supabase.from('categories').insert({
        id: sanitizedCat.id,
        name_ar: sanitizedCat.name_ar,
        name_en: sanitizedCat.name_en || sanitizedCat.name_ar,
        slug: sanitizedCat.slug,
        icon_name: sanitizedCat.icon_name || 'shopping_basket',
        image_url: sanitizedCat.image_url,
        sort_order: sanitizedCat.sort_order || 1,
        is_active: sanitizedCat.is_active !== false,
      });
      if (error) {
        console.warn('⚠️ Supabase Cloud category insert warning:', error.message);
        showSyncNotification(`💾 تم حفظ القسم "${sanitizedCat.name_ar}" محلياً.`, 'warning');
      } else {
        showSyncNotification(`✅ تم نشر القسم "${sanitizedCat.name_ar}" في السحابة والمتجر!`, 'success');
      }
    } catch (e) {
      console.warn('Supabase category insert error:', e);
    }
  };

  const handleUpdateCategory = async (updatedCat: Category) => {
    const validId = ensureUUID(updatedCat.id);
    const sanitizedCat: Category = { ...updatedCat, id: validId };

    setCategories((prev) => {
      const updated = prev.map((c) => (c.id === sanitizedCat.id ? sanitizedCat : c));
      try {
        localStorage.setItem(STORAGE_KEYS.CATEGORIES, JSON.stringify(updated));
      } catch (e) {}
      return updated;
    });

    try {
      const { error } = await supabase.from('categories').update({
        name_ar: sanitizedCat.name_ar,
        name_en: sanitizedCat.name_en || sanitizedCat.name_ar,
        slug: sanitizedCat.slug,
        image_url: sanitizedCat.image_url,
        sort_order: sanitizedCat.sort_order,
        is_active: sanitizedCat.is_active,
      }).eq('id', sanitizedCat.id);
      if (error) {
        console.warn('⚠️ Supabase Cloud category update warning:', error.message);
      } else {
        showSyncNotification(`✅ تم تحديث القسم "${sanitizedCat.name_ar}" في السحابة والمتجر!`, 'success');
      }
    } catch (e) {
      console.warn('Supabase category update error:', e);
    }
  };

  const handleDeleteCategory = async (categoryId: string) => {
    setCategories((prev) => {
      const updated = prev.filter((c) => c.id !== categoryId);
      try {
        localStorage.setItem(STORAGE_KEYS.CATEGORIES, JSON.stringify(updated));
      } catch (e) {}
      return updated;
    });

    try {
      const { error } = await supabase.from('categories').delete().eq('id', categoryId);
      if (error) {
        console.warn('⚠️ Supabase Cloud category delete warning:', error.message);
      } else {
        showSyncNotification('✅ تم حذف القسم بنجاح من السحابة والمتجر!', 'success');
      }
    } catch (e) {
      console.warn('Supabase category delete error:', e);
    }
  };

  const handleToggleCategory = async (categoryId: string) => {
    let updatedActive = false;
    setCategories((prev) => {
      const updated = prev.map((c) => {
        if (c.id === categoryId) {
          updatedActive = !c.is_active;
          return { ...c, is_active: updatedActive };
        }
        return c;
      });
      try {
        localStorage.setItem(STORAGE_KEYS.CATEGORIES, JSON.stringify(updated));
      } catch (e) {}
      return updated;
    });

    try {
      await supabase.from('categories').update({ is_active: updatedActive }).eq('id', categoryId);
    } catch (e) {
      console.warn('Could not update category in Supabase:', e);
    }
  };

  // Banner Actions with Multi-Tier Persistence
  const handleAddBanner = async (newBanner: Banner) => {
    const validId = ensureUUID(newBanner.id);
    const sanitizedBanner: Banner = { ...newBanner, id: validId };

    setBanners((prev) => {
      const updated = [sanitizedBanner, ...prev];
      try {
        localStorage.setItem(STORAGE_KEYS.BANNERS, JSON.stringify(updated));
      } catch (e) {}
      return updated;
    });

    try {
      const { error } = await supabase.from('banners').insert({
        id: sanitizedBanner.id,
        title_ar: sanitizedBanner.title_ar,
        title_en: sanitizedBanner.title_en,
        subtitle_ar: sanitizedBanner.subtitle_ar,
        subtitle_en: sanitizedBanner.subtitle_en,
        image_url: sanitizedBanner.image_url,
        slot: sanitizedBanner.slot,
        target_type: sanitizedBanner.target_type,
        target_id: sanitizedBanner.target_id,
        badge_ar: sanitizedBanner.badge_ar,
        badge_color: sanitizedBanner.badge_color,
        sort_order: sanitizedBanner.sort_order,
        is_active: sanitizedBanner.is_active,
      });
      if (error) {
        console.warn('⚠️ Supabase Cloud banner insert warning:', error.message);
        showSyncNotification(`💾 تم حفظ البانر "${sanitizedBanner.title_ar}" محلياً.`, 'warning');
      } else {
        showSyncNotification(`✅ تم نشر البانر "${sanitizedBanner.title_ar}" في السحابة والمتجر!`, 'success');
      }
    } catch (e) {
      console.warn('Supabase banner insert error:', e);
    }
  };

  const handleUpdateBanner = async (updatedBanner: Banner) => {
    const validId = ensureUUID(updatedBanner.id);
    const sanitizedBanner: Banner = { ...updatedBanner, id: validId };

    setBanners((prev) => {
      const updated = prev.map((b) => (b.id === sanitizedBanner.id ? sanitizedBanner : b));
      try {
        localStorage.setItem(STORAGE_KEYS.BANNERS, JSON.stringify(updated));
      } catch (e) {}
      return updated;
    });

    try {
      const { error } = await supabase.from('banners').update({
        title_ar: sanitizedBanner.title_ar,
        title_en: sanitizedBanner.title_en,
        subtitle_ar: sanitizedBanner.subtitle_ar,
        subtitle_en: sanitizedBanner.subtitle_en,
        image_url: sanitizedBanner.image_url,
        slot: sanitizedBanner.slot,
        target_type: sanitizedBanner.target_type,
        target_id: sanitizedBanner.target_id,
        badge_ar: sanitizedBanner.badge_ar,
        badge_color: sanitizedBanner.badge_color,
        sort_order: sanitizedBanner.sort_order,
        is_active: sanitizedBanner.is_active,
      }).eq('id', sanitizedBanner.id);
      if (error) {
        console.warn('⚠️ Supabase Cloud banner update warning:', error.message);
      } else {
        showSyncNotification(`✅ تم تحديث البانر "${sanitizedBanner.title_ar}" في السحابة والمتجر!`, 'success');
      }
    } catch (e) {
      console.warn('Supabase banner update error:', e);
    }
  };

  const handleDeleteBanner = async (bannerId: string) => {
    setBanners((prev) => {
      const updated = prev.filter((b) => b.id !== bannerId);
      try {
        localStorage.setItem(STORAGE_KEYS.BANNERS, JSON.stringify(updated));
      } catch (e) {}
      return updated;
    });

    try {
      const { error } = await supabase.from('banners').delete().eq('id', bannerId);
      if (error) {
        console.warn('⚠️ Supabase Cloud banner delete warning:', error.message);
      } else {
        showSyncNotification('✅ تم حذف البانر بنجاح من السحابة والمتجر!', 'success');
      }
    } catch (e) {
      console.warn('Supabase banner delete error:', e);
    }
  };

  const handleToggleBanner = async (bannerId: string) => {
    let updatedActive = false;
    setBanners((prev) => {
      const updated = prev.map((b) => {
        if (b.id === bannerId) {
          updatedActive = !b.is_active;
          return { ...b, is_active: updatedActive };
        }
        return b;
      });
      try {
        localStorage.setItem(STORAGE_KEYS.BANNERS, JSON.stringify(updated));
      } catch (e) {}
      return updated;
    });

    try {
      await supabase.from('banners').update({ is_active: updatedActive }).eq('id', bannerId);
    } catch (e) {
      console.warn('Could not update banner in Supabase:', e);
    }
  };

  // Coupon Actions with Multi-Tier Persistence
  const handleAddCoupon = async (newCoupon: Coupon) => {
    const validId = ensureUUID(newCoupon.id);
    const sanitizedCoupon: Coupon = { ...newCoupon, id: validId };

    setCoupons((prev) => {
      const updated = [sanitizedCoupon, ...prev];
      try {
        localStorage.setItem(STORAGE_KEYS.COUPONS, JSON.stringify(updated));
      } catch (e) {}
      return updated;
    });

    try {
      const { error } = await supabase.from('coupons').upsert({
        id: sanitizedCoupon.id,
        code: sanitizedCoupon.code,
        discount_type: sanitizedCoupon.discount_type,
        discount_value: sanitizedCoupon.discount_value,
        min_order_amount: sanitizedCoupon.min_order_amount,
        max_discount: sanitizedCoupon.max_discount || null,
        usage_limit: sanitizedCoupon.usage_limit || null,
        times_used: 0,
        expires_at: sanitizedCoupon.expires_at || null,
        is_active: sanitizedCoupon.is_active,
      }, { onConflict: 'code' });
      if (error) {
        console.warn('⚠️ Supabase Cloud coupon insert warning:', error.message);
        showSyncNotification(`💾 تم حفظ كود الخصم "${sanitizedCoupon.code}" محلياً.`, 'warning');
      } else {
        showSyncNotification(`✅ تم تفعيل كود الخصم "${sanitizedCoupon.code}" في السحابة والمتجر!`, 'success');
      }
    } catch (e) {
      console.warn('Supabase coupon insert error:', e);
    }
  };

  const handleToggleCoupon = async (couponId: string) => {
    let updatedActive = false;
    setCoupons((prev) => {
      const updated = prev.map((c) => {
        if (c.id === couponId) {
          updatedActive = !c.is_active;
          return { ...c, is_active: updatedActive };
        }
        return c;
      });
      try {
        localStorage.setItem(STORAGE_KEYS.COUPONS, JSON.stringify(updated));
      } catch (e) {}
      return updated;
    });

    try {
      await supabase.from('coupons').update({ is_active: updatedActive }).eq('id', couponId);
    } catch (e) {
      console.warn('Could not update coupon in Supabase:', e);
    }
  };

  const handleDeleteCoupon = async (couponId: string) => {
    setCoupons((prev) => {
      const updated = prev.filter((c) => c.id !== couponId);
      try {
        localStorage.setItem(STORAGE_KEYS.COUPONS, JSON.stringify(updated));
      } catch (e) {}
      return updated;
    });

    try {
      const { error } = await supabase.from('coupons').delete().eq('id', couponId);
      if (error) {
        console.warn('⚠️ Supabase Cloud coupon delete warning:', error.message);
      } else {
        showSyncNotification('✅ تم حذف كود الخصم بنجاح من السحابة والمتجر!', 'success');
      }
    } catch (e) {
      console.warn('Could not delete coupon in Supabase:', e);
    }
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
          title: 'إدارة حسابات الموظفين والصلاحيات', 
          subtitle: 'فتح حسابات الموظفين، تحديد كلمات السر وقفل تعديلها إلا بإذن، وتقييد كل موظف بفرعه الإلزامي' 
        };
      case 'accounting_payroll':
        return { 
          title: 'إدارة الرواتب والخصومات والسلف', 
          subtitle: 'كشف مسير رواتب الموظفين، قيد السحبيات والسلف، تسجيل الخصومات والجزاءات، وصلاحيات المحاسب والمدقق' 
        };
      case 'invoice_designer':
        return { 
          title: 'تصميم قوالب الفواتير والباركود', 
          subtitle: 'تخصيص فاتورة الكاشير والطباعة الحرارية، إظهار/إخفاء الحقول، وإعداد الباركود المعتمد' 
        };
      case 'butcher_operations':
        return {
          title: 'إدارة الملحمة والمسمكة والذبح اليومي',
          subtitle: 'متابعة طلبات تفصيل اللحوم، شهادات الذبح الحلال، وتقطيع وتغليف الأسماك'
        };
      case 'cold_chain':
        return {
          title: 'سلسلة التبريد وحساسات درجات الحرارة (Cold Chain IoT)',
          subtitle: 'مراقبة درجات حرارة الثلاجات والمجمدات وسيارات التوصيل اللحظية والتنبيهات الحرجة'
        };
      case 'corporate_b2b':
        return {
          title: 'مبيعات الشركات والتوريد بالجملة (B2B Portal)',
          subtitle: 'عقود المطاعم، الفنادق، الكافيهات، الأسعار الخاصة والتسهيلات الائتمانية'
        };
      case 'live_shopping':
        return {
          title: 'استوديو البث المباشر والتسوق الحي (Live Commerce Studio)',
          subtitle: 'إدارة غرف البث، المنتجات المعروضة على الهواء، وأكواد الخصم اللحظية'
        };
      case 'marketplace_vendors':
        return {
          title: 'إدارة تجار الماركت بليس والموردين المحليين (Multi-Vendor)',
          subtitle: 'تسجيل التجار، عمولات المبيعات، ومطابقة المنتجات مع معايير الجودة'
        };
      case 'meal_kits':
        return {
          title: 'مطبخ الديب وبوكسات الطهي (Gourmet Meal Kits)',
          subtitle: 'إدارة وصفات الشيف، مقادير الوجبات الموزونة، وجدول تجهيز بوكسات الطبخ'
        };
      case 'pharmacy':
        return {
          title: 'إدارة الصيدلية الرقمية ونظام وصفتي (e-Pharmacy & Wasfaty)',
          subtitle: 'اعتماد الوصفات الطبية، تدقيق التعارضات الدوائية، وإعادة الصرف المزمن'
        };
      case 'price_match':
        return {
          title: 'ضمان أفضل سعر ومطابقة المنافسين (Price Match & Guarantee)',
          subtitle: 'مراجعة مطالبات فرق السعر مع العثيم وبنده وكارفور وتعويض المحفظة آلياً'
        };
      case 'smart_lockers':
        return {
          title: 'شبكة الخزائن الذكية والاستلام 24/7 (Smart Locker Network)',
          subtitle: 'توزيع الطرود في الحجرات المبردة والمجمدة ومراقبة رموز الاستلام والـ PIN'
        };
      case 'zero_waste':
        return {
          title: 'سوق إنقاذ الطعام ومكافحة الهدر (Zero Waste & Food Rescue)',
          subtitle: 'تخفيضات 50-70% على المنتجات قريبة الانتهاء وحساب الأثر البيئي'
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

  if (isVerifyingSession) {
    return (
      <div className="min-h-screen bg-slate-950 flex flex-col items-center justify-center text-white" dir="rtl">
        <div className="w-10 h-10 border-4 border-blue-500 border-t-transparent rounded-full animate-spin mb-4" />
        <p className="text-sm font-bold text-slate-300">جاري التحقق من جلسة الخادم المشفرة...</p>
      </div>
    );
  }

  if (!isAuthenticated) {
    return (
      <AdminLoginPage
        staffList={staffList}
        onLogin={handleLogin}
        initialError={authNotice}
      />
    );
  }

  if (activeTab === 'pos_terminal') {
    return (
      <PosTerminalPage
        targetBranchId={currentUser.role === 'super_admin' ? (posBranchId || activeBranchId) : currentUser.branch_id}
        onExitPos={() => {
          loadCloudData();
          setActiveTab('dashboard');
        }}
        onNavigateToInvoiceDesigner={() => setActiveTab('invoice_designer')}
        isBranchLocked={currentUser.role !== 'super_admin'}
        currentCashierName={currentUser.full_name}
        currentStaff={currentUser}
        products={products}
        onOrderCompleted={handlePosOrderCompleted}
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
      <div className="flex-1 flex flex-col min-w-0 overflow-x-hidden">
        <Header
          title={pageInfo.title}
          subtitle={pageInfo.subtitle}
          soundEnabled={soundEnabled}
          setSoundEnabled={setSoundEnabled}
          onRefresh={() => {
            playOrderChime();
            loadCloudData(true);
          }}
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
          onLogout={handleLogout}
        />

        {/* Sync Status Banner */}
        {syncNotification && (
          <div
            className={`mx-8 mt-4 p-4 rounded-2xl border flex items-center justify-between gap-3 shadow-sm transition-all duration-300 ${
              syncNotification.type === 'success'
                ? 'bg-emerald-50 border-emerald-200 text-emerald-900'
                : syncNotification.type === 'warning'
                ? 'bg-amber-50 border-amber-200 text-amber-900'
                : 'bg-blue-50 border-blue-200 text-blue-900'
            }`}
          >
            <div className="flex items-center gap-3">
              {syncNotification.type === 'success' ? (
                <CheckCircle2 className="w-5 h-5 text-emerald-600 flex-shrink-0" />
              ) : syncNotification.type === 'warning' ? (
                <AlertTriangle className="w-5 h-5 text-amber-600 flex-shrink-0" />
              ) : (
                <Info className="w-5 h-5 text-blue-600 flex-shrink-0" />
              )}
              <span className="text-xs md:text-sm font-bold">{syncNotification.message}</span>
            </div>
            <button
              onClick={() => setSyncNotification(null)}
              className="p-1 rounded-lg hover:bg-black/5 text-slate-500 transition-colors"
              title="إغلاق التنبيه"
            >
              <CloseIcon className="w-4 h-4" />
            </button>
          </div>
        )}

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
              branches={branches}
              onRefreshGlobalData={() => loadCloudData(true)}
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
              currentUser={currentUser}
              couriers={visibleCouriers}
              onRefreshOrders={() => loadCloudData(true)}
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
              currentUser={currentUser}
              activeBranchId={activeBranchId}
              branches={branches}
              orders={orders}
              products={products}
              onOrderUpdated={() => loadCloudData(true)}
            />
          )}

          {activeTab === 'inventory_transfer' && (
            <InventoryTransferPage
              darkStores={darkStores}
              products={products}
              branches={branches}
              currentUser={currentUser}
              onRefresh={() => loadCloudData(true)}
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
              activeBranchId={activeBranchId}
              userRole={currentUser.role}
              onAddProduct={handleAddProduct}
              onUpdateProduct={handleUpdateProduct}
              onDeleteProduct={handleDeleteProduct}
              onToggleProductActive={handleToggleProductActive}
            />
          )}

          {activeTab === 'suppliers' && (
            <SuppliersPage
              suppliers={suppliers}
              purchaseOrders={purchaseOrders}
              products={products}
              branches={branches}
              activeBranchId={activeBranchId}
              currentUser={currentUser}
              onAddPO={handleCreatePO}
              onReceivePO={handleReceivePO}
              onRecordPayment={handleRecordPayment}
              onCancelPO={handleCancelPO}
              onAddSupplier={handleAddSupplier}
              onApproveDraftProduct={handleApproveDraftProduct}
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

          {activeTab === 'corporate_b2b' && (
            <CorporateB2BPage
              currentUser={currentUser}
              activeBranchId={activeBranchId}
              products={products}
            />
          )}

          {['butcher_operations', 'cold_chain', 'live_shopping', 'marketplace_vendors', 'meal_kits', 'pharmacy', 'price_match', 'smart_lockers', 'zero_waste'].includes(activeTab) && (
            <div className="bg-slate-900 border border-slate-800 rounded-2xl p-8 text-center max-w-2xl mx-auto my-12">
              <div className="w-16 h-16 bg-amber-500/10 border border-amber-500/20 text-amber-400 rounded-2xl flex items-center justify-center mx-auto mb-4 text-2xl font-black">
                ⚠️
              </div>
              <h2 className="text-xl font-bold text-white mb-2">هذه الوحدة ملغاة بقرار تشغيلي معتمد</h2>
              <p className="text-sm text-slate-400 leading-relaxed mb-6">
                تم إلغاء هذه الوحدة من الواجهات والتشغيل الفعلي بناءً على توجيهات الإدارة المركزية (المادة 18)، مع الحفاظ التام على السجلات التاريخية والقيود المالية وقواعد البيانات المعتمدة لأغراض التدقيق المحاسبي.
              </p>
              <button
                onClick={() => setActiveTab('dashboard')}
                className="px-6 py-2.5 bg-blue-600 hover:bg-blue-500 text-white rounded-xl text-xs font-bold transition-all cursor-pointer"
              >
                العودة للوحة التحكم المركزية
              </button>
            </div>
          )}
        </main>
      </div>
    </div>
    </HelpProvider>
  );
};
