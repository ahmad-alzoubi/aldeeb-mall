// Types and Mock Data for Store AI Vision, Footfall & Loss Prevention

export interface StoreCamera {
  id: string;
  name: string;
  location: string;
  zone: 'entrance' | 'butcher' | 'aisles' | 'cashier' | 'loading_dock' | 'bakery';
  status: 'online' | 'recording' | 'alert' | 'offline';
  resolution: string;
  fps: number;
  aiModel: string;
  peopleCount: number;
  lastIncident?: string;
  streamUrl?: string;
  colorScheme: string;
  detections: {
    type: 'person' | 'cart' | 'unscanned_item' | 'concealment' | 'queue_overflow';
    label: string;
    confidence: number;
    box: { x: number; y: number; w: number; h: number }; // percentage 0-100
  }[];
}

export interface SecurityIncident {
  id: string;
  cameraId: string;
  cameraName: string;
  location: string;
  timestamp: string;
  type: 'shoplifting_suspect' | 'pos_misscan' | 'queue_overflow' | 'unauthorized_zone' | 'coldchain_hazard';
  severity: 'critical' | 'warning' | 'info';
  title: string;
  description: string;
  confidence: number;
  status: 'active' | 'investigating' | 'resolved' | 'false_alarm';
  thumbnailUrl: string;
  potentialLossAmount?: number;
  actionTaken?: string;
}

export interface HourlyTraffic {
  hour: string;
  visitors: number;
  predictedVisitors: number;
  isPeak: boolean;
  occupancyRate: number; // percentage
  recommendedCashierLanes: number;
}

export interface StoreZoneDensity {
  id: string;
  nameAr: string;
  category: string;
  currentShoppers: number;
  capacityMax: number;
  avgDwellMinutes: number;
  densityLevel: 'low' | 'medium' | 'high' | 'critical';
  heatColor: string;
}

