export interface Product {
  id: string;
  name_ar: string;
  name_en: string;
  category_id?: string;
  barcode?: string;
  brand?: string;
  price: number;
  original_price?: number;
  discount_percent: number;
  unit: string;
  weight_step: number;
  stock_quantity: number;
  images: string[];
  is_featured: boolean;
  is_daily_deal: boolean;
  rating: number;
  sales_count: number;
  bundle_enabled?: boolean;
  bundle_discount_percent?: number;
  bundle_title?: string;
  bundle_product_ids?: string[];
  branch_id?: string;
  branch_name?: string;
  is_draft?: boolean;
  is_active?: boolean;
  cost_price?: number;
  status?: 'published' | 'incomplete_data' | 'archived';
}

export interface Category {
  id: string;
  name_ar: string;
  name_en: string;
  slug: string;
  icon_name: string;
  image_url?: string;
  sort_order: number;
  is_active: boolean;
  show_title?: boolean;
  group_tag?: string;
  item_count?: number;
}

export interface OrderItem {
  id: string;
  product_id?: string;
  product_name_ar: string;
  product_name_en: string;
  product_image?: string;
  unit_price: number;
  quantity: number;
  unit: string;
  total_price: number;
  bin_location?: string;
}

export type OrderStatus = 
  | 'pending'
  | 'confirmed'
  | 'packing'
  | 'assigned'
  | 'ready_for_driver'
  | 'out_for_delivery'
  | 'delivered'
  | 'cancelled'
  | 'failed';

export interface OrderStatusHistoryItem {
  id: string;
  order_id: string;
  from_status: OrderStatus | null;
  to_status: OrderStatus;
  reason?: string;
  notes?: string;
  staff_id?: string;
  staff_name?: string;
  staff_role?: string;
  metadata?: Record<string, any>;
  created_at: string;
}

export interface Order {
  id: string;
  order_number: string;
  customer_name: string;
  customer_phone: string;
  customer_address: string;
  status: OrderStatus;
  delivery_slot: string;
  delivery_type?: '15_min_express' | 'scheduled';
  payment_method: string;
  subtotal: number;
  delivery_fee: number;
  discount_amount: number;
  loyalty_discount: number;
  total_amount: number;
  created_at: string;
  notes?: string;
  items: OrderItem[];
  branch_id?: string;
  branch_name?: string;
  courier_id?: string;
  courier_name?: string;
  delivery_otp?: string;
  delivery_failure_reason?: string;
  cancellation_reason?: string;
  failure_reason?: string;
  delivered_at?: string;
  assigned_at?: string;
  version?: number;
  is_stock_restored?: boolean;
}

export interface Coupon {
  id: string;
  code: string;
  discount_type: 'percentage' | 'fixed';
  discount_value: number;
  min_order_amount: number;
  max_discount?: number;
  usage_limit: number;
  times_used: number;
  is_active: boolean;
  expires_at?: string;
  per_customer_limit?: number;
  allow_combine_with_flash_deals?: boolean;
  allow_stacking_coupons?: boolean;
  branch_id?: string;
}

export interface Customer {
  id: string;
  full_name: string;
  email: string;
  phone?: string;
  loyalty_points: number;
  tier: 'Silver' | 'Gold' | 'Platinum';
  total_orders: number;
  total_spent: number;
  created_at: string;
}

export interface DarkStore {
  id: string;
  code: string;
  name_ar: string;
  name_en: string;
  city: string;
  radius_km: number;
  is_active: boolean;
  active_pickers: number;
  pending_wave_orders: number;
  avg_pick_seconds: number;
}

export interface WarehouseItemStock {
  id: string;
  warehouse_id: string;
  product_id: string;
  product_name_ar: string;
  barcode: string;
  available_stock: number;
  reserved_stock: number;
  damaged_stock: number;
  bin_location: string;
  last_updated: string;
}

export interface InventoryMovementLog {
  id: string;
  timestamp: string;
  warehouse_id: string;
  branch_id?: string;
  product_id: string;
  product_name_ar?: string;
  barcode: string;
  type: 
    | 'supply' 
    | 'reservation' 
    | 'release_reservation' 
    | 'disbursement' 
    | 'sale' 
    | 'return' 
    | 'damaged' 
    | 'audit_reconciliation' 
    | 'adjustment' 
    | 'transfer_out' 
    | 'transfer_in' 
    | 'inbound_po' 
    | 'order_fulfillment';
  quantity_change: number;
  resulting_available: number;
  resulting_reserved?: number;
  reference_type?: string;
  reference_id: string;
  notes?: string;
  performed_by: string;
  actor_name?: string;
  actor_role?: string;
}

