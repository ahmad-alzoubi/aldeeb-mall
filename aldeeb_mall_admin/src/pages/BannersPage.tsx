import React, { useState } from 'react';
import { 
  Plus, 
  Image as ImageIcon, 
  X, 
  Edit3, 
  Trash2, 
  Eye, 
  EyeOff, 
  Sparkles, 
  Smartphone, 
  Monitor, 
  CheckCircle2,
  Sliders,
  ChevronLeft,
  ChevronRight
} from 'lucide-react';
import { Banner, Category, Product, Coupon } from '../types';
import { generateUUID, ensureUUID } from '../lib/uuidUtils';

interface BannersPageProps {
  banners: Banner[];
  categories: Category[];
  products: Product[];
  coupons: Coupon[];
  onAddBanner: (banner: Banner) => void;
  onUpdateBanner: (banner: Banner) => void;
  onDeleteBanner: (bannerId: string) => void;
  onToggleBanner: (bannerId: string) => void;
}

const IN_APP_SCREENS = [
  { id: 'flash_deals', name: 'عروض الفلاش والصفقات الخاطفة (Flash Deals)', icon: '⚡' },
  { id: 'loyalty', name: 'نادي مكافآت الديب ونقاط الولاء (Loyalty)', icon: '⭐' },
  { id: 'group_deals', name: 'الشراء الجماعي وتوفير الجيران (Group Deals)', icon: '👥' },
  { id: 'grocery_list', name: 'القائمة الذكية ومخطط المقاضي (Smart List)', icon: '📝' },
  { id: 'flyer', name: 'مجلة عروض الديب الأسبوعية الرقمية (Flyer)', icon: '📰' },
  { id: 'cart', name: 'سلة المشتريات (Cart)', icon: '🛒' },
  { id: 'orders', name: 'متابعة وتتبع الطلبات (Orders Tracking)', icon: '🛵' },
];

const PRESET_IMAGES = [
  {
    name: 'طماطم طازجة 🍅',
    url: 'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?auto=format&fit=crop&w=600&q=80',
    titleAr: 'صفقة اليوم الطازجة 🍅',
    subtitleAr: 'طماطم مزارع محلية قطاف الصباح بخصم 25%',
    badge: '3.75 د.أ / كجم',
    badgeColor: '#EF4444',
  },
  {
    name: 'توصيل فوري 🛵',
    url: 'https://images.unsplash.com/photo-1526367790999-0150786686a2?auto=format&fit=crop&w=600&q=80',
    titleAr: 'توصيل فوري خلال 60 دقيقة 🛵',
    subtitleAr: 'اطلب طلبات البيت واستلمها على بابك',
    badge: 'مجاناً للطلبات فوق 100 د.أ',
    badgeColor: '#0284C7',
  },
  {
    name: 'سوبرماركت التوفير 🛒',
    url: 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=1200&q=80',
    titleAr: 'مهرجان الصفقات الكبرى في الديب مول 🛒',
    subtitleAr: 'خصومات حصرية تصل إلى 50% على المواد الغذائية',
    badge: 'خصم حتى 50%',
    badgeColor: '#DC2626',
  },
  {
    name: 'سوق الخضار الطازج 🍎',
    url: 'https://images.unsplash.com/photo-1610348725531-843dff563e2c?auto=format&fit=crop&w=1200&q=80',
    titleAr: 'سوق الخضار والفواكه قطاف اليوم 🍎',
    subtitleAr: 'من المزرعة إلى مائدتك بتوصيل فوري مبرد وسريع',
    badge: 'طازج يومياً',
    badgeColor: '#16A34A',
  },
  {
    name: 'أجهزة وقلايات ⚡',
    url: 'https://images.unsplash.com/photo-1550009158-9ebf69173e03?auto=format&fit=crop&w=1200&q=80',
    titleAr: 'عروض الأجهزة المنزلية وقلايات الهواء ⚡',
    subtitleAr: 'وفر حتى 300 د.أ مع ضمان سنتين صيانة شاملة',
    badge: 'ضمان سنتين',
    badgeColor: '#0284C7',
  },
];

const BADGE_COLORS = [
  { name: 'أحمر ناري', hex: '#EF4444', class: 'bg-red-500' },
  { name: 'أزرق ملكي', hex: '#0284C7', class: 'bg-sky-600' },
  { name: 'أخضر طبيعي', hex: '#10B981', class: 'bg-emerald-500' },
  { name: 'برتقالي مشرق', hex: '#EA580C', class: 'bg-orange-600' },
  { name: 'كهرماني', hex: '#F59E0B', class: 'bg-amber-500' },
  { name: 'بنفسجي فاخر', hex: '#7C3AED', class: 'bg-purple-600' },
];

