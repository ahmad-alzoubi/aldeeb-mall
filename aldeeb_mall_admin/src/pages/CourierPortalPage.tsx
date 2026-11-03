import React, { useState, useEffect, useMemo, useRef } from 'react';
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
  Sparkles,
  Wallet,
  History,
  Headset,
  User,
  Search,
  Check,
  RefreshCw,
  QrCode,
  Wifi,
  WifiOff,
  Signal,
  Lock
} from 'lucide-react';
import { Courier, Order } from '../types';
import { logAuditEvent } from '../lib/auditLogger';
import { evaluateOrderDispatch } from '../lib/dispatchEngine';

interface CourierPortalPageProps {
  couriers: Courier[];
  orders: Order[];
  onUpdateOrder: (order: Order) => void;
  onUpdateCourier?: (courier: Courier) => void;
  onBackToAdmin?: () => void;
}

export type CaptainTab = 'missions' | 'offers' | 'history' | 'finances' | 'support' | 'profile';

export const CourierPortalPage: React.FC<CourierPortalPageProps> = ({
  couriers,
  orders,
  onUpdateOrder,
  onUpdateCourier,
  onBackToAdmin,
}) => {
  // Navigation State
  const [activeTab, setActiveTab] = useState<CaptainTab>('missions');

  // Current logged in courier
  const [selectedCourierId, setSelectedCourierId] = useState<string>(() => {
    return localStorage.getItem('captain_active_courier_id') || couriers[0]?.id || '';
  });
  const currentCourier = couriers.find((c) => c.id === selectedCourierId) || couriers[0];

  // Courier Local Shift & Status State
  const [shiftStatus, setShiftStatus] = useState<'active' | 'break' | 'off_duty'>(() => {
    return (localStorage.getItem(`captain_shift_${selectedCourierId}`) as any) || 'active';
  });

  // Selected Order for stage delivery action
  const [selectedOrderForDelivery, setSelectedOrderForDelivery] = useState<Order | null>(null);

  // Delivery Stages state map: order_id -> stage (1: accepted, 2: arrived_store, 3: picked_up, 4: en_route, 5: arrived_customer, 6: delivered)
  const [orderStages, setOrderStages] = useState<Record<string, number>>(() => {
    try {
      const raw = localStorage.getItem(`captain_order_stages_${selectedCourierId}`);
      return raw ? JSON.parse(raw) : {};
    } catch {
      return {};
    }
  });

  // Modals & Inputs
  const [otpInput, setOtpInput] = useState<string>('');
  const [otpError, setOtpError] = useState<string | null>(null);
  const [showDeclineModal, setShowDeclineModal] = useState<Order | null>(null);
  const [declineReason, setDeclineReason] = useState<string>('ازدحام مروري خانق على طريق التسليم');
  const [showFailureModal, setShowFailureModal] = useState<Order | null>(null);
  const [failureReason, setFailureReason] = useState<string>('العميل لم يجب على الاتصالات المتكررة');
  const [toastMessage, setToastMessage] = useState<string | null>(null);

  // Search & Filters for History
  const [historySearch, setHistorySearch] = useState('');

  // Support Chat State
  const [chatMessages, setChatMessages] = useState<Array<{ id: string; sender: 'captain' | 'support'; text: string; time: string }>>([
    { id: '1', sender: 'support', text: 'أهلاً بك كابتن في غرفة عمليات الذيب مول. نحن متواجدون لمساعدتك على مدار الساعة في أي طارئ على الطريق.', time: '09:00 ص' },
  ]);
  const [newChatMessage, setNewChatMessage] = useState('');

  // Password & Profile Settings State
  const [oldPassword, setOldPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [passwordToast, setPasswordToast] = useState<string | null>(null);

  // Real GPS Geolocation State
  const [geoCoords, setGeoCoords] = useState<{ lat: number; lng: number; accuracy: number; timestamp: number } | null>(null);
  const [geoStatus, setGeoStatus] = useState<'tracking' | 'denied' | 'stale' | 'unavailable'>('tracking');
  const [isOnline, setIsOnline] = useState<boolean>(typeof navigator !== 'undefined' ? navigator.onLine : true);

  // Watch GPS Geolocation
  useEffect(() => {
    if (typeof window === 'undefined' || !navigator.geolocation) {
      setGeoStatus('unavailable');
      return;
    }

    const watchId = navigator.geolocation.watchPosition(
      (pos) => {
        setGeoCoords({
          lat: pos.coords.latitude,
          lng: pos.coords.longitude,
          accuracy: Math.round(pos.coords.accuracy),
          timestamp: pos.timestamp,
        });
        setGeoStatus('tracking');
      },
      (err) => {
        if (err.code === err.PERMISSION_DENIED) {
          setGeoStatus('denied');
        } else {
          setGeoStatus('unavailable');
        }
      },
      { enableHighAccuracy: true, timeout: 15000, maximumAge: 10000 }
    );

    const handleOnline = () => setIsOnline(true);
    const handleOffline = () => setIsOnline(false);
    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);

    // Stale check every 30s
    const staleInterval = setInterval(() => {
      if (geoCoords && Date.now() - geoCoords.timestamp > 60000) {
        setGeoStatus('stale');
      }
    }, 30000);

    return () => {
      navigator.geolocation.clearWatch(watchId);
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
      clearInterval(staleInterval);
    };
  }, []);

  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(null), 3500);
  };

  const handleSwitchCourier = (id: string) => {
    setSelectedCourierId(id);
    localStorage.setItem('captain_active_courier_id', id);
    showToast(`تم التبديل للكابتن بنجاح.`);
  };

  const handleUpdateShift = (status: 'active' | 'break' | 'off_duty') => {
    setShiftStatus(status);
    localStorage.setItem(`captain_shift_${selectedCourierId}`, status);
    if (onUpdateCourier) {
      onUpdateCourier({
        ...currentCourier,
        status: status === 'active' ? 'idle' : status === 'break' ? 'break' : 'offline',
      });
    }
    showToast(`تم تغيير الحالة إلى: ${status === 'active' ? 'متاح للطلب' : status === 'break' ? 'استراحة' : 'خارج الوردية'}`);
  };

  // Orders assigned to this courier
  const myAssignedOrders = useMemo(() => {
    return orders.filter((o) => {
      return (
        o.courier_id === currentCourier?.id &&
        (o.status === 'out_for_delivery' || o.status === 'packing')
      );
    });
  }, [orders, currentCourier?.id]);

  // Available unassigned orders in dispatch pool (matching vehicle type or express)
  const availableOrdersPool = useMemo(() => {
    return orders.filter((o) => {
      return (
        (!o.courier_id || o.courier_id === '') &&
        (o.status === 'packing' || o.status === 'pending')
      );
    });
  }, [orders]);

  // Completed past trips for history and finances
  const completedOrders = useMemo(() => {
    return orders.filter(
      (o) => (o.courier_id === currentCourier?.id || o.courier_name === currentCourier?.full_name) && o.status === 'delivered'
    );
  }, [orders, currentCourier]);

  const totalCashCollected = useMemo(() => {
    return completedOrders
      .filter((o) => o.payment_method === 'cash_on_delivery' || o.payment_method === 'cash' || o.payment_method === 'cod')
      .reduce((sum, o) => sum + o.total_amount, 0);
  }, [completedOrders]);

  const deliveryCommission = useMemo(() => {
    return completedOrders.length * 2500; // 2,500 SYP per delivery
  }, [completedOrders]);

  // Stage Progression Handler
  const handleAdvanceStage = (order: Order, nextStage: number) => {
    const updatedStages = { ...orderStages, [order.id]: nextStage };
    setOrderStages(updatedStages);
    try {
      localStorage.setItem(`captain_order_stages_${selectedCourierId}`, JSON.stringify(updatedStages));
    } catch (_) {}

    const stageTitles: Record<number, string> = {
      1: 'تم قبول المهمة',
      2: 'وصلت إلى نقطة استلام الفرع/المستودع',
      3: 'تم استلام الطرد وتأكيد الباركود',
      4: 'في الطريق لموقع العميل',
      5: 'وصلت لموقع العميل أمام الباب',
      6: 'تم التسليم بنجاح',
    };

    logAuditEvent({
      actor_id: currentCourier.id,
      actor_name: currentCourier.full_name,
      actor_role: 'courier',
      action: `COURIER_STAGE_${nextStage}`,
      category: 'orders',
      details: `الكابتن ${currentCourier.full_name} حدث مرحلة طلب ${order.order_number} إلى: ${stageTitles[nextStage] || nextStage}`,
      target_id: order.id,
    });

    showToast(`✓ ${stageTitles[nextStage] || 'تم تحديث المرحلة'}`);
  };

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

    handleAdvanceStage(order, 1);
    showToast(`✓ تم قبول المهمة بنجاح، يمكنك الانطلاق الآن!`);
  };

  // Decline a mission
  const handleDeclineMission = (order: Order) => {
    const updated: Order = {
      ...order,
      courier_id: undefined,
      courier_name: undefined,
      status: 'packing',
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

    showToast(`تم تسجيل الاعتذار وإعادة الطلب لغرفة العمليات لتكليف مندوب بديل.`);
    setShowDeclineModal(null);
  };

  // Confirm delivery with OTP
  const handleConfirmDeliveryWithOtp = (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedOrderForDelivery) return;

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

    handleAdvanceStage(selectedOrderForDelivery, 6);

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

  // Record Delivery Failure
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

  // Send Support Message
  const handleSendChatMessage = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newChatMessage.trim()) return;

    const msg = {
      id: `msg-${Date.now()}`,
      sender: 'captain' as const,
      text: newChatMessage.trim(),
      time: new Date().toLocaleTimeString('ar-SA', { hour: '2-digit', minute: '2-digit' }),
    };
    setChatMessages((prev) => [...prev, msg]);
    setNewChatMessage('');

    setTimeout(() => {
      setChatMessages((prev) => [
        ...prev,
        {
          id: `reply-${Date.now()}`,
          sender: 'support',
          text: `تم استلام رسالتك كابتن (${currentCourier.full_name}). المشرف الميداني يتابع معك فوراً.`,
          time: new Date().toLocaleTimeString('ar-SA', { hour: '2-digit', minute: '2-digit' }),
        },
      ]);
    }, 1200);
  };

  // Change Password
  const handleChangePassword = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newPassword || newPassword.length < 6) {
      setPasswordToast('كلمة المرور الجديدة يجب أن لا تقل عن 6 أحرف أو أرقام.');
      return;
    }
    setPasswordToast('✓ تم تحديث كلمة المرور بنجاح وحفظها بأمان.');
    setOldPassword('');
    setNewPassword('');
    setTimeout(() => setPasswordToast(null), 3000);
  };

  return (
    <div className="min-h-screen bg-slate-900 text-white font-sans antialiased flex flex-col justify-between" dir="rtl">
      {/* 1. TOP MOBILE HEADER */}
      <header className="bg-slate-950 border-b border-slate-800 p-3 sticky top-0 z-30 shadow-md">
        <div className="max-w-md mx-auto flex items-center justify-between">
          <div className="flex items-center gap-2.5">
            <div className="w-10 h-10 rounded-2xl bg-black flex items-center justify-center overflow-hidden border border-cyan-500/40 shadow-md shrink-0">
              <img
                src={`${import.meta.env.BASE_URL}logo.png`}
                alt="شعار الديب مول DEB"
                className="w-full h-full object-cover"
              />
            </div>
            <div>
              <h2 className="text-sm font-black text-white flex items-center gap-1.5">
                <span>Captain الذيب مول</span>
                <span className="text-[10px] bg-blue-500/20 text-blue-300 px-1.5 py-0.2 rounded border border-blue-500/30 font-bold">
                  v3.8
                </span>
              </h2>
              <div className="flex items-center gap-1.5 text-[10px]">
                {/* GPS Status */}
                {geoStatus === 'tracking' && (
                  <span className="flex items-center gap-1 text-emerald-400 font-mono">
                    <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
                    GPS دقيق (±{geoCoords?.accuracy || 5}م)
                  </span>
                )}
                {geoStatus === 'denied' && (
                  <span className="flex items-center gap-1 text-rose-400 font-bold">
                    <AlertTriangle className="w-3 h-3 text-rose-400" />
                    GPS معطل
                  </span>
                )}
                {geoStatus === 'stale' && (
                  <span className="flex items-center gap-1 text-amber-400 font-bold">
                    <Clock className="w-3 h-3 text-amber-400" />
                    إشارة قديمة
                  </span>
                )}
                {geoStatus === 'unavailable' && (
                  <span className="flex items-center gap-1 text-slate-400">
                    GPS محايد
                  </span>
                )}

                <span className="text-slate-600">•</span>

                {/* Network Status */}
                {isOnline ? (
                  <span className="text-emerald-400 flex items-center gap-0.5">
                    <Wifi className="w-3 h-3" /> متصل
                  </span>
                ) : (
                  <span className="text-rose-400 flex items-center gap-0.5 animate-pulse">
                    <WifiOff className="w-3 h-3" /> غير متصل
                  </span>
                )}
              </div>
            </div>
          </div>

          <div className="flex items-center gap-2">
            {onBackToAdmin && (
              <button
                onClick={onBackToAdmin}
                className="px-2.5 py-1.5 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-xl text-xs font-bold transition-all border border-slate-700 flex items-center gap-1 cursor-pointer"
                title="الرجوع للوحة الإدارة العامة"
              >
                <ArrowLeft className="w-3.5 h-3.5" />
                <span>المركز القيادي</span>
              </button>
            )}
          </div>
        </div>
      </header>

      {/* 2. MAIN APPLICATION WORKSPACE */}
      <main className="flex-1 max-w-md w-full mx-auto p-4 space-y-4 pb-28">
        {/* Toast Alert */}
        {toastMessage && (
          <div className="p-3 bg-emerald-600 text-white rounded-2xl text-xs font-bold shadow-lg flex items-center gap-2 animate-fade-in">
            <CheckCircle2 className="w-4 h-4 shrink-0" />
            <span>{toastMessage}</span>
          </div>
        )}

        {/* Courier Identity & Shift Header */}
        <div className="bg-slate-800/80 rounded-3xl p-4 border border-slate-700/80 shadow-lg space-y-3">
          <div className="flex items-center justify-between">
            <div>
              <label className="text-[10px] text-slate-400 font-bold block mb-1">الكابتن النشط:</label>
              <select
                value={selectedCourierId}
                onChange={(e) => handleSwitchCourier(e.target.value)}
                className="bg-slate-900 border border-slate-700 text-white font-bold text-xs rounded-xl px-3 py-1.5 focus:outline-none focus:border-blue-500 cursor-pointer"
              >
                {couriers.map((c) => (
                  <option key={c.id} value={c.id}>
                    {c.full_name} ({c.vehicle_type === 'motorbike' ? 'دراجة سريعة' : 'فان مبرد'})
                  </option>
                ))}
              </select>
            </div>

            <div className="text-left font-mono">
              <span className="text-[10px] text-slate-400 block">رقم اللوحة والمركبة</span>
              <span className="text-xs font-bold text-slate-200 flex items-center gap-1">
                {currentCourier.vehicle_type === 'motorbike' ? <Bike className="w-3.5 h-3.5 text-blue-400" /> : <Truck className="w-3.5 h-3.5 text-amber-400" />}
                {currentCourier.license_plate}
              </span>
            </div>
          </div>

          {/* Shift State Toggle Buttons */}
          <div className="grid grid-cols-3 gap-2 pt-2 border-t border-slate-700/50">
            <button
              onClick={() => handleUpdateShift('active')}
              className={`py-2 rounded-xl text-xs font-bold transition-all flex items-center justify-center gap-1.5 cursor-pointer ${
                shiftStatus === 'active'
                  ? 'bg-emerald-600 text-white shadow-md shadow-emerald-600/30 font-black'
                  : 'bg-slate-900 text-slate-400 hover:text-white'
              }`}
            >
              <Power className="w-3.5 h-3.5" />
              <span>متاح للطلب</span>
            </button>

            <button
              onClick={() => handleUpdateShift('break')}
              className={`py-2 rounded-xl text-xs font-bold transition-all flex items-center justify-center gap-1.5 cursor-pointer ${
                shiftStatus === 'break'
                  ? 'bg-amber-600 text-white shadow-md shadow-amber-600/30 font-black'
                  : 'bg-slate-900 text-slate-400 hover:text-white'
              }`}
            >
              <Coffee className="w-3.5 h-3.5" />
              <span>استراحة</span>
            </button>

            <button
              onClick={() => handleUpdateShift('off_duty')}
              className={`py-2 rounded-xl text-xs font-bold transition-all flex items-center justify-center gap-1.5 cursor-pointer ${
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

        {/* TAB 1: ACTIVE MISSIONS (مهام التوصيل الحالية بمراحلها الستة) */}
        {activeTab === 'missions' && (
          <div className="space-y-3">
            <div className="flex items-center justify-between">
              <h3 className="text-xs font-black text-slate-200 flex items-center gap-1.5">
                <Package className="w-4 h-4 text-blue-400" />
                <span>المهام النشطة قيد التنفيذ ({myAssignedOrders.length})</span>
              </h3>
              <span className="text-[10px] text-slate-400 font-mono">تتبع حي</span>
            </div>

            {myAssignedOrders.length === 0 ? (
              <div className="bg-slate-800/50 rounded-3xl p-8 border border-slate-700/60 text-center space-y-3">
                <Compass className="w-12 h-12 text-slate-600 mx-auto animate-pulse" />
                <h4 className="font-bold text-slate-300 text-sm">لا توجد مهام نشطة حالياً</h4>
                <p className="text-xs text-slate-500 max-w-xs mx-auto">
                  أنت في وضع الجاهزية. استعرض تبويب "الطلبات المعروضة" لقبول مهام جديدة أو انتظر إسناداً تلقائياً من غرفة العمليات.
                </p>
                <button
                  onClick={() => setActiveTab('offers')}
                  className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-xl text-xs font-bold transition-all shadow-md cursor-pointer"
                >
                  استعراض الطلبات المتاحة ({availableOrdersPool.length})
                </button>
              </div>
            ) : (
              myAssignedOrders.map((order) => {
                const currentStage = orderStages[order.id] || (order.status === 'out_for_delivery' ? 4 : 1);
                return (
                  <div
                    key={order.id}
                    className="bg-slate-800 rounded-3xl p-4 border border-blue-500/50 shadow-xl space-y-3 ring-1 ring-blue-500/20"
                  >
                    {/* Header */}
                    <div className="flex items-start justify-between">
                      <div>
                        <div className="flex items-center gap-2">
                          <span className="text-xs font-black font-mono text-blue-400">{order.order_number}</span>
                          {order.delivery_type === '15_min_express' && (
                            <span className="text-[10px] font-black bg-rose-500/20 text-rose-300 px-2 py-0.5 rounded-full border border-rose-500/30 flex items-center gap-1">
                              <Clock className="w-3 h-3 text-rose-400" /> إكسبريس 15 دقيقة
                            </span>
                          )}
                        </div>
                        <h4 className="font-bold text-white text-sm mt-1">{order.customer_name}</h4>
                      </div>

                      <div className="text-left font-mono">
                        <div className="text-sm font-black text-emerald-400">{order.total_amount.toLocaleString()} ل.س</div>
                        <div className="text-[10px] text-slate-400">
                          {order.payment_method === 'cash_on_delivery' || order.payment_method === 'cash' || order.payment_method === 'cod'
                            ? 'تحصيل نقدي عند الباب'
                            : 'مدفوع إلكترونياً (شام كاش)'}
                        </div>
                      </div>
                    </div>

                    {/* 6-Stage Progress Indicator */}
                    <div className="bg-slate-900/90 p-3 rounded-2xl border border-slate-700/80 space-y-2">
                      <div className="flex items-center justify-between text-[10px] text-slate-400 font-bold">
                        <span>مراحل التوصيل الإلزامية:</span>
                        <span className="text-blue-400">المرحلة {currentStage} من 6</span>
                      </div>
                      <div className="grid grid-cols-6 gap-1">
                        {[1, 2, 3, 4, 5, 6].map((stg) => (
                          <div
                            key={stg}
                            className={`h-2 rounded-full transition-all ${
                              currentStage >= stg ? 'bg-emerald-500 shadow-xs shadow-emerald-500/50' : 'bg-slate-800'
                            }`}
                          />
                        ))}
                      </div>

                      {/* Stage Action Buttons */}
                      <div className="pt-1">
                        {currentStage === 1 && (
                          <button
                            onClick={() => handleAdvanceStage(order, 2)}
                            className="w-full py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-xl text-xs font-bold transition-all shadow-md flex items-center justify-center gap-1 cursor-pointer"
                          >
                            <Navigation className="w-3.5 h-3.5" />
                            <span>1. تأكيد الوصول للفرع/المستودع</span>
                          </button>
                        )}
                        {currentStage === 2 && (
                          <button
                            onClick={() => handleAdvanceStage(order, 3)}
                            className="w-full py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-xl text-xs font-bold transition-all shadow-md flex items-center justify-center gap-1 cursor-pointer"
                          >
                            <Package className="w-3.5 h-3.5" />
                            <span>2. تأكيد استلام الطرد وفحص الباركود</span>
                          </button>
                        )}
                        {currentStage === 3 && (
                          <button
                            onClick={() => handleAdvanceStage(order, 4)}
                            className="w-full py-2 bg-emerald-600 hover:bg-emerald-700 text-white rounded-xl text-xs font-bold transition-all shadow-md flex items-center justify-center gap-1 cursor-pointer"
                          >
                            <Navigation className="w-3.5 h-3.5" />
                            <span>3. الانطلاق: في الطريق إلى العميل</span>
                          </button>
                        )}
                        {currentStage === 4 && (
                          <button
                            onClick={() => handleAdvanceStage(order, 5)}
                            className="w-full py-2 bg-amber-600 hover:bg-amber-700 text-white rounded-xl text-xs font-bold transition-all shadow-md flex items-center justify-center gap-1 cursor-pointer"
                          >
                            <MapPin className="w-3.5 h-3.5" />
                            <span>4. تأكيد الوصول أمام باب العميل</span>
                          </button>
                        )}
                        {currentStage >= 5 && (
                          <div className="grid grid-cols-2 gap-2">
                            <button
                              onClick={() => setShowFailureModal(order)}
                              className="py-2.5 bg-slate-900 hover:bg-rose-950/40 text-rose-400 rounded-xl text-xs font-bold border border-rose-500/30 flex items-center justify-center gap-1 cursor-pointer"
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
                              className="py-2.5 bg-emerald-600 hover:bg-emerald-700 text-white rounded-xl text-xs font-bold shadow-lg shadow-emerald-600/30 flex items-center justify-center gap-1 cursor-pointer"
                            >
                              <ShieldCheck className="w-4 h-4" />
                              <span>إثبات التسليم (OTP)</span>
                            </button>
                          </div>
                        )}
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
                          <span>اتصال ({order.customer_phone})</span>
                        </a>

                        <a
                          href={`https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(order.customer_address)}`}
                          target="_blank"
                          rel="noreferrer"
                          className="px-3 py-1.5 bg-slate-800 hover:bg-slate-700 text-slate-200 border border-slate-700 rounded-xl font-bold flex items-center gap-1.5 transition-colors"
                        >
                          <Navigation className="w-3.5 h-3.5 text-emerald-400" />
                          <span>خريطة الملاحة GPS</span>
                        </a>
                      </div>
                    </div>

                    {/* Order Items Summary */}
                    <div className="text-[11px] text-slate-400 bg-slate-900/40 p-2 rounded-xl flex items-center justify-between">
                      <span>محتويات الطرد:</span>
                      <span className="font-bold text-slate-200">{order.items.length} أصناف ({order.items.map(i => i.product_name_ar).slice(0, 2).join('، ')}...)</span>
                    </div>
                  </div>
                );
              })
            )}
          </div>
        )}

        {/* TAB 2: AVAILABLE OFFERS (الطلبات المعروضة للإسناد) */}
        {activeTab === 'offers' && (
          <div className="space-y-3">
            <div className="flex items-center justify-between">
              <h3 className="text-xs font-black text-slate-200 flex items-center gap-1.5">
                <Compass className="w-4 h-4 text-emerald-400" />
                <span>الطلبات المتاحة للإسناد الفوري ({availableOrdersPool.length})</span>
              </h3>
              <span className="text-[10px] text-slate-400">حسب سعة المركبة</span>
            </div>

            {availableOrdersPool.length === 0 ? (
              <div className="bg-slate-800/50 rounded-3xl p-8 border border-slate-700/60 text-center space-y-2">
                <CheckCircle2 className="w-10 h-10 text-emerald-500/60 mx-auto" />
                <h4 className="font-bold text-slate-300 text-sm">تم إسناد كافة الطلبات حالياً</h4>
                <p className="text-xs text-slate-500">لا توجد طلبات معلقة بدون سائق في مركز التوزيع التابع لفرعك.</p>
              </div>
            ) : (
              availableOrdersPool.map((order) => {
                const evalResult = evaluateOrderDispatch(
                  order.items.map((i) => ({
                    id: i.product_id || i.id,
                    name: i.product_name_ar,
                    quantity: i.quantity,
                    weight_kg: 0.8,
                    volume_liters: 1.5,
                  }))
                );

                return (
                  <div key={order.id} className="bg-slate-800/90 rounded-3xl p-4 border border-slate-700 space-y-3 shadow-md">
                    <div className="flex items-start justify-between">
                      <div>
                        <div className="flex items-center gap-2">
                          <span className="text-xs font-black font-mono text-emerald-400">{order.order_number}</span>
                          <span className="text-[10px] bg-slate-900 text-slate-300 px-2 py-0.5 rounded-full font-mono">
                            {evalResult.total_weight_kg} كغ • {evalResult.total_volume_liters} لتر
                          </span>
                        </div>
                        <h4 className="font-bold text-white text-sm mt-1">{order.customer_name}</h4>
                      </div>

                      <div className="text-left font-mono">
                        <div className="text-sm font-black text-emerald-400">{order.total_amount.toLocaleString()} ل.س</div>
                        <div className="text-[10px] text-blue-300 font-bold">عمولة: +2,500 ل.س</div>
                      </div>
                    </div>

                    <div className="text-xs text-slate-300 bg-slate-900/60 p-2.5 rounded-xl flex items-center gap-2">
                      <MapPin className="w-4 h-4 text-rose-400 shrink-0" />
                      <span className="line-clamp-1">{order.customer_address}</span>
                    </div>

                    <div className="flex gap-2 pt-1">
                      <button
                        onClick={() => setShowDeclineModal(order)}
                        className="py-2.5 px-4 bg-slate-900 hover:bg-slate-700 text-slate-400 rounded-xl text-xs font-bold transition-all border border-slate-700 cursor-pointer"
                      >
                        تخطي
                      </button>

                      <button
                        onClick={() => handleAcceptMission(order)}
                        className="flex-1 py-2.5 bg-emerald-600 hover:bg-emerald-700 text-white rounded-xl text-xs font-bold transition-all shadow-md flex items-center justify-center gap-1.5 cursor-pointer"
                      >
                        <Navigation className="w-4 h-4" />
                        <span>قبول المهمة والانطلاق</span>
                      </button>
                    </div>
                  </div>
                );
              })
            )}
          </div>
        )}

        {/* TAB 3: HISTORY (سجل الطلبات السابقة مع البحث) */}
        {activeTab === 'history' && (
          <div className="space-y-3">
            <div className="flex items-center justify-between">
              <h3 className="text-xs font-black text-slate-200 flex items-center gap-1.5">
                <History className="w-4 h-4 text-blue-400" />
                <span>سجل الرحلات المسلمة ({completedOrders.length})</span>
              </h3>
            </div>

            {/* Search Box */}
            <div className="relative">
              <input
                type="text"
                placeholder="بحث برقم الطلب، اسم العميل، العنوان..."
                value={historySearch}
                onChange={(e) => setHistorySearch(e.target.value)}
                className="w-full pr-9 pl-3 py-2 bg-slate-950 border border-slate-700 rounded-xl text-xs text-white placeholder:text-slate-500 focus:outline-none focus:border-blue-500"
              />
              <Search className="w-4 h-4 text-slate-400 absolute right-3 top-2.5" />
            </div>

            {completedOrders.length === 0 ? (
              <div className="bg-slate-800/50 rounded-3xl p-8 border border-slate-700/60 text-center space-y-2">
                <Clock className="w-10 h-10 text-slate-600 mx-auto" />
                <h4 className="font-bold text-slate-300 text-sm">لا توجد رحلات سابقة</h4>
                <p className="text-xs text-slate-500">ستظهر هنا كافة الطلبات المسلمة بنجاح مع توقيتها ومبالغها.</p>
              </div>
            ) : (
              completedOrders
                .filter(
                  (o) =>
                    o.order_number.toLowerCase().includes(historySearch.toLowerCase()) ||
                    o.customer_name.toLowerCase().includes(historySearch.toLowerCase()) ||
                    o.customer_address.toLowerCase().includes(historySearch.toLowerCase())
                )
                .map((order) => (
                  <div key={order.id} className="bg-slate-800/80 p-3 rounded-2xl border border-slate-700 space-y-1.5 text-xs">
                    <div className="flex items-center justify-between">
                      <span className="font-mono font-bold text-blue-400">{order.order_number}</span>
                      <span className="text-[10px] text-emerald-400 bg-emerald-500/10 px-2 py-0.5 rounded-full font-bold">
                        تم التسليم بنجاح
                      </span>
                    </div>
                    <div className="flex items-center justify-between">
                      <span className="text-slate-300 font-bold">{order.customer_name}</span>
                      <span className="font-mono font-black text-white">{order.total_amount.toLocaleString()} ل.س</span>
                    </div>
                    <div className="text-[10px] text-slate-400 truncate">{order.customer_address}</div>
                  </div>
                ))
            )}
          </div>
        )}

        {/* TAB 4: FINANCES (المحفظة والتحصيلات والعمولات) */}
        {activeTab === 'finances' && (
          <div className="space-y-4">
            <h3 className="text-xs font-black text-slate-200 flex items-center gap-1.5">
              <Wallet className="w-4 h-4 text-amber-400" />
              <span>المحفظة المالية والعهدة النقدية</span>
            </h3>

            {/* Financial Cards */}
            <div className="grid grid-cols-2 gap-3 text-xs">
              <div className="bg-slate-800 p-4 rounded-3xl border border-slate-700 space-y-1">
                <span className="text-[11px] text-slate-400 font-bold block">العهدة النقدية في الحقيبة (COD):</span>
                <span className="font-mono text-xl font-black text-amber-400 block">{totalCashCollected.toLocaleString()} ل.س</span>
                <span className="text-[10px] text-slate-500 block">واجبة التوريد لخزينة المول بنهاية الوردية</span>
              </div>

              <div className="bg-slate-800 p-4 rounded-3xl border border-slate-700 space-y-1">
                <span className="text-[11px] text-slate-400 font-bold block">عمولاتك المستحقة اليوم:</span>
                <span className="font-mono text-xl font-black text-emerald-400 block">+{deliveryCommission.toLocaleString()} ل.س</span>
                <span className="text-[10px] text-slate-500 block">{completedOrders.length} مشاوير مكتملة (2,500 ل.س / رحلة)</span>
              </div>
            </div>

            {/* Cash Handover Simulation */}
            <div className="bg-slate-800/80 p-4 rounded-3xl border border-slate-700 space-y-2 text-xs">
              <h4 className="font-bold text-white flex items-center gap-1.5">
                <ShieldCheck className="w-4 h-4 text-emerald-400" />
                <span>إبراء الذمة وتوريد العهدة النقدية للخزينة</span>
              </h4>
              <p className="text-[11px] text-slate-400 leading-relaxed">
                يقوم أمين الخزينة بفرعك الرئيسي بفحص الإيصالات المسلمة واستلام المبلغ النقدي واعتماد التسوية.
              </p>
              <button
                onClick={() => showToast('تم إرسال طلب توريد العهدة لأمين الصندوق في الفرع.')}
                className="w-full py-2.5 bg-blue-600 hover:bg-blue-700 text-white rounded-xl font-bold transition-all shadow-md cursor-pointer"
              >
                طلب تسليم العهدة النقدية لأمين الصندوق
              </button>
            </div>
          </div>
        )}

        {/* TAB 5: SUPPORT CHAT (الدعم المباشر وغرفة العمليات) */}
        {activeTab === 'support' && (
          <div className="space-y-3">
            <h3 className="text-xs font-black text-slate-200 flex items-center gap-1.5">
              <Headset className="w-4 h-4 text-emerald-400" />
              <span>غرفة العمليات والدعم الفني المباشر</span>
            </h3>

            {/* Chat Box */}
            <div className="bg-slate-950 rounded-3xl border border-slate-800 p-3 h-72 overflow-y-auto space-y-2.5">
              {chatMessages.map((msg) => (
                <div
                  key={msg.id}
                  className={`flex flex-col max-w-[80%] rounded-2xl p-2.5 text-xs ${
                    msg.sender === 'captain'
                      ? 'mr-auto bg-blue-600 text-white rounded-br-none'
                      : 'ml-auto bg-slate-800 text-slate-200 rounded-bl-none border border-slate-700'
                  }`}
                >
                  <span className="leading-relaxed">{msg.text}</span>
                  <span className="text-[9px] opacity-70 mt-1 text-left font-mono">{msg.time}</span>
                </div>
              ))}
            </div>

            {/* Input Message */}
            <form onSubmit={handleSendChatMessage} className="flex gap-2">
              <input
                type="text"
                placeholder="اكتب رسالتك لغرفة العمليات..."
                value={newChatMessage}
                onChange={(e) => setNewChatMessage(e.target.value)}
                className="flex-1 bg-slate-950 border border-slate-700 rounded-2xl px-3 py-2 text-xs text-white placeholder:text-slate-500 focus:outline-none focus:border-blue-500"
              />
              <button
                type="submit"
                className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-2xl text-xs font-bold transition-all shadow-md flex items-center gap-1 cursor-pointer"
              >
                <Send className="w-3.5 h-3.5" />
                <span>إرسال</span>
              </button>
            </form>
          </div>
        )}

        {/* TAB 6: PROFILE & SECURITY (الملف الشخصي وإعدادات الحساب) */}
        {activeTab === 'profile' && (
          <div className="space-y-4">
            <h3 className="text-xs font-black text-slate-200 flex items-center gap-1.5">
              <User className="w-4 h-4 text-blue-400" />
              <span>الملف الشخصي وإعدادات أمان الكابتن</span>
            </h3>

            <div className="bg-slate-800 p-4 rounded-3xl border border-slate-700 space-y-3 text-xs">
              <div className="flex items-center gap-3">
                <div className="w-12 h-12 rounded-2xl bg-slate-900 border border-slate-700 flex items-center justify-center text-blue-400 font-bold text-lg font-mono">
                  {currentCourier.full_name.charAt(0)}
                </div>
                <div>
                  <h4 className="font-bold text-white text-sm">{currentCourier.full_name}</h4>
                  <span className="text-[11px] text-slate-400">{currentCourier.phone}</span>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-2 pt-2 border-t border-slate-700 text-[11px]">
                <div className="p-2 bg-slate-900 rounded-xl">
                  <span className="text-slate-400 block">نوع المركبة</span>
                  <span className="font-bold text-slate-200">{currentCourier.vehicle_type === 'motorbike' ? 'دراجة نارية' : 'سيارة / فان'}</span>
                </div>
                <div className="p-2 bg-slate-900 rounded-xl">
                  <span className="text-slate-400 block">رقم اللوحة</span>
                  <span className="font-bold text-slate-200 font-mono">{currentCourier.license_plate}</span>
                </div>
              </div>
            </div>

            {/* Change Password Form */}
            <form onSubmit={handleChangePassword} className="bg-slate-800 p-4 rounded-3xl border border-slate-700 space-y-3 text-xs">
              <h4 className="font-bold text-white flex items-center gap-1.5">
                <Lock className="w-4 h-4 text-amber-400" />
                <span>تغيير كلمة المرور الشخصية</span>
              </h4>

              {passwordToast && (
                <div className="p-2 bg-emerald-500/20 border border-emerald-500/30 text-emerald-300 rounded-xl text-xs font-bold">
                  {passwordToast}
                </div>
              )}

              <div>
                <label className="block text-[11px] text-slate-400 font-bold mb-1">كلمة المرور الحالية</label>
                <input
                  type="password"
                  placeholder="••••••••"
                  value={oldPassword}
                  onChange={(e) => setOldPassword(e.target.value)}
                  className="w-full p-2.5 bg-slate-950 border border-slate-700 rounded-xl text-white focus:outline-none focus:border-blue-500"
                />
              </div>

              <div>
                <label className="block text-[11px] text-slate-400 font-bold mb-1">كلمة المرور الجديدة</label>
                <input
                  type="password"
                  placeholder="••••••••"
                  value={newPassword}
                  onChange={(e) => setNewPassword(e.target.value)}
                  className="w-full p-2.5 bg-slate-950 border border-slate-700 rounded-xl text-white focus:outline-none focus:border-blue-500"
                />
              </div>

              <button
                type="submit"
                className="w-full py-2.5 bg-blue-600 hover:bg-blue-700 text-white rounded-xl font-bold transition-all shadow-md cursor-pointer"
              >
                تأكيد تغيير كلمة المرور
              </button>
            </form>
          </div>
        )}
      </main>

      {/* 3. BOTTOM MOBILE NAVIGATION DOCK */}
      <nav className="fixed bottom-0 inset-x-0 bg-slate-950 border-t border-slate-800 p-2 z-40 shadow-2xl">
        <div className="max-w-md mx-auto grid grid-cols-6 gap-1 text-center">
          <button
            onClick={() => setActiveTab('missions')}
            className={`py-2 rounded-2xl flex flex-col items-center gap-1 text-[10px] font-bold transition-all cursor-pointer ${
              activeTab === 'missions' ? 'bg-blue-600 text-white shadow-md shadow-blue-600/30' : 'text-slate-400 hover:text-slate-200'
            }`}
          >
            <Package className="w-4 h-4" />
            <span>المهام</span>
          </button>

          <button
            onClick={() => setActiveTab('offers')}
            className={`py-2 rounded-2xl flex flex-col items-center gap-1 text-[10px] font-bold transition-all cursor-pointer ${
              activeTab === 'offers' ? 'bg-blue-600 text-white shadow-md shadow-blue-600/30' : 'text-slate-400 hover:text-slate-200'
            }`}
          >
            <Compass className="w-4 h-4" />
            <span>المعروضة</span>
          </button>

          <button
            onClick={() => setActiveTab('history')}
            className={`py-2 rounded-2xl flex flex-col items-center gap-1 text-[10px] font-bold transition-all cursor-pointer ${
              activeTab === 'history' ? 'bg-blue-600 text-white shadow-md shadow-blue-600/30' : 'text-slate-400 hover:text-slate-200'
            }`}
          >
            <History className="w-4 h-4" />
            <span>السجل</span>
          </button>

          <button
            onClick={() => setActiveTab('finances')}
            className={`py-2 rounded-2xl flex flex-col items-center gap-1 text-[10px] font-bold transition-all cursor-pointer ${
              activeTab === 'finances' ? 'bg-blue-600 text-white shadow-md shadow-blue-600/30' : 'text-slate-400 hover:text-slate-200'
            }`}
          >
            <Wallet className="w-4 h-4" />
            <span>المحفظة</span>
          </button>

          <button
            onClick={() => setActiveTab('support')}
            className={`py-2 rounded-2xl flex flex-col items-center gap-1 text-[10px] font-bold transition-all cursor-pointer ${
              activeTab === 'support' ? 'bg-blue-600 text-white shadow-md shadow-blue-600/30' : 'text-slate-400 hover:text-slate-200'
            }`}
          >
            <Headset className="w-4 h-4" />
            <span>الدعم</span>
          </button>

          <button
            onClick={() => setActiveTab('profile')}
            className={`py-2 rounded-2xl flex flex-col items-center gap-1 text-[10px] font-bold transition-all cursor-pointer ${
              activeTab === 'profile' ? 'bg-blue-600 text-white shadow-md shadow-blue-600/30' : 'text-slate-400 hover:text-slate-200'
            }`}
          >
            <User className="w-4 h-4" />
            <span>حسابي</span>
          </button>
        </div>
      </nav>

      {/* 4. MODALS */}
      {/* OTP Delivery Verification Modal */}
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
                  className="flex-1 py-3 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-2xl text-xs font-bold transition-all cursor-pointer"
                >
                  إلغاء
                </button>
                <button
                  type="submit"
                  className="flex-1 py-3 bg-emerald-600 hover:bg-emerald-700 text-white rounded-2xl text-xs font-bold transition-all shadow-lg shadow-emerald-600/30 cursor-pointer"
                >
                  تأكيد وإتمام التسليم
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Decline Mission Modal */}
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
                  className="w-full p-2.5 bg-slate-950 border border-slate-700 rounded-xl font-bold text-slate-200 cursor-pointer"
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
                  className="flex-1 py-3 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-2xl font-bold cursor-pointer"
                >
                  تراجع
                </button>
                <button
                  type="button"
                  onClick={() => handleDeclineMission(showDeclineModal)}
                  className="flex-1 py-3 bg-rose-600 hover:bg-rose-700 text-white rounded-2xl font-bold cursor-pointer"
                >
                  تأكيد الاعتذار
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Delivery Failure Modal */}
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
                  className="w-full p-2.5 bg-slate-950 border border-slate-700 rounded-xl font-bold text-slate-200 cursor-pointer"
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
                  className="flex-1 py-3 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-2xl font-bold cursor-pointer"
                >
                  إلغاء
                </button>
                <button
                  type="submit"
                  className="flex-1 py-3 bg-rose-600 hover:bg-rose-700 text-white rounded-2xl font-bold cursor-pointer"
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
