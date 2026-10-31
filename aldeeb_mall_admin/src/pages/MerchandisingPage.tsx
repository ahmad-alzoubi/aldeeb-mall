import React, { useState } from 'react';
import { 
  Sparkles, 
  Split, 
  Layers, 
  ArrowUpDown, 
  TrendingUp, 
  Eye, 
  EyeOff, 
  CheckCircle2, 
  Trophy,
  MoveUp,
  MoveDown,
  Edit3,
  Sliders,
  Search,
  Zap,
  Tag,
  Package,
  X
} from 'lucide-react';

export interface ShelfSection {
  id: string;
  nameAr: string;
  type: string;
  isEnabled: boolean;
  order: number;
  itemCountDesc?: string;
  customBadge?: string;
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
    { id: '1', nameAr: 'شريط البحث الذكي (ابحث بين أكثر من 10,000 منتج)', type: 'search', isEnabled: true, order: 1, itemCountDesc: 'أعلى الصفحة الرئيسية', customBadge: 'رئيسي' },
    { id: '2', nameAr: 'منارات الإعلانات المتنقلة (سلايدر العروض الترويجية المتحركة)', type: 'hero_banners', isEnabled: true, order: 2, itemCountDesc: '4 منارات متحركة', customBadge: 'متحرك تلقائي' },
    { id: '3', nameAr: 'أقسام وتصنيفات الهايبرماركت الكبرى (13 قسماً رئيسياً)', type: 'categories', isEnabled: true, order: 3, itemCountDesc: '13 قسم هايبرماركت', customBadge: 'أقسام رئيسية' },
    { id: '4', nameAr: 'عروض الأسبوع التوفيرية الكبرى (Weekly Deals)', type: 'weekly_deals', isEnabled: true, order: 4, itemCountDesc: 'تخفيضات حتى 50%', customBadge: 'مؤقت تنازلي' },
    { id: '5', nameAr: 'الإعلان الفاصل الأول (مهرجان التمور الملكية والبن)', type: 'middle_banner_1', isEnabled: true, order: 5, itemCountDesc: 'بانر تسويقي عريض', customBadge: 'إعلان فاصل' },
    { id: '6', nameAr: 'صفقات لا تفوت والكميات المحدودة (Can\'t Miss Hot Deals)', type: 'cant_miss', isEnabled: true, order: 6, itemCountDesc: 'شريط نفاذ الكمية', customBadge: 'عروض خاطفة' },
    { id: '7', nameAr: 'منتجات جديدة وصلت حديثاً إلى المول (New Arrivals)', type: 'new_arrivals', isEnabled: true, order: 7, itemCountDesc: 'أحدث الأصناف', customBadge: 'جديد' },
    { id: '8', nameAr: 'الإعلان الفاصل الثاني (عروض الأجهزة المنزلية وقلايات الهواء)', type: 'middle_banner_2', isEnabled: true, order: 8, itemCountDesc: 'بانر تسويقي عريض', customBadge: 'إعلان فاصل' },
    { id: '9', nameAr: 'خصومات كبرى وباقات التوفير العائلية (Mega Savings)', type: 'mega_savings', isEnabled: true, order: 9, itemCountDesc: 'توفير الحجم العائلي', customBadge: 'وفر أكثر' },
    { id: '10', nameAr: 'سوق الخضار والفواكه الطازجة - قطاف الصباح (Fresh Produce)', type: 'produce_shelf', isEnabled: true, order: 10, itemCountDesc: 'منتجات مزارع طازجة', customBadge: 'طازج يومياً' },
    { id: '11', nameAr: 'الملحمة واللحوم والدواجن الحلال (Halal Butcher & Poultry)', type: 'butcher_shelf', isEnabled: true, order: 11, itemCountDesc: 'ذبح بلدي وتبريد سريع', customBadge: 'حلال 100%' },
    { id: '12', nameAr: 'الألبان والأجبان والبيض البلدي (Dairy & Eggs)', type: 'dairy_shelf', isEnabled: true, order: 12, itemCountDesc: 'مزارع محلية', customBadge: 'يومي' },
    { id: '13', nameAr: 'العناية بالجمال والنظافة الشخصية (Beauty & Personal Care)', type: 'beauty_shelf', isEnabled: true, order: 13, itemCountDesc: 'عطور ومستحضرات', customBadge: 'أصلي' },
    { id: '14', nameAr: 'مشترياتك المعتادة والطلب بضغطة واحدة (Quick Reorder)', type: 'reorder', isEnabled: true, order: 14, itemCountDesc: 'تكرار الطلب السريع', customBadge: 'شخصي' },
    { id: '15', nameAr: 'شبكة المنتجات الشاملة وتصنيفات الهايبرماركت مع الفلاتر', type: 'catalog', isEnabled: true, order: 15, itemCountDesc: 'جميع الأصناف المتاحة', customBadge: 'كتالوج شامل' },
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

