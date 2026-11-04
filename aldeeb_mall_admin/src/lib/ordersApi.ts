/**
 * ==============================================================================
 * Orders Authoritative API & State Transition Service
 * ==============================================================================
 * Handles database operations, server-side atomic transitions, audit ledger
 * timeline fetching, optimistic concurrency conflict guards, and courier linking.
 * ==============================================================================
 */

import { supabase, isValid3PartJwt } from './supabase';
import { Order, OrderStatus, OrderStatusHistoryItem } from '../types';

export interface UpdateOrderStatusOptions {
  orderId: string;
  newStatus: OrderStatus;
  expectedVersion?: number;
  reason?: string;
  notes?: string;
  courierId?: string;
  courierName?: string;
  courierPhone?: string;
  staffId?: string;
  staffName?: string;
  staffRole?: string;
  metadata?: Record<string, any>;
}

export interface TransitionResult {
  success: boolean;
  orderId?: string;
  orderNumber?: string;
  previousStatus?: string;
  newStatus?: OrderStatus;
  version?: number;
  historyId?: string;
  isNoop?: boolean;
  error?: string;
  errorCode?: string;
}

export const ORDER_STATUS_LABELS: Record<OrderStatus, { ar: string; en: string; badgeClass: string }> = {
  pending: {
    ar: 'جديد (بانتظار المراجعة)',
    en: 'Pending Review',
    badgeClass: 'bg-amber-100 text-amber-900 border-amber-200'
  },
  confirmed: {
    ar: 'تم التأكيد',
    en: 'Confirmed',
    badgeClass: 'bg-blue-100 text-blue-900 border-blue-200'
  },
  packing: {
    ar: 'جاري التجهيز والفرز',
    en: 'Packing & Picking',
    badgeClass: 'bg-indigo-100 text-indigo-900 border-indigo-200'
  },
  assigned: {
    ar: 'تم تعيين السائق',
    en: 'Driver Assigned',
    badgeClass: 'bg-cyan-100 text-cyan-900 border-cyan-200'
  },
  ready_for_driver: {
    ar: 'جاهز للاستلام',
    en: 'Ready for Driver',
    badgeClass: 'bg-sky-100 text-sky-900 border-sky-200'
  },
  out_for_delivery: {
    ar: 'مع مندوب التوصيل',
    en: 'Out for Delivery',
    badgeClass: 'bg-purple-100 text-purple-900 border-purple-200'
  },
  delivered: {
    ar: 'تم التسليم بنجاح',
    en: 'Delivered',
    badgeClass: 'bg-emerald-100 text-emerald-900 border-emerald-200'
  },
  cancelled: {
    ar: 'ملغي (مسترجع للمخزون)',
    en: 'Cancelled',
    badgeClass: 'bg-rose-100 text-rose-900 border-rose-200'
  },
  failed: {
    ar: 'تعذر التسليم (إخفاق)',
    en: 'Delivery Failed',
    badgeClass: 'bg-slate-200 text-slate-800 border-slate-300'
  }
};

/**
 * Returns allowed next statuses for a given current status and staff role.
 */
export function getAllowedNextStatuses(currentStatus: OrderStatus, role?: string): OrderStatus[] {
  const isSuper = role === 'super_admin' || role === 'general_manager';
  const isWarehouse = role === 'warehouse_manager';
  const isBranchMgr = role === 'branch_manager';
  const isCourier = role === 'courier';
  const isCashier = role === 'cashier';

  switch (currentStatus) {
    case 'pending':
      if (isCourier) return [];
      return ['confirmed', 'packing', 'cancelled'];

    case 'confirmed':
      if (isCourier) return [];
      return ['packing', 'assigned', 'out_for_delivery', 'cancelled'];

    case 'packing':
      if (isCourier) return [];
      return ['assigned', 'out_for_delivery', 'cancelled'];

    case 'assigned':
      if (isCourier) return ['out_for_delivery', 'delivered', 'failed'];
      return ['out_for_delivery', 'delivered', 'failed', 'cancelled'];

    case 'ready_for_driver':
      if (isCourier) return ['out_for_delivery', 'delivered', 'failed'];
      return ['out_for_delivery', 'delivered', 'failed', 'cancelled'];

    case 'out_for_delivery':
      return ['delivered', 'failed', 'cancelled'];

    case 'failed':
      if (isCourier) return [];
      return ['packing', 'assigned', 'out_for_delivery', 'cancelled'];

    case 'delivered':
    case 'cancelled':
    default:
      return []; // Terminal states
  }
}

