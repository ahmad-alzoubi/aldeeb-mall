import { useState, useEffect } from 'react';
import QRCode from 'qrcode';

export interface InvoiceSettings {
  // Store info & Header
  storeNameAr: string;
  storeNameEn: string;
  branchName: string;
  taxNumber: string;
  commercialRegister: string;
  phone: string;
  address: string;
  headerSubtitle: string;
  logoUrl: string;
  logoHeight: number;

  // Layout & Styling
  paperWidth: '80mm' | '58mm' | 'a4';
  fontSize: 'sm' | 'md' | 'lg';
  fontFamily: 'cairo' | 'mono' | 'sans';
  dividerStyle: 'dashed' | 'dotted' | 'solid' | 'double';
  accentColor: string;
  headerAlignment: 'center' | 'right';
  compactItemSpacing: boolean;

  // Visibility Toggles (Show / Hide Elements)
  showLogo: boolean;
  showStoreName: boolean;
  showBranchName: boolean;
  showTaxNumber: boolean;
  showCommercialRegister: boolean;
  showPhone: boolean;
  showAddress: boolean;
  showSubtitle: boolean;
  showInvoiceNumber: boolean;
  showDateTime: boolean;
  showCashierName: boolean;
  showTerminalCode: boolean;
  showCustomerName: boolean;
  showCustomerPhone: boolean;
  showBarcodeUnderNumber: boolean;
  showItemCode: boolean;
  showItemUnitPrice: boolean;
  showSubtotal: boolean;
  showTaxAmount: boolean;
  showTaxRate: boolean;
  taxRatePercent: number;
  showDiscountAmount: boolean;
  showGrandTotal: boolean;
  showPaymentMethod: boolean;
  showCashReceivedAndChange: boolean;
  showQrCode: boolean;
  qrCodeSize: number;
  qrType: 'electronic_url' | 'zatca_tlv';
  showReturnPolicy: boolean;
  showCustomFooterNote: boolean;
  showSecurityBadge: boolean;

  // Custom Texts
  returnPolicyText: string;
  customFooterNote: string;
  securityBadgeText: string;
}

export const DEFAULT_INVOICE_SETTINGS: InvoiceSettings = {
  storeNameAr: 'الديب مول | ALDEEB MALL',
  storeNameEn: 'ALDEEB HYPERMARKET & RETAIL',
  branchName: 'الفرع الرئيسي - برج الديب التجاري',
  taxNumber: '300123456700003',
  commercialRegister: 'CR-1010884920',
  phone: '800-ALDEEB • 011-2345678',
  address: 'دمشق - المزة أوتوستراد - مجمع الديب التجاري',
  headerSubtitle: 'فاتورة ضريبية مبسطة (Simplified Tax Invoice)',
  logoUrl: 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=120&auto=format&fit=crop&q=60',
  logoHeight: 46,

  paperWidth: '80mm',
  fontSize: 'md',
  fontFamily: 'cairo',
  dividerStyle: 'dashed',
  accentColor: '#0f172a',
  headerAlignment: 'center',
  compactItemSpacing: false,

  showLogo: true,
  showStoreName: true,
  showBranchName: true,
  showTaxNumber: true,
  showCommercialRegister: true,
  showPhone: true,
  showAddress: false,
  showSubtitle: true,
  showInvoiceNumber: true,
  showDateTime: true,
  showCashierName: true,
  showTerminalCode: true,
  showCustomerName: true,
  showCustomerPhone: false,
  showBarcodeUnderNumber: true,
  showItemCode: false,
  showItemUnitPrice: true,
  showSubtotal: true,
  showTaxAmount: true,
  showTaxRate: true,
  taxRatePercent: 15,
  showDiscountAmount: true,
  showGrandTotal: true,
  showPaymentMethod: true,
  showCashReceivedAndChange: true,
  showQrCode: true,
  qrCodeSize: 104,
  qrType: 'electronic_url',
  showReturnPolicy: true,
  showCustomFooterNote: true,
  showSecurityBadge: true,

  returnPolicyText: 'البضاعة المباعة ترد وتستبدل خلال 7 أيام بشرط سلامة الغلاف والإيصال الأصلي.',
  customFooterNote: 'شكراً لتسوقكم من الديب مول! نسعد بخدمتكم دائماً • aldbeeb-mall.com',
  securityBadgeText: 'فاتورة إلكترونية نظامية معتمدة ومسجلة رسمياً',
};

