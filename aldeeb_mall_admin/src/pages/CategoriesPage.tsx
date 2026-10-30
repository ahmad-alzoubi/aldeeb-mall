import React, { useState } from 'react';
import { Plus, Layers, Image as ImageIcon, X } from 'lucide-react';
import { Category } from '../types';

interface CategoriesPageProps {
  categories: Category[];
  onAddCategory: (category: Category) => void;
}

export const CategoriesPage: React.FC<CategoriesPageProps> = ({ categories, onAddCategory }) => {
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [nameAr, setNameAr] = useState('');
  const [nameEn, setNameEn] = useState('');
  const [imageUrl, setImageUrl] = useState('');

  const handleCreate = (e: React.FormEvent) => {
    e.preventDefault();
    if (!nameAr.trim()) return;

    const newCat: Category = {
      id: `c-${Date.now()}`,
      name_ar: nameAr,
      name_en: nameEn || nameAr,
      slug: nameEn.toLowerCase().replace(/\s+/g, '-') || `category-${Date.now()}`,
      icon_name: 'shopping_basket',
      image_url: imageUrl || 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=400&q=80',
      sort_order: categories.length + 1,
      is_active: true,
    };

    onAddCategory(newCat);
    setIsModalOpen(false);
    setNameAr('');
    setNameEn('');
    setImageUrl('');
  };

  return (
    <div className="space-y-6">
      <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-sm flex items-center justify-between">
        <div>
          <h3 className="text-base font-extrabold text-slate-900">أقسام وتصنيفات الهايبرماركت</h3>
          <p className="text-xs text-slate-400">إدارة الأقسام الرئيسية والفرعية وترتيب ظهورها في تطبيق الهاتف والمتجر</p>
        </div>
        <button
          onClick={() => setIsModalOpen(true)}
          className="px-4 py-2.5 bg-blue-600 hover:bg-blue-700 text-white rounded-xl text-xs font-bold transition-all shadow-md shadow-blue-600/20 flex items-center gap-2"
        >
          <Plus className="w-4 h-4" />
          إضافة قسم جديد
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {categories.map((cat, idx) => (
          <div key={cat.id} className="bg-white rounded-2xl border border-slate-200 p-4 shadow-sm flex items-center gap-4 hover:border-blue-400 transition-all">
            <img
              src={cat.image_url || 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=200&q=80'}
              alt={cat.name_ar}
              className="w-16 h-16 rounded-xl object-cover border border-slate-100 shrink-0"
            />
            <div className="flex-1">
              <span className="text-[10px] bg-slate-100 text-slate-600 px-2 py-0.5 rounded font-bold">
                ترتيب: #{idx + 1}
              </span>
              <h4 className="text-sm font-extrabold text-slate-900 mt-1">{cat.name_ar}</h4>
              <p className="text-xs text-slate-400">{cat.name_en}</p>
            </div>
          </div>
        ))}
      </div>

      {isModalOpen && (
        <div className="fixed inset-0 z-50 bg-black/50 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-md w-full p-6 shadow-2xl space-y-4">
            <div className="flex items-center justify-between border-b pb-3">
              <h3 className="text-base font-extrabold text-slate-900">إضافة قسم جديد للمول</h3>
              <button onClick={() => setIsModalOpen(false)} className="text-slate-400 hover:text-slate-600">
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleCreate} className="space-y-4 text-xs font-bold text-slate-700">
              <div>
                <label className="block mb-1">اسم القسم بالعربية *</label>
                <input
                  type="text"
                  required
                  placeholder="مثال: حبوب ومكسرات ومقبلات"
                  value={nameAr}
                  onChange={(e) => setNameAr(e.target.value)}
                  className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600"
                />
              </div>

              <div>
                <label className="block mb-1">اسم القسم بالإنجليزية</label>
                <input
                  type="text"
                  placeholder="Nuts & Snacks"
                  value={nameEn}
                  onChange={(e) => setNameEn(e.target.value)}
                  className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600"
                />
              </div>

              <div>
                <label className="block mb-1">رابط صورة القسم (URL)</label>
                <input
                  type="url"
                  placeholder="https://images.unsplash.com/..."
                  value={imageUrl}
                  onChange={(e) => setImageUrl(e.target.value)}
                  className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600"
                />
              </div>

              <div className="pt-3 flex justify-end gap-2 border-t">
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
                  حفظ ونشر القسم
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
