import React, { useState } from 'react';
import { 
  Boxes, 
  DoorClosed, 
  DoorOpen, 
  ThermometerSnowflake, 
  Lock, 
  Unlock, 
  AlertTriangle, 
  Search, 
  Clock, 
  Send, 
  CheckCircle2, 
  ShieldCheck, 
  MapPin, 
  RotateCw,
  QrCode,
  Package
} from 'lucide-react';

interface LockerDoor {
  doorNo: number;
  type: 'chilled' | 'frozen' | 'ambient';
  temperature: string;
  isOccupied: boolean;
  isDoorOpen: boolean;
  orderId?: string;
  customerName?: string;
  customerPhone?: string;
  pinCode?: string;
  depositedAt?: string;
  hoursRemaining?: number;
}

export const SmartLockersPage: React.FC = () => {
  const [selectedHub, setSelectedHub] = useState<string>('kafd');
  const [searchQuery, setSearchQuery] = useState('');

  // Initial Locker Grid Doors (24 Doors for KAFD)
  const [doors, setDoors] = useState<LockerDoor[]>([
    { doorNo: 1, type: 'frozen', temperature: '-18.5°C', isOccupied: true, isDoorOpen: false, orderId: '#ORD-88102', customerName: 'سارة العتيبي', pinCode: '391024', depositedAt: 'منذ 3 ساعات', hoursRemaining: 21 },
    { doorNo: 2, type: 'frozen', temperature: '-18.2°C', isOccupied: false, isDoorOpen: false },
    { doorNo: 3, type: 'frozen', temperature: '-19.0°C', isOccupied: true, isDoorOpen: false, orderId: '#ORD-88155', customerName: 'خالد العنزي', pinCode: '741290', depositedAt: 'منذ 8 ساعات', hoursRemaining: 16 },
    { doorNo: 4, type: 'frozen', temperature: '-18.7°C', isOccupied: false, isDoorOpen: false },
    
    { doorNo: 5, type: 'chilled', temperature: '3.2°C', isOccupied: true, isDoorOpen: false, orderId: '#ORD-88201', customerName: 'فهد المطيري', pinCode: '109823', depositedAt: 'منذ 1 ساعة', hoursRemaining: 23 },
    { doorNo: 6, type: 'chilled', temperature: '3.6°C', isOccupied: true, isDoorOpen: false, orderId: '#ORD-88210', customerName: 'نورة الدوسري', pinCode: '552341', depositedAt: 'منذ 14 ساعة', hoursRemaining: 10 },
    { doorNo: 7, type: 'chilled', temperature: '3.4°C', isOccupied: false, isDoorOpen: false },
    { doorNo: 8, type: 'chilled', temperature: '3.8°C', isOccupied: true, isDoorOpen: false, orderId: '#ORD-88219', customerName: 'سعود القحطاني', pinCode: '849201', depositedAt: 'منذ 6 ساعات', hoursRemaining: 18 },
    { doorNo: 9, type: 'chilled', temperature: '3.5°C', isOccupied: false, isDoorOpen: false },
    { doorNo: 10, type: 'chilled', temperature: '3.1°C', isOccupied: true, isDoorOpen: false, orderId: '#ORD-88099', customerName: 'عبدالرحمن الشهري', pinCode: '901284', depositedAt: 'منذ 26 ساعة', hoursRemaining: -2 }, // Overdue
    { doorNo: 11, type: 'chilled', temperature: '3.7°C', isOccupied: false, isDoorOpen: false },
    { doorNo: 12, type: 'chilled', temperature: '3.3°C', isOccupied: true, isDoorOpen: false, orderId: '#ORD-88240', customerName: 'ريم الغامدي', pinCode: '448102', depositedAt: 'منذ ساعتين', hoursRemaining: 22 },

    { doorNo: 13, type: 'ambient', temperature: '22.1°C', isOccupied: true, isDoorOpen: false, orderId: '#ORD-88190', customerName: 'تركي الشمري', pinCode: '310928', depositedAt: 'منذ 5 ساعات', hoursRemaining: 19 },
    { doorNo: 14, type: 'ambient', temperature: '21.8°C', isOccupied: false, isDoorOpen: false },
    { doorNo: 15, type: 'ambient', temperature: '22.4°C', isOccupied: true, isDoorOpen: false, orderId: '#ORD-88188', customerName: 'هند السبيعي', pinCode: '661029', depositedAt: 'منذ 11 ساعة', hoursRemaining: 13 },
    { doorNo: 16, type: 'ambient', temperature: '22.0°C', isOccupied: false, isDoorOpen: false },
    { doorNo: 17, type: 'ambient', temperature: '21.9°C', isOccupied: true, isDoorOpen: false, orderId: '#ORD-88050', customerName: 'بندر الحربي', pinCode: '881029', depositedAt: 'منذ 28 ساعة', hoursRemaining: -4 }, // Overdue
    { doorNo: 18, type: 'ambient', temperature: '22.3°C', isOccupied: true, isDoorOpen: false, orderId: '#ORD-88255', customerName: 'منى الخالدي', pinCode: '772910', depositedAt: 'منذ 4 ساعات', hoursRemaining: 20 },
    { doorNo: 19, type: 'ambient', temperature: '22.2°C', isOccupied: false, isDoorOpen: false },
    { doorNo: 20, type: 'ambient', temperature: '21.7°C', isOccupied: true, isDoorOpen: false, orderId: '#ORD-88260', customerName: 'عمر باوزير', pinCode: '229104', depositedAt: 'منذ ساعة', hoursRemaining: 23 },
    { doorNo: 21, type: 'ambient', temperature: '22.5°C', isOccupied: false, isDoorOpen: false },
    { doorNo: 22, type: 'ambient', temperature: '22.0°C', isOccupied: false, isDoorOpen: false },
    { doorNo: 23, type: 'ambient', temperature: '21.8°C', isOccupied: true, isDoorOpen: false, orderId: '#ORD-88277', customerName: 'فيصل المالكي', pinCode: '491028', depositedAt: 'منذ 3 ساعات', hoursRemaining: 21 },
    { doorNo: 24, type: 'ambient', temperature: '22.1°C', isOccupied: false, isDoorOpen: false },
  ]);

  // Handle Remote Master Unlock
  const handleRemoteUnlock = (doorNo: number) => {
    setDoors((prev) =>
      prev.map((d) =>
        d.doorNo === doorNo ? { ...d, isDoorOpen: !d.isDoorOpen } : d
      )
    );
  };

  const occupiedCount = doors.filter((d) => d.isOccupied).length;
  const overdueDoors = doors.filter((d) => d.isOccupied && (d.hoursRemaining ?? 0) <= 0);

  return (
    <div className="p-6 space-y-6 max-w-7xl mx-auto text-slate-800" dir="rtl">
      {/* Header Banner */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 bg-gradient-to-l from-slate-900 via-slate-800 to-cyan-950 p-6 rounded-2xl text-white shadow-xl">
        <div className="flex items-center gap-4">
          <div className="p-3 bg-white/10 backdrop-blur-md rounded-xl border border-white/20">
            <Boxes className="w-8 h-8 text-cyan-300" />
          </div>
          <div>
            <div className="flex items-center gap-3">
              <h1 className="text-2xl font-black tracking-tight">شبكة خزائن الاستلام الذكية 24/7</h1>
              <span className="px-2.5 py-0.5 rounded-full text-xs font-bold bg-cyan-400/20 text-cyan-300 border border-cyan-400/30">
                Aldeeb Smart Lockers Hub
              </span>
            </div>
            <p className="text-slate-300 text-sm mt-1">
              مراقبة الخلايا الذكية اللحظية، التحكم بدرجات التبريد والتجميد، والفتح المركزي عن بُعد
            </p>
          </div>
        </div>

        {/* Hub Selector */}
        <div className="flex items-center gap-2">
          <div className="bg-slate-800/80 px-4 py-2 rounded-xl border border-slate-700 flex items-center gap-3">
            <MapPin className="w-4 h-4 text-cyan-400" />
            <select
              value={selectedHub}
              onChange={(e) => setSelectedHub(e.target.value)}
              className="bg-transparent text-white text-xs font-bold focus:outline-hidden"
            >
              <option value="kafd" className="bg-slate-900 text-white">محطة كافد المالية - الرياض (24 خلية)</option>
              <option value="nakheel" className="bg-slate-900 text-white">محطة النخيل مول - بوابة 3 (32 خلية)</option>
              <option value="digital_city" className="bg-slate-900 text-white">محطة المدينة الرقمية (24 خلية)</option>
              <option value="jeddah" className="bg-slate-900 text-white">محطة كورنيش جدة (20 خلية)</option>
            </select>
          </div>
        </div>
      </div>

      {/* KPI Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-xs flex items-center justify-between">
          <div>
            <p className="text-xs font-semibold text-slate-500">إجمالي الخلايا العاملة</p>
            <p className="text-2xl font-black text-slate-900 mt-1">{doors.length} خلية</p>
            <p className="text-xs text-emerald-600 font-medium mt-1">جاهزية تشغيلية 100%</p>
          </div>
          <div className="p-3 bg-slate-100 rounded-xl">
            <Boxes className="w-6 h-6 text-slate-700" />
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-xs flex items-center justify-between">
          <div>
            <p className="text-xs font-semibold text-slate-500">الخلايا المشغولة حالياً</p>
            <p className="text-2xl font-black text-cyan-700 mt-1">
              {occupiedCount} / {doors.length}
            </p>
            <p className="text-xs text-cyan-700 font-medium mt-1">
              نسبة الإشغال: {Math.round((occupiedCount / doors.length) * 100)}%
            </p>
          </div>
          <div className="p-3 bg-cyan-50 rounded-xl">
            <DoorClosed className="w-6 h-6 text-cyan-600" />
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-xs flex items-center justify-between">
          <div>
            <p className="text-xs font-semibold text-slate-500">الخلايا المتاحة للإيداع</p>
            <p className="text-2xl font-black text-emerald-600 mt-1">
              {doors.length - occupiedCount} خلية
            </p>
            <p className="text-xs text-emerald-600 font-medium mt-1">جاهزة لاستقبال كباتن التوصيل</p>
          </div>
          <div className="p-3 bg-emerald-50 rounded-xl">
            <CheckCircle2 className="w-6 h-6 text-emerald-600" />
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-xs flex items-center justify-between">
          <div>
            <p className="text-xs font-semibold text-slate-500">طرود متأخرة عن الاستلام</p>
            <p className="text-2xl font-black text-red-600 mt-1">{overdueDoors.length} طرود</p>
            <p className="text-xs text-red-600 font-medium mt-1">تجاوزت مهلة الـ 24 ساعة</p>
          </div>
          <div className="p-3 bg-red-50 rounded-xl">
            <AlertTriangle className="w-6 h-6 text-red-600" />
          </div>
        </div>
      </div>

      {/* Overdue Warning Callout */}
      {overdueDoors.length > 0 && (
        <div className="p-4 rounded-xl bg-amber-50 border border-amber-200 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <AlertTriangle className="w-5 h-5 text-amber-600 shrink-0" />
            <div>
              <p className="text-sm font-bold text-amber-900">
                يوجد {overdueDoors.length} طرود تجاوزت 24 ساعة في الخزائن ({overdueDoors.map((d) => `#${d.doorNo}`).join(', ')})
              </p>
              <p className="text-xs text-amber-700 mt-0.5">
                يمكنك إعادة إرسال رسالة تذكير فورية SMS للعميل أو جدولة استرداد الطرد إلى الدارك ستور.
              </p>
            </div>
          </div>
          <button
            onClick={() => alert('تم إرسال رسائل تذكير فورية SMS للعملاء المتأخرين')}
            className="px-3.5 py-1.5 bg-amber-600 hover:bg-amber-700 text-white rounded-lg text-xs font-bold transition-colors flex items-center gap-1.5"
          >
            <Send className="w-3.5 h-3.5" />
            تذكير الكل SMS
          </button>
        </div>
      )}

      {/* 24-Locker Matrix Visual Grid */}
      <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-xs space-y-4">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
          <div>
            <h3 className="text-base font-bold text-slate-900 flex items-center gap-2">
              <Boxes className="w-5 h-5 text-cyan-600" />
              مصفوفة خلايا الخزانة التفاعلية (24 Doors Visual Matrix)
            </h3>
            <p className="text-xs text-slate-500 mt-0.5">
              الألوان: الأزرق (تجميد -18°C) • السماوي (تبريد 4°C) • الرمادي (جاف معتدل)
            </p>
          </div>

          <div className="flex items-center gap-2">
            <span className="inline-flex items-center gap-1 text-[11px] font-bold text-indigo-700 bg-indigo-50 px-2 py-1 rounded-md">
              <span className="w-2 h-2 rounded-full bg-indigo-500" /> مجمد 4
            </span>
            <span className="inline-flex items-center gap-1 text-[11px] font-bold text-cyan-700 bg-cyan-50 px-2 py-1 rounded-md">
              <span className="w-2 h-2 rounded-full bg-cyan-500" /> مبرد 8
            </span>
            <span className="inline-flex items-center gap-1 text-[11px] font-bold text-slate-700 bg-slate-100 px-2 py-1 rounded-md">
              <span className="w-2 h-2 rounded-full bg-slate-400" /> جاف 12
            </span>
          </div>
        </div>

        {/* The 24 Doors Grid */}
        <div className="grid grid-cols-2 sm:grid-cols-4 md:grid-cols-6 gap-3 pt-2">
          {doors.map((door) => {
            const isOverdue = door.isOccupied && (door.hoursRemaining ?? 0) <= 0;
            return (
              <div
                key={door.doorNo}
                className={`p-3.5 rounded-xl border transition-all duration-200 ${
                  door.isDoorOpen
                    ? 'border-amber-400 bg-amber-50/50 shadow-md'
                    : door.isOccupied
                        ? isOverdue
                            ? 'border-red-300 bg-red-50/40'
                            : 'border-slate-300 bg-slate-50/80'
                        : 'border-dashed border-slate-200 bg-white hover:border-slate-300'
                }`}
              >
                {/* Top header of door */}
                <div className="flex items-center justify-between">
                  <span className="font-black text-sm text-slate-800">#{door.doorNo}</span>
                  <span
                    className={`text-[10px] font-bold px-1.5 py-0.5 rounded-md ${
                      door.type === 'frozen'
                        ? 'bg-indigo-100 text-indigo-800'
                        : door.type === 'chilled'
                            ? 'bg-cyan-100 text-cyan-800'
                            : 'bg-slate-200 text-slate-800'
                    }`}
                  >
                    {door.temperature}
                  </span>
                </div>

                {/* Status Content */}
                <div className="my-2.5 min-h-[52px]">
                  {door.isOccupied ? (
                    <div>
                      <div className="font-bold text-xs text-slate-800 truncate">{door.customerName}</div>
                      <div className="text-[10px] text-slate-500 font-mono">{door.orderId}</div>
                      <div className="text-[10px] font-mono font-bold text-emerald-700 mt-0.5">
                        PIN: {door.pinCode}
                      </div>
                      {isOverdue && (
                        <div className="text-[9px] font-bold text-red-600 mt-0.5">⚠️ متأخر عن الاستلام</div>
                      )}
                    </div>
                  ) : (
                    <div className="flex flex-col items-center justify-center h-full text-slate-400">
                      <Package className="w-5 h-5 opacity-40 mb-1" />
                      <span className="text-[10px] font-semibold">خلية شاغرة</span>
                    </div>
                  )}
                </div>

                {/* Bottom Action Bar */}
                <div className="flex items-center justify-between pt-2 border-t border-slate-200/60">
                  <div className="flex items-center gap-1">
                    {door.isDoorOpen ? (
                      <span className="inline-flex items-center gap-1 text-[10px] font-bold text-amber-700">
                        <DoorOpen className="w-3 h-3" /> مفتوح
                      </span>
                    ) : (
                      <span className="inline-flex items-center gap-1 text-[10px] font-bold text-slate-500">
                        <DoorClosed className="w-3 h-3" /> مقفل
                      </span>
                    )}
                  </div>

                  <button
                    onClick={() => handleRemoteUnlock(door.doorNo)}
                    title="فتح / إغلاق الباب عن بُعد"
                    className={`p-1 rounded-md transition-colors ${
                      door.isDoorOpen
                        ? 'bg-amber-500 text-white hover:bg-amber-600'
                        : 'bg-slate-200 text-slate-700 hover:bg-slate-300'
                    }`}
                  >
                    {door.isDoorOpen ? <Unlock className="w-3.5 h-3.5" /> : <Lock className="w-3.5 h-3.5" />}
                  </button>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
};