export interface InventoryAuditRecord {
  id: string;
  audit_number: string;
  branch_id: string;
  product_id: string;
  product_name_ar?: string;
  system_quantity: number;
  physical_quantity: number;
  variance: number;
  reason?: string;
  auditor_name: string;
  auditor_role: string;
  status: string;
  created_at: string;
}

export type TransferStatus = 
  | 'requested'          // طلب المناقلة الأولي
  | 'under_review'       // قيد المراجعة الفنية
  | 'approved'           // تم الاعتماد
  | 'reserved'           // تم حجز بضاعة المصدر
  | 'dispatched'         // تم الإرسال والشحن مع السائق
  | 'received'           // تم الاستلام الأولي
  | 'matched'            // تمت المطابقة وحصر التلف أو الفروقات
  | 'closed'             // مغلق ومقيد في المخزون
  | 'cancelled'          // ملغي مع فك الحجز
  | 'compensated';       // تمت تسوية التعويض للفروقات والتوالف

export interface TransferOrder {
  id: string;
  manifest_number: string;
  transfer_number?: string;
  source_branch_id?: string;
  source_warehouse_id: string;
  source_warehouse_name: string;
  destination_branch_id?: string;
  destination_warehouse_id: string;
  destination_warehouse_name: string;
  sku: string;
  barcode?: string;
  product_id?: string;
  product_name_ar: string;
  quantity_requested: number;
  quantity_reserved?: number;
  quantity_dispatched: number;
  quantity_received: number;
  quantity_received_good?: number;
  quantity_damaged: number;
  discrepancy_quantity?: number;
  status: TransferStatus;
  assigned_driver?: string;
  requested_at: string;
  dispatched_at?: string;
  received_at?: string;
  closed_at?: string;
  cancelled_at?: string;
  compensated_at?: string;
  discrepancy_reason?: string;
  compensation_notes?: string;
  notes?: string;
  audit_locked?: boolean;
}

export interface PickerTask {
  id: string;
  order_number: string;
  order_id?: string;
  order_item_id?: string;
  product_id?: string;
  product_name_ar: string;
  product_name_en?: string;
  product_image?: string;
  bin_location: string;
  barcode: string;
  quantity_required: number;
  quantity_picked: number;
  is_verified: boolean;
  status: 'pending' | 'picked' | 'sorted' | 'packed' | 'verified' | 'out_of_stock' | 'substituted' | 'completed';
  branch_id?: string;
  branch_name?: string;
  assigned_staff_id?: string;
  assigned_staff_name?: string;
  stage?: 'picking' | 'sorting' | 'packing' | 'completed';
  item_type?: 'unit' | 'weighed';
  unit?: string;
  expected_weight?: number;
  actual_weight?: number;
  verification_method?: 'pending' | 'barcode_scan' | 'verified_manual';
  scanned_barcode?: string;
  is_substituted?: boolean;
  substitute_product_id?: string;
  substitute_product_name?: string;
  substitute_barcode?: string;
  substitution_reason?: string;
  price_difference?: number;
  is_shortage?: boolean;
  shortage_qty?: number;
  shortage_reason?: string;
  notes?: string;
  packing_box_id?: string;
  sorted_bin?: string;
  scanned_at?: string;
  sorted_at?: string;
  packed_at?: string;
  created_at?: string;
  updated_at?: string;
}

export interface FlashDeal {
  id: string;
  product_id: string;
  product_name_ar: string;
  product_image: string;
  original_price: number;
  deal_price: number;
  discount_percent: number;
  total_quota: number;
  claimed_quota: number;
  ends_at: string;
  is_active: boolean;
  branch_id?: string;
  branch_name?: string;
  product_ids?: string[];
  real_views_count?: number;
  real_clicks_count?: number;
  real_sold_units?: number;
  real_revenue_generated?: number;
}

export interface Courier {
  id: string;
  full_name: string;
  phone: string;
  vehicle_type: 'motorbike' | 'van' | 'electric_scooter';
  license_plate: string;
  current_location: string;
  status: 'idle' | 'on_delivery' | 'returning' | 'offline' | 'break';
  is_online?: boolean;
  shift_status?: 'active' | 'break' | 'off_duty';
  earnings_today?: number;
  tips_today?: number;
  battery_or_fuel: number;
  rating: number;
  assigned_orders_count: number;
  completed_today: number;
  branch_id?: string;
  branch_name?: string;
}


