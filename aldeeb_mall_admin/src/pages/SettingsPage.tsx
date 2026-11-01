import React, { useState, useEffect } from 'react';
import { 
  Palette, 
  Type, 
  Sliders, 
  Smartphone, 
  Sparkles, 
  Save, 
  RotateCcw, 
  CheckCircle2, 
  Copy, 
  Database, 
  Users, 
  CheckSquare, 
  ShoppingBag,
  Store,
  ChevronLeft,
  Receipt
} from 'lucide-react';
import { supabase } from '../lib/supabase';
import { InvoiceDesignerPage } from './InvoiceDesignerPage';

interface ThemePreset {
  id: string;
  name: string;
  tag: string;
  colors: {
    primary: string;
    primaryDark: string;
    secondary: string;
    accent: string;
    background: string;
    surface: string;
    textPrimary: string;
    textSecondary: string;
  };
}

const PRESETS: ThemePreset[] = [
  {
    id: 'carrefour_royal',
    name: 'أزرق كارفور رويال الملكي',
    tag: 'الافتراضي الموصى به',
    colors: {
      primary: '#0D47A1',
      primaryDark: '#0A2E6B',
      secondary: '#E53935',
      accent: '#FFB300',
      background: '#F8FAFC',
      surface: '#FFFFFF',
      textPrimary: '#0F172A',
      textSecondary: '#64748B',
    },
  },
  {
    id: 'aldeeb_emerald',
    name: 'أخضر الديب الزمردي العضوي',
    tag: 'طازج وصحي',
    colors: {
      primary: '#059669',
      primaryDark: '#064E3B',
      secondary: '#EA580C',
      accent: '#F59E0B',
      background: '#F0FDF4',
      surface: '#FFFFFF',
      textPrimary: '#064E3B',
      textSecondary: '#64748B',
    },
  },
  {
    id: 'noon_ruby',
    name: 'عنابي نون إكسبريس الفاخر',
    tag: 'عصري وسريع',
    colors: {
      primary: '#BE123C',
      primaryDark: '#881337',
      secondary: '#2563EB',
      accent: '#FBBF24',
      background: '#FFF1F2',
      surface: '#FFFFFF',
      textPrimary: '#1E1E24',
      textSecondary: '#64748B',
    },
  },
  {
    id: 'purple_prestige',
    name: 'أرجواني الديب بريميوم',
    tag: 'فاخر وحصري',
    colors: {
      primary: '#6D28D9',
      primaryDark: '#4C1D95',
      secondary: '#059669',
      accent: '#F59E0B',
      background: '#F5F3FF',
      surface: '#FFFFFF',
      textPrimary: '#1F1D2B',
      textSecondary: '#64748B',
    },
  },
];

const LOCAL_STORAGE_KEY = 'aldeeb_store_theme_settings_v1';

