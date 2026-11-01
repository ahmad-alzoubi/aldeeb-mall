import React, { useState } from 'react';
import { 
  ArrowLeftRight, 
  Building, 
  Boxes, 
  CheckCircle2, 
  AlertTriangle, 
  Truck, 
  Clock, 
  Package, 
  Barcode, 
  Plus, 
  Sparkles,
  Search,
  Check,
  X,
  ShieldCheck,
  Lock,
  RotateCcw,
  AlertOctagon,
  FileText,
  ArrowRight,
  Filter,
  Layers
} from 'lucide-react';
import { DarkStore, Product, TransferOrder, TransferStatus, WarehouseItemStock, InventoryMovementLog } from '../types';
import { logAuditEvent } from '../lib/auditLogger';

interface InventoryTransferPageProps {
  darkStores: DarkStore[];
  products: Product[];
}

export const InventoryTransferPage: React.FC<InventoryTransferPageProps> = ({
  darkStores,
  products,
}) => {
  const [activeTab, setActiveTab] = useState<'transfers' | 'stock' | 'movement_logs'>('transfers');
  const [selectedWarehouseFilter, setSelectedWarehouseFilter] = useState<string>('all');
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [toastMessage, setToastMessage] = useState<string | null>(null);

  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(null), 4000);
  };

  // 1. Initial State: Multi-warehouse stocks (Available / Reserved / Damaged)
  const [stockRecords, setStockRecords] = useState<WarehouseItemStock[]>(() => {
    const list: WarehouseItemStock[] = [];
    darkStores.forEach((wh, whIdx) => {
      products.slice(0, 10).forEach((p, pIdx) => {
        const baseQty = p.stock_quantity > 0 ? Math.floor(p.stock_quantity / Math.max(darkStores.length, 1)) : 80;
        list.push({
          id: `stk-${wh.id}-${p.id}`,
          warehouse_id: wh.id,
          product_id: p.id,
          product_name_ar: p.name_ar,
          barcode: p.barcode || `629100${whIdx}${pIdx}0`,
          available_stock: Math.max(10, baseQty - 15),
          reserved_stock: 10 + (pIdx % 5),
          damaged_stock: pIdx % 4 === 0 ? 2 : 0,
          bin_location: `رف-${String.fromCharCode(65 + (pIdx % 6))}-${(whIdx + 1) * 10 + (pIdx % 8)}`,
          last_updated: 'اليوم، 09:30 ص',
        });
      });
    });
    return list;
  });

  // 2. Initial State: Movement Logs
  const [movementLogs, setMovementLogs] = useState<InventoryMovementLog[]>([
    {
      id: 'mov-1',
      timestamp: '2026-11-01 08:30:15',
      warehouse_id: darkStores[0]?.id || 'wh-central',
      product_id: products[0]?.id || 'p-1',
      barcode: products[0]?.barcode || '6291001001',
      type: 'inbound_po',
      quantity_change: +100,
      resulting_available: 185,
      reference_id: 'PO-2026-104',
      notes: 'استلام وتفريغ أمر شراء مورد معتمد',
      performed_by: 'أمين المستودع المركزي',
    },
    {
      id: 'mov-2',
      timestamp: '2026-11-01 09:15:00',
      warehouse_id: darkStores[0]?.id || 'wh-central',
      product_id: products[1]?.id || 'p-2',
      barcode: products[1]?.barcode || '6291001002',
      type: 'transfer_out',
      quantity_change: -40,
      resulting_available: 95,
      reference_id: 'TRF-2026-901',
      notes: 'مناقلة شحنة مبردة إلى مركز توزيع درعا المدينة',
      performed_by: 'مسؤول الشحن والترحيل',
    },
    {
      id: 'mov-3',
      timestamp: '2026-11-01 09:40:22',
      warehouse_id: darkStores[1]?.id || 'ds-daraa-city',
      product_id: products[1]?.id || 'p-2',
      barcode: products[1]?.barcode || '6291001002',
      type: 'transfer_in',
      quantity_change: +40,
      resulting_available: 65,
      reference_id: 'TRF-2026-901',
      notes: 'استلام شحنة مناقلة واردة وإيداعها في رف التوزيع A-12',
      performed_by: 'مستلم مركز المدينة',
    },
  ]);

  // 3. Initial State: 7-Stage Transfers
  const [transfers, setTransfers] = useState<TransferOrder[]>([
    {
      id: 'tr-1',
      manifest_number: 'TRF-2026-904',
      source_warehouse_id: darkStores[0]?.id || 'wh-central',
      source_warehouse_name: darkStores[0]?.name_ar || 'المستودع اللوجستي المركزي الرئيسي (درعا)',
      destination_warehouse_id: darkStores[1]?.id || 'ds-daraa-city',
      destination_warehouse_name: darkStores[1]?.name_ar || 'مركز تجهيز وتوزيع درعا المدينة (المحطة والبلد)',
      sku: 'ALM-MILK-2L',
      barcode: products[0]?.barcode || '6291001001',
      product_id: products[0]?.id || 'p-1',
      product_name_ar: products[0]?.name_ar || 'حليب المراعي كامل الدسم 2 لتر',
      quantity_requested: 120,
      quantity_dispatched: 120,
      quantity_received: 0,
      quantity_damaged: 0,
      status: 'dispatched',
      assigned_driver: 'سامر المقداد (شاحنة مبردة رقم 14)',
      requested_at: 'اليوم، 07:45 ص',
      dispatched_at: 'اليوم، 08:30 ص',
    },
    {
      id: 'tr-2',
      manifest_number: 'TRF-2026-903',
      source_warehouse_id: darkStores[0]?.id || 'wh-central',
      source_warehouse_name: darkStores[0]?.name_ar || 'المستودع اللوجستي المركزي الرئيسي (درعا)',
      destination_warehouse_id: darkStores[2]?.id || 'ds-daraa-west',
      destination_warehouse_name: darkStores[2]?.name_ar || 'مركز توزيع ريف درعا الغربي (طفس ونوى)',
      sku: 'EGG-ORG-30',
      barcode: products[1]?.barcode || '6291001002',
      product_id: products[1]?.id || 'p-2',
      product_name_ar: products[1]?.name_ar || 'طبق بيض عضوي بلدي 30 حبة',
      quantity_requested: 60,
      quantity_dispatched: 0,
      quantity_received: 0,
      quantity_damaged: 0,
      status: 'under_review',
      requested_at: 'اليوم، 08:15 ص',
    },
    {
      id: 'tr-3',
      manifest_number: 'TRF-2026-901',
      source_warehouse_id: darkStores[0]?.id || 'wh-central',
      source_warehouse_name: darkStores[0]?.name_ar || 'المستودع اللوجستي المركزي الرئيسي (درعا)',
      destination_warehouse_id: darkStores[1]?.id || 'ds-daraa-city',
      destination_warehouse_name: darkStores[1]?.name_ar || 'مركز تجهيز وتوزيع درعا المدينة (المحطة والبلد)',
      sku: 'TOM-VINE-KG',
      barcode: products[2]?.barcode || '6291001003',
      product_id: products[2]?.id || 'p-3',
      product_name_ar: products[2]?.name_ar || 'طماطم مزارع عنقودية طازجة (كغم)',
      quantity_requested: 50,
      quantity_dispatched: 50,
      quantity_received: 48,
      quantity_damaged: 2,
      discrepancy_reason: 'تلف كرتونتين أثناء المطبات في النقل',
      status: 'closed',
      assigned_driver: 'محمد الزعبي (فان مبرد #08)',
      requested_at: 'أمس، 05:00 م',
      dispatched_at: 'أمس، 05:40 م',
      received_at: 'أمس، 06:30 م',
      audit_locked: true,
    },
  ]);

  // Modal States
  const [showNewTransferModal, setShowNewTransferModal] = useState<boolean>(false);
  const [newSourceWh, setNewSourceWh] = useState<string>(darkStores[0]?.id || '');
  const [newDestWh, setNewDestWh] = useState<string>(darkStores[1]?.id || '');
  const [newProductId, setNewProductId] = useState<string>(products[0]?.id || '');
  const [newQty, setNewQty] = useState<number>(50);

  // Match / Discrepancy Inspection Modal
  const [inspectingTransfer, setInspectingTransfer] = useState<TransferOrder | null>(null);
  const [matchGoodQty, setMatchGoodQty] = useState<number>(0);
  const [matchDamagedQty, setMatchDamagedQty] = useState<number>(0);
  const [discrepancyReason, setDiscrepancyReason] = useState<string>('');

  // Barcode quick lookup in stock tab
  const [barcodeSearch, setBarcodeSearch] = useState<string>('');
  const [scannedResult, setScannedResult] = useState<WarehouseItemStock | null>(null);

  // Adjust stock / record damage modal
  const [adjustingStock, setAdjustingStock] = useState<WarehouseItemStock | null>(null);
  const [adjustDamageCount, setAdjustDamageCount] = useState<number>(1);
  const [adjustReason, setAdjustReason] = useState<string>('انتهاء صلاحية أو كسر في الرف');

  // Create new transfer request (Phase 1: requested)
  const handleCreateTransferRequest = (e: React.FormEvent) => {
    e.preventDefault();
    if (newSourceWh === newDestWh) {
      alert('لا يمكن إجراء مناقلة بين نفس المستودع!');
      return;
    }

    const srcWh = darkStores.find((w) => w.id === newSourceWh);
    const destWh = darkStores.find((w) => w.id === newDestWh);
    const prod = products.find((p) => p.id === newProductId);

    if (!srcWh || !destWh || !prod) return;

    const newTransfer: TransferOrder = {
      id: `tr-${Date.now()}`,
      manifest_number: `TRF-2026-${Math.floor(100 + Math.random() * 900)}`,
      source_warehouse_id: srcWh.id,
      source_warehouse_name: srcWh.name_ar,
      destination_warehouse_id: destWh.id,
      destination_warehouse_name: destWh.name_ar,
      sku: prod.barcode || `SKU-${Date.now()}`,
      barcode: prod.barcode,
      product_id: prod.id,
      product_name_ar: prod.name_ar,
      quantity_requested: Number(newQty),
      quantity_dispatched: 0,
      quantity_received: 0,
      quantity_damaged: 0,
      status: 'requested',
      requested_at: 'الآن',
    };

    setTransfers((prev) => [newTransfer, ...prev]);

    logAuditEvent({
      actor_id: 'admin-1',
      actor_name: 'أمين المستودع',
      actor_role: 'warehouse_officer',
      action: 'TRANSFER_REQUESTED',
      category: 'inventory',
      details: `طلب مناقلة صادر ${newTransfer.manifest_number}: ${prod.name_ar} (كمية ${newQty}) من ${srcWh.name_ar} إلى ${destWh.name_ar}`,
      target_id: newTransfer.id,
    });

    showToast(`✓ تم إنشاء طلب المناقلة ${newTransfer.manifest_number} وهو بانتظار المراجعة الفنية.`);
    setShowNewTransferModal(false);
  };

  // Move status across the 7-step cycle
  const handleAdvanceStatus = (transfer: TransferOrder, targetStatus: TransferStatus) => {
    if (transfer.audit_locked) {
      alert('هذا السجل مغلق ومقفل نهائياً في سجلات التدقيق لمنع ازدواجية القيد!');
      return;
    }

    // Phase 2: Review -> Approved
    if (targetStatus === 'approved') {
      setTransfers((prev) =>
        prev.map((t) => (t.id === transfer.id ? { ...t, status: 'approved' } : t))
      );
      showToast(`✓ تم اعتماد طلب المناقلة ${transfer.manifest_number} وتجهيز البضاعة للشحن.`);
      logAuditEvent({
        actor_id: 'admin-1',
        actor_name: 'مدير المستودعات',
        actor_role: 'warehouse_manager',
        action: 'TRANSFER_APPROVED',
        category: 'inventory',
        details: `اعتماد المناقلة ${transfer.manifest_number} لصنف ${transfer.product_name_ar} (${transfer.quantity_requested} قطعة)`,
        target_id: transfer.id,
      });
      return;
    }

    // Phase 3: Approved -> Dispatched
    if (targetStatus === 'dispatched') {
      const driver = 'كابتن النقل اللوجستي (شاحنة تبريد رقم 21)';
      setTransfers((prev) =>
        prev.map((t) =>
          t.id === transfer.id
            ? {
                ...t,
                status: 'dispatched',
                quantity_dispatched: t.quantity_requested,
                assigned_driver: driver,
                dispatched_at: 'الآن',
              }
            : t
        )
      );

      // Deduct from source warehouse available stock
      setStockRecords((prev) =>
        prev.map((stk) =>
          stk.warehouse_id === transfer.source_warehouse_id && stk.product_id === transfer.product_id
            ? { ...stk, available_stock: Math.max(0, stk.available_stock - transfer.quantity_requested) }
            : stk
        )
      );

      // Add movement log
      setMovementLogs((prev) => [
        {
          id: `mov-${Date.now()}`,
          timestamp: new Date().toISOString().replace('T', ' ').substring(0, 19),
          warehouse_id: transfer.source_warehouse_id,
          product_id: transfer.product_id || '',
          barcode: transfer.barcode || '',
          type: 'transfer_out',
          quantity_change: -transfer.quantity_requested,
          resulting_available: 0,
          reference_id: transfer.manifest_number,
          notes: `شحن مناقلة إلى ${transfer.destination_warehouse_name}`,
          performed_by: 'مسؤول الشحن والترحيل',
        },
        ...prev,
      ]);

      showToast(`🚚 تم إرسال الشحنة ${transfer.manifest_number} وتحديث نظام النقل المبرد.`);
      return;
    }

    // Phase 4: Dispatched -> Received (Initial physical arrival)
    if (targetStatus === 'received') {
      setTransfers((prev) =>
        prev.map((t) =>
          t.id === transfer.id
            ? {
                ...t,
                status: 'received',
                received_at: 'الآن',
              }
            : t
        )
      );
      showToast(`📦 وصلت الشحنة ${transfer.manifest_number} إلى رصيف الاستلام، يرجى إجراء المطابقة.`);
      return;
    }
  };

  // Phase 5 & 6 & 7: Matching and Closing with Discrepancy & Damaged Handling
  const handleOpenMatchingModal = (transfer: TransferOrder) => {
    setInspectingTransfer(transfer);
    setMatchGoodQty(transfer.quantity_dispatched);
    setMatchDamagedQty(0);
    setDiscrepancyReason('');
  };

  const handleConfirmMatchAndClose = () => {
    if (!inspectingTransfer) return;
    if (inspectingTransfer.audit_locked) return;

    const good = Number(matchGoodQty) || 0;
    const damaged = Number(matchDamagedQty) || 0;
    const dispatched = inspectingTransfer.quantity_dispatched;

    if (good + damaged !== dispatched && !discrepancyReason.trim()) {
      alert('يوجد نقص في إجمالي الكميات المستلمة مقارنة بالمنفيست! يجب كتابة سبب النقص في حقل الملاحظات.');
      return;
    }

    // 1. Update transfer record to CLOSED and lock it against double-counting
    setTransfers((prev) =>
      prev.map((t) =>
        t.id === inspectingTransfer.id
          ? {
              ...t,
              quantity_received: good,
              quantity_damaged: damaged,
              discrepancy_reason: discrepancyReason.trim() || undefined,
              status: 'closed',
              audit_locked: true,
            }
          : t
      )
    );

    // 2. Safely add good quantity to destination warehouse stock
    setStockRecords((prev) => {
      const match = prev.find(
        (stk) =>
          stk.warehouse_id === inspectingTransfer.destination_warehouse_id &&
          stk.product_id === inspectingTransfer.product_id
      );

      if (match) {
        return prev.map((stk) =>
          stk.id === match.id
            ? {
                ...stk,
                available_stock: stk.available_stock + good,
                damaged_stock: stk.damaged_stock + damaged,
                last_updated: 'الآن',
              }
            : stk
        );
      } else {
        // If product was never in this warehouse before, add it
        return [
          ...prev,
          {
            id: `stk-${inspectingTransfer.destination_warehouse_id}-${inspectingTransfer.product_id}`,
            warehouse_id: inspectingTransfer.destination_warehouse_id,
            product_id: inspectingTransfer.product_id || '',
            product_name_ar: inspectingTransfer.product_name_ar,
            barcode: inspectingTransfer.barcode || '629100000000',
            available_stock: good,
            reserved_stock: 0,
            damaged_stock: damaged,
            bin_location: 'رف-جديد-01',
            last_updated: 'الآن',
          },
        ];
      }
    });

    // 3. Record Audit Log for incoming stock
    setMovementLogs((prev) => [
      {
        id: `mov-${Date.now()}`,
        timestamp: new Date().toISOString().replace('T', ' ').substring(0, 19),
        warehouse_id: inspectingTransfer.destination_warehouse_id,
        product_id: inspectingTransfer.product_id || '',
        barcode: inspectingTransfer.barcode || '',
        type: 'transfer_in',
        quantity_change: +good,
        resulting_available: good,
        reference_id: inspectingTransfer.manifest_number,
        notes: `مطابقة وإغلاق مناقلة: ${good} سليم، ${damaged} تالف. السبب: ${discrepancyReason || 'مطابق تماماً'}`,
        performed_by: 'أمين مستودع الاستلام والمطابقة',
      },
      ...prev,
    ]);

    logAuditEvent({
      actor_id: 'admin-1',
      actor_name: 'أمين مستودع الاستلام',
      actor_role: 'receiving_officer',
      action: 'TRANSFER_CLOSED_MATCHED',
      category: 'inventory',
      details: `إغلاق ومطابقة مناقلة ${inspectingTransfer.manifest_number}: استلام ${good} سليم و ${damaged} تالف وقفل السجل نهائياً.`,
      target_id: inspectingTransfer.id,
    });

    showToast(`✓ تمت المطابقة بنجاح وإيداع ${good} قطعة في الرصيد وإغلاق المنفيست نهائياً ومنع ازدواجية القيد.`);
    setInspectingTransfer(null);
  };

  // Barcode Scanner in Stock Tab
  const handleBarcodeSearch = (e: React.FormEvent) => {
    e.preventDefault();
    if (!barcodeSearch.trim()) return;
    const found = stockRecords.find(
      (stk) =>
        stk.barcode === barcodeSearch.trim() ||
        stk.product_name_ar.toLowerCase().includes(barcodeSearch.toLowerCase())
    );
    if (found) {
      setScannedResult(found);
    } else {
      setScannedResult(null);
      showToast(`لم يتم العثور على أي صنف بالباركود أو الاسم: ${barcodeSearch}`);
    }
  };

  // Record Damage on item in stock
  const handleConfirmDamageAdjustment = () => {
    if (!adjustingStock) return;
    const count = Number(adjustDamageCount);
    if (count <= 0 || count > adjustingStock.available_stock) {
      alert('الكمية التالفة يجب أن تكون أكبر من 0 ولا تتجاوز الرصيد المتوفر!');
      return;
    }

    setStockRecords((prev) =>
      prev.map((s) =>
        s.id === adjustingStock.id
          ? {
              ...s,
              available_stock: s.available_stock - count,
              damaged_stock: s.damaged_stock + count,
              last_updated: 'الآن',
            }
          : s
      )
    );

    setMovementLogs((prev) => [
      {
        id: `mov-${Date.now()}`,
        timestamp: new Date().toISOString().replace('T', ' ').substring(0, 19),
        warehouse_id: adjustingStock.warehouse_id,
        product_id: adjustingStock.product_id,
        barcode: adjustingStock.barcode,
        type: 'damaged',
        quantity_change: -count,
        resulting_available: adjustingStock.available_stock - count,
        reference_id: `DMG-${Date.now().toString().slice(-4)}`,
        notes: `قيد تلف بالمستودع: ${adjustReason}`,
        performed_by: 'لجنة جرد المستودع',
      },
      ...prev,
    ]);

    logAuditEvent({
      actor_id: 'admin-1',
      actor_name: 'لجنة الجرد',
      actor_role: 'inventory_auditor',
      action: 'STOCK_DAMAGE_RECORDED',
      category: 'inventory',
      details: `تسجيل تلف ${count} قطعة للصنف (${adjustingStock.product_name_ar}) في المستودع. السبب: ${adjustReason}`,
      target_id: adjustingStock.id,
    });

    showToast(`✓ تم قيد ${count} قطعة في رصيد التالف وخصمها من الرصيد الصالح للبيع.`);
    setAdjustingStock(null);
  };

  // Filter transfers
  const filteredTransfers = transfers.filter((t) => {
    const matchWh =
      selectedWarehouseFilter === 'all' ||
      t.source_warehouse_id === selectedWarehouseFilter ||
      t.destination_warehouse_id === selectedWarehouseFilter;
    const matchSearch =
      t.manifest_number.toLowerCase().includes(searchQuery.toLowerCase()) ||
      t.product_name_ar.toLowerCase().includes(searchQuery.toLowerCase()) ||
      (t.assigned_driver?.toLowerCase().includes(searchQuery.toLowerCase()) ?? false);
    return matchWh && matchSearch;
  });

  // Filter stock
  const filteredStock = stockRecords.filter((s) => {
    const matchWh = selectedWarehouseFilter === 'all' || s.warehouse_id === selectedWarehouseFilter;
    const matchSearch =
      s.product_name_ar.toLowerCase().includes(searchQuery.toLowerCase()) ||
      s.barcode.includes(searchQuery) ||
      s.bin_location.toLowerCase().includes(searchQuery.toLowerCase());
    return matchWh && matchSearch;
  });

  // Stage Badge Renderer
  const renderStatusBadge = (status: TransferStatus) => {
    switch (status) {
      case 'requested':
        return <span className="px-2 py-0.5 rounded-full text-[11px] font-bold bg-slate-100 text-slate-700">1. طلب مناقلة جديد</span>;
      case 'under_review':
        return <span className="px-2 py-0.5 rounded-full text-[11px] font-bold bg-amber-100 text-amber-800">2. قيد المراجعة الفنية</span>;
      case 'approved':
        return <span className="px-2 py-0.5 rounded-full text-[11px] font-bold bg-blue-100 text-blue-800">3. معتمد للشحن</span>;
      case 'dispatched':
        return <span className="px-2 py-0.5 rounded-full text-[11px] font-bold bg-purple-100 text-purple-800 flex items-center gap-1"><Truck className="w-3 h-3" /> 4. قيد النقل والشحن</span>;
      case 'received':
        return <span className="px-2 py-0.5 rounded-full text-[11px] font-bold bg-teal-100 text-teal-800">5. واصل للرصيف</span>;
      case 'matched':
        return <span className="px-2 py-0.5 rounded-full text-[11px] font-bold bg-emerald-100 text-emerald-800">6. تم فحص المطابقة</span>;
      case 'closed':
        return (
          <span className="px-2 py-0.5 rounded-full text-[11px] font-bold bg-emerald-50 text-emerald-700 border border-emerald-200 flex items-center gap-1">
            <Lock className="w-3 h-3 text-emerald-600" />
            7. مغلق ومقفل بالمخزون
          </span>
        );
    }
  };

  return (
    <div className="space-y-6">
      {/* Toast Alert */}
      {toastMessage && (
        <div className="bg-slate-900 text-white px-5 py-3 rounded-2xl shadow-xl flex items-center gap-3 animate-fade-in text-xs font-bold border border-slate-700">
          <CheckCircle2 className="w-4 h-4 text-emerald-400 shrink-0" />
          <span>{toastMessage}</span>
        </div>
      )}

      {/* Top Warehouse Overview Bar */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        {darkStores.map((wh) => {
          const isFilterActive = selectedWarehouseFilter === wh.id;
          const whStockCount = stockRecords.filter((s) => s.warehouse_id === wh.id).reduce((a, b) => a + b.available_stock, 0);
          return (
            <div
              key={wh.id}
              onClick={() => setSelectedWarehouseFilter(isFilterActive ? 'all' : wh.id)}
              className={`p-4 rounded-2xl border cursor-pointer transition-all ${
                isFilterActive
                  ? 'bg-blue-900 text-white border-blue-900 shadow-lg ring-2 ring-blue-500/50'
                  : 'bg-white text-slate-800 border-slate-200 hover:border-blue-300'
              }`}
            >
              <div className="flex items-center justify-between mb-2">
                <span className={`text-[11px] px-2 py-0.5 rounded-md font-mono font-bold ${
                  isFilterActive ? 'bg-blue-800 text-blue-200' : 'bg-slate-100 text-slate-600'
                }`}>
                  {wh.code}
                </span>
                <span className={`text-xs font-bold ${isFilterActive ? 'text-emerald-300' : 'text-emerald-600'}`}>
                  مستودع مستقل نشط
                </span>
              </div>
              <h4 className="font-bold text-sm leading-tight">{wh.name_ar}</h4>
              <p className={`text-xs mt-1 ${isFilterActive ? 'text-blue-200' : 'text-slate-400'}`}>{wh.city}</p>

              <div className="mt-3 pt-3 border-t border-slate-100/20 flex justify-between text-xs">
                <span className={isFilterActive ? 'text-blue-200' : 'text-slate-500'}>الرصيد الصالح المتوفر:</span>
                <span className="font-mono font-black">{whStockCount.toLocaleString()} قطعة</span>
              </div>
            </div>
          );
        })}
      </div>

      {/* Tabs and Actions */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-3 border-b border-slate-200 pb-3">
        <div className="flex flex-wrap gap-2">
          <button
            onClick={() => setActiveTab('transfers')}
            className={`px-4 py-2 rounded-xl text-xs font-bold transition-all flex items-center gap-1.5 ${
              activeTab === 'transfers'
                ? 'bg-blue-600 text-white shadow-md shadow-blue-600/30'
                : 'bg-white text-slate-600 hover:bg-slate-100 border border-slate-200'
            }`}
          >
            <ArrowLeftRight className="w-3.5 h-3.5" />
            <span>مناقلات المستودعات (دورة الـ 7 مراحل)</span>
            <span className={`px-1.5 py-0.2 rounded-full text-[10px] ${activeTab === 'transfers' ? 'bg-white text-blue-700' : 'bg-slate-100 text-slate-600'}`}>
              {transfers.length}
            </span>
          </button>

          <button
            onClick={() => setActiveTab('stock')}
            className={`px-4 py-2 rounded-xl text-xs font-bold transition-all flex items-center gap-1.5 ${
              activeTab === 'stock'
                ? 'bg-indigo-600 text-white shadow-md shadow-indigo-600/30'
                : 'bg-white text-slate-600 hover:bg-slate-100 border border-slate-200'
            }`}
          >
            <Boxes className="w-3.5 h-3.5" />
            <span>أرصدة المستودعات المستقلة (متوفر / محجوز / تالف)</span>
          </button>

          <button
            onClick={() => setActiveTab('movement_logs')}
            className={`px-4 py-2 rounded-xl text-xs font-bold transition-all flex items-center gap-1.5 ${
              activeTab === 'movement_logs'
                ? 'bg-slate-900 text-white shadow-md'
                : 'bg-white text-slate-600 hover:bg-slate-100 border border-slate-200'
            }`}
          >
            <FileText className="w-3.5 h-3.5" />
            <span>سجل حركة الأصناف والتدقيق اللوجستي</span>
          </button>
        </div>

        <div className="flex gap-2 w-full sm:w-auto">
          <div className="relative flex-1 sm:w-56">
            <input
              type="text"
              placeholder="بحث بالرقم أو الصنف..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pr-8 pl-3 py-1.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-medium focus:outline-none focus:border-blue-600"
            />
            <Search className="w-3.5 h-3.5 text-slate-400 absolute right-2.5 top-2.5" />
          </div>

          <button
            onClick={() => setShowNewTransferModal(true)}
            className="px-3.5 py-1.5 bg-blue-600 hover:bg-blue-700 text-white rounded-xl text-xs font-bold transition-colors flex items-center gap-1 shrink-0 shadow-sm"
          >
            <Plus className="w-3.5 h-3.5" />
            طلب مناقلة جديد
          </button>
        </div>
      </div>

      {/* TAB 1: 7-Stage Transfers Table */}
      {activeTab === 'transfers' && (
        <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
          <div className="p-4 bg-slate-50/80 border-b border-slate-200 flex flex-wrap justify-between items-center text-xs">
            <span className="font-bold text-slate-800">
              دورة إدارة المناقلات المعتمدة (طلب ← مراجعة ← اعتماد ← إرسال ← استلام ← مطابقة ← إغلاق)
            </span>
            <span className="text-[11px] text-slate-500 font-medium">
              محمية بآلية قفل التدقيق اللوجستي (Audit Lock) لمنع ازدواجية القيد في المخزون
            </span>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-right text-xs">
              <thead className="bg-slate-50 border-b border-slate-200 text-slate-500 font-bold">
                <tr>
                  <th className="p-3.5">رقم المنفيست</th>
                  <th className="p-3.5">المستودع المصدر ← المستهدف</th>
                  <th className="p-3.5">الصنف</th>
                  <th className="p-3.5 text-center">الكمية المطلوبة</th>
                  <th className="p-3.5 text-center">المشحون</th>
                  <th className="p-3.5 text-center">المستلم / التالف</th>
                  <th className="p-3.5">المرحلة التشغيلية</th>
                  <th className="p-3.5 text-center">إجراء الانتقال التالي</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {filteredTransfers.map((t) => (
                  <tr key={t.id} className="hover:bg-slate-50/60 transition-colors">
                    <td className="p-3.5 font-mono font-bold text-blue-600">{t.manifest_number}</td>
                    <td className="p-3.5">
                      <div className="font-bold text-slate-900 flex items-center gap-1">
                        <span>{t.source_warehouse_name.split('(')[0]}</span>
                        <ArrowRight className="w-3 h-3 text-slate-400 rotate-180" />
                        <span className="text-blue-700">{t.destination_warehouse_name.split('(')[0]}</span>
                      </div>
                      <div className="text-[11px] text-slate-400 mt-0.5">{t.assigned_driver || 'بانتظار الشحن'}</div>
                    </td>
                    <td className="p-3.5">
                      <div className="font-bold text-slate-800">{t.product_name_ar}</div>
                      <div className="font-mono text-[10px] text-slate-400">{t.barcode || t.sku}</div>
                    </td>
                    <td className="p-3.5 text-center font-bold text-slate-800">{t.quantity_requested}</td>
                    <td className="p-3.5 text-center font-bold text-purple-700">{t.quantity_dispatched || '-'}</td>
                    <td className="p-3.5 text-center">
                      {t.status === 'closed' ? (
                        <div className="font-bold text-emerald-700">
                          {t.quantity_received} سليم
                          {t.quantity_damaged > 0 && (
                            <span className="text-rose-600 font-bold block text-[10px]">
                              ({t.quantity_damaged} تالف)
                            </span>
                          )}
                        </div>
                      ) : (
                        <span className="text-slate-400 font-mono">-</span>
                      )}
                    </td>
                    <td className="p-3.5">{renderStatusBadge(t.status)}</td>
                    <td className="p-3.5 text-center">
                      <div className="flex items-center justify-center gap-1.5">
                        {t.status === 'requested' && (
                          <button
                            onClick={() => handleAdvanceStatus(t, 'under_review')}
                            className="px-2.5 py-1 bg-amber-600 hover:bg-amber-700 text-white rounded-lg font-bold text-[11px]"
                          >
                            بدء المراجعة
                          </button>
                        )}
                        {t.status === 'under_review' && (
                          <button
                            onClick={() => handleAdvanceStatus(t, 'approved')}
                            className="px-2.5 py-1 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-bold text-[11px]"
                          >
                            اعتماد وتجهيز
                          </button>
                        )}
                        {t.status === 'approved' && (
                          <button
                            onClick={() => handleAdvanceStatus(t, 'dispatched')}
                            className="px-2.5 py-1 bg-purple-600 hover:bg-purple-700 text-white rounded-lg font-bold text-[11px] flex items-center gap-1"
                          >
                            <Truck className="w-3 h-3" />
                            شحن وتفريغ المصدر
                          </button>
                        )}
                        {t.status === 'dispatched' && (
                          <button
                            onClick={() => handleAdvanceStatus(t, 'received')}
                            className="px-2.5 py-1 bg-teal-600 hover:bg-teal-700 text-white rounded-lg font-bold text-[11px]"
                          >
                            تأكيد وصول الرصيف
                          </button>
                        )}
                        {t.status === 'received' && (
                          <button
                            onClick={() => handleOpenMatchingModal(t)}
                            className="px-2.5 py-1 bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg font-bold text-[11px] shadow-sm"
                          >
                            مطابقة وفحص التلف
                          </button>
                        )}
                        {t.status === 'closed' && (
                          <span className="text-slate-400 font-medium text-[11px] flex items-center gap-1">
                            <Lock className="w-3.5 h-3.5 text-emerald-600" />
                            مقفل ومقيد
                          </span>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* TAB 2: Independent Warehouse Stock (Available / Reserved / Damaged / Bin) */}
      {activeTab === 'stock' && (
        <div className="space-y-4">
          {/* Quick Barcode Scanner Bar */}
          <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-xs flex flex-col md:flex-row items-center justify-between gap-4">
            <form onSubmit={handleBarcodeSearch} className="flex gap-2 w-full md:w-auto flex-1">
              <div className="relative flex-1">
                <input
                  type="text"
                  placeholder="امسح أو اكتب الباركود للتحقق الفوري من موقع الصنف ورصيده..."
                  value={barcodeSearch}
                  onChange={(e) => setBarcodeSearch(e.target.value)}
                  className="w-full pr-9 pl-3 py-2 bg-slate-50 border border-slate-300 rounded-xl text-xs font-mono"
                />
                <Barcode className="w-4 h-4 text-slate-400 absolute right-3 top-2.5" />
              </div>
              <button
                type="submit"
                className="px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-xl text-xs font-bold transition-colors shrink-0"
              >
                فحص الباركود
              </button>
            </form>

            <div className="flex items-center gap-4 text-xs font-bold text-slate-600">
              <span className="flex items-center gap-1.5">
                <span className="w-2.5 h-2.5 rounded-full bg-emerald-500"></span>
                رصيد متوفر للبيع
              </span>
              <span className="flex items-center gap-1.5">
                <span className="w-2.5 h-2.5 rounded-full bg-amber-500"></span>
                محجوز لطلبات جارية
              </span>
              <span className="flex items-center gap-1.5">
                <span className="w-2.5 h-2.5 rounded-full bg-rose-500"></span>
                رصيد تالف معزول
              </span>
            </div>
          </div>

          {/* Scanned Badge Banner if searched */}
          {scannedResult && (
            <div className="p-4 bg-indigo-50 border border-indigo-200 rounded-2xl flex items-center justify-between">
              <div>
                <span className="text-[10px] font-extrabold px-2 py-0.5 rounded bg-indigo-200 text-indigo-900">
                  نتيجة مسح الباركود
                </span>
                <h4 className="font-bold text-slate-900 text-sm mt-1">{scannedResult.product_name_ar}</h4>
                <p className="text-xs text-indigo-700 font-mono mt-0.5">
                  باركود: {scannedResult.barcode} • الرف: {scannedResult.bin_location}
                </p>
              </div>
              <div className="flex items-center gap-4 text-xs">
                <div className="text-center">
                  <div className="font-black text-emerald-700 font-mono text-base">{scannedResult.available_stock}</div>
                  <div className="text-[10px] text-slate-500">متوفر</div>
                </div>
                <div className="text-center">
                  <div className="font-black text-amber-700 font-mono text-base">{scannedResult.reserved_stock}</div>
                  <div className="text-[10px] text-slate-500">محجوز</div>
                </div>
                <div className="text-center">
                  <div className="font-black text-rose-700 font-mono text-base">{scannedResult.damaged_stock}</div>
                  <div className="text-[10px] text-slate-500">تالف</div>
                </div>
              </div>
            </div>
          )}

          {/* Stock Table */}
          <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full text-right text-xs">
                <thead className="bg-slate-50 border-b border-slate-200 text-slate-500 font-bold">
                  <tr>
                    <th className="p-3.5">اسم الصنف والباركود</th>
                    <th className="p-3.5">المستودع المستقل</th>
                    <th className="p-3.5">موقع الرف (Bin Location)</th>
                    <th className="p-3.5 text-center text-emerald-700">الرصيد المتوفر</th>
                    <th className="p-3.5 text-center text-amber-700">الرصيد المحجوز</th>
                    <th className="p-3.5 text-center text-rose-700">الرصيد التالف</th>
                    <th className="p-3.5 text-center">الإجمالي الفعلي</th>
                    <th className="p-3.5 text-center">إجراءات المخزون</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {filteredStock.map((stk) => {
                    const wh = darkStores.find((w) => w.id === stk.warehouse_id);
                    const totalPhysical = stk.available_stock + stk.reserved_stock + stk.damaged_stock;
                    return (
                      <tr key={stk.id} className="hover:bg-slate-50/60">
                        <td className="p-3.5">
                          <div className="font-bold text-slate-900">{stk.product_name_ar}</div>
                          <div className="font-mono text-[11px] text-slate-400">{stk.barcode}</div>
                        </td>
                        <td className="p-3.5 font-bold text-slate-700">{wh?.name_ar || stk.warehouse_id}</td>
                        <td className="p-3.5">
                          <span className="font-mono font-bold bg-slate-100 px-2 py-0.5 rounded text-slate-700">
                            {stk.bin_location}
                          </span>
                        </td>
                        <td className="p-3.5 text-center font-mono font-black text-emerald-700 text-sm">
                          {stk.available_stock}
                        </td>
                        <td className="p-3.5 text-center font-mono font-bold text-amber-700">
                          {stk.reserved_stock}
                        </td>
                        <td className="p-3.5 text-center font-mono font-bold text-rose-700">
                          {stk.damaged_stock}
                        </td>
                        <td className="p-3.5 text-center font-mono font-black text-slate-900">
                          {totalPhysical}
                        </td>
                        <td className="p-3.5 text-center">
                          <button
                            onClick={() => {
                              setAdjustingStock(stk);
                              setAdjustDamageCount(1);
                              setAdjustReason('انتهاء صلاحية أو كسر في الرف');
                            }}
                            className="px-2.5 py-1 bg-rose-50 hover:bg-rose-100 text-rose-700 border border-rose-200 rounded-lg font-bold text-[11px] transition-colors"
                          >
                            قيد تلف صنف
                          </button>
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

      {/* TAB 3: Movement Logs & Audit Trail */}
      {activeTab === 'movement_logs' && (
        <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
          <div className="p-4 bg-slate-50 border-b border-slate-200 font-bold text-slate-800 text-xs flex justify-between">
            <span>سجل تدقيق حركات المخزون والمناقلات المؤتمت (Immutable Audit Trail)</span>
            <span className="text-slate-400 font-normal">إجمالي الحركات: {movementLogs.length}</span>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-right text-xs">
              <thead className="bg-slate-50 text-slate-500 font-bold">
                <tr>
                  <th className="p-3">وقت الحركة</th>
                  <th className="p-3">المستودع</th>
                  <th className="p-3">نوع الحركة</th>
                  <th className="p-3 text-center">الكمية (+/-)</th>
                  <th className="p-3">المرجع</th>
                  <th className="p-3">البيان والملاحظات</th>
                  <th className="p-3">المسؤول المنفذ</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {movementLogs.map((log) => {
                  const wh = darkStores.find((w) => w.id === log.warehouse_id);
                  return (
                    <tr key={log.id} className="hover:bg-slate-50/50">
                      <td className="p-3 font-mono text-slate-500 text-[11px]">{log.timestamp}</td>
                      <td className="p-3 font-bold text-slate-800">{wh?.name_ar.split('(')[0] || log.warehouse_id}</td>
                      <td className="p-3">
                        {log.type === 'inbound_po' && <span className="bg-emerald-50 text-emerald-800 px-2 py-0.5 rounded font-bold">توريد من مورد</span>}
                        {log.type === 'transfer_out' && <span className="bg-purple-50 text-purple-800 px-2 py-0.5 rounded font-bold">مناقلة صادرة</span>}
                        {log.type === 'transfer_in' && <span className="bg-teal-50 text-teal-800 px-2 py-0.5 rounded font-bold">مناقلة واردة</span>}
                        {log.type === 'damaged' && <span className="bg-rose-50 text-rose-800 px-2 py-0.5 rounded font-bold">تلف ومستهلكات</span>}
                        {log.type === 'order_fulfillment' && <span className="bg-blue-50 text-blue-800 px-2 py-0.5 rounded font-bold">تجهيز طلب عميل</span>}
                      </td>
                      <td className={`p-3 text-center font-mono font-black ${
                        log.quantity_change > 0 ? 'text-emerald-700' : 'text-rose-700'
                      }`}>
                        {log.quantity_change > 0 ? `+${log.quantity_change}` : log.quantity_change}
                      </td>
                      <td className="p-3 font-mono text-blue-600 font-bold">{log.reference_id}</td>
                      <td className="p-3 text-slate-600">{log.notes || '-'}</td>
                      <td className="p-3 text-slate-500 font-medium">{log.performed_by}</td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* MODAL: Create New Transfer */}
      {showNewTransferModal && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl max-w-lg w-full p-6 shadow-2xl border border-slate-200">
            <h3 className="text-lg font-bold text-slate-900 mb-4 flex items-center gap-2">
              <ArrowLeftRight className="w-5 h-5 text-blue-600" />
              إصدار طلب مناقلة بضاعة جديد بين المستودعات
            </h3>

            <form onSubmit={handleCreateTransferRequest} className="space-y-4 text-xs">
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block font-bold text-slate-700 mb-1">المستودع المصدر (المُرسل) *</label>
                  <select
                    value={newSourceWh}
                    onChange={(e) => setNewSourceWh(e.target.value)}
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-300 rounded-xl font-bold"
                  >
                    {darkStores.map((w) => (
                      <option key={w.id} value={w.id}>
                        {w.name_ar}
                      </option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="block font-bold text-slate-700 mb-1">المستودع المستهدف (المُستلم) *</label>
                  <select
                    value={newDestWh}
                    onChange={(e) => setNewDestWh(e.target.value)}
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-300 rounded-xl font-bold"
                  >
                    {darkStores.map((w) => (
                      <option key={w.id} value={w.id}>
                        {w.name_ar}
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              <div>
                <label className="block font-bold text-slate-700 mb-1">الصنف المطلوب نقله *</label>
                <select
                  value={newProductId}
                  onChange={(e) => setNewProductId(e.target.value)}
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-300 rounded-xl font-bold"
                >
                  {products.map((p) => (
                    <option key={p.id} value={p.id}>
                      {p.name_ar} ({p.barcode || 'بدون باركود'})
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block font-bold text-slate-700 mb-1">الكمية المطلوبة (قطع/وحدات) *</label>
                <input
                  type="number"
                  min="1"
                  required
                  value={newQty}
                  onChange={(e) => setNewQty(Number(e.target.value))}
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-300 rounded-xl font-mono text-sm font-bold"
                />
              </div>

              <div className="flex justify-end gap-2 pt-4 border-t border-slate-100">
                <button
                  type="button"
                  onClick={() => setShowNewTransferModal(false)}
                  className="px-4 py-2 border border-slate-300 rounded-xl font-bold text-slate-600 hover:bg-slate-50"
                >
                  إلغاء
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 bg-blue-600 hover:bg-blue-700 text-white font-bold rounded-xl shadow-md shadow-blue-600/30 flex items-center gap-1.5"
                >
                  <Check className="w-3.5 h-3.5" />
                  إرسال الطلب للمراجعة
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* MODAL: Matching & Discrepancy Inspection */}
      {inspectingTransfer && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl max-w-md w-full p-6 shadow-2xl border border-slate-200">
            <h3 className="text-lg font-bold text-slate-900 mb-2 flex items-center gap-2">
              <ShieldCheck className="w-5 h-5 text-emerald-600" />
              مطابقة استلام الشحنة وفحص التلف
            </h3>
            <p className="text-xs text-slate-500 font-mono mb-4">
              منفيست: {inspectingTransfer.manifest_number} • الصنف: {inspectingTransfer.product_name_ar}
            </p>

            <div className="space-y-3 text-xs">
              <div className="p-3 bg-slate-50 rounded-xl flex justify-between font-bold">
                <span className="text-slate-600">الكمية المشحونة رسمياً:</span>
                <span className="font-mono text-purple-700">{inspectingTransfer.quantity_dispatched} قطعة</span>
              </div>

              <div className="grid grid-cols-2 gap-2">
                <div>
                  <label className="block font-bold text-slate-700 mb-1">الكمية السليمة الصالحة *</label>
                  <input
                    type="number"
                    min="0"
                    value={matchGoodQty}
                    onChange={(e) => setMatchGoodQty(Number(e.target.value))}
                    className="w-full px-3 py-2 bg-emerald-50 border border-emerald-300 rounded-xl font-mono text-sm font-bold text-emerald-900"
                  />
                </div>
                <div>
                  <label className="block font-bold text-slate-700 mb-1">الكمية التالفة / المفقودة</label>
                  <input
                    type="number"
                    min="0"
                    value={matchDamagedQty}
                    onChange={(e) => setMatchDamagedQty(Number(e.target.value))}
                    className="w-full px-3 py-2 bg-rose-50 border border-rose-300 rounded-xl font-mono text-sm font-bold text-rose-900"
                  />
                </div>
              </div>

              <div>
                <label className="block font-bold text-slate-700 mb-1">سبب الفروقات والتلف (إن وجد)</label>
                <input
                  type="text"
                  placeholder="مثال: مطبات أثناء النقل تسببت بكسر 2 كرتونة"
                  value={discrepancyReason}
                  onChange={(e) => setDiscrepancyReason(e.target.value)}
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-300 rounded-xl"
                />
              </div>

              <div className="p-3 bg-amber-50 border border-amber-200 rounded-xl text-amber-800 text-[11px] flex items-start gap-2">
                <Lock className="w-4 h-4 text-amber-600 shrink-0 mt-0.5" />
                <span>
                  عند التأكيد، سيتم إيداع الرصيد السليم فوراً وقفل المنفيست ضد التعديل لمنع تكرار القيد أو اختلال الرصيد.
                </span>
              </div>

              <div className="flex justify-end gap-2 pt-4 border-t border-slate-100">
                <button
                  type="button"
                  onClick={() => setInspectingTransfer(null)}
                  className="px-4 py-2 border border-slate-300 rounded-xl font-bold text-slate-600 hover:bg-slate-50"
                >
                  إلغاء
                </button>
                <button
                  type="button"
                  onClick={handleConfirmMatchAndClose}
                  className="px-5 py-2 bg-emerald-600 hover:bg-emerald-700 text-white font-bold rounded-xl shadow-md shadow-emerald-600/30 flex items-center gap-1.5"
                >
                  <Check className="w-3.5 h-3.5" />
                  اعتماد المطابقة وإغلاق المناقلة
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* MODAL: Record Damage on existing stock */}
      {adjustingStock && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl max-w-md w-full p-6 shadow-2xl border border-rose-200">
            <h3 className="text-lg font-bold text-slate-900 mb-2 flex items-center gap-2">
              <AlertTriangle className="w-5 h-5 text-rose-600" />
              قيد تلف صنف في المستودع
            </h3>
            <p className="text-xs text-slate-500 font-mono mb-4">
              الصنف: {adjustingStock.product_name_ar} • الرف: {adjustingStock.bin_location}
            </p>

            <div className="space-y-3 text-xs">
              <div className="p-3 bg-slate-50 rounded-xl flex justify-between font-bold">
                <span className="text-slate-600">الرصيد الصالح المتوفر حالياً:</span>
                <span className="font-mono text-emerald-700">{adjustingStock.available_stock} قطعة</span>
              </div>

              <div>
                <label className="block font-bold text-slate-700 mb-1">الكمية التالفة *</label>
                <input
                  type="number"
                  min="1"
                  max={adjustingStock.available_stock}
                  value={adjustDamageCount}
                  onChange={(e) => setAdjustDamageCount(Number(e.target.value))}
                  className="w-full px-3 py-2 bg-rose-50 border border-rose-300 rounded-xl font-mono text-sm font-bold text-rose-900"
                />
              </div>

              <div>
                <label className="block font-bold text-slate-700 mb-1">سبب التلف ومحضر الإتلاف *</label>
                <input
                  type="text"
                  value={adjustReason}
                  onChange={(e) => setAdjustReason(e.target.value)}
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-300 rounded-xl"
                />
              </div>

              <div className="flex justify-end gap-2 pt-4 border-t border-slate-100">
                <button
                  type="button"
                  onClick={() => setAdjustingStock(null)}
                  className="px-4 py-2 border border-slate-300 rounded-xl font-bold text-slate-600 hover:bg-slate-50"
                >
                  إلغاء
                </button>
                <button
                  type="button"
                  onClick={handleConfirmDamageAdjustment}
                  className="px-5 py-2 bg-rose-600 hover:bg-rose-700 text-white font-bold rounded-xl shadow-md shadow-rose-600/30 flex items-center gap-1.5"
                >
                  <Check className="w-3.5 h-3.5" />
                  قيد التلف وخصم المتوفر
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
