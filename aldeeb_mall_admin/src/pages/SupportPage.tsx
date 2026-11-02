import React, { useState, useEffect, useRef, useCallback } from 'react';
import { 
  Headset, 
  Send, 
  CheckCircle2, 
  Clock, 
  User, 
  Sparkles,
  Phone,
  MessageCircle,
  Search,
  Filter,
  AlertCircle,
  RefreshCw,
  Tag,
  Check,
  Radio,
  Volume2
} from 'lucide-react';
import { SupportTicket, TicketMessageItem } from '../types';
import { supabase, initialSupportTickets } from '../lib/supabase';

interface SupportPageProps {
  tickets?: SupportTicket[];
}

const STORAGE_KEY_WEB = 'aldeeb_support_tickets_v1';
const STORAGE_KEY_FLUTTER = 'flutter.aldeeb_support_tickets_v1';

// Soft, pleasant audio chime using browser Web Audio API (100% Free, Zero Assets)
const playSupportNotificationSound = () => {
  try {
    const AudioContextClass = window.AudioContext || (window as any).webkitAudioContext;
    if (!AudioContextClass) return;
    const ctx = new AudioContextClass();
    const now = ctx.currentTime;
    
    // Tone 1
    const osc1 = ctx.createOscillator();
    const gain1 = ctx.createGain();
    osc1.type = 'sine';
    osc1.frequency.setValueAtTime(587.33, now); // D5
    gain1.gain.setValueAtTime(0.12, now);
    gain1.gain.exponentialRampToValueAtTime(0.001, now + 0.25);
    osc1.connect(gain1);
    gain1.connect(ctx.destination);
    osc1.start(now);
    osc1.stop(now + 0.25);

    // Tone 2
    const osc2 = ctx.createOscillator();
    const gain2 = ctx.createGain();
    osc2.type = 'sine';
    osc2.frequency.setValueAtTime(880, now + 0.12); // A5
    gain2.gain.setValueAtTime(0.16, now + 0.12);
    gain2.gain.exponentialRampToValueAtTime(0.001, now + 0.45);
    osc2.connect(gain2);
    gain2.connect(ctx.destination);
    osc2.start(now + 0.12);
    osc2.stop(now + 0.45);
  } catch (_) {}
};

