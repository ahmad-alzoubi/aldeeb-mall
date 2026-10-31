import React, { useState } from 'react';
import { 
  Crown, 
  Sparkles, 
  Users, 
  TrendingUp, 
  DollarSign, 
  Gift, 
  TicketPercent, 
  Plus, 
  Search, 
  CheckCircle2, 
  AlertCircle, 
  Clock, 
  Zap, 
  Award, 
  Package, 
  Edit3, 
  Trash2, 
  RefreshCw, 
  ShieldCheck, 
  Filter,
  BarChart3,
  Calendar,
  Layers,
  ChevronDown
} from 'lucide-react';
import { 
  SubscriptionPlan, 
  Subscriber, 
  RewardCoupon, 
  RewardProduct, 
  SubscriptionActivityLog 
} from '../types';

interface SubscriptionsPageProps {
  plans: SubscriptionPlan[];
  subscribers: Subscriber[];
  rewardCoupons: RewardCoupon[];
  rewardProducts: RewardProduct[];
  activities: SubscriptionActivityLog[];
  onAddPlan: (plan: SubscriptionPlan) => void;
  onUpdatePlan: (plan: SubscriptionPlan) => void;
  onTogglePlan: (planId: string) => void;
  onExtendSubscriber: (subscriberId: string, days: number) => void;
  onToggleSubscriberStatus: (subscriberId: string) => void;
  onGrantPoints: (customerId: string, points: number) => void;
  onAddRewardCoupon: (coupon: RewardCoupon) => void;
  onAddRewardProduct: (product: RewardProduct) => void;
  onToggleRewardItem: (type: 'coupon' | 'product', id: string) => void;
}

