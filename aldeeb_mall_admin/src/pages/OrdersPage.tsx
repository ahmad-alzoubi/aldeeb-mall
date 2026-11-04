import React, { useState, useEffect } from 'react';
import { 
  Search, 
  Eye, 
  MapPin, 
  Phone, 
  X,
  PackageCheck,
  Receipt,
  Clock,
  CheckCircle2,
  AlertTriangle,
  XCircle,
  Truck,
  UserCheck,
  RotateCcw,
  RefreshCw,
  History,
  ShieldAlert
} from 'lucide-react';
import { Order, OrderStatus, Courier, StaffMember, OrderStatusHistoryItem } from '../types';
import { InvoiceModal } from '../components/InvoiceModal';
import { 
  ORDER_STATUS_LABELS, 
  updateOrderStatusAtomic, 
  fetchOrderTimeline,
  getAllowedNextStatuses
} from '../lib/ordersApi';

interface OrdersPageProps {
  orders: Order[];
  onUpdateOrderStatus: (
    orderId: string, 
    status: OrderStatus, 
    options?: {
      reason?: string;
      notes?: string;
      courierId?: string;
      courierName?: string;
      courierPhone?: string;
      expectedVersion?: number;
    }
  ) => Promise<boolean | void>;
  currentUser?: StaffMember;
  couriers?: Courier[];
  onRefreshOrders?: () => Promise<void>;
}

