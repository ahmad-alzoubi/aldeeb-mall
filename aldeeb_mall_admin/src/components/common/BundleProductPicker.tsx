import React, { useState } from 'react';
import { Search, Check, Plus, X, Layers, Sparkles } from 'lucide-react';
import { Product, Category } from '../../types';

interface BundleProductPickerProps {
  allProducts: Product[];
  categories: Category[];
  selectedProductIds: string[];
  onChange: (selectedIds: string[]) => void;
  currentProductId?: string;
  currentCategoryId?: string;
}

export const BundleProductPicker: React.FC<BundleProductPickerProps> = ({
  allProducts,
  categories,
  selectedProductIds,
  onChange,
  currentProductId,
  currentCategoryId,
}) => {
  const [searchQuery, setSearchQuery] = useState('');
  const [filterCategory, setFilterCategory] = useState<string>(currentCategoryId || 'all');

  // Filter out the product itself from suggestions
  const candidateProducts = allProducts.filter(p => p.id !== currentProductId);

  // Filter candidates by category and search
  const filteredCandidates = candidateProducts.filter(p => {
    const matchesCategory = filterCategory === 'all' || p.category_id === filterCategory;
    const matchesQuery = 
      p.name_ar.toLowerCase().includes(searchQuery.toLowerCase()) ||
      p.name_en.toLowerCase().includes(searchQuery.toLowerCase()) ||
      (p.barcode && p.barcode.includes(searchQuery));
    return matchesCategory && matchesQuery;
  });

  const toggleSelect = (productId: string) => {
    if (selectedProductIds.includes(productId)) {
      onChange(selectedProductIds.filter(id => id !== productId));
    } else {
      onChange([...selectedProductIds, productId]);
    }
  };

  const selectedProducts = allProducts.filter(p => selectedProductIds.includes(p.id));

  return (
    <div className="space-y-4 bg-slate-50 p-4 rounded-2xl border border-slate-200" dir="rtl">
      <div className="flex items-center justify-between">
        <div>
          <h4 className="text-xs font-black text-slate-800 flex items-center gap-1.5">
            <Sparkles className="w-4 h-4 text-amber-500" />
            <span>المنتجات المرافقة والمقترحة (اشترِ معاً ووفر)</span>
          </h4>
          <p className="text-[11px] text-slate-500 mt-0.5">
            اختر المنتجات المقترح شراؤها مع هذا الصنف مع عرض صورها وبحث سريع بالتصنيف أو الباركود
          </p>
        </div>
        <span className="text-xs font-extrabold px-2.5 py-1 rounded-xl bg-blue-100 text-blue-800 border border-blue-200">
          تم اختيار ({selectedProductIds.length}) منتجات
        </span>
      </div>

      {/* Selected Products Preview Chips */}
      {selectedProducts.length > 0 && (
        <div className="flex flex-wrap gap-2 p-2.5 bg-white rounded-xl border border-slate-200/80">
          {selectedProducts.map(prod => (
            <div 
              key={prod.id}
              className="flex items-center gap-2 bg-slate-100 text-slate-800 px-2.5 py-1.5 rounded-xl border border-slate-200 text-xs shadow-2xs"
            >
              <img 
                src={prod.images?.[0] || 'https://via.placeholder.com/40'} 
                alt={prod.name_ar} 
                className="w-6 h-6 rounded-lg object-cover" 
              />
              <span className="font-bold max-w-[120px] truncate">{prod.name_ar}</span>
              <span className="text-[10px] font-black text-blue-700">{prod.price.toFixed(2)} ل.س</span>
              <button
                type="button"
                onClick={() => toggleSelect(prod.id)}
                className="w-4 h-4 rounded-full bg-slate-200 hover:bg-rose-200 hover:text-rose-700 text-slate-500 flex items-center justify-center text-[10px] font-bold"
              >
                ✕
              </button>
            </div>
          ))}
        </div>
      )}

      {/* Filter and Search Bar */}
      <div className="flex flex-wrap items-center gap-2">
        <div className="relative flex-1 min-w-[180px]">
          <Search className="w-3.5 h-3.5 text-slate-400 absolute right-3 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            placeholder="ابحث بالاسم، الباركود..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pr-8 pl-3 py-2 rounded-xl bg-white border border-slate-200 text-xs font-medium focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>

        <select
          value={filterCategory}
          onChange={(e) => setFilterCategory(e.target.value)}
          className="bg-white border border-slate-200 text-slate-700 font-bold px-3 py-2 rounded-xl text-xs focus:outline-none focus:ring-2 focus:ring-blue-500"
        >
          <option value="all">كافة الأقسام</option>
          {categories.map(c => (
            <option key={c.id} value={c.id}>{c.name_ar}</option>
          ))}
        </select>
      </div>

      {/* Candidate Products Grid with Images and Click-to-Select */}
      <div className="max-h-48 overflow-y-auto grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-2 pr-1">
        {filteredCandidates.slice(0, 15).map(prod => {
          const isSelected = selectedProductIds.includes(prod.id);
          return (
            <div
              key={prod.id}
              onClick={() => toggleSelect(prod.id)}
              className={`p-2 rounded-xl border flex items-center gap-2.5 cursor-pointer transition-all ${
                isSelected 
                  ? 'bg-blue-50 border-blue-400 ring-1 ring-blue-400' 
                  : 'bg-white border-slate-200 hover:border-slate-300 hover:bg-slate-50/80'
              }`}
            >
              <img 
                src={prod.images?.[0] || 'https://via.placeholder.com/40'} 
                alt={prod.name_ar} 
                className="w-9 h-9 rounded-lg object-cover shrink-0 border border-slate-200" 
              />
              <div className="min-w-0 flex-1">
                <p className="text-[11px] font-bold text-slate-800 truncate">{prod.name_ar}</p>
                <div className="flex items-center justify-between text-[10px] text-slate-500 mt-0.5">
                  <span className="font-mono text-slate-400">{prod.barcode || '—'}</span>
                  <span className="font-black text-blue-700">{prod.price.toFixed(2)} ل.س</span>
                </div>
              </div>
              <div className={`w-5 h-5 rounded-lg flex items-center justify-center shrink-0 text-xs font-bold ${
                isSelected ? 'bg-blue-600 text-white' : 'bg-slate-100 text-slate-400'
              }`}>
                {isSelected ? <Check className="w-3 h-3" /> : <Plus className="w-3 h-3" />}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};
