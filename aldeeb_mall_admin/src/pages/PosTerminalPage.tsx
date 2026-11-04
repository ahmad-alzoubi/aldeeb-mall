import React, { useState, useEffect, useRef, useMemo } from 'react';
import { 
  Check,
  Barcode, 
  Search, 
  Plus, 
  Minus, 
  Trash2, 
  CreditCard, 
  DollarSign, 
  Receipt, 
  Printer, 
  PauseCircle, 
  PlayCircle, 
  RefreshCw, 
  User, 
  Phone, 
  ShoppingBag, 
  CheckCircle2, 
  X, 
  Maximize2, 
  Minimize2, 
  Lock, 
  Unlock, 
  Clock, 
  Store, 
  ChevronRight, 
  ChevronLeft, 
  Layers, 
  Sparkles, 
  QrCode, 
  ShieldCheck, 
  ArrowLeftRight,
  TrendingUp,
  Percent,
  Coins,
  Volume2,
  VolumeX,
  ArrowDownRight,
  ArrowUpRight,
  History,
  AlertTriangle,
  FileText,
  Copy,
  Eye,
  Info
} from 'lucide-react';
import { Product, Branch, PosCartItem, ParkedCart, PosShift, PosTransaction, Category, Order, CashierShiftMovement, StaffMember } from '../types';
import { supabase, initialProducts, initialCategories } from '../lib/supabase';
import { getStoredBranches, getActiveBranchId, setActiveBranchId } from '../lib/branchesData';
import { ThermalReceiptView } from '../components/ThermalReceiptView';
import { useInvoiceSettings, recordInvoicePrintInDb } from '../lib/invoiceSettings';
import { calculateSyrianTaxes, ACTIVE_SYRIAN_TAX_RULE } from '../lib/syrianTaxEngine';

// Shared singleton AudioContext to prevent browser instance exhaustion and audio suspension
let sharedAudioCtx: AudioContext | null = null;
const getAudioContext = (): AudioContext | null => {
  try {
    const AudioCtx = window.AudioContext || (window as any).webkitAudioContext;
    if (!AudioCtx) return null;
    if (!sharedAudioCtx || sharedAudioCtx.state === 'closed') {
      sharedAudioCtx = new AudioCtx();
    }
    if (sharedAudioCtx.state === 'suspended') {
      sharedAudioCtx.resume().catch(() => {});
    }
    return sharedAudioCtx;
  } catch (_) {
    return null;
  }
};

// Cash payment sound using uploaded audio file with instant preloading & Web Audio fallback
let preloadedPaymentAudio: HTMLAudioElement | null = null;
const getPaymentAudio = () => {
  if (typeof window === 'undefined') return null;
  if (!preloadedPaymentAudio) {
    try {
      preloadedPaymentAudio = new Audio(`${import.meta.env.BASE_URL}sounds/cash_payment.mp3`);
      preloadedPaymentAudio.preload = 'auto';
    } catch (_) {}
  }
  return preloadedPaymentAudio;
};

// Play Payment Cash Sound (uploaded mp3 with fallback)
const playPaymentSound = (enabled: boolean = true) => {
  if (!enabled) return;
  try {
    const audio = getPaymentAudio();
    if (audio) {
      audio.currentTime = 0;
      const promise = audio.play();
      if (promise !== undefined) {
        promise.catch(() => {
          playCashRegisterSound(enabled);
        });
      }
      return;
    }
  } catch (_) {}
  playCashRegisterSound(enabled);
};

// Supermarket barcode scanner beep when adding/moving products to cart ("صوت نقل وإضافة المنتجات")
const playProductBeep = () => {
  try {
    const ctx = getAudioContext();
    if (!ctx) return;
    const now = ctx.currentTime;
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();

    osc.type = 'sine';
    osc.frequency.setValueAtTime(1400, now);
    gain.gain.setValueAtTime(0.16, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.08);

    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.start(now);
    osc.stop(now + 0.08);
  } catch (_) {}
};

// Synthesize realistic Cash Register & Coin Sound ("Cha-Ching" & Coins Drop)
const playCashRegisterSound = (enabled: boolean = true) => {
  if (!enabled) return;
  try {
    const ctx = getAudioContext();
    if (!ctx) return;
    const now = ctx.currentTime;

    // Helper: play metallic coin chime
    const playCoin = (freq: number, start: number, duration: number, gainVal: number) => {
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.type = 'triangle';
      osc.frequency.setValueAtTime(freq, start);
      osc.frequency.exponentialRampToValueAtTime(freq * 0.98, start + duration);
      gain.gain.setValueAtTime(gainVal, start);
      gain.gain.exponentialRampToValueAtTime(0.0001, start + duration);
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start(start);
      osc.stop(start + duration);
    };

    // Helper: play bell chime
    const playBell = (freq: number, start: number, duration: number, gainVal: number) => {
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.type = 'sine';
      osc.frequency.setValueAtTime(freq, start);
      gain.gain.setValueAtTime(gainVal, start);
      gain.gain.exponentialRampToValueAtTime(0.0001, start + duration);
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start(start);
      osc.stop(start + duration);
    };

    // Helper: mechanical register click/thud
    const playClick = (freq: number, start: number, duration: number, gainVal: number) => {
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.type = 'square';
      osc.frequency.setValueAtTime(freq, start);
      osc.frequency.exponentialRampToValueAtTime(80, start + duration);
      gain.gain.setValueAtTime(gainVal, start);
      gain.gain.exponentialRampToValueAtTime(0.0001, start + duration);
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start(start);
      osc.stop(start + duration);
    };

    // 1. Mechanical register latch click
    playClick(240, now, 0.05, 0.15);
    playClick(160, now + 0.04, 0.06, 0.12);

    // 2. "Cha" - Coin rattle & initial bell strike
    playBell(1850, now + 0.03, 0.25, 0.18);
    playCoin(2400, now + 0.05, 0.18, 0.15);
    playCoin(2850, now + 0.08, 0.22, 0.14);

    // 3. "Ching!" - High crisp register bell ring
    playBell(3136, now + 0.12, 0.65, 0.28); // High E7 chime
    playBell(3920, now + 0.14, 0.55, 0.20); // High G7 overtone
    playCoin(3520, now + 0.16, 0.45, 0.16);

    // 4. Coins jingling into drawer
    playCoin(2637, now + 0.22, 0.25, 0.14);
    playCoin(3296, now + 0.28, 0.30, 0.15);
    playCoin(2093, now + 0.35, 0.35, 0.12);
  } catch (_) {}
};

// Synthesize pleasant sound effects with Web Audio API
const playSound = (type: 'beep' | 'success' | 'cash' | 'error', enabled: boolean = true) => {
  if (type === 'beep') {
    // صوت نقل وإضافة المنتجات إلى السلة يعمل دائماً باستقرار فوري
    playProductBeep();
    return;
  }
  if (type === 'cash') {
    playPaymentSound(enabled);
    return;
  }
  if (!enabled) return;
  try {
    const ctx = getAudioContext();
    if (!ctx) return;
    const now = ctx.currentTime;
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.connect(gain);
    gain.connect(ctx.destination);

    if (type === 'success') {
      osc.frequency.setValueAtTime(800, now);
      osc.frequency.exponentialRampToValueAtTime(1200, now + 0.15);
      gain.gain.setValueAtTime(0.15, now);
      gain.gain.exponentialRampToValueAtTime(0.01, now + 0.25);
      osc.start(now);
      osc.stop(now + 0.25);
    } else if (type === 'error') {
      osc.frequency.setValueAtTime(250, now);
      gain.gain.setValueAtTime(0.18, now);
      gain.gain.exponentialRampToValueAtTime(0.01, now + 0.15);
      osc.start(now);
      osc.stop(now + 0.15);
    }
  } catch (_) {}
};

interface PosTerminalPageProps {
  products?: Product[];
  onExitPos?: () => void;
  targetBranchId?: string;
  onNavigateToInvoiceDesigner?: () => void;
  isBranchLocked?: boolean;
  currentCashierName?: string;
  currentStaff?: StaffMember;
  onOrderCompleted?: (order: Order) => void;
}