export interface Supplier {
  id: string;
  name_ar: string;
  name_en: string;
  contact_person: string;
  phone: string;
  email: string;
  address?: string;
  commercial_reg?: string;
  tax_number?: string;
  lead_time_days: number;
  payment_terms: string;
  active_products_count: number;
  balance?: number;
  status: 'active' | 'under_review' | 'inactive';
}

export interface SupplierPayment {
  id: string;
  payment_number: string;
  purchase_order_id: string;
  supplier_id: string;
  amount: number;
  payment_method: 'sham_cash' | 'cash' | 'bank_transfer';
  payment_reference?: string;
  paid_by?: string;
  notes?: string;
  paid_at: string;
}

export interface PurchaseOrderItem {
  id?: string;
  purchase_order_id?: string;
  product_id?: string;
  name_ar: string;
  barcode?: string;
  unit?: string;
  quantity_ordered: number;
  quantity_received: number;
  quantity_damaged?: number;
  unit_cost: number;
  total_cost: number;
  is_new_draft_product?: boolean;
}

export interface PurchaseOrder {
  id: string;
  po_number: string;
  supplier_name: string;
  supplier_id?: string;
  branch_id?: string;
  branch_name?: string;
  total_items: number;
  total_cost: number;
  paid_amount?: number;
  payment_status?: 'unpaid' | 'partial' | 'paid';
  status: 'draft' | 'sent' | 'partially_received' | 'received' | 'cancelled';
  order_date: string;
  expected_arrival: string;
  items?: PurchaseOrderItem[];
  payments?: SupplierPayment[];
  notes?: string;
  cancellation_reason?: string;
  created_by?: string;
}

export interface TicketMessageItem {
  id: string;
  sender: 'customer' | 'agent' | 'bot' | 'system';
  sender_name?: string;
  text: string;
  timestamp?: string;
  time?: string;
}

export interface SupportTicket {
  id: string;
  ticket_number: string;
  customer_name: string;
  customer_phone?: string;
  order_number?: string;
  subject: string;
  category?: string;
  status: 'open' | 'in_progress' | 'resolved';
  priority: 'low' | 'medium' | 'high';
  created_at: string;
  last_message: string;
  messages?: TicketMessageItem[];
}


export interface MarketingCampaign {
  id: string;
  title_ar: string;
  body_ar: string;
  target_audience: 'all' | 'vip_gold_platinum' | 'cart_abandoners' | 'new_customers';
  scheduled_at: string;
  status: 'draft' | 'scheduled' | 'sent';
  open_rate: number;
  conversion_rate: number;
  sent_count: number;
}

export interface DeliveryZone {
  id: string;
  zone_name_ar: string;
  zone_name_en?: string;
  city?: string;
  district?: string;
  branch_id?: string;
  dark_store_code: string;
  center_latitude?: number;
  center_longitude?: number;
  radius_km: number;
  base_delivery_fee: number;
  free_delivery_threshold: number;
  estimated_minutes: number;
  is_surge_pricing_active: boolean;
  surge_fee: number;
  is_active: boolean;
  opening_time?: string;
  closing_time?: string;
  max_hourly_capacity?: number;
  current_hourly_load?: number;
  delivery_options?: Array<{
    id: string;
    name_ar: string;
    fee_modifier?: number;
    estimated_minutes?: number;
  }>;
}

export interface ColdChainSensor {
  id: string;
  room_name_ar: string;
  category: 'chiller_dairy' | 'chiller_meat' | 'freezer_ice' | 'produce_mist';
  current_temp_celsius: number;
  target_temp_celsius: number;
  min_safe_temp: number;
  max_safe_temp: number;
  humidity_percent: number;
  status: 'optimal' | 'warning' | 'critical';
  last_ping: string;
}

export interface ExpiryBatchItem {
  id: string;
  product_id: string;
  product_name_ar: string;
  category_name_ar: string;
  sku: string;
  batch_number: string;
  expiry_date: string;
  hours_remaining: number;
  stock_quantity: number;
  original_price: number;
  clearance_discount_percent: number;
  clearance_active: boolean;
}

export interface ReturnRequest {
  id: string;
  return_number: string;
  order_number: string;
  customer_name: string;
  customer_phone: string;
  items_summary: string;
  reason: 'defective_fresh' | 'wrong_item' | 'past_expiry' | 'damaged_packaging';
  reason_ar: string;
  requested_at: string;
  refund_amount: number;
  photo_evidence_url: string;
  status: 'pending_review' | 'approved_refunded' | 'approved_replacement' | 'rejected';
}

