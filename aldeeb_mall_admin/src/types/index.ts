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
}

export interface OrderItem {
  id: string;
  product_name_ar: string;
  product_name_en: string;
  product_image?: string;
  unit_price: number;
  quantity: number;
  unit: string;
  total_price: number;
  bin_location?: string;
}

export interface Order {
  id: string;
  order_number: string;
  customer_name: string;
  customer_phone: string;
  customer_address: string;
  status: 'pending' | 'packing' | 'out_for_delivery' | 'delivered' | 'cancelled';
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

export interface PickerTask {
  id: string;
  order_number: string;
  product_name_ar: string;
  bin_location: string;
  barcode: string;
  quantity_required: number;
  quantity_picked: number;
  is_verified: boolean;
  status: 'pending' | 'picked' | 'verified';
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
}

export interface Courier {
  id: string;
  full_name: string;
  phone: string;
  vehicle_type: 'motorbike' | 'van' | 'electric_scooter';
  license_plate: string;
  current_location: string;
  status: 'idle' | 'on_delivery' | 'returning';
  battery_or_fuel: number;
  rating: number;
  assigned_orders_count: number;
  completed_today: number;
}


export interface Supplier {
  id: string;
  name_ar: string;
  name_en: string;
  contact_person: string;
  phone: string;
  email: string;
  lead_time_days: number;
  payment_terms: string;
  active_products_count: number;
  status: 'active' | 'under_review' | 'inactive';
}

export interface PurchaseOrder {
  id: string;
  po_number: string;
  supplier_name: string;
  total_items: number;
  total_cost: number;
  status: 'draft' | 'sent' | 'received' | 'cancelled';
  order_date: string;
  expected_arrival: string;
}

export interface SupportTicket {
  id: string;
  ticket_number: string;
  customer_name: string;
  order_number?: string;
  subject: string;
  status: 'open' | 'in_progress' | 'resolved';
  priority: 'low' | 'medium' | 'high';
  created_at: string;
  last_message: string;
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
  dark_store_code: string;
  radius_km: number;
  base_delivery_fee: number;
  free_delivery_threshold: number;
  estimated_minutes: number;
  is_surge_pricing_active: boolean;
  surge_fee: number;
  is_active: boolean;
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

