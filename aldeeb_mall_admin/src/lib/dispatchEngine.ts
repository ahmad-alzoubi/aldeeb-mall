/**
 * 🛵🚗 Smart Fleet Dispatch & Vehicle Categorization Engine
 * Decides whether an order requires a Motorcycle or a Delivery Car/Van
 * based on weight, cubic volume, physical dimensions, and driver capacity.
 */

export interface PackagingFactor {
  weight_multiplier: number; // e.g. 1.05 (5% extra packaging weight)
  volume_buffer_liters: number; // e.g. 2 liters per order
}

export interface VehicleCapacityConfig {
  motorcycleMaxWeightKg: number;      // Configurable (default: 25 kg, bounds 20-30 kg)
  motorcycleMaxVolumeLiters: number;  // Configurable (default: 60 L)
  motorcycleMaxDimensionCm: number;   // Max single item side (default: 50 cm)
  carMaxWeightKg: number;             // Configurable (default: 350 kg)
  carMaxVolumeLiters: number;         // Configurable (default: 800 L)
  carMaxDimensionCm: number;          // Max single item side (default: 150 cm)
}

export const DEFAULT_VEHICLE_CONFIG: VehicleCapacityConfig = {
  motorcycleMaxWeightKg: 25.0,
  motorcycleMaxVolumeLiters: 60.0,
  motorcycleMaxDimensionCm: 50.0,
  carMaxWeightKg: 350.0,
  carMaxVolumeLiters: 800.0,
  carMaxDimensionCm: 150.0,
};

export const DEFAULT_PACKAGING_FACTOR: PackagingFactor = {
  weight_multiplier: 1.05,
  volume_buffer_liters: 3.0,
};

export interface OrderItemPhysicalSpec {
  id: string;
  name: string;
  quantity: number;
  weight_kg?: number;
  width_cm?: number;
  height_cm?: number;
  length_cm?: number;
  volume_liters?: number;
}

export interface DispatchRecommendation {
  vehicle_type: 'motorcycle' | 'car' | 'manual_review';
  decision_code: 
    | 'MOTORCYCLE_FIT'
    | 'CAR_EXCEEDS_WEIGHT'
    | 'CAR_EXCEEDS_VOLUME'
    | 'CAR_EXCEEDS_DIMENSION'
    | 'MANUAL_EXCEEDS_CAR_CAPACITY'
    | 'MANUAL_MISSING_SPECS';
  reason_ar: string;
  total_weight_kg: number;
  total_volume_liters: number;
  missing_specs_count: number;
  items_with_missing_specs: string[];
  max_item_dimension_cm: number;
  reservation_token: string;
}

/**
 * Calculates total weight, volume, and selects vehicle type
 */
