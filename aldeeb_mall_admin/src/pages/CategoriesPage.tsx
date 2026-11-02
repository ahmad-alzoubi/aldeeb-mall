import React, { useState } from 'react';
import { 
  Plus, 
  Layers, 
  Image as ImageIcon, 
  X, 
  Edit3, 
  Trash2, 
  Eye, 
  EyeOff, 
  Search, 
  CheckCircle2,
  Sparkles,
  LayoutGrid,
  CreditCard
} from 'lucide-react';
import { Category } from '../types';
import { generateUUID, ensureUUID } from '../lib/uuidUtils';

interface CategoriesPageProps {
  categories: Category[];
  onAddCategory: (category: Category) => void;
  onUpdateCategory?: (category: Category) => void;
  onDeleteCategory?: (categoryId: string) => void;
  onToggleCategory?: (categoryId: string) => void;
}

export const CategoriesPage: React.FC<CategoriesPageProps> = ({ 
  categories, 
  onAddCategory,
  onUpdateCategory,
  onDeleteCategory,
  onToggleCategory,
}) => {
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingCategory, setEditingCategory] = useState<Category | null>(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedGroup, setSelectedGroup] = useState('all');
  const [displayMode, setDisplayMode] = useState<'withTitle' | 'imageOnly'>('withTitle');
  const [toastMessage, setToastMessage] = useState<string | null>(null);

  // Form State
  const [nameAr, setNameAr] = useState('');
  const [nameEn, setNameEn] = useState('');
  const [imageUrl, setImageUrl] = useState('');
  const [slug, setSlug] = useState('');
  const [groupTag, setGroupTag] = useState('food_fresh');
  const [showTitle, setShowTitle] = useState(true);

  const presets = [
    { label: 'وجبات طازجة 🍲', url: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=400&q=80' },
    { label: 'خضار وفواكه 🍎', url: 'https://images.unsplash.com/photo-1610348725531-843dff563e2c?auto=format&fit=crop&w=400&q=80' },
    { label: 'ألبان وبيض 🥛', url: 'https://images.unsplash.com/photo-1550583724-b2692b85b150?auto=format&fit=crop&w=400&q=80' },
    { label: 'سوبرماركت 🛒', url: 'https://images.unsplash.com/photo-1578916171728-46686eac8d58?auto=format&fit=crop&w=400&q=80' },
    { label: 'مشروبات 🥤', url: 'https://images.unsplash.com/photo-1527661591475-527312dd65f5?auto=format&fit=crop&w=400&q=80' },
    { label: 'عناية وجمال 🧴', url: 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?auto=format&fit=crop&w=400&q=80' },
    { label: 'سيارات 🚗', url: 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?auto=format&fit=crop&w=400&q=80' },
    { label: 'ملابس 👕', url: 'https://images.unsplash.com/photo-1489987707025-afc232f7ea0f?auto=format&fit=crop&w=400&q=80' },
    { label: 'أطفال 👶', url: 'https://images.unsplash.com/photo-1515488042361-ee00e0ddd4e4?auto=format&fit=crop&w=400&q=80' },
    { label: 'منزل وحديقة 🏡', url: 'https://images.unsplash.com/photo-1513694203232-719a280e022f?auto=format&fit=crop&w=400&q=80' },
    { label: 'رياضة 🏋️', url: 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?auto=format&fit=crop&w=400&q=80' },
  ];

  const categoryGroups = [
    { id: 'all', title: 'كافة الأقسام 🗂️' },
    { id: 'food_fresh', title: 'أطعمة وطازج 🥗' },
    { id: 'groceries', title: 'مؤونة وسوبرماركت 🛒' },
    { id: 'care', title: 'عناية وأطفال 👶' },
    { id: 'home_tech', title: 'منزل وتنظيف وسيارات 🏡' },
    { id: 'fashion', title: 'أزياء وإكسسوارات 👕' },
    { id: 'lifestyle', title: 'رياضة وقرطاسية وألعاب ⚽' },
  ];

  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(null), 3000);
  };

  const handleOpenAdd = () => {
    setEditingCategory(null);
    setNameAr('');
    setNameEn('');
    setSlug('');
    setGroupTag('food_fresh');
    setShowTitle(true);
    setImageUrl('https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=400&q=80');
    setIsModalOpen(true);
  };

  const handleOpenEdit = (category: Category) => {
    setEditingCategory(category);
    setNameAr(category.name_ar);
    setNameEn(category.name_en);
    setSlug(category.slug);
    setGroupTag(category.group_tag || 'food_fresh');
    setShowTitle(category.show_title !== false);
    setImageUrl(category.image_url || '');
    setIsModalOpen(true);
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!nameAr.trim()) return;

    if (editingCategory && onUpdateCategory) {
      const updated: Category = {
        ...editingCategory,
        id: ensureUUID(editingCategory.id),
        name_ar: nameAr,
        name_en: nameEn || nameAr,
        slug: slug.trim() || nameEn.toLowerCase().replace(/\s+/g, '-') || editingCategory.slug,
        image_url: imageUrl || 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=400&q=80',
        group_tag: groupTag,
        show_title: showTitle,
      };
      onUpdateCategory(updated);
      showToast('تم تعديل بيانات وخيارات عرض القسم بنجاح!');
    } else {
      const newCat: Category = {
        id: generateUUID(),
        name_ar: nameAr,
        name_en: nameEn || nameAr,
        slug: slug.trim() || nameEn.toLowerCase().replace(/\s+/g, '-') || `category-${Date.now()}`,
        icon_name: 'shopping_basket',
        image_url: imageUrl || 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=400&q=80',
        sort_order: categories.length + 1,
        is_active: true,
        group_tag: groupTag,
        show_title: showTitle,
        item_count: 50,
      };
      onAddCategory(newCat);
      showToast('تمت إضافة القسم الجديد بنجاح!');
    }

    setIsModalOpen(false);
  };

  const filteredCategories = categories.filter((c) => {
    const matchesGroup = selectedGroup === 'all' || c.group_tag === selectedGroup;
    if (!matchesGroup) return false;

    if (!searchQuery.trim()) return true;
    const q = searchQuery.toLowerCase().trim();
    return c.name_ar.toLowerCase().includes(q) || c.name_en.toLowerCase().includes(q);
  });

  return (
    <div className="space-y-6">
      {/* Toast Alert */}
      {toastMessage && (
        <div className="bg-emerald-600 text-white px-5 py-3 rounded-2xl shadow-xl flex items-center gap-3 animate-fade-in text-sm font-bold">
          <CheckCircle2 className="w-5 h-5 flex-shrink-0" />
          <span>{toastMessage}</span>
        </div>
      )}

      {/* Header */}
      <div className="bg-white p-6 rounded-3xl border border-slate-200/80 shadow-sm flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <span className="p-2.5 bg-blue-50 text-blue-600 rounded-2xl">
              <Layers className="w-6 h-6" />
            </span>
            <h1 className="text-2xl font-black text-slate-900">
              أقسام وتصنيفات الهايبرماركت
            </h1>
            <span className="px-2.5 py-1 bg-emerald-50 text-emerald-700 text-xs font-black rounded-xl border border-emerald-200">
              {categories.length} قسماً معتمداً
            </span>
          </div>
          <p className="text-slate-500 text-xs md:text-sm mt-1">
            إدارة كافة الأقسام (طازجة ومبردة، سوبرماركت، عناية شخصية، أطفال، تنظيف، سيارات، ملابس، وغيرها) مع التحكم بنمط العرض (صورة مع عنوان / صورة فقط)
          </p>
        </div>

        <div className="flex flex-wrap items-center gap-3">
          {/* Display Mode Switcher */}
          <div className="flex items-center bg-slate-100 p-1 rounded-2xl border border-slate-200 text-xs font-bold text-slate-600">
            <button
              onClick={() => setDisplayMode('withTitle')}
              className={`px-3 py-1.5 rounded-xl transition-all flex items-center gap-1.5 ${
                displayMode === 'withTitle' ? 'bg-white text-blue-600 shadow-xs font-black' : 'hover:text-slate-900'
              }`}
            >
              <CreditCard className="w-3.5 h-3.5" />
              صورة وعنوان
            </button>
            <button
              onClick={() => setDisplayMode('imageOnly')}
              className={`px-3 py-1.5 rounded-xl transition-all flex items-center gap-1.5 ${
                displayMode === 'imageOnly' ? 'bg-white text-blue-600 shadow-xs font-black' : 'hover:text-slate-900'
              }`}
            >
              <LayoutGrid className="w-3.5 h-3.5" />
              صورة فقط
            </button>
          </div>

          <div className="relative">
            <Search className="w-4 h-4 text-slate-400 absolute right-3 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              placeholder="بحث في الأقسام..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="pl-4 pr-9 py-2.5 bg-slate-50 border border-slate-200 rounded-2xl text-xs font-bold focus:outline-none focus:border-blue-600 w-44 md:w-56"
            />
          </div>

          <button
            onClick={handleOpenAdd}
            className="px-5 py-2.5 bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-700 hover:to-teal-700 text-white rounded-2xl text-xs font-black shadow-lg shadow-emerald-500/20 transition-all flex items-center gap-2 whitespace-nowrap"
          >
            <Plus className="w-4 h-4" />
            إضافة قسم جديد
          </button>
        </div>
      </div>

      {/* Filter Chips Bar */}
      <div className="flex items-center gap-2 overflow-x-auto pb-1">
        {categoryGroups.map((grp) => {
          const isSel = selectedGroup === grp.id;
          return (
            <button
              key={grp.id}
              onClick={() => setSelectedGroup(grp.id)}
              className={`px-4 py-2 rounded-2xl text-xs font-bold whitespace-nowrap transition-all border ${
                isSel
                  ? 'bg-blue-600 text-white border-blue-600 shadow-sm'
                  : 'bg-white text-slate-600 border-slate-200 hover:border-slate-300'
              }`}
            >
              {grp.title}
            </button>
          );
        })}
      </div>

      {/* Categories Grid */}
      <div className={`grid gap-5 ${
        displayMode === 'imageOnly' 
          ? 'grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-6'
          : 'grid-cols-1 md:grid-cols-2 lg:grid-cols-3'
      }`}>
        {filteredCategories.map((cat, idx) => {
          const isPureImage = displayMode === 'imageOnly' || cat.show_title === false;

          if (isPureImage) {
            return (
              <div 
                key={cat.id} 
                className="group relative rounded-3xl overflow-hidden border border-slate-200/80 aspect-4/5 shadow-xs hover:shadow-lg transition-all hover:scale-[1.02] cursor-pointer"
                onClick={() => handleOpenEdit(cat)}
              >
                <img
                  src={cat.image_url || 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=400&q=80'}
                  alt={cat.name_ar}
                  className="w-full h-full object-cover"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-black/20 opacity-0 group-hover:opacity-100 transition-all flex flex-col justify-between p-3">
                  <span className="text-[10px] bg-white/90 text-slate-900 px-2 py-0.5 rounded-full font-black self-end">
                    #{idx + 1}
                  </span>
                  <div>
                    <h4 className="text-white text-xs font-black truncate">{cat.name_ar}</h4>
                    <p className="text-white/80 text-[10px] truncate">{cat.name_en}</p>
                  </div>
                </div>
              </div>
            );
          }

          return (
            <div 
              key={cat.id} 
              className={`bg-white rounded-3xl border p-4 shadow-sm flex items-center gap-4 transition-all hover:border-blue-400 hover:shadow-md ${
                cat.is_active ? 'border-slate-200' : 'border-slate-200 opacity-60 bg-slate-50'
              }`}
            >
              <div className="relative shrink-0">
                <img
                  src={cat.image_url || 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=200&q=80'}
                  alt={cat.name_ar}
                  className="w-20 h-20 rounded-2xl object-cover border border-slate-100 shadow-xs"
                />
                <span className="absolute -top-1.5 -right-1.5 w-6 h-6 rounded-full bg-slate-900 text-white flex items-center justify-center text-[10px] font-black border-2 border-white shadow-xs">
                  #{idx + 1}
                </span>
              </div>

              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2">
                  <span className={`text-[10px] px-2 py-0.5 rounded-full font-bold ${
                    cat.is_active ? 'bg-emerald-50 text-emerald-700 border border-emerald-200' : 'bg-slate-100 text-slate-500'
                  }`}>
                    {cat.is_active ? 'نشط في التطبيق' : 'معطل مؤقتاً'}
                  </span>
                  {cat.show_title === false && (
                    <span className="text-[10px] bg-amber-50 text-amber-700 px-2 py-0.5 rounded-full font-bold border border-amber-200">
                      صورة فقط
                    </span>
                  )}
                </div>
                <h4 className="text-sm font-black text-slate-900 mt-1 truncate">{cat.name_ar}</h4>
                <p className="text-xs text-slate-400 truncate">{cat.name_en}</p>
              </div>

              {/* Actions */}
              <div className="flex flex-col gap-1.5 shrink-0">
                <button
                  onClick={() => handleOpenEdit(cat)}
                  className="p-2 hover:bg-blue-50 text-slate-400 hover:text-blue-600 rounded-xl transition-all"
                  title="تعديل بيانات القسم وخيارات العرض"
                >
                  <Edit3 className="w-4 h-4" />
                </button>

                {onToggleCategory && (
                  <button
                    onClick={() => {
                      onToggleCategory(cat.id);
                      showToast(cat.is_active ? 'تم إخفاء القسم من المتجر' : 'تم تنشيط القسم');
                    }}
                    className={`p-2 rounded-xl transition-all ${
                      cat.is_active ? 'hover:bg-slate-100 text-slate-400' : 'hover:bg-emerald-50 text-emerald-600'
                    }`}
                    title={cat.is_active ? 'إخفاء القسم' : 'إظهار القسم'}
                  >
                    {cat.is_active ? <Eye className="w-4 h-4" /> : <EyeOff className="w-4 h-4" />}
                  </button>
                )}

                {onDeleteCategory && (
                  <button
                    onClick={() => {
                      if (confirm(`هل أنت متأكد من حذف قسم "${cat.name_ar}"؟`)) {
                        onDeleteCategory(cat.id);
                        showToast('تم حذف القسم بنجاح');
                      }
                    }}
                    className="p-2 hover:bg-red-50 text-slate-400 hover:text-red-600 rounded-xl transition-all"
                    title="حذف القسم"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                )}
              </div>
            </div>
          );
        })}
      </div>

      {/* Modal */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl max-w-lg w-full p-6 shadow-2xl space-y-4 border border-slate-100 max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between border-b pb-3">
              <h3 className="text-base font-black text-slate-900">
                {editingCategory ? 'تعديل قسم الهايبرماركت' : 'إضافة قسم جديد للمول'}
              </h3>
              <button onClick={() => setIsModalOpen(false)} className="text-slate-400 hover:text-slate-600 p-1">
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleSubmit} className="space-y-4 text-xs font-bold text-slate-700">
              <div>
                <label className="block mb-1 text-slate-600">اسم القسم بالعربية *</label>
                <input
                  type="text"
                  required
                  placeholder="مثال: أكسسوارات سيارات ومستلزمات القيادة"
                  value={nameAr}
                  onChange={(e) => setNameAr(e.target.value)}
                  className="w-full p-3 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600"
                />
              </div>

              <div>
                <label className="block mb-1 text-slate-600">اسم القسم بالإنجليزية</label>
                <input
                  type="text"
                  placeholder="Car Accessories & Care"
                  value={nameEn}
                  onChange={(e) => setNameEn(e.target.value)}
                  className="w-full p-3 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600 text-left"
                  dir="ltr"
                />
              </div>

              <div>
                <label className="block mb-1 text-slate-600">المعرف اللطيف (Slug)</label>
                <input
                  type="text"
                  placeholder="car-accessories"
                  value={slug}
                  onChange={(e) => setSlug(e.target.value)}
                  className="w-full p-3 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600 text-left"
                  dir="ltr"
                />
              </div>

              <div>
                <label className="block mb-1 text-slate-600">المجموعة والتصنيف الرئيسي</label>
                <select
                  value={groupTag}
                  onChange={(e) => setGroupTag(e.target.value)}
                  className="w-full p-3 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600"
                >
                  <option value="food_fresh">أطعمة وطازج 🥗</option>
                  <option value="groceries">مؤونة وسوبرماركت 🛒</option>
                  <option value="care">عناية وأطفال 👶</option>
                  <option value="home_tech">منزل وتنظيف وسيارات 🏡</option>
                  <option value="fashion">أزياء وإكسسوارات 👕</option>
                  <option value="lifestyle">رياضة وقرطاسية وألعاب ⚽</option>
                </select>
              </div>

              <div>
                <label className="block mb-1 text-slate-600">اختيار صورة سريعة للقسم:</label>
                <div className="flex flex-wrap gap-2 mb-2">
                  {presets.map((p) => (
                    <button
                      key={p.label}
                      type="button"
                      onClick={() => setImageUrl(p.url)}
                      className="px-2.5 py-1 bg-slate-100 hover:bg-blue-50 text-[11px] rounded-lg text-slate-700 hover:text-blue-600 border border-slate-200"
                    >
                      {p.label}
                    </button>
                  ))}
                </div>

                <label className="block mb-1 text-slate-600">رابط صورة القسم (URL مباشر)</label>
                <input
                  type="url"
                  placeholder="https://images.unsplash.com/..."
                  value={imageUrl}
                  onChange={(e) => setImageUrl(e.target.value)}
                  className="w-full p-3 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600 text-left"
                  dir="ltr"
                />
                {imageUrl && (
                  <div className="mt-2 h-24 w-full rounded-xl overflow-hidden border border-slate-200">
                    <img src={imageUrl} alt="معاينة" className="w-full h-full object-cover" />
                  </div>
                )}
              </div>

              {/* Show Title Checkbox */}
              <div className="bg-slate-50 p-3 rounded-xl border border-slate-200 flex items-center justify-between">
                <div>
                  <span className="block font-black text-slate-800">إظهار عنوان القسم أسفل الصورة</span>
                  <span className="text-[11px] text-slate-400">عند إلغاء التفعيل ستظهر صورة القسم فقط كبطاقة بصرية</span>
                </div>
                <input
                  type="checkbox"
                  checked={showTitle}
                  onChange={(e) => setShowTitle(e.target.checked)}
                  className="w-4 h-4 text-blue-600 rounded focus:ring-blue-500"
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
                  className="px-5 py-2 bg-emerald-600 hover:bg-emerald-700 text-white rounded-xl text-xs font-black shadow-md shadow-emerald-600/30"
                >
                  {editingCategory ? 'حفظ التعديلات' : 'حفظ ونشر القسم'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
