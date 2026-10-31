import React, { useState } from 'react';
import { Plus, TicketPercent, Check, X, Trash2 } from 'lucide-react';
import { Coupon } from '../types';

interface CouponsPageProps {
  coupons: Coupon[];
  onAddCoupon: (coupon: Coupon) => void;
  onToggleCoupon: (couponId: string) => void;
  onDeleteCoupon: (couponId: string) => void;
}

export const CouponsPage: React.FC<CouponsPageProps> = ({
  coupons,
  onAddCoupon,
  onToggleCoupon,
  onDeleteCoupon,
}) => {
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [code, setCode] = useState('');
  const [discountType, setDiscountType] = useState<'percentage' | 'fixed'>('percentage');
  const [discountValue, setDiscountValue] = useState<number>(15);
  const [minOrder, setMinOrder] = useState<number>(60);
  const [usageLimit, setUsageLimit] = useState<number>(1000);

  const handleCreate = (e: React.FormEvent) => {
    e.preventDefault();
    if (!code.trim()) return;

    const newCoupon: Coupon = {
      id: `cp-${Date.now()}`,
      code: code.trim().toUpperCase(),
      discount_type: discountType,
      discount_value: Number(discountValue),
      min_order_amount: Number(minOrder),
      usage_limit: Number(usageLimit),
      times_used: 0,
      is_active: true,
    };

    onAddCoupon(newCoupon);
    setIsModalOpen(false);
    setCode('');
  };

  return (
    <div className="space-y-6">
      {/* Top Action Bar */}
      <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-sm flex items-center justify-between">
        <div>
          <h3 className="text-base font-extrabold text-slate-900">إدارة الكوبونات وقسائم الخصم</h3>
          <p className="text-xs text-slate-400">أنشئ أكواد خصم ترويجية لحملات التسويق وزيادة المبيعات</p>
        </div>
        <button
          onClick={() => setIsModalOpen(true)}
          className="px-4 py-2.5 bg-blue-600 hover:bg-blue-700 text-white rounded-xl text-xs font-bold transition-all shadow-md shadow-blue-600/20 flex items-center gap-2"
        >
          <Plus className="w-4 h-4" />
          إنشاء كوبون جديد
        </button>
      </div>

      {/* Coupons Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {coupons.map((coupon) => (
          <div
            key={coupon.id}
            className={`p-6 rounded-2xl border transition-all bg-white shadow-sm flex flex-col justify-between ${
              coupon.is_active ? 'border-slate-200 hover:border-blue-400' : 'border-slate-200 opacity-60'
            }`}
          >
            <div>
              <div className="flex items-center justify-between mb-4">
                <span className="p-2.5 bg-red-50 text-red-600 rounded-xl">
                  <TicketPercent className="w-6 h-6" />
                </span>
                <button
                  onClick={() => onToggleCoupon(coupon.id)}
                  className={`text-xs px-2.5 py-1 rounded-full font-bold transition-colors ${
                    coupon.is_active
                      ? 'bg-emerald-100 text-emerald-800'
                      : 'bg-slate-200 text-slate-600'
                  }`}
                >
                  {coupon.is_active ? 'مفعل وجاهز' : 'معطل مؤقتاً'}
                </button>
              </div>

              <div className="p-3 bg-slate-50 border border-dashed border-slate-300 rounded-xl text-center mb-4">
                <p className="font-mono text-lg font-black tracking-widest text-blue-900">
                  {coupon.code}
                </p>
              </div>

              <div className="space-y-2 text-xs text-slate-600 font-medium">
                <div className="flex justify-between">
                  <span>قيمة الخصم:</span>
                  <span className="font-extrabold text-blue-700">
                    {coupon.discount_type === 'percentage'
                      ? `${coupon.discount_value}% من قيمة السلة`
                      : `${coupon.discount_value.toFixed(2)} ل.س خصم مباشر`}
                  </span>
                </div>
                <div className="flex justify-between">
                  <span>الحد الأدنى للطلب:</span>
                  <span className="font-bold text-slate-800">{coupon.min_order_amount.toFixed(2)} ل.س</span>
                </div>
                <div className="flex justify-between">
                  <span>مرات الاستخدام:</span>
                  <span className="font-bold text-slate-800">
                    {coupon.times_used} من أصل {coupon.usage_limit}
                  </span>
                </div>
              </div>
            </div>

            <div className="pt-4 mt-4 border-t border-slate-100 flex items-center justify-between">
              <span className="text-[11px] text-slate-400">صالح في التطبيق والمتجر</span>
              <button
                onClick={() => onDeleteCoupon(coupon.id)}
                className="text-xs text-slate-400 hover:text-rose-600 flex items-center gap-1 font-bold"
              >
                <Trash2 className="w-3.5 h-3.5" />
                حذف
              </button>
            </div>
          </div>
        ))}
      </div>

      {/* Create Coupon Modal */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 bg-black/50 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-md w-full p-6 shadow-2xl space-y-4">
            <div className="flex items-center justify-between border-b pb-3">
              <h3 className="text-base font-extrabold text-slate-900">إنشاء كوبون خصم جديد</h3>
              <button onClick={() => setIsModalOpen(false)} className="text-slate-400 hover:text-slate-600">
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleCreate} className="space-y-4 text-xs font-bold text-slate-700">
              <div>
                <label className="block mb-1">كود الكوبون (رمز الخصم) *</label>
                <input
                  type="text"
                  required
                  placeholder="مثال: RAMADAN25"
                  value={code}
                  onChange={(e) => setCode(e.target.value)}
                  className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600 font-mono uppercase text-sm"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block mb-1">نوع الخصم</label>
                  <select
                    value={discountType}
                    onChange={(e) => setDiscountType(e.target.value as 'percentage' | 'fixed')}
                    className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600"
                  >
                    <option value="percentage">نسبة مئوية (%)</option>
                    <option value="fixed">مبلغ مالي ثابت (ل.س)</option>
                  </select>
                </div>
                <div>
                  <label className="block mb-1">قيمة الخصم *</label>
                  <input
                    type="number"
                    required
                    value={discountValue}
                    onChange={(e) => setDiscountValue(Number(e.target.value))}
                    className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block mb-1">الحد الأدنى للطلب (ل.س)</label>
                  <input
                    type="number"
                    value={minOrder}
                    onChange={(e) => setMinOrder(Number(e.target.value))}
                    className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600"
                  />
                </div>
                <div>
                  <label className="block mb-1">حد مرات الاستخدام الكلي</label>
                  <input
                    type="number"
                    value={usageLimit}
                    onChange={(e) => setUsageLimit(Number(e.target.value))}
                    className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600"
                  />
                </div>
              </div>

              <div className="pt-3 flex justify-end gap-3 border-t">
                <button
                  type="button"
                  onClick={() => setIsModalOpen(false)}
                  className="px-4 py-2 bg-slate-100 hover:bg-slate-200 text-slate-600 rounded-xl text-xs font-bold"
                >
                  إلغاء
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-xl text-xs font-bold shadow-md shadow-blue-600/30"
                >
                  تفعيل وحفظ الكوبون
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
