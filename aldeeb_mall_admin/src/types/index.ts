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
