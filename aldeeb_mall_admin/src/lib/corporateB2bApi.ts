import { supabase } from './supabase';
import {
  CorporateAccount,
  CorporateQuotation,
  CorporateQuotationItem,
  CorporateInvoice,
  CorporateInvoiceItem,
  CorporatePayment,
  CorporateReturn,
  CorporateReturnItem,
} from '../types';

export const corporateB2bApi = {
  // ============================================================================
  // Corporate Accounts (حسابات الشركات المعتمدة)
  // ============================================================================
  async fetchCorporateAccounts(branchId?: string): Promise<CorporateAccount[]> {
    let query = supabase
      .from('corporate_accounts')
      .select('*')
      .order('company_name', { ascending: true });

    if (branchId && branchId !== 'all') {
      query = query.eq('branch_id', branchId);
    }

    const { data, error } = await query;
    if (error) {
      console.error('Failed to fetch corporate accounts:', error);
      throw new Error(error.message);
    }
    return (data || []).map((acc: any) => ({
      ...acc,
      monthly_credit_limit: Number(acc.monthly_credit_limit),
      current_balance: Number(acc.current_balance),
    }));
  },

  async createCorporateAccount(account: Partial<CorporateAccount>): Promise<CorporateAccount> {
    const { data, error } = await supabase
      .from('corporate_accounts')
      .insert([account])
      .select()
      .single();

    if (error) {
      console.error('Failed to create corporate account:', error);
      throw new Error(error.message);
    }
    return {
      ...data,
      monthly_credit_limit: Number(data.monthly_credit_limit),
      current_balance: Number(data.current_balance),
    };
  },

  async updateCorporateAccount(id: string, updates: Partial<CorporateAccount>): Promise<CorporateAccount> {
    const { data, error } = await supabase
      .from('corporate_accounts')
      .update({ ...updates, updated_at: new Date().toISOString() })
      .eq('id', id)
      .select()
      .single();

    if (error) {
      console.error('Failed to update corporate account:', error);
      throw new Error(error.message);
    }
    return {
      ...data,
      monthly_credit_limit: Number(data.monthly_credit_limit),
      current_balance: Number(data.current_balance),
    };
  },

  // ============================================================================
  // Corporate Quotations & RFQs (عروض الأسعار وطلبات الشراء)
  // ============================================================================
  async fetchQuotations(branchId?: string, accountId?: string): Promise<CorporateQuotation[]> {
    let query = supabase
      .from('corporate_quotations')
      .select(`
        *,
        corporate_account:corporate_accounts(company_name),
        items:corporate_quotation_items(
          id, quotation_id, product_id, quantity, unit_price,
          discount_percent, final_unit_price, total_price, notes,
          product:products(name_ar, name_en, barcode)
        )
      `)
      .order('created_at', { ascending: false });

    if (branchId && branchId !== 'all') {
      query = query.eq('branch_id', branchId);
    }
    if (accountId) {
      query = query.eq('corporate_account_id', accountId);
    }

    const { data, error } = await query;
    if (error) {
      console.error('Failed to fetch corporate quotations:', error);
      throw new Error(error.message);
    }

    return (data || []).map((q: any) => ({
      ...q,
      corporate_account_name: q.corporate_account?.company_name || 'شركة غير محددة',
      subtotal: Number(q.subtotal),
      discount_percent: Number(q.discount_percent),
      discount_amount: Number(q.discount_amount),
      tax_amount: Number(q.tax_amount),
      total_amount: Number(q.total_amount),
      items: (q.items || []).map((it: any) => ({
        ...it,
        quantity: Number(it.quantity),
        unit_price: Number(it.unit_price),
        discount_percent: Number(it.discount_percent),
        final_unit_price: Number(it.final_unit_price),
        total_price: Number(it.total_price),
        product_name_ar: it.product?.name_ar || 'منتج',
        product_name_en: it.product?.name_en || '',
        barcode: it.product?.barcode || '',
      })),
    }));
  },

  async createQuotation(
    quoteData: Partial<CorporateQuotation>,
    items: Array<{
      product_id: string;
      quantity: number;
      unit_price: number;
      discount_percent: number;
      notes?: string;
    }>
  ): Promise<CorporateQuotation> {
    const seqNum = Date.now().toString().slice(-4);
    const quotationNumber = `QT-${new Date().getFullYear()}-${seqNum}`;

    // Compute totals
    let subtotal = 0;
    let discountAmount = 0;

    const computedItems = items.map((it) => {
      const finalUnitPrice = Math.round(it.unit_price * (1 - (it.discount_percent / 100)) * 100) / 100;
      const lineTotal = Math.round(finalUnitPrice * it.quantity * 100) / 100;
      const origLineTotal = Math.round(it.unit_price * it.quantity * 100) / 100;

      subtotal += origLineTotal;
      discountAmount += (origLineTotal - lineTotal);

      return {
        product_id: it.product_id,
        quantity: it.quantity,
        unit_price: it.unit_price,
        discount_percent: it.discount_percent,
        final_unit_price: finalUnitPrice,
        total_price: lineTotal,
        notes: it.notes || '',
      };
    });

    const taxAmount = Math.round((subtotal - discountAmount) * 0.15 * 100) / 100;
    const totalAmount = (subtotal - discountAmount) + taxAmount;

    // 1. Insert Quotation Header
    const { data: quote, error: quoteErr } = await supabase
      .from('corporate_quotations')
      .insert([{
        quotation_number: quotationNumber,
        corporate_account_id: quoteData.corporate_account_id,
        branch_id: quoteData.branch_id,
        subtotal,
        discount_percent: quoteData.discount_percent || 0,
        discount_amount: discountAmount,
        tax_amount: taxAmount,
        total_amount: totalAmount,
        status: 'draft',
        valid_until: quoteData.valid_until || new Date(Date.now() + 30 * 86400000).toISOString().split('T')[0],
        notes: quoteData.notes || '',
        created_by: quoteData.created_by || 'مسؤول مبيعات الشركات',
      }])
      .select()
      .single();

    if (quoteErr) {
      console.error('Failed to insert quotation:', quoteErr);
      throw new Error(quoteErr.message);
    }

    // 2. Insert Quotation Items
    const itemsToInsert = computedItems.map((ci) => ({
      ...ci,
      quotation_id: quote.id,
    }));

    const { error: itemsErr } = await supabase
      .from('corporate_quotation_items')
      .insert(itemsToInsert);

    if (itemsErr) {
      console.error('Failed to insert quotation items:', itemsErr);
      throw new Error(itemsErr.message);
    }

    return {
      ...quote,
      items: itemsToInsert,
    };
  },

  async approveOrRejectQuotation(
    quotationId: string,
    action: 'approve' | 'reject',
    staffName: string,
    notes?: string,
    reason?: string
  ): Promise<any> {
    const { data, error } = await supabase.rpc('approve_or_reject_corporate_quotation', {
      p_payload: {
        quotation_id: quotationId,
        action,
        staff_name: staffName,
        notes,
        reason,
      },
    });

    if (error) {
      console.error('Failed to review quotation:', error);
      throw new Error(error.message);
    }
    return data;
  },

  // ============================================================================
  // Corporate Invoices & Receivables (الفواتير والمستحقات)
  // ============================================================================
  async fetchInvoices(branchId?: string, accountId?: string): Promise<CorporateInvoice[]> {
    let query = supabase
      .from('corporate_invoices')
      .select(`
        *,
        corporate_account:corporate_accounts(company_name),
        items:corporate_invoice_items(
          id, invoice_id, product_id, quantity, unit_price,
          discount_percent, final_unit_price, total_price,
          product:products(name_ar, name_en, barcode)
        )
      `)
      .order('created_at', { ascending: false });

    if (branchId && branchId !== 'all') {
      query = query.eq('branch_id', branchId);
    }
    if (accountId) {
      query = query.eq('corporate_account_id', accountId);
    }

    const { data, error } = await query;
    if (error) {
      console.error('Failed to fetch corporate invoices:', error);
      throw new Error(error.message);
    }

    return (data || []).map((inv: any) => ({
      ...inv,
      corporate_account_name: inv.corporate_account?.company_name || 'شركة غير محددة',
      subtotal: Number(inv.subtotal),
      discount_amount: Number(inv.discount_amount),
      tax_amount: Number(inv.tax_amount),
      total_amount: Number(inv.total_amount),
      paid_amount: Number(inv.paid_amount),
      remaining_amount: Number(inv.remaining_amount),
      items: (inv.items || []).map((it: any) => ({
        ...it,
        quantity: Number(it.quantity),
        unit_price: Number(it.unit_price),
        discount_percent: Number(it.discount_percent),
        final_unit_price: Number(it.final_unit_price),
        total_price: Number(it.total_price),
        product_name_ar: it.product?.name_ar || 'منتج',
        product_name_en: it.product?.name_en || '',
        barcode: it.product?.barcode || '',
      })),
    }));
  },

  async createInvoiceWithStockDeduction(payload: {
    corporate_account_id: string;
    branch_id: string;
    quotation_id?: string;
    items: Array<{
      product_id: string;
      quantity: number;
      unit_price: number;
      discount_percent?: number;
    }>;
    notes?: string;
    created_by?: string;
  }): Promise<any> {
    const { data, error } = await supabase.rpc('create_corporate_invoice_with_stock_deduction', {
      p_payload: payload,
    });

    if (error) {
      console.error('Failed to create corporate invoice:', error);
      throw new Error(error.message);
    }
    return data;
  },

  // ============================================================================
  // Corporate Payments & Debt Settlements (سداد الدفعات)
  // ============================================================================
  async fetchPayments(accountId?: string, invoiceId?: string): Promise<CorporatePayment[]> {
    let query = supabase
      .from('corporate_payments')
      .select(`
        *,
        corporate_account:corporate_accounts(company_name),
        invoice:corporate_invoices(invoice_number)
      `)
      .order('payment_date', { ascending: false });

    if (accountId) {
      query = query.eq('corporate_account_id', accountId);
    }
    if (invoiceId) {
      query = query.eq('invoice_id', invoiceId);
    }

    const { data, error } = await query;
    if (error) {
      console.error('Failed to fetch corporate payments:', error);
      throw new Error(error.message);
    }

    return (data || []).map((p: any) => ({
      ...p,
      amount: Number(p.amount),
      corporate_account_name: p.corporate_account?.company_name || 'شركة غير محددة',
      invoice_number: p.invoice?.invoice_number || 'فاتورة غير محددة',
    }));
  },

  async recordCorporatePayment(payload: {
    invoice_id: string;
    amount: number;
    payment_method: 'bank_transfer' | 'check' | 'cash' | 'credit_card';
    reference_number: string;
    notes?: string;
    received_by?: string;
  }): Promise<any> {
    const { data, error } = await supabase.rpc('record_corporate_payment', {
      p_payload: payload,
    });

    if (error) {
      console.error('Failed to record corporate payment:', error);
      throw new Error(error.message);
    }
    return data;
  },

  // ============================================================================
  // Corporate Returns & Credit Notes (المرتجعات والإشعارات الدائنة)
  // ============================================================================
  async fetchReturns(branchId?: string, invoiceId?: string): Promise<CorporateReturn[]> {
    let query = supabase
      .from('corporate_returns')
      .select(`
        *,
        corporate_account:corporate_accounts(company_name),
        invoice:corporate_invoices(invoice_number),
        items:corporate_return_items(
          id, return_id, product_id, quantity, unit_price,
          total_refund, reason,
          product:products(name_ar, name_en)
        )
      `)
      .order('created_at', { ascending: false });

    if (branchId && branchId !== 'all') {
      query = query.eq('branch_id', branchId);
    }
    if (invoiceId) {
      query = query.eq('invoice_id', invoiceId);
    }

    const { data, error } = await query;
    if (error) {
      console.error('Failed to fetch corporate returns:', error);
      throw new Error(error.message);
    }

    return (data || []).map((r: any) => ({
      ...r,
      total_refund_amount: Number(r.total_refund_amount),
      corporate_account_name: r.corporate_account?.company_name || 'شركة غير محددة',
      invoice_number: r.invoice?.invoice_number || 'فاتورة غير محددة',
      items: (r.items || []).map((it: any) => ({
        ...it,
        quantity: Number(it.quantity),
        unit_price: Number(it.unit_price),
        total_refund: Number(it.total_refund),
        product_name_ar: it.product?.name_ar || 'منتج',
      })),
    }));
  },

  async createReturn(
    invoice: CorporateInvoice,
    items: Array<{
      product_id: string;
      quantity: number;
      unit_price: number;
      reason?: string;
    }>,
    reason: string,
    createdBy: string
  ): Promise<any> {
    const seqNum = Date.now().toString().slice(-4);
    const returnNumber = `RET-B2B-${new Date().getFullYear()}-${seqNum}`;

    let totalRefund = 0;
    const computedItems = items.map((it) => {
      const lineRefund = Math.round(it.unit_price * it.quantity * 100) / 100;
      totalRefund += lineRefund;
      return {
        product_id: it.product_id,
        quantity: it.quantity,
        unit_price: it.unit_price,
        total_refund: lineRefund,
        reason: it.reason || reason,
      };
    });

    // 1. Insert Return Header
    const { data: ret, error: retErr } = await supabase
      .from('corporate_returns')
      .insert([{
        return_number: returnNumber,
        invoice_id: invoice.id,
        corporate_account_id: invoice.corporate_account_id,
        branch_id: invoice.branch_id,
        total_refund_amount: totalRefund,
        status: 'pending_approval',
        reason,
        created_by: createdBy,
      }])
      .select()
      .single();

    if (retErr) {
      console.error('Failed to insert corporate return:', retErr);
      throw new Error(retErr.message);
    }

    // 2. Insert Return Items
    const itemsToInsert = computedItems.map((ci) => ({
      ...ci,
      return_id: ret.id,
    }));

    const { error: itemsErr } = await supabase
      .from('corporate_return_items')
      .insert(itemsToInsert);

    if (itemsErr) {
      console.error('Failed to insert return items:', itemsErr);
      throw new Error(itemsErr.message);
    }

    return ret;
  },

  async processReturnWithStockRestoration(returnId: string, approvedBy: string): Promise<any> {
    const { data, error } = await supabase.rpc('process_corporate_return_with_stock_restoration', {
      p_payload: {
        return_id: returnId,
        approved_by: approvedBy,
      },
    });

    if (error) {
      console.error('Failed to process return and restore stock:', error);
      throw new Error(error.message);
    }
    return data;
  },
};
