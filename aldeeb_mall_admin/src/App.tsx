import React, { useState } from 'react';
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
import { ColdChainPage } from './pages/ColdChainPage';
import { ReturnsPage } from './pages/ReturnsPage';
import { CourierPortalPage } from './pages/CourierPortalPage';
import { MerchandisingPage } from './pages/MerchandisingPage';
import { InventoryTransferPage } from './pages/InventoryTransferPage';
import { ForecastingPage } from './pages/ForecastingPage';
import { MarketplaceVendorsPage } from './pages/MarketplaceVendorsPage';
import { ZeroWastePage } from './pages/ZeroWastePage';
import { LiveShoppingPage } from './pages/LiveShoppingPage';
import { MealKitsPage } from './pages/MealKitsPage';
import { PriceMatchPage } from './pages/PriceMatchPage';
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
  initialDeliveryZones
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
  DeliveryZone
} from './types';

export const App: React.FC = () => {
  const [activeTab, setActiveTab] = useState<string>('dashboard');
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
  const [couriers] = useState<Courier[]>(initialCouriers);
  const [suppliers] = useState<Supplier[]>(initialSuppliers);
  const [purchaseOrders, setPurchaseOrders] = useState<PurchaseOrder[]>(initialPurchaseOrders);
  const [supportTickets] = useState<SupportTicket[]>(initialSupportTickets);
  const [campaigns, setCampaigns] = useState<MarketingCampaign[]>(initialCampaigns);
  const [deliveryZones] = useState<DeliveryZone[]>(initialDeliveryZones);

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

  // Status Updater
  const handleUpdateOrderStatus = (orderId: string, newStatus: Order['status']) => {
    setOrders((prev) =>
      prev.map((o) => (o.id === orderId ? { ...o, status: newStatus } : o))
    );
    playOrderChime();
  };

  // Product Actions
  const handleAddProduct = (newProduct: Product) => {
    setProducts((prev) => [newProduct, ...prev]);
  };

  const handleDeleteProduct = (productId: string) => {
    setProducts((prev) => prev.filter((p) => p.id !== productId));
  };

  // Category Actions
  const handleAddCategory = (newCategory: Category) => {
    setCategories((prev) => [...prev, newCategory]);
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
  };

  const pendingCount = orders.filter((o) => o.status === 'pending').length;

  const getPageTitle = () => {
    switch (activeTab) {
      case 'dashboard':
        return { title: 'لوحة التحكم والعمليات', subtitle: 'نظرة شاملة ومؤشرات أداء مبيعات الديب مول' };
      case 'analytics':
        return { title: 'ذكاء الأعمال والتحليلات المالية (BI Analytics)', subtitle: 'مؤشرات الإيرادات اللحظية، ساعات الذروة، ونسب التزام التوصيل 15 دقيقة' };
      case 'orders':
        return { title: 'إدارة الطلبات الفورية والفرز', subtitle: 'متابعة الطلبات المباشرة من الاستلام حتى تسليم السائق' };
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
      case 'categories':
        return { title: 'أقسام وتصنيفات الهايبرماركت', subtitle: 'ترتيب وإضافة الأقسام المعروضة للعملاء' };
      case 'coupons':
        return { title: 'كوبونات الخصم والعروض الترويجية', subtitle: 'إطلاق ومتابعة فاعلية حملات الأكواد التسويقية' };
      case 'loyalty':
        return { title: 'نادي العملاء ونقاط الولاء', subtitle: 'سجل العملاء، النقاط التراكمية، ومكافآت التقدير' };
      case 'settings':
        return { title: 'إعدادات المول وسياسات التوصيل', subtitle: 'العملة، رسوم التوصيل المجاني، ومعلومات الاتصال' };
      default:
        return { title: 'الديب مول', subtitle: '' };
    }
  };

  const pageInfo = getPageTitle();

  return (
    <div className="flex bg-slate-50 min-h-screen text-slate-800">
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
        />

        <main className="p-8 flex-1 overflow-y-auto">
          {activeTab === 'dashboard' && (
            <DashboardPage
              orders={orders}
              products={products}
              setActiveTab={setActiveTab}
              onUpdateOrderStatus={handleUpdateOrderStatus}
            />
          )}

          {activeTab === 'analytics' && (
            <AnalyticsPage
              orders={orders}
              products={products}
            />
          )}

          {activeTab === 'forecasting' && (
            <ForecastingPage />
          )}

          {activeTab === 'orders' && (
            <OrdersPage
              orders={orders}
              onUpdateOrderStatus={handleUpdateOrderStatus}
            />
          )}

          {activeTab === 'fulfillment' && (
            <FulfillmentPage
              darkStores={darkStores}
              pickerTasks={pickerTasks}
            />
          )}

          {activeTab === 'inventory_transfer' && (
            <InventoryTransferPage />
          )}

          {activeTab === 'flash_deals' && (
            <FlashDealsPage
              deals={flashDeals}
              products={products}
              onAddDeal={handleAddFlashDeal}
              onDeleteDeal={handleDeleteFlashDeal}
              onToggleDeal={handleToggleFlashDeal}
            />
          )}

          {activeTab === 'live_shopping' && (
            <LiveShoppingPage />
          )}

          {activeTab === 'fleet' && (
            <FleetPage
              couriers={couriers}
              orders={orders}
            />
          )}

          {activeTab === 'courier_portal' && (
            <CourierPortalPage />
          )}

          {activeTab === 'merchandising' && (
            <MerchandisingPage />
          )}

          {activeTab === 'meal_kits' && (
            <MealKitsPage />
          )}

          {activeTab === 'products' && (
            <ProductsPage
              products={products}
              categories={categories}
              onAddProduct={handleAddProduct}
              onDeleteProduct={handleDeleteProduct}
            />
          )}

          {activeTab === 'suppliers' && (
            <SuppliersPage
              suppliers={suppliers}
              purchaseOrders={purchaseOrders}
              products={products}
              onAddPO={(newPO) => setPurchaseOrders((prev) => [newPO, ...prev])}
            />
          )}

          {activeTab === 'marketplace_vendors' && (
            <MarketplaceVendorsPage />
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

          {activeTab === 'cold_chain' && (
            <ColdChainPage />
          )}

          {activeTab === 'zero_waste' && (
            <ZeroWastePage />
          )}

          {activeTab === 'returns' && (
            <ReturnsPage />
          )}

          {activeTab === 'categories' && (
            <CategoriesPage
              categories={categories}
              onAddCategory={handleAddCategory}
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

          {activeTab === 'price_match' && (
            <PriceMatchPage />
          )}

          {activeTab === 'loyalty' && (
            <LoyaltyPage
              customers={customers}
              onAddPoints={handleAddPoints}
            />
          )}

          {activeTab === 'settings' && <SettingsPage />}
        </main>
      </div>
    </div>
  );
};
