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
}

export interface Order {
  id: string;
  order_number: string;
  customer_name: string;
  customer_phone: string;
  customer_address: string;
  status: 'pending' | 'packing' | 'out_for_delivery' | 'delivered' | 'cancelled';
  delivery_slot: string;
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
