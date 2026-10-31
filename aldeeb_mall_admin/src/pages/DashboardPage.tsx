import React from 'react';
import { 
  TrendingUp, 
  ShoppingBag, 
  AlertTriangle, 
  Award, 
  ArrowUpRight,
  Clock, 
  CheckCircle2,
  Package
} from 'lucide-react';
import { Order, Product } from '../types';

interface DashboardPageProps {
  orders: Order[];
  products: Product[];
  setActiveTab: (tab: string) => void;
  onUpdateOrderStatus: (orderId: string, status: Order['status']) => void;
}

export const DashboardPage: React.FC<DashboardPageProps> = ({
  orders,
  products,
  setActiveTab,
  onUpdateOrderStatus,
}) => {
  // Calculations
  const totalRevenue = orders.reduce((sum, o) => sum + o.total_amount, 0);
  const pendingOrders = orders.filter((o) => o.status === 'pending' || o.status === 'packing');
  const lowStockProducts = products.filter((p) => p.stock_quantity < 25);
  const totalPointsRedeemed = orders.reduce((sum, o) => sum + o.loyalty_discount, 0);

  return (
    <div className="space-y-8">
      {/* 1. Top KPI Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {/* Revenue */}
        <div className="bg-white p-6 rounded-2xl border border-slate-200/80 shadow-sm hover:shadow-md transition-shadow">
          <div className="flex items-center justify-between mb-4">
            <span className="text-xs font-bold text-slate-500">إجمالي مبيعات اليوم</span>
            <div className="p-2.5 bg-blue-50 text-blue-600 rounded-xl">
              <TrendingUp className="w-5 h-5" />
            </div>
          </div>
          <div className="flex items-baseline justify-between">
            <h3 className="text-2xl font-extrabold text-slate-900">{totalRevenue.toFixed(2)} ل.س</h3>
            <span className="text-xs font-bold text-emerald-600 flex items-center">
              +18.4%
              <ArrowUpRight className="w-3.5 h-3.5" />
            </span>
          </div>
          <p className="text-xs text-slate-400 mt-2">مقارنة بأمس في نفس التوقيت</p>
        </div>

        {/* Active Orders */}
        <div className="bg-white p-6 rounded-2xl border border-slate-200/80 shadow-sm hover:shadow-md transition-shadow">
          <div className="flex items-center justify-between mb-4">
            <span className="text-xs font-bold text-slate-500">طلبات نشطة قيد التجهيز</span>
            <div className="p-2.5 bg-amber-50 text-amber-600 rounded-xl">
              <ShoppingBag className="w-5 h-5" />
            </div>
          </div>
          <div className="flex items-baseline justify-between">
            <h3 className="text-2xl font-extrabold text-slate-900">{pendingOrders.length} طلبات</h3>
            <button
              onClick={() => setActiveTab('orders')}
              className="text-xs font-bold text-blue-600 hover:underline"
            >
              عرض الكل
            </button>
          </div>
          <p className="text-xs text-slate-400 mt-2">متوسط وقت التجهيز: 12 دقيقة</p>
        </div>

        {/* Low Stock Warnings */}
        <div className="bg-white p-6 rounded-2xl border border-slate-200/80 shadow-sm hover:shadow-md transition-shadow">
          <div className="flex items-center justify-between mb-4">
            <span className="text-xs font-bold text-slate-500">تنبيهات انخفاض المخزون</span>
            <div className="p-2.5 bg-rose-50 text-rose-600 rounded-xl">
              <AlertTriangle className="w-5 h-5" />
            </div>
          </div>
          <div className="flex items-baseline justify-between">
            <h3 className="text-2xl font-extrabold text-rose-600">{lowStockProducts.length} أصناف</h3>
            <button
              onClick={() => setActiveTab('products')}
              className="text-xs font-bold text-rose-600 hover:underline"
            >
              مراجعة
            </button>
          </div>
          <p className="text-xs text-slate-400 mt-2">أصناف تحتاج إعادة طلب وتوريد</p>
        </div>

        {/* Loyalty Discounts */}
        <div className="bg-white p-6 rounded-2xl border border-slate-200/80 shadow-sm hover:shadow-md transition-shadow">
          <div className="flex items-center justify-between mb-4">
            <span className="text-xs font-bold text-slate-500">خصومات نقاط الولاء</span>
            <div className="p-2.5 bg-emerald-50 text-emerald-600 rounded-xl">
              <Award className="w-5 h-5" />
            </div>
          </div>
          <div className="flex items-baseline justify-between">
            <h3 className="text-2xl font-extrabold text-slate-900">{totalPointsRedeemed.toFixed(2)} ل.س</h3>
            <span className="text-xs font-bold text-emerald-600">نادي الديب</span>
          </div>
          <p className="text-xs text-slate-400 mt-2">استبدال فوري للنقاط في السلة</p>
        </div>
      </div>

      {/* 2. Live Orders Feed & Low Stock Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Live Orders Stream (2 cols) */}
        <div className="lg:col-span-2 bg-white rounded-2xl border border-slate-200/80 p-6 shadow-sm">
          <div className="flex items-center justify-between mb-6">
            <div>
              <h3 className="text-base font-extrabold text-slate-900">غرفة العمليات • تدفق الطلبات الفوري</h3>
              <p className="text-xs text-slate-400">الطلبات الواردة من تطبيق الهاتف وموقع المتجر</p>
            </div>
            <button
              onClick={() => setActiveTab('orders')}
              className="text-xs font-bold text-blue-600 hover:text-blue-800 transition-colors"
            >
              فتح شاشة الفرز الكاملة ←
            </button>
          </div>

          <div className="space-y-4">
            {orders.map((order) => {
              const isPending = order.status === 'pending';
              const isPacking = order.status === 'packing';
              const isDelivering = order.status === 'out_for_delivery';

              return (
                <div
                  key={order.id}
                  className="p-4 rounded-xl border border-slate-100 hover:border-slate-200 bg-slate-50/50 hover:bg-white transition-all flex items-center justify-between"
                >
                  <div className="flex items-center gap-4">
                    <div className="w-10 h-10 rounded-xl bg-blue-100/70 text-blue-700 flex items-center justify-center font-extrabold text-xs">
                      #{order.order_number.split('-')[1] || order.order_number}
                    </div>
                    <div>
                      <div className="flex items-center gap-2">
                        <p className="text-sm font-bold text-slate-800">{order.customer_name}</p>
                        <span className="text-xs text-slate-400">• {order.created_at}</span>
                      </div>
                      <p className="text-xs text-slate-500 mt-0.5">
                        {order.items.length} أصناف • {order.delivery_slot}
                      </p>
                    </div>
                  </div>

                  <div className="flex items-center gap-4">
                    <div className="text-left">
                      <p className="text-sm font-extrabold text-blue-900">{order.total_amount.toFixed(2)} ل.س</p>
                      <p className="text-[11px] text-slate-400">{order.payment_method}</p>
                    </div>

                    {isPending && (
                      <button
                        onClick={() => onUpdateOrderStatus(order.id, 'packing')}
                        className="px-3 py-1.5 bg-blue-600 hover:bg-blue-700 text-white rounded-lg text-xs font-bold transition-colors shadow-sm"
                      >
                        بدء التجهيز
                      </button>
                    )}
                    {isPacking && (
                      <button
                        onClick={() => onUpdateOrderStatus(order.id, 'out_for_delivery')}
                        className="px-3 py-1.5 bg-amber-500 hover:bg-amber-600 text-white rounded-lg text-xs font-bold transition-colors shadow-sm"
                      >
                        تسليم للمندوب
                      </button>
                    )}
                    {isDelivering && (
                      <button
                        onClick={() => onUpdateOrderStatus(order.id, 'delivered')}
                        className="px-3 py-1.5 bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg text-xs font-bold transition-colors shadow-sm"
                      >
                        تأكيد التسليم
                      </button>
                    )}
                    {order.status === 'delivered' && (
                      <span className="px-3 py-1.5 bg-emerald-100 text-emerald-800 rounded-lg text-xs font-bold flex items-center gap-1">
                        <CheckCircle2 className="w-3.5 h-3.5" />
                        تم بنجاح
                      </span>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {/* Low Stock Alerts & Inventory Health (1 col) */}
        <div className="bg-white rounded-2xl border border-slate-200/80 p-6 shadow-sm flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-base font-extrabold text-slate-900">أصناف قاربت على النفاد</h3>
              <span className="text-xs bg-rose-100 text-rose-700 font-extrabold px-2 py-0.5 rounded-full">
                تحتاج طلب
              </span>
            </div>
            <p className="text-xs text-slate-400 mb-4">تحديثات المستودع التلقائية بناءً على المبيعات</p>

            <div className="space-y-3">
              {lowStockProducts.map((p) => (
                <div key={p.id} className="p-3 bg-rose-50/50 rounded-xl border border-rose-100 flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <img src={p.images[0]} alt={p.name_ar} className="w-10 h-10 object-cover rounded-lg" />
                    <div>
                      <p className="text-xs font-bold text-slate-800 line-clamp-1">{p.name_ar}</p>
                      <p className="text-[11px] text-rose-600 font-bold">المتبقي: {p.stock_quantity} {p.unit}</p>
                    </div>
                  </div>
                  <button
                    onClick={() => setActiveTab('products')}
                    className="text-xs font-bold text-blue-600 hover:underline px-2 py-1 bg-white rounded-lg border border-slate-200"
                  >
                    تعديل
                  </button>
                </div>
              ))}
            </div>
          </div>

          <div className="mt-6 pt-4 border-t border-slate-100">
            <button
              onClick={() => setActiveTab('products')}
              className="w-full py-2.5 bg-slate-900 hover:bg-slate-800 text-white rounded-xl text-xs font-bold transition-colors flex items-center justify-center gap-2"
            >
              <Package className="w-4 h-4" />
              إدارة كافة الأصناف والمستودع
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