export interface SubscriptionPlan {
  id: string;
  plan_key: string;
  name_ar: string;
  name_en: string;
  badge_tag_ar: string;
  price_monthly: number;
  price_annual: number;
  points_multiplier: number;
  cashback_percent: number;
  free_express_delivery: boolean;
  min_order_free_delivery: number;
  features_ar: string[];
  accent_color: string;
  is_popular: boolean;
  is_active: boolean;
  subscribers_count: number;
}

export interface Subscriber {
  id: string;
  customer_id: string;
  customer_name: string;
  customer_email: string;
  customer_phone: string;
  plan_key: string;
  plan_name_ar: string;
  billing_cycle: 'monthly' | 'annual';
  status: 'active' | 'paused' | 'cancelled' | 'expired' | 'pending_payment_review';
  auto_renew: boolean;
  started_at: string;
  renews_at: string;
  total_deliveries_saved: number;
  total_money_saved: number;
  total_spent: number;
  loyalty_points: number;
  payment_method?: 'sham_cash' | 'card' | 'manual_admin';
  transfer_receipt_url?: string;
  transfer_reference?: string;
  transfer_amount?: number;
  approved_by?: string;
  approved_at?: string;
  rejection_reason?: string;
  manual_activation_reason?: string;
}

export interface ShamCashPaymentReceipt {
  id: string;
  reference_number: string;
  subscriber_id: string;
  customer_name: string;
  amount: number;
  receipt_image_url: string;
  status: 'pending' | 'approved' | 'rejected';
  submitted_at: string;
  reviewed_by?: string;
  reviewed_at?: string;
  rejection_reason?: string;
}

export interface RewardCoupon {
  id: string;
  code_prefix: string;
  title_ar: string;
  description_ar: string;
  points_cost: number;
  discount_amount: number;
  min_order_amount: number;
  days_valid: number;
  total_claimed: number;
  is_active: boolean;
}

export interface RewardProduct {
  id: string;
  product_id?: string;
  title_ar: string;
  title_en: string;
  image_url: string;
  category_ar: string;
  points_cost: number;
  stock_quota: number;
  claimed_count: number;
  is_active: boolean;
}

export interface SubscriptionActivityLog {
  id: string;
  timestamp: string;
  customer_name: string;
  activity_type: 'new_subscription' | 'renewed' | 'upgraded' | 'points_redeemed' | 'reward_claimed' | 'paused';
  description_ar: string;
  badge_color: string;
  amount_or_points?: string;
}

export interface Banner {
  id: string;
  title_ar: string;
  title_en: string;
  subtitle_ar?: string;
  subtitle_en?: string;
  image_url: string;
  slot: 'hero' | 'side_top' | 'side_bottom' | 'promo' | 'middle_secondary';
  position?: 'hero' | 'middle_secondary' | 'side_top' | 'side_bottom' | 'promo';
  target_type: 'category' | 'screen' | 'product' | 'deal' | 'coupon' | 'external';
  target_id?: string;
  badge_ar?: string;
  badge_color?: string;
  sort_order: number;
  is_active: boolean;
}

export interface HomeShelf {
  id: string;
  nameAr: string;
  nameEn: string;
  type: 'search_header' | 'hero_banners' | 'departments' | 'weekly_deals' | 'secondary_banner_1' | 'cant_miss' | 'new_arrivals' | 'secondary_banner_2' | 'mega_savings' | 'category_shelf' | 'full_catalog';
  categoryId?: string;
  isEnabled: boolean;
  order: number;
  customTitleAr?: string;
}

// ==========================================
// Multi-Branch Management Interfaces
// ==========================================
export interface Branch {
  id: string;
  code: string;
  name_ar: string;
  name_en: string;
  city: string;
  district: string;
  address: string;
  phone: string;
  manager_name: string;
  is_active: boolean;
  terminals_count: number;
  daily_sales: number;
  currency: string;
  type: 'hypermarket' | 'supermarket' | 'express' | 'dark_store';
  created_at: string;
}

// ==========================================
// Enterprise POS Interfaces
// ==========================================
export interface PosCartItem {
  product_id: string;
  barcode?: string;
  name_ar: string;
  name_en?: string;
  price: number;
  quantity: number;
  unit: string;
  discount_amount: number;
  total: number;
  tax_amount: number;
  image_url?: string;
}

