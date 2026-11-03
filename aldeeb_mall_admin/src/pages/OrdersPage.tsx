import React, { useState } from 'react';
import { 
  Search, 
  Eye, 
  Printer, 
  MapPin, 
  Phone, 
  X,
  PackageCheck,
  Receipt
} from 'lucide-react';
import { Order } from '../types';
import { InvoiceModal } from '../components/InvoiceModal';

interface OrdersPageProps {
  orders: Order[];
  onUpdateOrderStatus: (orderId: string, status: Order['status']) => void;
}

export const OrdersPage: React.FC<OrdersPageProps> = ({ orders, onUpdateOrderStatus }) => {
  const [filterStatus, setFilterStatus] = useState<string>('all');
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [selectedOrder, setSelectedOrder] = useState<Order | null>(null);
  const [invoiceOrder, setInvoiceOrder] = useState<Order | null>(null);

  const filteredOrders = orders.filter((o) => {
    const matchesStatus = filterStatus === 'all' || o.status === filterStatus;
    const matchesSearch = 
      o.order_number.toLowerCase().includes(searchQuery.toLowerCase()) ||
      o.customer_name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      o.customer_phone.includes(searchQuery);
    return matchesStatus && matchesSearch;
  });

  const getStatusBadge = (status: Order['status']) => {
    switch (status) {
      case 'pending':
        return <span className="px-2.5 py-1 bg-blue-100 text-blue-800 rounded-lg text-xs font-bold">جديد (قيد المراجعة)</span>;
      case 'packing':
        return <span className="px-2.5 py-1 bg-amber-100 text-amber-800 rounded-lg text-xs font-bold">جاري الفرز والتجهيز</span>;
      case 'out_for_delivery':
        return <span className="px-2.5 py-1 bg-purple-100 text-purple-800 rounded-lg text-xs font-bold">مع مندوب التوصيل</span>;
      case 'delivered':
        return <span className="px-2.5 py-1 bg-emerald-100 text-emerald-800 rounded-lg text-xs font-bold">تم التسليم بنجاح</span>;
      case 'cancelled':
        return <span className="px-2.5 py-1 bg-rose-100 text-rose-800 rounded-lg text-xs font-bold">ملغي</span>;
    }
  };

  return (
    <div className="space-y-6">
      {/* Controls Bar: Filters & Search */}
      <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-sm flex flex-col md:flex-row items-stretch md:items-center justify-between gap-4">
        {/* Status Filters */}
        <div className="flex items-center gap-2 overflow-x-auto pb-1 md:pb-0 w-full md:w-auto scrollbar-thin">
          {[
            { id: 'all', label: 'كافة الطلبات' },
            { id: 'pending', label: 'الجديدة (قيد المراجعة)' },
            { id: 'packing', label: 'قيد التجهيز بالمستودع' },
            { id: 'out_for_delivery', label: 'مع المندوب' },
            { id: 'delivered', label: 'تم التسليم' },
            { id: 'cancelled', label: 'الملغاة' },
          ].map((tab) => (
            <button
              key={tab.id}
              onClick={() => setFilterStatus(tab.id)}
              className={`px-3.5 py-2 rounded-xl text-xs font-bold transition-all whitespace-nowrap shrink-0 ${
                filterStatus === tab.id
                  ? 'bg-blue-600 text-white shadow-md shadow-blue-600/30'
                  : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
              }`}
            >
              {tab.label}
            </button>
          ))}
        </div>

        {/* Search */}
        <div className="relative w-full md:w-80 shrink-0">
          <input
            type="text"
            placeholder="بحث برقم الطلب، اسم العميل، الهاتف..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pr-10 pl-4 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-medium focus:outline-none focus:border-blue-600 focus:bg-white transition-all"
          />
          <Search className="w-4 h-4 text-slate-400 absolute right-3.5 top-2.5" />
        </div>
      </div>

      {/* Orders Table */}
      <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-right border-collapse">
            <thead className="bg-slate-50/80 border-b border-slate-200 text-slate-500 text-xs font-extrabold whitespace-nowrap">
              <tr>
                <th className="p-4 min-w-[140px]">رقم الطلب</th>
                <th className="p-4 min-w-[200px]">العميل والموقع</th>
                <th className="p-4 min-w-[130px]">موعد التوصيل</th>
                <th className="p-4 min-w-[110px]">طريقة الدفع</th>
                <th className="p-4 min-w-[130px]">المبلغ الإجمالي</th>
                <th className="p-4 min-w-[140px]">حالة الطلب</th>
                <th className="p-4 min-w-[170px] text-center">الإجراءات والترحيل</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 text-xs">
              {filteredOrders.length === 0 ? (
                <tr>
                  <td colSpan={7} className="p-8 text-center text-slate-400 font-semibold">
                    لا توجد طلبات مطابقة للبحث أو التصفية الحالية
                  </td>
                </tr>
              ) : (
                filteredOrders.map((order) => (
                  <tr key={order.id} className="hover:bg-slate-50/60 transition-colors">
                    <td className="p-4 font-mono font-extrabold text-blue-600 whitespace-nowrap">
                      {order.order_number}
                      <span className="block text-[10px] text-slate-400 font-normal">{order.created_at}</span>
                    </td>
                    <td className="p-4 min-w-[200px]">
                      <p className="font-extrabold text-slate-800">{order.customer_name}</p>
                      <p className="text-slate-500 flex items-center gap-1 text-[11px] mt-0.5">
                        <MapPin className="w-3 h-3 text-slate-400 shrink-0" />
                        <span className="truncate max-w-[220px]" title={order.customer_address}>
                          {order.customer_address}
                        </span>
                      </p>
                    </td>
                    <td className="p-4 font-semibold text-slate-600 whitespace-nowrap">{order.delivery_slot}</td>
                    <td className="p-4 whitespace-nowrap">
                      <span className="font-bold text-slate-700">{order.payment_method}</span>
                    </td>
                    <td className="p-4 font-extrabold text-blue-900 whitespace-nowrap">
                      {order.total_amount.toFixed(2)} ل.س
                      {order.loyalty_discount > 0 && (
                        <p className="text-[10px] text-emerald-600 font-bold">
                          وفر {order.loyalty_discount.toFixed(2)} ل.س بالنقاط
                        </p>
                      )}
                    </td>
                    <td className="p-4 whitespace-nowrap">{getStatusBadge(order.status)}</td>
                    <td className="p-4 whitespace-nowrap">
                      <div className="flex items-center justify-center gap-2">
                        <button
                          onClick={() => setSelectedOrder(order)}
                          className="p-2 text-slate-600 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors border border-slate-200"
                          title="عرض تفاصيل الطلب والفرز"
                        >
                          <Eye className="w-4 h-4" />
                        </button>
                        <button
                          onClick={() => setInvoiceOrder(order)}
                          className="p-2 text-slate-600 hover:text-emerald-600 hover:bg-emerald-50 rounded-lg transition-colors border border-slate-200"
                          title="طباعة فاتورة ضريبية رسمية"
                        >
                          <Receipt className="w-4 h-4 text-emerald-600" />
                        </button>
                        {order.status === 'pending' && (
                          <button
                            onClick={() => onUpdateOrderStatus(order.id, 'packing')}
                            className="px-2.5 py-1.5 bg-blue-600 hover:bg-blue-700 text-white rounded-lg text-xs font-bold transition-colors shadow-xs"
                          >
                            تجهيز
                          </button>
                        )}
                        {order.status === 'packing' && (
                          <button
                            onClick={() => onUpdateOrderStatus(order.id, 'out_for_delivery')}
                            className="px-2.5 py-1.5 bg-amber-500 hover:bg-amber-600 text-white rounded-lg text-xs font-bold transition-colors shadow-xs"
                          >
                            إرسال للسائق
                          </button>
                        )}
                        {order.status === 'out_for_delivery' && (
                          <button
                            onClick={() => onUpdateOrderStatus(order.id, 'delivered')}
                            className="px-2.5 py-1.5 bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg text-xs font-bold transition-colors shadow-xs"
                          >
                            تم التسليم
                          </button>
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

      {/* Order Details & Picking Sheet Modal */}
      {selectedOrder && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl max-w-2xl w-full p-6 shadow-2xl max-h-[90vh] overflow-y-auto space-y-6">
            {/* Modal Header */}
            <div className="flex items-center justify-between border-b pb-4 border-slate-100">
              <div>
                <h3 className="text-lg font-black text-slate-900 flex items-center gap-2">
                  تفاصيل الطلب: <span className="font-mono text-blue-600">{selectedOrder.order_number}</span>
                </h3>
                <p className="text-xs text-slate-400 mt-0.5">تاريخ ووقت الإنشاء: {selectedOrder.created_at}</p>
              </div>
              <button
                onClick={() => setSelectedOrder(null)}
                className="p-2 hover:bg-slate-100 rounded-xl text-slate-400 hover:text-slate-600 transition-colors"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Customer & Address Details */}
            <div className="grid grid-cols-2 gap-4 bg-slate-50 p-4 rounded-2xl border border-slate-200/60">
              <div>
                <p className="text-xs text-slate-400 font-bold">بيانات العميل</p>
                <p className="text-sm font-extrabold text-slate-800 mt-1">{selectedOrder.customer_name}</p>
                <p className="text-xs text-slate-600 flex items-center gap-1 mt-0.5">
                  <Phone className="w-3.5 h-3.5 text-blue-600" />
                  {selectedOrder.customer_phone}
                </p>
              </div>
              <div>
                <p className="text-xs text-slate-400 font-bold">عنوان التوصيل المختار</p>
                <p className="text-xs font-medium text-slate-700 mt-1 flex items-start gap-1">
                  <MapPin className="w-3.5 h-3.5 text-blue-600 shrink-0 mt-0.5" />
                  {selectedOrder.customer_address}
                </p>
              </div>
            </div>

            {/* Items to Pick */}
            <div>
              <h4 className="text-sm font-extrabold text-slate-900 mb-3 flex items-center gap-2">
                <PackageCheck className="w-4 h-4 text-blue-600" />
                قائمة الأصناف لفرز وتجهيز الطلب ({selectedOrder.items.length})
              </h4>
              <div className="border border-slate-200 rounded-xl overflow-hidden divide-y divide-slate-100">
                {selectedOrder.items.map((item) => (
                  <div key={item.id} className="p-3 flex items-center justify-between bg-white">
                    <div>
                      <p className="text-xs font-bold text-slate-800">{item.product_name_ar}</p>
                      <p className="text-[11px] text-slate-400">
                        {item.quantity} {item.unit} × {item.unit_price.toFixed(2)} ل.س
                      </p>
                    </div>
                    <span className="text-xs font-extrabold text-blue-900">
                      {item.total_price.toFixed(2)} ل.س
                    </span>
                  </div>
                ))}
              </div>
            </div>

            {/* Bill Summary */}
            <div className="space-y-2 bg-slate-50 p-4 rounded-xl border border-slate-200/80 text-xs">
              <div className="flex justify-between text-slate-600">
                <span>المجموع الفرعي:</span>
                <span>{selectedOrder.subtotal.toFixed(2)} ل.س</span>
              </div>
              <div className="flex justify-between text-slate-600">
                <span>رسوم التوصيل:</span>
                <span>{selectedOrder.delivery_fee === 0 ? 'مجاناً' : `${selectedOrder.delivery_fee.toFixed(2)} ل.س`}</span>
              </div>
              {selectedOrder.discount_amount > 0 && (
                <div className="flex justify-between text-rose-600 font-bold">
                  <span>خصم الكوبون:</span>
                  <span>-{selectedOrder.discount_amount.toFixed(2)} ل.س</span>
                </div>
              )}
              {selectedOrder.loyalty_discount > 0 && (
                <div className="flex justify-between text-emerald-600 font-bold">
                  <span>خصم نقاط الولاء:</span>
                  <span>-{selectedOrder.loyalty_discount.toFixed(2)} ل.س</span>
                </div>
              )}
              <div className="border-t pt-2 flex justify-between text-sm font-extrabold text-slate-900">
                <span>المبلغ الإجمالي:</span>
                <span className="text-blue-700 text-base">{selectedOrder.total_amount.toFixed(2)} ل.س</span>
              </div>
            </div>

            {/* Modal Actions */}
            <div className="flex items-center justify-between pt-2">
              <button
                onClick={() => {
                  setInvoiceOrder(selectedOrder);
                }}
                className="px-4 py-2 border border-blue-600 text-blue-600 rounded-xl text-xs font-bold hover:bg-blue-50 flex items-center gap-2"
              >
                <Printer className="w-4 h-4" />
                طباعة الفاتورة الضريبية الرسمية
              </button>

              <div className="flex items-center gap-2">
                <button
                  onClick={() => setSelectedOrder(null)}
                  className="px-4 py-2 bg-slate-200 hover:bg-slate-300 text-slate-700 rounded-xl text-xs font-bold transition-colors"
                >
                  إغلاق
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Tax Invoice Modal */}
      <InvoiceModal order={invoiceOrder} onClose={() => setInvoiceOrder(null)} />
    </div>
  );
};
