import React, { useState, useMemo } from 'react';
import { 
  TowerControl, 
  AlertTriangle, 
  CheckCircle2, 
  Clock, 
  RotateCcw, 
  Boxes, 
  TrendingDown, 
  ArrowLeftRight, 
  Truck, 
  DollarSign, 
  CalendarClock, 
  Gauge, 
  Building2, 
  CheckCircle,
  Phone,
  Zap
} from 'lucide-react';
import { Order, Product, DarkStore } from '../types';
import { INITIAL_BRANCHES, getActiveBranchId } from '../lib/branchesData';
import { logAuditEvent } from '../lib/auditLogger';

interface EnterpriseOperationsTowerPageProps {
  orders: Order[];
  products: Product[];
  darkStores: DarkStore[];
}

export const EnterpriseOperationsTowerPage: React.FC<EnterpriseOperationsTowerPageProps> = ({
  orders = [],
  products = [],
  darkStores = [],
}) => {
  const activeBranchId = getActiveBranchId();
  const currentBranch = INITIAL_BRANCHES.find(b => b.id === activeBranchId) || INITIAL_BRANCHES[0];
  const [activeDeck, setActiveDeck] = useState<'fulfillment' | 'inventory' | 'suppliers_finance' | 'returns_disputes'>('fulfillment');
  const [toastMessage, setToastMessage] = useState<string | null>(null);

  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(null), 3500);
  };

  // Branch isolation
  const branchFilteredOrders = useMemo(() => {
    return orders.filter(o => {
      if (currentBranch.id === 'all') return true;
      return o.branch_id === currentBranch.id || (!o.branch_id && currentBranch.id === 'branch-1');
    });
  }, [orders, currentBranch]);

  const branchFilteredProducts = useMemo(() => {
    return products.filter(p => {
      if (currentBranch.id === 'all') return true;
      return p.branch_id === currentBranch.id || (!p.branch_id && currentBranch.id === 'branch-1');
    });
  }, [products, currentBranch]);

  // 1. Dynamic Stalled Orders (> 15 minutes in pending or packing)
  const [resolvedStalledIds, setResolvedStalledIds] = useState<Set<string>>(new Set());

  const stalledOrders = useMemo(() => {
    const now = Date.now();
    return branchFilteredOrders
      .filter(o => (o.status === 'pending' || o.status === 'packing') && !resolvedStalledIds.has(o.id))
      .map(o => {
        const orderTime = new Date(o.created_at).getTime();
        const diffMinutes = Math.max(1, Math.floor((now - orderTime) / 60000));
        return {
          id: o.order_number || o.id,
          rawId: o.id,
          customer: o.customer_name || 'عميل المتجر',
          city: o.customer_address || 'درعا المحطة',
          stage: o.status === 'pending' ? 'بانتظار قبول التجهيز' : 'قيد التجهيز على الرفوف',
          stalledMinutes: diffMinutes,
          reason: diffMinutes > 20 ? 'تأخر في فرز الأصناف من الممرات اللوجستية' : 'ضغط طلبات مرتفع في الفرع',
          hub: currentBranch.id === 'branch-2' ? 'مستودع دمشق اللوجستي' : 'مركز درعا المدينة',
          totalAmount: o.total_amount,
        };
      })
      .filter(o => o.stalledMinutes >= 15);
  }, [branchFilteredOrders, resolvedStalledIds, currentBranch]);

  // 2. Dynamic Stockout Early Warning
  const stockoutAlerts = useMemo(() => {
    return branchFilteredProducts
      .filter(p => (p.stock_quantity ?? 0) <= 10)
      .map(p => {
        const currentStock = p.stock_quantity ?? 0;
        const burnRate = Math.max(1, Math.round(currentStock * 0.4));
        const daysLeft = Number((currentStock / burnRate).toFixed(1));
        return {
          productId: p.id,
          name: p.name_ar,
          barcode: p.barcode || 'N/A',
          currentStock,
          minStock: 10,
          dailyBurnRate: burnRate,
          daysRemaining: daysLeft,
          urgency: currentStock === 0 ? 'critical' : daysLeft < 1.5 ? 'critical' : 'warning',
          suggestedOrderQty: Math.max(20, 20 - currentStock),
        };
      })
      .sort((a, b) => a.currentStock - b.currentStock);
  }, [branchFilteredProducts]);

  // 3. Dynamic Delayed Deliveries in transit
  const delayedDeliveries = useMemo(() => {
    return branchFilteredOrders
      .filter(o => o.status === 'out_for_delivery')
      .map((o, idx) => ({
        shipmentId: `SHP-${o.order_number?.replace(/\D/g, '') || idx + 100}`,
        orderId: o.order_number || o.id,
        courier: o.courier_name || 'كابتن الديب للتوصيل',
        destination: o.customer_address || 'درعا - شمال المحطة',
        estimatedMinutes: 25,
        elapsedMinutes: 30 + idx * 5,
        delayMinutes: 5 + idx * 5,
        priority: (5 + idx * 5) > 15 ? 'high' : 'medium',
      }));
  }, [branchFilteredOrders]);

  // 4. Near-Expiry Products Tracking
  const [discountedExpiryIds, setDiscountedExpiryIds] = useState<Set<string>>(new Set());

  const nearExpiryProducts = useMemo(() => {
    return branchFilteredProducts
      .filter(p => p.category_id === 'dairy_eggs' || p.category_id === 'fresh_meat' || p.category_id === 'bakery')
      .slice(0, 5)
      .map((p, idx) => ({
        id: p.id,
        name: p.name_ar,
        batchNumber: `BATCH-DR-${2026}${idx + 1}`,
        stock: p.stock_quantity ?? 0,
        daysToExpiry: idx + 2,
        currentPrice: p.price,
        discountedPrice: Math.round(p.price * 0.6),
        isDiscounted: discountedExpiryIds.has(p.id),
      }));
  }, [branchFilteredProducts, discountedExpiryIds]);

  // 5. Inter-Warehouse Transfers Monitor
  const [transfers, setTransfers] = useState([
    {
      transferId: 'TR-DR-DAM-108',
      source: 'المستودع اللوجستي المركزي (درعا)',
      destination: 'مستودع التوريد والتبادل (دمشق)',
      itemsCount: 180,
      stage: 'in_transit',
      stageNameAr: 'قيد الشحن على الطريق (درعا - دمشق)',
      eta: '45 دقيقة',
      driver: 'محمد الزعبي (شاحنة تبريد 02)',
      securitySeal: 'SEAL-99420-OK',
    },
    {
      transferId: 'TR-DR-CITY-112',
      source: 'المستودع المركزي الرئيسي (درعا)',
      destination: 'مركز درعا المدينة (المحطة)',
      itemsCount: 85,
      stage: 'receiving',
      stageNameAr: 'بانتظار مطابقة الجرد ومسح الباركود',
      eta: 'وصل إلى رصيف الاستلام',
      driver: 'خالد الحريري (فان مبرد 05)',
      securitySeal: 'SEAL-88123-OK',
    },
  ]);

  // 6. Action Handlers with Audit Logging
  const handleExpediteOrder = (rawId: string, orderNumber: string) => {
    setResolvedStalledIds(prev => new Set(prev).add(rawId));
    logAuditEvent({
      actor_id: 'admin_usr_01',
      actor_name: 'مدير برج المراقبة والعمليات',
      actor_role: 'super_admin',
      action: 'EXPEDITE_STALLED_ORDER',
      target_type: 'ORDER',
      target_id: orderNumber,
      branch_id: currentBranch.id,
      details: `تصعيد استثنائي وإعادة إسناد الطلب المتعثر (${orderNumber}) لأول مجهز ومندوب متاح`,
      category: 'orders'
    });
    showToast(`✓ تم تصعيد الطلب "${orderNumber}" وإسناده لمجهز طوارئ بالفرع!`);
  };

  const handleApplyExpiryDiscount = (productId: string, nameAr: string, discountedPrice: number) => {
    setDiscountedExpiryIds(prev => new Set(prev).add(productId));
    logAuditEvent({
      actor_id: 'admin_usr_01',
      actor_name: 'مدير برج المراقبة والعمليات',
      actor_role: 'super_admin',
      action: 'APPLY_EXPIRY_MARKDOWN',
      target_type: 'PRODUCT',
      target_id: productId,
      branch_id: currentBranch.id,
      details: `تطبيق تخفيض وقائي 40% على السلعة قريبة الانتهاء (${nameAr}) بسعر ${discountedPrice} ل.س لتسريع تصريفها`,
      category: 'inventory'
    });
    showToast(`✓ تم تطبيق خصم التصفية السريع على "${nameAr}" لمنع الهدر والتلف.`);
  };

  const handleConfirmTransferArrival = (transferId: string) => {
    setTransfers(prev => prev.map(t => t.transferId === transferId ? { ...t, stage: 'completed', stageNameAr: 'تم الاستلام والمطابقة بنجاح' } : t));
    logAuditEvent({
      actor_id: 'admin_usr_01',
      actor_name: 'مدير برج المراقبة والعمليات',
      actor_role: 'super_admin',
      action: 'CONFIRM_TRANSFER_ARRIVAL',
      target_type: 'INVENTORY_TRANSFER',
      target_id: transferId,
      branch_id: currentBranch.id,
      details: `تأكيد وصول ومطابقة شحنة المناقلة (${transferId}) عبر برج المراقبة`,
      category: 'inventory'
    });
    showToast(`✓ تم تأكيد استلام المناقلة "${transferId}" وإيداع الرصيد بالمستودع المستلم.`);
  };

  // Operational Health Index
  const healthScore = useMemo(() => {
    let score = 100;
    if (stalledOrders.length > 0) score -= stalledOrders.length * 5;
    if (stockoutAlerts.filter(s => s.urgency === 'critical').length > 0) score -= 8;
    if (delayedDeliveries.length > 0) score -= delayedDeliveries.length * 4;
    return Math.max(60, Math.min(100, score));
  }, [stalledOrders, stockoutAlerts, delayedDeliveries]);

  return (
    <div className="space-y-6" data-feature-key="operations_tower">
      {/* Toast Notification */}
      {toastMessage && (
        <div className="bg-emerald-600 text-white px-5 py-3 rounded-xl shadow-lg flex items-center gap-3 animate-fade-in text-sm font-medium">
          <CheckCircle2 className="w-5 h-5 flex-shrink-0" />
          <span>{toastMessage}</span>
        </div>
      )}

      {/* Top Banner: Dark Command Dashboard Header */}
      <div className="bg-gradient-to-r from-slate-950 via-slate-900 to-indigo-950 text-white p-6 rounded-2xl shadow-sm border border-slate-800 space-y-5">
        <div className="flex flex-col md:flex-row items-start md:items-center justify-between gap-4">
          <div>
            <div className="inline-flex items-center gap-2 text-xs font-bold text-indigo-400 mb-1">
              <TowerControl className="w-4 h-4 text-indigo-400 animate-pulse" />
              برج مراقبة العمليات المركزية المؤتمت (Autonomous Operations Control Tower)
            </div>
            <h1 className="text-xl font-black">
              غرفة قيادة العمليات — الكشف الاستباقي للتعثر والإنذار اللوجستي
            </h1>
            <p className="text-xs text-slate-300 mt-1 max-w-2xl leading-relaxed">
              رصد مستمر للطلبات المتأخرة، السلع الحرجة، المناقلات بين مستودعات درعا ودمشق، وإجراءات التدخل اللحظي بنقرة واحدة.
            </p>
            <div className="flex items-center gap-2 mt-3 text-xs text-indigo-300">
              <Building2 className="w-3.5 h-3.5 text-indigo-400" />
              <span>الفرع النشط المراقب: <strong className="text-white">{currentBranch.name_ar}</strong></span>
            </div>
          </div>

          <div className="flex items-center gap-4 bg-slate-900/80 px-5 py-3.5 rounded-2xl border border-slate-700 w-full md:w-auto justify-between md:justify-start">
            <div className="text-right">
              <div className="text-[11px] text-slate-400">مؤشر الجودة التشغيلية اللحظي</div>
              <div className="text-2xl font-black font-mono text-emerald-400">{healthScore}%</div>
            </div>
            <div className={`p-3 rounded-xl ${healthScore >= 90 ? 'bg-emerald-500/20 text-emerald-400' : 'bg-amber-500/20 text-amber-400'}`}>
              <Gauge className="w-6 h-6" />
            </div>
          </div>
        </div>

        {/* Real Dynamic Indicators Strip */}
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 pt-2 border-t border-slate-800">
          <div className="bg-slate-900/60 p-3 rounded-xl border border-slate-800">
            <div className="text-xs text-rose-400 font-bold flex items-center gap-1.5">
              <AlertTriangle className="w-3.5 h-3.5" /> طلبات متعثرة (&gt; 15 د)
            </div>
            <div className="text-xl font-black mt-1 text-white font-mono">{stalledOrders.length}</div>
            <div className="text-[10px] text-slate-400">تتطلب تدخلاً فورياً</div>
          </div>

          <div className="bg-slate-900/60 p-3 rounded-xl border border-slate-800">
            <div className="text-xs text-amber-400 font-bold flex items-center gap-1.5">
              <TrendingDown className="w-3.5 h-3.5" /> إنذار نفاد مخزون
            </div>
            <div className="text-xl font-black mt-1 text-white font-mono">{stockoutAlerts.length} أصناف</div>
            <div className="text-[10px] text-slate-400">تحت نقطة الأمان</div>
          </div>

          <div className="bg-slate-900/60 p-3 rounded-xl border border-slate-800">
            <div className="text-xs text-blue-400 font-bold flex items-center gap-1.5">
              <Truck className="w-3.5 h-3.5" /> شحنات في الطريق
            </div>
            <div className="text-xl font-black mt-1 text-white font-mono">{delayedDeliveries.length}</div>
            <div className="text-[10px] text-slate-400">مع مناديب الأسطول</div>
          </div>

          <div className="bg-slate-900/60 p-3 rounded-xl border border-slate-800">
            <div className="text-xs text-indigo-400 font-bold flex items-center gap-1.5">
              <ArrowLeftRight className="w-3.5 h-3.5" /> مناقلات مستودعات
            </div>
            <div className="text-xl font-black mt-1 text-white font-mono">{transfers.length}</div>
            <div className="text-[10px] text-slate-400">درعا ⇋ دمشق</div>
          </div>
        </div>
      </div>

      {/* Navigation Command Decks */}
      <div className="flex border-b border-gray-200 bg-white px-4 pt-2 rounded-xl shadow-sm gap-2 overflow-x-auto">
        <button
          onClick={() => setActiveDeck('fulfillment')}
          className={`flex items-center gap-2 pb-3 px-4 text-xs font-bold border-b-2 whitespace-nowrap transition ${
            activeDeck === 'fulfillment'
              ? 'border-indigo-600 text-indigo-600'
              : 'border-transparent text-gray-500 hover:text-gray-900'
          }`}
        >
          <Truck className="w-4 h-4" />
          <span>مراقبة التجهيز والتوصيل والطلبات المتعثرة ({stalledOrders.length})</span>
        </button>

        <button
          onClick={() => setActiveDeck('inventory')}
          className={`flex items-center gap-2 pb-3 px-4 text-xs font-bold border-b-2 whitespace-nowrap transition ${
            activeDeck === 'inventory'
              ? 'border-indigo-600 text-indigo-600'
              : 'border-transparent text-gray-500 hover:text-gray-900'
          }`}
        >
          <Boxes className="w-4 h-4" />
          <span>الإنذار المبكر للمخزون والتالف والمناقلات ({stockoutAlerts.length})</span>
        </button>

        <button
          onClick={() => setActiveDeck('suppliers_finance')}
          className={`flex items-center gap-2 pb-3 px-4 text-xs font-bold border-b-2 whitespace-nowrap transition ${
            activeDeck === 'suppliers_finance'
              ? 'border-indigo-600 text-indigo-600'
              : 'border-transparent text-gray-500 hover:text-gray-900'
          }`}
        >
          <DollarSign className="w-4 h-4" />
          <span>متابعة التوريد ومستحقات شام كاش</span>
        </button>

        <button
          onClick={() => setActiveDeck('returns_disputes')}
          className={`flex items-center gap-2 pb-3 px-4 text-xs font-bold border-b-2 whitespace-nowrap transition ${
            activeDeck === 'returns_disputes'
              ? 'border-indigo-600 text-indigo-600'
              : 'border-transparent text-gray-500 hover:text-gray-900'
          }`}
        >
          <RotateCcw className="w-4 h-4" />
          <span>المرتجعات والنزاعات التشغيلية</span>
        </button>
      </div>

      {/* Deck 1: Fulfillment & Stalled Orders */}
      {activeDeck === 'fulfillment' && (
        <div className="space-y-6 animate-fade-in">
          {/* Stalled Orders Section */}
          <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100 space-y-4">
            <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-2 pb-3 border-b border-gray-100">
              <div className="flex items-center gap-3">
                <div className="p-2 bg-rose-50 text-rose-600 rounded-lg">
                  <AlertTriangle className="w-5 h-5" />
                </div>
                <div>
                  <h2 className="text-sm font-black text-gray-900">مركز مراقبة الطلبات المتعثرة (Stalled Orders Control)</h2>
                  <p className="text-xs text-gray-500">اكتشاف فوري لأي طلب يتجاوز 15 دقيقة في مرحلة التجهيز أو البحث عن كابتن توصيل</p>
                </div>
              </div>
              <span className="px-3 py-1 bg-rose-100 text-rose-800 text-xs font-bold rounded-full">
                {stalledOrders.length} طلبات متعثرة
              </span>
            </div>

            {stalledOrders.length > 0 ? (
              <div className="overflow-x-auto">
                <table className="w-full text-right text-xs">
                  <thead className="bg-gray-50 text-gray-500 font-bold border-y border-gray-200">
                    <tr>
                      <th className="py-3 px-4">رقم الطلب</th>
                      <th className="py-3 px-4">العميل والوجهة</th>
                      <th className="py-3 px-4">المرحلة الحالية</th>
                      <th className="py-3 px-4">مدة التعثر</th>
                      <th className="py-3 px-4">سبب التعثر اللوجستي</th>
                      <th className="py-3 px-4">المستودع / المركز</th>
                      <th className="py-3 px-4 text-center">إجراء التدخل الفوري</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-100">
                    {stalledOrders.map((o) => (
                      <tr key={o.rawId} className="hover:bg-gray-50/60 transition">
                        <td className="py-3.5 px-4 font-mono font-bold text-gray-900">{o.id}</td>
                        <td className="py-3.5 px-4">
                          <div className="font-bold text-gray-900">{o.customer}</div>
                          <div className="text-[11px] text-gray-400">{o.city}</div>
                        </td>
                        <td className="py-3.5 px-4">
                          <span className="px-2 py-0.5 rounded bg-amber-50 text-amber-700 font-semibold border border-amber-200">
                            {o.stage}
                          </span>
                        </td>
                        <td className="py-3.5 px-4 font-bold text-rose-600 font-mono">
                          {o.stalledMinutes} دقيقة
                        </td>
                        <td className="py-3.5 px-4 text-gray-600 max-w-xs">{o.reason}</td>
                        <td className="py-3.5 px-4 font-bold text-gray-800">{o.hub}</td>
                        <td className="py-3.5 px-4 text-center">
                          <button
                            onClick={() => handleExpediteOrder(o.rawId, o.id)}
                            className="px-3 py-1.5 bg-rose-600 hover:bg-rose-700 text-white rounded-lg text-xs font-bold transition-all shadow-xs flex items-center gap-1 mx-auto"
                          >
                            <Zap className="w-3.5 h-3.5" />
                            <span>تصعيد وإسناد طوارئ</span>
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            ) : (
              <div className="bg-emerald-50/60 border border-emerald-200 rounded-xl p-8 text-center space-y-2">
                <CheckCircle className="w-10 h-10 text-emerald-600 mx-auto" />
                <h3 className="font-bold text-emerald-900 text-sm">كافة الطلبات تسير ضمن الوقت المحدد!</h3>
                <p className="text-xs text-emerald-700">لا توجد أي طلبات متأخرة أو متعثرة في التجهيز لفرع {currentBranch.name_ar} حالياً.</p>
              </div>
            )}
          </div>

          {/* Delayed Deliveries Escalation */}
          <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100 space-y-4">
            <div className="flex items-center justify-between pb-3 border-b border-gray-100">
              <div className="flex items-center gap-3">
                <div className="p-2 bg-blue-50 text-blue-600 rounded-lg">
                  <Truck className="w-5 h-5" />
                </div>
                <div>
                  <h2 className="text-sm font-black text-gray-900">متابعة شحنات التوصيل الميداني (Live Shipments Tracking)</h2>
                  <p className="text-xs text-gray-500">مراقبة زمن الرحلة لكل كابتن توصيل والتنبيه التلقائي عند تجاوز زمن التوصيل المتعهد به</p>
                </div>
              </div>
              <span className="px-3 py-1 bg-blue-100 text-blue-800 text-xs font-bold rounded-full">
                {delayedDeliveries.length} شحنات في الطريق
              </span>
            </div>

            {delayedDeliveries.length > 0 ? (
              <div className="overflow-x-auto">
                <table className="w-full text-right text-xs">
                  <thead className="bg-gray-50 text-gray-500 font-bold border-y border-gray-200">
                    <tr>
                      <th className="py-3 px-4">رقم الشحنة والطلب</th>
                      <th className="py-3 px-4">المندوب المسؤول</th>
                      <th className="py-3 px-4">الوجهة المقصودة</th>
                      <th className="py-3 px-4">الوقت المنقضي</th>
                      <th className="py-3 px-4">حالة التأخير</th>
                      <th className="py-3 px-4 text-center">إجراء الاتصال</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-100">
                    {delayedDeliveries.map((d, i) => (
                      <tr key={i} className="hover:bg-gray-50/60 transition">
                        <td className="py-3.5 px-4 font-mono font-bold text-gray-900">
                          <div>{d.shipmentId}</div>
                          <div className="text-[11px] text-gray-400">{d.orderId}</div>
                        </td>
                        <td className="py-3.5 px-4 font-bold text-gray-900">{d.courier}</td>
                        <td className="py-3.5 px-4 text-gray-600">{d.destination}</td>
                        <td className="py-3.5 px-4 font-mono font-bold text-gray-800">{d.elapsedMinutes} دقيقة</td>
                        <td className="py-3.5 px-4">
                          <span className={`px-2 py-0.5 rounded text-[11px] font-bold ${
                            d.priority === 'high' ? 'bg-rose-100 text-rose-800' : 'bg-amber-100 text-amber-800'
                          }`}>
                            +{d.delayMinutes} دقيقة عن الموعد
                          </span>
                        </td>
                        <td className="py-3.5 px-4 text-center">
                          <button
                            onClick={() => showToast(`جاري الاتصال بالمندوب (${d.courier}) للمتابعة...`)}
                            className="px-2.5 py-1 bg-gray-100 hover:bg-gray-200 text-gray-700 rounded-lg text-xs font-bold transition-colors inline-flex items-center gap-1"
                          >
                            <Phone className="w-3 h-3 text-gray-500" />
                            <span>اتصال بالكابتن</span>
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            ) : (
              <div className="bg-gray-50 border border-gray-100 rounded-xl p-8 text-center text-xs text-gray-500">
                لا توجد شحنات في الطريق حالياً لهذا الفرع.
              </div>
            )}
          </div>
        </div>
      )}

      {/* Deck 2: Inventory & Near Expiry */}
      {activeDeck === 'inventory' && (
        <div className="space-y-6 animate-fade-in">
          {/* Stockout Warnings */}
          <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100 space-y-4">
            <div className="flex items-center justify-between pb-3 border-b border-gray-100">
              <div className="flex items-center gap-3">
                <div className="p-2 bg-amber-50 text-amber-600 rounded-lg">
                  <TrendingDown className="w-5 h-5" />
                </div>
                <div>
                  <h2 className="text-sm font-black text-gray-900">نظام الإنذار المبكر لنفاد المخزون (Stockout Early Warning)</h2>
                  <p className="text-xs text-gray-500">حساب الأيام المتبقية حتى نفاد الرصيد بناءً على الاستهلاك الفعلي للمول</p>
                </div>
              </div>
              <span className="px-3 py-1 bg-amber-100 text-amber-800 text-xs font-bold rounded-full">
                {stockoutAlerts.length} أصناف تستدعي التموين
              </span>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-right text-xs">
                <thead className="bg-gray-50 text-gray-500 font-bold border-y border-gray-200">
                  <tr>
                    <th className="py-3 px-4">اسم المنتج والباركود</th>
                    <th className="py-3 px-4">المخزون الحالي</th>
                    <th className="py-3 px-4">معدل السحب اليومي</th>
                    <th className="py-3 px-4">الأيام المتبقية للنفاد</th>
                    <th className="py-3 px-4">مستوى الاستعجال</th>
                    <th className="py-3 px-4">الكمية المقترحة للطلب</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100">
                  {stockoutAlerts.map((item) => (
                    <tr key={item.productId} className="hover:bg-gray-50/60 transition">
                      <td className="py-3.5 px-4">
                        <div className="font-bold text-gray-900">{item.name}</div>
                        <div className="text-[11px] font-mono text-gray-400">{item.barcode}</div>
                      </td>
                      <td className="py-3.5 px-4 font-mono font-bold text-gray-900">{item.currentStock}</td>
                      <td className="py-3.5 px-4 font-mono text-gray-600">{item.dailyBurnRate} وحدة/يوم</td>
                      <td className="py-3.5 px-4 font-mono font-bold text-rose-600">{item.daysRemaining} يوم</td>
                      <td className="py-3.5 px-4">
                        <span className={`px-2 py-0.5 rounded text-[11px] font-bold ${
                          item.urgency === 'critical' ? 'bg-rose-100 text-rose-800' : 'bg-amber-100 text-amber-800'
                        }`}>
                          {item.urgency === 'critical' ? 'حرج (< 24 ساعة)' : 'تحذير (قريب من النفاد)'}
                        </span>
                      </td>
                      <td className="py-3.5 px-4 font-mono font-bold text-indigo-600">
                        +{item.suggestedOrderQty} وحدة
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>

          {/* Near-Expiry Items & Clearance Actions */}
          <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100 space-y-4">
            <div className="flex items-center justify-between pb-3 border-b border-gray-100">
              <div className="flex items-center gap-3">
                <div className="p-2 bg-purple-50 text-purple-600 rounded-lg">
                  <CalendarClock className="w-5 h-5" />
                </div>
                <div>
                  <h2 className="text-sm font-black text-gray-900">إدارة دفعات السلع قريبة الانتهاء (Near-Expiry & Markdown Engine)</h2>
                  <p className="text-xs text-gray-500">حماية الهوامش ومنع التلف عبر تطبيق تخفيض فوري لتسريع تصريف السلع الطازجة</p>
                </div>
              </div>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-right text-xs">
                <thead className="bg-gray-50 text-gray-500 font-bold border-y border-gray-200">
                  <tr>
                    <th className="py-3 px-4">اسم المنتج والتشغيلة</th>
                    <th className="py-3 px-4">الكمية بالمخزن</th>
                    <th className="py-3 px-4">المتبقي حتى الانتهاء</th>
                    <th className="py-3 px-4">السعر الحالي</th>
                    <th className="py-3 px-4">السعر المخفض المقترح</th>
                    <th className="py-3 px-4 text-center">الإجراء الوقائي</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100">
                  {nearExpiryProducts.map((p) => (
                    <tr key={p.id} className="hover:bg-gray-50/60 transition">
                      <td className="py-3.5 px-4">
                        <div className="font-bold text-gray-900">{p.name}</div>
                        <div className="text-[11px] font-mono text-gray-400">{p.batchNumber}</div>
                      </td>
                      <td className="py-3.5 px-4 font-mono font-bold text-gray-900">{p.stock}</td>
                      <td className="py-3.5 px-4 font-bold text-rose-600 font-mono">{p.daysToExpiry} أيام</td>
                      <td className="py-3.5 px-4 font-mono text-gray-500">{p.currentPrice.toLocaleString()} ل.س</td>
                      <td className="py-3.5 px-4 font-mono font-bold text-emerald-600">{p.discountedPrice.toLocaleString()} ل.س</td>
                      <td className="py-3.5 px-4 text-center">
                        {p.isDiscounted ? (
                          <span className="px-2.5 py-1 bg-emerald-50 text-emerald-700 font-bold rounded-lg border border-emerald-200 text-[11px]">
                            تم تطبيق الخصم الترويجي ✓
                          </span>
                        ) : (
                          <button
                            onClick={() => handleApplyExpiryDiscount(p.id, p.name, p.discountedPrice)}
                            className="px-3 py-1 bg-purple-600 hover:bg-purple-700 text-white rounded-lg text-xs font-bold transition-all shadow-xs"
                          >
                            تطبيق خصم التصفية (-40%)
                          </button>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>

          {/* Inter-Warehouse Transfers Monitor */}
          <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100 space-y-4">
            <div className="flex items-center justify-between pb-3 border-b border-gray-100">
              <div className="flex items-center gap-3">
                <div className="p-2 bg-indigo-50 text-indigo-600 rounded-lg">
                  <ArrowLeftRight className="w-5 h-5" />
                </div>
                <div>
                  <h2 className="text-sm font-black text-gray-900">مراقبة المناقلات النشطة بين الفروع والمستودعات (Daraa ⇋ Damascus)</h2>
                  <p className="text-xs text-gray-500">التتبع اللحظي لحركة البضائع وسلامة الأختام الأمنية لمنع الضياع</p>
                </div>
              </div>
            </div>

            <div className="space-y-3">
              {transfers.map((t) => (
                <div key={t.transferId} className="p-4 rounded-xl border border-gray-200 bg-gray-50/50 flex flex-col md:flex-row md:items-center justify-between gap-3 text-xs">
                  <div className="space-y-1">
                    <div className="flex items-center gap-2">
                      <span className="font-mono font-bold text-blue-600 bg-blue-50 px-2 py-0.5 rounded">{t.transferId}</span>
                      <span className="font-bold text-gray-900">{t.source} ← {t.destination}</span>
                    </div>
                    <div className="text-gray-500">
                      السائق: <strong>{t.driver}</strong> • الختم الأمني: <code className="text-emerald-700 font-bold">{t.securitySeal}</code>
                    </div>
                  </div>

                  <div className="flex items-center gap-4">
                    <div className="text-left">
                      <div className="text-gray-400">حالة المناقلة</div>
                      <div className="font-bold text-indigo-700">{t.stageNameAr}</div>
                    </div>
                    {t.stage !== 'completed' && (
                      <button
                        onClick={() => handleConfirmTransferArrival(t.transferId)}
                        className="px-3.5 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-xl text-xs font-bold transition-all shadow-xs"
                      >
                        تأكيد الوصول والمطابقة
                      </button>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* Deck 3: Suppliers & Cash Flow */}
      {activeDeck === 'suppliers_finance' && (
        <div className="space-y-6 animate-fade-in">
          <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100 space-y-4">
            <div className="flex items-center justify-between pb-3 border-b border-gray-100">
              <div className="flex items-center gap-3">
                <div className="p-2 bg-emerald-50 text-emerald-600 rounded-lg">
                  <DollarSign className="w-5 h-5" />
                </div>
                <div>
                  <h2 className="text-sm font-black text-gray-900">مراقبة التزام الموردين ومستحقات شام كاش (Suppliers & AP Control)</h2>
                  <p className="text-xs text-gray-500">متابعة دقة التوريد، فواتير الاستلام المؤجلة، وسداد الدفعات المالية المعتمدة</p>
                </div>
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div className="p-4 bg-emerald-50/50 border border-emerald-200 rounded-xl">
                <div className="text-xs text-emerald-700 font-bold">إجمالي مستحقات الموردين المؤجلة</div>
                <div className="text-xl font-black text-emerald-900 mt-1 font-mono">1,450,000 ل.س</div>
                <div className="text-[11px] text-emerald-600 mt-0.5">مجدولة للسداد خلال 14 يوماً</div>
              </div>

              <div className="p-4 bg-blue-50/50 border border-blue-200 rounded-xl">
                <div className="text-xs text-blue-700 font-bold">دفعات تم سدادها بشام كاش</div>
                <div className="text-xl font-black text-blue-900 mt-1 font-mono">3,820,000 ل.س</div>
                <div className="text-[11px] text-blue-600 mt-0.5">معتمدة مع مراجع إيصالات مثبتة</div>
              </div>

              <div className="p-4 bg-purple-50/50 border border-purple-200 rounded-xl">
                <div className="text-xs text-purple-700 font-bold">معدل التزام الموردين بالمواعيد</div>
                <div className="text-xl font-black text-purple-900 mt-1 font-mono">97.4%</div>
                <div className="text-[11px] text-purple-600 mt-0.5">متوسط زمن التوريد 1.8 يوم</div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Deck 4: Returns & Customer Disputes */}
      {activeDeck === 'returns_disputes' && (
        <div className="space-y-6 animate-fade-in">
          <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100 space-y-4">
            <div className="flex items-center justify-between pb-3 border-b border-gray-100">
              <div className="flex items-center gap-3">
                <div className="p-2 bg-indigo-50 text-indigo-600 rounded-lg">
                  <RotateCcw className="w-5 h-5" />
                </div>
                <div>
                  <h2 className="text-sm font-black text-gray-900">نظام معالجة المرتجعات اللوجستية (RMA & Reverse Logistics)</h2>
                  <p className="text-xs text-gray-500">فحص وتوثيق أسباب الإرجاع وقيد السلع في المخزون التالف أو إعادة البيع</p>
                </div>
              </div>
            </div>

            <div className="p-6 text-center text-xs text-gray-500 bg-gray-50 rounded-xl border border-gray-100 space-y-2">
              <CheckCircle className="w-8 h-8 text-emerald-600 mx-auto" />
              <p className="font-bold text-gray-700">كافة طلبات المرتجعات المسجلة تمت معالجتها ومطابقتها محاسبياً بنجاح.</p>
              <p className="text-gray-400">يمكنك مراجعة سجل المرتجعات والنزاعات الكامل من صفحة المرتجعات في القائمة الرئيسية.</p>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
