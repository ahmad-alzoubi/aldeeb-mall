import React, { useState } from 'react';
import { 
  Receipt, 
  Eye, 
  Settings2, 
  Printer, 
  Save, 
  RotateCcw, 
  Check, 
  QrCode, 
  FileText, 
  Type, 
  Sliders, 
  ShieldCheck, 
  Sparkles,
  Layers,
  HelpCircle,
  ExternalLink,
  Laptop,
  MousePointerClick,
  Info,
  CheckCircle2,
  EyeOff
} from 'lucide-react';
import { 
  InvoiceSettings, 
  DEFAULT_INVOICE_SETTINGS, 
  useInvoiceSettings 
} from '../lib/invoiceSettings';
import { ThermalReceiptView, ReceiptData, InspectTarget } from '../components/ThermalReceiptView';

const SAMPLE_RECEIPT: ReceiptData = {
  receipt_number: 'RCP-POS-948102',
  branch_name: 'الفرع الرئيسي - برج الديب التجاري',
  terminal_code: 'POS-01',
  cashier_name: 'أحمد السعيد',
  customer_name: 'محمد خالد العلي',
  customer_phone: '0509876543',
  created_at: '2026/11/01 14:35:12',
  items: [
    { name_ar: 'حليب كامل الدسم المراعي 1 لتر', quantity: 2, price: 6.50, total: 13.00, barcode: '6281007001' },
    { name_ar: 'أرز بسمتي الشعلان 5 كغ', quantity: 1, price: 42.00, total: 42.00, barcode: '6281007002' },
    { name_ar: 'زيت دوار الشمس عافية 1.5 لتر', quantity: 2, price: 18.50, total: 37.00, barcode: '6281007003' },
    { name_ar: 'بيض طازج مزارع الديب 30 حبة', quantity: 1, price: 19.50, total: 19.50, barcode: '6281007004' },
  ],
  subtotal: 96.96,
  tax_amount: 14.54,
  discount_amount: 0,
  grand_total: 111.50,
  payment_method: 'card',
  cash_received: 120.00,
  change_given: 8.50,
};

interface InvoiceDesignerPageProps {
  onOpenElectronicInvoice?: () => void;
}

