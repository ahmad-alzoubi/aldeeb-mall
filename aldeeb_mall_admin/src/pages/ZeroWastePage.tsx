import React, { useState } from 'react';
import { 
  Sparkles, 
  Clock, 
  DollarSign, 
  HeartHandshake, 
  AlertCircle, 
  TrendingUp, 
  ShieldCheck, 
  CheckCircle2, 
  RefreshCw, 
  Plus, 
  Tag, 
  Sliders, 
  Truck,
  Percent,
  X,
  Send
} from 'lucide-react';

interface ZeroWasteItem {
  id: string;
  name: string;
  category: string;
  darkStore: string;
  originalPrice: number;
  currentDiscount: number; // percentage
  markdownPrice: number;
  stock: number;
  hoursRemaining: number;
  status: 'CLEARANCE_ACTIVE' | 'DISPATCHED_DONATION' | 'SOLD_OUT';
  batchCode: string;
}

interface DonationBatch {
  id: string;
  charityName: string;
  itemCount: number;
  totalValue: number;
  mealsCount: number;
  scheduledPickup: string;
  driverName: string;
  temperatureControlled: boolean;
  status: 'READY_FOR_PICKUP' | 'COLLECTED' | 'DELIVERED';
}

const initialClearanceItems: ZeroWasteItem[] = [
  {
    id: 'ZW-001',
    name: 'كرواسون الزبدة الفرنسية الفاخر (علبة 4 قطع)',
    category: 'مخبوزات طازجة',
    darkStore: 'مستودع السلي الرقمي',
    originalPrice: 18.0,
    currentDiscount: 65,
    markdownPrice: 6.30,
    stock: 6,
    hoursRemaining: 14,
    status: 'CLEARANCE_ACTIVE',
    batchCode: 'LOT-BK-9921',
  },
  {
    id: 'ZW-002',
    name: 'حليب المراعي طازج كامل الدسم (2 لتر)',
    category: 'ألبان وأجبان',
    darkStore: 'مستودع النرجس الذكي',
    originalPrice: 11.5,
    currentDiscount: 50,
    markdownPrice: 5.75,
    stock: 12,
    hoursRemaining: 36,
    status: 'CLEARANCE_ACTIVE',
    batchCode: 'LOT-DY-3310',
  },
  {
    id: 'ZW-003',
    name: 'فراولة القصيم الطازجة عالي الحلاوة (صندوق 500غ)',
    category: 'فواكه وخضار',
    darkStore: 'مستودع الروضة السريع',
    originalPrice: 16.0,
    currentDiscount: 55,
    markdownPrice: 7.20,
    stock: 8,
    hoursRemaining: 40,
    status: 'CLEARANCE_ACTIVE',
    batchCode: 'LOT-PR-1192',
  },
  {
    id: 'ZW-004',
    name: 'لبنة تركية طازجة بينار (400غ)',
    category: 'ألبان وأجبان',
    darkStore: 'مستودع السلي الرقمي',
    originalPrice: 15.5,
    currentDiscount: 40,
    markdownPrice: 9.30,
    stock: 5,
    hoursRemaining: 68,
    status: 'CLEARANCE_ACTIVE',
    batchCode: 'LOT-DY-8821',
  },
  {
    id: 'ZW-005',
    name: 'صدور دجاج التنمية طازجة (450غ)',
    category: 'لحوم ودواجن',
    darkStore: 'مستودع النرجس الذكي',
    originalPrice: 21.0,
    currentDiscount: 60,
    markdownPrice: 8.40,
    stock: 4,
    hoursRemaining: 18,
    status: 'CLEARANCE_ACTIVE',
    batchCode: 'LOT-MT-4029',
  },
  {
    id: 'ZW-006',
    name: 'عصير برتقال معصور طازج بدون سكر (1 لتر)',
    category: 'عصائر طازجة',
    darkStore: 'مستودع الروضة السريع',
    originalPrice: 14.0,
    currentDiscount: 50,
    markdownPrice: 7.00,
    stock: 9,
    hoursRemaining: 22,
    status: 'CLEARANCE_ACTIVE',
    batchCode: 'LOT-JC-0923',
  },
];

