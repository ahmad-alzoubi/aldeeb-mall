import React, { useState } from 'react';
import { 
  TrendingUp, 
  BrainCircuit, 
  Sun, 
  Calendar, 
  CheckCircle2, 
  Sparkles, 
  ShoppingBag, 
  ArrowUpRight, 
  AlertCircle,
  PackagePlus,
  RefreshCw
} from 'lucide-react';

interface ForecastItem {
  id: string;
  categoryNameAr: string;
  expectedDemandGrowth: number;
  reason: string;
  suggestedRestockQty: number;
  unit: string;
  supplierName: string;
  confidenceScore: number;
  status: 'recommended' | 'po_generated';
}

export const ForecastingPage: React.FC = () => {
  const [forecasts, setForecasts] = useState<ForecastItem[]>([
    {
      id: 'fc-1',
      categoryNameAr: 'الآيس كريم والمشروبات والعصائر الباردة',
      expectedDemandGrowth: 42,
      reason: 'موجة حرارة متوقعة (+38°C) خلال عطلة نهاية الأسبوع وفق بيانات الأرصاد',
      suggestedRestockQty: 650,
      unit: 'عبوة',
      supplierName: 'شركة باسكن وندى للمرطبات',
      confidenceScore: 98.2,
      status: 'recommended',
    },
    {
      id: 'fc-2',
      categoryNameAr: 'اللحوم والدواجن الطازجة ومستلزمات الشواء',
      expectedDemandGrowth: 35,
      reason: 'ذروة وجبات الغداء العائلية ليومي الجمعة والسبت مع إجازة المدارس',
      suggestedRestockQty: 280,
      unit: 'كغم',
      supplierName: 'مزارع اليوم والفقيه للدواجن',
      confidenceScore: 95.8,
      status: 'recommended',
    },
    {
      id: 'fc-3',
      categoryNameAr: 'الخضار والفواكه الطازجة والعضوية',
      expectedDemandGrowth: 28,
      reason: 'يوم السوق الأسبوعي في الديب مول وتزامن موعد حملة مجلة العروض',
      suggestedRestockQty: 540,
      unit: 'كغم',
      supplierName: 'شركة مزارع نادك العضوية',
      confidenceScore: 94.0,
      status: 'recommended',
    },
    {
      id: 'fc-4',
      categoryNameAr: 'منتجات الألبان والأجبان اليومية',
      expectedDemandGrowth: 16,
      reason: 'معدل سحب يومي منتظم مع زيادة بنسبة 16% لاشتراكات المؤن الدورية',
      suggestedRestockQty: 420,
      unit: 'حبة',
      supplierName: 'شركة المراعي للألبان',
      confidenceScore: 97.4,
      status: 'recommended',
    },
  ]);

  const [toastMessage, setToastMessage] = useState<string | null>(null);

  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(null), 3500);
  };

  const handleGeneratePO = (id: string, item: ForecastItem) => {
    setForecasts((prev) =>
      prev.map((f) => (f.id === id ? { ...f, status: 'po_generated' } : f))
    );
    showToast(`✓ تم توليد وإرسال أمر شراء ذكي تلقائي لـ "${item.supplierName}" بكمية ${item.suggestedRestockQty} ${item.unit}!`);
  };

  const handleGenerateAllPOs = () => {
    setForecasts((prev) =>
      prev.map((f) => ({ ...f, status: 'po_generated' }))
    );
    showToast('🚀 تم توليد كافة أوامر الشراء التنبؤية المعتمدة بالذكاء الاصطناعي بنجاح وتوجيهها للموردين!');
  };

  return (
    <div className="space-y-6">
      {/* Toast */}
      {toastMessage && (
        <div className="bg-emerald-600 text-white px-5 py-3 rounded-xl shadow-lg flex items-center gap-3 animate-fade-in text-sm font-medium">
          <CheckCircle2 className="w-5 h-5 flex-shrink-0" />
          <span>{toastMessage}</span>
        </div>
      )}

      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 bg-white p-6 rounded-2xl border border-gray-100 shadow-sm">
        <div>
          <div className="flex items-center gap-2">
            <span className="p-2 bg-purple-50 text-purple-600 rounded-xl">
              <BrainCircuit className="w-6 h-6" />
            </span>
            <h1 className="text-2xl font-bold text-gray-900">التنبؤ الذكي بالطلب وإعادة التموين (AI Demand Forecasting)</h1>
          </div>
          <p className="text-gray-500 mt-1 text-sm">
            نماذج تعلم الآلة للتنبؤ الدقيق بحجم المبيعات المستقبلي بناءً على الطقس، العطلات، وسرعة دوران السلع
          </p>
        </div>
        <div className="flex items-center gap-3">
          <div className="flex items-center gap-2 bg-purple-50 text-purple-700 px-3.5 py-1.5 rounded-xl border border-purple-200 text-xs font-semibold">
            <Sparkles className="w-4 h-4 text-purple-600" />
            <span>دقة التنبؤ: 96.4%</span>
          </div>
          <button
            onClick={handleGenerateAllPOs}
            className="flex items-center gap-2 bg-purple-600 hover:bg-purple-700 text-white px-4 py-2 rounded-xl text-xs font-bold transition-all shadow-sm"
          >
            <PackagePlus className="w-4 h-4" />
            <span>توليد جميع أوامر الشراء المقترحة</span>
          </button>
        </div>
      </div>

      {/* External Macro Signal Cards (Weather, Events, Trends) */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="bg-white p-5 rounded-2xl border border-gray-100 shadow-sm flex items-center gap-4">
          <div className="p-3 bg-amber-50 text-amber-600 rounded-xl">
            <Sun className="w-6 h-6" />
          </div>
          <div>
            <div className="text-xs text-gray-400">بيانات الطقس المستوردة تلقائياً</div>
            <div className="text-lg font-bold text-gray-900">حرارة مرتفعة +38°C مشمس</div>
            <div className="text-xs text-emerald-600 font-semibold mt-0.5">تأثير محفز لمنتجات الآيس كريم والمرطبات</div>
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-gray-100 shadow-sm flex items-center gap-4">
          <div className="p-3 bg-blue-50 text-blue-600 rounded-xl">
            <Calendar className="w-6 h-6" />
          </div>
          <div>
            <div className="text-xs text-gray-400">عطلة نهاية الأسبوع</div>
            <div className="text-lg font-bold text-gray-900">جمعة وسبت (تسوق عائلي)</div>
            <div className="text-xs text-blue-600 font-semibold mt-0.5">+45% حجم السلة المتوسط (AOV)</div>
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-gray-100 shadow-sm flex items-center gap-4">
          <div className="p-3 bg-emerald-50 text-emerald-600 rounded-xl">
            <TrendingUp className="w-6 h-6" />
          </div>
          <div>
            <div className="text-xs text-gray-400">سرعة الفولفيلمنت اللوجستي</div>
            <div className="text-lg font-bold text-gray-900">100% جاهزية التخزين</div>
            <div className="text-xs text-emerald-600 font-semibold mt-0.5">سعة الشاحنات المبردة متوفرة بالكامل</div>
          </div>
        </div>
      </div>

      {/* Forecast Items Table */}
      <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-6">
        <div className="flex items-center justify-between pb-4 mb-4 border-b border-gray-100">
          <div>
            <h2 className="text-base font-bold text-gray-900">توصيات إعادة التموين الذكية (Predictive Restock Signals)</h2>
            <p className="text-xs text-gray-500">تم حساب الكميات المقترحة لتفادي نفاد المخزون مع تقليل تكاليف التخزين الفائض</p>
          </div>
        </div>

        <div className="space-y-4">
          {forecasts.map((item) => (
            <div 
              key={item.id}
              className="p-5 rounded-2xl border border-gray-200/80 bg-gray-50/40 hover:bg-white hover:shadow-md transition-all flex flex-col lg:flex-row lg:items-center justify-between gap-4"
            >
              <div className="space-y-2 max-w-xl">
                <div className="flex items-center gap-2.5">
                  <span className="font-bold text-gray-900 text-sm">{item.categoryNameAr}</span>
                  <span className="flex items-center gap-1 text-xs font-black text-rose-600 bg-rose-50 px-2 py-0.5 rounded-lg border border-rose-200">
                    <ArrowUpRight className="w-3.5 h-3.5" />
                    +{item.expectedDemandGrowth}% زيادة متوقعة
                  </span>
                </div>
                <div className="text-xs text-gray-600 leading-relaxed">
                  💡 سبب التوقع: {item.reason}
                </div>
                <div className="flex items-center gap-4 text-xs text-gray-400 pt-1">
                  <span>المورد المعتمد: <strong className="text-gray-700">{item.supplierName}</strong></span>
                  <span>•</span>
                  <span>معامل الثقة الرياضي: <strong className="text-purple-700 font-mono">{item.confidenceScore}%</strong></span>
                </div>
              </div>

              <div className="flex items-center justify-between lg:justify-end gap-5 pt-3 lg:pt-0 border-t lg:border-t-0 border-gray-100">
                <div className="text-left">
                  <span className="text-xs text-gray-400 block">الكمية المقترحة</span>
                  <span className="text-xl font-black text-gray-900 font-mono">
                    {item.suggestedRestockQty} <span className="text-xs font-normal text-gray-500">{item.unit}</span>
                  </span>
                </div>

                <div>
                  {item.status === 'recommended' ? (
                    <button
                      onClick={() => handleGeneratePO(item.id, item)}
                      className="px-4 py-2 bg-purple-600 hover:bg-purple-700 text-white rounded-xl text-xs font-bold transition-all shadow-sm flex items-center gap-1.5"
                    >
                      <PackagePlus className="w-4 h-4" />
                      <span>إصدار أمر الشراء (PO)</span>
                    </button>
                  ) : (
                    <span className="flex items-center gap-1 text-xs font-bold text-emerald-700 bg-emerald-50 border border-emerald-200 px-3 py-1.5 rounded-xl">
                      <CheckCircle2 className="w-4 h-4 text-emerald-600" />
                      <span>تم توجيه أمر الشراء للمورد ✓</span>
                    </span>
                  )}
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};
