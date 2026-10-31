import React, { useState } from 'react';
import { 
  TrendingUp, 
  DollarSign, 
  ShoppingBag, 
  Users, 
  Clock, 
  Zap, 
  ArrowUpRight, 
  ArrowDownRight, 
  Calendar, 
  PieChart as PieIcon,
  BarChart3,
  CheckCircle2,
  AlertCircle
} from 'lucide-react';
import { Order, Product } from '../types';

interface AnalyticsPageProps {
  orders: Order[];
  products: Product[];
}

export const AnalyticsPage: React.FC<AnalyticsPageProps> = ({ orders, products }) => {
  const [timeRange, setTimeRange] = useState<'today' | 'week' | 'month'>('today');

  // Core BI Metrics
  const totalGMV = orders.reduce((sum, o) => sum + o.total_amount, 0);
  const avgOrderValue = orders.length > 0 ? (totalGMV / orders.length).toFixed(2) : '0.00';
  const express15MinOrders = Math.round(orders.length * 0.72); // 72% are 15-min quick commerce

  // Hourly Order Volume Distribution
  const hourlyData = [
    { hour: '8:00 ص', orders: 18, peak: false },
    { hour: '10:00 ص', orders: 42, peak: false },
    { hour: '12:00 م', orders: 85, peak: true }, // Lunch rush
    { hour: '2:00 م', orders: 54, peak: false },
    { hour: '5:00 م', orders: 120, peak: true }, // Evening grocery rush
    { hour: '7:00 م', orders: 145, peak: true }, // Peak dinner
    { hour: '9:00 م', orders: 90, peak: false },
    { hour: '11:00 م', orders: 35, peak: false },
  ];

  // Category Revenue Share
  const categoryBreakdown = [
    { name: 'الخضروات والفواكه الطازجة', percent: 34, revenue: '14,280 ل.س', color: 'bg-emerald-500' },
    { name: 'الألبان والأجبان والبيض', percent: 26, revenue: '10,920 ل.س', color: 'bg-blue-500' },
    { name: 'اللحوم والدواجن المبردة', percent: 22, revenue: '9,240 ل.س', color: 'bg-rose-500' },
    { name: 'المؤن والزيوت والمعلبات', percent: 18, revenue: '7,560 ل.س', color: 'bg-amber-500' },
  ];

  // Fulfillment SLA Metrics
  const slaMetrics = {
    under15MinPercent: 94.2,
    between15And20MinPercent: 5.2,
    delayedPercent: 0.6,
    avgDeliveryMinutes: 12.8,
  };

  return (
    <div className="space-y-6">
      {/* Time Range Selector & Top Bar */}
      <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 bg-white p-4 rounded-2xl border border-slate-200 shadow-sm">
        <div>
          <h2 className="text-lg font-black text-slate-800 flex items-center gap-2">
            <BarChart3 className="w-5 h-5 text-blue-600" />
            لوحة ذكاء الأعمال والتحليلات المالية (BI Analytics)
          </h2>
          <p className="text-xs text-slate-500 mt-0.5">
            مؤشرات النمو، الإيرادات اللحظية، وتحليلات سرعة التوصيل 15 دقيقة
          </p>
        </div>

        <div className="flex items-center gap-2 bg-slate-100 p-1 rounded-xl">
          {[
            { id: 'today', label: 'اليوم' },
            { id: 'week', label: 'هذا الأسبوع' },
            { id: 'month', label: 'هذا الشهر' },
          ].map((tab) => (
            <button
              key={tab.id}
              onClick={() => setTimeRange(tab.id as 'today' | 'week' | 'month')}
              className={`px-3.5 py-1.5 rounded-lg text-xs font-bold transition-all ${
                timeRange === tab.id
                  ? 'bg-white text-blue-700 shadow-xs'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              {tab.label}
            </button>
          ))}
        </div>
      </div>

      {/* Top 4 KPI Metrics */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* GMV */}
        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm flex flex-col justify-between">
          <div className="flex items-center justify-between text-slate-500 text-xs font-bold mb-2">
            <span>إجمالي المبيعات (GMV)</span>
            <div className="w-8 h-8 rounded-lg bg-emerald-50 text-emerald-600 flex items-center justify-center">
              <DollarSign className="w-4 h-4" />
            </div>
          </div>
          <div>
            <div className="text-2xl font-black text-slate-800">
              {(totalGMV * 32.5).toFixed(2)} ل.س
            </div>
            <div className="flex items-center gap-1 text-xs text-emerald-600 font-bold mt-1">
              <ArrowUpRight className="w-3.5 h-3.5" />
              <span>+24.8% مقارنة بالأسبوع الماضي</span>
            </div>
          </div>
        </div>

        {/* Average Order Value (AOV) */}
        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm flex flex-col justify-between">
          <div className="flex items-center justify-between text-slate-500 text-xs font-bold mb-2">
            <span>متوسط قيمة السلة (AOV)</span>
            <div className="w-8 h-8 rounded-lg bg-blue-50 text-blue-600 flex items-center justify-center">
              <ShoppingBag className="w-4 h-4" />
            </div>
          </div>
          <div>
            <div className="text-2xl font-black text-slate-800">
              {avgOrderValue} ل.س
            </div>
            <div className="flex items-center gap-1 text-xs text-emerald-600 font-bold mt-1">
              <ArrowUpRight className="w-3.5 h-3.5" />
              <span>+8.4% بفضل باقات الطبخ الذكية</span>
            </div>
          </div>
        </div>

        {/* 15-Min Quick Commerce Orders */}
        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm flex flex-col justify-between">
          <div className="flex items-center justify-between text-slate-500 text-xs font-bold mb-2">
            <span>طلبات الديب ناو (15-Min)</span>
            <div className="w-8 h-8 rounded-lg bg-amber-50 text-amber-600 flex items-center justify-center">
              <Zap className="w-4 h-4 fill-amber-500 text-amber-500" />
            </div>
          </div>
          <div>
            <div className="text-2xl font-black text-slate-800">
              72% من إجمالي الطلبات
            </div>
            <div className="flex items-center gap-1 text-xs text-blue-600 font-bold mt-1">
              <span>{express15MinOrders} طلب فوري خلال 15 دقيقة</span>
            </div>
          </div>
        </div>

        {/* Fulfillment Speed */}
        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm flex flex-col justify-between">
          <div className="flex items-center justify-between text-slate-500 text-xs font-bold mb-2">
            <span>متوسط زمن التوصيل الكلي</span>
            <div className="w-8 h-8 rounded-lg bg-purple-50 text-purple-600 flex items-center justify-center">
              <Clock className="w-4 h-4" />
            </div>
          </div>
          <div>
            <div className="text-2xl font-black text-purple-700">
              {slaMetrics.avgDeliveryMinutes} دقيقة
            </div>
            <div className="flex items-center gap-1 text-xs text-emerald-600 font-bold mt-1">
              <CheckCircle2 className="w-3.5 h-3.5" />
              <span>94.2% تم تسليمها تحت 15 دقيقة</span>
            </div>
          </div>
        </div>
      </div>

      {/* Hourly Heatmap & Distribution Graph */}
      <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm space-y-4">
        <div className="flex items-center justify-between">
          <div>
            <h3 className="font-bold text-slate-800 text-sm">
              ساعات ذروة تدفق الطلبات على مدار اليوم (Hourly Order Distribution)
            </h3>
            <p className="text-xs text-slate-400 mt-0.5">
              توزيع الطلبات بالساعة لتنظيم طواقم الفرز والكوريير في المستودعات المظلمة
            </p>
          </div>
          <span className="text-xs bg-amber-50 text-amber-800 border border-amber-200 px-2.5 py-1 rounded-lg font-bold flex items-center gap-1">
            <Zap className="w-3 h-3 fill-amber-500 text-amber-500" />
            ساعة الذروة الكبرى: 7:00 مساءً
          </span>
        </div>

        {/* Visual Bar Columns */}
        <div className="pt-4 grid grid-cols-8 gap-2 items-end h-48 border-b border-slate-100 pb-2">
          {hourlyData.map((d, idx) => {
            const heightPercent = Math.round((d.orders / 150) * 100);
            return (
              <div key={idx} className="flex flex-col items-center h-full justify-end group">
                <span className="text-[10px] font-mono font-bold text-slate-600 mb-1 opacity-0 group-hover:opacity-100 transition-opacity">
                  {d.orders}
                </span>
                <div
                  className={`w-full rounded-t-lg transition-all duration-500 ${
                    d.peak
                      ? 'bg-gradient-to-t from-blue-700 to-blue-500 shadow-md shadow-blue-500/20'
                      : 'bg-slate-200 group-hover:bg-blue-300'
                  }`}
                  style={{ height: `${heightPercent}%` }}
                ></div>
                <span className="text-[11px] font-semibold text-slate-500 mt-2 truncate max-w-full">
                  {d.hour}
                </span>
              </div>
            );
          })}
        </div>
      </div>

      {/* Two Column Grid: Category Revenue Share & SLA Breakdown */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Category Share */}
        <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm space-y-4">
          <div className="flex items-center justify-between border-b pb-3 border-slate-100">
            <h3 className="font-bold text-slate-800 text-sm flex items-center gap-2">
              <PieIcon className="w-4 h-4 text-blue-600" />
              حصة المبيعات حسب أقسام الهايبرماركت
            </h3>
            <span className="text-xs text-slate-400">إجمالي 4 أقسام رئيسية</span>
          </div>

          <div className="space-y-3">
            {categoryBreakdown.map((cat, idx) => (
              <div key={idx} className="space-y-1.5">
                <div className="flex justify-between text-xs font-bold text-slate-700">
                  <span>{cat.name}</span>
                  <span className="font-mono text-slate-900">{cat.percent}% ({cat.revenue})</span>
                </div>
                <div className="w-full bg-slate-100 rounded-full h-2.5 overflow-hidden">
                  <div
                    className={`${cat.color} h-2.5 rounded-full transition-all duration-500`}
                    style={{ width: `${cat.percent}%` }}
                  ></div>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* SLA Breakdown */}
        <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm space-y-4">
          <div className="flex items-center justify-between border-b pb-3 border-slate-100">
            <h3 className="font-bold text-slate-800 text-sm flex items-center gap-2">
              <Clock className="w-4 h-4 text-purple-600" />
              مؤشرات دقة ومواعيد التوصيل (Delivery SLA)
            </h3>
            <span className="text-xs bg-emerald-50 text-emerald-700 px-2 py-0.5 rounded font-bold">
              ممتاز (99.4%)
            </span>
          </div>

          <div className="grid grid-cols-3 gap-3 text-center">
            <div className="p-3 bg-emerald-50 border border-emerald-200 rounded-xl">
              <div className="text-xl font-black text-emerald-800">{slaMetrics.under15MinPercent}%</div>
              <div className="text-[11px] text-emerald-700 font-semibold mt-0.5">أقل من 15 دقيقة</div>
            </div>
            <div className="p-3 bg-blue-50 border border-blue-200 rounded-xl">
              <div className="text-xl font-black text-blue-800">{slaMetrics.between15And20MinPercent}%</div>
              <div className="text-[11px] text-blue-700 font-semibold mt-0.5">من 15 إلى 20 دقيقة</div>
            </div>
            <div className="p-3 bg-rose-50 border border-rose-200 rounded-xl">
              <div className="text-xl font-black text-rose-800">{slaMetrics.delayedPercent}%</div>
              <div className="text-[11px] text-rose-700 font-semibold mt-0.5">تجاوز 20 دقيقة (متأخر)</div>
            </div>
          </div>

          <div className="p-3 bg-slate-50 rounded-xl text-xs text-slate-600 leading-relaxed">
            💡 <strong>تحليل الخوارزمية:</strong> حققت محطات المستودعات المظلمة في وسط دبي والمارينا التزاماً بنسبة 99.4% في زمن الجمع والتغليف (متوسط 92 ثانية للطلب الواحد).
          </div>
        </div>
      </div>
    </div>
  );
};
