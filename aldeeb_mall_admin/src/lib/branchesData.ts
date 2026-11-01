import { Branch } from '../types';

export const INITIAL_BRANCHES: Branch[] = [
  {
    id: 'b-ruh-01',
    code: 'BR-RUH-01',
    name_ar: 'هايبرماركت الرياض الرئيسي (المركز الفاخر)',
    name_en: 'Riyadh Flagship Hypermarket',
    city: 'الرياض',
    district: 'العليا - طريق الملك فهد',
    address: 'تقاطع طريق الملك فهد مع شارع التحلية، الرياض',
    phone: '+966 11 456 7890',
    manager_name: 'م. حسام الديب',
    is_active: true,
    terminals_count: 8,
    daily_sales: 142500,
    currency: 'ل.س',
    type: 'hypermarket',
    created_at: '2026-01-15T08:00:00Z',
  },
  {
    id: 'b-jed-01',
    code: 'BR-JED-01',
    name_ar: 'فرع جدة الكورنيش (واجهة البحر)',
    name_en: 'Jeddah Corniche Supermarket',
    city: 'جدة',
    district: 'الشاطئ - طريق الكورنيش',
    address: 'شارع حراء، حي الشاطئ، جدة',
    phone: '+966 12 654 3210',
    manager_name: 'رامي القحطاني',
    is_active: true,
    terminals_count: 5,
    daily_sales: 89400,
    currency: 'ل.س',
    type: 'supermarket',
    created_at: '2026-02-10T09:00:00Z',
  },
  {
    id: 'b-dmm-01',
    code: 'BR-DMM-01',
    name_ar: 'فرع الدمام الشاطئ ومول الشرقية',
    name_en: 'Dammam Eastern Province Branch',
    city: 'الدمام',
    district: 'الشاطئ الشرقي - طريق الخليج',
    address: 'مجمع الشاطئ مول، طريق الخليج العربي، الدمام',
    phone: '+966 13 888 4422',
    manager_name: 'ناصر الشمري',
    is_active: true,
    terminals_count: 6,
    daily_sales: 96200,
    currency: 'ل.س',
    type: 'hypermarket',
    created_at: '2026-03-01T10:00:00Z',
  },
  {
    id: 'b-dam-01',
    code: 'BR-DAM-01',
    name_ar: 'فرع دمشق المركزي (أوتوستراد المزة)',
    name_en: 'Damascus Central Supermarket',
    city: 'دمشق',
    district: 'المزة - الفيلات الشرقية',
    address: 'أوتوستراد المزة، جانب مشفى الرازي، دمشق',
    phone: '+963 11 611 2233',
    manager_name: 'وائل خوري',
    is_active: true,
    terminals_count: 5,
    daily_sales: 115000,
    currency: 'ل.س',
    type: 'supermarket',
    created_at: '2026-03-20T11:00:00Z',
  },
  {
    id: 'b-ruh-ds02',
    code: 'BR-RUH-DS02',
    name_ar: 'مركز تلبية النرجس فوري 15 دقيقة (Dark Store)',
    name_en: 'Al-Narjis Express Dark Store',
    city: 'الرياض',
    district: 'النرجس - شمال الرياض',
    address: 'حي النرجس، مخرج 7، الرياض',
    phone: '+966 11 999 0011',
    manager_name: 'سامي العتيبي',
    is_active: true,
    terminals_count: 3,
    daily_sales: 62000,
    currency: 'ل.س',
    type: 'dark_store',
    created_at: '2026-04-05T08:30:00Z',
  },
];

const LOCAL_STORAGE_KEY = 'aldeeb_branches_data_v1';
const ACTIVE_BRANCH_KEY = 'aldeeb_active_branch_id_v1';

export function getStoredBranches(): Branch[] {
  try {
    const raw = localStorage.getItem(LOCAL_STORAGE_KEY);
    if (raw) {
      return JSON.parse(raw);
    }
  } catch (_) {}
  return INITIAL_BRANCHES;
}

export function saveStoredBranches(branches: Branch[]) {
  try {
    localStorage.setItem(LOCAL_STORAGE_KEY, JSON.stringify(branches));
  } catch (_) {}
}

export function getActiveBranchId(): string {
  try {
    const active = localStorage.getItem(ACTIVE_BRANCH_KEY);
    if (active) return active;
  } catch (_) {}
  return INITIAL_BRANCHES[0].id;
}

export function setActiveBranchId(id: string) {
  try {
    localStorage.setItem(ACTIVE_BRANCH_KEY, id);
  } catch (_) {}
}
