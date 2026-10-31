import React, { useState } from 'react';
import { 
  TowerControl, 
  AlertTriangle, 
  CheckCircle2, 
  Clock, 
  RotateCcw, 
  Boxes, 
  TrendingDown, 
  ArrowLeftRight, 
  ShieldAlert, 
  FileText, 
  Layers, 
  Zap, 
  Truck, 
  DollarSign, 
  Store, 
  CalendarClock, 
  PackageCheck, 
  Gauge, 
  HelpCircle,
  Search,
  Filter,
  RefreshCw,
  Phone,
  ArrowRight,
  ExternalLink,
  ChevronRight,
  Sliders
} from 'lucide-react';
import { Order, Product, DarkStore } from '../types';

interface EnterpriseOperationsTowerPageProps {
  orders: Order[];
  products: Product[];
  darkStores: DarkStore[];
}

export const EnterpriseOperationsTowerPage: React.FC<EnterpriseOperationsTowerPageProps> = ({
  orders,
  products,
  darkStores,
}) => {
  const [activeDeck, setActiveDeck] = useState<'fulfillment' | 'inventory' | 'merchants_finance' | 'returns_disputes'>('fulfillment');
  const [selectedFacility, setSelectedFacility] = useState<string>('all');
  const [searchTerm, setSearchTerm] = useState<string>('');

  // 1. مركز مراقبة الطلبات المتعثرة (Stalled Orders)
  const [stalledOrders, setStalledOrders] = useState([
    {
      id: 'ORD-8942',
      customer: 'فيصل الشمري',
      city: 'الرياض - النرجس',
      stage: 'packing',
      stalledMinutes: 28,
      reason: 'نقص صنف: ستيك ريب آي أنجوس 400غ',
      hub: 'مستودع الرياض المركزي',
      status: 'action_required',
    },
    {
      id: 'ORD-8947',
      customer: 'سارة المهيري',
      city: 'دبي - المرابع العربية',
      stage: 'driver_assignment',
      stalledMinutes: 19,
      reason: 'عدم استجابة أقرب 3 كباتن توصيل',
      hub: 'دارك ستور دبي مارينا',
      status: 'escalated',
    },
    {
      id: 'ORD-8951',
      customer: 'محمد الكعبي',
      city: 'أبوظبي - جزيرة ياس',
      stage: 'payment_verification',
      stalledMinutes: 35,
      reason: 'تعليق في تأكيد التحويل البنكي B2B',
      hub: 'مستودع أبوظبي اللوجستي',
      status: 'action_required',
    },
  ]);

  // 2. نظام الإنذار المبكر لنفاد المخزون (Stockout Early Warning)
  const [stockoutAlerts, setStockoutAlerts] = useState([
    {
      productId: 'p1',
      name: 'موز فلبيني طازج كافنديش',
      currentStock: 42,
      dailyBurnRate: 65,
      leadTimeDays: 2,
      daysRemaining: 0.6,
      urgency: 'critical', // < 1 day
      suggestedOrderQty: 250,
    },
    {
      productId: 'p4',
      name: 'حليب المراعي كامل الدسم طازج 2 لتر',
      currentStock: 58,
      dailyBurnRate: 40,
      leadTimeDays: 1,
      daysRemaining: 1.45,
      urgency: 'warning',
      suggestedOrderQty: 180,
    },
    {
      productId: 'p11',
      name: 'فيليه سلمون نرويجي طازج فاخر 500غ',
      currentStock: 12,
      dailyBurnRate: 15,
      leadTimeDays: 2,
      daysRemaining: 0.8,
      urgency: 'critical',
      suggestedOrderQty: 60,
    },
  ]);

  // 3. توزيع الطلبات التلقائي (Smart Routing Log)
  const [routingLog] = useState([
    {
      orderId: 'ORD-9021',
      routedTo: 'دارك ستور دبي مارينا',
      score: '98%',
      reason: 'أقرب مسافة (2.1 كم) + توفر 100% للأصناف',
      costSaving: '14.50 ل.س',
      status: 'auto_routed',
    },
    {
      orderId: 'ORD-9020',
      routedTo: 'ملحمة الديب المركزية (تاجر 3P)',
      score: '94%',
      reason: 'طلب لحوم طازجة تتطلب تقطيع وتتبيل فوري',
      costSaving: '8.00 ل.س',
      status: 'merchant_routed',
    },
  ]);

  // 4. كشف فروقات الجرد (Inventory Discrepancy & Reconciliation)
  const [discrepancies, setDiscrepancies] = useState([
    {
      id: 'DISC-104',
      barcode: '62910034291',
      productName: 'زيت زيتون بكر ممتاز 1 لتر',
      systemStock: 140,
      physicalCount: 133,
      varianceQty: -7,
      varianceValue: -245.0,
      location: 'ممر B-04 رف 2',
      reason: 'تلف أثناء النقل الداخلي',
      status: 'pending_review',
    },
    {
      id: 'DISC-105',
      barcode: '62810052309',
      productName: 'شوكولاتة جلاكسي بالبندق عبوة عائلية',
      systemStock: 85,
      physicalCount: 88,
      varianceQty: +3,
      varianceValue: +45.0,
      location: 'ممر C-11 رف 1',
      reason: 'خطأ إدخال سابق في الشحنة الواردة',
      status: 'reconciled',
    },
  ]);

  // 5. إدارة المنتجات الراكدة (Dead Stock / Slow Moving)
  const [deadStockItems] = useState([
    {
      id: 'DS-201',
      name: 'مقلاة شواء جرانيت غير لاصقة 28 سم',
      stockQty: 48,
      daysInactive: 74,
      holdingCostPerMonth: 380,
      actionSuggested: 'تحويل إلى عرض فلاش بخصم 45% أو باقة مع زيت الزيتون',
    },
    {
      id: 'DS-202',
      name: 'معطر جو برائحة العود الملكي 500 مل',
      stockQty: 110,
      daysInactive: 92,
      holdingCostPerMonth: 220,
      actionSuggested: 'إضافته كهدية مجانية للطلبات فوق 250 ل.س لتفريغ المساحة',
    },
  ]);

  // 8. مراقبة التزام التجار (Merchant SLA)
  const [merchantsSla] = useState([
    {
      name: 'ملحمة البركة الحلال',
      avgPrepMinutes: 14,
      targetPrepMinutes: 15,
      cancelRate: '0.8%',
      fulfillmentRate: '99.2%',
      status: 'excellent',
    },
    {
      name: 'مخبز الأرياف الدمشقي',
      avgPrepMinutes: 26,
      targetPrepMinutes: 20,
      cancelRate: '4.2%',
      fulfillmentRate: '92.1%',
      status: 'warning', // high cancel rate
    },
    {
      name: 'أسماك الخليج الطازجة',
      avgPrepMinutes: 18,
      targetPrepMinutes: 20,
      cancelRate: '1.2%',
      fulfillmentRate: '98.5%',
      status: 'good',
    },
  ]);

  // 9. إدارة الشحنات المتأخرة (Delayed Deliveries Escalation)
  const [delayedDeliveries] = useState([
    {
      shipmentId: 'SHP-491',
      courier: 'عمر التميمي (دراجة 12)',
      orderId: 'ORD-8911',
      destination: 'دبي - البرشاء جنوب',
      originalEta: '14:15',
      delayMinutes: 24,
      priority: 'high',
      compensated: false,
    },
    {
      shipmentId: 'SHP-493',
      courier: 'أحمد جلال (فان مبرد 04)',
      orderId: 'ORD-8924',
      destination: 'الرياض - الياسمين',
      originalEta: '14:30',
      delayMinutes: 12,
      priority: 'medium',
      compensated: true,
    },
  ]);

  // 10. تجميع الطلبات حسب المنطقة (Zone-Based Batching)
  const [zoneBatches] = useState([
    {
      zone: 'دبي مارينا وJBR (المربع A4)',
      ordersCount: 6,
      assignedCourier: 'خالد المنصوري (فان كهربائي)',
      totalDistanceKm: 4.8,
      fuelSavedPercent: '46%',
      status: 'dispatched',
    },
    {
      zone: 'الرياض - النرجس والعارض (المربع N2)',
      ordersCount: 8,
      assignedCourier: 'سالم الدوسري',
      totalDistanceKm: 7.2,
      fuelSavedPercent: '52%',
      status: 'loading',
    },
  ]);

  // 11. تسوية حسابات التجار (Settlement & Reconciliation)
  const [merchantSettlements] = useState([
    {
      merchant: 'ملحمة البركة الحلال',
      period: '21 - 28 أكتوبر 2026',
      totalOrders: 142,
      grossSales: 16840.0,
      commissionDeducted: 1684.0, // 10%
      returnsDeducted: 220.0,
      netPayable: 14936.0,
      reconciliationStatus: 'matched',
    },
    {
      merchant: 'مخبز الأرياف الدمشقي',
      period: '21 - 28 أكتوبر 2026',
      totalOrders: 98,
      grossSales: 6420.0,
      commissionDeducted: 770.4, // 12%
      returnsDeducted: 140.0,
      netPayable: 5509.6,
      reconciliationStatus: 'matched',
    },
  ]);

  // 12. كشف العمليات المالية المكررة (Duplicate Financial Transactions)
  const [duplicateAlerts, setDuplicateAlerts] = useState([
    {
      id: 'DUP-089',
      reference: 'TXN-99812-B',
      customer: 'عبدالله القحطاني',
      amount: 245.50,
      detectedAt: 'قبل 18 دقيقة',
      type: 'دفع مكرر خلال 45 ثانية بنفس رقم البطاقة',
      actionTaken: 'تجميد العملية الثانية ورد المبلغ تلقائياً',
      status: 'auto_refunded',
    },
  ]);

  // 13. إدارة الديون والائتمان (Merchant Credit & Debt)
  const [merchantCreditLimits] = useState([
    {
      merchant: 'مزارع الصباح العضوية',
      creditLimit: 50000.0,
      currentDebt: 34200.0,
      utilization: '68%',
      dueDate: '05 نوفمبر 2026',
      status: 'healthy',
    },
    {
      merchant: 'شركة تموين الشرق الأوسط',
      creditLimit: 80000.0,
      currentDebt: 78500.0,
      utilization: '98%',
      dueDate: 'متأخر 3 أيام!',
      status: 'limit_warning',
    },
  ]);

  // 14. توزيع المخزون بين المستودعات (Inter-Warehouse Transfers)
  const [transferSuggestions] = useState([
    {
      productId: 'p8',
      productName: 'مياه العين كرتون (24 × 500مل)',
      fromHub: 'مستودع دبي المركزي (فائض 450 كرتون)',
      toHub: 'دارك ستور مارينا (متبقي 20 كرتون)',
      suggestedQty: 150,
      urgency: 'high',
    },
    {
      productId: 'p9',
      productName: 'مسحوق غسيل تايد 5 كجم',
      fromHub: 'مستودع الرياض الشمالي (فائض 180 كيس)',
      toHub: 'دارك ستور السليمانية (متبقي 8 أكياس)',
      suggestedQty: 60,
      urgency: 'medium',
    },
  ]);

  // 15. نظام حجز المخزون المؤقت (Temporary Stock Reservation TTL)
  const [activeStockReservations] = useState([
    {
      orderId: 'ORD-9024',
      customer: 'ريم الظاهري',
      itemsCount: 4,
      reservedAt: '14:48',
      ttlMinutesRemaining: 4,
      status: 'held_in_checkout',
    },
    {
      orderId: 'ORD-9025',
      customer: 'وليد الغامدي',
      itemsCount: 7,
      reservedAt: '14:51',
      ttlMinutesRemaining: 7,
      status: 'held_in_checkout',
    },
  ]);

  // 16. إدارة تواريخ الصلاحية (FEFO & Spoilage Alert)
  const [expiryAlerts] = useState([
    {
      productId: 'p4',
      productName: 'حليب المراعي كامل الدسم طازج',
      batchNo: 'B-7729',
      quantity: 34,
      daysToExpiry: 2,
      fefoAction: 'توجيه فوري لركن Zero Waste بخصم 50% لمنع التلف',
      urgency: 'critical',
    },
    {
      productId: 'p13',
      productName: 'بيض مزارع عضوي كرتون 30 حبة',
      batchNo: 'B-8104',
      quantity: 50,
      daysToExpiry: 4,
      fefoAction: 'أولوية الصرف الأولى في موجات الطلبات الحالية',
      urgency: 'warning',
    },
  ]);

  // 17. مراقبة جودة التغليف والتجهيز (Packaging & QA Auditing)
  const [packagingQaScorecard] = useState([
    {
      pickerName: 'أحمد فؤاد',
      hub: 'دارك ستور مارينا',
      auditedOrders: 180,
      packagingErrors: 1,
      accuracyRate: '99.4%',
      errorType: 'عدم وضع عازل تبريد مع الزبادي',
    },
    {
      pickerName: 'طارق الزهراني',
      hub: 'مستودع الرياض',
      auditedOrders: 140,
      packagingErrors: 4,
      accuracyRate: '97.1%',
      errorType: 'وضع خضار طرية تحت معلبات ثقيلة',
    },
  ]);

  // 18. نظام معالجة المرتجعات اللوجستية (RMA Processing)
  const [rmaList, setRmaList] = useState([
    {
      rmaId: 'RMA-501',
      orderId: 'ORD-8820',
      customer: 'عادل السعدي',
      product: 'شاحن سيارة أصلي',
      reason: 'العميل استلم طراز غير مطابق',
      itemCondition: 'سليم في الكرتون الأصلي',
      action: 'إعادة المخزون + تعويض العميل بكوبون 20 ل.س',
      status: 'restocked',
    },
    {
      rmaId: 'RMA-502',
      orderId: 'ORD-8834',
      customer: 'نوف العنزي',
      product: 'فراولة مزارع مستوردة',
      reason: 'تلف الرطوبة أثناء التوصيل',
      itemCondition: 'تالف - غير صالح',
      action: 'إتلاف رسمي + استرداد فوري للبطاقة + خصم من الكوريير',
      status: 'disposed',
    },
  ]);

  // 19. تحديد الطاقة الاستيعابية للمستودعات (Warehouse Throughput Throttling)
  const [warehouseCapacities] = useState([
    {
      hubName: 'دارك ستور دبي مارينا',
      currentOrdersPerHour: 118,
      maxCapacityPerHour: 120,
      loadPercent: 98,
      status: 'throttled', // Auto throttled to avoid delays
      actionActive: 'تم تمديد نافذة التوصيل مؤقتاً إلى 25 دقيقة وتحويل الفائض لأقرب فرع',
    },
    {
      hubName: 'مستودع الرياض المركزي',
      currentOrdersPerHour: 140,
      maxCapacityPerHour: 220,
      loadPercent: 64,
      status: 'optimal',
      actionActive: 'يعمل بكفاءة تامة وطاقة استيعاب جاهزة',
    },
    {
      hubName: 'دارك ستور أبوظبي البطين',
      currentOrdersPerHour: 82,
      maxCapacityPerHour: 100,
      loadPercent: 82,
      status: 'busy',
      actionActive: 'إرسال تنبيه لفريق الفرز لتسريع الموجات',
    },
  ]);

  // 20. مركز متابعة الشكاوى والنزاعات (Dispute Attribution Center)
  const [disputes, setDisputes] = useState([
    {
      ticketId: 'DSP-301',
      orderId: 'ORD-8871',
      customer: 'حمد المزروعي',
      issue: 'وصول كرتون البيض مكسوراً ونقص كيس خبز',
      blameAttribution: 'مسؤولية الكابتن (سوء قيادة وعدم تثبيت السلة)',
      vendor: 'مزارع الديب',
      courier: 'عثمان عبدربه',
      resolution: 'تعويض العميل 45 ل.س فوري + خصم 15 ل.س من مستحقات الكابتن',
      status: 'resolved',
    },
    {
      ticketId: 'DSP-302',
      orderId: 'ORD-8899',
      customer: 'سلطان الدوسري',
      issue: 'لحم العجل وصل مقطع خشن وليس مفروم ناعم كما في الملاحظات',
      blameAttribution: 'مسؤولية التاجر (تجاهل ملاحظات التقطيع)',
      vendor: 'ملحمة البركة',
      courier: 'ماجد العتيبي',
      resolution: 'إعادة إرسال طلب بديل مجاناً على نفقة الملحمة',
      status: 'in_progress',
    },
  ]);

  const handleResolveStalled = (orderId: string, actionText: string) => {
    setStalledOrders((prev) => prev.filter((o) => o.id !== orderId));
    alert(`✓ تم بنجاح اتخاذ الإجراء على الطلب ${orderId}: ${actionText}`);
  };

  return (
    <div className="space-y-6">
      {/* 1. Header Banner & Operations Command Tower Bar */}
      <div className="bg-gradient-to-r from-slate-900 via-indigo-950 to-slate-900 text-white p-6 rounded-2xl shadow-xl border border-indigo-800/40">
        <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
          <div className="flex items-center gap-4">
            <div className="p-3 bg-indigo-600/30 rounded-xl border border-indigo-400/40 text-indigo-400">
              <TowerControl className="w-8 h-8 animate-pulse text-indigo-300" />
            </div>
            <div>
              <div className="flex items-center gap-3">
                <h1 className="text-2xl font-black">برج مراقبة العمليات وسلسلة الإمداد الذكية (Enterprise Operations Tower)</h1>
                <span className="px-3 py-1 bg-emerald-500/20 text-emerald-400 border border-emerald-500/30 rounded-full text-xs font-bold">
                  20 نظام تشغيلي نشط
                </span>
              </div>
              <p className="text-sm text-slate-300 mt-1">
                نظام الرقابة الآلية اللحظي للطلبات، الذكاء التنبؤي للمخزون، امتثال التجار، التسويات المالية، ومنع الأخطاء التشغيلية.
              </p>
            </div>
          </div>
          <div className="flex items-center gap-3">
            <button 
              onClick={() => alert('جاري تشغيل خوارزميات التدقيق الشامل لكافة العمليات... تم التحقق!')}
              className="flex items-center gap-2 px-4 py-2.5 bg-indigo-600 hover:bg-indigo-500 text-white rounded-xl text-xs font-bold transition shadow-md"
            >
              <RefreshCw className="w-4 h-4" />
              تشغيل فحص النظام الشامل
            </button>
          </div>
        </div>

        {/* Real-Time Pulse Metric Cards */}
        <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-3 mt-6 pt-6 border-t border-slate-800">
          <div className="bg-slate-800/60 p-3 rounded-xl border border-slate-700">
            <div className="text-xs text-rose-400 font-bold flex items-center gap-1.5">
              <AlertTriangle className="w-3.5 h-3.5" /> طلبات متعثرة
            </div>
            <div className="text-xl font-black mt-1 text-white">{stalledOrders.length} طلبات</div>
            <div className="text-[10px] text-slate-400">تحتاج تدخل فوري</div>
          </div>

          <div className="bg-slate-800/60 p-3 rounded-xl border border-slate-700">
            <div className="text-xs text-amber-400 font-bold flex items-center gap-1.5">
              <TrendingDown className="w-3.5 h-3.5" /> إنذار نفاد مخزون
            </div>
            <div className="text-xl font-black mt-1 text-white">{stockoutAlerts.length} أصناف</div>
            <div className="text-[10px] text-slate-400">&lt; 48 ساعة حتى النفاد</div>
          </div>

          <div className="bg-slate-800/60 p-3 rounded-xl border border-slate-700">
            <div className="text-xs text-cyan-400 font-bold flex items-center gap-1.5">
              <Gauge className="w-3.5 h-3.5" /> كبح الطاقة (Throttling)
            </div>
            <div className="text-xl font-black mt-1 text-white">98% مارينا</div>
            <div className="text-[10px] text-slate-400">حماية الجودة مفعلة</div>
          </div>

          <div className="bg-slate-800/60 p-3 rounded-xl border border-slate-700">
            <div className="text-xs text-emerald-400 font-bold flex items-center gap-1.5">
              <ShieldAlert className="w-3.5 h-3.5" /> منع البيع الزائد
            </div>
            <div className="text-xl font-black mt-1 text-white">100% Locked</div>
            <div className="text-[10px] text-slate-400">قفل المخزون الصلب</div>
          </div>

          <div className="bg-slate-800/60 p-3 rounded-xl border border-slate-700">
            <div className="text-xs text-indigo-400 font-bold flex items-center gap-1.5">
              <Clock className="w-3.5 h-3.5" /> حجز مؤقت (TTL)
            </div>
            <div className="text-xl font-black mt-1 text-white">{activeStockReservations.length} سلات</div>
            <div className="text-[10px] text-slate-400">مهلة 10 دقائق</div>
          </div>

          <div className="bg-slate-800/60 p-3 rounded-xl border border-slate-700">
            <div className="text-xs text-purple-400 font-bold flex items-center gap-1.5">
              <DollarSign className="w-3.5 h-3.5" /> تسويات التجار
            </div>
            <div className="text-xl font-black mt-1 text-white">20,445 ل.س</div>
            <div className="text-[10px] text-slate-400">مطابقة بدون فروقات</div>
          </div>
        </div>
      </div>

      {/* 2. Command Deck Navigation Tabs */}
      <div className="flex border-b border-gray-200 bg-white px-4 pt-2 rounded-xl shadow-sm gap-2">
        <button
          onClick={() => setActiveDeck('fulfillment')}
          className={`flex items-center gap-2 pb-3 px-4 text-sm font-bold border-b-2 transition ${
            activeDeck === 'fulfillment'
              ? 'border-indigo-600 text-indigo-600'
              : 'border-transparent text-gray-500 hover:text-gray-900'
          }`}
        >
          <Truck className="w-4 h-4" />
          مراقبة الطلبات والشحنات والفرز (1, 3, 9, 10, 17, 19)
        </button>

        <button
          onClick={() => setActiveDeck('inventory')}
          className={`flex items-center gap-2 pb-3 px-4 text-sm font-bold border-b-2 transition ${
            activeDeck === 'inventory'
              ? 'border-indigo-600 text-indigo-600'
              : 'border-transparent text-gray-500 hover:text-gray-900'
          }`}
        >
          <Boxes className="w-4 h-4" />
          إدارة المخزون الذكي والجرد والتوريد (2, 4, 5, 6, 7, 14, 15, 16)
        </button>

        <button
          onClick={() => setActiveDeck('merchants_finance')}
          className={`flex items-center gap-2 pb-3 px-4 text-sm font-bold border-b-2 transition ${
            activeDeck === 'merchants_finance'
              ? 'border-indigo-600 text-indigo-600'
              : 'border-transparent text-gray-500 hover:text-gray-900'
          }`}
        >
          <DollarSign className="w-4 h-4" />
          التزام التجار والتسويات المالية (8, 11, 12, 13)
        </button>

        <button
          onClick={() => setActiveDeck('returns_disputes')}
          className={`flex items-center gap-2 pb-3 px-4 text-sm font-bold border-b-2 transition ${
            activeDeck === 'returns_disputes'
              ? 'border-indigo-600 text-indigo-600'
              : 'border-transparent text-gray-500 hover:text-gray-900'
          }`}
        >
          <RotateCcw className="w-4 h-4" />
          المرتجعات والنزاعات وتحديد المسؤولية (18, 20)
        </button>
      </div>

      {/* ========================================================================= */}
      {/* DECK 1: FULFILLMENT & ORDERS FLOW */}
      {/* ========================================================================= */}
      {activeDeck === 'fulfillment' && (
        <div className="space-y-6">
          {/* Section 1: مركز مراقبة الطلبات المتعثرة */}
          <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-200">
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-3">
                <div className="p-2 bg-rose-50 text-rose-600 rounded-lg">
                  <AlertTriangle className="w-5 h-5" />
                </div>
                <div>
                  <h2 className="text-lg font-black text-gray-900">1. مركز مراقبة الطلبات المتعثرة (Stalled Orders Center)</h2>
                  <p className="text-xs text-gray-500">رصد آلي للطلبات المتوقفة في أي مرحلة تشغيلية وتتطلب تدخلاً فورياً لمنع تأخير العميل.</p>
                </div>
              </div>
              <span className="px-3 py-1 bg-rose-100 text-rose-700 text-xs font-bold rounded-full">
                {stalledOrders.length} طلبات تحتاج تدخل
              </span>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-right text-xs">
                <thead className="bg-gray-50 text-gray-500 font-bold border-y border-gray-200">
                  <tr>
                    <th className="py-3 px-4">رقم الطلب</th>
                    <th className="py-3 px-4">العميل والمنطقة</th>
                    <th className="py-3 px-4">مرحلة التوقف</th>
                    <th className="py-3 px-4">زمن التعثر</th>
                    <th className="py-3 px-4">سبب التعثر الفعلي</th>
                    <th className="py-3 px-4">المركز اللوجستي</th>
                    <th className="py-3 px-4 text-center">إجراءات التدخل الفوري</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100">
                  {stalledOrders.map((ord) => (
                    <tr key={ord.id} className="hover:bg-rose-50/40 transition">
                      <td className="py-3.5 px-4 font-mono font-bold text-gray-900">{ord.id}</td>
                      <td className="py-3.5 px-4">
                        <div className="font-bold text-gray-900">{ord.customer}</div>
                        <div className="text-[11px] text-gray-400">{ord.city}</div>
                      </td>
                      <td className="py-3.5 px-4">
                        <span className="px-2.5 py-1 bg-amber-100 text-amber-800 rounded-md font-bold">
                          {ord.stage}
                        </span>
                      </td>
                      <td className="py-3.5 px-4 font-bold text-rose-600">
                        {ord.stalledMinutes} دقيقة متوقفة
                      </td>
                      <td className="py-3.5 px-4 text-gray-700 max-w-xs">{ord.reason}</td>
                      <td className="py-3.5 px-4 text-gray-500">{ord.hub}</td>
                      <td className="py-3.5 px-4 text-center">
                        <div className="flex items-center justify-center gap-1.5">
                          <button
                            onClick={() => handleResolveStalled(ord.id, 'تم توجيه صنف بديل معتمد')}
                            className="px-2.5 py-1.5 bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg text-[11px] font-bold"
                          >
                            تبديل صنف
                          </button>
                          <button
                            onClick={() => handleResolveStalled(ord.id, 'تم تعيين كابتن طوارئ إكسبريس')}
                            className="px-2.5 py-1.5 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg text-[11px] font-bold"
                          >
                            كابتن طوارئ
                          </button>
                          <button
                            onClick={() => handleResolveStalled(ord.id, 'تم التواصل بالعميل وتقديم كوبون 15 ل.س اعتذاري')}
                            className="p-1.5 bg-gray-100 hover:bg-gray-200 text-gray-700 rounded-lg"
                            title="اتصال بالعميل"
                          >
                            <Phone className="w-3.5 h-3.5" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>

          {/* Section 3 & 10: التوزيع التلقائي للطلبات وتجميع المناطق */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* 3. توزيع الطلبات التلقائي */}
            <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-200">
              <div className="flex items-center justify-between mb-4">
                <div className="flex items-center gap-3">
                  <div className="p-2 bg-indigo-50 text-indigo-600 rounded-lg">
                    <Sliders className="w-5 h-5" />
                  </div>
                  <div>
                    <h3 className="text-base font-black text-gray-900">3. توزيع الطلبات التلقائي (Smart Routing Engine)</h3>
                    <p className="text-xs text-gray-500">خوارزمية ذكية لاختيار المستودع أو التاجر الأنسب حسب التوفر والتكلفة والمسافة.</p>
                  </div>
                </div>
                <span className="px-2.5 py-1 bg-emerald-100 text-emerald-800 text-[11px] font-bold rounded-full">
                  Auto-Routing: نشط 100%
                </span>
              </div>

              <div className="space-y-3">
                {routingLog.map((r, i) => (
                  <div key={i} className="p-3.5 rounded-xl border border-gray-100 bg-gray-50/70 hover:bg-white hover:shadow-sm transition">
                    <div className="flex items-center justify-between">
                      <span className="font-mono font-bold text-gray-900">{r.orderId}</span>
                      <span className="text-xs font-bold text-emerald-600 bg-emerald-50 px-2 py-0.5 rounded border border-emerald-200">
                        كفاءة التوجيه {r.score}
                      </span>
                    </div>
                    <div className="text-xs font-bold text-indigo-700 mt-1.5">
                      تم التوجيه إلى: {r.routedTo}
                    </div>
                    <div className="text-[11px] text-gray-500 mt-0.5">{r.reason}</div>
                    <div className="text-[11px] text-gray-400 mt-1">وفر في التكلفة التشغيلية: {r.costSaving}</div>
                  </div>
                ))}
              </div>
            </div>

            {/* 10. تجميع الطلبات حسب المنطقة */}
            <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-200">
              <div className="flex items-center justify-between mb-4">
                <div className="flex items-center gap-3">
                  <div className="p-2 bg-emerald-50 text-emerald-600 rounded-lg">
                    <Truck className="w-5 h-5" />
                  </div>
                  <div>
                    <h3 className="text-base font-black text-gray-900">10. تجميع الطلبات حسب المنطقة (Zone Batching)</h3>
                    <p className="text-xs text-gray-500">دمج طلبات الحي المتقاربة في رحلة واحدة لتقليل رحلات التوصيل واستهلاك الوقود.</p>
                  </div>
                </div>
                <span className="px-2.5 py-1 bg-emerald-100 text-emerald-800 text-[11px] font-bold rounded-full">
                  وفر 48% في المسارات
                </span>
              </div>

              <div className="space-y-3">
                {zoneBatches.map((b, i) => (
                  <div key={i} className="p-3.5 rounded-xl border border-gray-100 bg-gray-50/70">
                    <div className="flex items-center justify-between">
                      <span className="font-bold text-gray-900 text-xs">{b.zone}</span>
                      <span className="px-2 py-0.5 bg-blue-100 text-blue-800 rounded text-[11px] font-bold">
                        {b.ordersCount} طلبات مجمعة
                      </span>
                    </div>
                    <div className="text-xs text-gray-600 mt-1">الكابتن المكلف: {b.assignedCourier}</div>
                    <div className="flex items-center justify-between mt-2 pt-2 border-t border-gray-200/60 text-[11px]">
                      <span className="text-gray-500">إجمالي مسار الدفعة: {b.totalDistanceKm} كم</span>
                      <span className="font-bold text-emerald-600">وفر الوقود: {b.fuelSavedPercent}</span>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* Section 9, 17, 19: إدارة الشحنات المتأخرة، مراقبة الجودة، وطاقة المستودعات */}
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            {/* 9. إدارة الشحنات المتأخرة */}
            <div className="bg-white rounded-2xl p-5 shadow-sm border border-gray-200">
              <div className="flex items-center gap-2.5 mb-3">
                <Clock className="w-5 h-5 text-rose-600" />
                <h4 className="font-black text-gray-900 text-sm">9. الشحنات المتأخرة وترتيب الأولويات</h4>
              </div>
              <p className="text-[11px] text-gray-500 mb-3">رصد الشحنات التي تجاوزت ETA مع تعويض العميل تلقائياً.</p>
              <div className="space-y-2.5">
                {delayedDeliveries.map((d, i) => (
                  <div key={i} className="p-3 rounded-lg border border-rose-100 bg-rose-50/40 text-xs">
                    <div className="flex justify-between font-bold">
                      <span className="font-mono text-gray-900">{d.shipmentId}</span>
                      <span className="text-rose-600">+{d.delayMinutes} دقيقة تأخير</span>
                    </div>
                    <div className="text-gray-600 mt-1">{d.courier} • {d.destination}</div>
                    <div className="mt-2 flex items-center justify-between">
                      <span className={`px-2 py-0.5 rounded text-[10px] font-bold ${
                        d.compensated ? 'bg-emerald-100 text-emerald-800' : 'bg-amber-100 text-amber-800'
                      }`}>
                        {d.compensated ? '✓ تم تعويض العميل' : 'بانتظار التعويض'}
                      </span>
                      {!d.compensated && (
                        <button
                          onClick={() => alert(`تم إيداع 20 ل.س في محفظة العميل للطلب ${d.orderId} كاعتذار عن التأخير`)}
                          className="px-2 py-1 bg-indigo-600 text-white rounded text-[10px] font-bold"
                        >
                          تعويض فوري
                        </button>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* 17. مراقبة جودة التغليف والتجهيز */}
            <div className="bg-white rounded-2xl p-5 shadow-sm border border-gray-200">
              <div className="flex items-center gap-2.5 mb-3">
                <PackageCheck className="w-5 h-5 text-indigo-600" />
                <h4 className="font-black text-gray-900 text-sm">17. مراقبة جودة التغليف والتجهيز (QA)</h4>
              </div>
              <p className="text-[11px] text-gray-500 mb-3">سجل أخطاء التجهيز والتغليف لكل موظف ونظام تصحيح الأداء.</p>
              <div className="space-y-2.5">
                {packagingQaScorecard.map((q, i) => (
                  <div key={i} className="p-3 rounded-lg border border-gray-100 bg-gray-50 text-xs">
                    <div className="flex justify-between font-bold">
                      <span className="text-gray-900">{q.pickerName}</span>
                      <span className="text-emerald-600">{q.accuracyRate} دقة</span>
                    </div>
                    <div className="text-[11px] text-gray-500 mt-0.5">{q.hub} ({q.auditedOrders} طلب مفحوص)</div>
                    <div className="text-[11px] text-rose-600 mt-1 bg-rose-50 p-1.5 rounded">
                      آخر خطأ: {q.errorType}
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* 19. تحديد الطاقة الاستيعابية للمستودعات */}
            <div className="bg-white rounded-2xl p-5 shadow-sm border border-gray-200">
              <div className="flex items-center gap-2.5 mb-3">
                <Gauge className="w-5 h-5 text-amber-600" />
                <h4 className="font-black text-gray-900 text-sm">19. سعة المستودعات والكبح التلقائي</h4>
              </div>
              <p className="text-[11px] text-gray-500 mb-3">منع استقبال طلبات تفوق قدرة المستودع مع كبح وتحويل فوري.</p>
              <div className="space-y-2.5">
                {warehouseCapacities.map((w, i) => (
                  <div key={i} className="p-3 rounded-lg border border-gray-100 bg-gray-50 text-xs">
                    <div className="flex justify-between font-bold">
                      <span className="text-gray-900">{w.hubName}</span>
                      <span className={w.loadPercent >= 90 ? 'text-rose-600' : 'text-emerald-600'}>
                        {w.loadPercent}% حمل
                      </span>
                    </div>
                    <div className="w-full bg-gray-200 h-2 rounded-full mt-2 overflow-hidden">
                      <div 
                        className={`h-full ${w.loadPercent >= 90 ? 'bg-rose-500' : 'bg-emerald-500'}`} 
                        style={{ width: `${w.loadPercent}%` }}
                      />
                    </div>
                    <div className="text-[10px] text-gray-500 mt-1.5">{w.actionActive}</div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      )}

      {/* ========================================================================= */}
      {/* DECK 2: INVENTORY INTELLIGENCE & STOCK CONTROL */}
      {/* ========================================================================= */}
      {activeDeck === 'inventory' && (
        <div className="space-y-6">
          {/* Section 2: نظام الإنذار المبكر لنفاد المخزون */}
          <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-200">
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-3">
                <div className="p-2 bg-amber-50 text-amber-600 rounded-lg">
                  <TrendingDown className="w-5 h-5" />
                </div>
                <div>
                  <h2 className="text-lg font-black text-gray-900">2. نظام الإنذار المبكر لنفاد المخزون (Stockout Early Warning)</h2>
                  <p className="text-xs text-gray-500">تنبيه ذكي قبل نفاد المنتج بناءً على معدل الاستهلاك اليومي (Burn Rate) ومهلة التوريد (Lead Time).</p>
                </div>
              </div>
              <span className="px-3 py-1 bg-rose-100 text-rose-700 text-xs font-bold rounded-full">
                {stockoutAlerts.length} منتجات في خطر النفاد
              </span>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-right text-xs">
                <thead className="bg-gray-50 text-gray-500 font-bold border-y border-gray-200">
                  <tr>
                    <th className="py-3 px-4">اسم المنتج</th>
                    <th className="py-3 px-4">المخزون الحالي</th>
                    <th className="py-3 px-4">معدل الاستهلاك/يوم</th>
                    <th className="py-3 px-4">مهلة التوريد</th>
                    <th className="py-3 px-4">الوقت المتبقي حتى النفاد</th>
                    <th className="py-3 px-4">الكمية المقترحة للطلب</th>
                    <th className="py-3 px-4 text-center">إجراء أمر الشراء (PO)</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100">
                  {stockoutAlerts.map((s) => (
                    <tr key={s.productId} className="hover:bg-amber-50/30 transition">
                      <td className="py-3.5 px-4 font-bold text-gray-900">{s.name}</td>
                      <td className="py-3.5 px-4 font-bold text-gray-900">{s.currentStock} قطعة</td>
                      <td className="py-3.5 px-4 text-gray-600">{s.dailyBurnRate} قطعة/يوم</td>
                      <td className="py-3.5 px-4 text-gray-600">{s.leadTimeDays} أيام</td>
                      <td className="py-3.5 px-4">
                        <span className="px-2.5 py-1 bg-rose-100 text-rose-700 rounded-md font-bold">
                          متبقي {s.daysRemaining} يوم فقط!
                        </span>
                      </td>
                      <td className="py-3.5 px-4 font-bold text-indigo-600">+{s.suggestedOrderQty} قطعة</td>
                      <td className="py-3.5 px-4 text-center">
                        <button
                          onClick={() => alert(`تم إنشاء أمر شراء إلكتروني فوري لـ ${s.name} بالكمية ${s.suggestedOrderQty} وإرساله للمورد معتمد!`)}
                          className="px-3 py-1.5 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg text-[11px] font-bold shadow-sm"
                        >
                          توليد أمر شراء فوري (PO)
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>

          {/* Section 4 & 5: كشف فروقات الجرد والمنتجات الراكدة */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* 4. كشف فروقات الجرد والمطابقة */}
            <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-200">
              <div className="flex items-center justify-between mb-4">
                <div className="flex items-center gap-3">
                  <div className="p-2 bg-purple-50 text-purple-600 rounded-lg">
                    <FileText className="w-5 h-5" />
                  </div>
                  <div>
                    <h3 className="text-base font-black text-gray-900">4. كشف فروقات الجرد والمطابقة (Inventory Audit)</h3>
                    <p className="text-xs text-gray-500">مقارنة الكميات الفعلية بالمسجلة وتحديد الأصناف التي تحتاج مراجعة أو تسوية.</p>
                  </div>
                </div>
              </div>

              <div className="space-y-3">
                {discrepancies.map((d) => (
                  <div key={d.id} className="p-3.5 rounded-xl border border-gray-200 bg-gray-50/70 text-xs">
                    <div className="flex justify-between items-center font-bold">
                      <span className="text-gray-900">{d.productName}</span>
                      <span className={`px-2 py-0.5 rounded text-[11px] ${d.varianceQty < 0 ? 'bg-rose-100 text-rose-700' : 'bg-emerald-100 text-emerald-700'}`}>
                        فارق: {d.varianceQty} قطعة ({d.varianceValue} ل.س)
                      </span>
                    </div>
                    <div className="text-gray-500 text-[11px] mt-1">الباركود: {d.barcode} • الموقع: {d.location}</div>
                    <div className="text-gray-700 mt-1 font-medium">السبب المسجل: {d.reason}</div>
                    <div className="mt-2.5 pt-2 border-t border-gray-200 flex justify-end gap-2">
                      <button
                        onClick={() => alert(`تمت تسوية الفارق للصنف ${d.productName} وتسجيل محضر جرد رسمي`)}
                        className="px-2.5 py-1 bg-purple-600 hover:bg-purple-700 text-white rounded text-[11px] font-bold"
                      >
                        اعتماد التسوية المحاسبية
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* 5. إدارة المنتجات الراكدة وتصريفها */}
            <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-200">
              <div className="flex items-center justify-between mb-4">
                <div className="flex items-center gap-3">
                  <div className="p-2 bg-rose-50 text-rose-600 rounded-lg">
                    <Boxes className="w-5 h-5" />
                  </div>
                  <div>
                    <h3 className="text-base font-black text-gray-900">5. إدارة المنتجات الراكدة (Dead Stock Clearance)</h3>
                    <p className="text-xs text-gray-500">اكتشاف الأصناف التي لم تتحرك منذ فترة طويلة واقتراح حلول تصريف فورية.</p>
                  </div>
                </div>
              </div>

              <div className="space-y-3">
                {deadStockItems.map((ds) => (
                  <div key={ds.id} className="p-3.5 rounded-xl border border-gray-200 bg-gray-50/70 text-xs">
                    <div className="flex justify-between items-center font-bold">
                      <span className="text-gray-900">{ds.name}</span>
                      <span className="px-2 py-0.5 bg-rose-100 text-rose-800 rounded font-bold text-[11px]">
                        راكد منذ {ds.daysInactive} يوم
                      </span>
                    </div>
                    <div className="text-gray-500 text-[11px] mt-1">الكمية المحبوسة: {ds.stockQty} قطعة • تكلفة الاحتفاظ: {ds.holdingCostPerMonth} ل.س/شهر</div>
                    <div className="text-indigo-700 font-bold mt-1.5 text-[11px] bg-indigo-50 p-2 rounded-lg">
                      💡 الإجراء المقترح: {ds.actionSuggested}
                    </div>
                    <div className="mt-2.5 flex justify-end gap-2">
                      <button
                        onClick={() => alert(`تم نقل ${ds.name} تلقائياً إلى عروض الفلاش بخصم 45%!`)}
                        className="px-2.5 py-1 bg-rose-600 hover:bg-rose-700 text-white rounded text-[11px] font-bold"
                      >
                        تطبيق صفقة فلاش فوراً
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* Section 6, 7, 14, 15, 16: ميزات المخزون الصلبة والمناقلات والصلاحيات */}
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            {/* 6 & 15. منع البيع فوق المخزون وحجز السلات */}
            <div className="bg-white rounded-2xl p-5 shadow-sm border border-gray-200">
              <div className="flex items-center gap-2.5 mb-3">
                <ShieldAlert className="w-5 h-5 text-emerald-600" />
                <h4 className="font-black text-gray-900 text-sm">6 & 15. قفل المخزون والحجز المؤقت (TTL)</h4>
              </div>
              <p className="text-[11px] text-gray-500 mb-3">حجز المخزون لمدة 10 دقائق أثناء الدفع ومنع أي بيع فوق الكمية المتاحة.</p>
              <div className="p-3 bg-emerald-50 rounded-xl border border-emerald-200 mb-3 text-xs">
                <div className="font-bold text-emerald-800 flex items-center gap-1.5">
                  <CheckCircle2 className="w-4 h-4 text-emerald-600" /> Hard Stock Lock: مفعّل 100%
                </div>
                <div className="text-[11px] text-emerald-700 mt-1">
                  تم حظر 18 محاولة بيع فوق المخزون اليوم بنجاح وحماية سلاسة التنفيذ.
                </div>
              </div>
              <div className="space-y-2">
                <div className="text-[11px] font-bold text-gray-700">السلات المحجوزة حالياً (TTL Reservations):</div>
                {activeStockReservations.map((r, i) => (
                  <div key={i} className="p-2.5 rounded-lg border border-gray-100 bg-gray-50 text-xs flex justify-between items-center">
                    <div>
                      <span className="font-bold text-gray-900">{r.orderId}</span> ({r.customer})
                      <div className="text-[10px] text-gray-400">{r.itemsCount} أصناف محجوزة</div>
                    </div>
                    <span className="font-mono text-indigo-600 font-bold bg-indigo-50 px-2 py-1 rounded">
                      متبقي {r.ttlMinutesRemaining} د
                    </span>
                  </div>
                ))}
              </div>
            </div>

            {/* 14. توزيع ومناقلة المخزون بين المستودعات */}
            <div className="bg-white rounded-2xl p-5 shadow-sm border border-gray-200">
              <div className="flex items-center gap-2.5 mb-3">
                <ArrowLeftRight className="w-5 h-5 text-indigo-600" />
                <h4 className="font-black text-gray-900 text-sm">14. موازنة ونقل المخزون بين الفروع</h4>
              </div>
              <p className="text-[11px] text-gray-500 mb-3">اقتراح نقل الأصناف من المستودع الفائض إلى المستودع الذي يعاني من شح.</p>
              <div className="space-y-2.5">
                {transferSuggestions.map((t, i) => (
                  <div key={i} className="p-3 rounded-lg border border-indigo-100 bg-indigo-50/40 text-xs">
                    <div className="font-bold text-gray-900">{t.productName}</div>
                    <div className="text-[11px] text-gray-600 mt-1">من: {t.fromHub}</div>
                    <div className="text-[11px] text-gray-600">إلى: {t.toHub}</div>
                    <div className="mt-2 flex justify-between items-center pt-2 border-t border-indigo-200/50">
                      <span className="font-bold text-indigo-700">الكمية: {t.suggestedQty} وحدة</span>
                      <button
                        onClick={() => alert(`تم إصدار أمر نقل داخلي رسمي للصنف ${t.productName}`)}
                        className="px-2 py-1 bg-indigo-600 text-white rounded text-[10px] font-bold"
                      >
                        إصدار أمر النقل
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* 16. إدارة الصلاحيات وتجنب التلف (FEFO) */}
            <div className="bg-white rounded-2xl p-5 shadow-sm border border-gray-200">
              <div className="flex items-center gap-2.5 mb-3">
                <CalendarClock className="w-5 h-5 text-rose-600" />
                <h4 className="font-black text-gray-900 text-sm">16. إدارة الصلاحيات (FEFO) وإنقاذ الغذاء</h4>
              </div>
              <p className="text-[11px] text-gray-500 mb-3">صرف الأقرب انتهاءً أولاً وتنبيه قبل التلف بـ 48 ساعة.</p>
              <div className="space-y-2.5">
                {expiryAlerts.map((ex, i) => (
                  <div key={i} className="p-3 rounded-lg border border-rose-100 bg-rose-50/40 text-xs">
                    <div className="flex justify-between font-bold">
                      <span className="text-gray-900">{ex.productName}</span>
                      <span className="text-rose-600 font-bold">باقي {ex.daysToExpiry} يوم</span>
                    </div>
                    <div className="text-[10px] text-gray-500">تشغيلة: {ex.batchNo} • الكمية: {ex.quantity} وحدة</div>
                    <div className="text-[11px] text-indigo-800 bg-white p-2 rounded border border-rose-200 mt-2">
                      {ex.fefoAction}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      )}

      {/* ========================================================================= */}
      {/* DECK 3: MERCHANTS COMPLIANCE & FINANCIAL RECONCILIATION */}
      {/* ========================================================================= */}
      {activeDeck === 'merchants_finance' && (
        <div className="space-y-6">
          {/* Section 8: مراقبة التزام التجار */}
          <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-200">
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-3">
                <div className="p-2 bg-indigo-50 text-indigo-600 rounded-lg">
                  <Store className="w-5 h-5" />
                </div>
                <div>
                  <h2 className="text-lg font-black text-gray-900">8. مراقبة التزام التجار (Merchant SLA & Performance)</h2>
                  <p className="text-xs text-gray-500">كشف التجار الذين يتأخرون في تجهيز الطلبات أو يسجلون نسب إلغاء مرتفعة لتطبيق الجزاءات أو إيقاف المتجر.</p>
                </div>
              </div>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-right text-xs">
                <thead className="bg-gray-50 text-gray-500 font-bold border-y border-gray-200">
                  <tr>
                    <th className="py-3 px-4">اسم التاجر أو الشريك</th>
                    <th className="py-3 px-4">متوسط زمن التجهيز</th>
                    <th className="py-3 px-4">الهدف المحدد</th>
                    <th className="py-3 px-4">نسبة الإلغاء</th>
                    <th className="py-3 px-4">نسبة الإيفاء بالطلبات</th>
                    <th className="py-3 px-4">مستوى الامتثال</th>
                    <th className="py-3 px-4 text-center">الإجراء الرقابي</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100">
                  {merchantsSla.map((m, i) => (
                    <tr key={i} className="hover:bg-gray-50/60 transition">
                      <td className="py-3.5 px-4 font-bold text-gray-900">{m.name}</td>
                      <td className="py-3.5 px-4 font-bold text-gray-800">{m.avgPrepMinutes} دقيقة</td>
                      <td className="py-3.5 px-4 text-gray-500">{m.targetPrepMinutes} دقيقة</td>
                      <td className="py-3.5 px-4">
                        <span className={`font-bold ${parseFloat(m.cancelRate) > 3.0 ? 'text-rose-600' : 'text-emerald-600'}`}>
                          {m.cancelRate}
                        </span>
                      </td>
                      <td className="py-3.5 px-4 font-bold text-emerald-600">{m.fulfillmentRate}</td>
                      <td className="py-3.5 px-4">
                        <span className={`px-2.5 py-1 rounded-md text-[11px] font-bold ${
                          m.status === 'excellent' ? 'bg-emerald-100 text-emerald-800' :
                          m.status === 'good' ? 'bg-blue-100 text-blue-800' : 'bg-rose-100 text-rose-800'
                        }`}>
                          {m.status === 'excellent' ? 'ممتاز' : m.status === 'good' ? 'جيد' : 'إنذار تأخير مرتفع'}
                        </span>
                      </td>
                      <td className="py-3.5 px-4 text-center">
                        {m.status === 'warning' ? (
                          <button
                            onClick={() => alert(`تم إرسال إنذار رسمي للتاجر ${m.name} وتطبيق غرامة تأخير 100 ل.س`)}
                            className="px-2.5 py-1 bg-rose-600 hover:bg-rose-700 text-white rounded text-[11px] font-bold"
                          >
                            تطبيق إنذار وغرامة
                          </button>
                        ) : (
                          <span className="text-gray-400 text-[11px]">ملتزم بالمعايير</span>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>

          {/* Section 11, 12, 13: تسوية الحسابات، كشف العمليات المكررة، وإدارة الديون */}
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            {/* 11. نظام تسوية حسابات التجار */}
            <div className="bg-white rounded-2xl p-5 shadow-sm border border-gray-200">
              <div className="flex items-center gap-2.5 mb-3">
                <DollarSign className="w-5 h-5 text-emerald-600" />
                <h4 className="font-black text-gray-900 text-sm">11. تسوية ومطابقة حسابات التجار</h4>
              </div>
              <p className="text-[11px] text-gray-500 mb-3">مطابقة المبيعات والعمولات والمرتجعات وتوليد مدفوعات دقيقة.</p>
              <div className="space-y-3">
                {merchantSettlements.map((st, i) => (
                  <div key={i} className="p-3.5 rounded-xl border border-gray-100 bg-gray-50 text-xs">
                    <div className="flex justify-between font-bold text-gray-900">
                      <span>{st.merchant}</span>
                      <span className="text-emerald-600">{st.netPayable.toLocaleString()} ل.س</span>
                    </div>
                    <div className="text-[11px] text-gray-500 mt-1">الفترة: {st.period} ({st.totalOrders} طلب)</div>
                    <div className="text-[11px] text-gray-600 mt-1">
                      عمولة المول: -{st.commissionDeducted} ل.س • مرتجعات: -{st.returnsDeducted} ل.س
                    </div>
                    <div className="mt-2.5 pt-2 border-t border-gray-200 flex justify-between items-center">
                      <span className="px-2 py-0.5 bg-emerald-100 text-emerald-800 rounded text-[10px] font-bold">
                        ✓ مطابقة 100% بلا فروقات
                      </span>
                      <button
                        onClick={() => alert(`تم اعتماد صرف التسوية البنكية للتاجر ${st.merchant}`)}
                        className="px-2 py-1 bg-emerald-600 text-white rounded text-[10px] font-bold"
                      >
                        اعتماد الصرف
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* 12. كشف العمليات المالية المكررة */}
            <div className="bg-white rounded-2xl p-5 shadow-sm border border-gray-200">
              <div className="flex items-center gap-2.5 mb-3">
                <ShieldAlert className="w-5 h-5 text-rose-600" />
                <h4 className="font-black text-gray-900 text-sm">12. كشف العمليات والفواتير المكررة</h4>
              </div>
              <p className="text-[11px] text-gray-500 mb-3">منع تسجيل أي دفعة أو استرداد أو فاتورة مرتين آلياً.</p>
              <div className="space-y-3">
                {duplicateAlerts.map((dp) => (
                  <div key={dp.id} className="p-3.5 rounded-xl border border-rose-100 bg-rose-50/40 text-xs">
                    <div className="flex justify-between font-bold text-gray-900">
                      <span className="font-mono">{dp.reference}</span>
                      <span className="text-rose-600">{dp.amount} ل.س</span>
                    </div>
                    <div className="text-[11px] text-gray-600 mt-1">العميل: {dp.customer} ({dp.detectedAt})</div>
                    <div className="text-[11px] text-rose-700 font-bold mt-1 bg-white p-1.5 rounded border border-rose-200">
                      ⚠️ {dp.type}
                    </div>
                    <div className="mt-2 text-[10px] text-emerald-700 font-bold flex items-center gap-1">
                      <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600" />
                      {dp.actionTaken}
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* 13. إدارة الديون والائتمان وسقوف السداد */}
            <div className="bg-white rounded-2xl p-5 shadow-sm border border-gray-200">
              <div className="flex items-center gap-2.5 mb-3">
                <DollarSign className="w-5 h-5 text-indigo-600" />
                <h4 className="font-black text-gray-900 text-sm">13. إدارة الائتمان وسقوف الديون</h4>
              </div>
              <p className="text-[11px] text-gray-500 mb-3">سقف ائتماني لكل تاجر ومراقبة المستحقات ومواعيد السداد.</p>
              <div className="space-y-3">
                {merchantCreditLimits.map((mc, i) => (
                  <div key={i} className="p-3.5 rounded-xl border border-gray-100 bg-gray-50 text-xs">
                    <div className="flex justify-between font-bold text-gray-900">
                      <span>{mc.merchant}</span>
                      <span className={mc.status === 'limit_warning' ? 'text-rose-600 font-black' : 'text-gray-700'}>
                        {mc.currentDebt.toLocaleString()} / {mc.creditLimit.toLocaleString()} ل.س
                      </span>
                    </div>
                    <div className="w-full bg-gray-200 h-2 rounded-full mt-2 overflow-hidden">
                      <div 
                        className={`h-full ${mc.status === 'limit_warning' ? 'bg-rose-500' : 'bg-indigo-600'}`} 
                        style={{ width: mc.utilization }}
                      />
                    </div>
                    <div className="flex justify-between items-center mt-2 text-[11px]">
                      <span className="text-gray-500">الاستهلاك: {mc.utilization}</span>
                      <span className={mc.status === 'limit_warning' ? 'text-rose-600 font-bold' : 'text-gray-500'}>
                        {mc.dueDate}
                      </span>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      )}

      {/* ========================================================================= */}
      {/* DECK 4: RETURNS & DISPUTE RESOLUTION */}
      {/* ========================================================================= */}
      {activeDeck === 'returns_disputes' && (
        <div className="space-y-6">
          {/* Section 18: نظام معالجة المرتجعات اللوجستية */}
          <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-200">
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-3">
                <div className="p-2 bg-indigo-50 text-indigo-600 rounded-lg">
                  <RotateCcw className="w-5 h-5" />
                </div>
                <div>
                  <h2 className="text-lg font-black text-gray-900">18. نظام معالجة المرتجعات اللوجستية (RMA & Reverse Logistics)</h2>
                  <p className="text-xs text-gray-500">تتبع دقيق لسبب الإرجاع، حالة المنتج المستلم، وإمكانية إعادته للمخزون أو إتلافه مع قرار الاسترداد المالي.</p>
                </div>
              </div>
              <span className="px-3 py-1 bg-indigo-100 text-indigo-700 text-xs font-bold rounded-full">
                {rmaList.length} حالات مرتجعات قيد المعالجة
              </span>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-right text-xs">
                <thead className="bg-gray-50 text-gray-500 font-bold border-y border-gray-200">
                  <tr>
                    <th className="py-3 px-4">رقم المرتجع</th>
                    <th className="py-3 px-4">الطلب والعميل</th>
                    <th className="py-3 px-4">المنتج المرتجع</th>
                    <th className="py-3 px-4">سبب الإرجاع</th>
                    <th className="py-3 px-4">حالة الفحص في المستودع</th>
                    <th className="py-3 px-4">قرار المعالجة والاسترداد</th>
                    <th className="py-3 px-4 text-center">الحالة</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100">
                  {rmaList.map((rma) => (
                    <tr key={rma.rmaId} className="hover:bg-gray-50/60 transition">
                      <td className="py-3.5 px-4 font-mono font-bold text-gray-900">{rma.rmaId}</td>
                      <td className="py-3.5 px-4">
                        <div className="font-bold text-gray-900">{rma.customer}</div>
                        <div className="text-[11px] text-gray-400 font-mono">{rma.orderId}</div>
                      </td>
                      <td className="py-3.5 px-4 font-bold text-gray-800">{rma.product}</td>
                      <td className="py-3.5 px-4 text-gray-600">{rma.reason}</td>
                      <td className="py-3.5 px-4">
                        <span className={`px-2 py-0.5 rounded text-[11px] font-bold ${
                          rma.status === 'restocked' ? 'bg-emerald-100 text-emerald-800' : 'bg-rose-100 text-rose-800'
                        }`}>
                          {rma.itemCondition}
                        </span>
                      </td>
                      <td className="py-3.5 px-4 text-gray-700 font-medium">{rma.action}</td>
                      <td className="py-3.5 px-4 text-center">
                        <span className="px-2.5 py-1 bg-gray-100 text-gray-800 rounded-md font-bold text-[10px]">
                          {rma.status === 'restocked' ? 'تمت إعادة المخزون' : 'تم الإتلاف والتعويض'}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>

          {/* Section 20: مركز متابعة الشكاوى والنزاعات وتحديد المسؤولية */}
          <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-200">
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-3">
                <div className="p-2 bg-rose-50 text-rose-600 rounded-lg">
                  <HelpCircle className="w-5 h-5" />
                </div>
                <div>
                  <h2 className="text-lg font-black text-gray-900">20. مركز متابعة الشكاوى والنزاعات وتحديد المسؤولية (Dispute Attribution)</h2>
                  <p className="text-xs text-gray-500">ربط كل نزاع بالطلب، التاجر، ومندوب التوصيل، وتحديد المسؤول عن الخطأ تلقائياً لفض النزاع بدقة وعدالة.</p>
                </div>
              </div>
            </div>

            <div className="space-y-4">
              {disputes.map((dsp) => (
                <div key={dsp.ticketId} className="p-4 rounded-xl border border-gray-200 bg-gray-50/70 hover:bg-white hover:shadow-sm transition">
                  <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 pb-2 border-b border-gray-200">
                    <div className="flex items-center gap-2">
                      <span className="font-mono font-black text-sm text-gray-900">{dsp.ticketId}</span>
                      <span className="text-gray-400">•</span>
                      <span className="font-bold text-gray-700">{dsp.customer}</span>
                      <span className="text-gray-400">•</span>
                      <span className="font-mono text-gray-500">{dsp.orderId}</span>
                    </div>
                    <span className={`px-2.5 py-0.5 rounded-full text-xs font-bold ${
                      dsp.status === 'resolved' ? 'bg-emerald-100 text-emerald-800' : 'bg-amber-100 text-amber-800'
                    }`}>
                      {dsp.status === 'resolved' ? '✓ تم فض النزاع والحل' : 'قيد التحقيق المشترك'}
                    </span>
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-3 gap-3 mt-3 text-xs">
                    <div>
                      <span className="text-gray-500 block mb-1">الشكوى المقدمة من العميل:</span>
                      <p className="font-medium text-gray-800">{dsp.issue}</p>
                    </div>

                    <div>
                      <span className="text-gray-500 block mb-1">الأطراف المرتبطة بالطلب:</span>
                      <p className="text-gray-800">التاجر: <span className="font-bold">{dsp.vendor}</span></p>
                      <p className="text-gray-800">الكابتن: <span className="font-bold">{dsp.courier}</span></p>
                    </div>

                    <div>
                      <span className="text-gray-500 block mb-1">تحديد المسؤولية (Blame Attribution):</span>
                      <p className="font-bold text-rose-600 bg-rose-50 p-1.5 rounded">{dsp.blameAttribution}</p>
                    </div>
                  </div>

                  <div className="mt-3 pt-3 border-t border-gray-200 flex flex-col sm:flex-row sm:items-center justify-between gap-2 text-xs">
                    <div className="text-emerald-800 font-bold">
                      القرار والتسوية المعتمدة: {dsp.resolution}
                    </div>
                    {dsp.status !== 'resolved' && (
                      <button
                        onClick={() => {
                          setDisputes((prev) =>
                            prev.map((d) => (d.ticketId === dsp.ticketId ? { ...d, status: 'resolved' } : d))
                          );
                          alert(`تم فض النزاع ${dsp.ticketId} بنجاح واعتماد التعويض`);
                        }}
                        className="px-3 py-1.5 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg font-bold"
                      >
                        اعتماد إغلاق النزاع
                      </button>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
