import React, { useState } from 'react';
import { 
  TrendingUp, 
  ShoppingBag, 
  AlertTriangle, 
  Award, 
  ArrowUpRight,
  Clock, 
  CheckCircle2,
  Package,
  Camera,
  Users,
  ShieldAlert,
  Flame,
  Layers,
  Radio,
  Sliders,
  Bell,
  Sparkles,
  Maximize2,
  RefreshCw,
  Zap,
  Play,
  Volume2
} from 'lucide-react';
import { Order, Product } from '../types';
import { 
  INITIAL_CAMERAS, 
  INITIAL_INCIDENTS, 
  StoreCamera, 
  SecurityIncident 
} from '../lib/storeVisionData';
import { LiveCameraFeedCard } from '../components/dashboard/LiveCameraFeedCard';
import { StoreFloorplanHeatmap } from '../components/dashboard/StoreFloorplanHeatmap';
import { FootfallPeakAnalytics } from '../components/dashboard/FootfallPeakAnalytics';
import { LossPreventionRadar } from '../components/dashboard/LossPreventionRadar';
import { IncidentReviewModal } from '../components/dashboard/IncidentReviewModal';
import { CameraMonitorModal } from '../components/dashboard/CameraMonitorModal';

interface DashboardPageProps {
  orders: Order[];
  products: Product[];
  setActiveTab: (tab: string) => void;
  onUpdateOrderStatus: (orderId: string, status: Order['status']) => void;
}

