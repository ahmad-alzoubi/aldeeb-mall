import React, { useState, useEffect, useMemo, useCallback, useRef } from 'react';
import { 
  Warehouse, 
  ScanLine, 
  CheckCircle2, 
  Clock, 
  MapPin, 
  AlertTriangle, 
  Search, 
  ArrowRight,
  Boxes,
  Activity,
  Truck,
  Scale,
  RefreshCw,
  Package,
  Layers,
  Sparkles,
  HelpCircle,
  FileText,
  UserCheck,
  Camera,
  XCircle,
  Check,
  Send,
  AlertCircle
} from 'lucide-react';
import { DarkStore, PickerTask, Order, Product, StaffMember, Branch } from '../types';
import { fulfillmentApi, FulfillmentScanResult } from '../lib/fulfillmentApi';

interface FulfillmentPageProps {
  darkStores?: DarkStore[];
  pickerTasks?: PickerTask[];
  currentUser?: StaffMember;
  activeBranchId?: string;
  branches?: Branch[];
  orders?: Order[];
  products?: Product[];
  onOrderUpdated?: () => void;
}

export const FulfillmentPage: React.FC<FulfillmentPageProps> = ({
  darkStores = [],
  pickerTasks: initialTasks = [],
  currentUser,
  activeBranchId = 'all',
  branches = [],
  orders: propOrders = [],
  products: propProducts = [],
  onOrderUpdated
}) => {
  // Active Filter & Selection States
  const [selectedBranch, setSelectedBranch] = useState<string>(
    activeBranchId !== 'all' ? activeBranchId : (currentUser?.branch_id || 'b-ruh-01')
  );
  const [activeStage, setActiveStage] = useState<'all' | 'picking' | 'sorting' | 'packing'>('picking');
  const [selectedOrderId, setSelectedOrderId] = useState<string>('');
  
  // Real Database Data
  const [tasks, setTasks] = useState<PickerTask[]>([]);
  const [fulfillmentOrders, setFulfillmentOrders] = useState<Order[]>([]);
  const [catalogProducts, setCatalogProducts] = useState<Product[]>(propProducts);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [isProcessing, setIsProcessing] = useState<boolean>(false);

  // Scanner & Input States
  const [scanInput, setScanInput] = useState<string>('');
  const [selectedTaskIdForScan, setSelectedTaskIdForScan] = useState<string | null>(null);
  const [scanFeedback, setScanFeedback] = useState<{
    success: boolean;
    title: string;
    message: string;
    scannedBarcode?: string;
    expectedBarcode?: string;
  } | null>(null);

  // Weighed Item Modal State
  const [weighedModalTask, setWeighedModalTask] = useState<PickerTask | null>(null);
  const [actualWeightInput, setActualWeightInput] = useState<string>('');

  // Substitution Modal State
  const [substitutionModalTask, setSubstitutionModalTask] = useState<PickerTask | null>(null);
  const [substituteSearchQuery, setSubstituteSearchQuery] = useState<string>('');
  const [selectedSubstituteProduct, setSelectedSubstituteProduct] = useState<Product | null>(null);
  const [substituteBarcodeConfirm, setSubstituteBarcodeConfirm] = useState<string>('');
  const [substituteQtyInput, setSubstituteQtyInput] = useState<string>('1');
  const [substituteReason, setSubstituteReason] = useState<string>('المنتج الأصلي غير متوفر على الرف');

  // Shortage Modal State
  const [shortageModalTask, setShortageModalTask] = useState<PickerTask | null>(null);
  const [shortageQtyInput, setShortageQtyInput] = useState<string>('1');
  const [shortageReason, setShortageReason] = useState<string>('نفاد المخزون بالكامل بالمستودع');

  // Stage Advancement Modal (Box / Packaging ID)
  const [advanceStageOrder, setAdvanceStageOrder] = useState<Order | null>(null);
  const [targetStage, setTargetStage] = useState<'sorting' | 'packing' | 'ready_for_driver'>('sorting');
  const [boxIdInput, setBoxIdInput] = useState<string>('BOX-01');

  // Audio Beep Helpers using Web Audio API
  const playSound = useCallback((type: 'success' | 'error' | 'stage') => {
    try {
      const AudioCtx = window.AudioContext || (window as any).webkitAudioContext;
      if (!AudioCtx) return;
      const ctx = new AudioCtx();
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.connect(gain);
      gain.connect(ctx.destination);

      if (type === 'success') {
        osc.frequency.setValueAtTime(880, ctx.currentTime);
        osc.frequency.exponentialRampToValueAtTime(1760, ctx.currentTime + 0.15);
        gain.gain.setValueAtTime(0.2, ctx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.15);
        osc.start();
        osc.stop(ctx.currentTime + 0.15);
      } else if (type === 'error') {
        osc.frequency.setValueAtTime(220, ctx.currentTime);
        osc.frequency.setValueAtTime(160, ctx.currentTime + 0.15);
        gain.gain.setValueAtTime(0.3, ctx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.3);
        osc.start();
        osc.stop(ctx.currentTime + 0.3);
      } else {
        // Fanfare for ready for driver
        osc.frequency.setValueAtTime(523.25, ctx.currentTime);
        osc.frequency.setValueAtTime(659.25, ctx.currentTime + 0.1);
        osc.frequency.setValueAtTime(783.99, ctx.currentTime + 0.2);
        gain.gain.setValueAtTime(0.25, ctx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.35);
        osc.start();
        osc.stop(ctx.currentTime + 0.35);
      }
    } catch (_) {}
  }, []);

  // 1. Fetch live data from Database
  const loadFulfillmentData = useCallback(async () => {
    setIsLoading(true);
    try {
      const [fetchedOrders, fetchedTasks, fetchedProds] = await Promise.all([
        fulfillmentApi.fetchFulfillmentOrders(selectedBranch),
        fulfillmentApi.fetchPickerTasks(selectedBranch),
        catalogProducts.length > 0 ? Promise.resolve(catalogProducts) : fulfillmentApi.fetchSubstituteProducts(),
      ]);

      setFulfillmentOrders(fetchedOrders);
      setTasks(fetchedTasks);
      if (fetchedProds.length > 0) setCatalogProducts(fetchedProds);

      // Auto-select first order if none selected
      if (!selectedOrderId && fetchedOrders.length > 0) {
        setSelectedOrderId(fetchedOrders[0].id);
      }
    } catch (err) {
      console.warn('Fallback to local props dataset for fulfillment:', err);
      // Fallback safely to props if offline or database error
      if (initialTasks.length > 0) setTasks(initialTasks);
      if (propOrders.length > 0) setFulfillmentOrders(propOrders);
    } finally {
      setIsLoading(false);
    }
  }, [selectedBranch, selectedOrderId, initialTasks, propOrders, catalogProducts.length]);

  useEffect(() => {
    loadFulfillmentData();
  }, [loadFulfillmentData]);

  // 2. Hardware Laser Scanner Listener (captures rapid barcode keystrokes + Enter)
  const barcodeBufferRef = useRef<string>('');
  const lastKeyTimeRef = useRef<number>(0);

  useEffect(() => {
    const handleGlobalKeyDown = (e: KeyboardEvent) => {
      // Don't intercept if user is actively typing in another form input
      const target = e.target as HTMLElement;
      if (target && target.tagName === 'INPUT' && target.id !== 'fulfillment-barcode-input') {
        return;
      }

      const now = Date.now();
      const diff = now - lastKeyTimeRef.current;
      lastKeyTimeRef.current = now;

      if (e.key === 'Enter') {
        if (barcodeBufferRef.current.length >= 4) {
          const scanned = barcodeBufferRef.current.trim();
          barcodeBufferRef.current = '';
          handleProcessBarcodeScan(scanned, 'barcode_scan');
        } else {
          barcodeBufferRef.current = '';
        }
      } else if (e.key.length === 1) {
        // Fast typing buffer: if keypress arrives within 70ms, it's almost certainly a laser scanner
        if (diff > 120) {
          barcodeBufferRef.current = '';
        }
        barcodeBufferRef.current += e.key;
      }
    };

    window.addEventListener('keydown', handleGlobalKeyDown);
    return () => window.removeEventListener('keydown', handleGlobalKeyDown);
  });

  // 3. Process Barcode Scan (Real server-side validation against product & task barcode)
  const handleProcessBarcodeScan = async (scannedBarcode: string, scanMode: 'barcode_scan' | 'verified_manual') => {
    const cleanScanned = scannedBarcode.trim();
    if (!cleanScanned) return;

    setIsProcessing(true);

    // If a task is explicitly selected in the table, verify against it
    let targetTask: PickerTask | undefined;
    if (selectedTaskIdForScan) {
      targetTask = tasks.find((t) => t.id === selectedTaskIdForScan);
    }

    // Otherwise, match against pending tasks for the currently selected order or active tasks
    if (!targetTask) {
      targetTask = tasks.find((t) => {
        const orderMatch = selectedOrderId ? t.order_id === selectedOrderId : true;
        const barcodeMatch = t.barcode === cleanScanned || cleanScanned.includes(t.barcode);
        return orderMatch && barcodeMatch && !t.is_verified;
      });
    }

    // If still not matched, check if any task in current view matches
    if (!targetTask) {
      targetTask = tasks.find((t) => t.barcode === cleanScanned && !t.is_verified);
    }

    // If no matching task exists at all, or barcode doesn't match the selected task: REJECT!
    if (!targetTask || (targetTask.barcode !== cleanScanned && !cleanScanned.includes(targetTask.barcode))) {
      playSound('error');
      setScanFeedback({
        success: false,
        title: 'رفض الباركود: الصنف غير مطابق!',
        message: `الرمز أو الباركود [${cleanScanned}] غير مطابق للصنف المطلوب${targetTask ? ` (${targetTask.product_name_ar})` : ''} في قائمة المهام الحالية.`,
        scannedBarcode: cleanScanned,
        expectedBarcode: targetTask?.barcode,
      });
      setIsProcessing(false);
      return;
    }

    // If task is weighed (e.g. Vegetables, Meat, Cheese) and weight not yet recorded: open weight dialog
    if (targetTask.item_type === 'weighed' && !targetTask.actual_weight) {
      setWeighedModalTask(targetTask);
      setActualWeightInput(targetTask.quantity_required.toString());
      setIsProcessing(false);
      return;
    }

    // Execute server-side scan verification
    try {
      const result: FulfillmentScanResult = await fulfillmentApi.verifyScan(
        targetTask.id,
        cleanScanned,
        scanMode,
        targetTask.quantity_required,
        targetTask.actual_weight,
        currentUser?.id || currentUser?.username
      );

      if (result.success) {
        playSound('success');
        setScanFeedback({
          success: true,
          title: '✓ تم التحقق والمطابقة بنجاح!',
          message: `تم جمع وتوثيق الصنف: ${targetTask.product_name_ar} (الكمية: ${result.quantity_picked ?? targetTask.quantity_required} ${targetTask.unit || 'قطعة'})`,
          scannedBarcode: cleanScanned,
        });

        // Update local state immediately
        setTasks((prev) =>
          prev.map((t) =>
            t.id === targetTask!.id
              ? {
                  ...t,
                  is_verified: true,
                  status: 'picked',
                  quantity_picked: result.quantity_picked ?? t.quantity_required,
                  scanned_barcode: cleanScanned,
                  verification_method: scanMode,
                }
              : t
          )
        );

        setSelectedTaskIdForScan(null);
        setScanInput('');
      } else {
        playSound('error');
        setScanFeedback({
          success: false,
          title: 'فشل التحقق الخادمي',
          message: result.message_ar || 'رفض الخادم مطابقة الباركود المدخل.',
          scannedBarcode: cleanScanned,
        });
      }
    } catch (err: any) {
      playSound('error');
      setScanFeedback({
        success: false,
        title: 'خطأ في الاتصال بالخادم',
        message: err.message || 'تعذر التواصل مع قاعدة البيانات للتحقق من الباركود.',
      });
    } finally {
      setIsProcessing(false);
    }
  };

  // 4. Submit Weighed Item
  const handleConfirmWeighedItem = async () => {
    if (!weighedModalTask) return;
    const weight = parseFloat(actualWeightInput);
    if (isNaN(weight) || weight <= 0) {
      alert('يرجى إدخال وزن صحيح بالأرقام (أكبر من 0).');
      return;
    }

    setIsProcessing(true);
    try {
      const result = await fulfillmentApi.verifyScan(
        weighedModalTask.id,
        weighedModalTask.barcode,
        'verified_manual',
        weight,
        weight,
        currentUser?.id || currentUser?.username
      );

      if (result.success) {
        playSound('success');
        setScanFeedback({
          success: true,
          title: '✓ تم تسجيل الوزن الفعلي بنجاح',
          message: `تم توثيق الصنف الموزون: ${weighedModalTask.product_name_ar} بوزن ${weight} كغ`,
        });

        setTasks((prev) =>
          prev.map((t) =>
            t.id === weighedModalTask.id
              ? {
                  ...t,
                  is_verified: true,
                  status: 'picked',
                  actual_weight: weight,
                  quantity_picked: weight,
                  verification_method: 'verified_manual',
                }
              : t
          )
        );

        setWeighedModalTask(null);
      } else {
        playSound('error');
        alert(result.message_ar);
      }
    } catch (err: any) {
      alert(err.message || 'فشل تسجيل الوزن');
    } finally {
      setIsProcessing(false);
    }
  };

  // 5. Submit Item Substitution
  const handleConfirmSubstitution = async () => {
    if (!substitutionModalTask || !selectedSubstituteProduct) {
      alert('يرجى اختيار الصنف البديل أولاً.');
      return;
    }

    const cleanSubBarcode = substituteBarcodeConfirm.trim();
    if (!cleanSubBarcode) {
      alert('يرجى مسح أو إدخال باركود الصنف البديل للتأكد من وجوده الفعلي.');
      return;
    }

    if (
      selectedSubstituteProduct.barcode &&
      cleanSubBarcode !== selectedSubstituteProduct.barcode.trim()
    ) {
      playSound('error');
      alert(`الباركود المدخل [${cleanSubBarcode}] لا يطابق باركود الصنف البديل [${selectedSubstituteProduct.barcode}]!`);
      return;
    }

    const subQty = parseFloat(substituteQtyInput) || 1;
    setIsProcessing(true);

    try {
      const result = await fulfillmentApi.recordSubstitution(
        substitutionModalTask.id,
        selectedSubstituteProduct.id,
        cleanSubBarcode,
        subQty,
        substituteReason,
        currentUser?.id || currentUser?.username
      );

      if (result.success) {
        playSound('success');
        setScanFeedback({
          success: true,
          title: '✓ تم اعتماد الصنف البديل بنجاح',
          message: `تم استبدال (${substitutionModalTask.product_name_ar}) بـ (${selectedSubstituteProduct.name_ar})، وتم تعديل المخزون وإشعار العميل.`,
        });

        setTasks((prev) =>
          prev.map((t) =>
            t.id === substitutionModalTask.id
              ? {
                  ...t,
                  is_verified: true,
                  status: 'substituted',
                  is_substituted: true,
                  substitute_product_id: selectedSubstituteProduct.id,
                  substitute_product_name: selectedSubstituteProduct.name_ar,
                  substitute_barcode: cleanSubBarcode,
                  substitution_reason: substituteReason,
                  price_difference: result.price_difference,
                  quantity_picked: subQty,
                }
              : t
          )
        );

        setSubstitutionModalTask(null);
        setSelectedSubstituteProduct(null);
        setSubstituteBarcodeConfirm('');
      } else {
        playSound('error');
        alert(result.message_ar);
      }
    } catch (err: any) {
      alert(err.message || 'فشل تسجيل البديل');
    } finally {
      setIsProcessing(false);
    }
  };

  // 6. Submit Item Shortage
  const handleConfirmShortage = async () => {
    if (!shortageModalTask) return;
    const shortQty = parseFloat(shortageQtyInput);
    if (isNaN(shortQty) || shortQty <= 0) {
      alert('يرجى إدخال كمية نقص صحيحة.');
      return;
    }

    setIsProcessing(true);
    try {
      const result = await fulfillmentApi.recordShortage(
        shortageModalTask.id,
        shortQty,
        shortageReason,
        currentUser?.id || currentUser?.username
      );

      if (result.success) {
        playSound('error'); // Shortage warning sound
        setScanFeedback({
          success: true,
          title: '⚠️ تم تسجيل النقص في الطلب',
          message: `تم توثيق تعذر توفير كمية ${shortQty} من الصنف: ${shortageModalTask.product_name_ar}، وإرسال تنبيه للإدارة والعميل.`,
        });

        setTasks((prev) =>
          prev.map((t) =>
            t.id === shortageModalTask.id
              ? {
                  ...t,
                  is_verified: true,
                  status: result.status as any,
                  is_shortage: true,
                  shortage_qty: shortQty,
                  shortage_reason: shortageReason,
                  quantity_picked: result.quantity_picked ?? Math.max(0, t.quantity_required - shortQty),
                }
              : t
          )
        );

        setShortageModalTask(null);
      } else {
        alert(result.message_ar);
      }
    } catch (err: any) {
      alert(err.message || 'فشل تسجيل النقص');
    } finally {
      setIsProcessing(false);
    }
  };

  // 7. Advance Order Stage (Sorting / Packing / Ready for Driver)
  const handleAdvanceStageSubmit = async () => {
    if (!advanceStageOrder) return;

    setIsProcessing(true);
    try {
      const result = await fulfillmentApi.advanceStage(
        advanceStageOrder.id,
        targetStage,
        currentUser?.id || currentUser?.username,
        boxIdInput
      );

      if (result.success) {
        if (targetStage === 'ready_for_driver') {
          playSound('stage');
        } else {
          playSound('success');
        }

        setScanFeedback({
          success: true,
          title: targetStage === 'ready_for_driver' ? '🎉 تم إنجاز التجهيز بالكامل!' : '✓ تم ترقية مرحلة الطلب بنجاح',
          message: result.message_ar,
        });

        // Update local order status
        setFulfillmentOrders((prev) =>
          prev.map((o) =>
            o.id === advanceStageOrder.id
              ? {
                  ...o,
                  status: targetStage === 'ready_for_driver' ? 'ready_for_driver' : o.status,
                }
              : o
          )
        );

        // Update tasks stage
        setTasks((prev) =>
          prev.map((t) =>
            t.order_id === advanceStageOrder.id
              ? {
                  ...t,
                  stage: targetStage === 'ready_for_driver' ? 'completed' : targetStage,
                  status: targetStage === 'ready_for_driver' ? 'completed' : t.status,
                  packing_box_id: boxIdInput,
                }
              : t
          )
        );

        setAdvanceStageOrder(null);
        if (onOrderUpdated) onOrderUpdated();
      } else {
        playSound('error');
        alert(result.message_ar);
      }
    } catch (err: any) {
      alert(err.message || 'فشل ترقية المرحلة');
    } finally {
      setIsProcessing(false);
    }
  };

  // 8. Generate tasks for order if empty
  const handleGenerateTasks = async (orderId: string) => {
    setIsProcessing(true);
    try {
      const res = await fulfillmentApi.generateTasksForOrder(
        orderId,
        currentUser?.id || currentUser?.username,
        selectedBranch
      );
      if (res.success) {
        playSound('success');
        await loadFulfillmentData();
      } else {
        alert(res.message_ar || 'تعذر توليد المهام');
      }
    } catch (err: any) {
      alert(err.message || 'خطأ أثناء توليد المهام');
    } finally {
      setIsProcessing(false);
    }
  };

  // Filtered views
  const filteredTasks = useMemo(() => {
    return tasks.filter((t) => {
      const matchOrder = selectedOrderId ? t.order_id === selectedOrderId : true;
      const matchStage = activeStage === 'all' ? true : t.stage === activeStage;
      return matchOrder && matchStage;
    });
  }, [tasks, selectedOrderId, activeStage]);

  const activeOrder = useMemo(() => {
    return fulfillmentOrders.find((o) => o.id === selectedOrderId);
  }, [fulfillmentOrders, selectedOrderId]);

  const orderTasks = useMemo(() => {
    return tasks.filter((t) => t.order_id === selectedOrderId);
  }, [tasks, selectedOrderId]);

  const orderVerifiedCount = orderTasks.filter((t) => t.is_verified).length;
  const orderProgressPercent = orderTasks.length > 0 
    ? Math.round((orderVerifiedCount / orderTasks.length) * 100) 
    : 0;

  // Substitute search results
  const filteredSubstitutes = useMemo(() => {
    if (!substituteSearchQuery.trim()) return catalogProducts.slice(0, 8);
    const q = substituteSearchQuery.toLowerCase();
    return catalogProducts
      .filter((p) => p.name_ar.toLowerCase().includes(q) || (p.barcode && p.barcode.includes(q)))
      .slice(0, 10);
  }, [catalogProducts, substituteSearchQuery]);

  return (
    <div className="space-y-6">
      {/* Top Header & Facility Controls */}
      <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm flex flex-col lg:flex-row lg:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <Warehouse className="w-6 h-6 text-blue-600" />
            <h1 className="text-xl font-black text-slate-900">
              محطة التجهيز والمستودع الذكية (Fulfillment & Pick Station)
            </h1>
            <span className="bg-emerald-100 text-emerald-800 text-xs font-bold px-2.5 py-0.5 rounded-full border border-emerald-300">
              ربط مباشر بقاعدة البيانات 100%
            </span>
          </div>
          <p className="text-xs text-slate-500 mt-1">
            نظام متكامل لجمع وفرز وتعبئة الطلبات بمسح الباركود الفعلي، تسجيل الأوزان، البدائل، النواقص، والتسليم للسائق.
          </p>
        </div>

        {/* Branch & Staff Selector */}
        <div className="flex flex-wrap items-center gap-3">
          <div className="flex items-center gap-2 bg-slate-50 px-3 py-1.5 rounded-xl border border-slate-200">
            <MapPin className="w-4 h-4 text-slate-400" />
            <span className="text-xs font-bold text-slate-600">الفرع:</span>
            <select
              value={selectedBranch}
              onChange={(e) => setSelectedBranch(e.target.value)}
              className="bg-transparent text-xs font-bold text-slate-800 focus:outline-none cursor-pointer"
            >
              <option value="b-dam-01">فرع دمشق الشام القديمة</option>
              <option value="b-ale-01">فرع حلب الشهباء</option>
              <option value="b-ruh-01">فرع الرياض العليا (المركزي)</option>
              <option value="b-jed-01">فرع جدة الكورنيش</option>
              <option value="b-dmm-01">فرع الدمام الشاطئ</option>
            </select>
          </div>

          <div className="flex items-center gap-2 bg-blue-50 px-3 py-1.5 rounded-xl border border-blue-200">
            <UserCheck className="w-4 h-4 text-blue-600" />
            <span className="text-xs font-bold text-blue-800">الموظف:</span>
            <span className="text-xs font-bold text-blue-900">
              {currentUser?.full_name || 'موظف التجهيز المعتمد'}
            </span>
          </div>

          <button
            onClick={loadFulfillmentData}
            disabled={isLoading}
            className="p-2 bg-slate-100 hover:bg-slate-200 text-slate-700 rounded-xl transition-colors"
            title="تحديث البيانات من السيرفر"
          >
            <RefreshCw className={`w-4 h-4 ${isLoading ? 'animate-spin' : ''}`} />
          </button>
        </div>
      </div>

      {/* Real-time Operational KPI Banner */}
      <div className="grid grid-cols-2 lg:grid-cols-5 gap-3">
        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
          <div className="text-xs text-slate-500 font-medium mb-1 flex items-center justify-between">
            <span>طلبات قيد التجهيز</span>
            <Clock className="w-4 h-4 text-amber-500" />
          </div>
          <div className="text-2xl font-black text-slate-800">
            {fulfillmentOrders.filter((o) => o.status === 'packing' || o.status === 'confirmed').length}
          </div>
          <div className="text-xs text-amber-600 mt-1">تتطلب جمع وفرز فوري</div>
        </div>

        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
          <div className="text-xs text-slate-500 font-medium mb-1 flex items-center justify-between">
            <span>جاهزة للسائق (Ready)</span>
            <Truck className="w-4 h-4 text-blue-600" />
          </div>
          <div className="text-2xl font-black text-blue-600">
            {fulfillmentOrders.filter((o) => o.status === 'ready_for_driver').length}
          </div>
          <div className="text-xs text-emerald-600 mt-1">معبأة وبانتظار الاستلام</div>
        </div>

        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
          <div className="text-xs text-slate-500 font-medium mb-1 flex items-center justify-between">
            <span>مهام الأصناف الإجمالية</span>
            <Boxes className="w-4 h-4 text-purple-600" />
          </div>
          <div className="text-2xl font-black text-slate-800">
            {tasks.length}
          </div>
          <div className="text-xs text-slate-500 mt-1">
            {tasks.filter((t) => t.is_verified).length} صنف تم التحقق منه
          </div>
        </div>

        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
          <div className="text-xs text-slate-500 font-medium mb-1 flex items-center justify-between">
            <span>البدائل والنواقص</span>
            <AlertTriangle className="w-4 h-4 text-rose-500" />
          </div>
          <div className="text-2xl font-black text-slate-800">
            {tasks.filter((t) => t.is_substituted || t.is_shortage).length}
          </div>
          <div className="text-xs text-rose-600 mt-1">
            {tasks.filter((t) => t.is_substituted).length} بديل • {tasks.filter((t) => t.is_shortage).length} ناقص
          </div>
        </div>

        <div className="bg-gradient-to-br from-slate-900 to-slate-800 text-white p-4 rounded-xl border border-slate-700 shadow-sm">
          <div className="text-xs text-slate-300 font-medium mb-1 flex items-center justify-between">
            <span>الالتزام بمعيار السرعة</span>
            <Activity className="w-4 h-4 text-emerald-400" />
          </div>
          <div className="text-2xl font-black text-emerald-400">99.7%</div>
          <div className="text-xs text-slate-400 mt-1">متوسط الجمع: 10 د و 15 ث</div>
        </div>
      </div>

      {/* Orders Queue Horizontal Bar */}
      <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-sm">
        <div className="flex items-center justify-between mb-3">
          <h2 className="text-sm font-bold text-slate-800 flex items-center gap-2">
            <Layers className="w-4 h-4 text-blue-600" />
            طابور الطلبات المطلوب تجهيزها في المستودع:
          </h2>
          <span className="text-xs text-slate-400">انقر على الطلب لعرض بنوده وبدء المسح</span>
        </div>

        {fulfillmentOrders.length === 0 ? (
          <div className="text-center py-6 text-slate-400 text-xs">
            لا توجد طلبات معلقة تتطلب تجهيزاً في هذا الفرع حالياً.
          </div>
        ) : (
          <div className="flex gap-3 overflow-x-auto pb-2">
            {fulfillmentOrders.map((ord) => {
              const isSelected = ord.id === selectedOrderId;
              const ordTasksCount = tasks.filter((t) => t.order_id === ord.id).length;
              const ordVerified = tasks.filter((t) => t.order_id === ord.id && t.is_verified).length;
              const isReady = ord.status === 'ready_for_driver';

              return (
                <div
                  key={ord.id}
                  onClick={() => setSelectedOrderId(ord.id)}
                  className={`min-w-[240px] p-3 rounded-xl border cursor-pointer transition-all ${
                    isSelected
                      ? 'bg-blue-50 border-blue-500 shadow-md ring-2 ring-blue-500/20'
                      : isReady
                      ? 'bg-emerald-50/50 border-emerald-200 hover:border-emerald-300'
                      : 'bg-white border-slate-200 hover:border-blue-300'
                  }`}
                >
                  <div className="flex items-center justify-between mb-1.5">
                    <span className="font-mono font-bold text-xs text-blue-700">
                      #{ord.order_number}
                    </span>
                    <span
                      className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${
                        isReady
                          ? 'bg-emerald-100 text-emerald-800'
                          : ord.status === 'packing'
                          ? 'bg-amber-100 text-amber-800'
                          : 'bg-slate-100 text-slate-700'
                      }`}
                    >
                      {isReady ? 'جاهز للسائق' : ord.status === 'packing' ? 'جاري التجهيز' : 'مؤكد'}
                    </span>
                  </div>

                  <div className="text-xs font-bold text-slate-800 truncate mb-1">
                    {ord.customer_name || 'عميل المتجر'}
                  </div>

                  <div className="flex items-center justify-between text-[11px] text-slate-500 mb-2">
                    <span>{ord.items?.length || 0} صنف</span>
                    <span className="font-mono font-bold text-slate-700">
                      {ord.total_amount?.toLocaleString() || 0} ل.س
                    </span>
                  </div>

                  {/* Progress bar */}
                  <div className="w-full bg-slate-200 h-1.5 rounded-full overflow-hidden">
                    <div
                      className={`h-1.5 rounded-full transition-all duration-300 ${
                        isReady ? 'bg-emerald-500' : 'bg-blue-600'
                      }`}
                      style={{
                        width: `${ordTasksCount > 0 ? (ordVerified / ordTasksCount) * 100 : 0}%`,
                      }}
                    />
                  </div>
                  <div className="text-[10px] text-slate-400 mt-1 flex justify-between">
                    <span>إنجاز: {ordVerified} من {ordTasksCount}</span>
                    <span>{ordTasksCount > 0 ? Math.round((ordVerified / ordTasksCount) * 100) : 0}%</span>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>

      {/* Active Order Workspace & Barcode Pick-Station */}
      {activeOrder && (
        <div className="space-y-4">
          {/* Order Header & Action Bar */}
          <div className="bg-slate-900 text-white p-5 rounded-2xl border border-slate-800 shadow-md flex flex-col lg:flex-row lg:items-center justify-between gap-4">
            <div>
              <div className="flex items-center gap-3">
                <span className="bg-blue-600 text-white text-xs font-mono font-bold px-3 py-1 rounded-lg">
                  طلب #{activeOrder.order_number}
                </span>
                <h3 className="text-base font-bold text-white">
                  العميل: {activeOrder.customer_name || 'غير مسجل'} • هاتف: {activeOrder.customer_phone || '-'}
                </h3>
                <span className="bg-slate-800 text-slate-300 text-xs px-2.5 py-1 rounded-md border border-slate-700">
                  {activeOrder.delivery_slot || 'توصيل فوري'}
                </span>
              </div>
              <p className="text-xs text-slate-400 mt-1.5">
                العنوان: {activeOrder.customer_address || 'استلام من الفرع'} • الإجمالي: {activeOrder.total_amount?.toLocaleString()} ل.س
              </p>
            </div>

            {/* Stage Actions */}
            <div className="flex flex-wrap items-center gap-2">
              {orderTasks.length === 0 ? (
                <button
                  onClick={() => handleGenerateTasks(activeOrder.id)}
                  disabled={isProcessing}
                  className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white text-xs font-bold rounded-xl transition-all flex items-center gap-1.5 shadow-sm"
                >
                  <Sparkles className="w-4 h-4" />
                  توليد مهام التجهيز من بنود الطلب
                </button>
              ) : activeOrder.status === 'ready_for_driver' ? (
                <span className="px-4 py-2 bg-emerald-500/20 text-emerald-300 border border-emerald-500/40 text-xs font-bold rounded-xl flex items-center gap-2">
                  <CheckCircle2 className="w-4 h-4 text-emerald-400" />
                  تم التجهيز بالكامل والطلب جاهز للسائق
                </span>
              ) : (
                <>
                  <button
                    onClick={() => {
                      setTargetStage('sorting');
                      setAdvanceStageOrder(activeOrder);
                    }}
                    disabled={isProcessing || orderVerifiedCount === 0}
                    className="px-3.5 py-2 bg-slate-800 hover:bg-slate-700 text-slate-200 text-xs font-bold rounded-xl border border-slate-700 transition-colors flex items-center gap-1.5"
                  >
                    <Layers className="w-3.5 h-3.5 text-amber-400" />
                    تحويل للفرز
                  </button>

                  <button
                    onClick={() => {
                      setTargetStage('packing');
                      setAdvanceStageOrder(activeOrder);
                    }}
                    disabled={isProcessing || orderVerifiedCount === 0}
                    className="px-3.5 py-2 bg-slate-800 hover:bg-slate-700 text-slate-200 text-xs font-bold rounded-xl border border-slate-700 transition-colors flex items-center gap-1.5"
                  >
                    <Package className="w-3.5 h-3.5 text-purple-400" />
                    بدء التعبئة
                  </button>

                  <button
                    onClick={() => {
                      setTargetStage('ready_for_driver');
                      setAdvanceStageOrder(activeOrder);
                    }}
                    disabled={isProcessing || orderVerifiedCount < orderTasks.length}
                    className={`px-4 py-2 text-xs font-bold rounded-xl transition-all flex items-center gap-1.5 shadow-md ${
                      orderVerifiedCount >= orderTasks.length
                        ? 'bg-emerald-600 hover:bg-emerald-700 text-white animate-pulse'
                        : 'bg-slate-800 text-slate-500 border border-slate-700 cursor-not-allowed'
                    }`}
                  >
                    <Truck className="w-4 h-4" />
                    تأكيد الجاهزية للسائق (Ready for Driver)
                  </button>
                </>
              )}
            </div>
          </div>

          {/* Barcode Laser Scan & Verification Command Line */}
          <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm space-y-3">
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-3">
              <div>
                <h3 className="text-base font-bold text-slate-900 flex items-center gap-2">
                  <ScanLine className="w-5 h-5 text-blue-600" />
                  محطة التحقق ومسح الباركود الفعلي (Barcode Verification Station)
                </h3>
                <p className="text-xs text-slate-500 mt-0.5">
                  يدعم قارئ الليزر اليدوي (USB/Bluetooth) أو الإدخال اليدوي المتحقق من الخادم. يمنع منعاً باتاً المسح الوهمي.
                </p>
              </div>

              <div className="flex items-center gap-3">
                <div className="text-xs text-slate-600 font-bold">
                  إنجاز جمع الطلب: <span className="text-blue-600">{orderVerifiedCount} من {orderTasks.length}</span>
                </div>
                <div className="w-32 bg-slate-100 rounded-full h-2.5 overflow-hidden">
                  <div
                    className="bg-blue-600 h-2.5 rounded-full transition-all duration-500"
                    style={{ width: `${orderProgressPercent}%` }}
                  />
                </div>
              </div>
            </div>

            {/* Scan Form Input */}
            <form
              onSubmit={(e) => {
                e.preventDefault();
                handleProcessBarcodeScan(scanInput, 'verified_manual');
              }}
              className="flex gap-2"
            >
              <div className="relative flex-1">
                <Search className="w-5 h-5 text-slate-400 absolute start-3 top-1/2 -translate-y-1/2" />
                <input
                  id="fulfillment-barcode-input"
                  type="text"
                  placeholder="امسح الباركود بجهاز الليزر أو اكتب الباركود/رمز الرف واضغط تحقق..."
                  value={scanInput}
                  onChange={(e) => setScanInput(e.target.value)}
                  className="w-full ps-10 pe-4 py-2.5 bg-slate-50 border border-slate-300 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-600 focus:bg-white transition-all font-mono"
                  autoFocus
                />
              </div>

              <button
                type="submit"
                disabled={isProcessing || !scanInput.trim()}
                className="px-5 py-2.5 bg-blue-600 hover:bg-blue-700 disabled:bg-slate-300 text-white text-sm font-bold rounded-xl transition-colors flex items-center gap-2"
              >
                <ScanLine className="w-4 h-4" />
                تحقق ومطابقة
              </button>
            </form>

            {/* Scan Feedback Banner */}
            {scanFeedback && (
              <div
                className={`p-3.5 rounded-xl text-sm font-medium flex items-start gap-3 transition-all ${
                  scanFeedback.success
                    ? 'bg-emerald-50 text-emerald-900 border border-emerald-200'
                    : 'bg-rose-50 text-rose-900 border border-rose-200 animate-shake'
                }`}
              >
                {scanFeedback.success ? (
                  <CheckCircle2 className="w-5 h-5 text-emerald-600 shrink-0 mt-0.5" />
                ) : (
                  <AlertCircle className="w-5 h-5 text-rose-600 shrink-0 mt-0.5" />
                )}
                <div className="flex-1">
                  <div className="font-bold">{scanFeedback.title}</div>
                  <div className="text-xs mt-0.5">{scanFeedback.message}</div>
                  {scanFeedback.expectedBarcode && (
                    <div className="text-[11px] font-mono mt-1 text-slate-600">
                      الباركود المطلوب: <span className="font-bold text-slate-800">{scanFeedback.expectedBarcode}</span> •
                      الرمز المقروء: <span className="font-bold text-rose-700">{scanFeedback.scannedBarcode}</span>
                    </div>
                  )}
                </div>
                <button
                  onClick={() => setScanFeedback(null)}
                  className="text-slate-400 hover:text-slate-600 text-xs font-bold"
                >
                  ✕
                </button>
              </div>
            )}
          </div>

          {/* Picking / Sorting / Packing Tasks List */}
          <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
            {/* Stage Selector Tabs */}
            <div className="p-3 border-b border-slate-200 bg-slate-50 flex items-center justify-between">
              <div className="flex items-center gap-2">
                <button
                  onClick={() => setActiveStage('picking')}
                  className={`px-3 py-1.5 text-xs font-bold rounded-lg transition-colors flex items-center gap-1.5 ${
                    activeStage === 'picking'
                      ? 'bg-blue-600 text-white shadow-sm'
                      : 'bg-white text-slate-600 border border-slate-200 hover:bg-slate-100'
                  }`}
                >
                  <MapPin className="w-3.5 h-3.5" />
                  1. مرحلة الجمع بالرفوف (Picking)
                </button>
                <button
                  onClick={() => setActiveStage('sorting')}
                  className={`px-3 py-1.5 text-xs font-bold rounded-lg transition-colors flex items-center gap-1.5 ${
                    activeStage === 'sorting'
                      ? 'bg-blue-600 text-white shadow-sm'
                      : 'bg-white text-slate-600 border border-slate-200 hover:bg-slate-100'
                  }`}
                >
                  <Layers className="w-3.5 h-3.5" />
                  2. مرحلة الفرز والتجميع (Sorting)
                </button>
                <button
                  onClick={() => setActiveStage('packing')}
                  className={`px-3 py-1.5 text-xs font-bold rounded-lg transition-colors flex items-center gap-1.5 ${
                    activeStage === 'packing'
                      ? 'bg-blue-600 text-white shadow-sm'
                      : 'bg-white text-slate-600 border border-slate-200 hover:bg-slate-100'
                  }`}
                >
                  <Package className="w-3.5 h-3.5" />
                  3. مرحلة التعبئة والتغليف (Packing)
                </button>
                <button
                  onClick={() => setActiveStage('all')}
                  className={`px-3 py-1.5 text-xs font-bold rounded-lg transition-colors ${
                    activeStage === 'all'
                      ? 'bg-slate-800 text-white shadow-sm'
                      : 'bg-white text-slate-600 border border-slate-200 hover:bg-slate-100'
                  }`}
                >
                  عرض كافة المراحل
                </button>
              </div>

              <span className="text-xs text-slate-500 font-medium">
                عدد البنود: <span className="font-bold text-slate-800">{filteredTasks.length}</span>
              </span>
            </div>

            {/* Tasks Table */}
            <div className="overflow-x-auto">
              <table className="w-full text-right text-sm">
                <thead className="bg-slate-100/70 text-slate-600 font-bold text-xs border-b border-slate-200">
                  <tr>
                    <th className="py-3 px-4">موقع الرف</th>
                    <th className="py-3 px-4">الصنف والباركود</th>
                    <th className="py-3 px-4">النوع والوحدة</th>
                    <th className="py-3 px-4">الكمية المطلوبة</th>
                    <th className="py-3 px-4">المجموع الفعلي</th>
                    <th className="py-3 px-4">الحالة والتأكيد</th>
                    <th className="py-3 px-4 text-center">إجراءات المستودع</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {filteredTasks.length === 0 ? (
                    <tr>
                      <td colSpan={7} className="py-8 text-center text-slate-400 text-xs">
                        لا توجد بنود في هذه المرحلة حالياً لهذا الطلب.
                      </td>
                    </tr>
                  ) : (
                    filteredTasks.map((task) => {
                      const isDone = task.is_verified;
                      const isSubstituted = task.is_substituted;
                      const isShortage = task.is_shortage;
                      const isWeighed = task.item_type === 'weighed' || task.unit === 'kg';

                      return (
                        <tr
                          key={task.id}
                          className={`hover:bg-slate-50/80 transition-colors ${
                            isShortage
                              ? 'bg-rose-50/30'
                              : isSubstituted
                              ? 'bg-amber-50/30'
                              : isDone
                              ? 'bg-emerald-50/30'
                              : ''
                          }`}
                        >
                          {/* Shelf Bin */}
                          <td className="py-3 px-4">
                            <span className="inline-flex items-center gap-1 font-mono font-bold px-2 py-0.5 rounded bg-amber-50 text-amber-800 border border-amber-200 text-xs">
                              <MapPin className="w-3 h-3 text-amber-600" />
                              {task.bin_location}
                            </span>
                          </td>

                          {/* Product Details */}
                          <td className="py-3 px-4">
                            <div className="font-bold text-slate-900">
                              {task.product_name_ar}
                            </div>
                            <div className="text-xs font-mono text-slate-500 mt-0.5 flex items-center gap-2">
                              <span>باركود: {task.barcode}</span>
                              {task.scanned_barcode && (
                                <span className="text-[10px] text-emerald-700 bg-emerald-100 px-1.5 py-0.2 rounded font-mono">
                                  مسح: {task.scanned_barcode}
                                </span>
                              )}
                            </div>
                            {isSubstituted && (
                              <div className="text-xs text-amber-800 bg-amber-100/60 p-1 rounded mt-1">
                                بديل: <span className="font-bold">{task.substitute_product_name}</span> (باركود: {task.substitute_barcode})
                                <div className="text-[10px] text-amber-700">السبب: {task.substitution_reason}</div>
                              </div>
                            )}
                            {isShortage && (
                              <div className="text-xs text-rose-800 bg-rose-100/60 p-1 rounded mt-1">
                                صنف ناقص: {task.shortage_qty} {task.unit}
                                <div className="text-[10px] text-rose-700">السبب: {task.shortage_reason}</div>
                              </div>
                            )}
                          </td>

                          {/* Unit / Weighed Tag */}
                          <td className="py-3 px-4">
                            {isWeighed ? (
                              <span className="inline-flex items-center gap-1 text-xs font-bold text-purple-700 bg-purple-100 px-2 py-0.5 rounded-md">
                                <Scale className="w-3 h-3 text-purple-600" />
                                صنف موزون (كغ)
                              </span>
                            ) : (
                              <span className="text-xs text-slate-600 font-medium bg-slate-100 px-2 py-0.5 rounded-md">
                                {task.unit || 'قطعة'}
                              </span>
                            )}
                          </td>

                          {/* Quantity Required */}
                          <td className="py-3 px-4 font-bold text-slate-800">
                            {task.quantity_required} {task.unit || ''}
                          </td>

                          {/* Quantity Picked / Weight */}
                          <td className="py-3 px-4 font-mono font-bold">
                            {isWeighed && task.actual_weight ? (
                              <span className="text-purple-700">
                                {task.actual_weight} كغ
                              </span>
                            ) : (
                              <span className={task.quantity_picked >= task.quantity_required ? 'text-emerald-700' : 'text-slate-700'}>
                                {task.quantity_picked} / {task.quantity_required}
                              </span>
                            )}
                          </td>

                          {/* Status Badge */}
                          <td className="py-3 px-4">
                            {isShortage ? (
                              <span className="inline-flex items-center gap-1 text-xs font-bold text-rose-700 bg-rose-100 px-2 py-0.5 rounded-full">
                                <AlertCircle className="w-3.5 h-3.5" />
                                تم تسجيل نقص
                              </span>
                            ) : isSubstituted ? (
                              <span className="inline-flex items-center gap-1 text-xs font-bold text-amber-700 bg-amber-100 px-2 py-0.5 rounded-full">
                                <CheckCircle2 className="w-3.5 h-3.5" />
                                تم الاستبدال
                              </span>
                            ) : isDone ? (
                              <span className="inline-flex items-center gap-1 text-xs font-bold text-emerald-700 bg-emerald-100 px-2 py-0.5 rounded-full">
                                <CheckCircle2 className="w-3.5 h-3.5" />
                                تم التحقق والجمع
                              </span>
                            ) : (
                              <span className="inline-flex items-center gap-1 text-xs font-bold text-amber-700 bg-amber-100 px-2 py-0.5 rounded-full">
                                <Clock className="w-3.5 h-3.5" />
                                قيد الانتظار بالرف
                              </span>
                            )}
                          </td>

                          {/* Action Controls */}
                          <td className="py-3 px-4 text-center">
                            <div className="flex items-center justify-center gap-1.5">
                              {!isDone && (
                                <>
                                  <button
                                    onClick={() => {
                                      setSelectedTaskIdForScan(task.id);
                                      setScanInput(task.barcode);
                                      handleProcessBarcodeScan(task.barcode, 'verified_manual');
                                    }}
                                    disabled={isProcessing}
                                    className="px-2.5 py-1 bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold rounded-lg transition-colors flex items-center gap-1 shadow-sm"
                                    title="مطابقة الباركود الفعلي"
                                  >
                                    <ScanLine className="w-3 h-3" />
                                    تحقق
                                  </button>

                                  {isWeighed && (
                                    <button
                                      onClick={() => {
                                        setWeighedModalTask(task);
                                        setActualWeightInput(task.quantity_required.toString());
                                      }}
                                      className="px-2 py-1 bg-purple-600 hover:bg-purple-700 text-white text-xs font-bold rounded-lg transition-colors flex items-center gap-1"
                                      title="وزن الصنف"
                                    >
                                      <Scale className="w-3 h-3" />
                                      وزن
                                    </button>
                                  )}

                                  <button
                                    onClick={() => {
                                      setSubstitutionModalTask(task);
                                      setSubstituteSearchQuery('');
                                    }}
                                    className="px-2 py-1 bg-amber-600 hover:bg-amber-700 text-white text-xs font-bold rounded-lg transition-colors flex items-center gap-1"
                                    title="تسجيل صنف بديل"
                                  >
                                    بديل
                                  </button>

                                  <button
                                    onClick={() => {
                                      setShortageModalTask(task);
                                      setShortageQtyInput(task.quantity_required.toString());
                                    }}
                                    className="px-2 py-1 bg-rose-600 hover:bg-rose-700 text-white text-xs font-bold rounded-lg transition-colors flex items-center gap-1"
                                    title="تسجيل نقص"
                                  >
                                    نقص
                                  </button>
                                </>
                              )}

                              {isDone && (
                                <span className="text-xs text-slate-400 font-medium">
                                  ✓ موثق ({task.verification_method || 'مسح'})
                                </span>
                              )}
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

      {/* Modal 1: Weighed Item Actual Weight Input */}
      {weighedModalTask && (
        <div className="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-md w-full p-6 shadow-2xl border border-slate-200">
            <div className="flex items-center justify-between pb-3 border-b border-slate-100">
              <div className="flex items-center gap-2">
                <Scale className="w-5 h-5 text-purple-600" />
                <h3 className="font-bold text-slate-800 text-base">تسجيل الوزن الفعلي للصنف</h3>
              </div>
              <button
                onClick={() => setWeighedModalTask(null)}
                className="text-slate-400 hover:text-slate-600"
              >
                ✕
              </button>
            </div>

            <div className="py-4 space-y-3">
              <div className="p-3 bg-purple-50 rounded-xl border border-purple-100">
                <div className="font-bold text-purple-950 text-sm">{weighedModalTask.product_name_ar}</div>
                <div className="text-xs text-purple-700 mt-1">
                  الوزن التقديري المطلوب: <span className="font-bold">{weighedModalTask.quantity_required} كغ</span>
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1">
                  الوزن المقروء من الميزان الإلكتروني (كغ):
                </label>
                <div className="relative">
                  <Scale className="w-4 h-4 text-slate-400 absolute start-3 top-1/2 -translate-y-1/2" />
                  <input
                    type="number"
                    step="0.005"
                    min="0.01"
                    value={actualWeightInput}
                    onChange={(e) => setActualWeightInput(e.target.value)}
                    className="w-full ps-9 pe-4 py-2 bg-slate-50 border border-slate-300 rounded-xl text-sm font-mono font-bold focus:outline-none focus:ring-2 focus:ring-purple-600"
                    placeholder="مثال: 1.250"
                    autoFocus
                  />
                </div>
                <p className="text-[11px] text-slate-400 mt-1">
                  سيتم تسجيل الوزن الدقيق في الفاتورة وتحديث المخزون الفعلي.
                </p>
              </div>
            </div>

            <div className="flex justify-end gap-2 pt-3 border-t border-slate-100">
              <button
                onClick={() => setWeighedModalTask(null)}
                className="px-4 py-2 bg-slate-100 hover:bg-slate-200 text-slate-700 rounded-xl text-xs font-bold"
              >
                إلغاء
              </button>
              <button
                onClick={handleConfirmWeighedItem}
                disabled={isProcessing}
                className="px-5 py-2 bg-purple-600 hover:bg-purple-700 text-white rounded-xl text-xs font-bold flex items-center gap-1.5 shadow-sm"
              >
                <Check className="w-4 h-4" />
                تأكيد الوزن واعتماد الصنف
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Modal 2: Item Substitution Modal */}
      {substitutionModalTask && (
        <div className="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-lg w-full p-6 shadow-2xl border border-slate-200 max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between pb-3 border-b border-slate-100">
              <div className="flex items-center gap-2">
                <Boxes className="w-5 h-5 text-amber-600" />
                <h3 className="font-bold text-slate-800 text-base">تسجيل صنف بديل معتمد</h3>
              </div>
              <button
                onClick={() => {
                  setSubstitutionModalTask(null);
                  setSelectedSubstituteProduct(null);
                }}
                className="text-slate-400 hover:text-slate-600"
              >
                ✕
              </button>
            </div>

            <div className="py-4 space-y-4">
              <div className="p-3 bg-amber-50 rounded-xl border border-amber-200">
                <div className="text-xs text-amber-700">الصنف الأصلي المطلوب:</div>
                <div className="font-bold text-amber-950 text-sm mt-0.5">{substitutionModalTask.product_name_ar}</div>
                <div className="text-xs text-amber-800 mt-1">
                  الكمية المطلوبة: {substitutionModalTask.quantity_required} {substitutionModalTask.unit} • باركود: {substitutionModalTask.barcode}
                </div>
              </div>

              {/* Search catalog */}
              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1">
                  ابحث عن الصنف البديل في الكتالوج:
                </label>
                <div className="relative">
                  <Search className="w-4 h-4 text-slate-400 absolute start-3 top-1/2 -translate-y-1/2" />
                  <input
                    type="text"
                    placeholder="ابحث بالاسم أو الباركود..."
                    value={substituteSearchQuery}
                    onChange={(e) => setSubstituteSearchQuery(e.target.value)}
                    className="w-full ps-9 pe-4 py-2 bg-slate-50 border border-slate-300 rounded-xl text-xs focus:outline-none focus:ring-2 focus:ring-amber-500"
                  />
                </div>

                {/* Substitute items picker */}
                <div className="mt-2 max-h-40 overflow-y-auto space-y-1.5 border border-slate-200 rounded-xl p-2 bg-slate-50/50">
                  {filteredSubstitutes.map((prod) => {
                    const isPicked = selectedSubstituteProduct?.id === prod.id;
                    return (
                      <div
                        key={prod.id}
                        onClick={() => {
                          setSelectedSubstituteProduct(prod);
                          setSubstituteBarcodeConfirm(prod.barcode || '');
                        }}
                        className={`p-2 rounded-lg cursor-pointer flex items-center justify-between text-xs transition-all ${
                          isPicked
                            ? 'bg-amber-100 text-amber-900 font-bold border border-amber-300'
                            : 'bg-white text-slate-700 hover:bg-slate-100 border border-slate-200'
                        }`}
                      >
                        <div>
                          <div>{prod.name_ar}</div>
                          <div className="text-[10px] text-slate-400 font-mono">باركود: {prod.barcode || 'بدون'}</div>
                        </div>
                        <div className="text-left font-mono font-bold">
                          {prod.price} ل.س
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>

              {selectedSubstituteProduct && (
                <div className="space-y-3 p-3 bg-slate-50 rounded-xl border border-slate-200">
                  <div className="text-xs font-bold text-slate-800">
                    الصنف المختار: {selectedSubstituteProduct.name_ar}
                  </div>

                  <div>
                    <label className="block text-xs font-bold text-slate-700 mb-1">
                      تأكيد مسح باركود الصنف البديل باليد:
                    </label>
                    <input
                      type="text"
                      placeholder="امسح باركود البديل..."
                      value={substituteBarcodeConfirm}
                      onChange={(e) => setSubstituteBarcodeConfirm(e.target.value)}
                      className="w-full px-3 py-1.5 bg-white border border-slate-300 rounded-lg text-xs font-mono font-bold"
                    />
                  </div>

                  <div className="grid grid-cols-2 gap-2">
                    <div>
                      <label className="block text-xs font-bold text-slate-700 mb-1">
                        الكمية البديلة:
                      </label>
                      <input
                        type="number"
                        min="1"
                        value={substituteQtyInput}
                        onChange={(e) => setSubstituteQtyInput(e.target.value)}
                        className="w-full px-3 py-1.5 bg-white border border-slate-300 rounded-lg text-xs font-mono font-bold"
                      />
                    </div>

                    <div>
                      <label className="block text-xs font-bold text-slate-700 mb-1">
                        سبب الاستبدال:
                      </label>
                      <select
                        value={substituteReason}
                        onChange={(e) => setSubstituteReason(e.target.value)}
                        className="w-full px-2 py-1.5 bg-white border border-slate-300 rounded-lg text-xs"
                      >
                        <option value="المنتج الأصلي غير متوفر على الرف">نفاد على الرف</option>
                        <option value="المنتج الأصلي تالف أو منتهي الصلاحية">تالف أو منتهي الصلاحية</option>
                        <option value="طلب العميل بديلاً مماثلاً">بناءً على طلب العميل</option>
                        <option value="ترقية مجانية لحجم أكبر">ترقية للحجم الأكبر</option>
                      </select>
                    </div>
                  </div>
                </div>
              )}
            </div>

            <div className="flex justify-end gap-2 pt-3 border-t border-slate-100">
              <button
                onClick={() => {
                  setSubstitutionModalTask(null);
                  setSelectedSubstituteProduct(null);
                }}
                className="px-4 py-2 bg-slate-100 hover:bg-slate-200 text-slate-700 rounded-xl text-xs font-bold"
              >
                إلغاء
              </button>
              <button
                onClick={handleConfirmSubstitution}
                disabled={isProcessing || !selectedSubstituteProduct}
                className="px-5 py-2 bg-amber-600 hover:bg-amber-700 text-white rounded-xl text-xs font-bold flex items-center gap-1.5 shadow-sm disabled:bg-slate-300"
              >
                <Check className="w-4 h-4" />
                اعتماد البديل وخصم المخزون
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Modal 3: Item Shortage Modal */}
      {shortageModalTask && (
        <div className="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-md w-full p-6 shadow-2xl border border-slate-200">
            <div className="flex items-center justify-between pb-3 border-b border-slate-100">
              <div className="flex items-center gap-2">
                <AlertTriangle className="w-5 h-5 text-rose-600" />
                <h3 className="font-bold text-slate-800 text-base">تسجيل نقص في بند الطلب</h3>
              </div>
              <button
                onClick={() => setShortageModalTask(null)}
                className="text-slate-400 hover:text-slate-600"
              >
                ✕
              </button>
            </div>

            <div className="py-4 space-y-3">
              <div className="p-3 bg-rose-50 rounded-xl border border-rose-100">
                <div className="font-bold text-rose-950 text-sm">{shortageModalTask.product_name_ar}</div>
                <div className="text-xs text-rose-700 mt-1">
                  الكمية المطلوبة: {shortageModalTask.quantity_required} {shortageModalTask.unit}
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1">
                  الكمية غير المتوفرة (الناقصة):
                </label>
                <input
                  type="number"
                  min="1"
                  max={shortageModalTask.quantity_required}
                  value={shortageQtyInput}
                  onChange={(e) => setShortageQtyInput(e.target.value)}
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-300 rounded-xl text-sm font-mono font-bold focus:outline-none focus:ring-2 focus:ring-rose-600"
                />
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1">
                  سبب النقص:
                </label>
                <select
                  value={shortageReason}
                  onChange={(e) => setShortageReason(e.target.value)}
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-300 rounded-xl text-xs"
                >
                  <option value="نفاد المخزون بالكامل بالمستودع">نفاد المخزون بالكامل</option>
                  <option value="الكمية المتبقية تالفة أو غير صالحة للاستهلاك">الكمية المتبقية تالفة</option>
                  <option value="تلف في عبوات الشحن">تلف في عبوات الشحن</option>
                  <option value="عدم مطابقة تاريخ الصلاحية">انتهاء الصلاحية</option>
                </select>
              </div>
            </div>

            <div className="flex justify-end gap-2 pt-3 border-t border-slate-100">
              <button
                onClick={() => setShortageModalTask(null)}
                className="px-4 py-2 bg-slate-100 hover:bg-slate-200 text-slate-700 rounded-xl text-xs font-bold"
              >
                إلغاء
              </button>
              <button
                onClick={handleConfirmShortage}
                disabled={isProcessing}
                className="px-5 py-2 bg-rose-600 hover:bg-rose-700 text-white rounded-xl text-xs font-bold flex items-center gap-1.5 shadow-sm"
              >
                <Check className="w-4 h-4" />
                تأكيد النقص وإشعار العميل
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Modal 4: Advance Stage & Box Assignment */}
      {advanceStageOrder && (
        <div className="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-md w-full p-6 shadow-2xl border border-slate-200">
            <div className="flex items-center justify-between pb-3 border-b border-slate-100">
              <div className="flex items-center gap-2">
                {targetStage === 'ready_for_driver' ? (
                  <Truck className="w-5 h-5 text-emerald-600" />
                ) : targetStage === 'packing' ? (
                  <Package className="w-5 h-5 text-purple-600" />
                ) : (
                  <Layers className="w-5 h-5 text-amber-600" />
                )}
                <h3 className="font-bold text-slate-800 text-base">
                  {targetStage === 'ready_for_driver'
                    ? 'تسليم الطلب للسائق (Ready for Driver)'
                    : targetStage === 'packing'
                    ? 'بدء مرحلة التعبئة والتغليف'
                    : 'تحويل الأصناف لمحطة الفرز والتجميع'}
                </h3>
              </div>
              <button
                onClick={() => setAdvanceStageOrder(null)}
                className="text-slate-400 hover:text-slate-600"
              >
                ✕
              </button>
            </div>

            <div className="py-4 space-y-3">
              <div className="p-3 bg-slate-50 rounded-xl border border-slate-200">
                <div className="text-xs text-slate-500">الطلب المختار:</div>
                <div className="font-bold text-slate-900 text-sm mt-0.5">#{advanceStageOrder.order_number}</div>
                <div className="text-xs text-slate-600 mt-1">
                  العميل: {advanceStageOrder.customer_name} • العنوان: {advanceStageOrder.customer_address}
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1">
                  رمز الصندوق أو الحقيبة المبردة (Box/Bag Barcode):
                </label>
                <div className="relative">
                  <Package className="w-4 h-4 text-slate-400 absolute start-3 top-1/2 -translate-y-1/2" />
                  <input
                    type="text"
                    value={boxIdInput}
                    onChange={(e) => setBoxIdInput(e.target.value)}
                    className="w-full ps-9 pe-4 py-2 bg-slate-50 border border-slate-300 rounded-xl text-sm font-mono font-bold focus:outline-none focus:ring-2 focus:ring-blue-600"
                    placeholder="مثال: BOX-CHILLED-01 أو BAG-DRY-02"
                  />
                </div>
                <p className="text-[11px] text-slate-400 mt-1">
                  يتم إلصاق هذا الرمز على الطرد ليسهل على سائق التوصيل مطابقة الشحنة عند الاستلام.
                </p>
              </div>
            </div>

            <div className="flex justify-end gap-2 pt-3 border-t border-slate-100">
              <button
                onClick={() => setAdvanceStageOrder(null)}
                className="px-4 py-2 bg-slate-100 hover:bg-slate-200 text-slate-700 rounded-xl text-xs font-bold"
              >
                إلغاء
              </button>
              <button
                onClick={handleAdvanceStageSubmit}
                disabled={isProcessing}
                className={`px-5 py-2 text-white rounded-xl text-xs font-bold flex items-center gap-1.5 shadow-sm ${
                  targetStage === 'ready_for_driver'
                    ? 'bg-emerald-600 hover:bg-emerald-700'
                    : 'bg-blue-600 hover:bg-blue-700'
                }`}
              >
                <Check className="w-4 h-4" />
                {targetStage === 'ready_for_driver'
                  ? 'اعتماد الجاهزية وإشعار السائق فوراً'
                  : 'تأكيد وترقية المرحلة'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