const STORAGE_KEY = 'aldeeb_invoice_settings';
const EVENT_NAME = 'aldeeb_invoice_settings_updated';

export function getInvoiceSettings(): InvoiceSettings {
  if (typeof window === 'undefined') return DEFAULT_INVOICE_SETTINGS;
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return DEFAULT_INVOICE_SETTINGS;
    return { ...DEFAULT_INVOICE_SETTINGS, ...JSON.parse(raw) };
  } catch (err) {
    console.error('Failed to parse invoice settings from localStorage', err);
    return DEFAULT_INVOICE_SETTINGS;
  }
}

export function saveInvoiceSettings(settings: InvoiceSettings): void {
  if (typeof window === 'undefined') return;
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(settings));
    window.dispatchEvent(new CustomEvent(EVENT_NAME, { detail: settings }));
  } catch (err) {
    console.error('Failed to save invoice settings', err);
  }
}

export function resetInvoiceSettings(): InvoiceSettings {
  if (typeof window !== 'undefined') {
    localStorage.removeItem(STORAGE_KEY);
    window.dispatchEvent(new CustomEvent(EVENT_NAME, { detail: DEFAULT_INVOICE_SETTINGS }));
  }
  return DEFAULT_INVOICE_SETTINGS;
}

export function useInvoiceSettings(): [InvoiceSettings, (s: InvoiceSettings) => void] {
  const [settings, setSettings] = useState<InvoiceSettings>(() => getInvoiceSettings());

  useEffect(() => {
    const handleUpdate = (e: Event) => {
      const customEvent = e as CustomEvent<InvoiceSettings>;
      if (customEvent.detail) {
        setSettings(customEvent.detail);
      } else {
        setSettings(getInvoiceSettings());
      }
    };

    const handleStorage = (e: StorageEvent) => {
      if (e.key === STORAGE_KEY) {
        setSettings(getInvoiceSettings());
      }
    };

    window.addEventListener(EVENT_NAME, handleUpdate);
    window.addEventListener('storage', handleStorage);
    return () => {
      window.removeEventListener(EVENT_NAME, handleUpdate);
      window.removeEventListener('storage', handleStorage);
    };
  }, []);

  const update = (newSettings: InvoiceSettings) => {
    saveInvoiceSettings(newSettings);
    setSettings(newSettings);
  };

  return [settings, update];
}

// Generate high quality QR code data URL
export async function generateQrCodeDataUrl(
  content: string,
  width: number = 256
): Promise<string> {
  try {
    return await QRCode.toDataURL(content, {
      width,
      margin: 1,
      errorCorrectionLevel: 'M',
      color: {
        dark: '#0f172a',
        light: '#ffffff',
      },
    });
  } catch (err) {
    console.error('Failed to generate QR code data URL', err);
    return '';
  }
}

// TLV encoder for standard ZATCA Phase 1 / Phase 2 e-invoices
export function generateZatcaTlvBase64(
  sellerName: string,
  vatRegistrationNumber: string,
  timestampIso: string,
  invoiceTotalWithVat: string,
  vatTotal: string
): string {
  try {
    const getTlv = (tag: number, value: string): Uint8Array => {
      const utf8Encoder = new TextEncoder();
      const valBytes = utf8Encoder.encode(value);
      const tagByte = tag;
      const lenByte = valBytes.length;
      const result = new Uint8Array(2 + lenByte);
      result[0] = tagByte;
      result[1] = lenByte;
      result.set(valBytes, 2);
      return result;
    };

    const tlv1 = getTlv(1, sellerName);
    const tlv2 = getTlv(2, vatRegistrationNumber);
    const tlv3 = getTlv(3, timestampIso);
    const tlv4 = getTlv(4, invoiceTotalWithVat);
    const tlv5 = getTlv(5, vatTotal);

    const totalLen = tlv1.length + tlv2.length + tlv3.length + tlv4.length + tlv5.length;
    const combined = new Uint8Array(totalLen);
    let offset = 0;
    for (const chunk of [tlv1, tlv2, tlv3, tlv4, tlv5]) {
      combined.set(chunk, offset);
      offset += chunk.length;
    }

    let binary = '';
    const len = combined.byteLength;
    for (let i = 0; i < len; i++) {
      binary += String.fromCharCode(combined[i]);
    }
    return btoa(binary);
  } catch (err) {
    console.error('Failed to encode ZATCA TLV', err);
    return '';
  }
}