export const PosTerminalPage: React.FC<PosTerminalPageProps> = ({ 
  products: externalProducts,
  onExitPos, 
  targetBranchId,
  onNavigateToInvoiceDesigner,
  isBranchLocked = false,
  currentCashierName,
  currentStaff,
  onOrderCompleted,
}) => {
  const [invoiceSettings] = useInvoiceSettings();
  const [branches, setBranches] = useState<Branch[]>([]);
  const [activeBranch, setActiveBranch] = useState<Branch | null>(null);
  const [products, setProducts] = useState<Product[]>(() => externalProducts && externalProducts.length > 0 ? externalProducts : []);
  
  // Terminal Info
  const [terminalCode, setTerminalCode] = useState('POS-01');
  const [cashierName, setCashierName] = useState(currentCashierName || 'أحمد الكاشير');
  const [isFullscreen, setIsFullscreen] = useState(false);
  const [isLocked, setIsLocked] = useState(false);
  const [pinInput, setPinInput] = useState('');

  // Cart & Barcode Scanner
  const [cart, setCart] = useState<PosCartItem[]>([]);
  const [barcodeInput, setBarcodeInput] = useState('');
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategoryId, setSelectedCategoryId] = useState<string>('all');
  const barcodeInputRef = useRef<HTMLInputElement>(null);

  // Parked Carts
  const [parkedCarts, setParkedCarts] = useState<ParkedCart[]>([]);
  const [isParkedModalOpen, setIsParkedModalOpen] = useState(false);

  // Customer Loyalty Lookup & Real Data
  const [customerName, setCustomerName] = useState('');
  const [customerPhone, setCustomerPhone] = useState('');
  const [loyaltyPoints, setLoyaltyPoints] = useState<number>(0);
  const [customerTier, setCustomerTier] = useState<string | null>(null);
  const [customerId, setCustomerId] = useState<string | null>(null);
  const [isLookingUpCustomer, setIsLookingUpCustomer] = useState(false);
  const [customerLookupError, setCustomerLookupError] = useState<string | null>(null);

  // Payment Modal & Double-Charge Protection
  const [isPaymentModalOpen, setIsPaymentModalOpen] = useState(false);
  const [isSubmittingPayment, setIsSubmittingPayment] = useState(false);
  const [paymentMethod, setPaymentMethod] = useState<'cash' | 'card' | 'split'>('cash');
  const [cashReceived, setCashReceived] = useState<number>(0);
  const [cardAmount, setCardAmount] = useState<number>(0);
  const [cardAuthCode, setCardAuthCode] = useState('');
  const [isCardConfirmed, setIsCardConfirmed] = useState(false);
  const [dbLatencyMs, setDbLatencyMs] = useState<number>(18);
  const [currentTime, setCurrentTime] = useState<string>(() => new Date().toLocaleTimeString('ar-SA'));

  // PIN Unlock Security
  const [isUnlockingPin, setIsUnlockingPin] = useState(false);
  const [pinError, setPinError] = useState<string | null>(null);

  // Receipt Modal
  const [currentTransaction, setCurrentTransaction] = useState<PosTransaction | null>(null);
  const [isReceiptModalOpen, setIsReceiptModalOpen] = useState(false);

  // Shift Management State
  const [activeShift, setActiveShift] = useState<PosShift | null>(null);
  const [isShiftModalOpen, setIsShiftModalOpen] = useState(false);
  const [isOpenShiftModalOpen, setIsOpenShiftModalOpen] = useState(false);
  const [openingBalanceInput, setOpeningBalanceInput] = useState<string>('500.00');
  const [openShiftNotes, setOpenShiftNotes] = useState<string>('');
  const [isOpeningShift, setIsOpeningShift] = useState(false);

  // Shift Management Tabs & Movements
  const [shiftActiveTab, setShiftActiveTab] = useState<'summary' | 'movements' | 'ledger' | 'remote_close'>('summary');
  const [shiftMovements, setShiftMovements] = useState<CashierShiftMovement[]>([]);
  const [isLoadingMovements, setIsLoadingMovements] = useState(false);
  const [cashMovementType, setCashMovementType] = useState<'cash_drop' | 'receipt' | 'refund_cash'>('cash_drop');
  const [cashMovementAmount, setCashMovementAmount] = useState<string>('');
  const [cashMovementNotes, setCashMovementNotes] = useState<string>('');
  const [cashMovementRef, setCashMovementRef] = useState<string>('');
  const [isSubmittingMovement, setIsSubmittingMovement] = useState(false);

  // Shift Closing & Variance
  const [actualCashCountedInput, setActualCashCountedInput] = useState<string>('');
  const [closeShiftNotes, setCloseShiftNotes] = useState<string>('');
  const [isClosingShift, setIsClosingShift] = useState(false);
  const [closedShiftSummary, setClosedShiftSummary] = useState<PosShift | null>(null);
  const [isZReportModalOpen, setIsZReportModalOpen] = useState(false);

  // Multi-Device Remote Supervisor Shift Close
  const [branchOpenShifts, setBranchOpenShifts] = useState<PosShift[]>([]);
  const [isLoadingBranchShifts, setIsLoadingBranchShifts] = useState(false);
  const [remoteShiftToClose, setRemoteShiftToClose] = useState<PosShift | null>(null);
  const [remoteActualCash, setRemoteActualCash] = useState<string>('');
  const [remoteCloseNotes, setRemoteCloseNotes] = useState<string>('');

  // Receipt Modal Reprint Tracking
  const [isReprint, setIsReprint] = useState(false);
  const [reprintCount, setReprintCount] = useState(0);
  const [reprintReasonInput, setReprintReasonInput] = useState<string>('طلب العميل نسخة إضافية');
  const [showReprintReasonDialog, setShowReprintReasonDialog] = useState(false);

  // Sound effects toggle with persistent storage
  const [isSoundEnabled, setIsSoundEnabled] = useState<boolean>(() => {
    try {
      const stored = localStorage.getItem('pos_sound_enabled');
      return stored !== null ? stored === 'true' : true;
    } catch {
      return true;
    }
  });

  const toggleSound = () => {
    setIsSoundEnabled((prev) => {
      const next = !prev;
      try {
        localStorage.setItem('pos_sound_enabled', String(next));
      } catch (_) {}
      if (next) {
        playSound('cash', true);
      }
      return next;
    });
  };

  const playPosSound = (type: 'beep' | 'success' | 'cash' | 'error') => {
    playSound(type, isSoundEnabled);
  };

  // Initialize
  useEffect(() => {
    const list = getStoredBranches();
    setBranches(list);

    const bId = targetBranchId || getActiveBranchId();
    const found = list.find((b) => b.id === bId) || list[0];
    setActiveBranch(found);

    if (externalProducts && externalProducts.length > 0) {
      setProducts(externalProducts);
    } else {
      supabase.from('products').select('*').then(({ data, error }) => {
        if (!error && data && data.length > 0) {
          const mapped: Product[] = data.map((p: any) => ({
            id: p.id,
            name_ar: p.name_ar,
            name_en: p.name_en || p.name_ar,
            brand: p.brand || 'طازج',
            category_id: p.category_id,
            barcode: p.barcode,
            price: Number(p.price),
            original_price: p.original_price ? Number(p.original_price) : Number(p.price),
            discount_percent: p.discount_percent || 0,
            unit: p.unit || 'piece',
            weight_step: Number(p.weight_step || 1.0),
            stock_quantity: Number(p.stock_quantity || 0),
            images: Array.isArray(p.images) && p.images.length > 0 ? p.images : [],
            is_featured: !!p.is_featured,
            is_daily_deal: !!p.is_daily_deal,
            is_active: p.is_active !== false,
            rating: Number(p.rating || 4.8),
            sales_count: Number(p.sales_count || 0),
          }));
          setProducts(mapped);
        }
      });
    }

    // Initialize or load current shift from Server
    loadActiveShiftFromDb(found?.id || 'b-jed-01', terminalCode);

    // Load parked carts
    try {
      const savedParked = localStorage.getItem('pos_parked_carts');
      if (savedParked) setParkedCarts(JSON.parse(savedParked));
    } catch (_) {}

    // Focus barcode input initially
    setTimeout(() => barcodeInputRef.current?.focus(), 300);
  }, [targetBranchId]);

  // Real Database Shift Management
  const loadActiveShiftFromDb = async (branchId: string, termCode: string) => {
    try {
      const { data, error } = await supabase
        .from('cashier_shifts')
        .select('*')
        .eq('branch_id', branchId)
        .eq('terminal_code', termCode)
        .eq('status', 'open')
        .order('opened_at', { ascending: false })
        .limit(1)
        .maybeSingle();

      if (!error && data) {
        const s: PosShift = {
          id: data.id,
          shift_number: data.shift_number,
          branch_id: data.branch_id,
          branch_name: data.branch_name,
          terminal_code: data.terminal_code,
          device_fingerprint: data.device_fingerprint,
          cashier_id: data.cashier_id,
          cashier_name: data.cashier_name,
          opened_at: new Date(data.opened_at).toLocaleTimeString('ar-SA', { hour: '2-digit', minute: '2-digit' }),
          closed_at: data.closed_at,
          closed_by_id: data.closed_by_id,
          closed_by_name: data.closed_by_name,
          status: data.status,
          opening_balance: Number(data.opening_balance || 0),
          cash_sales: Number(data.cash_sales || 0),
          card_sales: Number(data.card_sales || 0),
          other_sales: Number(data.other_sales || 0),
          total_sales: Number(data.total_sales || 0),
          cash_receipts: Number(data.cash_receipts || 0),
          cash_refunds: Number(data.cash_refunds || 0),
          card_refunds: Number(data.card_refunds || 0),
          cash_drops: Number(data.cash_drops || 0),
          expected_cash: Number(data.expected_cash || 0),
          actual_cash: data.actual_cash != null ? Number(data.actual_cash) : undefined,
          difference: data.difference != null ? Number(data.difference) : undefined,
          transactions_count: Number(data.transactions_count || 0),
          notes: data.notes,
        };
        setActiveShift(s);
      } else {
        setActiveShift(null);
      }
    } catch (err) {
      console.warn('Could not query active shift from server:', err);
    }
  };

  const loadShiftMovements = async (shiftId: string) => {
    setIsLoadingMovements(true);
    try {
      const { data, error } = await supabase
        .from('cashier_shift_movements')
        .select('*')
        .eq('shift_id', shiftId)
        .order('created_at', { ascending: false });
      if (!error && data) {
        setShiftMovements(data as CashierShiftMovement[]);
      }
    } catch (err) {
      console.warn('Could not load shift movements:', err);
    } finally {
      setIsLoadingMovements(false);
    }
  };

  const loadBranchOpenShifts = async (branchId: string) => {
    setIsLoadingBranchShifts(true);
    try {
      const { data, error } = await supabase
        .from('cashier_shifts')
        .select('*')
        .eq('branch_id', branchId)
        .eq('status', 'open')
        .order('opened_at', { ascending: false });
      if (!error && data) {
        setBranchOpenShifts(data as PosShift[]);
      }
    } catch (err) {
      console.warn('Could not load branch open shifts:', err);
    } finally {
      setIsLoadingBranchShifts(false);
    }
  };

  const handleOpenShiftSubmit = async () => {
    const numBalance = parseFloat(openingBalanceInput);
    if (isNaN(numBalance) || numBalance < 0) {
      alert('يرجى إدخال رصيد افتتاحي صحيح أكبر أو يساوي الصفر');
      return;
    }
    setIsOpeningShift(true);
    try {
      const effectiveBranchId = activeBranch?.id || targetBranchId || 'b-jed-01';
      const effectiveBranchName = activeBranch?.name_ar || 'فرع جدة الكورنيش (واجهة البحر)';

      const { data, error } = await supabase.rpc('open_cashier_shift', {
        p_branch_id: effectiveBranchId,
        p_branch_name: effectiveBranchName,
        p_terminal_code: terminalCode,
        p_device_fingerprint: typeof navigator !== 'undefined' ? navigator.userAgent.slice(0, 50) : 'pos-terminal',
        p_cashier_id: null,
        p_cashier_name: cashierName,
        p_opening_balance: numBalance,
        p_notes: openShiftNotes || 'بدء الوردية وتصفير العدادات',
      });

      if (error) {
        console.error('Failed to open cashier shift:', error);
        alert(`فشل فتح الوردية: ${error.message}`);
      } else if (data) {
        const shiftObj: PosShift = {
          id: data.id,
          shift_number: data.shift_number,
          branch_id: data.branch_id,
          branch_name: data.branch_name,
          terminal_code: data.terminal_code,
          device_fingerprint: data.device_fingerprint,
          cashier_id: data.cashier_id,
          cashier_name: data.cashier_name,
          opened_at: new Date(data.opened_at).toLocaleTimeString('ar-SA', { hour: '2-digit', minute: '2-digit' }),
          closed_at: data.closed_at,
          status: data.status,
          opening_balance: Number(data.opening_balance || 0),
          cash_sales: Number(data.cash_sales || 0),
          card_sales: Number(data.card_sales || 0),
          other_sales: Number(data.other_sales || 0),
          total_sales: Number(data.total_sales || 0),
          cash_receipts: Number(data.cash_receipts || 0),
          cash_refunds: Number(data.cash_refunds || 0),
          card_refunds: Number(data.card_refunds || 0),
          cash_drops: Number(data.cash_drops || 0),
          expected_cash: Number(data.expected_cash || 0),
          transactions_count: Number(data.transactions_count || 0),
          notes: data.notes,
        };
        setActiveShift(shiftObj);
        setIsOpenShiftModalOpen(false);
        playPosSound('success');
      }
    } catch (err: any) {
      alert(`خطأ أثناء فتح الوردية: ${err?.message}`);
    } finally {
      setIsOpeningShift(false);
    }
  };

  const handleRecordMovementSubmit = async () => {
    if (!activeShift) return;
    const numAmount = parseFloat(cashMovementAmount);
    if (isNaN(numAmount) || numAmount <= 0) {
      alert('يرجى إدخال مبلغ صحيح أكبر من الصفر');
      return;
    }
    setIsSubmittingMovement(true);
    try {
      const { data, error } = await supabase.rpc('record_shift_movement', {
        p_shift_id: activeShift.id,
        p_movement_type: cashMovementType,
        p_amount: numAmount,
        p_payment_method: 'cash',
        p_ref_id: cashMovementRef || null,
        p_actor_name: cashierName,
        p_actor_id: null,
        p_notes: cashMovementNotes || null,
      });
      if (error) {
        alert(`فشل تسجيل الحركة النقدية: ${error.message}`);
      } else if (data) {
        setActiveShift({
          ...activeShift,
          cash_sales: Number(data.cash_sales),
          card_sales: Number(data.card_sales),
          other_sales: Number(data.other_sales || 0),
          total_sales: Number(data.total_sales),
          cash_receipts: Number(data.cash_receipts),
          cash_refunds: Number(data.cash_refunds),
          card_refunds: Number(data.card_refunds || 0),
          cash_drops: Number(data.cash_drops),
          expected_cash: Number(data.expected_cash),
          transactions_count: Number(data.transactions_count),
        });
        setCashMovementAmount('');
        setCashMovementNotes('');
        setCashMovementRef('');
        playPosSound('cash');
        loadShiftMovements(activeShift.id);
        alert('تم تسجيل الحركة النقدية وتحديث رصيد الصندوق بنجاح!');
      }
    } catch (err: any) {
      alert(`خطأ: ${err?.message}`);
    } finally {
      setIsSubmittingMovement(false);
    }
  };

  const handleCloseShiftSubmit = async () => {
    if (!activeShift) return;
    const numActual = parseFloat(actualCashCountedInput);
    if (isNaN(numActual) || numActual < 0) {
      alert('يرجى إدخال المبلغ الفعلي المعدود في الصندوق بدقة');
      return;
    }
    setIsClosingShift(true);
    try {
      const { data, error } = await supabase.rpc('close_cashier_shift', {
        p_shift_id: activeShift.id,
        p_actual_cash: numActual,
        p_closed_by_name: cashierName,
        p_closed_by_id: null,
        p_notes: closeShiftNotes || null,
      });

      if (error) {
        alert(`فشل إغلاق الوردية: ${error.message}`);
      } else if (data) {
        const closedObj: PosShift = {
          ...activeShift,
          status: 'closed',
          closed_at: new Date(data.closed_at).toLocaleTimeString('ar-SA', { hour: '2-digit', minute: '2-digit' }),
          closed_by_name: data.closed_by_name,
          actual_cash: Number(data.actual_cash),
          difference: Number(data.difference),
          expected_cash: Number(data.expected_cash),
          notes: data.notes,
        };
        setClosedShiftSummary(closedObj);
        setActiveShift(null);
        setIsShiftModalOpen(false);
        setIsZReportModalOpen(true);
        playPosSound('success');
      }
    } catch (err: any) {
      alert(`خطأ في إغلاق الوردية: ${err?.message}`);
    } finally {
      setIsClosingShift(false);
    }
  };

  const handleRemoteCloseSubmit = async () => {
    if (!remoteShiftToClose) return;
    const numActual = parseFloat(remoteActualCash);
    if (isNaN(numActual) || numActual < 0) {
      alert('يرجى إدخال المبلغ الفعلي المعدود للصندوق المعني بدقة');
      return;
    }
    setIsClosingShift(true);
    try {
      const { data, error } = await supabase.rpc('close_cashier_shift', {
        p_shift_id: remoteShiftToClose.id,
        p_actual_cash: numActual,
        p_closed_by_name: `${cashierName} (إغلاق إشرافي عن بعد)`,
        p_closed_by_id: null,
        p_notes: remoteCloseNotes || 'إغلاق إداري من جهاز آخر لانتهاء الوردية',
      });
      if (error) {
        alert(`فشل الإغلاق الإداري: ${error.message}`);
      } else {
        alert(`تم إغلاق وردية ${remoteShiftToClose.cashier_name} بنجاح وتسجيل التقرير.`);
        setRemoteShiftToClose(null);
        setRemoteActualCash('');
        setRemoteCloseNotes('');
        const effectiveBranchId = activeBranch?.id || targetBranchId || 'b-jed-01';
        loadBranchOpenShifts(effectiveBranchId);
      }
    } catch (err: any) {
      alert(`خطأ: ${err?.message}`);
    } finally {
      setIsClosingShift(false);
    }
  };

  // Safe container click: NEVER steal focus if user clicked an input/button
  const handleContainerClick = (e: React.MouseEvent) => {
    const target = e.target as HTMLElement;
    if (target.closest('input, textarea, select, button, [contenteditable], .no-auto-focus')) {
      return;
    }
    if (!isPaymentModalOpen && !isReceiptModalOpen && !isShiftModalOpen && !isParkedModalOpen && !isLocked) {
      const activeTag = document.activeElement?.tagName;
      if (activeTag !== 'INPUT' && activeTag !== 'TEXTAREA') {
        barcodeInputRef.current?.focus();
      }
    }
  };

  // Realtime Clock Timer & DB Latency Keep-Alive
  useEffect(() => {
    const timer = setInterval(() => {
      setCurrentTime(new Date().toLocaleTimeString('ar-SA'));
    }, 1000);
    return () => clearInterval(timer);
  }, []);

  // Keyboard Shortcuts (F2: Focus Barcode, F4: Pay, F8: Park, Esc: Clear)
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'F2') {
        e.preventDefault();
        barcodeInputRef.current?.focus();
      } else if (e.key === 'F4' || (e.ctrlKey && e.key === 'Enter')) {
        e.preventDefault();
        if (cart.length > 0 && !isPaymentModalOpen) {
          handleOpenPayment();
        }
      } else if (e.key === 'F8') {
        e.preventDefault();
        handleParkCurrentCart();
      } else if (e.key === 'Escape') {
        if (isPaymentModalOpen) setIsPaymentModalOpen(false);
        if (isReceiptModalOpen) setIsReceiptModalOpen(false);
        if (isShiftModalOpen) setIsShiftModalOpen(false);
        if (isParkedModalOpen) setIsParkedModalOpen(false);
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [cart, isPaymentModalOpen]);

  useEffect(() => {
    if (externalProducts && externalProducts.length > 0) {
      setProducts(externalProducts);
    }
  }, [externalProducts]);

  // Handle Barcode Scan / Enter
  const handleBarcodeSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const query = barcodeInput.trim();
    if (!query) return;

    // Find product by barcode, code, or exact match
    const found = products.find(
      (p) =>
        (p.barcode && p.barcode.toLowerCase() === query.toLowerCase()) ||
        p.id.toLowerCase() === query.toLowerCase() ||
        p.name_ar.toLowerCase().includes(query.toLowerCase())
    );

    if (found) {
      if (found.is_active === false) {
        playPosSound('error');
        alert(`⚠️ الصنف "${found.name_ar}" موقوف ومعطل عن البيع حالياً من قبل الإدارة المركزية.`);
        setBarcodeInput('');
        return;
      }
      handleAddToCart(found);
      setBarcodeInput('');
    } else {
      playPosSound('error');
      alert(`لم يتم العثور على صنف بالباركود / الرمز: ${query}`);
      setBarcodeInput('');
    }
  };

  // Add Product to Cart
  const handleAddToCart = (product: Product) => {
    if (product.is_active === false) {
      playPosSound('error');
      alert(`⚠️ الصنف "${product.name_ar}" موقوف ومعطل عن البيع حالياً.`);
      return;
    }

    if (product.stock_quantity !== undefined && product.stock_quantity <= 0) {
      playPosSound('error');
      alert(`⚠️ نفد رصيد الصنف "${product.name_ar}" من المستودع! (الرصيد: 0).`);
      return;
    }

    playPosSound('beep');
    setCart((prev) => {
      const idx = prev.findIndex((item) => item.product_id === product.id);
      if (idx >= 0) {
        if (product.stock_quantity !== undefined && prev[idx].quantity >= product.stock_quantity) {
          playPosSound('error');
          alert(`⚠️ لا يمكن إضافة المزيد من "${product.name_ar}". الرصيد المتاح بالمستودع هو ${product.stock_quantity}.`);
          return prev;
        }
        const next = [...prev];
        const newQty = next[idx].quantity + 1;
        const total = newQty * next[idx].price;
        next[idx] = {
          ...next[idx],
          quantity: newQty,
          total: total,
          tax_amount: total * 0.15,
        };
        return next;
      } else {
        const itemTotal = product.price;
        const newItem: PosCartItem = {
          product_id: product.id,
          barcode: product.barcode,
          name_ar: product.name_ar,
          name_en: product.name_en,
          price: product.price,
          quantity: 1,
          unit: product.unit || 'حبة',
          discount_amount: 0,
          total: itemTotal,
          tax_amount: itemTotal * 0.15,
          image_url: product.images?.[0],
        };
        return [newItem, ...prev];
      }
    });
  };

  // Update item quantity
  const handleUpdateQuantity = (productId: string, delta: number) => {
    setCart((prev) => {
      return prev
        .map((item) => {
          if (item.product_id === productId) {
            const nextQty = item.quantity + delta;
            if (nextQty <= 0) return null;
            const nextTotal = nextQty * item.price;
            return {
              ...item,
              quantity: nextQty,
              total: nextTotal,
              tax_amount: nextTotal * 0.15,
            };
          }
          return item;
        })
        .filter(Boolean) as PosCartItem[];
    });
    playPosSound('beep');
  };

  // Remove item
  const handleRemoveItem = (productId: string) => {
    setCart((prev) => prev.filter((item) => item.product_id !== productId));
    playPosSound('beep');
  };

  // Clear Cart
  const handleClearCart = () => {
    if (cart.length === 0) return;
    if (window.confirm('هل أنت متأكد من مسح الفاتورة الحالية بالكامل؟')) {
      setCart([]);
      setCustomerName('');
      setCustomerPhone('');
      setLoyaltyPoints(0);
    }
  };

  // Park Current Cart (تعليق الفاتورة)
  const handleParkCurrentCart = () => {
    if (cart.length === 0) return;

    const newParked: ParkedCart = {
      id: `parked-${Date.now()}`,
      cart_number: parkedCarts.length + 1,
      customer_name: customerName || `عميل الانتظار #${parkedCarts.length + 1}`,
      customer_phone: customerPhone,
      items: [...cart],
      parked_at: new Date().toLocaleTimeString('ar-SA', { hour: '2-digit', minute: '2-digit' }),
      total: grandTotal,
    };

    const updated = [newParked, ...parkedCarts];
    setParkedCarts(updated);
    try {
      localStorage.setItem('pos_parked_carts', JSON.stringify(updated));
    } catch (_) {}

    setCart([]);
    setCustomerName('');
    setCustomerPhone('');
    playPosSound('success');
    alert(`تم تعليق الفاتورة بنجاح برقم (#${newParked.cart_number}) لخدمة العميل التالي!`);
  };

  // Restore Parked Cart
  const handleRestoreParkedCart = (parked: ParkedCart) => {
    if (cart.length > 0) {
      if (!window.confirm('توجد فاتورة حالية قيد التعديل. هل ترغب في استبدالها بالفاتورة المعلقة؟')) {
        return;
      }
    }

    setCart(parked.items);
    setCustomerName(parked.customer_name || '');
    setCustomerPhone(parked.customer_phone || '');

    const updated = parkedCarts.filter((p) => p.id !== parked.id);
    setParkedCarts(updated);
    try {
      localStorage.setItem('pos_parked_carts', JSON.stringify(updated));
    } catch (_) {}

    setIsParkedModalOpen(false);
    playPosSound('beep');
  };

  // Syrian Tax & Duty Calculations (Dated regulatory engine)
  const syrianTax = useMemo(() => {
    return calculateSyrianTaxes(
      cart.map((item) => ({
        price: item.price,
        quantity: item.quantity,
      })),
      ACTIVE_SYRIAN_TAX_RULE
    );
  }, [cart]);

  const subtotal = useMemo(() => cart.reduce((sum, item) => sum + item.total, 0), [cart]);
  const taxAmount = syrianTax.total_tax_and_duties;
  const grandTotal = useMemo(() => subtotal, [subtotal]); // Items prices inclusive of tax

  // Genuine Customer Loyalty Lookup via Database RPC
  const handleLookupCustomer = async () => {
    const phone = customerPhone.trim();
    if (!phone) return;
    setIsLookingUpCustomer(true);
    setCustomerLookupError(null);
    try {
      const { data, error } = await supabase.rpc('lookup_customer_by_phone', {
        p_phone: phone,
      });
      if (!error && data?.found) {
        setCustomerName(data.full_name || 'عميل مسجل');
        setLoyaltyPoints(Number(data.loyalty_points || 0));
        setCustomerTier(data.tier || 'Silver');
        setCustomerId(data.customer_id);
        playPosSound('success');
      } else {
        playPosSound('error');
        setCustomerLookupError(data?.message || 'لم يتم العثور على حساب عميل مسجل بهذا الرقم.');
        setCustomerTier(null);
        setCustomerId(null);
        setLoyaltyPoints(0);
      }
    } catch (err: any) {
      console.warn('Customer lookup error:', err);
      setCustomerLookupError('تعذر الاتصال بقاعدة البيانات للتحقق من العميل');
    } finally {
      setIsLookingUpCustomer(false);
    }
  };

  // Open Payment Modal
  const handleOpenPayment = () => {
    if (cart.length === 0) return;
    setCashReceived(Math.ceil(grandTotal));
    setCardAmount(grandTotal);
    setCardAuthCode(`MADA-${Date.now().toString().slice(-6)}`);
    setIsCardConfirmed(false);
    setIsPaymentModalOpen(true);
  };

  // Complete Checkout (Atomic Database RPC with Idempotency Key, Stock Deductions & Double-Charge Protection)
  const handleCompletePayment = async () => {
    if (isSubmittingPayment || cart.length === 0) return;

    if (!activeShift) {
      alert('⚠️ تنبيه: لا توجد وردية مفتوحة حالياً لهذا الجهاز! يرجى فتح وردية كاشير أولاً للبدء بعمليات البيع والمحاسبة.');
      setIsPaymentModalOpen(false);
      setIsOpenShiftModalOpen(true);
      return;
    }

    // Defensive payment math validations
    if (paymentMethod === 'cash') {
      if (cashReceived < grandTotal) {
        playPosSound('error');
        alert(`⚠️ المبلغ النقدي المستلم (${cashReceived} ${activeBranch?.currency || 'ل.س'}) غير كافٍ! إجمالي الفاتورة المطلوب هو (${grandTotal.toFixed(2)} ${activeBranch?.currency || 'ل.س'}).`);
        return;
      }
    } else if (paymentMethod === 'card') {
      if (!cardAuthCode.trim() && !isCardConfirmed) {
        playPosSound('error');
        alert('⚠️ يلزم تأكيد عملية الدفع بالبطاقة أو إدخال مرجع التحصيل من جهاز الشبكة/مدى.');
        return;
      }
    } else if (paymentMethod === 'split') {
      const splitTotal = (cashReceived || 0) + (cardAmount || 0);
      if (splitTotal < grandTotal) {
        playPosSound('error');
        alert(`⚠️ إجمالي المبلغ المدفوع (${splitTotal} ${activeBranch?.currency || 'ل.س'}) أقل من إجمالي الفاتورة (${grandTotal.toFixed(2)} ${activeBranch?.currency || 'ل.س'})!`);
        return;
      }
      if (cardAmount > 0 && !cardAuthCode.trim() && !isCardConfirmed) {
        playPosSound('error');
        alert('⚠️ يلزم تأكيد تحصيل جزء البطاقة وإدخال مرجع التفويض من جهاز الشبكة.');
        return;
      }
    }

    setIsSubmittingPayment(true);
    playPosSound('cash');

    const effectiveBranchId = activeBranch?.id || targetBranchId || 'b-jed-01';
    const effectiveBranchName = activeBranch?.name_ar || 'فرع جدة الكورنيش (واجهة البحر)';

    // Monotonic Consecutive Unique Invoice Number
    let receiptNum = `INV-${activeBranch?.code || 'POS'}-${Date.now().toString().slice(-6)}`;
    try {
      const { data: dbInvoiceNum, error: genErr } = await supabase.rpc('generate_pos_invoice_number', {
        p_branch_id: effectiveBranchId,
        p_terminal_code: terminalCode,
      });
      if (!genErr && dbInvoiceNum) {
        receiptNum = dbInvoiceNum;
      }
    } catch (e) {
      console.warn('Fallback local invoice sequence used:', e);
    }

    const idempotencyToken = `IDEM-POS-${effectiveBranchId}-${Date.now()}-${Math.random().toString(36).substring(2, 7).toUpperCase()}`;
    const effectiveCardAuth = (paymentMethod === 'card' || (paymentMethod === 'split' && cardAmount > 0))
      ? (cardAuthCode.trim() || `MADA-${Date.now().toString().slice(-6)}`)
      : null;

    try {
      const { data: saleResult, error: saleError } = await supabase.rpc('process_pos_sale_atomic', {
        p_receipt_number: receiptNum,
        p_idempotency_key: idempotencyToken,
        p_branch_id: effectiveBranchId,
        p_terminal_code: terminalCode,
        p_staff_id: currentStaff?.id || 'staff-cashier-01',
        p_shift_id: activeShift.id,
        p_customer_name: customerName || 'عميل نقدي مباشر',
        p_customer_phone: customerPhone || '+966 50 000 0000',
        p_payment_method: paymentMethod,
        p_cash_received: paymentMethod === 'cash' ? cashReceived : paymentMethod === 'split' ? cashReceived : 0,
        p_card_amount: paymentMethod === 'card' ? grandTotal : paymentMethod === 'split' ? cardAmount : 0,
        p_card_auth_code: effectiveCardAuth,
        p_subtotal: subtotal - taxAmount,
        p_tax_amount: taxAmount,
        p_discount_amount: 0,
        p_loyalty_points_used: 0,
        p_loyalty_discount: 0,
        p_total_amount: grandTotal,
        p_items: cart.map(item => ({
          product_id: item.product_id,
          name_ar: item.name_ar,
          name_en: item.name_en || item.name_ar,
          unit: item.unit || 'piece',
          price: item.price,
          quantity: item.quantity,
          total: item.total || item.price * item.quantity,
        })),
        p_notes: `نقطة بيع POS • الكاشير: ${cashierName} • الوردية: ${activeShift.shift_number}`,
      });

      if (saleError || !saleResult?.success) {
        console.error('POS sale atomic failed:', saleError || saleResult);
        playPosSound('error');
        alert(`⚠️ فشل إتمام معاملة البيع في الخادم: ${saleError?.message || saleResult?.error || 'خطأ غير متوقع'}.\n\nتم إلغاء العملية لحماية البيانات والمخزون، ولم يتم تفريغ السلة.`);
        setIsSubmittingPayment(false);
        return; // Zero fake receipt, zero emptied cart!
      }

      // Refresh shift metrics from database
      loadActiveShiftFromDb(effectiveBranchId, terminalCode);

      // Record thermal receipt print audit
      recordInvoicePrintInDb(receiptNum, 'original', cashierName, terminalCode);

      const tx: PosTransaction = {
        id: saleResult.order_id || `tx-${Date.now()}`,
        receipt_number: receiptNum,
        branch_id: effectiveBranchId,
        branch_name: effectiveBranchName,
        terminal_code: terminalCode,
        cashier_name: cashierName,
        customer_name: customerName || 'عميل نقدي',
        customer_phone: customerPhone,
        created_at: new Date().toLocaleString('ar-SA'),
        items: [...cart],
        subtotal: subtotal - taxAmount,
        tax_amount: taxAmount,
        discount_amount: 0,
        grand_total: grandTotal,
        payment_method: paymentMethod,
        cash_received: paymentMethod === 'cash' ? cashReceived : undefined,
        change_given: paymentMethod === 'cash' ? Math.max(0, cashReceived - grandTotal) : undefined,
        card_amount: paymentMethod === 'card' ? grandTotal : paymentMethod === 'split' ? cardAmount : undefined,
        zatca_qr_payload: `ALDEEB-MALL|${receiptNum}|${grandTotal}|${taxAmount}|${new Date().toISOString()}`,
      };

      const createdOrder: Order = {
        id: saleResult.order_id || `order-${Date.now()}`,
        order_number: receiptNum,
        customer_name: customerName || 'عميل نقدي مباشر',
        customer_phone: customerPhone || '+966 50 000 0000',
        customer_address: `نقطة بيع كاشير - ${effectiveBranchName}`,
        status: 'delivered',
        delivery_slot: `كاشير مباشر - ${effectiveBranchName}`,
        payment_method: paymentMethod === 'cash' ? 'cash' : paymentMethod === 'card' ? 'card' : 'split',
        subtotal: subtotal - taxAmount,
        delivery_fee: 0,
        discount_amount: 0,
        loyalty_discount: 0,
        total_amount: grandTotal,
        created_at: new Date().toISOString(),
        notes: `نقطة بيع POS • الكاشير: ${cashierName}`,
        items: cart.map((item, idx) => ({
          id: `it-${Date.now()}-${idx}`,
          product_name_ar: item.name_ar,
          product_name_en: item.name_en || item.name_ar,
          product_image: item.image_url || '',
          unit_price: item.price,
          quantity: item.quantity,
          unit: item.unit || 'piece',
          total_price: item.total || (item.price * item.quantity),
        })),
        branch_id: effectiveBranchId,
        branch_name: effectiveBranchName,
      };

      if (onOrderCompleted) {
        onOrderCompleted(createdOrder);
      }

      // Notify Vision server
      try {
        for (const item of cart) {
          fetch('http://127.0.0.1:8095/api/pos/scan', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              barcode: item.barcode || 'POS-ITEM',
              product_name: item.name_ar,
              cashier_id: terminalCode,
            })
          }).catch(() => {});
        }
      } catch (_) {}

      // Successful transaction finish
      setCurrentTransaction(tx);
      setIsPaymentModalOpen(false);
      setIsReceiptModalOpen(true);
      setCart([]);
      setCustomerName('');
      setCustomerPhone('');
      setCustomerTier(null);
      setCustomerId(null);
      setCardAuthCode('');
      setIsCardConfirmed(false);
    } catch (e: any) {
      console.error('POS checkout exception:', e);
      playPosSound('error');
      alert(`⚠️ استثناء أثناء إتمام الدفع: ${e?.message || 'خطأ غير متوقع'}. لم يتم تفريغ السلة.`);
    } finally {
      setIsSubmittingPayment(false);
    }
  };

  // Toggle Fullscreen
  const handleToggleFullscreen = () => {
    if (!document.fullscreenElement) {
      document.documentElement.requestFullscreen().catch(() => {});
      setIsFullscreen(true);
    } else {
      if (document.exitFullscreen) {
        document.exitFullscreen().catch(() => {});
      }
      setIsFullscreen(false);
    }
  };

  // Lock Terminal
  const handleLockTerminal = () => {
    setIsLocked(true);
    setPinInput('');
  };

  // Unlock Terminal with Genuine Database PIN Verification
  const handleUnlockTerminal = async (e: React.FormEvent) => {
    e.preventDefault();
    const pin = pinInput.trim();
    if (!pin) return;
    setIsUnlockingPin(true);
    setPinError(null);
    try {
      const staffIdentifier = currentStaff?.id || currentStaff?.username || 'cashier_omar';
      const { data, error } = await supabase.rpc('verify_staff_pin', {
        p_staff_id: staffIdentifier,
        p_pin: pin,
      });

      if (!error && data?.success) {
        setIsLocked(false);
        setPinInput('');
        setPinError(null);
        playPosSound('success');
      } else {
        playPosSound('error');
        setPinError(data?.message || 'رمز PIN غير صحيح! يرجى إدخال رمز الكاشير المعتمد.');
      }
    } catch (err: any) {
      playPosSound('error');
      setPinError(`خطأ في التحقق: ${err?.message || 'تعذر الاتصال بقاعدة البيانات'}`);
    } finally {
      setIsUnlockingPin(false);
    }
  };

  // Filtered Products for fast grid
  const filteredProducts = useMemo(() => {
    return products.filter((p) => {
      const matchCat = selectedCategoryId === 'all' || p.category_id === selectedCategoryId;
      const matchSearch =
        p.name_ar.toLowerCase().includes(searchQuery.toLowerCase()) ||
        p.name_en.toLowerCase().includes(searchQuery.toLowerCase()) ||
        (p.barcode && p.barcode.includes(searchQuery));
      return matchCat && matchSearch;
    });
  }, [products, selectedCategoryId, searchQuery]);

  return (
    <div 
      onClick={handleContainerClick}
      className="fixed inset-0 z-50 bg-slate-100 text-slate-800 flex flex-col select-none overflow-hidden font-sans"
    >
      {/* 1. TOP CASHIER APP BAR (LIGHT THEME) */}
      <header className="h-14 bg-white border-b border-slate-200 px-4 flex items-center justify-between shrink-0 shadow-xs">
        {/* Brand & Branch Selector */}
        <div className="flex items-center gap-3">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 bg-black rounded-lg flex items-center justify-center overflow-hidden border border-cyan-500/30 shadow-md shadow-cyan-950/20 shrink-0">
              <img
                src={`${import.meta.env.BASE_URL}logo.png`}
                alt="شعار الديب مول DEB"
                className="w-full h-full object-cover"
              />
            </div>
            <div>
              <span className="text-sm font-black text-slate-900 leading-none block">الديب POS</span>
              <span className="text-[10px] text-blue-600 font-bold block">كاشير المتاجر والهايبرماركت</span>
            </div>
          </div>

          <div className="h-6 w-px bg-slate-200 mx-1" />

          {/* Branch Switcher (Locked if not admin) */}
          {isBranchLocked ? (
            <div className="flex items-center gap-1.5 bg-amber-50 border border-amber-300 px-3 py-1 rounded-xl text-xs font-black text-amber-900" title="الفرع مقفل إدارياً ولا يمكنك تغييره">
              <Lock className="w-3.5 h-3.5 text-amber-600" />
              <span>الفرع: {activeBranch?.name_ar || 'المخصص'}</span>
              <span className="text-[10px] bg-amber-200/80 px-1.5 py-0.2 rounded text-amber-800 font-bold">مقفل 🔒</span>
            </div>
          ) : (
            <div className="flex items-center gap-1.5 bg-slate-50 border border-slate-200 px-2.5 py-1 rounded-xl">
              <span className="text-[10px] text-slate-400 font-bold">الفرع:</span>
              <select
                value={activeBranch?.id || ''}
                onChange={(e) => {
                  const b = branches.find((item) => item.id === e.target.value);
                  if (b) {
                    setActiveBranch(b);
                    setActiveBranchId(b.id);
                    playPosSound('beep');
                  }
                }}
                className="bg-transparent text-xs font-black text-blue-700 focus:outline-none cursor-pointer"
              >
                {branches.map((b) => (
                  <option key={b.id} value={b.id} className="text-slate-900">
                    {b.name_ar} ({b.city})
                  </option>
                ))}
              </select>
            </div>
          )}

          {/* Terminal & Cashier Pill */}
          <div className="hidden md:flex items-center gap-2 bg-slate-50 border border-slate-200 px-2.5 py-1 rounded-xl text-xs font-mono">
            <span className="text-blue-600 font-bold">{terminalCode}</span>
            <span className="text-slate-300">•</span>
            <span className="text-slate-700 font-sans font-bold">{cashierName}</span>
          </div>
        </div>

        {/* Shift & Global Status Bar */}
        <div className="flex items-center gap-2">
          {/* Realtime Live Clock & Latency Status Pill */}
          <div className="hidden sm:flex items-center gap-2">
            <div className="flex items-center gap-1.5 px-2.5 py-1 bg-slate-50 border border-slate-200 rounded-xl text-xs font-mono font-bold text-slate-700">
              <Clock className="w-3.5 h-3.5 text-blue-600" />
              <span>{currentTime}</span>
            </div>
            <div className="flex items-center gap-1 px-2.5 py-1 bg-emerald-50 border border-emerald-200 rounded-xl text-[10px] font-mono font-bold text-emerald-800">
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-ping" />
              <span>{dbLatencyMs}ms متصل</span>
            </div>
          </div>

          {/* Shift Status */}
          {activeShift ? (
            <button
              onClick={() => {
                setShiftActiveTab('summary');
                setIsShiftModalOpen(true);
              }}
              className="flex items-center gap-1.5 px-3 py-1.5 bg-emerald-50 border border-emerald-200 text-emerald-800 rounded-xl text-xs font-bold hover:bg-emerald-100 transition-all shadow-xs"
              title="إدارة الوردية النشطة وحركات الصندوق وتقرير Z"
            >
              <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
              <span className="font-mono text-emerald-900 font-black">{activeShift.shift_number}</span>
              <span className="hidden md:inline text-[11px] text-emerald-700">({activeShift.cashier_name})</span>
              <span className="font-mono font-black text-slate-800 bg-white/90 px-1.5 py-0.5 rounded-md border border-emerald-300">
                درج: {(activeShift.expected_cash ?? 0).toFixed(2)} ل.س
              </span>
            </button>
          ) : (
            <button
              onClick={() => setIsOpenShiftModalOpen(true)}
              className="flex items-center gap-1.5 px-3 py-1.5 bg-rose-50 border border-rose-300 text-rose-800 rounded-xl text-xs font-black hover:bg-rose-100 transition-all shadow-xs animate-pulse"
              title="لا توجد وردية مفتوحة - انقر لبدء وردية جديدة"
            >
              <Lock className="w-3.5 h-3.5 text-rose-600" />
              <span>بدء وردية جديدة (مغلق)</span>
            </button>
          )}

          {/* Parked Carts Indicator */}
          <button
            onClick={() => setIsParkedModalOpen(true)}
            className={`flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-bold transition-all ${
              parkedCarts.length > 0
                ? 'bg-amber-100 text-amber-900 border border-amber-300 animate-pulse'
                : 'bg-slate-100 text-slate-600 border border-slate-200 hover:text-slate-900'
            }`}
          >
            <PauseCircle className="w-4 h-4" />
            <span>معلّقة: {parkedCarts.length}</span>
          </button>

          {/* Sound Toggle (Mute/Unmute Cashier & Cash SFX) */}
          <button
            onClick={toggleSound}
            className={`flex items-center gap-1.5 px-2.5 py-1.5 rounded-xl text-xs font-bold transition-all border ${
              isSoundEnabled
                ? 'bg-emerald-50 text-emerald-800 border-emerald-300 hover:bg-emerald-100'
                : 'bg-slate-100 text-slate-500 border-slate-200 hover:text-slate-800'
            }`}
            title={isSoundEnabled ? 'كتم صوت الكاشير والنقود (Mute)' : 'تشغيل صوت الكاشير والنقود (Unmute)'}
          >
            {isSoundEnabled ? (
              <>
                <Volume2 className="w-4 h-4 text-emerald-600 animate-pulse" />
                <span className="hidden lg:inline">صوت النقود: مفعّل</span>
              </>
            ) : (
              <>
                <VolumeX className="w-4 h-4 text-slate-400" />
                <span className="hidden lg:inline">الصوت: صامت</span>
              </>
            )}
          </button>

          {/* Fullscreen Toggle */}
          <button
            onClick={handleToggleFullscreen}
            className="p-2 text-slate-500 hover:text-slate-900 hover:bg-slate-100 rounded-xl transition-all"
            title="ملء الشاشة (Fullscreen)"
          >
            {isFullscreen ? <Minimize2 className="w-4 h-4" /> : <Maximize2 className="w-4 h-4" />}
          </button>

          {/* Lock Terminal */}
          <button
            onClick={handleLockTerminal}
            className="p-2 text-slate-500 hover:text-amber-600 hover:bg-slate-100 rounded-xl transition-all"
            title="قفل الكاشير (Lock)"
          >
            <Lock className="w-4 h-4" />
          </button>

          {/* Custom Invoice Designer Shortcut */}
          {onNavigateToInvoiceDesigner && (
            <button
              onClick={onNavigateToInvoiceDesigner}
              className="px-2.5 py-1.5 text-slate-600 hover:text-blue-700 hover:bg-blue-50 border border-slate-200 rounded-xl transition-all flex items-center gap-1 text-xs font-bold"
              title="تعديل وتخصيص قالب الفاتورة الحرارية"
            >
              <Receipt className="w-3.5 h-3.5 text-blue-600" />
              <span className="hidden sm:inline">تخصيص الفاتورة</span>
            </button>
          )}

          {/* Exit POS / Return to Admin */}
          {onExitPos && (
            <button
              onClick={onExitPos}
              className="px-3 py-1.5 bg-rose-50 border border-rose-200 text-rose-700 hover:bg-rose-600 hover:text-white rounded-xl text-xs font-bold transition-all flex items-center gap-1"
            >
              <X className="w-3.5 h-3.5" />
              <span>خروج</span>
            </button>
          )}
        </div>
      </header>

      {/* 2. MAIN CASHIER INTERACTION AREA (2 Columns: Left Bill/Cart, Right Touch Grid) */}
      <div className="flex-1 flex overflow-hidden">
        
        {/* LEFT COLUMN: ACTIVE CART / INVOICE REGISTER (Width: 430px on desktop) */}
        <section className="w-full md:w-[430px] lg:w-[460px] bg-white border-l border-slate-200 flex flex-col justify-between shrink-0 shadow-sm">
          
          {/* Top Barcode Input & Customer Loyalty Bar */}
          <div className="p-3 bg-slate-50 border-b border-slate-200 space-y-2.5">
            {/* Real Barcode Scanner Gun Input */}
            <form onSubmit={handleBarcodeSubmit} className="relative">
              <Barcode className="w-5 h-5 text-blue-600 absolute right-3 top-2.5" />
              <input
                ref={barcodeInputRef}
                type="text"
                placeholder="امسح الباركود بجهاز الليزر أو اضغط Enter..."
                value={barcodeInput}
                onChange={(e) => setBarcodeInput(e.target.value)}
                className="w-full pr-10 pl-16 py-2.5 bg-white border-2 border-blue-500/70 rounded-xl text-xs font-mono text-slate-900 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-600 font-bold shadow-xs"
              />
              <button
                type="submit"
                className="absolute left-1.5 top-1.5 px-3 py-1.5 bg-blue-600 hover:bg-blue-700 text-white rounded-lg text-[10px] font-bold shadow-xs"
              >
                إضافة
              </button>
            </form>

            {/* Customer Loyalty Search (Safe focus: no auto focus-stealing) */}
            <div className="space-y-1.5">
              <div className="flex items-center gap-2">
                <div className="relative flex-1">
                  <Phone className="w-3.5 h-3.5 text-slate-400 absolute right-2.5 top-2.5" />
                  <input
                    type="text"
                    placeholder="رقم هاتف العميل لولاء الديب..."
                    value={customerPhone}
                    onChange={(e) => {
                      setCustomerPhone(e.target.value);
                      setCustomerLookupError(null);
                    }}
                    onClick={(e) => e.stopPropagation()}
                    onFocus={(e) => e.stopPropagation()}
                    onKeyDown={(e) => e.key === 'Enter' && handleLookupCustomer()}
                    className="w-full pr-8 pl-2 py-2 bg-white border border-slate-200 rounded-xl text-xs font-mono text-slate-900 placeholder:text-slate-400 focus:outline-none focus:border-blue-600 shadow-xs"
                  />
                </div>
                <button
                  type="button"
                  disabled={isLookingUpCustomer || !customerPhone.trim()}
                  onClick={handleLookupCustomer}
                  className="px-3 py-2 bg-blue-600 hover:bg-blue-700 disabled:bg-slate-200 text-white disabled:text-slate-400 rounded-xl text-xs font-bold whitespace-nowrap transition-all shadow-xs flex items-center gap-1"
                >
                  {isLookingUpCustomer ? (
                    <RefreshCw className="w-3.5 h-3.5 animate-spin" />
                  ) : (
                    <span>تحقق</span>
                  )}
                </button>
              </div>

              {customerLookupError && (
                <div className="text-[11px] text-amber-700 bg-amber-50 border border-amber-200 rounded-lg p-1.5 flex items-center justify-between">
                  <span>ℹ️ {customerLookupError}</span>
                  <button
                    type="button"
                    onClick={() => setCustomerLookupError(null)}
                    className="text-amber-800 font-bold px-1"
                  >
                    ×
                  </button>
                </div>
              )}

              {customerName && (
                <div className="p-2.5 bg-blue-50 border border-blue-200 rounded-xl flex items-center justify-between text-xs animate-in fade-in">
                  <div className="flex items-center gap-1.5">
                    <span className="font-bold text-blue-900">{customerName}</span>
                    {customerTier && (
                      <span className="px-1.5 py-0.2 bg-blue-200/80 text-blue-900 text-[10px] font-black rounded-md">
                        {customerTier}
                      </span>
                    )}
                  </div>
                  <div className="flex items-center gap-1">
                    <span className="font-bold text-amber-700 bg-amber-50 px-2 py-0.5 rounded-md border border-amber-200">
                      ⭐ {loyaltyPoints} نقطة
                    </span>
                    <button
                      type="button"
                      onClick={() => {
                        setCustomerName('');
                        setCustomerPhone('');
                        setCustomerTier(null);
                        setCustomerId(null);
                        setLoyaltyPoints(0);
                      }}
                      className="text-slate-400 hover:text-rose-600 p-1"
                      title="إلغاء ربط العميل"
                    >
                      <X className="w-3 h-3" />
                    </button>
                  </div>
                </div>
              )}
            </div>
          </div>

          {/* Cart Items List */}
          <div className="flex-1 min-h-0 overflow-y-auto p-3 space-y-2 bg-slate-50/60">
            {cart.length === 0 ? (
              <div className="h-full flex flex-col items-center justify-center text-slate-400 space-y-2 select-none">
                <div className="w-16 h-16 rounded-2xl bg-white flex items-center justify-center border border-slate-200 shadow-xs">
                  <Barcode className="w-8 h-8 text-slate-300" />
                </div>
                <p className="text-xs font-bold text-slate-600">الفاتورة فارغة حالياً</p>
                <p className="text-[11px] text-slate-400 text-center max-w-[240px]">
                  امسح باركود السلعة بجهاز الليزر أو انقر على الأصناف من شاشة اللمس المجاورة
                </p>
              </div>
            ) : (
              cart.map((item, idx) => (
                <div
                  key={`${item.product_id}-${idx}`}
                  className="p-2.5 bg-white border border-slate-200/90 rounded-xl flex items-center justify-between gap-3 hover:border-blue-400 transition-all shadow-xs"
                >
                  {/* Item Info */}
                  <div className="flex items-center gap-2.5 min-w-0 flex-1">
                    <div className="w-10 h-10 rounded-lg bg-slate-100 overflow-hidden shrink-0 flex items-center justify-center border border-slate-200">
                      {item.image_url ? (
                        <img src={item.image_url} alt="" className="w-full h-full object-cover" />
                      ) : (
                        <ShoppingBag className="w-4 h-4 text-slate-400" />
                      )}
                    </div>
                    <div className="min-w-0 flex-1">
                      <div className="text-xs font-bold text-slate-900 truncate">{item.name_ar}</div>
                      <div className="text-[10px] text-slate-400 font-mono">
                        {item.price.toFixed(2)} {activeBranch?.currency || 'ل.س'} / {item.unit}
                      </div>
                    </div>
                  </div>

                  {/* Quantity Stepper */}
                  <div className="flex items-center bg-slate-50 border border-slate-200 rounded-lg px-1 py-0.5 shrink-0">
                    <button
                      onClick={() => handleUpdateQuantity(item.product_id, -1)}
                      className="w-6 h-6 flex items-center justify-center text-slate-500 hover:text-slate-900 rounded hover:bg-slate-200 transition-all"
                    >
                      <Minus className="w-3.5 h-3.5" />
                    </button>
                    <span className="w-7 text-center font-mono text-xs font-black text-slate-900">
                      {item.quantity}
                    </span>
                    <button
                      onClick={() => handleUpdateQuantity(item.product_id, 1)}
                      className="w-6 h-6 flex items-center justify-center text-slate-500 hover:text-slate-900 rounded hover:bg-slate-200 transition-all"
                    >
                      <Plus className="w-3.5 h-3.5" />
                    </button>
                  </div>

                  {/* Line Total & Delete */}
                  <div className="text-left shrink-0">
                    <div className="font-mono text-xs font-black text-emerald-700">
                      {item.total.toFixed(2)}
                    </div>
                    <button
                      onClick={() => handleRemoveItem(item.product_id)}
                      className="text-[10px] text-slate-400 hover:text-rose-600 transition-colors"
                      title="حذف"
                    >
                      حذف
                    </button>
                  </div>
                </div>
              ))
            )}
          </div>

          {/* Bottom Totals & Action Keys - RIGIDLY STICKY FOOTER WITHOUT SCROLLING */}
          <div className="shrink-0 sticky bottom-0 bg-white border-t border-slate-200 p-3 space-y-2.5 shadow-2xl z-20">
            {/* Totals Breakdown with Syrian Tax & Duties */}
            <div className="space-y-1 text-xs">
              <div className="flex justify-between text-slate-500 font-medium text-[11px]">
                <span>المجموع الفرعي (قبل الرسوم والضريبة):</span>
                <span className="font-mono font-bold">{(subtotal - taxAmount).toFixed(2)} {activeBranch?.currency || 'ل.س'}</span>
              </div>
              <div className="flex justify-between text-slate-500 font-medium text-[11px]">
                <span className="flex items-center gap-1">
                  <span>الرسوم الضريبية (إنفاق استهلاكي وإدارة محلية):</span>
                  <span className="text-[9px] bg-blue-50 text-blue-700 px-1 py-0.2 rounded font-mono font-bold">
                    {syrianTax.rule_applied}
                  </span>
                </span>
                <span className="font-mono text-blue-600 font-bold">{taxAmount.toFixed(2)} {activeBranch?.currency || 'ل.س'}</span>
              </div>
              <div className="flex justify-between items-center text-sm font-black text-slate-900 pt-1.5 border-t border-slate-200">
                <span>المبلغ الإجمالي المطلوب:</span>
                <span className="font-mono text-2xl text-emerald-600 font-black">
                  {grandTotal.toFixed(2)} <span className="text-xs text-slate-400 font-sans">{activeBranch?.currency || 'ل.س'}</span>
                </span>
              </div>
            </div>

            {/* Quick Action Buttons (Park Cart, Clear, F4 Checkout) */}
            <div className="grid grid-cols-3 gap-2 pt-0.5">
              <button
                type="button"
                onClick={handleParkCurrentCart}
                disabled={cart.length === 0}
                className="py-2.5 bg-amber-50 hover:bg-amber-100 disabled:opacity-40 text-amber-800 rounded-xl text-xs font-bold transition-all flex items-center justify-center gap-1.5 border border-amber-200 shadow-xs active:scale-95 cursor-pointer"
                title="تعليق الفاتورة لخدمة العميل التالي (F8)"
              >
                <PauseCircle className="w-4 h-4" />
                <span>تعليق (F8)</span>
              </button>

              <button
                type="button"
                onClick={handleClearCart}
                disabled={cart.length === 0}
                className="py-2.5 bg-rose-50 hover:bg-rose-100 disabled:opacity-40 text-rose-700 rounded-xl text-xs font-bold transition-all flex items-center justify-center gap-1.5 border border-rose-200 shadow-xs active:scale-95 cursor-pointer"
                title="إلغاء الفاتورة"
              >
                <Trash2 className="w-4 h-4" />
                <span>مسح</span>
              </button>

              <button
                type="button"
                onClick={handleOpenPayment}
                disabled={cart.length === 0 || isSubmittingPayment}
                className="py-2.5 bg-emerald-600 hover:bg-emerald-700 disabled:opacity-40 text-white rounded-xl text-xs font-black shadow-lg shadow-emerald-600/30 transition-all flex items-center justify-center gap-1.5 active:scale-95 cursor-pointer"
                title="الدفع وإصدار الفاتورة (F4)"
              >
                <DollarSign className="w-4 h-4" />
                <span>{isSubmittingPayment ? 'جاري الحفظ...' : 'دفع (F4)'}</span>
              </button>
            </div>
          </div>
        </section>

        {/* RIGHT COLUMN: SPEED TOUCH-SCREEN PRODUCT GRID & CATEGORIES */}
        <main className="flex-1 flex flex-col bg-slate-100 overflow-hidden">
          
          {/* Category Tabs & Quick Search */}
          <div className="p-3 bg-white border-b border-slate-200 flex items-center justify-between gap-3 shrink-0 shadow-xs">
            {/* Quick Categories Bar */}
            <div className="flex items-center gap-1.5 overflow-x-auto no-scrollbar py-0.5">
              <button
                onClick={() => setSelectedCategoryId('all')}
                className={`px-3 py-1.5 rounded-xl text-xs font-bold whitespace-nowrap transition-all ${
                  selectedCategoryId === 'all'
                    ? 'bg-blue-600 text-white shadow-sm'
                    : 'bg-slate-100 text-slate-700 hover:bg-slate-200 hover:text-slate-900'
                }`}
              >
                الكل ({products.length})
              </button>
              {initialCategories.slice(0, 10).map((cat: Category) => (
                <button
                  key={cat.id}
                  onClick={() => setSelectedCategoryId(cat.id)}
                  className={`px-3 py-1.5 rounded-xl text-xs font-bold whitespace-nowrap transition-all ${
                    selectedCategoryId === cat.id
                      ? 'bg-blue-600 text-white shadow-sm'
                      : 'bg-slate-100 text-slate-700 hover:bg-slate-200 hover:text-slate-900'
                  }`}
                >
                  {cat.name_ar}
                </button>
              ))}
            </div>

            {/* Search Filter (Safe focus) */}
            <div className="relative w-56 shrink-0 hidden sm:block">
              <Search className="w-3.5 h-3.5 text-slate-400 absolute right-3 top-2.5" />
              <input
                type="text"
                placeholder="بحث سريع بالاسم أو السعر..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                onClick={(e) => e.stopPropagation()}
                onFocus={(e) => e.stopPropagation()}
                className="w-full pr-8 pl-3 py-1.5 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 placeholder:text-slate-400 focus:outline-none focus:border-blue-600 focus:bg-white"
              />
            </div>
          </div>

          {/* Speed Touch Tiles Grid */}
          <div className="flex-1 p-4 overflow-y-auto">
            <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6 gap-3">
              {filteredProducts.map((product) => {
                const isDeactivated = product.is_active === false;
                return (
                  <button
                    key={product.id}
                    disabled={isDeactivated}
                    onClick={() => handleAddToCart(product)}
                    className={`group rounded-2xl p-2.5 text-right transition-all duration-150 flex flex-col justify-between shadow-xs ${
                      isDeactivated
                        ? 'bg-slate-50 border border-slate-200 opacity-50 cursor-not-allowed'
                        : 'bg-white hover:bg-blue-50/50 border border-slate-200 hover:border-blue-500 hover:shadow-md active:scale-95'
                    }`}
                  >
                    {/* Thumbnail */}
                    <div className="w-full aspect-square rounded-xl bg-slate-50 overflow-hidden relative mb-2 border border-slate-100">
                      {product.images?.[0] ? (
                        <img
                          src={product.images[0]}
                          alt=""
                          className={`w-full h-full object-cover transition-transform duration-200 ${
                            isDeactivated ? 'grayscale' : 'group-hover:scale-105'
                          }`}
                          loading="lazy"
                        />
                      ) : (
                        <div className="w-full h-full flex items-center justify-center text-slate-300">
                          <ShoppingBag className="w-8 h-8" />
                        </div>
                      )}
                      <span className="absolute top-1.5 right-1.5 px-1.5 py-0.5 rounded-md bg-slate-900/70 text-white text-[9px] font-mono">
                        {product.unit || 'حبة'}
                      </span>
                      {isDeactivated && (
                        <span className="absolute inset-0 bg-rose-950/40 backdrop-blur-[1px] flex items-center justify-center text-white text-[10px] font-black tracking-wider">
                          معطل بالمول ⏸️
                        </span>
                      )}
                    </div>

                    {/* Title & Price */}
                    <div>
                      <h4 className={`text-xs font-bold line-clamp-2 leading-tight transition-colors ${
                        isDeactivated ? 'text-slate-400 line-through' : 'text-slate-800 group-hover:text-blue-700'
                      }`}>
                        {product.name_ar}
                      </h4>
                      <div className="mt-2 flex items-center justify-between">
                        <span className={`font-mono text-sm font-black ${
                          isDeactivated ? 'text-slate-400' : 'text-emerald-700'
                        }`}>
                          {product.price.toFixed(2)}
                        </span>
                        {!isDeactivated && (
                          <div className="w-6 h-6 rounded-lg bg-blue-50 text-blue-600 group-hover:bg-blue-600 group-hover:text-white flex items-center justify-center transition-all shadow-xs">
                            <Plus className="w-3.5 h-3.5" />
                          </div>
                        )}
                      </div>
                    </div>
                  </button>
                );
              })}
            </div>
          </div>
        </main>
      </div>

      {/* 3. MODAL: PAYMENT CHECKOUT DRAWER (LIGHT THEME) */}
      {isPaymentModalOpen && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white border border-slate-200 rounded-3xl max-w-lg w-full p-6 shadow-2xl space-y-5 animate-fade-in text-slate-900">
            <div className="flex items-center justify-between border-b border-slate-100 pb-4">
              <div>
                <h3 className="text-base font-black text-slate-900 flex items-center gap-2">
                  <DollarSign className="w-5 h-5 text-emerald-600" />
                  تسوية الفاتورة والدفع (Checkout)
                </h3>
                <span className="text-xs text-slate-500">
                  إجمالي المبلغ المطلوب: <strong className="text-emerald-700 font-mono text-sm">{grandTotal.toFixed(2)} {activeBranch?.currency || 'ل.س'}</strong>
                </span>
              </div>
              <button
                onClick={() => setIsPaymentModalOpen(false)}
                className="p-2 text-slate-400 hover:text-slate-700 rounded-xl hover:bg-slate-100"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Payment Method Selector */}
            <div className="grid grid-cols-3 gap-2">
              <button
                type="button"
                onClick={() => setPaymentMethod('cash')}
                className={`py-3 rounded-2xl border text-xs font-bold flex flex-col items-center gap-1.5 transition-all ${
                  paymentMethod === 'cash'
                    ? 'border-emerald-600 bg-emerald-50 text-emerald-800 ring-2 ring-emerald-600/30'
                    : 'border-slate-200 bg-slate-50 text-slate-600 hover:bg-slate-100'
                }`}
              >
                <DollarSign className="w-5 h-5 text-emerald-600" />
                <span>نقدي (Cash)</span>
              </button>

              <button
                type="button"
                onClick={() => setPaymentMethod('card')}
                className={`py-3 rounded-2xl border text-xs font-bold flex flex-col items-center gap-1.5 transition-all ${
                  paymentMethod === 'card'
                    ? 'border-blue-600 bg-blue-50 text-blue-800 ring-2 ring-blue-600/30'
                    : 'border-slate-200 bg-slate-50 text-slate-600 hover:bg-slate-100'
                }`}
              >
                <CreditCard className="w-5 h-5 text-blue-600" />
                <span>مدى / بطاقة (Mada)</span>
              </button>

              <button
                type="button"
                onClick={() => setPaymentMethod('split')}
                className={`py-3 rounded-2xl border text-xs font-bold flex flex-col items-center gap-1.5 transition-all ${
                  paymentMethod === 'split'
                    ? 'border-purple-600 bg-purple-50 text-purple-800 ring-2 ring-purple-600/30'
                    : 'border-slate-200 bg-slate-50 text-slate-600 hover:bg-slate-100'
                }`}
              >
                <ArrowLeftRight className="w-5 h-5 text-purple-600" />
                <span>دفع مجزأ (Split)</span>
              </button>
            </div>

            {/* Cash Calculator */}
            {paymentMethod === 'cash' && (
              <div className="space-y-3 bg-slate-50 p-4 rounded-2xl border border-slate-200">
                <label className="text-xs font-bold text-slate-700 block">المبلغ المستلم من العميل نقداً:</label>
                <div className="flex items-center gap-2">
                  <input
                    type="number"
                    step="1"
                    value={cashReceived}
                    onChange={(e) => setCashReceived(Number(e.target.value))}
                    className="flex-1 p-3 bg-white border border-slate-300 rounded-xl font-mono text-xl text-center font-black text-slate-900 focus:outline-none focus:border-emerald-600 shadow-xs"
                  />
                  <span className="font-bold text-xs text-slate-500">{activeBranch?.currency || 'ل.س'}</span>
                </div>

                {/* Quick Cash Buttons */}
                <div className="flex items-center gap-1.5 flex-wrap">
                  {[Math.ceil(grandTotal), 50, 100, 200, 500, 1000].map((amt) => (
                    <button
                      key={amt}
                      type="button"
                      onClick={() => setCashReceived(amt)}
                      className="px-3 py-1.5 bg-white border border-slate-200 hover:bg-slate-100 text-xs font-mono font-bold rounded-lg text-slate-700 shadow-xs"
                    >
                      +{amt}
                    </button>
                  ))}
                </div>

                {/* Change Due Display */}
                <div className="p-3 bg-emerald-50 border border-emerald-200 rounded-xl flex items-center justify-between">
                  <span className="text-xs font-bold text-emerald-800">المتبقي للعميل (Change Due):</span>
                  <span className="font-mono text-xl font-black text-emerald-700">
                    {Math.max(0, cashReceived - grandTotal).toFixed(2)} {activeBranch?.currency || 'ل.س'}
                  </span>
                </div>

                {cashReceived < grandTotal && (
                  <div className="p-2.5 bg-rose-50 border border-rose-200 text-rose-700 rounded-xl text-xs font-bold flex items-center gap-1.5">
                    <AlertTriangle className="w-4 h-4 shrink-0" />
                    <span>⚠️ المبلغ المستلم أقل من قيمة الفاتورة بمقدار {(grandTotal - cashReceived).toFixed(2)} {activeBranch?.currency || 'ل.س'}</span>
                  </div>
                )}
              </div>
            )}

            {/* Card Payment Confirmation */}
            {paymentMethod === 'card' && (
              <div className="space-y-3 bg-blue-50/60 p-4 rounded-2xl border border-blue-200">
                <div className="flex items-center justify-between">
                  <span className="text-xs font-bold text-blue-900 flex items-center gap-1.5">
                    <CreditCard className="w-4 h-4 text-blue-600" />
                    تحصيل بطاقة شبكة مدى / POS Terminal
                  </span>
                  <span className="font-mono text-base font-black text-blue-700">
                    {grandTotal.toFixed(2)} {activeBranch?.currency || 'ل.س'}
                  </span>
                </div>

                <div>
                  <label className="text-[11px] font-bold text-slate-700 block mb-1">
                    مرجع التفويض / رقم إيصال جهاز الشبكة (Auth / Ref Number):
                  </label>
                  <input
                    type="text"
                    value={cardAuthCode}
                    onChange={(e) => setCardAuthCode(e.target.value)}
                    placeholder="مثال: MADA-982145 أو مرجع العملية"
                    className="w-full p-2.5 bg-white border border-slate-300 rounded-xl font-mono text-sm text-slate-900 focus:outline-none focus:border-blue-600 shadow-xs"
                  />
                </div>

                <label className="flex items-center gap-2 p-2.5 bg-white border border-blue-200 rounded-xl cursor-pointer hover:bg-blue-50/30 transition-all">
                  <input
                    type="checkbox"
                    checked={isCardConfirmed}
                    onChange={(e) => setIsCardConfirmed(e.target.checked)}
                    className="w-4 h-4 text-blue-600 rounded border-slate-300 focus:ring-blue-500"
                  />
                  <span className="text-xs font-bold text-slate-800">
                    تم تأكيد العملية بنجاح عبر جهاز نقاط البيع المعتمد
                  </span>
                </label>
              </div>
            )}

            {/* Split Payment */}
            {paymentMethod === 'split' && (
              <div className="space-y-3 bg-slate-50 p-4 rounded-2xl border border-slate-200">
                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="text-[11px] font-bold text-slate-500 block mb-1">المبلغ كاش (Cash)</label>
                    <input
                      type="number"
                      value={cashReceived}
                      onChange={(e) => setCashReceived(Number(e.target.value))}
                      className="w-full p-2.5 bg-white border border-slate-300 rounded-xl font-mono text-sm text-center font-bold text-emerald-700 focus:outline-none focus:border-emerald-600 shadow-xs"
                    />
                  </div>
                  <div>
                    <label className="text-[11px] font-bold text-slate-500 block mb-1">المبلغ بالبطاقة (Card)</label>
                    <input
                      type="number"
                      value={cardAmount}
                      onChange={(e) => setCardAmount(Number(e.target.value))}
                      className="w-full p-2.5 bg-white border border-slate-300 rounded-xl font-mono text-sm text-center font-bold text-blue-700 focus:outline-none focus:border-blue-600 shadow-xs"
                    />
                  </div>
                </div>

                <div>
                  <label className="text-[11px] font-bold text-slate-700 block mb-1">
                    مرجع تفويض البطاقة (Mada Auth Ref):
                  </label>
                  <input
                    type="text"
                    value={cardAuthCode}
                    onChange={(e) => setCardAuthCode(e.target.value)}
                    placeholder="مثال: MADA-SPLIT-1234"
                    className="w-full p-2 bg-white border border-slate-300 rounded-xl font-mono text-xs text-slate-900 focus:outline-none focus:border-purple-600 shadow-xs"
                  />
                </div>

                {((cashReceived || 0) + (cardAmount || 0)) < grandTotal && (
                  <div className="p-2 bg-rose-50 border border-rose-200 text-rose-700 rounded-xl text-[11px] font-bold">
                    ⚠️ المجموع ({(cashReceived || 0) + (cardAmount || 0)}) أقل من إجمالي الفاتورة ({grandTotal.toFixed(2)})
                  </div>
                )}
              </div>
            )}

            {/* Sound Effect Toggle Control */}
            <div className="flex items-center justify-between p-3 bg-slate-50 border border-slate-200 rounded-2xl">
              <div className="flex items-center gap-2.5">
                <div className={`p-2 rounded-xl ${isSoundEnabled ? 'bg-emerald-100 text-emerald-700' : 'bg-slate-200 text-slate-500'}`}>
                  {isSoundEnabled ? <Volume2 className="w-4 h-4 animate-pulse" /> : <VolumeX className="w-4 h-4" />}
                </div>
                <div>
                  <div className="text-xs font-bold text-slate-800">صوت درج النقود وعدّ الكاش</div>
                  <div className="text-[10px] text-slate-500">تأثير صوتي حقيقي ومحفز عند إتمام الدفع</div>
                </div>
              </div>
              <button
                type="button"
                onClick={toggleSound}
                className={`px-3 py-1.5 text-xs font-bold rounded-xl border transition-all ${
                  isSoundEnabled
                    ? 'bg-emerald-600 text-white border-emerald-700 shadow-xs'
                    : 'bg-white text-slate-600 border-slate-300 hover:bg-slate-100'
                }`}
              >
                {isSoundEnabled ? 'مفعّل 🔔' : 'صامت 🔕'}
              </button>
            </div>

            {/* Confirm Payment Button */}
            <button
              onClick={handleCompletePayment}
              disabled={isSubmittingPayment}
              className={`w-full py-3.5 text-white rounded-2xl font-black text-sm shadow-xl transition-all flex items-center justify-center gap-2 ${
                isSubmittingPayment
                  ? 'bg-slate-400 cursor-not-allowed'
                  : 'bg-emerald-600 hover:bg-emerald-700 shadow-emerald-600/30'
              }`}
            >
              {isSubmittingPayment ? (
                <>
                  <RefreshCw className="w-5 h-5 animate-spin" />
                  <span>جاري تسجيل المعاملة وخصم المخزون...</span>
                </>
              ) : (
                <>
                  <CheckCircle2 className="w-5 h-5" />
                  <span>تأكيد وطباعة الفاتورة (Enter)</span>
                </>
              )}
            </button>
          </div>
        </div>
      )}

      {/* 4. MODAL: ZATCA-COMPLIANT 80MM THERMAL RECEIPT */}
      {isReceiptModalOpen && currentTransaction && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white text-slate-900 rounded-3xl max-w-sm w-full p-4 sm:p-5 shadow-2xl space-y-4 max-h-[92vh] overflow-y-auto print:m-0 print:p-0 select-text">
            {/* Customized Thermal Receipt Component */}
            <div className="rounded-2xl border border-slate-200 overflow-hidden shadow-xs">
              <ThermalReceiptView
                data={{
                  receipt_number: currentTransaction.receipt_number,
                  branch_name: currentTransaction.branch_name || activeBranch?.name_ar || invoiceSettings.branchName,
                  terminal_code: currentTransaction.terminal_code,
                  cashier_name: currentTransaction.cashier_name,
                  customer_name: currentTransaction.customer_name,
                  customer_phone: currentTransaction.customer_phone,
                  created_at: currentTransaction.created_at,
                  items: currentTransaction.items.map((it) => ({
                    name_ar: it.name_ar,
                    name_en: it.name_en,
                    quantity: it.quantity,
                    price: it.price,
                    total: it.total,
                    unit: it.unit,
                    barcode: it.barcode,
                  })),
                  subtotal: currentTransaction.subtotal,
                  tax_amount: currentTransaction.tax_amount,
                  discount_amount: currentTransaction.discount_amount,
                  grand_total: currentTransaction.grand_total,
                  payment_method: currentTransaction.payment_method,
                  cash_received: currentTransaction.cash_received,
                  change_given: currentTransaction.change_given,
                }}
                settings={invoiceSettings}
                isPreview={false}
                isReprint={isReprint}
                reprintCount={reprintCount}
              />
            </div>

            {/* Modal Actions */}
            <div className="flex flex-col gap-2 pt-2 border-t border-slate-200 print:hidden">
              <button
                onClick={async () => {
                  window.print();
                  const res = await recordInvoicePrintInDb(
                    currentTransaction.receipt_number,
                    isReprint ? 'reprint' : 'original',
                    cashierName,
                    terminalCode,
                    isReprint ? reprintReasonInput : undefined
                  );
                  if (res.isReprint) {
                    setReprintCount(res.reprintCount);
                  }
                }}
                className="w-full py-2.5 bg-blue-600 hover:bg-blue-700 text-white rounded-xl text-xs font-bold flex items-center justify-center gap-2 shadow-sm transition-colors"
              >
                <Printer className="w-4 h-4" />
                <span>{isReprint ? `طباعة نسخة إضافية (نسخة #${reprintCount + 1})` : 'طباعة الفاتورة الحرارية'}</span>
              </button>

              <button
                onClick={() => {
                  const reason = window.prompt('يرجى كتابة سبب إعادة الطباعة:', 'طلب العميل نسخة إضافية للضمان');
                  if (reason !== null) {
                    setIsReprint(true);
                    setReprintCount((prev) => prev + 1);
                    setReprintReasonInput(reason || 'طلب نسخة إضافية');
                  }
                }}
                className="w-full py-2 bg-rose-50 hover:bg-rose-100 text-rose-800 border border-rose-200 rounded-xl text-xs font-bold flex items-center justify-center gap-1.5 transition-colors"
              >
                <Copy className="w-3.5 h-3.5 text-rose-600" />
                <span>إعادة طباعة (نسخة طبق الأصل معتمدة)</span>
              </button>

              <a
                href={`#invoice?id=${encodeURIComponent(currentTransaction.receipt_number)}`}
                target="_blank"
                rel="noreferrer"
                className="w-full py-2 bg-slate-100 hover:bg-slate-200 text-slate-800 rounded-xl text-xs font-bold flex items-center justify-center gap-1.5 transition-colors text-center"
              >
                <Eye className="w-3.5 h-3.5 text-blue-600" />
                <span>عرض الفاتورة الإلكترونية الكاملة</span>
              </a>

              <div className="flex items-center gap-2">
                {onNavigateToInvoiceDesigner && (
                  <button
                    onClick={() => {
                      setIsReceiptModalOpen(false);
                      onNavigateToInvoiceDesigner();
                    }}
                    className="flex-1 py-2 bg-slate-100 hover:bg-slate-200 text-slate-700 rounded-xl text-xs font-bold flex items-center justify-center gap-1.5 transition-colors"
                  >
                    <Receipt className="w-3.5 h-3.5 text-blue-600" />
                    <span>تعديل شكل الفاتورة</span>
                  </button>
                )}
                <button
                  onClick={() => setIsReceiptModalOpen(false)}
                  className="px-4 py-2 bg-slate-100 hover:bg-slate-200 text-slate-700 rounded-xl text-xs font-bold transition-colors"
                >
                  إغلاق
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* 5. MODAL: PARKED CARTS MANAGEMENT (LIGHT THEME) */}
      {isParkedModalOpen && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white border border-slate-200 rounded-3xl max-w-lg w-full p-6 shadow-2xl space-y-4 text-slate-900">
            <div className="flex items-center justify-between border-b border-slate-100 pb-3">
              <h3 className="text-base font-black flex items-center gap-2 text-amber-700">
                <PauseCircle className="w-5 h-5 text-amber-600" />
                الفواتير المعلقة في الانتظار ({parkedCarts.length})
              </h3>
              <button
                onClick={() => setIsParkedModalOpen(false)}
                className="p-1.5 text-slate-400 hover:text-slate-700 rounded-lg hover:bg-slate-100"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {parkedCarts.length === 0 ? (
              <p className="text-xs text-slate-400 text-center py-8">لا توجد فواتير معلقة حالياً.</p>
            ) : (
              <div className="space-y-2 max-h-[60vh] overflow-y-auto">
                {parkedCarts.map((parked) => (
                  <div
                    key={parked.id}
                    className="p-3 bg-slate-50 border border-slate-200 rounded-2xl flex items-center justify-between gap-3 shadow-xs"
                  >
                    <div>
                      <div className="text-xs font-bold text-slate-900 flex items-center gap-2">
                        <span>#{parked.cart_number} - {parked.customer_name}</span>
                        <span className="text-[10px] text-slate-400 font-mono">({parked.parked_at})</span>
                      </div>
                      <div className="text-[11px] text-slate-500 mt-1">
                        {parked.items.length} أصناف • إجمالي: <strong className="text-emerald-700 font-mono">{parked.total.toFixed(2)}</strong>
                      </div>
                    </div>

                    <button
                      onClick={() => handleRestoreParkedCart(parked)}
                      className="px-3.5 py-2 bg-amber-500 hover:bg-amber-600 text-white rounded-xl text-xs font-black transition-all flex items-center gap-1 shadow-xs"
                    >
                      <PlayCircle className="w-4 h-4" />
                      استرجاع الفاتورة
                    </button>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      )}

      {/* 6A. MODAL: OPEN NEW CASHIER SHIFT */}
      {isOpenShiftModalOpen && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white border border-slate-200 rounded-3xl max-w-md w-full p-6 shadow-2xl space-y-4 text-slate-900 animate-in fade-in zoom-in duration-200">
            <div className="flex items-center justify-between border-b border-slate-100 pb-3">
              <h3 className="text-base font-black flex items-center gap-2 text-emerald-700">
                <Clock className="w-5 h-5 text-emerald-600" />
                بدء وردية كاشير جديدة (Open Shift)
              </h3>
              {activeShift && (
                <button
                  onClick={() => setIsOpenShiftModalOpen(false)}
                  className="p-1.5 text-slate-400 hover:text-slate-700 rounded-lg hover:bg-slate-100"
                >
                  <X className="w-5 h-5" />
                </button>
              )}
            </div>

            <p className="text-xs text-slate-500 leading-relaxed">
              يرجى التحقق من الرصيد الافتتاحي الفعلي في درج النقدية قبل بدء عمليات البيع لضمان دقة المطابقة المحاسبية.
            </p>

            <div className="space-y-3 text-xs">
              <div className="flex justify-between p-2.5 bg-slate-50 rounded-xl border border-slate-200">
                <span className="text-slate-500">الفرع والجهاز:</span>
                <span className="font-bold text-slate-900">{activeBranch?.name_ar} ({terminalCode})</span>
              </div>
              <div className="flex justify-between p-2.5 bg-slate-50 rounded-xl border border-slate-200">
                <span className="text-slate-500">اسم الكاشير:</span>
                <span className="font-bold text-blue-700">{cashierName}</span>
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1">
                  الرصيد الافتتاحي للدرج (Opening Cash Balance):
                </label>
                <div className="relative">
                  <input
                    type="number"
                    step="0.01"
                    min="0"
                    value={openingBalanceInput}
                    onChange={(e) => setOpeningBalanceInput(e.target.value)}
                    placeholder="0.00"
                    className="w-full px-3 py-2.5 bg-slate-50 border border-slate-300 rounded-xl font-mono text-base font-bold text-slate-900 outline-none focus:ring-2 focus:ring-emerald-500"
                  />
                  <span className="absolute left-3 top-2.5 text-xs text-slate-400 font-bold">
                    {activeBranch?.currency || 'ل.س'}
                  </span>
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1">ملاحظات الفتح (اختياري):</label>
                <input
                  type="text"
                  value={openShiftNotes}
                  onChange={(e) => setOpenShiftNotes(e.target.value)}
                  placeholder="مثال: فكة نقدية من الإدارة..."
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-300 rounded-xl text-xs text-slate-900 outline-none focus:ring-2 focus:ring-emerald-500"
                />
              </div>
            </div>

            <div className="pt-2 flex items-center gap-2">
              <button
                disabled={isOpeningShift}
                onClick={handleOpenShiftSubmit}
                className="w-full py-3 bg-emerald-600 hover:bg-emerald-700 disabled:opacity-50 text-white rounded-xl text-xs font-black shadow-lg shadow-emerald-600/30 transition-all flex items-center justify-center gap-2"
              >
                {isOpeningShift ? (
                  <>
                    <RefreshCw className="w-4 h-4 animate-spin" />
                    <span>جاري فتح الوردية وتوثيق السجل...</span>
                  </>
                ) : (
                  <>
                    <CheckCircle2 className="w-4 h-4" />
                    <span>فتح الوردية واعتماد الصندوق</span>
                  </>
                )}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* 6B. MODAL: SHIFT Z-REPORT MANAGEMENT & AUDIT TABS */}
      {isShiftModalOpen && activeShift && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex items-center justify-center p-3 sm:p-4">
          <div className="bg-white border border-slate-200 rounded-3xl max-w-2xl w-full p-5 sm:p-6 shadow-2xl space-y-4 text-slate-900 max-h-[92vh] overflow-y-auto">
            {/* Modal Header */}
            <div className="flex items-center justify-between border-b border-slate-100 pb-3">
              <div>
                <h3 className="text-base font-black flex items-center gap-2 text-emerald-800">
                  <Clock className="w-5 h-5 text-emerald-600" />
                  <span>إدارة وردية الكاشير</span>
                  <span className="text-xs font-mono font-bold text-slate-500">({activeShift.shift_number})</span>
                </h3>
                <p className="text-[11px] text-slate-500 mt-0.5">
                  الفرع: {activeShift.branch_name} • الجهاز: {activeShift.terminal_code} • الكاشير: {activeShift.cashier_name}
                </p>
              </div>
              <button
                onClick={() => setIsShiftModalOpen(false)}
                className="p-1.5 text-slate-400 hover:text-slate-700 rounded-lg hover:bg-slate-100"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Navigation Tabs */}
            <div className="flex items-center gap-1.5 p-1 bg-slate-100 rounded-2xl text-xs font-bold">
              <button
                onClick={() => setShiftActiveTab('summary')}
                className={`flex-1 py-2 rounded-xl transition-all flex items-center justify-center gap-1.5 ${
                  shiftActiveTab === 'summary'
                    ? 'bg-white text-emerald-800 shadow-xs font-black'
                    : 'text-slate-600 hover:text-slate-900'
                }`}
              >
                <FileText className="w-3.5 h-3.5" />
                <span>الملخص والإغلاق</span>
              </button>

              <button
                onClick={() => setShiftActiveTab('movements')}
                className={`flex-1 py-2 rounded-xl transition-all flex items-center justify-center gap-1.5 ${
                  shiftActiveTab === 'movements'
                    ? 'bg-white text-blue-800 shadow-xs font-black'
                    : 'text-slate-600 hover:text-slate-900'
                }`}
              >
                <DollarSign className="w-3.5 h-3.5" />
                <span>حركات النقدية (توريد/تسليم)</span>
              </button>

              <button
                onClick={() => {
                  setShiftActiveTab('ledger');
                  loadShiftMovements(activeShift.id);
                }}
                className={`flex-1 py-2 rounded-xl transition-all flex items-center justify-center gap-1.5 ${
                  shiftActiveTab === 'ledger'
                    ? 'bg-white text-purple-800 shadow-xs font-black'
                    : 'text-slate-600 hover:text-slate-900'
                }`}
              >
                <History className="w-3.5 h-3.5" />
                <span>سجل الحركات الدائم</span>
              </button>

              <button
                onClick={() => {
                  setShiftActiveTab('remote_close');
                  loadBranchOpenShifts(activeBranch?.id || targetBranchId || 'b-jed-01');
                }}
                className={`flex-1 py-2 rounded-xl transition-all flex items-center justify-center gap-1.5 ${
                  shiftActiveTab === 'remote_close'
                    ? 'bg-white text-amber-800 shadow-xs font-black'
                    : 'text-slate-600 hover:text-slate-900'
                }`}
              >
                <ShieldCheck className="w-3.5 h-3.5" />
                <span>إشراف الفرع وعن بعد</span>
              </button>
            </div>

            {/* TAB 1: SUMMARY & CLOSE */}
            {shiftActiveTab === 'summary' && (
              <div className="space-y-4">
                <div className="grid grid-cols-2 sm:grid-cols-3 gap-2.5 text-xs">
                  <div className="p-2.5 bg-slate-50 border border-slate-200 rounded-xl">
                    <span className="text-slate-500 block text-[11px]">الرصيد الافتتاحي</span>
                    <strong className="text-slate-900 font-mono text-sm">{activeShift.opening_balance.toFixed(2)}</strong>
                  </div>

                  <div className="p-2.5 bg-emerald-50 border border-emerald-200 rounded-xl">
                    <span className="text-emerald-700 block text-[11px]">مبيعات الكاش (+)</span>
                    <strong className="text-emerald-900 font-mono text-sm">{activeShift.cash_sales.toFixed(2)}</strong>
                  </div>

                  <div className="p-2.5 bg-blue-50 border border-blue-200 rounded-xl">
                    <span className="text-blue-700 block text-[11px]">مبيعات الشبكة/مدى</span>
                    <strong className="text-blue-900 font-mono text-sm">{activeShift.card_sales.toFixed(2)}</strong>
                  </div>

                  <div className="p-2.5 bg-teal-50 border border-teal-200 rounded-xl">
                    <span className="text-teal-700 block text-[11px]">مقبوضات نقدية (+)</span>
                    <strong className="text-teal-900 font-mono text-sm">{(activeShift.cash_receipts ?? 0).toFixed(2)}</strong>
                  </div>

                  <div className="p-2.5 bg-rose-50 border border-rose-200 rounded-xl">
                    <span className="text-rose-700 block text-[11px]">مرتجعات نقدية (-)</span>
                    <strong className="text-rose-900 font-mono text-sm">{(activeShift.cash_refunds ?? 0).toFixed(2)}</strong>
                  </div>

                  <div className="p-2.5 bg-amber-50 border border-amber-200 rounded-xl">
                    <span className="text-amber-700 block text-[11px]">تسليم للخزينة (-)</span>
                    <strong className="text-amber-900 font-mono text-sm">{(activeShift.cash_drops ?? 0).toFixed(2)}</strong>
                  </div>
                </div>

                {/* Highlight: Expected Cash in Drawer */}
                <div className="p-3.5 bg-gradient-to-r from-emerald-50 to-teal-50 border border-emerald-300 rounded-2xl flex items-center justify-between">
                  <div>
                    <span className="text-xs text-emerald-900 font-black block">المبلغ المتوقع في الدرج حالياً:</span>
                    <span className="text-[10px] text-emerald-700">
                      = الرصيد الافتتاحي + مبيعات الكاش + المقبوضات - المرتجعات - التسليمات
                    </span>
                  </div>
                  <span className="font-mono text-lg font-black text-emerald-950">
                    {(activeShift.expected_cash ?? 0).toFixed(2)} {activeBranch?.currency || 'ل.س'}
                  </span>
                </div>

                {/* Shift Close Section */}
                <div className="p-4 bg-slate-50 border border-slate-200 rounded-2xl space-y-3">
                  <h4 className="text-xs font-black text-slate-900 flex items-center gap-1.5">
                    <Lock className="w-3.5 h-3.5 text-rose-600" />
                    <span>إغلاق الوردية والمطابقة النقدية (Z-Report Close)</span>
                  </h4>

                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs">
                    <div>
                      <label className="block font-bold text-slate-700 mb-1">
                        المبلغ الفعلي المعدود بالدرج (Actual Cash Counted):
                      </label>
                      <input
                        type="number"
                        step="0.01"
                        min="0"
                        value={actualCashCountedInput}
                        onChange={(e) => setActualCashCountedInput(e.target.value)}
                        placeholder="0.00"
                        className="w-full px-3 py-2 bg-white border border-slate-300 rounded-xl font-mono text-sm font-bold text-slate-900 outline-none focus:ring-2 focus:ring-rose-500"
                      />
                    </div>

                    <div>
                      <label className="block font-bold text-slate-700 mb-1">
                        الفرق المالي المحسوب (Variance):
                      </label>
                      {actualCashCountedInput !== '' ? (
                        (() => {
                          const actual = parseFloat(actualCashCountedInput) || 0;
                          const diff = actual - (activeShift.expected_cash ?? 0);
                          if (Math.abs(diff) < 0.01) {
                            return (
                              <div className="px-3 py-2 bg-emerald-100 border border-emerald-300 text-emerald-900 font-bold rounded-xl text-xs flex items-center justify-between">
                                <span>متطابق تماماً</span>
                                <span className="font-mono">0.00 ل.س</span>
                              </div>
                            );
                          } else if (diff > 0) {
                            return (
                              <div className="px-3 py-2 bg-blue-100 border border-blue-300 text-blue-900 font-bold rounded-xl text-xs flex items-center justify-between">
                                <span>فائض نقدي (+)</span>
                                <span className="font-mono">+{diff.toFixed(2)} ل.س</span>
                              </div>
                            );
                          } else {
                            return (
                              <div className="px-3 py-2 bg-rose-100 border border-rose-300 text-rose-900 font-bold rounded-xl text-xs flex items-center justify-between">
                                <span>عجز نقدي (-)</span>
                                <span className="font-mono">{diff.toFixed(2)} ل.س</span>
                              </div>
                            );
                          }
                        })()
                      ) : (
                        <div className="px-3 py-2 bg-slate-100 border border-slate-200 text-slate-500 rounded-xl text-xs">
                          بانتظار إدخال المبلغ المعدود...
                        </div>
                      )}
                    </div>
                  </div>

                  <div>
                    <label className="block text-xs font-bold text-slate-700 mb-1">ملاحظات الإغلاق والتسليم:</label>
                    <input
                      type="text"
                      value={closeShiftNotes}
                      onChange={(e) => setCloseShiftNotes(e.target.value)}
                      placeholder="أي فروقات أو مبررات يتم تدوينها هنا بشكل دائم..."
                      className="w-full px-3 py-2 bg-white border border-slate-300 rounded-xl text-xs text-slate-900 outline-none focus:ring-2 focus:ring-rose-500"
                    />
                  </div>

                  <button
                    disabled={isClosingShift || actualCashCountedInput === ''}
                    onClick={handleCloseShiftSubmit}
                    className="w-full py-3 bg-rose-600 hover:bg-rose-700 disabled:opacity-50 text-white rounded-xl text-xs font-black shadow-lg shadow-rose-600/30 transition-all flex items-center justify-center gap-2"
                  >
                    {isClosingShift ? (
                      <>
                        <RefreshCw className="w-4 h-4 animate-spin" />
                        <span>جاري إغلاق الوردية وحساب الفروقات...</span>
                      </>
                    ) : (
                      <>
                        <Lock className="w-4 h-4" />
                        <span>تأكيد إغلاق الوردية واعتماد تقرير Z-Report</span>
                      </>
                    )}
                  </button>
                </div>
              </div>
            )}

            {/* TAB 2: CASH MOVEMENTS (DROP / RECEIPT / REFUND) */}
            {shiftActiveTab === 'movements' && (
              <div className="space-y-4">
                <div className="flex items-center gap-2 p-1 bg-slate-100 rounded-xl text-xs font-bold">
                  <button
                    onClick={() => setCashMovementType('cash_drop')}
                    className={`flex-1 py-1.5 rounded-lg transition-all ${
                      cashMovementType === 'cash_drop' ? 'bg-amber-600 text-white shadow-xs' : 'text-slate-600'
                    }`}
                  >
                    تسليم نقدي للخزينة (Drop)
                  </button>
                  <button
                    onClick={() => setCashMovementType('receipt')}
                    className={`flex-1 py-1.5 rounded-lg transition-all ${
                      cashMovementType === 'receipt' ? 'bg-teal-600 text-white shadow-xs' : 'text-slate-600'
                    }`}
                  >
                    توريد نقدي إضافي (Inflow)
                  </button>
                  <button
                    onClick={() => setCashMovementType('refund_cash')}
                    className={`flex-1 py-1.5 rounded-lg transition-all ${
                      cashMovementType === 'refund_cash' ? 'bg-rose-600 text-white shadow-xs' : 'text-slate-600'
                    }`}
                  >
                    مرتجع نقدي لعميل (Refund)
                  </button>
                </div>

                <div className="p-4 bg-slate-50 border border-slate-200 rounded-2xl space-y-3 text-xs">
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                    <div>
                      <label className="block font-bold text-slate-700 mb-1">المبلغ (Amount):</label>
                      <input
                        type="number"
                        step="0.01"
                        min="0"
                        value={cashMovementAmount}
                        onChange={(e) => setCashMovementAmount(e.target.value)}
                        placeholder="0.00"
                        className="w-full px-3 py-2 bg-white border border-slate-300 rounded-xl font-mono font-bold text-slate-900 outline-none focus:ring-2 focus:ring-blue-500"
                      />
                    </div>
                    <div>
                      <label className="block font-bold text-slate-700 mb-1">رقم السند / الإيصال المرجعي:</label>
                      <input
                        type="text"
                        value={cashMovementRef}
                        onChange={(e) => setCashMovementRef(e.target.value)}
                        placeholder="مثال: VOUCHER-001 أو رقم الفاتورة"
                        className="w-full px-3 py-2 bg-white border border-slate-300 rounded-xl text-slate-900 outline-none focus:ring-2 focus:ring-blue-500"
                      />
                    </div>
                  </div>

                  <div>
                    <label className="block font-bold text-slate-700 mb-1">البيان / السبب:</label>
                    <input
                      type="text"
                      value={cashMovementNotes}
                      onChange={(e) => setCashMovementNotes(e.target.value)}
                      placeholder="سبب الحركة أو اسم المستلم في الخزينة..."
                      className="w-full px-3 py-2 bg-white border border-slate-300 rounded-xl text-slate-900 outline-none focus:ring-2 focus:ring-blue-500"
                    />
                  </div>

                  <button
                    disabled={isSubmittingMovement || !cashMovementAmount}
                    onClick={handleRecordMovementSubmit}
                    className="w-full py-2.5 bg-blue-600 hover:bg-blue-700 disabled:opacity-50 text-white rounded-xl font-bold flex items-center justify-center gap-1.5 shadow-sm transition-all"
                  >
                    {isSubmittingMovement ? (
                      <>
                        <RefreshCw className="w-3.5 h-3.5 animate-spin" />
                        <span>جاري تسجيل الحركة...</span>
                      </>
                    ) : (
                      <>
                        <Check className="w-3.5 h-3.5" />
                        <span>تأكيد تسجيل الحركة في الصندوق</span>
                      </>
                    )}
                  </button>
                </div>
              </div>
            )}

            {/* TAB 3: LIVE LEDGER */}
            {shiftActiveTab === 'ledger' && (
              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <span className="text-xs font-bold text-slate-600">
                    سجل الحركات النقدية الدائم للوردية الحالية ({shiftMovements.length})
                  </span>
                  <button
                    onClick={() => loadShiftMovements(activeShift.id)}
                    className="px-2.5 py-1 bg-slate-100 hover:bg-slate-200 text-slate-700 rounded-lg text-xs font-bold flex items-center gap-1"
                  >
                    <RefreshCw className={`w-3.5 h-3.5 ${isLoadingMovements ? 'animate-spin' : ''}`} />
                    <span>تحديث</span>
                  </button>
                </div>

                <div className="border border-slate-200 rounded-2xl overflow-hidden max-h-64 overflow-y-auto">
                  <table className="w-full text-right text-xs">
                    <thead className="bg-slate-100 border-b border-slate-200 text-slate-600 font-bold sticky top-0">
                      <tr>
                        <th className="p-2.5">النوع</th>
                        <th className="p-2.5">المبلغ</th>
                        <th className="p-2.5">المرجع</th>
                        <th className="p-2.5">المسؤول</th>
                        <th className="p-2.5">الوقت</th>
                        <th className="p-2.5">ملاحظات</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100">
                      {shiftMovements.length === 0 ? (
                        <tr>
                          <td colSpan={6} className="p-4 text-center text-slate-400">
                            {isLoadingMovements ? 'جاري تحميل السجل...' : 'لا توجد حركات مسجلة بعد'}
                          </td>
                        </tr>
                      ) : (
                        shiftMovements.map((m) => (
                          <tr key={m.id} className="hover:bg-slate-50">
                            <td className="p-2.5">
                              <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold ${
                                m.movement_type === 'sale_cash' ? 'bg-emerald-100 text-emerald-800' :
                                m.movement_type === 'sale_card' ? 'bg-blue-100 text-blue-800' :
                                m.movement_type === 'receipt' ? 'bg-teal-100 text-teal-800' :
                                m.movement_type === 'cash_drop' ? 'bg-amber-100 text-amber-800' :
                                m.movement_type === 'refund_cash' ? 'bg-rose-100 text-rose-800' :
                                'bg-slate-100 text-slate-800'
                              }`}>
                                {m.movement_type}
                              </span>
                            </td>
                            <td className="p-2.5 font-mono font-bold text-slate-900">
                              {Number(m.amount).toFixed(2)}
                            </td>
                            <td className="p-2.5 font-mono text-[11px] text-slate-500">{m.reference_id || '-'}</td>
                            <td className="p-2.5 text-slate-700">{m.performed_by}</td>
                            <td className="p-2.5 text-slate-500 font-mono text-[10px]">
                              {new Date(m.created_at).toLocaleTimeString('ar-SA')}
                            </td>
                            <td className="p-2.5 text-slate-600 text-[11px] max-w-[150px] truncate">{m.notes || '-'}</td>
                          </tr>
                        ))
                      )}
                    </tbody>
                  </table>
                </div>
              </div>
            )}

            {/* TAB 4: REMOTE SUPERVISOR CLOSE */}
            {shiftActiveTab === 'remote_close' && (
              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <span className="text-xs font-bold text-slate-700">
                    الورديات المفتوحة في هذا الفرع ({branchOpenShifts.length})
                  </span>
                  <button
                    onClick={() => loadBranchOpenShifts(activeBranch?.id || targetBranchId || 'b-jed-01')}
                    className="px-2.5 py-1 bg-slate-100 hover:bg-slate-200 text-slate-700 rounded-lg text-xs font-bold flex items-center gap-1"
                  >
                    <RefreshCw className={`w-3.5 h-3.5 ${isLoadingBranchShifts ? 'animate-spin' : ''}`} />
                    <span>تحديث القائمة</span>
                  </button>
                </div>

                <div className="space-y-2">
                  {branchOpenShifts.length === 0 ? (
                    <div className="p-4 text-center text-slate-400 bg-slate-50 border border-slate-200 rounded-xl text-xs">
                      لا توجد أي ورديات مفتوحة حالياً في هذا الفرع.
                    </div>
                  ) : (
                    branchOpenShifts.map((s) => (
                      <div
                        key={s.id}
                        className={`p-3 rounded-xl border transition-all text-xs flex flex-wrap items-center justify-between gap-2 ${
                          remoteShiftToClose?.id === s.id
                            ? 'bg-amber-50 border-amber-300 ring-2 ring-amber-500/20'
                            : 'bg-slate-50 border-slate-200 hover:bg-slate-100'
                        }`}
                      >
                        <div>
                          <div className="font-bold text-slate-900 flex items-center gap-1.5">
                            <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
                            <span>{s.cashier_name}</span>
                            <span className="text-slate-500 font-mono text-[11px]">({s.terminal_code})</span>
                          </div>
                          <div className="text-[11px] text-slate-500 mt-0.5">
                            رقم الوردية: <span className="font-mono">{s.shift_number}</span> • وقت الفتح:{' '}
                            <span className="font-mono">{new Date(s.opened_at).toLocaleTimeString('ar-SA')}</span>
                          </div>
                        </div>

                        <div className="flex items-center gap-3">
                          <div className="text-end">
                            <span className="text-[10px] text-slate-500 block">المتوقع بالدرج:</span>
                            <span className="font-mono font-bold text-emerald-800">{Number(s.expected_cash).toFixed(2)} ل.س</span>
                          </div>

                          <button
                            onClick={() => {
                              setRemoteShiftToClose(s);
                              setRemoteActualCash(String(s.expected_cash || ''));
                            }}
                            className="px-3 py-1.5 bg-rose-600 hover:bg-rose-700 text-white rounded-lg font-bold text-xs transition-colors"
                          >
                            إغلاق إداري عن بعد
                          </button>
                        </div>
                      </div>
                    ))
                  )}
                </div>

                {/* Remote close action box */}
                {remoteShiftToClose && (
                  <div className="p-3.5 bg-rose-50 border border-rose-300 rounded-2xl space-y-2.5 text-xs animate-in fade-in duration-150">
                    <h5 className="font-black text-rose-900">
                      تأكيد الإغلاق الإداري لوردية الكاشير: {remoteShiftToClose.cashier_name} ({remoteShiftToClose.shift_number})
                    </h5>

                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                      <div>
                        <label className="block font-bold text-rose-800 mb-1">المبلغ الفعلي المعدود في الصندوق:</label>
                        <input
                          type="number"
                          step="0.01"
                          min="0"
                          value={remoteActualCash}
                          onChange={(e) => setRemoteActualCash(e.target.value)}
                          className="w-full px-3 py-2 bg-white border border-rose-300 rounded-xl font-mono font-bold text-slate-900"
                        />
                      </div>
                      <div>
                        <label className="block font-bold text-rose-800 mb-1">سبب الإغلاق الإداري:</label>
                        <input
                          type="text"
                          value={remoteCloseNotes}
                          onChange={(e) => setRemoteCloseNotes(e.target.value)}
                          placeholder="مثال: مغادرة الكاشير المفاجئة / تعطل الجهاز..."
                          className="w-full px-3 py-2 bg-white border border-rose-300 rounded-xl text-slate-900"
                        />
                      </div>
                    </div>

                    <div className="flex items-center gap-2 pt-1">
                      <button
                        disabled={isClosingShift}
                        onClick={handleRemoteCloseSubmit}
                        className="flex-1 py-2.5 bg-rose-600 hover:bg-rose-700 disabled:opacity-50 text-white rounded-xl font-black shadow-md shadow-rose-600/30 transition-all"
                      >
                        {isClosingShift ? 'جاري الإغلاق...' : 'اعتماد الإغلاق الإشرافي وتوليد تقرير Z'}
                      </button>
                      <button
                        onClick={() => setRemoteShiftToClose(null)}
                        className="px-3 py-2.5 bg-slate-200 hover:bg-slate-300 text-slate-700 rounded-xl font-bold"
                      >
                        إلغاء
                      </button>
                    </div>
                  </div>
                )}
              </div>
            )}
          </div>
        </div>
      )}

      {/* 6C. MODAL: OFFICIAL Z-REPORT SUMMARY (PRINTABLE) */}
      {isZReportModalOpen && closedShiftSummary && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white text-slate-900 rounded-3xl max-w-md w-full p-6 shadow-2xl space-y-4 max-h-[92vh] overflow-y-auto select-text">
            <div className="text-center space-y-1 pb-3 border-b border-dashed border-slate-300">
              <h3 className="text-lg font-black text-slate-950">تقرير إغلاق الوردية النهائي (Z-REPORT)</h3>
              <p className="text-xs text-slate-500 font-mono font-bold">{closedShiftSummary.shift_number}</p>
              <div className="text-[11px] text-slate-600">
                {closedShiftSummary.branch_name} • جهاز: {closedShiftSummary.terminal_code}
              </div>
            </div>

            <div className="space-y-2 text-xs divide-y divide-slate-100">
              <div className="flex justify-between py-1.5">
                <span className="text-slate-500">الكاشير:</span>
                <span className="font-bold text-slate-900">{closedShiftSummary.cashier_name}</span>
              </div>
              <div className="flex justify-between py-1.5">
                <span className="text-slate-500">تم الإغلاق بواسطة:</span>
                <span className="font-bold text-slate-900">{closedShiftSummary.closed_by_name || cashierName}</span>
              </div>
              <div className="flex justify-between py-1.5">
                <span className="text-slate-500">وقت البدء والإغلاق:</span>
                <span className="font-mono text-slate-700">{closedShiftSummary.opened_at} — {closedShiftSummary.closed_at}</span>
              </div>
              <div className="flex justify-between py-1.5">
                <span className="text-slate-500">الرصيد الافتتاحي:</span>
                <span className="font-mono font-bold text-slate-900">{closedShiftSummary.opening_balance.toFixed(2)} ل.س</span>
              </div>
              <div className="flex justify-between py-1.5">
                <span className="text-slate-500">إجمالي مبيعات الكاش (+):</span>
                <span className="font-mono font-bold text-emerald-700">+{closedShiftSummary.cash_sales.toFixed(2)} ل.س</span>
              </div>
              <div className="flex justify-between py-1.5">
                <span className="text-slate-500">إجمالي مبيعات الشبكة/مدى:</span>
                <span className="font-mono font-bold text-blue-700">{closedShiftSummary.card_sales.toFixed(2)} ل.س</span>
              </div>
              <div className="flex justify-between py-1.5">
                <span className="text-slate-500">مقبوضات نقدية أخرى (+):</span>
                <span className="font-mono font-bold text-teal-700">+{(closedShiftSummary.cash_receipts ?? 0).toFixed(2)} ل.س</span>
              </div>
              <div className="flex justify-between py-1.5">
                <span className="text-slate-500">مرتجعات نقدية (-):</span>
                <span className="font-mono font-bold text-rose-700">-{(closedShiftSummary.cash_refunds ?? 0).toFixed(2)} ل.س</span>
              </div>
              <div className="flex justify-between py-1.5">
                <span className="text-slate-500">تسليم نقدي للخزينة (-):</span>
                <span className="font-mono font-bold text-amber-700">-{(closedShiftSummary.cash_drops ?? 0).toFixed(2)} ل.س</span>
              </div>
              <div className="flex justify-between py-2 bg-slate-50 px-2 rounded-xl border border-slate-200 font-bold">
                <span className="text-slate-700">المبلغ المتوقع بالدرج:</span>
                <span className="font-mono text-slate-900">{(closedShiftSummary.expected_cash ?? 0).toFixed(2)} ل.س</span>
              </div>
              <div className="flex justify-between py-2 bg-slate-50 px-2 rounded-xl border border-slate-200 font-bold">
                <span className="text-slate-700">المبلغ الفعلي المعدود:</span>
                <span className="font-mono text-slate-900">{(closedShiftSummary.actual_cash || 0).toFixed(2)} ل.س</span>
              </div>
              <div className="flex justify-between py-2 px-2 rounded-xl font-black text-sm">
                <span>الفارق النهائي (Variance):</span>
                <span className={`font-mono ${
                  (closedShiftSummary.difference || 0) === 0 ? 'text-emerald-700' :
                  (closedShiftSummary.difference || 0) > 0 ? 'text-blue-700' : 'text-rose-700'
                }`}>
                  {(closedShiftSummary.difference || 0) > 0 ? `+${closedShiftSummary.difference?.toFixed(2)} (فائض)` :
                   (closedShiftSummary.difference || 0) < 0 ? `${closedShiftSummary.difference?.toFixed(2)} (عجز)` :
                   '0.00 (متطابق)'}
                </span>
              </div>
            </div>

            <div className="pt-2 flex items-center gap-2 print:hidden">
              <button
                onClick={() => window.print()}
                className="flex-1 py-2.5 bg-blue-600 hover:bg-blue-700 text-white rounded-xl text-xs font-bold flex items-center justify-center gap-1.5 shadow-sm"
              >
                <Printer className="w-4 h-4" />
                <span>طباعة تقرير Z-Report</span>
              </button>
              <button
                onClick={() => setIsZReportModalOpen(false)}
                className="px-4 py-2.5 bg-slate-100 hover:bg-slate-200 text-slate-700 rounded-xl text-xs font-bold"
              >
                إغلاق
              </button>
            </div>
          </div>
        </div>
      )}

      {/* 7. LOCK SCREEN OVERLAY (LIGHT THEME) */}
      {isLocked && (
        <div className="fixed inset-0 z-50 bg-slate-900/60 backdrop-blur-md flex items-center justify-center p-4">
          <div className="bg-white border border-slate-200 p-8 rounded-3xl max-w-xs w-full text-center space-y-4 shadow-2xl">
            <div className="w-16 h-16 mx-auto bg-amber-50 text-amber-600 border border-amber-200 rounded-2xl flex items-center justify-center">
              <Lock className="w-8 h-8" />
            </div>
            <div>
              <h3 className="text-base font-black text-slate-900">نقطة البيع مقفلة مؤقتاً</h3>
              <p className="text-xs text-slate-500 mt-1">
                أدخل رمز PIN للموظف ({currentStaff?.full_name || cashierName}) للاستئناف
              </p>
            </div>

            {pinError && (
              <div className="p-2.5 bg-rose-50 border border-rose-200 text-rose-700 text-xs font-bold rounded-xl animate-shake">
                ⚠️ {pinError}
              </div>
            )}

            <form onSubmit={handleUnlockTerminal} className="space-y-3">
              <input
                type="password"
                maxLength={6}
                autoFocus
                disabled={isUnlockingPin}
                placeholder="• • • •"
                value={pinInput}
                onChange={(e) => {
                  setPinInput(e.target.value);
                  setPinError(null);
                }}
                className="w-full text-center font-mono text-2xl tracking-widest py-3 bg-slate-50 border border-slate-300 rounded-xl text-slate-900 focus:outline-none focus:border-blue-500 shadow-xs"
              />
              <button
                type="submit"
                disabled={isUnlockingPin || !pinInput.trim()}
                className="w-full py-3 bg-blue-600 hover:bg-blue-700 disabled:bg-slate-300 text-white rounded-xl text-xs font-black shadow-md shadow-blue-600/30 transition-all flex items-center justify-center gap-2"
              >
                {isUnlockingPin ? (
                  <>
                    <RefreshCw className="w-4 h-4 animate-spin" />
                    <span>جاري التحقق...</span>
                  </>
                ) : (
                  <span>فتح القفل والاستئناف</span>
                )}
              </button>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