/**
 * Fetches all orders with items from PostgreSQL / Supabase, filtered by branch if specified.
 */
export async function fetchOrders(options?: {
  branchId?: string;
  status?: OrderStatus | 'all';
  searchQuery?: string;
}): Promise<Order[]> {
  try {
    let query = supabase
      .from('orders')
      .select('*, order_items(*)')
      .order('created_at', { ascending: false });

    if (options?.branchId && options.branchId !== 'all') {
      query = query.eq('branch_id', options.branchId);
    }

    if (options?.status && options.status !== 'all') {
      query = query.eq('status', options.status);
    }

    const { data, error } = await query;
    if (error) {
      console.warn('⚠️ [ordersApi] Failed to fetch orders from Supabase:', error.message);
      return [];
    }

    if (!data) return [];

    return data.map((o: any) => ({
      id: o.id,
      order_number: o.order_number,
      customer_name: o.customer_name || 'عميل الديب مول',
      customer_phone: o.customer_phone || '+963 90 000 0000',
      customer_address: o.notes || o.delivery_slot || 'عنوان التوصيل',
      status: o.status as OrderStatus,
      delivery_slot: o.delivery_slot || 'فوري',
      delivery_type: o.delivery_type,
      payment_method: o.payment_method === 'cod' ? 'الدفع عند الاستلام' : (o.payment_method || 'نقدي'),
      subtotal: Number(o.subtotal) || 0,
      delivery_fee: Number(o.delivery_fee) || 0,
      discount_amount: Number(o.discount_amount) || 0,
      loyalty_discount: Number(o.loyalty_discount) || 0,
      total_amount: Number(o.total_amount) || 0,
      created_at: o.created_at ? new Date(o.created_at).toLocaleString('ar-SY') : '',
      notes: o.notes,
      branch_id: o.branch_id,
      branch_name: o.branch_name,
      courier_id: o.courier_id,
      courier_name: o.delivery_driver_name,
      delivery_otp: o.delivery_otp,
      cancellation_reason: o.cancellation_reason,
      failure_reason: o.failure_reason,
      delivered_at: o.delivered_at,
      assigned_at: o.assigned_at,
      version: o.version ?? 1,
      is_stock_restored: o.is_stock_restored ?? false,
      items: Array.isArray(o.order_items)
        ? o.order_items.map((item: any) => ({
            id: item.id,
            product_id: item.product_id,
            product_name_ar: item.product_name_ar || 'صنف ممتاز',
            product_name_en: item.product_name_en || 'Product item',
            unit_price: Number(item.unit_price) || 0,
            quantity: Number(item.quantity) || 1,
            unit: item.unit || 'حبة',
            total_price: Number(item.total_price) || 0,
            bin_location: item.bin_location
          }))
        : []
    }));
  } catch (err: any) {
    console.error('❌ [ordersApi] fetchOrders exception:', err);
    return [];
  }
}

/**
 * Fetches status timeline for an order from public.order_status_history.
 */
