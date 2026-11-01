import React, { useState } from 'react';
import { 
  Building2, 
  FileText, 
  Plus, 
  CheckCircle2, 
  Clock, 
  AlertCircle, 
  Phone, 
  Mail, 
  TrendingDown, 
  Send,
  DollarSign,
  PackageCheck,
  AlertTriangle,
  CreditCard,
  Check,
  X,
  Sparkles,
  Barcode,
  Layers,
  ArrowDownRight,
  ShieldCheck
} from 'lucide-react';
import { Supplier, PurchaseOrder, Product, PurchaseOrderItem } from '../types';
import { logAuditEvent } from '../lib/auditLogger';

interface SuppliersPageProps {
  suppliers: Supplier[];
  purchaseOrders: PurchaseOrder[];
  products: Product[];
  onAddPO?: (po: PurchaseOrder) => void;
  onAddProduct?: (product: Product) => void;
  onUpdateProduct?: (product: Product) => void;
}

export const SuppliersPage: React.FC<SuppliersPageProps> = ({
  suppliers,
  purchaseOrders: initialPOs,
  products,
  onAddPO,
  onAddProduct,
  onUpdateProduct,
}) => {
  // Enriched initial PO state with structured items and payment tracking
  const [pos, setPOs] = useState<PurchaseOrder[]>(() => {
    return initialPOs.map((po, idx) => ({
      ...po,
      paid_amount: po.paid_amount ?? (po.status === 'received' ? po.total_cost : idx % 2 === 0 ? po.total_cost * 0.5 : 0),
      payment_status: po.payment_status ?? (po.status === 'received' ? 'paid' : idx % 2 === 0 ? 'partial' : 'unpaid'),
      items: po.items && po.items.length > 0 ? po.items : [
        {
          product_id: products[idx % products.length]?.id,
          name_ar: products[idx % products.length]?.name_ar || 'صنف توريد قياسي',
          barcode: products[idx % products.length]?.barcode || '629100123456',
          quantity_ordered: po.total_items,
          quantity_received: po.status === 'received' ? po.total_items : 0,
          unit_cost: Math.round(po.total_cost / Math.max(po.total_items, 1)),
          total_cost: po.total_cost,
        }
      ]
    }));
  });

  const [activeTab, setActiveTab] = useState<'orders' | 'suppliers' | 'drafts' | 'payables'>('orders');
  
  // New PO Modal States
  const [showNewPOModal, setShowNewPOModal] = useState<boolean>(false);
  const [selectedSupplier, setSelectedSupplier] = useState<string>(suppliers[0]?.name_ar || '');
  const [expectedArrival, setExpectedArrival] = useState<string>('غداً صباحاً (6:00 ص)');
  const [poNotes, setPoNotes] = useState<string>('');
  const [orderItems, setOrderItems] = useState<PurchaseOrderItem[]>([
    {
      product_id: products[0]?.id,
      name_ar: products[0]?.name_ar || 'زيت زيتون بكر ممتاز',
      barcode: products[0]?.barcode || '6291001001',
      quantity_ordered: 100,
      quantity_received: 0,
      unit_cost: 25.0,
      total_cost: 2500.0,
    }
  ]);

  // Draft product inside PO state
  const [showAddDraftModal, setShowAddDraftModal] = useState<boolean>(false);
  const [draftNameAr, setDraftNameAr] = useState<string>('');
  const [draftBarcode, setDraftBarcode] = useState<string>('');
  const [draftUnit, setDraftUnit] = useState<string>('piece');
  const [draftCost, setDraftCost] = useState<number>(15.0);
  const [draftQty, setDraftQty] = useState<number>(50);

  // Receiving Sheet Modal
  const [receivingPO, setReceivingPO] = useState<PurchaseOrder | null>(null);
  const [receivingItems, setReceivingItems] = useState<{ [index: number]: { qtyReceived: number; damagedQty: number } }>({});

  // Payment Modal
  const [payingPO, setPayingPO] = useState<PurchaseOrder | null>(null);
  const [paymentAmount, setPaymentAmount] = useState<number>(0);
  const [paymentMethod, setPaymentMethod] = useState<'cash' | 'sham_cash' | 'bank_transfer'>('sham_cash');
  const [paymentReference, setPaymentReference] = useState<string>('');

  // Auto-alert products below safety stock
  const lowStockProducts = products.filter((p) => p.stock_quantity <= 50);

  // Draft / Incomplete products in catalog
  const draftProducts = products.filter((p) => p.is_draft === true || p.status === 'incomplete_data');

  // Total financial calculations
  const totalPurchasesCost = pos.reduce((sum, p) => sum + p.total_cost, 0);
  const totalPaidCost = pos.reduce((sum, p) => sum + (p.paid_amount || 0), 0);
  const totalOutstandingPayable = Math.max(0, totalPurchasesCost - totalPaidCost);

  // Add an existing catalog product to PO
  const handleAddCatalogItemToPO = (productId: string) => {
    const prod = products.find((p) => p.id === productId);
    if (!prod) return;
    const unitCost = prod.cost_price || Math.round(prod.price * 0.75);
    const newItem: PurchaseOrderItem = {
      product_id: prod.id,
      name_ar: prod.name_ar,
      barcode: prod.barcode,
      quantity_ordered: 50,
      quantity_received: 0,
      unit_cost: unitCost,
      total_cost: unitCost * 50,
      is_new_draft_product: false,
    };
    setOrderItems((prev) => [...prev, newItem]);
  };

  // Add a brand-new draft product directly in PO
  const handleConfirmAddDraftItem = (e: React.FormEvent) => {
    e.preventDefault();
    if (!draftNameAr.trim()) return;

    const draftId = `p-draft-${Date.now()}`;
    const generatedBarcode = draftBarcode.trim() || `${Math.floor(629000000000 + Math.random() * 1000000000)}`;
    const cost = Number(draftCost);
    const qty = Number(draftQty);

    const newItem: PurchaseOrderItem = {
      product_id: draftId,
      name_ar: draftNameAr.trim(),
      barcode: generatedBarcode,
      quantity_ordered: qty,
      quantity_received: 0,
      unit_cost: cost,
      total_cost: cost * qty,
      is_new_draft_product: true,
    };

    setOrderItems((prev) => [...prev, newItem]);

    // Also register as a draft in catalog (invisible to customer app)
    if (onAddProduct) {
      const newDraftProduct: Product = {
        id: draftId,
        name_ar: draftNameAr.trim(),
        name_en: draftNameAr.trim(),
        brand: selectedSupplier,
        barcode: generatedBarcode,
        category_id: 'c1',
        cost_price: cost,
        price: Math.round(cost * 1.3),
        discount_percent: 0,
        unit: draftUnit,
        weight_step: draftUnit === 'kg' ? 0.5 : 1.0,
        stock_quantity: 0, // 0 until received at warehouse
        images: ['https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=400&q=80'],
        is_featured: false,
        is_daily_deal: false,
        rating: 4.8,
        sales_count: 0,
        is_draft: true,
        status: 'incomplete_data',
      };
      onAddProduct(newDraftProduct);
      logAuditEvent({
        actor_id: 'admin-1',
        actor_name: 'مدير المشتريات والمستودعات',
        actor_role: 'procurement_manager',
        action: 'DRAFT_PRODUCT_CREATED',
        category: 'inventory',
        details: `تم إنشاء مسودة صنف جديد (${draftNameAr}) عبر فاتورة شراء للمورد ${selectedSupplier} - محجوب عن التطبيق حتى الاعتماد.`,
        target_id: draftId,
      });
    }

    setDraftNameAr('');
    setDraftBarcode('');
    setDraftQty(50);
    setDraftCost(15);
    setShowAddDraftModal(false);
  };

  // Submit complete PO
  const handleCreatePO = (e: React.FormEvent) => {
    e.preventDefault();
    if (orderItems.length === 0) return;

    const totalCost = orderItems.reduce((acc, item) => acc + item.total_cost, 0);
    const totalItems = orderItems.reduce((acc, item) => acc + item.quantity_ordered, 0);

    const newPO: PurchaseOrder = {
      id: `po-${Date.now()}`,
      po_number: `PO-2026-${Math.floor(100 + Math.random() * 900)}`,
      supplier_name: selectedSupplier,
      total_items: totalItems,
      total_cost: totalCost,
      paid_amount: 0,
      payment_status: 'unpaid',
      status: 'sent',
      order_date: new Date().toISOString().split('T')[0],
      expected_arrival: expectedArrival,
      items: orderItems,
      notes: poNotes.trim() || undefined,
    };

    setPOs((prev) => [newPO, ...prev]);
    if (onAddPO) onAddPO(newPO);

    logAuditEvent({
      actor_id: 'admin-1',
      actor_name: 'مدير المشتريات والمستودعات',
      actor_role: 'procurement_manager',
      action: 'PO_CREATED',
      category: 'inventory',
      details: `إصدار أمر شراء جديد ${newPO.po_number} للمورد ${selectedSupplier} بإجمالي ${totalCost.toLocaleString()} ل.س وعدد أصناف ${orderItems.length}`,
      target_id: newPO.id,
    });

    setShowNewPOModal(false);
    setOrderItems([]);
    setPoNotes('');
  };

  // Open Receiving Modal
  const handleOpenReceivingModal = (po: PurchaseOrder) => {
    setReceivingPO(po);
    const initialMap: { [index: number]: { qtyReceived: number; damagedQty: number } } = {};
    (po.items || []).forEach((item, index) => {
      const remaining = Math.max(0, item.quantity_ordered - item.quantity_received);
      initialMap[index] = {
        qtyReceived: remaining,
        damagedQty: 0,
      };
    });
    setReceivingItems(initialMap);
  };

  // Fast Fill: Receive all remaining
  const handleReceiveAll = () => {
    if (!receivingPO?.items) return;
    const filled: { [index: number]: { qtyReceived: number; damagedQty: number } } = {};
    receivingPO.items.forEach((item, index) => {
      const remaining = Math.max(0, item.quantity_ordered - item.quantity_received);
      filled[index] = {
        qtyReceived: remaining,
        damagedQty: 0,
      };
    });
    setReceivingItems(filled);
  };

  // Confirm Receiving (Partial or Full)
  const handleConfirmReceiving = () => {
    if (!receivingPO || !receivingPO.items) return;

    let allFulfilled = true;
    let anyReceived = false;

    const updatedItems: PurchaseOrderItem[] = receivingPO.items.map((item, index) => {
      const entry = receivingItems[index] || { qtyReceived: 0, damagedQty: 0 };
      const newlyReceived = Number(entry.qtyReceived) || 0;
      const damaged = Number(entry.damagedQty) || 0;
      const netGoodReceived = Math.max(0, newlyReceived - damaged);

      const totalReceivedNow = item.quantity_received + netGoodReceived;
      if (totalReceivedNow < item.quantity_ordered) {
        allFulfilled = false;
      }
      if (newlyReceived > 0) {
        anyReceived = true;
      }

      // If product exists in catalog, update its stock!
      if (netGoodReceived > 0 && onUpdateProduct && item.product_id) {
        const prod = products.find((p) => p.id === item.product_id);
        if (prod) {
          onUpdateProduct({
            ...prod,
            stock_quantity: prod.stock_quantity + netGoodReceived,
            cost_price: item.unit_cost,
          });
        }
      }

      return {
        ...item,
        quantity_received: totalReceivedNow,
      };
    });

    const newStatus = allFulfilled ? 'received' : anyReceived ? 'partially_received' : receivingPO.status;

    setPOs((prev) =>
      prev.map((p) =>
        p.id === receivingPO.id
          ? {
              ...p,
              items: updatedItems,
              status: newStatus,
            }
          : p
      )
    );

    logAuditEvent({
      actor_id: 'admin-1',
      actor_name: 'أمين المستودع الرئيسي',
      actor_role: 'warehouse_keeper',
      action: 'PO_RECEIVE',
      category: 'inventory',
      details: `تم ${allFulfilled ? 'الاستلام الكامل' : 'الاستلام الجزئي'} لأمر الشراء ${receivingPO.po_number} وتحديث المخزون الفعلي.`,
      target_id: receivingPO.id,
    });

    setReceivingPO(null);
  };

  // Open Payment Modal
  const handleOpenPaymentModal = (po: PurchaseOrder) => {
    setPayingPO(po);
    const balance = Math.max(0, po.total_cost - (po.paid_amount || 0));
    setPaymentAmount(balance);
    setPaymentReference('');
  };

  // Confirm Payment
  const handleConfirmPayment = () => {
    if (!payingPO) return;
    const currentPaid = payingPO.paid_amount || 0;
    const newPaidTotal = currentPaid + Number(paymentAmount);
    const isFullyPaid = newPaidTotal >= payingPO.total_cost;
    const status = isFullyPaid ? 'paid' : newPaidTotal > 0 ? 'partial' : 'unpaid';

    setPOs((prev) =>
      prev.map((p) =>
        p.id === payingPO.id
          ? {
              ...p,
              paid_amount: newPaidTotal,
              payment_status: status,
            }
          : p
      )
    );

    logAuditEvent({
      actor_id: 'admin-1',
      actor_name: 'المحاسب المالي',
      actor_role: 'accountant',
      action: 'SUPPLIER_PAYMENT',
      category: 'financial',
      details: `تسديد دفعة بقيمة ${paymentAmount.toLocaleString()} ل.س للمورد ${payingPO.supplier_name} عبر ${paymentMethod === 'sham_cash' ? 'شام كاش' : paymentMethod === 'cash' ? 'نقداً' : 'تحويل بنكي'}. المرجع: ${paymentReference || 'بدون'}`,
      target_id: payingPO.id,
    });

    setPayingPO(null);
  };

  // Approve Draft Product for customer application
  const handleApproveDraft = (prod: Product) => {
    if (!onUpdateProduct) return;
    onUpdateProduct({
      ...prod,
      is_draft: false,
      status: 'published',
    });
    logAuditEvent({
      actor_id: 'admin-1',
      actor_name: 'مدير العمليات التجارية',
      actor_role: 'catalog_manager',
      action: 'DRAFT_PRODUCT_APPROVED',
      category: 'inventory',
      details: `تم اعتماد ونشر الصنف المسودة (${prod.name_ar}) ليظهر رسمياً في تطبيق العملاء.`,
      target_id: prod.id,
    });
  };

  return (
    <div className="space-y-6">
      {/* Top Automated Stock Alert Banner */}
      {lowStockProducts.length > 0 && (
        <div className="bg-amber-50 border border-amber-200 rounded-2xl p-4 flex flex-col md:flex-row items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-amber-100 flex items-center justify-center shrink-0">
              <TrendingDown className="w-5 h-5 text-amber-700" />
            </div>
            <div>
              <h4 className="font-bold text-amber-900 text-sm">
                تنبيه تشغيلي: أصناف تقترب من حد الأمان الأدنى للمخزون ({lowStockProducts.length} أصناف)
              </h4>
              <p className="text-xs text-amber-700 mt-0.5">
                مثل: {lowStockProducts.map((p) => p.name_ar).slice(0, 3).join('، ')} بحاجة إلى طلب توريد فوري.
              </p>
            </div>
          </div>
          <button
            onClick={() => {
              setOrderItems(
                lowStockProducts.slice(0, 3).map((p) => ({
                  product_id: p.id,
                  name_ar: p.name_ar,
                  barcode: p.barcode,
                  quantity_ordered: 100,
                  quantity_received: 0,
                  unit_cost: p.cost_price || Math.round(p.price * 0.7),
                  total_cost: (p.cost_price || Math.round(p.price * 0.7)) * 100,
                }))
              );
              setShowNewPOModal(true);
            }}
            className="px-4 py-2 bg-amber-600 hover:bg-amber-700 text-white rounded-xl text-xs font-bold transition-colors shrink-0 shadow-sm flex items-center gap-1.5"
          >
            <Plus className="w-4 h-4" />
            توليد أمر توريد تلقائي (Auto-PO)
          </button>
        </div>
      )}

      {/* Tabs & Controls */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-3 border-b border-slate-200 pb-3">
        <div className="flex flex-wrap gap-2">
          <button
            onClick={() => setActiveTab('orders')}
            className={`px-4 py-2 rounded-xl text-xs font-bold transition-all ${
              activeTab === 'orders'
                ? 'bg-blue-600 text-white shadow-md shadow-blue-600/30'
                : 'bg-white text-slate-600 hover:bg-slate-100 border border-slate-200'
            }`}
          >
            أوامر الشراء والتوريد ({pos.length})
          </button>
          
          <button
            onClick={() => setActiveTab('drafts')}
            className={`px-4 py-2 rounded-xl text-xs font-bold transition-all flex items-center gap-1.5 ${
              activeTab === 'drafts'
                ? 'bg-indigo-600 text-white shadow-md shadow-indigo-600/30'
                : 'bg-white text-slate-600 hover:bg-slate-100 border border-slate-200'
            }`}
          >
            <Sparkles className="w-3.5 h-3.5" />
            <span>مسودات الأصناف قيد الاكتمال</span>
            {draftProducts.length > 0 && (
              <span className={`px-1.5 py-0.2 rounded-full text-[10px] font-extrabold ${activeTab === 'drafts' ? 'bg-white text-indigo-700' : 'bg-indigo-100 text-indigo-700'}`}>
                {draftProducts.length}
              </span>
            )}
          </button>

          <button
            onClick={() => setActiveTab('payables')}
            className={`px-4 py-2 rounded-xl text-xs font-bold transition-all flex items-center gap-1.5 ${
              activeTab === 'payables'
                ? 'bg-emerald-700 text-white shadow-md shadow-emerald-700/30'
                : 'bg-white text-slate-600 hover:bg-slate-100 border border-slate-200'
            }`}
          >
            <DollarSign className="w-3.5 h-3.5" />
            <span>تتبع المستحقات والسداد</span>
          </button>

          <button
            onClick={() => setActiveTab('suppliers')}
            className={`px-4 py-2 rounded-xl text-xs font-bold transition-all ${
              activeTab === 'suppliers'
                ? 'bg-blue-600 text-white shadow-md shadow-blue-600/30'
                : 'bg-white text-slate-600 hover:bg-slate-100 border border-slate-200'
            }`}
          >
            سجل الموردين المعتمدين ({suppliers.length})
          </button>
        </div>

        <button
          onClick={() => {
            setOrderItems([
              {
                product_id: products[0]?.id,
                name_ar: products[0]?.name_ar || 'صنف توريد',
                barcode: products[0]?.barcode,
                quantity_ordered: 100,
                quantity_received: 0,
                unit_cost: 20.0,
                total_cost: 2000.0,
              }
            ]);
            setShowNewPOModal(true);
          }}
          className="px-4 py-2 bg-slate-900 hover:bg-slate-800 text-white rounded-xl text-xs font-bold transition-colors flex items-center gap-1.5 shrink-0"
        >
          <Plus className="w-4 h-4" />
          إنشاء أمر شراء جديد
        </button>
      </div>

      {/* TAB 1: Purchase Orders List */}
      {activeTab === 'orders' && (
        <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-right text-xs">
              <thead className="bg-slate-50 border-b border-slate-200 text-slate-500 font-bold">
                <tr>
                  <th className="p-4">رقم الأمر</th>
                  <th className="p-4">المورد</th>
                  <th className="p-4">الأصناف والكميات</th>
                  <th className="p-4">التكلفة والمدفوع</th>
                  <th className="p-4">تاريخ الطلب والوصول</th>
                  <th className="p-4">حالة التوريد</th>
                  <th className="p-4">حالة السداد</th>
                  <th className="p-4 text-center">إجراءات المستودع والمالية</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {pos.map((po) => {
                  const paid = po.paid_amount || 0;
                  const balance = Math.max(0, po.total_cost - paid);
                  return (
                    <tr key={po.id} className="hover:bg-slate-50/60 transition-colors">
                      <td className="p-4 font-mono font-bold text-blue-600">{po.po_number}</td>
                      <td className="p-4 font-bold text-slate-800">{po.supplier_name}</td>
                      <td className="p-4">
                        <div className="font-bold text-slate-900">{po.total_items} قطعة</div>
                        <div className="text-[11px] text-slate-400">
                          {po.items ? `${po.items.length} أصناف فرعية` : 'تفاصيل توريد عامة'}
                        </div>
                      </td>
                      <td className="p-4">
                        <div className="font-mono font-bold text-slate-900">{po.total_cost.toLocaleString()} ل.س</div>
                        <div className="text-[11px] text-slate-500">
                          مسدد: <span className="font-mono text-emerald-700">{paid.toLocaleString()} ل.س</span>
                        </div>
                      </td>
                      <td className="p-4 text-slate-500">
                        <div>{po.order_date}</div>
                        <div className="text-[11px] font-semibold text-slate-700 mt-0.5">{po.expected_arrival}</div>
                      </td>
                      <td className="p-4">
                        {po.status === 'received' && (
                          <span className="inline-flex items-center gap-1 text-xs font-bold text-emerald-700 bg-emerald-100 px-2 py-0.5 rounded-full">
                            <CheckCircle2 className="w-3.5 h-3.5" />
                            مستلم بالكامل بالمستودع
                          </span>
                        )}
                        {po.status === 'partially_received' && (
                          <span className="inline-flex items-center gap-1 text-xs font-bold text-amber-700 bg-amber-100 px-2 py-0.5 rounded-full">
                            <PackageCheck className="w-3.5 h-3.5" />
                            مستلم جزئياً
                          </span>
                        )}
                        {po.status === 'sent' && (
                          <span className="inline-flex items-center gap-1 text-xs font-bold text-blue-700 bg-blue-100 px-2 py-0.5 rounded-full">
                            <Clock className="w-3.5 h-3.5" />
                            بانتظار وصول البضاعة
                          </span>
                        )}
                        {po.status === 'draft' && (
                          <span className="inline-flex items-center gap-1 text-xs font-bold text-slate-700 bg-slate-200 px-2 py-0.5 rounded-full">
                            مسودة داخلية
                          </span>
                        )}
                      </td>
                      <td className="p-4">
                        {po.payment_status === 'paid' && (
                          <span className="inline-flex items-center gap-1 text-xs font-bold text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded border border-emerald-200">
                            <Check className="w-3 h-3" />
                            مسدد بالكامل
                          </span>
                        )}
                        {po.payment_status === 'partial' && (
                          <span className="inline-flex items-center gap-1 text-xs font-bold text-amber-800 bg-amber-50 px-2 py-0.5 rounded border border-amber-200">
                            دفعة جزئية (متبقي {balance.toLocaleString()})
                          </span>
                        )}
                        {po.payment_status === 'unpaid' && (
                          <span className="inline-flex items-center gap-1 text-xs font-bold text-rose-700 bg-rose-50 px-2 py-0.5 rounded border border-rose-200">
                            مستحق غير مسدد
                          </span>
                        )}
                      </td>
                      <td className="p-4 text-center">
                        <div className="flex items-center justify-center gap-2">
                          {(po.status === 'sent' || po.status === 'partially_received') && (
                            <button
                              onClick={() => handleOpenReceivingModal(po)}
                              className="px-3 py-1.5 bg-emerald-600 hover:bg-emerald-700 text-white rounded-xl font-bold text-xs shadow-sm transition-colors flex items-center gap-1"
                            >
                              <PackageCheck className="w-3.5 h-3.5" />
                              استلام بالمستودع
                            </button>
                          )}
                          {po.payment_status !== 'paid' && (
                            <button
                              onClick={() => handleOpenPaymentModal(po)}
                              className="px-2.5 py-1.5 bg-slate-100 hover:bg-slate-200 text-slate-700 rounded-xl font-bold text-xs transition-colors flex items-center gap-1"
                              title="تسجيل دفعة سداد للمورد"
                            >
                              <CreditCard className="w-3.5 h-3.5 text-blue-600" />
                              سداد
                            </button>
                          )}
                          {po.status === 'received' && po.payment_status === 'paid' && (
                            <span className="text-slate-400 font-medium text-[11px] flex items-center gap-1">
                              <ShieldCheck className="w-3.5 h-3.5 text-emerald-600" />
                              مغلق ومسدد
                            </span>
                          )}
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* TAB 2: Drafts & Incomplete Products */}
      {activeTab === 'drafts' && (
        <div className="space-y-4">
          <div className="bg-indigo-50 border border-indigo-200 rounded-2xl p-4 flex items-start gap-3">
            <Sparkles className="w-5 h-5 text-indigo-600 shrink-0 mt-0.5" />
            <div>
              <h4 className="font-bold text-indigo-900 text-sm">
                نظام حماية تجربة العملاء: مسودات الأصناف قيد الاكتمال
              </h4>
              <p className="text-xs text-indigo-700 mt-1">
                أي منتج جديد يُضاف عبر فواتير الشراء والتوريد يتم قيده بدقة في التكاليف والمخزون وحساب المورد، ولكنه <strong>محجوب بنسبة 100% عن تطبيق العملاء</strong> كمسودة (`incomplete_data`) حتى يقوم مدير التسويق أو القسم بمراجعة الباركود، رفع الصور الحقيقية، والضغط على زر "اعتماد ونشر".
              </p>
            </div>
          </div>

          {draftProducts.length === 0 ? (
            <div className="bg-white rounded-2xl border border-slate-200 p-8 text-center text-slate-500">
              <CheckCircle2 className="w-8 h-8 text-emerald-500 mx-auto mb-2" />
              <p className="font-bold text-slate-700">لا توجد مسودات أصناف معلقة حالياً!</p>
              <p className="text-xs text-slate-400 mt-1">كافة الأصناف المسجلة في فواتير الشراء معتمدة ومنشورة للعملاء.</p>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {draftProducts.map((prod) => (
                <div key={prod.id} className="bg-white rounded-2xl border border-indigo-100 p-4 shadow-xs space-y-3">
                  <div className="flex items-start justify-between">
                    <div>
                      <span className="text-[10px] font-extrabold px-2 py-0.5 rounded-full bg-amber-100 text-amber-800">
                        مسودة - محجوب عن التطبيق
                      </span>
                      <h4 className="font-bold text-slate-900 text-sm mt-1">{prod.name_ar}</h4>
                      <p className="text-xs text-slate-400 font-mono">{prod.barcode || 'بدون باركود'}</p>
                    </div>
                    <div className="text-left">
                      <div className="text-xs font-mono font-bold text-slate-800">{prod.price.toFixed(2)} ل.س</div>
                      <div className="text-[10px] text-slate-400">التكلفة: {(prod.cost_price || 0).toFixed(2)} ل.س</div>
                    </div>
                  </div>

                  <div className="flex items-center justify-between text-xs bg-slate-50 p-2.5 rounded-xl border border-slate-100">
                    <span className="text-slate-600">الرصيد بالمستودع:</span>
                    <span className="font-bold text-slate-900">{prod.stock_quantity} {prod.unit}</span>
                  </div>

                  <button
                    onClick={() => handleApproveDraft(prod)}
                    className="w-full py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-xl text-xs font-bold transition-colors shadow-sm flex items-center justify-center gap-1.5"
                  >
                    <Check className="w-3.5 h-3.5" />
                    اعتماد ونشر الصنف لتطبيق العملاء
                  </button>
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {/* TAB 3: Payables & Debt Tracking */}
      {activeTab === 'payables' && (
        <div className="space-y-6">
          {/* Summary Cards */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-xs">
              <div className="text-slate-500 text-xs font-bold">إجمالي المشتريات والتوريدات</div>
              <div className="text-2xl font-black text-slate-900 font-mono mt-1">
                {totalPurchasesCost.toLocaleString()} ل.س
              </div>
              <div className="text-[11px] text-slate-400 mt-1">عبر كافة أوامر الشراء المسجلة</div>
            </div>

            <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-xs">
              <div className="text-slate-500 text-xs font-bold">إجمالي المبالغ المسددة للموردين</div>
              <div className="text-2xl font-black text-emerald-600 font-mono mt-1">
                {totalPaidCost.toLocaleString()} ل.س
              </div>
              <div className="text-[11px] text-emerald-700 mt-1">
                نسبة السداد: {totalPurchasesCost > 0 ? Math.round((totalPaidCost / totalPurchasesCost) * 100) : 0}%
              </div>
            </div>

            <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-xs">
              <div className="text-slate-500 text-xs font-bold">المستحقات المتبقية في الذمة للموردين</div>
              <div className="text-2xl font-black text-rose-600 font-mono mt-1">
                {totalOutstandingPayable.toLocaleString()} ل.س
              </div>
              <div className="text-[11px] text-rose-700 mt-1">واجبة الدفع وفق الجداول المتفق عليها</div>
            </div>
          </div>

          {/* Outstanding Bills Table */}
          <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
            <div className="p-4 border-b border-slate-200 bg-slate-50 font-bold text-slate-800 text-xs">
              جدول التوريدات والمستحقات قيد التسديد
            </div>
            <div className="overflow-x-auto">
              <table className="w-full text-right text-xs">
                <thead className="bg-slate-50 text-slate-500 font-bold">
                  <tr>
                    <th className="p-3">رقم الأمر</th>
                    <th className="p-3">المورد</th>
                    <th className="p-3">التكلفة الإجمالية</th>
                    <th className="p-3">المسدد حتى الآن</th>
                    <th className="p-3">المتبقي في الذمة</th>
                    <th className="p-3">الحالة</th>
                    <th className="p-3 text-center">الإجراء</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {pos.map((po) => {
                    const paid = po.paid_amount || 0;
                    const balance = Math.max(0, po.total_cost - paid);
                    return (
                      <tr key={po.id} className="hover:bg-slate-50/60">
                        <td className="p-3 font-mono font-bold text-blue-600">{po.po_number}</td>
                        <td className="p-3 font-bold text-slate-800">{po.supplier_name}</td>
                        <td className="p-3 font-mono font-bold">{po.total_cost.toLocaleString()} ل.س</td>
                        <td className="p-3 font-mono text-emerald-700 font-bold">{paid.toLocaleString()} ل.س</td>
                        <td className="p-3 font-mono font-bold text-rose-700">{balance.toLocaleString()} ل.س</td>
                        <td className="p-3">
                          {po.payment_status === 'paid' ? (
                            <span className="text-emerald-700 font-bold bg-emerald-50 px-2 py-0.5 rounded">مسدد بالكامل</span>
                          ) : (
                            <span className="text-rose-700 font-bold bg-rose-50 px-2 py-0.5 rounded">مستحق السداد</span>
                          )}
                        </td>
                        <td className="p-3 text-center">
                          {balance > 0 && (
                            <button
                              onClick={() => handleOpenPaymentModal(po)}
                              className="px-3 py-1 bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg text-xs font-bold transition-colors"
                            >
                              سداد دفعة
                            </button>
                          )}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

      {/* TAB 4: Suppliers List */}
      {activeTab === 'suppliers' && (
        <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
          {suppliers.map((sup) => (
            <div key={sup.id} className="bg-white rounded-2xl border border-slate-200 p-5 shadow-sm space-y-4">
              <div className="flex items-start justify-between">
                <div>
                  <h4 className="font-bold text-slate-900 text-sm">{sup.name_ar}</h4>
                  <p className="text-xs text-slate-400 font-mono mt-0.5">{sup.name_en}</p>
                </div>
                <span className="text-[11px] font-bold px-2 py-0.5 rounded bg-emerald-100 text-emerald-800">
                  معتمد نشط
                </span>
              </div>

              <div className="space-y-2 text-xs text-slate-600 bg-slate-50 p-3 rounded-xl border border-slate-100">
                <div className="flex items-center gap-2">
                  <Building2 className="w-3.5 h-3.5 text-blue-600" />
                  <span>المسؤول: {sup.contact_person}</span>
                </div>
                <div className="flex items-center gap-2">
                  <Phone className="w-3.5 h-3.5 text-blue-600" />
                  <span className="font-mono">{sup.phone}</span>
                </div>
                <div className="flex items-center gap-2">
                  <Mail className="w-3.5 h-3.5 text-blue-600" />
                  <span className="font-mono">{sup.email}</span>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-2 text-center text-xs">
                <div className="bg-slate-50 p-2 rounded-lg">
                  <div className="font-bold text-slate-800">{sup.lead_time_days} يوم</div>
                  <div className="text-slate-400 text-[10px]">زمن التوريد (Lead Time)</div>
                </div>
                <div className="bg-slate-50 p-2 rounded-lg">
                  <div className="font-bold text-slate-800">{sup.active_products_count}</div>
                  <div className="text-slate-400 text-[10px]">أصناف مسجلة</div>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* MODAL: Create New Purchase Order */}
      {showNewPOModal && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl max-w-2xl w-full p-6 shadow-2xl border border-slate-200 max-h-[90vh] overflow-y-auto">
            <h3 className="text-lg font-bold text-slate-900 mb-4 flex items-center gap-2">
              <FileText className="w-5 h-5 text-blue-600" />
              إصدار أمر شراء وتوريد جديد للمستودع
            </h3>

            <form onSubmit={handleCreatePO} className="space-y-4 text-xs">
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block font-bold text-slate-700 mb-1">المورد المعتمد</label>
                  <select
                    value={selectedSupplier}
                    onChange={(e) => setSelectedSupplier(e.target.value)}
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-300 rounded-xl text-xs font-bold"
                  >
                    {suppliers.map((s) => (
                      <option key={s.id} value={s.name_ar}>
                        {s.name_ar}
                      </option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="block font-bold text-slate-700 mb-1">موعد الوصول المتوقع</label>
                  <input
                    type="text"
                    value={expectedArrival}
                    onChange={(e) => setExpectedArrival(e.target.value)}
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-300 rounded-xl"
                  />
                </div>
              </div>

              {/* Items in PO */}
              <div>
                <div className="flex items-center justify-between mb-2">
                  <label className="font-bold text-slate-800">أصناف أمر الشراء ({orderItems.length})</label>
                  <div className="flex gap-2">
                    <button
                      type="button"
                      onClick={() => setShowAddDraftModal(true)}
                      className="px-2.5 py-1 bg-indigo-50 text-indigo-700 border border-indigo-200 rounded-lg font-bold text-[11px] hover:bg-indigo-100 flex items-center gap-1"
                    >
                      <Sparkles className="w-3 h-3 text-indigo-600" />
                      + إضافة صنف جديد كمسودة
                    </button>
                    <select
                      onChange={(e) => {
                        if (e.target.value) {
                          handleAddCatalogItemToPO(e.target.value);
                          e.target.value = '';
                        }
                      }}
                      className="px-2.5 py-1 bg-slate-100 border border-slate-200 rounded-lg font-bold text-[11px]"
                    >
                      <option value="">+ صنف من الكتالوج الحالي...</option>
                      {products.map((p) => (
                        <option key={p.id} value={p.id}>
                          {p.name_ar}
                        </option>
                      ))}
                    </select>
                  </div>
                </div>

                <div className="border border-slate-200 rounded-xl overflow-hidden">
                  <table className="w-full text-right text-[11px]">
                    <thead className="bg-slate-50 text-slate-500 font-bold">
                      <tr>
                        <th className="p-2.5">اسم الصنف</th>
                        <th className="p-2.5">الكمية المطلوبة</th>
                        <th className="p-2.5">سعر التكلفة للوحدة</th>
                        <th className="p-2.5">الإجمالي</th>
                        <th className="p-2.5 text-center">حذف</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100">
                      {orderItems.map((item, idx) => (
                        <tr key={idx}>
                          <td className="p-2.5 font-bold text-slate-800">
                            {item.name_ar}
                            {item.is_new_draft_product && (
                              <span className="mr-1.5 text-[9px] bg-indigo-100 text-indigo-700 px-1 py-0.5 rounded font-extrabold">
                                مسودة جديدة
                              </span>
                            )}
                          </td>
                          <td className="p-2.5">
                            <input
                              type="number"
                              min="1"
                              value={item.quantity_ordered}
                              onChange={(e) => {
                                const q = Number(e.target.value);
                                setOrderItems((prev) =>
                                  prev.map((it, i) => (i === idx ? { ...it, quantity_ordered: q, total_cost: q * it.unit_cost } : it))
                                );
                              }}
                              className="w-20 px-2 py-1 bg-slate-50 border border-slate-300 rounded font-mono"
                            />
                          </td>
                          <td className="p-2.5">
                            <input
                              type="number"
                              step="0.5"
                              value={item.unit_cost}
                              onChange={(e) => {
                                const c = Number(e.target.value);
                                setOrderItems((prev) =>
                                  prev.map((it, i) => (i === idx ? { ...it, unit_cost: c, total_cost: c * it.quantity_ordered } : it))
                                );
                              }}
                              className="w-20 px-2 py-1 bg-slate-50 border border-slate-300 rounded font-mono"
                            />
                          </td>
                          <td className="p-2.5 font-mono font-bold text-slate-900">
                            {item.total_cost.toLocaleString()} ل.س
                          </td>
                          <td className="p-2.5 text-center">
                            <button
                              type="button"
                              onClick={() => setOrderItems(orderItems.filter((_, i) => i !== idx))}
                              className="text-slate-400 hover:text-rose-600 p-1"
                            >
                              <X className="w-3.5 h-3.5" />
                            </button>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>

                <div className="flex justify-between items-center p-3 bg-slate-50 rounded-xl mt-2 font-bold">
                  <span>إجمالي تكلفة أمر الشراء:</span>
                  <span className="font-mono text-sm text-blue-700">
                    {orderItems.reduce((acc, i) => acc + i.total_cost, 0).toLocaleString()} ل.س
                  </span>
                </div>
              </div>

              <div>
                <label className="block font-bold text-slate-700 mb-1">ملاحظات وشروط التوريد</label>
                <input
                  type="text"
                  placeholder="مثال: مطابقة تاريخ الصلاحية لأكثر من 9 أشهر، التسليم على رصيف المستودع الرئيسي"
                  value={poNotes}
                  onChange={(e) => setPoNotes(e.target.value)}
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-300 rounded-xl"
                />
              </div>

              <div className="flex justify-end gap-2 pt-4 border-t border-slate-100">
                <button
                  type="button"
                  onClick={() => setShowNewPOModal(false)}
                  className="px-4 py-2 border border-slate-300 rounded-xl font-bold text-slate-600 hover:bg-slate-50"
                >
                  إلغاء
                </button>
                <button
                  type="submit"
                  disabled={orderItems.length === 0}
                  className="px-5 py-2 bg-blue-600 hover:bg-blue-700 disabled:opacity-50 text-white font-bold rounded-xl shadow-md shadow-blue-600/30 flex items-center gap-1.5"
                >
                  <Send className="w-3.5 h-3.5" />
                  إرسال أمر الشراء الآن
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* SUB-MODAL: Add Brand-New Draft Product inside PO */}
      {showAddDraftModal && (
        <div className="fixed inset-0 z-60 bg-black/70 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl max-w-md w-full p-6 shadow-2xl border border-indigo-200">
            <div className="flex items-center gap-2 mb-3">
              <Sparkles className="w-5 h-5 text-indigo-600" />
              <h4 className="font-bold text-slate-900 text-sm">إضافة منتج جديد كمسودة في أمر الشراء</h4>
            </div>
            <p className="text-[11px] text-slate-500 mb-4">
              سيتم قيد هذا الصنف في فاتورة الشراء وحساب المورد والمخزون، وسيظل <strong>محجوباً عن تطبيق العملاء</strong> حتى يتم اعتماد بياناته لاحقاً.
            </p>

            <form onSubmit={handleConfirmAddDraftItem} className="space-y-3 text-xs">
              <div>
                <label className="block font-bold text-slate-700 mb-1">اسم الصنف بالعربية *</label>
                <input
                  type="text"
                  required
                  placeholder="مثال: جبنة حلوم طازجة بلدي 400 غرام"
                  value={draftNameAr}
                  onChange={(e) => setDraftNameAr(e.target.value)}
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-300 rounded-xl"
                />
              </div>

              <div className="grid grid-cols-2 gap-2">
                <div>
                  <label className="block font-bold text-slate-700 mb-1">الباركود (إن وجد)</label>
                  <input
                    type="text"
                    placeholder="امسح أو اكتب الباركود"
                    value={draftBarcode}
                    onChange={(e) => setDraftBarcode(e.target.value)}
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-300 rounded-xl font-mono"
                  />
                </div>
                <div>
                  <label className="block font-bold text-slate-700 mb-1">الوحدة</label>
                  <select
                    value={draftUnit}
                    onChange={(e) => setDraftUnit(e.target.value)}
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-300 rounded-xl"
                  >
                    <option value="piece">قطعة (Piece)</option>
                    <option value="kg">كيلوغرام (kg)</option>
                    <option value="pack">علبة (Pack)</option>
                    <option value="carton">كرتون (Carton)</option>
                  </select>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-2">
                <div>
                  <label className="block font-bold text-slate-700 mb-1">سعر التكلفة (ل.س) *</label>
                  <input
                    type="number"
                    step="0.5"
                    required
                    value={draftCost}
                    onChange={(e) => setDraftCost(Number(e.target.value))}
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-300 rounded-xl font-mono"
                  />
                </div>
                <div>
                  <label className="block font-bold text-slate-700 mb-1">الكمية المطلوبة *</label>
                  <input
                    type="number"
                    min="1"
                    required
                    value={draftQty}
                    onChange={(e) => setDraftQty(Number(e.target.value))}
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-300 rounded-xl font-mono"
                  />
                </div>
              </div>

              <div className="flex justify-end gap-2 pt-3 border-t">
                <button
                  type="button"
                  onClick={() => setShowAddDraftModal(false)}
                  className="px-3 py-1.5 border border-slate-300 rounded-xl font-bold text-slate-600"
                >
                  إلغاء
                </button>
                <button
                  type="submit"
                  className="px-4 py-1.5 bg-indigo-600 hover:bg-indigo-700 text-white font-bold rounded-xl shadow-xs"
                >
                  إدراج في الفاتورة كمسودة
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* MODAL: Receiving Sheet (Partial / Full Receiving) */}
      {receivingPO && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl max-w-xl w-full p-6 shadow-2xl border border-slate-200 max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between mb-4">
              <div>
                <h3 className="text-lg font-bold text-slate-900 flex items-center gap-2">
                  <PackageCheck className="w-5 h-5 text-emerald-600" />
                  محضر استلام وتفريغ بضاعة المستودع
                </h3>
                <p className="text-xs text-slate-500 font-mono mt-0.5">
                  أمر الشراء: {receivingPO.po_number} • المورد: {receivingPO.supplier_name}
                </p>
              </div>
              <button
                type="button"
                onClick={handleReceiveAll}
                className="px-3 py-1.5 bg-emerald-50 text-emerald-700 hover:bg-emerald-100 border border-emerald-200 rounded-xl text-xs font-bold transition-colors"
              >
                استلام كامل لجميع الكميات
              </button>
            </div>

            <div className="space-y-3">
              <div className="border border-slate-200 rounded-xl overflow-hidden">
                <table className="w-full text-right text-xs">
                  <thead className="bg-slate-50 text-slate-500 font-bold">
                    <tr>
                      <th className="p-2.5">الصنف</th>
                      <th className="p-2.5 text-center">المطلوب</th>
                      <th className="p-2.5 text-center">المستلم سابقاً</th>
                      <th className="p-2.5 text-center">الكمية المستلمة الآن</th>
                      <th className="p-2.5 text-center">تالف/مرفوض</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100">
                    {(receivingPO.items || []).map((item, idx) => {
                      const entry = receivingItems[idx] || { qtyReceived: 0, damagedQty: 0 };
                      return (
                        <tr key={idx}>
                          <td className="p-2.5 font-bold text-slate-800">{item.name_ar}</td>
                          <td className="p-2.5 text-center font-bold">{item.quantity_ordered}</td>
                          <td className="p-2.5 text-center text-slate-500">{item.quantity_received}</td>
                          <td className="p-2.5 text-center">
                            <input
                              type="number"
                              min="0"
                              value={entry.qtyReceived}
                              onChange={(e) => {
                                const val = Number(e.target.value);
                                setReceivingItems((prev) => ({
                                  ...prev,
                                  [idx]: { ...entry, qtyReceived: val },
                                }));
                              }}
                              className="w-16 px-2 py-1 bg-emerald-50 border border-emerald-300 rounded font-bold font-mono text-center text-emerald-900"
                            />
                          </td>
                          <td className="p-2.5 text-center">
                            <input
                              type="number"
                              min="0"
                              value={entry.damagedQty}
                              onChange={(e) => {
                                const val = Number(e.target.value);
                                setReceivingItems((prev) => ({
                                  ...prev,
                                  [idx]: { ...entry, damagedQty: val },
                                }));
                              }}
                              className="w-14 px-2 py-1 bg-rose-50 border border-rose-300 rounded font-bold font-mono text-center text-rose-800"
                            />
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>

              <div className="bg-slate-50 p-3 rounded-xl text-xs text-slate-600 flex items-center gap-2">
                <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0" />
                <span>
                  عند تأكيد الاستلام، سيتم تحديث أرصدة المستودع الفعلية مباشرة وقيد الكميات الصالحة في رصيد المتجر.
                </span>
              </div>
            </div>

            <div className="flex justify-end gap-2 pt-4 border-t border-slate-100 mt-4">
              <button
                type="button"
                onClick={() => setReceivingPO(null)}
                className="px-4 py-2 border border-slate-300 rounded-xl font-bold text-slate-600 hover:bg-slate-50 text-xs"
              >
                إلغاء
              </button>
              <button
                type="button"
                onClick={handleConfirmReceiving}
                className="px-5 py-2 bg-emerald-600 hover:bg-emerald-700 text-white font-bold rounded-xl shadow-md shadow-emerald-600/30 text-xs flex items-center gap-1.5"
              >
                <Check className="w-4 h-4" />
                تأكيد الاستلام وقيد الرصيد
              </button>
            </div>
          </div>
        </div>
      )}

      {/* MODAL: Record Supplier Payment */}
      {payingPO && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl max-w-md w-full p-6 shadow-2xl border border-slate-200">
            <h3 className="text-lg font-bold text-slate-900 mb-3 flex items-center gap-2">
              <CreditCard className="w-5 h-5 text-blue-600" />
              تسجيل دفعة سداد للمورد
            </h3>
            <p className="text-xs text-slate-500 font-mono mb-4">
              فاتورة: {payingPO.po_number} • المورد: {payingPO.supplier_name}
            </p>

            <div className="space-y-3 text-xs">
              <div className="p-3 bg-slate-50 rounded-xl space-y-1">
                <div className="flex justify-between">
                  <span className="text-slate-500">إجمالي الفاتورة:</span>
                  <span className="font-bold font-mono">{payingPO.total_cost.toLocaleString()} ل.س</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-500">المسدد سابقاً:</span>
                  <span className="font-bold font-mono text-emerald-700">
                    {(payingPO.paid_amount || 0).toLocaleString()} ل.س
                  </span>
                </div>
                <div className="flex justify-between border-t pt-1 font-bold">
                  <span className="text-slate-800">المتبقي المطلوب:</span>
                  <span className="font-mono text-rose-700">
                    {Math.max(0, payingPO.total_cost - (payingPO.paid_amount || 0)).toLocaleString()} ل.س
                  </span>
                </div>
              </div>

              <div>
                <label className="block font-bold text-slate-700 mb-1">مبلغ الدفعة المسددة (ل.س) *</label>
                <input
                  type="number"
                  required
                  value={paymentAmount}
                  onChange={(e) => setPaymentAmount(Number(e.target.value))}
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-300 rounded-xl font-mono text-sm font-bold text-emerald-800"
                />
              </div>

              <div>
                <label className="block font-bold text-slate-700 mb-1">طريقة السداد المعتمدة</label>
                <select
                  value={paymentMethod}
                  onChange={(e) => setPaymentMethod(e.target.value as any)}
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-300 rounded-xl font-bold"
                >
                  <option value="sham_cash">شام كاش (Sham Cash)</option>
                  <option value="cash">نقداً من الصندوق (Cash)</option>
                  <option value="bank_transfer">تحويل بنكي / شركة حوالات</option>
                </select>
              </div>

              <div>
                <label className="block font-bold text-slate-700 mb-1">رقم مرجع التحويل أو سند الصرف</label>
                <input
                  type="text"
                  placeholder="مثال: SHAM-TRX-984321 أو سند رقم 402"
                  value={paymentReference}
                  onChange={(e) => setPaymentReference(e.target.value)}
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-300 rounded-xl font-mono"
                />
              </div>

              <div className="flex justify-end gap-2 pt-4 border-t border-slate-100">
                <button
                  type="button"
                  onClick={() => setPayingPO(null)}
                  className="px-4 py-2 border border-slate-300 rounded-xl font-bold text-slate-600 hover:bg-slate-50"
                >
                  إلغاء
                </button>
                <button
                  type="button"
                  onClick={handleConfirmPayment}
                  disabled={paymentAmount <= 0}
                  className="px-5 py-2 bg-emerald-600 hover:bg-emerald-700 disabled:opacity-50 text-white font-bold rounded-xl shadow-md shadow-emerald-600/30 flex items-center gap-1.5"
                >
                  <Check className="w-3.5 h-3.5" />
                  اعتماد قيد السداد
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