export const SettingsPage: React.FC = () => {
  const [activeTab, setActiveTab] = useState<'theme' | 'texts' | 'policies' | 'invoices'>('theme');
  const [previewDevice, setPreviewDevice] = useState<'mobile' | 'desktop'>('mobile');

  // Theme Colors
  const [primaryColor, setPrimaryColor] = useState('#0D47A1');
  const [primaryDarkColor, setPrimaryDarkColor] = useState('#0A2E6B');
  const [secondaryColor, setSecondaryColor] = useState('#E53935');
  const [accentColor, setAccentColor] = useState('#FFB300');
  const [backgroundColor, setBackgroundColor] = useState('#F8FAFC');
  const [surfaceColor, setSurfaceColor] = useState('#FFFFFF');
  const [textPrimaryColor, setTextPrimaryColor] = useState('#0F172A');
  const [textSecondaryColor, setTextSecondaryColor] = useState('#64748B');

  // Store Texts
  const [storeNameAr, setStoreNameAr] = useState('الديب مول');
  const [storeNameEn, setStoreNameEn] = useState('Aldeeb Mall');
  const [taglineAr, setTaglineAr] = useState('هايبرماركت العائلة الأول - جودة وتوفير بلا حدود');
  const [announcementText, setAnnouncementText] = useState('🚚 توصيل مجاني للطلبات فوق 100 ل.س | صفقات حصرية يومياً');
  const [expressDeliveryText, setExpressDeliveryText] = useState('توصيل إكسبريس فوري خلال 15 دقيقة ⚡');
  const [smartExperiencesTitle, setSmartExperiencesTitle] = useState('تجارب الديب الذكية');
  const [smartExperiencesSubtitle, setSmartExperiencesSubtitle] = useState('وفّر مع الجيران، ونظّم مقاضيك الشهرية بذكاء وسرعة');
  const [groupDealsTitle, setGroupDealsTitle] = useState('الشراء الجماعي الذكي');
  const [groupDealsSubtitle, setGroupDealsSubtitle] = useState('وفّر حتى 40% مع عروض الجيران التشاركية الحية');
  const [groceryListTitle, setGroceryListTitle] = useState('القائمة الذكية ومخطط المقاضي');
  const [groceryListSubtitle, setGroceryListSubtitle] = useState('تنظيم ومزامنة المقاضي العائلية بذكاء');
  
  // Policies & General
  const [currency, setCurrency] = useState('ل.س');
  const [deliveryFee, setDeliveryFee] = useState<number>(10.0);
  const [freeThreshold, setFreeThreshold] = useState<number>(100.0);
  const [phone, setPhone] = useState('+971 50 123 4567');
  const [whatsapp, setWhatsapp] = useState('+971 50 123 4567');
  const [enableProductBundles, setEnableProductBundles] = useState<boolean>(true);

  const [saved, setSaved] = useState(false);
  const [copied, setCopied] = useState(false);

  const applySettingsData = (parsed: any) => {
    if (!parsed || typeof parsed !== 'object') return;
    if (parsed.primaryColor) setPrimaryColor(parsed.primaryColor);
    if (parsed.primaryDarkColor) setPrimaryDarkColor(parsed.primaryDarkColor);
    if (parsed.secondaryColor) setSecondaryColor(parsed.secondaryColor);
    if (parsed.accentColor) setAccentColor(parsed.accentColor);
    if (parsed.backgroundColor) setBackgroundColor(parsed.backgroundColor);
    if (parsed.surfaceColor) setSurfaceColor(parsed.surfaceColor);
    if (parsed.textPrimaryColor) setTextPrimaryColor(parsed.textPrimaryColor);
    if (parsed.textSecondaryColor) setTextSecondaryColor(parsed.textSecondaryColor);

    if (parsed.storeNameAr) setStoreNameAr(parsed.storeNameAr);
    if (parsed.storeNameEn) setStoreNameEn(parsed.storeNameEn);
    if (parsed.taglineAr) setTaglineAr(parsed.taglineAr);
    if (parsed.announcementText) setAnnouncementText(parsed.announcementText);
    if (parsed.expressDeliveryText) setExpressDeliveryText(parsed.expressDeliveryText);
    if (parsed.smartExperiencesTitle) setSmartExperiencesTitle(parsed.smartExperiencesTitle);
    if (parsed.smartExperiencesSubtitle) setSmartExperiencesSubtitle(parsed.smartExperiencesSubtitle);
    if (parsed.groupDealsTitle) setGroupDealsTitle(parsed.groupDealsTitle);
    if (parsed.groupDealsSubtitle) setGroupDealsSubtitle(parsed.groupDealsSubtitle);
    if (parsed.groceryListTitle) setGroceryListTitle(parsed.groceryListTitle);
    if (parsed.groceryListSubtitle) setGroceryListSubtitle(parsed.groceryListSubtitle);

    if (parsed.currency) setCurrency(parsed.currency);
    if (parsed.deliveryFee !== undefined) setDeliveryFee(Number(parsed.deliveryFee));
    if (parsed.freeThreshold !== undefined) setFreeThreshold(Number(parsed.freeThreshold));
    if (parsed.phone) setPhone(parsed.phone);
    if (parsed.whatsapp) setWhatsapp(parsed.whatsapp);
    if (parsed.enableProductBundles !== undefined) setEnableProductBundles(parsed.enableProductBundles === true || parsed.enableProductBundles === 'true');
  };

  // Load initial settings
  useEffect(() => {
    let isMounted = true;

    const loadInitial = async () => {
      // 1. Try Shared Local/LAN Backend API
      try {
        const resp = await fetch('/api/store_settings');
        if (resp.ok) {
          const apiData = await resp.json();
          if (isMounted && apiData && typeof apiData === 'object') {
            applySettingsData(apiData);
            return;
          }
        }
      } catch (_) {}

      // 2. Try Supabase if connected
      try {
        const { data, error } = await supabase
          .from('store_settings')
          .select('*')
          .eq('id', 'active_theme')
          .maybeSingle();
        if (!error && data && data.settings && isMounted) {
          applySettingsData(data.settings);
          return;
        }
      } catch (_) {}

      // 3. Fallback to LocalStorage
      try {
        const savedSettings = localStorage.getItem(LOCAL_STORAGE_KEY);
        if (savedSettings && isMounted) {
          applySettingsData(JSON.parse(savedSettings));
        }
      } catch (_) {}
    };

    loadInitial();

    return () => {
      isMounted = false;
    };
  }, []);

  const handleApplyPreset = (preset: ThemePreset) => {
    setPrimaryColor(preset.colors.primary);
    setPrimaryDarkColor(preset.colors.primaryDark);
    setSecondaryColor(preset.colors.secondary);
    setAccentColor(preset.colors.accent);
    setBackgroundColor(preset.colors.background);
    setSurfaceColor(preset.colors.surface);
    setTextPrimaryColor(preset.colors.textPrimary);
    setTextSecondaryColor(preset.colors.textSecondary);
  };

  const handleResetDefaults = () => {
    handleApplyPreset(PRESETS[0]);
    setStoreNameAr('الديب مول');
    setStoreNameEn('Aldeeb Mall');
    setTaglineAr('هايبرماركت العائلة الأول - جودة وتوفير بلا حدود');
    setAnnouncementText('🚚 توصيل مجاني للطلبات فوق 100 ل.س | صفقات حصرية يومياً');
    setExpressDeliveryText('توصيل إكسبريس فوري خلال 15 دقيقة ⚡');
    setSmartExperiencesTitle('تجارب الديب الذكية');
    setSmartExperiencesSubtitle('وفّر مع الجيران، ونظّم مقاضيك الشهرية بذكاء وسرعة');
    setGroupDealsTitle('الشراء الجماعي الذكي');
    setGroupDealsSubtitle('وفّر حتى 40% مع عروض الجيران التشاركية الحية');
    setGroceryListTitle('القائمة الذكية ومخطط المقاضي');
    setGroceryListSubtitle('تنظيم ومزامنة المقاضي العائلية بذكاء');
    setCurrency('ل.س');
  };

  const handleSave = async (e?: React.FormEvent) => {
    if (e) e.preventDefault();

    const payload = {
      primaryColor,
      primaryDarkColor,
      secondaryColor,
      accentColor,
      backgroundColor,
      surfaceColor,
      textPrimaryColor,
      textSecondaryColor,
      storeNameAr,
      storeNameEn,
      taglineAr,
      announcementText,
      expressDeliveryText,
      smartExperiencesTitle,
      smartExperiencesSubtitle,
      groupDealsTitle,
      groupDealsSubtitle,
      groceryListTitle,
      groceryListSubtitle,
      currency,
      deliveryFee,
      freeThreshold,
      phone,
      whatsapp,
      enableProductBundles,
      updated_at: new Date().toISOString(),
    };

    try {
      // 1. Save to LocalStorage
      localStorage.setItem(LOCAL_STORAGE_KEY, JSON.stringify(payload));
      
      // 2. Save to Shared Local/LAN Backend API
      try {
        await fetch('/api/store_settings', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(payload),
        });
      } catch (_) {}

      // If user app is on port 8080 and admin on 3000, also notify port 8080 directly
      try {
        const host = window.location.hostname || 'localhost';
        if (window.location.port !== '8080') {
          await fetch(`http://${host}:8080/api/store_settings`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload),
          }).catch(() => {});
        }
      } catch (_) {}

      // 3. Broadcast across all tabs and origins on this browser
      try {
        const channel = new BroadcastChannel('aldeeb_store_settings_sync');
        channel.postMessage({ type: 'STORE_SETTINGS_UPDATED', settings: payload });
        channel.close();
      } catch (_) {}

      // 4. Save to Supabase table if available
      try {
        await supabase.from('store_settings').upsert({
          id: 'active_theme',
          store_name_ar: storeNameAr,
          store_name_en: storeNameEn,
          currency: currency,
          delivery_fee: deliveryFee,
          free_delivery_threshold: freeThreshold,
          settings: payload,
          updated_at: new Date().toISOString(),
        });
      } catch (_) {}

      setSaved(true);
      setTimeout(() => setSaved(false), 3000);
    } catch (_) {}
  };

  const handleCopyJSON = () => {
    const payload = {
      primaryColor,
      primaryDarkColor,
      secondaryColor,
      accentColor,
      backgroundColor,
      surfaceColor,
      textPrimaryColor,
      textSecondaryColor,
      storeNameAr,
      storeNameEn,
      taglineAr,
      announcementText,
      expressDeliveryText,
      smartExperiencesTitle,
      smartExperiencesSubtitle,
      groupDealsTitle,
      groupDealsSubtitle,
      groceryListTitle,
      groceryListSubtitle,
      currency,
    };
    navigator.clipboard.writeText(JSON.stringify(payload, null, 2));
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div className="space-y-6 max-w-7xl pb-16">
      {/* Top Banner Header */}
      <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <div className="p-2 bg-blue-50 text-blue-700 rounded-xl">
              <Palette className="w-5 h-5" />
            </div>
            <h2 className="text-lg font-black text-slate-900">استوديو تخصيص الثيم والعلامة التجارية والنصوص</h2>
          </div>
          <p className="text-xs text-slate-500 mt-1">
            التحكم الشامل في ألوان المتجر، نصوص الهيدر، قسم التجارب الذكية، وسياسات التوصيل مع معاينة حية مباشرة
          </p>
        </div>

        <div className="flex items-center gap-2">
          <button
            onClick={handleCopyJSON}
            className="px-3.5 py-2 text-xs font-bold text-slate-700 bg-slate-100 hover:bg-slate-200 rounded-xl transition-all flex items-center gap-1.5"
            title="نسخ الإعدادات كـ JSON"
          >
            <Copy className="w-4 h-4 text-slate-500" />
            {copied ? 'تم النسخ!' : 'تصدير JSON'}
          </button>
          <button
            onClick={handleResetDefaults}
            className="px-3.5 py-2 text-xs font-bold text-rose-600 bg-rose-50 hover:bg-rose-100 rounded-xl transition-all flex items-center gap-1.5"
          >
            <RotateCcw className="w-4 h-4" />
            استعادة الافتراضي
          </button>
          <button
            onClick={() => handleSave()}
            className="px-5 py-2 text-xs font-bold text-white bg-blue-600 hover:bg-blue-700 rounded-xl shadow-md shadow-blue-600/30 transition-all flex items-center gap-1.5"
          >
            <Save className="w-4 h-4" />
            حفظ التغييرات
          </button>
        </div>
      </div>

      {saved && (
        <div className="p-4 bg-emerald-50 border border-emerald-200 text-emerald-800 rounded-2xl text-xs font-bold flex items-center gap-2 animate-fade-in shadow-xs">
          <CheckCircle2 className="w-5 h-5 text-emerald-600 shrink-0" />
          <span>تم حفظ الثيم والنصوص بنجاح! سيتم تطبيقها وتحديثها فورياً في كافة واجهات التطبيق والمتجر.</span>
        </div>
      )}

      {/* Main Grid: Left Controls (Tabs), Right Live Interactive Preview */}
      {activeTab === 'invoices' ? (
        <div className="space-y-4">
          <div className="flex bg-slate-200/70 p-1 rounded-2xl text-xs font-bold text-slate-600 max-w-2xl">
            <button
              onClick={() => setActiveTab('theme')}
              className="flex-1 py-2.5 rounded-xl hover:text-slate-900 transition-all flex items-center justify-center gap-2"
            >
              <Palette className="w-4 h-4" />
              الألوان وهوية الثيم
            </button>
            <button
              onClick={() => setActiveTab('texts')}
              className="flex-1 py-2.5 rounded-xl hover:text-slate-900 transition-all flex items-center justify-center gap-2"
            >
              <Type className="w-4 h-4" />
              نصوص المتجر والعلامة
            </button>
            <button
              onClick={() => setActiveTab('policies')}
              className="flex-1 py-2.5 rounded-xl hover:text-slate-900 transition-all flex items-center justify-center gap-2"
            >
              <Sliders className="w-4 h-4" />
              سياسات التوصيل والاتصال
            </button>
            <button
              onClick={() => setActiveTab('invoices')}
              className="flex-1 py-2.5 rounded-xl bg-white text-blue-700 shadow-xs transition-all flex items-center justify-center gap-2"
            >
              <Receipt className="w-4 h-4" />
              تصميم الفواتير والباركود
            </button>
          </div>
          <InvoiceDesignerPage />
        </div>
      ) : (
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
        
        {/* Controls Column */}
        <div className="lg:col-span-7 space-y-6">
          
          {/* Navigation Tabs */}
          <div className="flex bg-slate-200/70 p-1 rounded-2xl text-xs font-bold text-slate-600">
            <button
              onClick={() => setActiveTab('theme')}
              className={`flex-1 py-2.5 rounded-xl transition-all flex items-center justify-center gap-2 ${
                activeTab === 'theme' ? 'bg-white text-blue-700 shadow-xs' : 'hover:text-slate-900'
              }`}
            >
              <Palette className="w-4 h-4" />
              الألوان وهوية الثيم
            </button>
            <button
              onClick={() => setActiveTab('texts')}
              className={`flex-1 py-2.5 rounded-xl transition-all flex items-center justify-center gap-2 ${
                activeTab === 'texts' ? 'bg-white text-blue-700 shadow-xs' : 'hover:text-slate-900'
              }`}
            >
              <Type className="w-4 h-4" />
              نصوص المتجر والعلامة
            </button>
            <button
              onClick={() => setActiveTab('policies')}
              className={`flex-1 py-2.5 rounded-xl transition-all flex items-center justify-center gap-2 ${
                activeTab === 'policies' ? 'bg-white text-blue-700 shadow-xs' : 'hover:text-slate-900'
              }`}
            >
              <Sliders className="w-4 h-4" />
              سياسات التوصيل والاتصال
            </button>
            <button
              onClick={() => setActiveTab('invoices')}
              className="flex-1 py-2.5 rounded-xl transition-all flex items-center justify-center gap-2 hover:text-slate-900"
            >
              <Receipt className="w-4 h-4" />
              تصميم الفواتير والباركود
            </button>
          </div>

          {/* TAB 1: THEME COLORS & PALETTES */}
          {activeTab === 'theme' && (
            <div className="space-y-6 bg-white p-6 rounded-2xl border border-slate-200 shadow-sm">
              <div>
                <h3 className="text-sm font-extrabold text-slate-900 flex items-center gap-2">
                  <Sparkles className="w-4 h-4 text-amber-500" />
                  قوالب ألوان جاهزة بنقرة واحدة (Presets)
                </h3>
                <p className="text-xs text-slate-400 mt-0.5">اختر تركيبة ألوان تم إعدادها وتنسيقها باحترافية</p>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 mt-4">
                  {PRESETS.map((preset) => (
                    <button
                      key={preset.id}
                      onClick={() => handleApplyPreset(preset)}
                      className={`p-3.5 rounded-2xl border text-right transition-all flex flex-col justify-between hover:shadow-md ${
                        primaryColor === preset.colors.primary
                          ? 'border-blue-600 bg-blue-50/40 ring-2 ring-blue-600/20'
                          : 'border-slate-200 bg-slate-50/50 hover:bg-slate-50'
                      }`}
                    >
                      <div className="flex items-center justify-between mb-2">
                        <span className="text-xs font-bold text-slate-800">{preset.name}</span>
                        <span className="text-[10px] bg-slate-200 text-slate-700 px-2 py-0.5 rounded-full font-medium">
                          {preset.tag}
                        </span>
                      </div>
                      <div className="flex items-center gap-1.5 mt-2">
                        <div className="w-5 h-5 rounded-full shadow-xs" style={{ backgroundColor: preset.colors.primary }} />
                        <div className="w-5 h-5 rounded-full shadow-xs" style={{ backgroundColor: preset.colors.primaryDark }} />
                        <div className="w-5 h-5 rounded-full shadow-xs" style={{ backgroundColor: preset.colors.secondary }} />
                        <div className="w-5 h-5 rounded-full shadow-xs" style={{ backgroundColor: preset.colors.accent }} />
                        <div className="w-5 h-5 rounded-full shadow-xs border border-slate-300" style={{ backgroundColor: preset.colors.background }} />
                      </div>
                    </button>
                  ))}
                </div>
              </div>

              <div className="border-t border-slate-200 pt-6">
                <h3 className="text-sm font-extrabold text-slate-900 mb-1">تعديل الألوان الدقيقة (Fine Color Tuning)</h3>
                <p className="text-xs text-slate-400 mb-4">انقر على الأيقونة لاختيار اللون أو اكتب الكود السداسي Hex</p>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 text-xs font-bold text-slate-700">
                  {/* Primary Color */}
                  <div className="p-3 bg-slate-50 rounded-xl border border-slate-200 space-y-1.5">
                    <label className="block text-slate-800">اللون الأساسي (Primary Brand)</label>
                    <div className="flex items-center gap-2">
                      <input
                        type="color"
                        value={primaryColor}
                        onChange={(e) => setPrimaryColor(e.target.value)}
                        className="w-10 h-10 rounded-xl border-0 cursor-pointer p-0.5 bg-white shadow-xs"
                      />
                      <input
                        type="text"
                        value={primaryColor}
                        onChange={(e) => setPrimaryColor(e.target.value)}
                        className="flex-1 p-2 bg-white border border-slate-200 rounded-xl font-mono text-xs uppercase"
                      />
                    </div>
                  </div>

                  {/* Primary Dark */}
                  <div className="p-3 bg-slate-50 rounded-xl border border-slate-200 space-y-1.5">
                    <label className="block text-slate-800">تدرج الهوية الداكن (Primary Dark)</label>
                    <div className="flex items-center gap-2">
                      <input
                        type="color"
                        value={primaryDarkColor}
                        onChange={(e) => setPrimaryDarkColor(e.target.value)}
                        className="w-10 h-10 rounded-xl border-0 cursor-pointer p-0.5 bg-white shadow-xs"
                      />
                      <input
                        type="text"
                        value={primaryDarkColor}
                        onChange={(e) => setPrimaryDarkColor(e.target.value)}
                        className="flex-1 p-2 bg-white border border-slate-200 rounded-xl font-mono text-xs uppercase"
                      />
                    </div>
                  </div>

                  {/* Secondary Color */}
                  <div className="p-3 bg-slate-50 rounded-xl border border-slate-200 space-y-1.5">
                    <label className="block text-slate-800">لون الخصومات والشارات (Secondary)</label>
                    <div className="flex items-center gap-2">
                      <input
                        type="color"
                        value={secondaryColor}
                        onChange={(e) => setSecondaryColor(e.target.value)}
                        className="w-10 h-10 rounded-xl border-0 cursor-pointer p-0.5 bg-white shadow-xs"
                      />
                      <input
                        type="text"
                        value={secondaryColor}
                        onChange={(e) => setSecondaryColor(e.target.value)}
                        className="flex-1 p-2 bg-white border border-slate-200 rounded-xl font-mono text-xs uppercase"
                      />
                    </div>
                  </div>

                  {/* Accent Color */}
                  <div className="p-3 bg-slate-50 rounded-xl border border-slate-200 space-y-1.5">
                    <label className="block text-slate-800">لون التمييز والنجوم (Accent Gold)</label>
                    <div className="flex items-center gap-2">
                      <input
                        type="color"
                        value={accentColor}
                        onChange={(e) => setAccentColor(e.target.value)}
                        className="w-10 h-10 rounded-xl border-0 cursor-pointer p-0.5 bg-white shadow-xs"
                      />
                      <input
                        type="text"
                        value={accentColor}
                        onChange={(e) => setAccentColor(e.target.value)}
                        className="flex-1 p-2 bg-white border border-slate-200 rounded-xl font-mono text-xs uppercase"
                      />
                    </div>
                  </div>

                  {/* Background Color */}
                  <div className="p-3 bg-slate-50 rounded-xl border border-slate-200 space-y-1.5">
                    <label className="block text-slate-800">لون خلفية التطبيق (Background)</label>
                    <div className="flex items-center gap-2">
                      <input
                        type="color"
                        value={backgroundColor}
                        onChange={(e) => setBackgroundColor(e.target.value)}
                        className="w-10 h-10 rounded-xl border-0 cursor-pointer p-0.5 bg-white shadow-xs"
                      />
                      <input
                        type="text"
                        value={backgroundColor}
                        onChange={(e) => setBackgroundColor(e.target.value)}
                        className="flex-1 p-2 bg-white border border-slate-200 rounded-xl font-mono text-xs uppercase"
                      />
                    </div>
                  </div>

                  {/* Surface Color */}
                  <div className="p-3 bg-slate-50 rounded-xl border border-slate-200 space-y-1.5">
                    <label className="block text-slate-800">لون البطاقات والحاويات (Card Surface)</label>
                    <div className="flex items-center gap-2">
                      <input
                        type="color"
                        value={surfaceColor}
                        onChange={(e) => setSurfaceColor(e.target.value)}
                        className="w-10 h-10 rounded-xl border-0 cursor-pointer p-0.5 bg-white shadow-xs"
                      />
                      <input
                        type="text"
                        value={surfaceColor}
                        onChange={(e) => setSurfaceColor(e.target.value)}
                        className="flex-1 p-2 bg-white border border-slate-200 rounded-xl font-mono text-xs uppercase"
                      />
                    </div>
                  </div>

                  {/* Text Primary */}
                  <div className="p-3 bg-slate-50 rounded-xl border border-slate-200 space-y-1.5">
                    <label className="block text-slate-800">لون النصوص الرئيسي (Text Primary)</label>
                    <div className="flex items-center gap-2">
                      <input
                        type="color"
                        value={textPrimaryColor}
                        onChange={(e) => setTextPrimaryColor(e.target.value)}
                        className="w-10 h-10 rounded-xl border-0 cursor-pointer p-0.5 bg-white shadow-xs"
                      />
                      <input
                        type="text"
                        value={textPrimaryColor}
                        onChange={(e) => setTextPrimaryColor(e.target.value)}
                        className="flex-1 p-2 bg-white border border-slate-200 rounded-xl font-mono text-xs uppercase"
                      />
                    </div>
                  </div>

                  {/* Text Secondary */}
                  <div className="p-3 bg-slate-50 rounded-xl border border-slate-200 space-y-1.5">
                    <label className="block text-slate-800">لون النصوص الفرعي (Text Muted)</label>
                    <div className="flex items-center gap-2">
                      <input
                        type="color"
                        value={textSecondaryColor}
                        onChange={(e) => setTextSecondaryColor(e.target.value)}
                        className="w-10 h-10 rounded-xl border-0 cursor-pointer p-0.5 bg-white shadow-xs"
                      />
                      <input
                        type="text"
                        value={textSecondaryColor}
                        onChange={(e) => setTextSecondaryColor(e.target.value)}
                        className="flex-1 p-2 bg-white border border-slate-200 rounded-xl font-mono text-xs uppercase"
                      />
                    </div>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* TAB 2: STORE TEXTS & COPYWRITING */}
          {activeTab === 'texts' && (
            <div className="space-y-6 bg-white p-6 rounded-2xl border border-slate-200 shadow-sm">
              <div>
                <h3 className="text-sm font-extrabold text-slate-900 mb-1">نصوص العلامة التجارية والترويسة</h3>
                <p className="text-xs text-slate-400 mb-4">التحكم في كافة نصوص التطبيق الظاهرة للمتسوقين</p>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 text-xs font-bold text-slate-700">
                  <div>
                    <label className="block mb-1.5">اسم المتجر (بالعربية)</label>
                    <input
                      type="text"
                      value={storeNameAr}
                      onChange={(e) => setStoreNameAr(e.target.value)}
                      className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:border-blue-600 focus:outline-none"
                    />
                  </div>

                  <div>
                    <label className="block mb-1.5">اسم المتجر (بالإنجليزية)</label>
                    <input
                      type="text"
                      value={storeNameEn}
                      onChange={(e) => setStoreNameEn(e.target.value)}
                      className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:border-blue-600 focus:outline-none"
                    />
                  </div>

                  <div className="sm:col-span-2">
                    <label className="block mb-1.5">شعار المتجر التسويقي (Tagline)</label>
                    <input
                      type="text"
                      value={taglineAr}
                      onChange={(e) => setTaglineAr(e.target.value)}
                      className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:border-blue-600 focus:outline-none"
                    />
                  </div>

                  <div className="sm:col-span-2">
                    <label className="block mb-1.5">شريط الإعلانات العلوي في الهيدر (Top Bar Announcement)</label>
                    <input
                      type="text"
                      value={announcementText}
                      onChange={(e) => setAnnouncementText(e.target.value)}
                      className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:border-blue-600 focus:outline-none"
                    />
                  </div>

                  <div className="sm:col-span-2">
                    <label className="block mb-1.5">شريط وضع التوصيل السريع (Express 15-Min Mode)</label>
                    <input
                      type="text"
                      value={expressDeliveryText}
                      onChange={(e) => setExpressDeliveryText(e.target.value)}
                      className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:border-blue-600 focus:outline-none"
                    />
                  </div>
                </div>
              </div>

              {/* Smart Experiences Texts */}
              <div className="border-t border-slate-200 pt-6">
                <h3 className="text-sm font-extrabold text-slate-900 mb-1">نصوص قسم تجارب الديب الذكية</h3>
                <p className="text-xs text-slate-400 mb-4">
                  تعديل عناوين ووصف بطاقتي (الشراء الجماعي) و (القائمة الذكية)
                </p>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 text-xs font-bold text-slate-700">
                  <div>
                    <label className="block mb-1.5">عنوان قسم التجارب الرئيسي</label>
                    <input
                      type="text"
                      value={smartExperiencesTitle}
                      onChange={(e) => setSmartExperiencesTitle(e.target.value)}
                      className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:border-blue-600 focus:outline-none"
                    />
                  </div>

                  <div>
                    <label className="block mb-1.5">العنوان الفرعي للقسم</label>
                    <input
                      type="text"
                      value={smartExperiencesSubtitle}
                      onChange={(e) => setSmartExperiencesSubtitle(e.target.value)}
                      className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:border-blue-600 focus:outline-none"
                    />
                  </div>

                  {/* Group Deals Card */}
                  <div className="p-3 bg-blue-50/50 rounded-xl border border-blue-200 space-y-3">
                    <div className="font-extrabold text-blue-900 text-xs">بطاقة 1: الشراء الجماعي</div>
                    <div>
                      <label className="block mb-1">عنوان البطاقة</label>
                      <input
                        type="text"
                        value={groupDealsTitle}
                        onChange={(e) => setGroupDealsTitle(e.target.value)}
                        className="w-full p-2 bg-white border border-slate-200 rounded-xl focus:border-blue-600 focus:outline-none"
                      />
                    </div>
                    <div>
                      <label className="block mb-1">وصف البطاقة</label>
                      <input
                        type="text"
                        value={groupDealsSubtitle}
                        onChange={(e) => setGroupDealsSubtitle(e.target.value)}
                        className="w-full p-2 bg-white border border-slate-200 rounded-xl focus:border-blue-600 focus:outline-none"
                      />
                    </div>
                  </div>

                  {/* Smart List Card */}
                  <div className="p-3 bg-teal-50/50 rounded-xl border border-teal-200 space-y-3">
                    <div className="font-extrabold text-teal-900 text-xs">بطاقة 2: القائمة الذكية</div>
                    <div>
                      <label className="block mb-1">عنوان البطاقة</label>
                      <input
                        type="text"
                        value={groceryListTitle}
                        onChange={(e) => setGroceryListTitle(e.target.value)}
                        className="w-full p-2 bg-white border border-slate-200 rounded-xl focus:border-blue-600 focus:outline-none"
                      />
                    </div>
                    <div>
                      <label className="block mb-1">وصف البطاقة</label>
                      <input
                        type="text"
                        value={groceryListSubtitle}
                        onChange={(e) => setGroceryListSubtitle(e.target.value)}
                        className="w-full p-2 bg-white border border-slate-200 rounded-xl focus:border-blue-600 focus:outline-none"
                      />
                    </div>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* TAB 3: POLICIES & SUPABASE */}
          {activeTab === 'policies' && (
            <div className="space-y-6 bg-white p-6 rounded-2xl border border-slate-200 shadow-sm">
              <h3 className="text-sm font-extrabold text-slate-900 mb-1">سياسات التوصيل والاتصال المباشر</h3>
              <p className="text-xs text-slate-400 mb-4">التحكم في العملة، رسوم الشحن المجاني، وأرقام خدمة العملاء</p>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 text-xs font-bold text-slate-700">
                <div>
                  <label className="block mb-1.5">رمز العملة الافتراضي</label>
                  <input
                    type="text"
                    value={currency}
                    onChange={(e) => setCurrency(e.target.value)}
                    className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:border-blue-600 focus:outline-none font-bold text-blue-700"
                  />
                </div>

                <div>
                  <label className="block mb-1.5">رسوم التوصيل الافتراضية ({currency})</label>
                  <input
                    type="number"
                    step="0.5"
                    value={deliveryFee}
                    onChange={(e) => setDeliveryFee(Number(e.target.value))}
                    className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:border-blue-600 focus:outline-none font-mono"
                  />
                </div>

                <div>
                  <label className="block mb-1.5">الحد الأدنى للتوصيل المجاني ({currency})</label>
                  <input
                    type="number"
                    step="5"
                    value={freeThreshold}
                    onChange={(e) => setFreeThreshold(Number(e.target.value))}
                    className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:border-blue-600 focus:outline-none font-mono"
                  />
                </div>

                <div>
                  <label className="block mb-1.5">هاتف خدمة العملاء</label>
                  <input
                    type="text"
                    value={phone}
                    onChange={(e) => setPhone(e.target.value)}
                    className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:border-blue-600 focus:outline-none font-mono"
                  />
                </div>

                <div className="sm:col-span-2">
                  <label className="block mb-1.5">واتساب الدعم السريع والطلبات</label>
                  <input
                    type="text"
                    value={whatsapp}
                    onChange={(e) => setWhatsapp(e.target.value)}
                    className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:border-blue-600 focus:outline-none font-mono"
                  />
                </div>
              </div>

              {/* Product Bundles Master Switch */}
              <div className="p-4 bg-purple-50/70 rounded-2xl border border-purple-200 flex items-center justify-between gap-4 mt-2">
                <div className="flex items-center gap-3">
                  <div className="w-9 h-9 rounded-xl bg-purple-600 text-white flex items-center justify-center shrink-0">
                    <Sparkles className="w-5 h-5" />
                  </div>
                  <div>
                    <h4 className="text-xs font-black text-slate-900">
                      مفتاح التحكم العام بعروض باقات "اشترِ معاً ووفر" (Master Switch)
                    </h4>
                    <p className="text-[11px] text-slate-500 mt-0.5">
                      {enableProductBundles
                        ? 'مفعل على مستوى المتجر: يتم إظهار الباقات للمنتجات المفعلة في كتالوج الأصناف.'
                        : 'معطل كلياً على مستوى المتجر: تم حجب وإلغاء جميع باقات "اشترِ معاً" من كافة صفحات المنتجات دفعة واحدة.'}
                    </p>
                  </div>
                </div>

                <label className="relative inline-flex items-center cursor-pointer shrink-0">
                  <input
                    type="checkbox"
                    checked={enableProductBundles}
                    onChange={(e) => setEnableProductBundles(e.target.checked)}
                    className="sr-only peer"
                  />
                  <div className="w-12 h-6.5 bg-slate-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[3px] after:left-[3px] after:bg-white after:border-slate-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-purple-600"></div>
                </label>
              </div>

              {/* Supabase status */}
              <div className="p-4 bg-blue-50/70 rounded-xl border border-blue-200 flex items-start gap-3 mt-4">
                <Database className="w-5 h-5 text-blue-600 shrink-0 mt-0.5" />
                <div>
                  <p className="text-xs font-bold text-blue-900">سحابة سوبابيز (Supabase Connected)</p>
                  <p className="text-[11px] text-blue-700 mt-0.5">
                    يتم تخزين ومزامنة إعدادات الثيم في جدول <code>store_settings</code> سحابياً، مع تخزين نسخة احتياطية في LocalStorage لضمان استمرارية العمل بدون انقطاع.
                  </p>
                </div>
              </div>
            </div>
          )}

          {/* Bottom Save Bar */}
          <div className="flex items-center justify-between p-4 bg-white rounded-2xl border border-slate-200 shadow-sm">
            <span className="text-xs text-slate-400">
              جميع التعديلات ستنعكس فور حفظها في التطبيق ولوحة الإدارة
            </span>
            <button
              onClick={() => handleSave()}
              className="px-6 py-2.5 text-xs font-bold text-white bg-blue-600 hover:bg-blue-700 rounded-xl shadow-md shadow-blue-600/30 transition-all flex items-center gap-2"
            >
              <Save className="w-4 h-4" />
              حفظ وتطبيق الثيم
            </button>
          </div>
        </div>

        {/* RIGHT COLUMN: LIVE INTERACTIVE PHONE & DESKTOP PREVIEW */}
        <div className="lg:col-span-5 sticky top-6">
          <div className="bg-slate-900 p-4 rounded-3xl shadow-2xl border border-slate-800">
            {/* Device Switcher Header */}
            <div className="flex items-center justify-between mb-3 px-2">
              <div className="flex items-center gap-1.5 text-white text-xs font-bold">
                <Smartphone className="w-4 h-4 text-cyan-400" />
                معاينة حية للمتجر (Live Preview)
              </div>
              <div className="flex items-center bg-slate-800 p-1 rounded-xl text-[11px] font-bold text-slate-300">
                <button
                  onClick={() => setPreviewDevice('mobile')}
                  className={`px-3 py-1 rounded-lg transition-all ${
                    previewDevice === 'mobile' ? 'bg-blue-600 text-white' : 'hover:text-white'
                  }`}
                >
                  هاتف
                </button>
                <button
                  onClick={() => setPreviewDevice('desktop')}
                  className={`px-3 py-1 rounded-lg transition-all ${
                    previewDevice === 'desktop' ? 'bg-blue-600 text-white' : 'hover:text-white'
                  }`}
                >
                  سطح المكتب
                </button>
              </div>
            </div>

            {/* Mobile / Desktop Frame Container */}
            <div
              className="rounded-2xl overflow-hidden border border-slate-700 shadow-inner transition-all duration-300 text-right select-none"
              style={{ backgroundColor: backgroundColor }}
            >
              {/* Announcement Bar */}
              <div
                className="py-1 px-3 text-[10px] text-center font-bold text-white truncate"
                style={{ backgroundColor: primaryDarkColor }}
              >
                {announcementText}
              </div>

              {/* Header Navigation */}
              <div
                className="p-3 text-white flex items-center justify-between shadow-sm"
                style={{ backgroundColor: primaryColor }}
              >
                <div className="flex items-center gap-2">
                  <div className="w-7 h-7 rounded-lg bg-white/20 flex items-center justify-center">
                    <Store className="w-4 h-4 text-white" />
                  </div>
                  <div>
                    <div className="text-xs font-black leading-none">{storeNameAr}</div>
                    <div className="text-[9px] text-white/70">{storeNameEn}</div>
                  </div>
                </div>

                <div className="flex items-center gap-2">
                  <div className="w-6 h-6 rounded-full bg-white/10 flex items-center justify-center text-xs">
                    🔍
                  </div>
                  <div className="w-6 h-6 rounded-full bg-white/10 flex items-center justify-center text-xs">
                    🛒
                  </div>
                </div>
              </div>

              {/* Body Content Preview */}
              <div className="p-3 space-y-3 max-h-[500px] overflow-y-auto">
                {/* Hero Banner Sample */}
                <div
                  className="p-4 rounded-xl text-white relative overflow-hidden shadow-sm"
                  style={{
                    background: `linear-gradient(135deg, ${primaryColor} 0%, ${primaryDarkColor} 100%)`,
                  }}
                >
                  <span
                    className="text-[9px] px-2 py-0.5 rounded-full font-bold inline-block mb-1 text-white shadow-xs"
                    style={{ backgroundColor: secondaryColor }}
                  >
                    عروض كبرى
                  </span>
                  <div className="text-xs font-black">{taglineAr}</div>
                  <div className="text-[10px] text-white/80 mt-1">توصيل مجاني لكافة الطلبات</div>
                </div>

                {/* Smart Experiences Section Showcase (EXCLUSIVE Group Deals & Smart List) */}
                <div>
                  <div className="flex items-center justify-between mb-2">
                    <div className="flex items-center gap-1.5">
                      <div className="w-1 h-3 rounded-full" style={{ backgroundColor: primaryColor }} />
                      <span className="text-[11px] font-black" style={{ color: textPrimaryColor }}>
                        {smartExperiencesTitle}
                      </span>
                      <span
                        className="text-[8px] font-bold px-1.5 py-0.5 rounded-md"
                        style={{ backgroundColor: `${primaryColor}15`, color: primaryColor }}
                      >
                        حصري للديب ✦
                      </span>
                    </div>
                  </div>

                  {/* The 2 Flagship Responsive Cards */}
                  <div className={`gap-2 ${previewDevice === 'desktop' ? 'grid grid-cols-2' : 'space-y-2'}`}>
                    {/* Card 1: Group Deals */}
                    <div
                      className="p-3 rounded-xl text-white shadow-sm transition-all"
                      style={{
                        background: `linear-gradient(135deg, ${primaryDarkColor} 0%, ${primaryColor} 100%)`,
                        border: `1px solid ${accentColor}40`,
                      }}
                    >
                      <div className="flex items-center justify-between mb-1.5">
                        <span
                          className="text-[8px] font-bold px-1.5 py-0.5 rounded-full text-white"
                          style={{ backgroundColor: secondaryColor }}
                        >
                          وفر 40% 🔥
                        </span>
                        <span className="text-[8px] font-bold text-white/80 flex items-center gap-1">
                          🟢 صفقات حية
                        </span>
                      </div>
                      <div className="flex items-start gap-2">
                        <div className="w-7 h-7 rounded-lg bg-white/15 flex items-center justify-center shrink-0">
                          <Users className="w-3.5 h-3.5 text-white" />
                        </div>
                        <div>
                          <div className="text-[11px] font-bold">{groupDealsTitle}</div>
                          <div className="text-[9px] text-white/70 line-clamp-1">{groupDealsSubtitle}</div>
                        </div>
                      </div>
                      <div className="mt-2 pt-1.5 border-t border-white/10 flex items-center justify-between text-[8px] font-bold">
                        <span className="text-white/80">+18 جار انضموا</span>
                        <span style={{ color: accentColor }} className="flex items-center gap-0.5">
                          انضم الآن <ChevronLeft className="w-2.5 h-2.5" />
                        </span>
                      </div>
                    </div>

                    {/* Card 2: Smart List */}
                    <div
                      className="p-3 rounded-xl text-white shadow-sm transition-all"
                      style={{
                        background: 'linear-gradient(135deg, #0F766E 0%, #0D9488 100%)',
                        border: '1px solid rgba(45, 212, 191, 0.4)',
                      }}
                    >
                      <div className="flex items-center justify-between mb-1.5">
                        <span className="text-[8px] font-bold px-1.5 py-0.5 rounded-full bg-teal-800 text-teal-100">
                          AI ذكي ⚡
                        </span>
                        <span className="text-[8px] font-bold text-teal-200">مزامنة فورية</span>
                      </div>
                      <div className="flex items-start gap-2">
                        <div className="w-7 h-7 rounded-lg bg-white/15 flex items-center justify-center shrink-0">
                          <CheckSquare className="w-3.5 h-3.5 text-white" />
                        </div>
                        <div>
                          <div className="text-[11px] font-bold">{groceryListTitle}</div>
                          <div className="text-[9px] text-white/70 line-clamp-1">{groceryListSubtitle}</div>
                        </div>
                      </div>
                      <div className="mt-2 pt-1.5 border-t border-white/10 flex items-center justify-between text-[8px] font-bold">
                        <span className="text-white/80">مقترحات تلقائية</span>
                        <span className="text-teal-200 flex items-center gap-0.5">
                          افتح القائمة <ChevronLeft className="w-2.5 h-2.5" />
                        </span>
                      </div>
                    </div>
                  </div>
                </div>

                {/* Sample Product Card */}
                <div
                  className="p-3 rounded-xl border flex items-center justify-between shadow-xs"
                  style={{
                    backgroundColor: surfaceColor,
                    borderColor: '#E2E8F0',
                  }}
                >
                  <div className="flex items-center gap-2.5">
                    <div className="w-10 h-10 rounded-lg bg-amber-50 border border-amber-100 flex items-center justify-center text-lg">
                      🍎
                    </div>
                    <div>
                      <div className="text-xs font-bold" style={{ color: textPrimaryColor }}>
                        تفاح أحمر سكري فاخر (1 كجم)
                      </div>
                      <div className="text-[10px]" style={{ color: textSecondaryColor }}>
                        طازج يومياً من المزرعة
                      </div>
                      <div className="text-xs font-black mt-0.5" style={{ color: primaryColor }}>
                        12.50 {currency}
                      </div>
                    </div>
                  </div>

                  <button
                    className="px-2.5 py-1.5 rounded-lg text-white text-[10px] font-bold flex items-center gap-1 shadow-xs"
                    style={{ backgroundColor: primaryColor }}
                  >
                    <ShoppingBag className="w-3 h-3" />
                    أضف
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      )}
    </div>
  );
};
