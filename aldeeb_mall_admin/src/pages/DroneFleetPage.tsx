import React, { useState } from 'react';
import { 
  Plane, 
  BatteryCharging, 
  Wind, 
  MapPin, 
  ShieldAlert, 
  RotateCcw, 
  Video, 
  CheckCircle2, 
  Clock, 
  Navigation,
  Signal,
  Eye,
  Activity,
  Layers,
  Sparkles
} from 'lucide-react';

interface DroneMission {
  id: string;
  droneModel: string;
  droneSerial: string;
  status: 'in_flight' | 'landing_winch' | 'returning' | 'docked_charging' | 'standby';
  batteryPercent: number;
  altitudeMeters: number;
  speedKmh: number;
  originHelipad: string;
  destination: string;
  payloadKg: number;
  gacaPermit: string;
  etaMinutes: number;
  windSpeedKnots: number;
  liveFeedActive: boolean;
}

export const DroneFleetPage: React.FC = () => {
  const [drones, setDrones] = useState<DroneMission[]>([
    {
      id: 'drn-01',
      droneModel: 'Falcon-X Hexacopter Carbon',
      droneSerial: 'ALDEEB-UAV-01',
      status: 'in_flight',
      batteryPercent: 88,
      altitudeMeters: 64,
      speedKmh: 72,
      originHelipad: 'مهبط كافد H1',
      destination: 'حي النرجس - فيلا 14',
      payloadKg: 2.8,
      gacaPermit: 'GACA-DRN-2026-9041',
      etaMinutes: 4.2,
      windSpeedKnots: 11,
      liveFeedActive: true,
    },
    {
      id: 'drn-02',
      droneModel: 'Falcon-X Hexacopter Carbon',
      droneSerial: 'ALDEEB-UAV-02',
      status: 'landing_winch',
      batteryPercent: 62,
      altitudeMeters: 15,
      speedKmh: 0,
      originHelipad: 'مهبط حطين H2',
      destination: 'حي العقيق - برج اليمامة',
      payloadKg: 3.4,
      gacaPermit: 'GACA-DRN-2026-9042',
      etaMinutes: 0.5,
      windSpeedKnots: 9,
      liveFeedActive: true,
    },
    {
      id: 'drn-03',
      droneModel: 'Skylark Quad-Lift Long Range',
      droneSerial: 'ALDEEB-UAV-03',
      status: 'returning',
      batteryPercent: 54,
      altitudeMeters: 80,
      speedKmh: 85,
      originHelipad: 'مهبط الدرعية H3',
      destination: 'عائد إلى مهبط كافد H1',
      payloadKg: 0.0,
      gacaPermit: 'GACA-DRN-2026-9039',
      etaMinutes: 3.1,
      windSpeedKnots: 12,
      liveFeedActive: false,
    },
    {
      id: 'drn-04',
      droneModel: 'Falcon-X Hexacopter Carbon',
      droneSerial: 'ALDEEB-UAV-04',
      status: 'docked_charging',
      batteryPercent: 96,
      altitudeMeters: 0,
      speedKmh: 0,
      originHelipad: 'مهبط كافد H1 (منصة شحن سريع 120A)',
      destination: 'جاهز للإقلاع والمهمة القادمة',
      payloadKg: 0.0,
      gacaPermit: 'GACA-STANDBY',
      etaMinutes: 0,
      windSpeedKnots: 8,
      liveFeedActive: false,
    },
    {
      id: 'drn-05',
      droneModel: 'Skylark Quad-Lift Long Range',
      droneSerial: 'ALDEEB-UAV-05',
      status: 'standby',
      batteryPercent: 100,
      altitudeMeters: 0,
      speedKmh: 0,
      originHelipad: 'مهبط حطين H2',
      destination: 'جاهز في الهنجر',
      payloadKg: 0.0,
      gacaPermit: 'GACA-STANDBY',
      etaMinutes: 0,
      windSpeedKnots: 8,
      liveFeedActive: false,
    },
  ]);

  const [selectedDrone, setSelectedDrone] = useState<DroneMission | null>(null);

  // Return to base trigger
  const handleReturnToBase = (id: string) => {
    setDrones((prev) =>
      prev.map((d) =>
        d.id === id
          ? {
              ...d,
              status: 'returning',
              destination: 'أمر عودة اضطراري للقاعدة (RTH Triggered)',
              speedKmh: 85,
              altitudeMeters: 80,
            }
          : d
      )
    );
  };

  const activeInAir = drones.filter((d) => d.status === 'in_flight' || d.status === 'landing_winch' || d.status === 'returning').length;

  return (
    <div className="p-6 space-y-6 max-w-7xl mx-auto text-slate-800" dir="rtl">
      {/* Header Banner */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 bg-gradient-to-l from-slate-950 via-slate-900 to-cyan-950 p-6 rounded-2xl text-white shadow-xl">
        <div className="flex items-center gap-4">
          <div className="p-3 bg-white/10 backdrop-blur-md rounded-xl border border-white/20">
            <Plane className="w-8 h-8 text-cyan-300" />
          </div>
          <div>
            <div className="flex items-center gap-3">
              <h1 className="text-2xl font-black tracking-tight">أسطول درونز الديب للشحن الجوي الفائق</h1>
              <span className="px-2.5 py-0.5 rounded-full text-xs font-bold bg-cyan-400/20 text-cyan-300 border border-cyan-400/30">
                GACA Air Corridor Certified
              </span>
            </div>
            <p className="text-slate-300 text-sm mt-1">
              مراقبة الرادار الجوي اللحظي، توجيه الطائرات المسيرة ذاتية القيادة، وتتبع إنزال الطرود بالرافعة خلال 10 دقائق
            </p>
          </div>
        </div>

        <div className="flex items-center gap-2">
          <div className="bg-slate-800/80 px-4 py-2.5 rounded-xl border border-slate-700 flex items-center gap-3">
            <Wind className="w-5 h-5 text-cyan-400" />
            <div className="text-xs">
              <p className="font-bold text-white">الطقس وسرعة الرياح</p>
              <p className="text-cyan-300">11 عقدة • رؤية 10 كم (مثالي 🟢)</p>
            </div>
          </div>
        </div>
      </div>

      {/* KPI Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-xs flex items-center justify-between">
          <div>
            <p className="text-xs font-semibold text-slate-500">طائرات في الجو الآن</p>
            <p className="text-2xl font-black text-cyan-700 mt-1">{activeInAir} طائرات</p>
            <p className="text-xs text-cyan-600 font-medium mt-1">من أصل {drones.length} بالأسطول</p>
          </div>
          <div className="p-3 bg-cyan-50 rounded-xl">
            <Plane className="w-6 h-6 text-cyan-600" />
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-xs flex items-center justify-between">
          <div>
            <p className="text-xs font-semibold text-slate-500">متوسط وقت الطيران والتسليم</p>
            <p className="text-2xl font-black text-slate-900 mt-1">6.8 دقيقة</p>
            <p className="text-xs text-emerald-600 font-medium mt-1">أسرع بـ 65% من الدراجات</p>
          </div>
          <div className="p-3 bg-emerald-50 rounded-xl">
            <Clock className="w-6 h-6 text-emerald-600" />
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-xs flex items-center justify-between">
          <div>
            <p className="text-xs font-semibold text-slate-500">نجاح الإنزال بالرافعة (Winch)</p>
            <p className="text-2xl font-black text-emerald-600 mt-1">99.7%</p>
            <p className="text-xs text-slate-500 font-medium mt-1">حساسات استشعار القرب الأرضي</p>
          </div>
          <div className="p-3 bg-teal-50 rounded-xl">
            <CheckCircle2 className="w-6 h-6 text-teal-600" />
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-xs flex items-center justify-between">
          <div>
            <p className="text-xs font-semibold text-slate-500">ترخيص الممر الجوي (GACA)</p>
            <p className="text-2xl font-black text-blue-600 mt-1">نشط ومصرح</p>
            <p className="text-xs text-blue-600 font-medium mt-1">تتبع إلكتروني متصل بالرادار</p>
          </div>
          <div className="p-3 bg-blue-50 rounded-xl">
            <Signal className="w-6 h-6 text-blue-600" />
          </div>
        </div>
      </div>

      {/* Drone Fleet Table */}
      <div className="bg-white rounded-2xl border border-slate-200 shadow-xs overflow-hidden">
        <div className="p-4 border-b border-slate-100 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Activity className="w-5 h-5 text-cyan-600" />
            <h3 className="font-bold text-sm text-slate-900">طائرات أسطول الشحن الجوي الفائق وقائمة المهام</h3>
          </div>
          <span className="text-xs text-slate-500">تحديث القياسات عن بُعد لحظي عبر 5G Telemetry</span>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-right text-xs">
            <thead className="bg-slate-50 text-slate-600 font-bold border-b border-slate-200">
              <tr>
                <th className="p-3.5">الدرونز والرقم التسلسلي</th>
                <th className="p-3.5">الحالة الميدانية</th>
                <th className="p-3.5">البطارية</th>
                <th className="p-3.5">الارتفاع والسرعة</th>
                <th className="p-3.5">المهبط والوجهة</th>
                <th className="p-3.5">الحمولة المنقولة</th>
                <th className="p-3.5">الوقت للوصول</th>
                <th className="p-3.5 text-center">الإجراءات اللحظية</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {drones.map((drone) => (
                <tr key={drone.id} className="hover:bg-slate-50/80 transition-colors">
                  <td className="p-3.5">
                    <div className="font-bold text-slate-800">{drone.droneSerial}</div>
                    <div className="text-[11px] text-slate-400">{drone.droneModel}</div>
                  </td>
                  <td className="p-3.5">
                    {drone.status === 'in_flight' && (
                      <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-cyan-50 text-cyan-700 border border-cyan-200 font-bold text-[11px]">
                        <Plane className="w-3 h-3" /> محلّق بالجو
                      </span>
                    )}
                    {drone.status === 'landing_winch' && (
                      <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-amber-50 text-amber-700 border border-amber-200 font-bold text-[11px]">
                        <Activity className="w-3 h-3 animate-spin" /> إنزال الكابل
                      </span>
                    )}
                    {drone.status === 'returning' && (
                      <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-indigo-50 text-indigo-700 border border-indigo-200 font-bold text-[11px]">
                        <RotateCcw className="w-3 h-3" /> عائد للمهبط
                      </span>
                    )}
                    {drone.status === 'docked_charging' && (
                      <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-emerald-50 text-emerald-700 border border-emerald-200 font-bold text-[11px]">
                        <BatteryCharging className="w-3 h-3" /> يشحن على المهبط
                      </span>
                    )}
                    {drone.status === 'standby' && (
                      <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-slate-100 text-slate-700 border border-slate-200 font-bold text-[11px]">
                        جاهز ومستعد
                      </span>
                    )}
                  </td>
                  <td className="p-3.5">
                    <div className="flex items-center gap-1.5 font-bold font-mono text-slate-800">
                      <BatteryCharging className="w-4 h-4 text-emerald-600" />
                      {drone.batteryPercent}%
                    </div>
                  </td>
                  <td className="p-3.5">
                    <div className="font-mono text-slate-800 font-bold">{drone.altitudeMeters} م</div>
                    <div className="text-[10px] text-slate-400 font-mono">{drone.speedKmh} كم/س</div>
                  </td>
                  <td className="p-3.5">
                    <div className="font-semibold text-slate-800">{drone.destination}</div>
                    <div className="text-[10px] text-slate-400">من: {drone.originHelipad}</div>
                  </td>
                  <td className="p-3.5 font-mono font-bold text-slate-700">
                    {drone.payloadKg > 0 ? `${drone.payloadKg} كجم` : 'بدون حمولة'}
                  </td>
                  <td className="p-3.5">
                    {drone.etaMinutes > 0 ? (
                      <span className="font-mono font-bold text-cyan-700">{drone.etaMinutes} دقيقة</span>
                    ) : (
                      <span className="text-slate-400">--</span>
                    )}
                  </td>
                  <td className="p-3.5 text-center">
                    <div className="flex items-center justify-center gap-1.5">
                      <button
                        onClick={() => setSelectedDrone(drone)}
                        className="p-1.5 text-cyan-700 hover:bg-cyan-50 rounded-lg transition-colors"
                        title="معاينة القياسات عن بُعد والكاميرا"
                      >
                        <Eye className="w-4 h-4" />
                      </button>

                      {drone.status === 'in_flight' && (
                        <button
                          onClick={() => handleReturnToBase(drone.id)}
                          className="px-2.5 py-1 bg-red-600 hover:bg-red-700 text-white rounded-lg font-bold text-[11px] transition-colors flex items-center gap-1"
                          title="إلغاء وأمر عودة للقاعدة فوراً"
                        >
                          <RotateCcw className="w-3 h-3" />
                          RTH
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Selected Drone Telemetry Modal */}
      {selectedDrone && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4 z-50">
          <div className="bg-slate-900 border border-cyan-800 text-white rounded-2xl max-w-xl w-full p-6 space-y-4 shadow-2xl animate-in fade-in zoom-in duration-150">
            <div className="flex items-center justify-between border-b pb-3 border-slate-800">
              <div className="flex items-center gap-2">
                <Plane className="w-6 h-6 text-cyan-400" />
                <h3 className="font-bold text-lg">
                  كاميرا الرؤية المباشرة والقياسات ({selectedDrone.droneSerial})
                </h3>
              </div>
              <button
                onClick={() => setSelectedDrone(null)}
                className="text-slate-400 hover:text-white p-1"
              >
                ✕
              </button>
            </div>

            {/* Simulated Live Camera Feed */}
            <div className="relative h-56 bg-slate-950 rounded-xl overflow-hidden border border-cyan-900/60 flex items-center justify-center">
              <div className="absolute top-3 right-3 flex items-center gap-2 bg-black/70 px-2.5 py-1 rounded-md text-[10px] font-mono text-red-400">
                <span className="w-2 h-2 rounded-full bg-red-500 animate-ping" />
                LIVE FPV 1080p • 60 FPS
              </div>
              <div className="text-center space-y-2">
                <Video className="w-10 h-10 text-cyan-500/40 mx-auto" />
                <p className="text-xs text-slate-400 font-mono">
                  HUD TELEMETRY: ALT {selectedDrone.altitudeMeters}M | SPD {selectedDrone.speedKmh}KM/H | BAT {selectedDrone.batteryPercent}%
                </p>
                <p className="text-[11px] text-cyan-400 font-mono">
                  GACA PERMIT: {selectedDrone.gacaPermit}
                </p>
              </div>
            </div>

            <div className="grid grid-cols-2 gap-3 text-xs bg-slate-800/60 p-3 rounded-xl border border-slate-700">
              <div>
                <span className="text-slate-400">الطراز:</span>{' '}
                <span className="font-bold text-white">{selectedDrone.droneModel}</span>
              </div>
              <div>
                <span className="text-slate-400">الحمولة:</span>{' '}
                <span className="font-mono font-bold text-cyan-400">{selectedDrone.payloadKg} كجم</span>
              </div>
              <div>
                <span className="text-slate-400">نقطة الإقلاع:</span>{' '}
                <span className="font-bold text-white">{selectedDrone.originHelipad}</span>
              </div>
              <div>
                <span className="text-slate-400">الوجهة:</span>{' '}
                <span className="font-bold text-white">{selectedDrone.destination}</span>
              </div>
            </div>

            <div className="flex items-center justify-between pt-2">
              <span className="text-xs text-slate-400 font-mono">
                LAT: 24.77426 • LNG: 46.63852 (Riyadh Air Corridor #4)
              </span>
              <button
                onClick={() => setSelectedDrone(null)}
                className="px-4 py-2 bg-cyan-600 hover:bg-cyan-700 text-white rounded-xl text-xs font-bold transition-colors"
              >
                إغلاق النافذة
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
