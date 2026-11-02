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
import { AdminLoginPage } from './pages/AdminLoginPage';
import { ButcherOperationsPage } from './pages/ButcherOperationsPage';
import { ColdChainPage } from './pages/ColdChainPage';
import { CorporateB2BPage } from './pages/CorporateB2BPage';
import { LiveShoppingPage } from './pages/LiveShoppingPage';
import { MarketplaceVendorsPage } from './pages/MarketplaceVendorsPage';
import { MealKitsPage } from './pages/MealKitsPage';
import { PharmacyPage } from './pages/PharmacyPage';
import { PriceMatchPage } from './pages/PriceMatchPage';
import { SmartLockersPage } from './pages/SmartLockersPage';
import { ZeroWastePage } from './pages/ZeroWastePage';
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
  };

  const getCachedData = <T,>(key: string, fallback: T[]): T[] => {
    if (typeof window === 'undefined') return fallback;
    try {
      const saved = localStorage.getItem(key);
      if (saved) {
        const parsed = JSON.parse(saved);
        if (Array.isArray(parsed) && parsed.length > 0) return parsed;
      }
    } catch (e) {
      console.warn(`Failed to read cache for ${key}:`, e);
    }
    return fallback;
  };

  // Sync Notification Banner State
  const [syncNotification, setSyncNotification] = useState<{
    message: string;
    type: 'success' | 'warning' | 'info';
    id: number;
  } | null>(null);

  const showSyncNotification = (message: string, type: 'success' | 'warning' | 'info' = 'info') => {
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
  const [banners, setBanners] = useState<Banner[]>(() => getCachedData(STORAGE_KEYS.BANNERS, initialBanners));

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
  const [currentUser, setCurrentUser] = useState<StaffMember>(() => {
    if (typeof window !== 'undefined') {
      const savedId = localStorage.getItem('aldeeb_admin_user_id');
      if (savedId) {
        const found = INITIAL_STAFF.find(s => s.id === savedId);
        if (found) return found;
      }
    }
    return INITIAL_STAFF[0];
  });
  const [isAuthenticated, setIsAuthenticated] = useState<boolean>(() => {
    if (typeof window !== 'undefined') {
      return localStorage.getItem('aldeeb_admin_auth') === 'true';
    }
    return false;
  });
  const [payrollTransactions, setPayrollTransactions] = useState<PayrollTransaction[]>(INITIAL_PAYROLL_TRANSACTIONS);
  const [passwordRequests, setPasswordRequests] = useState<PasswordChangeRequest[]>(INITIAL_PASSWORD_REQUESTS);

  const handleLogin = (staff: StaffMember) => {
    setCurrentUser(staff);
    setIsAuthenticated(true);
    if (typeof window !== 'undefined') {
      localStorage.setItem('aldeeb_admin_auth', 'true');
      localStorage.setItem('aldeeb_admin_user_id', staff.id);
    }
    if (staff.role === 'cashier') {
      setActiveTab('pos_terminal');
    }
  };

  const handleLogout = () => {
    setIsAuthenticated(false);
    if (typeof window !== 'undefined') {
      localStorage.removeItem('aldeeb_admin_auth');
      localStorage.removeItem('aldeeb_admin_user_id');
    }
  };

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

  // Synchronize Core Datasets with Supabase Cloud
  useEffect(() => {
    let isMounted = true;

    const loadCloudData = async () => {
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
          }));
          setProducts((prev) => {
            const cloudIds = new Set(mappedProducts.map((p) => p.id));
            const localCustom = prev.filter((p) => !cloudIds.has(p.id));
            const merged = [...localCustom, ...mappedProducts];
            try {
              localStorage.setItem(STORAGE_KEYS.PRODUCTS, JSON.stringify(merged));
            } catch (e) {}
            return merged;
          });
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
          setCategories((prev) => {
            const cloudIds = new Set(mappedCats.map((c) => c.id));
            const localCustom = prev.filter((c) => !cloudIds.has(c.id));
            const merged = [...localCustom, ...mappedCats];
            try {
              localStorage.setItem(STORAGE_KEYS.CATEGORIES, JSON.stringify(merged));
            } catch (e) {}
            return merged;
          });
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
            branch_id: o.branch_id || 'b-ruh-01',
          }));
          setOrders((prev) => {
            const cloudIds = new Set(mappedOrders.map((o) => o.id));
            const localCustom = prev.filter((o) => !cloudIds.has(o.id));
            const merged = [...localCustom, ...mappedOrders];
            try {
              localStorage.setItem(STORAGE_KEYS.ORDERS, JSON.stringify(merged));
            } catch (e) {}
            return merged;
          });
        }
      } catch (err) {
        console.warn('⚠️ Supabase data sync note:', err);
      }
    };

    loadCloudData();

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

    return () => {
      isMounted = false;
      supabase.removeChannel(ordersChannel);
    };
  }, []);

  // Status & Order Updater
  const handleUpdateOrderStatus = async (orderId: string, newStatus: Order['status']) => {
    setOrders((prev) => {
      const updated = prev.map((o) => (o.id === orderId ? { ...o, status: newStatus } : o));
      try {
        localStorage.setItem(STORAGE_KEYS.ORDERS, JSON.stringify(updated));
      } catch (e) {}
      return updated;
    });
    playOrderChime();

    try {
      if (orderId && orderId.length > 10) {
        const { error } = await supabase
          .from('orders')
          .update({ status: newStatus, updated_at: new Date().toISOString() })
          .eq('id', orderId);
        if (error) {
          console.warn('⚠️ Supabase order update warning:', error.message);
        } else {
          showSyncNotification(`✅ تم تحديث حالة الطلب إلى "${newStatus}" في السحابة والمتجر!`, 'success');
        }
      }
    } catch (e) {
      console.warn('Could not update order status in Supabase:', e);
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

  // Product Actions with Multi-Tier LocalStorage & Supabase Integration
  const handleAddProduct = async (newProduct: Product) => {
    const sanitizedCatId = toCanonicalCategoryId(newProduct.category_id);
    const validId = ensureUUID(newProduct.id);

    const sanitizedProduct: Product = {
      ...newProduct,
      id: validId,
      category_id: sanitizedCatId,
    };

    // 1. Immediately persist in local React state and Browser LocalStorage
    setProducts((prev) => {
      const updated = [sanitizedProduct, ...prev.filter((p) => p.id !== sanitizedProduct.id)];
      try {
        localStorage.setItem(STORAGE_KEYS.PRODUCTS, JSON.stringify(updated));
      } catch (e) {}
      return updated;
    });

    // 2. Prepare payload aligned 100% with Supabase products table schema
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
      is_active: true,
    };

    // 3. Attempt Supabase Cloud write
    try {
      const { error } = await supabase.from('products').insert(supabasePayload);
      if (error) {
        console.warn('⚠️ Supabase Cloud product insert warning (42501/RLS):', error.message);
        showSyncNotification(
          `💾 تم حفظ المنتج "${sanitizedProduct.name_ar}" محلياً في المتصفح! (تنبيه: للمزامنة مع السحابة، يرجى تشغيل FIX_ADMIN_RLS.sql في Supabase)`,
          'warning'
        );
      } else {
        showSyncNotification(`✅ تم حفظ ونشر المنتج "${sanitizedProduct.name_ar}" بنجاح في السحابة والمتجر!`, 'success');
      }
    } catch (e: any) {
      console.warn('Supabase product sync network error:', e);
      showSyncNotification(`💾 تم حفظ المنتج "${sanitizedProduct.name_ar}" محلياً في المتصفح.`, 'info');
    }
  };

  const handleUpdateProduct = async (updatedProduct: Product) => {
    const sanitizedCatId = toCanonicalCategoryId(updatedProduct.category_id);
    const validId = ensureUUID(updatedProduct.id);

    const sanitizedProduct: Product = {
      ...updatedProduct,
      id: validId,
      category_id: sanitizedCatId,
    };

    setProducts((prev) => {
      const updated = prev.map((p) => (p.id === sanitizedProduct.id ? sanitizedProduct : p));
      try {
        localStorage.setItem(STORAGE_KEYS.PRODUCTS, JSON.stringify(updated));
      } catch (e) {}
      return updated;
    });

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
      bundle_enabled: !!sanitizedProduct.bundle_enabled,
      bundle_discount_percent: Number(sanitizedProduct.bundle_discount_percent || 0),
      bundle_title: sanitizedProduct.bundle_title || null,
      bundle_product_ids: sanitizedProduct.bundle_product_ids || [],
      updated_at: new Date().toISOString(),
    };

    try {
      const { error } = await supabase.from('products').update(supabasePayload).eq('id', sanitizedProduct.id);
      if (error) {
        console.warn('⚠️ Supabase Cloud product update warning:', error.message);
        showSyncNotification(`💾 تم تحديث بيانات المنتج "${sanitizedProduct.name_ar}" محلياً.`, 'warning');
      } else {
        showSyncNotification(`✅ تم تحديث بيانات المنتج "${sanitizedProduct.name_ar}" في السحابة والمتجر!`, 'success');
      }
    } catch (e) {
      console.warn('Supabase product update error:', e);
    }
  };

  const handleDeleteProduct = async (productId: string) => {
    setProducts((prev) => {
      const updated = prev.filter((p) => p.id !== productId);
      try {
        localStorage.setItem(STORAGE_KEYS.PRODUCTS, JSON.stringify(updated));
      } catch (e) {}
      return updated;
    });

    try {
      const { error } = await supabase.from('products').delete().eq('id', productId);
      if (error) {
        console.warn('⚠️ Supabase Cloud product delete warning:', error.message);
      } else {
        showSyncNotification('✅ تم حذف المنتج بنجاح من السحابة والمتجر!', 'success');
      }
    } catch (e) {
      console.warn('Supabase delete product error:', e);
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
      const { error } = await supabase.from('coupons').insert({
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
      });
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

  if (!isAuthenticated) {
    return (
      <AdminLoginPage
        staffList={staffList}
        onLogin={handleLogin}
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

          {activeTab === 'butcher_operations' && <ButcherOperationsPage />}
          {activeTab === 'cold_chain' && <ColdChainPage />}
          {activeTab === 'corporate_b2b' && <CorporateB2BPage />}
          {activeTab === 'live_shopping' && <LiveShoppingPage />}
          {activeTab === 'marketplace_vendors' && <MarketplaceVendorsPage />}
          {activeTab === 'meal_kits' && <MealKitsPage />}
          {activeTab === 'pharmacy' && <PharmacyPage />}
          {activeTab === 'price_match' && <PriceMatchPage />}
          {activeTab === 'smart_lockers' && <SmartLockersPage />}
          {activeTab === 'zero_waste' && <ZeroWastePage />}
        </main>
      </div>
    </div>
    </HelpProvider>
  );
};
