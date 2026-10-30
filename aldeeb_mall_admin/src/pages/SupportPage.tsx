import React, { useState } from 'react';
import { 
  Headset, 
  MessageSquare, 
  Send, 
  CheckCircle2, 
  Clock, 
  User, 
  Sparkles,
  ShoppingBag
} from 'lucide-react';
import { SupportTicket } from '../types';

interface SupportPageProps {
  tickets: SupportTicket[];
}

export const SupportPage: React.FC<SupportPageProps> = ({ tickets: initialTickets }) => {
  const [tickets, setTickets] = useState<SupportTicket[]>(initialTickets);
  const [selectedTicketId, setSelectedTicketId] = useState<string>(tickets[0]?.id || '');
  const [replyText, setReplyText] = useState<string>('');
  const [conversation, setConversation] = useState<{ sender: 'customer' | 'agent'; text: string; time: string }[]>([
    { sender: 'customer', text: 'مرحباً، هل يمكن إضافة صنف إضافي لطلبي قبل خروج المندوب؟', time: '10:42 ص' },
    { sender: 'agent', text: 'أهلاً بك عميلنا العزيز فاطمة! تم التحقق وطلبك لا يزال في مرحلة التجهيز في المستودع المظلم.', time: '10:44 ص' },
  ]);

  const selectedTicket = tickets.find((t) => t.id === selectedTicketId) || tickets[0];

  const handleSendReply = (e: React.FormEvent) => {
    e.preventDefault();
    if (!replyText.trim()) return;

    setConversation((prev) => [
      ...prev,
      { sender: 'agent', text: replyText, time: 'الآن' },
    ]);
    setReplyText('');
  };

  const handleQuickReply = (text: string) => {
    setReplyText(text);
  };

  return (
    <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 h-[calc(100vh-160px)]">
      {/* Tickets List (1/3) */}
      <div className="bg-white rounded-2xl border border-slate-200 shadow-sm flex flex-col overflow-hidden">
        <div className="p-4 border-b border-slate-200 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Headset className="w-5 h-5 text-blue-600" />
            <h3 className="font-bold text-slate-800 text-sm">مكتب خدمة العملاء الحي</h3>
          </div>
          <span className="text-xs bg-blue-50 text-blue-700 px-2.5 py-0.5 rounded-full font-bold">
            {tickets.filter((t) => t.status !== 'resolved').length} نشطة
          </span>
        </div>

        <div className="overflow-y-auto flex-1 divide-y divide-slate-100">
          {tickets.map((tkt) => {
            const isSelected = tkt.id === selectedTicket?.id;
            return (
              <div
                key={tkt.id}
                onClick={() => setSelectedTicketId(tkt.id)}
                className={`p-4 cursor-pointer transition-all ${
                  isSelected ? 'bg-blue-50/70 border-r-4 border-blue-600' : 'hover:bg-slate-50'
                }`}
              >
                <div className="flex items-center justify-between text-xs mb-1">
                  <span className="font-bold text-slate-800">{tkt.customer_name}</span>
                  <span className="text-slate-400 font-medium">{tkt.created_at}</span>
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
                    <span className="font-mono text-slate-400 bg-slate-100 px-1.5 py-0.5 rounded">
                      {tkt.order_number}
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
          })}
        </div>
      </div>

      {/* Live Chat Console (2/3) */}
      <div className="lg:col-span-2 bg-white rounded-2xl border border-slate-200 shadow-sm flex flex-col overflow-hidden">
        {/* Chat Header */}
        <div className="p-4 border-b border-slate-200 flex items-center justify-between bg-slate-50">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-blue-100 flex items-center justify-center font-bold text-blue-700 text-sm">
              <User className="w-5 h-5 text-blue-600" />
            </div>
            <div>
              <h4 className="font-bold text-slate-800 text-sm">{selectedTicket?.customer_name}</h4>
              <p className="text-xs text-slate-500 flex items-center gap-2">
                <span>تذكرة: {selectedTicket?.ticket_number}</span>
                {selectedTicket?.order_number && (
                  <span className="text-blue-600 font-bold font-mono">
                    • الطلب المرتبط: #{selectedTicket.order_number}
                  </span>
                )}
              </p>
            </div>
          </div>

          <div className="flex items-center gap-2">
            <button className="px-3 py-1 bg-emerald-100 text-emerald-800 rounded-lg text-xs font-bold hover:bg-emerald-200 transition-colors flex items-center gap-1">
              <CheckCircle2 className="w-3.5 h-3.5" />
              إغلاق التذكرة
            </button>
          </div>
        </div>

        {/* Message Stream */}
        <div className="flex-1 p-5 overflow-y-auto space-y-4 bg-slate-50/40">
          {conversation.map((msg, idx) => (
            <div
              key={idx}
              className={`flex flex-col ${msg.sender === 'agent' ? 'items-start' : 'items-end'}`}
            >
              <div
                className={`max-w-md p-3.5 rounded-2xl text-xs leading-relaxed ${
                  msg.sender === 'agent'
                    ? 'bg-blue-600 text-white rounded-tr-none shadow-sm'
                    : 'bg-white text-slate-800 border border-slate-200 rounded-tl-none shadow-xs'
                }`}
              >
                {msg.text}
              </div>
              <span className="text-[10px] text-slate-400 mt-1 px-1">{msg.time}</span>
            </div>
          ))}
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
            'تم تعويضك بكوبون خصم 20% على طلبك القادم.',
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
            className="flex-1 px-4 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs focus:ring-2 focus:ring-blue-600 focus:bg-white"
          />
          <button
            type="submit"
            className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-xl text-xs font-bold transition-colors flex items-center gap-1.5 shadow-sm"
          >
            <Send className="w-3.5 h-3.5" />
            إرسال
          </button>
        </form>
      </div>
    </div>
  );
};
