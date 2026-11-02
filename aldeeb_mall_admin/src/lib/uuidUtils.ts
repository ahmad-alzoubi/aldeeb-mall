/**
 * UUID and Canonical Mapping Utilities
 * Aldeeb Mall & Hypermarket Multi-Platform Suite
 * Ensures 100% PostgreSQL UUID compliance and zero syntax errors.
 */

export const CANONICAL_CATEGORY_MAP: Record<string, string> = {
  // Legacy short codes to Supabase UUIDs
  'c1': 'c0000000-0000-0000-0000-000000000001',
  'c2': 'c0000000-0000-0000-0000-000000000002',
  'c3': 'c0000000-0000-0000-0000-000000000003',
  'c4': 'c0000000-0000-0000-0000-000000000004',
  'c5': 'c0000000-0000-0000-0000-000000000005',
  'c6': 'c0000000-0000-0000-0000-000000000006',
  'c7': 'c0000000-0000-0000-0000-000000000007',
  'c8': 'c0000000-0000-0000-0000-000000000008',
  'c9': 'c0000000-0000-0000-0000-000000000009',
  'c10': 'c0000000-0000-0000-0000-000000000010',
  'c11': 'c0000000-0000-0000-0000-000000000011',

  // Slugs & descriptive IDs to Supabase UUIDs
  'fresh-produce': 'c0000000-0000-0000-0000-000000000001',
  'c_ready_meals': 'c0000000-0000-0000-0000-000000000001',
  'dairy-eggs': 'c0000000-0000-0000-0000-000000000002',
  'c_chilled': 'c0000000-0000-0000-0000-000000000002',
  'meat-poultry': 'c0000000-0000-0000-0000-000000000003',
  'bakery-pastries': 'c0000000-0000-0000-0000-000000000004',
  'beverages-water': 'c0000000-0000-0000-0000-000000000005',
  'c_supermarket': 'c0000000-0000-0000-0000-000000000005',
  'frozen-foods': 'c0000000-0000-0000-0000-000000000006',
  'c_frozen': 'c0000000-0000-0000-0000-000000000006',
  'pantry-cooking': 'c0000000-0000-0000-0000-000000000007',
  'c_paper': 'c0000000-0000-0000-0000-000000000007',
  'cleaning-household': 'c0000000-0000-0000-0000-000000000008',
  'c_beauty': 'c0000000-0000-0000-0000-000000000008',
  'c_baby': 'c0000000-0000-0000-0000-000000000008',
  'electronics-appliances': 'c0000000-0000-0000-0000-000000000009',
  'c_pets': 'c0000000-0000-0000-0000-000000000009',
  'home-garden': 'c0000000-0000-0000-0000-000000000010',
  'c_clothing': 'c0000000-0000-0000-0000-000000000010',
  'c_accessories': 'c0000000-0000-0000-0000-000000000010',
  'c_sports': 'c0000000-0000-0000-0000-000000000010',
  'c_stationery': 'c0000000-0000-0000-0000-000000000010',
  'c_toys': 'c0000000-0000-0000-0000-000000000010',
  'home-appliances': 'c0000000-0000-0000-0000-000000000011',
  'c_essentials': 'c0000000-0000-0000-0000-000000000011',
};

/**
 * Validates if string is a valid standard UUID
 */
export const isValidUUID = (str?: string | null): boolean => {
  if (!str || typeof str !== 'string') return false;
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(str);
};

/**
 * Generates RFC4122 compliant UUID v4
 */
export const generateUUID = (): string => {
  if (typeof crypto !== 'undefined' && typeof crypto.randomUUID === 'function') {
    return crypto.randomUUID();
  }
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0;
    const v = c === 'x' ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
};

/**
 * Ensures ID is a valid UUID, otherwise returns a generated UUID v4
 */
export const ensureUUID = (id?: string | null): string => {
  if (id && isValidUUID(id)) return id;
  return generateUUID();
};

/**
 * Normalizes any category string/legacy ID into a guaranteed canonical Supabase UUID
 */
export const toCanonicalCategoryId = (rawId?: string | null): string => {
  if (!rawId) return 'c0000000-0000-0000-0000-000000000001';
  if (isValidUUID(rawId)) return rawId;
  return CANONICAL_CATEGORY_MAP[rawId] || 'c0000000-0000-0000-0000-000000000001';
};