const initialDonations: DonationBatch[] = [
  {
    id: 'DON-2026-1031-01',
    charityName: 'جمعية إطعام لحفظ النعمة بالرياض',
    itemCount: 42,
    totalValue: 840,
    mealsCount: 65,
    scheduledPickup: 'اليوم 11:30 صباحاً',
    driverName: 'خالد العنزي (شاحنة تبريد إطعام 4)',
    temperatureControlled: true,
    status: 'READY_FOR_PICKUP',
  },
  {
    id: 'DON-2026-1030-02',
    charityName: 'جمعية إطعام لحفظ النعمة بالرياض',
    itemCount: 58,
    totalValue: 1250,
    mealsCount: 90,
    scheduledPickup: 'أمس 04:00 مساءً',
    driverName: 'سعود المطيري',
    temperatureControlled: true,
    status: 'DELIVERED',
  },
];

export const ZeroWastePage: React.FC = () => {
  const [items, setItems] = useState<ZeroWasteItem[]>(initialClearanceItems);
  const [donations, setDonations] = useState<DonationBatch[]>(initialDonations);
  const [activeTab, setActiveTab] = useState<'clearance' | 'donations' | 'rules'>('clearance');
  const [selectedFilter, setSelectedFilter] = useState<'ALL' | 'CRITICAL' | 'URGENT' | 'MODERATE'>('ALL');
  const [isScanning, setIsScanning] = useState(false);

  // Modal for Edit Markdown
  const [selectedItem, setSelectedItem] = useState<ZeroWasteItem | null>(null);
  const [newDiscount, setNewDiscount] = useState<number>(50);

  // Modal for New Donation Batch
  const [showDonationModal, setShowDonationModal] = useState(false);
  const [donationCharity, setDonationCharity] = useState('جمعية إطعام لحفظ النعمة بالرياض');

  const handleSimulateScan = () => {
    setIsScanning(true);
    setTimeout(() => {
      setIsScanning(false);
      alert('تم تحديث مسح الباركود وسجلات الصلاحية عبر حساسات المستودعات الذكية. تم تحديث 6 أصناف تلقائياً.');
    }, 1200);
  };

  const handleUpdateDiscount = (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedItem) return;

    const updatedPrice = Number((selectedItem.originalPrice * (1 - newDiscount / 100)).toFixed(2));
    setItems(items.map(it => {
      if (it.id === selectedItem.id) {
        return {
          ...it,
          currentDiscount: newDiscount,
          markdownPrice: updatedPrice,
        };
      }
      return it;
    }));
    setSelectedItem(null);
  };

  const handleCreateDonationBatch = (e: React.FormEvent) => {
    e.preventDefault();
    const newBatch: DonationBatch = {
      id: `DON-${Date.now().toString().slice(-6)}`,
      charityName: donationCharity,
      itemCount: 25,
      totalValue: 460,
      mealsCount: 38,
      scheduledPickup: 'اليوم خلال ساعتين',
      driverName: 'مندوب بنك الطعام المعتمد',
      temperatureControlled: true,
      status: 'READY_FOR_PICKUP',
    };
    setDonations([newBatch, ...donations]);
    setShowDonationModal(false);
  };

  const filteredItems = items.filter(item => {
    if (selectedFilter === 'CRITICAL') return item.hoursRemaining <= 24;
    if (selectedFilter === 'URGENT') return item.hoursRemaining > 24 && item.hoursRemaining <= 48;
    if (selectedFilter === 'MODERATE') return item.hoursRemaining > 48;
    return true;
  });

  const totalSalvagedValue = items.reduce((acc, it) => acc + (it.markdownPrice * it.stock), 0);
  const totalItemsCount = items.reduce((acc, it) => acc + it.stock, 0);

  return (
    <div className="space-y-6">
      {/* Top Banner */}
      <div className="bg-gradient-to-r from-slate-900 via-emerald-950 to-slate-900 border border-emerald-900/50 rounded-2xl p-6 text-white shadow-xl flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <div>
          <div className="flex items-center gap-3">
            <div className="p-3 bg-emerald-600/30 border border-emerald-500/40 rounded-xl text-emerald-400">
              <Sparkles className="w-7 h-7" />
            </div>
            <div>
              <h1 className="text-2xl font-bold flex items-center gap-2">
                منظومة إنقاذ الغذاء والتخفيض الذكي (Zero Food Waste)
                <span className="text-xs bg-emerald-500/20 text-emerald-300 border border-emerald-500/30 px-2.5 py-0.5 rounded-full font-mono">
                  SFDA & Eta'am Certified
                </span>
              </h1>
              <p className="text-sm text-slate-400 mt-1">
                تسعير ديناميكي آلي للمنتجات القريبة من انتهاء الصلاحية (-70%)، وترحيل الفائض تلقائياً لبنك الطعام إطعام
              </p>
            </div>
          </div>
        </div>

        <div className="flex items-center gap-3 w-full md:w-auto">
          <button
            onClick={handleSimulateScan}
            disabled={isScanning}
            className="flex-1 md:flex-none flex items-center justify-center gap-2 bg-slate-800 hover:bg-slate-700 text-white font-medium px-4 py-2.5 rounded-xl transition border border-slate-700 text-sm"
          >
            <RefreshCw className={`w-4 h-4 ${isScanning ? 'animate-spin' : ''}`} />
            مسح تواريخ المستودعات
          </button>
          <button
            onClick={() => setShowDonationModal(true)}
            className="flex-1 md:flex-none flex items-center justify-center gap-2 bg-emerald-600 hover:bg-emerald-700 text-white font-medium px-4 py-2.5 rounded-xl transition shadow-lg shadow-emerald-600/30 text-sm"
          >
            <HeartHandshake className="w-4 h-4" />
            تجهيز دفعة تبرع لإطعام
          </button>
        </div>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs flex items-center justify-between">
          <div>
            <p className="text-xs font-medium text-slate-700">معدل تحويل وتفادي الهدر</p>
            <h3 className="text-2xl font-extrabold text-emerald-600 mt-1">94.8%</h3>
            <p className="text-xs text-slate-700 font-medium mt-1 flex items-center gap-1">
              <ShieldCheck className="w-3.5 h-3.5 text-emerald-600" />
              تم بيعها أو التبرع بها بالكامل
            </p>
          </div>
          <div className="p-3 bg-emerald-50 text-emerald-600 rounded-xl">
            <TrendingUp className="w-6 h-6" />
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs flex items-center justify-between">
          <div>
            <p className="text-xs font-medium text-slate-700">قيمة المبيعات المنقذة (Revenue)</p>
            <h3 className="text-2xl font-extrabold text-slate-900 mt-1">{totalSalvagedValue.toLocaleString()} ل.س</h3>
            <p className="text-xs text-blue-600 font-medium mt-1">
              مبيعات محققة بدلاً من الإتلاف
            </p>
          </div>
          <div className="p-3 bg-blue-50 text-blue-600 rounded-xl">
            <DollarSign className="w-6 h-6" />
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs flex items-center justify-between">
          <div>
            <p className="text-xs font-medium text-slate-700">قطع معروضة بالتخفيض الفوري</p>
            <h3 className="text-2xl font-extrabold text-amber-600 mt-1">{totalItemsCount} قطعة</h3>
            <p className="text-xs text-amber-700 font-medium mt-1">
              في ركن التوفير بتطبيق الديب مول
            </p>
          </div>
          <div className="p-3 bg-amber-50 text-amber-600 rounded-xl">
            <Tag className="w-6 h-6" />
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs flex items-center justify-between">
          <div>
            <p className="text-xs font-medium text-slate-700">وجبات تم التبرع بها لإطعام</p>
            <h3 className="text-2xl font-extrabold text-purple-600 mt-1">1,480 وجبة</h3>
            <p className="text-xs text-purple-700 font-medium mt-1 flex items-center gap-1">
              <HeartHandshake className="w-3.5 h-3.5" />
              لصالح الأسر المتعففة
            </p>
          </div>
          <div className="p-3 bg-purple-50 text-purple-600 rounded-xl">
            <HeartHandshake className="w-6 h-6" />
          </div>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex border-b border-slate-200">
        <button
          onClick={() => setActiveTab('clearance')}
          className={`pb-3 px-4 text-sm font-bold border-b-2 flex items-center gap-2 transition ${
            activeTab === 'clearance'
              ? 'border-emerald-600 text-emerald-600'
              : 'border-transparent text-slate-500 hover:text-slate-700'
          }`}
        >
          <Tag className="w-4 h-4" />
          أصناف التخفيض الذكي الحالية ({items.length})
        </button>

        <button
          onClick={() => setActiveTab('donations')}
          className={`pb-3 px-4 text-sm font-bold border-b-2 flex items-center gap-2 transition ${
            activeTab === 'donations'
              ? 'border-emerald-600 text-emerald-600'
              : 'border-transparent text-slate-500 hover:text-slate-700'
          }`}
        >
          <Truck className="w-4 h-4" />
          شحنات التبرع لجمعية إطعام ({donations.length})
        </button>

        <button
          onClick={() => setActiveTab('rules')}
          className={`pb-3 px-4 text-sm font-bold border-b-2 flex items-center gap-2 transition ${
            activeTab === 'rules'
              ? 'border-emerald-600 text-emerald-600'
              : 'border-transparent text-slate-500 hover:text-slate-700'
          }`}
        >
          <Sliders className="w-4 h-4" />
          قواعد الخصم التلقائي والإنقاذ (Automation Rules)
        </button>
      </div>

      {/* TAB 1: CLEARANCE ITEMS */}
      {activeTab === 'clearance' && (
        <div className="space-y-4">
          {/* Filters Bar */}
          <div className="bg-white p-4 rounded-xl border border-slate-200 flex flex-wrap gap-2 items-center justify-between">
            <div className="flex items-center gap-2">
              <span className="text-xs font-bold text-slate-700">تصفية حسب وقت الصلاحية:</span>
              <button
                onClick={() => setSelectedFilter('ALL')}
                className={`text-xs px-3 py-1.5 rounded-lg font-medium transition ${
                  selectedFilter === 'ALL' ? 'bg-slate-900 text-white' : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
                }`}
              >
                الكل ({items.length})
              </button>
              <button
                onClick={() => setSelectedFilter('CRITICAL')}
                className={`text-xs px-3 py-1.5 rounded-lg font-medium transition ${
                  selectedFilter === 'CRITICAL' ? 'bg-rose-600 text-white' : 'bg-rose-50 text-rose-700 hover:bg-rose-100'
                }`}
              >
                حرجة (أقل من 24 ساعة - 70%)
              </button>
              <button
                onClick={() => setSelectedFilter('URGENT')}
                className={`text-xs px-3 py-1.5 rounded-lg font-medium transition ${
                  selectedFilter === 'URGENT' ? 'bg-amber-600 text-white' : 'bg-amber-50 text-amber-700 hover:bg-amber-100'
                }`}
              >
                عاجلة (24 - 48 ساعة - 50%)
              </button>
              <button
                onClick={() => setSelectedFilter('MODERATE')}
                className={`text-xs px-3 py-1.5 rounded-lg font-medium transition ${
                  selectedFilter === 'MODERATE' ? 'bg-blue-600 text-white' : 'bg-blue-50 text-blue-700 hover:bg-blue-100'
                }`}
              >
                معتدلة (48 - 72 ساعة - 40%)
              </button>
            </div>
          </div>

          <div className="bg-white rounded-xl border border-slate-200 overflow-hidden shadow-xs">
            <div className="overflow-x-auto">
              <table className="w-full text-right text-sm">
                <thead className="bg-slate-50 text-slate-700 text-xs font-bold border-b border-slate-200">
                  <tr>
                    <th className="p-3.5">المنتج / كود التشغيلة</th>
                    <th className="p-3.5">الفرع والمستودع</th>
                    <th className="p-3.5">الوقت المتبقي للصلاحية</th>
                    <th className="p-3.5">السعر الأصلي</th>
                    <th className="p-3.5">سعر التخفيض الذكي</th>
                    <th className="p-3.5">نسبة الخصم</th>
                    <th className="p-3.5">الكمية بالمستودع</th>
                    <th className="p-3.5 text-center">إجراءات</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {filteredItems.map((it) => (
                    <tr key={it.id} className="hover:bg-slate-50 transition">
                      <td className="p-3.5">
                        <div className="font-bold text-slate-900">{it.name}</div>
                        <div className="text-xs text-slate-400 font-mono">
                          {it.category} | {it.batchCode}
                        </div>
                      </td>
                      <td className="p-3.5 text-xs text-slate-600">
                        {it.darkStore}
                      </td>
                      <td className="p-3.5">
                        <div className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg text-xs font-bold ${
                          it.hoursRemaining <= 24 
                            ? 'bg-rose-50 text-rose-700 border border-rose-200' 
                            : it.hoursRemaining <= 48 
                            ? 'bg-amber-50 text-amber-800 border border-amber-200' 
                            : 'bg-blue-50 text-blue-800 border border-blue-200'
                        }`}>
                          <Clock className="w-3.5 h-3.5" />
                          متبقي {it.hoursRemaining} ساعة
                        </div>
                      </td>
                      <td className="p-3.5 text-slate-400 line-through text-xs">
                        {it.originalPrice.toFixed(2)} ل.س
                      </td>
                      <td className="p-3.5 font-extrabold text-emerald-600 text-base">
                        {it.markdownPrice.toFixed(2)} ل.س
                      </td>
                      <td className="p-3.5">
                        <span className="bg-emerald-100 text-emerald-800 font-bold px-2 py-0.5 rounded text-xs">
                          -{it.currentDiscount}%
                        </span>
                      </td>
                      <td className="p-3.5 font-bold text-slate-800">
                        {it.stock} قطع
                      </td>
                      <td className="p-3.5 text-center">
                        <button
                          onClick={() => {
                            setSelectedItem(it);
                            setNewDiscount(it.currentDiscount);
                          }}
                          className="bg-slate-100 hover:bg-slate-200 text-slate-700 text-xs font-bold px-3 py-1.5 rounded-lg transition"
                        >
                          تعديل الخصم
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

      {/* TAB 2: DONATIONS */}
      {activeTab === 'donations' && (
        <div className="space-y-4">
          <div className="bg-purple-50 border border-purple-200 rounded-xl p-4 flex items-center justify-between text-purple-900 text-sm">
            <div className="flex items-center gap-3">
              <HeartHandshake className="w-5 h-5 text-purple-700" />
              <div>
                <span className="font-bold">برنامج حفظ النعمة بالشراكة مع جمعية إطعام: </span>
                أي منتج متبقي عليه 12 ساعة ولم يُبَع يتم نقله آلياً في حاويات تبريد معتمدة لبنك الطعام مجاناً.
              </div>
            </div>
          </div>

          <div className="bg-white rounded-xl border border-slate-200 overflow-hidden shadow-xs">
            <div className="overflow-x-auto">
              <table className="w-full text-right text-sm">
                <thead className="bg-slate-50 text-slate-700 text-xs font-bold border-b border-slate-200">
                  <tr>
                    <th className="p-3.5">رقم الشحنة</th>
                    <th className="p-3.5">الجهة المستفيدة</th>
                    <th className="p-3.5">عدد المنتجات</th>
                    <th className="p-3.5">القيمة المقدرة</th>
                    <th className="p-3.5">الوجبات الموفرة</th>
                    <th className="p-3.5">موعد الاستلام بالشاحنة</th>
                    <th className="p-3.5">سائق شاحنة التبريد</th>
                    <th className="p-3.5">الحالة</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {donations.map((d) => (
                    <tr key={d.id} className="hover:bg-slate-50 transition">
                      <td className="p-3.5 font-mono text-xs font-bold text-slate-900">
                        {d.id}
                      </td>
                      <td className="p-3.5 font-bold text-purple-900">
                        {d.charityName}
                      </td>
                      <td className="p-3.5 font-bold text-slate-800">
                        {d.itemCount} صنف
                      </td>
                      <td className="p-3.5 text-slate-600">
                        {d.totalValue.toLocaleString()} ل.س
                      </td>
                      <td className="p-3.5 font-bold text-emerald-600">
                        {d.mealsCount} وجبة طازجة
                      </td>
                      <td className="p-3.5 text-xs text-slate-600">
                        {d.scheduledPickup}
                      </td>
                      <td className="p-3.5 text-xs text-slate-700">
                        {d.driverName}
                      </td>
                      <td className="p-3.5">
                        {d.status === 'READY_FOR_PICKUP' && (
                          <span className="bg-amber-100 text-amber-800 font-bold px-2 py-0.5 rounded-full text-xs">
                            جاهزة للاستلام
                          </span>
                        )}
                        {d.status === 'DELIVERED' && (
                          <span className="bg-emerald-100 text-emerald-800 font-bold px-2 py-0.5 rounded-full text-xs inline-flex items-center gap-1">
                            <CheckCircle2 className="w-3 h-3" /> تم التسليم
                          </span>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

      {/* TAB 3: AUTOMATION RULES */}
      {activeTab === 'rules' && (
        <div className="bg-white rounded-xl border border-slate-200 p-6 space-y-6 shadow-xs">
          <div>
            <h3 className="text-lg font-bold text-slate-900">سلم التخفيض الذكي الآلي (Smart Markdown Ladder)</h3>
            <p className="text-xs text-slate-500 mt-1">
              يتم تطبيق الخصم فورياً في تطبيق المستند وفروع الكاشير لحظة قراءة مستشعر الباركود للوقت المتبقي
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            <div className="p-4 rounded-xl border border-blue-200 bg-blue-50/50">
              <span className="text-xs font-bold text-blue-800 bg-blue-200 px-2 py-0.5 rounded">المرحلة 1</span>
              <h4 className="text-base font-bold text-slate-900 mt-2">72 إلى 48 ساعة</h4>
              <p className="text-xs text-slate-600 mt-1">خصم تلقائي 30% - 40% وعرض في قسم التوفير الذكي</p>
              <div className="mt-4 pt-3 border-t border-blue-200 font-extrabold text-blue-700 text-lg">
                خصم 35%
              </div>
            </div>

            <div className="p-4 rounded-xl border border-amber-200 bg-amber-50/50">
              <span className="text-xs font-bold text-amber-800 bg-amber-200 px-2 py-0.5 rounded">المرحلة 2</span>
              <h4 className="text-base font-bold text-slate-900 mt-2">48 إلى 24 ساعة</h4>
              <p className="text-xs text-slate-600 mt-1">خصم 50% وإرسال إشعار فوري للعملاء في نطاق الحي</p>
              <div className="mt-4 pt-3 border-t border-amber-200 font-extrabold text-amber-700 text-lg">
                خصم 50%
              </div>
            </div>

            <div className="p-4 rounded-xl border border-rose-200 bg-rose-50/50">
              <span className="text-xs font-bold text-rose-800 bg-rose-200 px-2 py-0.5 rounded">المرحلة 3</span>
              <h4 className="text-base font-bold text-slate-900 mt-2">24 إلى 12 ساعة</h4>
              <p className="text-xs text-slate-600 mt-1">ساعة الإنقاذ القصوى: خصم 65% - 70% للإنقاذ السريع</p>
              <div className="mt-4 pt-3 border-t border-rose-200 font-extrabold text-rose-700 text-lg">
                خصم 70%
              </div>
            </div>

            <div className="p-4 rounded-xl border border-purple-200 bg-purple-50/50">
              <span className="text-xs font-bold text-purple-800 bg-purple-200 px-2 py-0.5 rounded">المرحلة 4</span>
              <h4 className="text-base font-bold text-slate-900 mt-2">أقل من 12 ساعة</h4>
              <p className="text-xs text-slate-600 mt-1">ترحيل تلقائي لدفعة التبرع لبنك الطعام إطعام</p>
              <div className="mt-4 pt-3 border-t border-purple-200 font-extrabold text-purple-700 text-lg">
                تبرع خيري 100%
              </div>
            </div>
          </div>
        </div>
      )}

      {/* MODAL: EDIT MARKDOWN DISCOUNT */}
      {selectedItem && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-xs flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl max-w-sm w-full p-6 shadow-2xl">
            <div className="flex items-center justify-between border-b pb-3 mb-4">
              <h3 className="text-base font-bold text-slate-900 flex items-center gap-2">
                <Percent className="w-4 h-4 text-emerald-600" />
                تعديل نسبة التخفيض الذكي
              </h3>
              <button onClick={() => setSelectedItem(null)} className="text-slate-400 hover:text-slate-600">
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleUpdateDiscount} className="space-y-4">
              <div>
                <p className="text-xs text-slate-500">المنتج المختار:</p>
                <p className="text-sm font-bold text-slate-900">{selectedItem.name}</p>
                <p className="text-xs text-slate-400 mt-0.5">السعر الأصلي: {selectedItem.originalPrice.toFixed(2)} ل.س</p>
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1">
                  نسبة الخصم: {newDiscount}%
                </label>
                <input
                  type="range"
                  min="20"
                  max="80"
                  step="5"
                  value={newDiscount}
                  onChange={(e) => setNewDiscount(Number(e.target.value))}
                  className="w-full accent-emerald-600"
                />
                <div className="flex justify-between text-[11px] text-slate-400 mt-1">
                  <span>20%</span>
                  <span>50%</span>
                  <span>80%</span>
                </div>
              </div>

              <div className="p-3 bg-emerald-50 rounded-xl flex justify-between items-center text-sm">
                <span className="text-slate-600 font-medium">السعر الجديد بعد الخصم:</span>
                <span className="font-extrabold text-emerald-700 text-base">
                  {(selectedItem.originalPrice * (1 - newDiscount / 100)).toFixed(2)} ل.س
                </span>
              </div>

              <div className="flex items-center justify-end gap-2 pt-2 border-t">
                <button
                  type="button"
                  onClick={() => setSelectedItem(null)}
                  className="px-3 py-1.5 border rounded-lg text-xs text-slate-600 hover:bg-slate-50"
                >
                  إلغاء
                </button>
                <button
                  type="submit"
                  className="px-4 py-1.5 bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg text-xs font-bold shadow-xs"
                >
                  تحديث السعر الفوري
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* MODAL: DONATION BATCH */}
      {showDonationModal && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-xs flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl max-w-md w-full p-6 shadow-2xl">
            <div className="flex items-center justify-between border-b pb-3 mb-4">
              <h3 className="text-lg font-bold text-slate-900 flex items-center gap-2">
                <HeartHandshake className="w-5 h-5 text-purple-600" />
                تأكيد تجهيز دفعة تبرع لبنك الطعام إطعام
              </h3>
              <button onClick={() => setShowDonationModal(false)} className="text-slate-400 hover:text-slate-600">
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleCreateDonationBatch} className="space-y-4">
              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1">الجهة الخيرية الشريكة</label>
                <select
                  value={donationCharity}
                  onChange={(e) => setDonationCharity(e.target.value)}
                  className="w-full px-3 py-2 border rounded-lg text-sm bg-white"
                >
                  <option value="جمعية إطعام لحفظ النعمة بالرياض">جمعية إطعام لحفظ النعمة بالرياض</option>
                  <option value="مبادرة بنك الطعام الوطني السعودي">مبادرة بنك الطعام الوطني السعودي</option>
                </select>
              </div>

              <div className="p-3 bg-purple-50 rounded-xl space-y-2 text-xs text-purple-900 border border-purple-100">
                <div className="flex justify-between">
                  <span>الأصناف المرشحة (صلاحية أقل من 12 ساعة):</span>
                  <span className="font-bold">25 صنف مبرد</span>
                </div>
                <div className="flex justify-between">
                  <span>الوجبات الغذائية التقديرية:</span>
                  <span className="font-bold text-emerald-700">38 وجبة متكاملة</span>
                </div>
                <div className="flex justify-between">
                  <span>معايير النقل:</span>
                  <span className="font-bold">شاحنة مبردة بدرجة 4 مئوية</span>
                </div>
              </div>

              <div className="flex items-center justify-end gap-3 pt-3 border-t">
                <button
                  type="button"
                  onClick={() => setShowDonationModal(false)}
                  className="px-4 py-2 border rounded-lg text-sm text-slate-600 hover:bg-slate-50"
                >
                  إلغاء
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 bg-purple-600 hover:bg-purple-700 text-white rounded-lg text-sm font-bold shadow-md shadow-purple-600/30 flex items-center gap-1.5"
                >
                  <Send className="w-4 h-4" />
                  إرسال إشعار التجهيز لإطعام
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
