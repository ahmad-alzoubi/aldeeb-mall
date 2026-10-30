import React, { useState } from 'react';
import { 
  Plus, 
  Search, 
  Edit3, 
  Trash2, 
  Barcode, 
  X, 
  Tag
} from 'lucide-react';
import { Product, Category } from '../types';

interface ProductsPageProps {
  products: Product[];
  categories: Category[];
  onAddProduct: (product: Product) => void;
  onDeleteProduct: (productId: string) => void;
}

export const ProductsPage: React.FC<ProductsPageProps> = ({
  products,
  categories,
  onAddProduct,
  onDeleteProduct,
}) => {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);

  // New product form state
  const [nameAr, setNameAr] = useState('');
  const [nameEn, setNameEn] = useState('');
  const [brand, setBrand] = useState('طازج');
  const [barcode, setBarcode] = useState('');
  const [categoryId, setCategoryId] = useState('c1');
  const [price, setPrice] = useState<number>(9.95);
  const [originalPrice, setOriginalPrice] = useState<number>(12.50);
  const [unit, setUnit] = useState('kg');
  const [stockQuantity, setStockQuantity] = useState<number>(150);
  const [imageUrl, setImageUrl] = useState('https://images.unsplash.com/photo-1610348725531-843dff563e2c?auto=format&fit=crop&w=400&q=80');
  const [isDailyDeal, setIsDailyDeal] = useState(true);
  const [isFeatured, setIsFeatured] = useState(true);

  const filteredProducts = products.filter((p) => {
    const matchesCategory = selectedCategory === 'all' || p.category_id === selectedCategory;
    const matchesSearch = 
      p.name_ar.toLowerCase().includes(searchQuery.toLowerCase()) ||
      p.name_en.toLowerCase().includes(searchQuery.toLowerCase()) ||
      (p.brand?.toLowerCase().includes(searchQuery.toLowerCase()) ?? false) ||
      (p.barcode?.includes(searchQuery) ?? false);
    return matchesCategory && matchesSearch;
  });

  const handleCreate = (e: React.FormEvent) => {
    e.preventDefault();
    if (!nameAr.trim()) return;

    const discountPercent = originalPrice > price 
      ? Math.round(((originalPrice - price) / originalPrice) * 100) 
      : 0;

    const newProd: Product = {
      id: `p-${Date.now()}`,
      name_ar: nameAr,
      name_en: nameEn || nameAr,
      brand,
      barcode: barcode || `${Math.floor(100000000000 + Math.random() * 900000000000)}`,
      category_id: categoryId,
      price: Number(price),
      original_price: Number(originalPrice),
      discount_percent: discountPercent,
      unit,
      weight_step: unit === 'kg' ? 0.5 : 1.0,
      stock_quantity: Number(stockQuantity),
      images: [imageUrl],
      is_daily_deal: isDailyDeal,
      is_featured: isFeatured,
      rating: 4.9,
      sales_count: 0,
    };

    onAddProduct(newProd);
    setIsAddModalOpen(false);
    // Reset form
    setNameAr('');
    setNameEn('');
  };

  return (
    <div className="space-y-6">
      {/* Top Bar: Search, Category Filter, and Add Button */}
      <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-sm flex flex-col md:flex-row items-center justify-between gap-4">
        <div className="flex items-center gap-3 w-full md:w-auto">
          {/* Category Dropdown */}
          <select
            value={selectedCategory}
            onChange={(e) => setSelectedCategory(e.target.value)}
            className="px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-bold focus:outline-none focus:border-blue-600"
          >
            <option value="all">كافة الأقسام والتصنيفات</option>
            {categories.map((c) => (
              <option key={c.id} value={c.id}>{c.name_ar}</option>
            ))}
          </select>

          {/* Search */}
          <div className="relative flex-1 md:w-72">
            <input
              type="text"
              placeholder="ابحث بالاسم، الماركة، أو الباركود..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pr-10 pl-4 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-medium focus:outline-none focus:border-blue-600 focus:bg-white"
            />
            <Search className="w-4 h-4 text-slate-400 absolute right-3.5 top-2.5" />
          </div>
        </div>

        {/* Add Product Button */}
        <button
          onClick={() => setIsAddModalOpen(true)}
          className="w-full md:w-auto px-4 py-2.5 bg-blue-600 hover:bg-blue-700 text-white rounded-xl text-xs font-bold transition-all shadow-md shadow-blue-600/20 flex items-center justify-center gap-2"
        >
          <Plus className="w-4 h-4" />
          إضافة صنف جديد للمول
        </button>
      </div>

      {/* Products Table */}
      <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-right">
            <thead className="bg-slate-50/80 border-b border-slate-200 text-slate-500 text-xs font-extrabold">
              <tr>
                <th className="p-4">المنتج والصورة</th>
                <th className="p-4">الباركود والماركة</th>
                <th className="p-4">سعر البيع</th>
                <th className="p-4">السعر الأصلي</th>
                <th className="p-4">الخصم</th>
                <th className="p-4">الكمية بالمخزن</th>
                <th className="p-4">الحالة</th>
                <th className="p-4 text-center">الإجراءات</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 text-xs font-medium text-slate-700">
              {filteredProducts.map((p) => {
                const isLowStock = p.stock_quantity < 25;
                return (
                  <tr key={p.id} className="hover:bg-slate-50/60 transition-colors">
                    <td className="p-4">
                      <div className="flex items-center gap-3">
                        <img
                          src={p.images[0]}
                          alt={p.name_ar}
                          className="w-12 h-12 rounded-xl object-cover border border-slate-200 shadow-xs shrink-0"
                        />
                        <div>
                          <p className="font-extrabold text-slate-900">{p.name_ar}</p>
                          <p className="text-[11px] text-slate-400">{p.name_en}</p>
                        </div>
                      </div>
                    </td>
                    <td className="p-4">
                      <div className="flex items-center gap-1.5 text-slate-600 font-mono text-[11px]">
                        <Barcode className="w-3.5 h-3.5 text-slate-400" />
                        {p.barcode}
                      </div>
                      <span className="text-[10px] text-blue-600 font-bold">{p.brand}</span>
                    </td>
                    <td className="p-4 font-extrabold text-blue-900 text-sm">
                      {p.price.toFixed(2)} د.إ
                      <span className="text-[10px] text-slate-400 font-normal mr-1">/ {p.unit}</span>
                    </td>
                    <td className="p-4 text-slate-400 line-through">
                      {p.original_price ? `${p.original_price.toFixed(2)} د.إ` : '-'}
                    </td>
                    <td className="p-4">
                      {p.discount_percent > 0 ? (
                        <span className="px-2 py-0.5 bg-red-100 text-red-700 rounded-md text-[11px] font-extrabold">
                          {p.discount_percent}% خصم
                        </span>
                      ) : (
                        <span className="text-slate-400">-</span>
                      )}
                    </td>
                    <td className="p-4">
                      <span
                        className={`px-2.5 py-1 rounded-lg text-xs font-extrabold ${
                          isLowStock
                            ? 'bg-rose-100 text-rose-700 animate-pulse'
                            : 'bg-emerald-100 text-emerald-800'
                        }`}
                      >
                        {p.stock_quantity} {p.unit}
                      </span>
                    </td>
                    <td className="p-4">
                      <div className="flex flex-col gap-1">
                        {p.is_daily_deal && (
                          <span className="text-[10px] text-amber-600 font-bold flex items-center gap-1">
                            <Tag className="w-3 h-3" />
                            صفقة يومية
                          </span>
                        )}
                        {p.is_featured && (
                          <span className="text-[10px] text-blue-600 font-bold">مميز بالرئيسية</span>
                        )}
                      </div>
                    </td>
                    <td className="p-4">
                      <div className="flex items-center justify-center gap-1">
                        <button
                          onClick={() => onDeleteProduct(p.id)}
                          className="p-1.5 text-slate-400 hover:text-rose-600 hover:bg-rose-50 rounded-lg transition-colors"
                          title="حذف المنتج"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>

      {/* Add Product Modal */}
      {isAddModalOpen && (
        <div className="fixed inset-0 z-50 bg-black/50 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-xl w-full max-h-[90vh] overflow-y-auto p-6 shadow-2xl space-y-4">
            <div className="flex items-center justify-between border-b pb-3">
              <h3 className="text-base font-extrabold text-slate-900">إضافة صنف ومنتج جديد للمول</h3>
              <button
                onClick={() => setIsAddModalOpen(false)}
                className="p-1 rounded-lg text-slate-400 hover:text-slate-600"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleCreate} className="space-y-4 text-xs font-bold text-slate-700">
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block mb-1">اسم المنتج بالعربية *</label>
                  <input
                    type="text"
                    required
                    placeholder="مثال: أرز بسمتي هندي فاخر 5 كجم"
                    value={nameAr}
                    onChange={(e) => setNameAr(e.target.value)}
                    className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600"
                  />
                </div>
                <div>
                  <label className="block mb-1">اسم المنتج بالإنجليزية</label>
                  <input
                    type="text"
                    placeholder="Premium Basmati Rice 5kg"
                    value={nameEn}
                    onChange={(e) => setNameEn(e.target.value)}
                    className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600"
                  />
                </div>
              </div>

              <div className="grid grid-cols-3 gap-3">
                <div>
                  <label className="block mb-1">القسم</label>
                  <select
                    value={categoryId}
                    onChange={(e) => setCategoryId(e.target.value)}
                    className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600"
                  >
                    {categories.map((c) => (
                      <option key={c.id} value={c.id}>{c.name_ar}</option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="block mb-1">الماركة التجارية</label>
                  <input
                    type="text"
                    value={brand}
                    onChange={(e) => setBrand(e.target.value)}
                    className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600"
                  />
                </div>
                <div>
                  <label className="block mb-1">الباركود</label>
                  <input
                    type="text"
                    placeholder="6291000..."
                    value={barcode}
                    onChange={(e) => setBarcode(e.target.value)}
                    className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600 font-mono"
                  />
                </div>
              </div>

              <div className="grid grid-cols-4 gap-3">
                <div>
                  <label className="block mb-1">سعر العرض (د.إ) *</label>
                  <input
                    type="number"
                    step="0.05"
                    required
                    value={price}
                    onChange={(e) => setPrice(Number(e.target.value))}
                    className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600"
                  />
                </div>
                <div>
                  <label className="block mb-1">السعر الأصلي (د.إ)</label>
                  <input
                    type="number"
                    step="0.05"
                    value={originalPrice}
                    onChange={(e) => setOriginalPrice(Number(e.target.value))}
                    className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600"
                  />
                </div>
                <div>
                  <label className="block mb-1">الوحدة</label>
                  <select
                    value={unit}
                    onChange={(e) => setUnit(e.target.value)}
                    className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600"
                  >
                    <option value="kg">كيلوجرام (kg)</option>
                    <option value="piece">حبة (Piece)</option>
                    <option value="pack">علبة / باكت (Pack)</option>
                    <option value="bottle">زجاجة (Bottle)</option>
                    <option value="carton">كرتون (Carton)</option>
                  </select>
                </div>
                <div>
                  <label className="block mb-1">الكمية بالمستودع</label>
                  <input
                    type="number"
                    value={stockQuantity}
                    onChange={(e) => setStockQuantity(Number(e.target.value))}
                    className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600"
                  />
                </div>
              </div>

              <div>
                <label className="block mb-1">رابط صورة المنتج (URL)</label>
                <input
                  type="url"
                  required
                  value={imageUrl}
                  onChange={(e) => setImageUrl(e.target.value)}
                  className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600"
                />
                {imageUrl && (
                  <div className="mt-2 flex items-center gap-3">
                    <img src={imageUrl} alt="preview" className="w-12 h-12 object-cover rounded-lg border" />
                    <span className="text-[11px] text-slate-400">معاينة الصورة المباشرة</span>
                  </div>
                )}
              </div>

              <div className="flex items-center gap-6 pt-2">
                <label className="flex items-center gap-2 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={isDailyDeal}
                    onChange={(e) => setIsDailyDeal(e.target.checked)}
                    className="rounded text-blue-600 focus:ring-blue-500 w-4 h-4"
                  />
                  <span>إظهار في عروض الصفقات الكبرى (Flash Sale)</span>
                </label>
                <label className="flex items-center gap-2 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={isFeatured}
                    onChange={(e) => setIsFeatured(e.target.checked)}
                    className="rounded text-blue-600 focus:ring-blue-500 w-4 h-4"
                  />
                  <span>منتج مميز بالرئيسية</span>
                </label>
              </div>

              <div className="pt-4 flex justify-end gap-3 border-t">
                <button
                  type="button"
                  onClick={() => setIsAddModalOpen(false)}
                  className="px-4 py-2 bg-slate-100 hover:bg-slate-200 text-slate-600 rounded-xl text-xs font-bold"
                >
                  إلغاء
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-xl text-xs font-bold shadow-md shadow-blue-600/30"
                >
                  حفظ ونشر المنتج فوراً
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
