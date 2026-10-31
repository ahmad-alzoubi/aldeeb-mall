import React, { useState } from 'react';
import { 
  Sparkles, 
  Plus, 
  Trash2, 
  Edit3, 
  Eye, 
  EyeOff, 
  CheckCircle2, 
  Image as ImageIcon, 
  Layers, 
  X,
  Sliders,
  MoveUp,
  MoveDown,
  LayoutGrid
} from 'lucide-react';
import { Banner, Category } from '../types';

interface BannersPageProps {
  banners: Banner[];
  categories: Category[];
  onAddBanner: (banner: Banner) => void;
  onUpdateBanner: (banner: Banner) => void;
  onDeleteBanner: (bannerId: string) => void;
  onToggleBanner: (bannerId: string) => void;
}

export const BannersPage: React.FC<BannersPageProps> = ({
  banners,
  categories,
  onAddBanner,
  onUpdateBanner,
  onDeleteBanner,
  onToggleBanner,
}) => {
  const [filterType, setFilterType] = useState<'all' | 'hero' | 'middle_secondary'>('all');
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingBanner, setEditingBanner] = useState<Banner | null>(null);

  // Form State
  const [titleAr, setTitleAr] = useState('');
  const [titleEn, setTitleEn] = useState('');
  const [subtitleAr, setSubtitleAr] = useState('');
  const [subtitleEn, setSubtitleEn] = useState('');
  const [imageUrl, setImageUrl] = useState('');
  const [badgeAr, setBadgeAr] = useState('');
  const [position, setPosition] = useState<'hero' | 'middle_secondary'>('hero');
  const [targetType, setTargetType] = useState<'category' | 'product' | 'deal' | 'external'>('deal');
  const [targetId, setTargetId] = useState('');
  const [toastMessage, setToastMessage] = useState<string | null>(null);

  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(null), 3000);
  };

  const handleOpenAdd = () => {
    setEditingBanner(null);
    setTitleAr('');
    setTitleEn('');
    setSubtitleAr('');
    setSubtitleEn('');
    setImageUrl('https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=1200&q=80');
    setBadgeAr('عرض خاص 🌟');
    setPosition('hero');
    setTargetType('deal');
    setTargetId('');
    setIsModalOpen(true);
  };

  const handleOpenEdit = (banner: Banner) => {
    setEditingBanner(banner);
    setTitleAr(banner.title_ar);
    setTitleEn(banner.title_en);
    setSubtitleAr(banner.subtitle_ar || '');
    setSubtitleEn(banner.subtitle_en || '');
    setImageUrl(banner.image_url);
    setBadgeAr(banner.badge_ar || '');
    setPosition(banner.position || 'hero');
    setTargetType(banner.target_type);
    setTargetId(banner.target_id || '');
    setIsModalOpen(true);
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!titleAr.trim() || !imageUrl.trim()) return;

    if (editingBanner) {
      const updated: Banner = {
        ...editingBanner,
        title_ar: titleAr,
        title_en: titleEn || titleAr,
        subtitle_ar: subtitleAr,
        subtitle_en: subtitleEn,
        image_url: imageUrl,
        badge_ar: badgeAr,
        position,
        target_type: targetType,
        target_id: targetId || undefined,
      };
      onUpdateBanner(updated);
      showToast('تم تحديث المنارة الإعلانية بنجاح!');
    } else {
      const newBanner: Banner = {
        id: `b-${Date.now()}`,
        title_ar: titleAr,
        title_en: titleEn || titleAr,
        subtitle_ar: subtitleAr,
        subtitle_en: subtitleEn,
        image_url: imageUrl,
        badge_ar: badgeAr,
        position,
        target_type: targetType,
        target_id: targetId || undefined,
        sort_order: banners.length + 1,
        is_active: true,
      };
      onAddBanner(newBanner);
      showToast('تمت إضافة المنارة الإعلانية المتنقلة بنجاح!');
    }

    setIsModalOpen(false);
  };

  const filteredBanners = banners.filter((b) => {
    if (filterType === 'all') return true;
    return (b.position || 'hero') === filterType;
  });

  return (
    <div className="space-y-6">
      {/* Toast Alert */}
      {toastMessage && (
        <div className="bg-emerald-600 text-white px-5 py-3 rounded-2xl shadow-xl flex items-center gap-3 animate-fade-in text-sm font-bold">
          <CheckCircle2 className="w-5 h-5 flex-shrink-0" />
          <span>{toastMessage}</span>
        </div>
      )}

      {/* Top Banner Control Header */}
      <div className="bg-white p-6 rounded-3xl border border-slate-200/80 shadow-sm flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <span className="p-2.5 bg-blue-50 text-blue-600 rounded-2xl">
              <Sparkles className="w-6 h-6" />
            </span>
            <h1 className="text-2xl font-black text-slate-900">
              إدارة المنارات الإعلانية والبانرات المتنقلة
            </h1>
          </div>
          <p className="text-slate-500 text-xs md:text-sm mt-1">
            التحكم الكامل في سلايدر الإعلانات المتنقلة بأعلى الصفحة الرئيسية، والإعلانات الفاصلة بين الأقسام
          </p>
        </div>

        <div className="flex items-center gap-3">
          <button
            onClick={handleOpenAdd}
            className="px-5 py-3 bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 text-white rounded-2xl text-xs font-black shadow-lg shadow-blue-500/20 transition-all flex items-center gap-2"
          >
            <Plus className="w-4 h-4" />
            إضافة منارة إعلانية جديدة
          </button>
        </div>
      </div>

      {/* Quick Filter Tabs */}
      <div className="flex items-center gap-2 bg-slate-100/80 p-1.5 rounded-2xl w-fit">
        <button
          onClick={() => setFilterType('all')}
          className={`px-4 py-2 rounded-xl text-xs font-black transition-all ${
            filterType === 'all'
              ? 'bg-white text-blue-700 shadow-sm'
              : 'text-slate-600 hover:text-slate-900'
          }`}
        >
          كل الإعلانات ({banners.length})
        </button>
        <button
          onClick={() => setFilterType('hero')}
          className={`px-4 py-2 rounded-xl text-xs font-black transition-all ${
            filterType === 'hero'
              ? 'bg-white text-blue-700 shadow-sm'
              : 'text-slate-600 hover:text-slate-900'
          }`}
        >
          منارات إعلانات متنقلة رئيسية ({banners.filter((b) => (b.position || 'hero') === 'hero').length})
        </button>
        <button
          onClick={() => setFilterType('middle_secondary')}
          className={`px-4 py-2 rounded-xl text-xs font-black transition-all ${
            filterType === 'middle_secondary'
              ? 'bg-white text-blue-700 shadow-sm'
              : 'text-slate-600 hover:text-slate-900'
          }`}
        >
          إعلانات فاصلة بين الأقسام ({banners.filter((b) => b.position === 'middle_secondary').length})
        </button>
      </div>

      {/* Banners Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {filteredBanners.map((banner, idx) => {
          const isHero = (banner.position || 'hero') === 'hero';
          return (
            <div
              key={banner.id}
              className={`bg-white rounded-3xl border transition-all overflow-hidden shadow-sm hover:shadow-md flex flex-col justify-between ${
                banner.is_active ? 'border-slate-200' : 'border-slate-200 opacity-60 bg-slate-50/50'
              }`}
            >
              {/* Banner Visual Preview */}
              <div className="relative h-48 w-full bg-slate-100 overflow-hidden">
                <img
                  src={banner.image_url}
                  alt={banner.title_ar}
                  className="w-full h-full object-cover"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/30 to-transparent" />
                
                {/* Position Badge & Status */}
                <div className="absolute top-4 left-4 right-4 flex items-center justify-between">
                  <span
                    className={`px-3 py-1 rounded-xl text-[11px] font-black shadow-sm ${
                      isHero
                        ? 'bg-blue-600 text-white'
                        : 'bg-amber-600 text-white'
                    }`}
                  >
                    {isHero ? 'منارة رئيسية متنقلة (Slider)' : 'إعلان فاصل بين الأقسام'}
                  </span>

                  <button
                    onClick={() => {
                      onToggleBanner(banner.id);
                      showToast(
                        banner.is_active
                          ? 'تم إخفاء الإعلان من التطبيق والمتجر'
                          : 'تم تفعيل ظهور الإعلان على التطبيق والمتجر'
                      );
                    }}
                    className={`p-2 rounded-xl backdrop-blur-md transition-all ${
                      banner.is_active
                        ? 'bg-emerald-500/90 text-white hover:bg-emerald-600'
                        : 'bg-slate-700/80 text-white hover:bg-slate-800'
                    }`}
                    title={banner.is_active ? 'تعطيل الإعلان' : 'تفعيل الإعلان'}
                  >
                    {banner.is_active ? <Eye className="w-4 h-4" /> : <EyeOff className="w-4 h-4" />}
                  </button>
                </div>

                {/* Banner Text Overlay */}
                <div className="absolute bottom-4 right-4 left-4 text-white">
                  {banner.badge_ar && (
                    <span className="inline-block px-2.5 py-0.5 bg-red-600 text-white text-[10px] font-black rounded-lg mb-1.5 shadow-sm">
                      {banner.badge_ar}
                    </span>
                  )}
                  <h3 className="text-base font-black leading-tight line-clamp-1">
                    {banner.title_ar}
                  </h3>
                  {banner.subtitle_ar && (
                    <p className="text-xs text-white/80 line-clamp-1 mt-0.5">
                      {banner.subtitle_ar}
                    </p>
                  )}
                </div>
              </div>

              {/* Banner Details & Action Footer */}
              <div className="p-4 flex items-center justify-between border-t border-slate-100 bg-white">
                <div className="text-xs text-slate-500 space-y-0.5">
                  <div className="flex items-center gap-2">
                    <span className="font-bold text-slate-700">الربط:</span>
                    <span className="px-2 py-0.5 bg-slate-100 rounded text-slate-600 font-mono text-[11px]">
                      {banner.target_type === 'category'
                        ? 'قسم هايبرماركت'
                        : banner.target_type === 'deal'
                        ? 'صفحة العروض والصفقات'
                        : 'رابط مباشر'}
                    </span>
                  </div>
                  <div className="text-[11px] text-slate-400">
                    الترتيب: #{idx + 1}
                  </div>
                </div>

                <div className="flex items-center gap-2">
                  <button
                    onClick={() => handleOpenEdit(banner)}
                    className="p-2.5 bg-slate-100 hover:bg-blue-50 text-slate-600 hover:text-blue-600 rounded-xl transition-all"
                    title="تعديل الإعلان"
                  >
                    <Edit3 className="w-4 h-4" />
                  </button>
                  <button
                    onClick={() => {
                      if (confirm('هل أنت متأكد من حذف هذه المنارة الإعلانية؟')) {
                        onDeleteBanner(banner.id);
                        showToast('تم حذف الإعلان بنجاح');
                      }
                    }}
                    className="p-2.5 bg-slate-100 hover:bg-red-50 text-slate-600 hover:text-red-600 rounded-xl transition-all"
                    title="حذف الإعلان"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {/* Add / Edit Modal */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4 overflow-y-auto">
          <div className="bg-white rounded-3xl max-w-xl w-full p-6 shadow-2xl space-y-4 my-8 border border-slate-100">
            <div className="flex items-center justify-between border-b pb-4">
              <div className="flex items-center gap-2">
                <span className="p-2 bg-blue-50 text-blue-600 rounded-xl">
                  <Sliders className="w-5 h-5" />
                </span>
                <h3 className="text-lg font-black text-slate-900">
                  {editingBanner ? 'تعديل المنارة الإعلانية' : 'إضافة منارة إعلانية جديدة للمول'}
                </h3>
              </div>
              <button
                onClick={() => setIsModalOpen(false)}
                className="text-slate-400 hover:text-slate-600 p-1.5 rounded-lg"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleSubmit} className="space-y-4 text-xs font-bold text-slate-700">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block mb-1 text-slate-600">العنوان بالعربية *</label>
                  <input
                    type="text"
                    required
                    placeholder="مثال: مهرجان الصفقات الكبرى 🛒"
                    value={titleAr}
                    onChange={(e) => setTitleAr(e.target.value)}
                    className="w-full p-3 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600"
                  />
                </div>
                <div>
                  <label className="block mb-1 text-slate-600">العنوان بالإنجليزية</label>
                  <input
                    type="text"
                    placeholder="Mega Supermarket Festival"
                    value={titleEn}
                    onChange={(e) => setTitleEn(e.target.value)}
                    className="w-full p-3 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600 text-left"
                    dir="ltr"
                  />
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block mb-1 text-slate-600">العنوان الفرعي بالعربية</label>
                  <input
                    type="text"
                    placeholder="خصومات تصل إلى 50% على الأغذية والمؤن"
                    value={subtitleAr}
                    onChange={(e) => setSubtitleAr(e.target.value)}
                    className="w-full p-3 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600"
                  />
                </div>
                <div>
                  <label className="block mb-1 text-slate-600">شارة الإعلان (Badge Ribbon)</label>
                  <input
                    type="text"
                    placeholder="مثال: خصم 50% أو طازج يومياً"
                    value={badgeAr}
                    onChange={(e) => setBadgeAr(e.target.value)}
                    className="w-full p-3 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600"
                  />
                </div>
              </div>

              <div>
                <label className="block mb-1 text-slate-600">رابط صورة الإعلان (URL) *</label>
                <div className="flex gap-2">
                  <input
                    type="url"
                    required
                    placeholder="https://images.unsplash.com/..."
                    value={imageUrl}
                    onChange={(e) => setImageUrl(e.target.value)}
                    className="w-full p-3 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600 text-left"
                    dir="ltr"
                  />
                </div>
                {imageUrl && (
                  <div className="mt-2 h-28 w-full rounded-xl overflow-hidden border border-slate-200 bg-slate-100">
                    <img src={imageUrl} alt="معاينة" className="w-full h-full object-cover" />
                  </div>
                )}
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block mb-1 text-slate-600">موضع ظهور الإعلان *</label>
                  <select
                    value={position}
                    onChange={(e) => setPosition(e.target.value as 'hero' | 'middle_secondary')}
                    className="w-full p-3 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600"
                  >
                    <option value="hero">منارات إعلانات متنقلة رئيسية (سلايدر أعلى الصفحة)</option>
                    <option value="middle_secondary">إعلان فاصل بين الأقسام (عرض كامل)</option>
                  </select>
                </div>

                <div>
                  <label className="block mb-1 text-slate-600">نوع الرابط / التوجيه عند النقر</label>
                  <select
                    value={targetType}
                    onChange={(e) => setTargetType(e.target.value as 'category' | 'product' | 'deal' | 'external')}
                    className="w-full p-3 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600"
                  >
                    <option value="deal">صفحة العروض والصفقات الكبرى</option>
                    <option value="category">قسم معين في الهايبرماركت</option>
                    <option value="product">منتج محدد بالباركود</option>
                    <option value="external">رابط خارجي</option>
                  </select>
                </div>
              </div>

              {targetType === 'category' && (
                <div>
                  <label className="block mb-1 text-slate-600">اختر القسم المرتبط</label>
                  <select
                    value={targetId}
                    onChange={(e) => setTargetId(e.target.value)}
                    className="w-full p-3 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600"
                  >
                    <option value="">-- اختر القسم --</option>
                    {categories.map((c) => (
                      <option key={c.id} value={c.id}>
                        {c.name_ar} ({c.name_en})
                      </option>
                    ))}
                  </select>
                </div>
              )}

              <div className="pt-4 border-t flex items-center justify-end gap-3">
                <button
                  type="button"
                  onClick={() => setIsModalOpen(false)}
                  className="px-5 py-2.5 bg-slate-100 hover:bg-slate-200 text-slate-700 rounded-xl font-bold transition-all"
                >
                  إلغاء
                </button>
                <button
                  type="submit"
                  className="px-6 py-2.5 bg-blue-600 hover:bg-blue-700 text-white rounded-xl font-bold transition-all shadow-md shadow-blue-600/20"
                >
                  {editingBanner ? 'حفظ التعديلات' : 'نشر الإعلان فوراً'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
