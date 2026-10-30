import React, { useState } from 'react';
import { 
  Zap, 
  Plus, 
  Clock, 
  Trash2, 
  Percent, 
  Package, 
  TrendingUp,
  Tag,
  AlertCircle
} from 'lucide-react';
import { FlashDeal, Product } from '../types';

interface FlashDealsPageProps {
  deals: FlashDeal[];
  products: Product[];
  onAddDeal: (deal: FlashDeal) => void;
  onDeleteDeal: (dealId: string) => void;
  onToggleDeal: (dealId: string) => void;
}

export const FlashDealsPage: React.FC<FlashDealsPageProps> = ({
  deals,
  products,
  onAddDeal,
  onDeleteDeal,
  onToggleDeal,
}) => {
  const [showAddModal, setShowAddModal] = useState<boolean>(false);
  const [selectedProductId, setSelectedProductId] = useState<string>(products[0]?.id || '');
  const [discountPercent, setDiscountPercent] = useState<number>(30);
  const [quota, setQuota] = useState<number>(100);
  const [durationHours, setDurationHours] = useState<number>(6);

  const selectedProduct = products.find((p) => p.id === selectedProductId) || products[0];
  const calculatedDealPrice = selectedProduct
    ? Number((selectedProduct.price * (1 - discountPercent / 100)).toFixed(2))
    : 0;

  const handleSubmitNewDeal = (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedProduct) return;

    const newDeal: FlashDeal = {
      id: `fd-${Date.now()}`,
      product_id: selectedProduct.id,
      product_name_ar: selectedProduct.name_ar,
      product_image: selectedProduct.images[0] || '',
      original_price: selectedProduct.price,
      deal_price: calculatedDealPrice,
      discount_percent: discountPercent,
      total_quota: quota,
      claimed_quota: 0,
      ends_at: `${String(durationHours).padStart(2, '0')}:00:00`,
      is_active: true,
    };

    onAddDeal(newDeal);
    setShowAddModal(false);
  };

  const totalActiveDeals = deals.filter((d) => d.is_active).length;
  const totalClaims = deals.reduce((sum, d) => sum + d.claimed_quota, 0);

  return (
    <div className="space-y-6">
      {/* Metrics Banner */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="bg-gradient-to-r from-amber-500 to-amber-600 text-white p-5 rounded-xl shadow-sm flex items-center justify-between">
          <div>
            <div className="text-xs font-bold text-amber-100 mb-1">عروض الفلاش النشطة (Noon Yellow Deals)</div>
            <div className="text-3xl font-black">{totalActiveDeals} عروض حية</div>
            <p className="text-xs text-amber-100 mt-1">تظهر في الشريط العلوي لتطبيق العملاء مع عد تنازلي حي</p>
          </div>
          <Zap className="w-10 h-10 text-amber-200 fill-amber-200 opacity-80" />
        </div>

        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm flex items-center justify-between">
          <div>
            <div className="text-xs font-bold text-slate-500 mb-1">إجمالي القطع المحجوزة بالعروض</div>
            <div className="text-3xl font-black text-slate-800">{totalClaims} قطعة</div>
            <p className="text-xs text-emerald-600 font-medium mt-1">✓ نسبة نفاذ الكميات 76%</p>
          </div>
          <TrendingUp className="w-10 h-10 text-emerald-600" />
        </div>

        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm flex flex-col justify-center">
          <button
            onClick={() => setShowAddModal(true)}
            className="w-full py-3 bg-blue-600 hover:bg-blue-700 text-white font-bold rounded-lg transition-colors flex items-center justify-center gap-2 shadow-sm"
          >
            <Plus className="w-5 h-5" />
            إطلاق عرض فلاش جديد
          </button>
        </div>
      </div>

      {/* Flash Deals Cards Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
        {deals.map((deal) => {
          const percentClaimed = Math.min(100, Math.round((deal.claimed_quota / deal.total_quota) * 100));
          return (
            <div
              key={deal.id}
              className={`bg-white rounded-xl border transition-all overflow-hidden shadow-sm ${
                deal.is_active ? 'border-amber-300 ring-1 ring-amber-300' : 'border-slate-200 opacity-60'
              }`}
            >
              {/* Card Header with Timer */}
              <div className="bg-amber-50 px-4 py-2.5 border-b border-amber-200 flex items-center justify-between text-xs">
                <span className="inline-flex items-center gap-1 font-bold text-amber-900">
                  <Zap className="w-3.5 h-3.5 fill-amber-500 text-amber-500" />
                  عرض خاطف محدود
                </span>
                <span className="inline-flex items-center gap-1 font-mono font-bold text-rose-700 bg-rose-100 px-2 py-0.5 rounded">
                  <Clock className="w-3.5 h-3.5" />
                  ينتهي خلال {deal.ends_at}
                </span>
              </div>

              <div className="p-4 flex gap-4">
                <img
                  src={deal.product_image}
                  alt={deal.product_name_ar}
                  className="w-20 h-20 object-cover rounded-lg border border-slate-100 shrink-0"
                />
                <div className="flex-1 min-w-0">
                  <h4 className="font-bold text-slate-800 text-sm line-clamp-2 mb-1">
                    {deal.product_name_ar}
                  </h4>
                  <div className="flex items-baseline gap-2 mb-2">
                    <span className="text-lg font-black text-rose-600">
                      {deal.deal_price.toFixed(2)} د.إ
                    </span>
                    <span className="text-xs text-slate-400 line-through">
                      {deal.original_price.toFixed(2)} د.إ
                    </span>
                    <span className="text-xs bg-rose-50 text-rose-700 border border-rose-200 px-1.5 py-0.5 rounded font-bold">
                      وفر {deal.discount_percent}%
                    </span>
                  </div>

                  {/* Quota Progress Bar */}
                  <div>
                    <div className="flex justify-between text-xs text-slate-500 mb-1">
                      <span>تم بيع: <strong className="text-slate-800">{deal.claimed_quota}</strong> من {deal.total_quota}</span>
                      <span className="font-bold text-amber-700">{percentClaimed}%</span>
                    </div>
                    <div className="w-full bg-slate-100 rounded-full h-2 overflow-hidden">
                      <div
                        className="bg-amber-500 h-2 rounded-full transition-all duration-500"
                        style={{ width: `${percentClaimed}%` }}
                      ></div>
                    </div>
                  </div>
                </div>
              </div>

              {/* Actions Footer */}
              <div className="px-4 py-2.5 bg-slate-50 border-t border-slate-100 flex items-center justify-between text-xs">
                <button
                  onClick={() => onToggleDeal(deal.id)}
                  className={`font-bold px-3 py-1 rounded transition-colors ${
                    deal.is_active
                      ? 'bg-amber-100 text-amber-800 hover:bg-amber-200'
                      : 'bg-slate-200 text-slate-700 hover:bg-slate-300'
                  }`}
                >
                  {deal.is_active ? 'إيقاف مؤقت' : 'تفعيل العرض'}
                </button>
                <button
                  onClick={() => onDeleteDeal(deal.id)}
                  className="text-rose-600 hover:text-rose-700 p-1 rounded hover:bg-rose-50 transition-colors"
                  title="حذف العرض"
                >
                  <Trash2 className="w-4 h-4" />
                </button>
              </div>
            </div>
          );
        })}
      </div>

      {/* Create Flash Deal Modal */}
      {showAddModal && (
        <div className="fixed inset-0 z-50 bg-black/50 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-lg w-full p-6 shadow-2xl border border-slate-200">
            <h3 className="text-lg font-bold text-slate-800 mb-4 flex items-center gap-2">
              <Zap className="w-5 h-5 text-amber-500 fill-amber-500" />
              إعداد حملة عرض فلاش خاطف
            </h3>

            <form onSubmit={handleSubmitNewDeal} className="space-y-4">
              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1">اختر المنتج من الكتالوج</label>
                <select
                  value={selectedProductId}
                  onChange={(e) => setSelectedProductId(e.target.value)}
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-600"
                >
                  {products.map((p) => (
                    <option key={p.id} value={p.id}>
                      {p.name_ar} (السعر الأصلي: {p.price.toFixed(2)} د.إ)
                    </option>
                  ))}
                </select>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">نسبة الخصم (%)</label>
                  <input
                    type="number"
                    min="5"
                    max="90"
                    value={discountPercent}
                    onChange={(e) => setDiscountPercent(Number(e.target.value))}
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-300 rounded-lg text-sm"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">السعر المخفض المحسوب</label>
                  <div className="w-full px-3 py-2 bg-emerald-50 border border-emerald-200 rounded-lg text-sm font-bold text-emerald-800 font-mono">
                    {calculatedDealPrice} د.إ
                  </div>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">الكمية المخصصة للعرض (Quota)</label>
                  <input
                    type="number"
                    min="10"
                    value={quota}
                    onChange={(e) => setQuota(Number(e.target.value))}
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-300 rounded-lg text-sm"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">مدة سريان العرض (بالساعات)</label>
                  <input
                    type="number"
                    min="1"
                    max="72"
                    value={durationHours}
                    onChange={(e) => setDurationHours(Number(e.target.value))}
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-300 rounded-lg text-sm"
                  />
                </div>
              </div>

              <div className="flex justify-end gap-3 pt-4 border-t border-slate-100">
                <button
                  type="button"
                  onClick={() => setShowAddModal(false)}
                  className="px-4 py-2 border border-slate-300 rounded-lg text-sm text-slate-600 hover:bg-slate-50"
                >
                  إلغاء
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 bg-amber-500 hover:bg-amber-600 text-white font-bold rounded-lg text-sm shadow-sm flex items-center gap-1.5"
                >
                  <Zap className="w-4 h-4 fill-white" />
                  بدء العرض الفوري
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
