import React, { useState } from 'react';
import { 
  ShieldCheck, 
  TrendingDown, 
  Scale, 
  Search, 
  CheckCircle2, 
  Clock, 
  AlertTriangle, 
  RefreshCw, 
  ExternalLink, 
  DollarSign, 
  Zap, 
  Check, 
  X, 
  Sliders,
  Sparkles
} from 'lucide-react';

interface PriceMatchClaim {
  id: string;
  customerName: string;
  customerPhone: string;
  productName: string;
  aldeebPrice: number;
  competitorName: string;
  competitorPrice: number;
  difference: number;
  refundAmount: number; // 2x difference
  proofUrl: string;
  submittedAt: string;
  status: 'PENDING' | 'APPROVED' | 'REJECTED';
}

interface CompetitorParityItem {
  id: string;
  barcode: string;
  name: string;
  category: string;
  aldeebPrice: number;
  pandaPrice: number;
  othaimPrice: number;
  carrefourPrice: number;
  luluPrice: number;
  status: 'ALDEEB_CHEAPEST' | 'MATCHED' | 'DISPARITY_ALERT';
}

const initialClaims: PriceMatchClaim[] = [
  {
    id: 'PMC-9912',
    customerName: 'عبدالرحمن الدوسري',
    customerPhone: '+966 50 882 1199',
    productName: 'حليب نيدو مجفف مدعم (2.5 كجم)',
    aldeebPrice: 94.0,
    competitorName: 'أسواق العثيم',
    competitorPrice: 87.5,
    difference: 6.5,
    refundAmount: 13.0,
    proofUrl: 'https://othaimmarkets.com/promo/nido-deal',
    submittedAt: 'منذ 15 دقيقة',
    status: 'PENDING',
  },
  {
    id: 'PMC-9911',
    customerName: 'سارة المنصور',
    customerPhone: '+966 55 334 2200',
    productName: 'زيت دوار الشمس عافية (2 × 1.5 لتر)',
    aldeebPrice: 38.0,
    competitorName: 'هايبر بندة',
    competitorPrice: 34.0,
    difference: 4.0,
    refundAmount: 8.0,
    proofUrl: 'https://panda.com.sa/weekly-flyer-afia',
    submittedAt: 'منذ ساعتين',
    status: 'PENDING',
  },
  {
    id: 'PMC-9908',
    customerName: 'فهد القحطاني',
    customerPhone: '+966 54 991 4433',
    productName: 'أرز كلاسيك الشعلان عنبر (10 كجم)',
    aldeebPrice: 78.0,
    competitorName: 'لولو هايبرماركت',
    competitorPrice: 72.0,
    difference: 6.0,
    refundAmount: 12.0,
    proofUrl: 'https://luluhypermarket.com/sa/rice-offer',
    submittedAt: 'أمس 08:30 م',
    status: 'APPROVED',
  },
];

const initialParityItems: CompetitorParityItem[] = [
  {
    id: 'PAR-01',
    barcode: '6281007001234',
    name: 'حليب المراعي كامل الدسم (2 لتر)',
    category: 'ألبان وأجبان',
    aldeebPrice: 11.5,
    pandaPrice: 11.5,
    othaimPrice: 11.5,
    carrefourPrice: 11.5,
    luluPrice: 12.0,
    status: 'MATCHED',
  },
  {
    id: 'PAR-02',
    barcode: '6281007005678',
    name: 'دجاج ساديا مجمد (10 × 1000غ كرتون)',
    category: 'مجمدات ولحوم',
    aldeebPrice: 152.0,
    pandaPrice: 158.0,
    othaimPrice: 156.0,
    carrefourPrice: 160.0,
    luluPrice: 154.0,
    status: 'ALDEEB_CHEAPEST',
  },
  {
    id: 'PAR-03',
    barcode: '7613035821902',
    name: 'حليب نيدو مجفف مدعم (2.5 كجم)',
    category: 'أغذية وحليب مجفف',
    aldeebPrice: 94.0,
    pandaPrice: 95.0,
    othaimPrice: 87.5,
    carrefourPrice: 96.0,
    luluPrice: 93.0,
    status: 'DISPARITY_ALERT',
  },
  {
    id: 'PAR-04',
    barcode: '6281014002345',
    name: 'زيت دوار الشمس عافية (2 × 1.5 لتر)',
    category: 'زيوت وسمن',
    aldeebPrice: 38.0,
    pandaPrice: 34.0,
    othaimPrice: 39.0,
    carrefourPrice: 37.5,
    luluPrice: 38.5,
    status: 'DISPARITY_ALERT',
  },
  {
    id: 'PAR-05',
    barcode: '6281017009871',
    name: 'سكر الأسرة ناعم أكياس (10 كجم)',
    category: 'تموين وبقالة',
    aldeebPrice: 32.5,
    pandaPrice: 34.0,
    othaimPrice: 33.5,
    carrefourPrice: 35.0,
    luluPrice: 33.0,
    status: 'ALDEEB_CHEAPEST',
  },
];