export function evaluateOrderDispatch(
  items: OrderItemPhysicalSpec[],
  config: VehicleCapacityConfig = DEFAULT_VEHICLE_CONFIG,
  packaging: PackagingFactor = DEFAULT_PACKAGING_FACTOR
): DispatchRecommendation {
  let netWeightKg = 0;
  let netVolumeLiters = 0;
  let missingCount = 0;
  const missingItems: string[] = [];
  let maxDimension = 0;

  for (const item of items) {
    // Check weight
    if (typeof item.weight_kg === 'number' && item.weight_kg > 0) {
      netWeightKg += item.weight_kg * item.quantity;
    } else {
      missingCount++;
      missingItems.push(`${item.name} (وزن مفقود)`);
      // Standard estimation: 0.5 kg per unspecified grocery unit
      netWeightKg += 0.5 * item.quantity;
    }

    // Check dimensions & volume
    let itemVolume = 0;
    if (item.volume_liters && item.volume_liters > 0) {
      itemVolume = item.volume_liters;
    } else if (item.length_cm && item.width_cm && item.height_cm) {
      itemVolume = (item.length_cm * item.width_cm * item.height_cm) / 1000; // cm3 to liters
    } else {
      missingCount++;
      missingItems.push(`${item.name} (أبعاد وحجم مفقود)`);
      // Standard grocery unit volume estimate: 1.2 liters
      itemVolume = 1.2;
    }
    netVolumeLiters += itemVolume * item.quantity;

    // Track max single dimension
    const singleMax = Math.max(item.length_cm || 0, item.width_cm || 0, item.height_cm || 0);
    if (singleMax > maxDimension) {
      maxDimension = singleMax;
    }
  }

  // Apply packaging factors
  const grossWeightKg = Math.round(netWeightKg * packaging.weight_multiplier * 100) / 100;
  const grossVolumeLiters = Math.round((netVolumeLiters + packaging.volume_buffer_liters) * 100) / 100;

  // Generate an atomic reservation token to prevent concurrent double-booking of drivers
  const reservationToken = `RES-${Date.now()}-${Math.random().toString(36).substring(2, 8).toUpperCase()}`;

  // Evaluate capacity
  if (missingCount > items.length * 0.5) {
    return {
      vehicle_type: 'manual_review',
      decision_code: 'MANUAL_MISSING_SPECS',
      reason_ar: `أكثر من 50% من سلع الطلب تفتقر إلى أوزان أو أبعاد مسجلة بدقة. تم توجيه الطلب للمراجعة البشرية والتوزين الميداني.`,
      total_weight_kg: grossWeightKg,
      total_volume_liters: grossVolumeLiters,
      missing_specs_count: missingCount,
      items_with_missing_specs: missingItems,
      max_item_dimension_cm: maxDimension,
      reservation_token: reservationToken,
    };
  }

  if (grossWeightKg > config.carMaxWeightKg || grossVolumeLiters > config.carMaxVolumeLiters || maxDimension > config.carMaxDimensionCm) {
    return {
      vehicle_type: 'manual_review',
      decision_code: 'MANUAL_EXCEEDS_CAR_CAPACITY',
      reason_ar: `إجمالي الشحنة (${grossWeightKg} كغ، ${grossVolumeLiters} لتر) يتجاوز سعة السيارة القياسية القصوى. يتطلب تقسيم الطلب أو شاحنة نقل مخصصة.`,
      total_weight_kg: grossWeightKg,
      total_volume_liters: grossVolumeLiters,
      missing_specs_count: missingCount,
      items_with_missing_specs: missingItems,
      max_item_dimension_cm: maxDimension,
      reservation_token: reservationToken,
    };
  }

  // Check if fits motorcycle
  const fitsMotorcycleWeight = grossWeightKg <= config.motorcycleMaxWeightKg;
  const fitsMotorcycleVolume = grossVolumeLiters <= config.motorcycleMaxVolumeLiters;
  const fitsMotorcycleDimension = maxDimension <= config.motorcycleMaxDimensionCm;

  if (fitsMotorcycleWeight && fitsMotorcycleVolume && fitsMotorcycleDimension) {
    return {
      vehicle_type: 'motorcycle',
      decision_code: 'MOTORCYCLE_FIT',
      reason_ar: `الطلب يطابق حدود الدراجة النارية بالكامل (الوزن: ${grossWeightKg} كغ ≤ ${config.motorcycleMaxWeightKg} كغ، الحجم: ${grossVolumeLiters} لتر ≤ ${config.motorcycleMaxVolumeLiters} لتر).`,
      total_weight_kg: grossWeightKg,
      total_volume_liters: grossVolumeLiters,
      missing_specs_count: missingCount,
      items_with_missing_specs: missingItems,
      max_item_dimension_cm: maxDimension,
      reservation_token: reservationToken,
    };
  }

  // Needs car
  let carReason = '';
  let decisionCode: DispatchRecommendation['decision_code'] = 'CAR_EXCEEDS_WEIGHT';
  if (!fitsMotorcycleWeight) {
    carReason = `الوزن الإجمالي (${grossWeightKg} كغ) يتجاوز الحد الأقصى للدراجة (${config.motorcycleMaxWeightKg} كغ).`;
    decisionCode = 'CAR_EXCEEDS_WEIGHT';
  } else if (!fitsMotorcycleVolume) {
    carReason = `الحجم الإجمالي (${grossVolumeLiters} لتر) يتجاوز سعة صندوق الدراجة (${config.motorcycleMaxVolumeLiters} لتر).`;
    decisionCode = 'CAR_EXCEEDS_VOLUME';
  } else {
    carReason = `أحد الطرود بطول (${maxDimension} سم) يتجاوز الأبعاد الهندسية الآمنة لصندوق الدراجة (${config.motorcycleMaxDimensionCm} سم).`;
    decisionCode = 'CAR_EXCEEDS_DIMENSION';
  }

  return {
    vehicle_type: 'car',
    decision_code: decisionCode,
    reason_ar: `تم الإسناد لسيارة توصيل: ${carReason}`,
    total_weight_kg: grossWeightKg,
    total_volume_liters: grossVolumeLiters,
    missing_specs_count: missingCount,
    items_with_missing_specs: missingItems,
    max_item_dimension_cm: maxDimension,
    reservation_token: reservationToken,
  };
}
