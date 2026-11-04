import React, { useState, useEffect, useCallback } from 'react';
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
  Layers,
  ClipboardList,
  RefreshCw,
  TrendingDown,
  TrendingUp
} from 'lucide-react';
import { 
  DarkStore, 
  Product, 
  TransferOrder, 
  TransferStatus, 
  WarehouseItemStock, 
  InventoryMovementLog,
  InventoryAuditRecord,
  Branch,
  StaffMember
} from '../types';
import { logAuditEvent } from '../lib/auditLogger';
import { supabase } from '../lib/supabase';

interface InventoryTransferPageProps {
  darkStores: DarkStore[];
  products: Product[];
  branches?: Branch[];
  currentUser?: StaffMember;
  onRefresh?: () => void;
}

export const InventoryTransferPage: React.FC<InventoryTransferPageProps> = ({
  darkStores,
  products,
  branches = [],
  currentUser,
  onRefresh,
}) => {
  const [activeTab, setActiveTab] = useState<'transfers' | 'stock' | 'movement_logs' | 'audits'>('transfers');
  const [selectedWarehouseFilter, setSelectedWarehouseFilter] = useState<string>('all');
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [toastMessage, setToastMessage] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(false);

  // Active warehouses/branches list for selection
  const operationalWarehouses = branches.length > 0
    ? branches.map((b) => ({
        id: b.id,
        code: b.code,
        name_ar: b.name_ar,
        city: b.city,
        type: b.type,
      }))
    : darkStores.map((d) => ({
        id: d.id,
        code: d.code,
        name_ar: d.name_ar,
        city: d.city,
        type: 'dark_store',
      }));

  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(null), 4000);
  };

  // 1. Live State: Multi-warehouse stocks
  const [stockRecords, setStockRecords] = useState<WarehouseItemStock[]>([]);

  // 2. Live State: Movement Logs
  const [movementLogs, setMovementLogs] = useState<InventoryMovementLog[]>([]);

  // 3. Live State: 7-Stage Transfers
  const [transfers, setTransfers] = useState<TransferOrder[]>([]);

  // 4. Live State: Audits & Physical Reconciliations
  const [auditRecords, setAuditRecords] = useState<InventoryAuditRecord[]>([]);

  // Modals States
  const [showNewTransferModal, setShowNewTransferModal] = useState<boolean>(false);
  const [newSourceWh, setNewSourceWh] = useState<string>(operationalWarehouses[0]?.id || '');
  const [newDestWh, setNewDestWh] = useState<string>(operationalWarehouses[1]?.id || '');
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

  // Record Damage modal
  const [adjustingStock, setAdjustingStock] = useState<WarehouseItemStock | null>(null);
  const [adjustDamageCount, setAdjustDamageCount] = useState<number>(1);
  const [adjustReason, setAdjustReason] = useState<string>('انتهاء صلاحية أو كسر في الرف');

  // Inbound Supply modal (توريد)
  const [supplyingStock, setSupplyingStock] = useState<WarehouseItemStock | null>(null);
  const [supplyQty, setSupplyQty] = useState<number>(50);
  const [supplyPoNumber, setSupplyPoNumber] = useState<string>('');
  const [supplyNotes, setSupplyNotes] = useState<string>('توريد واستلام أمر شراء معتمد');

  // Physical Count Reconciliation modal (تسوية جرد فعلي)
  const [reconcilingStock, setReconcilingStock] = useState<WarehouseItemStock | null>(null);
  const [physicalCountInput, setPhysicalCountInput] = useState<number>(0);
  const [auditReasonInput, setAuditReasonInput] = useState<string>('جرد دوري مجدول');

  // Load live data from PostgreSQL via Supabase
  const loadLiveData = useCallback(async () => {
    setIsLoading(true);
    try {
      // 1. Fetch branch inventory
      const { data: dbStock, error: stockErr } = await supabase
        .from('branch_inventory')
        .select('*');

      if (!stockErr && dbStock && dbStock.length > 0) {
        const mappedStock: WarehouseItemStock[] = dbStock.map((row) => {
          const prod = products.find((p) => p.id === row.product_id);
          return {
            id: row.id,
            warehouse_id: row.branch_id,
            product_id: row.product_id,
            product_name_ar: prod?.name_ar || 'صنف متجر',
            barcode: prod?.barcode || '629100000000',
            available_stock: Number(row.quantity_on_hand) || 0,
            reserved_stock: Number(row.quantity_reserved) || 0,
            damaged_stock: 0,
            bin_location: row.bin_location || 'رف-A-01',
            last_updated: row.updated_at ? new Date(row.updated_at).toLocaleTimeString('ar-SA', { hour: '2-digit', minute: '2-digit' }) : 'محدث',
          };
        });
        setStockRecords(mappedStock);
      } else {
        // Fallback default distribution from loaded products
        const fallbackList: WarehouseItemStock[] = [];
        operationalWarehouses.forEach((wh, whIdx) => {
          products.forEach((p, pIdx) => {
            const baseQty = p.stock_quantity > 0 ? Math.floor(p.stock_quantity / Math.max(operationalWarehouses.length, 1)) : 80;
            fallbackList.push({
              id: `stk-${wh.id}-${p.id}`,
              warehouse_id: wh.id,
              product_id: p.id,
              product_name_ar: p.name_ar,
              barcode: p.barcode || `629100${whIdx}${pIdx}0`,
              available_stock: Math.max(10, baseQty),
              reserved_stock: 0,
              damaged_stock: 0,
              bin_location: `رف-${String.fromCharCode(65 + (pIdx % 6))}-${(whIdx + 1) * 10 + (pIdx % 8)}`,
              last_updated: 'محدث',
            });
          });
        });
        setStockRecords(fallbackList);
      }

      // 2. Fetch inventory movements
      const { data: dbMovements, error: movErr } = await supabase
        .from('inventory_movements')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(100);

      if (!movErr && dbMovements) {
        const mappedMovements: InventoryMovementLog[] = dbMovements.map((m) => {
          const prod = products.find((p) => p.id === m.product_id);
          return {
            id: m.id,
            timestamp: m.created_at ? new Date(m.created_at).toLocaleString('ar-SA') : 'الآن',
            warehouse_id: m.branch_id,
            branch_id: m.branch_id,
            product_id: m.product_id,
            product_name_ar: prod?.name_ar || 'صنف تسوق',
            barcode: prod?.barcode || '',
            type: m.movement_type as any,
            quantity_change: Number(m.quantity_change) || 0,
            resulting_available: Number(m.resulting_on_hand) || 0,
            resulting_reserved: Number(m.resulting_reserved) || 0,
            reference_type: m.reference_type,
            reference_id: m.reference_id,
            notes: m.notes,
            performed_by: m.actor_name || 'مسؤول المخزون',
            actor_name: m.actor_name,
            actor_role: m.actor_role,
          };
        });
        setMovementLogs(mappedMovements);
      }

      // 3. Fetch inventory transfers
      const { data: dbTransfers, error: trfErr } = await supabase
        .from('inventory_transfers')
        .select('*')
        .order('created_at', { ascending: false });

      if (!trfErr && dbTransfers && dbTransfers.length > 0) {
        const mappedTransfers: TransferOrder[] = dbTransfers.map((t) => {
          const srcWh = operationalWarehouses.find((w) => w.id === t.source_branch_id);
          const dstWh = operationalWarehouses.find((w) => w.id === t.destination_branch_id);
          const prod = products.find((p) => p.id === t.product_id);
          return {
            id: t.id,
            manifest_number: t.transfer_number,
            source_warehouse_id: t.source_branch_id,
            source_warehouse_name: srcWh?.name_ar || t.source_branch_id,
            destination_warehouse_id: t.destination_branch_id,
            destination_warehouse_name: dstWh?.name_ar || t.destination_branch_id,
            sku: prod?.barcode || 'SKU-ITEM',
            barcode: prod?.barcode,
            product_id: t.product_id,
            product_name_ar: prod?.name_ar || 'صنف مناقلة',
            quantity_requested: Number(t.quantity_requested) || 0,
            quantity_dispatched: Number(t.quantity_dispatched) || 0,
            quantity_received: Number(t.quantity_received) || 0,
            quantity_damaged: Number(t.quantity_damaged) || 0,
            status: t.status as TransferStatus,
            assigned_driver: t.assigned_driver || undefined,
            requested_at: t.requested_at ? new Date(t.requested_at).toLocaleString('ar-SA') : 'مؤخراً',
            dispatched_at: t.dispatched_at ? new Date(t.dispatched_at).toLocaleString('ar-SA') : undefined,
            received_at: t.received_at ? new Date(t.received_at).toLocaleString('ar-SA') : undefined,
            discrepancy_reason: t.discrepancy_reason || undefined,
            audit_locked: !!t.audit_locked,
          };
        });
        setTransfers(mappedTransfers);
      }

      // 4. Fetch inventory audits
      const { data: dbAudits, error: audErr } = await supabase
        .from('inventory_audits')
        .select('*')
        .order('created_at', { ascending: false });

      if (!audErr && dbAudits) {
        const mappedAudits: InventoryAuditRecord[] = dbAudits.map((a) => {
          const prod = products.find((p) => p.id === a.product_id);
          return {
            id: a.id,
            audit_number: a.audit_number,
            branch_id: a.branch_id,
            product_id: a.product_id,
            product_name_ar: prod?.name_ar || 'صنف تم جرده',
            system_quantity: Number(a.system_quantity) || 0,
            physical_quantity: Number(a.physical_quantity) || 0,
            variance: Number(a.variance) || 0,
            reason: a.reason,
            auditor_name: a.auditor_name || 'مدقق الجرد',
            auditor_role: a.auditor_role || 'auditor',
            status: a.status || 'completed',
            created_at: a.created_at ? new Date(a.created_at).toLocaleString('ar-SA') : 'اليوم',
          };
        });
        setAuditRecords(mappedAudits);
      }
    } catch (e) {
      console.warn('Live inventory data load info:', e);
    } finally {
      setIsLoading(false);
    }
  }, [operationalWarehouses, products]);

  useEffect(() => {
    loadLiveData();
  }, [loadLiveData]);

  // Create new transfer request (Phase 1: requested)
  const handleCreateTransferRequest = async (e: React.FormEvent) => {
    e.preventDefault();
    if (newSourceWh === newDestWh) {
      alert('لا يمكن إجراء مناقلة بين نفس المستودع/الفرع!');
      return;
    }

    const srcWh = operationalWarehouses.find((w) => w.id === newSourceWh);
    const destWh = operationalWarehouses.find((w) => w.id === newDestWh);
    const prod = products.find((p) => p.id === newProductId);

    if (!srcWh || !destWh || !prod) return;

    const manifestNum = `TRF-2026-${Math.floor(100 + Math.random() * 900)}`;

    try {
      const { data: insData, error: insErr } = await supabase
        .from('inventory_transfers')
        .insert({
          transfer_number: manifestNum,
          source_branch_id: srcWh.id,
          destination_branch_id: destWh.id,
          product_id: prod.id,
          quantity_requested: Number(newQty),
          status: 'requested',
          requested_by: currentUser?.full_name || 'أمين المستودع العام',
        })
        .select()
        .single();

      if (insErr) {
        console.warn('Direct transfer insert warning:', insErr);
      }

      logAuditEvent({
        actor_id: currentUser?.id || 'admin-1',
        actor_name: currentUser?.full_name || 'أمين المستودع',
        actor_role: currentUser?.role || 'warehouse_officer',
        action: 'TRANSFER_REQUESTED',
        category: 'inventory',
        details: `طلب مناقلة صادر ${manifestNum}: ${prod.name_ar} (كمية ${newQty}) من ${srcWh.name_ar} إلى ${destWh.name_ar}`,
        target_id: insData?.id || manifestNum,
      });

      showToast(`✓ تم إنشاء طلب المناقلة ${manifestNum} بنجاح وهو بانتظار الاعتماد.`);
      setShowNewTransferModal(false);
      loadLiveData();
      if (onRefresh) onRefresh();
    } catch (err: any) {
      alert(`حدث خطأ أثناء إنشاء المناقلة: ${err?.message || err}`);
    }
  };

  // Move status across the 7-step cycle
  const handleAdvanceStatus = async (transfer: TransferOrder, targetStatus: TransferStatus) => {
    if (transfer.audit_locked) {
      alert('هذا السجل مغلق ومقفل نهائياً في سجلات التدقيق لمنع ازدواجية القيد!');
      return;
    }

    try {
      if (targetStatus === 'under_review') {
        await supabase
          .from('inventory_transfers')
          .update({ status: 'under_review' })
          .eq('transfer_number', transfer.manifest_number);

        showToast(`✓ تم وضع طلب المناقلة ${transfer.manifest_number} قيد المراجعة الفنية.`);
        loadLiveData();
        return;
      }

      if (targetStatus === 'approved') {
        const { error: rpcErr } = await supabase.rpc('perform_inventory_transfer_step_atomic', {
          p_transfer_id: transfer.id,
          p_action: 'approve',
          p_actor_name: currentUser?.full_name || 'مدير المستودعات',
          p_actor_role: currentUser?.role || 'warehouse_manager',
        });

        if (rpcErr) throw rpcErr;

        showToast(`✓ تم اعتماد طلب المناقلة ${transfer.manifest_number} وتجهيز البضاعة للشحن.`);
        loadLiveData();
        return;
      }

      if (targetStatus === 'dispatched') {
        const driverName = 'كابتن النقل اللوجستي المبرد (شاحنة #21)';
        const { error: rpcErr } = await supabase.rpc('perform_inventory_transfer_step_atomic', {
          p_transfer_id: transfer.id,
          p_action: 'dispatch',
          p_driver: driverName,
          p_actor_name: currentUser?.full_name || 'مسؤول الترحيل',
          p_actor_role: currentUser?.role || 'warehouse_manager',
        });

        if (rpcErr) throw rpcErr;

        showToast(`🚚 تم شحن الشحنة ${transfer.manifest_number} وخصم الكمية ذرياً من الفرع المصدر.`);
        loadLiveData();
        if (onRefresh) onRefresh();
        return;
      }

      if (targetStatus === 'received') {
        // Open matching dialog directly
        handleOpenMatchingModal(transfer);
        return;
      }
    } catch (err: any) {
      alert(`فشل تنفيذ إجراء الانتقال: ${err?.message || err}`);
    }
  };

  // Phase 5 & 6 & 7: Matching and Closing with Discrepancy & Damaged Handling
  const handleOpenMatchingModal = (transfer: TransferOrder) => {
    setInspectingTransfer(transfer);
    setMatchGoodQty(transfer.quantity_dispatched || transfer.quantity_requested);
    setMatchDamagedQty(0);
    setDiscrepancyReason('');
  };

  const handleConfirmMatchAndClose = async () => {
    if (!inspectingTransfer) return;
    if (inspectingTransfer.audit_locked) return;

    const good = Number(matchGoodQty) || 0;
    const damaged = Number(matchDamagedQty) || 0;
    const dispatched = inspectingTransfer.quantity_dispatched || inspectingTransfer.quantity_requested;

    if (good + damaged !== dispatched && !discrepancyReason.trim()) {
      alert('يوجد نقص في إجمالي الكميات المستلمة مقارنة بالمنفيست! يجب كتابة سبب النقص في حقل الملاحظات.');
      return;
    }

    try {
      const { error: rpcErr } = await supabase.rpc('perform_inventory_transfer_step_atomic', {
        p_transfer_id: inspectingTransfer.id,
        p_action: 'receive',
        p_good_qty: good,
        p_damaged_qty: damaged,
        p_discrepancy_reason: discrepancyReason.trim() || 'مطابق تماماً للمنفيست',
        p_actor_name: currentUser?.full_name || 'أمين مستودع الاستلام والمطابقة',
        p_actor_role: currentUser?.role || 'warehouse_manager',
      });

      if (rpcErr) throw rpcErr;

      logAuditEvent({
        actor_id: currentUser?.id || 'admin-1',
        actor_name: currentUser?.full_name || 'أمين مستودع الاستلام',
        actor_role: currentUser?.role || 'receiving_officer',
        action: 'TRANSFER_CLOSED_MATCHED',
        category: 'inventory',
        details: `إغلاق ومطابقة مناقلة ${inspectingTransfer.manifest_number}: استلام ${good} سليم و ${damaged} تالف وقفل السجل نهائياً.`,
        target_id: inspectingTransfer.id,
      });

      showToast(`✓ تمت المطابقة بنجاح وإيداع ${good} قطعة في الفرع المستلم وقفل المنفيست ضد التكرار.`);
      setInspectingTransfer(null);
      loadLiveData();
      if (onRefresh) onRefresh();
    } catch (err: any) {
      alert(`فشل إتمام المطابقة وإغلاق المنفيست: ${err?.message || err}`);
    }
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
  const handleConfirmDamageAdjustment = async () => {
    if (!adjustingStock) return;
    const count = Number(adjustDamageCount);
    if (count <= 0 || count > adjustingStock.available_stock) {
      alert('الكمية التالفة يجب أن تكون أكبر من 0 ولا تتجاوز الرصيد المتوفر!');
      return;
    }

    try {
      const dmgRef = `DMG-${Date.now().toString().slice(-4)}`;
      const { error: rpcErr } = await supabase.rpc('record_inventory_movement_atomic', {
        p_branch_id: adjustingStock.warehouse_id,
        p_product_id: adjustingStock.product_id,
        p_movement_type: 'damaged',
        p_qty_change: -count,
        p_qty_reserved_change: 0,
        p_ref_type: 'loss_prevention',
        p_ref_id: dmgRef,
        p_actor_name: currentUser?.full_name || 'لجنة جرد المستودع',
        p_actor_role: currentUser?.role || 'inventory_auditor',
        p_notes: `قيد تلف بالمستودع: ${adjustReason}`,
      });

      if (rpcErr) throw rpcErr;

      logAuditEvent({
        actor_id: currentUser?.id || 'admin-1',
        actor_name: currentUser?.full_name || 'لجنة الجرد',
        actor_role: currentUser?.role || 'inventory_auditor',
        action: 'STOCK_DAMAGE_RECORDED',
        category: 'inventory',
        details: `تسجيل تلف ${count} قطعة للصنف (${adjustingStock.product_name_ar}) في المستودع. السبب: ${adjustReason}`,
        target_id: adjustingStock.id,
      });

      showToast(`✓ تم قيد ${count} قطعة في رصيد التالف وخصمها ذرياً من الرصيد الصالح للبيع.`);
      setAdjustingStock(null);
      loadLiveData();
      if (onRefresh) onRefresh();
    } catch (err: any) {
      alert(`فشل تسجيل التلف في الخادم: ${err?.message || err}`);
    }
  };

  // Inbound Supply (توريد بضاعة جديدة)
  const handleConfirmSupply = async () => {
    if (!supplyingStock) return;
    const qty = Number(supplyQty);
    if (qty <= 0) {
      alert('يجب إدخال كمية توريد صحيحة أكبر من صفر!');
      return;
    }

    const poNumber = supplyPoNumber.trim() || `PO-2026-${Math.floor(100 + Math.random() * 900)}`;

    try {
      const { error: rpcErr } = await supabase.rpc('record_inventory_movement_atomic', {
        p_branch_id: supplyingStock.warehouse_id,
        p_product_id: supplyingStock.product_id,
        p_movement_type: 'supply',
        p_qty_change: qty,
        p_qty_reserved_change: 0,
        p_ref_type: 'po',
        p_ref_id: poNumber,
        p_actor_name: currentUser?.full_name || 'أمين التوريد والاستلام',
        p_actor_role: currentUser?.role || 'warehouse_manager',
        p_notes: supplyNotes || 'استلام وتوريد شحنة مورد',
      });

      if (rpcErr) throw rpcErr;

      showToast(`✓ تم توريد ${qty} وحدة بنجاح وتحديث الرصيد الفعلي للصنف.`);
      setSupplyingStock(null);
      loadLiveData();
      if (onRefresh) onRefresh();
    } catch (err: any) {
      alert(`فشل إتمام التوريد: ${err?.message || err}`);
    }
  };

  // Physical Count Reconciliation (الجرد والتسوية)
  const handleConfirmReconciliation = async () => {
    if (!reconcilingStock) return;
    const physQty = Number(physicalCountInput);
    if (physQty < 0) {
      alert('الكمية المحصورة لا يمكن أن تكون سالبة!');
      return;
    }

    try {
      const { data: audData, error: rpcErr } = await supabase.rpc('perform_stock_audit_reconciliation_atomic', {
        p_branch_id: reconcilingStock.warehouse_id,
        p_product_id: reconcilingStock.product_id,
        p_physical_qty: physQty,
        p_auditor_name: currentUser?.full_name || 'المدقق المالي والمخزني',
        p_auditor_role: currentUser?.role || 'auditor',
        p_reason: auditReasonInput || 'تسوية جرد دوري فعلي',
      });

      if (rpcErr) throw rpcErr;

      const variance = audData?.variance ?? (physQty - reconcilingStock.available_stock);
      showToast(`✓ تمت التسوية الجردية بنجاح! الرصيد الجديد: ${physQty} (الفارق: ${variance > 0 ? `+${variance}` : variance})`);
      setReconcilingStock(null);
      loadLiveData();
      if (onRefresh) onRefresh();
    } catch (err: any) {
      alert(`فشل اعتماد تسوية الجرد: ${err?.message || err}`);
    }
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

  // Filter movements
  const filteredMovements = movementLogs.filter((m) => {
    const matchWh = selectedWarehouseFilter === 'all' || m.warehouse_id === selectedWarehouseFilter || m.branch_id === selectedWarehouseFilter;
    const matchSearch =
      m.reference_id.toLowerCase().includes(searchQuery.toLowerCase()) ||
      (m.product_name_ar?.toLowerCase().includes(searchQuery.toLowerCase()) ?? false) ||
      m.barcode.includes(searchQuery) ||
      (m.performed_by?.toLowerCase().includes(searchQuery.toLowerCase()) ?? false);
    return matchWh && matchSearch;
  });

  // Filter audits
  const filteredAudits = auditRecords.filter((a) => {
    const matchWh = selectedWarehouseFilter === 'all' || a.branch_id === selectedWarehouseFilter;
    const matchSearch =
      a.audit_number.toLowerCase().includes(searchQuery.toLowerCase()) ||
      (a.product_name_ar?.toLowerCase().includes(searchQuery.toLowerCase()) ?? false) ||
      (a.auditor_name?.toLowerCase().includes(searchQuery.toLowerCase()) ?? false);
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
      default:
        return <span className="px-2 py-0.5 rounded-full text-[11px] font-bold bg-slate-100 text-slate-700">{status}</span>;
    }
  };

  const renderMovementBadge = (type: string) => {
    switch (type) {
      case 'supply':
      case 'inbound_po':
        return <span className="bg-emerald-50 text-emerald-800 border border-emerald-200 px-2 py-0.5 rounded font-bold">توريد وارد</span>;
      case 'reservation':
        return <span className="bg-amber-50 text-amber-800 border border-amber-200 px-2 py-0.5 rounded font-bold">حجز للطلب</span>;
      case 'release_reservation':
        return <span className="bg-sky-50 text-sky-800 border border-sky-200 px-2 py-0.5 rounded font-bold">فك حجز (إلغاء)</span>;
      case 'disbursement':
        return <span className="bg-indigo-50 text-indigo-800 border border-indigo-200 px-2 py-0.5 rounded font-bold">إذن صرف</span>;
      case 'sale':
      case 'order_fulfillment':
        return <span className="bg-blue-50 text-blue-800 border border-blue-200 px-2 py-0.5 rounded font-bold">بيع مباشر / POS</span>;
      case 'return':
        return <span className="bg-emerald-100 text-emerald-900 border border-emerald-300 px-2 py-0.5 rounded font-bold">مرتجع عميل</span>;
      case 'damaged':
        return <span className="bg-rose-50 text-rose-800 border border-rose-200 px-2 py-0.5 rounded font-bold">تالف ومستهلكات</span>;
      case 'audit_reconciliation':
        return <span className="bg-purple-50 text-purple-800 border border-purple-200 px-2 py-0.5 rounded font-bold">تسوية جردية</span>;
      case 'transfer_out':
        return <span className="bg-purple-50 text-purple-800 border border-purple-200 px-2 py-0.5 rounded font-bold">مناقلة صادرة</span>;
      case 'transfer_in':
        return <span className="bg-teal-50 text-teal-800 border border-teal-200 px-2 py-0.5 rounded font-bold">مناقلة واردة</span>;
      default:
        return <span className="bg-slate-50 text-slate-800 border border-slate-200 px-2 py-0.5 rounded font-bold">{type}</span>;
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
      <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-3">
        {operationalWarehouses.map((wh) => {
          const isFilterActive = selectedWarehouseFilter === wh.id;
          const whStockCount = stockRecords
            .filter((s) => s.warehouse_id === wh.id)
            .reduce((a, b) => a + b.available_stock, 0);

          return (
            <div
              key={wh.id}
              onClick={() => setSelectedWarehouseFilter(isFilterActive ? 'all' : wh.id)}
              className={`p-3.5 rounded-2xl border cursor-pointer transition-all ${
                isFilterActive
                  ? 'bg-blue-900 text-white border-blue-900 shadow-lg ring-2 ring-blue-500/50'
                  : 'bg-white text-slate-800 border-slate-200 hover:border-blue-300'
              }`}
            >
              <div className="flex items-center justify-between mb-1.5">
                <span className={`text-[10px] px-2 py-0.5 rounded-md font-mono font-bold ${
                  isFilterActive ? 'bg-blue-800 text-blue-200' : 'bg-slate-100 text-slate-600'
                }`}>
                  {wh.code}
                </span>
                <span className={`text-[11px] font-bold ${isFilterActive ? 'text-emerald-300' : 'text-emerald-600'}`}>
                  نشط
                </span>
              </div>
              <h4 className="font-bold text-xs leading-tight line-clamp-1">{wh.name_ar}</h4>
              <p className={`text-[11px] mt-0.5 ${isFilterActive ? 'text-blue-200' : 'text-slate-400'}`}>{wh.city}</p>

              <div className="mt-2.5 pt-2 border-t border-slate-100/20 flex justify-between text-[11px]">
                <span className={isFilterActive ? 'text-blue-200' : 'text-slate-500'}>الرصيد المتاح:</span>
                <span className="font-mono font-black">{whStockCount.toLocaleString()} قطعة</span>
              </div>
            </div>
          );
        })}
      </div>

      {/* Tabs and Actions Header */}
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
            <span>المناقلات اللوجستية (7 مراحل)</span>
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
            <span>أرصدة الفروع والمستودعات</span>
            <span className={`px-1.5 py-0.2 rounded-full text-[10px] ${activeTab === 'stock' ? 'bg-white text-indigo-700' : 'bg-slate-100 text-slate-600'}`}>
              {stockRecords.length}
            </span>
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
            <span>سجل حركات المخزون والتدقيق</span>
            <span className={`px-1.5 py-0.2 rounded-full text-[10px] ${activeTab === 'movement_logs' ? 'bg-white text-slate-900' : 'bg-slate-100 text-slate-600'}`}>
              {movementLogs.length}
            </span>
          </button>

          <button
            onClick={() => setActiveTab('audits')}
            className={`px-4 py-2 rounded-xl text-xs font-bold transition-all flex items-center gap-1.5 ${
              activeTab === 'audits'
                ? 'bg-purple-700 text-white shadow-md shadow-purple-700/30'
                : 'bg-white text-slate-600 hover:bg-slate-100 border border-slate-200'
            }`}
          >
            <ClipboardList className="w-3.5 h-3.5" />
            <span>جلسات وتقارير الجرد والتسوية</span>
            <span className={`px-1.5 py-0.2 rounded-full text-[10px] ${activeTab === 'audits' ? 'bg-white text-purple-700' : 'bg-slate-100 text-slate-600'}`}>
              {auditRecords.length}
            </span>
          </button>
        </div>

        <div className="flex gap-2 w-full sm:w-auto items-center">
          <div className="relative flex-1 sm:w-56">
            <input
              type="text"
              placeholder="بحث بالرقم أو الصنف أو الباركود..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pr-8 pl-3 py-1.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-medium focus:outline-none focus:border-blue-600"
            />
            <Search className="w-3.5 h-3.5 text-slate-400 absolute right-2.5 top-2.5" />
          </div>

          <button
            onClick={loadLiveData}
            disabled={isLoading}
            className="p-2 border border-slate-200 rounded-xl hover:bg-slate-50 text-slate-600 transition-colors"
            title="تحديث البيانات من الخادم"
          >
            <RefreshCw className={`w-3.5 h-3.5 ${isLoading ? 'animate-spin text-blue-600' : ''}`} />
          </button>

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
                  <th className="p-3.5">المصدر ← المستهدف</th>
                  <th className="p-3.5">الصنف</th>
                  <th className="p-3.5 text-center">الكمية المطلوبة</th>
                  <th className="p-3.5 text-center">المشحون</th>
                  <th className="p-3.5 text-center">المستلم / التالف</th>
                  <th className="p-3.5">المرحلة التشغيلية</th>
                  <th className="p-3.5 text-center">إجراء الانتقال التالي</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {filteredTransfers.length === 0 ? (
                  <tr>
                    <td colSpan={8} className="p-8 text-center text-slate-400 font-medium">
                      لا توجد مناقلات مسجلة تطابق محددات البحث الحالية.
                    </td>
                  </tr>
                ) : (
                  filteredTransfers.map((t) => (
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
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* TAB 2: Independent Branch & Warehouse Stock */}
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
                رصيد متاح للبيع
              </span>
              <span className="flex items-center gap-1.5">
                <span className="w-2.5 h-2.5 rounded-full bg-amber-500"></span>
                محجوز لطلبات
              </span>
              <span className="flex items-center gap-1.5">
                <span className="w-2.5 h-2.5 rounded-full bg-blue-500"></span>
                تحديث ذري خادمي
              </span>
            </div>
          </div>

          {/* Scanned Badge Banner */}
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
                  <div className="text-[10px] text-slate-500">متاح</div>
                </div>
                <div className="text-center">
                  <div className="font-black text-amber-700 font-mono text-base">{scannedResult.reserved_stock}</div>
                  <div className="text-[10px] text-slate-500">محجوز</div>
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
                    <th className="p-3.5">الفرع / المستودع</th>
                    <th className="p-3.5">موقع الرف</th>
                    <th className="p-3.5 text-center text-emerald-700">الرصيد المتاح</th>
                    <th className="p-3.5 text-center text-amber-700">المحجوز</th>
                    <th className="p-3.5 text-center">آخر تحديث</th>
                    <th className="p-3.5 text-center">إجراءات المخزون الذرية</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {filteredStock.length === 0 ? (
                    <tr>
                      <td colSpan={7} className="p-8 text-center text-slate-400 font-medium">
                        لا توجد أصناف تطابق محددات البحث.
                      </td>
                    </tr>
                  ) : (
                    filteredStock.map((stk) => {
                      const wh = operationalWarehouses.find((w) => w.id === stk.warehouse_id);
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
                          <td className="p-3.5 text-center text-slate-400 font-mono text-[11px]">
                            {stk.last_updated}
                          </td>
                          <td className="p-3.5 text-center">
                            <div className="flex items-center justify-center gap-1.5">
                              <button
                                onClick={() => {
                                  setSupplyingStock(stk);
                                  setSupplyQty(50);
                                  setSupplyPoNumber(`PO-2026-${Math.floor(100 + Math.random() * 900)}`);
                                }}
                                className="px-2 py-1 bg-emerald-50 hover:bg-emerald-100 text-emerald-700 border border-emerald-200 rounded-lg font-bold text-[11px] transition-colors"
                              >
                                توريد وارد
                              </button>
                              <button
                                onClick={() => {
                                  setReconcilingStock(stk);
                                  setPhysicalCountInput(stk.available_stock);
                                  setAuditReasonInput('مطابقة جرد دوري فعلي');
                                }}
                                className="px-2 py-1 bg-purple-50 hover:bg-purple-100 text-purple-700 border border-purple-200 rounded-lg font-bold text-[11px] transition-colors"
                              >
                                تسوية جرد
                              </button>
                              <button
                                onClick={() => {
                                  setAdjustingStock(stk);
                                  setAdjustDamageCount(1);
                                  setAdjustReason('انتهاء صلاحية أو كسر في الرف');
                                }}
                                className="px-2 py-1 bg-rose-50 hover:bg-rose-100 text-rose-700 border border-rose-200 rounded-lg font-bold text-[11px] transition-colors"
                              >
                                قيد تلف
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
        </div>
      )}

      {/* TAB 3: Movement Logs & Audit Trail */}
      {activeTab === 'movement_logs' && (
        <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
          <div className="p-4 bg-slate-50 border-b border-slate-200 font-bold text-slate-800 text-xs flex justify-between items-center">
            <span>سجل تدقيق حركات المخزون والمناقلات المؤتمت (Immutable Audit Trail)</span>
            <span className="text-slate-500 font-mono text-[11px]">إجمالي الحركات: {filteredMovements.length}</span>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-right text-xs">
              <thead className="bg-slate-50 text-slate-500 font-bold border-b border-slate-200">
                <tr>
                  <th className="p-3">رقم الحركة والوقت</th>
                  <th className="p-3">الفرع / المستودع</th>
                  <th className="p-3">نوع الحركة</th>
                  <th className="p-3 text-center">التغير (+/-)</th>
                  <th className="p-3 text-center">الرصيد الناتج</th>
                  <th className="p-3">المرجع</th>
                  <th className="p-3">الملاحظات</th>
                  <th className="p-3">المسؤول المنفذ</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {filteredMovements.length === 0 ? (
                  <tr>
                    <td colSpan={8} className="p-8 text-center text-slate-400 font-medium">
                      لا توجد حركات مخزنية مسجلة تطابق محددات البحث.
                    </td>
                  </tr>
                ) : (
                  filteredMovements.map((log) => {
                    const wh = operationalWarehouses.find((w) => w.id === log.warehouse_id || w.id === log.branch_id);
                    return (
                      <tr key={log.id} className="hover:bg-slate-50/50">
                        <td className="p-3">
                          <div className="font-mono text-blue-600 font-bold text-[11px]">{log.id.slice(0, 8)}</div>
                          <div className="font-mono text-slate-400 text-[10px]">{log.timestamp}</div>
                        </td>
                        <td className="p-3 font-bold text-slate-800">{wh?.name_ar.split('(')[0] || log.warehouse_id}</td>
                        <td className="p-3">{renderMovementBadge(log.type)}</td>
                        <td className={`p-3 text-center font-mono font-black ${
                          log.quantity_change > 0 ? 'text-emerald-700' : log.quantity_change < 0 ? 'text-rose-700' : 'text-slate-500'
                        }`}>
                          {log.quantity_change > 0 ? `+${log.quantity_change}` : log.quantity_change}
                        </td>
                        <td className="p-3 text-center font-mono font-bold text-slate-800">
                          {log.resulting_available}
                        </td>
                        <td className="p-3 font-mono text-indigo-700 font-bold">{log.reference_id}</td>
                        <td className="p-3 text-slate-600 max-w-xs truncate">{log.notes || '-'}</td>
                        <td className="p-3 text-slate-500 font-medium">
                          <div>{log.performed_by}</div>
                          {log.actor_role && (
                            <span className="text-[10px] text-slate-400 font-mono">({log.actor_role})</span>
                          )}
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

      {/* TAB 4: Audits & Physical Reconciliations */}
      {activeTab === 'audits' && (
        <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
          <div className="p-4 bg-slate-50 border-b border-slate-200 font-bold text-slate-800 text-xs flex justify-between items-center">
            <span>سجل جلسات وتقارير الجرد الدوري والتسوية المعتمدة (Physical Inventory Audits)</span>
            <span className="text-slate-500 font-mono text-[11px]">إجمالي الجلسات: {filteredAudits.length}</span>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-right text-xs">
              <thead className="bg-slate-50 text-slate-500 font-bold border-b border-slate-200">
                <tr>
                  <th className="p-3.5">رقم محضر الجرد</th>
                  <th className="p-3.5">الفرع</th>
                  <th className="p-3.5">الصنف</th>
                  <th className="p-3.5 text-center">الرصيد الدفتري</th>
                  <th className="p-3.5 text-center">العد الفعلي</th>
                  <th className="p-3.5 text-center">الفارق (عجز / فائض)</th>
                  <th className="p-3.5">الملاحظات والسبب</th>
                  <th className="p-3.5">المدقق المالي</th>
                  <th className="p-3.5 text-center">التاريخ</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {filteredAudits.length === 0 ? (
                  <tr>
                    <td colSpan={9} className="p-8 text-center text-slate-400 font-medium">
                      لا توجد جلسات جرد مسجلة. يمكنك إجراء تسوية جردية من تبويب "أرصدة الفروع".
                    </td>
                  </tr>
                ) : (
                  filteredAudits.map((aud) => {
                    const wh = operationalWarehouses.find((w) => w.id === aud.branch_id);
                    const isDeficit = aud.variance < 0;
                    const isSurplus = aud.variance > 0;
                    return (
                      <tr key={aud.id} className="hover:bg-slate-50/50">
                        <td className="p-3.5 font-mono font-bold text-purple-700">{aud.audit_number}</td>
                        <td className="p-3.5 font-bold text-slate-800">{wh?.name_ar.split('(')[0] || aud.branch_id}</td>
                        <td className="p-3.5 font-bold text-slate-900">{aud.product_name_ar}</td>
                        <td className="p-3.5 text-center font-mono font-bold text-slate-700">{aud.system_quantity}</td>
                        <td className="p-3.5 text-center font-mono font-black text-blue-800">{aud.physical_quantity}</td>
                        <td className="p-3.5 text-center">
                          <span className={`inline-flex items-center gap-1 font-mono font-black px-2 py-0.5 rounded ${
                            isDeficit 
                              ? 'bg-rose-50 text-rose-700 border border-rose-200' 
                              : isSurplus 
                              ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                              : 'bg-slate-100 text-slate-700'
                          }`}>
                            {isDeficit && <TrendingDown className="w-3 h-3" />}
                            {isSurplus && <TrendingUp className="w-3 h-3" />}
                            {aud.variance > 0 ? `+${aud.variance}` : aud.variance}
                          </span>
                        </td>
                        <td className="p-3.5 text-slate-600 max-w-xs truncate">{aud.reason || '-'}</td>
                        <td className="p-3.5 text-slate-700 font-medium">{aud.auditor_name}</td>
                        <td className="p-3.5 text-center font-mono text-slate-400 text-[11px]">{aud.created_at}</td>
                      </tr>
                    );
                  })
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* MODAL 1: Create New Transfer */}
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
                    {operationalWarehouses.map((w) => (
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
                    {operationalWarehouses.map((w) => (
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

      {/* MODAL 2: Matching & Discrepancy Inspection */}
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
                <span className="font-mono text-purple-700">{inspectingTransfer.quantity_dispatched || inspectingTransfer.quantity_requested} قطعة</span>
              </div>

              <div className="grid grid-cols-2 gap-2">
                <div>
                  <label className="block font-bold text-slate-700 mb-1">الكمية السليمة المستلمة *</label>
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
                  placeholder="مثال: تلف أثناء النقل اللوجستي"
                  value={discrepancyReason}
                  onChange={(e) => setDiscrepancyReason(e.target.value)}
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-300 rounded-xl"
                />
              </div>

              <div className="p-3 bg-amber-50 border border-amber-200 rounded-xl text-amber-800 text-[11px] flex items-start gap-2">
                <Lock className="w-4 h-4 text-amber-600 shrink-0 mt-0.5" />
                <span>
                  عند التأكيد، سيتم إيداع الرصيد السليم ذرياً وقفل المنفيست ضد التعديل لمنع تكرار القيد أو اختلال الرصيد.
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

      {/* MODAL 3: Record Damage on existing stock */}
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
                <span className="text-slate-600">الرصيد المتاح حالياً:</span>
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

      {/* MODAL 4: Inbound Supply (توريد وارد) */}
      {supplyingStock && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl max-w-md w-full p-6 shadow-2xl border border-emerald-200">
            <h3 className="text-lg font-bold text-slate-900 mb-2 flex items-center gap-2">
              <Package className="w-5 h-5 text-emerald-600" />
              توريد واستلام بضاعة جديدة (أمر شراء)
            </h3>
            <p className="text-xs text-slate-500 font-mono mb-4">
              الصنف: {supplyingStock.product_name_ar} • الرف: {supplyingStock.bin_location}
            </p>

            <div className="space-y-3 text-xs">
              <div className="p-3 bg-slate-50 rounded-xl flex justify-between font-bold">
                <span className="text-slate-600">الرصيد المتاح الحالي:</span>
                <span className="font-mono text-slate-900">{supplyingStock.available_stock} قطعة</span>
              </div>

              <div>
                <label className="block font-bold text-slate-700 mb-1">الكمية الموردة *</label>
                <input
                  type="number"
                  min="1"
                  value={supplyQty}
                  onChange={(e) => setSupplyQty(Number(e.target.value))}
                  className="w-full px-3 py-2 bg-emerald-50 border border-emerald-300 rounded-xl font-mono text-sm font-bold text-emerald-900"
                />
              </div>

              <div>
                <label className="block font-bold text-slate-700 mb-1">رقم أمر الشراء / المنفيست المرجعي *</label>
                <input
                  type="text"
                  value={supplyPoNumber}
                  onChange={(e) => setSupplyPoNumber(e.target.value)}
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-300 rounded-xl font-mono"
                  placeholder="PO-2026-..."
                />
              </div>

              <div>
                <label className="block font-bold text-slate-700 mb-1">ملاحظات التوريد واسم المورد</label>
                <input
                  type="text"
                  value={supplyNotes}
                  onChange={(e) => setSupplyNotes(e.target.value)}
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-300 rounded-xl"
                />
              </div>

              <div className="flex justify-end gap-2 pt-4 border-t border-slate-100">
                <button
                  type="button"
                  onClick={() => setSupplyingStock(null)}
                  className="px-4 py-2 border border-slate-300 rounded-xl font-bold text-slate-600 hover:bg-slate-50"
                >
                  إلغاء
                </button>
                <button
                  type="button"
                  onClick={handleConfirmSupply}
                  className="px-5 py-2 bg-emerald-600 hover:bg-emerald-700 text-white font-bold rounded-xl shadow-md shadow-emerald-600/30 flex items-center gap-1.5"
                >
                  <Check className="w-3.5 h-3.5" />
                  تأكيد التوريد وقيد الحركة
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* MODAL 5: Physical Count Reconciliation (الجرد والتسوية) */}
      {reconcilingStock && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl max-w-md w-full p-6 shadow-2xl border border-purple-200">
            <h3 className="text-lg font-bold text-slate-900 mb-2 flex items-center gap-2">
              <ClipboardList className="w-5 h-5 text-purple-600" />
              تسوية جرد فعلي (Stock Reconciliation)
            </h3>
            <p className="text-xs text-slate-500 font-mono mb-4">
              الصنف: {reconcilingStock.product_name_ar} • الرف: {reconcilingStock.bin_location}
            </p>

            <div className="space-y-3 text-xs">
              <div className="p-3 bg-slate-50 rounded-xl flex justify-between font-bold">
                <span className="text-slate-600">الرصيد الدفتري في النظام:</span>
                <span className="font-mono text-purple-800">{reconcilingStock.available_stock} قطعة</span>
              </div>

              <div>
                <label className="block font-bold text-slate-700 mb-1">الكمية الفعلية المحصورة بالجرد *</label>
                <input
                  type="number"
                  min="0"
                  value={physicalCountInput}
                  onChange={(e) => setPhysicalCountInput(Number(e.target.value))}
                  className="w-full px-3 py-2 bg-purple-50 border border-purple-300 rounded-xl font-mono text-sm font-bold text-purple-900"
                />
              </div>

              {/* Live variance indicator */}
              <div className="p-2.5 rounded-xl border flex justify-between items-center font-bold text-xs">
                <span className="text-slate-600">فارق التسوية (Variance):</span>
                <span className={`font-mono font-black ${
                  physicalCountInput - reconcilingStock.available_stock < 0
                    ? 'text-rose-600'
                    : physicalCountInput - reconcilingStock.available_stock > 0
                    ? 'text-emerald-600'
                    : 'text-slate-600'
                }`}>
                  {physicalCountInput - reconcilingStock.available_stock > 0
                    ? `+${physicalCountInput - reconcilingStock.available_stock} (فائض)`
                    : physicalCountInput - reconcilingStock.available_stock < 0
                    ? `${physicalCountInput - reconcilingStock.available_stock} (عجز)`
                    : '0 (مطابق تماماً)'}
                </span>
              </div>

              <div>
                <label className="block font-bold text-slate-700 mb-1">سبب التسوية ورقم المحضر *</label>
                <input
                  type="text"
                  value={auditReasonInput}
                  onChange={(e) => setAuditReasonInput(e.target.value)}
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-300 rounded-xl"
                  placeholder="سبب الفارق أو دورة الجرد..."
                />
              </div>

              <div className="flex justify-end gap-2 pt-4 border-t border-slate-100">
                <button
                  type="button"
                  onClick={() => setReconcilingStock(null)}
                  className="px-4 py-2 border border-slate-300 rounded-xl font-bold text-slate-600 hover:bg-slate-50"
                >
                  إلغاء
                </button>
                <button
                  type="button"
                  onClick={handleConfirmReconciliation}
                  className="px-5 py-2 bg-purple-600 hover:bg-purple-700 text-white font-bold rounded-xl shadow-md shadow-purple-600/30 flex items-center gap-1.5"
                >
                  <Check className="w-3.5 h-3.5" />
                  اعتماد التسوية وتوثيق المحضر
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
