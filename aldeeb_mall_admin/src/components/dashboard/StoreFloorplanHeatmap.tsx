import React, { useState, useEffect } from 'react';
import { 
  MapPin, 
  Users, 
  Clock, 
  Camera, 
  Flame, 
  Info, 
  Sparkles, 
  Layers, 
  SlidersHorizontal,
  ChevronRight
} from 'lucide-react';
import { STORE_ZONES, StoreZoneDensity, INITIAL_CAMERAS, StoreCamera } from '../../lib/storeVisionData';
import { fetchVisionTelemetry } from '../../lib/visionApi';
import { FEATURE_FLAGS } from '../../lib/featureFlags';

interface StoreFloorplanHeatmapProps {
  onSelectCamera: (cam: StoreCamera) => void;
}

export const StoreFloorplanHeatmap: React.FC<StoreFloorplanHeatmapProps> = ({
  onSelectCamera,
}) => {
  const [zones, setZones] = useState<StoreZoneDensity[]>(STORE_ZONES);
  const [selectedZone, setSelectedZone] = useState<StoreZoneDensity | null>(STORE_ZONES[6]); // default POS
  const [activeLayer, setActiveLayer] = useState<'density' | 'dwell' | 'cameras'>('density');

  useEffect(() => {
    let isMounted = true;
    fetchVisionTelemetry().then((res) => {
      if (isMounted && res?.zones && res.zones.length > 0) {
        setZones(res.zones);
        setSelectedZone((current) => {
          if (!current) return res.zones[6] || res.zones[0];
          return res.zones.find(z => z.id === current.id) || current;
        });
      }
    });
    return () => { isMounted = false; };
  }, []);

  const getZone = (id: string, fallbackIdx: number) => {
    return zones.find(z => z.id === id) || STORE_ZONES[fallbackIdx];
  };

  return (
    <div className="bg-slate-900 border border-slate-800 rounded-3xl p-6 text-slate-100 shadow-xl space-y-6" dir="rtl">
      {/* Header and Filter Controls */}
      <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <h3 className="text-base font-extrabold text-white flex items-center gap-2">
              <span className="p-2 bg-blue-600/20 text-blue-400 rounded-xl">
                <Layers className="w-5 h-5" />
              </span>
              المسقط الأفقي والخريطة الحرارية للمتجر (Live Store 2D Heatmap)
            </h3>
            <span className="text-[11px] font-bold bg-emerald-500/20 text-emerald-300 border border-emerald-500/30 px-2 py-0.5 rounded-full">
              تحديث بالثانية
            </span>
          </div>
          <p className="text-xs text-slate-400 mt-1">
            متابعة فورية لتوزيع الزوار، نقاط التزاحم، وتغطية كاميرات الذكاء البصري في أرجاء الهايبرماركت
          </p>
        </div>

        {/* Layer Switcher */}
        <div className="flex items-center gap-1.5 p-1 bg-slate-950 rounded-2xl border border-slate-800 text-xs">
          <button
            onClick={() => setActiveLayer('density')}
            className={`px-3 py-1.5 rounded-xl font-bold transition-all ${
              activeLayer === 'density' ? 'bg-blue-600 text-white shadow-md' : 'text-slate-400 hover:text-white'
            }`}
          >
            كثافة الزوار
          </button>
          <button
            onClick={() => setActiveLayer('dwell')}
            className={`px-3 py-1.5 rounded-xl font-bold transition-all ${
              activeLayer === 'dwell' ? 'bg-amber-600 text-white shadow-md' : 'text-slate-400 hover:text-white'
            }`}
          >
            مدة المكوث (Dwell)
          </button>
          {FEATURE_FLAGS.ENABLE_STORE_CAMERAS && (
            <button
              onClick={() => setActiveLayer('cameras')}
              className={`px-3 py-1.5 rounded-xl font-bold transition-all ${
                activeLayer === 'cameras' ? 'bg-purple-600 text-white shadow-md' : 'text-slate-400 hover:text-white'
              }`}
            >
              نطاق الكاميرات (FOV)
            </button>
          )}
        </div>
      </div>

      {/* Main Schematic Floorplan Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
        {/* Floorplan Layout Canvas (8 Cols) */}
        <div className="lg:col-span-8 bg-slate-950/80 rounded-2xl border border-slate-800 p-5 relative overflow-hidden">
          {/* Subtle architectural grid pattern */}
          <div className="absolute inset-0 bg-[radial-gradient(#1e293b_1px,transparent_1px)] [background-size:20px_20px] opacity-70 pointer-events-none" />

          {/* Top Entrance Banner */}
          <div className="mb-4 text-center">
            <span className="text-[11px] font-bold text-slate-400 bg-slate-900 border border-slate-800 px-3 py-1 rounded-full uppercase tracking-wider">
              بوابة الدخول الرئيسية للمول (الواجهة الشمالية)
            </span>
          </div>

          {/* Zones Arrangement Grid */}
          <div className="grid grid-cols-3 gap-3.5 relative z-10">
            {/* 1. Entrance Zone */}
            <div 
              onClick={() => setSelectedZone(getZone('entrance', 0))}
              className={`p-3.5 rounded-2xl border cursor-pointer transition-all ${
                selectedZone?.id === getZone('entrance', 0).id ? 'ring-2 ring-blue-500 scale-[1.02]' : ''
              } bg-amber-500/10 border-amber-500/40 hover:bg-amber-500/20`}
            >
              <div className="flex items-center justify-between text-xs mb-2">
                <span className="font-extrabold text-amber-300">المدخل والاستقبال</span>
                <span className="text-[10px] font-mono px-1.5 py-0.5 rounded bg-amber-950 text-amber-200">
                  {getZone('entrance', 0).currentShoppers} متسوق
                </span>
              </div>
              <p className="text-[11px] text-slate-400">كاميرا 01 تغطي مسار البوابات</p>
            </div>

            {/* 2. Produce Zone */}
            <div 
              onClick={() => setSelectedZone(getZone('produce', 1))}
              className={`p-3.5 rounded-2xl border cursor-pointer transition-all ${
                selectedZone?.id === getZone('produce', 1).id ? 'ring-2 ring-emerald-500 scale-[1.02]' : ''
              } bg-emerald-500/10 border-emerald-500/40 hover:bg-emerald-500/20`}
            >
              <div className="flex items-center justify-between text-xs mb-2">
                <span className="font-extrabold text-emerald-300">الخضار والفواكه</span>
                <span className="text-[10px] font-mono px-1.5 py-0.5 rounded bg-emerald-950 text-emerald-200">
                  {getZone('produce', 1).currentShoppers} متسوق
                </span>
              </div>
              <p className="text-[11px] text-slate-400">إشغال {Math.round((getZone('produce', 1).currentShoppers / (getZone('produce', 1).capacityMax || 40)) * 100)}% • حركة حية</p>
            </div>

            {/* 3. Bakery Zone */}
            <div 
              onClick={() => setSelectedZone(getZone('bakery', 3))}
              className={`p-3.5 rounded-2xl border cursor-pointer transition-all ${
                selectedZone?.id === getZone('bakery', 3).id ? 'ring-2 ring-orange-500 scale-[1.02]' : ''
              } bg-orange-500/10 border-orange-500/40 hover:bg-orange-500/20`}
            >
              <div className="flex items-center justify-between text-xs mb-2">
                <span className="font-extrabold text-orange-300">المخبز والحلويات</span>
                <span className="text-[10px] font-mono px-1.5 py-0.5 rounded bg-orange-950 text-orange-200">
                  {getZone('bakery', 3).currentShoppers} متسوق
                </span>
              </div>
              <p className="text-[11px] text-slate-400">كاميرا 05 نشطة</p>
            </div>

            {/* 4. Central Grocery Aisles (Span 2 cols) */}
            <div 
              onClick={() => setSelectedZone(getZone('aisles', 4))}
              className={`col-span-2 p-3.5 rounded-2xl border cursor-pointer transition-all ${
                selectedZone?.id === getZone('aisles', 4).id ? 'ring-2 ring-blue-500 scale-[1.02]' : ''
              } bg-blue-500/10 border-blue-500/40 hover:bg-blue-500/20`}
            >
              <div className="flex items-center justify-between text-xs mb-2">
                <span className="font-extrabold text-blue-300">الممرات المركزية والمعلبات (الممرات 1 إلى 6)</span>
                <span className="text-[10px] font-mono px-1.5 py-0.5 rounded bg-blue-950 text-blue-200">
                  {getZone('aisles', 4).currentShoppers} متسوق
                </span>
              </div>
              <p className="text-[11px] text-slate-400">متوسط مكوث المتسوق 14.8 دقيقة • تدفق منتظم</p>
            </div>

            {/* 5. Beauty & Fragrance */}
            <div 
              onClick={() => setSelectedZone(getZone('beverages', 5))}
              className={`p-3.5 rounded-2xl border cursor-pointer transition-all ${
                selectedZone?.id === getZone('beverages', 5).id ? 'ring-2 ring-purple-500 scale-[1.02]' : ''
              } bg-purple-500/10 border-purple-500/40 hover:bg-purple-500/20`}
            >
              <div className="flex items-center justify-between text-xs mb-2">
                <span className="font-extrabold text-purple-300">العطور والمستوردات</span>
                <span className="text-[10px] font-mono px-1.5 py-0.5 rounded bg-purple-950 text-purple-200">
                  {getZone('beverages', 5).currentShoppers} متسوق
                </span>
              </div>
              <p className="text-[11px] text-slate-400 font-bold text-amber-400">
                ⚠️ رصد اشتباه أمني نشط (CAM-04)
              </p>
            </div>

            {/* 6. Butcher & Cold Cuts */}
            <div 
              onClick={() => setSelectedZone(getZone('butcher', 2))}
              className={`p-3.5 rounded-2xl border cursor-pointer transition-all ${
                selectedZone?.id === getZone('butcher', 2).id ? 'ring-2 ring-rose-500 scale-[1.02]' : ''
              } bg-rose-500/10 border-rose-500/40 hover:bg-rose-500/20`}
            >
              <div className="flex items-center justify-between text-xs mb-2">
                <span className="font-extrabold text-rose-300">الملحمة والمبردات</span>
                <span className="text-[10px] font-mono px-1.5 py-0.5 rounded bg-rose-950 text-rose-200">
                  {getZone('butcher', 2).currentShoppers} متسوق
                </span>
              </div>
              <p className="text-[11px] text-slate-400">كاميرا 03 • رقابة سلسلة التبريد</p>
            </div>

            {/* 7. POS & Self-Checkout Area (Span 2 cols) */}
            <div 
              onClick={() => setSelectedZone(getZone('cashier', 6))}
              className={`col-span-2 p-3.5 rounded-2xl border cursor-pointer transition-all ${
                selectedZone?.id === getZone('cashier', 6).id ? 'ring-2 ring-red-500 scale-[1.02]' : ''
              } bg-red-600/15 border-red-500/60 hover:bg-red-600/25 relative overflow-hidden`}
            >
              <div className="flex items-center justify-between text-xs mb-2">
                <span className="font-extrabold text-red-300 flex items-center gap-1.5">
                  <span className="w-2 h-2 rounded-full bg-red-500 animate-ping" />
                  منطقة الكاشير والدفع الذاتي (مستوى كثافة حرج ⚠️)
                </span>
                <span className="text-[10px] font-mono px-1.5 py-0.5 rounded bg-red-950 text-red-200 font-bold">
                  {getZone('cashier', 6).currentShoppers} متسوق ({Math.round((getZone('cashier', 6).currentShoppers / (getZone('cashier', 6).capacityMax || 50)) * 100)}% إشغال)
                </span>
              </div>
              <p className="text-[11px] text-slate-300">
                طابور كاشير 1 يتطلب دعماً • كاميرا 06 تراقب عدم تطابق المسح
              </p>
            </div>

            {/* 8. Loading Dock (Bottom) */}
            <div 
              onClick={() => setSelectedZone(getZone('loading_dock', 7))}
              className={`col-span-3 p-3 rounded-2xl border cursor-pointer transition-all ${
                selectedZone?.id === getZone('loading_dock', 7).id ? 'ring-2 ring-slate-400' : ''
              } bg-slate-900 border-slate-800 hover:bg-slate-800/80`}
            >
              <div className="flex items-center justify-between text-xs">
                <span className="font-extrabold text-slate-400">رصيف الشحن والتوريد والمستودع الخلفي (منطقة آمنة)</span>
                <span className="text-[10px] font-mono text-slate-400">كاميرا 05 (ليلي)</span>
              </div>
            </div>
          </div>

          {/* Interactive Camera Nodes with clickable cones */}
          {FEATURE_FLAGS.ENABLE_STORE_CAMERAS && (
            <div className="mt-4 pt-4 border-t border-slate-800 flex flex-wrap items-center justify-between gap-3 text-xs">
              <span className="font-bold text-slate-400 flex items-center gap-1">
                <Camera className="w-4 h-4 text-blue-400" />
                الكاميرات الموزعة على الخريطة (اضغط للانتقال للبث المباشر):
              </span>
              <div className="flex flex-wrap items-center gap-2">
                {INITIAL_CAMERAS.map((cam) => (
                  <button
                    key={cam.id}
                    onClick={() => onSelectCamera(cam)}
                    className={`px-2.5 py-1 rounded-lg text-[11px] font-bold border transition-colors flex items-center gap-1 ${
                      cam.status === 'alert'
                        ? 'bg-rose-500/20 text-rose-300 border-rose-500/40 hover:bg-rose-500/30'
                        : 'bg-slate-900 text-slate-300 border-slate-700 hover:bg-slate-800'
                    }`}
                  >
                    <span className={`w-1.5 h-1.5 rounded-full ${cam.status === 'alert' ? 'bg-rose-500 animate-ping' : 'bg-emerald-400'}`} />
                    {cam.id}
                  </button>
                ))}
              </div>
            </div>
          )}
        </div>

        {/* Selected Zone Deep Dive Panel (4 Cols) */}
        <div className="lg:col-span-4 bg-slate-950 rounded-2xl border border-slate-800 p-5 space-y-4">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-slate-400">تحليل المنطقة المحددة:</span>
            <span className="text-[10px] font-mono bg-blue-500/20 text-blue-300 px-2 py-0.5 rounded-md">
              {selectedZone?.category}
            </span>
          </div>

          {selectedZone && (
            <div className="space-y-4">
              <h4 className="text-base font-extrabold text-white">{selectedZone.nameAr}</h4>

              {/* Occupancy gauge */}
              <div className="space-y-1.5">
                <div className="flex items-center justify-between text-xs">
                  <span className="text-slate-400">الإشغال الحالي:</span>
                  <span className="font-bold text-slate-200">
                    {selectedZone.currentShoppers} من أصل {selectedZone.capacityMax} متسوق
                  </span>
                </div>
                <div className="w-full h-2.5 bg-slate-800 rounded-full overflow-hidden">
                  <div 
                    className={`h-full rounded-full transition-all duration-500 ${
                      selectedZone.densityLevel === 'critical' ? 'bg-rose-500' :
                      selectedZone.densityLevel === 'high' ? 'bg-amber-500' :
                      selectedZone.densityLevel === 'medium' ? 'bg-blue-500' : 'bg-emerald-500'
                    }`}
                    style={{ width: `${(selectedZone.currentShoppers / selectedZone.capacityMax) * 100}%` }}
                  />
                </div>
              </div>

              {/* Dwell stats */}
              <div className="p-3 bg-slate-900 rounded-xl border border-slate-800 flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <Clock className="w-4 h-4 text-purple-400" />
                  <span className="text-xs text-slate-400">متوسط مكوث المتسوق:</span>
                </div>
                <span className="text-sm font-extrabold text-purple-300">
                  {selectedZone.avgDwellMinutes} دقيقة
                </span>
              </div>

              {/* Status Note */}
              <div className={`p-3 rounded-xl border text-xs leading-relaxed ${
                selectedZone.densityLevel === 'critical' 
                  ? 'bg-rose-500/10 border-rose-500/30 text-rose-300' 
                  : 'bg-blue-500/10 border-blue-500/30 text-blue-300'
              }`}>
                {selectedZone.densityLevel === 'critical' ? (
                  <span>⚠️ يُنصح بتوجيه مشرف أو فتح مسار كاشير إضافي فوراً لتفادي اختناق حركة المتسوقين.</span>
                ) : (
                  <span>✅ حركة التسوق في هذا القسم انسيابية ومعدلات التصفح مطابقة للمعايير المثالية.</span>
                )}
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