export const InvoiceDesignerPage: React.FC<InvoiceDesignerPageProps> = ({ onOpenElectronicInvoice }) => {
  const [settings, setSettings] = useInvoiceSettings();
  const [draft, setDraft] = useState<InvoiceSettings>(settings);
  const [activeSubTab, setActiveSubTab] = useState<'elements' | 'store' | 'style' | 'qrcode' | 'texts'>('elements');
  const [showSavedBadge, setShowSavedBadge] = useState(false);
  const [previewPaper, setPreviewPaper] = useState<'80mm' | '58mm'>('80mm');

  // Interactive Inspector States
  const [isInspectorActive, setIsInspectorActive] = useState(true);
  const [inspectedTarget, setInspectedTarget] = useState<InspectTarget | null>(null);
  const [highlightedFieldId, setHighlightedFieldId] = useState<string | null>(null);

  // Handle local changes
  const updateDraft = <K extends keyof InvoiceSettings>(key: K, value: InvoiceSettings[K]) => {
    setDraft((prev) => ({ ...prev, [key]: value }));
  };

  const handleSave = () => {
    setSettings(draft);
    setShowSavedBadge(true);
    setTimeout(() => setShowSavedBadge(false), 2500);
  };

  const handleReset = () => {
    if (window.confirm('هل ترغب في استعادة إعدادات وتصميم الفاتورة الافتراضية؟')) {
      setDraft(DEFAULT_INVOICE_SETTINGS);
      setSettings(DEFAULT_INVOICE_SETTINGS);
      setShowSavedBadge(true);
      setTimeout(() => setShowSavedBadge(false), 2500);
    }
  };

  const handleTestPrint = () => {
    const printArea = document.getElementById('aldeeb-thermal-receipt');
    if (printArea) {
      window.print();
    }
  };

  // Click-to-Inspect Handler (Visual Inspector)
  const handleInspectElement = (target: InspectTarget) => {
    setInspectedTarget(target);
    setActiveSubTab(target.subTab);
    setHighlightedFieldId(target.fieldId);

    // Scroll and focus on target input
    setTimeout(() => {
      const el = document.getElementById(target.fieldId);
      if (el) {
        el.scrollIntoView({ behavior: 'smooth', block: 'center' });
        if (el instanceof HTMLInputElement || el instanceof HTMLTextAreaElement) {
          el.focus();
        }
      }
    }, 70);

    // Clear pulsing highlight ring after 3.5s
    setTimeout(() => {
      setHighlightedFieldId((curr) => (curr === target.fieldId ? null : curr));
    }, 3500);
  };

  // Direct toggle from preview hover badge
  const handleToggleElementVisibility = (toggleKey: keyof InvoiceSettings) => {
    const newValue = !draft[toggleKey];
    updateDraft(toggleKey, newValue as any);
  };

  // Helper for applying highlight styles to inputs/controls
  const getHighlightClass = (id: string) => {
    if (highlightedFieldId === id) {
      return 'ring-4 ring-blue-500 border-blue-600 bg-blue-50/70 shadow-lg transition-all duration-300 animate-pulse';
    }
    return '';
  };

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 bg-white p-6 rounded-2xl border border-slate-200 shadow-xs">
        <div className="flex items-center gap-3">
          <div className="w-12 h-12 bg-blue-50 text-blue-600 rounded-xl flex items-center justify-center shrink-0">
            <Receipt className="w-6 h-6" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h1 className="text-xl font-black text-slate-900 tracking-tight">
                مصمم ومحرر قوالب الفواتير والباركود الإلكتروني
              </h1>
              <span className="px-2 py-0.5 rounded-full bg-emerald-50 text-emerald-800 border border-emerald-200 text-[10px] font-bold">
                تحديد تفاعلي مباشر
              </span>
            </div>
            <p className="text-xs text-slate-500 mt-1">
              انقر على أي عنصر بالفاتورة في لوحة المعاينة ليتم توجيهك فوراً للحقل الخاص به وتعديله أو إخفائه.
            </p>
          </div>
        </div>

        {/* Action Buttons */}
        <div className="flex items-center gap-2">
          {showSavedBadge && (
            <div className="flex items-center gap-1.5 px-3 py-2 bg-emerald-50 text-emerald-700 border border-emerald-200 rounded-xl text-xs font-bold animate-pulse">
              <Check className="w-4 h-4" />
              <span>تم الحفظ والتطبيق في الكاشير!</span>
            </div>
          )}

          <button
            onClick={handleReset}
            className="px-3 py-2 bg-slate-100 hover:bg-slate-200 text-slate-700 rounded-xl text-xs font-bold flex items-center gap-1.5 transition-colors"
          >
            <RotateCcw className="w-4 h-4" />
            <span>استعادة الافتراضي</span>
          </button>

          <button
            onClick={handleTestPrint}
            className="px-3.5 py-2 bg-slate-800 hover:bg-slate-900 text-white rounded-xl text-xs font-bold flex items-center gap-1.5 transition-colors shadow-xs"
          >
            <Printer className="w-4 h-4" />
            <span>طباعة تجريبية</span>
          </button>

          <button
            onClick={handleSave}
            className="px-5 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-xl text-xs font-bold flex items-center gap-1.5 transition-colors shadow-sm"
          >
            <Save className="w-4 h-4" />
            <span>حفظ واعتماد التعديلات</span>
          </button>
        </div>
      </div>

      {/* Main Grid: Left Controls (Tabs), Right Live Interactive Preview */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
        {/* RIGHT (Controls & Settings - 7 cols) */}
        <div className="lg:col-span-7 bg-white rounded-2xl border border-slate-200 shadow-xs overflow-hidden">
          {/* Sub Tabs */}
          <div className="flex border-b border-slate-200 bg-slate-50/70 p-2 gap-1 overflow-x-auto text-xs font-bold">
            <button
              onClick={() => setActiveSubTab('elements')}
              className={`px-3.5 py-2 rounded-xl flex items-center gap-1.5 transition-all shrink-0 ${
                activeSubTab === 'elements'
                  ? 'bg-white text-blue-700 shadow-xs border border-slate-200/60'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              <Eye className="w-4 h-4" />
              <span>إظهار وإخفاء العناصر</span>
            </button>

            <button
              onClick={() => setActiveSubTab('store')}
              className={`px-3.5 py-2 rounded-xl flex items-center gap-1.5 transition-all shrink-0 ${
                activeSubTab === 'store'
                  ? 'bg-white text-blue-700 shadow-xs border border-slate-200/60'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              <FileText className="w-4 h-4" />
              <span>معلومات المنشأة والترويسة</span>
            </button>

            <button
              onClick={() => setActiveSubTab('style')}
              className={`px-3.5 py-2 rounded-xl flex items-center gap-1.5 transition-all shrink-0 ${
                activeSubTab === 'style'
                  ? 'bg-white text-blue-700 shadow-xs border border-slate-200/60'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              <Sliders className="w-4 h-4" />
              <span>المظهر والورق والطباعة</span>
            </button>

            <button
              onClick={() => setActiveSubTab('qrcode')}
              className={`px-3.5 py-2 rounded-xl flex items-center gap-1.5 transition-all shrink-0 ${
                activeSubTab === 'qrcode'
                  ? 'bg-white text-blue-700 shadow-xs border border-slate-200/60'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              <QrCode className="w-4 h-4" />
              <span>الباركود والفوترة الإلكترونية</span>
            </button>

            <button
              onClick={() => setActiveSubTab('texts')}
              className={`px-3.5 py-2 rounded-xl flex items-center gap-1.5 transition-all shrink-0 ${
                activeSubTab === 'texts'
                  ? 'bg-white text-blue-700 shadow-xs border border-slate-200/60'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              <Type className="w-4 h-4" />
              <span>السياسات والرسائل المخصصة</span>
            </button>
          </div>

          <div className="p-6">
            {/* Visual Inspector Focus Card Notification */}
            {inspectedTarget && (
              <div className="mb-6 p-4 bg-gradient-to-r from-blue-50 via-indigo-50/70 to-blue-50 border-2 border-blue-400 rounded-2xl flex items-center justify-between gap-3 shadow-sm animate-in fade-in slide-in-from-top-2 duration-200">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-xl bg-blue-600 text-white flex items-center justify-center shrink-0 shadow-xs">
                    <MousePointerClick className="w-5 h-5 animate-bounce" />
                  </div>
                  <div>
                    <div className="text-xs font-black text-slate-900 flex items-center gap-2">
                      <span>تم توجيهك لتعديل:</span>
                      <span className="text-blue-700 bg-white px-2.5 py-0.5 rounded-lg border border-blue-200 shadow-xs">
                        {inspectedTarget.title}
                      </span>
                    </div>
                    <p className="text-[11px] text-slate-600 mt-1 leading-relaxed">
                      {inspectedTarget.description} — تم تمييز الحقل الخاص به أدناه باللون الأزرق.
                    </p>
                  </div>
                </div>

                <div className="flex items-center gap-1.5 shrink-0">
                  {inspectedTarget.toggleKey && (
                    <button
                      type="button"
                      onClick={() => handleToggleElementVisibility(inspectedTarget.toggleKey!)}
                      className={`px-3 py-1.5 rounded-xl text-xs font-bold transition-all flex items-center gap-1 shadow-xs ${
                        draft[inspectedTarget.toggleKey]
                          ? 'bg-rose-100 hover:bg-rose-200 text-rose-800'
                          : 'bg-emerald-100 hover:bg-emerald-200 text-emerald-800'
                      }`}
                    >
                      {draft[inspectedTarget.toggleKey] ? (
                        <>
                          <EyeOff className="w-3.5 h-3.5" />
                          <span>إخفاء هذا العنصر</span>
                        </>
                      ) : (
                        <>
                          <Eye className="w-3.5 h-3.5" />
                          <span>إظهار هذا العنصر</span>
                        </>
                      )}
                    </button>
                  )}
                  <button
                    type="button"
                    onClick={() => setInspectedTarget(null)}
                    className="p-1.5 text-slate-400 hover:text-slate-600 rounded-lg hover:bg-white/60"
                    title="إغلاق التلميح"
                  >
                    ×
                  </button>
                </div>
              </div>
            )}

            {/* 1. ELEMENTS TOGGLES */}
            {activeSubTab === 'elements' && (
              <div className="space-y-6">
                <div>
                  <h3 className="text-sm font-black text-slate-900">
                    التحكم بإظهار وإخفاء أقسام وحقول الفاتورة
                  </h3>
                  <p className="text-xs text-slate-500 mt-0.5">
                    قم بتفعيل أو تعطيل أي عنصر ليختفي فوراً من إيصال الكاشير المطبوع والفاتورة.
                  </p>
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  {[
                    { key: 'showLogo', id: 'toggle-showLogo', label: 'شعار المتجر (Logo)', desc: 'عرض شعار الديب مول بأعلى الفاتورة' },
                    { key: 'showStoreName', id: 'toggle-showStoreName', label: 'اسم المتجر الرئيسي', desc: 'الديب مول باللغتين العربية والإنجليزية' },
                    { key: 'showBranchName', id: 'toggle-showBranchName', label: 'اسم الفرع', desc: 'إظهار اسم الفرع المصدر للفاتورة' },
                    { key: 'showSubtitle', id: 'toggle-showSubtitle', label: 'عنوان الفاتورة الفرعي', desc: 'مثل: فاتورة ضريبية مبسطة' },
                    { key: 'showTaxNumber', id: 'toggle-showTaxNumber', label: 'الرقم الضريبي (VAT / TRN)', desc: 'رقم التسجيل الضريبي الرسمي للمنشأة' },
                    { key: 'showCommercialRegister', id: 'toggle-showCommercialRegister', label: 'السجل التجاري (CR)', desc: 'رقم السجل التجاري' },
                    { key: 'showPhone', id: 'toggle-showPhone', label: 'رقم الهاتف وخدمة العملاء', desc: 'أرقام الاتصال والتواصل' },
                    { key: 'showAddress', id: 'toggle-showAddress', label: 'العنوان الجغرافي للمتجر', desc: 'المدينة والشارع والمجمع' },
                    { key: 'showInvoiceNumber', id: 'toggle-showInvoiceNumber', label: 'رقم الفاتورة (Invoice #)', desc: 'كود الفاتورة التعريفي الفريد' },
                    { key: 'showBarcodeUnderNumber', id: 'toggle-showBarcodeUnderNumber', label: 'باركود رقم الفاتورة الخطي', desc: 'رمز باركود سريع للقارئ الضوئي' },
                    { key: 'showDateTime', id: 'toggle-showDateTime', label: 'تاريخ ووقت الفاتورة', desc: 'التاريخ والساعة والدقيقة' },
                    { key: 'showCashierName', id: 'toggle-showCashierName', label: 'اسم الكاشير ونقطة البيع', desc: 'اسم الموظف ورقم نقطة الكاشير' },
                    { key: 'showCustomerName', id: 'toggle-showCustomerName', label: 'اسم وبيانات العميل', desc: 'الاسم ورقم هاتف العميل' },
                    { key: 'showCustomerPhone', id: 'toggle-showCustomerPhone', label: 'رقم هاتف العميل المنفصل', desc: 'إظهار رقم جوال العميل' },
                    { key: 'showItemCode', id: 'toggle-showItemCode', label: 'كود وباركود الصنف', desc: 'إظهار رقم باركود كل سلعة' },
                    { key: 'showItemUnitPrice', id: 'toggle-showItemUnitPrice', label: 'سعر الوحدة والكمية', desc: 'تفصيل الكمية × السعر الفردي' },
                    { key: 'showSubtotal', id: 'toggle-showSubtotal', label: 'المجموع الخاضع للضريبة', desc: 'صافي المبلغ قبل إضافة الضريبة' },
                    { key: 'showTaxAmount', id: 'toggle-showTaxAmount', label: 'قيمة الضريبة المضافة', desc: 'مبلغ الضريبة محسوباً بدقة' },
                    { key: 'showGrandTotal', id: 'toggle-showGrandTotal', label: 'المبلغ الإجمالي النهائي', desc: 'القيمة النهائية المطلوب سدادها' },
                    { key: 'showPaymentMethod', id: 'toggle-showPaymentMethod', label: 'طريقة الدفع والتفاصيل', desc: 'كاش، مدى، شبكة، فيزا، والمتبقي' },
                    { key: 'showCashReceivedAndChange', id: 'toggle-showCashReceivedAndChange', label: 'المبلغ المستلم والمتبقي', desc: 'في حالة الدفع النقدي' },
                    { key: 'showQrCode', id: 'toggle-showQrCode', label: 'الباركود المربع الإلكتروني QR', desc: 'الباركود النظامي الذي يفتح الفاتورة' },
                    { key: 'showSecurityBadge', id: 'toggle-showSecurityBadge', label: 'ختم الفاتورة الإلكترونية', desc: 'شارة اعتماد الفوترة النظامية' },
                    { key: 'showReturnPolicy', id: 'toggle-showReturnPolicy', label: 'سياسة الاستبدال والاسترجاع', desc: 'الشروط المطبوعة أسفل الفاتورة' },
                    { key: 'showCustomFooterNote', id: 'toggle-showCustomFooterNote', label: 'رسالة الشكر والختام', desc: 'عبارات التقدير وحسابات التواصل' },
                  ].map((item) => {
                    const isChecked = Boolean(draft[item.key as keyof InvoiceSettings]);
                    const highlight = getHighlightClass(item.id);
                    return (
                      <label
                        key={item.key}
                        id={item.id}
                        className={`flex items-start gap-3 p-3 rounded-xl border transition-all cursor-pointer ${highlight} ${
                          isChecked
                            ? 'bg-blue-50/40 border-blue-200'
                            : 'bg-slate-50/50 border-slate-200 text-slate-400'
                        }`}
                      >
                        <input
                          type="checkbox"
                          checked={isChecked}
                          onChange={(e) => updateDraft(item.key as keyof InvoiceSettings, e.target.checked as any)}
                          className="mt-1 w-4 h-4 rounded text-blue-600 focus:ring-blue-500 cursor-pointer"
                        />
                        <div className="flex-1">
                          <div className={`text-xs font-bold ${isChecked ? 'text-slate-900' : 'text-slate-500'}`}>
                            {item.label}
                          </div>
                          <div className="text-[10px] text-slate-500 mt-0.5 leading-tight">
                            {item.desc}
                          </div>
                        </div>
                      </label>
                    );
                  })}
                </div>
              </div>
            )}

            {/* 2. STORE & HEADER INFO */}
            {activeSubTab === 'store' && (
              <div className="space-y-4">
                <div>
                  <h3 className="text-sm font-black text-slate-900">بيانات المتجر والترويسة الرسمية</h3>
                  <p className="text-xs text-slate-500 mt-0.5">
                    البيانات القانونية والتعريفية التي تطبع على الفواتير والإيصالات.
                  </p>
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 text-xs">
                  <div>
                    <label className="block font-bold text-slate-700 mb-1">اسم المتجر بالعربي</label>
                    <input
                      id="field-storeNameAr"
                      type="text"
                      value={draft.storeNameAr}
                      onChange={(e) => updateDraft('storeNameAr', e.target.value)}
                      className={`w-full px-3 py-2 border border-slate-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none ${getHighlightClass('field-storeNameAr')}`}
                    />
                  </div>

                  <div>
                    <label className="block font-bold text-slate-700 mb-1">اسم المتجر بالإنجليزي</label>
                    <input
                      id="field-storeNameEn"
                      type="text"
                      value={draft.storeNameEn}
                      onChange={(e) => updateDraft('storeNameEn', e.target.value)}
                      className={`w-full px-3 py-2 border border-slate-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none font-mono ${getHighlightClass('field-storeNameEn')}`}
                    />
                  </div>

                  <div>
                    <label className="block font-bold text-slate-700 mb-1">اسم الفرع الافتراضي</label>
                    <input
                      id="field-branchName"
                      type="text"
                      value={draft.branchName}
                      onChange={(e) => updateDraft('branchName', e.target.value)}
                      className={`w-full px-3 py-2 border border-slate-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none ${getHighlightClass('field-branchName')}`}
                    />
                  </div>

                  <div>
                    <label className="block font-bold text-slate-700 mb-1">عنوان الفاتورة الفرعي</label>
                    <input
                      id="field-headerSubtitle"
                      type="text"
                      value={draft.headerSubtitle}
                      onChange={(e) => updateDraft('headerSubtitle', e.target.value)}
                      className={`w-full px-3 py-2 border border-slate-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none ${getHighlightClass('field-headerSubtitle')}`}
                    />
                  </div>

                  <div>
                    <label className="block font-bold text-slate-700 mb-1">الرقم الضريبي (VAT / TRN)</label>
                    <input
                      id="field-taxNumber"
                      type="text"
                      value={draft.taxNumber}
                      onChange={(e) => updateDraft('taxNumber', e.target.value)}
                      className={`w-full px-3 py-2 border border-slate-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none font-mono ${getHighlightClass('field-taxNumber')}`}
                    />
                  </div>

                  <div>
                    <label className="block font-bold text-slate-700 mb-1">السجل التجاري (CR)</label>
                    <input
                      id="field-commercialRegister"
                      type="text"
                      value={draft.commercialRegister}
                      onChange={(e) => updateDraft('commercialRegister', e.target.value)}
                      className={`w-full px-3 py-2 border border-slate-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none font-mono ${getHighlightClass('field-commercialRegister')}`}
                    />
                  </div>

                  <div>
                    <label className="block font-bold text-slate-700 mb-1">أرقام الهواتف والتواصل</label>
                    <input
                      id="field-phone"
                      type="text"
                      value={draft.phone}
                      onChange={(e) => updateDraft('phone', e.target.value)}
                      className={`w-full px-3 py-2 border border-slate-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none font-mono ${getHighlightClass('field-phone')}`}
                    />
                  </div>

                  <div>
                    <label className="block font-bold text-slate-700 mb-1">العنوان والموقع</label>
                    <input
                      id="field-address"
                      type="text"
                      value={draft.address}
                      onChange={(e) => updateDraft('address', e.target.value)}
                      className={`w-full px-3 py-2 border border-slate-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none ${getHighlightClass('field-address')}`}
                    />
                  </div>

                  <div className="sm:col-span-2">
                    <label className="block font-bold text-slate-700 mb-1">رابط صورة الشعار (Logo URL)</label>
                    <input
                      id="field-logoUrl"
                      type="text"
                      value={draft.logoUrl}
                      onChange={(e) => updateDraft('logoUrl', e.target.value)}
                      className={`w-full px-3 py-2 border border-slate-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none font-mono text-xs ${getHighlightClass('field-logoUrl')}`}
                      placeholder="https://..."
                    />
                  </div>

                  <div>
                    <label className="block font-bold text-slate-700 mb-1">
                      ارتفاع الشعار: <span className="font-mono text-blue-600">{draft.logoHeight}px</span>
                    </label>
                    <input
                      id="field-logoHeight"
                      type="range"
                      min={28}
                      max={80}
                      step={2}
                      value={draft.logoHeight}
                      onChange={(e) => updateDraft('logoHeight', Number(e.target.value))}
                      className="w-full accent-blue-600 cursor-pointer"
                    />
                  </div>

                  <div>
                    <label className="block font-bold text-slate-700 mb-1">
                      نسبة ضريبة القيمة المضافة (%): <span className="font-mono text-blue-600">{draft.taxRatePercent}%</span>
                    </label>
                    <input
                      id="field-taxRatePercent"
                      type="number"
                      min={0}
                      max={100}
                      value={draft.taxRatePercent}
                      onChange={(e) => updateDraft('taxRatePercent', Number(e.target.value))}
                      className={`w-full px-3 py-2 border border-slate-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none font-mono ${getHighlightClass('field-taxRatePercent')}`}
                    />
                  </div>
                </div>
              </div>
            )}

            {/* 3. STYLE & PAPER OPTIONS */}
            {activeSubTab === 'style' && (
              <div className="space-y-5">
                <div>
                  <h3 className="text-sm font-black text-slate-900">المظهر العام وقياس الورق والطباعة</h3>
                  <p className="text-xs text-slate-500 mt-0.5">
                    ضبط عرض الورقة، ونوع الخط، وشكل الفواصل بين الأقسام.
                  </p>
                </div>

                <div className="space-y-4 text-xs">
                  <div id="field-paperWidth" className={`p-2 rounded-xl ${getHighlightClass('field-paperWidth')}`}>
                    <label className="block font-bold text-slate-700 mb-2">نوع وحجم ورق الطباعة (Paper Format)</label>
                    <div className="grid grid-cols-3 gap-3">
                      {[
                        { id: '80mm', title: 'حراري 80mm', desc: 'طابعات الكاشير القياسية (الموصى به)' },
                        { id: '58mm', title: 'حراري 58mm', desc: 'طابعات كاشير مصغرة ومتنقلة' },
                        { id: 'a4', title: 'فاتورة رسمية A4', desc: 'طباعة ليزرية أو PDF رسمي' },
                      ].map((p) => (
                        <button
                          key={p.id}
                          type="button"
                          onClick={() => {
                            updateDraft('paperWidth', p.id as any);
                            setPreviewPaper(p.id as any);
                          }}
                          className={`p-3 rounded-xl border text-start transition-all ${
                            draft.paperWidth === p.id
                              ? 'border-blue-600 bg-blue-50/60 ring-2 ring-blue-500/20'
                              : 'border-slate-200 hover:border-slate-300 bg-white'
                          }`}
                        >
                          <div className="font-extrabold text-slate-900">{p.title}</div>
                          <div className="text-[10px] text-slate-500 mt-0.5 leading-tight">{p.desc}</div>
                        </button>
                      ))}
                    </div>
                  </div>

                  <div id="field-fontSize" className={`p-2 rounded-xl ${getHighlightClass('field-fontSize')}`}>
                    <label className="block font-bold text-slate-700 mb-2">حجم نصوص الفاتورة (Font Size)</label>
                    <div className="grid grid-cols-3 gap-3">
                      {[
                        { id: 'sm', title: 'مدمج وصغير', desc: 'مناسب لتقليل استهلاك الورق' },
                        { id: 'md', title: 'متوسط قياسي', desc: 'أعلى وضوح وتوازن' },
                        { id: 'lg', title: 'كبير وبارز', desc: 'سهل القراءة لكبار السن' },
                      ].map((f) => (
                        <button
                          key={f.id}
                          type="button"
                          onClick={() => updateDraft('fontSize', f.id as any)}
                          className={`p-3 rounded-xl border text-start transition-all ${
                            draft.fontSize === f.id
                              ? 'border-blue-600 bg-blue-50/60 ring-2 ring-blue-500/20'
                              : 'border-slate-200 hover:border-slate-300 bg-white'
                          }`}
                        >
                          <div className="font-extrabold text-slate-900">{f.title}</div>
                          <div className="text-[10px] text-slate-500 mt-0.5">{f.desc}</div>
                        </button>
                      ))}
                    </div>
                  </div>

                  <div id="field-dividerStyle" className={`p-2 rounded-xl ${getHighlightClass('field-dividerStyle')}`}>
                    <label className="block font-bold text-slate-700 mb-2">نمط الفواصل بين الأقسام (Dividers)</label>
                    <div className="grid grid-cols-4 gap-2">
                      {[
                        { id: 'dashed', title: 'متقطع (Dashed)', sample: '- - - - - - -' },
                        { id: 'dotted', title: 'منقط (Dotted)', sample: '•••••••••••' },
                        { id: 'solid', title: 'خطي (Solid)', sample: '───────────' },
                        { id: 'double', title: 'مزدوج (Double)', sample: '═══════════' },
                      ].map((d) => (
                        <button
                          key={d.id}
                          type="button"
                          onClick={() => updateDraft('dividerStyle', d.id as any)}
                          className={`p-2.5 rounded-xl border text-center transition-all ${
                            draft.dividerStyle === d.id
                              ? 'border-blue-600 bg-blue-50/60 ring-2 ring-blue-500/20'
                              : 'border-slate-200 hover:border-slate-300 bg-white'
                          }`}
                        >
                          <div className="font-bold text-slate-900 text-[11px]">{d.title}</div>
                          <div className="text-[10px] text-slate-400 font-mono mt-1">{d.sample}</div>
                        </button>
                      ))}
                    </div>
                  </div>

                  <div id="field-compactItemSpacing" className="pt-2">
                    <label className="flex items-center gap-3 p-3 rounded-xl border border-slate-200 bg-slate-50/50 cursor-pointer">
                      <input
                        type="checkbox"
                        checked={draft.compactItemSpacing}
                        onChange={(e) => updateDraft('compactItemSpacing', e.target.checked)}
                        className="w-4 h-4 rounded text-blue-600 focus:ring-blue-500"
                      />
                      <div>
                        <div className="font-bold text-slate-900">تقليل تباعد أسطر الأصناف (Eco Print)</div>
                        <div className="text-[10px] text-slate-500">
                          تقليل المسافات الرأسية لتوفير ورق الطباعة الحراري في العمليات الطويلة.
                        </div>
                      </div>
                    </label>
                  </div>
                </div>
              </div>
            )}

            {/* 4. QR CODE & E-INVOICE SETTINGS */}
            {activeSubTab === 'qrcode' && (
              <div className="space-y-5">
                <div>
                  <h3 className="text-sm font-black text-slate-900">
                    الباركود المربع والفوترة الإلكترونية (Real E-Invoice QR)
                  </h3>
                  <p className="text-xs text-slate-500 mt-0.5">
                    الباركود يطبع بشكل قياسي حقيقي، ومسحه بكاميرا أي هاتف يفتح الفاتورة الإلكترونية المعتمدة فوراً!
                  </p>
                </div>

                <div className="space-y-4 text-xs">
                  <div id="field-qrType" className={`p-2 rounded-xl ${getHighlightClass('field-qrType')}`}>
                    <label className="block font-bold text-slate-700 mb-2">وجهة الباركود المربع عند المسح</label>
                    <div className="space-y-2">
                      <label
                        className={`flex items-start gap-3 p-3 rounded-xl border cursor-pointer transition-all ${
                          draft.qrType === 'electronic_url'
                            ? 'bg-blue-50/60 border-blue-600 ring-2 ring-blue-500/20'
                            : 'bg-white border-slate-200'
                        }`}
                      >
                        <input
                          type="radio"
                          name="qrType"
                          checked={draft.qrType === 'electronic_url'}
                          onChange={() => updateDraft('qrType', 'electronic_url')}
                          className="mt-0.5 w-4 h-4 text-blue-600 focus:ring-blue-500"
                        />
                        <div>
                          <div className="font-black text-slate-900">
                            رابط الفاتورة الإلكترونية المعتمدة (الموصى به - يفتح الفاتورة على الجوال)
                          </div>
                          <div className="text-[11px] text-slate-500 mt-0.5 leading-relaxed">
                            عندما يقوم المشتري بمسح الباركود بكاميرا أي هاتف (iPhone أو Android)، تفتح شاشة الفاتورة الإلكترونية الرسمية متضمنة تفاصيل الأصناف والضريبة ومطابقة المعايير مع إمكانية التحميل والطباعة.
                          </div>
                        </div>
                      </label>

                      <label
                        className={`flex items-start gap-3 p-3 rounded-xl border cursor-pointer transition-all ${
                          draft.qrType === 'zatca_tlv'
                            ? 'bg-blue-50/60 border-blue-600 ring-2 ring-blue-500/20'
                            : 'bg-white border-slate-200'
                        }`}
                      >
                        <input
                          type="radio"
                          name="qrType"
                          checked={draft.qrType === 'zatca_tlv'}
                          onChange={() => updateDraft('qrType', 'zatca_tlv')}
                          className="mt-0.5 w-4 h-4 text-blue-600 focus:ring-blue-500"
                        />
                        <div>
                          <div className="font-black text-slate-900">
                            ترميز هيئة الزكاة والضريبة والجمارك (ZATCA TLV Base64)
                          </div>
                          <div className="text-[11px] text-slate-500 mt-0.5 leading-relaxed">
                            ترميز Tag-Length-Value معتمد لقراءة الفاتورة عبر تطبيقات التدقيق الضريبي المتخصصة.
                          </div>
                        </div>
                      </label>
                    </div>
                  </div>

                  <div id="field-qrCodeSize" className={`p-2 rounded-xl ${getHighlightClass('field-qrCodeSize')}`}>
                    <label className="block font-bold text-slate-700 mb-1">
                      حجم الباركود في الطباعة الحرارية: <span className="font-mono text-blue-600">{draft.qrCodeSize}px</span>
                    </label>
                    <input
                      type="range"
                      min={80}
                      max={140}
                      step={4}
                      value={draft.qrCodeSize}
                      onChange={(e) => updateDraft('qrCodeSize', Number(e.target.value))}
                      className="w-full accent-blue-600 cursor-pointer"
                    />
                    <div className="flex justify-between text-[10px] text-slate-400 mt-1 font-mono">
                      <span>صغير (80px)</span>
                      <span>قياسي (104px)</span>
                      <span>كبير وواضح (140px)</span>
                    </div>
                  </div>

                  {/* Test Electronic Invoice Link Button */}
                  <div className="p-4 bg-emerald-50 border border-emerald-200 rounded-2xl flex items-center justify-between gap-3">
                    <div className="flex items-center gap-2.5">
                      <div className="w-8 h-8 rounded-lg bg-emerald-600 text-white flex items-center justify-center shrink-0">
                        <QrCode className="w-5 h-5" />
                      </div>
                      <div>
                        <div className="font-bold text-emerald-950 text-xs">
                          تجربة شاشة الفاتورة الإلكترونية المعتمدة
                        </div>
                        <div className="text-[10px] text-emerald-700 mt-0.5">
                          شاهد الفاتورة الإلكترونية التي تظهر للعميل عند مسح الباركود
                        </div>
                      </div>
                    </div>

                    <a
                      href="#invoice?id=RCP-POS-948102"
                      target="_blank"
                      rel="noreferrer"
                      onClick={(e) => {
                        if (onOpenElectronicInvoice) {
                          e.preventDefault();
                          onOpenElectronicInvoice();
                        }
                      }}
                      className="px-3 py-1.5 bg-emerald-700 hover:bg-emerald-800 text-white rounded-xl text-xs font-bold flex items-center gap-1 shrink-0 shadow-xs"
                    >
                      <span>عرض الفاتورة</span>
                      <ExternalLink className="w-3.5 h-3.5" />
                    </a>
                  </div>
                </div>
              </div>
            )}

            {/* 5. CUSTOM TEXTS & POLICIES */}
            {activeSubTab === 'texts' && (
              <div className="space-y-4 text-xs">
                <div>
                  <h3 className="text-sm font-black text-slate-900">النصوص والسياسات المخصصة</h3>
                  <p className="text-xs text-slate-500 mt-0.5">
                    التحكم بالنصوص التي تظهر في تذييل الفاتورة وشروط الاسترجاع والاستبدال.
                  </p>
                </div>

                <div id="field-returnPolicyText" className={`p-2 rounded-xl ${getHighlightClass('field-returnPolicyText')}`}>
                  <label className="block font-bold text-slate-700 mb-1">
                    نص سياسة الاستبدال والاسترجاع
                  </label>
                  <textarea
                    rows={3}
                    value={draft.returnPolicyText}
                    onChange={(e) => updateDraft('returnPolicyText', e.target.value)}
                    className="w-full px-3 py-2 border border-slate-300 rounded-xl focus:ring-2 focus:ring-blue-500 outline-none text-xs leading-relaxed"
                  />
                </div>

                <div id="field-customFooterNote" className={`p-2 rounded-xl ${getHighlightClass('field-customFooterNote')}`}>
                  <label className="block font-bold text-slate-700 mb-1">
                    رسالة الشكر والختام أسفل الفاتورة
                  </label>
                  <textarea
                    rows={2}
                    value={draft.customFooterNote}
                    onChange={(e) => updateDraft('customFooterNote', e.target.value)}
                    className="w-full px-3 py-2 border border-slate-300 rounded-xl focus:ring-2 focus:ring-blue-500 outline-none text-xs leading-relaxed"
                  />
                </div>

                <div id="field-securityBadgeText" className={`p-2 rounded-xl ${getHighlightClass('field-securityBadgeText')}`}>
                  <label className="block font-bold text-slate-700 mb-1">
                    نص ختم الفاتورة الإلكترونية المعتمدة
                  </label>
                  <input
                    type="text"
                    value={draft.securityBadgeText}
                    onChange={(e) => updateDraft('securityBadgeText', e.target.value)}
                    className="w-full px-3 py-2 border border-slate-300 rounded-xl focus:ring-2 focus:ring-blue-500 outline-none text-xs"
                  />
                </div>
              </div>
            )}
          </div>
        </div>

        {/* LEFT (Realistic Live Thermal Preview - 5 cols) */}
        <div className="lg:col-span-5 space-y-3">
          <div className="flex items-center justify-between px-2">
            <span className="text-xs font-black text-slate-800 flex items-center gap-1.5">
              <Eye className="w-4 h-4 text-blue-600" />
              <span>معاينة حية وتحديد بصري فوري</span>
            </span>

            <div className="flex items-center gap-2">
              {/* Toggle Inspector Mode */}
              <button
                type="button"
                onClick={() => setIsInspectorActive(!isInspectorActive)}
                className={`px-2.5 py-1 rounded-xl text-[10px] font-bold flex items-center gap-1 transition-all border ${
                  isInspectorActive
                    ? 'bg-blue-50 text-blue-700 border-blue-200 ring-2 ring-blue-500/20'
                    : 'bg-slate-100 text-slate-500 border-slate-200'
                }`}
                title="تفعيل/تعطيل وضع التحديد والتوجيه بالنقر على الفاتورة"
              >
                <MousePointerClick className="w-3.5 h-3.5" />
                <span>{isInspectorActive ? 'وضع التحديد: نشط' : 'التحديد: معطل'}</span>
              </button>

              <div className="flex items-center gap-1 bg-slate-200 p-0.5 rounded-lg text-[10px] font-bold">
                <button
                  type="button"
                  onClick={() => setPreviewPaper('80mm')}
                  className={`px-2 py-0.5 rounded-md ${previewPaper === '80mm' ? 'bg-white text-slate-900 shadow-xs' : 'text-slate-600'}`}
                >
                  80mm
                </button>
                <button
                  type="button"
                  onClick={() => setPreviewPaper('58mm')}
                  className={`px-2 py-0.5 rounded-md ${previewPaper === '58mm' ? 'bg-white text-slate-900 shadow-xs' : 'text-slate-600'}`}
                >
                  58mm
                </button>
              </div>
            </div>
          </div>

          {/* Interactive Hint Banner */}
          {isInspectorActive && (
            <div className="p-2.5 bg-blue-50/80 border border-blue-200 rounded-xl text-[11px] text-blue-900 flex items-center gap-2 leading-tight">
              <Sparkles className="w-4 h-4 text-blue-600 shrink-0" />
              <span>
                <strong>انقر مباشرة على أي عنصر</strong> في الفاتورة بالأسفل ليتم نقلك فوراً إلى خيارات تعديله أو إخفائه.
              </span>
            </div>
          )}

          {/* Thermal Paper Simulation Container */}
          <div className="bg-slate-200/80 p-4 sm:p-6 rounded-3xl border border-slate-300 flex justify-center items-center shadow-inner overflow-hidden">
            <div className="relative shadow-2xl rounded-sm transform hover:scale-[1.005] transition-transform duration-200">
              {/* Top tear effect */}
              <div className="h-2 bg-white border-b border-dashed border-slate-200 w-full" />

              {/* Thermal Component with Interactive Inspector */}
              <ThermalReceiptView
                data={SAMPLE_RECEIPT}
                settings={{
                  ...draft,
                  paperWidth: previewPaper,
                }}
                interactiveInspector={isInspectorActive}
                onInspectElement={handleInspectElement}
                onToggleElementVisibility={handleToggleElementVisibility}
                activeInspectedKey={inspectedTarget?.key}
                onOpenElectronicInvoice={onOpenElectronicInvoice}
              />

              {/* Bottom paper tear serrated edge simulation */}
              <div 
                className="h-3 bg-white w-full"
                style={{
                  clipPath: 'polygon(0% 0%, 5% 100%, 10% 0%, 15% 100%, 20% 0%, 25% 100%, 30% 0%, 35% 100%, 40% 0%, 45% 100%, 50% 0%, 55% 100%, 60% 0%, 65% 100%, 70% 0%, 75% 100%, 80% 0%, 85% 100%, 90% 0%, 95% 100%, 100% 0%)'
                }}
              />
            </div>
          </div>

          <div className="text-center text-[11px] text-slate-500">
            تتحدث المعاينة تلقائياً وبشكل فوري عند تعديل أي إعداد أو خيار أعلاه.
          </div>
        </div>
      </div>
    </div>
  );
};
