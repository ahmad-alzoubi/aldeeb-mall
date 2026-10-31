import React, { useState } from 'react';
import { 
  Bike, 
  MapPin, 
  CheckCircle2, 
  ShieldCheck, 
  Phone, 
  Navigation, 
  Camera, 
  Clock, 
  PackageCheck, 
  Sparkles,
  ThermometerSnowflake,
  QrCode
} from 'lucide-react';

interface DeliveryRun {
  id: string;
  orderNumber: string;
  customerName: string;
  phone: string;
  address: string;
  zone: string;
  itemsCount: number;
  expectedPin: string;
  status: 'assigned' | 'picked_up' | 'arrived' | 'delivered';
  specialNotes?: string;
  isColdChain: boolean;
  totalAmount: number;
}

export const CourierPortalPage: React.FC = () => {
  const [runs, setRuns] = useState<DeliveryRun[]>([
    {
      id: 'run-1',
      orderNumber: 'ORD-9025',
      customerName: 'د. فيصل الشمري',
      phone: '+966 50 443 1122',
      address: 'حي النرجس، شارع أنس بن مالك، فيلا 14B',
      zone: 'الرياض - شمال',
      itemsCount: 7,
      expectedPin: '4821',
      status: 'assigned',
      specialNotes: 'يرجى وضع الطلب عند الباب ولا تدق الجرس لوجود طفل نائم',
      isColdChain: true,
      totalAmount: 184.50,
    },
    {
      id: 'run-2',
      orderNumber: 'ORD-9026',
      customerName: 'ريم المطيري',
      phone: '+966 55 119 8833',
      address: 'حي الياسمين، مجمع أوركيد السكني، شقة 302',
      zone: 'الرياض - شمال',
      itemsCount: 4,
      expectedPin: '7914',
      status: 'picked_up',
      specialNotes: 'رمز الدخول إلى العمارة هو #8822',
      isColdChain: false,
      totalAmount: 96.00,
    },
    {
      id: 'run-3',
      orderNumber: 'ORD-9022',
      customerName: 'م. عبدالله القحطاني',
      phone: '+966 56 778 3344',
      address: 'حي الملقا، طريق الإمام سعود، عمارة 9',
      zone: 'الرياض - شمال',
      itemsCount: 12,
      expectedPin: '1105',
      status: 'delivered',
      isColdChain: true,
      totalAmount: 312.00,
    },
  ]);

  const [pinInputs, setPinInputs] = useState<{ [orderId: string]: string }>({});
  const [coldChainVerified, setColdChainVerified] = useState<{ [orderId: string]: boolean }>({});
  const [toastMessage, setToastMessage] = useState<string | null>(null);

  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(null), 3500);
  };

  const handleUpdateStatus = (id: string, newStatus: DeliveryRun['status']) => {
    setRuns((prev) =>
      prev.map((r) => (r.id === id ? { ...r, status: newStatus } : r))
    );
    if (newStatus === 'picked_up') {
      showToast('تم استلام الشحنة وفحص الحقيبة الحرارية، وبدء مسار الملاحة الفوري GPS!');
    } else if (newStatus === 'arrived') {
      showToast('تم الوصول إلى موقع العميل. بانتظار إدخال رمز التحقق PIN.');
    }
  };

  const handleVerifyPinAndDeliver = (run: DeliveryRun) => {
    const entered = pinInputs[run.id]?.trim();
    if (entered === run.expectedPin) {
      setRuns((prev) =>
        prev.map((r) => (r.id === run.id ? { ...r, status: 'delivered' } : r))
      );
      showToast(`🎉 تم تأكيد التسليم بنجاح لطلب ${run.orderNumber}! وتم إرسال إشعار التقييم للعميل.`);
    } else {
      showToast('رمز PIN غير صحيح! يرجى الاستفسار من العميل عن الرمز الظاهر بتطبيقه.');
    }
  };

  return (
    <div className="space-y-6">
      {/* Toast */}
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
            <span className="p-2 bg-blue-50 text-blue-600 rounded-xl">
              <Bike className="w-6 h-6" />
            </span>
            <h1 className="text-2xl font-bold text-gray-900">بوابة الكابتن والتسليم الفوري (Courier Dispatch Companion)</h1>
          </div>
          <p className="text-gray-500 mt-1 text-sm">
            محطة السائق الميدانية لتنفيذ شحنات الـ 15 دقيقة، وتأكيد فحص سلسلة التبريد، والتحقق من رمز PIN الآمن
          </p>
        </div>
        <div className="flex items-center gap-3">
          <div className="flex items-center gap-2 bg-emerald-50 text-emerald-700 px-3 py-1.5 rounded-xl border border-emerald-200 text-xs font-semibold">
            <Sparkles className="w-4 h-4 text-emerald-600" />
            <span>متوسط زمن التوصيل اليوم: 13.8 دقيقة ⚡</span>
          </div>
        </div>
      </div>

      {/* Runs List */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {runs.map((run) => {
          const isDelivered = run.status === 'delivered';

          return (
            <div 
              key={run.id}
              className={`bg-white rounded-2xl border transition-all p-5 flex flex-col justify-between ${
                isDelivered ? 'border-gray-200 opacity-75' : 'border-blue-200 shadow-md ring-1 ring-blue-100'
              }`}
            >
              <div>
                {/* Header */}
                <div className="flex items-center justify-between pb-3 border-b border-gray-100">
                  <div className="flex items-center gap-2">
                    <span className="font-mono text-xs font-black bg-blue-50 text-blue-700 px-2 py-1 rounded-md">
                      {run.orderNumber}
                    </span>
                    {run.isColdChain && (
                      <span className="flex items-center gap-1 bg-cyan-50 text-cyan-700 px-2 py-0.5 rounded text-[11px] font-bold border border-cyan-200">
                        <ThermometerSnowflake className="w-3 h-3" />
                        تبريد
                      </span>
                    )}
                  </div>
                  <span className={`px-2.5 py-0.5 rounded-full text-xs font-bold ${
                    run.status === 'assigned' ? 'bg-amber-50 text-amber-700' :
                    run.status === 'picked_up' ? 'bg-blue-50 text-blue-700' :
                    run.status === 'arrived' ? 'bg-purple-50 text-purple-700' :
                    'bg-emerald-50 text-emerald-700'
                  }`}>
                    {run.status === 'assigned' && 'بانتظار الاستلام'}
                    {run.status === 'picked_up' && 'في الطريق للعميل'}
                    {run.status === 'arrived' && 'وصل للموقع'}
                    {run.status === 'delivered' && 'تم التسليم بنجاح ✓'}
                  </span>
                </div>

                {/* Customer Details */}
                <div className="mt-4 space-y-2">
                  <div className="flex items-center justify-between">
                    <span className="font-bold text-gray-900 text-sm">{run.customerName}</span>
                    <a 
                      href={`tel:${run.phone}`}
                      className="flex items-center gap-1 text-xs text-blue-600 bg-blue-50 hover:bg-blue-100 px-2.5 py-1 rounded-lg font-semibold"
                    >
                      <Phone className="w-3 h-3" />
                      اتصال
                    </a>
                  </div>

                  <div className="flex items-start gap-1.5 text-xs text-gray-600">
                    <MapPin className="w-4 h-4 text-rose-500 flex-shrink-0 mt-0.5" />
                    <span>{run.address}</span>
                  </div>

                  {run.specialNotes && (
                    <div className="bg-amber-50/70 border border-amber-200 text-amber-800 text-[11px] p-2.5 rounded-xl font-medium">
                      ⚠️ ملاحظة العميل: {run.specialNotes}
                    </div>
                  )}

                  <div className="flex items-center justify-between text-xs text-gray-500 pt-2 border-t border-gray-100">
                    <span>عدد الأصناف: <strong className="text-gray-800">{run.itemsCount} أصناف</strong></span>
                    <span>الإجمالي: <strong className="text-gray-900 font-mono">{run.totalAmount.toFixed(2)} ل.س</strong></span>
                  </div>
                </div>

                {/* Cold Chain Verification Checkbox for Pending Pick up */}
                {run.status === 'assigned' && run.isColdChain && (
                  <div className="mt-4 p-3 bg-cyan-50/80 rounded-xl border border-cyan-200">
                    <label className="flex items-center gap-2 cursor-pointer text-xs font-semibold text-cyan-900">
                      <input 
                        type="checkbox"
                        checked={!!coldChainVerified[run.id]}
                        onChange={(e) => setColdChainVerified({ ...coldChainVerified, [run.id]: e.target.checked })}
                        className="rounded border-cyan-300 text-cyan-600 focus:ring-cyan-500 w-4 h-4"
                      />
                      <span>تأكيد إحكام إغلاق حقيبة التبريد المعزولة (Cold-Chain Verified)</span>
                    </label>
                  </div>
                )}
              </div>

              {/* Action Buttons Depending on Status */}
              <div className="mt-5 pt-3 border-t border-gray-100">
                {run.status === 'assigned' && (
                  <button
                    onClick={() => handleUpdateStatus(run.id, 'picked_up')}
                    disabled={run.isColdChain && !coldChainVerified[run.id]}
                    className="w-full py-2.5 rounded-xl text-xs font-bold bg-blue-600 hover:bg-blue-700 disabled:opacity-50 text-white shadow-sm flex items-center justify-center gap-2 transition-all"
                  >
                    <PackageCheck className="w-4 h-4" />
                    <span>استلام الشحنة وبدء الانطلاق</span>
                  </button>
                )}

                {run.status === 'picked_up' && (
                  <div className="space-y-2">
                    <button
                      onClick={() => handleUpdateStatus(run.id, 'arrived')}
                      className="w-full py-2.5 rounded-xl text-xs font-bold bg-purple-600 hover:bg-purple-700 text-white shadow-sm flex items-center justify-center gap-2 transition-all"
                    >
                      <Navigation className="w-4 h-4" />
                      <span>تأكيد الوصول إلى باب العميل</span>
                    </button>
                  </div>
                )}

                {run.status === 'arrived' && (
                  <div className="space-y-3">
                    <div>
                      <span className="text-xs text-gray-500 block mb-1">أدخل رمز PIN من تطبيق العميل (رمز تجريبي: {run.expectedPin}):</span>
                      <div className="flex gap-2">
                        <input
                          type="text"
                          maxLength={4}
                          placeholder="مثال: 4821"
                          value={pinInputs[run.id] || ''}
                          onChange={(e) => setPinInputs({ ...pinInputs, [run.id]: e.target.value })}
                          className="w-full px-3 py-2 bg-gray-50 border border-gray-200 rounded-xl text-center font-mono font-bold text-sm tracking-widest focus:outline-none focus:ring-2 focus:ring-emerald-500"
                        />
                        <button
                          onClick={() => handleVerifyPinAndDeliver(run)}
                          className="px-4 py-2 bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-xs rounded-xl transition-all shadow-sm flex items-center gap-1"
                        >
                          <ShieldCheck className="w-4 h-4" />
                          <span>تأكيد</span>
                        </button>
                      </div>
                    </div>
                  </div>
                )}

                {isDelivered && (
                  <div className="flex items-center justify-center gap-1.5 py-1 text-xs text-emerald-700 font-bold bg-emerald-50 rounded-xl border border-emerald-100">
                    <CheckCircle2 className="w-4 h-4" />
                    <span>تم التسليم بنجاح مع مطابقة الـ PIN</span>
                  </div>
                )}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};
