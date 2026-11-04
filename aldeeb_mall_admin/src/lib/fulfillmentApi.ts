import { supabase } from './supabase';
import { PickerTask, Order, Product } from '../types';

export interface FulfillmentScanResult {
  success: boolean;
  error?: string;
  message_ar: string;
  task_id?: string;
  status?: string;
  is_verified?: boolean;
  quantity_picked?: number;
  actual_weight?: number;
  scanned_barcode?: string;
  expected_barcode?: string;
}

export interface FulfillmentSubstitutionResult {
  success: boolean;
  error?: string;
  message_ar: string;
  task_id?: string;
  status?: string;
  substitute_name?: string;
  price_difference?: number;
}

export interface FulfillmentShortageResult {
  success: boolean;
  error?: string;
  message_ar: string;
  task_id?: string;
  status?: string;
  shortage_qty?: number;
  quantity_picked?: number;
}

export interface FulfillmentStageResult {
  success: boolean;
  error?: string;
  message_ar: string;
  stage?: string;
  order_id?: string;
  order_number?: string;
  sorted_bin?: string;
  packing_box_id?: string;
  unfulfilled_count?: number;
}

export const fulfillmentApi = {
  /**
   * Fetch active fulfillment orders (pending, confirmed, packing, ready_for_driver)
   */
  async fetchFulfillmentOrders(branchId?: string): Promise<Order[]> {
    let query = supabase
      .from('orders')
      .select(`
        *,
        items:order_items(*)
      `)
      .in('status', ['pending', 'confirmed', 'packing', 'ready_for_driver'])
      .order('created_at', { ascending: false });

    if (branchId && branchId !== 'all') {
      query = query.eq('branch_id', branchId);
    }

    const { data, error } = await query;
    if (error) {
      console.error('Failed to fetch fulfillment orders:', error);
      throw new Error(error.message);
    }

    return (data || []).map((row: any) => ({
      ...row,
      subtotal: Number(row.subtotal),
      delivery_fee: Number(row.delivery_fee),
      discount_amount: Number(row.discount_amount),
      loyalty_discount: Number(row.loyalty_discount),
      total_amount: Number(row.total_amount),
      items: (row.items || []).map((item: any) => ({
        ...item,
        unit_price: Number(item.unit_price),
        quantity: Number(item.quantity),
        total_price: Number(item.total_price),
      })),
    }));
  },

  /**
   * Fetch persistent picker tasks from database
   */
  async fetchPickerTasks(branchId?: string, orderId?: string, stage?: string): Promise<PickerTask[]> {
    let query = supabase
      .from('picker_tasks')
      .select(`
        *,
        order:orders(order_number, branch_id, branch_name, status, delivery_slot, customer_name, customer_phone),
        product:products(name_ar, name_en, barcode, unit, images)
      `)
      .order('created_at', { ascending: false });

    if (branchId && branchId !== 'all') {
      query = query.eq('branch_id', branchId);
    }
    if (orderId) {
      query = query.eq('order_id', orderId);
    }
    if (stage && stage !== 'all') {
      query = query.eq('stage', stage);
    }

    const { data, error } = await query;
    if (error) {
      console.error('Failed to fetch picker tasks:', error);
      throw new Error(error.message);
    }

    return (data || []).map((row: any) => ({
      id: row.id,
      order_id: row.order_id,
      order_item_id: row.order_item_id,
      order_number: row.order?.order_number || 'DEEB-ORD',
      product_id: row.product_id,
      product_name_ar: row.product?.name_ar || 'صنف تمويني',
      product_name_en: row.product?.name_en || 'Grocery Item',
      product_image: row.product?.images?.[0] || '',
      bin_location: row.bin_location || 'A-01-R1-B01',
      barcode: row.barcode || row.product?.barcode || '',
      quantity_required: Number(row.quantity_required),
      quantity_picked: Number(row.quantity_picked),
      is_verified: Boolean(row.is_verified),
      status: row.status,
      branch_id: row.branch_id,
      branch_name: row.branch_name,
      assigned_staff_id: row.assigned_staff_id,
      assigned_staff_name: row.assigned_staff_name,
      stage: row.stage || 'picking',
      item_type: row.item_type || 'unit',
      unit: row.unit || row.product?.unit || 'قطعة',
      expected_weight: row.expected_weight ? Number(row.expected_weight) : undefined,
      actual_weight: row.actual_weight ? Number(row.actual_weight) : undefined,
      verification_method: row.verification_method || 'pending',
      scanned_barcode: row.scanned_barcode,
      is_substituted: Boolean(row.is_substituted),
      substitute_product_id: row.substitute_product_id,
      substitute_product_name: row.substitute_product_name,
      substitute_barcode: row.substitute_barcode,
      substitution_reason: row.substitution_reason,
      price_difference: Number(row.price_difference || 0),
      is_shortage: Boolean(row.is_shortage),
      shortage_qty: Number(row.shortage_qty || 0),
      shortage_reason: row.shortage_reason,
      notes: row.notes,
      packing_box_id: row.packing_box_id,
      sorted_bin: row.sorted_bin,
      scanned_at: row.scanned_at,
      sorted_at: row.sorted_at,
      packed_at: row.packed_at,
      created_at: row.created_at,
      updated_at: row.updated_at,
    }));
  },

  /**
   * Generate persistent tasks for an order
   */
  async generateTasksForOrder(
    orderId: string,
    staffId?: string,
    branchId?: string
  ): Promise<any> {
    const { data, error } = await supabase.rpc('generate_fulfillment_tasks_for_order', {
      p_order_id: orderId,
      p_staff_id: staffId || null,
      p_branch_id: branchId || null,
    });

    if (error) {
      console.error('Failed to generate tasks for order:', error);
      throw new Error(error.message);
    }
    return data;
  },

  /**
   * Real Barcode / Verified Manual Scan Verification
   */
  async verifyScan(
    taskId: string,
    scannedBarcode: string,
    scanMode: 'barcode_scan' | 'verified_manual' = 'barcode_scan',
    actualQty: number = 1,
    actualWeight?: number,
    staffId?: string
  ): Promise<FulfillmentScanResult> {
    const { data, error } = await supabase.rpc('verify_fulfillment_scan', {
      p_task_id: taskId,
      p_scanned_barcode: scannedBarcode,
      p_scan_mode: scanMode,
      p_actual_qty: actualQty,
      p_actual_weight: actualWeight ?? null,
      p_staff_id: staffId || null,
    });

    if (error) {
      console.error('Scan verification error:', error);
      return {
        success: false,
        error: 'NETWORK_ERROR',
        message_ar: error.message || 'حدث خطأ أثناء الاتصال بالخادم لمطابقة الباركود',
      };
    }
    return data as FulfillmentScanResult;
  },

  /**
   * Record Item Substitution with Stock Adjustment
   */
  async recordSubstitution(
    taskId: string,
    substituteProductId: string,
    substituteBarcode: string,
    substituteQty: number,
    reason: string,
    staffId?: string
  ): Promise<FulfillmentSubstitutionResult> {
    const { data, error } = await supabase.rpc('record_fulfillment_substitution', {
      p_task_id: taskId,
      p_substitute_product_id: substituteProductId,
      p_substitute_barcode: substituteBarcode,
      p_substitute_qty: substituteQty,
      p_reason: reason,
      p_staff_id: staffId || null,
    });

    if (error) {
      console.error('Substitution error:', error);
      return {
        success: false,
        error: 'NETWORK_ERROR',
        message_ar: error.message || 'حدث خطأ أثناء تسجيل الصنف البديل',
      };
    }
    return data as FulfillmentSubstitutionResult;
  },

  /**
   * Record Item Shortage / Out of Stock
   */
  async recordShortage(
    taskId: string,
    shortageQty: number,
    reason: string,
    staffId?: string
  ): Promise<FulfillmentShortageResult> {
    const { data, error } = await supabase.rpc('record_fulfillment_shortage', {
      p_task_id: taskId,
      p_shortage_qty: shortageQty,
      p_reason: reason,
      p_staff_id: staffId || null,
    });

    if (error) {
      console.error('Shortage error:', error);
      return {
        success: false,
        error: 'NETWORK_ERROR',
        message_ar: error.message || 'حدث خطأ أثناء تسجيل النقص',
      };
    }
    return data as FulfillmentShortageResult;
  },

  /**
   * Advance Stage: 'sorting' | 'packing' | 'ready_for_driver'
   */
  async advanceStage(
    orderId: string,
    newStage: 'sorting' | 'packing' | 'ready_for_driver',
    staffId?: string,
    boxId?: string
  ): Promise<FulfillmentStageResult> {
    const { data, error } = await supabase.rpc('advance_fulfillment_stage', {
      p_order_id: orderId,
      p_new_stage: newStage,
      p_staff_id: staffId || null,
      p_box_id: boxId || null,
    });

    if (error) {
      console.error('Advance stage error:', error);
      return {
        success: false,
        error: 'NETWORK_ERROR',
        message_ar: error.message || 'حدث خطأ أثناء ترقية مرحلة التجهيز',
      };
    }
    return data as FulfillmentStageResult;
  },

  /**
   * Fetch active catalog products to use as substitutes
   */
  async fetchSubstituteProducts(categoryId?: string): Promise<Product[]> {
    let query = supabase
      .from('products')
      .select('*')
      .eq('is_active', true)
      .gt('stock_quantity', 0)
      .order('name_ar', { ascending: true })
      .limit(50);

    if (categoryId) {
      query = query.eq('category_id', categoryId);
    }

    const { data, error } = await query;
    if (error) {
      console.error('Failed to fetch substitute products:', error);
      return [];
    }

    return (data || []).map((p: any) => ({
      ...p,
      price: Number(p.price),
      original_price: p.original_price ? Number(p.original_price) : undefined,
    }));
  },
};
