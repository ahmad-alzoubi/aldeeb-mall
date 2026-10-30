import React, { useState } from 'react';
import { 
  Warehouse, 
  ScanLine, 
  CheckCircle2, 
  Clock, 
  MapPin, 
  AlertTriangle, 
  Search, 
  ArrowRight,
  Boxes,
  Activity
} from 'lucide-react';
import { DarkStore, PickerTask } from '../types';

interface FulfillmentPageProps {
  darkStores: DarkStore[];
  pickerTasks: PickerTask[];
  onVerifyTask?: (taskId: string) => void;
}

export const FulfillmentPage: React.FC<FulfillmentPageProps> = ({
  darkStores,
  pickerTasks: initialTasks,
}) => {
  const [selectedStoreId, setSelectedStoreId] = useState<string>(darkStores[0]?.id || '');
  const [tasks, setTasks] = useState<PickerTask[]>(initialTasks);
  const [scanInput, setScanInput] = useState<string>('');
  const [scanMessage, setScanMessage] = useState<{ text: string; success: boolean } | null>(null);

  const selectedStore = darkStores.find((s) => s.id === selectedStoreId) || darkStores[0];

  const handleSimulateScan = (task: PickerTask) => {
    setTasks((prev) =>
      prev.map((t) =>
        t.id === task.id
          ? {
              ...t,
              quantity_picked: t.quantity_required,
              is_verified: true,
              status: 'verified',
            }
          : t
      )
    );
    setScanMessage({
      text: `✓ تم التحقق بنجاح من الصنف: ${task.product_name_ar} (باركود: ${task.barcode})`,
      success: true,
    });
    setTimeout(() => setScanMessage(null), 4000);
  };

  const handleManualScanSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!scanInput.trim()) return;

    const matched = tasks.find(
      (t) => t.barcode === scanInput.trim() || t.bin_location.toLowerCase() === scanInput.trim().toLowerCase()
    );

    if (matched) {
      handleSimulateScan(matched);
      setScanInput('');
    } else {
      setScanMessage({
        text: `خطأ: الرمز أو الباركود "${scanInput}" غير مطابق لأي صنف في قائمة المهام الحالية!`,
        success: false,
      });
      setTimeout(() => setScanMessage(null), 4000);
    }
  };

  const verifiedCount = tasks.filter((t) => t.is_verified).length;
  const progressPercent = Math.round((verifiedCount / tasks.length) * 100) || 0;

  return (
    <div className="space-y-6">
      {/* Top Dark Store Facility Selector & Real-Time Stats */}
      <div className="grid grid-cols-1 lg:grid-cols-4 gap-4">
        {darkStores.map((store) => {
          const isSelected = store.id === selectedStore?.id;
          return (
            <div
              key={store.id}
              onClick={() => setSelectedStoreId(store.id)}
              className={`p-4 rounded-xl border cursor-pointer transition-all ${
                isSelected
                  ? 'bg-blue-900 text-white border-blue-900 shadow-md ring-2 ring-blue-500/50'
                  : 'bg-white text-slate-700 border-slate-200 hover:border-blue-300'
              }`}
            >
              <div className="flex items-center justify-between mb-2">
                <span className={`text-xs px-2 py-0.5 rounded font-mono font-bold ${
                  isSelected ? 'bg-blue-800 text-blue-200' : 'bg-slate-100 text-slate-600'
                }`}>
                  {store.code}
                </span>
                <span className={`flex items-center gap-1 text-xs font-medium ${
                  isSelected ? 'text-emerald-300' : 'text-emerald-600'
                }`}>
                  <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
                  نشط ومفتوح
                </span>
              </div>
              <h3 className="font-bold text-sm mb-1">{store.name_ar}</h3>
              <p className={`text-xs mb-3 ${isSelected ? 'text-blue-200' : 'text-slate-500'}`}>
                {store.city} • نطاق التغطية: {store.radius_km} كم
              </p>
              <div className="grid grid-cols-3 gap-2 pt-2 border-t border-slate-100/20 text-center text-xs">
                <div>
                  <div className="font-bold">{store.active_pickers}</div>
                  <div className={isSelected ? 'text-blue-300' : 'text-slate-400'}>جامعي الطلبات</div>
                </div>
                <div>
                  <div className="font-bold">{store.pending_wave_orders}</div>
                  <div className={isSelected ? 'text-blue-300' : 'text-slate-400'}>طلبات معلقة</div>
                </div>
                <div>
                  <div className="font-bold">{store.avg_pick_seconds}ث</div>
                  <div className={isSelected ? 'text-blue-300' : 'text-slate-400'}>متوسط الجمع</div>
                </div>
              </div>
            </div>
          );
        })}

        {/* Global Picking SLA Card */}
        <div className="bg-gradient-to-br from-slate-900 to-slate-800 text-white p-4 rounded-xl border border-slate-700 flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between text-xs text-slate-300 mb-2">
              <span className="flex items-center gap-1.5">
                <Activity className="w-4 h-4 text-emerald-400" />
                مؤشر سرعة المستودعات (SLA)
              </span>
              <span className="bg-emerald-500/20 text-emerald-300 px-2 py-0.5 rounded font-bold">
                99.4% التزام
              </span>
            </div>
            <div className="text-2xl font-black text-white mb-1">11 دقيقة و 40 ثانية</div>
            <p className="text-xs text-slate-400">
              متوسط الزمن الكلي من نقرة العميل حتى استلام السائق لحقيبة التوصيل المبردة.
            </p>
          </div>
          <div className="mt-3 pt-3 border-t border-slate-700/60 flex items-center justify-between text-xs text-slate-300">
            <span>دقة المسح بالباركود:</span>
            <span className="font-bold text-emerald-400">100% تطابق</span>
          </div>
        </div>
      </div>

      {/* Barcode Scanner & Wave Picking Command Line */}
      <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-4">
          <div>
            <h2 className="text-lg font-bold text-slate-800 flex items-center gap-2">
              <ScanLine className="w-5 h-5 text-blue-600" />
              محطة التحقق ومسح الباركود الرقمي (Smart Pick-Station)
            </h2>
            <p className="text-xs text-slate-500 mt-1">
              قم بمسح باركود الصنف أو كتابة رمز الرف للتأكد من جمع الصنف الصحيح بنسبة 100%.
            </p>
          </div>
          <div className="flex items-center gap-3">
            <div className="text-xs text-slate-500 font-medium">
              نسبة إنجاز دفعة الجمع الحالية: <span className="font-bold text-blue-600">{verifiedCount} من {tasks.length}</span>
            </div>
            <div className="w-32 bg-slate-100 rounded-full h-2.5 overflow-hidden">
              <div 
                className="bg-blue-600 h-2.5 rounded-full transition-all duration-500" 
                style={{ width: `${progressPercent}%` }}
              ></div>
            </div>
          </div>
        </div>

        {/* Scan Input Form */}
        <form onSubmit={handleManualScanSubmit} className="flex gap-2">
          <div className="relative flex-1">
            <Search className="w-5 h-5 text-slate-400 absolute start-3 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              placeholder="امسح الباركود بجهاز الليزر أو ادخل رمز الرف (مثل: 629100000003 أو A-02-R1-B04)..."
              value={scanInput}
              onChange={(e) => setScanInput(e.target.value)}
              className="w-full ps-10 pe-4 py-2.5 bg-slate-50 border border-slate-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-600 focus:bg-white transition-all font-mono"
            />
          </div>
          <button
            type="submit"
            className="px-5 py-2.5 bg-blue-600 hover:bg-blue-700 text-white text-sm font-bold rounded-lg transition-colors flex items-center gap-2"
          >
            <ScanLine className="w-4 h-4" />
            تحقق
          </button>
        </form>

        {/* Scan Feedback Message */}
        {scanMessage && (
          <div
            className={`mt-3 p-3 rounded-lg text-sm font-medium flex items-center gap-2 ${
              scanMessage.success
                ? 'bg-emerald-50 text-emerald-800 border border-emerald-200'
                : 'bg-rose-50 text-rose-800 border border-rose-200'
            }`}
          >
            {scanMessage.success ? (
              <CheckCircle2 className="w-5 h-5 text-emerald-600 shrink-0" />
            ) : (
              <AlertTriangle className="w-5 h-5 text-rose-600 shrink-0" />
            )}
            <span>{scanMessage.text}</span>
          </div>
        )}
      </div>

      {/* Picking Tasks Table by Shelf Location */}
      <div className="bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden">
        <div className="p-4 border-b border-slate-200 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Boxes className="w-5 h-5 text-slate-600" />
            <h3 className="font-bold text-slate-800 text-sm">
              قائمة فرز الأصناف ومسار المشي الأقصر (Dijkstra Optimized Walk Path)
            </h3>
          </div>
          <span className="text-xs bg-slate-100 text-slate-600 px-2.5 py-1 rounded-md font-medium">
            المستودع: {selectedStore?.name_ar}
          </span>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-right text-sm">
            <thead className="bg-slate-50 text-slate-500 font-semibold border-b border-slate-200 text-xs">
              <tr>
                <th className="py-3 px-4">رقم الطلب</th>
                <th className="py-3 px-4">موقع الرف والحاوية</th>
                <th className="py-3 px-4">اسم الصنف المطلوب</th>
                <th className="py-3 px-4">الباركود المسجل</th>
                <th className="py-3 px-4">الكمية</th>
                <th className="py-3 px-4">حالة التحقق</th>
                <th className="py-3 px-4 text-center">الإجراء</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {tasks.map((task) => {
                const isDone = task.is_verified;
                return (
                  <tr
                    key={task.id}
                    className={`hover:bg-slate-50/80 transition-colors ${
                      isDone ? 'bg-emerald-50/30' : ''
                    }`}
                  >
                    <td className="py-3 px-4 font-mono font-bold text-blue-600 text-xs">
                      {task.order_number}
                    </td>
                    <td className="py-3 px-4">
                      <span className="inline-flex items-center gap-1 font-mono font-bold px-2 py-0.5 rounded bg-amber-50 text-amber-800 border border-amber-200 text-xs">
                        <MapPin className="w-3 h-3 text-amber-600" />
                        {task.bin_location}
                      </span>
                    </td>
                    <td className="py-3 px-4 font-bold text-slate-800">
                      {task.product_name_ar}
                    </td>
                    <td className="py-3 px-4 font-mono text-xs text-slate-500">
                      {task.barcode}
                    </td>
                    <td className="py-3 px-4 font-bold">
                      {task.quantity_picked} / {task.quantity_required}
                    </td>
                    <td className="py-3 px-4">
                      {isDone ? (
                        <span className="inline-flex items-center gap-1 text-xs font-bold text-emerald-700 bg-emerald-100 px-2 py-0.5 rounded-full">
                          <CheckCircle2 className="w-3.5 h-3.5" />
                          تم التحقق والجمع
                        </span>
                      ) : (
                        <span className="inline-flex items-center gap-1 text-xs font-bold text-amber-700 bg-amber-100 px-2 py-0.5 rounded-full">
                          <Clock className="w-3.5 h-3.5" />
                          قيد الانتظار بالرف
                        </span>
                      )}
                    </td>
                    <td className="py-3 px-4 text-center">
                      {isDone ? (
                        <span className="text-xs text-slate-400 font-medium">جاهز للتعبئة</span>
                      ) : (
                        <button
                          onClick={() => handleSimulateScan(task)}
                          className="px-3 py-1 bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold rounded-lg transition-colors inline-flex items-center gap-1 shadow-sm"
                        >
                          <ScanLine className="w-3 h-3" />
                          مسح ومطابقة
                        </button>
                      )}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};
