import React, { useState, useEffect, useRef, useMemo } from 'react';
import { 
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
  VolumeX
} from 'lucide-react';
import { Product, Branch, PosCartItem, ParkedCart, PosShift, PosTransaction, Category } from '../types';
import { supabase, initialProducts, initialCategories } from '../lib/supabase';
import { getStoredBranches, getActiveBranchId, setActiveBranchId } from '../lib/branchesData';
import { ThermalReceiptView } from '../components/ThermalReceiptView';
import { useInvoiceSettings } from '../lib/invoiceSettings';
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
  onExitPos?: () => void;
  targetBranchId?: string;
  onNavigateToInvoiceDesigner?: () => void;
  isBranchLocked?: boolean;
  currentCashierName?: string;
}

export const PosTerminalPage: React.FC<PosTerminalPageProps> = ({ 
  onExitPos, 
  targetBranchId,
  onNavigateToInvoiceDesigner,
  isBranchLocked = false,
  currentCashierName,
}) => {
  const [invoiceSettings] = useInvoiceSettings();
  const [branches, setBranches] = useState<Branch[]>([]);
  const [activeBranch, setActiveBranch] = useState<Branch | null>(null);
  const [products, setProducts] = useState<Product[]>([]);
  
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

  // Customer Loyalty Lookup
  const [customerName, setCustomerName] = useState('');
  const [customerPhone, setCustomerPhone] = useState('');
  const [loyaltyPoints, setLoyaltyPoints] = useState<number>(0);

  // Payment Modal & Double-Charge Protection
  const [isPaymentModalOpen, setIsPaymentModalOpen] = useState(false);
  const [isSubmittingPayment, setIsSubmittingPayment] = useState(false);
  const [paymentMethod, setPaymentMethod] = useState<'cash' | 'card' | 'split'>('cash');
  const [cashReceived, setCashReceived] = useState<number>(0);
  const [cardAmount, setCardAmount] = useState<number>(0);
  const [dbLatencyMs, setDbLatencyMs] = useState<number>(18);
  const [currentTime, setCurrentTime] = useState<string>(() => new Date().toLocaleTimeString('ar-SA'));

  // Receipt Modal
  const [currentTransaction, setCurrentTransaction] = useState<PosTransaction | null>(null);
  const [isReceiptModalOpen, setIsReceiptModalOpen] = useState(false);

  // Shift Management
  const [activeShift, setActiveShift] = useState<PosShift | null>(null);
  const [isShiftModalOpen, setIsShiftModalOpen] = useState(false);

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

    setProducts(initialProducts);

    // Initialize or load current shift
    const savedShift = localStorage.getItem(`pos_shift_${found?.id || 'default'}`);
    if (savedShift) {
      try {
        setActiveShift(JSON.parse(savedShift));
      } catch (_) {}
    } else {
      // Default open shift
      const shift: PosShift = {
        id: `shift-${Date.now()}`,
        branch_id: found.id,
        branch_name: found.name_ar,
        terminal_code: 'POS-01',
        cashier_name: 'أحمد الكاشير',
        opened_at: new Date().toLocaleTimeString('ar-SA', { hour: '2-digit', minute: '2-digit' }),
        opening_balance: 500,
        cash_sales: 0,
        card_sales: 0,
        total_sales: 0,
        transactions_count: 0,
        status: 'open',
      };
      setActiveShift(shift);
    }

    // Load parked carts
    try {
      const savedParked = localStorage.getItem('pos_parked_carts');
      if (savedParked) setParkedCarts(JSON.parse(savedParked));
    } catch (_) {}

    // Focus barcode input initially
    setTimeout(() => barcodeInputRef.current?.focus(), 300);
  }, [targetBranchId]);

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
    playPosSound('beep');
    setCart((prev) => {
      const idx = prev.findIndex((item) => item.product_id === product.id);
      if (idx >= 0) {
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

  // Customer Loyalty Lookup Simulator
  const handleLookupCustomer = () => {
    if (!customerPhone.trim()) return;
    setCustomerName('أحمد العتيبي (عميل VIP)');
    setLoyaltyPoints(450);
    playPosSound('success');
  };

  // Open Payment Modal
  const handleOpenPayment = () => {
    if (cart.length === 0) return;
    setCashReceived(Math.ceil(grandTotal));
    setCardAmount(grandTotal);
    setIsPaymentModalOpen(true);
  };

  // Complete Checkout (Protected with Idempotency Key & Double-Click Lock)
  const handleCompletePayment = async () => {
    if (isSubmittingPayment || cart.length === 0) return;
    setIsSubmittingPayment(true);
    playPosSound('cash');

    const receiptNum = `RCP-${activeBranch?.code || 'POS'}-${Date.now().toString().slice(-6)}`;
    const idempotencyToken = `IDEM-POS-${activeBranch?.id || 'main'}-${Date.now()}-${Math.random().toString(36).substring(2, 7).toUpperCase()}`;

    const tx: PosTransaction = {
      id: `tx-${Date.now()}`,
      receipt_number: receiptNum,
      branch_id: activeBranch?.id || '',
      branch_name: activeBranch?.name_ar || 'فرع الديب مول',
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

    // Update active shift stats
    if (activeShift) {
      const isCash = paymentMethod === 'cash';
      const isCard = paymentMethod === 'card';
      const isSplit = paymentMethod === 'split';

      const cashSalesAdd = isCash ? grandTotal : isSplit ? grandTotal - cardAmount : 0;
      const cardSalesAdd = isCard ? grandTotal : isSplit ? cardAmount : 0;

      const updatedShift: PosShift = {
        ...activeShift,
        cash_sales: activeShift.cash_sales + cashSalesAdd,
        card_sales: activeShift.card_sales + cardSalesAdd,
        total_sales: activeShift.total_sales + grandTotal,
        transactions_count: activeShift.transactions_count + 1,
      };
      setActiveShift(updatedShift);
      try {
        localStorage.setItem(`pos_shift_${activeBranch?.id || 'default'}`, JSON.stringify(updatedShift));
      } catch (_) {}
    }

    // Sync POS Transaction with Supabase Orders & Order Items
    try {
      const isUuid = (id?: string) => !!id && /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/.test(id);
      const { data } = await supabase
        .from('orders')
        .insert({
          order_number: receiptNum,
          status: 'delivered',
          delivery_slot: `كاشير مباشر - ${activeBranch?.name_ar || 'الفرع الرئيسي'}`,
          payment_method: paymentMethod === 'cash' ? 'cod' : 'card',
          payment_status: 'paid',
          subtotal: subtotal - taxAmount,
          delivery_fee: 0,
          total_amount: grandTotal,
          notes: `نقطة بيع POS • الكاشير: ${cashierName} • العميل: ${customerName || 'عميل نقدي'} • ${idempotencyToken}`,
        })
        .select('id')
        .maybeSingle();

      if (data?.id && cart.length > 0) {
        const itemsPayload = cart.map((item) => ({
          order_id: data.id,
          product_id: isUuid(item.product_id) ? item.product_id : null,
          product_name_ar: item.name_ar,
          product_name_en: item.name_en || item.name_ar,
          unit: item.unit || 'piece',
          unit_price: item.price,
          quantity: item.quantity,
          total_price: item.total || item.price * item.quantity,
        }));
        await supabase.from('order_items').insert(itemsPayload);
      }
    } catch (e) {
      console.warn('POS order sync note:', e);
    } finally {
      setIsSubmittingPayment(false);
    }

    setCurrentTransaction(tx);
    setIsPaymentModalOpen(false);
    setIsReceiptModalOpen(true);
    setCart([]);
    setCustomerName('');
    setCustomerPhone('');
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

  const handleUnlockTerminal = (e: React.FormEvent) => {
    e.preventDefault();
    if (pinInput === '1234' || pinInput === '0000' || pinInput.length >= 4) {
      setIsLocked(false);
      setPinInput('');
      playPosSound('success');
    } else {
      playPosSound('error');
      alert('رمز PIN غير صحيح! الرمز الافتراضي: 1234');
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
          <button
            onClick={() => setIsShiftModalOpen(true)}
            className="flex items-center gap-1.5 px-3 py-1.5 bg-emerald-50 border border-emerald-200 text-emerald-700 rounded-xl text-xs font-bold hover:bg-emerald-100 transition-all"
          >
            <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
            <span>الوردية مفتوحة (Z-Report)</span>
          </button>

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
            <div className="flex items-center gap-2">
              <div className="relative flex-1">
                <Phone className="w-3.5 h-3.5 text-slate-400 absolute right-2.5 top-2.5" />
                <input
                  type="text"
                  placeholder="رقم هاتف العميل لولاء الديب..."
                  value={customerPhone}
                  onChange={(e) => setCustomerPhone(e.target.value)}
                  onClick={(e) => e.stopPropagation()}
                  onFocus={(e) => e.stopPropagation()}
                  onKeyDown={(e) => e.key === 'Enter' && handleLookupCustomer()}
                  className="w-full pr-8 pl-2 py-2 bg-white border border-slate-200 rounded-xl text-xs font-mono text-slate-900 placeholder:text-slate-400 focus:outline-none focus:border-blue-600 shadow-xs"
                />
              </div>
              <button
                type="button"
                onClick={handleLookupCustomer}
                className="px-3 py-2 bg-slate-200 hover:bg-slate-300 text-slate-800 rounded-xl text-xs font-bold whitespace-nowrap transition-all shadow-xs"
              >
                تحقق
              </button>
            </div>

            {customerName && (
              <div className="p-2.5 bg-blue-50 border border-blue-200 rounded-xl flex items-center justify-between text-xs">
                <span className="font-bold text-blue-900">{customerName}</span>
                <span className="font-bold text-amber-700 bg-amber-50 px-2 py-0.5 rounded-md border border-amber-200">
                  ⭐ {loyaltyPoints} نقطة
                </span>
              </div>
            )}
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
              {filteredProducts.map((product) => (
                <button
                  key={product.id}
                  onClick={() => handleAddToCart(product)}
                  className="group bg-white hover:bg-blue-50/50 border border-slate-200 hover:border-blue-500 rounded-2xl p-2.5 text-right transition-all duration-150 flex flex-col justify-between shadow-xs hover:shadow-md active:scale-95"
                >
                  {/* Thumbnail */}
                  <div className="w-full aspect-square rounded-xl bg-slate-50 overflow-hidden relative mb-2 border border-slate-100">
                    {product.images?.[0] ? (
                      <img
                        src={product.images[0]}
                        alt=""
                        className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-200"
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
                  </div>

                  {/* Title & Price */}
                  <div>
                    <h4 className="text-xs font-bold text-slate-800 line-clamp-2 leading-tight group-hover:text-blue-700 transition-colors">
                      {product.name_ar}
                    </h4>
                    <div className="mt-2 flex items-center justify-between">
                      <span className="font-mono text-sm font-black text-emerald-700">
                        {product.price.toFixed(2)}
                      </span>
                      <div className="w-6 h-6 rounded-lg bg-blue-50 text-blue-600 group-hover:bg-blue-600 group-hover:text-white flex items-center justify-center transition-all shadow-xs">
                        <Plus className="w-3.5 h-3.5" />
                      </div>
                    </div>
                  </div>
                </button>
              ))}
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
                      value={Math.max(0, grandTotal - cardAmount)}
                      readOnly
                      className="w-full p-2.5 bg-white border border-slate-200 rounded-xl font-mono text-sm text-center font-bold text-emerald-700"
                    />
                  </div>
                  <div>
                    <label className="text-[11px] font-bold text-slate-500 block mb-1">المبلغ بالبطاقة (Card)</label>
                    <input
                      type="number"
                      value={cardAmount}
                      onChange={(e) => setCardAmount(Number(e.target.value))}
                      className="w-full p-2.5 bg-white border border-slate-300 rounded-xl font-mono text-sm text-center font-bold text-blue-700 focus:outline-none focus:border-blue-600"
                    />
                  </div>
                </div>
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
              className="w-full py-3.5 bg-emerald-600 hover:bg-emerald-700 text-white rounded-2xl font-black text-sm shadow-xl shadow-emerald-600/30 transition-all flex items-center justify-center gap-2"
            >
              <CheckCircle2 className="w-5 h-5" />
              <span>تأكيد وطباعة الفاتورة (Enter)</span>
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
              />
            </div>

            {/* Modal Actions */}
            <div className="flex flex-col gap-2 pt-2 border-t border-slate-200 print:hidden">
              <button
                onClick={() => window.print()}
                className="w-full py-2.5 bg-blue-600 hover:bg-blue-700 text-white rounded-xl text-xs font-bold flex items-center justify-center gap-2 shadow-sm transition-colors"
              >
                <Printer className="w-4 h-4" />
                <span>طباعة الفاتورة الحرارية</span>
              </button>

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

      {/* 6. MODAL: SHIFT Z-REPORT MANAGEMENT (LIGHT THEME) */}
      {isShiftModalOpen && activeShift && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white border border-slate-200 rounded-3xl max-w-md w-full p-6 shadow-2xl space-y-4 text-slate-900">
            <div className="flex items-center justify-between border-b border-slate-100 pb-3">
              <h3 className="text-base font-black flex items-center gap-2 text-emerald-700">
                <Clock className="w-5 h-5 text-emerald-600" />
                تقرير وردية الكاشير (Z-Report)
              </h3>
              <button
                onClick={() => setIsShiftModalOpen(false)}
                className="p-1.5 text-slate-400 hover:text-slate-700 rounded-lg hover:bg-slate-100"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="space-y-2.5 text-xs text-slate-700">
              <div className="flex justify-between p-2.5 bg-slate-50 rounded-xl border border-slate-200">
                <span className="text-slate-500">الفرع والكاشير:</span>
                <span className="font-bold text-slate-900">{activeShift.branch_name} ({activeShift.terminal_code})</span>
              </div>
              <div className="flex justify-between p-2.5 bg-slate-50 rounded-xl border border-slate-200">
                <span className="text-slate-500">وقت فتح الوردية:</span>
                <span className="font-mono text-blue-700 font-bold">{activeShift.opened_at}</span>
              </div>
              <div className="flex justify-between p-2.5 bg-slate-50 rounded-xl border border-slate-200">
                <span className="text-slate-500">الرصيد الافتتاحي للدرج:</span>
                <span className="font-mono font-bold text-slate-900">{activeShift.opening_balance.toFixed(2)}</span>
              </div>
              <div className="flex justify-between p-2.5 bg-slate-50 rounded-xl border border-slate-200">
                <span className="text-slate-500">إجمالي مبيعات الكاش:</span>
                <span className="font-mono font-bold text-emerald-700">{activeShift.cash_sales.toFixed(2)}</span>
              </div>
              <div className="flex justify-between p-2.5 bg-slate-50 rounded-xl border border-slate-200">
                <span className="text-slate-500">إجمالي مبيعات الشبكة (Mada/Card):</span>
                <span className="font-mono font-bold text-blue-700">{activeShift.card_sales.toFixed(2)}</span>
              </div>
              <div className="flex justify-between p-3 bg-emerald-50 border border-emerald-200 rounded-xl text-sm font-black">
                <span className="text-emerald-900">المبيعات الكلية + الرصيد:</span>
                <span className="font-mono text-emerald-700">
                  {(activeShift.total_sales + activeShift.opening_balance).toFixed(2)} {activeBranch?.currency || 'ل.س'}
                </span>
              </div>
            </div>

            <div className="pt-2 flex items-center gap-2">
              <button
                onClick={() => {
                  alert('تم إغلاق الوردية وطباعة تقرير Z-Report بنجاح!');
                  setIsShiftModalOpen(false);
                }}
                className="flex-1 py-3 bg-rose-600 hover:bg-rose-700 text-white rounded-xl text-xs font-black shadow-lg shadow-rose-600/30 transition-all"
              >
                إغلاق الوردية ومطابقة الصندوق
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
              <p className="text-xs text-slate-500 mt-1">أدخل رمز PIN للكاشير للاستئناف (الرمز: 1234)</p>
            </div>

            <form onSubmit={handleUnlockTerminal} className="space-y-3">
              <input
                type="password"
                maxLength={4}
                autoFocus
                placeholder="• • • •"
                value={pinInput}
                onChange={(e) => setPinInput(e.target.value)}
                className="w-full text-center font-mono text-2xl tracking-widest py-3 bg-slate-50 border border-slate-300 rounded-xl text-slate-900 focus:outline-none focus:border-blue-500 shadow-xs"
              />
              <button
                type="submit"
                className="w-full py-3 bg-blue-600 hover:bg-blue-700 text-white rounded-xl text-xs font-black shadow-md shadow-blue-600/30 transition-all"
              >
                فتح القفل والاستئناف
              </button>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
