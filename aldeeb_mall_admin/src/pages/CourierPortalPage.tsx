import React, { useState } from 'react';
import { 
  Bike, 
  Truck, 
  MapPin, 
  Phone, 
  Navigation, 
  CheckCircle2, 
  Clock, 
  AlertTriangle, 
  DollarSign, 
  ShieldCheck, 
  KeyRound, 
  ArrowLeft, 
  UserCheck, 
  Power, 
  Coffee, 
  Compass, 
  Send, 
  XCircle,
  Package,
  Layers,
  Sparkles
} from 'lucide-react';
import { Courier, Order } from '../types';
import { logAuditEvent } from '../lib/auditLogger';

interface CourierPortalPageProps {
  couriers: Courier[];
  orders: Order[];
  onUpdateOrder: (order: Order) => void;
  onUpdateCourier?: (courier: Courier) => void;
  onBackToAdmin?: () => void;
}

export const CourierPortalPage: React.FC<CourierPortalPageProps> = ({
  couriers,
  orders,
  onUpdateOrder,
  onUpdateCourier,
  onBackToAdmin,
}) => {
  // Current logged in courier
  const [selectedCourierId, setSelectedCourierId] = useState<string>(couriers[0]?.id || '');
  const currentCourier = couriers.find((c) => c.id === selectedCourierId) || couriers[0];

  // Courier Local Shift & Orders State
  const [shiftStatus, setShiftStatus] = useState<'active' | 'break' | 'off_duty'>('active');
  const [selectedOrderForDelivery, setSelectedOrderForDelivery] = useState<Order | null>(null);
  
  // Modal States
  const [otpInput, setOtpInput] = useState<string>('');
  const [otpError, setOtpError] = useState<string | null>(null);
  const [showDeclineModal, setShowDeclineModal] = useState<Order | null>(null);
  const [declineReason, setDeclineReason] = useState<string>('ازدحام مروري خانق على طريق التسليم');
  const [showFailureModal, setShowFailureModal] = useState<Order | null>(null);
  const [failureReason, setFailureReason] = useState<string>('العميل لم يجب على الاتصالات المتكررة');
  const [toastMessage, setToastMessage] = useState<string | null>(null);

  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(null), 3500);
  };

  // Orders assigned to this courier or pending dispatch for this courier
  const myAssignedOrders = orders.filter((o) => {
    // Assigned directly or courier matches
    return o.courier_id === currentCourier?.id || 
      (o.status === 'out_for_delivery' && (!o.courier_id || o.courier_id === currentCourier?.id)) ||
      (o.status === 'packing' && o.courier_id === currentCourier?.id);
  });

  // Calculate courier daily financial pouch
  const completedOrders = orders.filter(
    (o) => (o.courier_id === currentCourier?.id || o.status === 'delivered') && o.status === 'delivered'
  );
  const totalCashCollected = completedOrders
    .filter((o) => o.payment_method === 'cash_on_delivery' || o.payment_method === 'cash')
    .reduce((sum, o) => sum + o.total_amount, 0);
  const deliveryCommission = completedOrders.length * 2500; // 2500 SYP commission per delivery

  // Accept a mission
  const handleAcceptMission = (order: Order) => {
    const updated: Order = {
      ...order,
      courier_id: currentCourier.id,
      courier_name: currentCourier.full_name,
      status: 'out_for_delivery',
      assigned_at: new Date().toISOString(),
      delivery_otp: order.delivery_otp || `${Math.floor(1000 + Math.random() * 9000)}`,
    };
    onUpdateOrder(updated);

    if (onUpdateCourier) {
      onUpdateCourier({
        ...currentCourier,
        status: 'on_delivery',
        assigned_orders_count: (currentCourier.assigned_orders_count || 0) + 1,
      });
    }

    logAuditEvent({
      actor_id: currentCourier.id,
      actor_name: currentCourier.full_name,
      actor_role: 'courier',
      action: 'COURIER_ACCEPTED_MISSION',
      category: 'orders',
      details: `الكابتن ${currentCourier.full_name} قبل مهمة توصيل الطلب ${order.order_number} إلى ${order.customer_address}`,
      target_id: order.id,
    });

    showToast(`✓ تم قبول المهمة بنجاح، يمكنك الانطلاق الآن!`);
  };

  // Decline a mission
  const handleDeclineMission = (order: Order) => {
    const updated: Order = {
      ...order,
      courier_id: undefined,
      courier_name: undefined,
      status: 'packing', // return to dispatch pool
      notes: `${order.notes || ''} [اعتذر الكابتن ${currentCourier.full_name}: ${declineReason}]`,
    };
    onUpdateOrder(updated);

    logAuditEvent({
      actor_id: currentCourier.id,
      actor_name: currentCourier.full_name,
      actor_role: 'courier',
      action: 'COURIER_DECLINED_MISSION',
      category: 'orders',
      details: `اعتذر الكابتن ${currentCourier.full_name} عن طلب ${order.order_number}. السبب: ${declineReason}`,
      target_id: order.id,
    });

    showToast(`تم تسجيل الاعتذار وإعادة الطلب لغرفة التحكم لتكليف مندوب بديل.`);
    setShowDeclineModal(null);
  };

  // Confirm delivery with OTP Verification
  const handleConfirmDeliveryWithOtp = (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedOrderForDelivery) return;

    // Expected OTP: default is 1234 or order.delivery_otp
    const expectedOtp = selectedOrderForDelivery.delivery_otp || '1234';

    if (otpInput.trim() !== expectedOtp && otpInput.trim() !== '1234') {
      setOtpError(`رمز التحقق غير صحيح! رمز العميل هو "${expectedOtp}" (أو 1234 للاختبار).`);
      return;
    }

    const updated: Order = {
      ...selectedOrderForDelivery,
      status: 'delivered',
      delivered_at: new Date().toISOString(),
    };
    onUpdateOrder(updated);

    if (onUpdateCourier) {
      onUpdateCourier({
        ...currentCourier,
        completed_today: (currentCourier.completed_today || 0) + 1,
        status: 'idle',
      });
    }

    logAuditEvent({
      actor_id: currentCourier.id,
      actor_name: currentCourier.full_name,
      actor_role: 'courier',
      action: 'ORDER_DELIVERED_VERIFIED',
      category: 'orders',
      details: `تم تسليم الطلب ${selectedOrderForDelivery.order_number} بنجاح للعميل (${selectedOrderForDelivery.customer_name}) ومطابقة OTP.`,
      target_id: selectedOrderForDelivery.id,
    });

    showToast(`🎉 مبروك! تم تسليم الطلب ${selectedOrderForDelivery.order_number} بنجاح واحتساب العمولة.`);
    setSelectedOrderForDelivery(null);
    setOtpInput('');
    setOtpError(null);
  };

  // Record Delivery Failure (Proof of Failure)
  const handleConfirmFailure = (e: React.FormEvent) => {
    e.preventDefault();
    if (!showFailureModal) return;

    const updated: Order = {
      ...showFailureModal,
      status: 'cancelled',
      delivery_failure_reason: failureReason,
      notes: `${showFailureModal.notes || ''} [فشل التسليم بواسطة ${currentCourier.full_name}: ${failureReason}]`,
    };
    onUpdateOrder(updated);

    if (onUpdateCourier) {
      onUpdateCourier({
        ...currentCourier,
        status: 'idle',
      });
    }

    logAuditEvent({
      actor_id: currentCourier.id,
      actor_name: currentCourier.full_name,
      actor_role: 'courier',
      action: 'DELIVERY_FAILURE_RECORDED',
      category: 'orders',
      details: `إثبات تعذر تسليم الطلب ${showFailureModal.order_number} للعميل ${showFailureModal.customer_name}. السبب: ${failureReason}`,
      target_id: showFailureModal.id,
    });

    showToast(`تم توثيق تعذر التسليم وإشعار غرفة العمليات وخدمة العملاء.`);
    setShowFailureModal(null);
  };

  return (
    <div className="min-h-screen bg-slate-900 text-white font-sans antialiased" dir="rtl">
      {/* Top Mobile Bar */}
      <div className="bg-slate-950 border-b border-slate-800 p-4 sticky top-0 z-30">
        <div className="max-w-md mx-auto flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="w-10 h-10 rounded-2xl bg-black flex items-center justify-center overflow-hidden border border-cyan-500/40 shadow-md shrink-0">
              <img
                src={`${import.meta.env.BASE_URL}logo.png`}
                alt="شعار الديب مول DEB"
                className="w-full h-full object-cover"
              />
            </div>
            <div>
              <h2 className="text-sm font-black text-white flex items-center gap-1.5">
                <span>تطبيق كابتن الديب مول</span>
                <span className="text-[10px] bg-blue-500/20 text-blue-300 px-1.5 py-0.2 rounded border border-blue-500/30 font-bold">
                  PWA
                </span>
              </h2>
              <div className="flex items-center gap-1 text-[11px] text-slate-400">
                <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
                <span>متصل بالأقمار الصناعية (GPS)</span>
              </div>
            </div>
          </div>

          <div className="flex items-center gap-2">
            {onBackToAdmin && (
              <button
                onClick={onBackToAdmin}
                className="px-3 py-1.5 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-xl text-xs font-bold transition-all border border-slate-700 flex items-center gap-1"
                title="الرجوع للوحة الإدارة العامة"
              >
                <ArrowLeft className="w-3.5 h-3.5" />
                <span>الإدارة</span>
              </button>
            )}
          </div>
        </div>
      </div>

      {/* Main Container */}
      <div className="max-w-md mx-auto p-4 space-y-4 pb-24">
        {/* Toast Alert */}
        {toastMessage && (
          <div className="p-3 bg-emerald-600 text-white rounded-2xl text-xs font-bold shadow-lg flex items-center gap-2 animate-fade-in">
            <CheckCircle2 className="w-4 h-4 shrink-0" />
            <span>{toastMessage}</span>
          </div>
        )}

        {/* Courier Profile & Shift Switcher */}
        <div className="bg-slate-800/80 rounded-3xl p-4 border border-slate-700/80 shadow-lg space-y-3">
          <div className="flex items-center justify-between">
            <div>
              <label className="text-[10px] text-slate-400 font-bold block mb-1">تسجيل دخول السائق / الكابتن:</label>
              <select
                value={selectedCourierId}
                onChange={(e) => setSelectedCourierId(e.target.value)}
                className="bg-slate-900 border border-slate-700 text-white font-bold text-xs rounded-xl px-3 py-1.5 focus:outline-none focus:border-blue-500"
              >
                {couriers.map((c) => (
                  <option key={c.id} value={c.id}>
                    {c.full_name} ({c.vehicle_type === 'motorbike' ? 'دراجة' : 'فان مبرد'})
                  </option>
                ))}
              </select>
            </div>

            <div className="text-left font-mono">
              <span className="text-[10px] text-slate-400 block">رقم اللوحة</span>
              <span className="text-xs font-bold text-slate-200">{currentCourier.license_plate}</span>
            </div>
          </div>

          {/* Shift State Toggle Buttons */}
          <div className="grid grid-cols-3 gap-2 pt-2 border-t border-slate-700/50">
            <button
              onClick={() => setShiftStatus('active')}
              className={`py-2 rounded-xl text-xs font-bold transition-all flex items-center justify-center gap-1.5 ${
                shiftStatus === 'active'
                  ? 'bg-emerald-600 text-white shadow-md shadow-emerald-600/30 font-black'
                  : 'bg-slate-900 text-slate-400 hover:text-white'
              }`}
            >
              <Power className="w-3.5 h-3.5" />
              <span>متاح للطلب</span>
            </button>

            <button
              onClick={() => setShiftStatus('break')}
              className={`py-2 rounded-xl text-xs font-bold transition-all flex items-center justify-center gap-1.5 ${
                shiftStatus === 'break'
                  ? 'bg-amber-600 text-white shadow-md shadow-amber-600/30 font-black'
                  : 'bg-slate-900 text-slate-400 hover:text-white'
              }`}
            >
              <Coffee className="w-3.5 h-3.5" />
              <span>استراحة</span>
            </button>

            <button
              onClick={() => setShiftStatus('off_duty')}
              className={`py-2 rounded-xl text-xs font-bold transition-all flex items-center justify-center gap-1.5 ${
                shiftStatus === 'off_duty'
                  ? 'bg-rose-600 text-white shadow-md shadow-rose-600/30 font-black'
                  : 'bg-slate-900 text-slate-400 hover:text-white'
              }`}
            >
              <Power className="w-3.5 h-3.5" />
              <span>خارج الوردية</span>
            </button>
          </div>
        </div>

        {/* Courier Financial Summary Card */}
        <div className="grid grid-cols-3 gap-2 text-center text-xs">
          <div className="bg-slate-800/80 p-3 rounded-2xl border border-slate-700">
            <div className="text-[10px] text-slate-400 font-bold">طلبات اليوم</div>
            <div className="text-lg font-black text-emerald-400 font-mono mt-0.5">
              {currentCourier.completed_today || completedOrders.length}
            </div>
            <div className="text-[9px] text-slate-400">ناجحة 100%</div>
          </div>

          <div className="bg-slate-800/80 p-3 rounded-2xl border border-slate-700">
            <div className="text-[10px] text-slate-400 font-bold">عمولتك المستحقة</div>
            <div className="text-lg font-black text-blue-400 font-mono mt-0.5">
              {deliveryCommission.toLocaleString()}
            </div>
            <div className="text-[9px] text-slate-400">ليرة سورية</div>
          </div>

          <div className="bg-slate-800/80 p-3 rounded-2xl border border-slate-700">
            <div className="text-[10px] text-slate-400 font-bold">العهدة النقدية</div>
            <div className="text-lg font-black text-amber-400 font-mono mt-0.5">
              {totalCashCollected.toLocaleString()}
            </div>
            <div className="text-[9px] text-slate-400">ل.س بالحقيبة</div>
          </div>
        </div>

        {/* Shift status warning */}
        {shiftStatus !== 'active' && (
          <div className="p-3 bg-amber-500/10 border border-amber-500/30 rounded-2xl text-xs text-amber-300 flex items-center gap-2">
            <AlertTriangle className="w-4 h-4 shrink-0 text-amber-400" />
            <span>أنت حالياً في وضع {shiftStatus === 'break' ? 'الاستراحة' : 'خارج الوردية'}. قم بالتبديل إلى "متاح للطلب" لاستلام مهام جديدة.</span>
          </div>
        )}

        {/* Missions Section */}
        <div className="space-y-3">
          <div className="flex items-center justify-between">
            <h3 className="text-xs font-black text-slate-200 flex items-center gap-1.5">
              <Package className="w-4 h-4 text-blue-400" />
              <span>مهام التوصيل المسندة إليك ({myAssignedOrders.length})</span>
            </h3>
            <span className="text-[10px] text-slate-400 font-mono">تحديث لحظي</span>
          </div>

          {myAssignedOrders.length === 0 ? (
            <div className="bg-slate-800/50 rounded-3xl p-8 border border-slate-700/60 text-center space-y-2">
              <Compass className="w-10 h-10 text-slate-600 mx-auto" />
              <h4 className="font-bold text-slate-300 text-sm">لا توجد طلبات مسندة حالياً</h4>
              <p className="text-xs text-slate-500">
                أنت في وضع الاستعداد. سيتم تنبيهك بصوت وإشعار فوري عند إسناد مهمة جديدة من مركز التوزيع.
              </p>
            </div>
          ) : (
            myAssignedOrders.map((order) => {
              const isOutForDelivery = order.status === 'out_for_delivery';
              return (
                <div
                  key={order.id}
                  className={`rounded-3xl p-4 border transition-all space-y-3 ${
                    isOutForDelivery
                      ? 'bg-gradient-to-b from-blue-950/40 to-slate-800 border-blue-500/50 shadow-xl ring-1 ring-blue-500/30'
                      : 'bg-slate-800/80 border-slate-700'
                  }`}
                >
                  <div className="flex items-start justify-between">
                    <div>
                      <div className="flex items-center gap-2">
                        <span className="text-xs font-black font-mono text-blue-400">{order.order_number}</span>
                        {order.delivery_type === '15_min_express' && (
                          <span className="text-[10px] font-black bg-rose-500/20 text-rose-300 px-2 py-0.5 rounded-full border border-rose-500/30 flex items-center gap-1">
                            <Clock className="w-3 h-3 text-rose-400" />
                            إكسبريس 15 دقيقة
                          </span>
                        )}
                      </div>
                      <h4 className="font-bold text-white text-sm mt-1">{order.customer_name}</h4>
                    </div>

                    <div className="text-left font-mono">
                      <div className="text-sm font-black text-emerald-400">{order.total_amount.toLocaleString()} ل.س</div>
                      <div className="text-[10px] text-slate-400">
                        {order.payment_method === 'cash_on_delivery' || order.payment_method === 'cash'
                          ? 'تحصيل نقد عند الاستلام'
                          : 'مدفوع مسبقاً (شام كاش)'}
                      </div>
                    </div>
                  </div>

                  {/* Address & Navigation */}
                  <div className="bg-slate-900/80 p-3 rounded-2xl border border-slate-700/60 text-xs space-y-2">
                    <div className="flex items-start gap-2 text-slate-300">
                      <MapPin className="w-4 h-4 text-rose-400 shrink-0 mt-0.5" />
                      <span className="leading-relaxed font-medium">{order.customer_address}</span>
                    </div>

                    <div className="flex items-center justify-between pt-2 border-t border-slate-800 text-[11px]">
                      <a
                        href={`tel:${order.customer_phone}`}
                        className="px-3 py-1.5 bg-blue-600/20 text-blue-300 hover:bg-blue-600/30 border border-blue-500/30 rounded-xl font-bold flex items-center gap-1.5 transition-colors"
                      >
                        <Phone className="w-3.5 h-3.5 text-blue-400" />
                        <span>اتصال بالعميل ({order.customer_phone})</span>
                      </a>

                      <a
                        href={`https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(order.customer_address)}`}
                        target="_blank"
                        rel="noreferrer"
                        className="px-3 py-1.5 bg-slate-800 hover:bg-slate-700 text-slate-200 border border-slate-700 rounded-xl font-bold flex items-center gap-1.5 transition-colors"
                      >
                        <Navigation className="w-3.5 h-3.5 text-emerald-400" />
                        <span>فتح الخريطة والملاحة</span>
                      </a>
                    </div>
                  </div>

                  {/* Order Items Snapshot */}
                  <div className="text-[11px] text-slate-400 bg-slate-900/40 p-2 rounded-xl flex items-center justify-between">
                    <span>عدد الأصناف في الحقيبة:</span>
                    <span className="font-bold text-slate-200">{order.items.length} أصناف ({order.items.map(i => i.product_name_ar).slice(0, 2).join('، ')}...)</span>
                  </div>

                  {/* Actions according to status */}
                  {!isOutForDelivery ? (
                    <div className="grid grid-cols-2 gap-2 pt-1">
                      <button
                        onClick={() => setShowDeclineModal(order)}
                        className="py-2.5 bg-slate-900 hover:bg-slate-700 text-rose-400 rounded-2xl text-xs font-bold transition-all border border-rose-500/20 flex items-center justify-center gap-1.5"
                      >
                        <XCircle className="w-4 h-4" />
                        <span>اعتذار عن المهمة</span>
                      </button>

                      <button
                        onClick={() => handleAcceptMission(order)}
                        className="py-2.5 bg-blue-600 hover:bg-blue-700 text-white rounded-2xl text-xs font-bold transition-all shadow-lg shadow-blue-600/30 flex items-center justify-center gap-1.5"
                      >
                        <Navigation className="w-4 h-4" />
                        <span>قبول وبدء التوصيل</span>
                      </button>
                    </div>
                  ) : (
                    <div className="space-y-2 pt-1">
                      <div className="p-3 bg-emerald-500/10 border border-emerald-500/30 rounded-2xl flex items-center justify-between text-xs">
                        <span className="text-emerald-300 font-bold flex items-center gap-1.5">
                          <CheckCircle2 className="w-4 h-4 text-emerald-400" />
                          أنت الآن في طريقك للعميل
                        </span>
                        <span className="text-[11px] text-slate-400 font-mono">OTP: {order.delivery_otp || '1234'}</span>
                      </div>

                      <div className="grid grid-cols-2 gap-2">
                        <button
                          onClick={() => setShowFailureModal(order)}
                          className="py-2.5 bg-slate-800 hover:bg-rose-950/40 text-rose-400 rounded-2xl text-xs font-bold border border-rose-500/30 flex items-center justify-center gap-1"
                        >
                          <AlertTriangle className="w-3.5 h-3.5" />
                          <span>تعذر التسليم (إثبات فشل)</span>
                        </button>

                        <button
                          onClick={() => {
                            setSelectedOrderForDelivery(order);
                            setOtpInput('');
                            setOtpError(null);
                          }}
                          className="py-2.5 bg-emerald-600 hover:bg-emerald-700 text-white rounded-2xl text-xs font-bold shadow-lg shadow-emerald-600/30 flex items-center justify-center gap-1"
                        >
                          <ShieldCheck className="w-4 h-4" />
                          <span>إثبات التسليم بكود OTP</span>
                        </button>
                      </div>
                    </div>
                  )}
                </div>
              );
            })
          )}
        </div>
      </div>

      {/* MODAL: OTP Verification for Successful Delivery */}
      {selectedOrderForDelivery && (
        <div className="fixed inset-0 z-50 bg-black/80 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-slate-900 border border-slate-700 rounded-3xl max-w-sm w-full p-6 text-white space-y-4 shadow-2xl">
            <div className="text-center space-y-1">
              <div className="w-12 h-12 bg-emerald-500/20 text-emerald-400 rounded-2xl flex items-center justify-center mx-auto border border-emerald-500/30">
                <KeyRound className="w-6 h-6 text-emerald-400" />
              </div>
              <h3 className="text-base font-black">التحقق من كود استلام العميل</h3>
              <p className="text-xs text-slate-400">
                اطلب من العميل ({selectedOrderForDelivery.customer_name}) رمز الـ OTP المكون من 4 أرقام لتأكيد الاستلام.
              </p>
            </div>

            <form onSubmit={handleConfirmDeliveryWithOtp} className="space-y-4">
              <div>
                <input
                  type="text"
                  maxLength={4}
                  required
                  autoFocus
                  placeholder="• • • •"
                  value={otpInput}
                  onChange={(e) => setOtpInput(e.target.value)}
                  className="w-full text-center tracking-[1em] text-2xl font-black font-mono py-3 bg-slate-950 border border-slate-700 rounded-2xl text-emerald-400 focus:outline-none focus:border-emerald-500"
                />
                <span className="block text-center text-[11px] text-slate-500 mt-1 font-mono">
                  (رمز العميل المسجل في النظام: {selectedOrderForDelivery.delivery_otp || '1234'})
                </span>
                {otpError && (
                  <p className="text-xs text-rose-400 font-bold text-center mt-1">{otpError}</p>
                )}
              </div>

              <div className="flex gap-2">
                <button
                  type="button"
                  onClick={() => setSelectedOrderForDelivery(null)}
                  className="flex-1 py-3 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-2xl text-xs font-bold transition-all"
                >
                  إلغاء
                </button>
                <button
                  type="submit"
                  className="flex-1 py-3 bg-emerald-600 hover:bg-emerald-700 text-white rounded-2xl text-xs font-bold transition-all shadow-lg shadow-emerald-600/30"
                >
                  تأكيد وإتمام التسليم
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* MODAL: Decline Mission */}
      {showDeclineModal && (
        <div className="fixed inset-0 z-50 bg-black/80 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-slate-900 border border-slate-700 rounded-3xl max-w-sm w-full p-6 text-white space-y-4 shadow-2xl">
            <div className="text-center space-y-1">
              <div className="w-12 h-12 bg-rose-500/20 text-rose-400 rounded-2xl flex items-center justify-center mx-auto border border-rose-500/30">
                <XCircle className="w-6 h-6 text-rose-400" />
              </div>
              <h3 className="text-base font-black">الاعتذار عن مهمة التوصيل</h3>
              <p className="text-xs text-slate-400">
                يرجى تحديد سبب تعذر استلام الطلب {showDeclineModal.order_number} لتحويله لسائق آخر فوراً.
              </p>
            </div>

            <div className="space-y-3 text-xs">
              <div>
                <label className="block font-bold text-slate-400 mb-1">سبب الاعتذار الإلزامي:</label>
                <select
                  value={declineReason}
                  onChange={(e) => setDeclineReason(e.target.value)}
                  className="w-full p-2.5 bg-slate-950 border border-slate-700 rounded-xl font-bold text-slate-200"
                >
                  <option value="ازدحام مروري خانق على طريق التسليم">ازدحام مروري خانق على طريق التسليم</option>
                  <option value="عطل ميكانيكي طارئ بالدراجة / المركبة">عطل ميكانيكي طارئ بالدراجة / المركبة</option>
                  <option value="حمولة زائدة لا تتسع في حقيبة التوصيل">حمولة زائدة لا تتسع في حقيبة التوصيل</option>
                  <option value="انتهاء ساعات الوردية المقررة">انتهاء ساعات الوردية المقررة</option>
                </select>
              </div>

              <div className="flex gap-2 pt-2">
                <button
                  type="button"
                  onClick={() => setShowDeclineModal(null)}
                  className="flex-1 py-3 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-2xl font-bold"
                >
                  تراجع
                </button>
                <button
                  type="button"
                  onClick={() => handleDeclineMission(showDeclineModal)}
                  className="flex-1 py-3 bg-rose-600 hover:bg-rose-700 text-white rounded-2xl font-bold"
                >
                  تأكيد الاعتذار
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* MODAL: Proof of Delivery Failure */}
      {showFailureModal && (
        <div className="fixed inset-0 z-50 bg-black/80 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-slate-900 border border-slate-700 rounded-3xl max-w-sm w-full p-6 text-white space-y-4 shadow-2xl">
            <div className="text-center space-y-1">
              <div className="w-12 h-12 bg-rose-500/20 text-rose-400 rounded-2xl flex items-center justify-center mx-auto border border-rose-500/30">
                <AlertTriangle className="w-6 h-6 text-rose-400" />
              </div>
              <h3 className="text-base font-black">إثبات تعذر أو فشل التسليم</h3>
              <p className="text-xs text-slate-400">
                طلب: {showFailureModal.order_number} للعميل ({showFailureModal.customer_name})
              </p>
            </div>

            <form onSubmit={handleConfirmFailure} className="space-y-3 text-xs">
              <div>
                <label className="block font-bold text-slate-400 mb-1">سبب تعذر التسليم *</label>
                <select
                  value={failureReason}
                  onChange={(e) => setFailureReason(e.target.value)}
                  className="w-full p-2.5 bg-slate-950 border border-slate-700 rounded-xl font-bold text-slate-200"
                >
                  <option value="العميل لم يجب على الاتصالات المتكررة">العميل لم يجب على الاتصالات المتكررة</option>
                  <option value="العنوان غير دقيق والعميل مغلق هاتفه">العنوان غير دقيق والعميل مغلق هاتفه</option>
                  <option value="العميل رفض استلام الطلب عند الباب">العميل رفض استلام الطلب عند الباب</option>
                  <option value="العميل طلب تأجيل موعد التسليم لوقت آخر">العميل طلب تأجيل موعد التسليم لوقت آخر</option>
                </select>
              </div>

              <div className="flex gap-2 pt-2">
                <button
                  type="button"
                  onClick={() => setShowFailureModal(null)}
                  className="flex-1 py-3 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-2xl font-bold"
                >
                  إلغاء
                </button>
                <button
                  type="submit"
                  className="flex-1 py-3 bg-rose-600 hover:bg-rose-700 text-white rounded-2xl font-bold"
                >
                  توثيق الفشل وإلغاء المهمة
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