// Compact serialization for QR url to display the full invoice on ANY smartphone
export function generateElectronicInvoiceUrl(
  receiptNumber: string,
  invoiceData?: any
): string {
  const origin = typeof window !== 'undefined' ? window.location.origin : 'https://aldeebmall.com';
  const pathname = typeof window !== 'undefined' ? window.location.pathname : '/';

  if (!invoiceData) {
    return `${origin}${pathname}#invoice?id=${encodeURIComponent(receiptNumber)}`;
  }

  try {
    const compactPayload = {
      rn: receiptNumber,
      bn: invoiceData.branch_name || 'الفرع الرئيسي',
      ca: invoiceData.cashier_name || 'كاشير 1',
      tc: invoiceData.terminal_code || 'POS-01',
      cn: invoiceData.customer_name || 'عميل نقدي',
      cp: invoiceData.customer_phone || '',
      dt: invoiceData.created_at || new Date().toLocaleString('ar-SA'),
      it: (invoiceData.items || []).map((it: any) => ({
        n: it.name_ar || it.product_name_ar || 'صنف',
        q: it.quantity || 1,
        p: it.price || it.unit_price || 0,
        t: it.total || it.total_price || 0,
        u: it.unit || 'حبة',
      })),
      st: invoiceData.subtotal || 0,
      tx: invoiceData.tax_amount || 0,
      gt: invoiceData.grand_total || invoiceData.total_amount || 0,
      pm: invoiceData.payment_method || 'cash',
      cr: invoiceData.cash_received,
      cg: invoiceData.change_given,
    };

    const jsonStr = JSON.stringify(compactPayload);
    // Base64 encode UTF-8 string safely
    const utf8Bytes = new TextEncoder().encode(jsonStr);
    let binary = '';
    for (let i = 0; i < utf8Bytes.length; i++) {
      binary += String.fromCharCode(utf8Bytes[i]);
    }
    const base64 = btoa(binary);
    return `${origin}${pathname}#invoice?id=${encodeURIComponent(receiptNumber)}&d=${encodeURIComponent(base64)}`;
  } catch (err) {
    console.error('Failed to serialize invoice payload', err);
    return `${origin}${pathname}#invoice?id=${encodeURIComponent(receiptNumber)}`;
  }
}

// Decode compressed payload on the viewer page
export function decodeElectronicInvoicePayload(base64String: string): any | null {
  try {
    const binary = atob(base64String);
    const bytes = new Uint8Array(binary.length);
    for (let i = 0; i < binary.length; i++) {
      bytes[i] = binary.charCodeAt(i);
    }
    const jsonStr = new TextDecoder().decode(bytes);
    const parsed = JSON.parse(jsonStr);
    return {
      receipt_number: parsed.rn,
      branch_name: parsed.bn,
      cashier_name: parsed.ca,
      terminal_code: parsed.tc,
      customer_name: parsed.cn,
      customer_phone: parsed.cp,
      created_at: parsed.dt,
      items: (parsed.it || []).map((item: any) => ({
        name_ar: item.n,
        quantity: item.q,
        price: item.p,
        total: item.t,
        unit: item.u,
      })),
      subtotal: parsed.st,
      tax_amount: parsed.tx,
      grand_total: parsed.gt,
      payment_method: parsed.pm,
      cash_received: parsed.cr,
      change_given: parsed.cg,
    };
  } catch (err) {
    console.error('Failed to decode invoice payload', err);
    return null;
  }
}
