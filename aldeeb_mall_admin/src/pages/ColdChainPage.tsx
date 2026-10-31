import React, { useState } from 'react';
import { 
  ThermometerSnowflake, 
  AlertTriangle, 
  CheckCircle2, 
  Droplets, 
  Clock, 
  Zap, 
  ShieldCheck, 
  Flame, 
  TrendingDown,
  RefreshCw,
  Tag
} from 'lucide-react';
import { ColdChainSensor, ExpiryBatchItem } from '../types';

export const ColdChainPage: React.FC = () => {
  const [sensors, setSensors] = useState<ColdChainSensor[]>([
    {
      id: 'sensor-1',
      room_name_ar: 'غرفة الألبان والأجبان الطازجة (Chiller #1)',
      category: 'chiller_dairy',
      current_temp_celsius: 3.4,
      target_temp_celsius: 4.0,
      min_safe_temp: 1.0,
      max_safe_temp: 5.0,
      humidity_percent: 68,
      status: 'optimal',
      last_ping: 'قبل دقيقة',
    },
    {
      id: 'sensor-2',
      room_name_ar: 'ثلاجة اللحوم والدواجن الطازجة (Chiller #2)',
      category: 'chiller_meat',
      current_temp_celsius: 1.8,
      target_temp_celsius: 2.0,
      min_safe_temp: 0.0,
      max_safe_temp: 3.0,
      humidity_percent: 75,
      status: 'optimal',
      last_ping: 'قبل 30 ثانية',
    },
    {
      id: 'sensor-3',
      room_name_ar: 'فريزر التجميد العميق والآيس كريم (Deep Freeze)',
      category: 'freezer_ice',
      current_temp_celsius: -19.2,
      target_temp_celsius: -20.0,
      min_safe_temp: -25.0,
      max_safe_temp: -16.0,
      humidity_percent: 45,
      status: 'optimal',
      last_ping: 'قبل 15 ثانية',
    },
    {
      id: 'sensor-4',
      room_name_ar: 'مستودع رذاذ الخضار والفواكه الورقية',
      category: 'produce_mist',
      current_temp_celsius: 6.2,
      target_temp_celsius: 6.0,
      min_safe_temp: 3.0,
      max_safe_temp: 8.0,
      humidity_percent: 88,
      status: 'optimal',
      last_ping: 'قبل دقيقتين',
    },
  ]);

  const [expiryItems, setExpiryItems] = useState<ExpiryBatchItem[]>([
    {
      id: 'exp-1',
      product_id: 'prod-milk',
      product_name_ar: 'حليب المراعي كامل الدسم 2 لتر',
      category_name_ar: 'الألبان والبيض',
      sku: 'ALM-MILK-2L',
      batch_number: 'B26-8841',
      expiry_date: 'خلال 28 ساعة (غداً مساءً)',
      hours_remaining: 28,
      stock_quantity: 42,
      original_price: 11.50,
      clearance_discount_percent: 30,
      clearance_active: true,
    },
    {
      id: 'exp-2',
      product_id: 'prod-croissant',
      product_name_ar: 'كرواسون زبدة طازج مخبوز اليوم (علبة 4 قطع)',
      category_name_ar: 'المخبوزات والحلويات',
      sku: 'BAK-CR-04',
      batch_number: 'B26-9022',
      expiry_date: 'خلال 14 ساعة (نهاية اليوم)',
      hours_remaining: 14,
      stock_quantity: 18,
      original_price: 14.00,
      clearance_discount_percent: 50,
      clearance_active: true,
    },
    {
      id: 'exp-3',
      product_id: 'prod-chicken',
      product_name_ar: 'دجاج اليوم طازج مبرد 1000 غم',
      category_name_ar: 'اللحوم والدواجن الطازجة',
      sku: 'CHK-ALY-10',
      batch_number: 'B26-9110',
      expiry_date: 'خلال 46 ساعة',
      hours_remaining: 46,
      stock_quantity: 26,
      original_price: 19.75,
      clearance_discount_percent: 25,
      clearance_active: false,
    },
    {
      id: 'exp-4',
      product_id: 'prod-yogurt',
      product_name_ar: 'لبن زبادي يوناني ندى بروتين 350 غم',
      category_name_ar: 'الألبان والبيض',
      sku: 'NADA-GRK-350',
      batch_number: 'B26-7911',
      expiry_date: 'خلال 36 ساعة',
      hours_remaining: 36,
      stock_quantity: 35,
      original_price: 7.50,
      clearance_discount_percent: 35,
      clearance_active: false,
    },
  ]);

  const [notification, setNotification] = useState<string | null>(null);

  const triggerNotification = (msg: string) => {
    setNotification(msg);
    setTimeout(() => setNotification(null), 3500);
  };

  const handleToggleClearance = (id: string) => {
    setExpiryItems((prev) =>
      prev.map((item) => {
        if (item.id === id) {
          const newState = !item.clearance_active;
          triggerNotification(
            newState 
              ? `تم تفعيل خصم التصفية بنسبة ${item.clearance_discount_percent}% لـ "${item.product_name_ar}" ونشرها في عروض تطبيق العميل فوراً!`
              : `تم إيقاف خصم التصفية لـ "${item.product_name_ar}" واستعادة السعر الأصلي.`
          );
          return { ...item, clearance_active: newState };
        }
        return item;
      })
    );
  };

  const handleUpdateDiscount = (id: string, discount: number) => {
    setExpiryItems((prev) =>
      prev.map((item) => (item.id === id ? { ...item, clearance_discount_percent: discount } : item))
    );
  };

  return (
    <div className="space-y-6">
      {/* Toast Alert */}
      {notification && (
        <div className="bg-emerald-600 text-white px-5 py-3 rounded-xl shadow-lg flex items-center gap-3 animate-fade-in text-sm font-medium">
          <CheckCircle2 className="w-5 h-5 flex-shrink-0" />
          <span>{notification}</span>
        </div>
      )}

      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 bg-white p-6 rounded-2xl border border-gray-100 shadow-sm">
        <div>
          <div className="flex items-center gap-2">
            <span className="p-2 bg-blue-50 text-blue-600 rounded-xl">
              <ThermometerSnowflake className="w-6 h-6" />
            </span>
            <h1 className="text-2xl font-bold text-gray-900">سلسلة التبريد وصلاحية المنتجات (Cold-Chain & HACCP)</h1>
          </div>
          <p className="text-gray-500 mt-1 text-sm">
            مراقبة تيليمترية ذكية لدرجات حرارة مستودعات الديب مول ونظام التصفية التلقائي للتواريخ القريبة (FEFO Engine)
          </p>
        </div>
        <div className="flex items-center gap-3">
          <div className="flex items-center gap-2 bg-emerald-50 text-emerald-700 border border-emerald-200 px-3 py-1.5 rounded-xl text-xs font-semibold">
            <ShieldCheck className="w-4 h-4 text-emerald-600" />
            <span>معايير HACCP العالمية: مطابقة 100%</span>
          </div>
          <button 
            onClick={() => triggerNotification('تم تحديث قراءات المستشعرات وتزامن درجات الحرارة بنجاح')}
            className="flex items-center gap-2 bg-gray-100 hover:bg-gray-200 text-gray-700 px-3.5 py-2 rounded-xl text-sm font-medium transition-colors"
          >
            <RefreshCw className="w-4 h-4" />
            <span>تحديث التيليمترية</span>
          </button>
        </div>
      </div>

      {/* Sensor Gauges Grid */}
      <div>
        <h2 className="text-base font-bold text-gray-900 mb-3 flex items-center gap-2">
          <span>حساسات التبريد والتجميد اللحظية (IoT Sensors)</span>
          <span className="text-xs font-normal text-gray-500">محدثة على مدار 24 ساعة عبر شبكة LoRaWAN الصناعية</span>
        </h2>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          {sensors.map((sensor) => {
            const isFreezer = sensor.category === 'freezer_ice';
            const tempDiff = sensor.current_temp_celsius - sensor.target_temp_celsius;

            return (
              <div 
                key={sensor.id}
                className="bg-white rounded-2xl p-5 border border-gray-100 shadow-sm hover:shadow-md transition-all flex flex-col justify-between"
              >
                <div>
                  <div className="flex items-center justify-between mb-3">
                    <span className="text-xs font-semibold px-2.5 py-1 rounded-lg bg-blue-50 text-blue-700">
                      {sensor.category === 'chiller_dairy' && 'ثلاجة ألبان'}
                      {sensor.category === 'chiller_meat' && 'ثلاجة لحوم'}
                      {sensor.category === 'freezer_ice' && 'تجميد عميق'}
                      {sensor.category === 'produce_mist' && 'رذاذ خضار'}
                    </span>
                    <span className="flex items-center gap-1.5 text-xs font-medium text-emerald-600">
                      <span className="w-2 h-2 rounded-full bg-emerald-500 animate-ping"></span>
                      مثالي
                    </span>
                  </div>

                  <h3 className="font-bold text-gray-900 text-sm mb-4 leading-snug">
                    {sensor.room_name_ar}
                  </h3>

                  {/* Temperature Big Display */}
                  <div className="flex items-baseline justify-between py-3 px-4 rounded-xl bg-gray-50 border border-gray-100 mb-3">
                    <div>
                      <span className="text-xs text-gray-500 block">الحرارة الحالية</span>
                      <span className={`text-3xl font-black ${isFreezer ? 'text-indigo-600' : 'text-blue-600'}`}>
                        {sensor.current_temp_celsius > 0 ? `+${sensor.current_temp_celsius}` : sensor.current_temp_celsius}°C
                      </span>
                    </div>
                    <div className="text-left">
                      <span className="text-xs text-gray-400 block">الهدف</span>
                      <span className="text-sm font-bold text-gray-700">
                        {sensor.target_temp_celsius > 0 ? `+${sensor.target_temp_celsius}` : sensor.target_temp_celsius}°C
                      </span>
                    </div>
                  </div>

                  {/* Humidity & Safe Range */}
                  <div className="space-y-1.5 text-xs text-gray-600 mb-4">
                    <div className="flex items-center justify-between">
                      <span className="flex items-center gap-1">
                        <Droplets className="w-3.5 h-3.5 text-sky-500" />
                        الرطوبة النسبية:
                      </span>
                      <span className="font-semibold text-gray-800">{sensor.humidity_percent}%</span>
                    </div>
                    <div className="flex items-center justify-between">
                      <span>النطاق الآمن:</span>
                      <span className="font-mono text-gray-700">
                        {sensor.min_safe_temp}°C إلى {sensor.max_safe_temp}°C
                      </span>
                    </div>
                  </div>
                </div>

                <div className="border-t border-gray-100 pt-3 flex items-center justify-between text-xs text-gray-400">
                  <span className="flex items-center gap-1">
                    <Clock className="w-3 h-3" />
                    {sensor.last_ping}
                  </span>
                  <span className="text-emerald-600 font-medium">مستقر (انحراف {Math.abs(tempDiff).toFixed(1)}°C)</span>
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* FEFO Expiry Date Guardian & Auto-Markdown Section */}
      <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-6">
        <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 mb-6 pb-4 border-b border-gray-100">
          <div>
            <div className="flex items-center gap-2">
              <span className="p-2 bg-amber-50 text-amber-600 rounded-xl">
                <Flame className="w-5 h-5" />
              </span>
              <h2 className="text-lg font-bold text-gray-900">
                حارس الصلاحية والتصفية الذكية (FEFO Clearance Engine)
              </h2>
            </div>
            <p className="text-sm text-gray-500 mt-1">
              منتجات أوشكت صلاحيتها على الانتهاء خلال 48 ساعة. خفض السعر بنقرة واحدة لطرحها في قسم التوفير السريع بتطبيق العميل لتقليل الهدر إلى 0%
            </p>
          </div>
          <div className="flex items-center gap-3">
            <span className="px-3 py-1.5 bg-amber-50 text-amber-700 text-xs font-bold rounded-xl border border-amber-200">
              {expiryItems.filter(e => e.clearance_active).length} منتج معروض في التصفية حالياً
            </span>
          </div>
        </div>

        {/* Expiry Items Table */}
        <div className="overflow-x-auto">
          <table className="w-full text-right text-sm">
            <thead className="bg-gray-50 text-gray-500 font-semibold border-b border-gray-100">
              <tr>
                <th className="py-3 px-4">المنتج والرمز</th>
                <th className="py-3 px-4">رقم الشحنة (Batch)</th>
                <th className="py-3 px-4">الوقت المتبقي للصلاحية</th>
                <th className="py-3 px-4">المخزون المتوفر</th>
                <th className="py-3 px-4">السعر الأصلي</th>
                <th className="py-3 px-4">نسبة التخفيض</th>
                <th className="py-3 px-4">سعر التصفية للعميل</th>
                <th className="py-3 px-4 text-center">إجراء التصفية</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {expiryItems.map((item) => {
                const discountedPrice = (item.original_price * (1 - item.clearance_discount_percent / 100)).toFixed(2);
                const isUrgent = item.hours_remaining < 24;

                return (
                  <tr key={item.id} className="hover:bg-gray-50/80 transition-colors">
                    <td className="py-3.5 px-4">
                      <div className="font-bold text-gray-900">{item.product_name_ar}</div>
                      <div className="text-xs text-gray-400">{item.category_name_ar} • SKU: {item.sku}</div>
                    </td>
                    <td className="py-3.5 px-4 font-mono text-xs text-gray-600 font-semibold">
                      {item.batch_number}
                    </td>
                    <td className="py-3.5 px-4">
                      <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-bold ${
                        isUrgent 
                          ? 'bg-rose-50 text-rose-700 border border-rose-200' 
                          : 'bg-amber-50 text-amber-700 border border-amber-200'
                      }`}>
                        <AlertTriangle className="w-3 h-3 flex-shrink-0" />
                        {item.expiry_date}
                      </span>
                    </td>
                    <td className="py-3.5 px-4 font-bold text-gray-800">
                      {item.stock_quantity} حبة
                    </td>
                    <td className="py-3.5 px-4 font-semibold text-gray-500">
                      {item.original_price.toFixed(2)} ل.س
                    </td>
                    <td className="py-3.5 px-4">
                      <select
                        value={item.clearance_discount_percent}
                        onChange={(e) => handleUpdateDiscount(item.id, Number(e.target.value))}
                        disabled={item.clearance_active}
                        className="bg-white border border-gray-200 rounded-lg px-2 py-1 text-xs font-bold text-amber-600 focus:outline-none focus:ring-2 focus:ring-amber-500 disabled:opacity-60"
                      >
                        <option value={20}>20% خصم</option>
                        <option value={30}>30% خصم</option>
                        <option value={40}>40% خصم</option>
                        <option value={50}>50% خصم نصف السعر</option>
                        <option value={70}>70% تصفية كبرى</option>
                      </select>
                    </td>
                    <td className="py-3.5 px-4">
                      <span className="font-black text-rose-600 text-base">
                        {discountedPrice} ل.س
                      </span>
                    </td>
                    <td className="py-3.5 px-4 text-center">
                      <button
                        onClick={() => handleToggleClearance(item.id)}
                        className={`px-3.5 py-1.5 rounded-xl text-xs font-bold transition-all shadow-sm flex items-center justify-center gap-1.5 mx-auto ${
                          item.clearance_active
                            ? 'bg-rose-50 hover:bg-rose-100 text-rose-700 border border-rose-200'
                            : 'bg-amber-500 hover:bg-amber-600 text-white'
                        }`}
                      >
                        <Tag className="w-3.5 h-3.5" />
                        {item.clearance_active ? 'إلغاء التصفية' : 'تفعيل التصفية الفورية'}
                      </button>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>

      {/* KPI Impact Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="bg-white p-5 rounded-2xl border border-gray-100 shadow-sm flex items-center gap-4">
          <div className="p-3 bg-emerald-50 text-emerald-600 rounded-xl">
            <TrendingDown className="w-6 h-6" />
          </div>
          <div>
            <div className="text-2xl font-black text-gray-900">0.08%</div>
            <div className="text-xs text-gray-500">نسبة الهدر الغذائي الإجمالية (أقل من المتوسط العالمي 2.5%)</div>
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-gray-100 shadow-sm flex items-center gap-4">
          <div className="p-3 bg-blue-50 text-blue-600 rounded-xl">
            <ShieldCheck className="w-6 h-6" />
          </div>
          <div>
            <div className="text-2xl font-black text-gray-900">4,820 ل.س</div>
            <div className="text-xs text-gray-500">قيمة المبيعات المستردة هذا الأسبوع عبر صفقات التصفية السريعة</div>
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-gray-100 shadow-sm flex items-center gap-4">
          <div className="p-3 bg-amber-50 text-amber-600 rounded-xl">
            <Zap className="w-6 h-6" />
          </div>
          <div>
            <div className="text-2xl font-black text-gray-900">100%</div>
            <div className="text-xs text-gray-500">سلامة سلسلة التبريد للمنتاجات المبردة والمجمدة أثناء التوصيل</div>
          </div>
        </div>
      </div>
    </div>
  );
};