// Initial Mock Cameras with Edge AI Data
export const INITIAL_CAMERAS: StoreCamera[] = [
  {
    id: 'CAM-01',
    name: 'كاميرا 01: بوابة الدخول وبوابة العبور',
    location: 'المدخل الشمالي الرئيسي',
    zone: 'entrance',
    status: 'online',
    resolution: '4K UltraHD',
    fps: 30,
    aiModel: 'YOLOv10-Footfall-v3.2',
    peopleCount: 14,
    colorScheme: 'from-blue-600 to-indigo-900',
    detections: [
      { type: 'person', label: 'زائر #1042 (داخل)', confidence: 98.4, box: { x: 22, y: 35, w: 18, h: 48 } },
      { type: 'person', label: 'زائر #1043 (داخل)', confidence: 96.1, box: { x: 55, y: 28, w: 16, h: 54 } },
      { type: 'cart', label: 'عربة تسوق رقم #38', confidence: 92.0, box: { x: 38, y: 62, w: 22, h: 28 } }
    ]
  },
  {
    id: 'CAM-02',
    name: 'كاميرا 02: ممر الملحمة والأجبان الطازجة',
    location: 'قسم اللحوم والمأكولات المبردة',
    zone: 'butcher',
    status: 'online',
    resolution: '1440p QHD',
    fps: 30,
    aiModel: 'DwellTimer-FreshZone-v2',
    peopleCount: 9,
    colorScheme: 'from-rose-600 to-red-950',
    detections: [
      { type: 'person', label: 'زبون أمام واجهة الريب آي (Dwell: 42s)', confidence: 97.2, box: { x: 18, y: 30, w: 20, h: 52 } },
      { type: 'person', label: 'جزار الديب مول في الخدمة', confidence: 99.1, box: { x: 62, y: 24, w: 19, h: 58 } }
    ]
  },
  {
    id: 'CAM-03',
    name: 'كاميرا 03: ممر العطور والمنتجات الفاخرة',
    location: 'الممر 4 - مستحضرات التجميل والأغذية المستوردة',
    zone: 'aisles',
    status: 'alert',
    resolution: '4K UltraHD',
    fps: 30,
    aiModel: 'ShrinkGuard-LossPrevention-v4.1',
    peopleCount: 6,
    lastIncident: 'اشتباه إخفاء صنف دون سلة',
    colorScheme: 'from-amber-600 to-stone-900',
    detections: [
      { type: 'concealment', label: '⚠️ اشتباه إخفاء صنف (Confidence: 94%)', confidence: 94.2, box: { x: 42, y: 32, w: 24, h: 46 } },
      { type: 'person', label: 'متسوق ممر 4', confidence: 93.0, box: { x: 74, y: 38, w: 15, h: 44 } }
    ]
  },
  {
    id: 'CAM-04',
    name: 'كاميرا 04: محطات الكاشير والدفع الذاتي',
    location: 'بوابات الخروج ونقاط البيع POS 1-4',
    zone: 'cashier',
    status: 'alert',
    resolution: '4K AI-Targeted',
    fps: 60,
    aiModel: 'POS-ScanVerify-Discrepancy-v5',
    peopleCount: 16,
    lastIncident: 'صنف في الكيس غير ممسوح',
    colorScheme: 'from-emerald-600 to-teal-950',
    detections: [
      { type: 'unscanned_item', label: '⚠️ صنف غير ممسوح في السلة (POS-Mismatch)', confidence: 89.8, box: { x: 48, y: 44, w: 18, h: 22 } },
      { type: 'person', label: 'عميل كاشير 2 (إتمام دفع)', confidence: 98.7, box: { x: 30, y: 26, w: 22, h: 60 } },
      { type: 'queue_overflow', label: 'طابور كاشير 1: 5 عملاء (تجاوز الحد)', confidence: 95.0, box: { x: 68, y: 34, w: 28, h: 45 } }
    ]
  },
  {
    id: 'CAM-05',
    name: 'كاميرا 05: رصيف الشحن والتوريد الخلفي',
    location: 'مستودع الاستلام ورصيف الشاحنات',
    zone: 'loading_dock',
    status: 'online',
    resolution: '1080p Starlight Night-Vision',
    fps: 25,
    aiModel: 'DockSecure-SafetyNet-v2',
    peopleCount: 4,
    colorScheme: 'from-slate-700 to-slate-950',
    detections: [
      { type: 'person', label: 'أمين المستودع (زي معتمد)', confidence: 99.0, box: { x: 35, y: 40, w: 17, h: 48 } },
      { type: 'cart', label: 'طبلية بضائع (استلام توريد جديد)', confidence: 96.5, box: { x: 58, y: 52, w: 26, h: 32 } }
    ]
  },
  {
    id: 'CAM-06',
    name: 'كاميرا 06: ركن المخبز والمقرمشات الساخنة',
    location: 'قسم الأفران والحلويات الشرقية',
    zone: 'bakery',
    status: 'online',
    resolution: '1440p QHD',
    fps: 30,
    aiModel: 'FreshReplenish-Monitor-v1.8',
    peopleCount: 8,
    colorScheme: 'from-orange-600 to-amber-950',
    detections: [
      { type: 'person', label: 'زبون يختار خبز بريوش طازج', confidence: 96.8, box: { x: 32, y: 35, w: 19, h: 50 } },
      { type: 'person', label: 'شيف المخبز', confidence: 98.2, box: { x: 68, y: 28, w: 18, h: 55 } }
    ]
  }
];