export interface ParkedCart {
  id: string;
  cart_number: number;
  customer_name?: string;
  customer_phone?: string;
  items: PosCartItem[];
  parked_at: string;
  total: number;
}

export interface PosShift {
  id: string;
  shift_number?: string;
  branch_id: string;
  branch_name: string;
  terminal_code: string;
  device_fingerprint?: string;
  cashier_id?: string;
  cashier_name: string;
  opened_at: string;
  closed_at?: string;
  closed_by_id?: string;
  closed_by_name?: string;
  status: 'open' | 'closed' | 'suspended';
  opening_balance: number;
  cash_sales: number;
  card_sales: number;
  other_sales?: number;
  total_sales: number;
  cash_receipts?: number;
  cash_refunds?: number;
  card_refunds?: number;
  cash_drops?: number;
  expected_cash?: number;
  actual_cash?: number;
  difference?: number;
  transactions_count: number;
  notes?: string;
}

export interface CashierShiftMovement {
  id: string;
  shift_id: string;
  movement_type: 'opening' | 'sale_cash' | 'sale_card' | 'sale_split' | 'receipt' | 'refund_cash' | 'refund_card' | 'cash_drop' | 'closing';
  amount: number;
  payment_method: string;
  reference_id?: string;
  performed_by: string;
  performed_by_id?: string;
  notes?: string;
  created_at: string;
}

export interface InvoiceTemplateRecord {
  id: string;
  name: string;
  branch_id?: string | null;
  is_active: boolean;
  paper_width: '80mm' | '58mm' | 'a4';
  settings: any;
  created_at: string;
  updated_at: string;
}

export interface InvoiceAuditLog {
  id: string;
  order_id?: string;
  order_number: string;
  shift_id?: string;
  print_type: 'original' | 'reprint' | 'electronic_view' | 'preview';
  reprint_count: number;
  printed_by: string;
  printed_by_id?: string;
  device_code: string;
  reprint_reason?: string;
  created_at: string;
}

export interface PosTransaction {
  id: string;
  receipt_number: string;
  branch_id: string;
  branch_name: string;
  terminal_code: string;
  cashier_name: string;
  customer_name?: string;
  customer_phone?: string;
  created_at: string;
  items: PosCartItem[];
  subtotal: number;
  tax_amount: number;
  discount_amount: number;
  grand_total: number;
  payment_method: 'cash' | 'card' | 'split' | 'loyalty';
  cash_received?: number;
  change_given?: number;
  card_amount?: number;
  zatca_qr_payload?: string;
}

export type { InvoiceSettings } from '../lib/invoiceSettings';

// ==========================================
// Staff, Roles, Permissions & Shift System
// ==========================================

export type StaffRole = 
  | 'super_admin'        // مسؤول نظام
  | 'general_manager'    // مدير عام
  | 'auditor'            // مدقق
  | 'accountant'         // محاسب
  | 'cashier'            // كاشير
  | 'branch_manager'     // مدير فرع
  | 'warehouse_manager'; // مدير مستودعات ومشتريات

export interface StaffMember {
  id: string;
  employee_code: string;
  full_name: string;
  username: string;
  email: string;
  phone: string;
  role: StaffRole;
  branch_id: string;
  branch_name: string;
  password?: string;
  can_change_password: boolean; // لا يمكن تغيير كلمة السر إلا بإذن من الإدارة
  has_pending_password_request?: boolean;
  password_request_reason?: string;
  basic_salary: number; // الراتب الأساسي
  allowances: number;   // البدلات
  shift_start: string;  // وقت بدء الدوام HH:mm (e.g. "08:00")
  shift_end: string;    // وقت انتهاء الدوام HH:mm (e.g. "16:00")
  avatar_url?: string;
  is_active: boolean;
  joined_date: string;
  allowed_branch_ids?: string[];
  last_active_at?: string;
  session_revoked_at?: string;
}

export type PayrollTransactionType = 
  | 'salary_payment'     // صرف راتب
  | 'advance_withdrawal' // سحب سلفة / سحبيات
  | 'deduction'          // خصم (تأخير / غياب / جزاءات)
  | 'bonus';             // مكافأة

export interface PayrollTransaction {
  id: string;
  transaction_number: string;
  employee_id: string;
  employee_name: string;
  employee_role: StaffRole;
  branch_id: string;
  branch_name: string;
  type: PayrollTransactionType;
  amount: number;
  reason: string;
  created_by_name: string;
  created_by_role: StaffRole;
  date: string;
  status: 'completed' | 'pending' | 'approved';
  notes?: string;
}