export async function fetchOrderTimeline(orderId: string): Promise<OrderStatusHistoryItem[]> {
  try {
    const { data, error } = await supabase
      .from('order_status_history')
      .select('*')
      .eq('order_id', orderId)
      .order('created_at', { ascending: true });

    if (error) {
      console.warn(`⚠️ [ordersApi] Could not fetch timeline for order ${orderId}:`, error.message);
      return [];
    }

    return (data || []).map((h: any) => ({
      id: h.id,
      order_id: h.order_id,
      from_status: h.from_status as OrderStatus | null,
      to_status: h.to_status as OrderStatus,
      reason: h.reason,
      notes: h.notes,
      staff_id: h.staff_id,
      staff_name: h.staff_name,
      staff_role: h.staff_role,
      metadata: h.metadata || {},
      created_at: h.created_at ? new Date(h.created_at).toLocaleString('ar-SY') : ''
    }));
  } catch (err: any) {
    console.error('❌ [ordersApi] fetchOrderTimeline exception:', err);
    return [];
  }
}

/**
 * Atomically updates order status with validation, optimistic lock, reason check,
 * and automatic stock restoration.
 */
export async function updateOrderStatusAtomic(
  options: UpdateOrderStatusOptions
): Promise<TransitionResult> {
  const {
    orderId,
    newStatus,
    expectedVersion,
    reason,
    notes,
    courierId,
    courierName,
    courierPhone,
    staffId,
    staffName,
    staffRole,
    metadata
  } = options;

  if (!orderId) {
    return { success: false, error: 'معرف الطلب غير محدد' };
  }

  // Client-side quick check: reason is strictly mandatory for cancelled or failed
  if ((newStatus === 'cancelled' || newStatus === 'failed') && (!reason || reason.trim().length === 0)) {
    return {
      success: false,
      errorCode: 'REASON_REQUIRED',
      error: `يجب توضيح سبب الانتقال إلى حالة "${ORDER_STATUS_LABELS[newStatus]?.ar || newStatus}" إلزامياً.`
    };
  }

  try {
    const payload = {
      p_order_id: orderId,
      p_new_status: newStatus,
      p_expected_version: expectedVersion ?? null,
      p_reason: reason ? reason.trim() : null,
      p_notes: notes ? notes.trim() : null,
      p_courier_id: courierId ?? null,
      p_courier_name: courierName ?? null,
      p_courier_phone: courierPhone ?? null,
      p_staff_id: staffId ?? null,
      p_staff_name: staffName ?? 'موظف الإدارة',
      p_staff_role: staffRole ?? 'super_admin',
      p_metadata: metadata ?? {}
    };

    const { data, error } = await supabase.rpc('update_order_status_atomic', payload);

    if (error) {
      console.warn('⚠️ [ordersApi] update_order_status_atomic error:', error.message);
      
      let friendlyError = error.message;
      if (error.message.includes('CONCURRENT_MODIFICATION_CONFLICT')) {
        friendlyError = '⚠️ تم تعديل هذا الطلب بواسطة موظف آخر في نفس الوقت! جاري تحديث البيانات تلقائياً.';
      } else if (error.message.includes('REASON_REQUIRED')) {
        friendlyError = '⚠️ إدخال السبب إلزامي لإتمام هذا الإجراء.';
      } else if (error.message.includes('INVALID_TRANSITION')) {
        friendlyError = `⚠️ لا يمكن الانتقال إلى هذه الحالة مباشرة من الحالة الحالية للطلب.`;
      } else if (error.message.includes('UNAUTHORIZED_BRANCH')) {
        friendlyError = '⚠️ غير مصرح لحسابك بتعديل طلبات فرع آخر.';
      }

      return {
        success: false,
        error: friendlyError,
        errorCode: error.code || 'RPC_ERROR'
      };
    }

    const result = data as any;
    return {
      success: true,
      orderId: result?.order_id,
      orderNumber: result?.order_number,
      previousStatus: result?.previous_status,
      newStatus: result?.new_status as OrderStatus,
      version: result?.version,
      historyId: result?.history_id,
      isNoop: result?.is_noop
    };
  } catch (err: any) {
    console.error('❌ [ordersApi] updateOrderStatusAtomic exception:', err);
    return {
      success: false,
      error: err?.message || 'حدث خطأ غير متوقع أثناء معالجة الطلب.'
    };
  }
}
