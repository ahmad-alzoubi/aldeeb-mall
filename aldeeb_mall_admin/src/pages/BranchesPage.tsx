import React, { useState, useEffect } from 'react';
import { 
  Building2, 
  MapPin, 
  Plus, 
  Search, 
  Store, 
  Monitor, 
  DollarSign, 
  Phone, 
  UserCheck, 
  CheckCircle2, 
  X, 
  SlidersHorizontal,
  ExternalLink,
  Edit2,
  Trash2,
  TrendingUp,
  Warehouse
} from 'lucide-react';
import { Branch } from '../types';
import { 
  getStoredBranches, 
  saveStoredBranches, 
  getActiveBranchId, 
  setActiveBranchId 
} from '../lib/branchesData';

interface BranchesPageProps {
  onOpenPosForBranch?: (branchId: string) => void;
}

export const BranchesPage: React.FC<BranchesPageProps> = ({ onOpenPosForBranch }) => {
  const [branches, setBranches] = useState<Branch[]>([]);
  const [activeBranchId, setActiveId] = useState<string>('');
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCity, setSelectedCity] = useState<string>('all');
  const [selectedType, setSelectedType] = useState<string>('all');

  // Modal State
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingBranch, setEditingBranch] = useState<Branch | null>(null);

  // Form State
  const [formData, setFormData] = useState({
    code: '',
    name_ar: '',
    name_en: '',
    city: 'الرياض',
    district: '',
    address: '',
    phone: '',
    manager_name: '',
    type: 'hypermarket' as Branch['type'],
    terminals_count: 4,
    daily_sales: 0,
    currency: 'ل.س',
    is_active: true,
  });

  const [notification, setNotification] = useState<string | null>(null);

  useEffect(() => {
    const list = getStoredBranches();
    setBranches(list);
    setActiveId(getActiveBranchId());
  }, []);

  const showNotification = (msg: string) => {
    setNotification(msg);
    setTimeout(() => setNotification(null), 3000);
  };

  const handleSelectActiveBranch = (id: string) => {
    setActiveBranchId(id);
    setActiveId(id);
    showNotification('تم تبديل الفرع النشط في النظام بنجاح!');
  };

  const handleOpenModal = (branch?: Branch) => {
    if (branch) {
      setEditingBranch(branch);
      setFormData({
        code: branch.code,
        name_ar: branch.name_ar,
        name_en: branch.name_en,
        city: branch.city,
        district: branch.district,
        address: branch.address,
        phone: branch.phone,
        manager_name: branch.manager_name,
        type: branch.type,
        terminals_count: branch.terminals_count,
        daily_sales: branch.daily_sales,
        currency: branch.currency,
        is_active: branch.is_active,
      });
    } else {
      setEditingBranch(null);
      const nextNum = branches.length + 1;
      setFormData({
        code: `BR-NEW-0${nextNum}`,
        name_ar: '',
        name_en: '',
        city: 'الرياض',
        district: '',
        address: '',
        phone: '+966 ',
        manager_name: '',
        type: 'supermarket',
        terminals_count: 4,
        daily_sales: 0,
        currency: 'ل.س',
        is_active: true,
      });
    }
    setIsModalOpen(true);
  };

  const handleSaveBranch = (e: React.FormEvent) => {
    e.preventDefault();
    if (!formData.name_ar.trim()) return;

    if (editingBranch) {
      const updated = branches.map((b) =>
        b.id === editingBranch.id
          ? {
              ...b,
              ...formData,
            }
          : b
      );
      setBranches(updated);
      saveStoredBranches(updated);
      showNotification(`تم تحديث بيانات الفرع (${formData.name_ar}) بنجاح!`);
    } else {
      const newBranch: Branch = {
        id: `branch-${Date.now()}`,
        ...formData,
        created_at: new Date().toISOString(),
      };
      const updated = [newBranch, ...branches];
      setBranches(updated);
      saveStoredBranches(updated);
      showNotification(`تم إضافة الفرع الجديد (${newBranch.name_ar}) بنجاح!`);
    }

    setIsModalOpen(false);
  };

  const handleToggleStatus = (id: string) => {
    const updated = branches.map((b) =>
      b.id === id ? { ...b, is_active: !b.is_active } : b
    );
    setBranches(updated);
    saveStoredBranches(updated);
    showNotification('تم تعديل حالة تشغيل الفرع!');
  };

  const handleDeleteBranch = (id: string, name: string) => {
    if (branches.length <= 1) {
      alert('لا يمكن حذف آخر فرع في النظام.');
      return;
    }
    if (window.confirm(`هل أنت متأكد من رغبتك في إزالة الفرع "${name}"؟`)) {
      const updated = branches.filter((b) => b.id !== id);
      setBranches(updated);
      saveStoredBranches(updated);
      if (activeBranchId === id && updated.length > 0) {
        handleSelectActiveBranch(updated[0].id);
      }
      showNotification('تم إزالة الفرع من المنظومة.');
    }
  };

  // Filtered branches
  const filteredBranches = branches.filter((b) => {
    const matchSearch =
      b.name_ar.toLowerCase().includes(searchQuery.toLowerCase()) ||
      b.name_en.toLowerCase().includes(searchQuery.toLowerCase()) ||
      b.code.toLowerCase().includes(searchQuery.toLowerCase()) ||
      b.city.toLowerCase().includes(searchQuery.toLowerCase()) ||
      b.district.toLowerCase().includes(searchQuery.toLowerCase());

    const matchCity = selectedCity === 'all' || b.city === selectedCity;
    const matchType = selectedType === 'all' || b.type === selectedType;

    return matchSearch && matchCity && matchType;
  });

  const cities = Array.from(new Set(branches.map((b) => b.city)));

  // KPI Calculations
  const totalSales = branches.reduce((acc, b) => acc + (b.is_active ? b.daily_sales : 0), 0);
  const totalTerminals = branches.reduce((acc, b) => acc + (b.is_active ? b.terminals_count : 0), 0);
  const activeCount = branches.filter((b) => b.is_active).length;

  return (
    <div className="space-y-6 max-w-7xl pb-16 select-none">
      {/* Header & Actions */}
      <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2.5">
            <div className="p-2.5 bg-blue-50 text-blue-700 rounded-xl">
              <Building2 className="w-6 h-6" />
            </div>
            <div>
              <h2 className="text-lg font-black text-slate-900">إدارة الفروع المتعددة ومراكز التوزيع</h2>
              <p className="text-xs text-slate-500 mt-0.5">
                التحكم المركزي في فروع الهايبرماركت، السوبرماركت، مراكز التلبية السريعة ونقاط البيع
              </p>
            </div>
          </div>
        </div>

        <div className="flex items-center gap-3">
          <button
            onClick={() => handleOpenModal()}
            className="px-4 py-2.5 bg-blue-600 hover:bg-blue-700 text-white rounded-xl text-xs font-bold shadow-md shadow-blue-600/30 flex items-center gap-2 transition-all"
          >
            <Plus className="w-4 h-4" />
            إضافة فرع جديد
          </button>
        </div>
      </div>

      {notification && (
        <div className="p-4 bg-emerald-50 border border-emerald-200 text-emerald-800 rounded-2xl text-xs font-bold flex items-center gap-2 shadow-xs animate-fade-in">
          <CheckCircle2 className="w-5 h-5 text-emerald-600 shrink-0" />
          <span>{notification}</span>
        </div>
      )}

      {/* KPI Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-xs flex items-center justify-between">
          <div>
            <span className="text-xs font-bold text-slate-400">شبكة الفروع النشطة</span>
            <div className="text-2xl font-black text-slate-900 mt-1">
              {activeCount} <span className="text-xs font-medium text-slate-400">من أصل {branches.length}</span>
            </div>
          </div>
          <div className="w-12 h-12 bg-blue-50 text-blue-600 rounded-2xl flex items-center justify-center">
            <Store className="w-6 h-6" />
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-xs flex items-center justify-between">
          <div>
            <span className="text-xs font-bold text-slate-400">نقاط البيع والكاشير المتاحة</span>
            <div className="text-2xl font-black text-slate-900 mt-1">
              {totalTerminals} <span className="text-xs font-medium text-slate-400">كاشير متصل</span>
            </div>
          </div>
          <div className="w-12 h-12 bg-purple-50 text-purple-600 rounded-2xl flex items-center justify-center">
            <Monitor className="w-6 h-6" />
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-xs flex items-center justify-between">
          <div>
            <span className="text-xs font-bold text-slate-400">إجمالي مبيعات الفروع اليوم</span>
            <div className="text-2xl font-black text-emerald-600 mt-1">
              {totalSales.toLocaleString()} <span className="text-xs font-bold text-slate-400">ل.س</span>
            </div>
          </div>
          <div className="w-12 h-12 bg-emerald-50 text-emerald-600 rounded-2xl flex items-center justify-center">
            <TrendingUp className="w-6 h-6" />
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-xs flex items-center justify-between">
          <div>
            <span className="text-xs font-bold text-slate-400">الفرع النشط في الجلسة</span>
            <div className="text-sm font-black text-blue-700 mt-1 truncate max-w-[150px]">
              {branches.find((b) => b.id === activeBranchId)?.name_ar || 'غير محدد'}
            </div>
          </div>
          <div className="w-12 h-12 bg-amber-50 text-amber-600 rounded-2xl flex items-center justify-center">
            <CheckCircle2 className="w-6 h-6" />
          </div>
        </div>
      </div>

      {/* Filter and Search Bar */}
      <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-xs flex flex-col md:flex-row items-center gap-3">
        <div className="relative flex-1 w-full">
          <Search className="w-4 h-4 text-slate-400 absolute right-3.5 top-3" />
          <input
            type="text"
            placeholder="البحث باسم الفرع، المدينة، الرمز، أو الحي..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pr-10 pl-4 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-bold focus:border-blue-600 focus:outline-none"
          />
        </div>

        <div className="flex items-center gap-2 w-full md:w-auto">
          <select
            value={selectedCity}
            onChange={(e) => setSelectedCity(e.target.value)}
            className="p-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-bold text-slate-700 focus:outline-none"
          >
            <option value="all">جميع المدن ({cities.length})</option>
            {cities.map((city) => (
              <option key={city} value={city}>
                {city}
              </option>
            ))}
          </select>

          <select
            value={selectedType}
            onChange={(e) => setSelectedType(e.target.value)}
            className="p-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-bold text-slate-700 focus:outline-none"
          >
            <option value="all">جميع أنواع الفروع</option>
            <option value="hypermarket">هايبرماركت ضخم</option>
            <option value="supermarket">سوبرماركت مركزي</option>
            <option value="dark_store">دارك ستور فوري 15 دقيقة</option>
            <option value="express">إكسبريس سريع</option>
          </select>
        </div>
      </div>

      {/* Branches Cards Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
        {filteredBranches.map((branch) => {
          const isCurrentActive = branch.id === activeBranchId;

          return (
            <div
              key={branch.id}
              className={`bg-white rounded-2xl border transition-all duration-200 flex flex-col justify-between overflow-hidden shadow-xs hover:shadow-md ${
                isCurrentActive
                  ? 'border-blue-600 ring-2 ring-blue-600/20'
                  : 'border-slate-200 hover:border-slate-300'
              }`}
            >
              <div>
                {/* Branch Card Header */}
                <div className="p-5 border-b border-slate-100 flex items-start justify-between gap-3">
                  <div className="flex items-start gap-3">
                    <div
                      className={`w-11 h-11 rounded-xl flex items-center justify-center shrink-0 ${
                        branch.type === 'hypermarket'
                          ? 'bg-blue-600 text-white'
                          : branch.type === 'dark_store'
                          ? 'bg-amber-600 text-white'
                          : 'bg-emerald-600 text-white'
                      }`}
                    >
                      {branch.type === 'dark_store' ? (
                        <Warehouse className="w-5 h-5" />
                      ) : (
                        <Store className="w-5 h-5" />
                      )}
                    </div>
                    <div>
                      <div className="flex items-center gap-2">
                        <span className="font-mono text-[10px] font-bold text-slate-400 bg-slate-100 px-2 py-0.5 rounded-md">
                          {branch.code}
                        </span>
                        <span
                          className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${
                            branch.is_active
                              ? 'bg-emerald-50 text-emerald-700'
                              : 'bg-rose-50 text-rose-700'
                          }`}
                        >
                          {branch.is_active ? 'نشط ويعمل' : 'مغلق مؤقتاً'}
                        </span>
                      </div>
                      <h3 className="text-sm font-black text-slate-900 mt-1 leading-snug">
                        {branch.name_ar}
                      </h3>
                      <div className="text-[11px] text-slate-400 font-medium">
                        {branch.name_en}
                      </div>
                    </div>
                  </div>

                  <div className="flex items-center gap-1">
                    <button
                      onClick={() => handleOpenModal(branch)}
                      className="p-1.5 text-slate-400 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-all"
                      title="تعديل بيانات الفرع"
                    >
                      <Edit2 className="w-4 h-4" />
                    </button>
                    <button
                      onClick={() => handleDeleteBranch(branch.id, branch.name_ar)}
                      className="p-1.5 text-slate-400 hover:text-rose-600 hover:bg-rose-50 rounded-lg transition-all"
                      title="حذف الفرع"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                </div>

                {/* Branch Details Body */}
                <div className="p-5 space-y-3 text-xs text-slate-600">
                  <div className="flex items-center gap-2">
                    <MapPin className="w-4 h-4 text-slate-400 shrink-0" />
                    <span className="truncate">
                      {branch.city} - {branch.district}
                    </span>
                  </div>

                  <div className="flex items-center gap-2">
                    <UserCheck className="w-4 h-4 text-slate-400 shrink-0" />
                    <span>المدير المسؤول: <strong className="text-slate-900">{branch.manager_name}</strong></span>
                  </div>

                  <div className="flex items-center gap-2">
                    <Phone className="w-4 h-4 text-slate-400 shrink-0" />
                    <span className="font-mono">{branch.phone}</span>
                  </div>

                  {/* Micro KPI Row */}
                  <div className="grid grid-cols-2 gap-2 pt-2 border-t border-slate-100">
                    <div className="p-2.5 bg-slate-50 rounded-xl">
                      <span className="text-[10px] text-slate-400 block">نقاط البيع والكاشير</span>
                      <strong className="text-xs text-slate-900 font-black flex items-center gap-1 mt-0.5">
                        <Monitor className="w-3.5 h-3.5 text-blue-600" />
                        {branch.terminals_count} شاشات كاشير
                      </strong>
                    </div>

                    <div className="p-2.5 bg-slate-50 rounded-xl">
                      <span className="text-[10px] text-slate-400 block">مبيعات اليوم</span>
                      <strong className="text-xs text-emerald-700 font-black mt-0.5 block">
                        {branch.daily_sales.toLocaleString()} {branch.currency}
                      </strong>
                    </div>
                  </div>
                </div>
              </div>

              {/* Bottom Actions */}
              <div className="p-4 bg-slate-50/80 border-t border-slate-100 flex items-center justify-between gap-2">
                {isCurrentActive ? (
                  <span className="text-[11px] font-bold text-blue-700 bg-blue-100/70 px-3 py-1.5 rounded-xl flex items-center gap-1">
                    <CheckCircle2 className="w-3.5 h-3.5" />
                    الفرع النشط حالياً
                  </span>
                ) : (
                  <button
                    onClick={() => handleSelectActiveBranch(branch.id)}
                    className="text-[11px] font-bold text-slate-700 hover:text-blue-700 hover:bg-white px-3 py-1.5 rounded-xl border border-transparent hover:border-slate-200 transition-all"
                  >
                    تعيين كفرع نشط
                  </button>
                )}

                <button
                  onClick={() => {
                    handleSelectActiveBranch(branch.id);
                    if (onOpenPosForBranch) {
                      onOpenPosForBranch(branch.id);
                    }
                  }}
                  className="px-3.5 py-1.5 bg-emerald-600 hover:bg-emerald-700 text-white rounded-xl text-xs font-bold shadow-xs flex items-center gap-1.5 transition-all"
                  title="فتح شاشة الكاشير المستقلة الخاصة بهذا الفرع"
                >
                  <Monitor className="w-3.5 h-3.5" />
                  فتح الكاشير (POS)
                </button>
              </div>
            </div>
          );
        })}
      </div>

      {/* Add / Edit Branch Modal */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl max-w-xl w-full shadow-2xl border border-slate-200 overflow-hidden animate-fade-in">
            <div className="p-6 border-b border-slate-100 flex items-center justify-between">
              <h3 className="text-base font-black text-slate-900 flex items-center gap-2">
                <Store className="w-5 h-5 text-blue-600" />
                {editingBranch ? 'تعديل بيانات الفرع' : 'إضافة فرع جديد للشبكة'}
              </h3>
              <button
                onClick={() => setIsModalOpen(false)}
                className="p-2 text-slate-400 hover:text-slate-600 rounded-xl hover:bg-slate-100 transition-all"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleSaveBranch} className="p-6 space-y-4 text-xs font-bold text-slate-700">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="block mb-1 text-slate-800">رمز الفرع (Branch Code)</label>
                  <input
                    type="text"
                    required
                    value={formData.code}
                    onChange={(e) => setFormData({ ...formData, code: e.target.value })}
                    className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl font-mono uppercase focus:outline-none focus:border-blue-600"
                    placeholder="BR-RUH-04"
                  />
                </div>

                <div>
                  <label className="block mb-1 text-slate-800">نوع الفرع والنشاط</label>
                  <select
                    value={formData.type}
                    onChange={(e) => setFormData({ ...formData, type: e.target.value as Branch['type'] })}
                    className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600"
                  >
                    <option value="hypermarket">هايبرماركت ضخم (Hypermarket)</option>
                    <option value="supermarket">سوبرماركت مركزي (Supermarket)</option>
                    <option value="dark_store">دارك ستور لتلبية الطلبات الفورية 15 دقيقة</option>
                    <option value="express">إكسبريس للمقاضي السريعة</option>
                  </select>
                </div>

                <div className="sm:col-span-2">
                  <label className="block mb-1 text-slate-800">اسم الفرع (بالعربية)</label>
                  <input
                    type="text"
                    required
                    value={formData.name_ar}
                    onChange={(e) => setFormData({ ...formData, name_ar: e.target.value })}
                    className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600"
                    placeholder="مثال: فرع الرياض - حي النرجس"
                  />
                </div>

                <div className="sm:col-span-2">
                  <label className="block mb-1 text-slate-800">اسم الفرع (بالإنجليزية)</label>
                  <input
                    type="text"
                    value={formData.name_en}
                    onChange={(e) => setFormData({ ...formData, name_en: e.target.value })}
                    className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600"
                    placeholder="e.g. Riyadh - Al-Narjis Branch"
                  />
                </div>

                <div>
                  <label className="block mb-1 text-slate-800">المدينة</label>
                  <input
                    type="text"
                    required
                    value={formData.city}
                    onChange={(e) => setFormData({ ...formData, city: e.target.value })}
                    className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600"
                    placeholder="الرياض / جدة / دمشق..."
                  />
                </div>

                <div>
                  <label className="block mb-1 text-slate-800">الحي / المنطقة</label>
                  <input
                    type="text"
                    value={formData.district}
                    onChange={(e) => setFormData({ ...formData, district: e.target.value })}
                    className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600"
                    placeholder="طريق الملك فهد..."
                  />
                </div>

                <div className="sm:col-span-2">
                  <label className="block mb-1 text-slate-800">العنوان التفصيلي</label>
                  <input
                    type="text"
                    value={formData.address}
                    onChange={(e) => setFormData({ ...formData, address: e.target.value })}
                    className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600"
                    placeholder="الشارع، رقم المبنى، المعالم القريبة"
                  />
                </div>

                <div>
                  <label className="block mb-1 text-slate-800">المدير المسؤول</label>
                  <input
                    type="text"
                    value={formData.manager_name}
                    onChange={(e) => setFormData({ ...formData, manager_name: e.target.value })}
                    className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600"
                    placeholder="اسم مدير الفرع"
                  />
                </div>

                <div>
                  <label className="block mb-1 text-slate-800">هاتف الفرع</label>
                  <input
                    type="text"
                    value={formData.phone}
                    onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                    className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl font-mono focus:outline-none focus:border-blue-600"
                    placeholder="+966 11..."
                  />
                </div>

                <div>
                  <label className="block mb-1 text-slate-800">عدد شاشات الكاشير (POS Terminals)</label>
                  <input
                    type="number"
                    min="1"
                    max="50"
                    value={formData.terminals_count}
                    onChange={(e) => setFormData({ ...formData, terminals_count: Number(e.target.value) })}
                    className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl font-mono focus:outline-none focus:border-blue-600"
                  />
                </div>

                <div className="flex items-center gap-3 pt-4">
                  <label className="flex items-center gap-2 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={formData.is_active}
                      onChange={(e) => setFormData({ ...formData, is_active: e.target.checked })}
                      className="w-4 h-4 text-blue-600 rounded"
                    />
                    <span className="text-xs font-bold text-slate-900">الفرع نشط ومفعل للعمليات</span>
                  </label>
                </div>
              </div>

              <div className="flex items-center justify-end gap-3 pt-4 border-t border-slate-100">
                <button
                  type="button"
                  onClick={() => setIsModalOpen(false)}
                  className="px-4 py-2.5 text-slate-500 hover:text-slate-700 text-xs font-bold rounded-xl"
                >
                  إلغاء
                </button>
                <button
                  type="submit"
                  className="px-6 py-2.5 bg-blue-600 hover:bg-blue-700 text-white text-xs font-bold rounded-xl shadow-md shadow-blue-600/30 transition-all"
                >
                  {editingBranch ? 'حفظ التعديلات' : 'إضافة الفرع الآن'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
