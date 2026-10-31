import React, { useState } from 'react';
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
  Sparkles 
} from 'lucide-react';

interface TransferOrder {
  id: string;
  manifestNumber: string;
  sourceHub: string;
  destinationStore: string;
  sku: string;
  productNameAr: string;
  quantityRequested: number;
  quantityDispatched: number;
  quantityReceived?: number;
  status: 'pending' | 'in_transit' | 'received';
  assignedDriver: string;
  requestedAt: string;
}

export const InventoryTransferPage: React.FC = () => {
  const [transfers, setTransfers] = useState<TransferOrder[]>([
    {
      id: 'tr-1',
      manifestNumber: 'TRF-2026-904',
      sourceHub: 'المستودع اللوجستي المركزي (Hub 01)',
      destinationStore: 'مستودع الرياض - شمال (Dark Store 02 - النرجس)',
      sku: 'ALM-MILK-2L',
      productNameAr: 'حليب المراعي كامل الدسم 2 لتر',
      quantityRequested: 120,
      quantityDispatched: 120,
      status: 'in_transit',
      assignedDriver: 'سعد العنزي (شاحنة مبردة رقم 14)',
      requestedAt: 'قبل 40 دقيقة',
    },
    {
      id: 'tr-2',
      manifestNumber: 'TRF-2026-903',
      sourceHub: 'المستودع اللوجستي المركزي (Hub 01)',
      destinationStore: 'مستودع الرياض - الملقا (Dark Store 03)',
      sku: 'EGG-ORG-30',
      productNameAr: 'طبق بيض عضوي بلدي 30 حبة',
      quantityRequested: 60,
      quantityDispatched: 60,
      status: 'pending',
      assignedDriver: 'بانتظار تخصيص شاحنة النقل',
      requestedAt: 'قبل 15 دقيقة',
    },
    {
      id: 'tr-3',
      manifestNumber: 'TRF-2026-901',
      sourceHub: 'مستودع الرياض - الملقا (Dark Store 03)',
      destinationStore: 'مستودع الرياض - شمال (Dark Store 02)',
      sku: 'TOM-VINE-KG',
      productNameAr: 'طماطم مزارع عنقودية طازجة (كغم)',
      quantityRequested: 45,
      quantityDispatched: 45,
      quantityReceived: 45,
      status: 'received',
      assignedDriver: 'محمد الحربي (فان مبرد #08)',
      requestedAt: 'أمس، 06:30 م',
    },
  ]);

  const [toastMessage, setToastMessage] = useState<string | null>(null);

  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(null), 3500);
  };

  const handleConfirmReceipt = (id: string, manifestNumber: string) => {
    setTransfers((prev) =>
      prev.map((t) => (t.id === id ? { ...t, status: 'received', quantityReceived: t.quantityDispatched } : t))
    );
    showToast(`✓ تم تأكيد استلام شحنة المنفيست ${manifestNumber} ومطابقة الباركود وإيداع المخزون بنجاح!`);
  };

  const handleDispatch = (id: string, manifestNumber: string) => {
    setTransfers((prev) =>
      prev.map((t) => (t.id === id ? { ...t, status: 'in_transit', assignedDriver: 'كابتن النقل اللوجستي (شاحنة تبريد #21)' } : t))
    );
    showToast(`🚚 تم تحريك شحنة ${manifestNumber} وتحديث نظام التتبع اللوجستي بين الفروع!`);
  };

  return (
    <div className="space-y-6">
      {/* Toast Alert */}
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
            <span className="p-2 bg-indigo-50 text-indigo-600 rounded-xl">
              <ArrowLeftRight className="w-6 h-6" />
            </span>
            <h1 className="text-2xl font-bold text-gray-900">إدارة المناقلات والمخزون بين الفروع (Inventory Transfer Hub)</h1>
          </div>
          <p className="text-gray-500 mt-1 text-sm">
            موازنة المخزون التلقائية بين المستودع اللوجستي الرئيسي وفروع الميكرو-فولفيلمنت (Dark Stores) لضمان عدم نفاد أي صنف
          </p>
        </div>
        <div className="flex items-center gap-2">
          <span className="px-3.5 py-1.5 bg-indigo-50 text-indigo-700 text-xs font-bold rounded-xl border border-indigo-200">
            {transfers.filter(t => t.status === 'in_transit').length} شحنات جارية على الطريق
          </span>
        </div>
      </div>

      {/* Dark Stores Stock Balancing Health */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="bg-white p-5 rounded-2xl border border-gray-100 shadow-sm">
          <div className="flex items-center justify-between mb-3">
            <span className="text-xs font-bold text-gray-500">المستودع اللوجستي المركزي</span>
            <span className="px-2 py-0.5 rounded text-[11px] font-bold bg-emerald-50 text-emerald-700">Hub 01</span>
          </div>
          <div className="text-2xl font-black text-gray-900">14,200 صنف</div>
          <div className="text-xs text-gray-400 mt-1">نسبة كفاية المخزون: 98.4% (ممتاز)</div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-gray-100 shadow-sm">
          <div className="flex items-center justify-between mb-3">
            <span className="text-xs font-bold text-gray-500">مستودع شمال الرياض (النرجس)</span>
            <span className="px-2 py-0.5 rounded text-[11px] font-bold bg-blue-50 text-blue-700">Dark Store 02</span>
          </div>
          <div className="text-2xl font-black text-gray-900">3,850 صنف</div>
          <div className="text-xs text-amber-600 font-semibold mt-1">تنبيه ذكاء اصطناعي: شارف الحليب على النفاد</div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-gray-100 shadow-sm">
          <div className="flex items-center justify-between mb-3">
            <span className="text-xs font-bold text-gray-500">مستودع غرب الرياض (الملقا)</span>
            <span className="px-2 py-0.5 rounded text-[11px] font-bold bg-purple-50 text-purple-700">Dark Store 03</span>
          </div>
          <div className="text-2xl font-black text-gray-900">4,120 صنف</div>
          <div className="text-xs text-emerald-600 font-semibold mt-1">مستقر ومطابق لمعايير الـ 15 دقيقة</div>
        </div>
      </div>

      {/* Transfers List */}
      <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-6">
        <div className="flex items-center justify-between pb-4 mb-4 border-b border-gray-100">
          <div>
            <h2 className="text-base font-bold text-gray-900">أوامر المناقلة والشحنات الميدانية (Transfer Manifests)</h2>
            <p className="text-xs text-gray-500">متابعة تحرك شاحنات التبريد بين الفروع وتأكيد الاستلام بالمستودع المستقبل</p>
          </div>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-right text-sm">
            <thead className="bg-gray-50 text-gray-500 font-semibold border-b border-gray-100">
              <tr>
                <th className="py-3 px-4">رقم المنفيست</th>
                <th className="py-3 px-4">المنتج والرمز</th>
                <th className="py-3 px-4">من (المستودع المصدر)</th>
                <th className="py-3 px-4">إلى (الفرع المستهدف)</th>
                <th className="py-3 px-4">الكمية المنقولة</th>
                <th className="py-3 px-4">السائق والشاحنة</th>
                <th className="py-3 px-4">الحالة</th>
                <th className="py-3 px-4 text-center">الإجراء اللوجستي</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {transfers.map((t) => (
                <tr key={t.id} className="hover:bg-gray-50/80 transition-colors">
                  <td className="py-3.5 px-4 font-mono font-bold text-xs text-indigo-700">
                    {t.manifestNumber}
                  </td>
                  <td className="py-3.5 px-4">
                    <div className="font-bold text-gray-900">{t.productNameAr}</div>
                    <div className="text-xs text-gray-400 font-mono">SKU: {t.sku}</div>
                  </td>
                  <td className="py-3.5 px-4 text-xs font-medium text-gray-700">
                    {t.sourceHub}
                  </td>
                  <td className="py-3.5 px-4 text-xs font-bold text-blue-700">
                    {t.destinationStore}
                  </td>
                  <td className="py-3.5 px-4 font-bold text-gray-900 font-mono">
                    {t.quantityDispatched} حبة
                  </td>
                  <td className="py-3.5 px-4 text-xs text-gray-600">
                    <div className="flex items-center gap-1">
                      <Truck className="w-3.5 h-3.5 text-gray-400" />
                      <span>{t.assignedDriver}</span>
                    </div>
                  </td>
                  <td className="py-3.5 px-4">
                    <span className={`px-2.5 py-1 rounded-full text-xs font-bold ${
                      t.status === 'pending' ? 'bg-amber-50 text-amber-700 border border-amber-200' :
                      t.status === 'in_transit' ? 'bg-blue-50 text-blue-700 border border-blue-200' :
                      'bg-emerald-50 text-emerald-700 border border-emerald-200'
                    }`}>
                      {t.status === 'pending' && 'بانتظار الانطلاق'}
                      {t.status === 'in_transit' && 'في الطريق 🚚'}
                      {t.status === 'received' && 'تم الاستلام والتسوية ✓'}
                    </span>
                  </td>
                  <td className="py-3.5 px-4 text-center">
                    {t.status === 'pending' && (
                      <button
                        onClick={() => handleDispatch(t.id, t.manifestNumber)}
                        className="px-3.5 py-1.5 bg-blue-600 hover:bg-blue-700 text-white rounded-xl text-xs font-bold transition-all shadow-sm flex items-center gap-1 mx-auto"
                      >
                        <Truck className="w-3.5 h-3.5" />
                        <span>تحريك الشحنة</span>
                      </button>
                    )}

                    {t.status === 'in_transit' && (
                      <button
                        onClick={() => handleConfirmReceipt(t.id, t.manifestNumber)}
                        className="px-3.5 py-1.5 bg-emerald-600 hover:bg-emerald-700 text-white rounded-xl text-xs font-bold transition-all shadow-sm flex items-center gap-1 mx-auto"
                      >
                        <Barcode className="w-3.5 h-3.5" />
                        <span>تأكيد الاستلام بالمستودع</span>
                      </button>
                    )}

                    {t.status === 'received' && (
                      <span className="text-xs text-emerald-600 font-bold">مكتمل</span>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};
