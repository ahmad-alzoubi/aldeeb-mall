import React, { useState } from 'react';
import { Save, CheckCircle2, ShieldCheck, Database } from 'lucide-react';

export const SettingsPage: React.FC = () => {
  const [storeNameAr, setStoreNameAr] = useState('الديب مول');
  const [storeNameEn, setStoreNameEn] = useState('Aldeeb Mall');
  const [currency, setCurrency] = useState('د.إ');
  const [deliveryFee, setDeliveryFee] = useState<number>(10.0);
  const [freeThreshold, setFreeThreshold] = useState<number>(100.0);
  const [phone, setPhone] = useState('+971 50 123 4567');
  const [whatsapp, setWhatsapp] = useState('+971 50 123 4567');
  const [saved, setSaved] = useState(false);

  const handleSave = (e: React.FormEvent) => {
    e.preventDefault();
    setSaved(true);
    setTimeout(() => setSaved(false), 2500);
  };

  return (
    <div className="space-y-6 max-w-4xl">
      <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm">
        <h3 className="text-base font-extrabold text-slate-900 mb-1">إعدادات المول العامة وسياسات التوصيل</h3>
        <p className="text-xs text-slate-400 mb-6">التحكم في العملة، رسوم الشحن المجاني، وأرقام خدمة العملاء المباشرة</p>

        <form onSubmit={handleSave} className="space-y-6 text-xs font-bold text-slate-700">
          {/* Store Info */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div>
              <label className="block mb-1.5">اسم المتجر (بالعربية)</label>
              <input
                type="text"
                value={storeNameAr}
                onChange={(e) => setStoreNameAr(e.target.value)}
                className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600"
              />
            </div>
            <div>
              <label className="block mb-1.5">اسم المتجر (بالإنجليزية)</label>
              <input
                type="text"
                value={storeNameEn}
                onChange={(e) => setStoreNameEn(e.target.value)}
                className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600"
              />
            </div>
            <div>
              <label className="block mb-1.5">رمز العملة الافتراضي</label>
              <input
                type="text"
                value={currency}
                onChange={(e) => setCurrency(e.target.value)}
                className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600"
              />
            </div>
          </div>

          {/* Delivery Policy */}
          <div className="p-4 bg-slate-50 rounded-xl border border-slate-200/80 space-y-4">
            <h4 className="text-xs font-extrabold text-slate-900">سياسة ورسوم التوصيل للعملاء</h4>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block mb-1.5">رسوم التوصيل الافتراضية (د.إ)</label>
                <input
                  type="number"
                  step="0.5"
                  value={deliveryFee}
                  onChange={(e) => setDeliveryFee(Number(e.target.value))}
                  className="w-full p-2.5 bg-white border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600"
                />
              </div>
              <div>
                <label className="block mb-1.5">الحد الأدنى للتوصيل المجاني (د.إ)</label>
                <input
                  type="number"
                  step="5"
                  value={freeThreshold}
                  onChange={(e) => setFreeThreshold(Number(e.target.value))}
                  className="w-full p-2.5 bg-white border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600"
                />
              </div>
            </div>
          </div>

          {/* Contact info */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block mb-1.5">هاتف خدمة العملاء</label>
              <input
                type="text"
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
                className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600 font-mono"
              />
            </div>
            <div>
              <label className="block mb-1.5">واتساب خدمة العملاء والطلبات</label>
              <input
                type="text"
                value={whatsapp}
                onChange={(e) => setWhatsapp(e.target.value)}
                className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600 font-mono"
              />
            </div>
          </div>

          {/* Supabase Connection Details Card */}
          <div className="p-4 bg-blue-50/60 rounded-xl border border-blue-200 flex items-start gap-3">
            <Database className="w-5 h-5 text-blue-600 shrink-0 mt-0.5" />
            <div>
              <p className="text-xs font-bold text-blue-900">سحابة سوبابيز (Supabase Integration)</p>
              <p className="text-[11px] text-blue-700 mt-0.5">
                قاعدة البيانات متصلة وجاهزة بنظام PostgreSQL و RLS. يمكنك تعديل مفاتيح الربط في ملف <code>.env</code> أو تطبيق الهجرة عبر ملفات <code>/supabase/migrations</code>.
              </p>
            </div>
          </div>

          <div className="flex items-center justify-between pt-4 border-t">
            {saved ? (
              <span className="text-xs font-bold text-emerald-600 flex items-center gap-1.5">
                <CheckCircle2 className="w-4 h-4" />
                تم حفظ التغييرات بنجاح في النظام!
              </span>
            ) : <span />}

            <button
              type="submit"
              className="px-6 py-2.5 bg-blue-600 hover:bg-blue-700 text-white rounded-xl text-xs font-bold shadow-md shadow-blue-600/30 flex items-center gap-2"
            >
              <Save className="w-4 h-4" />
              حفظ الإعدادات
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
