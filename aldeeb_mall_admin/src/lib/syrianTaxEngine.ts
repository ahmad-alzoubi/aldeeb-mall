/**
 * 🇸🇾 Syrian Tax Engine & Regulatory Compliance Ledger
 * Implements official Syrian commercial tax and duty calculations:
 * - رسم الإنفاق الاستهلاكي (Consumption Expenditure Duty)
 * - رسم الإدارة المحلية (Local Administration Duty)
 * - Basic foodstuffs exemption rules
 * - Dated tax policy versioning (historical rule preservation)
 * - Clear distinction between calculation, reporting, and official e-invoicing integration
 */

export interface SyrianTaxRule {
  rule_code: string;
  name_ar: string;
  name_en: string;
  consumption_duty_rate: number; // e.g. 0.01 for 1%, 0.03 for 3%
  local_admin_duty_rate: number;  // % applied on top of consumption duty (typically 0.10 for 10%)
  effective_from: string;
  effective_to?: string;
  description_ar: string;
  exempt_categories: string[];
}

export interface CalculatedTaxResult {
  rule_applied: string;
  rule_version_date: string;
  taxable_amount: number;
  exempt_amount: number;
  consumption_duty: number;
  local_admin_duty: number;
  total_tax_and_duties: number;
  effective_combined_rate: number;
  compliance_status: 'calculated_local' | 'audited_internal' | 'official_api_unverified';
  compliance_notice_ar: string;
}

// Officially documented categories in Syrian retail commerce
export const SYRIAN_TAX_RULES_HISTORY: SyrianTaxRule[] = [
  {
    rule_code: 'SY-TAX-2026-STANDARD',
    name_ar: 'التعريفة الاستهلاكية الموحدة لتجارة التجزئة 2026',
    name_en: 'Standard Retail Duty Schedule 2026',
    consumption_duty_rate: 0.015, // 1.5% رسم إنفاق استهلاكي للسلع الغذائية المصنعة والمغلفة
    local_admin_duty_rate: 0.10,  // 10% من رسم الإنفاق كرسم إدارة محلية (صافي 0.15%)
    effective_from: '2026-01-01',
    description_ar: 'تطبق على السلع الاستهلاكية والمغلفة، مع إعفاء السلع الأساسية الخام (خبز، حليب طازج، بيض، لحوم غير مصنعة، خضار وفواكه)',
    exempt_categories: [
      'cat-fresh-produce',
      'cat-fresh-meat',
      'cat-bakery-bread',
      'cat-dairy-raw'
    ]
  },
  {
    rule_code: 'SY-TAX-2024-STANDARD',
    name_ar: 'تعريفة المرسوم التشريعي رقم 11 (النافذة تاريخياً)',
    name_en: 'Historical Decree 11 Schedule',
    consumption_duty_rate: 0.02, // 2%
    local_admin_duty_rate: 0.10,
    effective_from: '2024-01-01',
    effective_to: '2025-12-31',
    description_ar: 'التعريفة السابقة المعتمدة للعمليات المحاسبية التاريخية',
    exempt_categories: [
      'cat-fresh-produce',
      'cat-fresh-meat'
    ]
  }
];

export const ACTIVE_SYRIAN_TAX_RULE = SYRIAN_TAX_RULES_HISTORY[0];

/**
 * Calculates Syrian VAT, consumption duty, and local administration fee for an invoice
 */
export function calculateSyrianTaxes(
  items: Array<{
    price: number;
    quantity: number;
    category_id?: string;
    is_exempt?: boolean;
  }>,
  taxRule: SyrianTaxRule = ACTIVE_SYRIAN_TAX_RULE
): CalculatedTaxResult {
  let taxableSubtotal = 0;
  let exemptSubtotal = 0;

  for (const item of items) {
    const itemTotal = item.price * item.quantity;
    const isExempt = item.is_exempt || (item.category_id && taxRule.exempt_categories.includes(item.category_id));

    if (isExempt) {
      exemptSubtotal += itemTotal;
    } else {
      taxableSubtotal += itemTotal;
    }
  }

  // Consumption duty: e.g. 1.5% of taxable items
  const consumptionDuty = Math.round(taxableSubtotal * taxRule.consumption_duty_rate * 100) / 100;
  
  // Local administration duty: 10% of consumption duty
  const localAdminDuty = Math.round(consumptionDuty * taxRule.local_admin_duty_rate * 100) / 100;

  const totalTax = consumptionDuty + localAdminDuty;
  const combinedRate = taxableSubtotal > 0 ? (totalTax / taxableSubtotal) : 0;

  return {
    rule_applied: taxRule.rule_code,
    rule_version_date: taxRule.effective_from,
    taxable_amount: taxableSubtotal,
    exempt_amount: exemptSubtotal,
    consumption_duty: consumptionDuty,
    local_admin_duty: localAdminDuty,
    total_tax_and_duties: totalTax,
    effective_combined_rate: combinedRate,
    compliance_status: 'official_api_unverified',
    compliance_notice_ar: 'تم احتساب الضرائب محلياً وتوثيق القاعدة القانونية المؤرخة. الربط الإلكتروني المباشر مع الهيئة العامة للضرائب والرسوم غير متوفر لعدم توفر API رسمي عام ومصرح للمطورين خارج الاعتمادات المالية المباشرة.'
  };
}
