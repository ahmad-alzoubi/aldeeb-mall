import React, { useState, useEffect } from 'react';
import { ShieldCheck, ExternalLink, QrCode as QrIcon, Edit3, EyeOff } from 'lucide-react';
import { InvoiceSettings, generateQrCodeDataUrl, generateElectronicInvoiceUrl, generateZatcaTlvBase64 } from '../lib/invoiceSettings';

export interface InspectTarget {
  key: string;
  title: string;
  subTab: 'elements' | 'store' | 'style' | 'qrcode' | 'texts';
  fieldId: string;
  toggleKey?: keyof InvoiceSettings;
  description: string;
}

export interface ReceiptItem {
  name_ar: string;
  name_en?: string;
  quantity: number;
  unit?: string;
  price: number;
  total: number;
  barcode?: string;
}

export interface ReceiptData {
  receipt_number: string;
  branch_name: string;
  terminal_code: string;
  cashier_name: string;
  customer_name?: string;
  customer_phone?: string;
  created_at: string;
  items: ReceiptItem[];
  subtotal: number;
  tax_amount: number;
  discount_amount?: number;
  grand_total: number;
  payment_method: string;
  cash_received?: number;
  change_given?: number;
}

interface ThermalReceiptViewProps {
  data: ReceiptData;
  settings: InvoiceSettings;
  className?: string;
  onOpenElectronicInvoice?: () => void;
  interactiveInspector?: boolean;
  onInspectElement?: (target: InspectTarget) => void;
  onToggleElementVisibility?: (toggleKey: keyof InvoiceSettings) => void;
  activeInspectedKey?: string;
}