// Initial Security & Anomaly Incidents
export const INITIAL_INCIDENTS: SecurityIncident[] = [
  {
    id: 'INC-2026-891',
    cameraId: 'CAM-03',
    cameraName: 'كاميرا 03: ممر العطور والمنتجات الفاخرة',
    location: 'ممر 4 - رف العطور الفرنسية',
    timestamp: 'منذ دقيقتين (03:18:24)',
    type: 'shoplifting_suspect',
    severity: 'critical',
    title: 'اشتباه إخفاء صنف دون وضعه في السلة (Concealment Gesture)',
    description: 'تم رصد حركة يد متسارعة بإدخال عبوة عطر ديور سوفاج داخل المعطف دون وضعها في عربة التسوق. درجة الثقة: 94.2%.',
    confidence: 94.2,
    status: 'active',
    thumbnailUrl: 'https://images.unsplash.com/photo-1541643600914-78b084683601?auto=format&fit=crop&w=600&q=80',
    potentialLossAmount: 540,
    actionTaken: 'توجيه إشعار هادئ لجهاز الأمن الميداني (رجل أمن ممر 4)'
  },
  {
    id: 'INC-2026-890',
    cameraId: 'CAM-04',
    cameraName: 'كاميرا 04: محطات الكاشير والدفع الذاتي',
    location: 'نقطة الدفع الذاتي كاشير رقم #2',
    timestamp: 'منذ 7 دقائق (03:13:02)',
    type: 'pos_misscan',
    severity: 'critical',
    title: 'عدم تطابق المسح الضوئي في السلة (Sweethearting / Misscan)',
    description: 'رصد وضع كيس مكسرات مشكلة فاخرة 500غ داخل كيس التسوق دون ظهور قراءة باركود على واجهة الكاشير المربوطة بالـ API.',
    confidence: 89.8,
    status: 'investigating',
    thumbnailUrl: 'https://images.unsplash.com/photo-1556742049-0a67c5574f73?auto=format&fit=crop&w=600&q=80',
    potentialLossAmount: 95,
    actionTaken: 'تجميد شاشة الكاشير تلقائياً لطلب مساعدة الموظف المشرف'
  },
  {
    id: 'INC-2026-889',
    cameraId: 'CAM-04',
    cameraName: 'كاميرا 04: محطات الكاشير',
    location: 'مسار كاشير 1 الرئيسي',
    timestamp: 'منذ 18 دقيقة (03:02:15)',
    type: 'queue_overflow',
    severity: 'warning',
    title: 'تكدس طابور العملاء وتجاوز السعة (Queue Delay Alert)',
    description: 'طابور كاشير 1 تجاوز 5 عملاء بمتوسط انتظار 6.8 دقيقة لكل عميل. يتطلب فتح مسار إضافي فوراً.',
    confidence: 95.0,
    status: 'resolved',
    thumbnailUrl: 'https://images.unsplash.com/photo-1578916171728-46686eac8d58?auto=format&fit=crop&w=600&q=80',
    actionTaken: 'تم إرسال إشعار وفتح كاشير رقم 3 وتقليص الطابور بنجاح'
  },
  {
    id: 'INC-2026-888',
    cameraId: 'CAM-02',
    cameraName: 'كاميرا 02: ممر الملحمة والأجبان الطازجة',
    location: 'الممر 2 - قسم الأغذية المجففة',
    timestamp: 'منذ 34 دقيقة (02:46:11)',
    type: 'coldchain_hazard',
    severity: 'warning',
    title: 'صنف مبرد متروك في بيئة جافة (Cold Chain Hazard)',
    description: 'تم رصد ترك طبق كفتة بلدي مبردة على رف البسكويت الجاف من قبل متسوق. يتطلب استعادته فوراً للحفاظ على سلسلة التبريد.',
    confidence: 91.5,
    status: 'resolved',
    thumbnailUrl: 'https://images.unsplash.com/photo-1607623814075-e51df1bdc82f?auto=format&fit=crop&w=600&q=80',
    potentialLossAmount: 68,
    actionTaken: 'قام موظف ترتيب الرفوف بإرجاع الصنف فور تلقي التنبيه'
  },
  {
    id: 'INC-2026-887',
    cameraId: 'CAM-05',
    cameraName: 'كاميرا 05: رصيف الشحن والتوريد',
    location: 'باب المستودع الخلفي',
    timestamp: 'منذ ساعة (02:20:00)',
    type: 'unauthorized_zone',
    severity: 'info',
    title: 'حركة عبور خارج ساعات التوريد المقررة',
    description: 'دخول موظف النظافة لفرز الحاويات الكرتونية. تم التحقق من البصمة وبطاقة الموظف وصرف الإشعار كإجراء طبيعي.',
    confidence: 99.2,
    status: 'resolved',
    thumbnailUrl: 'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?auto=format&fit=crop&w=600&q=80',
    actionTaken: 'مطابقة رقم البصمة وإغلاق التنبيه كإجراء روتيني'
  }
];

