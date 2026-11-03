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
  AlertCircle,
  Building2,
  CheckCircle2,
  Check,
  X,
  Eye,
  MousePointerClick,
  DollarSign
} from 'lucide-react';
import { FlashDeal, Product, Order } from '../types';
import { logAuditEvent } from '../lib/auditLogger';

interface FlashDealsPageProps {
  deals: FlashDeal[];
  products: Product[];
  orders?: Order[];
  onAddDeal: (deal: FlashDeal) => void;
  onDeleteDeal: (dealId: string) => void;
  onToggleDeal: (dealId: string) => void;
}

export const FlashDealsPage: React.FC<FlashDealsPageProps> = ({
  deals,
  products,
  orders = [],
  onAddDeal,
  onDeleteDeal,
  onToggleDeal,
}) => {
  const [showAddModal, setShowAddModal] = useState<boolean>(false);
  const [selectedProductIds, setSelectedProductIds] = useState<string[]>([products[0]?.id || '']);
  const [discountPercent, setDiscountPercent] = useState<number>(30);
  const [quota, setQuota] = useState<number>(100);
  const [durationHours, setDurationHours] = useState<number>(6);
  const [targetBranch, setTargetBranch] = useState<string>('all');
  const [productSearch, setProductSearch] = useState<string>('');

  // Target branch names
  const branchOptions = [
    { id: 'all', name: 'كافة الفروع والمستودعات' },
    { id: 'b-daraa-station', name: 'فرع درعا المحطة المركزي' },
    { id: 'b-daraa-countryside', name: 'فرع درعا البلد وريف حوران' },
    { id: 'b-damascus-hub', name: 'فرع دمشق والمنطقة الجنوبية' },
  ];

  // Helper to compute real sold units from verified orders
  const getRealUnitsSoldForProduct = (productId: string) => {
    return orders.reduce((sum, o) => {
      if (o.status === 'cancelled') return sum;
      const matched = o.items.filter((i) => i.id === productId);
      return sum + matched.reduce((a, b) => a + b.quantity, 0);
    }, 0);
  };

  const handleSubmitNewDeal = (e: React.FormEvent) => {
    e.preventDefault();
    if (selectedProductIds.length === 0) return;

    selectedProductIds.forEach((prodId) => {
      const prod = products.find((p) => p.id === prodId);
      if (!prod) return;

      const calculatedPrice = Number((prod.price * (1 - discountPercent / 100)).toFixed(2));
      const branchObj = branchOptions.find((b) => b.id === targetBranch);

      const newDeal: FlashDeal = {
        id: `fd-${Date.now()}-${Math.random().toString(36).substring(2, 6)}`,
        product_id: prod.id,
        product_name_ar: prod.name_ar,
        product_image: prod.images[0] || 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=400&q=80',
        original_price: prod.price,
        deal_price: calculatedPrice,
        discount_percent: discountPercent,
        total_quota: quota,
        claimed_quota: 0,
        ends_at: `${String(durationHours).padStart(2, '0')}:00:00`,
        is_active: true,
        branch_id: targetBranch === 'all' ? undefined : targetBranch,
        branch_name: branchObj?.name,
        real_views_count: 0,
        real_clicks_count: 0,
        real_sold_units: 0,
        real_revenue_generated: 0,
      };

      onAddDeal(newDeal);

      logAuditEvent({
        actor_id: 'admin-1',
        actor_name: 'مدير التسويق والعروض',
        actor_role: 'marketing_manager',
        action: 'FLASH_DEAL_CREATED',
        category: 'inventory',
        details: `إطلاق عرض فلاش جديد: ${prod.name_ar} بخصم ${discountPercent}% (${calculatedPrice} ل.س) موجه لـ (${branchObj?.name})`,
        target_id: newDeal.id,
      });
    });

    setShowAddModal(false);
  };

  const totalActiveDeals = deals.filter((d) => d.is_active).length;
  
  // Real aggregates calculated from actual operations
  const totalRealUnitsSold = deals.reduce((sum, d) => {
    const sold = getRealUnitsSoldForProduct(d.product_id) || d.claimed_quota || 0;
    return sum + sold;
  }, 0);

  const totalRealRevenue = deals.reduce((sum, d) => {
    const sold = getRealUnitsSoldForProduct(d.product_id) || d.claimed_quota || 0;
    return sum + (sold * d.deal_price);
  }, 0);

  // Toggle selection in modal
  const handleToggleProductSelection = (id: string) => {
    if (selectedProductIds.includes(id)) {
      if (selectedProductIds.length > 1) {
        setSelectedProductIds(selectedProductIds.filter((pId) => pId !== id));
      }
    } else {
      setSelectedProductIds([...selectedProductIds, id]);
    }
  };

  const filteredCandidateProducts = products.filter((p) =>
    p.name_ar.toLowerCase().includes(productSearch.toLowerCase()) ||
    (p.barcode && p.barcode.includes(productSearch))
  );

  return (
    <div className="space-y-6">
      {/* Metrics Banner */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="bg-gradient-to-r from-amber-500 to-amber-600 text-white p-5 rounded-2xl shadow-sm flex items-center justify-between">
          <div>
            <div className="text-xs font-bold text-amber-100 mb-1">عروض الفلاش الحية</div>
            <div className="text-3xl font-black">{totalActiveDeals} عروض حية</div>
            <p className="text-xs text-amber-100 mt-1">تظهر في الشريط العلوي لتطبيق العملاء مع عد تنازلي حي</p>
          </div>
          <Zap className="w-10 h-10 text-amber-200 fill-amber-200 opacity-80" />
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm flex items-center justify-between">
          <div>
            <div className="text-xs font-bold text-slate-500 mb-1">الوحدات المباعة فعلياً</div>
            <div className="text-3xl font-black text-slate-800 font-mono">{totalRealUnitsSold} قطعة</div>
            <p className="text-xs text-emerald-600 font-medium mt-1">محسوبة من طلبات العملاء الحقيقية</p>
          </div>
          <TrendingUp className="w-9 h-9 text-emerald-600" />
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm flex items-center justify-between">
          <div>
            <div className="text-xs font-bold text-slate-500 mb-1">الإيراد المحقق من العروض</div>
            <div className="text-3xl font-black text-blue-700 font-mono">{totalRealRevenue.toLocaleString()} ل.س</div>
            <p className="text-xs text-slate-400 mt-1">صافي المبيعات بدون تكرار أو مبالغات</p>
          </div>
          <DollarSign className="w-9 h-9 text-blue-600" />
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm flex flex-col justify-center">
          <button
            onClick={() => {
              setSelectedProductIds([products[0]?.id || '']);
              setShowAddModal(true);
            }}
            className="w-full py-3.5 bg-blue-600 hover:bg-blue-700 text-white font-bold rounded-xl transition-colors flex items-center justify-center gap-2 shadow-md shadow-blue-600/30 text-xs"
          >
            <Plus className="w-4 h-4" />
            إطلاق عرض فلاش جديد
          </button>
        </div>
      </div>

      {/* Flash Deals Cards Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
        {deals.map((deal) => {
          const realSold = getRealUnitsSoldForProduct(deal.product_id) || deal.claimed_quota || 0;
          const percentClaimed = Math.min(100, Math.round((realSold / deal.total_quota) * 100));
          const realRev = realSold * deal.deal_price;

          return (
            <div
              key={deal.id}
              className={`bg-white rounded-2xl border transition-all overflow-hidden shadow-sm ${
                deal.is_active ? 'border-amber-300 ring-1 ring-amber-300/50' : 'border-slate-200 opacity-60'
              }`}
            >
              {/* Card Header with Timer & Target Branch */}
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

              {/* Product Info */}
              <div className="p-4 space-y-3">
                <div className="flex gap-3">
                  <img
                    src={deal.product_image}
                    alt={deal.product_name_ar}
                    className="w-16 h-16 object-cover rounded-xl border border-slate-100 shrink-0"
                  />
                  <div className="flex-1 min-w-0">
                    <h4 className="font-bold text-slate-900 text-sm truncate">{deal.product_name_ar}</h4>
                    <div className="flex items-center gap-1.5 mt-0.5 text-[11px] text-slate-500">
                      <Building2 className="w-3 h-3 text-slate-400" />
                      <span>{deal.branch_name || 'كافة الفروع'}</span>
                    </div>
                    <div className="flex items-baseline gap-2 mt-1">
                      <span className="text-base font-black text-rose-600 font-mono">{deal.deal_price.toFixed(2)} ل.س</span>
                      <span className="text-xs text-slate-400 line-through font-mono">{deal.original_price.toFixed(2)}</span>
                      <span className="text-[10px] bg-rose-100 text-rose-800 font-extrabold px-1.5 py-0.2 rounded">
                        وفر {deal.discount_percent}%
                      </span>
                    </div>
                  </div>
                </div>

                {/* Quota Progress */}
                <div className="space-y-1">
                  <div className="flex justify-between text-xs text-slate-600 font-medium">
                    <span>الكمية المحجوزة والمباعة:</span>
                    <span className="font-bold font-mono text-slate-900">
                      {realSold} من أصل {deal.total_quota} قطعة
                    </span>
                  </div>
                  <div className="w-full bg-slate-100 rounded-full h-2 overflow-hidden">
                    <div
                      className="bg-amber-500 h-2 rounded-full transition-all"
                      style={{ width: `${percentClaimed}%` }}
                    />
                  </div>
                </div>

                {/* Real Metrics Row */}
                <div className="grid grid-cols-2 gap-2 pt-2 border-t border-slate-100 text-[11px]">
                  <div className="bg-slate-50 p-2 rounded-xl text-center">
                    <span className="text-slate-400 block text-[10px]">الإيراد الفعلي</span>
                    <span className="font-mono font-bold text-blue-700">{realRev.toLocaleString()} ل.س</span>
                  </div>
                  <div className="bg-slate-50 p-2 rounded-xl text-center">
                    <span className="text-slate-400 block text-[10px]">نسبة استهلاك الحصة</span>
                    <span className="font-mono font-bold text-amber-700">{percentClaimed}%</span>
                  </div>
                </div>

                {/* Actions */}
                <div className="flex items-center justify-between pt-2 border-t border-slate-100">
                  <button
                    onClick={() => onToggleDeal(deal.id)}
                    className={`text-xs px-3 py-1 rounded-xl font-bold transition-colors ${
                      deal.is_active
                        ? 'bg-amber-100 text-amber-900 hover:bg-amber-200'
                        : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
                    }`}
                  >
                    {deal.is_active ? 'العرض نشط الآن' : 'العرض متوقف'}
                  </button>

                  <button
                    onClick={() => onDeleteDeal(deal.id)}
                    className="p-1.5 text-slate-400 hover:text-rose-600 rounded-lg hover:bg-rose-50 transition-colors"
                    title="حذف العرض"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {/* MODAL: Launch Flash Deal with Multi-Product & Branch Targeting */}
      {showAddModal && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl max-w-xl w-full p-6 shadow-2xl border border-slate-200 max-h-[90vh] overflow-y-auto">
            <h3 className="text-lg font-bold text-slate-900 mb-3 flex items-center gap-2">
              <Zap className="w-5 h-5 text-amber-500 fill-amber-500" />
              إطلاق عرض فلاش خاطف جديد (Flash Sale)
            </h3>

            <form onSubmit={handleSubmitNewDeal} className="space-y-4 text-xs">
              {/* Target Branch */}
              <div>
                <label className="block font-bold text-slate-700 mb-1">الفرع المستهدف بالعرض الخاطف *</label>
                <select
                  value={targetBranch}
                  onChange={(e) => setTargetBranch(e.target.value)}
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-300 rounded-xl font-bold"
                >
                  {branchOptions.map((b) => (
                    <option key={b.id} value={b.id}>
                      {b.name}
                    </option>
                  ))}
                </select>
              </div>

              {/* Multi-product Selector */}
              <div>
                <div className="flex justify-between items-center mb-1">
                  <label className="font-bold text-slate-700">
                    اختر المنتجات المشمولة بالعرض ({selectedProductIds.length} محددة)
                  </label>
                  <input
                    type="text"
                    placeholder="تصفية الأصناف بالاسم أو الباركود..."
                    value={productSearch}
                    onChange={(e) => setProductSearch(e.target.value)}
                    className="px-2.5 py-1 text-[11px] bg-slate-50 border border-slate-200 rounded-lg"
                  />
                </div>

                <div className="max-h-48 overflow-y-auto border border-slate-200 rounded-xl p-2 space-y-1.5 divide-y divide-slate-100">
                  {filteredCandidateProducts.slice(0, 30).map((prod) => {
                    const isSelected = selectedProductIds.includes(prod.id);
                    return (
                      <div
                        key={prod.id}
                        onClick={() => handleToggleProductSelection(prod.id)}
                        className={`flex items-center justify-between p-2 rounded-xl cursor-pointer transition-colors ${
                          isSelected ? 'bg-amber-50 border border-amber-200' : 'hover:bg-slate-50'
                        }`}
                      >
                        <div className="flex items-center gap-2 min-w-0">
                          <img
                            src={prod.images[0] || 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=400&q=80'}
                            alt=""
                            className="w-8 h-8 rounded-lg object-cover border"
                          />
                          <div className="truncate">
                            <span className="font-bold text-slate-900 block truncate">{prod.name_ar}</span>
                            <span className="text-[10px] text-slate-400 font-mono">{prod.barcode || 'بدون باركود'}</span>
                          </div>
                        </div>

                        <div className="flex items-center gap-3 shrink-0">
                          <span className="font-mono font-bold text-slate-800">{prod.price.toFixed(2)} ل.س</span>
                          <div className={`w-5 h-5 rounded-md flex items-center justify-center border ${
                            isSelected ? 'bg-amber-500 border-amber-500 text-white' : 'border-slate-300'
                          }`}>
                            {isSelected && <Check className="w-3.5 h-3.5" />}
                          </div>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>

              {/* Discount, Quota, Duration */}
              <div className="grid grid-cols-3 gap-3">
                <div>
                  <label className="block font-bold text-slate-700 mb-1">نسبة الخصم (%) *</label>
                  <input
                    type="number"
                    min="5"
                    max="90"
                    required
                    value={discountPercent}
                    onChange={(e) => setDiscountPercent(Number(e.target.value))}
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-300 rounded-xl font-bold font-mono"
                  />
                </div>
                <div>
                  <label className="block font-bold text-slate-700 mb-1">الحصة المخصصة (قطع) *</label>
                  <input
                    type="number"
                    min="10"
                    required
                    value={quota}
                    onChange={(e) => setQuota(Number(e.target.value))}
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-300 rounded-xl font-bold font-mono"
                  />
                </div>
                <div>
                  <label className="block font-bold text-slate-700 mb-1">المدة بالساعات *</label>
                  <input
                    type="number"
                    min="1"
                    max="72"
                    required
                    value={durationHours}
                    onChange={(e) => setDurationHours(Number(e.target.value))}
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-300 rounded-xl font-bold font-mono"
                  />
                </div>
              </div>

              {/* Live Flash Deal Preview */}
              {selectedProductIds.length > 0 && (() => {
                const previewProd = products.find((p) => p.id === selectedProductIds[0]);
                if (!previewProd) return null;
                const calcPrice = Number((previewProd.price * (1 - discountPercent / 100)).toFixed(2));
                return (
                  <div className="p-3 bg-gradient-to-r from-amber-50 to-orange-50 rounded-2xl border border-amber-200 space-y-2">
                    <span className="text-[10px] font-extrabold text-amber-900 flex items-center gap-1">
                      <Zap className="w-3.5 h-3.5 text-amber-600 fill-amber-600" />
                      معاينة حية لبطاقة العرض الخاطف للمستخدمين:
                    </span>
                    <div className="flex items-center gap-3 bg-white p-2.5 rounded-xl border border-amber-100 shadow-2xs">
                      <img
                        src={previewProd.images[0] || 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=400&q=80'}
                        alt=""
                        className="w-12 h-12 rounded-lg object-cover border"
                      />
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center justify-between">
                          <p className="font-extrabold text-slate-900 truncate text-xs">{previewProd.name_ar}</p>
                          <span className="bg-rose-500 text-white text-[10px] font-black px-1.5 py-0.5 rounded-md">
                            -{discountPercent}%
                          </span>
                        </div>
                        <div className="flex items-baseline gap-2 mt-1">
                          <span className="font-mono font-black text-rose-600 text-xs">{calcPrice.toFixed(2)} ل.س</span>
                          <span className="line-through text-slate-400 text-[10px] font-mono">{previewProd.price.toFixed(2)} ل.س</span>
                        </div>
                        <p className="text-[9px] text-slate-500 mt-0.5">
                          الحصة: {quota} قطعة • المدة: {durationHours} ساعة
                        </p>
                      </div>
                    </div>
                  </div>
                );
              })()}

              <div className="flex justify-end gap-2 pt-4 border-t border-slate-100">
                <button
                  type="button"
                  onClick={() => setShowAddModal(false)}
                  className="px-4 py-2 border border-slate-300 rounded-xl font-bold text-slate-600 hover:bg-slate-50"
                >
                  إلغاء
                </button>
                <button
                  type="submit"
                  disabled={selectedProductIds.length === 0}
                  className="px-5 py-2 bg-amber-500 hover:bg-amber-600 disabled:opacity-50 text-white font-bold rounded-xl shadow-md shadow-amber-500/30 flex items-center gap-1.5"
                >
                  <Zap className="w-4 h-4 fill-white" />
                  إطلاق العروض الآن
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