export const ThermalReceiptView: React.FC<ThermalReceiptViewProps> = ({
  data,
  settings,
  className = '',
  onOpenElectronicInvoice,
  interactiveInspector = false,
  onInspectElement,
  onToggleElementVisibility,
  activeInspectedKey,
}) => {
  const [qrCodeUrl, setQrCodeUrl] = useState<string>('');
  const [eInvoiceTargetUrl, setEInvoiceTargetUrl] = useState<string>('');

  useEffect(() => {
    let isMounted = true;

    async function makeQr() {
      if (!settings.showQrCode) return;

      const targetUrl = generateElectronicInvoiceUrl(data.receipt_number, data);
      if (isMounted) setEInvoiceTargetUrl(targetUrl);

      let payloadToEncode = targetUrl;
      if (settings.qrType === 'zatca_tlv') {
        const zatcaIso = new Date().toISOString();
        const tlv = generateZatcaTlvBase64(
          settings.storeNameAr,
          settings.taxNumber,
          zatcaIso,
          data.grand_total.toFixed(2),
          data.tax_amount.toFixed(2)
        );
        payloadToEncode = tlv || targetUrl;
      }

      const dataUrl = await generateQrCodeDataUrl(payloadToEncode, settings.qrCodeSize * 2);
      if (isMounted) {
        setQrCodeUrl(dataUrl);
      }
    }

    makeQr();
    return () => {
      isMounted = false;
    };
  }, [data, settings]);

  // Width mapping
  const widthClass =
    settings.paperWidth === '58mm'
      ? 'w-[260px] max-w-[260px]'
      : settings.paperWidth === 'a4'
      ? 'w-full max-w-[580px]'
      : 'w-[340px] max-w-[340px]'; // 80mm standard

  // Font size mapping
  const baseFontSizeClass =
    settings.fontSize === 'sm'
      ? 'text-[11px]'
      : settings.fontSize === 'lg'
      ? 'text-[13px]'
      : 'text-[12px]';

  // Divider border mapping
  const dividerClass =
    settings.dividerStyle === 'dotted'
      ? 'border-b-2 border-dotted border-slate-300'
      : settings.dividerStyle === 'solid'
      ? 'border-b border-slate-300'
      : settings.dividerStyle === 'double'
      ? 'border-b-4 border-double border-slate-400'
      : 'border-b border-dashed border-slate-300';

  const fontClass =
    settings.fontFamily === 'mono'
      ? 'font-mono'
      : settings.fontFamily === 'sans'
      ? 'font-sans'
      : 'font-sans';

  // Interactive Inspector Item Wrapper
  const renderInspectable = (target: InspectTarget, children: React.ReactNode) => {
    if (!interactiveInspector) {
      return <>{children}</>;
    }
    const isSelected = activeInspectedKey === target.key;
    return (
      <div
        onClick={(e) => {
          e.stopPropagation();
          onInspectElement?.(target);
        }}
        className={`relative group/inspector rounded-md transition-all cursor-pointer p-0.5 ${
          isSelected
            ? 'ring-2 ring-blue-600 bg-blue-50/70 shadow-xs'
            : 'hover:ring-2 hover:ring-blue-400 hover:bg-blue-50/40'
        }`}
        title={`انقر لتعديل: ${target.title}`}
      >
        {children}

        {/* Hover Action Badge */}
        <div className="absolute -top-3.5 left-1/2 -translate-x-1/2 hidden group-hover/inspector:flex items-center gap-1.5 bg-slate-900 text-white text-[9px] font-bold px-2 py-0.5 rounded-full shadow-xl z-30 pointer-events-auto whitespace-nowrap border border-slate-700">
          <span className="flex items-center gap-1 text-blue-300">
            <Edit3 className="w-2.5 h-2.5" />
            <span>تعديل {target.title}</span>
          </span>

          {target.toggleKey && onToggleElementVisibility && (
            <button
              type="button"
              onClick={(e) => {
                e.stopPropagation();
                onToggleElementVisibility(target.toggleKey!);
              }}
              className="mr-1 pr-1 border-r border-slate-700 text-rose-300 hover:text-rose-100 flex items-center gap-0.5"
              title="إخفاء هذا العنصر فوراً"
            >
              <EyeOff className="w-2.5 h-2.5" />
              <span>إخفاء</span>
            </button>
          )}
        </div>
      </div>
    );
  };

  return (
    <div
      className={`bg-white text-slate-900 mx-auto p-4 transition-all duration-200 select-text ${widthClass} ${baseFontSizeClass} ${fontClass} ${className}`}
      dir="rtl"
      id="aldeeb-thermal-receipt"
    >
      {/* 1. Header Section */}
      <div className={`text-center space-y-1 pb-3 ${dividerClass}`}>
        {settings.showLogo && settings.logoUrl && (
          renderInspectable(
            {
              key: 'logo',
              title: 'شعار المتجر',
              subTab: 'store',
              fieldId: 'field-logoUrl',
              toggleKey: 'showLogo',
              description: 'رابط صورة الشعار وارتفاعه',
            },
            <div className="flex justify-center mb-1">
              <img
                src={settings.logoUrl}
                alt="Logo"
                style={{ maxHeight: `${settings.logoHeight}px` }}
                className="object-contain rounded-md"
                onError={(e) => {
                  (e.target as HTMLElement).style.display = 'none';
                }}
              />
            </div>
          )
        )}

        {settings.showStoreName && (
          renderInspectable(
            {
              key: 'storeName',
              title: 'اسم المتجر',
              subTab: 'store',
              fieldId: 'field-storeNameAr',
              toggleKey: 'showStoreName',
              description: 'اسم المتجر بالعربي والإنجليزي',
            },
            <div>
              <h2 className="text-sm font-black text-slate-950 tracking-tight leading-snug">
                {settings.storeNameAr}
              </h2>
              {settings.storeNameEn && (
                <p className="text-[10px] text-slate-500 font-mono tracking-wider uppercase">
                  {settings.storeNameEn}
                </p>
              )}
            </div>
          )
        )}

        {settings.showBranchName && (
          renderInspectable(
            {
              key: 'branchName',
              title: 'اسم الفرع',
              subTab: 'store',
              fieldId: 'field-branchName',
              toggleKey: 'showBranchName',
              description: 'اسم الفرع المصدر للفاتورة',
            },
            <p className="text-[11px] font-bold text-slate-700">
              {data.branch_name || settings.branchName}
            </p>
          )
        )}

        {settings.showAddress && settings.address && (
          renderInspectable(
            {
              key: 'address',
              title: 'العنوان الجغرافي',
              subTab: 'store',
              fieldId: 'field-address',
              toggleKey: 'showAddress',
              description: 'موقع وعنوان المتجر الجغرافي',
            },
            <p className="text-[10px] text-slate-500 leading-tight">
              {settings.address}
            </p>
          )
        )}

        {settings.showPhone && settings.phone && (
          renderInspectable(
            {
              key: 'phone',
              title: 'رقم الهاتف',
              subTab: 'store',
              fieldId: 'field-phone',
              toggleKey: 'showPhone',
              description: 'أرقام التواصل وخدمة العملاء',
            },
            <p className="text-[10px] text-slate-600 font-mono">
              هاتف: {settings.phone}
            </p>
          )
        )}

        <div className="pt-0.5 space-y-0.5">
          {settings.showTaxNumber && (
            renderInspectable(
              {
                key: 'taxNumber',
                title: 'الرقم الضريبي',
                subTab: 'store',
                fieldId: 'field-taxNumber',
                toggleKey: 'showTaxNumber',
                description: 'رقم التسجيل الضريبي VAT',
              },
              <div className="text-[10px] text-slate-700 font-mono">
                الرقم الضريبي: <strong>{settings.taxNumber}</strong>
              </div>
            )
          )}
          {settings.showCommercialRegister && settings.commercialRegister && (
            renderInspectable(
              {
                key: 'commercialRegister',
                title: 'السجل التجاري',
                subTab: 'store',
                fieldId: 'field-commercialRegister',
                toggleKey: 'showCommercialRegister',
                description: 'رقم السجل التجاري الرسمي',
              },
              <div className="text-[10px] text-slate-600 font-mono">
                السجل التجاري: {settings.commercialRegister}
              </div>
            )
          )}
        </div>

        {settings.showSubtitle && settings.headerSubtitle && (
          renderInspectable(
            {
              key: 'headerSubtitle',
              title: 'عنوان الفاتورة الفرعي',
              subTab: 'store',
              fieldId: 'field-headerSubtitle',
              toggleKey: 'showSubtitle',
              description: 'نوع الفاتورة مثل فاتورة ضريبية مبسطة',
            },
            <div className="inline-block px-2.5 py-0.5 rounded-md bg-slate-100 text-[10px] font-bold text-slate-800 border border-slate-200 mt-1">
              {settings.headerSubtitle}
            </div>
          )
        )}
      </div>

      {/* 2. Metadata Section (Invoice #, Date, Cashier, Customer) */}
      <div className={`space-y-1 text-[11px] font-mono py-2.5 ${dividerClass}`}>
        {settings.showInvoiceNumber && (
          renderInspectable(
            {
              key: 'invoiceNumber',
              title: 'رقم الفاتورة',
              subTab: 'elements',
              fieldId: 'toggle-showInvoiceNumber',
              toggleKey: 'showInvoiceNumber',
              description: 'رقم الفاتورة وكود المعاملة',
            },
            <div className="flex justify-between items-center">
              <span className="text-slate-600 font-sans font-medium">رقم الفاتورة:</span>
              <strong className="text-slate-950 tracking-wider">{data.receipt_number}</strong>
            </div>
          )
        )}

        {/* Pseudo Linear Barcode */}
        {settings.showBarcodeUnderNumber && (
          renderInspectable(
            {
              key: 'barcodeNumber',
              title: 'الباركود الخطي',
              subTab: 'elements',
              fieldId: 'toggle-showBarcodeUnderNumber',
              toggleKey: 'showBarcodeUnderNumber',
              description: 'الباركود الخطي تحت رقم الفاتورة',
            },
            <div className="py-1 text-center font-mono">
              <div className="inline-block tracking-[0.25em] text-[11px] font-bold text-slate-800 bg-slate-50 px-2 py-0.5 border border-slate-200 rounded">
                ||| | ||||| | ||| {data.receipt_number.slice(-8)} || |||
              </div>
            </div>
          )
        )}

        {settings.showDateTime && (
          renderInspectable(
            {
              key: 'dateTime',
              title: 'التاريخ والوقت',
              subTab: 'elements',
              fieldId: 'toggle-showDateTime',
              toggleKey: 'showDateTime',
              description: 'تاريخ وساعة إصدار الفاتورة',
            },
            <div className="flex justify-between items-center text-[10px]">
              <span className="text-slate-500 font-sans">التاريخ والوقت:</span>
              <span className="text-slate-700">{data.created_at}</span>
            </div>
          )
        )}

        {(settings.showCashierName || settings.showTerminalCode) && (
          renderInspectable(
            {
              key: 'cashier',
              title: 'الكاشير ونقطة البيع',
              subTab: 'elements',
              fieldId: 'toggle-showCashierName',
              toggleKey: 'showCashierName',
              description: 'اسم الموظف ورقم نقطة البيع POS',
            },
            <div className="flex justify-between items-center text-[10px]">
              <span className="text-slate-500 font-sans">الكاشير / النقطة:</span>
              <span className="text-slate-800 font-medium">
                {settings.showCashierName && (data.cashier_name || 'كاشير')}
                {settings.showTerminalCode && ` (${data.terminal_code || 'POS-01'})`}
              </span>
            </div>
          )
        )}

        {settings.showCustomerName && data.customer_name && (
          renderInspectable(
            {
              key: 'customer',
              title: 'بيانات العميل',
              subTab: 'elements',
              fieldId: 'toggle-showCustomerName',
              toggleKey: 'showCustomerName',
              description: 'اسم العميل ورقم هاتفه',
            },
            <div className="flex justify-between items-center text-[10px]">
              <span className="text-slate-500 font-sans">العميل:</span>
              <span className="text-slate-800 font-bold">{data.customer_name}</span>
            </div>
          )
        )}

        {settings.showCustomerPhone && data.customer_phone && (
          renderInspectable(
            {
              key: 'customerPhone',
              title: 'هاتف العميل',
              subTab: 'elements',
              fieldId: 'toggle-showCustomerPhone',
              toggleKey: 'showCustomerPhone',
              description: 'رقم هاتف العميل',
            },
            <div className="flex justify-between items-center text-[10px]">
              <span className="text-slate-500 font-sans">الهاتف:</span>
              <span className="text-slate-700">{data.customer_phone}</span>
            </div>
          )
        )}
      </div>

      {/* 3. Items Breakdown Table */}
      <div className={`py-2 ${dividerClass}`}>
        {renderInspectable(
          {
            key: 'itemsTable',
            title: 'جدول الأصناف والأسعار',
            subTab: 'elements',
            fieldId: 'toggle-showItemUnitPrice',
            toggleKey: 'showItemUnitPrice',
            description: 'تفاصيل الأصناف والكميات والأسعار الفردية',
          },
          <div>
            <div className="flex justify-between text-[10px] font-bold text-slate-600 pb-1.5 border-b border-slate-200">
              <span>الصنف والكمية</span>
              <span>الإجمالي</span>
            </div>

            <div className={settings.compactItemSpacing ? 'space-y-0.5 pt-1' : 'space-y-1.5 pt-1.5'}>
              {data.items.map((item, idx) => (
                <div key={idx} className="flex justify-between items-start text-[11px] leading-tight">
                  <div className="flex-1 pl-2">
                    <div className="font-bold text-slate-900">{item.name_ar}</div>
                    {item.name_en && (
                      <div className="text-[9px] text-slate-400 font-sans">{item.name_en}</div>
                    )}
                    {settings.showItemCode && item.barcode && (
                      <div className="text-[9px] text-slate-400 font-mono">#{item.barcode}</div>
                    )}
                    {settings.showItemUnitPrice && (
                      <div className="text-[10px] text-slate-500 font-mono mt-0.5">
                        {item.quantity} {item.unit || 'حبة'} × {item.price.toFixed(2)}
                      </div>
                    )}
                  </div>
                  <span className="font-mono font-bold text-slate-950 text-end whitespace-nowrap">
                    {item.total.toFixed(2)}
                  </span>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>

      {/* 4. Totals Breakdown */}
      <div className={`space-y-1 py-2 font-mono text-[11px] ${dividerClass}`}>
        {renderInspectable(
          {
            key: 'totalsBreakdown',
            title: 'المجاميع والضريبة',
            subTab: 'store',
            fieldId: 'field-taxRatePercent',
            toggleKey: 'showTaxAmount',
            description: 'المجموع الخاضع للضريبة ونسبة وقيمة VAT والإجمالي',
          },
          <div className="space-y-1">
            {settings.showSubtotal && (
              <div className="flex justify-between text-slate-600">
                <span className="font-sans">المجموع الخاضع للضريبة:</span>
                <span>{data.subtotal.toFixed(2)}</span>
              </div>
            )}

            {settings.showDiscountAmount && data.discount_amount && data.discount_amount > 0 && (
              <div className="flex justify-between text-rose-600 font-medium">
                <span className="font-sans">إجمالي الخصم:</span>
                <span>-{data.discount_amount.toFixed(2)}</span>
              </div>
            )}

            {settings.showTaxAmount && (
              <div className="flex justify-between text-slate-600">
                <span className="font-sans">
                  ضريبة القيمة المضافة {settings.showTaxRate && `(${settings.taxRatePercent}%)`}:
                </span>
                <span>{data.tax_amount.toFixed(2)}</span>
              </div>
            )}

            {settings.showGrandTotal && (
              <div className="flex justify-between items-center text-sm font-black text-slate-950 pt-1.5 border-t border-slate-300">
                <span className="font-sans">المبلغ المستحق الإجمالي:</span>
                <span className="text-base text-slate-950 font-black">
                  {data.grand_total.toFixed(2)} ل.س
                </span>
              </div>
            )}
          </div>
        )}

        {/* Payment details */}
        {renderInspectable(
          {
            key: 'paymentDetails',
            title: 'طريقة الدفع والمتبقي',
            subTab: 'elements',
            fieldId: 'toggle-showPaymentMethod',
            toggleKey: 'showPaymentMethod',
            description: 'طريقة الدفع (كاش/شبكة) والمبلغ المستلم والمتبقي',
          },
          <div className="space-y-1 pt-1">
            {settings.showPaymentMethod && (
              <div className="flex justify-between text-[10px] text-slate-600">
                <span className="font-sans">طريقة السداد:</span>
                <span className="font-sans font-bold text-slate-800">
                  {data.payment_method === 'cash'
                    ? 'نقدي (Cash)'
                    : data.payment_method === 'card'
                    ? 'بطاقة بنكية / شبكة (POS Card)'
                    : data.payment_method === 'split'
                    ? 'دفع مجزأ'
                    : 'نقاط ولاء الديب'}
                </span>
              </div>
            )}

            {settings.showCashReceivedAndChange && data.cash_received && (
              <>
                <div className="flex justify-between text-[10px] text-slate-600">
                  <span className="font-sans">المبلغ المدفوع كاش:</span>
                  <span>{data.cash_received.toFixed(2)}</span>
                </div>
                {data.change_given !== undefined && (
                  <div className="flex justify-between text-[10px] font-bold text-emerald-700">
                    <span className="font-sans">المتبقي للعميل:</span>
                    <span>{data.change_given.toFixed(2)}</span>
                  </div>
                )}
              </>
            )}
          </div>
        )}
      </div>

      {/* 5. QR Code & Electronic Invoice Link */}
      {settings.showQrCode && (
        renderInspectable(
          {
            key: 'qrCode',
            title: 'الباركود المربع الإلكتروني QR',
            subTab: 'qrcode',
            fieldId: 'field-qrType',
            toggleKey: 'showQrCode',
            description: 'إعدادات الباركود ونوعه وحجمه ومساره المباشر',
          },
          <div className="text-center py-2.5 space-y-1.5">
            <div className="relative inline-block group">
              {qrCodeUrl ? (
                <div className="p-1.5 bg-white border border-slate-200 rounded-xl shadow-xs inline-block">
                  <img
                    src={qrCodeUrl}
                    alt="QR Code"
                    style={{ width: `${settings.qrCodeSize}px`, height: `${settings.qrCodeSize}px` }}
                    className="mx-auto"
                  />
                </div>
              ) : (
                <div
                  style={{ width: `${settings.qrCodeSize}px`, height: `${settings.qrCodeSize}px` }}
                  className="mx-auto bg-slate-100 rounded-xl flex items-center justify-center border border-slate-200"
                >
                  <QrIcon className="w-8 h-8 text-slate-400 animate-pulse" />
                </div>
              )}

              {/* Click to preview/open e-invoice button (screen only) */}
              <div className="print:hidden mt-1">
                <a
                  href={eInvoiceTargetUrl || `#invoice?id=${data.receipt_number}`}
                  target="_blank"
                  rel="noreferrer"
                  onClick={(e) => {
                    if (onOpenElectronicInvoice) {
                      e.preventDefault();
                      onOpenElectronicInvoice();
                    }
                  }}
                  className="inline-flex items-center gap-1 text-[10px] font-bold text-blue-600 hover:text-blue-800 hover:underline"
                >
                  <span>فتح الفاتورة الإلكترونية مباشرة</span>
                  <ExternalLink className="w-3 h-3" />
                </a>
              </div>
            </div>

            <p className="text-[9px] text-slate-400 font-sans leading-tight">
              امسح الباركود بكاميرا الجوال لعرض الفاتورة الإلكترونية المعتمدة وتحميلها
            </p>
          </div>
        )
      )}

      {/* 6. Security Seal / Badge */}
      {settings.showSecurityBadge && (
        renderInspectable(
          {
            key: 'securityBadge',
            title: 'ختم الفاتورة الإلكترونية',
            subTab: 'texts',
            fieldId: 'field-securityBadgeText',
            toggleKey: 'showSecurityBadge',
            description: 'نص شارة اعتماد الفاتورة الإلكترونية',
          },
          <div className="py-1 text-center">
            <div className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-emerald-50 text-emerald-800 border border-emerald-200 text-[9px] font-bold">
              <ShieldCheck className="w-3.5 h-3.5 text-emerald-600" />
              <span>{settings.securityBadgeText}</span>
            </div>
          </div>
        )
      )}

      {/* 7. Policies & Footer Notes */}
      <div className="pt-2 text-center space-y-1.5 text-[9px] text-slate-500 leading-snug">
        {settings.showReturnPolicy && settings.returnPolicyText && (
          renderInspectable(
            {
              key: 'returnPolicy',
              title: 'سياسة الاسترجاع',
              subTab: 'texts',
              fieldId: 'field-returnPolicyText',
              toggleKey: 'showReturnPolicy',
              description: 'شروط واستبدال واسترجاع البضائع',
            },
            <p className="border-t border-slate-100 pt-1.5 font-medium text-slate-600">
              {settings.returnPolicyText}
            </p>
          )
        )}

        {settings.showCustomFooterNote && settings.customFooterNote && (
          renderInspectable(
            {
              key: 'customFooter',
              title: 'رسالة الشكر والختام',
              subTab: 'texts',
              fieldId: 'field-customFooterNote',
              toggleKey: 'showCustomFooterNote',
              description: 'العبارات الختامية وحسابات التواصل',
            },
            <p className="font-bold text-slate-700">
              {settings.customFooterNote}
            </p>
          )
        )}
      </div>
    </div>
  );
};