  const [searchTargetCount, setSearchTargetCount] = useState<string>('10,000');
  const [toastMessage, setToastMessage] = useState<string | null>(null);
  const [editingShelf, setEditingShelf] = useState<ShelfSection | null>(null);
  const [editTitleAr, setEditTitleAr] = useState<string>('');

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

  const handleMoveUp = (index: number) => {
    if (index === 0) return;
    const newShelves = [...shelves];
    const temp = newShelves[index - 1];
    newShelves[index - 1] = newShelves[index];
    newShelves[index] = temp;
    setShelves(newShelves);
    showToast('تم تعديل ترتيب ظهور الرف في الصفحة الرئيسية بنجاح!');
  };

  const handleMoveDown = (index: number) => {
    if (index === shelves.length - 1) return;
    const newShelves = [...shelves];
    const temp = newShelves[index + 1];
    newShelves[index + 1] = newShelves[index];
    newShelves[index] = temp;
    setShelves(newShelves);
    showToast('تم تعديل ترتيب ظهور الرف في الصفحة الرئيسية بنجاح!');
  };

  const handleSaveShelfTitle = (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingShelf || !editTitleAr.trim()) return;

    setShelves((prev) =>
      prev.map((s) => (s.id === editingShelf.id ? { ...s, nameAr: editTitleAr } : s))
    );
    setEditingShelf(null);
    showToast('تم تعديل عنوان الرف المعروض للعملاء بنجاح!');
  };

  const handlePromoteWinner = (expId: string, winner: 'A' | 'B') => {
    setExperiments((prev) =>
      prev.map((e) => (e.id === expId ? { ...e, status: 'completed', winner } : e))
    );
    showToast(`🏆 تم تعميم النسخة الفائزة (${winner}) على 100% من زوار التطبيق بنجاح!`);
  };

  return (
    <div className="space-y-6">
      {/* Toast Alert */}
      {toastMessage && (
        <div className="bg-emerald-600 text-white px-5 py-3 rounded-2xl shadow-xl flex items-center gap-3 animate-fade-in text-sm font-bold">
          <CheckCircle2 className="w-5 h-5 flex-shrink-0" />
          <span>{toastMessage}</span>
        </div>
      )}

      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 bg-white p-6 rounded-3xl border border-slate-200/80 shadow-sm">
        <div>
          <div className="flex items-center gap-2">
            <span className="p-2.5 bg-indigo-50 text-indigo-600 rounded-2xl">
              <Layers className="w-6 h-6" />
            </span>
            <h1 className="text-2xl font-black text-slate-900">
              هندسة واجهة الصفحة الرئيسية وعروض الهايبرماركت
            </h1>
          </div>
          <p className="text-slate-500 mt-1 text-xs md:text-sm">
            التحكم الكامل في ظهور وترتيب وعناوين جميع أقسام ورفوف الصفحة الرئيسية (البحث، المنارات المتنقلة، الأقسام، عروض الأسبوع، صفقات لا تفوت، والمنتجات الجديدة)
          </p>
        </div>
        <div className="flex items-center gap-2">
          <span className="px-4 py-2 bg-indigo-50 text-indigo-700 text-xs font-black rounded-2xl border border-indigo-200">
            {shelves.filter((s) => s.isEnabled).length} من أصل {shelves.length} رفوف معروضة
          </span>
        </div>
      </div>

      {/* Quick Search Bar Settings Widget */}
      <div className="bg-gradient-to-r from-blue-700 to-indigo-800 text-white p-6 rounded-3xl shadow-lg flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div className="flex items-center gap-4">
          <div className="p-3 bg-white/10 rounded-2xl backdrop-blur-md">
            <Search className="w-6 h-6 text-white" />
          </div>
          <div>
            <h3 className="text-base font-black">إعدادات شريط البحث بأعلى الصفحة</h3>
            <p className="text-xs text-blue-100 mt-0.5">
              النص الظاهر للمستخدم: "ابحث بين أكثر من {searchTargetCount} منتج في الديب مول..."
            </p>
          </div>
        </div>

        <div className="flex items-center gap-3">
          <label className="text-xs font-bold text-blue-200">العدد المعروض:</label>
          <input
            type="text"
            value={searchTargetCount}
            onChange={(e) => {
              setSearchTargetCount(e.target.value);
              showToast(`تم تعيين عداد البحث إلى أكثر من ${e.target.value} منتج!`);
            }}
            className="w-28 p-2.5 bg-white/15 border border-white/20 rounded-xl text-white text-xs font-black text-center focus:outline-none focus:bg-white/25"
          />
          <button
            onClick={() => showToast('تم تحديث نص البحث اللحظي لتطبيق المتجر والويب!')}
            className="px-4 py-2.5 bg-white text-blue-800 rounded-xl text-xs font-black hover:bg-blue-50 transition-all shadow-sm"
          >
            تحديث النص
          </button>
        </div>
      </div>

      {/* Shelf Sections Priority & Visibility Manager */}
      <div className="bg-white rounded-3xl border border-slate-200/80 shadow-sm p-6 space-y-4">
        <div className="flex items-center justify-between pb-4 border-b border-slate-100">
          <div>
            <h2 className="text-base font-black text-slate-900 flex items-center gap-2">
              <Sliders className="w-5 h-5 text-blue-600" />
              ترتيب وعناوين رفوف وأقسام الصفحة الرئيسية
            </h2>
            <p className="text-xs text-slate-500 mt-0.5">
              يمكنك إعادة ترتيب الرفوف للأعلى وللأسفل، تفعيل أو إخفاء أي قسم، وتعديل عنوان القسم الظاهر للعملاء
            </p>
          </div>
        </div>

        <div className="space-y-3">
          {shelves.map((shelf, idx) => (
            <div 
              key={shelf.id}
              className={`flex flex-col sm:flex-row sm:items-center justify-between p-4 rounded-2xl border transition-all gap-3 ${
                shelf.isEnabled 
                  ? 'bg-slate-50/80 border-slate-200 hover:bg-slate-100/80' 
                  : 'bg-slate-100/50 border-slate-200/60 opacity-60'
              }`}
            >
              <div className="flex items-center gap-3">
                <span className="w-7 h-7 rounded-xl bg-white border border-slate-200 flex items-center justify-center text-xs font-black text-slate-700 shadow-xs">
                  {idx + 1}
                </span>

                <div>
                  <div className="flex items-center gap-2">
                    <span className="font-black text-slate-900 text-sm">{shelf.nameAr}</span>
                    {shelf.customBadge && (
                      <span className="text-[10px] font-bold px-2 py-0.5 rounded-lg bg-blue-50 text-blue-700 border border-blue-200">
                        {shelf.customBadge}
                      </span>
                    )}
                  </div>
                  {shelf.itemCountDesc && (
                    <span className="text-xs text-slate-400 mt-0.5 block">{shelf.itemCountDesc}</span>
                  )}
                </div>
              </div>

              <div className="flex items-center gap-2 self-end sm:self-center">
                {/* Reorder Buttons */}
                <div className="flex items-center bg-white border border-slate-200 rounded-xl overflow-hidden p-0.5">
                  <button
                    onClick={() => handleMoveUp(idx)}
                    disabled={idx === 0}
                    className="p-1.5 hover:bg-slate-100 text-slate-500 hover:text-blue-600 disabled:opacity-30 disabled:hover:bg-transparent rounded-lg transition-colors"
                    title="تحريك للأعلى"
                  >
                    <MoveUp className="w-4 h-4" />
                  </button>
                  <button
                    onClick={() => handleMoveDown(idx)}
                    disabled={idx === shelves.length - 1}
                    className="p-1.5 hover:bg-slate-100 text-slate-500 hover:text-blue-600 disabled:opacity-30 disabled:hover:bg-transparent rounded-lg transition-colors"
                    title="تحريك للأسفل"
                  >
                    <MoveDown className="w-4 h-4" />
                  </button>
                </div>

                {/* Edit Title Button */}
                <button
                  onClick={() => {
                    setEditingShelf(shelf);
                    setEditTitleAr(shelf.nameAr);
                  }}
                  className="p-2 bg-white hover:bg-blue-50 text-slate-500 hover:text-blue-600 border border-slate-200 rounded-xl transition-all"
                  title="تعديل عنوان الرف"
                >
                  <Edit3 className="w-4 h-4" />
                </button>

                {/* Active Switch */}
                <label className="relative inline-flex items-center cursor-pointer mr-2">
                  <input
                    type="checkbox"
                    checked={shelf.isEnabled}
                    onChange={() => handleToggleShelf(shelf.id)}
                    className="sr-only peer"
                  />
                  <div className="w-11 h-6 bg-slate-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-slate-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-emerald-600"></div>
                </label>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* A/B Testing Experiments */}
      <div className="bg-white rounded-3xl border border-slate-200/80 shadow-sm p-6">
        <div className="flex items-center justify-between pb-4 mb-4 border-b border-slate-100">
          <div className="flex items-center gap-2">
            <span className="p-2.5 bg-amber-50 text-amber-600 rounded-2xl">
              <Split className="w-5 h-5" />
            </span>
            <div>
              <h2 className="text-base font-black text-slate-900">اختبارات A/B لتحسين معدل التحويل (CRO)</h2>
              <p className="text-xs text-slate-500">مقارنة أداء البانرات والحملات لتحديد التصميم الأكثر جلباً للطلبات</p>
            </div>
          </div>
        </div>

        {experiments.map((exp) => (
          <div key={exp.id} className="border border-slate-200 rounded-2xl p-5 bg-slate-50/50">
            <div className="flex items-center justify-between mb-4">
              <span className="font-black text-slate-900 text-sm">{exp.name}</span>
              <span className="text-xs font-bold px-3 py-1 rounded-full bg-blue-50 text-blue-700 border border-blue-200">
                {exp.status === 'running' ? 'تجربة حية جارية (50/50 تقسيم الزوار)' : `مكتملة (الفائز: النسخة ${exp.winner})`}
              </span>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              {/* Variant A */}
              <div className={`p-4 rounded-2xl border transition-all ${
                exp.winner === 'A' ? 'bg-emerald-50 border-emerald-300 ring-2 ring-emerald-500/20' : 'bg-white border-slate-200'
              }`}>
                <div className="flex items-center justify-between mb-3">
                  <span className="font-bold text-xs text-blue-700 bg-blue-50 px-2.5 py-1 rounded-lg">النسخة A (Control)</span>
                  <span className="text-xs text-slate-400 font-mono">12,450 مشاهدة</span>
                </div>
                <img src={exp.variantA.image} alt="Variant A" className="w-full h-32 object-cover rounded-xl mb-3" />
                <div className="text-xs font-bold text-slate-800 mb-3">{exp.variantA.title}</div>
                <div className="grid grid-cols-3 gap-2 text-center text-xs py-2 bg-slate-50 rounded-xl mb-3">
                  <div>
                    <span className="text-slate-400 block text-[10px]">النقرات</span>
                    <span className="font-bold text-slate-800">{exp.variantA.clicks}</span>
                  </div>
                  <div>
                    <span className="text-slate-400 block text-[10px]">نسبة النقر CTR</span>
                    <span className="font-bold text-slate-800">{exp.variantA.ctr}%</span>
                  </div>
                  <div>
                    <span className="text-slate-400 block text-[10px]">الطلبات الفعلية</span>
                    <span className="font-bold text-emerald-600">{exp.variantA.conversions}</span>
                  </div>
                </div>
                {exp.status === 'running' && (
                  <button 
                    onClick={() => handlePromoteWinner(exp.id, 'A')}
                    className="w-full py-2 bg-white hover:bg-slate-50 text-slate-700 border border-slate-300 rounded-xl text-xs font-bold transition-colors"
                  >
                    اعتماد النسخة A لجميع الزوار
                  </button>
                )}
              </div>

              {/* Variant B */}
              <div className={`p-4 rounded-2xl border transition-all ${
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
                  <span className="text-xs text-slate-400 font-mono">12,890 مشاهدة</span>
                </div>
                <img src={exp.variantB.image} alt="Variant B" className="w-full h-32 object-cover rounded-xl mb-3" />
                <div className="text-xs font-bold text-slate-800 mb-3">{exp.variantB.title}</div>
                <div className="grid grid-cols-3 gap-2 text-center text-xs py-2 bg-slate-50 rounded-xl mb-3">
                  <div>
                    <span className="text-slate-400 block text-[10px]">النقرات</span>
                    <span className="font-bold text-slate-800">{exp.variantB.clicks}</span>
                  </div>
                  <div>
                    <span className="text-slate-400 block text-[10px]">نسبة النقر CTR</span>
                    <span className="font-bold text-rose-600 font-black">{exp.variantB.ctr}%</span>
                  </div>
                  <div>
                    <span className="text-slate-400 block text-[10px]">الطلبات الفعلية</span>
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

      {/* Edit Title Modal */}
      {editingShelf && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl max-w-md w-full p-6 shadow-2xl space-y-4 border border-slate-100">
            <div className="flex items-center justify-between border-b pb-3">
              <h3 className="text-base font-black text-slate-900">تعديل عنوان الرف في التطبيق</h3>
              <button onClick={() => setEditingShelf(null)} className="text-slate-400 hover:text-slate-600 p-1">
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleSaveShelfTitle} className="space-y-4 text-xs font-bold text-slate-700">
              <div>
                <label className="block mb-1 text-slate-600">العنوان المعروض بالعربية *</label>
                <input
                  type="text"
                  required
                  value={editTitleAr}
                  onChange={(e) => setEditTitleAr(e.target.value)}
                  className="w-full p-3 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600"
                />
              </div>

              <div className="pt-3 flex justify-end gap-2 border-t">
                <button
                  type="button"
                  onClick={() => setEditingShelf(null)}
                  className="px-4 py-2 bg-slate-100 hover:bg-slate-200 text-slate-600 rounded-xl text-xs font-bold"
                >
                  إلغاء
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-xl text-xs font-black shadow-md shadow-blue-600/30"
                >
                  حفظ العنوان
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