export const PriceMatchPage: React.FC = () => {
  const [claims, setClaims] = useState<PriceMatchClaim[]>(initialClaims);
  const [items, setItems] = useState<CompetitorParityItem[]>(initialParityItems);
  const [activeTab, setActiveTab] = useState<'claims' | 'radar' | 'rules'>('claims');
  const [isScraping, setIsScraping] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');

  const handleSimulateScrape = () => {
    setIsScraping(true);
    setTimeout(() => {
      setIsScraping(false);
      alert('تم تحديث مسح أسعار 1,420 منتج من مواقع ونشرات بندة والعثيم وكارفور ولولو بنجاح!');
    }, 1200);
  };

  const handleApproveClaim = (claimId: string) => {
    const claim = claims.find(c => c.id === claimId);
    if (!claim) return;

    setClaims(claims.map(c => c.id === claimId ? { ...c, status: 'APPROVED' } : c));
    alert(`تمت الموافقة على طلب المطابقة وإيداع تعويض ${claim.refundAmount} ل.س كاش في محفظة العميل (${claim.customerName}) بنجاح!`);
  };

  const handleRejectClaim = (claimId: string) => {
    setClaims(claims.map(c => c.id === claimId ? { ...c, status: 'REJECTED' } : c));
  };

  const handleAutoMatchPrice = (itemId: string, newPrice: number) => {
    setItems(items.map(it => {
      if (it.id === itemId) {
        return {
          ...it,
          aldeebPrice: newPrice,
          status: 'MATCHED',
        };
      }
      return it;
    }));
    alert(`تم تعديل ومطابقة سعر المنتج في الكتالوج والتطبيق وفروع الكاشير فورياً إلى ${newPrice} ل.س!`);
  };

  const pendingClaimsCount = claims.filter(c => c.status === 'PENDING').length;
  const parityScore = 98.4;

  return (
    <div className="space-y-6">
      {/* Top Banner */}
      <div className="bg-gradient-to-r from-slate-900 via-blue-950 to-slate-900 border border-blue-900/50 rounded-2xl p-6 text-white shadow-xl flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <div>
          <div className="flex items-center gap-3">
            <div className="p-3 bg-blue-600/30 border border-blue-500/40 rounded-xl text-blue-400">
              <Scale className="w-7 h-7" />
            </div>
            <div>
              <h1 className="text-2xl font-bold flex items-center gap-2">
                منظومة مطابقة الأسعار الذكية ورادار المنافسين (Price Match & Parity Radar)
                <span className="text-xs bg-blue-500/20 text-blue-300 border border-blue-500/30 px-2.5 py-0.5 rounded-full font-mono">
                  Live Scraping Engine
                </span>
              </h1>
              <p className="text-sm text-slate-400 mt-1">
                رصد أسعار كبرى سلاسل الهايبرماركت بالمملكة، التنبيه بالفروقات، وتعويض العملاء بضعف الفرق كاش بالمحفظة
              </p>
            </div>
          </div>
        </div>

        <div className="flex items-center gap-3 w-full md:w-auto">
          <button
            onClick={handleSimulateScrape}
            disabled={isScraping}
            className="flex-1 md:flex-none flex items-center justify-center gap-2 bg-blue-600 hover:bg-blue-700 text-white font-medium px-4 py-2.5 rounded-xl transition shadow-lg shadow-blue-600/30 text-sm"
          >
            <RefreshCw className={`w-4 h-4 ${isScraping ? 'animate-spin' : ''}`} />
            مسح أسعار المنافسين الآن
          </button>
        </div>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs flex items-center justify-between">
          <div>
            <p className="text-xs font-medium text-slate-700">مؤشر أفضلية السعر (Parity Score)</p>
            <h3 className="text-2xl font-extrabold text-emerald-600 mt-1">{parityScore}%</h3>
            <p className="text-xs text-slate-700 font-medium mt-1 flex items-center gap-1">
              <ShieldCheck className="w-3.5 h-3.5 text-emerald-600" />
              الأرخص أو المتطابق في الرياض
            </p>
          </div>
          <div className="p-3 bg-emerald-50 text-emerald-600 rounded-xl">
            <Scale className="w-6 h-6" />
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs flex items-center justify-between">
          <div>
            <p className="text-xs font-medium text-slate-700">طلبات التعويض المعلقة</p>
            <h3 className="text-2xl font-extrabold text-amber-600 mt-1">{pendingClaimsCount} طلبات</h3>
            <p className="text-xs text-amber-700 font-medium mt-1 flex items-center gap-1">
              <Clock className="w-3.5 h-3.5" />
              متوسط وقت الرد: 4 دقائق
            </p>
          </div>
          <div className="p-3 bg-amber-50 text-amber-600 rounded-xl">
            <Clock className="w-6 h-6" />
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs flex items-center justify-between">
          <div>
            <p className="text-xs font-medium text-slate-700">إجمالي التعويضات المصروفة</p>
            <h3 className="text-2xl font-extrabold text-slate-900 mt-1">3,420 ل.س</h3>
            <p className="text-xs text-blue-600 font-medium mt-1">
              تعويض كاش في محافظ العملاء
            </p>
          </div>
          <div className="p-3 bg-blue-50 text-blue-600 rounded-xl">
            <DollarSign className="w-6 h-6" />
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs flex items-center justify-between">
          <div>
            <p className="text-xs font-medium text-slate-700">أصناف تحت الرصد اللحظي</p>
            <h3 className="text-2xl font-extrabold text-indigo-600 mt-1">1,420 صنف</h3>
            <p className="text-xs text-slate-700 font-medium mt-1">
              تحديث آلي كل ساعة من 5 سلاسل
            </p>
          </div>
          <div className="p-3 bg-indigo-50 text-indigo-600 rounded-xl">
            <Sparkles className="w-6 h-6" />
          </div>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex border-b border-slate-200">
        <button
          onClick={() => setActiveTab('claims')}
          className={`pb-3 px-4 text-sm font-bold border-b-2 flex items-center gap-2 transition ${
            activeTab === 'claims'
              ? 'border-blue-600 text-blue-600'
              : 'border-transparent text-slate-500 hover:text-slate-700'
          }`}
        >
          <Clock className="w-4 h-4" />
          طلبات تعويض العملاء الفورية ({claims.length})
        </button>

        <button
          onClick={() => setActiveTab('radar')}
          className={`pb-3 px-4 text-sm font-bold border-b-2 flex items-center gap-2 transition ${
            activeTab === 'radar'
              ? 'border-blue-600 text-blue-600'
              : 'border-transparent text-slate-500 hover:text-slate-700'
          }`}
        >
          <Scale className="w-4 h-4" />
          رادار مقارنة الأسعار مع المنافسين ({items.length})
        </button>

        <button
          onClick={() => setActiveTab('rules')}
          className={`pb-3 px-4 text-sm font-bold border-b-2 flex items-center gap-2 transition ${
            activeTab === 'rules'
              ? 'border-blue-600 text-blue-600'
              : 'border-transparent text-slate-500 hover:text-slate-700'
          }`}
        >
          <Sliders className="w-4 h-4" />
          قواعد المطابقة التلقائية والحدود السعرية
        </button>
      </div>

      {/* TAB 1: CLAIMS */}
      {activeTab === 'claims' && (
        <div className="space-y-4">
          <div className="bg-white rounded-xl border border-slate-200 overflow-hidden shadow-xs">
            <div className="overflow-x-auto">
              <table className="w-full text-right text-sm">
                <thead className="bg-slate-50 text-slate-700 text-xs font-bold border-b border-slate-200">
                  <tr>
                    <th className="p-3.5">العميل / الطلب</th>
                    <th className="p-3.5">المنتج المتنازع عليه</th>
                    <th className="p-3.5">سعر الديب</th>
                    <th className="p-3.5">المنافس وسعره</th>
                    <th className="p-3.5">الفرق</th>
                    <th className="p-3.5">مبلغ التعويض (2X كاش)</th>
                    <th className="p-3.5">إثبات الرابط / الصورة</th>
                    <th className="p-3.5">الحالة</th>
                    <th className="p-3.5 text-center">إجراءات الاعتماد</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {claims.map((c) => (
                    <tr key={c.id} className="hover:bg-slate-50 transition">
                      <td className="p-3.5">
                        <div className="font-bold text-slate-900">{c.customerName}</div>
                        <div className="text-xs text-slate-400 font-mono">{c.customerPhone} | {c.submittedAt}</div>
                      </td>
                      <td className="p-3.5 font-medium text-slate-800">
                        {c.productName}
                      </td>
                      <td className="p-3.5 font-bold text-slate-900">
                        {c.aldeebPrice.toFixed(2)} ل.س
                      </td>
                      <td className="p-3.5">
                        <div className="font-bold text-slate-800">{c.competitorName}</div>
                        <div className="text-xs font-bold text-red-600">{c.competitorPrice.toFixed(2)} ل.س</div>
                      </td>
                      <td className="p-3.5 text-red-600 font-bold">
                        -{c.difference.toFixed(2)} ل.س
                      </td>
                      <td className="p-3.5 font-extrabold text-emerald-600 text-base">
                        +{c.refundAmount.toFixed(2)} ل.س
                      </td>
                      <td className="p-3.5">
                        <a
                          href={c.proofUrl}
                          target="_blank"
                          rel="noreferrer"
                          className="inline-flex items-center gap-1 text-xs text-blue-600 hover:text-blue-800 font-medium"
                        >
                          <ExternalLink className="w-3 h-3" /> عرض الإثبات
                        </a>
                      </td>
                      <td className="p-3.5">
                        {c.status === 'PENDING' && (
                          <span className="bg-amber-100 text-amber-800 font-bold px-2 py-0.5 rounded-full text-xs">
                            بانتظار المراجعة
                          </span>
                        )}
                        {c.status === 'APPROVED' && (
                          <span className="bg-emerald-100 text-emerald-800 font-bold px-2 py-0.5 rounded-full text-xs inline-flex items-center gap-1">
                            <CheckCircle2 className="w-3 h-3" /> تم التعويض بالمحفظة
                          </span>
                        )}
                        {c.status === 'REJECTED' && (
                          <span className="bg-rose-100 text-rose-800 font-bold px-2 py-0.5 rounded-full text-xs">
                            مرفوض
                          </span>
                        )}
                      </td>
                      <td className="p-3.5 text-center">
                        {c.status === 'PENDING' ? (
                          <div className="flex items-center justify-center gap-2">
                            <button
                              onClick={() => handleApproveClaim(c.id)}
                              className="bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold px-3 py-1.5 rounded-lg flex items-center gap-1 transition"
                            >
                              <Check className="w-3 h-3" /> اعتماد وإيداع
                            </button>
                            <button
                              onClick={() => handleRejectClaim(c.id)}
                              className="bg-rose-50 hover:bg-rose-100 text-rose-700 text-xs font-bold px-2.5 py-1.5 rounded-lg transition"
                            >
                              <X className="w-3 h-3" /> رفض
                            </button>
                          </div>
                        ) : (
                          <span className="text-xs text-slate-400">مكتمل</span>
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

      {/* TAB 2: COMPETITOR PRICE RADAR */}
      {activeTab === 'radar' && (
        <div className="space-y-4">
          <div className="bg-white rounded-xl border border-slate-200 overflow-hidden shadow-xs">
            <div className="overflow-x-auto">
              <table className="w-full text-right text-sm">
                <thead className="bg-slate-50 text-slate-700 text-xs font-bold border-b border-slate-200">
                  <tr>
                    <th className="p-3.5">المنتج والباركود</th>
                    <th className="p-3.5">سعر الديب مول</th>
                    <th className="p-3.5">هايبر بندة</th>
                    <th className="p-3.5">أسواق العثيم</th>
                    <th className="p-3.5">كارفور</th>
                    <th className="p-3.5">لولو هايبر</th>
                    <th className="p-3.5">حالة التكافؤ</th>
                    <th className="p-3.5 text-center">المطابقة الفورية</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {items.map((it) => (
                    <tr key={it.id} className="hover:bg-slate-50 transition">
                      <td className="p-3.5">
                        <div className="font-bold text-slate-900">{it.name}</div>
                        <div className="text-xs text-slate-400 font-mono">{it.barcode} | {it.category}</div>
                      </td>
                      <td className="p-3.5 font-extrabold text-emerald-600 text-base">
                        {it.aldeebPrice.toFixed(2)} ل.س
                      </td>
                      <td className="p-3.5 text-slate-600 font-mono text-xs">
                        {it.pandaPrice.toFixed(2)} ل.س
                      </td>
                      <td className="p-3.5 text-slate-600 font-mono text-xs">
                        {it.othaimPrice.toFixed(2)} ل.س
                      </td>
                      <td className="p-3.5 text-slate-600 font-mono text-xs">
                        {it.carrefourPrice.toFixed(2)} ل.س
                      </td>
                      <td className="p-3.5 text-slate-600 font-mono text-xs">
                        {it.luluPrice.toFixed(2)} ل.س
                      </td>
                      <td className="p-3.5">
                        {it.status === 'ALDEEB_CHEAPEST' && (
                          <span className="bg-emerald-100 text-emerald-800 font-bold px-2 py-0.5 rounded text-xs">
                            الديب الأرخص 🏆
                          </span>
                        )}
                        {it.status === 'MATCHED' && (
                          <span className="bg-blue-100 text-blue-800 font-bold px-2 py-0.5 rounded text-xs">
                            متطابق تماماً
                          </span>
                        )}
                        {it.status === 'DISPARITY_ALERT' && (
                          <span className="bg-rose-100 text-rose-800 font-bold px-2 py-0.5 rounded text-xs flex items-center gap-1 w-max">
                            <AlertTriangle className="w-3 h-3" /> تنبيه: منافس أرخص
                          </span>
                        )}
                      </td>
                      <td className="p-3.5 text-center">
                        {it.status === 'DISPARITY_ALERT' ? (
                          <button
                            onClick={() => {
                              const lowestPrice = Math.min(it.pandaPrice, it.othaimPrice, it.carrefourPrice, it.luluPrice);
                              handleAutoMatchPrice(it.id, lowestPrice);
                            }}
                            className="bg-indigo-600 hover:bg-indigo-700 text-white text-xs font-bold px-3 py-1.5 rounded-lg flex items-center gap-1 mx-auto transition"
                          >
                            <Zap className="w-3 h-3" /> مطابقة لأقل سعر
                          </button>
                        ) : (
                          <span className="text-xs text-emerald-600 font-bold">السعر مثالي</span>
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

      {/* TAB 3: RULES */}
      {activeTab === 'rules' && (
        <div className="bg-white rounded-xl border border-slate-200 p-6 space-y-4 shadow-xs">
          <div>
            <h3 className="text-lg font-bold text-slate-900">سياسات مطابقة الأسعار التلقائية وضمان الـ 200%</h3>
            <p className="text-xs text-slate-500 mt-1">
              قواعد حماية هامش الربح والاعتماد الآلي الفوري لطلبات التعويض دون تدخل يدوي
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-4 pt-2">
            <div className="p-4 rounded-xl border border-blue-200 bg-blue-50/40">
              <span className="text-xs font-bold text-blue-800 bg-blue-200 px-2 py-0.5 rounded">الموافقة التلقائية</span>
              <h4 className="text-base font-bold text-slate-900 mt-2">التعويضات أقل من 25 ل.س</h4>
              <p className="text-xs text-slate-600 mt-1">
                تعتمد فورياً بواسطة خوارزمية الذكاء الاصطناعي وتودع في محفظة العميل خلال 60 ثانية لتعزيز الثقة.
              </p>
            </div>

            <div className="p-4 rounded-xl border border-amber-200 bg-amber-50/40">
              <span className="text-xs font-bold text-amber-800 bg-amber-200 px-2 py-0.5 rounded">التحقق اليدوي</span>
              <h4 className="text-base font-bold text-slate-900 mt-2">التعويضات فوق 25 ل.س</h4>
              <p className="text-xs text-slate-600 mt-1">
                تحال لمشرف قسم الأسعار لفحص رابط المنافس أو صورة المجلة الإعلانية للتأكد من تطابق الحجم والوزن.
              </p>
            </div>

            <div className="p-4 rounded-xl border border-emerald-200 bg-emerald-50/40">
              <span className="text-xs font-bold text-emerald-800 bg-emerald-200 px-2 py-0.5 rounded">حارس هامش الربح</span>
              <h4 className="text-base font-bold text-slate-900 mt-2">الحد الأدنى للتكلفة المباشرة</h4>
              <p className="text-xs text-slate-600 mt-1">
                لا تنخفض أسعار المطابقة التلقائية عن سعر التكلفة المباشرة للمورد لمنع البيع بالخسارة.
              </p>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