export interface PasswordChangeRequest {
  id: string;
  employee_id: string;
  employee_name: string;
  role: StaffRole;
  branch_name: string;
  requested_at: string;
  reason: string;
  status: 'pending' | 'approved' | 'rejected';
  reviewed_by?: string;
  reviewed_at?: string;
}

// ==============================================================================
// Corporate B2B Sales & Enterprise Accounts Interfaces
// ==============================================================================

export type PaymentTerms = 'Cash' | 'Net-15' | 'Net-30' | 'Net-60';
export type CorporateAccountStatus = 'active' | 'pending_kyc' | 'suspended' | 'overdue';
export type QuotationStatus = 'draft' | 'pending_approval' | 'approved' | 'rejected' | 'converted';
export type CorporateInvoiceStatus = 'unpaid' | 'partially_paid' | 'paid' | 'overdue';
export type CorporateReturnStatus = 'pending_approval' | 'approved' | 'rejected' | 'completed';

export interface CorporateAccount {
  id: string;
  company_name: string;
  cr_number: string;
  vat_number: string;
  contact_person: string;
  phone: string;
  email?: string;
  city: string;
  address?: string;
  branch_id: string;
  monthly_credit_limit: number;
  current_balance: number;
  payment_terms: PaymentTerms;
  status: CorporateAccountStatus;
  recurring_schedule?: string;
  items_summary?: string;
  notes?: string;
  created_by?: string;
  created_at: string;
  updated_at: string;
}

export interface CorporateQuotationItem {
  id?: string;
  quotation_id?: string;
  product_id: string;
  product_name_ar?: string;
  product_name_en?: string;
  barcode?: string;
  quantity: number;
  unit_price: number;
  discount_percent: number;
  final_unit_price: number;
  total_price: number;
  notes?: string;
}

export interface CorporateQuotation {
  id: string;
  quotation_number: string;
  corporate_account_id: string;
  corporate_account_name?: string;
  branch_id: string;
  subtotal: number;
  discount_percent: number;
  discount_amount: number;
  tax_amount: number;
  total_amount: number;
  status: QuotationStatus;
  valid_until: string;
  notes?: string;
  approved_by?: string;
  approved_at?: string;
  rejection_reason?: string;
  created_by?: string;
  created_at: string;
  updated_at: string;
  items?: CorporateQuotationItem[];
}

export interface CorporateInvoiceItem {
  id?: string;
  invoice_id?: string;
  product_id: string;
  product_name_ar?: string;
  product_name_en?: string;
  barcode?: string;
  quantity: number;
  unit_price: number;
  discount_percent: number;
  final_unit_price: number;
  total_price: number;
}

export interface CorporateInvoice {
  id: string;
  invoice_number: string;
  quotation_id?: string;
  corporate_account_id: string;
  corporate_account_name?: string;
  branch_id: string;
  subtotal: number;
  discount_amount: number;
  tax_amount: number;
  total_amount: number;
  paid_amount: number;
  remaining_amount: number;
  payment_status: CorporateInvoiceStatus;
  due_date: string;
  notes?: string;
  created_by?: string;
  created_at: string;
  updated_at: string;
  items?: CorporateInvoiceItem[];
}

export interface CorporatePayment {
  id: string;
  payment_number: string;
  invoice_id: string;
  invoice_number?: string;
  corporate_account_id: string;
  corporate_account_name?: string;
  amount: number;
  payment_method: 'bank_transfer' | 'check' | 'cash' | 'credit_card';
  reference_number: string;
  payment_date: string;
  notes?: string;
  received_by?: string;
  created_at: string;
}

export interface CorporateReturnItem {
  id?: string;
  return_id?: string;
  product_id: string;
  product_name_ar?: string;
  quantity: number;
  unit_price: number;
  total_refund: number;
  reason?: string;
}

export interface CorporateReturn {
  id: string;
  return_number: string;
  invoice_id: string;
  invoice_number?: string;
  corporate_account_id: string;
  corporate_account_name?: string;
  branch_id: string;
  total_refund_amount: number;
  status: CorporateReturnStatus;
  reason: string;
  approved_by?: string;
  approved_at?: string;
  rejection_reason?: string;
  created_by?: string;
  created_at: string;
  updated_at: string;
  items?: CorporateReturnItem[];
}