// Hourly Footfall & Peak Rush Curve (24 Hours)
export const HOURLY_TRAFFIC_DATA: HourlyTraffic[] = [
  { hour: '08:00', visitors: 42, predictedVisitors: 45, isPeak: false, occupancyRate: 25, recommendedCashierLanes: 1 },
  { hour: '09:00', visitors: 68, predictedVisitors: 65, isPeak: false, occupancyRate: 35, recommendedCashierLanes: 2 },
  { hour: '10:00', visitors: 94, predictedVisitors: 90, isPeak: false, occupancyRate: 48, recommendedCashierLanes: 2 },
  { hour: '11:00', visitors: 118, predictedVisitors: 110, isPeak: false, occupancyRate: 58, recommendedCashierLanes: 2 },
  { hour: '12:00', visitors: 135, predictedVisitors: 140, isPeak: false, occupancyRate: 65, recommendedCashierLanes: 3 },
  { hour: '13:00', visitors: 162, predictedVisitors: 155, isPeak: true, occupancyRate: 78, recommendedCashierLanes: 3 },
  { hour: '14:00', visitors: 140, predictedVisitors: 145, isPeak: false, occupancyRate: 68, recommendedCashierLanes: 3 },
  { hour: '15:00', visitors: 112, predictedVisitors: 115, isPeak: false, occupancyRate: 54, recommendedCashierLanes: 2 },
  { hour: '16:00', visitors: 145, predictedVisitors: 150, isPeak: false, occupancyRate: 70, recommendedCashierLanes: 3 },
  { hour: '17:00', visitors: 185, predictedVisitors: 190, isPeak: true, occupancyRate: 88, recommendedCashierLanes: 4 },
  { hour: '18:00', visitors: 228, predictedVisitors: 230, isPeak: true, occupancyRate: 98, recommendedCashierLanes: 5 },
  { hour: '19:00', visitors: 254, predictedVisitors: 250, isPeak: true, occupancyRate: 100, recommendedCashierLanes: 5 },
  { hour: '20:00', visitors: 242, predictedVisitors: 245, isPeak: true, occupancyRate: 96, recommendedCashierLanes: 5 },
  { hour: '21:00', visitors: 210, predictedVisitors: 205, isPeak: true, occupancyRate: 85, recommendedCashierLanes: 4 },
  { hour: '22:00', visitors: 130, predictedVisitors: 125, isPeak: false, occupancyRate: 55, recommendedCashierLanes: 2 },
  { hour: '23:00', visitors: 64, predictedVisitors: 60, isPeak: false, occupancyRate: 30, recommendedCashierLanes: 1 }
];

// Physical Store Floorplan Zones & Heatmap Data
export const STORE_ZONES: StoreZoneDensity[] = [
  {
    id: 'zone-ent',
    nameAr: 'بوابة الدخول والاستقبال',
    category: 'Entrance',
    currentShoppers: 12,
    capacityMax: 20,
    avgDwellMinutes: 2.1,
    densityLevel: 'medium',
    heatColor: 'bg-amber-500/80 border-amber-400'
  },
  {
    id: 'zone-produce',
    nameAr: 'قسم الخضار والفواكه الطازجة',
    category: 'Fresh Produce',
    currentShoppers: 16,
    capacityMax: 25,
    avgDwellMinutes: 8.4,
    densityLevel: 'high',
    heatColor: 'bg-emerald-500/80 border-emerald-400'
  },
  {
    id: 'zone-butcher',
    nameAr: 'الملحمة والمأكولات البحرية المبردة',
    category: 'Butcher & Seafood',
    currentShoppers: 9,
    capacityMax: 15,
    avgDwellMinutes: 11.2,
    densityLevel: 'medium',
    heatColor: 'bg-rose-500/80 border-rose-400'
  },
  {
    id: 'zone-bakery',
    nameAr: 'المخبز والحلويات الطازجة',
    category: 'Bakery',
    currentShoppers: 7,
    capacityMax: 12,
    avgDwellMinutes: 5.6,
    densityLevel: 'medium',
    heatColor: 'bg-orange-500/80 border-orange-400'
  },
  {
    id: 'zone-grocery',
    nameAr: 'الممرات المركزية والمعلبات',
    category: 'Grocery & Dry',
    currentShoppers: 14,
    capacityMax: 30,
    avgDwellMinutes: 14.8,
    densityLevel: 'medium',
    heatColor: 'bg-blue-500/80 border-blue-400'
  },
  {
    id: 'zone-beauty',
    nameAr: 'العطور ومستحضرات العناية الفاخرة',
    category: 'Beauty & Premium',
    currentShoppers: 5,
    capacityMax: 10,
    avgDwellMinutes: 9.7,
    densityLevel: 'low',
    heatColor: 'bg-purple-500/80 border-purple-400'
  },
  {
    id: 'zone-pos',
    nameAr: 'منطقة الكاشير والدفع الذاتي',
    category: 'Checkout Lines',
    currentShoppers: 18,
    capacityMax: 22,
    avgDwellMinutes: 4.8,
    densityLevel: 'critical',
    heatColor: 'bg-red-600/90 border-red-500 animate-pulse'
  },
  {
    id: 'zone-loading',
    nameAr: 'رصيف الاستلام والمستودع الخلفي',
    category: 'Logistics',
    currentShoppers: 4,
    capacityMax: 10,
    avgDwellMinutes: 18.0,
    densityLevel: 'low',
    heatColor: 'bg-slate-500/80 border-slate-400'
  }
];
