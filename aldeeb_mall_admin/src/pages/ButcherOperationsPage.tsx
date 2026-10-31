import React, { useState } from 'react';
import { 
  Beef, 
  Scissors, 
  Scale, 
  ThermometerSnowflake, 
  CheckCircle2, 
  Clock, 
  Printer, 
  ShieldCheck, 
  Search, 
  Utensils, 
  Layers,
  Sparkles,
  Droplets,
  Package
} from 'lucide-react';

interface ButcherOrder {
  id: string;
  orderNumber: string;
  customerName: string;
  meatType: string;
  cutStyle: string;
  fatRatio: string;
  packaging: string;
  carcassPortion: string;
  targetWeightKg: number;
  finalWeightKg?: number;
  includesOffal: boolean;
  chefSpiceRub: boolean;
  status: 'cutting' | 'vacuum_packaging' | 'ready_for_dispatch';
  slaughterhouseBatch: string;
}

export const ButcherOperationsPage: React.FC = () => {
  const [orders, setOrders] = useState<ButcherOrder[]>([
    {
      id: 'bo-1',
      orderNumber: '#ORD-88219',
      customerName: 'سعود بن فهد القحطاني',
      meatType: 'خروف نعيمي بلدي (جذع فاخر)',
      cutStyle: 'تفصيل ثلاجة (قطع متوسطة)',
      fatRatio: 'قليل الدسم 10%',
      packaging: 'تغليف سحب هواء مفرغ 1 كجم (Vacuum)',
      carcassPortion: 'ذبيحة كاملة',
      targetWeightKg: 20.5,
      finalWeightKg: 20.8,
      includesOffal: true,
      chefSpiceRub: false,
      status: 'cutting',
      slaughterhouseBatch: 'MEWA-RIYADH-0415-A',
    },
    {
      id: 'bo-2',
      orderNumber: '#ORD-88230',
      customerName: 'منيرة عبدالرحمن الشمري',
      meatType: 'تيس بلدي عارضي لباني',
      cutStyle: 'تفصيل كبسة ومفطح (قطع ضيافة كبيرة)',
      fatRatio: 'هبر صافي 0%',
      packaging: 'أطباق لحام حراري مبردة',
      carcassPortion: 'نصف ذبيحة',
      targetWeightKg: 6.8,
      finalWeightKg: 6.9,
      includesOffal: false,
      chefSpiceRub: true,
      status: 'vacuum_packaging',
      slaughterhouseBatch: 'MEWA-RIYADH-0422-B',
    },
    {
      id: 'bo-3',
      orderNumber: '#ORD-88245',
      customerName: 'فهد المطيري',
      meatType: 'ستيك ريب آي واغيو ياباني A5 معتق 28 يوماً',
      cutStyle: 'ستيك سمك 1.5 إنش للشواء',
      fatRatio: 'ماربلينج BMS 11+',
      packaging: 'تغليف سحب هواء مفرغ فردي',
      carcassPortion: 'قطع ستيك (1.4 كجم)',
      targetWeightKg: 1.4,
      finalWeightKg: 1.42,
      includesOffal: false,
      chefSpiceRub: false,
      status: 'ready_for_dispatch',
      slaughterhouseBatch: 'MIYAZAKI-DRYAGED-28D',
    },
  ]);

  const [searchQuery, setSearchQuery] = useState('');

  // Move status forward
  const handleAdvanceStatus = (id: string) => {
    setOrders((prev) =>
      prev.map((o) => {
        if (o.id !== id) return o;
        if (o.status === 'cutting') return { ...o, status: 'vacuum_packaging' };
        if (o.status === 'vacuum_packaging') return { ...o, status: 'ready_for_dispatch' };
        return o;
      })
    );
  };

  return (
    <div className="p-6 space-y-6 max-w-7xl mx-auto text-slate-800" dir="rtl">
      {/* Header Banner */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 bg-gradient-to-l from-rose-950 via-rose-900 to-red-950 p-6 rounded-2xl text-white shadow-xl">
        <div className="flex items-center gap-4">
          <div className="p-3 bg-white/10 backdrop-blur-md rounded-xl border border-white/20">
            <Beef className="w-8 h-8 text-rose-300" />
          </div>
          <div>
            <div className="flex items-center gap-3">
              <h1 className="text-2xl font-black tracking-tight">مسلخ وملحمة الديب وغرف التعتيق الذكية</h1>
              <span className="px-2.5 py-0.5 rounded-full text-xs font-bold bg-rose-400/20 text-rose-300 border border-rose-400/30">
                MEWA Certified #8842
              </span>
            </div>
            <p className="text-rose-200 text-sm mt-1">
              إدارة خطوط تقطيع وتفصيل الذبائح، التغليف المفرغ (Vacuum)، ومراقبة غرف التعتيق الجاف للواغيو بحساسات IoT
            </p>
          </div>
        </div>

        <div className="flex items-center gap-2">
          <div className="bg-rose-950/60 px-4 py-2.5 rounded-xl border border-rose-700/50 flex items-center gap-3">
            <ShieldCheck className="w-5 h-5 text-rose-400" />
            <div className="text-xs">
              <p className="font-bold text-white">إشراف بيطري معتمد</p>
              <p className="text-rose-300">مسلخ الرياض الآلي النموذجي (100% حلال)</p>
            </div>
          </div>
        </div>
      </div>

      {/* KPI Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-xs flex items-center justify-between">
          <div>
            <p className="text-xs font-semibold text-slate-500">الذبائح الواردة اليوم</p>
            <p className="text-2xl font-black text-slate-900 mt-1">38 ذبيحة</p>
            <p className="text-xs text-rose-600 font-medium mt-1">24 نعيمي • 8 عوارض • 6 عجول</p>
          </div>
          <div className="p-3 bg-rose-50 rounded-xl">
            <Beef className="w-6 h-6 text-rose-600" />
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-xs flex items-center justify-between">
          <div>
            <p className="text-xs font-semibold text-slate-500">طلبات التقطيع والتفصيل الجارية</p>
            <p className="text-2xl font-black text-amber-600 mt-1">
              {orders.filter((o) => o.status !== 'ready_for_dispatch').length} طلبات
            </p>
            <p className="text-xs text-slate-500 font-medium mt-1">على طاولات القصابين المحترفين</p>
          </div>
          <div className="p-3 bg-amber-50 rounded-xl">
            <Scissors className="w-6 h-6 text-amber-600" />
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-xs flex items-center justify-between">
          <div>
            <p className="text-xs font-semibold text-slate-500">كفاءة العائد الصافي (Yield)</p>
            <p className="text-2xl font-black text-emerald-600 mt-1">68.4%</p>
            <p className="text-xs text-emerald-600 font-medium mt-1">صافي لحم ممتاز بعد التشذيب</p>
          </div>
          <div className="p-3 bg-emerald-50 rounded-xl">
            <Scale className="w-6 h-6 text-emerald-600" />
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-xs flex items-center justify-between">
          <div>
            <p className="text-xs font-semibold text-slate-500">غرفة التعتيق الجاف (IoT Wagyu)</p>
            <p className="text-2xl font-black text-blue-600 mt-1">1.4°C • 82%</p>
            <p className="text-xs text-blue-600 font-medium mt-1">تعقيم UV نشط • معتق 28 يوماً</p>
          </div>
          <div className="p-3 bg-blue-50 rounded-xl">
            <ThermometerSnowflake className="w-6 h-6 text-blue-600" />
          </div>
        </div>
      </div>

      {/* Butcher Orders Queue Table */}
      <div className="bg-white rounded-2xl border border-slate-200 shadow-xs overflow-hidden">
        <div className="p-4 border-b border-slate-100 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Utensils className="w-5 h-5 text-rose-700" />
            <h3 className="font-bold text-sm text-slate-900">طابور التجهيز والتفصيل والتغليف المفرغ للملحمة</h3>
          </div>
          <span className="text-xs text-slate-500 font-mono">طاولات التقطيع المعقمة #T1 - #T4</span>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-right text-xs">
            <thead className="bg-slate-50 text-slate-600 font-bold border-b border-slate-200">
              <tr>
                <th className="p-3.5">الطلب والعميل</th>
                <th className="p-3.5">نوع اللحم والذبيحة</th>
                <th className="p-3.5">طريقة التقطيع ونسبة الشحم</th>
                <th className="p-3.5">نوع التغليف والإضافات</th>
                <th className="p-3.5">الوزن المستهدف والنهائي</th>
                <th className="p-3.5">الحالة التنفيذية</th>
                <th className="p-3.5 text-center">الإجراءات</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {orders.map((order) => (
                <tr key={order.id} className="hover:bg-slate-50/80 transition-colors">
                  <td className="p-3.5">
                    <div className="font-bold text-slate-900">{order.customerName}</div>
                    <div className="text-[11px] text-slate-500 font-mono">{order.orderNumber}</div>
                    <div className="text-[10px] text-slate-400 font-mono mt-0.5">تشغيلة: {order.slaughterhouseBatch}</div>
                  </td>
                  <td className="p-3.5">
                    <div className="font-bold text-rose-900">{order.meatType}</div>
                    <span className="inline-block px-2 py-0.5 bg-rose-50 text-rose-700 rounded text-[10px] font-bold mt-1">
                      {order.carcassPortion}
                    </span>
                  </td>
                  <td className="p-3.5">
                    <div className="font-semibold text-slate-800">{order.cutStyle}</div>
                    <div className="text-[11px] text-slate-500">{order.fatRatio}</div>
                  </td>
                  <td className="p-3.5">
                    <div className="font-medium text-slate-700">{order.packaging}</div>
                    <div className="flex gap-1.5 mt-1">
                      {order.includesOffal && (
                        <span className="px-1.5 py-0.5 bg-amber-50 text-amber-700 rounded text-[9px] font-bold">
                          + رأس وكراعين
                        </span>
                      )}
                      {order.chefSpiceRub && (
                        <span className="px-1.5 py-0.5 bg-emerald-50 text-emerald-700 rounded text-[9px] font-bold">
                          + تتبيلة شواء نجدية
                        </span>
                      )}
                    </div>
                  </td>
                  <td className="p-3.5">
                    <div className="font-bold font-mono text-slate-900">{order.finalWeightKg} كجم</div>
                    <div className="text-[10px] text-slate-400 font-mono">الهدف: {order.targetWeightKg} كجم</div>
                  </td>
                  <td className="p-3.5">
                    {order.status === 'cutting' && (
                      <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-amber-50 text-amber-700 border border-amber-200 font-bold text-[11px]">
                        <Scissors className="w-3 h-3" /> قيد التقطيع والتفصيل
                      </span>
                    )}
                    {order.status === 'vacuum_packaging' && (
                      <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-blue-50 text-blue-700 border border-blue-200 font-bold text-[11px]">
                        <Package className="w-3 h-3" /> سحب هواء وتغليف
                      </span>
                    )}
                    {order.status === 'ready_for_dispatch' && (
                      <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-emerald-50 text-emerald-700 border border-emerald-200 font-bold text-[11px]">
                        <CheckCircle2 className="w-3 h-3" /> جاهز للتفويج المبرد
                      </span>
                    )}
                  </td>
                  <td className="p-3.5 text-center">
                    <div className="flex items-center justify-center gap-1.5">
                      {order.status !== 'ready_for_dispatch' && (
                        <button
                          onClick={() => handleAdvanceStatus(order.id)}
                          className="px-2.5 py-1 bg-rose-700 hover:bg-rose-800 text-white rounded-lg font-bold text-[11px] transition-colors"
                        >
                          {order.status === 'cutting' ? 'إلى التغليف' : 'اعتماد وجاهز'}
                        </button>
                      )}

                      <button
                        onClick={() => alert(`تمت طباعة ملصق الذبح الحلال MEWA والباركود للطلب ${order.orderNumber}`)}
                        className="p-1.5 text-slate-600 hover:bg-slate-100 rounded-lg transition-colors"
                        title="طباعة ملصق شهادة الذبح الحلال والوزن"
                      >
                        <Printer className="w-4 h-4" />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};
