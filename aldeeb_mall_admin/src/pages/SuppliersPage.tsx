import React, { useState } from 'react';
import { 
  Building2, 
  FileText, 
  Plus, 
  CheckCircle2, 
  Clock, 
  AlertCircle, 
  Phone, 
  Mail, 
  TrendingDown, 
  Send
} from 'lucide-react';
import { Supplier, PurchaseOrder, Product } from '../types';

interface SuppliersPageProps {
  suppliers: Supplier[];
  purchaseOrders: PurchaseOrder[];
  products: Product[];
  onAddPO?: (po: PurchaseOrder) => void;
}

export const SuppliersPage: React.FC<SuppliersPageProps> = ({
  suppliers,
  purchaseOrders: initialPOs,
  products,
}) => {
  const [pos, setPOs] = useState<PurchaseOrder[]>(initialPOs);
  const [activeTab, setActiveTab] = useState<'orders' | 'suppliers'>('orders');
  const [showNewPOModal, setShowNewPOModal] = useState<boolean>(false);
  const [selectedSupplier, setSelectedSupplier] = useState<string>(suppliers[0]?.name_ar || '');
  const [itemCount, setItemCount] = useState<number>(300);
  const [estimatedCost, setEstimatedCost] = useState<number>(3200);

  // Auto-alert products below safety stock (e.g. stock < 50)
  const lowStockProducts = products.filter((p) => p.stock_quantity <= 50);

  const handleCreatePO = (e: React.FormEvent) => {
    e.preventDefault();
    const newPO: PurchaseOrder = {
      id: `po-${Date.now()}`,
      po_number: `PO-2026-${Math.floor(100 + Math.random() * 900)}`,
      supplier_name: selectedSupplier,
      total_items: itemCount,
      total_cost: estimatedCost,
      status: 'sent',
      order_date: new Date().toISOString().split('T')[0],
      expected_arrival: 'غداً صباحاً (6:00 ص)',
    };
    setPOs((prev) => [newPO, ...prev]);
    setShowNewPOModal(false);
  };

  const handleAdvancePOStatus = (poId: string) => {
    setPOs((prev) =>
      prev.map((p) =>
        p.id === poId
          ? { ...p, status: p.status === 'draft' ? 'sent' : p.status === 'sent' ? 'received' : p.status }
          : p
      )
    );
  };

  return (
    <div className="space-y-6">
      {/* Top Automated Stock Alert Banner */}
      {lowStockProducts.length > 0 && (
        <div className="bg-amber-50 border border-amber-200 rounded-2xl p-4 flex flex-col md:flex-row items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-amber-100 flex items-center justify-center shrink-0">
              <TrendingDown className="w-5 h-5 text-amber-700" />
            </div>
            <div>
              <h4 className="font-bold text-amber-900 text-sm">
                تنبيه ذكي: أصناف تقترب من حد الأمان الأدنى للمخزون ({lowStockProducts.length} أصناف)
              </h4>
              <p className="text-xs text-amber-700 mt-0.5">
                مثل: {lowStockProducts.map((p) => p.name_ar).slice(0, 2).join('، ')} بحاجة إلى إعادة طلب فوري من المورد.
              </p>
            </div>
          </div>
          <button
            onClick={() => setShowNewPOModal(true)}
            className="px-4 py-2 bg-amber-600 hover:bg-amber-700 text-white rounded-xl text-xs font-bold transition-colors shrink-0 shadow-sm flex items-center gap-1.5"
          >
            <Plus className="w-4 h-4" />
            إنشاء أمر شراء تلقائي (Auto-PO)
          </button>
        </div>
      )}

      {/* Tabs */}
      <div className="flex justify-between items-center border-b border-slate-200 pb-3">
        <div className="flex gap-2">
          <button
            onClick={() => setActiveTab('orders')}
            className={`px-4 py-2 rounded-xl text-xs font-bold transition-all ${
              activeTab === 'orders'
                ? 'bg-blue-600 text-white shadow-md shadow-blue-600/30'
                : 'bg-white text-slate-600 hover:bg-slate-100 border border-slate-200'
            }`}
          >
            أوامر الشراء والتوريد (Purchase Orders)
          </button>
          <button
            onClick={() => setActiveTab('suppliers')}
            className={`px-4 py-2 rounded-xl text-xs font-bold transition-all ${
              activeTab === 'suppliers'
                ? 'bg-blue-600 text-white shadow-md shadow-blue-600/30'
                : 'bg-white text-slate-600 hover:bg-slate-100 border border-slate-200'
            }`}
          >
            سجل الموردين المعتمدين ({suppliers.length})
          </button>
        </div>

        <button
          onClick={() => setShowNewPOModal(true)}
          className="px-4 py-2 bg-slate-900 hover:bg-slate-800 text-white rounded-xl text-xs font-bold transition-colors flex items-center gap-1.5"
        >
          <Plus className="w-4 h-4" />
          أمر شراء جديد
        </button>
      </div>

      {/* Tab 1: Purchase Orders */}
      {activeTab === 'orders' && (
        <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-right text-xs">
              <thead className="bg-slate-50 border-b border-slate-200 text-slate-500 font-bold">
                <tr>
                  <th className="p-4">رقم أمر الشراء</th>
                  <th className="p-4">اسم المورد</th>
                  <th className="p-4">إجمالي الكمية</th>
                  <th className="p-4">التكلفة الإجمالية</th>
                  <th className="p-4">تاريخ الطلب</th>
                  <th className="p-4">الوصول المتوقع</th>
                  <th className="p-4">حالة التوريد</th>
                  <th className="p-4 text-center">الإجراء</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {pos.map((po) => (
                  <tr key={po.id} className="hover:bg-slate-50/60 transition-colors">
                    <td className="p-4 font-mono font-bold text-blue-600">{po.po_number}</td>
                    <td className="p-4 font-bold text-slate-800">{po.supplier_name}</td>
                    <td className="p-4 font-bold">{po.total_items} قطعة</td>
                    <td className="p-4 font-mono font-bold text-blue-900">{po.total_cost.toFixed(2)} د.إ</td>
                    <td className="p-4 text-slate-500">{po.order_date}</td>
                    <td className="p-4 text-slate-600 font-semibold">{po.expected_arrival}</td>
                    <td className="p-4">
                      {po.status === 'received' && (
                        <span className="inline-flex items-center gap-1 text-xs font-bold text-emerald-700 bg-emerald-100 px-2 py-0.5 rounded-full">
                          <CheckCircle2 className="w-3.5 h-3.5" />
                          تم الاستلام بالمستودع
                        </span>
                      )}
                      {po.status === 'sent' && (
                        <span className="inline-flex items-center gap-1 text-xs font-bold text-blue-700 bg-blue-100 px-2 py-0.5 rounded-full">
                          <Clock className="w-3.5 h-3.5" />
                          تم الإرسال للمورد
                        </span>
                      )}
                      {po.status === 'draft' && (
                        <span className="inline-flex items-center gap-1 text-xs font-bold text-slate-700 bg-slate-200 px-2 py-0.5 rounded-full">
                          مسودة داخلية
                        </span>
                      )}
                    </td>
                    <td className="p-4 text-center">
                      {po.status === 'sent' && (
                        <button
                          onClick={() => handleAdvancePOStatus(po.id)}
                          className="px-3 py-1 bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg font-bold text-xs shadow-sm transition-colors"
                        >
                          تأكيد الاستلام بالمستودع
                        </button>
                      )}
                      {po.status === 'received' && (
                        <span className="text-slate-400 font-medium">مكتمل ومضاف للرصيد</span>
                      )}
                      {po.status === 'draft' && (
                        <button
                          onClick={() => handleAdvancePOStatus(po.id)}
                          className="px-3 py-1 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-bold text-xs transition-colors flex items-center gap-1 mx-auto"
                        >
                          <Send className="w-3 h-3" />
                          إرسال للمورد
                        </button>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Tab 2: Suppliers List */}
      {activeTab === 'suppliers' && (
        <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
          {suppliers.map((sup) => (
            <div key={sup.id} className="bg-white rounded-2xl border border-slate-200 p-5 shadow-sm space-y-4">
              <div className="flex items-start justify-between">
                <div>
                  <h4 className="font-bold text-slate-900 text-sm">{sup.name_ar}</h4>
                  <p className="text-xs text-slate-400 font-mono mt-0.5">{sup.name_en}</p>
                </div>
                <span className="text-[11px] font-bold px-2 py-0.5 rounded bg-emerald-100 text-emerald-800">
                  معتمد نشط
                </span>
              </div>

              <div className="space-y-2 text-xs text-slate-600 bg-slate-50 p-3 rounded-xl border border-slate-100">
                <div className="flex items-center gap-2">
                  <Building2 className="w-3.5 h-3.5 text-blue-600" />
                  <span>المسؤول: {sup.contact_person}</span>
                </div>
                <div className="flex items-center gap-2">
                  <Phone className="w-3.5 h-3.5 text-blue-600" />
                  <span className="font-mono">{sup.phone}</span>
                </div>
                <div className="flex items-center gap-2">
                  <Mail className="w-3.5 h-3.5 text-blue-600" />
                  <span className="font-mono">{sup.email}</span>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-2 text-center text-xs">
                <div className="bg-slate-50 p-2 rounded-lg">
                  <div className="font-bold text-slate-800">{sup.lead_time_days} يوم</div>
                  <div className="text-slate-400 text-[10px]">زمن التوريد (Lead Time)</div>
                </div>
                <div className="bg-slate-50 p-2 rounded-lg">
                  <div className="font-bold text-slate-800">{sup.active_products_count}</div>
                  <div className="text-slate-400 text-[10px]">أصناف مسجلة</div>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* New PO Modal */}
      {showNewPOModal && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl max-w-md w-full p-6 shadow-2xl border border-slate-200">
            <h3 className="text-lg font-bold text-slate-900 mb-4 flex items-center gap-2">
              <FileText className="w-5 h-5 text-blue-600" />
              إصدار أمر شراء وتوريد جديد للمستودع
            </h3>

            <form onSubmit={handleCreatePO} className="space-y-4 text-xs">
              <div>
                <label className="block font-bold text-slate-700 mb-1">المورد المستهدف</label>
                <select
                  value={selectedSupplier}
                  onChange={(e) => setSelectedSupplier(e.target.value)}
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-300 rounded-xl text-xs"
                >
                  {suppliers.map((s) => (
                    <option key={s.id} value={s.name_ar}>
                      {s.name_ar}
                    </option>
                  ))}
                </select>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block font-bold text-slate-700 mb-1">الكمية الإجمالية (قطع)</label>
                  <input
                    type="number"
                    min="10"
                    value={itemCount}
                    onChange={(e) => setItemCount(Number(e.target.value))}
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-300 rounded-xl"
                  />
                </div>
                <div>
                  <label className="block font-bold text-slate-700 mb-1">التكلفة التقديرية (د.إ)</label>
                  <input
                    type="number"
                    min="100"
                    value={estimatedCost}
                    onChange={(e) => setEstimatedCost(Number(e.target.value))}
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-300 rounded-xl font-mono"
                  />
                </div>
              </div>

              <div className="flex justify-end gap-2 pt-4 border-t border-slate-100">
                <button
                  type="button"
                  onClick={() => setShowNewPOModal(false)}
                  className="px-4 py-2 border border-slate-300 rounded-xl font-bold text-slate-600 hover:bg-slate-50"
                >
                  إلغاء
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 bg-blue-600 hover:bg-blue-700 text-white font-bold rounded-xl shadow-md shadow-blue-600/30 flex items-center gap-1.5"
                >
                  <Send className="w-3.5 h-3.5" />
                  إرسال أمر الشراء الآن
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