export const SupportPage: React.FC<SupportPageProps> = ({ tickets: initialPropsTickets }) => {
  const [tickets, setTickets] = useState<SupportTicket[]>(initialPropsTickets || []);
  const [selectedTicketId, setSelectedTicketId] = useState<string>('');
  const [replyText, setReplyText] = useState<string>('');
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [statusFilter, setStatusFilter] = useState<'all' | 'open' | 'in_progress' | 'resolved'>('all');
  const [isRefreshing, setIsRefreshing] = useState<boolean>(false);
  const [soundEnabled, setSoundEnabled] = useState<boolean>(true);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const lastKnownMsgCountRef = useRef<number>(0);

  // Helper to persist across web and flutter storage
  const persistTicketsLocally = useCallback((updated: SupportTicket[]) => {
    try {
      const raw = JSON.stringify(updated);
      localStorage.setItem(STORAGE_KEY_WEB, raw);
      localStorage.setItem(STORAGE_KEY_FLUTTER, raw);
      window.dispatchEvent(new Event('storage'));
    } catch (_) {}
  }, []);

  // 1. Fetch tickets from LocalStorage -> Supabase -> LAN backend API
  const fetchTickets = useCallback(async (silent = true) => {
    if (!silent) setIsRefreshing(true);
    let loaded: SupportTicket[] = [];

    // Step A: Load from browser LocalStorage (Instant cross-tab sync with Flutter web)
    try {
      const fltStr = localStorage.getItem(STORAGE_KEY_FLUTTER) || localStorage.getItem(STORAGE_KEY_WEB);
      if (fltStr) {
        const parsed = JSON.parse(fltStr);
        if (Array.isArray(parsed) && parsed.length > 0) {
          loaded = parsed.map((t: any) => ({
            id: t.id,
            ticket_number: t.ticket_number || t.ticketNumber || 'TKT-0000',
            customer_name: t.customer_name || t.customerName || 'عميل الديب مول',
            customer_phone: t.customer_phone || t.customerPhone,
            order_number: t.order_number || t.orderNumber,
            subject: t.subject || 'استفسار دعم',
            category: t.category || 'general',
            status: t.status || 'open',
            priority: t.priority || 'medium',
            created_at: t.created_at || t.createdAt || 'الآن',
            last_message: t.last_message || t.lastMessage || '',
            messages: Array.isArray(t.messages)
              ? t.messages.map((m: any) => ({
                  id: m.id,
                  sender: m.sender,
                  sender_name: m.sender_name || m.senderName,
                  text: m.text,
                  time: m.time || m.timestamp,
                  timestamp: m.timestamp || m.time,
                }))
              : [],
          }));
        }
      }
    } catch (_) {}

    // Step B: Try Supabase Database if connected
    try {
      if (supabase) {
        const { data, error } = await supabase
          .from('support_tickets')
          .select('*')
          .order('created_at', { ascending: false });

        if (!error && Array.isArray(data) && data.length > 0) {
          // Merge or adopt Supabase tickets
          const dbTickets: SupportTicket[] = data.map((t: any) => ({
            id: t.id,
            ticket_number: t.ticket_number,
            customer_name: t.customer_name,
            customer_phone: t.customer_phone,
            order_number: t.order_number,
            subject: t.subject,
            category: t.category,
            status: t.status,
            priority: t.priority,
            created_at: t.created_at,
            last_message: t.last_message,
            messages: Array.isArray(t.messages) ? t.messages : [],
          }));
          loaded = dbTickets;
        }
      }
    } catch (_) {}

    // Step C: Try LAN API fallback
    try {
      const res = await fetch('/api/support_tickets');
      if (res.ok) {
        const data = await res.json();
        if (Array.isArray(data) && data.length > 0) {
          loaded = data;
        }
      }
    } catch (_) {}

    // Step D: Default Seed fallback if empty
    if (loaded.length === 0) {
      loaded = initialPropsTickets || initialSupportTickets;
      persistTicketsLocally(loaded);
    }

    // Step E: Sound notification for incoming customer message
    const totalMsgs = loaded.reduce((acc, t) => acc + (t.messages?.length || 1), 0);
    if (lastKnownMsgCountRef.current > 0 && totalMsgs > lastKnownMsgCountRef.current) {
      if (soundEnabled) {
        playSupportNotificationSound();
      }
    }
    lastKnownMsgCountRef.current = totalMsgs;

    setTickets(loaded);
    if (!silent) setTimeout(() => setIsRefreshing(false), 400);
  }, [initialPropsTickets, persistTicketsLocally, soundEnabled]);

  // Initial load and periodic polling every 2.5 seconds (Instant free realtime)
  useEffect(() => {
    fetchTickets(false);
    const interval = setInterval(() => fetchTickets(true), 2500);

    const handleStorageEvent = (e: StorageEvent) => {
      if (e.key === STORAGE_KEY_FLUTTER || e.key === STORAGE_KEY_WEB || !e.key) {
        fetchTickets(true);
      }
    };
    window.addEventListener('storage', handleStorageEvent);

    return () => {
      clearInterval(interval);
      window.removeEventListener('storage', handleStorageEvent);
    };
  }, [fetchTickets]);

  useEffect(() => {
    if (!selectedTicketId && tickets.length > 0) {
      setSelectedTicketId(tickets[0].id);
    }
  }, [tickets, selectedTicketId]);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [tickets, selectedTicketId]);

  const selectedTicket = tickets.find((t) => t.id === selectedTicketId) || tickets[0];

  // Filtered tickets
  const filteredTickets = tickets.filter((t) => {
    const matchesStatus = statusFilter === 'all' || t.status === statusFilter;
    const matchesSearch = 
      t.customer_name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      t.ticket_number.toLowerCase().includes(searchQuery.toLowerCase()) ||
      (t.order_number && t.order_number.toLowerCase().includes(searchQuery.toLowerCase())) ||
      t.subject.toLowerCase().includes(searchQuery.toLowerCase());
    return matchesStatus && matchesSearch;
  });

  // 2. Send reply & sync to localStorage, Supabase, and API
  const handleSendReply = async (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    if (!replyText.trim() || !selectedTicket) return;

    const newMsg: TicketMessageItem = {
      id: `m-${Date.now()}`,
      sender: 'agent',
      sender_name: 'فريق خدمة العملاء',
      text: replyText.trim(),
      time: new Date().toLocaleTimeString('ar-EG', { hour: '2-digit', minute: '2-digit' }),
      timestamp: new Date().toLocaleTimeString('ar-EG', { hour: '2-digit', minute: '2-digit' })
    };

    const currentMessages = selectedTicket.messages || [];
    const updatedMessages = [...currentMessages, newMsg];

    const updatedTicket: SupportTicket = {
      ...selectedTicket,
      last_message: newMsg.text,
      status: selectedTicket.status === 'open' ? 'in_progress' : selectedTicket.status,
      messages: updatedMessages
    };

    // Update state immediately
    const updatedTickets = tickets.map((t) => t.id === updatedTicket.id ? updatedTicket : t);
    setTickets(updatedTickets);
    setReplyText('');
    persistTicketsLocally(updatedTickets);

    // Push to Supabase if connected
    try {
      if (supabase) {
        await supabase.from('support_tickets').upsert(updatedTicket);
      }
    } catch (_) {}

    // Push to LAN API
    try {
      await fetch('/api/support_tickets', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(updatedTicket)
      });
    } catch (_) {}
  };

  // 3. Update Status
  const handleStatusChange = async (newStatus: 'open' | 'in_progress' | 'resolved') => {
    if (!selectedTicket) return;

    const statusNote: TicketMessageItem = {
      id: `sys-${Date.now()}`,
      sender: 'system',
      sender_name: 'النظام',
      text: newStatus === 'resolved' 
        ? 'تم تغيير حالة التذكرة إلى: مغلقة / تم الحل بنجاح.'
        : newStatus === 'in_progress'
        ? 'تم استلام التذكرة من قِبل ممثل الدعم للمتابعة الفورية.'
        : 'تمت إعادة فتح التذكرة.',
      time: new Date().toLocaleTimeString('ar-EG', { hour: '2-digit', minute: '2-digit' }),
      timestamp: new Date().toLocaleTimeString('ar-EG', { hour: '2-digit', minute: '2-digit' })
    };

    const updatedTicket: SupportTicket = {
      ...selectedTicket,
      status: newStatus,
      messages: [...(selectedTicket.messages || []), statusNote]
    };

    const updatedTickets = tickets.map((t) => t.id === updatedTicket.id ? updatedTicket : t);
    setTickets(updatedTickets);
    persistTicketsLocally(updatedTickets);

    try {
      if (supabase) {
        await supabase.from('support_tickets').upsert(updatedTicket);
      }
      await fetch('/api/support_tickets', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(updatedTicket)
      });
    } catch (_) {}
  };

  // 4. Quick Canned Macros
  const handleQuickReply = (text: string) => {
    setReplyText(text);
  };

  // 5. Open WhatsApp direct chat
  const handleWhatsAppCustomer = () => {
    if (!selectedTicket) return;
    const phone = selectedTicket.customer_phone || '+971501234567';
    const cleanPhone = phone.replace(/[^\d]/g, '');
    const msg = encodeURIComponent(
      `مرحباً ${selectedTicket.customer_name}، نتواصل معك من خدمة عملاء الديب مول بخصوص التذكرة رقم (${selectedTicket.ticket_number}).`
    );
    window.open(`https://wa.me/${cleanPhone}?text=${msg}`, '_blank');
  };

  return (
    <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 h-[calc(100vh-140px)]">
      {/* Tickets List (1/3) */}
      <div className="bg-white rounded-2xl border border-slate-200 shadow-sm flex flex-col overflow-hidden">
        {/* Header */}
        <div className="p-4 border-b border-slate-200 space-y-3">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 rounded-lg bg-blue-100 flex items-center justify-center text-blue-600">
                <Headset className="w-4 h-4" />
              </div>
              <div>
                <div className="flex items-center gap-1.5">
                  <h3 className="font-bold text-slate-800 text-sm">مكتب خدمة العملاء الحي</h3>
                  <span className="inline-flex items-center gap-1 px-1.5 py-0.5 rounded-full text-[10px] font-bold bg-emerald-100 text-emerald-800">
                    <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse"></span>
                    مباشر
                  </span>
                </div>
                <span className="text-[11px] text-slate-400">مزامنة لحظية مجانية مع تطبيق المتجر</span>
              </div>
            </div>
            <div className="flex items-center gap-1">
              <button
                onClick={() => setSoundEnabled(!soundEnabled)}
                className={`p-1.5 rounded-lg text-xs transition-all ${
                  soundEnabled ? 'text-blue-600 bg-blue-50' : 'text-slate-400 hover:bg-slate-100'
                }`}
                title={soundEnabled ? 'التنبيهات الصوتية مفعلة' : 'التنبيهات الصوتية معطلة'}
              >
                <Volume2 className="w-4 h-4" />
              </button>
              <button
                onClick={() => fetchTickets(false)}
                className={`p-1.5 rounded-lg text-slate-500 hover:bg-slate-100 transition-all ${isRefreshing ? 'animate-spin' : ''}`}
                title="تحديث القائمة"
              >
                <RefreshCw className="w-4 h-4" />
              </button>
            </div>
          </div>

          {/* Search bar */}
          <div className="relative">
            <Search className="w-3.5 h-3.5 absolute right-3 top-2.5 text-slate-400" />
            <input
              type="text"
              placeholder="بحث بالاسم، رقم التذكرة، أو الطلب..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pr-8 pl-3 py-1.5 bg-slate-50 border border-slate-200 rounded-xl text-xs focus:ring-2 focus:ring-blue-600 focus:bg-white transition-all"
            />
          </div>

          {/* Status Filters */}
          <div className="flex gap-1 overflow-x-auto pb-1 text-xs">
            {[
              { id: 'all', label: 'الكل', count: tickets.length },
              { id: 'open', label: 'جديدة', count: tickets.filter((t) => t.status === 'open').length },
              { id: 'in_progress', label: 'قيد المتابعة', count: tickets.filter((t) => t.status === 'in_progress').length },
              { id: 'resolved', label: 'مغلقة', count: tickets.filter((t) => t.status === 'resolved').length },
            ].map((tab) => (
              <button
                key={tab.id}
                onClick={() => setStatusFilter(tab.id as any)}
                className={`px-2.5 py-1 rounded-lg font-bold text-[11px] transition-colors flex items-center gap-1.5 whitespace-nowrap ${
                  statusFilter === tab.id
                    ? 'bg-blue-600 text-white'
                    : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
                }`}
              >
                <span>{tab.label}</span>
                <span className={`text-[10px] px-1 rounded-full ${statusFilter === tab.id ? 'bg-blue-800' : 'bg-slate-200'}`}>
                  {tab.count}
                </span>
              </button>
            ))}
          </div>
        </div>

        {/* Tickets Scroll List */}
        <div className="overflow-y-auto flex-1 divide-y divide-slate-100">
          {filteredTickets.length === 0 ? (
            <div className="p-8 text-center text-slate-400 text-xs">
              لا توجد تذاكر مطابقة للبحث أو الفلتر
            </div>
          ) : (
            filteredTickets.map((tkt) => {
              const isSelected = tkt.id === selectedTicket?.id;
              return (
                <div
                  key={tkt.id}
                  onClick={() => setSelectedTicketId(tkt.id)}
                  className={`p-4 cursor-pointer transition-all ${
                    isSelected ? 'bg-blue-50/70 border-r-4 border-blue-600 shadow-xs' : 'hover:bg-slate-50'
                  }`}
                >
                  <div className="flex items-center justify-between text-xs mb-1">
                    <span className="font-bold text-slate-800">{tkt.customer_name}</span>
                    <span className="text-slate-400 font-medium text-[10px]">{tkt.created_at}</span>
                  </div>
                  <h4 className="text-xs font-bold text-slate-700 line-clamp-1 mb-1">
                    {tkt.subject}
                  </h4>
                  <p className="text-[11px] text-slate-500 line-clamp-1 mb-2">
                    {tkt.last_message}
                  </p>
                  <div className="flex items-center justify-between text-[10px]">
                    <span className="font-mono text-blue-600 font-bold">{tkt.ticket_number}</span>
                    {tkt.order_number && (
                      <span className="font-mono text-amber-700 bg-amber-50 border border-amber-200 px-1.5 py-0.5 rounded font-bold">
                        #{tkt.order_number}
                      </span>
                    )}
                    <span
                      className={`font-bold px-2 py-0.5 rounded-full ${
                        tkt.status === 'open'
                          ? 'bg-rose-100 text-rose-800'
                          : tkt.status === 'in_progress'
                          ? 'bg-blue-100 text-blue-800'
                          : 'bg-emerald-100 text-emerald-800'
                      }`}
                    >
                      {tkt.status === 'open' ? 'جديد' : tkt.status === 'in_progress' ? 'قيد المتابعة' : 'مغلق'}
                    </span>
                  </div>
                </div>
              );
            })
          )}
        </div>
      </div>

      {/* Live Chat Console (2/3) */}
      <div className="lg:col-span-2 bg-white rounded-2xl border border-slate-200 shadow-sm flex flex-col overflow-hidden">
        {selectedTicket ? (
          <>
            {/* Chat Header */}
            <div className="p-4 border-b border-slate-200 flex flex-wrap items-center justify-between gap-3 bg-slate-50">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-full bg-blue-100 flex items-center justify-center font-bold text-blue-700 text-sm">
                  <User className="w-5 h-5 text-blue-600" />
                </div>
                <div>
                  <h4 className="font-bold text-slate-800 text-sm flex items-center gap-2">
                    <span>{selectedTicket.customer_name}</span>
                    <span className="text-[10px] font-normal font-mono bg-slate-200 px-1.5 py-0.5 rounded text-slate-700">
                      {selectedTicket.ticket_number}
                    </span>
                  </h4>
                  <p className="text-xs text-slate-500 flex items-center gap-2 mt-0.5">
                    {selectedTicket.order_number && (
                      <span className="text-amber-700 font-bold font-mono">
                        طلب مرتبط: #{selectedTicket.order_number}
                      </span>
                    )}
                    {selectedTicket.customer_phone && (
                      <span className="text-slate-400 font-mono">
                        • {selectedTicket.customer_phone}
                      </span>
                    )}
                  </p>
                </div>
              </div>

              {/* Action Buttons: WhatsApp, Call, Status Changer */}
              <div className="flex items-center gap-2">
                {/* WhatsApp Button */}
                <button
                  onClick={handleWhatsAppCustomer}
                  className="px-2.5 py-1.5 bg-emerald-50 text-emerald-700 border border-emerald-200 rounded-lg text-xs font-bold hover:bg-emerald-100 transition-colors flex items-center gap-1"
                  title="محادثة واتساب مباشرة"
                >
                  <MessageCircle className="w-3.5 h-3.5" />
                  <span>واتساب</span>
                </button>

                {/* Call Button */}
                <a
                  href={`tel:${selectedTicket.customer_phone || '+971501234567'}`}
                  className="px-2.5 py-1.5 bg-blue-50 text-blue-700 border border-blue-200 rounded-lg text-xs font-bold hover:bg-blue-100 transition-colors flex items-center gap-1"
                  title="اتصال هاتفي"
                >
                  <Phone className="w-3.5 h-3.5" />
                  <span>اتصال</span>
                </a>

                {/* Status Toggle Button */}
                {selectedTicket.status !== 'resolved' ? (
                  <button
                    onClick={() => handleStatusChange('resolved')}
                    className="px-3 py-1.5 bg-emerald-600 text-white rounded-lg text-xs font-bold hover:bg-emerald-700 transition-colors flex items-center gap-1 shadow-xs"
                  >
                    <CheckCircle2 className="w-3.5 h-3.5" />
                    <span>إغلاق التذكرة</span>
                  </button>
                ) : (
                  <button
                    onClick={() => handleStatusChange('in_progress')}
                    className="px-3 py-1.5 bg-amber-100 text-amber-800 rounded-lg text-xs font-bold hover:bg-amber-200 transition-colors flex items-center gap-1"
                  >
                    <Clock className="w-3.5 h-3.5" />
                    <span>إعادة فتح</span>
                  </button>
                )}
              </div>
            </div>

            {/* Subject Banner */}
            <div className="px-5 py-2.5 bg-blue-50/60 border-b border-blue-100 flex items-center justify-between text-xs">
              <span className="font-bold text-blue-900 flex items-center gap-1.5">
                <Tag className="w-3.5 h-3.5 text-blue-600" />
                الموضوع: {selectedTicket.subject}
              </span>
              <span className="text-[11px] text-blue-700 font-medium">
                الأولوية: {selectedTicket.priority === 'high' ? '🚨 عاجلة' : selectedTicket.priority === 'medium' ? 'متوسطة' : 'عادية'}
              </span>
            </div>

            {/* Message Stream */}
            <div className="flex-1 p-5 overflow-y-auto space-y-4 bg-slate-50/40">
              {(selectedTicket.messages && selectedTicket.messages.length > 0) ? (
                selectedTicket.messages.map((msg, idx) => {
                  if (msg.sender === 'system') {
                    return (
                      <div key={idx} className="flex justify-center my-2">
                        <span className="text-[10px] bg-slate-200 text-slate-600 px-3 py-1 rounded-full font-medium">
                          {msg.text}
                        </span>
                      </div>
                    );
                  }

                  const isAgent = msg.sender === 'agent' || msg.sender === 'bot';
                  return (
                    <div
                      key={idx}
                      className={`flex flex-col ${isAgent ? 'items-end' : 'items-start'}`}
                    >
                      <div className="flex items-center gap-1 mb-1 px-1">
                        <span className="text-[10px] font-bold text-slate-600">
                          {msg.sender_name || (isAgent ? 'فريق خدمة العملاء' : selectedTicket.customer_name)}
                        </span>
                      </div>
                      <div
                        className={`max-w-md p-3.5 rounded-2xl text-xs leading-relaxed ${
                          isAgent
                            ? 'bg-blue-600 text-white rounded-tr-none shadow-sm'
                            : 'bg-white text-slate-800 border border-slate-200 rounded-tl-none shadow-xs'
                        }`}
                      >
                        {msg.text}
                      </div>
                      <span className="text-[10px] text-slate-400 mt-1 px-1">
                        {msg.time || msg.timestamp || 'الآن'}
                      </span>
                    </div>
                  );
                })
              ) : (
                <div className="flex flex-col items-start">
                  <div className="max-w-md p-3.5 rounded-2xl text-xs leading-relaxed bg-white text-slate-800 border border-slate-200 rounded-tl-none shadow-xs">
                    {selectedTicket.last_message}
                  </div>
                  <span className="text-[10px] text-slate-400 mt-1 px-1">{selectedTicket.created_at}</span>
                </div>
              )}
              <div ref={messagesEndRef} />
            </div>

            {/* Quick Canned Macros */}
            <div className="px-4 py-2 bg-white border-t border-slate-100 flex gap-2 overflow-x-auto text-[11px]">
              <span className="text-slate-400 font-bold flex items-center gap-1 shrink-0">
                <Sparkles className="w-3.5 h-3.5 text-amber-500" />
                ردود سريعة:
              </span>
              {[
                'طلبك مع الكابتن وفي الطريق ويصلك خلال دقائق!',
                'تم فحص الشحنة وتغليفها بأعلى معايير السلسلة الباردة.',
                'تم تعويضك بكوبون خصم 20% على طلبك القادم واعتذارنا الشديد.',
                'تم تحويل استفسارك لمشرف الجودة وسيتم التواصل معك هاتفياً.',
              ].map((macro, idx) => (
                <button
                  key={idx}
                  onClick={() => handleQuickReply(macro)}
                  className="px-2.5 py-1 bg-slate-100 hover:bg-blue-50 hover:text-blue-700 text-slate-600 rounded-lg whitespace-nowrap transition-colors"
                >
                  {macro}
                </button>
              ))}
            </div>

            {/* Reply Input Bar */}
            <form onSubmit={handleSendReply} className="p-3 bg-white border-t border-slate-200 flex gap-2">
              <input
                type="text"
                placeholder="اكتب ردك للعميل هنا..."
                value={replyText}
                onChange={(e) => setReplyText(e.target.value)}
                className="flex-1 px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs focus:ring-2 focus:ring-blue-600 focus:bg-white transition-all"
              />
              <button
                type="submit"
                disabled={!replyText.trim()}
                className="px-5 py-2.5 bg-blue-600 hover:bg-blue-700 disabled:opacity-50 text-white rounded-xl text-xs font-bold transition-colors flex items-center gap-1.5 shadow-sm"
              >
                <Send className="w-3.5 h-3.5" />
                <span>إرسال الرد</span>
              </button>
            </form>
          </>
        ) : (
          <div className="h-full flex items-center justify-center text-slate-400 text-xs">
            اختر تذكرة من القائمة لعرض المحادثة والمتابعة
          </div>
        )}
      </div>
    </div>
  );
};
