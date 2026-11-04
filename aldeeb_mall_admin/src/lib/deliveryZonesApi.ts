import { supabase } from './supabase';
import { DeliveryZone } from '../types';
import { initialDeliveryZones } from './supabase';

export interface CoverageCheckRequest {
  latitude?: number;
  longitude?: number;
  city?: string;
  district?: string;
  subtotal?: number;
  deliverySlot?: string;
}

export interface CoverageCheckResponse {
  is_covered: boolean;
  status: 'ALLOWED' | 'REJECTED';
  message: string;
  rejection_reason?: 'OUT_OF_COVERAGE' | 'ZONE_INACTIVE' | 'BRANCH_CLOSED' | 'OUTSIDE_OPERATING_HOURS';
  zone_id?: string;
  zone_name_ar?: string;
  city?: string;
  district?: string;
  branch_id?: string;
  branch_name_ar?: string;
  dark_store_code?: string;
  distance_km?: number;
  radius_km?: number;
  base_delivery_fee?: number;
  is_surge_active?: boolean;
  surge_fee?: number;
  surge_applied?: boolean;
  final_delivery_fee?: number;
  free_delivery_threshold?: number;
  is_free_delivery?: boolean;
  estimated_minutes?: number;
  opening_time?: string;
  closing_time?: string;
  delivery_options?: Array<{
    id: string;
    name_ar: string;
    fee_modifier?: number;
    estimated_minutes?: number;
  }>;
}

export const deliveryZonesApi = {
  /**
   * Fetches authoritative delivery zones from PostgreSQL / PostgREST.
   * Resilient fallback to initialDeliveryZones if offline or connection fails.
   */
  async getDeliveryZones(): Promise<DeliveryZone[]> {
    try {
      const { data, error } = await supabase
        .from('delivery_zones')
        .select('*')
        .order('is_active', { ascending: false })
        .order('city', { ascending: true });

      if (error) {
        console.warn('⚠️ [deliveryZonesApi] Could not fetch from server, fallback to local seeds:', error.message);
        return initialDeliveryZones;
      }

      if (data && data.length > 0) {
        return data as DeliveryZone[];
      }
      return initialDeliveryZones;
    } catch (err) {
      console.warn('⚠️ [deliveryZonesApi] Exception querying server:', err);
      return initialDeliveryZones;
    }
  },

  /**
   * Upserts or creates a delivery zone on the server.
   */
  async saveDeliveryZone(zone: Partial<DeliveryZone>): Promise<DeliveryZone> {
    const payload = {
      ...zone,
      updated_at: new Date().toISOString(),
    };

    const { data, error } = await supabase
      .from('delivery_zones')
      .upsert(payload)
      .select()
      .single();

    if (error) {
      throw new Error(`فشل حفظ نطاق التوصيل في الخادم: ${error.message}`);
    }

    return data as DeliveryZone;
  },

  /**
   * Updates surge pricing toggle and fee on the server.
   */
  async setSurgePricing(zoneId: string, isActive: boolean, surgeFee: number): Promise<DeliveryZone> {
    const { data, error } = await supabase
      .from('delivery_zones')
      .update({
        is_surge_pricing_active: isActive,
        surge_fee: surgeFee,
        updated_at: new Date().toISOString(),
      })
      .eq('id', zoneId)
      .select()
      .single();

    if (error) {
      throw new Error(`فشل تحديث تسعير الذروة في الخادم: ${error.message}`);
    }

    return data as DeliveryZone;
  },

  /**
   * Toggles zone operational status (active/inactive) on the server.
   */
  async toggleZoneStatus(zoneId: string, isActive: boolean): Promise<DeliveryZone> {
    const { data, error } = await supabase
      .from('delivery_zones')
      .update({
        is_active: isActive,
        updated_at: new Date().toISOString(),
      })
      .eq('id', zoneId)
      .select()
      .single();

    if (error) {
      throw new Error(`فشل تغيير حالة النطاق في الخادم: ${error.message}`);
    }

    return data as DeliveryZone;
  },

  /**
   * Performs server-authoritative delivery coverage, branch assignment, and fee calculation.
   */
  async checkCoverage(params: CoverageCheckRequest): Promise<CoverageCheckResponse> {
    const { data, error } = await supabase.rpc('check_delivery_coverage', {
      p_latitude: params.latitude ?? null,
      p_longitude: params.longitude ?? null,
      p_city: params.city ?? null,
      p_district: params.district ?? null,
      p_subtotal: params.subtotal ?? 0.0,
      p_delivery_slot: params.deliverySlot ?? null,
    });

    if (error) {
      throw new Error(`فشل فحص التغطية في الخادم: ${error.message}`);
    }

    return data as CoverageCheckResponse;
  }
};
