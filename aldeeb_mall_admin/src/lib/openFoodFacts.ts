/**
 * Open Food Facts & Regional Barcode Scanner Integration
 * Automatically retrieves product metadata, imagery, and branding on barcode scan.
 */

export interface ScannedProductResult {
  found: boolean;
  name_ar?: string;
  name_en?: string;
  brand?: string;
  image_url?: string;
  unit?: string;
  weight_step?: number;
  category_hint?: string;
  raw_barcode: string;
  source: 'open_food_facts' | 'regional_database';
}

// Regional Syrian & Arab Grocery Offline Cache
const REGIONAL_ARAB_PRODUCTS: Record<string, Omit<ScannedProductResult, 'found' | 'raw_barcode' | 'source'>> = {
  '629100000001': {
    name_ar: 'موز فلبيني طازج كافنديش درجة أولى',
    name_en: 'Fresh Cavendish Bananas',
    brand: 'طازج',
    unit: 'kg',
    weight_step: 0.5,
    category_hint: 'c1',
  },
  '629100000004': {
    name_ar: 'حليب المراعي كامل الدسم طازج 2 لتر',
    name_en: 'Almarai Fresh Milk Full Fat 2L',
    brand: 'المراعي',
    unit: 'piece',
    weight_step: 1,
    category_hint: 'c2',
  },
  '621000100001': {
    name_ar: 'مكدوس سوري بزيت الزيتون والجوز - الدرة 650غ',
    name_en: 'Al Durra Syrian Makdous in Olive Oil 650g',
    brand: 'الدرة (Al Durra)',
    unit: 'piece',
    weight_step: 1,
    category_hint: 'c4',
  },
  '621000200002': {
    name_ar: 'حلاوة طحينية بالفستق الحلبي الفاخر - شتورة 400غ',
    name_en: 'Chtoura Halawa with Pistachio 400g',
    brand: 'شتورة (Chtoura)',
    unit: 'piece',
    weight_step: 1,
    category_hint: 'c4',
  },
  '621000300003': {
    name_ar: 'زعتر بلدي حلبي إكسترا مع السمسم وزيت الزيتون 500غ',
    name_en: 'Syrian Extra Thyme Zaatar 500g',
    brand: 'شاميات',
    unit: 'piece',
    weight_step: 1,
    category_hint: 'c4',
  },
  '3017620422003': {
    name_ar: 'شوكولاتة نوتيلا قابلة للدهن بالبندق والكاكاو 400غ',
    name_en: 'Nutella Hazelnut Spread with Cocoa 400g',
    brand: 'Nutella / Ferrero',
    unit: 'piece',
    weight_step: 1,
    category_hint: 'c4',
  },
};

export async function lookupBarcodeOpenFoodFacts(barcode: string): Promise<ScannedProductResult> {
  const cleanBarcode = barcode.trim();
  if (!cleanBarcode) {
    return { found: false, raw_barcode: barcode, source: 'regional_database' };
  }

  // 1. Check local regional cache first (fastest, zero network delay)
  if (REGIONAL_ARAB_PRODUCTS[cleanBarcode]) {
    const cached = REGIONAL_ARAB_PRODUCTS[cleanBarcode];
    return {
      found: true,
      ...cached,
      raw_barcode: cleanBarcode,
      source: 'regional_database',
    };
  }

  // 2. Query Open Food Facts global API
  try {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 4500);

    const response = await fetch(`https://world.openfoodfacts.org/api/v2/product/${encodeURIComponent(cleanBarcode)}.json`, {
      signal: controller.signal,
      headers: {
        'User-Agent': 'AldeebMall-Enterprise/1.0 (info@aldeebmall.com)',
      },
    });

    clearTimeout(timeoutId);

    if (!response.ok) {
      return { found: false, raw_barcode: cleanBarcode, source: 'open_food_facts' };
    }

    const data = await response.json();
    if (data.status === 1 && data.product) {
      const prod = data.product;
      const nameAr = prod.product_name_ar || prod.product_name || prod.generic_name_ar;
      const nameEn = prod.product_name_en || prod.product_name || '';
      const brand = prod.brands || 'منتج مستورد';
      const imageUrl = prod.image_front_url || prod.image_url || '';
      
      let unit = 'piece';
      if (prod.quantity && prod.quantity.includes('kg')) {
        unit = 'kg';
      }

      return {
        found: true,
        name_ar: nameAr || nameEn,
        name_en: nameEn || nameAr,
        brand,
        image_url: imageUrl,
        unit,
        weight_step: unit === 'kg' ? 0.5 : 1,
        raw_barcode: cleanBarcode,
        source: 'open_food_facts',
      };
    }
  } catch (_) {
    // Network or abort error: fail gracefully without fake data
  }

  return { found: false, raw_barcode: cleanBarcode, source: 'open_food_facts' };
}
