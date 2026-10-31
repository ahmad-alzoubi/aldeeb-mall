import React, { useState } from 'react';
import { 
  MapPin, 
  Layers, 
  Zap, 
  DollarSign, 
  Clock, 
  ShieldCheck, 
  ToggleLeft, 
  ToggleRight,
  TrendingUp,
  Compass
} from 'lucide-react';
import { DeliveryZone } from '../types';

interface ZonesPageProps {
  zones: DeliveryZone[];
  onToggleSurge?: (zoneId: string) => void;
}

export const ZonesPage: React.FC<ZonesPageProps> = ({
  zones: initialZones,
}) => {
  const [zones, setZones] = useState<DeliveryZone[]>(initialZones);

  const handleToggleSurge = (zoneId: string) => {
    setZones((prev) =>
      prev.map((z) =>
        z.id === zoneId
          ? {
              ...z,
              is_surge_pricing_active: !z.is_surge_pricing_active,
              surge_fee: !z.is_surge_pricing_active ? 4.0 : 0.0,
            }
          : z
      )
    );
  };

  const handleToggleActive = (zoneId: string) => {
    setZones((prev) =>
      prev.map((z) => (z.id === zoneId ? { ...z, is_active: !z.is_active } : z))
    );
  };

  return (
    <div className="space-y-6">
      {/* Top Banner */}
      <div className="bg-gradient-to-r from-slate-900 to-blue-950 text-white p-6 rounded-2xl shadow-sm flex flex-col md:flex-row items-center justify-between gap-4">
        <div>
          <div className="inline-flex items-center gap-1.5 text-xs font-bold text-blue-300 mb-1">
            <Compass className="w-4 h-4 text-blue-400" />
            نظام النطاقات الجغرافية والتسعير الديناميكي (Geofencing & Dynamic Surge)
          </div>
          <h2 className="text-xl font-black">
            إدارة أقطار التوصيل 15 دقيقة ورسوم الذروة للمستودعات المظلمة
          </h2>
          <p className="text-xs text-slate-300 mt-1 max-w-2xl">
            يتم تحديد نطاق خدمة الـ 15 دقيقة بقطر 3.5 إلى 4 كم لضمان وصول الطلب مبرداً وطازجاً في الوقت القياسي.
          </p>
        </div>
        <div className="flex items-center gap-2 bg-white/10 px-4 py-2.5 rounded-xl border border-white/15">
          <span className="w-2.5 h-2.5 rounded-full bg-emerald-400 animate-pulse"></span>
          <span className="text-xs font-bold">3 نطاقات جغرافية نشطة</span>
        </div>
      </div>

      {/* Zones Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-5">
        {zones.map((zone) => {
          return (
            <div
              key={zone.id}
              className={`bg-white rounded-2xl border transition-all p-5 shadow-sm space-y-4 ${
                zone.is_active ? 'border-slate-200' : 'border-slate-200 opacity-60'
              }`}
            >
              {/* Header */}
              <div className="flex items-start justify-between">
                <div>
                  <span className="text-xs font-mono font-bold text-blue-600 bg-blue-50 px-2 py-0.5 rounded">
                    {zone.dark_store_code}
                  </span>
                  <h3 className="font-bold text-slate-900 text-sm mt-1">{zone.zone_name_ar}</h3>
                </div>
                <button
                  onClick={() => handleToggleActive(zone.id)}
                  className={`text-xs px-2.5 py-1 rounded-lg font-bold transition-colors ${
                    zone.is_active
                      ? 'bg-emerald-100 text-emerald-800'
                      : 'bg-rose-100 text-rose-800'
                  }`}
                >
                  {zone.is_active ? 'مفعل' : 'معطل'}
                </button>
              </div>

              {/* Geo Specs */}
              <div className="space-y-2 bg-slate-50 p-3.5 rounded-xl border border-slate-100 text-xs">
                <div className="flex justify-between text-slate-600">
                  <span className="flex items-center gap-1.5">
                    <Compass className="w-3.5 h-3.5 text-blue-600" />
                    نصف قطر التغطية (Radius):
                  </span>
                  <span className="font-bold text-slate-900">{zone.radius_km} كم</span>
                </div>
                <div className="flex justify-between text-slate-600">
                  <span className="flex items-center gap-1.5">
                    <Clock className="w-3.5 h-3.5 text-blue-600" />
                    زمن الوصول المتعهد به:
                  </span>
                  <span className="font-bold text-blue-600">{zone.estimated_minutes} دقيقة</span>
                </div>
                <div className="flex justify-between text-slate-600">
                  <span className="flex items-center gap-1.5">
                    <DollarSign className="w-3.5 h-3.5 text-blue-600" />
                    رسوم التوصيل الأساسية:
                  </span>
                  <span className="font-mono font-bold text-slate-900">{zone.base_delivery_fee.toFixed(2)} ل.س</span>
                </div>
                <div className="flex justify-between text-slate-600">
                  <span className="flex items-center gap-1.5">
                    <ShieldCheck className="w-3.5 h-3.5 text-emerald-600" />
                    حد الشحن المجاني:
                  </span>
                  <span className="font-mono font-bold text-emerald-700">فوق {zone.free_delivery_threshold} ل.س</span>
                </div>
              </div>

              {/* Surge Pricing Toggle Section */}
              <div className="p-3.5 bg-amber-50/70 border border-amber-200 rounded-xl space-y-2">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-1.5">
                    <Zap className="w-4 h-4 fill-amber-500 text-amber-500" />
                    <span className="text-xs font-bold text-amber-900">تسعير الذروة (Surge Fee)</span>
                  </div>
                  <button
                    onClick={() => handleToggleSurge(zone.id)}
                    className={`text-xs px-2.5 py-1 rounded-lg font-bold transition-all ${
                      zone.is_surge_pricing_active
                        ? 'bg-amber-500 text-white shadow-xs'
                        : 'bg-slate-200 text-slate-700'
                    }`}
                  >
                    {zone.is_surge_pricing_active ? 'مفعل (+4 ل.س)' : 'معطل'}
                  </button>
                </div>
                <p className="text-[11px] text-amber-800 leading-relaxed">
                  {zone.is_surge_pricing_active
                    ? 'يتم تطبيق رسوم إضافية 4.00 ل.س تلقائياً بسبب ذروة الطلبات الحالية لتحفيز السائقين.'
                    : 'التسعير العادي ساري، لا توجد رسوم ذروة في هذا النطاق.'}
                </p>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};
