import React, { useState, useEffect } from 'react';
import { 
  Printer, 
  Share2, 
  Copy, 
  Check, 
  ShieldCheck, 
  CheckCircle2, 
  Store, 
  Calendar, 
  User, 
  CreditCard, 
  ArrowRight,
  FileCheck2,
  ExternalLink,
  AlertCircle
} from 'lucide-react';
import { 
  InvoiceSettings, 
  getInvoiceSettings, 
  decodeElectronicInvoicePayload,
  generateQrCodeDataUrl
} from '../lib/invoiceSettings';
import { supabase } from '../lib/supabase';

interface ElectronicInvoicePageProps {
  onBackToApp?: () => void;
}

export const ElectronicInvoicePage: React.FC<ElectronicInvoicePageProps> = ({ onBackToApp }) => {
  const [invoiceData, setInvoiceData] = useState<any | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [settings] = useState<InvoiceSettings>(() => getInvoiceSettings());
  const [qrCodeDataUrl, setQrCodeDataUrl] = useState<string>('');
  const [copiedLink, setCopiedLink] = useState(false);

  useEffect(() => {
    let isMounted = true;

    async function resolveInvoice() {
      setIsLoading(true);

      // Parse URL params from hash or search
      const hash = window.location.hash;
      const search = window.location.search;
      const urlString = hash.includes('?') ? hash.split('?')[1] : search.replace('?', '');
      const urlParams = new URLSearchParams(urlString);
      
      const idParam = urlParams.get('id') || urlParams.get('order') || '';
      const dataParam = urlParams.get('d');
      const isExplicitPreview = urlParams.get('preview') === 'true' || idParam.toLowerCase().includes('preview');

      // 1. Try querying real order from Supabase database if ID exists
      if (idParam && !isExplicitPreview) {
        try {
          const isUuid = /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/.test(idParam);
          let query = supabase.from('orders').select(`
            *,
            order_items (*)
          `);

          if (isUuid) {
            query = query.or(`id.eq.${idParam},order_number.eq.${idParam}`);
          } else {
            query = query.eq('order_number', idParam);
          }

          const { data: dbOrder, error: dbError } = await query.maybeSingle();

          if (!dbError && dbOrder && isMounted) {
            // Extract cashier from notes if available
            let cashierName = 'كاشير نقطة البيع';
            if (dbOrder.notes && dbOrder.notes.includes('الكاشير:')) {
              const match = dbOrder.notes.match(/الكاشير:\s*([^•\n]+)/);
              if (match) cashierName = match[1].trim();
            }

            const mappedItems = (dbOrder.order_items || []).map((item: any) => ({
              name_ar: item.product_name || 'منتج',
              quantity: item.quantity,
              price: item.unit_price,
              total: item.total_price,
              unit: 'حبة',
            }));

            setInvoiceData({
              receipt_number: dbOrder.order_number,
              branch_name: dbOrder.branch_name || 'فرع الديب مول',
              cashier_name: cashierName,
              terminal_code: 'POS-01',
              customer_name: dbOrder.customer_name || 'عميل نقدي مباشر',
              customer_phone: dbOrder.customer_phone || '-',
              created_at: new Date(dbOrder.created_at).toLocaleString('ar-SA'),
              items: mappedItems.length > 0 ? mappedItems : [
                { name_ar: 'مشتريات نقطة البيع POS', quantity: 1, price: dbOrder.total_amount, total: dbOrder.total_amount, unit: 'طلب' }
              ],
              subtotal: Number(dbOrder.subtotal || dbOrder.total_amount),
              tax_amount: Math.max(0, Number(dbOrder.total_amount) - Number(dbOrder.subtotal || dbOrder.total_amount)),
              grand_total: Number(dbOrder.total_amount),
              payment_method: dbOrder.payment_method || 'cash',
              cash_received: undefined,
              change_given: undefined,
              is_reprinted: Boolean(dbOrder.is_reprinted),
              reprint_count: Number(dbOrder.reprint_count || 0),
              isVerifiedServerOrder: true,
              isPreview: false,
            });
            setIsLoading(false);
            return;
          }
        } catch (err) {
          console.warn('Could not query database order, checking URL payload:', err);
        }
      }

      // 2. Fallback to decoded base64 URL payload
      if (dataParam) {
        const decoded = decodeElectronicInvoicePayload(dataParam);
        if (decoded && isMounted) {
          setInvoiceData({
            ...decoded,
            isVerifiedServerOrder: false,
            isPreview: false,
          });
          setIsLoading(false);
          return;
        }
      }

      // 3. Fallback to preview sample data with explicit preview notice
      if (isMounted) {
        setInvoiceData({
          receipt_number: idParam || 'PREVIEW-POS-001',
          branch_name: 'الفرع الرئيسي - برج الديب التجاري',
          cashier_name: 'أحمد السعيد (كاشير تجريبي)',
          terminal_code: 'POS-01',
          customer_name: 'عميل نقدي تجريبي',
          customer_phone: '0501234567',
          created_at: new Date().toLocaleDateString('ar-SA', { 
            year: 'numeric', 
            month: 'long', 
            day: 'numeric', 
            hour: '2-digit', 
            minute: '2-digit' 
          }),
          items: [
            { name_ar: 'حليب كامل الدسم المراعي 1 لتر', quantity: 2, price: 6.50, total: 13.00, unit: 'حبة' },
            { name_ar: 'أرز بسمتي الشعلان 5 كغ', quantity: 1, price: 42.00, total: 42.00, unit: 'كيس' },
            { name_ar: 'زيت دوار الشمس عافية 1.5 لتر', quantity: 2, price: 18.50, total: 37.00, unit: 'حبة' },
            { name_ar: 'بيض طازج مزارع الديب 30 حبة', quantity: 1, price: 19.50, total: 19.50, unit: 'طبق' },
          ],
          subtotal: 96.96,
          tax_amount: 14.54,
          grand_total: 111.50,
          payment_method: 'card',
          cash_received: undefined,
          change_given: undefined,
          isVerifiedServerOrder: false,
          isPreview: true,
        });
        setIsLoading(false);
      }
    }

    resolveInvoice();
    return () => { isMounted = false; };
  }, []);

  useEffect(() => {
    if (!invoiceData) return;
    generateQrCodeDataUrl(window.location.href, 220).then((url) => {
      setQrCodeDataUrl(url);
    });
  }, [invoiceData]);

  const handlePrint = () => {
    window.print();
  };

  const handleCopyLink = () => {
    navigator.clipboard.writeText(window.location.href);
    setCopiedLink(true);
    setTimeout(() => setCopiedLink(false), 2500);
  };

  const handleShareWhatsApp = () => {
    if (!invoiceData) return;
    const message = `فاتورة إلكترونية معتمدة من الديب مول:\nرقم الفاتورة: ${invoiceData.receipt_number}\nالمبلغ الإجمالي: ${invoiceData.grand_total} ل.س\nرابط الفاتورة المعتمدة: ${window.location.href}`;
    window.open(`https://api.whatsapp.com/send?text=${encodeURIComponent(message)}`, '_blank');
  };

  if (!invoiceData) {
    return (
      <div className="min-h-screen bg-slate-50 flex items-center justify-center p-4">
        <div className="text-center space-y-3">
          <div className="w-10 h-10 border-4 border-blue-600 border-t-transparent rounded-full animate-spin mx-auto" />
          <p className="text-sm font-bold text-slate-600">جاري تحميل الفاتورة الإلكترونية...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-slate-100 text-slate-900 py-6 px-3 sm:px-6 font-sans antialiased">
      {/* Top action toolbar (hidden when printing) */}
      <div className="max-w-2xl mx-auto mb-4 flex flex-wrap items-center justify-between gap-2 print:hidden">
        <div className="flex items-center gap-2">
          {onBackToApp && (
            <button
              onClick={onBackToApp}
              className="inline-flex items-center gap-1.5 px-3 py-1.5 bg-white border border-slate-300 rounded-xl text-xs font-bold text-slate-700 hover:bg-slate-50 shadow-xs transition-colors"
            >
              <ArrowRight className="w-4 h-4" />
              <span>العودة للنظام</span>
            </button>
          )}
          {invoiceData.isPreview ? (
            <div className="flex items-center gap-1.5 px-3 py-1 bg-amber-50 border border-amber-300 text-amber-900 rounded-xl text-xs font-black">
              <AlertCircle className="w-4 h-4 text-amber-600" />
              <span>معاينة تصميم تجريبية • غير مخصصة للبيع (PREVIEW ONLY)</span>
            </div>
          ) : invoiceData.isVerifiedServerOrder ? (
            <div className="flex items-center gap-1.5 px-3 py-1 bg-emerald-50 border border-emerald-300 text-emerald-800 rounded-xl text-xs font-black">
              <CheckCircle2 className="w-4 h-4 text-emerald-600" />
              <span>فاتورة إلكترونية مؤكدة ومحفوظة في الخادم</span>
            </div>
          ) : (
            <div className="flex items-center gap-1.5 px-3 py-1 bg-blue-50 border border-blue-200 text-blue-800 rounded-xl text-xs font-bold">
              <FileCheck2 className="w-4 h-4 text-blue-600" />
              <span>إيصال بيع إلكتروني تجاري</span>
            </div>
          )}

          {invoiceData.is_reprinted && (
            <div className="flex items-center gap-1 px-2.5 py-1 bg-rose-50 border border-rose-300 text-rose-800 rounded-xl text-xs font-black">
              <span>نسخة معاد طباعتها (#{invoiceData.reprint_count || 1})</span>
            </div>
          )}
        </div>

        <div className="flex items-center gap-2">
          <button
            onClick={handleCopyLink}
            className="inline-flex items-center gap-1.5 px-3 py-1.5 bg-white border border-slate-300 rounded-xl text-xs font-bold text-slate-700 hover:bg-slate-50 shadow-xs transition-colors"
          >
            {copiedLink ? <Check className="w-4 h-4 text-emerald-600" /> : <Copy className="w-4 h-4 text-slate-500" />}
            <span>{copiedLink ? 'تم النسخ!' : 'نسخ الرابط'}</span>
          </button>

          <button
            onClick={handleShareWhatsApp}
            className="inline-flex items-center gap-1.5 px-3 py-1.5 bg-emerald-600 text-white rounded-xl text-xs font-bold hover:bg-emerald-700 shadow-xs transition-colors"
          >
            <Share2 className="w-4 h-4" />
            <span>واتساب</span>
          </button>

          <button
            onClick={handlePrint}
            className="inline-flex items-center gap-1.5 px-3.5 py-1.5 bg-blue-600 text-white rounded-xl text-xs font-bold hover:bg-blue-700 shadow-xs transition-colors"
          >
            <Printer className="w-4 h-4" />
            <span>طباعة / حفظ PDF</span>
          </button>
        </div>
      </div>

      {/* Main Electronic Invoice Card */}
      <div className="max-w-2xl mx-auto bg-white rounded-3xl shadow-xl border border-slate-200/80 overflow-hidden print:border-none print:shadow-none print:m-0 print:p-0">
        {/* Verification Top Banner */}
        <div className="bg-gradient-to-r from-slate-900 via-blue-950 to-slate-900 text-white p-5 sm:p-6 text-center relative overflow-hidden">
          <div className="relative z-10 space-y-2">
            <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-emerald-500/20 text-emerald-300 border border-emerald-400/30 text-xs font-bold backdrop-blur-xs">
              <ShieldCheck className="w-4 h-4 text-emerald-400" />
              <span>
                {invoiceData.isPreview
                  ? 'معاينة قالب الفاتورة الإلكترونية - غير معتمدة للبيع'
                  : 'فاتورة إلكترونية تجارية قياسية مسجلة في سجلات المتجر'}
              </span>
            </div>
            <h1 className="text-xl sm:text-2xl font-black tracking-tight">{settings.storeNameAr}</h1>
            <p className="text-xs text-slate-300 font-mono tracking-wider">{settings.storeNameEn}</p>
          </div>
        </div>

        {/* Invoice Body */}
        <div className="p-6 sm:p-8 space-y-6">
          {/* Header Metadata Grid */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 pb-6 border-b border-slate-200 text-xs">
            <div className="space-y-1.5">
              <div className="flex justify-between sm:justify-start sm:gap-3 text-slate-500">
                <span>رقم الفاتورة:</span>
                <strong className="text-slate-900 font-mono text-sm">{invoiceData.receipt_number}</strong>
              </div>
              <div className="flex justify-between sm:justify-start sm:gap-3 text-slate-500">
                <span>التاريخ والوقت:</span>
                <span className="text-slate-800 font-medium">{invoiceData.created_at}</span>
              </div>
              <div className="flex justify-between sm:justify-start sm:gap-3 text-slate-500">
                <span>الفرع المصدر:</span>
                <span className="text-slate-800 font-medium">{invoiceData.branch_name}</span>
              </div>
              <div className="flex justify-between sm:justify-start sm:gap-3 text-slate-500">
                <span>الكاشير:</span>
                <span className="text-slate-800 font-medium">
                  {invoiceData.cashier_name} ({invoiceData.terminal_code})
                </span>
              </div>
            </div>

            <div className="space-y-1.5 sm:text-end sm:border-r sm:pr-4 sm:border-slate-100">
              <div className="flex justify-between sm:justify-end sm:gap-3 text-slate-500">
                <span>الرقم الضريبي:</span>
                <strong className="text-slate-900 font-mono">{settings.taxNumber}</strong>
              </div>
              <div className="flex justify-between sm:justify-end sm:gap-3 text-slate-500">
                <span>السجل التجاري:</span>
                <span className="text-slate-800 font-mono">{settings.commercialRegister}</span>
              </div>
              <div className="flex justify-between sm:justify-end sm:gap-3 text-slate-500">
                <span>اسم العميل:</span>
                <span className="text-slate-800 font-bold">{invoiceData.customer_name || 'عميل نقدي'}</span>
              </div>
              <div className="flex justify-between sm:justify-end sm:gap-3 text-slate-500">
                <span>طريقة الدفع:</span>
                <span className="font-bold text-blue-700">
                  {invoiceData.payment_method === 'cash' ? 'نقدي (Cash)' : 'بطاقة بنكية / شبكة (POS)'}
                </span>
              </div>
            </div>
          </div>

          {/* Line Items Table */}
          <div>
            <h3 className="text-xs font-extrabold text-slate-400 uppercase tracking-wider mb-2">
              تفاصيل الأصناف المشتراة
            </h3>
            <div className="overflow-x-auto">
              <table className="w-full text-xs text-right border-collapse">
                <thead>
                  <tr className="bg-slate-50 border-b border-slate-200 text-slate-600 font-bold">
                    <th className="py-2.5 px-3">#</th>
                    <th className="py-2.5 px-3">الصنف</th>
                    <th className="py-2.5 px-3 text-center">الكمية</th>
                    <th className="py-2.5 px-3 text-center">سعر الوحدة</th>
                    <th className="py-2.5 px-3 text-start">المجموع</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {invoiceData.items.map((item: any, idx: number) => (
                    <tr key={idx} className="hover:bg-slate-50/50">
                      <td className="py-2.5 px-3 text-slate-400 font-mono">{idx + 1}</td>
                      <td className="py-2.5 px-3">
                        <div className="font-bold text-slate-900">{item.name_ar}</div>
                        {item.unit && (
                          <div className="text-[10px] text-slate-400">{item.unit}</div>
                        )}
                      </td>
                      <td className="py-2.5 px-3 text-center font-bold text-slate-800">
                        {item.quantity}
                      </td>
                      <td className="py-2.5 px-3 text-center font-mono text-slate-600">
                        {Number(item.price).toFixed(2)}
                      </td>
                      <td className="py-2.5 px-3 text-start font-mono font-bold text-slate-950">
                        {Number(item.total).toFixed(2)} ل.س
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>

          {/* Financial Breakdown & QR Code Grid */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-6 pt-4 border-t border-slate-200 items-center">
            {/* Left: Authentic QR Code */}
            <div className="text-center sm:text-start flex flex-col items-center sm:items-start space-y-2">
              <div className="p-2 bg-slate-50 border border-slate-200 rounded-2xl inline-block shadow-xs">
                {qrCodeDataUrl ? (
                  <img src={qrCodeDataUrl} alt="QR Code" className="w-32 h-32" />
                ) : (
                  <div className="w-32 h-32 bg-slate-200 animate-pulse rounded-lg" />
                )}
              </div>
              <p className="text-[10px] text-slate-500 font-sans max-w-[200px] leading-tight">
                مسح الباركود يثبت صحة الفاتورة ومطابقتها للمنظومة الرسمية للفوترة الإلكترونية.
              </p>
            </div>

            {/* Right: Totals Box */}
            <div className="bg-slate-50 p-4 rounded-2xl border border-slate-200 space-y-2 text-xs">
              <div className="flex justify-between text-slate-600">
                <span>المجموع الخاضع للضريبة:</span>
                <span className="font-mono">{Number(invoiceData.subtotal).toFixed(2)} ل.س</span>
              </div>
              <div className="flex justify-between text-slate-600">
                <span>ضريبة القيمة المضافة ({settings.taxRatePercent}%):</span>
                <span className="font-mono">{Number(invoiceData.tax_amount).toFixed(2)} ل.س</span>
              </div>
              <div className="flex justify-between items-center text-sm font-black text-slate-950 pt-2 border-t border-slate-200">
                <span>المبلغ الإجمالي المستحق:</span>
                <span className="text-base text-blue-900 font-mono font-black">
                  {Number(invoiceData.grand_total).toFixed(2)} ل.س
                </span>
              </div>

              {invoiceData.cash_received && (
                <div className="pt-2 border-t border-slate-200 space-y-1 text-[11px]">
                  <div className="flex justify-between text-slate-600">
                    <span>المبلغ المستلم:</span>
                    <span className="font-mono">{Number(invoiceData.cash_received).toFixed(2)} ل.س</span>
                  </div>
                  <div className="flex justify-between text-emerald-700 font-bold">
                    <span>المتبقي للعميل:</span>
                    <span className="font-mono">{Number(invoiceData.change_given || 0).toFixed(2)} ل.س</span>
                  </div>
                </div>
              )}
            </div>
          </div>

          {/* Policy & Official Footer */}
          <div className="pt-4 border-t border-slate-100 text-center space-y-2 text-xs text-slate-500">
            <p className="font-medium text-slate-700">{settings.returnPolicyText}</p>
            <p className="text-[11px] text-slate-400">{settings.customFooterNote}</p>
            <div className="pt-2 text-[10px] text-slate-400 font-mono">
              رقم التوثيق الرقمي: SHA256:{invoiceData.receipt_number.split('').map((c: string) => c.charCodeAt(0).toString(16)).join('').slice(0, 32)}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
