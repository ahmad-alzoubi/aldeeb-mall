import React, { useState, useEffect, useMemo, useCallback } from 'react';
import { 
  Building, 
  Briefcase, 
  CreditCard, 
  Calendar, 
  CheckCircle2, 
  Clock, 
  FileText, 
  Search, 
  ShieldCheck, 
  Truck, 
  DollarSign, 
  Plus,
  Eye,
  Printer,
  RotateCcw,
  AlertTriangle,
  RefreshCw,
  XCircle,
  FileCheck,
  ChevronRight,
  TrendingUp,
  Receipt,
  QrCode
} from 'lucide-react';
import { 
  CorporateAccount, 
  CorporateQuotation, 
  CorporateInvoice, 
  CorporatePayment, 
  CorporateReturn, 
  Product, 
  StaffMember,
  PaymentTerms
} from '../types';
import { corporateB2bApi } from '../lib/corporateB2bApi';

interface CorporateB2BPageProps {
  currentUser?: StaffMember;
  activeBranchId?: string;
  products?: Product[];
}

export const CorporateB2BPage: React.FC<CorporateB2BPageProps> = ({
  currentUser,
  activeBranchId = 'all',
  products = []
}) => {
  // Navigation Tabs
  const [activeSubTab, setActiveSubTab] = useState<'accounts' | 'quotations' | 'invoices' | 'payments' | 'returns'>('accounts');

  // Datasets from PostgreSQL Database
  const [accounts, setAccounts] = useState<CorporateAccount[]>([]);
  const [quotations, setQuotations] = useState<CorporateQuotation[]>([]);
  const [invoices, setInvoices] = useState<CorporateInvoice[]>([]);
  const [payments, setPayments] = useState<CorporatePayment[]>([]);
  const [returns, setReturns] = useState<CorporateReturn[]>([]);

  // UI State
  const [isLoading, setIsLoading] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [notification, setNotification] = useState<{ type: 'success' | 'error'; message: string } | null>(null);

  // Modals State
  const [selectedAccount, setSelectedAccount] = useState<CorporateAccount | null>(null);
  const [selectedInvoice, setSelectedInvoice] = useState<CorporateInvoice | null>(null);
  const [selectedQuotation, setSelectedQuotation] = useState<CorporateQuotation | null>(null);

  const [isCreateAccountOpen, setIsCreateAccountOpen] = useState(false);
  const [isCreateQuotationOpen, setIsCreateQuotationOpen] = useState(false);
  const [isCreateInvoiceOpen, setIsCreateInvoiceOpen] = useState(false);
  const [isRecordPaymentOpen, setIsRecordPaymentOpen] = useState(false);
  const [isCreateReturnOpen, setIsCreateReturnOpen] = useState(false);
  const [isPrintInvoiceOpen, setIsPrintInvoiceOpen] = useState(false);

  // New Account Form State
  const [newAccount, setNewAccount] = useState({
    company_name: '',
    cr_number: '',
    vat_number: '',
    contact_person: '',
    phone: '',
    email: '',
    city: 'دمشق',
    address: '',
    branch_id: activeBranchId && activeBranchId !== 'all' ? activeBranchId : 'b-dam-01',
    monthly_credit_limit: 5000000,
    payment_terms: 'Net-30' as PaymentTerms,
    recurring_schedule: 'كل أحد 08:00 صباحاً',
    items_summary: '',
    notes: '',
  });

  // Quotation Builder State
  const [quoteTargetAccountId, setQuoteTargetAccountId] = useState('');
  const [quoteItems, setQuoteItems] = useState<Array<{ product_id: string; quantity: number; unit_price: number; discount_percent: number; notes?: string }>>([]);
  const [quoteGlobalDiscount, setQuoteGlobalDiscount] = useState(10);
  const [quoteNotes, setQuoteNotes] = useState('');

  // Direct Invoice Builder State
  const [invoiceTargetAccountId, setInvoiceTargetAccountId] = useState('');
  const [invoiceItems, setInvoiceItems] = useState<Array<{ product_id: string; quantity: number; unit_price: number; discount_percent: number }>>([]);
  const [invoiceNotes, setInvoiceNotes] = useState('');

  // Payment Settlement Form State
  const [paymentAmount, setPaymentAmount] = useState<number>(0);
  const [paymentMethod, setPaymentMethod] = useState<'bank_transfer' | 'check' | 'cash' | 'credit_card'>('bank_transfer');
  const [paymentRefNumber, setPaymentRefNumber] = useState('');
  const [paymentNotes, setPaymentNotes] = useState('');

  // Return Form State
  const [returnItems, setReturnItems] = useState<Array<{ product_id: string; quantity: number; unit_price: number; reason: string }>>([]);
  const [returnReason, setReturnReason] = useState('');

  // Load Real Cloud / Local Database Data
  const loadData = useCallback(async () => {
    setIsLoading(true);
    try {
      const branchToQuery = activeBranchId === 'all' ? undefined : activeBranchId;
      const [accs, quotes, invs, pays, rets] = await Promise.all([
        corporateB2bApi.fetchCorporateAccounts(branchToQuery),
        corporateB2bApi.fetchQuotations(branchToQuery),
        corporateB2bApi.fetchInvoices(branchToQuery),
        corporateB2bApi.fetchPayments(),
        corporateB2bApi.fetchReturns(branchToQuery),
      ]);
      setAccounts(accs);
      setQuotations(quotes);
      setInvoices(invs);
      setPayments(pays);
      setReturns(rets);
    } catch (err: any) {
      console.error('Error loading Corporate B2B data:', err);
      setNotification({
        type: 'error',
        message: `خطأ في مزامنة بيانات الشركات: ${err.message || 'فشل الاتصال بالخادم'}`,
      });
    } finally {
      setIsLoading(false);
    }
  }, [activeBranchId]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  // Toast auto-clear
  useEffect(() => {
    if (notification) {
      const timer = setTimeout(() => setNotification(null), 6000);
      return () => clearTimeout(timer);
    }
  }, [notification]);

  // Derived KPI Metrics
  const kpiMetrics = useMemo(() => {
    const totalAccounts = accounts.length;
    const totalInvoiced = invoices.reduce((sum, inv) => sum + (inv.total_amount || 0), 0);
    const totalCollected = invoices.reduce((sum, inv) => sum + (inv.paid_amount || 0), 0);
    const totalOutstanding = invoices.reduce((sum, inv) => sum + (inv.remaining_amount || 0), 0);
    const pendingQuotes = quotations.filter((q) => q.status === 'draft' || q.status === 'pending_approval').length;
    const overdueAccounts = accounts.filter((a) => a.current_balance > a.monthly_credit_limit || a.status === 'overdue').length;

    return {
      totalAccounts,
      totalInvoiced,
      totalCollected,
      totalOutstanding,
      pendingQuotes,
      overdueAccounts,
    };
  }, [accounts, invoices, quotations]);

  // Filtered Accounts
  const filteredAccounts = useMemo(() => {
    return accounts.filter((acc) => {
      const matchSearch =
        acc.company_name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        acc.cr_number.includes(searchQuery) ||
        acc.contact_person.toLowerCase().includes(searchQuery.toLowerCase());
      const matchStatus = statusFilter === 'all' || acc.status === statusFilter;
      return matchSearch && matchStatus;
    });
  }, [accounts, searchQuery, statusFilter]);

  // Filtered Quotations
  const filteredQuotations = useMemo(() => {
    return quotations.filter((q) => {
      const matchSearch =
        q.quotation_number.toLowerCase().includes(searchQuery.toLowerCase()) ||
        (q.corporate_account_name || '').toLowerCase().includes(searchQuery.toLowerCase());
      const matchStatus = statusFilter === 'all' || q.status === statusFilter;
      return matchSearch && matchStatus;
    });
  }, [quotations, searchQuery, statusFilter]);

  // Filtered Invoices
  const filteredInvoices = useMemo(() => {
    return invoices.filter((inv) => {
      const matchSearch =
        inv.invoice_number.toLowerCase().includes(searchQuery.toLowerCase()) ||
        (inv.corporate_account_name || '').toLowerCase().includes(searchQuery.toLowerCase());
      const matchStatus = statusFilter === 'all' || inv.payment_status === statusFilter;
      return matchSearch && matchStatus;
    });
  }, [invoices, searchQuery, statusFilter]);

  // Handlers: Create Corporate Account
  const handleCreateAccount = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newAccount.company_name || !newAccount.cr_number || !newAccount.vat_number || !newAccount.contact_person || !newAccount.phone) {
      setNotification({ type: 'error', message: 'يرجى استكمال الحقول الإلزامية لبيانات الشركة' });
      return;
    }

    setIsSubmitting(true);
    try {
      const created = await corporateB2bApi.createCorporateAccount({
        ...newAccount,
        created_by: currentUser?.full_name || 'مسؤول الحسابات',
      });
      setAccounts((prev) => [created, ...prev]);
      setIsCreateAccountOpen(false);
      setNotification({
        type: 'success',
        message: `تم اعتماد حساب الشركة (${created.company_name}) بنجاح وتسجيل السجل التجاري في قاعدة البيانات.`,
      });
      setNewAccount({
        company_name: '',
        cr_number: '',
        vat_number: '',
        contact_person: '',
        phone: '',
        email: '',
        city: 'دمشق',
        address: '',
        branch_id: activeBranchId && activeBranchId !== 'all' ? activeBranchId : 'b-dam-01',
        monthly_credit_limit: 5000000,
        payment_terms: 'Net-30',
        recurring_schedule: 'كل أحد 08:00 صباحاً',
        items_summary: '',
        notes: '',
      });
    } catch (err: any) {
      setNotification({ type: 'error', message: `فشل إنشاء حساب الشركة: ${err.message}` });
    } finally {
      setIsSubmitting(false);
    }
  };

  // Handlers: Create Quotation
  const handleCreateQuotation = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!quoteTargetAccountId) {
      setNotification({ type: 'error', message: 'يرجى اختيار الشركة المستهدفة لعرض السعر' });
      return;
    }
    if (quoteItems.length === 0) {
      setNotification({ type: 'error', message: 'يرجى إضافة صنف واحد على الأقل في عرض السعر' });
      return;
    }

    setIsSubmitting(true);
    try {
      const quote = await corporateB2bApi.createQuotation(
        {
          corporate_account_id: quoteTargetAccountId,
          branch_id: activeBranchId && activeBranchId !== 'all' ? activeBranchId : 'b-dam-01',
          discount_percent: quoteGlobalDiscount,
          notes: quoteNotes,
          created_by: currentUser?.full_name || 'مسؤول مبيعات الشركات',
        },
        quoteItems
      );
      setQuotations((prev) => [quote, ...prev]);
      setIsCreateQuotationOpen(false);
      setQuoteItems([]);
      setQuoteNotes('');
      setNotification({
        type: 'success',
        message: `تم إصدار عرض السعر رقم (${quote.quotation_number}) بنجاح وبانتظار الاعتماد.`,
      });
      loadData();
    } catch (err: any) {
      setNotification({ type: 'error', message: `فشل إنشاء عرض السعر: ${err.message}` });
    } finally {
      setIsSubmitting(false);
    }
  };

  // Handlers: Approve Quotation
  const handleApproveQuotation = async (quote: CorporateQuotation) => {
    setIsSubmitting(true);
    try {
      await corporateB2bApi.approveOrRejectQuotation(
        quote.id,
        'approve',
        currentUser?.full_name || 'المدير المالي المعتمد',
        'تمت مراجعة شروط التوريد واعتماد العرض رسمياً'
      );
      setNotification({
        type: 'success',
        message: `تم اعتماد عرض السعر (${quote.quotation_number}) رسمياً. يمكنك الآن تحويله إلى فاتورة مبيعات.`,
      });
      loadData();
    } catch (err: any) {
      setNotification({ type: 'error', message: `فشل اعتماد عرض السعر: ${err.message}` });
    } finally {
      setIsSubmitting(false);
    }
  };

  // Handlers: Convert Quotation to Invoice with Stock Deduction
  const handleConvertQuoteToInvoice = async (quote: CorporateQuotation) => {
    if (!confirm(`هل أنت متأكد من تحويل عرض السعر (${quote.quotation_number}) إلى فاتورة مبيعات رسمية وخصم المخزون؟`)) {
      return;
    }

    setIsSubmitting(true);
    try {
      const itemsPayload = (quote.items || []).map((it) => ({
        product_id: it.product_id,
        quantity: it.quantity,
        unit_price: it.unit_price,
        discount_percent: it.discount_percent,
      }));

      const res = await corporateB2bApi.createInvoiceWithStockDeduction({
        corporate_account_id: quote.corporate_account_id,
        branch_id: quote.branch_id,
        quotation_id: quote.id,
        items: itemsPayload,
        notes: `فاتورة محولة من عرض السعر ${quote.quotation_number}`,
        created_by: currentUser?.full_name || 'مسؤول مبيعات الشركات',
      });

      setNotification({
        type: 'success',
        message: `تم إنشاء الفاتورة رقم (${res.invoice_number}) بنجاح، وخصم المخزون، وتحديث رصيد العميل!`,
      });
      loadData();
    } catch (err: any) {
      setNotification({ type: 'error', message: `فشل تحويل عرض السعر لفاتورة: ${err.message}` });
    } finally {
      setIsSubmitting(false);
    }
  };

  // Handlers: Create Direct Invoice
  const handleCreateDirectInvoice = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!invoiceTargetAccountId) {
      setNotification({ type: 'error', message: 'يرجى اختيار حساب الشركة' });
      return;
    }
    if (invoiceItems.length === 0) {
      setNotification({ type: 'error', message: 'يرجى إضافة صنف واحد على الأقل للفاتورة' });
      return;
    }

    setIsSubmitting(true);
    try {
      const res = await corporateB2bApi.createInvoiceWithStockDeduction({
        corporate_account_id: invoiceTargetAccountId,
        branch_id: activeBranchId && activeBranchId !== 'all' ? activeBranchId : 'b-dam-01',
        items: invoiceItems,
        notes: invoiceNotes,
        created_by: currentUser?.full_name || 'مسؤول مبيعات الشركات',
      });

      setNotification({
        type: 'success',
        message: `تم إصدار الفاتورة الضريبية رقم (${res.invoice_number}) بقيمة ${Number(res.total_amount).toLocaleString()} ل.س وخصم المخزون فوراً!`,
      });
      setIsCreateInvoiceOpen(false);
      setInvoiceItems([]);
      setInvoiceNotes('');
      loadData();
    } catch (err: any) {
      setNotification({ type: 'error', message: `فشل إصدار الفاتورة: ${err.message}` });
    } finally {
      setIsSubmitting(false);
    }
  };

  // Handlers: Record Payment
  const handleRecordPayment = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedInvoice) return;
    if (paymentAmount <= 0) {
      setNotification({ type: 'error', message: 'مبلغ السداد يجب أن يكون أكبر من الصفر' });
      return;
    }
    if (paymentAmount > selectedInvoice.remaining_amount) {
      setNotification({ type: 'error', message: 'مبلغ السداد لا يمكن أن يتجاوز المبلغ المتبقي على الفاتورة' });
      return;
    }

    setIsSubmitting(true);
    try {
      const res = await corporateB2bApi.recordCorporatePayment({
        invoice_id: selectedInvoice.id,
        amount: paymentAmount,
        payment_method: paymentMethod,
        reference_number: paymentRefNumber || `REF-${Date.now().toString().slice(-6)}`,
        notes: paymentNotes,
        received_by: currentUser?.full_name || 'محاسب الشركات',
      });

      setNotification({
        type: 'success',
        message: `تم تسجيل سند القبض رقم (${res.payment_number}) بمبلغ ${paymentAmount.toLocaleString()} ل.س وتخفيض مديونية العميل بنجاح.`,
      });
      setIsRecordPaymentOpen(false);
      setSelectedInvoice(null);
      setPaymentAmount(0);
      setPaymentNotes('');
      setPaymentRefNumber('');
      loadData();
    } catch (err: any) {
      setNotification({ type: 'error', message: `فشل تسجيل السداد: ${err.message}` });
    } finally {
      setIsSubmitting(false);
    }
  };

  // Handlers: Process Return and Restore Stock
  const handleProcessReturn = async (ret: CorporateReturn) => {
    if (!confirm(`هل أنت متأكد من اعتماد الإرجاع رقم (${ret.return_number}) واستعادة المخزون إلى المستودع؟`)) {
      return;
    }

    setIsSubmitting(true);
    try {
      const res = await corporateB2bApi.processReturnWithStockRestoration(
        ret.id,
        currentUser?.full_name || 'مدير مراقبة المخزون'
      );

      setNotification({
        type: 'success',
        message: `تم اعتماد الإرجاع (${res.return_number})، استعادة ${res.restored_items_count} صنف إلى المخزون، وخصم ${Number(res.total_refund_amount).toLocaleString()} ل.س من المديونية.`,
      });
      loadData();
    } catch (err: any) {
      setNotification({ type: 'error', message: `فشل معالجة الإرجاع: ${err.message}` });
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="p-6 space-y-6 max-w-7xl mx-auto text-slate-800" dir="rtl">
      {/* Toast Notification */}
      {notification && (
        <div
          className={`p-4 rounded-xl flex items-center justify-between border shadow-lg transition-all animate-in fade-in duration-200 ${
            notification.type === 'success'
              ? 'bg-emerald-900/90 text-emerald-100 border-emerald-600'
              : 'bg-red-900/90 text-red-100 border-red-600'
          }`}
        >
          <div className="flex items-center gap-3">
            {notification.type === 'success' ? (
              <CheckCircle2 className="w-5 h-5 text-emerald-400" />
            ) : (
              <AlertTriangle className="w-5 h-5 text-red-400" />
            )}
            <p className="text-sm font-bold">{notification.message}</p>
          </div>
          <button
            onClick={() => setNotification(null)}
            className="text-white/60 hover:text-white text-xs font-bold px-2 py-1"
          >
            ✕
          </button>
        </div>
      )}

      {/* Header Banner */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 bg-gradient-to-l from-blue-950 via-slate-900 to-indigo-950 p-6 rounded-2xl text-white shadow-xl border border-blue-900/50">
        <div className="flex items-center gap-4">
          <div className="p-3.5 bg-blue-600/20 backdrop-blur-md rounded-2xl border border-blue-400/30">
            <Building className="w-8 h-8 text-blue-300" />
          </div>
          <div>
            <div className="flex items-center gap-3">
              <h1 className="text-2xl font-black tracking-tight">بوابة مبيعات الشركات وعقود التوريد B2B</h1>
              <span className="px-3 py-0.5 rounded-full text-xs font-bold bg-blue-500/20 text-blue-300 border border-blue-400/30">
                Enterprise & Wholesale Portal
              </span>
            </div>
            <p className="text-blue-200 text-xs mt-1">
              إدارة الحسابات المؤسسية، عروض الأسعار والموافقات، القيود الائتمانية، الفواتير الضريبية ZATCA، وربط المخزون اللحظي
            </p>
          </div>
        </div>

        <div className="flex items-center gap-3">
          <button
            onClick={() => loadData()}
            disabled={isLoading}
            className="px-3.5 py-2 bg-white/10 hover:bg-white/20 text-white rounded-xl text-xs font-bold border border-white/20 transition-colors flex items-center gap-2"
            title="تحديث البيانات من السيرفر"
          >
            <RefreshCw className={`w-4 h-4 text-blue-300 ${isLoading ? 'animate-spin' : ''}`} />
            تحديث حي
          </button>

          <div className="bg-blue-950/80 px-4 py-2 rounded-xl border border-blue-700/50 flex items-center gap-2.5">
            <ShieldCheck className="w-5 h-5 text-emerald-400" />
            <div className="text-xs">
              <p className="font-bold text-white">عزل الشركات والمخزون</p>
              <p className="text-blue-300">RBAC + Multi-Branch RLS</p>
            </div>
          </div>
        </div>
      </div>

      {/* KPI Stats Overview */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-xs flex items-center justify-between">
          <div>
            <p className="text-xs font-semibold text-slate-500">الشركات والجهات المعتمدة</p>
            <p className="text-2xl font-black text-slate-900 mt-1">{kpiMetrics.totalAccounts} جهة</p>
            <p className="text-[11px] text-emerald-600 font-medium mt-1">
              {kpiMetrics.overdueAccounts > 0 ? `⚠️ ${kpiMetrics.overdueAccounts} حسابات تجاوزت الحد` : '✓ جميع الحسابات ضمن الحد'}
            </p>
          </div>
          <div className="p-3 bg-blue-50 rounded-xl">
            <Building className="w-6 h-6 text-blue-600" />
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-xs flex items-center justify-between">
          <div>
            <p className="text-xs font-semibold text-slate-500">إجمالي المبيعات المفوترة</p>
            <p className="text-2xl font-black text-emerald-600 mt-1">
              {kpiMetrics.totalInvoiced.toLocaleString()} ل.س
            </p>
            <p className="text-[11px] text-slate-500 font-medium mt-1">
              محصل: {kpiMetrics.totalCollected.toLocaleString()} ل.س
            </p>
          </div>
          <div className="p-3 bg-emerald-50 rounded-xl">
            <DollarSign className="w-6 h-6 text-emerald-600" />
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-xs flex items-center justify-between">
          <div>
            <p className="text-xs font-semibold text-slate-500">الرصيد الائتماني المستحق (الذمم)</p>
            <p className="text-2xl font-black text-amber-600 mt-1">
              {kpiMetrics.totalOutstanding.toLocaleString()} ل.س
            </p>
            <p className="text-[11px] text-amber-700 font-medium mt-1">
              ذمم آجلة قيد التحصيل (Net-15/30/60)
            </p>
          </div>
          <div className="p-3 bg-amber-50 rounded-xl">
            <CreditCard className="w-6 h-6 text-amber-600" />
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-xs flex items-center justify-between">
          <div>
            <p className="text-xs font-semibold text-slate-500">عروض الأسعار والطلبيات</p>
            <p className="text-2xl font-black text-indigo-600 mt-1">
              {quotations.length} عرض
            </p>
            <p className="text-[11px] text-indigo-600 font-medium mt-1">
              {kpiMetrics.pendingQuotes} عروض بانتظار الاعتماد
            </p>
          </div>
          <div className="p-3 bg-indigo-50 rounded-xl">
            <FileText className="w-6 h-6 text-indigo-600" />
          </div>
        </div>
      </div>

      {/* Main Module Tabs */}
      <div className="flex border-b border-slate-200 gap-2 overflow-x-auto">
        <button
          onClick={() => { setActiveSubTab('accounts'); setStatusFilter('all'); }}
          className={`px-4 py-3 text-xs font-bold flex items-center gap-2 border-b-2 transition-colors ${
            activeSubTab === 'accounts'
              ? 'border-blue-600 text-blue-600'
              : 'border-transparent text-slate-500 hover:text-slate-800'
          }`}
        >
          <Building className="w-4 h-4" />
          حسابات الشركات والائتمان ({accounts.length})
        </button>

        <button
          onClick={() => { setActiveSubTab('quotations'); setStatusFilter('all'); }}
          className={`px-4 py-3 text-xs font-bold flex items-center gap-2 border-b-2 transition-colors ${
            activeSubTab === 'quotations'
              ? 'border-blue-600 text-blue-600'
              : 'border-transparent text-slate-500 hover:text-slate-800'
          }`}
        >
          <FileText className="w-4 h-4" />
          طلبات وعروض الأسعار ({quotations.length})
        </button>

        <button
          onClick={() => { setActiveSubTab('invoices'); setStatusFilter('all'); }}
          className={`px-4 py-3 text-xs font-bold flex items-center gap-2 border-b-2 transition-colors ${
            activeSubTab === 'invoices'
              ? 'border-blue-600 text-blue-600'
              : 'border-transparent text-slate-500 hover:text-slate-800'
          }`}
        >
          <Receipt className="w-4 h-4" />
          الفواتير الضريبية والمستحقات ({invoices.length})
        </button>

        <button
          onClick={() => { setActiveSubTab('payments'); setStatusFilter('all'); }}
          className={`px-4 py-3 text-xs font-bold flex items-center gap-2 border-b-2 transition-colors ${
            activeSubTab === 'payments'
              ? 'border-blue-600 text-blue-600'
              : 'border-transparent text-slate-500 hover:text-slate-800'
          }`}
        >
          <DollarSign className="w-4 h-4" />
          سجل السداد والتحصيلات ({payments.length})
        </button>

        <button
          onClick={() => { setActiveSubTab('returns'); setStatusFilter('all'); }}
          className={`px-4 py-3 text-xs font-bold flex items-center gap-2 border-b-2 transition-colors ${
            activeSubTab === 'returns'
              ? 'border-blue-600 text-blue-600'
              : 'border-transparent text-slate-500 hover:text-slate-800'
          }`}
        >
          <RotateCcw className="w-4 h-4" />
          المرتجعات والإشعارات الدائنة ({returns.length})
        </button>
      </div>

      {/* ========================================================================= */}
      {/* TAB 1: CORPORATE ACCOUNTS & CREDIT LIMITS */}
      {/* ========================================================================= */}
      {activeSubTab === 'accounts' && (
        <div className="bg-white rounded-2xl border border-slate-200 shadow-xs overflow-hidden">
          <div className="p-4 border-b border-slate-100 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
            <div className="flex items-center gap-3 flex-1 max-w-md">
              <div className="relative w-full">
                <Search className="w-4 h-4 text-slate-400 absolute right-3 top-3" />
                <input
                  type="text"
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  placeholder="بحث باسم الشركة، السجل التجاري، أو المسؤول..."
                  className="w-full pr-9 pl-4 py-2 border border-slate-200 rounded-xl text-xs focus:outline-hidden focus:ring-2 focus:ring-blue-500"
                />
              </div>

              <select
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value)}
                className="px-3 py-2 border border-slate-200 rounded-xl text-xs focus:outline-hidden focus:ring-2 focus:ring-blue-500"
              >
                <option value="all">كافة الحالات</option>
                <option value="active">نشط وتوريد ساري</option>
                <option value="overdue">تجاوز الحد الائتماني</option>
                <option value="pending_kyc">قيد المراجعة KYC</option>
                <option value="suspended">موقوف مؤقتاً</option>
              </select>
            </div>

            <button
              onClick={() => setIsCreateAccountOpen(true)}
              className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-xl text-xs font-bold transition-colors flex items-center gap-1.5 self-end sm:self-auto shadow-xs"
            >
              <Plus className="w-4 h-4" />
              اعتماد حساب شركة جديد
            </button>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-right text-xs">
              <thead className="bg-slate-50 text-slate-600 font-bold border-b border-slate-200">
                <tr>
                  <th className="p-3.5">الشركة والسجل التجاري</th>
                  <th className="p-3.5">المسؤول المفوض والتواصل</th>
                  <th className="p-3.5">الفرع التابع</th>
                  <th className="p-3.5">الحد الائتماني والرصيد المستحق</th>
                  <th className="p-3.5">شروط السداد</th>
                  <th className="p-3.5">الحالة</th>
                  <th className="p-3.5 text-center">الإجراءات</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {filteredAccounts.length === 0 ? (
                  <tr>
                    <td colSpan={7} className="p-8 text-center text-slate-400">
                      لا توجد حسابات شركات مطابقة لمعايير البحث الحالية
                    </td>
                  </tr>
                ) : (
                  filteredAccounts.map((account) => {
                    const creditUsage = account.monthly_credit_limit > 0
                      ? Math.min(100, Math.round((account.current_balance / account.monthly_credit_limit) * 100))
                      : 0;
                    const isOverLimit = account.current_balance > account.monthly_credit_limit;

                    return (
                      <tr key={account.id} className="hover:bg-slate-50/80 transition-colors">
                        <td className="p-3.5">
                          <div className="font-bold text-slate-900">{account.company_name}</div>
                          <div className="text-[11px] text-slate-500 font-mono">
                            س.ت: {account.cr_number} • ضريبة: {account.vat_number}
                          </div>
                        </td>
                        <td className="p-3.5">
                          <div className="font-medium text-slate-800">{account.contact_person}</div>
                          <div className="text-[11px] text-slate-400 font-mono">{account.phone}</div>
                        </td>
                        <td className="p-3.5">
                          <span className="px-2 py-0.5 rounded-md bg-slate-100 text-slate-700 font-medium text-[11px]">
                            {account.city} ({account.branch_id})
                          </span>
                        </td>
                        <td className="p-3.5">
                          <div className="flex items-center justify-between text-[11px] mb-1 font-mono">
                            <span className={isOverLimit ? 'text-red-700 font-bold' : 'text-slate-900 font-bold'}>
                              {account.current_balance.toLocaleString()} ل.س
                            </span>
                            <span className="text-slate-400">
                              / {account.monthly_credit_limit.toLocaleString()} ل.س
                            </span>
                          </div>
                          <div className="w-36 h-1.5 bg-slate-100 rounded-full overflow-hidden">
                            <div
                              className={`h-full rounded-full transition-all ${
                                isOverLimit ? 'bg-red-500' : creditUsage > 75 ? 'bg-amber-500' : 'bg-blue-600'
                              }`}
                              style={{ width: `${creditUsage}%` }}
                            />
                          </div>
                        </td>
                        <td className="p-3.5">
                          <span className="inline-block px-2 py-0.5 bg-blue-50 text-blue-700 rounded-md text-[11px] font-bold">
                            {account.payment_terms}
                          </span>
                        </td>
                        <td className="p-3.5">
                          {account.status === 'active' && !isOverLimit && (
                            <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-emerald-50 text-emerald-700 border border-emerald-200 font-bold text-[11px]">
                              <CheckCircle2 className="w-3 h-3" /> نشط وتوريد ساري
                            </span>
                          )}
                          {(account.status === 'overdue' || isOverLimit) && (
                            <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-red-50 text-red-700 border border-red-200 font-bold text-[11px]">
                              <AlertTriangle className="w-3 h-3" /> تجاوز الائتمان
                            </span>
                          )}
                          {account.status === 'pending_kyc' && (
                            <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-amber-50 text-amber-700 border border-amber-200 font-bold text-[11px]">
                              <Clock className="w-3 h-3" /> قيد التحقق KYC
                            </span>
                          )}
                          {account.status === 'suspended' && (
                            <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-slate-100 text-slate-700 border border-slate-300 font-bold text-[11px]">
                              موقوف
                            </span>
                          )}
                        </td>
                        <td className="p-3.5 text-center">
                          <div className="flex items-center justify-center gap-1.5">
                            <button
                              onClick={() => setSelectedAccount(account)}
                              className="p-1.5 text-blue-700 hover:bg-blue-50 rounded-lg transition-colors"
                              title="معاينة ملف الشركة والائتمان"
                            >
                              <Eye className="w-4 h-4" />
                            </button>

                            <button
                              onClick={() => {
                                setQuoteTargetAccountId(account.id);
                                setIsCreateQuotationOpen(true);
                              }}
                              className="p-1.5 text-indigo-700 hover:bg-indigo-50 rounded-lg transition-colors"
                              title="إصدار عرض سعر للشركة"
                            >
                              <FileText className="w-4 h-4" />
                            </button>

                            <button
                              onClick={() => {
                                setInvoiceTargetAccountId(account.id);
                                setIsCreateInvoiceOpen(true);
                              }}
                              className="p-1.5 text-emerald-700 hover:bg-emerald-50 rounded-lg transition-colors"
                              title="إصدار فاتورة مبيعات مباشرة"
                            >
                              <Receipt className="w-4 h-4" />
                            </button>
                          </div>
                        </td>
                      </tr>
                    );
                  })
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* ========================================================================= */}
      {/* TAB 2: CORPORATE QUOTATIONS & RFQs */}
      {/* ========================================================================= */}
      {activeSubTab === 'quotations' && (
        <div className="bg-white rounded-2xl border border-slate-200 shadow-xs overflow-hidden">
          <div className="p-4 border-b border-slate-100 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
            <div className="flex items-center gap-3 flex-1 max-w-md">
              <div className="relative w-full">
                <Search className="w-4 h-4 text-slate-400 absolute right-3 top-3" />
                <input
                  type="text"
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  placeholder="بحث برقم عرض السعر أو اسم الشركة..."
                  className="w-full pr-9 pl-4 py-2 border border-slate-200 rounded-xl text-xs focus:outline-hidden focus:ring-2 focus:ring-blue-500"
                />
              </div>

              <select
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value)}
                className="px-3 py-2 border border-slate-200 rounded-xl text-xs focus:outline-hidden focus:ring-2 focus:ring-blue-500"
              >
                <option value="all">كافة الحالات</option>
                <option value="draft">مسودة</option>
                <option value="pending_approval">قيد الاعتماد</option>
                <option value="approved">معتمد رسمياً</option>
                <option value="converted">تم التحويل لفاتورة</option>
                <option value="rejected">مرفوض</option>
              </select>
            </div>

            <button
              onClick={() => setIsCreateQuotationOpen(true)}
              className="px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-xl text-xs font-bold transition-colors flex items-center gap-1.5 self-end sm:self-auto shadow-xs"
            >
              <Plus className="w-4 h-4" />
              إنشاء عرض سعر جديد
            </button>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-right text-xs">
              <thead className="bg-slate-50 text-slate-600 font-bold border-b border-slate-200">
                <tr>
                  <th className="p-3.5">رقم العرض والتاريخ</th>
                  <th className="p-3.5">الشركة المستفيدة</th>
                  <th className="p-3.5">عدد الأصناف</th>
                  <th className="p-3.5">المجموع قبل الخصم</th>
                  <th className="p-3.5">الخصم التجاري</th>
                  <th className="p-3.5">الإجمالي الصافي + الضريبة</th>
                  <th className="p-3.5">الحالة</th>
                  <th className="p-3.5 text-center">الإجراءات والاعتماد</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {filteredQuotations.length === 0 ? (
                  <tr>
                    <td colSpan={8} className="p-8 text-center text-slate-400">
                      لا توجد عروض أسعار مسجلة في النظام
                    </td>
                  </tr>
                ) : (
                  filteredQuotations.map((quote) => (
                    <tr key={quote.id} className="hover:bg-slate-50/80 transition-colors">
                      <td className="p-3.5">
                        <div className="font-bold font-mono text-indigo-700">{quote.quotation_number}</div>
                        <div className="text-[11px] text-slate-400">
                          صالح حتى: {quote.valid_until}
                        </div>
                      </td>
                      <td className="p-3.5 font-bold text-slate-900">
                        {quote.corporate_account_name}
                      </td>
                      <td className="p-3.5 font-medium text-slate-700">
                        {(quote.items || []).length} أصناف
                      </td>
                      <td className="p-3.5 font-mono text-slate-600">
                        {quote.subtotal.toLocaleString()} ل.س
                      </td>
                      <td className="p-3.5 font-mono text-amber-600 font-bold">
                        {quote.discount_amount.toLocaleString()} ل.س
                      </td>
                      <td className="p-3.5 font-bold font-mono text-emerald-700 text-sm">
                        {quote.total_amount.toLocaleString()} ل.س
                      </td>
                      <td className="p-3.5">
                        {quote.status === 'draft' && (
                          <span className="px-2.5 py-1 rounded-full bg-slate-100 text-slate-700 border border-slate-200 font-bold text-[11px]">
                            مسودة
                          </span>
                        )}
                        {quote.status === 'pending_approval' && (
                          <span className="px-2.5 py-1 rounded-full bg-amber-50 text-amber-700 border border-amber-200 font-bold text-[11px]">
                            قيد الاعتماد
                          </span>
                        )}
                        {quote.status === 'approved' && (
                          <span className="px-2.5 py-1 rounded-full bg-emerald-50 text-emerald-700 border border-emerald-200 font-bold text-[11px]">
                            معتمد رسمياً
                          </span>
                        )}
                        {quote.status === 'converted' && (
                          <span className="px-2.5 py-1 rounded-full bg-blue-50 text-blue-700 border border-blue-200 font-bold text-[11px]">
                            محول إلى فاتورة
                          </span>
                        )}
                        {quote.status === 'rejected' && (
                          <span className="px-2.5 py-1 rounded-full bg-red-50 text-red-700 border border-red-200 font-bold text-[11px]">
                            مرفوض
                          </span>
                        )}
                      </td>
                      <td className="p-3.5 text-center">
                        <div className="flex items-center justify-center gap-1.5">
                          <button
                            onClick={() => setSelectedQuotation(quote)}
                            className="p-1.5 text-slate-600 hover:bg-slate-100 rounded-lg transition-colors"
                            title="معاينة بنود العرض"
                          >
                            <Eye className="w-4 h-4" />
                          </button>

                          {(quote.status === 'draft' || quote.status === 'pending_approval') && (
                            <button
                              onClick={() => handleApproveQuotation(quote)}
                              disabled={isSubmitting}
                              className="px-2.5 py-1 bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg text-[11px] font-bold transition-colors flex items-center gap-1"
                              title="اعتماد عرض السعر"
                            >
                              <FileCheck className="w-3.5 h-3.5" />
                              اعتماد
                            </button>
                          )}

                          {quote.status === 'approved' && (
                            <button
                              onClick={() => handleConvertQuoteToInvoice(quote)}
                              disabled={isSubmitting}
                              className="px-2.5 py-1 bg-blue-600 hover:bg-blue-700 text-white rounded-lg text-[11px] font-bold transition-colors flex items-center gap-1"
                              title="تحويل إلى فاتورة مبيعات وخصم المخزون"
                            >
                              <Truck className="w-3.5 h-3.5" />
                              تحويل لفاتورة
                            </button>
                          )}
                        </div>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* ========================================================================= */}
      {/* TAB 3: CORPORATE TAX INVOICES & RECEIVABLES */}
      {/* ========================================================================= */}
      {activeSubTab === 'invoices' && (
        <div className="bg-white rounded-2xl border border-slate-200 shadow-xs overflow-hidden">
          <div className="p-4 border-b border-slate-100 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
            <div className="flex items-center gap-3 flex-1 max-w-md">
              <div className="relative w-full">
                <Search className="w-4 h-4 text-slate-400 absolute right-3 top-3" />
                <input
                  type="text"
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  placeholder="بحث برقم الفاتورة أو اسم الشركة..."
                  className="w-full pr-9 pl-4 py-2 border border-slate-200 rounded-xl text-xs focus:outline-hidden focus:ring-2 focus:ring-blue-500"
                />
              </div>

              <select
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value)}
                className="px-3 py-2 border border-slate-200 rounded-xl text-xs focus:outline-hidden focus:ring-2 focus:ring-blue-500"
              >
                <option value="all">كافة حالات السداد</option>
                <option value="unpaid">غير مسددة</option>
                <option value="partially_paid">مسددة جزئياً</option>
                <option value="paid">مسددة بالكامل</option>
                <option value="overdue">متأخرة السداد</option>
              </select>
            </div>

            <button
              onClick={() => setIsCreateInvoiceOpen(true)}
              className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-xl text-xs font-bold transition-colors flex items-center gap-1.5 self-end sm:self-auto shadow-xs"
            >
              <Plus className="w-4 h-4" />
              إصدار فاتورة شركات جديدة
            </button>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-right text-xs">
              <thead className="bg-slate-50 text-slate-600 font-bold border-b border-slate-200">
                <tr>
                  <th className="p-3.5">رقم الفاتورة ZATCA</th>
                  <th className="p-3.5">الشركة المفوترة</th>
                  <th className="p-3.5">إجمالي الفاتورة</th>
                  <th className="p-3.5">المسدد</th>
                  <th className="p-3.5">المتبقي</th>
                  <th className="p-3.5">تاريخ الاستحقاق</th>
                  <th className="p-3.5">حالة السداد</th>
                  <th className="p-3.5 text-center">الإجراءات</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {filteredInvoices.length === 0 ? (
                  <tr>
                    <td colSpan={8} className="p-8 text-center text-slate-400">
                      لا توجد فواتير مبيعات شركات مسجلة في النظام
                    </td>
                  </tr>
                ) : (
                  filteredInvoices.map((inv) => (
                    <tr key={inv.id} className="hover:bg-slate-50/80 transition-colors">
                      <td className="p-3.5">
                        <div className="font-bold font-mono text-blue-700">{inv.invoice_number}</div>
                        <div className="text-[10px] text-slate-400 font-mono">
                          {new Date(inv.created_at).toLocaleDateString('ar-SA')}
                        </div>
                      </td>
                      <td className="p-3.5 font-bold text-slate-900">
                        {inv.corporate_account_name}
                      </td>
                      <td className="p-3.5 font-bold font-mono text-slate-900">
                        {inv.total_amount.toLocaleString()} ل.س
                      </td>
                      <td className="p-3.5 font-mono text-emerald-700 font-bold">
                        {inv.paid_amount.toLocaleString()} ل.س
                      </td>
                      <td className="p-3.5 font-mono font-bold text-amber-700">
                        {inv.remaining_amount.toLocaleString()} ل.س
                      </td>
                      <td className="p-3.5 font-mono text-slate-600">
                        {inv.due_date}
                      </td>
                      <td className="p-3.5">
                        {inv.payment_status === 'paid' && (
                          <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-emerald-50 text-emerald-700 border border-emerald-200 font-bold text-[11px]">
                            <CheckCircle2 className="w-3 h-3" /> مسددة بالكامل
                          </span>
                        )}
                        {inv.payment_status === 'partially_paid' && (
                          <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-blue-50 text-blue-700 border border-blue-200 font-bold text-[11px]">
                            <Clock className="w-3 h-3" /> سداد جزئي
                          </span>
                        )}
                        {inv.payment_status === 'unpaid' && (
                          <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-amber-50 text-amber-700 border border-amber-200 font-bold text-[11px]">
                            غير مسددة
                          </span>
                        )}
                        {inv.payment_status === 'overdue' && (
                          <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-red-50 text-red-700 border border-red-200 font-bold text-[11px]">
                            متأخرة السداد
                          </span>
                        )}
                      </td>
                      <td className="p-3.5 text-center">
                        <div className="flex items-center justify-center gap-1.5">
                          <button
                            onClick={() => {
                              setSelectedInvoice(inv);
                              setIsPrintInvoiceOpen(true);
                            }}
                            className="p-1.5 text-slate-600 hover:bg-slate-100 rounded-lg transition-colors"
                            title="معاينة وطباعة الفاتورة الضريبية ZATCA"
                          >
                            <Printer className="w-4 h-4" />
                          </button>

                          {inv.remaining_amount > 0 && (
                            <button
                              onClick={() => {
                                setSelectedInvoice(inv);
                                setPaymentAmount(inv.remaining_amount);
                                setIsRecordPaymentOpen(true);
                              }}
                              className="px-2.5 py-1 bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg text-[11px] font-bold transition-colors flex items-center gap-1"
                              title="تسجيل سداد دفعة"
                            >
                              <DollarSign className="w-3.5 h-3.5" />
                              سداد
                            </button>
                          )}

                          <button
                            onClick={() => {
                              setSelectedInvoice(inv);
                              setReturnItems((inv.items || []).map((it) => ({
                                product_id: it.product_id,
                                quantity: it.quantity,
                                unit_price: it.final_unit_price,
                                reason: 'إرجاع بضاعة تالفة أو غير مطابقة',
                              })));
                              setIsCreateReturnOpen(true);
                            }}
                            className="p-1.5 text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                            title="طلب إرجاع بضاعة وإشعار دائن"
                          >
                            <RotateCcw className="w-4 h-4" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* ========================================================================= */}
      {/* TAB 4: PAYMENTS & SETTLEMENTS */}
      {/* ========================================================================= */}
      {activeSubTab === 'payments' && (
        <div className="bg-white rounded-2xl border border-slate-200 shadow-xs overflow-hidden">
          <div className="p-4 border-b border-slate-100 flex items-center justify-between">
            <h3 className="font-bold text-sm text-slate-900">سجل التحصيلات وسندات القبض المعتمدة</h3>
            <span className="text-xs text-slate-500 font-mono">
              إجمالي التحصيلات: {kpiMetrics.totalCollected.toLocaleString()} ل.س
            </span>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-right text-xs">
              <thead className="bg-slate-50 text-slate-600 font-bold border-b border-slate-200">
                <tr>
                  <th className="p-3.5">رقم السند</th>
                  <th className="p-3.5">الشركة المورد لها</th>
                  <th className="p-3.5">الفاتورة المرتبطة</th>
                  <th className="p-3.5">المبلغ المحصل</th>
                  <th className="p-3.5">طريقة التحصيل</th>
                  <th className="p-3.5">رقم الحوالة / المرجع</th>
                  <th className="p-3.5">تاريخ السداد</th>
                  <th className="p-3.5">المستلم</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {payments.length === 0 ? (
                  <tr>
                    <td colSpan={8} className="p-8 text-center text-slate-400">
                      لا توجد سندات قبض مسجلة حتى الآن
                    </td>
                  </tr>
                ) : (
                  payments.map((p) => (
                    <tr key={p.id} className="hover:bg-slate-50/80 transition-colors">
                      <td className="p-3.5 font-bold font-mono text-emerald-700">{p.payment_number}</td>
                      <td className="p-3.5 font-bold text-slate-900">{p.corporate_account_name}</td>
                      <td className="p-3.5 font-mono text-blue-700">{p.invoice_number}</td>
                      <td className="p-3.5 font-bold font-mono text-emerald-700 text-sm">
                        {p.amount.toLocaleString()} ل.س
                      </td>
                      <td className="p-3.5">
                        <span className="px-2 py-0.5 rounded-md bg-slate-100 text-slate-700 font-bold text-[11px]">
                          {p.payment_method === 'bank_transfer'
                            ? 'تحويل بنكي'
                            : p.payment_method === 'check'
                            ? 'شيك مصرفي'
                            : p.payment_method === 'cash'
                            ? 'نقدي'
                            : 'بطاقة ائتمانية'}
                        </span>
                      </td>
                      <td className="p-3.5 font-mono text-slate-600">{p.reference_number}</td>
                      <td className="p-3.5 font-mono text-slate-500">{p.payment_date}</td>
                      <td className="p-3.5 text-slate-700">{p.received_by || 'محاسب الشركات'}</td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* ========================================================================= */}
      {/* TAB 5: RETURNS & CREDIT NOTES */}
      {/* ========================================================================= */}
      {activeSubTab === 'returns' && (
        <div className="bg-white rounded-2xl border border-slate-200 shadow-xs overflow-hidden">
          <div className="p-4 border-b border-slate-100 flex items-center justify-between">
            <h3 className="font-bold text-sm text-slate-900">سجل الإشعارات الدائنة والمرتجعات واستعادة المخزون</h3>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-right text-xs">
              <thead className="bg-slate-50 text-slate-600 font-bold border-b border-slate-200">
                <tr>
                  <th className="p-3.5">رقم الإشعار الدائن</th>
                  <th className="p-3.5">الشركة المورد لها</th>
                  <th className="p-3.5">الفاتورة الأصلية</th>
                  <th className="p-3.5">مبلغ التعويض / الإرجاع</th>
                  <th className="p-3.5">سبب الإرجاع</th>
                  <th className="p-3.5">الحالة</th>
                  <th className="p-3.5 text-center">الإجراءات</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {returns.length === 0 ? (
                  <tr>
                    <td colSpan={7} className="p-8 text-center text-slate-400">
                      لا توجد إشعارات دائنة أو طلبات إرجاع مسجلة
                    </td>
                  </tr>
                ) : (
                  returns.map((ret) => (
                    <tr key={ret.id} className="hover:bg-slate-50/80 transition-colors">
                      <td className="p-3.5 font-bold font-mono text-red-700">{ret.return_number}</td>
                      <td className="p-3.5 font-bold text-slate-900">{ret.corporate_account_name}</td>
                      <td className="p-3.5 font-mono text-blue-700">{ret.invoice_number}</td>
                      <td className="p-3.5 font-bold font-mono text-red-600">
                        {ret.total_refund_amount.toLocaleString()} ل.س
                      </td>
                      <td className="p-3.5 text-slate-600 max-w-xs truncate">{ret.reason}</td>
                      <td className="p-3.5">
                        {ret.status === 'completed' && (
                          <span className="px-2.5 py-1 rounded-full bg-emerald-50 text-emerald-700 border border-emerald-200 font-bold text-[11px]">
                            ✓ تمت استعادة المخزون
                          </span>
                        )}
                        {ret.status === 'pending_approval' && (
                          <span className="px-2.5 py-1 rounded-full bg-amber-50 text-amber-700 border border-amber-200 font-bold text-[11px]">
                            قيد الاعتماد
                          </span>
                        )}
                      </td>
                      <td className="p-3.5 text-center">
                        {ret.status === 'pending_approval' && (
                          <button
                            onClick={() => handleProcessReturn(ret)}
                            disabled={isSubmitting}
                            className="px-3 py-1 bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg text-[11px] font-bold transition-colors flex items-center gap-1 mx-auto"
                          >
                            <RotateCcw className="w-3.5 h-3.5" />
                            اعتماد واستعادة للمستودع
                          </button>
                        )}
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* ========================================================================= */}
      {/* MODAL 1: CREATE CORPORATE ACCOUNT */}
      {/* ========================================================================= */}
      {isCreateAccountOpen && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-2xl max-w-2xl w-full p-6 space-y-4 shadow-2xl border border-slate-200 max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between border-b pb-3 border-slate-100">
              <div className="flex items-center gap-2">
                <Building className="w-5 h-5 text-blue-600" />
                <h3 className="font-bold text-base text-slate-900">اعتماد حساب شركة ومبيعات جملة جديد</h3>
              </div>
              <button
                onClick={() => setIsCreateAccountOpen(false)}
                className="text-slate-400 hover:text-slate-600 p-1"
              >
                ✕
              </button>
            </div>

            <form onSubmit={handleCreateAccount} className="space-y-4 text-xs">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="block text-slate-700 font-bold mb-1">اسم المنشأة / الشركة *</label>
                  <input
                    type="text"
                    required
                    value={newAccount.company_name}
                    onChange={(e) => setNewAccount({ ...newAccount, company_name: e.target.value })}
                    placeholder="مثال: شركة الاتصالات السورية"
                    className="w-full p-2.5 border border-slate-200 rounded-xl"
                  />
                </div>

                <div>
                  <label className="block text-slate-700 font-bold mb-1">رقم السجل التجاري (CR) *</label>
                  <input
                    type="text"
                    required
                    value={newAccount.cr_number}
                    onChange={(e) => setNewAccount({ ...newAccount, cr_number: e.target.value })}
                    placeholder="مثال: 1010150261"
                    className="w-full p-2.5 border border-slate-200 rounded-xl font-mono"
                  />
                </div>

                <div>
                  <label className="block text-slate-700 font-bold mb-1">الرقم الضريبي (VAT) *</label>
                  <input
                    type="text"
                    required
                    value={newAccount.vat_number}
                    onChange={(e) => setNewAccount({ ...newAccount, vat_number: e.target.value })}
                    placeholder="300000000000003"
                    className="w-full p-2.5 border border-slate-200 rounded-xl font-mono"
                  />
                </div>

                <div>
                  <label className="block text-slate-700 font-bold mb-1">المسؤول المفوض / المشتريات *</label>
                  <input
                    type="text"
                    required
                    value={newAccount.contact_person}
                    onChange={(e) => setNewAccount({ ...newAccount, contact_person: e.target.value })}
                    placeholder="م. فهد السديري"
                    className="w-full p-2.5 border border-slate-200 rounded-xl"
                  />
                </div>

                <div>
                  <label className="block text-slate-700 font-bold mb-1">رقم الهاتف / الجوال *</label>
                  <input
                    type="text"
                    required
                    value={newAccount.phone}
                    onChange={(e) => setNewAccount({ ...newAccount, phone: e.target.value })}
                    placeholder="+963 93 112 3456"
                    className="w-full p-2.5 border border-slate-200 rounded-xl font-mono"
                  />
                </div>

                <div>
                  <label className="block text-slate-700 font-bold mb-1">البريد الإلكتروني الرسمي</label>
                  <input
                    type="email"
                    value={newAccount.email}
                    onChange={(e) => setNewAccount({ ...newAccount, email: e.target.value })}
                    placeholder="procurement@company.com"
                    className="w-full p-2.5 border border-slate-200 rounded-xl"
                  />
                </div>

                <div>
                  <label className="block text-slate-700 font-bold mb-1">الحد الائتماني الشهري (ل.س) *</label>
                  <input
                    type="number"
                    required
                    min={0}
                    value={newAccount.monthly_credit_limit}
                    onChange={(e) => setNewAccount({ ...newAccount, monthly_credit_limit: Number(e.target.value) })}
                    className="w-full p-2.5 border border-slate-200 rounded-xl font-mono"
                  />
                </div>

                <div>
                  <label className="block text-slate-700 font-bold mb-1">شروط السداد المعتمدة *</label>
                  <select
                    value={newAccount.payment_terms}
                    onChange={(e) => setNewAccount({ ...newAccount, payment_terms: e.target.value as PaymentTerms })}
                    className="w-full p-2.5 border border-slate-200 rounded-xl font-bold text-slate-800"
                  >
                    <option value="Net-30">آجل 30 يوم (Net-30)</option>
                    <option value="Net-15">آجل 15 يوم (Net-15)</option>
                    <option value="Net-60">آجل 60 يوم (Net-60)</option>
                    <option value="Cash">سداد نقدي فوري (Cash)</option>
                  </select>
                </div>
              </div>

              <div>
                <label className="block text-slate-700 font-bold mb-1">عنوان المقر الرئيسي والتسليم</label>
                <input
                  type="text"
                  value={newAccount.address}
                  onChange={(e) => setNewAccount({ ...newAccount, address: e.target.value })}
                  placeholder="المدينة، الحي، الشارع، المبنى"
                  className="w-full p-2.5 border border-slate-200 rounded-xl"
                />
              </div>

              <div>
                <label className="block text-slate-700 font-bold mb-1">جدولة التوريد الدورية الموصى بها</label>
                <input
                  type="text"
                  value={newAccount.recurring_schedule}
                  onChange={(e) => setNewAccount({ ...newAccount, recurring_schedule: e.target.value })}
                  placeholder="مثال: كل أحد وأربعاء صباحاً"
                  className="w-full p-2.5 border border-slate-200 rounded-xl"
                />
              </div>

              <div className="flex items-center justify-end gap-2 pt-3 border-t border-slate-100">
                <button
                  type="button"
                  onClick={() => setIsCreateAccountOpen(false)}
                  className="px-4 py-2 border border-slate-200 rounded-xl text-slate-600 hover:bg-slate-50 font-bold"
                >
                  إلغاء
                </button>
                <button
                  type="submit"
                  disabled={isSubmitting}
                  className="px-5 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-xl font-bold shadow-xs flex items-center gap-2"
                >
                  {isSubmitting ? 'جاري الاعتماد...' : 'اعتماد وحفظ الحساب'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ========================================================================= */}
      {/* MODAL 2: ACCOUNT DETAILS & FINANCIAL PROFILE */}
      {/* ========================================================================= */}
      {selectedAccount && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-2xl max-w-xl w-full p-6 space-y-4 shadow-2xl border border-slate-200">
            <div className="flex items-center justify-between border-b pb-3 border-slate-100">
              <div className="flex items-center gap-2">
                <Building className="w-6 h-6 text-blue-700" />
                <h3 className="font-bold text-base text-slate-900">
                  ملف حساب الشركة ({selectedAccount.company_name})
                </h3>
              </div>
              <button
                onClick={() => setSelectedAccount(null)}
                className="text-slate-400 hover:text-slate-600 p-1"
              >
                ✕
              </button>
            </div>

            <div className="space-y-3 text-xs bg-slate-50 p-4 rounded-xl border border-slate-200">
              <div className="flex justify-between">
                <span className="text-slate-500">السجل التجاري CR:</span>
                <span className="font-mono font-bold text-slate-900">{selectedAccount.cr_number}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-500">الرقم الضريبي VAT:</span>
                <span className="font-mono font-bold text-slate-900">{selectedAccount.vat_number}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-500">الحد الائتماني المعتمد:</span>
                <span className="font-mono font-bold text-blue-700">
                  {selectedAccount.monthly_credit_limit.toLocaleString()} ل.س
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-500">الرصيد المستحق الحالي (الذمم):</span>
                <span className="font-mono font-bold text-amber-700">
                  {selectedAccount.current_balance.toLocaleString()} ل.س
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-500">شروط السداد:</span>
                <span className="font-bold text-slate-800">{selectedAccount.payment_terms}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-500">جدولة التوريد الآلية:</span>
                <span className="font-bold text-indigo-700">{selectedAccount.recurring_schedule}</span>
              </div>
              {selectedAccount.items_summary && (
                <div className="pt-2 border-t border-slate-200">
                  <span className="text-slate-500 block mb-1">أصناف التموين الأساسية:</span>
                  <span className="font-medium text-slate-800">{selectedAccount.items_summary}</span>
                </div>
              )}
            </div>

            <div className="flex items-center justify-between pt-2">
              <button
                onClick={() => {
                  setInvoiceTargetAccountId(selectedAccount.id);
                  setSelectedAccount(null);
                  setIsCreateInvoiceOpen(true);
                }}
                className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-xl text-xs font-bold transition-colors flex items-center gap-1.5"
              >
                <Receipt className="w-4 h-4" />
                إصدار فاتورة مبيعات جديدة
              </button>

              <button
                onClick={() => setSelectedAccount(null)}
                className="px-4 py-2 border border-slate-200 hover:bg-slate-50 text-slate-700 rounded-xl text-xs font-bold transition-colors"
              >
                إغلاق
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ========================================================================= */}
      {/* MODAL 3: CREATE QUOTATION */}
      {/* ========================================================================= */}
      {isCreateQuotationOpen && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-2xl max-w-3xl w-full p-6 space-y-4 shadow-2xl border border-slate-200 max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between border-b pb-3 border-slate-100">
              <div className="flex items-center gap-2">
                <FileText className="w-5 h-5 text-indigo-600" />
                <h3 className="font-bold text-base text-slate-900">إعداد عرض سعر جديد للشركات (B2B RFQ)</h3>
              </div>
              <button
                onClick={() => setIsCreateQuotationOpen(false)}
                className="text-slate-400 hover:text-slate-600 p-1"
              >
                ✕
              </button>
            </div>

            <form onSubmit={handleCreateQuotation} className="space-y-4 text-xs">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="block text-slate-700 font-bold mb-1">الشركة المستهدفة *</label>
                  <select
                    required
                    value={quoteTargetAccountId}
                    onChange={(e) => setQuoteTargetAccountId(e.target.value)}
                    className="w-full p-2.5 border border-slate-200 rounded-xl font-bold"
                  >
                    <option value="">-- اختر شركة معتمدة --</option>
                    {accounts.map((a) => (
                      <option key={a.id} value={a.id}>
                        {a.company_name} (س.ت: {a.cr_number})
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-slate-700 font-bold mb-1">نسبة خصم الجملة المقترحة (%)</label>
                  <input
                    type="number"
                    min={0}
                    max={50}
                    value={quoteGlobalDiscount}
                    onChange={(e) => setQuoteGlobalDiscount(Number(e.target.value))}
                    className="w-full p-2.5 border border-slate-200 rounded-xl font-mono"
                  />
                </div>
              </div>

              {/* Items Table */}
              <div className="border border-slate-200 rounded-xl overflow-hidden">
                <div className="p-3 bg-slate-50 border-b border-slate-200 flex items-center justify-between">
                  <span className="font-bold text-slate-700">بنود عرض السعر والكميات المطلوبة</span>
                  <button
                    type="button"
                    onClick={() => {
                      if (products.length > 0) {
                        const first = products[0];
                        setQuoteItems((prev) => [
                          ...prev,
                          {
                            product_id: first.id,
                            quantity: 10,
                            unit_price: first.price,
                            discount_percent: quoteGlobalDiscount,
                          },
                        ]);
                      }
                    }}
                    className="px-3 py-1 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg text-xs font-bold flex items-center gap-1"
                  >
                    <Plus className="w-3.5 h-3.5" />
                    إضافة صنف
                  </button>
                </div>

                <div className="p-3 space-y-2">
                  {quoteItems.length === 0 ? (
                    <p className="text-center text-slate-400 py-4">لم يتم اختيار أي أصناف بعد. انقر على إضافة صنف.</p>
                  ) : (
                    quoteItems.map((item, idx) => (
                      <div key={idx} className="flex items-center gap-2 bg-slate-50 p-2.5 rounded-xl border border-slate-200">
                        <select
                          value={item.product_id}
                          onChange={(e) => {
                            const p = products.find((prod) => prod.id === e.target.value);
                            const updated = [...quoteItems];
                            updated[idx].product_id = e.target.value;
                            if (p) updated[idx].unit_price = p.price;
                            setQuoteItems(updated);
                          }}
                          className="flex-1 p-2 border border-slate-200 rounded-lg text-xs"
                        >
                          {products.map((p) => (
                            <option key={p.id} value={p.id}>
                              {p.name_ar} (متوفر: {p.stock_quantity}) - {p.price} ل.س
                            </option>
                          ))}
                        </select>

                        <input
                          type="number"
                          min={1}
                          placeholder="الكمية"
                          value={item.quantity}
                          onChange={(e) => {
                            const updated = [...quoteItems];
                            updated[idx].quantity = Number(e.target.value);
                            setQuoteItems(updated);
                          }}
                          className="w-20 p-2 border border-slate-200 rounded-lg text-xs font-mono text-center"
                        />

                        <input
                          type="number"
                          placeholder="السعر"
                          value={item.unit_price}
                          onChange={(e) => {
                            const updated = [...quoteItems];
                            updated[idx].unit_price = Number(e.target.value);
                            setQuoteItems(updated);
                          }}
                          className="w-24 p-2 border border-slate-200 rounded-lg text-xs font-mono text-center"
                        />

                        <button
                          type="button"
                          onClick={() => setQuoteItems(quoteItems.filter((_, i) => i !== idx))}
                          className="p-1.5 text-red-500 hover:bg-red-50 rounded-lg"
                        >
                          ✕
                        </button>
                      </div>
                    ))
                  )}
                </div>
              </div>

              <div>
                <label className="block text-slate-700 font-bold mb-1">ملاحظات وشروط العرض</label>
                <textarea
                  rows={2}
                  value={quoteNotes}
                  onChange={(e) => setQuoteNotes(e.target.value)}
                  placeholder="شروط التسليم، الدفع، الصلاحية..."
                  className="w-full p-2.5 border border-slate-200 rounded-xl"
                />
              </div>

              <div className="flex items-center justify-end gap-2 pt-3 border-t border-slate-100">
                <button
                  type="button"
                  onClick={() => setIsCreateQuotationOpen(false)}
                  className="px-4 py-2 border border-slate-200 rounded-xl text-slate-600 hover:bg-slate-50 font-bold"
                >
                  إلغاء
                </button>
                <button
                  type="submit"
                  disabled={isSubmitting}
                  className="px-5 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-xl font-bold shadow-xs"
                >
                  {isSubmitting ? 'جاري الإنشاء...' : 'حفظ وإصدار عرض السعر'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ========================================================================= */}
      {/* MODAL 4: CREATE DIRECT INVOICE */}
      {/* ========================================================================= */}
      {isCreateInvoiceOpen && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-2xl max-w-3xl w-full p-6 space-y-4 shadow-2xl border border-slate-200 max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between border-b pb-3 border-slate-100">
              <div className="flex items-center gap-2">
                <Receipt className="w-5 h-5 text-blue-600" />
                <h3 className="font-bold text-base text-slate-900">إصدار فاتورة مبيعات شركات ZATCA B2B مع خصم المخزون</h3>
              </div>
              <button
                onClick={() => setIsCreateInvoiceOpen(false)}
                className="text-slate-400 hover:text-slate-600 p-1"
              >
                ✕
              </button>
            </div>

            <form onSubmit={handleCreateDirectInvoice} className="space-y-4 text-xs">
              <div>
                <label className="block text-slate-700 font-bold mb-1">حساب الشركة المفوترة *</label>
                <select
                  required
                  value={invoiceTargetAccountId}
                  onChange={(e) => setInvoiceTargetAccountId(e.target.value)}
                  className="w-full p-2.5 border border-slate-200 rounded-xl font-bold"
                >
                  <option value="">-- اختر شركة معتمدة --</option>
                  {accounts.map((a) => (
                    <option key={a.id} value={a.id}>
                      {a.company_name} (س.ت: {a.cr_number}) - الحد المتبقي: {(a.monthly_credit_limit - a.current_balance).toLocaleString()} ل.س
                    </option>
                  ))}
                </select>
              </div>

              {/* Items Selector */}
              <div className="border border-slate-200 rounded-xl overflow-hidden">
                <div className="p-3 bg-slate-50 border-b border-slate-200 flex items-center justify-between">
                  <span className="font-bold text-slate-700">أصناف الفاتورة (سيتم خصمها من المخزون فورياً)</span>
                  <button
                    type="button"
                    onClick={() => {
                      if (products.length > 0) {
                        const first = products[0];
                        setInvoiceItems((prev) => [
                          ...prev,
                          {
                            product_id: first.id,
                            quantity: 5,
                            unit_price: first.price,
                            discount_percent: 10,
                          },
                        ]);
                      }
                    }}
                    className="px-3 py-1 bg-blue-600 hover:bg-blue-700 text-white rounded-lg text-xs font-bold flex items-center gap-1"
                  >
                    <Plus className="w-3.5 h-3.5" />
                    إضافة صنف
                  </button>
                </div>

                <div className="p-3 space-y-2">
                  {invoiceItems.length === 0 ? (
                    <p className="text-center text-slate-400 py-4">أضف أصناف الفاتورة للبدء.</p>
                  ) : (
                    invoiceItems.map((item, idx) => (
                      <div key={idx} className="flex items-center gap-2 bg-slate-50 p-2.5 rounded-xl border border-slate-200">
                        <select
                          value={item.product_id}
                          onChange={(e) => {
                            const p = products.find((prod) => prod.id === e.target.value);
                            const updated = [...invoiceItems];
                            updated[idx].product_id = e.target.value;
                            if (p) updated[idx].unit_price = p.price;
                            setInvoiceItems(updated);
                          }}
                          className="flex-1 p-2 border border-slate-200 rounded-lg text-xs"
                        >
                          {products.map((p) => (
                            <option key={p.id} value={p.id}>
                              {p.name_ar} (متوفر بالمخزون: {p.stock_quantity}) - {p.price} ل.س
                            </option>
                          ))}
                        </select>

                        <input
                          type="number"
                          min={1}
                          placeholder="الكمية"
                          value={item.quantity}
                          onChange={(e) => {
                            const updated = [...invoiceItems];
                            updated[idx].quantity = Number(e.target.value);
                            setInvoiceItems(updated);
                          }}
                          className="w-20 p-2 border border-slate-200 rounded-lg text-xs font-mono text-center"
                        />

                        <input
                          type="number"
                          placeholder="السعر"
                          value={item.unit_price}
                          onChange={(e) => {
                            const updated = [...invoiceItems];
                            updated[idx].unit_price = Number(e.target.value);
                            setInvoiceItems(updated);
                          }}
                          className="w-24 p-2 border border-slate-200 rounded-lg text-xs font-mono text-center"
                        />

                        <input
                          type="number"
                          placeholder="خصم %"
                          value={item.discount_percent}
                          onChange={(e) => {
                            const updated = [...invoiceItems];
                            updated[idx].discount_percent = Number(e.target.value);
                            setInvoiceItems(updated);
                          }}
                          className="w-16 p-2 border border-slate-200 rounded-lg text-xs font-mono text-center"
                        />

                        <button
                          type="button"
                          onClick={() => setInvoiceItems(invoiceItems.filter((_, i) => i !== idx))}
                          className="p-1.5 text-red-500 hover:bg-red-50 rounded-lg"
                        >
                          ✕
                        </button>
                      </div>
                    ))
                  )}
                </div>
              </div>

              <div>
                <label className="block text-slate-700 font-bold mb-1">ملاحظات الفاتورة والتسليم</label>
                <input
                  type="text"
                  value={invoiceNotes}
                  onChange={(e) => setInvoiceNotes(e.target.value)}
                  placeholder="شحنة أسبوعية / تموين المقر"
                  className="w-full p-2.5 border border-slate-200 rounded-xl"
                />
              </div>

              <div className="flex items-center justify-end gap-2 pt-3 border-t border-slate-100">
                <button
                  type="button"
                  onClick={() => setIsCreateInvoiceOpen(false)}
                  className="px-4 py-2 border border-slate-200 rounded-xl text-slate-600 hover:bg-slate-50 font-bold"
                >
                  إلغاء
                </button>
                <button
                  type="submit"
                  disabled={isSubmitting}
                  className="px-5 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-xl font-bold shadow-xs"
                >
                  {isSubmitting ? 'جاري الإصدار والخصم...' : 'إصدار الفاتورة وخصم المخزون'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ========================================================================= */}
      {/* MODAL 5: RECORD PAYMENT */}
      {/* ========================================================================= */}
      {isRecordPaymentOpen && selectedInvoice && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-2xl max-w-lg w-full p-6 space-y-4 shadow-2xl border border-slate-200">
            <div className="flex items-center justify-between border-b pb-3 border-slate-100">
              <div className="flex items-center gap-2">
                <DollarSign className="w-5 h-5 text-emerald-600" />
                <h3 className="font-bold text-base text-slate-900">
                  تسجيل سداد دفعة للفاتورة ({selectedInvoice.invoice_number})
                </h3>
              </div>
              <button
                onClick={() => setIsRecordPaymentOpen(false)}
                className="text-slate-400 hover:text-slate-600 p-1"
              >
                ✕
              </button>
            </div>

            <form onSubmit={handleRecordPayment} className="space-y-4 text-xs">
              <div className="bg-slate-50 p-3.5 rounded-xl space-y-1.5 border border-slate-200 font-mono">
                <div className="flex justify-between">
                  <span className="text-slate-500">إجمالي الفاتورة:</span>
                  <span className="font-bold text-slate-900">{selectedInvoice.total_amount.toLocaleString()} ل.س</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-500">المسدد سابقاً:</span>
                  <span className="font-bold text-emerald-700">{selectedInvoice.paid_amount.toLocaleString()} ل.س</span>
                </div>
                <div className="flex justify-between border-t pt-1.5">
                  <span className="text-slate-700 font-bold">المتبقي المطلوب سداده:</span>
                  <span className="font-bold text-amber-700">{selectedInvoice.remaining_amount.toLocaleString()} ل.س</span>
                </div>
              </div>

              <div>
                <label className="block text-slate-700 font-bold mb-1">مبلغ السداد الحالي (ل.س) *</label>
                <input
                  type="number"
                  required
                  min={1}
                  max={selectedInvoice.remaining_amount}
                  value={paymentAmount}
                  onChange={(e) => setPaymentAmount(Number(e.target.value))}
                  className="w-full p-2.5 border border-slate-200 rounded-xl font-mono text-sm font-bold text-emerald-700"
                />
              </div>

              <div>
                <label className="block text-slate-700 font-bold mb-1">طريقة السداد المعتمدة *</label>
                <select
                  value={paymentMethod}
                  onChange={(e) => setPaymentMethod(e.target.value as any)}
                  className="w-full p-2.5 border border-slate-200 rounded-xl font-bold"
                >
                  <option value="bank_transfer">تحويل بنكي / حوالة مصرفية</option>
                  <option value="check">شيك مصرفي مصدق</option>
                  <option value="cash">نقداً عبر الكاشير</option>
                  <option value="credit_card">بطاقة بنكية / شبكة</option>
                </select>
              </div>

              <div>
                <label className="block text-slate-700 font-bold mb-1">رقم الحوالة البنكية / المرجع *</label>
                <input
                  type="text"
                  required
                  value={paymentRefNumber}
                  onChange={(e) => setPaymentRefNumber(e.target.value)}
                  placeholder="مثال: TRX-B2B-984210"
                  className="w-full p-2.5 border border-slate-200 rounded-xl font-mono"
                />
              </div>

              <div>
                <label className="block text-slate-700 font-bold mb-1">ملاحظات السند</label>
                <input
                  type="text"
                  value={paymentNotes}
                  onChange={(e) => setPaymentNotes(e.target.value)}
                  placeholder="سداد دفعة أولى / تصفية حساب"
                  className="w-full p-2.5 border border-slate-200 rounded-xl"
                />
              </div>

              <div className="flex items-center justify-end gap-2 pt-3 border-t border-slate-100">
                <button
                  type="button"
                  onClick={() => setIsRecordPaymentOpen(false)}
                  className="px-4 py-2 border border-slate-200 rounded-xl text-slate-600 hover:bg-slate-50 font-bold"
                >
                  إلغاء
                </button>
                <button
                  type="submit"
                  disabled={isSubmitting}
                  className="px-5 py-2 bg-emerald-600 hover:bg-emerald-700 text-white rounded-xl font-bold shadow-xs"
                >
                  {isSubmitting ? 'جاري التقييد...' : 'تأكيد السداد وتخفيض المديونية'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ========================================================================= */}
      {/* MODAL 6: PRINTABLE ZATCA TAX INVOICE */}
      {/* ========================================================================= */}
      {isPrintInvoiceOpen && selectedInvoice && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-2xl max-w-2xl w-full p-8 space-y-6 shadow-2xl border border-slate-200 max-h-[90vh] overflow-y-auto print:p-0">
            <div className="flex items-center justify-between border-b pb-4 border-slate-200">
              <div className="flex items-center gap-3">
                <div className="w-12 h-12 bg-blue-900 rounded-xl flex items-center justify-center text-white font-black text-xl">
                  الديب
                </div>
                <div>
                  <h2 className="font-black text-lg text-slate-900">هايبرماركت ومول الديب المركزي</h2>
                  <p className="text-xs text-slate-500 font-mono">فاتورة ضريبية B2B Tax Invoice (ZATCA Fatoora)</p>
                </div>
              </div>

              <div className="text-left font-mono text-xs">
                <p className="font-bold text-slate-900">{selectedInvoice.invoice_number}</p>
                <p className="text-slate-500">{new Date(selectedInvoice.created_at).toLocaleDateString('ar-SA')}</p>
              </div>
            </div>

            {/* Parties info */}
            <div className="grid grid-cols-2 gap-4 text-xs bg-slate-50 p-4 rounded-xl border border-slate-200">
              <div>
                <p className="font-bold text-slate-900 mb-1">المورد (البائع):</p>
                <p className="text-slate-700">شركة أسواق الديب الكبرى للتجارة</p>
                <p className="text-slate-500 font-mono">الرقم الضريبي: 300998877660003</p>
                <p className="text-slate-500">فرع: {selectedInvoice.branch_id}</p>
              </div>

              <div>
                <p className="font-bold text-slate-900 mb-1">العميل (المشتري):</p>
                <p className="text-slate-700 font-bold">{selectedInvoice.corporate_account_name}</p>
                <p className="text-slate-500 font-mono">تاريخ الاستحقاق: {selectedInvoice.due_date}</p>
                <p className="text-slate-500 font-bold text-blue-700">حالة السداد: {selectedInvoice.payment_status}</p>
              </div>
            </div>

            {/* Line items table */}
            <table className="w-full text-right text-xs border border-slate-200 rounded-xl overflow-hidden">
              <thead className="bg-slate-100 text-slate-700 font-bold">
                <tr>
                  <th className="p-2.5">الصنف</th>
                  <th className="p-2.5 text-center">الكمية</th>
                  <th className="p-2.5 text-center">سعر الوحدة</th>
                  <th className="p-2.5 text-center">الخصم</th>
                  <th className="p-2.5 text-center">المجموع الصافي</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 font-mono">
                {(selectedInvoice.items || []).map((it, idx) => (
                  <tr key={idx}>
                    <td className="p-2.5 font-sans font-medium text-slate-800">{it.product_name_ar || 'صنف'}</td>
                    <td className="p-2.5 text-center">{it.quantity}</td>
                    <td className="p-2.5 text-center">{it.unit_price} ل.س</td>
                    <td className="p-2.5 text-center">{it.discount_percent}%</td>
                    <td className="p-2.5 text-center font-bold text-slate-900">{it.total_price.toLocaleString()} ل.س</td>
                  </tr>
                ))}
              </tbody>
            </table>

            {/* Financial Totals */}
            <div className="flex justify-between items-end text-xs font-mono bg-slate-50 p-4 rounded-xl border border-slate-200">
              <div className="flex items-center gap-3">
                <QrCode className="w-20 h-20 text-slate-800 border p-1 rounded-lg bg-white" />
                <div className="text-[10px] text-slate-500 font-sans space-y-0.5">
                  <p className="font-bold text-slate-700">رمز الاستجابة السريعة ZATCA QR</p>
                  <p>مشفر بالمعايير الضريبية المعتمدة</p>
                  <p className="text-emerald-700 font-bold">✓ توقيع إلكتروني خادمي موثق</p>
                </div>
              </div>

              <div className="w-64 space-y-1.5">
                <div className="flex justify-between">
                  <span className="text-slate-500">المجموع قبل الضريبة:</span>
                  <span className="font-bold text-slate-900">{selectedInvoice.subtotal.toLocaleString()} ل.س</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-500">الخصم التجاري الممنوح:</span>
                  <span className="font-bold text-amber-600">-{selectedInvoice.discount_amount.toLocaleString()} ل.س</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-500">ضريبة القيمة المضافة (15%):</span>
                  <span className="font-bold text-slate-900">{selectedInvoice.tax_amount.toLocaleString()} ل.س</span>
                </div>
                <div className="flex justify-between border-t border-slate-300 pt-1.5 text-sm">
                  <span className="font-bold text-slate-900">الإجمالي النهائي:</span>
                  <span className="font-black text-blue-800">{selectedInvoice.total_amount.toLocaleString()} ل.س</span>
                </div>
              </div>
            </div>

            <div className="flex items-center justify-between pt-2">
              <button
                onClick={() => window.print()}
                className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-xl text-xs font-bold transition-colors flex items-center gap-1.5"
              >
                <Printer className="w-4 h-4" />
                طباعة الفاتورة الآن
              </button>

              <button
                onClick={() => setIsPrintInvoiceOpen(false)}
                className="px-4 py-2 border border-slate-200 hover:bg-slate-50 text-slate-700 rounded-xl text-xs font-bold transition-colors"
              >
                إغلاق
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
