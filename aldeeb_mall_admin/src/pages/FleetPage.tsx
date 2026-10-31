import React, { useState } from 'react';
import { 
  Bike, 
  Truck, 
  MapPin, 
  BatteryCharging, 
  Phone, 
  Star, 
  Navigation, 
  Radio, 
  Send,
  CheckCircle2,
  Clock
} from 'lucide-react';
import { Courier, Order } from '../types';

interface FleetPageProps {
  couriers: Courier[];
  orders: Order[];
  onAssignOrderToCourier?: (orderId: string, courierId: string) => void;
}

export const FleetPage: React.FC<FleetPageProps> = ({
  couriers: initialCouriers,
  orders,
}) => {
  const [couriers, setCouriers] = useState<Courier[]>(initialCouriers);
  const [filter, setFilter] = useState<'all' | 'on_delivery' | 'idle'>('all');
  const [assignModalCourier, setAssignModalCourier] = useState<Courier | null>(null);

  const pendingOrders = orders.filter((o) => o.status === 'packing' || o.status === 'pending');

  const filteredCouriers = couriers.filter((c) => {
    if (filter === 'all') return true;
    return c.status === filter;
  });

  const getVehicleIcon = (type: Courier['vehicle_type']) => {
    switch (type) {
      case 'van':
        return <Truck className="w-5 h-5 text-indigo-600" />;
      case 'electric_scooter':
        return <Navigation className="w-5 h-5 text-emerald-600" />;
      case 'motorbike':
      default:
        return <Bike className="w-5 h-5 text-blue-600" />;
    }
  };

  const handleAssignOrder = (orderId: string) => {
    if (!assignModalCourier) return;

    setCouriers((prev) =>
      prev.map((c) =>
        c.id === assignModalCourier.id
          ? {
              ...c,
              assigned_orders_count: c.assigned_orders_count + 1,
              status: 'on_delivery',
            }
          : c
      )
    );
    setAssignModalCourier(null);
  };

  return (
    <div className="space-y-6">
      {/* Fleet KPI Banner */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between text-xs text-slate-500 font-bold mb-1">
            <span>إجمالي أسطول الديب كوريير</span>
            <Radio className="w-4 h-4 text-emerald-500 animate-pulse" />
          </div>
          <div className="text-3xl font-black text-slate-800">{couriers.length} سائقين</div>
          <p className="text-xs text-emerald-600 font-medium mt-1">✓ اتصال حي بنظام GPS</p>
        </div>

        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm">
          <div className="text-xs text-slate-500 font-bold mb-1">في مهمات توصيل الآن</div>
          <div className="text-3xl font-black text-blue-600">
            {couriers.filter((c) => c.status === 'on_delivery').length}
          </div>
          <p className="text-xs text-blue-500 font-medium mt-1">متوسط زمن التوصيل: 14.2 دقيقة</p>
        </div>

        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm">
          <div className="text-xs text-slate-500 font-bold mb-1">سائقين متاحين للطلب الفوري</div>
          <div className="text-3xl font-black text-emerald-600">
            {couriers.filter((c) => c.status === 'idle').length}
          </div>
          <p className="text-xs text-slate-400 mt-1">جاهزون في محطات الانتظار</p>
        </div>

        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm">
          <div className="text-xs text-slate-500 font-bold mb-1">إجمالي طلبات تم تسليمها اليوم</div>
          <div className="text-3xl font-black text-slate-800">
            {couriers.reduce((sum, c) => sum + c.completed_today, 0)}
          </div>
          <p className="text-xs text-emerald-600 font-medium mt-1">معدل رضا العملاء: 4.96 ★</p>
        </div>
      </div>

      {/* Filter Tabs */}
      <div className="flex gap-2 border-b border-slate-200 pb-3">
        <button
          onClick={() => setFilter('all')}
          className={`px-4 py-1.5 rounded-lg text-xs font-bold transition-colors ${
            filter === 'all'
              ? 'bg-slate-900 text-white'
              : 'bg-white text-slate-600 hover:bg-slate-100 border border-slate-200'
          }`}
        >
          كافة السائقين ({couriers.length})
        </button>
        <button
          onClick={() => setFilter('on_delivery')}
          className={`px-4 py-1.5 rounded-lg text-xs font-bold transition-colors ${
            filter === 'on_delivery'
              ? 'bg-blue-600 text-white'
              : 'bg-white text-slate-600 hover:bg-slate-100 border border-slate-200'
          }`}
        >
          على الطريق للتسليم ({couriers.filter((c) => c.status === 'on_delivery').length})
        </button>
        <button
          onClick={() => setFilter('idle')}
          className={`px-4 py-1.5 rounded-lg text-xs font-bold transition-colors ${
            filter === 'idle'
              ? 'bg-emerald-600 text-white'
              : 'bg-white text-slate-600 hover:bg-slate-100 border border-slate-200'
          }`}
        >
          سائقون متاحون ({couriers.filter((c) => c.status === 'idle').length})
        </button>
      </div>

      {/* Courier Cards Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
        {filteredCouriers.map((courier) => {
          const isOnDelivery = courier.status === 'on_delivery';
          return (
            <div
              key={courier.id}
              className="bg-white rounded-xl border border-slate-200 shadow-sm p-5 hover:shadow-md transition-all flex flex-col justify-between"
            >
              <div>
                {/* Header */}
                <div className="flex items-start justify-between mb-3">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-xl bg-slate-100 flex items-center justify-center">
                      {getVehicleIcon(courier.vehicle_type)}
                    </div>
                    <div>
                      <h4 className="font-bold text-slate-800 text-sm">{courier.full_name}</h4>
                      <span className="font-mono text-xs text-slate-400 font-semibold">
                        {courier.license_plate}
                      </span>
                    </div>
                  </div>
                  <span
                    className={`inline-flex items-center gap-1 text-xs font-bold px-2 py-0.5 rounded-full ${
                      isOnDelivery
                        ? 'bg-blue-100 text-blue-800'
                        : 'bg-emerald-100 text-emerald-800'
                    }`}
                  >
                    <span className="w-1.5 h-1.5 rounded-full bg-current"></span>
                    {isOnDelivery ? 'في الطريق للعميل' : 'متاح للطلب'}
                  </span>
                </div>

                {/* Location & Battery */}
                <div className="space-y-2 text-xs text-slate-600 mb-4 bg-slate-50 p-3 rounded-lg border border-slate-100">
                  <div className="flex items-center gap-2">
                    <MapPin className="w-3.5 h-3.5 text-rose-500 shrink-0" />
                    <span className="truncate">{courier.current_location}</span>
                  </div>
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-1.5">
                      <BatteryCharging className="w-3.5 h-3.5 text-emerald-500" />
                      <span>شحن المركبة: {courier.battery_or_fuel}%</span>
                    </div>
                    <div className="flex items-center gap-1 font-bold text-amber-600">
                      <Star className="w-3.5 h-3.5 fill-amber-500 text-amber-500" />
                      <span>{courier.rating}</span>
                    </div>
                  </div>
                </div>

                {/* Performance stats */}
                <div className="grid grid-cols-2 gap-2 text-center text-xs pb-4 border-b border-slate-100 mb-4">
                  <div className="bg-slate-50 p-2 rounded">
                    <div className="font-black text-slate-800 text-sm">{courier.assigned_orders_count}</div>
                    <div className="text-slate-400 text-xs">طلبات محملة حالياً</div>
                  </div>
                  <div className="bg-slate-50 p-2 rounded">
                    <div className="font-black text-emerald-700 text-sm">{courier.completed_today}</div>
                    <div className="text-slate-400 text-xs">أكملها اليوم</div>
                  </div>
                </div>
              </div>

              {/* Actions */}
              <div className="flex gap-2">
                <a
                  href={`tel:${courier.phone}`}
                  className="px-3 py-2 border border-slate-200 rounded-lg text-slate-600 hover:bg-slate-50 transition-colors inline-flex items-center justify-center gap-1 text-xs font-bold"
                  title="اتصال بالسائق"
                >
                  <Phone className="w-3.5 h-3.5" />
                  اتصال
                </a>
                <button
                  onClick={() => setAssignModalCourier(courier)}
                  className="flex-1 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg text-xs font-bold transition-colors inline-flex items-center justify-center gap-1.5 shadow-sm"
                >
                  <Send className="w-3.5 h-3.5" />
                  إسناد طلب للسائق
                </button>
              </div>
            </div>
          );
        })}
      </div>

      {/* Assign Order Modal */}
      {assignModalCourier && (
        <div className="fixed inset-0 z-50 bg-black/50 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-md w-full p-6 shadow-2xl border border-slate-200">
            <h3 className="text-base font-bold text-slate-800 mb-2">
              إسناد طلب للسائق: {assignModalCourier.full_name}
            </h3>
            <p className="text-xs text-slate-500 mb-4">
              اختر طلباً من قائمة الطلبات المجهزة في المستودع لإسناد التوصيل فائق السرعة:
            </p>

            <div className="space-y-2 max-h-60 overflow-y-auto mb-4">
              {pendingOrders.length === 0 ? (
                <div className="p-4 text-center text-xs text-slate-400">
                  لا توجد طلبات معلقة بانتظار الشحن حالياً
                </div>
              ) : (
                pendingOrders.map((ord) => (
                  <div
                    key={ord.id}
                    onClick={() => handleAssignOrder(ord.id)}
                    className="p-3 border border-slate-200 hover:border-blue-500 hover:bg-blue-50/50 rounded-lg cursor-pointer transition-all flex items-center justify-between text-xs"
                  >
                    <div>
                      <div className="font-mono font-bold text-blue-600">{ord.order_number}</div>
                      <div className="text-slate-600 font-bold">{ord.customer_name}</div>
                      <div className="text-slate-400 truncate max-w-xs">{ord.customer_address}</div>
                    </div>
                    <span className="font-bold text-slate-800 bg-slate-100 px-2 py-1 rounded">
                      {ord.total_amount.toFixed(2)} ل.س
                    </span>
                  </div>
                ))
              )}
            </div>

            <div className="flex justify-end">
              <button
                type="button"
                onClick={() => setAssignModalCourier(null)}
                className="px-4 py-2 border border-slate-300 rounded-lg text-xs font-bold text-slate-600 hover:bg-slate-50"
              >
                إغلاق
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
