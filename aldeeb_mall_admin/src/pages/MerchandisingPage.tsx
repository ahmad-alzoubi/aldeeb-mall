import React, { useState } from 'react';
import { 
  Sparkles, 
  Split, 
  Layers, 
  ArrowUpDown, 
  TrendingUp, 
  Eye, 
  MousePointerClick, 
  ShoppingBag,
  CheckCircle2,
  Trophy
} from 'lucide-react';

interface ShelfSection {
  id: string;
  nameAr: string;
  type: string;
  isEnabled: boolean;
  order: number;
}

interface ABExperiment {
  id: string;
  name: string;
  targetShelf: string;
  variantA: {
    title: string;
    image: string;
    impressions: number;
    clicks: number;
    ctr: number;
    conversions: number;
  };
  variantB: {
    title: string;
    image: string;
    impressions: number;
    clicks: number;
    ctr: number;
    conversions: number;
  };
  status: 'running' | 'completed';
  winner?: 'A' | 'B';
}

export const MerchandisingPage: React.FC = () => {
  const [shelves, setShelves] = useState<ShelfSection[]>([
    { id: '1', nameAr: 'شريط الفلاتر الصحية والأنظمة الغذائية (Dietary Filter Strip)', type: 'filter', isEnabled: true, order: 1 },
    { id: '2', nameAr: 'عروض الفلاش والتخفيضات اليومية (Flash Deals Scroller)', type: 'deals', isEnabled: true, order: 2 },
    { id: '3', nameAr: 'مجلة عروض الديب الأسبوعية التفاعلية (Digital Flyer)', type: 'flyer', isEnabled: true, order: 3 },
    { id: '4', nameAr: 'مشترياتك المعتادة والطلب بضغطة واحدة (Quick Reorder)', type: 'reorder', isEnabled: true, order: 4 },
    { id: '5', nameAr: 'صفقات الشراء الجماعي التشاركي (Group Deals 40% Off)', type: 'group', isEnabled: true, order: 5 },
    { id: '6', nameAr: 'اشتراكات المؤن الدورية (Subscribe & Save 10%)', type: 'subscriptions', isEnabled: true, order: 6 },
    { id: '7', nameAr: 'شبكة المنتجات الشاملة وتصنيفات الهايبرماركت', type: 'catalog', isEnabled: true, order: 7 },
  ]);

  const [experiments, setExperiments] = useState<ABExperiment[]>([
    {
      id: 'exp-1',
      name: 'اختبار بانر عروض الـ 15 دقيقة (الأزرق الملكي مقابل الأحمر الخاطف)',
      targetShelf: 'Hero Banner',
      variantA: {
        title: 'النسخة A: النمط الكلاسيكي لكارفور (أزرق ملكي)',
        image: 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=500&auto=format&fit=crop&q=80',
        impressions: 12450,
        clicks: 1480,
        ctr: 11.9,
        conversions: 412,
      },
      variantB: {
        title: 'النسخة B: أسلوب نون دقائق السريع (أحمر خاطف)',
        image: 'https://images.unsplash.com/photo-1526367790999-0150786686a2?w=500&auto=format&fit=crop&q=80',
        impressions: 12890,
        clicks: 2110,
        ctr: 16.4,
        conversions: 685,
      },
      status: 'running',
    },
  ]);

  const [toastMessage, setToastMessage] = useState<string | null>(null);

  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(null), 3500);
  };

  const handleToggleShelf = (id: string) => {
    setShelves((prev) =>
      prev.map((s) => (s.id === id ? { ...s, isEnabled: !s.isEnabled } : s))
    );
    showToast('تم تحديث إعدادات عرض الرف على تطبيق العميل فوراً!');
  };

  const handlePromoteWinner = (expId: string, winner: 'A' | 'B') => {
    setExperiments((prev) =>
      prev.map((e) => (e.id === expId ? { ...e, status: 'completed', winner } : e))
    );
    showToast(`🏆 تم تعميم النسخة الفائزة (${winner}) على 100% من زوار التطبيق والمتجر بنجاح!`);
  };

  return (
    <div className="space-y-6">
      {/* Toast Alert */}
      {toastMessage && (
        <div className="bg-emerald-600 text-white px-5 py-3 rounded-xl shadow-lg flex items-center gap-3 animate-fade-in text-sm font-medium">
          <CheckCircle2 className="w-5 h-5 flex-shrink-0" />
          <span>{toastMessage}</span>
        </div>
      )}

      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 bg-white p-6 rounded-2xl border border-gray-100 shadow-sm">
        <div>
          <div className="flex items-center gap-2">
            <span className="p-2 bg-indigo-50 text-indigo-600 rounded-xl">
              <Layers className="w-6 h-6" />
            </span>
            <h1 className="text-2xl font-bold text-gray-900">هندسة العرض والاختبارات الذكية (Merchandising & A/B Testing)</h1>
          </div>
          <p className="text-gray-500 mt-1 text-sm">
            إدارة ترتيب رفوف وأقسام الصفحة الرئيسية لتطبيق العميل، وإطلاق اختبارات A/B لزيادة معدل التحويل والمبيعات
          </p>
        </div>
        <div className="flex items-center gap-2">
          <span className="px-3.5 py-1.5 bg-indigo-50 text-indigo-700 text-xs font-bold rounded-xl border border-indigo-200">
            {shelves.filter(s => s.isEnabled).length} رفوف نشطة حالياً
          </span>
        </div>
      </div>

      {/* A/B Testing Experiments */}
      <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-6">
        <div className="flex items-center justify-between pb-4 mb-4 border-b border-gray-100">
          <div className="flex items-center gap-2">
            <span className="p-2 bg-amber-50 text-amber-600 rounded-xl">
              <Split className="w-5 h-5" />
            </span>
            <div>
              <h2 className="text-base font-bold text-gray-900">اختبارات A/B لتحسين التحويل (Conversion Rate Optimization)</h2>
              <p className="text-xs text-gray-500">مقارنة أداء البانرات والحملات بصرياً وتحديد التصميم الأكثر جلباً للطلبات</p>
            </div>
          </div>
        </div>

        {experiments.map((exp) => (
          <div key={exp.id} className="border border-gray-200 rounded-2xl p-5 bg-gray-50/50">
            <div className="flex items-center justify-between mb-4">
              <span className="font-bold text-gray-900 text-sm">{exp.name}</span>
              <span className="text-xs font-semibold px-2.5 py-1 rounded-full bg-blue-50 text-blue-700 border border-blue-200">
                {exp.status === 'running' ? 'تجربة حية جارية (50/50 تقسيم الزوار)' : `مكتملة (الفائز: النسخة ${exp.winner})`}
              </span>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              {/* Variant A */}
              <div className={`p-4 rounded-xl border transition-all ${
                exp.winner === 'A' ? 'bg-emerald-50 border-emerald-300 ring-2 ring-emerald-500/20' : 'bg-white border-gray-200'
              }`}>
                <div className="flex items-center justify-between mb-3">
                  <span className="font-bold text-xs text-blue-700 bg-blue-50 px-2.5 py-1 rounded-lg">النسخة A (Control)</span>
                  <span className="text-xs text-gray-400 font-mono">12,450 مشاهدة</span>
                </div>
                <img src={exp.variantA.image} alt="Variant A" className="w-full h-32 object-cover rounded-lg mb-3" />
                <div className="text-xs font-bold text-gray-800 mb-3">{exp.variantA.title}</div>
                <div className="grid grid-cols-3 gap-2 text-center text-xs py-2 bg-gray-50 rounded-lg mb-3">
                  <div>
                    <span className="text-gray-400 block text-[10px]">النقرات</span>
                    <span className="font-bold text-gray-800">{exp.variantA.clicks}</span>
                  </div>
                  <div>
                    <span className="text-gray-400 block text-[10px]">نسبة النقر CTR</span>
                    <span className="font-bold text-gray-800">{exp.variantA.ctr}%</span>
                  </div>
                  <div>
                    <span className="text-gray-400 block text-[10px]">الطلبات الفعلية</span>
                    <span className="font-bold text-emerald-600">{exp.variantA.conversions}</span>
                  </div>
                </div>
                {exp.status === 'running' && (
                  <button 
                    onClick={() => handlePromoteWinner(exp.id, 'A')}
                    className="w-full py-2 bg-white hover:bg-gray-50 text-gray-700 border border-gray-300 rounded-xl text-xs font-bold transition-colors"
                  >
                    اعتماد النسخة A لجميع الزوار
                  </button>
                )}
              </div>

              {/* Variant B */}
              <div className={`p-4 rounded-xl border transition-all ${
                exp.winner === 'B' ? 'bg-emerald-50 border-emerald-300 ring-2 ring-emerald-500/20' : 'bg-white border-rose-200 shadow-sm'
              }`}>
                <div className="flex items-center justify-between mb-3">
                  <div className="flex items-center gap-1.5">
                    <span className="font-bold text-xs text-rose-700 bg-rose-50 px-2.5 py-1 rounded-lg">النسخة B (Challenger)</span>
                    <span className="flex items-center gap-1 text-[11px] text-emerald-600 font-bold bg-emerald-50 px-2 py-0.5 rounded">
                      <TrendingUp className="w-3 h-3" />
                      أعلى تحويلاً (+38%)
                    </span>
                  </div>
                  <span className="text-xs text-gray-400 font-mono">12,890 مشاهدة</span>
                </div>
                <img src={exp.variantB.image} alt="Variant B" className="w-full h-32 object-cover rounded-lg mb-3" />
                <div className="text-xs font-bold text-gray-800 mb-3">{exp.variantB.title}</div>
                <div className="grid grid-cols-3 gap-2 text-center text-xs py-2 bg-gray-50 rounded-lg mb-3">
                  <div>
                    <span className="text-gray-400 block text-[10px]">النقرات</span>
                    <span className="font-bold text-gray-800">{exp.variantB.clicks}</span>
                  </div>
                  <div>
                    <span className="text-gray-400 block text-[10px]">نسبة النقر CTR</span>
                    <span className="font-bold text-rose-600 font-black">{exp.variantB.ctr}%</span>
                  </div>
                  <div>
                    <span className="text-gray-400 block text-[10px]">الطلبات الفعلية</span>
                    <span className="font-bold text-emerald-600 font-black">{exp.variantB.conversions}</span>
                  </div>
                </div>
                {exp.status === 'running' && (
                  <button 
                    onClick={() => handlePromoteWinner(exp.id, 'B')}
                    className="w-full py-2 bg-emerald-600 hover:bg-emerald-700 text-white rounded-xl text-xs font-bold transition-colors flex items-center justify-center gap-1.5 shadow-sm"
                  >
                    <Trophy className="w-3.5 h-3.5" />
                    <span>اعتماد النسخة B الفائزة فوراً</span>
                  </button>
                )}
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Shelf Sections Priority Manager */}
      <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-6">
        <div className="flex items-center justify-between pb-4 mb-4 border-b border-gray-100">
          <div>
            <h2 className="text-base font-bold text-gray-900">ترتيب أولويات رفوف الصفحة الرئيسية (Home Shelves Priority)</h2>
            <p className="text-xs text-gray-500">التحكم في ظهور أو إخفاء الرفوف الترويجية في تطبيق الهاتف والويب</p>
          </div>
        </div>

        <div className="space-y-3">
          {shelves.map((shelf, idx) => (
            <div 
              key={shelf.id}
              className="flex items-center justify-between p-4 bg-gray-50/80 rounded-xl border border-gray-200/80 hover:bg-gray-100/80 transition-colors"
            >
              <div className="flex items-center gap-3">
                <span className="w-6 h-6 rounded-full bg-white border border-gray-300 flex items-center justify-center text-xs font-black text-gray-600">
                  {idx + 1}
                </span>
                <span className="font-bold text-gray-800 text-sm">{shelf.nameAr}</span>
              </div>
              <div className="flex items-center gap-3">
                <label className="relative inline-flex items-center cursor-pointer">
                  <input
                    type="checkbox"
                    checked={shelf.isEnabled}
                    onChange={() => handleToggleShelf(shelf.id)}
                    className="sr-only peer"
                  />
                  <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-emerald-600"></div>
                </label>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};
