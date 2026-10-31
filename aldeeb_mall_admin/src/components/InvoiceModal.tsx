import React from 'react';
import { Printer, X, CheckCircle, MapPin, Phone, ShieldCheck } from 'lucide-react';
import { Order } from '../types';

interface InvoiceModalProps {
  order: Order | null;
  onClose: () => void;
}

export const InvoiceModal: React.FC<InvoiceModalProps> = ({ order, onClose }) => {
  if (!order) return null;

  const handlePrint = () => {
    window.print();
  };

  const vatAmount = (order.total_amount * 0.05).toFixed(2);

  return (
    <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl max-w-lg w-full max-h-[90vh] flex flex-col shadow-2xl overflow-hidden border border-slate-200">
        {/* Modal Top Bar */}
        <div className="p-4 bg-slate-900 text-white flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Printer className="w-5 h-5 text-blue-400" />
            <span className="font-bold text-sm">فاتورة ضريبية رسمية وبطاقة تجهيز الطلب</span>
          </div>
          <button
            onClick={onClose}
            className="p-1 hover:bg-slate-800 rounded-lg transition-colors text-slate-400 hover:text-white"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Printable Area */}
        <div id="printable-invoice" className="p-6 overflow-y-auto flex-1 font-sans text-slate-800 space-y-4">
          {/* Header */}
          <div className="text-center border-b pb-4 border-slate-200">
            <div className="text-2xl font-black text-blue-900 tracking-tight mb-1">
              الديب مول | ALDEEB MALL
            </div>
            <div className="text-xs text-slate-500 font-medium">
              هايبرماركت متكامل • توصيل فائق السرعة • الرقم الضريبي: TRN-100482910300003
            </div>
            <div className="mt-2 inline-block bg-slate-100 font-mono font-bold text-xs px-3 py-1 rounded">
              رقم الفاتورة: {order.order_number}
            </div>
          </div>

          {/* Customer & Slot Info */}
          <div className="bg-slate-50 p-3 rounded-lg border border-slate-200 text-xs space-y-1.5">
            <div className="flex justify-between">
              <span className="text-slate-500">اسم العميل:</span>
              <span className="font-bold text-slate-800">{order.customer_name}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-slate-500">الهاتف:</span>
              <span className="font-mono text-slate-700">{order.customer_phone}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-slate-500">العنوان:</span>
              <span className="font-medium text-slate-800 text-end max-w-xs">{order.customer_address}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-slate-500">موعد التسليم:</span>
              <span className="font-bold text-blue-600">{order.delivery_slot}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-slate-500">طريقة الدفع:</span>
              <span className="font-bold text-emerald-700">{order.payment_method}</span>
            </div>
          </div>

          {/* Items Table */}
          <table className="w-full text-xs text-right border-collapse">
            <thead>
              <tr className="border-b-2 border-slate-300 text-slate-600 font-bold">
                <th className="py-2">الصنف</th>
                <th className="py-2 text-center">الكمية</th>
                <th className="py-2 text-center">السعر</th>
                <th className="py-2 text-start">الإجمالي</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {order.items.map((item, idx) => (
                <tr key={idx} className="py-2">
                  <td className="py-2">
                    <div className="font-bold text-slate-800">{item.product_name_ar}</div>
                    <div className="text-[10px] text-slate-400 font-mono">{item.product_name_en}</div>
                  </td>
                  <td className="py-2 text-center font-bold">{item.quantity} {item.unit}</td>
                  <td className="py-2 text-center font-mono">{item.unit_price.toFixed(2)}</td>
                  <td className="py-2 text-start font-bold font-mono">{item.total_price.toFixed(2)} ل.س</td>
                </tr>
              ))}
            </tbody>
          </table>

          {/* Totals Breakdown */}
          <div className="border-t-2 border-slate-200 pt-3 text-xs space-y-1">
            <div className="flex justify-between text-slate-600">
              <span>المجموع الفرعي:</span>
              <span className="font-mono">{order.subtotal.toFixed(2)} ل.س</span>
            </div>
            {order.discount_amount > 0 && (
              <div className="flex justify-between text-rose-600">
                <span>خصم الكوبون الترويجي:</span>
                <span className="font-mono">-{order.discount_amount.toFixed(2)} ل.س</span>
              </div>
            )}
            {order.loyalty_discount > 0 && (
              <div className="flex justify-between text-amber-600">
                <span>خصم نقاط ولاء الديب:</span>
                <span className="font-mono">-{order.loyalty_discount.toFixed(2)} ل.س</span>
              </div>
            )}
            <div className="flex justify-between text-slate-600">
              <span>رسوم التوصيل المبرد:</span>
              <span className="font-mono">
                {order.delivery_fee === 0 ? 'مجاني (0.00)' : `${order.delivery_fee.toFixed(2)} ل.س`}
              </span>
            </div>
            <div className="flex justify-between text-slate-400 text-[11px]">
              <span>شامل ضريبة القيمة المضافة (5%):</span>
              <span className="font-mono">{vatAmount} ل.س</span>
            </div>
            <div className="flex justify-between text-sm font-black text-slate-900 border-t border-slate-300 pt-2 mt-2">
              <span>المبلغ الإجمالي النهائي:</span>
              <span className="text-blue-900 font-mono text-base">{order.total_amount.toFixed(2)} ل.س</span>
            </div>
          </div>

          {/* Barcode & Security stamp */}
          <div className="pt-3 border-t border-dashed border-slate-300 text-center space-y-1">
            <div className="font-mono tracking-widest text-lg font-bold text-slate-700">
              *{order.order_number}*
            </div>
            <p className="text-[10px] text-slate-400">
              شكراً لتسوقكم من الديب مول • سياسة الاستبدال خلال 48 ساعة • خدمة العملاء: 800-ALDEEB
            </p>
          </div>
        </div>

        {/* Modal Actions */}
        <div className="p-4 bg-slate-50 border-t border-slate-200 flex justify-end gap-3">
          <button
            onClick={onClose}
            className="px-4 py-2 border border-slate-300 text-slate-700 font-bold rounded-lg text-xs hover:bg-slate-100 transition-colors"
          >
            إغلاق
          </button>
          <button
            onClick={handlePrint}
            className="px-5 py-2 bg-blue-600 hover:bg-blue-700 text-white font-bold rounded-lg text-xs transition-colors flex items-center gap-1.5 shadow-sm"
          >
            <Printer className="w-4 h-4" />
            طباعة الفاتورة الحرارية
          </button>
        </div>
      </div>
    </div>
  );
};