export const DashboardPage: React.FC<DashboardPageProps> = ({
  orders,
  products,
  setActiveTab,
  onUpdateOrderStatus,
}) => {
  // Navigation Tabs for Dashboard
  const [activeDeck, setActiveDeck] = useState<'overview' | 'cctv_matrix' | 'footfall_peaks' | 'store_floorplan' | 'loss_prevention'>('overview');

  // Cameras and Incidents State
  const [cameras, setCameras] = useState<StoreCamera[]>(INITIAL_CAMERAS);
  const [incidents, setIncidents] = useState<SecurityIncident[]>(INITIAL_INCIDENTS);

  // Modals state
  const [selectedMonitorCamera, setSelectedMonitorCamera] = useState<StoreCamera | null>(null);
  const [selectedReviewIncident, setSelectedReviewIncident] = useState<SecurityIncident | null>(null);

  // Action Bar Status
  const [actionAlertMsg, setActionAlertMsg] = useState<string | null>(null);
  const [highAlertMode, setHighAlertMode] = useState(false);

  // Financial & Inventory calculations
  const totalRevenue = orders.reduce((sum, o) => sum + o.total_amount, 0);
  const pendingOrders = orders.filter((o) => o.status === 'pending' || o.status === 'packing');
  const lowStockProducts = products.filter((p) => p.stock_quantity < 25);
  const totalPointsRedeemed = orders.reduce((sum, o) => sum + o.loyalty_discount, 0);

  // Trigger quick operations action
  const triggerQuickAction = (msg: string) => {
    setActionAlertMsg(msg);
    setTimeout(() => setActionAlertMsg(null), 3000);
  };

  const handleUpdateIncidentStatus = (
    incidentId: string, 
    newStatus: SecurityIncident['status'], 
    actionMessage: string
  ) => {
    setIncidents(prev => prev.map(inc => {
      if (inc.id === incidentId) {
        return {
          ...inc,
          status: newStatus,
          actionTaken: actionMessage
        };
      }
      return inc;
    }));
  };

  const activeAlertsCount = incidents.filter(i => i.status === 'active' || i.status === 'investigating').length;

  return (
    <div className="space-y-6" dir="rtl">
      {/* 1. Top Command & Operations Bar */}
      <div className="bg-slate-900 border border-slate-800 rounded-3xl p-5 text-slate-100 shadow-xl flex flex-col lg:flex-row items-start lg:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-2xl bg-gradient-to-tr from-blue-600 to-indigo-600 flex items-center justify-center text-white shadow-lg shadow-blue-900/50">
              <Camera className="w-5 h-5" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h2 className="text-lg font-black text-white">مركز العمليات والمراقبة البصرية الذكية</h2>
                <span className="text-[11px] font-bold bg-emerald-500/20 text-emerald-300 border border-emerald-500/30 px-2 py-0.5 rounded-full flex items-center gap-1">
                  <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-ping" />
                  6 كاميرات متصلة (4K Edge AI)
                </span>
                {highAlertMode && (
                  <span className="text-[11px] font-bold bg-rose-500/20 text-rose-300 border border-rose-500/40 px-2 py-0.5 rounded-full animate-pulse">
                    🚨 وضع الحراسة المشددة
                  </span>
                )}
              </div>
              <p className="text-xs text-slate-400 mt-0.5">
                تتبع لحظي للزوار، ساعات الذروة، كشف السرقات وأخطاء الكاشير، وإدارة الطلبات الميدانية
              </p>
            </div>
          </div>
        </div>

        {/* Quick Operations Triggers */}
        <div className="flex flex-wrap items-center gap-2 text-xs">
          <button
            onClick={() => triggerQuickAction('🔔 تم إرسال نغمة استدعاء صامتة إلى أجهزة حراس الأمن الميدانيين')}
            className="px-3 py-2 bg-rose-600/20 hover:bg-rose-600/30 text-rose-300 border border-rose-500/40 rounded-xl font-bold transition-all flex items-center gap-1.5 shadow-sm"
          >
            <Radio className="w-3.5 h-3.5 animate-pulse" />
            إشعار أمني صامت (Guard Chime)
          </button>

          <button
            onClick={() => triggerQuickAction('📢 تم توجيه نداء آلي لشاشات الكاشير: فتح مسار كاشير إضافي فوراً')}
            className="px-3 py-2 bg-amber-600/20 hover:bg-amber-600/30 text-amber-300 border border-amber-500/40 rounded-xl font-bold transition-all flex items-center gap-1.5 shadow-sm"
          >
            <Zap className="w-3.5 h-3.5" />
            استدعاء كاشير إضافي للذروة
          </button>

          <button
            onClick={() => {
              setHighAlertMode(!highAlertMode);
              triggerQuickAction(highAlertMode ? 'تم تعطيل وضع الاستنفار الأمني' : '⚠️ تم تفعيل وضع الاستنفار الأمني والتدقيق المضاعف بالذكاء الاصطناعي');
            }}
            className={`px-3 py-2 rounded-xl font-bold transition-all flex items-center gap-1.5 border ${
              highAlertMode 
                ? 'bg-rose-600 text-white border-rose-400 shadow-md shadow-rose-900/50' 
                : 'bg-slate-800 text-slate-300 border-slate-700 hover:text-white hover:bg-slate-700'
            }`}
          >
            <ShieldAlert className="w-3.5 h-3.5" />
            {highAlertMode ? 'إلغاء الاستنفار' : 'استنفار أمني'}
          </button>
        </div>
      </div>

      {/* Action Feedback Banner */}
      {actionAlertMsg && (
        <div className="p-3.5 bg-blue-600 text-white rounded-2xl shadow-lg flex items-center justify-between text-xs font-bold animate-in fade-in duration-200">
          <span className="flex items-center gap-2">
            <Sparkles className="w-4 h-4" />
            {actionAlertMsg}
          </span>
          <button onClick={() => setActionAlertMsg(null)} className="opacity-80 hover:opacity-100">✕</button>
        </div>
      )}

      {/* 2. Operations Sub-Navigation Tabs */}
      <div className="flex items-center gap-2 overflow-x-auto pb-1 border-b border-slate-200 dark:border-slate-800">
        <button
          onClick={() => setActiveDeck('overview')}
          className={`px-4 py-2.5 rounded-2xl text-xs font-extrabold transition-all flex items-center gap-2 shrink-0 ${
            activeDeck === 'overview'
              ? 'bg-blue-600 text-white shadow-md shadow-blue-600/30'
              : 'bg-white hover:bg-slate-50 text-slate-600 border border-slate-200/80 shadow-sm'
          }`}
        >
          <TrendingUp className="w-4 h-4" />
          المركز القيادي الشامل (Omni Operations)
        </button>

        <button
          onClick={() => setActiveDeck('cctv_matrix')}
          className={`px-4 py-2.5 rounded-2xl text-xs font-extrabold transition-all flex items-center gap-2 shrink-0 ${
            activeDeck === 'cctv_matrix'
              ? 'bg-blue-600 text-white shadow-md shadow-blue-600/30'
              : 'bg-white hover:bg-slate-50 text-slate-600 border border-slate-200/80 shadow-sm'
          }`}
        >
          <Camera className="w-4 h-4" />
          مصفوفة الكاميرات والذكاء البصري (CCTV 6-Cam)
          <span className="text-[10px] bg-slate-900 text-emerald-400 px-1.5 py-0.5 rounded-md font-mono">
            LIVE 4K
          </span>
        </button>

        <button
          onClick={() => setActiveDeck('footfall_peaks')}
          className={`px-4 py-2.5 rounded-2xl text-xs font-extrabold transition-all flex items-center gap-2 shrink-0 ${
            activeDeck === 'footfall_peaks'
              ? 'bg-blue-600 text-white shadow-md shadow-blue-600/30'
              : 'bg-white hover:bg-slate-50 text-slate-600 border border-slate-200/80 shadow-sm'
          }`}
        >
          <Users className="w-4 h-4" />
          عداد الزوار وساعات الذروة (Footfall & Peaks)
          <span className="text-[10px] bg-emerald-100 text-emerald-800 px-1.5 py-0.5 rounded-md font-bold">
            52 زائر الآن
          </span>
        </button>

        <button
          onClick={() => setActiveDeck('store_floorplan')}
          className={`px-4 py-2.5 rounded-2xl text-xs font-extrabold transition-all flex items-center gap-2 shrink-0 ${
            activeDeck === 'store_floorplan'
              ? 'bg-blue-600 text-white shadow-md shadow-blue-600/30'
              : 'bg-white hover:bg-slate-50 text-slate-600 border border-slate-200/80 shadow-sm'
          }`}
        >
          <Layers className="w-4 h-4" />
          الخريطة الحرارية ومسقط المتجر (2D Floorplan)
        </button>

        <button
          onClick={() => setActiveDeck('loss_prevention')}
          className={`px-4 py-2.5 rounded-2xl text-xs font-extrabold transition-all flex items-center gap-2 shrink-0 ${
            activeDeck === 'loss_prevention'
              ? 'bg-blue-600 text-white shadow-md shadow-blue-600/30'
              : 'bg-white hover:bg-slate-50 text-slate-600 border border-slate-200/80 shadow-sm'
          }`}
        >
          <ShieldAlert className="w-4 h-4" />
          رادار كشف السرقات وأخطاء الكاشير (Loss Prevention)
          {activeAlertsCount > 0 && (
            <span className="text-[10px] bg-rose-500 text-white px-2 py-0.5 rounded-full font-bold animate-pulse">
              {activeAlertsCount} نشط
            </span>
          )}
        </button>
      </div>

      {/* 3. VIEW MODE 1: OVERVIEW (Comprehensive Hybrid Deck) */}
      {activeDeck === 'overview' && (
        <div className="space-y-6">
          {/* Top KPI Cards (Sales, Footfall, Pending, Alerts) */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-5">
            {/* Sales Revenue */}
            <div className="bg-white p-5 rounded-3xl border border-slate-200/80 shadow-sm hover:shadow-md transition-shadow">
              <div className="flex items-center justify-between mb-3">
                <span className="text-xs font-bold text-slate-500">إجمالي مبيعات اليوم</span>
                <div className="p-2.5 bg-blue-50 text-blue-600 rounded-2xl">
                  <TrendingUp className="w-5 h-5" />
                </div>
              </div>
              <div className="flex items-baseline justify-between">
                <h3 className="text-2xl font-extrabold text-slate-900">{totalRevenue.toFixed(2)} ل.س</h3>
                <span className="text-xs font-bold text-emerald-600 flex items-center">
                  +18.4%
                  <ArrowUpRight className="w-3.5 h-3.5" />
                </span>
              </div>
              <p className="text-[11px] text-slate-400 mt-2">تحديث مباشر من نقاط البيع وتطبيقات الجوال</p>
            </div>

            {/* In-Store Occupancy & Footfall */}
            <div className="bg-white p-5 rounded-3xl border border-slate-200/80 shadow-sm hover:shadow-md transition-shadow">
              <div className="flex items-center justify-between mb-3">
                <span className="text-xs font-bold text-slate-500">حركة الزوار الميدانية (الكاميرات)</span>
                <div className="p-2.5 bg-emerald-50 text-emerald-600 rounded-2xl">
                  <Users className="w-5 h-5" />
                </div>
              </div>
              <div className="flex items-baseline justify-between">
                <h3 className="text-2xl font-extrabold text-slate-900">52 متسوقاً</h3>
                <button
                  onClick={() => setActiveDeck('footfall_peaks')}
                  className="text-xs font-bold text-emerald-600 hover:underline"
                >
                  تحليل الذروة
                </button>
              </div>
              <div className="w-full h-1.5 bg-slate-100 rounded-full mt-2.5 overflow-hidden">
                <div className="h-full bg-emerald-500 rounded-full" style={{ width: '65%' }} />
              </div>
              <p className="text-[11px] text-slate-400 mt-1.5">إشغال 65% من أصل 80 متسوق كحد مريح</p>
            </div>

            {/* Active Orders */}
            <div className="bg-white p-5 rounded-3xl border border-slate-200/80 shadow-sm hover:shadow-md transition-shadow">
              <div className="flex items-center justify-between mb-3">
                <span className="text-xs font-bold text-slate-500">طلبات نشطة قيد التجهيز</span>
                <div className="p-2.5 bg-amber-50 text-amber-600 rounded-2xl">
                  <ShoppingBag className="w-5 h-5" />
                </div>
              </div>
              <div className="flex items-baseline justify-between">
                <h3 className="text-2xl font-extrabold text-slate-900">{pendingOrders.length} طلبات</h3>
                <button
                  onClick={() => setActiveTab('orders')}
                  className="text-xs font-bold text-blue-600 hover:underline"
                >
                  عرض الطلبات
                </button>
              </div>
              <p className="text-[11px] text-slate-400 mt-2">متوسط وقت التجهيز والفرز: 11 دقيقة</p>
            </div>

            {/* AI Loss Prevention Alerts */}
            <div className="bg-white p-5 rounded-3xl border border-slate-200/80 shadow-sm hover:shadow-md transition-shadow">
              <div className="flex items-center justify-between mb-3">
                <span className="text-xs font-bold text-slate-500">رادار السرقات وأخطاء الكاشير</span>
                <div className="p-2.5 bg-rose-50 text-rose-600 rounded-2xl">
                  <ShieldAlert className="w-5 h-5" />
                </div>
              </div>
              <div className="flex items-baseline justify-between">
                <h3 className="text-2xl font-extrabold text-rose-600">{activeAlertsCount} حالات</h3>
                <button
                  onClick={() => setActiveDeck('loss_prevention')}
                  className="text-xs font-bold text-rose-600 hover:underline"
                >
                  فحص الحوادث
                </button>
              </div>
              <p className="text-[11px] text-rose-500 font-bold mt-2">اشتباه إخفاء + عدم تطابق كاشير 2</p>
            </div>
          </div>

          {/* Real-time Surveillance Highlights (2-cam live snapshot + fast incident alert) */}
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
            {/* Live Camera Grid Preview (8 cols) */}
            <div className="lg:col-span-8 bg-slate-900 border border-slate-800 rounded-3xl p-5 text-slate-100 shadow-xl space-y-4">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <Camera className="w-5 h-5 text-blue-400" />
                  <h3 className="font-extrabold text-base text-white">بث الكاميرات الحية الأهم (Live Vision Preview)</h3>
                </div>
                <button
                  onClick={() => setActiveDeck('cctv_matrix')}
                  className="text-xs font-bold text-blue-400 hover:text-blue-300 flex items-center gap-1"
                >
                  عرض كافة الـ 6 كاميرات
                  <Maximize2 className="w-3.5 h-3.5" />
                </button>
              </div>

              {/* 2 Primary Cameras Side by Side */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <LiveCameraFeedCard 
                  camera={cameras[0]} 
                  onSelectCamera={(cam) => setSelectedMonitorCamera(cam)} 
                />
                <LiveCameraFeedCard 
                  camera={cameras[3]} 
                  onSelectCamera={(cam) => setSelectedMonitorCamera(cam)} 
                />
              </div>

              <div className="p-3 bg-slate-950 rounded-2xl border border-slate-800 flex items-center justify-between text-xs text-slate-400">
                <span className="flex items-center gap-2">
                  <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />
                  نظام التعرف YOLOv10 يعمل بأقصى طاقة استيعابية (معدل استجابة 22ms)
                </span>
                <button
                  onClick={() => setActiveDeck('store_floorplan')}
                  className="text-blue-400 hover:text-blue-300 font-bold"
                >
                  عرض المسقط الأفقي للمول ←
                </button>
              </div>
            </div>

            {/* Real-time Anomaly Ticker & Fast Actions (4 cols) */}
            <div className="lg:col-span-4 bg-slate-900 border border-slate-800 rounded-3xl p-5 text-slate-100 shadow-xl flex flex-col justify-between space-y-4">
              <div>
                <div className="flex items-center justify-between mb-3">
                  <h3 className="font-extrabold text-sm text-white flex items-center gap-2">
                    <ShieldAlert className="w-4 h-4 text-rose-500" />
                    أحدث التنبيهات الأمنية والتشغيلية
                  </h3>
                  <span className="text-[10px] bg-rose-500/20 text-rose-400 border border-rose-500/30 px-2 py-0.5 rounded-full font-bold">
                    فوري
                  </span>
                </div>

                <div className="space-y-3">
                  {incidents.slice(0, 3).map((inc) => (
                    <div 
                      key={inc.id}
                      onClick={() => setSelectedReviewIncident(inc)}
                      className={`p-3 rounded-2xl border cursor-pointer transition-all ${
                        inc.severity === 'critical' && inc.status === 'active'
                          ? 'bg-rose-950/30 border-rose-500/40 hover:bg-rose-950/50'
                          : 'bg-slate-950/80 border-slate-800 hover:bg-slate-800/80'
                      }`}
                    >
                      <div className="flex items-center justify-between text-xs mb-1">
                        <span className="font-bold text-white line-clamp-1">{inc.title}</span>
                        <span className="text-[10px] font-mono text-purple-300">{inc.timestamp}</span>
                      </div>
                      <p className="text-[11px] text-slate-300 line-clamp-2 leading-relaxed">
                        {inc.description}
                      </p>
                      <div className="mt-2 pt-2 border-t border-slate-800 flex items-center justify-between text-[10px]">
                        <span className="text-slate-400">{inc.cameraName}</span>
                        <span className="text-blue-400 font-bold flex items-center gap-0.5">
                          <Play className="w-3 h-3" /> مراجعة المقطع
                        </span>
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              <button
                onClick={() => setActiveDeck('loss_prevention')}
                className="w-full py-2.5 bg-slate-950 hover:bg-slate-800 text-slate-200 border border-slate-800 rounded-xl text-xs font-bold transition-colors flex items-center justify-center gap-2"
              >
                <ShieldAlert className="w-4 h-4 text-rose-400" />
                فتح الرادار الأمني الكامل ومراجعة الأدلة
              </button>
            </div>
          </div>

          {/* Quick Operations & Order Queue Section */}
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            {/* Live Orders Queue (2 cols) */}
            <div className="lg:col-span-2 bg-white rounded-3xl border border-slate-200/80 p-6 shadow-sm">
              <div className="flex items-center justify-between mb-4">
                <div>
                  <h3 className="text-base font-extrabold text-slate-900">طابور الطلبات الحية والتجهيز الفوري</h3>
                  <p className="text-xs text-slate-400">تحديث فوري لطلبات العملاء من المتجر والتطبيق</p>
                </div>
                <button
                  onClick={() => setActiveTab('orders')}
                  className="text-xs font-bold text-blue-600 hover:underline"
                >
                  كافة الطلبات ({orders.length})
                </button>
              </div>

              <div className="space-y-3">
                {orders.slice(0, 4).map((order) => {
                  const isPending = order.status === 'pending';
                  const isPacking = order.status === 'packing';
                  const isDelivering = order.status === 'out_for_delivery';

                  return (
                    <div
                      key={order.id}
                      className="p-4 rounded-2xl border border-slate-100 hover:border-slate-200 bg-slate-50/50 hover:bg-white transition-all flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3"
                    >
                      <div className="flex items-center gap-3">
                        <div className={`w-9 h-9 rounded-xl flex items-center justify-center font-bold text-xs ${
                          isPending ? 'bg-amber-100 text-amber-800' :
                          isPacking ? 'bg-blue-100 text-blue-800' :
                          isDelivering ? 'bg-purple-100 text-purple-800' : 'bg-emerald-100 text-emerald-800'
                        }`}>
                          {order.id.slice(-4)}
                        </div>
                        <div>
                          <div className="flex items-center gap-2">
                            <span className="text-xs font-bold text-slate-900">{order.customer_name}</span>
                            <span className="text-[11px] text-slate-400">• {order.created_at}</span>
                          </div>
                          <p className="text-[11px] text-slate-500">
                            {order.items.length} أصناف • {order.delivery_slot}
                          </p>
                        </div>
                      </div>

                      <div className="flex items-center gap-3 w-full sm:w-auto justify-between sm:justify-end">
                        <span className="text-sm font-extrabold text-slate-900 font-mono">
                          {order.total_amount.toFixed(2)} ل.س
                        </span>

                        {isPending && (
                          <button
                            onClick={() => onUpdateOrderStatus(order.id, 'packing')}
                            className="px-3 py-1.5 bg-blue-600 hover:bg-blue-700 text-white rounded-xl text-xs font-bold transition-colors"
                          >
                            بدء التجهيز
                          </button>
                        )}
                        {isPacking && (
                          <button
                            onClick={() => onUpdateOrderStatus(order.id, 'out_for_delivery')}
                            className="px-3 py-1.5 bg-amber-500 hover:bg-amber-600 text-white rounded-xl text-xs font-bold transition-colors"
                          >
                            تسليم للمندوب
                          </button>
                        )}
                        {isDelivering && (
                          <button
                            onClick={() => onUpdateOrderStatus(order.id, 'delivered')}
                            className="px-3 py-1.5 bg-emerald-600 hover:bg-emerald-700 text-white rounded-xl text-xs font-bold transition-colors"
                          >
                            تأكيد التسليم
                          </button>
                        )}
                        {order.status === 'delivered' && (
                          <span className="px-3 py-1.5 bg-emerald-100 text-emerald-800 rounded-xl text-xs font-bold flex items-center gap-1">
                            <CheckCircle2 className="w-3.5 h-3.5" /> تم التسليم
                          </span>
                        )}
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>

            {/* Low Stock Alerts (1 col) */}
            <div className="bg-white rounded-3xl border border-slate-200/80 p-6 shadow-sm flex flex-col justify-between">
              <div>
                <div className="flex items-center justify-between mb-4">
                  <h3 className="text-base font-extrabold text-slate-900">أصناف قاربت على النفاد</h3>
                  <span className="text-xs bg-rose-100 text-rose-700 font-extrabold px-2 py-0.5 rounded-full">
                    تحتاج توريد
                  </span>
                </div>
                <p className="text-xs text-slate-400 mb-3">ربط مع الموردين وأوامر الشراء التلقائية</p>

                <div className="space-y-3">
                  {lowStockProducts.slice(0, 3).map((p) => (
                    <div key={p.id} className="p-3 bg-rose-50/50 rounded-2xl border border-rose-100 flex items-center justify-between">
                      <div className="flex items-center gap-3">
                        <img src={p.images[0]} alt={p.name_ar} className="w-9 h-9 object-cover rounded-xl" />
                        <div>
                          <p className="text-xs font-bold text-slate-800 line-clamp-1">{p.name_ar}</p>
                          <p className="text-[11px] text-rose-600 font-bold">المتبقي: {p.stock_quantity} {p.unit}</p>
                        </div>
                      </div>
                      <button
                        onClick={() => setActiveTab('products')}
                        className="text-xs font-bold text-blue-600 hover:underline px-2.5 py-1 bg-white rounded-lg border border-slate-200"
                      >
                        طلب
                      </button>
                    </div>
                  ))}
                </div>
              </div>

              <div className="mt-4 pt-3 border-t border-slate-100">
                <button
                  onClick={() => setActiveTab('products')}
                  className="w-full py-2.5 bg-slate-900 hover:bg-slate-800 text-white rounded-xl text-xs font-bold transition-colors flex items-center justify-center gap-2"
                >
                  <Package className="w-4 h-4" />
                  إدارة كافة الأصناف والمستودع
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* 4. VIEW MODE 2: FULL CCTV 6-CAM MATRIX */}
      {activeDeck === 'cctv_matrix' && (
        <div className="space-y-6">
          <div className="bg-slate-900 border border-slate-800 rounded-3xl p-5 text-slate-100 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3 shadow-xl">
            <div>
              <h3 className="text-base font-extrabold text-white flex items-center gap-2">
                <Camera className="w-5 h-5 text-blue-400" />
                مصفوفة الرقابة البصرية الشاملة (All 6 Store Cameras Live Grid)
              </h3>
              <p className="text-xs text-slate-400 mt-0.5">
                تغطية شاملة لكافة أرجاء الهايبرماركت مع محددات الذكاء الاصطناعي YOLO وتصنيف السلوكيات الميدانية
              </p>
            </div>

            <div className="flex items-center gap-2">
              <span className="text-xs font-mono bg-slate-950 px-3 py-1.5 rounded-xl border border-slate-800 text-emerald-400 font-bold">
                إجمالي الإطارات: 180 FPS • زمن الاستجابة: 24ms
              </span>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
            {cameras.map((camera) => (
              <LiveCameraFeedCard
                key={camera.id}
                camera={camera}
                onSelectCamera={(cam) => setSelectedMonitorCamera(cam)}
              />
            ))}
          </div>
        </div>
      )}

      {/* 5. VIEW MODE 3: FOOTFALL & PEAK HOURS ANALYTICS */}
      {activeDeck === 'footfall_peaks' && (
        <FootfallPeakAnalytics totalOrdersCount={orders.length} />
      )}

      {/* 6. VIEW MODE 4: 2D STORE FLOORPLAN HEATMAP */}
      {activeDeck === 'store_floorplan' && (
        <StoreFloorplanHeatmap 
          onSelectCamera={(cam) => setSelectedMonitorCamera(cam)}
        />
      )}

      {/* 7. VIEW MODE 5: LOSS PREVENTION RADAR */}
      {activeDeck === 'loss_prevention' && (
        <LossPreventionRadar
          incidents={incidents}
          onOpenIncidentReview={(inc) => setSelectedReviewIncident(inc)}
        />
      )}

      {/* Fullscreen Camera Monitor Modal */}
      {selectedMonitorCamera && (
        <CameraMonitorModal
          camera={selectedMonitorCamera}
          allCameras={cameras}
          onClose={() => setSelectedMonitorCamera(null)}
          onSelectCamera={(cam) => setSelectedMonitorCamera(cam)}
        />
      )}

      {/* Incident Review Video Player Modal */}
      {selectedReviewIncident && (
        <IncidentReviewModal
          incident={selectedReviewIncident}
          onClose={() => setSelectedReviewIncident(null)}
          onUpdateStatus={handleUpdateIncidentStatus}
        />
      )}
    </div>
  );
};