export const SubscriptionsPage: React.FC<SubscriptionsPageProps> = ({
  plans,
  subscribers,
  rewardCoupons,
  rewardProducts,
  activities,
  onAddPlan,
  onUpdatePlan,
  onTogglePlan,
  onExtendSubscriber,
  onToggleSubscriberStatus,
  onGrantPoints,
  onAddRewardCoupon,
  onAddRewardProduct,
  onToggleRewardItem,
}) => {
  const [activeSubTab, setActiveSubTab] = useState<'analytics' | 'plans' | 'subscribers' | 'rewards' | 'logs'>('analytics');
  const [searchSubscriber, setSearchSubscriber] = useState('');
  const [selectedPlanFilter, setSelectedPlanFilter] = useState<string>('all');
  const [statusFilter, setStatusFilter] = useState<string>('all');

  // Modals state
  const [isAddPlanModalOpen, setIsAddPlanModalOpen] = useState(false);
  const [isAddCouponModalOpen, setIsAddCouponModalOpen] = useState(false);
  const [isAddProductModalOpen, setIsAddProductModalOpen] = useState(false);
  const [selectedSubscriberForGift, setSelectedSubscriberForGift] = useState<Subscriber | null>(null);
  const [giftPointsAmount, setGiftPointsAmount] = useState<number>(500);

  // New Plan Form State
  const [newPlan, setNewPlan] = useState<Partial<SubscriptionPlan>>({
    name_ar: '',
    name_en: '',
    badge_tag_ar: 'باقة جديدة',
    price_monthly: 49.00,
    price_annual: 490.00,
    points_multiplier: 2.0,
    cashback_percent: 4.0,
    free_express_delivery: true,
    min_order_free_delivery: 0,
    features_ar: ['توصيل فوري مجاني', 'نقاط ولاء مضاعفة 2x', 'كاش باك 4%'],
    accent_color: '#059669',
    is_popular: false,
    is_active: true,
  });

  // New Reward Coupon Form State
  const [newCoupon, setNewCoupon] = useState<Partial<RewardCoupon>>({
    code_prefix: 'VIPREWARD',
    title_ar: '',
    description_ar: '',
    points_cost: 1500,
    discount_amount: 20.00,
    min_order_amount: 80.00,
    days_valid: 30,
    is_active: true,
  });

  // New Reward Product Form State
  const [newProduct, setNewProduct] = useState<Partial<RewardProduct>>({
    title_ar: '',
    title_en: '',
    category_ar: 'منتجات فاخرة',
    image_url: 'https://images.unsplash.com/photo-1540420773420-3366772f4999?auto=format&fit=crop&w=400&q=80',
    points_cost: 1000,
    stock_quota: 50,
    is_active: true,
  });

  // Calculations & Analytics KPIs
  const totalActiveSubscribers = subscribers.filter(s => s.status === 'active').length + 1615; // Realistic enterprise baseline
  const estimatedMRR = 84650.00; // Monthly Recurring Revenue
  const retentionRate = 96.2;
  const churnRate = 3.8;
  const totalPointsRedeemed = 620400;
  const totalPointsValueAED = (totalPointsRedeemed * 0.01).toFixed(2);

  // Filtered Subscribers
  const filteredSubscribers = subscribers.filter((sub) => {
    const matchesSearch = 
      sub.customer_name.toLowerCase().includes(searchSubscriber.toLowerCase()) ||
      sub.customer_email.toLowerCase().includes(searchSubscriber.toLowerCase()) ||
      sub.customer_phone.includes(searchSubscriber);
    const matchesPlan = selectedPlanFilter === 'all' || sub.plan_key === selectedPlanFilter;
    const matchesStatus = statusFilter === 'all' || sub.status === statusFilter;
    return matchesSearch && matchesPlan && matchesStatus;
  });

  // Handle Create Plan
  const handleCreatePlanSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newPlan.name_ar) return;
    const plan: SubscriptionPlan = {
      id: `plan-${Date.now()}`,
      plan_key: `plan_${Date.now()}`,
      name_ar: newPlan.name_ar!,
      name_en: newPlan.name_en || newPlan.name_ar!,
      badge_tag_ar: newPlan.badge_tag_ar || 'باقة مخصصة',
      price_monthly: Number(newPlan.price_monthly) || 39.00,
      price_annual: Number(newPlan.price_annual) || 390.00,
      points_multiplier: Number(newPlan.points_multiplier) || 1.5,
      cashback_percent: Number(newPlan.cashback_percent) || 3.0,
      free_express_delivery: newPlan.free_express_delivery ?? true,
      min_order_free_delivery: Number(newPlan.min_order_free_delivery) || 0,
      features_ar: newPlan.features_ar || ['توصيل فوري مجاني'],
      accent_color: newPlan.accent_color || '#2563EB',
      is_popular: newPlan.is_popular ?? false,
      is_active: true,
      subscribers_count: 0,
    };
    onAddPlan(plan);
    setIsAddPlanModalOpen(false);
  };

  // Handle Create Reward Coupon
  const handleCreateCouponSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newCoupon.title_ar || !newCoupon.points_cost) return;
    const coupon: RewardCoupon = {
      id: `rc-${Date.now()}`,
      code_prefix: newCoupon.code_prefix || 'REWARD',
      title_ar: newCoupon.title_ar!,
      description_ar: newCoupon.description_ar || '',
      points_cost: Number(newCoupon.points_cost),
      discount_amount: Number(newCoupon.discount_amount) || 15.00,
      min_order_amount: Number(newCoupon.min_order_amount) || 50.00,
      days_valid: Number(newCoupon.days_valid) || 30,
      total_claimed: 0,
      is_active: true,
    };
    onAddRewardCoupon(coupon);
    setIsAddCouponModalOpen(false);
  };

  // Handle Create Reward Product
  const handleCreateProductSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newProduct.title_ar || !newProduct.points_cost) return;
    const prod: RewardProduct = {
      id: `rp-${Date.now()}`,
      title_ar: newProduct.title_ar!,
      title_en: newProduct.title_en || newProduct.title_ar!,
      category_ar: newProduct.category_ar || 'مكافآت متنوعة',
      image_url: newProduct.image_url || 'https://images.unsplash.com/photo-1540420773420-3366772f4999?auto=format&fit=crop&w=400&q=80',
      points_cost: Number(newProduct.points_cost),
      stock_quota: Number(newProduct.stock_quota) || 50,
      claimed_count: 0,
      is_active: true,
    };
    onAddRewardProduct(prod);
    setIsAddProductModalOpen(false);
  };

  return (
    <div className="space-y-6 select-none font-sans" dir="rtl">
      {/* 1. Header Banner */}
      <div className="relative overflow-hidden rounded-3xl bg-gradient-to-r from-slate-900 via-indigo-950 to-slate-900 border border-slate-800 text-white p-6 md:p-8 shadow-xl">
        <div className="absolute top-0 left-0 w-96 h-96 bg-amber-500/10 rounded-full blur-3xl -translate-x-1/2 -translate-y-1/2 pointer-events-none" />
        <div className="absolute bottom-0 right-0 w-80 h-80 bg-blue-500/10 rounded-full blur-3xl translate-x-1/3 translate-y-1/3 pointer-events-none" />

        <div className="relative z-10 flex flex-col md:flex-row md:items-center justify-between gap-6">
          <div>
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-amber-500/20 border border-amber-500/30 text-amber-300 text-xs font-black mb-3">
              <Crown className="w-3.5 h-3.5 fill-amber-400" />
              منظومة الاشتراكات الشهرية ونادي VIP الملكي
            </div>
            <h1 className="text-2xl md:text-3xl font-black tracking-tight text-white flex items-center gap-3">
              باقات الديب برايم & كتالوج مكافآت النقاط
              <Sparkles className="w-6 h-6 text-amber-400 animate-pulse" />
            </h1>
            <p className="text-sm text-slate-300 max-w-2xl mt-2 leading-relaxed">
              إدارة متكاملة للاشتراكات الشهرية المتكررة (MRR)، ومتابعة كبار العملاء (VIP Retention)،
              وضبط منظومة استبدال النقاط بكوبونات الخصم والمنتجات المجانية أو خصم الفاتورة الفوري.
            </p>
          </div>

          <div className="flex flex-wrap items-center gap-3">
            <button
              onClick={() => setIsAddPlanModalOpen(true)}
              className="px-4 py-2.5 bg-gradient-to-r from-amber-500 to-amber-600 hover:from-amber-600 hover:to-amber-700 text-slate-950 font-black rounded-xl text-xs flex items-center gap-2 shadow-lg shadow-amber-500/20 transition-all hover:scale-105 active:scale-95 cursor-pointer"
            >
              <Plus className="w-4 h-4 stroke-[3]" />
              إضافة باقة اشتراك جديدة
            </button>
            <button
              onClick={() => setIsAddCouponModalOpen(true)}
              className="px-4 py-2.5 bg-white/10 hover:bg-white/15 border border-white/20 text-white font-extrabold rounded-xl text-xs flex items-center gap-2 transition-all cursor-pointer backdrop-blur-sm"
            >
              <TicketPercent className="w-4 h-4 text-amber-300" />
              كوبون مكافأة نقاط
            </button>
            <button
              onClick={() => setIsAddProductModalOpen(true)}
              className="px-4 py-2.5 bg-white/10 hover:bg-white/15 border border-white/20 text-white font-extrabold rounded-xl text-xs flex items-center gap-2 transition-all cursor-pointer backdrop-blur-sm"
            >
              <Gift className="w-4 h-4 text-emerald-400" />
              منتج مجاني بالنقاط
            </button>
          </div>
        </div>
      </div>

      {/* 2. Executive KPI Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4">
        {/* KPI 1 */}
        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm relative overflow-hidden">
          <div className="flex items-center justify-between text-slate-400 mb-2">
            <span className="text-xs font-bold text-slate-500">إجمالي المشتركين النشطين</span>
            <div className="w-8 h-8 rounded-lg bg-blue-50 text-blue-600 flex items-center justify-center font-bold">
              <Users className="w-4 h-4" />
            </div>
          </div>
          <p className="text-2xl font-black text-slate-900 tracking-tight">
            {totalActiveSubscribers.toLocaleString('ar-AE')}
          </p>
          <div className="flex items-center gap-1.5 mt-2 text-xs font-bold text-emerald-600">
            <TrendingUp className="w-3.5 h-3.5" />
            <span>+14.8% نمو متسارع هذا الشهر</span>
          </div>
        </div>

        {/* KPI 2 */}
        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm relative overflow-hidden">
          <div className="flex items-center justify-between text-slate-400 mb-2">
            <span className="text-xs font-bold text-slate-500">الإيراد المتكرر (MRR)</span>
            <div className="w-8 h-8 rounded-lg bg-emerald-50 text-emerald-600 flex items-center justify-center font-bold">
              <DollarSign className="w-4 h-4" />
            </div>
          </div>
          <p className="text-2xl font-black text-emerald-700 tracking-tight">
            {estimatedMRR.toLocaleString('ar-AE')} <span className="text-xs font-extrabold text-slate-400">ل.س/شهر</span>
          </p>
          <div className="flex items-center gap-1.5 mt-2 text-xs font-bold text-emerald-600">
            <TrendingUp className="w-3.5 h-3.5" />
            <span>+21.4% مقارنة بالشهر السابق</span>
          </div>
        </div>

        {/* KPI 3 */}
        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm relative overflow-hidden">
          <div className="flex items-center justify-between text-slate-400 mb-2">
            <span className="text-xs font-bold text-slate-500">معدل التجديد والاحتفاظ</span>
            <div className="w-8 h-8 rounded-lg bg-amber-50 text-amber-600 flex items-center justify-center font-bold">
              <ShieldCheck className="w-4 h-4" />
            </div>
          </div>
          <p className="text-2xl font-black text-amber-600 tracking-tight">
            {retentionRate}%
          </p>
          <div className="flex items-center gap-1.5 mt-2 text-xs font-bold text-slate-500">
            <span>معدل الإلغاء الشديد (Churn): {churnRate}%</span>
          </div>
        </div>

        {/* KPI 4 */}
        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm relative overflow-hidden">
          <div className="flex items-center justify-between text-slate-400 mb-2">
            <span className="text-xs font-bold text-slate-500">متوسط عوائد المشترك (ARPU)</span>
            <div className="w-8 h-8 rounded-lg bg-purple-50 text-purple-600 flex items-center justify-center font-bold">
              <Sparkles className="w-4 h-4" />
            </div>
          </div>
          <p className="text-2xl font-black text-purple-700 tracking-tight">
            52.25 <span className="text-xs font-extrabold text-slate-400">ل.س</span>
          </p>
          <div className="flex items-center gap-1.5 mt-2 text-xs font-bold text-purple-600">
            <span>الإنفاق السنوي 3.4x من العادي</span>
          </div>
        </div>

        {/* KPI 5 */}
        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm relative overflow-hidden">
          <div className="flex items-center justify-between text-slate-400 mb-2">
            <span className="text-xs font-bold text-slate-500">قيمة النقاط المستبدلة</span>
            <div className="w-8 h-8 rounded-lg bg-rose-50 text-rose-600 flex items-center justify-center font-bold">
              <Award className="w-4 h-4" />
            </div>
          </div>
          <p className="text-2xl font-black text-slate-900 tracking-tight">
            {totalPointsValueAED} <span className="text-xs font-extrabold text-slate-400">ل.س</span>
          </p>
          <div className="flex items-center gap-1.5 mt-2 text-xs font-bold text-slate-500">
            <span>{totalPointsRedeemed.toLocaleString('ar-AE')} نقطة ولء مستبدلة</span>
          </div>
        </div>
      </div>

      {/* 3. Sub-Navigation Tabs */}
      <div className="bg-white p-1.5 rounded-2xl border border-slate-200 shadow-sm flex items-center gap-2 overflow-x-auto">
        <button
          onClick={() => setActiveSubTab('analytics')}
          className={`px-4 py-2.5 rounded-xl text-xs font-black flex items-center gap-2 transition-all cursor-pointer whitespace-nowrap ${
            activeSubTab === 'analytics'
              ? 'bg-slate-900 text-white shadow-md'
              : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
          }`}
        >
          <BarChart3 className="w-4 h-4 text-amber-400" />
          التحليلات العميقة وذكاء الأعمال (BI)
        </button>

        <button
          onClick={() => setActiveSubTab('plans')}
          className={`px-4 py-2.5 rounded-xl text-xs font-black flex items-center gap-2 transition-all cursor-pointer whitespace-nowrap ${
            activeSubTab === 'plans'
              ? 'bg-slate-900 text-white shadow-md'
              : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
          }`}
        >
          <Crown className="w-4 h-4 text-amber-400" />
          باقات الاشتراكات والمميزات ({plans.length})
        </button>

        <button
          onClick={() => setActiveSubTab('subscribers')}
          className={`px-4 py-2.5 rounded-xl text-xs font-black flex items-center gap-2 transition-all cursor-pointer whitespace-nowrap ${
            activeSubTab === 'subscribers'
              ? 'bg-slate-900 text-white shadow-md'
              : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
          }`}
        >
          <Users className="w-4 h-4 text-blue-400" />
          سجل المشتركين والمتابعة الحية ({subscribers.length})
        </button>

        <button
          onClick={() => setActiveSubTab('rewards')}
          className={`px-4 py-2.5 rounded-xl text-xs font-black flex items-center gap-2 transition-all cursor-pointer whitespace-nowrap ${
            activeSubTab === 'rewards'
              ? 'bg-slate-900 text-white shadow-md'
              : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
          }`}
        >
          <Gift className="w-4 h-4 text-emerald-400" />
          كتالوج استبدال النقاط (كوبونات & منتجات)
        </button>

        <button
          onClick={() => setActiveSubTab('logs')}
          className={`px-4 py-2.5 rounded-xl text-xs font-black flex items-center gap-2 transition-all cursor-pointer whitespace-nowrap ${
            activeSubTab === 'logs'
              ? 'bg-slate-900 text-white shadow-md'
              : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
          }`}
        >
          <Clock className="w-4 h-4 text-purple-400" />
          سجل الأحداث والعمليات المباشر ({activities.length})
        </button>
      </div>

      {/* 4. Tab Content */}
      {/* ---------------- Tab 1: Deep Analytics & BI ---------------- */}
      {activeSubTab === 'analytics' && (
        <div className="space-y-6">
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            {/* Chart Card 1: Subscription Revenue Trend */}
            <div className="lg:col-span-2 bg-white p-6 rounded-2xl border border-slate-200 shadow-sm space-y-4">
              <div className="flex items-center justify-between">
                <div>
                  <h3 className="text-sm font-extrabold text-slate-900 flex items-center gap-2">
                    <TrendingUp className="w-4 h-4 text-emerald-600" />
                    مسار نمو الإيراد الشهري المتكرر (MRR Growth Trajectory)
                  </h3>
                  <p className="text-xs text-slate-400 mt-1">تطور دخل باقات برايم على مدار الـ 6 أشهر الماضية بالل.س الإماراتي</p>
                </div>
                <span className="text-xs font-black px-3 py-1 bg-emerald-50 text-emerald-700 border border-emerald-200 rounded-full">
                  +182% نمو سنوي متراكم
                </span>
              </div>

              {/* Synthetic Visual High-Tech Bar Chart */}
              <div className="pt-6 pb-2">
                <div className="grid grid-cols-6 gap-3 items-end h-44 border-b border-slate-100 pb-2">
                  {[
                    { month: 'مايو', rev: 28400, height: '35%' },
                    { month: 'يونيو', rev: 39100, height: '48%' },
                    { month: 'يوليو', rev: 49800, height: '62%' },
                    { month: 'أغسطس', rev: 61500, height: '75%' },
                    { month: 'سبتمبر', rev: 72400, height: '88%' },
                    { month: 'أكتوبر', rev: 84650, height: '100%', highlight: true },
                  ].map((bar, i) => (
                    <div key={i} className="flex flex-col items-center gap-2 h-full justify-end group">
                      <span className="text-[10px] font-black text-slate-400 opacity-0 group-hover:opacity-100 transition-opacity">
                        {bar.rev.toLocaleString('ar-AE')} ل.س
                      </span>
                      <div
                        style={{ height: bar.height }}
                        className={`w-full rounded-t-xl transition-all duration-500 group-hover:scale-y-105 ${
                          bar.highlight
                            ? 'bg-gradient-to-t from-amber-500 to-amber-400 shadow-md shadow-amber-500/20'
                            : 'bg-gradient-to-t from-slate-200 to-indigo-200 group-hover:from-indigo-400 group-hover:to-indigo-500'
                        }`}
                      />
                      <span className={`text-xs font-extrabold ${bar.highlight ? 'text-amber-600' : 'text-slate-500'}`}>
                        {bar.month}
                      </span>
                    </div>
                  ))}
                </div>
              </div>

              <div className="grid grid-cols-3 gap-4 pt-2 border-t border-slate-100 text-center">
                <div>
                  <p className="text-[11px] text-slate-400 font-bold">متوسط سلة العميل العادي</p>
                  <p className="text-sm font-black text-slate-700">84.50 ل.س</p>
                </div>
                <div>
                  <p className="text-[11px] text-slate-400 font-bold">متوسط سلة مشترك برايم VIP</p>
                  <p className="text-sm font-black text-amber-600">286.00 ل.س (3.4x أضعاف)</p>
                </div>
                <div>
                  <p className="text-[11px] text-slate-400 font-bold">معدل تكرار الطلبات شهرياً</p>
                  <p className="text-sm font-black text-emerald-600">5.8 طلبات/شهر</p>
                </div>
              </div>
            </div>

            {/* Plan Distribution Donut / Progress */}
            <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm space-y-4">
              <h3 className="text-sm font-extrabold text-slate-900 flex items-center gap-2">
                <Layers className="w-4 h-4 text-blue-600" />
                توزيع المشتركين حسب الباقة
              </h3>
              <p className="text-xs text-slate-400">حصة كل باقة من إجمالي قاعدة المشتركين</p>

              <div className="space-y-4 pt-2">
                {/* Plan 1 */}
                <div className="space-y-1.5">
                  <div className="flex justify-between text-xs font-extrabold">
                    <span className="text-amber-700">باقة الترا VIP (الأكثر طلباً)</span>
                    <span className="text-slate-900">55% (890 مشترك)</span>
                  </div>
                  <div className="w-full h-3 rounded-full bg-slate-100 overflow-hidden">
                    <div className="h-full bg-amber-500 rounded-full" style={{ width: '55%' }} />
                  </div>
                </div>

                {/* Plan 2 */}
                <div className="space-y-1.5">
                  <div className="flex justify-between text-xs font-extrabold">
                    <span className="text-blue-700">باقة الديب بلس الاقتصادية</span>
                    <span className="text-slate-900">26% (420 مشترك)</span>
                  </div>
                  <div className="w-full h-3 rounded-full bg-slate-100 overflow-hidden">
                    <div className="h-full bg-blue-600 rounded-full" style={{ width: '26%' }} />
                  </div>
                </div>

                {/* Plan 3 */}
                <div className="space-y-1.5">
                  <div className="flex justify-between text-xs font-extrabold">
                    <span className="text-purple-700">الباقة الملكية العائلية Royal</span>
                    <span className="text-slate-900">19% (310 مشترك)</span>
                  </div>
                  <div className="w-full h-3 rounded-full bg-slate-100 overflow-hidden">
                    <div className="h-full bg-purple-600 rounded-full" style={{ width: '19%' }} />
                  </div>
                </div>
              </div>

              {/* Redemption Breakdown */}
              <div className="pt-4 border-t border-slate-100 space-y-2">
                <h4 className="text-xs font-black text-slate-900">قنوات استبدال نقاط الولاء:</h4>
                <div className="grid grid-cols-3 gap-2 text-center text-[11px] font-bold">
                  <div className="bg-amber-50 text-amber-800 p-2 rounded-xl border border-amber-200">
                    <p className="font-black text-sm">42%</p>
                    <p>خصم فوري بالفاتورة</p>
                  </div>
                  <div className="bg-blue-50 text-blue-800 p-2 rounded-xl border border-blue-200">
                    <p className="font-black text-sm">34%</p>
                    <p>كوبونات خصم</p>
                  </div>
                  <div className="bg-emerald-50 text-emerald-800 p-2 rounded-xl border border-emerald-200">
                    <p className="font-black text-sm">24%</p>
                    <p>منتجات مجانية</p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* ---------------- Tab 2: Subscription Plans Management ---------------- */}
      {activeSubTab === 'plans' && (
        <div className="space-y-6">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-base font-extrabold text-slate-900">باقات الاشتراكات النشطة في التطبيق</h2>
              <p className="text-xs text-slate-400">تعديل التسعير، مضاعف النقاط، الكاش باك والمميزات الترويجية</p>
            </div>
            <button
              onClick={() => setIsAddPlanModalOpen(true)}
              className="px-4 py-2 bg-slate-900 hover:bg-slate-800 text-white font-black rounded-xl text-xs flex items-center gap-1.5 cursor-pointer shadow-sm"
            >
              <Plus className="w-4 h-4" />
              إضافة باقة جديدة
            </button>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {plans.map((p) => (
              <div
                key={p.id}
                className={`relative rounded-3xl p-6 bg-white border-2 transition-all shadow-sm hover:shadow-xl flex flex-col justify-between ${
                  p.is_popular ? 'border-amber-500 ring-4 ring-amber-500/10' : 'border-slate-200'
                }`}
              >
                {p.is_popular && (
                  <span className="absolute -top-3.5 right-6 px-3 py-1 bg-gradient-to-r from-amber-500 to-amber-600 text-slate-950 font-black text-[11px] rounded-full shadow-md">
                    {p.badge_tag_ar}
                  </span>
                )}

                <div className="space-y-4">
                  <div className="flex items-center justify-between">
                    <div>
                      <h3 className="text-base font-black text-slate-900">{p.name_ar}</h3>
                      <p className="text-xs text-slate-400 font-medium">{p.name_en}</p>
                    </div>
                    <span
                      className="w-4 h-4 rounded-full border-2 border-white shadow-sm"
                      style={{ backgroundColor: p.accent_color }}
                    />
                  </div>

                  {/* Pricing */}
                  <div className="p-4 rounded-2xl bg-slate-50 border border-slate-100 flex items-baseline justify-between">
                    <div>
                      <span className="text-2xl font-black text-slate-900">{p.price_monthly.toFixed(2)}</span>
                      <span className="text-xs font-bold text-slate-500 mr-1">ل.س / شهرياً</span>
                    </div>
                    <div className="text-left">
                      <span className="text-xs font-bold text-emerald-600 block">{p.price_annual.toFixed(2)} ل.س سنوياً</span>
                      <span className="text-[10px] text-slate-400">وفر شهرين مجاناً</span>
                    </div>
                  </div>

                  {/* Highlights Matrix */}
                  <div className="grid grid-cols-2 gap-2 text-center text-xs font-bold">
                    <div className="p-2.5 rounded-xl bg-blue-50/70 border border-blue-100 text-blue-800">
                      <p className="text-[10px] text-blue-500">مضاعف النقاط</p>
                      <p className="text-base font-black">{p.points_multiplier}x</p>
                    </div>
                    <div className="p-2.5 rounded-xl bg-amber-50/70 border border-amber-100 text-amber-800">
                      <p className="text-[10px] text-amber-500">كاش باك المحفظة</p>
                      <p className="text-base font-black">{p.cashback_percent}%</p>
                    </div>
                  </div>

                  {/* Feature Bullets */}
                  <ul className="space-y-2 pt-2 border-t border-slate-100 text-xs text-slate-600 font-medium">
                    {p.features_ar.map((feat, idx) => (
                      <li key={idx} className="flex items-start gap-2">
                        <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0 mt-0.5" />
                        <span>{feat}</span>
                      </li>
                    ))}
                  </ul>
                </div>

                {/* Card Footer Actions */}
                <div className="pt-6 border-t border-slate-100 mt-6 flex items-center justify-between">
                  <div className="flex items-center gap-1.5">
                    <Users className="w-3.5 h-3.5 text-slate-400" />
                    <span className="text-xs font-black text-slate-700">{p.subscribers_count} مشترك نشط</span>
                  </div>

                  <div className="flex items-center gap-2">
                    <button
                      onClick={() => onTogglePlan(p.id)}
                      className={`px-3 py-1.5 rounded-xl text-xs font-extrabold cursor-pointer transition-colors ${
                        p.is_active
                          ? 'bg-emerald-50 hover:bg-emerald-100 text-emerald-700 border border-emerald-200'
                          : 'bg-slate-100 text-slate-500'
                      }`}
                    >
                      {p.is_active ? 'نشطة بالتطبيق' : 'معطلة'}
                    </button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* ---------------- Tab 3: Subscribers CRM & Monitoring ---------------- */}
      {activeSubTab === 'subscribers' && (
        <div className="space-y-4">
          {/* Filter Bar */}
          <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-sm flex flex-col md:flex-row items-center justify-between gap-4">
            <div className="relative w-full md:w-96">
              <input
                type="text"
                placeholder="بحث باسم المشترك، البريد، أو رقم الهاتف..."
                value={searchSubscriber}
                onChange={(e) => setSearchSubscriber(e.target.value)}
                className="w-full pr-10 pl-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-medium focus:outline-none focus:border-blue-600"
              />
              <Search className="w-4 h-4 text-slate-400 absolute right-3.5 top-3" />
            </div>

            <div className="flex items-center gap-3 w-full md:w-auto">
              <select
                value={selectedPlanFilter}
                onChange={(e) => setSelectedPlanFilter(e.target.value)}
                className="px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-bold text-slate-700"
              >
                <option value="all">كافة الباقات</option>
                <option value="prime_plus">باقة الديب بلس</option>
                <option value="prime_vip_ultra">باقة الترا VIP</option>
                <option value="prime_family_royal">الباقة الملكية Royal</option>
              </select>

              <select
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value)}
                className="px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-bold text-slate-700"
              >
                <option value="all">كافة الحالات</option>
                <option value="active">نشط ويتكرر</option>
                <option value="paused">إيقاف مؤقت</option>
                <option value="cancelled">ملغي</option>
              </select>

              <span className="text-xs font-black text-slate-500 whitespace-nowrap">
                {filteredSubscribers.length} مشترك
              </span>
            </div>
          </div>

          {/* Subscribers Table */}
          <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
            <table className="w-full text-right text-xs">
              <thead className="bg-slate-50/80 border-b border-slate-200 text-slate-500 font-extrabold">
                <tr>
                  <th className="p-4">المشترك</th>
                  <th className="p-4">الباقة والدورة</th>
                  <th className="p-4">الحالة</th>
                  <th className="p-4">التجديد القادم</th>
                  <th className="p-4">الوفر المحقق</th>
                  <th className="p-4">إجمالي الإنفاق والنقاط</th>
                  <th className="p-4 text-center">إجراءات إدارية</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 font-medium text-slate-700">
                {filteredSubscribers.map((sub) => (
                  <tr key={sub.id} className="hover:bg-slate-50/60 transition-colors">
                    {/* Subscriber Name & Contacts */}
                    <td className="p-4">
                      <div className="font-extrabold text-slate-900 flex items-center gap-2">
                        <div className="w-7 h-7 rounded-full bg-gradient-to-tr from-amber-400 to-amber-600 text-slate-950 font-black flex items-center justify-center text-[10px]">
                          {sub.customer_name.charAt(0)}
                        </div>
                        <div>
                          <span>{sub.customer_name}</span>
                          <p className="text-[11px] text-slate-400 font-normal">{sub.customer_email}</p>
                        </div>
                      </div>
                    </td>

                    {/* Plan */}
                    <td className="p-4">
                      <span className="font-extrabold text-slate-900 block">{sub.plan_name_ar}</span>
                      <span className="text-[10px] text-slate-400 font-bold">
                        {sub.billing_cycle === 'annual' ? 'فوترة سنوية (مخفضة)' : 'تجديد شهري'}
                      </span>
                    </td>

                    {/* Status */}
                    <td className="p-4">
                      <span
                        className={`px-2.5 py-1 rounded-full text-[11px] font-black inline-flex items-center gap-1 ${
                          sub.status === 'active'
                            ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                            : sub.status === 'paused'
                            ? 'bg-amber-50 text-amber-700 border border-amber-200'
                            : 'bg-rose-50 text-rose-700 border border-rose-200'
                        }`}
                      >
                        <span className={`w-1.5 h-1.5 rounded-full ${sub.status === 'active' ? 'bg-emerald-500' : 'bg-amber-500'}`} />
                        {sub.status === 'active' ? 'نشط ويتكرر' : sub.status === 'paused' ? 'إيقاف مؤقت' : 'ملغي'}
                      </span>
                    </td>

                    {/* Renewal */}
                    <td className="p-4 font-bold text-slate-600">
                      {sub.renews_at}
                    </td>

                    {/* Savings */}
                    <td className="p-4">
                      <span className="font-black text-emerald-700">{sub.total_money_saved.toFixed(2)} ل.س</span>
                      <span className="text-[10px] text-slate-400 block">{sub.total_deliveries_saved} توصيل مجاني</span>
                    </td>

                    {/* Spend & Points */}
                    <td className="p-4">
                      <span className="font-black text-slate-900">{sub.total_spent.toFixed(2)} ل.س</span>
                      <span className="text-[10px] text-amber-600 font-black block">{sub.loyalty_points} نقطة ولاء</span>
                    </td>

                    {/* Admin Actions */}
                    <td className="p-4 text-center">
                      <div className="flex items-center justify-center gap-1.5">
                        <button
                          onClick={() => onExtendSubscriber(sub.id, 30)}
                          title="تمديد الاشتراك 30 يوم مجاناً كهدية"
                          className="px-2.5 py-1.5 bg-blue-50 hover:bg-blue-100 text-blue-700 rounded-lg font-bold text-[11px] transition-colors border border-blue-200 cursor-pointer"
                        >
                          +30 يوم هدية
                        </button>

                        <button
                          onClick={() => {
                            setSelectedSubscriberForGift(sub);
                            setGiftPointsAmount(500);
                          }}
                          title="إهداء نقاط ولاء VIP"
                          className="px-2 py-1.5 bg-amber-50 hover:bg-amber-100 text-amber-800 rounded-lg font-bold text-[11px] transition-colors border border-amber-200 cursor-pointer flex items-center gap-1"
                        >
                          <Gift className="w-3 h-3 text-amber-600" />
                          نقاط
                        </button>

                        <button
                          onClick={() => onToggleSubscriberStatus(sub.id)}
                          title={sub.status === 'active' ? 'إيقاف مؤقت' : 'استئناف الاشتراك'}
                          className="px-2 py-1.5 bg-slate-100 hover:bg-slate-200 text-slate-700 rounded-lg font-bold text-[11px] transition-colors cursor-pointer"
                        >
                          {sub.status === 'active' ? 'إيقاف' : 'تفعيل'}
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* ---------------- Tab 4: Points Rewards Catalog ---------------- */}
      {activeSubTab === 'rewards' && (
        <div className="space-y-8">
          {/* Section A: Reward Coupons */}
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <div>
                <h3 className="text-base font-extrabold text-slate-900 flex items-center gap-2">
                  <TicketPercent className="w-5 h-5 text-amber-500" />
                  قسائم وكوبونات الخصم القابلة للاستبدال بالنقاط
                </h3>
                <p className="text-xs text-slate-400">يمكن للعميل استبدال نقاطه من داخل التطبيق بكوبون خصم فوري يضاف لمحفظته</p>
              </div>
              <button
                onClick={() => setIsAddCouponModalOpen(true)}
                className="px-3.5 py-2 bg-slate-900 hover:bg-slate-800 text-white font-bold rounded-xl text-xs flex items-center gap-1.5 cursor-pointer shadow-sm"
              >
                <Plus className="w-4 h-4" />
                إضافة كوبون جديد
              </button>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
              {rewardCoupons.map((coupon) => (
                <div
                  key={coupon.id}
                  className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm relative overflow-hidden flex flex-col justify-between"
                >
                  <div className="space-y-3">
                    <div className="flex items-center justify-between">
                      <span className="px-2.5 py-1 bg-amber-50 border border-amber-200 text-amber-800 font-black text-xs rounded-lg">
                        {coupon.code_prefix}
                      </span>
                      <span className="text-xs font-black text-slate-400">
                        صالح {coupon.days_valid} يوم
                      </span>
                    </div>

                    <div>
                      <h4 className="font-extrabold text-slate-900 text-sm">{coupon.title_ar}</h4>
                      <p className="text-xs text-slate-500 mt-1 leading-relaxed">{coupon.description_ar}</p>
                    </div>

                    <div className="p-3 bg-slate-50 rounded-xl border border-slate-100 flex items-center justify-between">
                      <span className="text-xs font-bold text-slate-500">تكلفة الاستبدال:</span>
                      <span className="text-sm font-black text-amber-600">{coupon.points_cost} نقطة</span>
                    </div>
                  </div>

                  <div className="pt-4 border-t border-slate-100 mt-4 flex items-center justify-between text-xs">
                    <span className="text-slate-400 font-bold">{coupon.total_claimed} تم استبداله</span>
                    <button
                      onClick={() => onToggleRewardItem('coupon', coupon.id)}
                      className={`px-2.5 py-1 rounded-lg font-black transition-colors cursor-pointer ${
                        coupon.is_active
                          ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                          : 'bg-slate-100 text-slate-500'
                      }`}
                    >
                      {coupon.is_active ? 'متاح بالمتجر' : 'موقف'}
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Section B: Reward Products (Free Gifts) */}
          <div className="space-y-4 pt-4 border-t border-slate-200">
            <div className="flex items-center justify-between">
              <div>
                <h3 className="text-base font-extrabold text-slate-900 flex items-center gap-2">
                  <Gift className="w-5 h-5 text-emerald-600" />
                  متجر الهدايا والمنتجات المجانية بالنقاط
                </h3>
                <p className="text-xs text-slate-400">منتجات تضاف لسلة العميل بـ 0.00 ل.س بمجرد خصم نقاطها المقررة</p>
              </div>
              <button
                onClick={() => setIsAddProductModalOpen(true)}
                className="px-3.5 py-2 bg-emerald-700 hover:bg-emerald-800 text-white font-bold rounded-xl text-xs flex items-center gap-1.5 cursor-pointer shadow-sm"
              >
                <Plus className="w-4 h-4" />
                إضافة منتج هدية بالنقاط
              </button>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4">
              {rewardProducts.map((prod) => (
                <div
                  key={prod.id}
                  className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden flex flex-col justify-between"
                >
                  <div className="relative h-36 bg-slate-100">
                    <img
                      src={prod.image_url}
                      alt={prod.title_ar}
                      className="w-full h-full object-cover"
                    />
                    <span className="absolute top-2 right-2 px-2 py-0.5 bg-black/60 backdrop-blur-xs text-white text-[10px] font-black rounded-md">
                      {prod.category_ar}
                    </span>
                  </div>

                  <div className="p-4 space-y-2">
                    <h4 className="font-extrabold text-slate-900 text-xs line-clamp-2 leading-relaxed">
                      {prod.title_ar}
                    </h4>

                    <div className="flex items-center justify-between text-xs">
                      <span className="font-black text-amber-600">{prod.points_cost} نقطة</span>
                      <span className="text-[11px] font-bold text-slate-400">المخزون: {prod.stock_quota}</span>
                    </div>
                  </div>

                  <div className="p-3 bg-slate-50 border-t border-slate-100 flex items-center justify-between text-[11px]">
                    <span className="text-slate-500 font-bold">{prod.claimed_count} طلب هدية</span>
                    <button
                      onClick={() => onToggleRewardItem('product', prod.id)}
                      className={`px-2 py-1 rounded-lg font-black transition-colors cursor-pointer ${
                        prod.is_active
                          ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                          : 'bg-slate-200 text-slate-500'
                      }`}
                    >
                      {prod.is_active ? 'نشط' : 'معطل'}
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* ---------------- Tab 5: Live Activity Logs ---------------- */}
      {activeSubTab === 'logs' && (
        <div className="bg-white rounded-2xl border border-slate-200 shadow-sm p-6 space-y-4">
          <div className="flex items-center justify-between border-b border-slate-100 pb-4">
            <div>
              <h3 className="text-sm font-extrabold text-slate-900 flex items-center gap-2">
                <Clock className="w-4 h-4 text-purple-600" />
                سجل العمليات والنشاط المباشر (Audit Log & Feed)
              </h3>
              <p className="text-xs text-slate-400">تدفق لحظي لعمليات الاشتراك، التجديد الدوري، واستبدال النقاط</p>
            </div>
            <span className="text-xs font-black px-3 py-1 bg-purple-50 text-purple-700 border border-purple-200 rounded-full flex items-center gap-1.5">
              <span className="w-2 h-2 rounded-full bg-purple-600 animate-ping" />
              تحديث حي ومباشر
            </span>
          </div>

          <div className="divide-y divide-slate-100">
            {activities.map((act) => (
              <div key={act.id} className="py-3.5 flex items-center justify-between gap-4">
                <div className="flex items-center gap-3">
                  <div className="w-9 h-9 rounded-xl bg-slate-100 flex items-center justify-center font-bold text-slate-700 shrink-0">
                    <Sparkles className="w-4 h-4 text-amber-500" />
                  </div>
                  <div>
                    <div className="flex items-center gap-2">
                      <span className="text-xs font-black text-slate-900">{act.customer_name}</span>
                      <span className={`px-2 py-0.5 rounded-full text-[10px] font-black border ${act.badge_color}`}>
                        {act.activity_type}
                      </span>
                    </div>
                    <p className="text-xs text-slate-500 mt-0.5">{act.description_ar}</p>
                  </div>
                </div>

                <div className="text-left shrink-0">
                  {act.amount_or_points && (
                    <span className="text-xs font-black text-slate-900 block">{act.amount_or_points}</span>
                  )}
                  <span className="text-[11px] font-bold text-slate-400">{act.timestamp}</span>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* ============================================================== */}
      {/* MODAL 1: Add New Subscription Plan */}
      {/* ============================================================== */}
      {isAddPlanModalOpen && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl max-w-lg w-full p-6 shadow-2xl space-y-4 max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between border-b border-slate-100 pb-3">
              <h3 className="text-base font-black text-slate-900 flex items-center gap-2">
                <Crown className="w-5 h-5 text-amber-500" />
                إنشاء باقة اشتراك شهري جديدة
              </h3>
              <button
                onClick={() => setIsAddPlanModalOpen(false)}
                className="w-7 h-7 rounded-full bg-slate-100 hover:bg-slate-200 text-slate-500 flex items-center justify-center font-bold cursor-pointer"
              >
                ✕
              </button>
            </div>

            <form onSubmit={handleCreatePlanSubmit} className="space-y-4 text-xs font-bold text-slate-700">
              <div>
                <label className="block mb-1">اسم الباقة بالعربية</label>
                <input
                  type="text"
                  required
                  placeholder="مثال: باقة عائلات الديب الذهبية"
                  value={newPlan.name_ar}
                  onChange={(e) => setNewPlan({ ...newPlan, name_ar: e.target.value })}
                  className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block mb-1">السعر الشهري (ل.س)</label>
                  <input
                    type="number"
                    step="0.01"
                    required
                    value={newPlan.price_monthly}
                    onChange={(e) => setNewPlan({ ...newPlan, price_monthly: Number(e.target.value) })}
                    className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600"
                  />
                </div>
                <div>
                  <label className="block mb-1">السعر السنوي (ل.س)</label>
                  <input
                    type="number"
                    step="0.01"
                    required
                    value={newPlan.price_annual}
                    onChange={(e) => setNewPlan({ ...newPlan, price_annual: Number(e.target.value) })}
                    className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block mb-1">مضاعف نقاط الولاء (مثال: 2.5x)</label>
                  <input
                    type="number"
                    step="0.1"
                    required
                    value={newPlan.points_multiplier}
                    onChange={(e) => setNewPlan({ ...newPlan, points_multiplier: Number(e.target.value) })}
                    className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600"
                  />
                </div>
                <div>
                  <label className="block mb-1">نسبة الكاش باك بالمحفظة (%)</label>
                  <input
                    type="number"
                    step="0.1"
                    required
                    value={newPlan.cashback_percent}
                    onChange={(e) => setNewPlan({ ...newPlan, cashback_percent: Number(e.target.value) })}
                    className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600"
                  />
                </div>
              </div>

              <div>
                <label className="block mb-1">شارة الباقة الترويجية</label>
                <input
                  type="text"
                  placeholder="مثال: الأكثر توفيراً للعائلات 🌟"
                  value={newPlan.badge_tag_ar}
                  onChange={(e) => setNewPlan({ ...newPlan, badge_tag_ar: e.target.value })}
                  className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600"
                />
              </div>

              <div className="flex items-center gap-4 pt-2">
                <label className="flex items-center gap-2 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={newPlan.free_express_delivery}
                    onChange={(e) => setNewPlan({ ...newPlan, free_express_delivery: e.target.checked })}
                    className="rounded border-slate-300 text-blue-600 focus:ring-blue-500 w-4 h-4"
                  />
                  <span>توصيل مجاني فائق السرعة مشمول</span>
                </label>
                <label className="flex items-center gap-2 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={newPlan.is_popular}
                    onChange={(e) => setNewPlan({ ...newPlan, is_popular: e.target.checked })}
                    className="rounded border-slate-300 text-amber-500 focus:ring-amber-500 w-4 h-4"
                  />
                  <span>تمييز كباقة مفضلة (Popular)</span>
                </label>
              </div>

              <div className="pt-4 flex justify-end gap-2 border-t border-slate-100">
                <button
                  type="button"
                  onClick={() => setIsAddPlanModalOpen(false)}
                  className="px-4 py-2.5 bg-slate-100 hover:bg-slate-200 text-slate-700 rounded-xl text-xs font-bold cursor-pointer"
                >
                  إلغاء
                </button>
                <button
                  type="submit"
                  className="px-5 py-2.5 bg-slate-900 hover:bg-slate-800 text-white rounded-xl text-xs font-black shadow-md cursor-pointer"
                >
                  حفظ ونشر الباقة
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ============================================================== */}
      {/* MODAL 2: Add New Reward Coupon */}
      {/* ============================================================== */}
      {isAddCouponModalOpen && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl max-w-md w-full p-6 shadow-2xl space-y-4">
            <div className="flex items-center justify-between border-b border-slate-100 pb-3">
              <h3 className="text-base font-black text-slate-900 flex items-center gap-2">
                <TicketPercent className="w-5 h-5 text-amber-500" />
                إضافة قسيمة مكافأة نقاط جديدة
              </h3>
              <button
                onClick={() => setIsAddCouponModalOpen(false)}
                className="w-7 h-7 rounded-full bg-slate-100 hover:bg-slate-200 text-slate-500 flex items-center justify-center font-bold cursor-pointer"
              >
                ✕
              </button>
            </div>

            <form onSubmit={handleCreateCouponSubmit} className="space-y-4 text-xs font-bold text-slate-700">
              <div>
                <label className="block mb-1">عنوان القسيمة</label>
                <input
                  type="text"
                  required
                  placeholder="مثال: قسيمة خصم 25 ل.س خاصة بالنقاط"
                  value={newCoupon.title_ar}
                  onChange={(e) => setNewCoupon({ ...newCoupon, title_ar: e.target.value })}
                  className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600"
                />
              </div>

              <div>
                <label className="block mb-1">بادئة كود الكوبون</label>
                <input
                  type="text"
                  required
                  placeholder="مثال: REWARD25"
                  value={newCoupon.code_prefix}
                  onChange={(e) => setNewCoupon({ ...newCoupon, code_prefix: e.target.value.toUpperCase() })}
                  className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl uppercase tracking-wider focus:outline-none focus:border-blue-600"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block mb-1">النقاط المطلوبة للاستبدال</label>
                  <input
                    type="number"
                    step="50"
                    min="100"
                    required
                    value={newCoupon.points_cost}
                    onChange={(e) => setNewCoupon({ ...newCoupon, points_cost: Number(e.target.value) })}
                    className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600"
                  />
                </div>
                <div>
                  <label className="block mb-1">قيمة الخصم الفعلي (ل.س)</label>
                  <input
                    type="number"
                    step="1"
                    min="5"
                    required
                    value={newCoupon.discount_amount}
                    onChange={(e) => setNewCoupon({ ...newCoupon, discount_amount: Number(e.target.value) })}
                    className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block mb-1">الحد الأدنى للطلب (ل.س)</label>
                  <input
                    type="number"
                    value={newCoupon.min_order_amount}
                    onChange={(e) => setNewCoupon({ ...newCoupon, min_order_amount: Number(e.target.value) })}
                    className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600"
                  />
                </div>
                <div>
                  <label className="block mb-1">مدة الصلاحية (أيام)</label>
                  <input
                    type="number"
                    value={newCoupon.days_valid}
                    onChange={(e) => setNewCoupon({ ...newCoupon, days_valid: Number(e.target.value) })}
                    className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600"
                  />
                </div>
              </div>

              <div className="pt-3 flex justify-end gap-2 border-t border-slate-100">
                <button
                  type="button"
                  onClick={() => setIsAddCouponModalOpen(false)}
                  className="px-4 py-2 bg-slate-100 text-slate-700 rounded-xl text-xs font-bold cursor-pointer"
                >
                  إلغاء
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 bg-amber-500 hover:bg-amber-600 text-slate-950 font-black rounded-xl text-xs cursor-pointer shadow-md"
                >
                  حفظ وتفعيل القسيمة
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ============================================================== */}
      {/* MODAL 3: Add New Reward Product */}
      {/* ============================================================== */}
      {isAddProductModalOpen && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl max-w-md w-full p-6 shadow-2xl space-y-4">
            <div className="flex items-center justify-between border-b border-slate-100 pb-3">
              <h3 className="text-base font-black text-slate-900 flex items-center gap-2">
                <Gift className="w-5 h-5 text-emerald-600" />
                إضافة منتج هدية مجاني بالنقاط
              </h3>
              <button
                onClick={() => setIsAddProductModalOpen(false)}
                className="w-7 h-7 rounded-full bg-slate-100 hover:bg-slate-200 text-slate-500 flex items-center justify-center font-bold cursor-pointer"
              >
                ✕
              </button>
            </div>

            <form onSubmit={handleCreateProductSubmit} className="space-y-4 text-xs font-bold text-slate-700">
              <div>
                <label className="block mb-1">اسم المنتج الهدية</label>
                <input
                  type="text"
                  required
                  placeholder="مثال: بوكس عسل طبيعي سدر يمني 500 غرام"
                  value={newProduct.title_ar}
                  onChange={(e) => setNewProduct({ ...newProduct, title_ar: e.target.value })}
                  className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600"
                />
              </div>

              <div>
                <label className="block mb-1">رابط صورة المنتج (URL)</label>
                <input
                  type="url"
                  required
                  value={newProduct.image_url}
                  onChange={(e) => setNewProduct({ ...newProduct, image_url: e.target.value })}
                  className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block mb-1">النقاط المطلوبة</label>
                  <input
                    type="number"
                    step="50"
                    min="100"
                    required
                    value={newProduct.points_cost}
                    onChange={(e) => setNewProduct({ ...newProduct, points_cost: Number(e.target.value) })}
                    className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600"
                  />
                </div>
                <div>
                  <label className="block mb-1">الكمية المتاحة (المخزون)</label>
                  <input
                    type="number"
                    min="1"
                    required
                    value={newProduct.stock_quota}
                    onChange={(e) => setNewProduct({ ...newProduct, stock_quota: Number(e.target.value) })}
                    className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600"
                  />
                </div>
              </div>

              <div>
                <label className="block mb-1">التصنيف</label>
                <select
                  value={newProduct.category_ar}
                  onChange={(e) => setNewProduct({ ...newProduct, category_ar: e.target.value })}
                  className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600"
                >
                  <option value="فواكه وخضار طازجة">فواكه وخضار طازجة</option>
                  <option value="مؤن وتموين فاخر">مؤن وتموين فاخر</option>
                  <option value="حلويات وسكاكر">حلويات وسكاكر</option>
                  <option value="مشروبات ومياه">مشروبات ومياه</option>
                  <option value="المخبز والحلويات">المخبز والحلويات</option>
                </select>
              </div>

              <div className="pt-3 flex justify-end gap-2 border-t border-slate-100">
                <button
                  type="button"
                  onClick={() => setIsAddProductModalOpen(false)}
                  className="px-4 py-2 bg-slate-100 text-slate-700 rounded-xl text-xs font-bold cursor-pointer"
                >
                  إلغاء
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 bg-emerald-700 hover:bg-emerald-800 text-white font-black rounded-xl text-xs cursor-pointer shadow-md"
                >
                  حفظ المنتج الهدية
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ============================================================== */}
      {/* MODAL 4: Grant VIP Loyalty Points to Subscriber */}
      {/* ============================================================== */}
      {selectedSubscriberForGift && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl max-w-sm w-full p-6 shadow-2xl space-y-4">
            <h3 className="text-base font-black text-slate-900 flex items-center gap-2">
              <Gift className="w-5 h-5 text-amber-500" />
              إهداء نقاط ولاء VIP
            </h3>
            <p className="text-xs text-slate-500">
              إضافة نقاط مكافأة مباشرة إلى حساب <span className="font-bold text-slate-900">{selectedSubscriberForGift.customer_name}</span>
            </p>

            <div className="space-y-3 text-xs font-bold text-slate-700">
              <div>
                <label className="block mb-1">عدد النقاط الممنوحة</label>
                <input
                  type="number"
                  min="50"
                  step="50"
                  value={giftPointsAmount}
                  onChange={(e) => setGiftPointsAmount(Number(e.target.value))}
                  className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600"
                />
                <p className="text-[11px] text-slate-400 mt-1 font-normal">
                  تعادل خصماً بقيمة {(giftPointsAmount * 0.01).toFixed(2)} ل.س في سلة العميل.
                </p>
              </div>

              <div className="pt-2 flex justify-end gap-2">
                <button
                  type="button"
                  onClick={() => setSelectedSubscriberForGift(null)}
                  className="px-3.5 py-2 bg-slate-100 text-slate-600 rounded-xl text-xs font-bold cursor-pointer"
                >
                  إلغاء
                </button>
                <button
                  type="button"
                  onClick={() => {
                    onGrantPoints(selectedSubscriberForGift.customer_id, giftPointsAmount);
                    setSelectedSubscriberForGift(null);
                  }}
                  className="px-4 py-2 bg-amber-500 hover:bg-amber-600 text-slate-950 rounded-xl text-xs font-black shadow-md cursor-pointer"
                >
                  تأكيد الإيداع الفوري
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