export const OrdersPage: React.FC<OrdersPageProps> = ({ 
  orders, 
  onUpdateOrderStatus,
  currentUser,
  couriers = [],
  onRefreshOrders
}) => {
  const [filterStatus, setFilterStatus] = useState<string>('all');
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [selectedOrder, setSelectedOrder] = useState<Order | null>(null);
  const [invoiceOrder, setInvoiceOrder] = useState<Order | null>(null);

  // Modals state
  const [timelineOrder, setTimelineOrder] = useState<Order | null>(null);
  const [timelineItems, setTimelineItems] = useState<OrderStatusHistoryItem[]>([]);
  const [isLoadingTimeline, setIsLoadingTimeline] = useState<boolean>(false);

  const [cancelModalOrder, setCancelModalOrder] = useState<Order | null>(null);
  const [cancelReason, setCancelReason] = useState<string>('طلب العميل إلغاء الطلب');
  const [cancelCustomReason, setCancelCustomReason] = useState<string>('');
  const [isProcessingCancel, setIsProcessingCancel] = useState<boolean>(false);

  const [failModalOrder, setFailModalOrder] = useState<Order | null>(null);
  const [failReason, setFailReason] = useState<string>('تعذر الوصول للعميل والهاتف مغلق');
  const [failCustomReason, setFailCustomReason] = useState<string>('');
  const [isProcessingFail, setIsProcessingFail] = useState<boolean>(false);

  const [assignModalOrder, setAssignModalOrder] = useState<Order | null>(null);
  const [selectedCourierId, setSelectedCourierId] = useState<string>('');
  const [isProcessingAssign, setIsProcessingAssign] = useState<boolean>(false);

  const [actionError, setActionError] = useState<string | null>(null);

  // Fetch timeline whenever timelineOrder changes
  useEffect(() => {
    let isMounted = true;
    if (timelineOrder) {
      setIsLoadingTimeline(true);
      fetchOrderTimeline(timelineOrder.id)
        .then((items) => {
          if (isMounted) {
            setTimelineItems(items);
            setIsLoadingTimeline(false);
          }
        })
        .catch(() => {
          if (isMounted) setIsLoadingTimeline(false);
        });
    } else {
      setTimelineItems([]);
    }
    return () => {
      isMounted = false;
    };
  }, [timelineOrder]);

  const filteredOrders = orders.filter((o) => {
    const matchesStatus = filterStatus === 'all' || o.status === filterStatus;
    const query = searchQuery.toLowerCase().trim();
    const matchesSearch = 
      !query ||
      o.order_number.toLowerCase().includes(query) ||
      o.customer_name.toLowerCase().includes(query) ||
      o.customer_phone.includes(query) ||
      (o.customer_address && o.customer_address.toLowerCase().includes(query)) ||
      (o.notes && o.notes.toLowerCase().includes(query));
    return matchesStatus && matchesSearch;
  });

  const getStatusBadge = (status: OrderStatus) => {
    const meta = ORDER_STATUS_LABELS[status] || {
      ar: status,
      en: status,
      badgeClass: 'bg-slate-100 text-slate-800 border-slate-200'
    };
    return (
      <span className={`px-2.5 py-1 rounded-lg text-xs font-bold border ${meta.badgeClass} inline-flex items-center gap-1`}>
        {status === 'delivered' && <CheckCircle2 className="w-3 h-3 text-emerald-600" />}
        {status === 'cancelled' && <XCircle className="w-3 h-3 text-rose-600" />}
        {status === 'failed' && <AlertTriangle className="w-3 h-3 text-amber-600" />}
        {status === 'out_for_delivery' && <Truck className="w-3 h-3 text-purple-600" />}
        {meta.ar}
      </span>
    );
  };

  const handleSimpleTransition = async (order: Order, newStatus: OrderStatus, notes?: string) => {
    setActionError(null);
    try {
      const res = await updateOrderStatusAtomic({
        orderId: order.id,
        newStatus,
        expectedVersion: order.version,
        notes: notes || `تحديث إلى ${newStatus}`,
        staffId: currentUser?.id,
        staffName: currentUser?.full_name || 'موظف الإدارة',
        staffRole: currentUser?.role || 'super_admin'
      });

      if (!res.success) {
        setActionError(res.error || 'تعذر تحديث حالة الطلب');
        return;
      }

      await onUpdateOrderStatus(order.id, newStatus, {
        notes,
        expectedVersion: order.version
      });

      if (onRefreshOrders) {
        await onRefreshOrders();
      }
    } catch (e: any) {
      setActionError(e?.message || 'خطأ أثناء تنفيذ الإجراء');
    }
  };

  const handleConfirmCancel = async () => {
    if (!cancelModalOrder) return;
    const finalReason = cancelReason === 'أخرى' ? cancelCustomReason.trim() : cancelReason;
    if (!finalReason) {
      setActionError('يرجى تحديد أو كتابة سبب الإلغاء بدقة.');
      return;
    }

    setIsProcessingCancel(true);
    setActionError(null);

    try {
      const res = await updateOrderStatusAtomic({
        orderId: cancelModalOrder.id,
        newStatus: 'cancelled',
        expectedVersion: cancelModalOrder.version,
        reason: finalReason,
        staffId: currentUser?.id,
        staffName: currentUser?.full_name || 'موظف الإدارة',
        staffRole: currentUser?.role || 'super_admin'
      });

      if (!res.success) {
        setActionError(res.error || 'فشل إلغاء الطلب');
        setIsProcessingCancel(false);
        return;
      }

      await onUpdateOrderStatus(cancelModalOrder.id, 'cancelled', {
        reason: finalReason,
        expectedVersion: cancelModalOrder.version
      });

      setCancelModalOrder(null);
      setCancelCustomReason('');
      setIsProcessingCancel(false);

      if (onRefreshOrders) {
        await onRefreshOrders();
      }
    } catch (e: any) {
      setActionError(e?.message || 'خطأ أثناء إلغاء الطلب');
      setIsProcessingCancel(false);
    }
  };

  const handleConfirmFail = async () => {
    if (!failModalOrder) return;
    const finalReason = failReason === 'أخرى' ? failCustomReason.trim() : failReason;
    if (!finalReason) {
      setActionError('يرجى تحديد أو كتابة سبب الإخفاق بدقة.');
      return;
    }

    setIsProcessingFail(true);
    setActionError(null);

    try {
      const res = await updateOrderStatusAtomic({
        orderId: failModalOrder.id,
        newStatus: 'failed',
        expectedVersion: failModalOrder.version,
        reason: finalReason,
        staffId: currentUser?.id,
        staffName: currentUser?.full_name || 'موظف الإدارة',
        staffRole: currentUser?.role || 'super_admin'
      });

      if (!res.success) {
        setActionError(res.error || 'فشل تسجيل إخفاق التسليم');
        setIsProcessingFail(false);
        return;
      }

      await onUpdateOrderStatus(failModalOrder.id, 'failed', {
        reason: finalReason,
        expectedVersion: failModalOrder.version
      });

      setFailModalOrder(null);
      setFailCustomReason('');
      setIsProcessingFail(false);

      if (onRefreshOrders) {
        await onRefreshOrders();
      }
    } catch (e: any) {
      setActionError(e?.message || 'خطأ أثناء تسجيل الإخفاق');
      setIsProcessingFail(false);
    }
  };

  const handleConfirmAssign = async () => {
    if (!assignModalOrder || !selectedCourierId) {
      setActionError('يرجى اختيار الكابتن أو المندوب المتاح.');
      return;
    }

    const courier = couriers.find((c) => c.id === selectedCourierId);
    if (!courier) {
      setActionError('الكابتن المختار غير موجود.');
      return;
    }

    setIsProcessingAssign(true);
    setActionError(null);

    try {
      const res = await updateOrderStatusAtomic({
        orderId: assignModalOrder.id,
        newStatus: 'assigned',
        expectedVersion: assignModalOrder.version,
        courierId: courier.id,
        courierName: courier.full_name,
        courierPhone: courier.phone,
        notes: `تم تعيين الكابتن ${courier.full_name} (${courier.phone})`,
        staffId: currentUser?.id,
        staffName: currentUser?.full_name || 'مسؤول الإرسال اللوجستي',
        staffRole: currentUser?.role || 'super_admin'
      });

      if (!res.success) {
        setActionError(res.error || 'فشل تخصيص المندوب للطلب');
        setIsProcessingAssign(false);
        return;
      }

      await onUpdateOrderStatus(assignModalOrder.id, 'assigned', {
        courierId: courier.id,
        courierName: courier.full_name,
        courierPhone: courier.phone,
        expectedVersion: assignModalOrder.version
      });

      setAssignModalOrder(null);
      setSelectedCourierId('');
      setIsProcessingAssign(false);

      if (onRefreshOrders) {
        await onRefreshOrders();
      }
    } catch (e: any) {
      setActionError(e?.message || 'خطأ أثناء تخصيص السائق');
      setIsProcessingAssign(false);
    }
  };

  return (
    <div className="space-y-6">
      {/* Action Error Banner */}
      {actionError && (
        <div className="p-4 bg-rose-50 border border-rose-200 rounded-2xl flex items-center justify-between text-rose-800 text-xs font-bold animate-in fade-in">
          <div className="flex items-center gap-2">
            <ShieldAlert className="w-5 h-5 text-rose-600 shrink-0" />
            <span>{actionError}</span>
          </div>
          <button 
            onClick={() => setActionError(null)} 
            className="p-1 hover:bg-rose-100 rounded-lg"
          >
            <X className="w-4 h-4 text-rose-600" />
          </button>
        </div>
      )}

      {/* Controls Bar: Filters & Search */}
      <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-sm flex flex-col md:flex-row items-stretch md:items-center justify-between gap-4">
        {/* Status Filters */}
        <div className="flex items-center gap-2 overflow-x-auto pb-1 md:pb-0 w-full md:w-auto scrollbar-thin">
          {[
            { id: 'all', label: 'كافة الطلبات' },
            { id: 'pending', label: 'الجديدة (قيد المراجعة)' },
            { id: 'confirmed', label: 'المؤكدة' },
            { id: 'packing', label: 'قيد التجهيز بالمستودع' },
            { id: 'assigned', label: 'مخصصة لسائق' },
            { id: 'out_for_delivery', label: 'مع المندوب' },
            { id: 'delivered', label: 'تم التسليم' },
            { id: 'cancelled', label: 'الملغاة (مسترجعة)' },
            { id: 'failed', label: 'تعذر التسليم' },
          ].map((tab) => (
            <button
              key={tab.id}
              onClick={() => setFilterStatus(tab.id)}
              className={`px-3.5 py-2 rounded-xl text-xs font-bold transition-all whitespace-nowrap shrink-0 ${
                filterStatus === tab.id
                  ? 'bg-blue-600 text-white shadow-md shadow-blue-600/30'
                  : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
              }`}
            >
              {tab.label}
            </button>
          ))}
        </div>

        {/* Search and Refresh */}
        <div className="flex items-center gap-2 shrink-0">
          {onRefreshOrders && (
            <button
              onClick={() => onRefreshOrders()}
              className="p-2 bg-slate-100 hover:bg-slate-200 text-slate-700 rounded-xl transition-colors text-xs font-bold flex items-center gap-1.5 shrink-0"
              title="تحديث قائمة الطلبات الآن"
            >
              <RefreshCw className="w-4 h-4 text-slate-500" />
              <span>تحديث</span>
            </button>
          )}

          <div className="relative w-full md:w-80 shrink-0">
            <input
              type="text"
              placeholder="بحث برقم الطلب، اسم العميل، الهاتف، العنوان..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pr-10 pl-4 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-medium focus:outline-none focus:border-blue-600 focus:bg-white transition-all"
            />
            <Search className="w-4 h-4 text-slate-400 absolute right-3.5 top-2.5" />
          </div>
        </div>
      </div>

      {/* Orders Table */}
      <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-right border-collapse">
            <thead className="bg-slate-50/80 border-b border-slate-200 text-slate-500 text-xs font-extrabold whitespace-nowrap">
              <tr>
                <th className="p-4 min-w-[140px]">رقم الطلب والإصدار</th>
                <th className="p-4 min-w-[200px]">العميل والموقع</th>
                <th className="p-4 min-w-[130px]">الفرع والتوصيل</th>
                <th className="p-4 min-w-[110px]">طريقة الدفع</th>
                <th className="p-4 min-w-[130px]">المبلغ الإجمالي</th>
                <th className="p-4 min-w-[150px]">حالة الطلب</th>
                <th className="p-4 min-w-[240px] text-center">الإجراءات وانتقال الحالة</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 text-xs">
              {filteredOrders.length === 0 ? (
                <tr>
                  <td colSpan={7} className="p-8 text-center text-slate-400 font-semibold">
                    لا توجد طلبات مطابقة للبحث أو التصفية الحالية
                  </td>
                </tr>
              ) : (
                filteredOrders.map((order) => {
                  const allowed = getAllowedNextStatuses(order.status, currentUser?.role);
                  return (
                    <tr key={order.id} className="hover:bg-slate-50/60 transition-colors">
                      <td className="p-4 font-mono font-extrabold text-blue-600 whitespace-nowrap">
                        <div className="flex items-center gap-1.5">
                          <span>{order.order_number}</span>
                          {order.version && (
                            <span className="px-1.5 py-0.5 bg-slate-100 text-slate-500 rounded text-[10px] font-mono">
                              v{order.version}
                            </span>
                          )}
                        </div>
                        <span className="block text-[10px] text-slate-400 font-normal">{order.created_at}</span>
                      </td>

                      <td className="p-4 min-w-[200px]">
                        <p className="font-extrabold text-slate-800">{order.customer_name}</p>
                        <p className="text-slate-500 flex items-center gap-1 text-[11px] mt-0.5">
                          <MapPin className="w-3 h-3 text-slate-400 shrink-0" />
                          <span className="truncate max-w-[220px]" title={order.customer_address}>
                            {order.customer_address}
                          </span>
                        </p>
                        {order.courier_name && (
                          <p className="text-[10px] text-purple-700 font-bold flex items-center gap-1 mt-1">
                            <Truck className="w-3 h-3 text-purple-600" />
                            الكابتن: {order.courier_name}
                          </p>
                        )}
                      </td>

                      <td className="p-4 whitespace-nowrap">
                        <span className="font-bold text-slate-700">{order.branch_name || 'الفرع الرئيسي'}</span>
                        <p className="text-[10px] text-slate-400 flex items-center gap-1 mt-0.5">
                          <Clock className="w-3 h-3" />
                          {order.delivery_slot}
                        </p>
                      </td>

                      <td className="p-4 whitespace-nowrap">
                        <span className="font-bold text-slate-700">{order.payment_method}</span>
                      </td>

                      <td className="p-4 font-extrabold text-blue-900 whitespace-nowrap">
                        {order.total_amount.toFixed(2)} ل.س
                        {order.loyalty_discount > 0 && (
                          <p className="text-[10px] text-emerald-600 font-bold">
                            وفر {order.loyalty_discount.toFixed(2)} ل.س بالنقاط
                          </p>
                        )}
                      </td>

                      <td className="p-4 whitespace-nowrap">
                        {getStatusBadge(order.status)}
                        {order.status === 'cancelled' && order.cancellation_reason && (
                          <p className="text-[10px] text-rose-600 mt-1 max-w-[140px] truncate" title={order.cancellation_reason}>
                            السبب: {order.cancellation_reason}
                          </p>
                        )}
                        {order.status === 'failed' && order.failure_reason && (
                          <p className="text-[10px] text-slate-600 mt-1 max-w-[140px] truncate" title={order.failure_reason}>
                            السبب: {order.failure_reason}
                          </p>
                        )}
                      </td>

                      <td className="p-4 whitespace-nowrap">
                        <div className="flex items-center justify-center gap-1.5 flex-wrap max-w-[280px]">
                          {/* Details Eye */}
                          <button
                            onClick={() => setSelectedOrder(order)}
                            className="p-1.5 text-slate-600 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors border border-slate-200"
                            title="عرض تفاصيل الطلب والفرز"
                          >
                            <Eye className="w-3.5 h-3.5" />
                          </button>

                          {/* Timeline / Audit Ledger */}
                          <button
                            onClick={() => setTimelineOrder(order)}
                            className="p-1.5 text-slate-600 hover:text-purple-600 hover:bg-purple-50 rounded-lg transition-colors border border-slate-200"
                            title="السجل الزمني وتدقيق الحالات"
                          >
                            <History className="w-3.5 h-3.5 text-purple-600" />
                          </button>

                          {/* Print Tax Invoice */}
                          <button
                            onClick={() => setInvoiceOrder(order)}
                            className="p-1.5 text-slate-600 hover:text-emerald-600 hover:bg-emerald-50 rounded-lg transition-colors border border-slate-200"
                            title="طباعة فاتورة ضريبية رسمية"
                          >
                            <Receipt className="w-3.5 h-3.5 text-emerald-600" />
                          </button>

                          {/* Dynamic Transition Action Buttons */}
                          {allowed.includes('confirmed') && (
                            <button
                              onClick={() => handleSimpleTransition(order, 'confirmed', 'تأكيد من الإدارة')}
                              className="px-2 py-1 bg-blue-600 hover:bg-blue-700 text-white rounded-lg text-[11px] font-bold transition-colors shadow-xs"
                            >
                              تأكيد
                            </button>
                          )}

                          {allowed.includes('packing') && (
                            <button
                              onClick={() => handleSimpleTransition(order, 'packing', 'بدء تجهيز الطلب بالمستودع')}
                              className="px-2 py-1 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg text-[11px] font-bold transition-colors shadow-xs"
                            >
                              تجهيز
                            </button>
                          )}

                          {allowed.includes('assigned') && (
                            <button
                              onClick={() => {
                                setAssignModalOrder(order);
                                setSelectedCourierId(order.courier_id || '');
                              }}
                              className="px-2 py-1 bg-cyan-600 hover:bg-cyan-700 text-white rounded-lg text-[11px] font-bold transition-colors shadow-xs flex items-center gap-1"
                            >
                              <UserCheck className="w-3 h-3" />
                              <span>تعيين سائق</span>
                            </button>
                          )}

                          {allowed.includes('out_for_delivery') && (
                            <button
                              onClick={() => handleSimpleTransition(order, 'out_for_delivery', 'انطلاق المندوب للتوصيل')}
                              className="px-2 py-1 bg-purple-600 hover:bg-purple-700 text-white rounded-lg text-[11px] font-bold transition-colors shadow-xs flex items-center gap-1"
                            >
                              <Truck className="w-3 h-3" />
                              <span>مع السائق</span>
                            </button>
                          )}

                          {allowed.includes('delivered') && (
                            <button
                              onClick={() => handleSimpleTransition(order, 'delivered', 'تم التسليم بنجاح واستلام الدفعة')}
                              className="px-2 py-1 bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg text-[11px] font-bold transition-colors shadow-xs"
                            >
                              تم التسليم
                            </button>
                          )}

                          {allowed.includes('failed') && (
                            <button
                              onClick={() => {
                                setFailModalOrder(order);
                                setFailReason('تعذر الوصول للعميل والهاتف مغلق');
                              }}
                              className="px-2 py-1 bg-slate-600 hover:bg-slate-700 text-white rounded-lg text-[11px] font-bold transition-colors shadow-xs"
                            >
                              إخفاق
                            </button>
                          )}

                          {allowed.includes('cancelled') && (
                            <button
                              onClick={() => {
                                setCancelModalOrder(order);
                                setCancelReason('طلب العميل إلغاء الطلب');
                              }}
                              className="px-2 py-1 bg-rose-100 hover:bg-rose-200 text-rose-800 rounded-lg text-[11px] font-bold transition-colors border border-rose-300"
                            >
                              إلغاء
                            </button>
                          )}
                        </div>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Order Details & Picking Sheet Modal */}
      {selectedOrder && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl max-w-2xl w-full p-6 shadow-2xl max-h-[90vh] overflow-y-auto space-y-6">
            <div className="flex items-center justify-between border-b pb-4 border-slate-100">
              <div>
                <h3 className="text-lg font-black text-slate-900 flex items-center gap-2">
                  تفاصيل الطلب: <span className="font-mono text-blue-600">{selectedOrder.order_number}</span>
                </h3>
                <p className="text-xs text-slate-400 mt-0.5">تاريخ الإنشاء: {selectedOrder.created_at}</p>
              </div>
              <button
                onClick={() => setSelectedOrder(null)}
                className="p-2 hover:bg-slate-100 rounded-xl text-slate-400 hover:text-slate-600 transition-colors"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Customer & Address Details */}
            <div className="grid grid-cols-2 gap-4 bg-slate-50 p-4 rounded-2xl border border-slate-200/60">
              <div>
                <p className="text-xs text-slate-400 font-bold">بيانات العميل</p>
                <p className="text-sm font-extrabold text-slate-800 mt-1">{selectedOrder.customer_name}</p>
                <p className="text-xs text-slate-600 flex items-center gap-1 mt-0.5">
                  <Phone className="w-3.5 h-3.5 text-blue-600" />
                  {selectedOrder.customer_phone}
                </p>
              </div>
              <div>
                <p className="text-xs text-slate-400 font-bold">عنوان التوصيل والفرع</p>
                <p className="text-xs font-medium text-slate-700 mt-1 flex items-start gap-1">
                  <MapPin className="w-3.5 h-3.5 text-blue-600 shrink-0 mt-0.5" />
                  {selectedOrder.customer_address}
                </p>
                <p className="text-[11px] text-slate-500 font-bold mt-1">الفرع المخدم: {selectedOrder.branch_name || 'فرع جدة'}</p>
              </div>
            </div>

            {/* Items to Pick */}
            <div>
              <h4 className="text-sm font-extrabold text-slate-900 mb-3 flex items-center gap-2">
                <PackageCheck className="w-4 h-4 text-blue-600" />
                قائمة الأصناف لفرز وتجهيز الطلب ({selectedOrder.items.length})
              </h4>
              <div className="border border-slate-200 rounded-xl overflow-hidden divide-y divide-slate-100">
                {selectedOrder.items.map((item) => (
                  <div key={item.id} className="p-3 flex items-center justify-between bg-white">
                    <div>
                      <p className="text-xs font-bold text-slate-800">{item.product_name_ar}</p>
                      <p className="text-[11px] text-slate-400">
                        {item.quantity} {item.unit} × {item.unit_price.toFixed(2)} ل.س
                        {item.bin_location && ` • رف ${item.bin_location}`}
                      </p>
                    </div>
                    <span className="text-xs font-extrabold text-blue-900">
                      {item.total_price.toFixed(2)} ل.س
                    </span>
                  </div>
                ))}
              </div>
            </div>

            {/* Bill Summary */}
            <div className="space-y-2 bg-slate-50 p-4 rounded-xl border border-slate-200/80 text-xs">
              <div className="flex justify-between text-slate-600">
                <span>المجموع الفرعي:</span>
                <span>{selectedOrder.subtotal.toFixed(2)} ل.س</span>
              </div>
              <div className="flex justify-between text-slate-600">
                <span>رسوم التوصيل:</span>
                <span>{selectedOrder.delivery_fee === 0 ? 'مجاناً' : `${selectedOrder.delivery_fee.toFixed(2)} ل.س`}</span>
              </div>
              {selectedOrder.discount_amount > 0 && (
                <div className="flex justify-between text-rose-600 font-bold">
                  <span>خصم الكوبون:</span>
                  <span>-{selectedOrder.discount_amount.toFixed(2)} ل.س</span>
                </div>
              )}
              {selectedOrder.loyalty_discount > 0 && (
                <div className="flex justify-between text-emerald-600 font-bold">
                  <span>خصم نقاط الولاء:</span>
                  <span>-{selectedOrder.loyalty_discount.toFixed(2)} ل.س</span>
                </div>
              )}
              <div className="border-t pt-2 flex justify-between text-sm font-extrabold text-slate-900">
                <span>المبلغ الإجمالي:</span>
                <span className="text-blue-700 text-base">{selectedOrder.total_amount.toFixed(2)} ل.س</span>
              </div>
            </div>

            {/* Modal Actions */}
            <div className="flex items-center justify-between pt-2">
              <button
                onClick={() => setInvoiceOrder(selectedOrder)}
                className="px-4 py-2 border border-blue-600 text-blue-600 rounded-xl text-xs font-bold hover:bg-blue-50 flex items-center gap-2"
              >
                <Receipt className="w-4 h-4" />
                طباعة الفاتورة الضريبية الرسمية
              </button>

              <button
                onClick={() => setSelectedOrder(null)}
                className="px-4 py-2 bg-slate-200 hover:bg-slate-300 text-slate-700 rounded-xl text-xs font-bold transition-colors"
              >
                إغلاق
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Order Status History / Timeline Modal */}
      {timelineOrder && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl max-w-xl w-full p-6 shadow-2xl max-h-[90vh] overflow-y-auto space-y-6">
            <div className="flex items-center justify-between border-b pb-4 border-slate-100">
              <div className="flex items-center gap-2">
                <History className="w-5 h-5 text-purple-600" />
                <div>
                  <h3 className="text-base font-black text-slate-900">
                    السجل الزمني للطلب: <span className="font-mono text-purple-700">{timelineOrder.order_number}</span>
                  </h3>
                  <p className="text-xs text-slate-400">سجل التدقيق الشامل لعمليات وانتقالات الطلب</p>
                </div>
              </div>
              <button
                onClick={() => setTimelineOrder(null)}
                className="p-2 hover:bg-slate-100 rounded-xl text-slate-400 hover:text-slate-600 transition-colors"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {isLoadingTimeline ? (
              <div className="p-8 text-center text-slate-400 flex flex-col items-center gap-2">
                <RefreshCw className="w-6 h-6 animate-spin text-purple-600" />
                <span className="text-xs font-semibold">جاري جلب السجل الزمني من الخادم...</span>
              </div>
            ) : timelineItems.length === 0 ? (
              <div className="p-6 text-center text-slate-400 font-semibold bg-slate-50 rounded-2xl">
                لا توجد سجلات تاريخية مسجلة لهذا الطلب
              </div>
            ) : (
              <div className="relative border-r-2 border-slate-200 pr-4 mr-2 space-y-6">
                {timelineItems.map((item, idx) => (
                  <div key={item.id || idx} className="relative">
                    {/* Timeline Node Dot */}
                    <div className="absolute -right-[23px] top-1 w-3.5 h-3.5 rounded-full bg-purple-600 border-2 border-white shadow-xs" />
                    
                    <div className="bg-slate-50 p-3.5 rounded-xl border border-slate-200/80 space-y-1.5">
                      <div className="flex items-center justify-between flex-wrap gap-2">
                        <div className="flex items-center gap-2">
                          {item.from_status && (
                            <span className="text-[11px] font-bold text-slate-500 line-through">
                              {ORDER_STATUS_LABELS[item.from_status]?.ar || item.from_status}
                            </span>
                          )}
                          {item.from_status && <span className="text-xs text-slate-400">←</span>}
                          <span className={`px-2 py-0.5 rounded text-[11px] font-extrabold ${ORDER_STATUS_LABELS[item.to_status]?.badgeClass || 'bg-slate-200'}`}>
                            {ORDER_STATUS_LABELS[item.to_status]?.ar || item.to_status}
                          </span>
                        </div>
                        <span className="text-[10px] text-slate-400 font-mono">{item.created_at}</span>
                      </div>

                      {item.staff_name && (
                        <p className="text-[11px] text-slate-600 font-medium">
                          بواسطة: <span className="font-bold text-slate-800">{item.staff_name}</span> ({item.staff_role || 'موظف'})
                        </p>
                      )}

                      {item.reason && (
                        <p className="text-xs text-rose-700 font-bold bg-rose-50 p-2 rounded-lg border border-rose-100">
                          السبب: {item.reason}
                        </p>
                      )}

                      {item.notes && (
                        <p className="text-[11px] text-slate-500 bg-white p-2 rounded-lg border border-slate-100">
                          {item.notes}
                        </p>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            )}

            <div className="flex justify-end pt-2">
              <button
                onClick={() => setTimelineOrder(null)}
                className="px-4 py-2 bg-slate-100 hover:bg-slate-200 text-slate-700 rounded-xl text-xs font-bold transition-colors"
              >
                إغلاق
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Cancel Order Modal */}
      {cancelModalOrder && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl max-w-md w-full p-6 shadow-2xl space-y-4">
            <div className="flex items-center justify-between border-b pb-3 border-slate-100">
              <div className="flex items-center gap-2">
                <XCircle className="w-5 h-5 text-rose-600" />
                <h3 className="text-base font-black text-slate-900">إلغاء الطلب: {cancelModalOrder.order_number}</h3>
              </div>
              <button
                onClick={() => setCancelModalOrder(null)}
                className="p-1.5 hover:bg-slate-100 rounded-xl text-slate-400"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <div className="p-3 bg-amber-50 border border-amber-200 rounded-xl text-[11px] text-amber-900 font-semibold flex items-start gap-2">
              <RotateCcw className="w-4 h-4 text-amber-600 shrink-0 mt-0.5" />
              <span>
                سيتم استرجاع أصناف الطلب تلقائياً إلى رصيد المخزون في الكتالوج والفرع وتسجيل حركة استرجاع في دفتر الأستاذ.
              </span>
            </div>

            <div>
              <label className="block text-xs font-bold text-slate-700 mb-2">سبب الإلغاء (إلزامي):</label>
              <div className="space-y-2">
                {[
                  'طلب العميل إلغاء الطلب',
                  'عدم توفر صنف في المستودع بعد الفرز',
                  'تكرار الطلب عن طريق الخطأ',
                  'عنوان التوصيل خارج النطاق الجغرافي',
                  'أخرى'
                ].map((reasonOption) => (
                  <label key={reasonOption} className="flex items-center gap-2 text-xs font-medium text-slate-700 cursor-pointer">
                    <input
                      type="radio"
                      name="cancel_reason"
                      value={reasonOption}
                      checked={cancelReason === reasonOption}
                      onChange={() => setCancelReason(reasonOption)}
                      className="text-rose-600 focus:ring-rose-500"
                    />
                    <span>{reasonOption}</span>
                  </label>
                ))}
              </div>

              {cancelReason === 'أخرى' && (
                <textarea
                  rows={2}
                  placeholder="اكتب سبب الإلغاء المفصل هنا..."
                  value={cancelCustomReason}
                  onChange={(e) => setCancelCustomReason(e.target.value)}
                  className="w-full mt-2 p-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-medium focus:outline-none focus:border-rose-600"
                />
              )}
            </div>

            <div className="flex items-center justify-end gap-2 pt-2 border-t border-slate-100">
              <button
                onClick={() => setCancelModalOrder(null)}
                className="px-4 py-2 bg-slate-100 hover:bg-slate-200 text-slate-700 rounded-xl text-xs font-bold"
                disabled={isProcessingCancel}
              >
                تراجع
              </button>
              <button
                onClick={handleConfirmCancel}
                disabled={isProcessingCancel}
                className="px-4 py-2 bg-rose-600 hover:bg-rose-700 text-white rounded-xl text-xs font-bold flex items-center gap-1.5 shadow-sm"
              >
                {isProcessingCancel ? (
                  <>
                    <RefreshCw className="w-3.5 h-3.5 animate-spin" />
                    <span>جاري الإلغاء واسترجاع المخزون...</span>
                  </>
                ) : (
                  <span>تأكيد الإلغاء واسترجاع المخزون</span>
                )}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Fail Delivery Modal */}
      {failModalOrder && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl max-w-md w-full p-6 shadow-2xl space-y-4">
            <div className="flex items-center justify-between border-b pb-3 border-slate-100">
              <div className="flex items-center gap-2">
                <AlertTriangle className="w-5 h-5 text-amber-600" />
                <h3 className="text-base font-black text-slate-900">تسجيل تعذر تسليم: {failModalOrder.order_number}</h3>
              </div>
              <button
                onClick={() => setFailModalOrder(null)}
                className="p-1.5 hover:bg-slate-100 rounded-xl text-slate-400"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <div className="p-3 bg-amber-50 border border-amber-200 rounded-xl text-[11px] text-amber-900 font-semibold flex items-start gap-2">
              <RotateCcw className="w-4 h-4 text-amber-600 shrink-0 mt-0.5" />
              <span>
                سيتم استرجاع أصناف الشحنة إلى المخزون وتحديث سجل المندوب برحلة غير مكتملة.
              </span>
            </div>

            <div>
              <label className="block text-xs font-bold text-slate-700 mb-2">سبب الإخفاق (إلزامي):</label>
              <div className="space-y-2">
                {[
                  'تعذر الوصول للعميل والهاتف مغلق',
                  'رفض العميل الاستلام عند الوصول',
                  'العنوان غير دقيق ولم يتم العثور على الموقع',
                  'عطل في وسيلة النقل أو حادث طارئ',
                  'أخرى'
                ].map((reasonOption) => (
                  <label key={reasonOption} className="flex items-center gap-2 text-xs font-medium text-slate-700 cursor-pointer">
                    <input
                      type="radio"
                      name="fail_reason"
                      value={reasonOption}
                      checked={failReason === reasonOption}
                      onChange={() => setFailReason(reasonOption)}
                      className="text-amber-600 focus:ring-amber-500"
                    />
                    <span>{reasonOption}</span>
                  </label>
                ))}
              </div>

              {failReason === 'أخرى' && (
                <textarea
                  rows={2}
                  placeholder="اكتب سبب التعذر هنا..."
                  value={failCustomReason}
                  onChange={(e) => setFailCustomReason(e.target.value)}
                  className="w-full mt-2 p-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-medium focus:outline-none focus:border-amber-600"
                />
              )}
            </div>

            <div className="flex items-center justify-end gap-2 pt-2 border-t border-slate-100">
              <button
                onClick={() => setFailModalOrder(null)}
                className="px-4 py-2 bg-slate-100 hover:bg-slate-200 text-slate-700 rounded-xl text-xs font-bold"
                disabled={isProcessingFail}
              >
                تراجع
              </button>
              <button
                onClick={handleConfirmFail}
                disabled={isProcessingFail}
                className="px-4 py-2 bg-amber-600 hover:bg-amber-700 text-white rounded-xl text-xs font-bold flex items-center gap-1.5 shadow-sm"
              >
                {isProcessingFail ? (
                  <>
                    <RefreshCw className="w-3.5 h-3.5 animate-spin" />
                    <span>جاري تسجيل الإخفاق...</span>
                  </>
                ) : (
                  <span>تأكيد الإخفاق واسترجاع الشحنة</span>
                )}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Assign Courier Modal */}
      {assignModalOrder && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl max-w-md w-full p-6 shadow-2xl space-y-4">
            <div className="flex items-center justify-between border-b pb-3 border-slate-100">
              <div className="flex items-center gap-2">
                <Truck className="w-5 h-5 text-cyan-600" />
                <h3 className="text-base font-black text-slate-900">تعيين كابتن التوصيل: {assignModalOrder.order_number}</h3>
              </div>
              <button
                onClick={() => setAssignModalOrder(null)}
                className="p-1.5 hover:bg-slate-100 rounded-xl text-slate-400"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <div>
              <p className="text-xs text-slate-500 mb-3">
                اختر كابتن التوصيل المتاح لتسليمه شحنة العميل <span className="font-bold text-slate-800">{assignModalOrder.customer_name}</span>:
              </p>

              <div className="space-y-2 max-h-60 overflow-y-auto pr-1">
                {couriers.length === 0 ? (
                  <p className="text-xs text-slate-400 text-center py-4 bg-slate-50 rounded-xl">
                    لا يوجد مناديب مسجلين في النظام حالياً
                  </p>
                ) : (
                  couriers.map((c) => (
                    <label
                      key={c.id}
                      className={`p-3 rounded-xl border flex items-center justify-between cursor-pointer transition-colors ${
                        selectedCourierId === c.id
                          ? 'border-cyan-600 bg-cyan-50/50'
                          : 'border-slate-200 hover:bg-slate-50'
                      }`}
                    >
                      <div className="flex items-center gap-3">
                        <input
                          type="radio"
                          name="courier_selection"
                          value={c.id}
                          checked={selectedCourierId === c.id}
                          onChange={() => setSelectedCourierId(c.id)}
                          className="text-cyan-600 focus:ring-cyan-500"
                        />
                        <div>
                          <p className="text-xs font-bold text-slate-800">{c.full_name}</p>
                          <p className="text-[10px] text-slate-500 flex items-center gap-1">
                            <Phone className="w-3 h-3 text-cyan-600" />
                            {c.phone} • {c.vehicle_type === 'motorbike' ? 'دراجة نارية' : 'سيارة فان'}
                          </p>
                        </div>
                      </div>
                      <span className={`px-2 py-0.5 rounded text-[10px] font-bold ${c.status !== 'offline' ? 'bg-emerald-100 text-emerald-800' : 'bg-slate-100 text-slate-600'}`}>
                        {c.status !== 'offline' ? 'متصل' : 'غير متصل'}
                      </span>
                    </label>
                  ))
                )}
              </div>
            </div>

            <div className="flex items-center justify-end gap-2 pt-2 border-t border-slate-100">
              <button
                onClick={() => setAssignModalOrder(null)}
                className="px-4 py-2 bg-slate-100 hover:bg-slate-200 text-slate-700 rounded-xl text-xs font-bold"
                disabled={isProcessingAssign}
              >
                إلغاء
              </button>
              <button
                onClick={handleConfirmAssign}
                disabled={isProcessingAssign || !selectedCourierId}
                className="px-4 py-2 bg-cyan-600 hover:bg-cyan-700 disabled:opacity-50 text-white rounded-xl text-xs font-bold flex items-center gap-1.5 shadow-sm"
              >
                {isProcessingAssign ? (
                  <>
                    <RefreshCw className="w-3.5 h-3.5 animate-spin" />
                    <span>جاري التعيين...</span>
                  </>
                ) : (
                  <span>تعيين وإرسال الإشعار للكابتن</span>
                )}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Tax Invoice Modal */}
      <InvoiceModal order={invoiceOrder} onClose={() => setInvoiceOrder(null)} />
    </div>
  );
};
