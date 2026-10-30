import React, { useState } from 'react';
import { 
  RotateCcw, 
  CheckCircle2, 
  XCircle, 
  RefreshCw, 
  Wallet, 
  Truck, 
  AlertCircle,
  Eye,
  MessageSquare
} from 'lucide-react';
import { ReturnRequest } from '../types';

export const ReturnsPage: React.FC = () => {
  const [returnRequests, setReturnRequests] = useState<ReturnRequest[]>([
    {
      id: 'ret-101',
      return_number: 'RET-2026-881',
      order_number: 'ORD-9024',
      customer_name: 'سارة بنت عبدالله',
      customer_phone: '+966 50 123 4567',
      items_summary: 'أفوكادو هاس مكسيكي (3 حبات) - نضج زائد جداً وغير صالح للاستخدام',
      reason: 'defective_fresh',
      reason_ar: 'منتج طازج غير مطابق لمعايير الجودة العالية',
      requested_at: 'قبل 12 دقيقة',
      refund_amount: 24.50,
      photo_evidence_url: 'https://images.unsplash.com/photo-1523049673857-eb18f1d7b578?w=500&auto=format&fit=crop&q=80',
      status: 'pending_review',
    },
    {
      id: 'ret-102',
      return_number: 'RET-2026-880',
      order_number: 'ORD-9018',
      customer_name: 'خالد المطيري',
      customer_phone: '+966 55 987 6543',
      items_summary: 'جبنة فيتا يونانية طبيعية - تم إرسال جبنة حلوم بدلاً منها بالخطأ',
      reason: 'wrong_item',
      reason_ar: 'عنصر خاطئ أثناء تجهيز الطلب (Packing Mismatch)',
      requested_at: 'قبل 45 دقيقة',
      refund_amount: 18.00,
      photo_evidence_url: 'https://images.unsplash.com/photo-1559561853-08451507cbe7?w=500&auto=format&fit=crop&q=80',
      status: 'pending_review',
    },
    {
      id: 'ret-103',
      return_number: 'RET-2026-879',
      order_number: 'ORD-8991',
      customer_name: 'فهد العتيبي',
      customer_phone: '+966 54 333 2211',
      items_summary: 'علبة بيض عضوي بلدي 30 بيضة - كسر في 3 بيضات أثناء نقل المندوب',
      reason: 'damaged_packaging',
      reason_ar: 'تلف جزئي بسبب النقل السريع',
      requested_at: 'قبل ساعتين',
      refund_amount: 12.00,
      photo_evidence_url: 'https://images.unsplash.com/photo-1582722872445-44dc5f7e3c8f?w=500&auto=format&fit=crop&q=80',
      status: 'approved_refunded',
    },
  ]);

  const [filter, setFilter] = useState<'all' | 'pending_review' | 'approved_refunded' | 'approved_replacement'>('all');
  const [selectedPhoto, setSelectedPhoto] = useState<string | null>(null);
  const [toastMessage, setToastMessage] = useState<string | null>(null);

  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(null), 3500);
  };

  const handleApproveWalletRefund = (req: ReturnRequest) => {
    setReturnRequests((prev) =>
      prev.map((r) => (r.id === req.id ? { ...r, status: 'approved_refunded' } : r))
    );
    showToast(`تم استرداد مبلغ ${req.refund_amount} ر.س فمع مكافأة ولاء فوراً إلى محفظة ${req.customer_name}!`);
  };

  const handleApproveReplacement = (req: ReturnRequest) => {
    setReturnRequests((prev) =>
      prev.map((r) => (r.id === req.id ? { ...r, status: 'approved_replacement' } : r))
    );
    showToast(`تم توجيه أمر استبدال فوري إلى أقرب كوريير لطلب ${req.order_number}!`);
  };

  const handleReject = (req: ReturnRequest) => {
    setReturnRequests((prev) =>
      prev.map((r) => (r.id === req.id ? { ...r, status: 'rejected' } : r))
    );
    showToast(`تم رفض طلب المرتجع ${req.return_number} وإرسال إشعار توضيحي للعميل.`);
  };

  const filteredRequests = returnRequests.filter((r) => {
    if (filter === 'all') return true;
    return r.status === filter;
  });

  return (
    <div className="space-y-6">
      {/* Toast Notification */}
      {toastMessage && (
        <div className="bg-emerald-600 text-white px-5 py-3 rounded-xl shadow-lg flex items-center gap-3 animate-fade-in text-sm font-medium">
          <CheckCircle2 className="w-5 h-5 flex-shrink-0" />
          <span>{toastMessage}</span>
        </div>
      )}

      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 bg-white p-6 rounded-2xl border border-gray-100 shadow-sm">
        <div>
          <div className="flex items-center gap-2">
            <span className="p-2 bg-rose-50 text-rose-600 rounded-xl">
              <RotateCcw className="w-6 h-6" />
            </span>
            <h1 className="text-2xl font-bold text-gray-900">إدارة المرتجعات والنزاعات الفورية (Returns & Refunds)</h1>
          </div>
          <p className="text-gray-500 mt-1 text-sm">
            معالجة طلبات الاسترجاع بضمان ذهبي 100%، واسترداد الأموال لحظياً لمحفظة العميل أو جدولة كوريير استبدال فوري
          </p>
        </div>
        <div className="flex items-center gap-2">
          <span className="px-3.5 py-1.5 bg-rose-50 text-rose-700 text-xs font-bold rounded-xl border border-rose-200">
            {returnRequests.filter(r => r.status === 'pending_review').length} بانتظار البت السريع
          </span>
        </div>
      </div>

      {/* Filter Tabs */}
      <div className="flex items-center gap-2 overflow-x-auto pb-1">
        <button
          onClick={() => setFilter('all')}
          className={`px-4 py-2 rounded-xl text-xs font-bold transition-all ${
            filter === 'all'
              ? 'bg-rose-600 text-white shadow-sm'
              : 'bg-white text-gray-600 hover:bg-gray-50 border border-gray-200'
          }`}
        >
          جميع الطلبات ({returnRequests.length})
        </button>
        <button
          onClick={() => setFilter('pending_review')}
          className={`px-4 py-2 rounded-xl text-xs font-bold transition-all ${
            filter === 'pending_review'
              ? 'bg-rose-600 text-white shadow-sm'
              : 'bg-white text-gray-600 hover:bg-gray-50 border border-gray-200'
          }`}
        >
          قيد المراجعة ({returnRequests.filter((r) => r.status === 'pending_review').length})
        </button>
        <button
          onClick={() => setFilter('approved_refunded')}
          className={`px-4 py-2 rounded-xl text-xs font-bold transition-all ${
            filter === 'approved_refunded'
              ? 'bg-rose-600 text-white shadow-sm'
              : 'bg-white text-gray-600 hover:bg-gray-50 border border-gray-200'
          }`}
        >
          مستردة للمحفظة ({returnRequests.filter((r) => r.status === 'approved_refunded').length})
        </button>
        <button
          onClick={() => setFilter('approved_replacement')}
          className={`px-4 py-2 rounded-xl text-xs font-bold transition-all ${
            filter === 'approved_replacement'
              ? 'bg-rose-600 text-white shadow-sm'
              : 'bg-white text-gray-600 hover:bg-gray-50 border border-gray-200'
          }`}
        >
          استبدال فوري ({returnRequests.filter((r) => r.status === 'approved_replacement').length})
        </button>
      </div>

      {/* Requests List */}
      <div className="space-y-4">
        {filteredRequests.map((req) => (
          <div 
            key={req.id}
            className="bg-white rounded-2xl border border-gray-100 shadow-sm p-6 hover:shadow-md transition-shadow"
          >
            <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4 pb-4 border-b border-gray-100">
              <div className="flex items-center gap-3">
                <span className="font-mono text-xs font-bold bg-gray-100 text-gray-700 px-2.5 py-1 rounded-lg">
                  {req.return_number}
                </span>
                <span className="font-bold text-gray-900">{req.customer_name}</span>
                <span className="text-xs text-gray-400 font-mono">{req.customer_phone}</span>
                <span className="text-xs text-gray-400">• لطلب: <span className="font-mono font-semibold text-gray-700">{req.order_number}</span></span>
              </div>
              <div className="flex items-center gap-3">
                <span className="text-xs text-gray-400">{req.requested_at}</span>
                <span className={`px-3 py-1 rounded-full text-xs font-bold ${
                  req.status === 'pending_review' ? 'bg-amber-50 text-amber-700 border border-amber-200' :
                  req.status === 'approved_refunded' ? 'bg-emerald-50 text-emerald-700 border border-emerald-200' :
                  req.status === 'approved_replacement' ? 'bg-blue-50 text-blue-700 border border-blue-200' :
                  'bg-rose-50 text-rose-700 border border-rose-200'
                }`}>
                  {req.status === 'pending_review' && 'بانتظار القرار'}
                  {req.status === 'approved_refunded' && 'مسترد للمحفظة'}
                  {req.status === 'approved_replacement' && 'تم توجيه الاستبدال'}
                  {req.status === 'rejected' && 'طلب مرفوض'}
                </span>
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-6 my-4">
              {/* Items & Reason */}
              <div className="md:col-span-2 space-y-2">
                <div className="text-xs text-gray-500 font-semibold">تفاصيل المنتجات المتأثرة:</div>
                <div className="font-bold text-gray-800 text-sm leading-relaxed">{req.items_summary}</div>
                <div className="flex items-center gap-2 pt-1 text-xs text-rose-600 font-medium">
                  <AlertCircle className="w-4 h-4 flex-shrink-0" />
                  <span>السبب المصرح: {req.reason_ar}</span>
                </div>
              </div>

              {/* Photo Evidence & Refund Amount */}
              <div className="flex items-center justify-between md:justify-end gap-4 bg-gray-50 p-3.5 rounded-xl border border-gray-100">
                <div className="relative group cursor-pointer" onClick={() => setSelectedPhoto(req.photo_evidence_url)}>
                  <img 
                    src={req.photo_evidence_url} 
                    alt="إثبات الحالة" 
                    className="w-16 h-16 rounded-lg object-cover border border-gray-200 shadow-sm"
                  />
                  <div className="absolute inset-0 bg-black/40 rounded-lg flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity">
                    <Eye className="w-5 h-5 text-white" />
                  </div>
                </div>
                <div className="text-left">
                  <span className="text-xs text-gray-500 block">المبلغ المستحق للاسترداد</span>
                  <span className="text-xl font-black text-rose-600">{req.refund_amount.toFixed(2)} ر.س</span>
                </div>
              </div>
            </div>

            {/* Action Buttons for Pending Review */}
            {req.status === 'pending_review' && (
              <div className="flex flex-wrap items-center justify-end gap-2.5 pt-4 border-t border-gray-100">
                <button
                  onClick={() => handleReject(req)}
                  className="px-4 py-2 rounded-xl text-xs font-bold text-gray-600 hover:bg-gray-100 border border-gray-200 transition-colors"
                >
                  رفض مع توضيح السبب
                </button>
                <button
                  onClick={() => handleApproveReplacement(req)}
                  className="flex items-center gap-1.5 px-4 py-2 rounded-xl text-xs font-bold bg-blue-50 text-blue-700 hover:bg-blue-100 border border-blue-200 transition-colors"
                >
                  <Truck className="w-4 h-4" />
                  <span>توجيه كوريير استبدال فوري</span>
                </button>
                <button
                  onClick={() => handleApproveWalletRefund(req)}
                  className="flex items-center gap-1.5 px-4 py-2 rounded-xl text-xs font-bold bg-emerald-600 text-white hover:bg-emerald-700 shadow-sm transition-all"
                >
                  <Wallet className="w-4 h-4" />
                  <span>استرداد فوري لمحفظة الديب (Aldeeb Pay)</span>
                </button>
              </div>
            )}
          </div>
        ))}
      </div>

      {/* Photo Preview Modal */}
      {selectedPhoto && (
        <div 
          className="fixed inset-0 bg-black/70 backdrop-blur-sm z-50 flex items-center justify-center p-4 animate-fade-in"
          onClick={() => setSelectedPhoto(null)}
        >
          <div className="bg-white rounded-2xl max-w-lg w-full p-4 overflow-hidden relative shadow-2xl" onClick={e => e.stopPropagation()}>
            <div className="flex items-center justify-between pb-3 mb-3 border-b border-gray-100">
              <span className="font-bold text-sm text-gray-900">صورة إثبات الحالة المرفقة من العميل</span>
              <button onClick={() => setSelectedPhoto(null)} className="p-1 rounded-lg text-gray-400 hover:text-gray-700">
                <XCircle className="w-5 h-5" />
              </button>
            </div>
            <img src={selectedPhoto} alt="صورة المرفق" className="w-full h-80 object-cover rounded-xl" />
            <div className="mt-3 text-center">
              <button 
                onClick={() => setSelectedPhoto(null)}
                className="px-5 py-2 bg-gray-100 hover:bg-gray-200 text-gray-700 rounded-xl text-xs font-bold"
              >
                إغلاق الصورة
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
