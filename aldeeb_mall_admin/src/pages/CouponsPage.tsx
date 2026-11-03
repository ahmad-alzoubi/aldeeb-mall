import React, { useState } from 'react';
import { 
  Plus, 
  TicketPercent, 
  Check, 
  X, 
  Trash2, 
  ShieldAlert, 
  AlertCircle, 
  Clock, 
  Calendar, 
  Building2, 
  Layers,
  Sparkles,
  Lock
} from 'lucide-react';
import { Coupon } from '../types';
import { logAuditEvent } from '../lib/auditLogger';
import { generateUUID } from '../lib/uuidUtils';

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
  const [minOrder, setMinOrder] = useState<number>(50);
  const [maxDiscount, setMaxDiscount] = useState<number>(20);
  const [usageLimit, setUsageLimit] = useState<number>(500);
  const [perCustomerLimit, setPerCustomerLimit] = useState<number>(1);
  const [allowWithFlash, setAllowWithFlash] = useState<boolean>(false);
  const [allowStacking, setAllowStacking] = useState<boolean>(false);
  const [expiryDate, setExpiryDate] = useState<string>(() => {
    const d = new Date();
    d.setDate(d.getDate() + 30);
    return d.toISOString().split('T')[0];
  });
  const [targetBranch, setTargetBranch] = useState<string>('all');

  const handleCreate = (e: React.FormEvent) => {
    e.preventDefault();
    if (!code.trim()) return;

    const newCoupon: Coupon = {
      id: generateUUID(),
      code: code.trim().toUpperCase(),
      discount_type: discountType,
      discount_value: Number(discountValue),
      min_order_amount: Number(minOrder),
      max_discount: discountType === 'percentage' ? Number(maxDiscount) : undefined,
      usage_limit: Number(usageLimit),
      times_used: 0,
      is_active: true,
      expires_at: expiryDate,
      per_customer_limit: Number(perCustomerLimit),
      allow_combine_with_flash_deals: allowWithFlash,
      allow_stacking_coupons: allowStacking,
      branch_id: targetBranch === 'all' ? undefined : targetBranch,
    };

    onAddCoupon(newCoupon);

    logAuditEvent({
      actor_id: 'admin-1',
      actor_name: 'مدير التسويق',
      actor_role: 'marketing_manager',
      action: 'COUPON_CREATED',
      category: 'financial',
      details: `إنشاء كود خصم جديد (${newCoupon.code}) بقيمة ${discountValue}${discountType === 'percentage' ? '%' : 'ل.س'} مع منع التضارب والتكرار.`,
      target_id: newCoupon.id,
    });

    setIsModalOpen(false);
    setCode('');
  };

  return (
    <div className="space-y-6">
      {/* Top Banner with Anti-Conflict Guarantees */}
      <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm flex flex-col md:flex-row items-start md:items-center justify-between gap-4">
        <div>
          <h3 className="text-base font-extrabold text-slate-900 flex items-center gap-2">
            <TicketPercent className="w-5 h-5 text-blue-600" />
            إدارة الكوبونات وقواعد منع التضارب والتكرار
          </h3>
          <p className="text-xs text-slate-500 mt-1">
            كافة الكوبونات مضبوطة بقواعد حوكمة مالية: منع الاستخدام المكرر لنفس العميل، منع دمج أكثر من كوبون في نفس السلة، ومنع تضارب الخصومات مع عروض الفلاش إلا بشرط صريح.
          </p>
        </div>
        <button
          onClick={() => setIsModalOpen(true)}
          className="px-4 py-2.5 bg-blue-600 hover:bg-blue-700 text-white rounded-xl text-xs font-bold transition-all shadow-md shadow-blue-600/20 flex items-center gap-2 shrink-0"
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
                <span className="p-2.5 bg-blue-50 text-blue-600 rounded-xl">
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
                  <span className="font-mono font-bold">{coupon.min_order_amount.toFixed(2)} ل.س</span>
                </div>

                {coupon.max_discount && (
                  <div className="flex justify-between">
                    <span>الحد الأقصى للخصم (سقف الخصم):</span>
                    <span className="font-mono font-bold text-amber-700">{coupon.max_discount.toFixed(2)} ل.س</span>
                  </div>
                )}

                <div className="flex justify-between">
                  <span>حد الاستخدام للعميل الواحد:</span>
                  <span className="font-bold text-slate-800">
                    {coupon.per_customer_limit ? `${coupon.per_customer_limit} مرة واحدة` : 'مرة واحدة فقط'}
                  </span>
                </div>

                <div className="flex justify-between">
                  <span>صالح حتى تاريخ:</span>
                  <span className="font-mono text-slate-500">{coupon.expires_at || 'مفتوح الصلاحية'}</span>
                </div>

                {/* Conflict Badges */}
                <div className="pt-2 border-t border-slate-100 flex flex-wrap gap-1.5">
                  <span className="text-[10px] px-2 py-0.5 rounded font-extrabold bg-slate-100 text-slate-700 flex items-center gap-1">
                    <Lock className="w-3 h-3 text-slate-500" />
                    غير قابل للدمج مع كوبونات أخرى
                  </span>
                  {!coupon.allow_combine_with_flash_deals && (
                    <span className="text-[10px] px-2 py-0.5 rounded font-extrabold bg-rose-50 text-rose-700 border border-rose-200">
                      محجوب عن أصناف عروض الفلاش
                    </span>
                  )}
                </div>
              </div>
            </div>

            <div className="mt-5 pt-4 border-t border-slate-100 flex items-center justify-between text-xs">
              <span className="text-slate-400">
                مرات الاستخدام: <strong className="text-slate-700 font-mono">{coupon.times_used}</strong> / {coupon.usage_limit}
              </span>
              <button
                onClick={() => onDeleteCoupon(coupon.id)}
                className="text-slate-400 hover:text-rose-600 transition-colors p-1"
                title="حذف الكوبون"
              >
                <Trash2 className="w-4 h-4" />
              </button>
            </div>
          </div>
        ))}
      </div>

      {/* New Coupon Modal */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl max-w-lg w-full p-6 shadow-2xl border border-slate-200 max-h-[90vh] overflow-y-auto">
            <h3 className="text-lg font-bold text-slate-900 mb-4 flex items-center gap-2">
              <TicketPercent className="w-5 h-5 text-blue-600" />
              إنشاء كود خصم جديد مع حوكمة المنع
            </h3>

            {/* Live Interactive Preview Card */}
            <div className="mb-5 p-4 bg-gradient-to-br from-blue-50 to-indigo-50/50 rounded-2xl border border-blue-100 space-y-2">
              <div className="flex items-center justify-between text-xs text-blue-800 font-extrabold">
                <span className="flex items-center gap-1.5">
                  <Sparkles className="w-4 h-4 text-amber-500" />
                  معاينة الكوبون للمستخدم في التطبيق
                </span>
                <span className="bg-blue-600 text-white px-2 py-0.5 rounded text-[10px] font-mono">
                  {code.trim() ? code.trim().toUpperCase() : 'CODE-PREVIEW'}
                </span>
              </div>
              <div className="p-3 bg-white rounded-xl border border-blue-100 flex items-center justify-between">
                <div>
                  <p className="text-xs font-bold text-slate-800">
                    {discountType === 'percentage'
                      ? `خصم ${discountValue || 0}% حتى سقف ${maxDiscount || 0} ل.س`
                      : `خصم مباشر ${discountValue || 0} ل.س`}
                  </p>
                  <p className="text-[10px] text-slate-500">
                    الحد الأدنى للطلب: {minOrder || 0} ل.س • ينتهي في: {expiryDate || 'مفتوح'}
                  </p>
                </div>
                <div className="text-right">
                  <span className="text-[10px] bg-slate-100 text-slate-700 px-2 py-0.5 rounded font-mono block">
                    {perCustomerLimit === 1 ? 'استخدام واحد فقط' : `${perCustomerLimit} مرات`}
                  </span>
                </div>
              </div>
            </div>

            <form onSubmit={handleCreate} className="space-y-4 text-xs">
              <div>
                <label className="block font-bold text-slate-700 mb-1">كود الكوبون (الرمز الترويجي) *</label>
                <input
                  type="text"
                  required
                  placeholder="مثال: ALDEEB2026 أو WELCOME10"
                  value={code}
                  onChange={(e) => setCode(e.target.value)}
                  className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl font-mono uppercase font-black text-blue-800"
                />
                {coupons.some((c) => c.code === code.trim().toUpperCase()) && (
                  <p className="text-[10px] text-rose-600 font-bold mt-1 flex items-center gap-1">
                    <AlertCircle className="w-3 h-3" />
                    هذا الكود مستخدم مسبقاً، الرجاء اختيار كود فريد لمنع تضارب قواعد الخصم.
                  </p>
                )}
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block font-bold text-slate-700 mb-1">نوع الخصم</label>
                  <select
                    value={discountType}
                    onChange={(e) => setDiscountType(e.target.value as 'percentage' | 'fixed')}
                    className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl font-bold"
                  >
                    <option value="percentage">نسبة مئوية (%)</option>
                    <option value="fixed">مبلغ ثابت (ل.س)</option>
                  </select>
                </div>
                <div>
                  <label className="block font-bold text-slate-700 mb-1">قيمة الخصم *</label>
                  <input
                    type="number"
                    min="1"
                    required
                    value={discountValue}
                    onChange={(e) => setDiscountValue(Number(e.target.value))}
                    className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl font-mono font-bold"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block font-bold text-slate-700 mb-1">الحد الأدنى للطلب (ل.س) *</label>
                  <input
                    type="number"
                    min="0"
                    required
                    value={minOrder}
                    onChange={(e) => setMinOrder(Number(e.target.value))}
                    className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl font-mono"
                  />
                </div>
                <div>
                  <label className="block font-bold text-slate-700 mb-1">سقف الخصم الأقصى (ل.س)</label>
                  <input
                    type="number"
                    min="1"
                    placeholder="20"
                    value={maxDiscount}
                    onChange={(e) => setMaxDiscount(Number(e.target.value))}
                    className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl font-mono"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block font-bold text-slate-700 mb-1">حد مرات الاستخدام للعميل الواحد</label>
                  <input
                    type="number"
                    min="1"
                    value={perCustomerLimit}
                    onChange={(e) => setPerCustomerLimit(Number(e.target.value))}
                    className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl font-mono font-bold"
                  />
                  <span className="text-[10px] text-slate-400">1 يعني يمنع العميل من تكرار الاستخدام</span>
                </div>
                <div>
                  <label className="block font-bold text-slate-700 mb-1">تاريخ انتهاء الصلاحية</label>
                  <input
                    type="date"
                    value={expiryDate}
                    onChange={(e) => setExpiryDate(e.target.value)}
                    className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl font-mono"
                  />
                </div>
              </div>

              {/* Target Branch Allocation */}
              <div>
                <label className="block font-bold text-slate-700 mb-1">تخصيص الكوبون لفرع محدد</label>
                <select
                  value={targetBranch}
                  onChange={(e) => setTargetBranch(e.target.value)}
                  className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl font-bold"
                >
                  <option value="all">كافة الفروع والمستودعات</option>
                  <option value="b-damascus-hub">فرع دمشق والمنطقة الجنوبية</option>
                  <option value="b-daraa-station">فرع درعا المحطة المركزي</option>
                  <option value="b-daraa-countryside">فرع درعا البلد وريف حوران</option>
                </select>
              </div>

              {/* Anti-Conflict Toggles */}
              <div className="p-3 bg-slate-50 rounded-2xl border border-slate-200 space-y-2">
                <span className="font-bold text-slate-800 block text-[11px]">سياسات منع التضارب المالي:</span>
                <label className="flex items-center gap-2 cursor-pointer text-[11px] text-slate-700">
                  <input
                    type="checkbox"
                    checked={allowWithFlash}
                    onChange={(e) => setAllowWithFlash(e.target.checked)}
                    className="rounded text-blue-600 focus:ring-blue-500 w-3.5 h-3.5"
                  />
                  <span>السماح بتطبيق الكوبون على سلع عروض الفلاش (افتراضياً: ممنوع لمنع الخسارة)</span>
                </label>
                <label className="flex items-center gap-2 cursor-pointer text-[11px] text-slate-700">
                  <input
                    type="checkbox"
                    checked={allowStacking}
                    onChange={(e) => setAllowStacking(e.target.checked)}
                    className="rounded text-blue-600 focus:ring-blue-500 w-3.5 h-3.5"
                  />
                  <span>السماح بدمج أكثر من كوبون في نفس السلة (افتراضياً: ممنوع)</span>
                </label>
              </div>

              <div className="flex justify-end gap-2 pt-3 border-t">
                <button
                  type="button"
                  onClick={() => setIsModalOpen(false)}
                  className="px-4 py-2 bg-slate-100 hover:bg-slate-200 text-slate-600 rounded-xl font-bold"
                >
                  إلغاء
                </button>
                <button
                  type="submit"
                  disabled={coupons.some((c) => c.code === code.trim().toUpperCase()) || !code.trim()}
                  className="px-5 py-2 bg-blue-600 hover:bg-blue-700 disabled:bg-slate-300 disabled:cursor-not-allowed text-white rounded-xl font-bold shadow-md shadow-blue-600/30"
                >
                  حفظ وتفعيل الكوبون
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