export const BannersPage: React.FC<BannersPageProps> = ({
  banners,
  categories,
  products = [],
  coupons = [],
  onAddBanner,
  onUpdateBanner,
  onDeleteBanner,
  onToggleBanner,
}) => {
  const [selectedSlot, setSelectedSlot] = useState<string>('all');
  const [previewMode, setPreviewMode] = useState<'desktop' | 'mobile'>('desktop');
  const [previewCarouselIdx, setPreviewCarouselIdx] = useState(0);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingBanner, setEditingBanner] = useState<Banner | null>(null);
  const [toastMessage, setToastMessage] = useState<string | null>(null);

  // Form State
  const [titleAr, setTitleAr] = useState('');
  const [titleEn, setTitleEn] = useState('');
  const [subtitleAr, setSubtitleAr] = useState('');
  const [subtitleEn, setSubtitleEn] = useState('');
  const [imageUrl, setImageUrl] = useState('');
  const [slot, setSlot] = useState<Banner['slot']>('hero');
  const [targetType, setTargetType] = useState<'category' | 'screen' | 'product' | 'coupon' | 'deal' | 'external'>('screen');
  const [targetId, setTargetId] = useState('flash_deals');
  const [badgeAr, setBadgeAr] = useState('');
  const [badgeColor, setBadgeColor] = useState('#EF4444');
  const [sortOrder, setSortOrder] = useState(1);
  const [isActive, setIsActive] = useState(true);

  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(null), 3000);
  };

  const openAddModal = (presetSlot?: Banner['slot']) => {
    setEditingBanner(null);
    setTitleAr('');
    setTitleEn('');
    setSubtitleAr('');
    setSubtitleEn('');
    setImageUrl(PRESET_IMAGES[0].url);
    setSlot(presetSlot || 'hero');
    setTargetType('screen');
    setTargetId('flash_deals');
    setBadgeAr('');
    setBadgeColor('#EF4444');
    setSortOrder(banners.length + 1);
    setIsActive(true);
    setIsModalOpen(true);
  };

  const openEditModal = (b: Banner) => {
    setEditingBanner(b);
    setTitleAr(b.title_ar);
    setTitleEn(b.title_en || '');
    setSubtitleAr(b.subtitle_ar || '');
    setSubtitleEn(b.subtitle_en || '');
    setImageUrl(b.image_url);
    setSlot(b.slot || (b.position === 'middle_secondary' ? 'middle_secondary' : 'hero'));
    setTargetType(b.target_type || 'screen');
    setTargetId(b.target_id || '');
    setBadgeAr(b.badge_ar || '');
    setBadgeColor(b.badge_color || '#EF4444');
    setSortOrder(b.sort_order || 1);
    setIsActive(b.is_active !== false);
    setIsModalOpen(true);
  };

  const handleSave = (e: React.FormEvent) => {
    e.preventDefault();
    if (!titleAr.trim() || !imageUrl.trim()) {
      showToast('يرجى كتابة عنوان البانر ورابط الصورة');
      return;
    }

    const payload: Banner = {
      id: editingBanner ? ensureUUID(editingBanner.id) : generateUUID(),
      title_ar: titleAr.trim(),
      title_en: titleEn.trim() || titleAr.trim(),
      subtitle_ar: subtitleAr.trim() || undefined,
      subtitle_en: subtitleEn.trim() || undefined,
      image_url: imageUrl.trim(),
      slot: slot,
      position: slot === 'middle_secondary' ? 'middle_secondary' : 'hero',
      target_type: targetType,
      target_id: targetId.trim() || undefined,
      badge_ar: badgeAr.trim() || undefined,
      badge_color: badgeColor,
      sort_order: Number(sortOrder) || 1,
      is_active: isActive,
    };

    if (editingBanner) {
      onUpdateBanner(payload);
      showToast('تم تحديث بيانات البانر بنجاح! ✨');
    } else {
      onAddBanner(payload);
      showToast('تمت إضافة البانر الترويجي بنجاح! 🎉');
    }
    setIsModalOpen(false);
  };

  const applyPreset = (preset: typeof PRESET_IMAGES[0]) => {
    setImageUrl(preset.url);
    setTitleAr(preset.titleAr);
    setSubtitleAr(preset.subtitleAr);
    setBadgeAr(preset.badge);
    setBadgeColor(preset.badgeColor);
  };

  // Filtered List
  const filteredBanners = banners.filter((b) => {
    if (selectedSlot === 'all') return true;
    return b.slot === selectedSlot;
  });

  const heroBanners = banners.filter((b) => (b.slot === 'hero' || (!b.slot && b.position === 'hero')) && b.is_active);
  const sideTopBanner = banners.find((b) => b.slot === 'side_top' && b.is_active);
  const sideBottomBanner = banners.find((b) => b.slot === 'side_bottom' && b.is_active);

  const getTargetLabel = (type: string, id?: string) => {
    if (!id && type !== 'external') return 'غير محدد';
    switch (type) {
      case 'category': {
        const cat = categories.find((c) => c.id === id || c.slug === id);
        return `🏢 قسم: ${cat ? cat.name_ar : id}`;
      }
      case 'product': {
        const prod = products.find((p) => p.id === id);
        return `🛍️ منتج: ${prod ? prod.name_ar : id}`;
      }
      case 'screen': {
        const scr = IN_APP_SCREENS.find((s) => s.id === id);
        return `📱 صفحة: ${scr ? scr.name : id}`;
      }
      case 'coupon': {
        return `🎟️ كود خصم: ${id}`;
      }
      case 'external':
        return `🌐 رابط خارجي: ${id || 'Web'}`;
      default:
        return `⚡ إجراء: ${id || type}`;
    }
  };

  const getSlotBadge = (s: string) => {
    switch (s) {
      case 'hero':
        return <span className="px-2.5 py-1 text-xs font-bold rounded-lg bg-blue-100 text-blue-800 border border-blue-200">السلايدر الرئيسي</span>;
      case 'side_top':
        return <span className="px-2.5 py-1 text-xs font-bold rounded-lg bg-orange-100 text-orange-800 border border-orange-200">جانبي علوي (صفقة اليوم)</span>;
      case 'side_bottom':
        return <span className="px-2.5 py-1 text-xs font-bold rounded-lg bg-sky-100 text-sky-800 border border-sky-200">جانبي سفلي (توصيل فوري)</span>;
      case 'middle_secondary':
        return <span className="px-2.5 py-1 text-xs font-bold rounded-lg bg-purple-100 text-purple-800 border border-purple-200">إعلان فاصل بين الأقسام</span>;
      default:
        return <span className="px-2.5 py-1 text-xs font-bold rounded-lg bg-slate-100 text-slate-800">عام</span>;
    }
  };

  return (
    <div className="space-y-8 select-none">
      {/* Toast Notification */}
      {toastMessage && (
        <div className="fixed bottom-6 left-6 z-50 bg-slate-900 text-white px-5 py-3 rounded-2xl shadow-2xl flex items-center gap-3 border border-slate-700 animate-bounce">
          <CheckCircle2 className="w-5 h-5 text-emerald-400" />
          <span className="text-sm font-bold">{toastMessage}</span>
        </div>
      )}

      {/* Top Header & Actions */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 bg-white p-6 rounded-3xl shadow-xs border border-slate-200/80">
        <div>
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-2xl bg-gradient-to-tr from-blue-600 to-indigo-600 flex items-center justify-center text-white shadow-md shadow-blue-500/20">
              <ImageIcon className="w-5 h-5" />
            </div>
            <div>
              <h2 className="text-xl font-extrabold text-slate-900">إدارة البنرات والعروض التفاعلية (Hero & Promos)</h2>
              <p className="text-xs text-slate-500 font-medium mt-0.5">
                التحكم الكامل بالسلايدر الرئيسي، البطاقات الجانبية، وإجراءات النقر المباشر (التوجيه للأقسام، الصفحات، المنتجات، أو تفعيل الكوبونات)
              </p>
            </div>
          </div>
        </div>

        <div className="flex items-center gap-3">
          <button
            onClick={() => openAddModal()}
            className="flex items-center gap-2 bg-blue-600 hover:bg-blue-700 text-white px-5 py-2.5 rounded-xl font-bold text-sm shadow-md shadow-blue-600/30 transition-all hover:scale-[1.02] active:scale-[0.98]"
          >
            <Plus className="w-4 h-4" />
            <span>إضافة بانر جديد</span>
          </button>
        </div>
      </div>

      {/* Live Interactive Hypermarket Storefront Preview */}
      <div className="bg-slate-900 text-white p-6 rounded-3xl shadow-xl border border-slate-800">
        <div className="flex items-center justify-between pb-5 border-b border-slate-800">
          <div className="flex items-center gap-2.5">
            <Sparkles className="w-5 h-5 text-amber-400" />
            <h3 className="font-extrabold text-sm text-white">معاينة تفاعلية حية لواجهة الديب مول (Live Storefront Preview)</h3>
            <span className="text-[11px] bg-slate-800 text-slate-300 px-2.5 py-0.5 rounded-full border border-slate-700">
              انقر على أي كارت للتعديل السريع
            </span>
          </div>

          <div className="flex items-center bg-slate-800 p-1 rounded-xl border border-slate-700">
            <button
              onClick={() => setPreviewMode('desktop')}
              className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-bold transition-all ${
                previewMode === 'desktop' ? 'bg-blue-600 text-white shadow-sm' : 'text-slate-400 hover:text-white'
              }`}
            >
              <Monitor className="w-3.5 h-3.5" />
              <span>واجهة الويب (Split Hero)</span>
            </button>
            <button
              onClick={() => setPreviewMode('mobile')}
              className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-bold transition-all ${
                previewMode === 'mobile' ? 'bg-blue-600 text-white shadow-sm' : 'text-slate-400 hover:text-white'
              }`}
            >
              <Smartphone className="w-3.5 h-3.5" />
              <span>تطبيق الجوال (Mobile)</span>
            </button>
          </div>
        </div>

        {/* Preview Container */}
        <div className="mt-6 flex justify-center">
          {previewMode === 'desktop' ? (
            /* Desktop Split Layout (Matching User's Screenshot Exactly!) */
            <div className="w-full max-w-5xl bg-slate-950 p-6 rounded-2xl border border-slate-800">
              <div className="grid grid-cols-12 gap-4 h-[300px]">
                {/* Side 1/3 Promo Cards (Left in RTL - tomatoes and delivery) */}
                <div className="col-span-4 flex flex-col gap-3 h-full">
                  {/* Side Top Card */}
                  <div
                    onClick={() => sideTopBanner && openEditModal(sideTopBanner)}
                    className="relative flex-1 rounded-2xl overflow-hidden cursor-pointer group border border-slate-800 hover:border-amber-500/50 transition-all shadow-md"
                  >
                    <img
                      src={sideTopBanner?.image_url || PRESET_IMAGES[0].url}
                      alt="Side Top Promo"
                      className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
                    />
                    <div className="absolute inset-0 bg-gradient-to-t from-black/90 via-black/40 to-transparent flex flex-col justify-end p-3.5">
                      <div className="flex items-center justify-between mb-1">
                        <span
                          className="text-[10px] font-black text-white px-2 py-0.5 rounded-md"
                          style={{ backgroundColor: sideTopBanner?.badge_color || '#EF4444' }}
                        >
                          {sideTopBanner?.badge_ar || '3.75 د.أ / كجم'}
                        </span>
                        <span className="opacity-0 group-hover:opacity-100 transition-opacity text-[10px] bg-white/20 text-white px-1.5 py-0.5 rounded-md">
                          تعديل ✏️
                        </span>
                      </div>
                      <h4 className="text-xs font-bold text-white truncate">
                        {sideTopBanner?.title_ar || 'صفقة اليوم الطازجة 🍅'}
                      </h4>
                      <p className="text-[10px] text-white/70 truncate">
                        {sideTopBanner?.subtitle_ar || 'طماطم مزارع محلية قطاف الصباح بخصم 25%'}
                      </p>
                      <div className="mt-1 text-[9px] text-amber-300 font-medium truncate">
                        {sideTopBanner ? getTargetLabel(sideTopBanner.target_type, sideTopBanner.target_id) : '🎯 غير مرتبط'}
                      </div>
                    </div>
                  </div>

                  {/* Side Bottom Card */}
                  <div
                    onClick={() => sideBottomBanner && openEditModal(sideBottomBanner)}
                    className="relative flex-1 rounded-2xl overflow-hidden cursor-pointer group border border-slate-800 hover:border-sky-500/50 transition-all shadow-md"
                  >
                    <img
                      src={sideBottomBanner?.image_url || PRESET_IMAGES[1].url}
                      alt="Side Bottom Promo"
                      className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
                    />
                    <div className="absolute inset-0 bg-gradient-to-t from-black/90 via-black/40 to-transparent flex flex-col justify-end p-3.5">
                      <div className="flex items-center justify-between mb-1">
                        <span
                          className="text-[10px] font-black text-white px-2 py-0.5 rounded-md"
                          style={{ backgroundColor: sideBottomBanner?.badge_color || '#0284C7' }}
                        >
                          {sideBottomBanner?.badge_ar || 'مجاناً للطلبات فوق 100 د.أ'}
                        </span>
                        <span className="opacity-0 group-hover:opacity-100 transition-opacity text-[10px] bg-white/20 text-white px-1.5 py-0.5 rounded-md">
                          تعديل ✏️
                        </span>
                      </div>
                      <h4 className="text-xs font-bold text-white truncate">
                        {sideBottomBanner?.title_ar || 'توصيل فوري خلال 60 دقيقة 🛵'}
                      </h4>
                      <p className="text-[10px] text-white/70 truncate">
                        {sideBottomBanner?.subtitle_ar || 'اطلب طلبات البيت واستلمها على بابك'}
                      </p>
                      <div className="mt-1 text-[9px] text-sky-300 font-medium truncate">
                        {sideBottomBanner ? getTargetLabel(sideBottomBanner.target_type, sideBottomBanner.target_id) : '🎯 غير مرتبط'}
                      </div>
                    </div>
                  </div>
                </div>

                {/* Main 2/3 Hero Carousel (Right in RTL - courier delivery & promo) */}
                <div className="col-span-8 relative rounded-2xl overflow-hidden border border-slate-800 group shadow-lg">
                  {heroBanners.length > 0 ? (
                    (() => {
                      const current = heroBanners[previewCarouselIdx % heroBanners.length];
                      return (
                        <div
                          onClick={() => openEditModal(current)}
                          className="w-full h-full cursor-pointer relative"
                        >
                          <img
                            src={current.image_url}
                            alt="Hero Carousel"
                            className="w-full h-full object-cover group-hover:scale-102 transition-transform duration-500"
                          />
                          <div className="absolute inset-0 bg-gradient-to-t from-black/85 via-black/35 to-transparent flex flex-col justify-end p-6">
                            <div className="flex items-center justify-between mb-2">
                              {current.badge_ar && (
                                <span
                                  className="text-xs font-bold text-white px-3 py-1 rounded-lg"
                                  style={{ backgroundColor: current.badge_color || '#EF4444' }}
                                >
                                  {current.badge_ar}
                                </span>
                              )}
                              <span className="opacity-0 group-hover:opacity-100 transition-opacity text-xs bg-white/20 backdrop-blur-xs text-white px-2 py-1 rounded-lg">
                                تعديل البانر ✏️
                              </span>
                            </div>
                            <h3 className="text-lg font-black text-white mb-1">{current.title_ar}</h3>
                            {current.subtitle_ar && (
                              <p className="text-xs text-white/80 line-clamp-1">{current.subtitle_ar}</p>
                            )}
                            <div className="mt-2 text-xs text-emerald-400 font-bold flex items-center gap-1.5">
                              <span>وجهة النقر:</span>
                              <span>{getTargetLabel(current.target_type, current.target_id)}</span>
                            </div>
                          </div>
                        </div>
                      );
                    })()
                  ) : (
                    <div className="w-full h-full flex flex-col items-center justify-center text-slate-500">
                      <ImageIcon className="w-12 h-12 mb-2 stroke-1" />
                      <p className="text-xs">لا يوجد بنرات في السلايدر الرئيسي</p>
                    </div>
                  )}

                  {/* Carousel Controls */}
                  {heroBanners.length > 1 && (
                    <>
                      <button
                        onClick={(e) => {
                          e.stopPropagation();
                          setPreviewCarouselIdx((prev) => (prev - 1 + heroBanners.length) % heroBanners.length);
                        }}
                        className="absolute right-3 top-1/2 -translate-y-1/2 w-8 h-8 rounded-full bg-black/40 hover:bg-black/80 text-white flex items-center justify-center transition-all"
                      >
                        <ChevronRight className="w-4 h-4" />
                      </button>
                      <button
                        onClick={(e) => {
                          e.stopPropagation();
                          setPreviewCarouselIdx((prev) => (prev + 1) % heroBanners.length);
                        }}
                        className="absolute left-3 top-1/2 -translate-y-1/2 w-8 h-8 rounded-full bg-black/40 hover:bg-black/80 text-white flex items-center justify-center transition-all"
                      >
                        <ChevronLeft className="w-4 h-4" />
                      </button>

                      {/* Dots Indicator */}
                      <div className="absolute bottom-4 left-6 flex items-center gap-1.5">
                        {heroBanners.map((_, idx) => (
                          <span
                            key={idx}
                            onClick={(e) => {
                              e.stopPropagation();
                              setPreviewCarouselIdx(idx);
                            }}
                            className={`h-2 rounded-full cursor-pointer transition-all ${
                              previewCarouselIdx === idx ? 'w-6 bg-white' : 'w-2 bg-white/40'
                            }`}
                          />
                        ))}
                      </div>
                    </>
                  )}
                </div>
              </div>
            </div>
          ) : (
            /* Mobile Phone View */
            <div className="w-[340px] bg-slate-950 p-4 rounded-[40px] border-4 border-slate-700 shadow-2xl">
              <div className="w-20 h-4 bg-slate-800 rounded-full mx-auto mb-3" />
              {/* Mobile Carousel */}
              <div className="h-[150px] relative rounded-2xl overflow-hidden border border-slate-800">
                {heroBanners.length > 0 ? (
                  (() => {
                    const current = heroBanners[previewCarouselIdx % heroBanners.length];
                    return (
                      <div className="w-full h-full relative">
                        <img src={current.image_url} alt="Mobile Hero" className="w-full h-full object-cover" />
                        <div className="absolute inset-0 bg-gradient-to-t from-black/85 via-black/20 to-transparent flex flex-col justify-end p-3">
                          {current.badge_ar && (
                            <span
                              className="w-fit text-[9px] font-bold text-white px-1.5 py-0.5 rounded-sm mb-1"
                              style={{ backgroundColor: current.badge_color || '#EF4444' }}
                            >
                              {current.badge_ar}
                            </span>
                          )}
                          <h4 className="text-xs font-bold text-white truncate">{current.title_ar}</h4>
                        </div>
                      </div>
                    );
                  })()
                ) : (
                  <div className="w-full h-full flex items-center justify-center text-xs text-slate-500">
                    لا يوجد بنرات
                  </div>
                )}
              </div>

              {/* Dots */}
              <div className="flex justify-center gap-1 my-2">
                {heroBanners.map((_, idx) => (
                  <span
                    key={idx}
                    className={`h-1.5 rounded-full ${previewCarouselIdx === idx ? 'w-4 bg-blue-500' : 'w-1.5 bg-slate-700'}`}
                  />
                ))}
              </div>

              {/* Quick Side Deals Below Carousel on Mobile */}
              <div className="grid grid-cols-2 gap-2 mt-2">
                <div className="h-[80px] relative rounded-xl overflow-hidden border border-slate-800">
                  <img src={sideTopBanner?.image_url || PRESET_IMAGES[0].url} className="w-full h-full object-cover" />
                  <div className="absolute inset-0 bg-gradient-to-t from-black/90 to-transparent flex flex-col justify-end p-2">
                    <span className="text-[8px] font-bold text-amber-400 truncate">
                      {sideTopBanner?.badge_ar || '3.75 د.أ'}
                    </span>
                    <span className="text-[9px] font-bold text-white truncate">
                      {sideTopBanner?.title_ar || 'صفقة اليوم'}
                    </span>
                  </div>
                </div>

                <div className="h-[80px] relative rounded-xl overflow-hidden border border-slate-800">
                  <img src={sideBottomBanner?.image_url || PRESET_IMAGES[1].url} className="w-full h-full object-cover" />
                  <div className="absolute inset-0 bg-gradient-to-t from-black/90 to-transparent flex flex-col justify-end p-2">
                    <span className="text-[8px] font-bold text-sky-400 truncate">
                      {sideBottomBanner?.badge_ar || 'توصيل مجاني'}
                    </span>
                    <span className="text-[9px] font-bold text-white truncate">
                      {sideBottomBanner?.title_ar || 'توصيل فوري'}
                    </span>
                  </div>
                </div>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Filter Tabs by Placement */}
      <div className="flex flex-wrap items-center gap-2 border-b border-slate-200 pb-3">
        {[
          { id: 'all', label: `كافة البنرات (${banners.length})` },
          { id: 'hero', label: `السلايدر الرئيسي (${banners.filter((b) => b.slot === 'hero').length})` },
          { id: 'side_top', label: `البانر الجانبي العلوي (${banners.filter((b) => b.slot === 'side_top').length})` },
          { id: 'side_bottom', label: `البانر الجانبي السفلي (${banners.filter((b) => b.slot === 'side_bottom').length})` },
          { id: 'middle_secondary', label: `الفواصل الإعلانية (${banners.filter((b) => b.slot === 'middle_secondary').length})` },
        ].map((tab) => (
          <button
            key={tab.id}
            onClick={() => setSelectedSlot(tab.id)}
            className={`px-4 py-2 rounded-xl text-xs font-bold transition-all ${
              selectedSlot === tab.id
                ? 'bg-blue-600 text-white shadow-sm shadow-blue-500/20'
                : 'bg-white text-slate-600 hover:bg-slate-100 border border-slate-200'
            }`}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {/* Banners Grid / Table */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
        {filteredBanners.map((banner) => (
          <div
            key={banner.id}
            className={`bg-white rounded-2xl border transition-all hover:shadow-md flex flex-col justify-between overflow-hidden ${
              banner.is_active ? 'border-slate-200' : 'border-slate-200 opacity-60 bg-slate-50'
            }`}
          >
            {/* Banner Media Header */}
            <div className="relative h-44 w-full bg-slate-100">
              <img
                src={banner.image_url}
                alt={banner.title_ar}
                className="w-full h-full object-cover"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/20 to-transparent" />

              {/* Badges on Image */}
              <div className="absolute top-3 right-3 flex items-center gap-2">
                {getSlotBadge(banner.slot)}
              </div>

              <div className="absolute top-3 left-3 flex items-center gap-1.5">
                <button
                  onClick={() => onToggleBanner(banner.id)}
                  className={`p-1.5 rounded-lg backdrop-blur-md transition-all ${
                    banner.is_active
                      ? 'bg-emerald-500/90 text-white hover:bg-emerald-600'
                      : 'bg-slate-800/80 text-slate-400 hover:text-white'
                  }`}
                  title={banner.is_active ? 'تعطيل البانر' : 'تفعيل البانر'}
                >
                  {banner.is_active ? <Eye className="w-4 h-4" /> : <EyeOff className="w-4 h-4" />}
                </button>
              </div>

              {/* Title & Badge */}
              <div className="absolute bottom-3 right-3 left-3 text-white">
                {banner.badge_ar && (
                  <span
                    className="inline-block text-[10px] font-black px-2 py-0.5 rounded-md mb-1 text-white"
                    style={{ backgroundColor: banner.badge_color || '#EF4444' }}
                  >
                    {banner.badge_ar}
                  </span>
                )}
                <h4 className="text-sm font-extrabold line-clamp-1">{banner.title_ar}</h4>
                {banner.subtitle_ar && (
                  <p className="text-[11px] text-white/80 line-clamp-1 mt-0.5">{banner.subtitle_ar}</p>
                )}
              </div>
            </div>

            {/* Banner Details & Action Destination */}
            <div className="p-4 space-y-3 flex-1 flex flex-col justify-between">
              <div>
                <div className="bg-slate-50 p-2.5 rounded-xl border border-slate-200/80">
                  <div className="text-[11px] text-slate-400 font-medium mb-1">وجهة النقر (Action Target):</div>
                  <div className="text-xs font-bold text-slate-800 flex items-center gap-1.5 truncate">
                    <span>{getTargetLabel(banner.target_type, banner.target_id)}</span>
                  </div>
                </div>

                <div className="flex items-center justify-between text-xs text-slate-400 mt-2 px-1">
                  <span>الترتيب: #{banner.sort_order}</span>
                  <span className={banner.is_active ? 'text-emerald-600 font-bold' : 'text-slate-400'}>
                    {banner.is_active ? '● معروض حالياً' : '○ متوقف مؤقتاً'}
                  </span>
                </div>
              </div>

              {/* Action Buttons */}
              <div className="flex items-center gap-2 pt-2 border-t border-slate-100">
                <button
                  onClick={() => openEditModal(banner)}
                  className="flex-1 flex items-center justify-center gap-1.5 bg-blue-50 hover:bg-blue-100 text-blue-700 py-2 rounded-xl text-xs font-bold transition-colors"
                >
                  <Edit3 className="w-3.5 h-3.5" />
                  <span>تعديل الإعدادات والوجهة</span>
                </button>
                <button
                  onClick={() => {
                    if (confirm(`هل أنت متأكد من حذف البانر: "${banner.title_ar}"؟`)) {
                      onDeleteBanner(banner.id);
                      showToast('تم حذف البانر بنجاح');
                    }
                  }}
                  className="p-2 text-rose-500 hover:bg-rose-50 rounded-xl transition-colors"
                  title="حذف البانر"
                >
                  <Trash2 className="w-4 h-4" />
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Add / Edit Banner Modal */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs">
          <div className="bg-white rounded-3xl max-w-2xl w-full max-h-[90vh] overflow-y-auto shadow-2xl border border-slate-200">
            {/* Modal Header */}
            <div className="flex items-center justify-between p-6 border-b border-slate-100">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-2xl bg-blue-100 text-blue-600 flex items-center justify-center font-bold">
                  <ImageIcon className="w-5 h-5" />
                </div>
                <div>
                  <h3 className="text-lg font-extrabold text-slate-900">
                    {editingBanner ? 'تعديل البانر الترويجي' : 'إضافة بانر ترويجي جديد'}
                  </h3>
                  <p className="text-xs text-slate-400 font-medium">
                    حدد موضع البانر، تصميمه، ووجهة الانتقال عند النقر داخل التطبيق
                  </p>
                </div>
              </div>
              <button
                onClick={() => setIsModalOpen(false)}
                className="w-8 h-8 rounded-full hover:bg-slate-100 flex items-center justify-center text-slate-400 hover:text-slate-700"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Modal Form */}
            <form onSubmit={handleSave} className="p-6 space-y-5">
              {/* Placement / Slot Selector */}
              <div>
                <label className="block text-xs font-bold text-slate-700 mb-2">موضع العرض (Placement Slot):</label>
                <div className="grid grid-cols-2 md:grid-cols-4 gap-2">
                  {[
                    { id: 'hero', title: 'السلايدر الرئيسي', desc: 'Main Carousel' },
                    { id: 'side_top', title: 'جانبي علوي', desc: 'صفقة اليوم' },
                    { id: 'side_bottom', title: 'جانبي سفلي', desc: 'توصيل فوري' },
                    { id: 'middle_secondary', title: 'إعلان فاصل', desc: 'بين الأقسام' },
                  ].map((pos) => (
                    <button
                      type="button"
                      key={pos.id}
                      onClick={() => setSlot(pos.id as any)}
                      className={`p-3 rounded-2xl border text-right transition-all ${
                        slot === pos.id
                          ? 'border-blue-600 bg-blue-50/60 ring-2 ring-blue-500/20'
                          : 'border-slate-200 hover:border-slate-300 bg-white'
                      }`}
                    >
                      <div className="text-xs font-extrabold text-slate-900">{pos.title}</div>
                      <div className="text-[10px] text-slate-400 mt-0.5">{pos.desc}</div>
                    </button>
                  ))}
                </div>
              </div>

              {/* Title & Subtitle */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1.5">
                    العنوان الرئيسي (بالعربية) <span className="text-rose-500">*</span>:
                  </label>
                  <input
                    type="text"
                    required
                    value={titleAr}
                    onChange={(e) => setTitleAr(e.target.value)}
                    placeholder="مثال: توصيل فوري إكسبريس خلال 60 دقيقة 🛵"
                    className="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 text-sm focus:outline-hidden focus:ring-2 focus:ring-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1.5">العنوان بالإنجليزية (English):</label>
                  <input
                    type="text"
                    value={titleEn}
                    onChange={(e) => setTitleEn(e.target.value)}
                    placeholder="Express 60-Min Fast Delivery 🛵"
                    className="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 text-sm focus:outline-hidden focus:ring-2 focus:ring-blue-500"
                  />
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1.5">العنوان الفرعي (Subtitle):</label>
                  <input
                    type="text"
                    value={subtitleAr}
                    onChange={(e) => setSubtitleAr(e.target.value)}
                    placeholder="مثال: اطلب مستلزمات بيتك الآن واستلمها على بابك"
                    className="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 text-sm focus:outline-hidden focus:ring-2 focus:ring-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1.5">شارة البانر (Badge Text):</label>
                  <input
                    type="text"
                    value={badgeAr}
                    onChange={(e) => setBadgeAr(e.target.value)}
                    placeholder="مثال: 3.75 د.أ / كجم أو سريع ومضمون"
                    className="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 text-sm focus:outline-hidden focus:ring-2 focus:ring-blue-500"
                  />
                </div>
              </div>

              {/* Badge Color Swatches */}
              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1.5">لون شارة البانر (Badge Color):</label>
                <div className="flex items-center gap-2">
                  {BADGE_COLORS.map((c) => (
                    <button
                      key={c.hex}
                      type="button"
                      onClick={() => setBadgeColor(c.hex)}
                      className={`w-7 h-7 rounded-full flex items-center justify-center transition-all ${c.class} ${
                        badgeColor === c.hex ? 'ring-3 ring-blue-500 ring-offset-2 scale-110' : 'opacity-80 hover:opacity-100'
                      }`}
                      title={c.name}
                    >
                      {badgeColor === c.hex && <div className="w-2 h-2 rounded-full bg-white" />}
                    </button>
                  ))}
                  <input
                    type="text"
                    value={badgeColor}
                    onChange={(e) => setBadgeColor(e.target.value)}
                    className="w-24 text-xs font-mono px-2 py-1 rounded-lg border border-slate-200 mr-2"
                  />
                </div>
              </div>

              {/* Action Destination Settings (The Core Feature User Requested!) */}
              <div className="bg-slate-50 p-4 rounded-2xl border border-slate-200 space-y-3">
                <div className="flex items-center gap-2">
                  <Sliders className="w-4 h-4 text-blue-600" />
                  <span className="text-xs font-extrabold text-slate-800">
                    إجراء النقر ووجهة الانتقال في التطبيق (Click Action & Target)
                  </span>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                  <div>
                    <label className="block text-xs font-bold text-slate-600 mb-1">نوع الإجراء:</label>
                    <select
                      value={targetType}
                      onChange={(e) => {
                        const newType = e.target.value as any;
                        setTargetType(newType);
                        if (newType === 'category' && categories.length > 0) setTargetId(categories[0].id);
                        if (newType === 'screen') setTargetId('flash_deals');
                        if (newType === 'product' && products.length > 0) setTargetId(products[0].id);
                        if (newType === 'coupon' && coupons.length > 0) setTargetId(coupons[0].code);
                        if (newType === 'external') setTargetId('https://aldeebmall.com');
                      }}
                      className="w-full px-3 py-2 rounded-xl border border-slate-200 text-sm bg-white font-medium focus:ring-2 focus:ring-blue-500"
                    >
                      <option value="screen">📱 الانتقال لصفحة داخل التطبيق (App Screen)</option>
                      <option value="category">🏢 فتح قسم محدد (Hypermarket Category)</option>
                      <option value="product">🛍️ فتح تفاصيل منتج معين (Product Details)</option>
                      <option value="coupon">🎟️ تطبيق كود خصم فوري (Apply Coupon)</option>
                      <option value="external">🌐 فتح رابط ويب خارجي (External URL)</option>
                    </select>
                  </div>

                  <div>
                    <label className="block text-xs font-bold text-slate-600 mb-1">الوجهة المحددة:</label>
                    {targetType === 'screen' && (
                      <select
                        value={targetId}
                        onChange={(e) => setTargetId(e.target.value)}
                        className="w-full px-3 py-2 rounded-xl border border-slate-200 text-sm bg-white font-medium focus:ring-2 focus:ring-blue-500"
                      >
                        {IN_APP_SCREENS.map((scr) => (
                          <option key={scr.id} value={scr.id}>
                            {scr.icon} {scr.name}
                          </option>
                        ))}
                      </select>
                    )}

                    {targetType === 'category' && (
                      <select
                        value={targetId}
                        onChange={(e) => setTargetId(e.target.value)}
                        className="w-full px-3 py-2 rounded-xl border border-slate-200 text-sm bg-white font-medium focus:ring-2 focus:ring-blue-500"
                      >
                        {categories.map((c) => (
                          <option key={c.id} value={c.id}>
                            {c.name_ar} ({c.name_en})
                          </option>
                        ))}
                      </select>
                    )}

                    {targetType === 'product' && (
                      <select
                        value={targetId}
                        onChange={(e) => setTargetId(e.target.value)}
                        className="w-full px-3 py-2 rounded-xl border border-slate-200 text-sm bg-white font-medium focus:ring-2 focus:ring-blue-500"
                      >
                        {products.map((p) => (
                          <option key={p.id} value={p.id}>
                            {p.name_ar} - {p.price} د.أ
                          </option>
                        ))}
                      </select>
                    )}

                    {targetType === 'coupon' && (
                      <div className="flex gap-2">
                        <select
                          value={targetId}
                          onChange={(e) => setTargetId(e.target.value)}
                          className="w-full px-3 py-2 rounded-xl border border-slate-200 text-sm bg-white font-medium focus:ring-2 focus:ring-blue-500"
                        >
                          {coupons.map((c) => (
                            <option key={c.code} value={c.code}>
                              {c.code} ({c.discount_value} {c.discount_type === 'percentage' ? '%' : 'د.أ'} خصم)
                            </option>
                          ))}
                          <option value="FREE100">FREE100 (توصيل مجاني فوق 100 د.أ)</option>
                          <option value="DEEB20">DEEB20 (خصم 20%)</option>
                        </select>
                      </div>
                    )}

                    {targetType === 'external' && (
                      <input
                        type="url"
                        value={targetId}
                        onChange={(e) => setTargetId(e.target.value)}
                        placeholder="https://example.com/campaign"
                        className="w-full px-3.5 py-2 rounded-xl border border-slate-200 text-sm bg-white focus:ring-2 focus:ring-blue-500"
                      />
                    )}
                  </div>
                </div>
              </div>

              {/* Image URL & Quick Presets */}
              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1.5">
                  رابط صورة البانر (Image URL) <span className="text-rose-500">*</span>:
                </label>
                <input
                  type="url"
                  required
                  value={imageUrl}
                  onChange={(e) => setImageUrl(e.target.value)}
                  placeholder="https://images.unsplash.com/..."
                  className="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 text-sm focus:outline-hidden focus:ring-2 focus:ring-blue-500 font-mono text-xs"
                />

                {/* Preset Fast Picker */}
                <div className="mt-2.5">
                  <div className="text-[11px] text-slate-400 font-medium mb-1.5">صور ونماذج سريعة جاهزة:</div>
                  <div className="flex flex-wrap gap-2">
                    {PRESET_IMAGES.map((p, idx) => (
                      <button
                        key={idx}
                        type="button"
                        onClick={() => applyPreset(p)}
                        className="px-2.5 py-1 rounded-lg text-xs bg-slate-100 hover:bg-slate-200 text-slate-700 font-medium transition-colors"
                      >
                        {p.name}
                      </button>
                    ))}
                  </div>
                </div>
              </div>

              {/* Sort Order & Active Switch */}
              <div className="flex items-center justify-between pt-2 border-t border-slate-100">
                <div className="flex items-center gap-2">
                  <label className="text-xs font-bold text-slate-700">ترتيب الظهور:</label>
                  <input
                    type="number"
                    min="1"
                    value={sortOrder}
                    onChange={(e) => setSortOrder(Number(e.target.value))}
                    className="w-20 px-3 py-1.5 rounded-lg border border-slate-200 text-sm text-center"
                  />
                </div>

                <div className="flex items-center gap-2">
                  <label className="text-xs font-bold text-slate-700 cursor-pointer" htmlFor="banner-active">
                    حالة البانر (مفعل ومعروض للعملاء):
                  </label>
                  <input
                    id="banner-active"
                    type="checkbox"
                    checked={isActive}
                    onChange={(e) => setIsActive(e.target.checked)}
                    className="w-5 h-5 rounded-md text-blue-600 focus:ring-blue-500"
                  />
                </div>
              </div>

              {/* Submit Buttons */}
              <div className="flex items-center justify-end gap-3 pt-4 border-t border-slate-100">
                <button
                  type="button"
                  onClick={() => setIsModalOpen(false)}
                  className="px-5 py-2.5 rounded-xl border border-slate-200 text-slate-600 font-bold text-sm hover:bg-slate-50 transition-colors"
                >
                  إلغاء
                </button>
                <button
                  type="submit"
                  className="px-6 py-2.5 rounded-xl bg-blue-600 hover:bg-blue-700 text-white font-bold text-sm shadow-md shadow-blue-600/30 transition-all hover:scale-[1.01]"
                >
                  {editingBanner ? 'حفظ التعديلات' : 'إضافة البانر'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
