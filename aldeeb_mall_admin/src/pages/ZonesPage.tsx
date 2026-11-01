import React, { useState } from 'react';
import { 
  MapPin, 
  Layers, 
  Zap, 
  DollarSign, 
  Clock, 
  ShieldCheck, 
  Compass,
  Plus,
  Edit2,
  CheckCircle2,
  Building2,
  Search,
  Filter
} from 'lucide-react';
import { DeliveryZone } from '../types';
import { INITIAL_BRANCHES, getActiveBranchId } from '../lib/branchesData';
import { logAuditEvent } from '../lib/auditLogger';

interface ZonesPageProps {
  zones: DeliveryZone[];
  onToggleSurge?: (zoneId: string) => void;
}

export const ZonesPage: React.FC<ZonesPageProps> = ({
  zones: initialZones,
}) => {
  const activeBranchId = getActiveBranchId();
  const currentBranch = INITIAL_BRANCHES.find(b => b.id === activeBranchId) || INITIAL_BRANCHES[0];
  const [zones, setZones] = useState<DeliveryZone[]>(initialZones);
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState<'all' | 'active' | 'inactive'>('all');
  
  // Modal states
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingZone, setEditingZone] = useState<DeliveryZone | null>(null);
  const [toastMessage, setToastMessage] = useState<string | null>(null);

  // Form state
  const [formData, setFormData] = useState<Partial<DeliveryZone>>({
    zone_name_ar: '',
    dark_store_code: 'FC-DR-CITY',
    radius_km: 5.0,
    base_delivery_fee: 5000,
    free_delivery_threshold: 150000,
    estimated_minutes: 20,
    is_surge_pricing_active: false,
    surge_fee: 2000,
    is_active: true,
  });

  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(null), 3500);
  };

  const handleToggleSurge = (zoneId: string) => {
    const target = zones.find(z => z.id === zoneId);
    if (!target) return;
    const newSurgeState = !target.is_surge_pricing_active;
    const newSurgeFee = newSurgeState ? 2500.0 : 0.0;

    setZones((prev) =>
      prev.map((z) =>
        z.id === zoneId
          ? {
              ...z,
              is_surge_pricing_active: newSurgeState,
              surge_fee: newSurgeFee,
            }
          : z
      )
    );

    logAuditEvent({
      actor_id: 'admin_usr_01',
      actor_name: 'مدير العمليات اللوجستية',
      actor_role: 'super_admin',
      action: 'UPDATE_SURGE_PRICING',
      target_type: 'DELIVERY_ZONE',
      target_id: zoneId,
      branch_id: currentBranch.id,
      details: `تبديل تسعير الذروة لنطاق (${target.zone_name_ar}) إلى: ${newSurgeState ? 'مفعل (+2,500 ل.س)' : 'معطل'}`,
      category: 'system'
    });

    showToast(`✓ تم ${newSurgeState ? 'تفعيل' : 'تعطيل'} تسعير الذروة لنطاق "${target.zone_name_ar}" بنجاح.`);
  };

  const handleToggleActive = (zoneId: string) => {
    const target = zones.find(z => z.id === zoneId);
    if (!target) return;
    const newActiveState = !target.is_active;

    setZones((prev) =>
      prev.map((z) => (z.id === zoneId ? { ...z, is_active: newActiveState } : z))
    );

    logAuditEvent({
      actor_id: 'admin_usr_01',
      actor_name: 'مدير العمليات اللوجستية',
      actor_role: 'super_admin',
      action: 'TOGGLE_ZONE_STATUS',
      target_type: 'DELIVERY_ZONE',
      target_id: zoneId,
      branch_id: currentBranch.id,
      details: `تغيير حالة نطاق التوصيل (${target.zone_name_ar}) إلى: ${newActiveState ? 'نشط' : 'معطل'}`,
      category: 'system'
    });

    showToast(`✓ تم ${newActiveState ? 'تفعيل' : 'تعطيل'} النطاق "${target.zone_name_ar}".`);
  };

  const handleOpenAddModal = () => {
    setEditingZone(null);
    setFormData({
      zone_name_ar: '',
      dark_store_code: currentBranch.id === 'branch-2' ? 'WH-DAM-HUB' : 'FC-DR-CITY',
      radius_km: 5.0,
      base_delivery_fee: 5000,
      free_delivery_threshold: 150000,
      estimated_minutes: 20,
      is_surge_pricing_active: false,
      surge_fee: 2000,
      is_active: true,
    });
    setIsModalOpen(true);
  };

  const handleOpenEditModal = (zone: DeliveryZone) => {
    setEditingZone(zone);
    setFormData(zone);
    setIsModalOpen(true);
  };

  const handleSaveZone = (e: React.FormEvent) => {
    e.preventDefault();
    if (!formData.zone_name_ar) {
      alert('يرجى كتابة اسم النطاق الجغرافي');
      return;
    }

    if (editingZone) {
      // Update existing
      setZones(prev => prev.map(z => z.id === editingZone.id ? { ...z, ...formData } as DeliveryZone : z));
      logAuditEvent({
        actor_id: 'admin_usr_01',
        actor_name: 'مدير العمليات اللوجستية',
        actor_role: 'super_admin',
        action: 'UPDATE_ZONE_DETAILS',
        target_type: 'DELIVERY_ZONE',
        target_id: editingZone.id,
        branch_id: currentBranch.id,
        details: `تعديل معايير نطاق التوصيل (${formData.zone_name_ar})`,
        category: 'system'
      });
      showToast(`✓ تم تحديث بيانات نطاق "${formData.zone_name_ar}" بنجاح!`);
    } else {
      // Create new
      const newZone: DeliveryZone = {
        id: `zn-${Date.now()}`,
        zone_name_ar: formData.zone_name_ar || '',
        dark_store_code: formData.dark_store_code || 'FC-DR-CITY',
        radius_km: Number(formData.radius_km) || 5,
        base_delivery_fee: Number(formData.base_delivery_fee) || 5000,
        free_delivery_threshold: Number(formData.free_delivery_threshold) || 150000,
        estimated_minutes: Number(formData.estimated_minutes) || 20,
        is_surge_pricing_active: !!formData.is_surge_pricing_active,
        surge_fee: Number(formData.surge_fee) || 0,
        is_active: true,
      };
      setZones(prev => [newZone, ...prev]);
      logAuditEvent({
        actor_id: 'admin_usr_01',
        actor_name: 'مدير العمليات اللوجستية',
        actor_role: 'super_admin',
        action: 'CREATE_DELIVERY_ZONE',
        target_type: 'DELIVERY_ZONE',
        target_id: newZone.id,
        branch_id: currentBranch.id,
        details: `إضافة نطاق جغرافي جديد (${newZone.zone_name_ar})`,
        category: 'system'
      });
      showToast(`✓ تمت إضافة نطاق التوصيل "${newZone.zone_name_ar}" بنجاح!`);
    }

    setIsModalOpen(false);
  };

  // Branch filtering
  const filteredByBranch = zones.filter(zone => {
    if (currentBranch.id === 'branch-2') {
      // Damascus only
      return zone.dark_store_code.includes('DAM');
    } else if (currentBranch.id === 'branch-1') {
      // Daraa only
      return !zone.dark_store_code.includes('DAM');
    }
    return true;
  });

  // Search & Status filtering
  const displayZones = filteredByBranch.filter(zone => {
    const matchesSearch = zone.zone_name_ar.toLowerCase().includes(searchQuery.toLowerCase()) ||
                          zone.dark_store_code.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesStatus = statusFilter === 'all' ? true :
                          statusFilter === 'active' ? zone.is_active : !zone.is_active;
    return matchesSearch && matchesStatus;
  });

  const activeCount = filteredByBranch.filter(z => z.is_active).length;

  return (
    <div className="space-y-6" data-feature-key="zones">
      {/* Toast Notification */}
      {toastMessage && (
        <div className="bg-emerald-600 text-white px-5 py-3 rounded-xl shadow-lg flex items-center gap-3 animate-fade-in text-sm font-medium">
          <CheckCircle2 className="w-5 h-5 flex-shrink-0" />
          <span>{toastMessage}</span>
        </div>
      )}

      {/* Top Banner */}
      <div className="bg-gradient-to-r from-slate-900 via-indigo-950 to-blue-950 text-white p-6 rounded-2xl shadow-sm flex flex-col md:flex-row items-center justify-between gap-4">
        <div>
          <div className="inline-flex items-center gap-1.5 text-xs font-bold text-blue-300 mb-1">
            <Compass className="w-4 h-4 text-blue-400" />
            نظام النطاقات الجغرافية والتسعير اللوجستي — محافظة درعا وسوريا
          </div>
          <h2 className="text-xl font-black">
            إدارة أقطار التوصيل والحد الأدنى للطلب ورسوم الذروة
          </h2>
          <p className="text-xs text-slate-300 mt-1 max-w-2xl leading-relaxed">
            يتم تحديد نطاقات الخدمة اللوجستية لكل مستودع وفرع لضمان وصول الطلب مبرداً وطازجاً في الوقت القياسي المتعهد به (15 - 45 دقيقة).
          </p>
          <div className="flex items-center gap-2 mt-3 text-xs text-blue-200">
            <Building2 className="w-3.5 h-3.5 text-blue-400" />
            <span>الفرع النشط المعروض: <strong className="text-white">{currentBranch.name_ar}</strong></span>
          </div>
        </div>

        <div className="flex flex-col sm:flex-row items-center gap-3 w-full md:w-auto">
          <div className="flex items-center gap-2 bg-white/10 px-4 py-2.5 rounded-xl border border-white/15 w-full sm:w-auto justify-center">
            <span className="w-2.5 h-2.5 rounded-full bg-emerald-400 animate-pulse"></span>
            <span className="text-xs font-bold">{activeCount} نطاقات نشطة</span>
          </div>
          <button
            onClick={handleOpenAddModal}
            className="flex items-center justify-center gap-2 bg-blue-600 hover:bg-blue-700 text-white px-4 py-2.5 rounded-xl text-xs font-bold transition-all shadow-sm w-full sm:w-auto"
          >
            <Plus className="w-4 h-4" />
            <span>إضافة نطاق جغرافي جديد</span>
          </button>
        </div>
      </div>

      {/* Control Bar: Search & Status Filter */}
      <div className="flex flex-col sm:flex-row items-center justify-between gap-4 bg-white p-4 rounded-xl border border-gray-100 shadow-sm">
        <div className="relative w-full sm:w-80">
          <Search className="w-4 h-4 text-gray-400 absolute right-3 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            placeholder="بحث باسم المنطقة أو كود المستودع..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-3 pr-9 py-2 bg-gray-50 border border-gray-200 rounded-lg text-xs focus:outline-none focus:border-blue-500"
          />
        </div>

        <div className="flex items-center gap-2 w-full sm:w-auto justify-end">
          <Filter className="w-4 h-4 text-gray-400" />
          <span className="text-xs text-gray-500">الحالة:</span>
          <div className="flex bg-gray-100 p-1 rounded-lg text-xs font-semibold">
            <button
              onClick={() => setStatusFilter('all')}
              className={`px-3 py-1 rounded-md transition-all ${statusFilter === 'all' ? 'bg-white text-gray-900 shadow-xs' : 'text-gray-500'}`}
            >
              الكل ({filteredByBranch.length})
            </button>
            <button
              onClick={() => setStatusFilter('active')}
              className={`px-3 py-1 rounded-md transition-all ${statusFilter === 'active' ? 'bg-white text-emerald-700 shadow-xs' : 'text-gray-500'}`}
            >
              المفعلة ({activeCount})
            </button>
            <button
              onClick={() => setStatusFilter('inactive')}
              className={`px-3 py-1 rounded-md transition-all ${statusFilter === 'inactive' ? 'bg-white text-rose-700 shadow-xs' : 'text-gray-500'}`}
            >
              المعطلة ({filteredByBranch.length - activeCount})
            </button>
          </div>
        </div>
      </div>

      {/* Zones Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
        {displayZones.map((zone) => {
          return (
            <div
              key={zone.id}
              className={`bg-white rounded-2xl border transition-all p-5 shadow-sm space-y-4 hover:shadow-md ${
                zone.is_active ? 'border-slate-200' : 'border-slate-200 opacity-60 bg-gray-50/50'
              }`}
            >
              {/* Header */}
              <div className="flex items-start justify-between">
                <div>
                  <div className="flex items-center gap-2">
                    <span className="text-xs font-mono font-bold text-blue-600 bg-blue-50 px-2 py-0.5 rounded">
                      {zone.dark_store_code}
                    </span>
                    <button
                      onClick={() => handleOpenEditModal(zone)}
                      className="p-1 hover:bg-gray-100 rounded text-gray-400 hover:text-blue-600 transition-colors"
                      title="تعديل النطاق"
                    >
                      <Edit2 className="w-3.5 h-3.5" />
                    </button>
                  </div>
                  <h3 className="font-bold text-slate-900 text-sm mt-1.5">{zone.zone_name_ar}</h3>
                </div>
                <button
                  onClick={() => handleToggleActive(zone.id)}
                  className={`text-xs px-2.5 py-1 rounded-lg font-bold transition-colors ${
                    zone.is_active
                      ? 'bg-emerald-100 text-emerald-800'
                      : 'bg-rose-100 text-rose-800'
                  }`}
                >
                  {zone.is_active ? 'مفعل' : 'معطل'}
                </button>
              </div>

              {/* Geo Specs */}
              <div className="space-y-2 bg-slate-50 p-3.5 rounded-xl border border-slate-100 text-xs">
                <div className="flex justify-between text-slate-600">
                  <span className="flex items-center gap-1.5">
                    <Compass className="w-3.5 h-3.5 text-blue-600" />
                    نصف قطر التغطية (Radius):
                  </span>
                  <span className="font-bold text-slate-900">{zone.radius_km} كم</span>
                </div>
                <div className="flex justify-between text-slate-600">
                  <span className="flex items-center gap-1.5">
                    <Clock className="w-3.5 h-3.5 text-blue-600" />
                    زمن الوصول المتعهد به:
                  </span>
                  <span className="font-bold text-blue-600">{zone.estimated_minutes} دقيقة</span>
                </div>
                <div className="flex justify-between text-slate-600">
                  <span className="flex items-center gap-1.5">
                    <DollarSign className="w-3.5 h-3.5 text-blue-600" />
                    رسوم التوصيل الأساسية:
                  </span>
                  <span className="font-mono font-bold text-slate-900">{zone.base_delivery_fee.toLocaleString()} ل.س</span>
                </div>
                <div className="flex justify-between text-slate-600">
                  <span className="flex items-center gap-1.5">
                    <ShieldCheck className="w-3.5 h-3.5 text-emerald-600" />
                    حد الشحن المجاني:
                  </span>
                  <span className="font-mono font-bold text-emerald-700">فوق {zone.free_delivery_threshold.toLocaleString()} ل.س</span>
                </div>
              </div>

              {/* Surge Pricing Toggle Section */}
              <div className="p-3.5 bg-amber-50/70 border border-amber-200 rounded-xl space-y-2">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-1.5">
                    <Zap className="w-4 h-4 fill-amber-500 text-amber-500" />
                    <span className="text-xs font-bold text-amber-900">تسعير الذروة (Surge Fee)</span>
                  </div>
                  <button
                    onClick={() => handleToggleSurge(zone.id)}
                    className={`text-xs px-2.5 py-1 rounded-lg font-bold transition-all ${
                      zone.is_surge_pricing_active
                        ? 'bg-amber-500 text-white shadow-xs'
                        : 'bg-slate-200 text-slate-700'
                    }`}
                  >
                    {zone.is_surge_pricing_active ? 'مفعل (+2,500 ل.س)' : 'معطل'}
                  </button>
                </div>
                <p className="text-[11px] text-amber-800 leading-relaxed">
                  {zone.is_surge_pricing_active
                    ? 'يتم تطبيق رسوم إضافية 2,500 ل.س تلقائياً بسبب ذروة الطلبات الحالية لتحفيز السائقين.'
                    : 'التسعير العادي ساري، لا توجد رسوم ذروة في هذا النطاق.'}
                </p>
              </div>
            </div>
          );
        })}
      </div>

      {displayZones.length === 0 && (
        <div className="bg-white p-12 text-center rounded-2xl border border-gray-100 space-y-3">
          <MapPin className="w-12 h-12 text-gray-300 mx-auto" />
          <h3 className="font-bold text-gray-700 text-sm">لا توجد نطاقات جغرافية مطابقة للبحث أو للفرع النشط</h3>
          <p className="text-xs text-gray-400">يمكنك إضافة نطاق جديد أو التحقق من تصفية الفروع في القائمة العلوية.</p>
        </div>
      )}

      {/* Add / Edit Modal */}
      {isModalOpen && (
        <div className="fixed inset-0 bg-slate-900/60 backdrop-blur-xs flex items-center justify-center p-4 z-50 animate-fade-in">
          <div className="bg-white rounded-2xl shadow-xl w-full max-w-lg overflow-hidden border border-gray-100">
            <div className="p-5 border-b border-gray-100 flex items-center justify-between bg-slate-50">
              <div className="flex items-center gap-2">
                <Compass className="w-5 h-5 text-blue-600" />
                <h3 className="font-bold text-gray-900 text-sm">
                  {editingZone ? 'تعديل نطاق التغطية الجغرافية' : 'إضافة نطاق جغرافي جديد'}
                </h3>
              </div>
              <button
                onClick={() => setIsModalOpen(false)}
                className="text-gray-400 hover:text-gray-600 text-lg font-bold"
              >
                ×
              </button>
            </div>

            <form onSubmit={handleSaveZone} className="p-5 space-y-4 text-xs">
              <div>
                <label className="block text-gray-700 font-bold mb-1">اسم المنطقة / النطاق الجغرافي *</label>
                <input
                  type="text"
                  required
                  placeholder="مثال: درعا المحطة وشمال المدينة"
                  value={formData.zone_name_ar || ''}
                  onChange={(e) => setFormData({ ...formData, zone_name_ar: e.target.value })}
                  className="w-full p-2.5 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:border-blue-500"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-gray-700 font-bold mb-1">مركز التوزيع / المستودع *</label>
                  <select
                    value={formData.dark_store_code || 'FC-DR-CITY'}
                    onChange={(e) => setFormData({ ...formData, dark_store_code: e.target.value })}
                    className="w-full p-2.5 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:border-blue-500"
                  >
                    <option value="FC-DR-CITY">مركز درعا المدينة (FC-DR-CITY)</option>
                    <option value="FC-DR-WEST">مركز ريف درعا الغربي (FC-DR-WEST)</option>
                    <option value="WH-DR-CENTRAL">المستودع المركزي درعا (WH-DR-CENTRAL)</option>
                    <option value="WH-DAM-HUB">مستودع التوريد دمشق (WH-DAM-HUB)</option>
                  </select>
                </div>

                <div>
                  <label className="block text-gray-700 font-bold mb-1">نصف القطر (كم) *</label>
                  <input
                    type="number"
                    step="0.5"
                    min="1"
                    max="50"
                    required
                    value={formData.radius_km || 5}
                    onChange={(e) => setFormData({ ...formData, radius_km: parseFloat(e.target.value) })}
                    className="w-full p-2.5 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:border-blue-500"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-gray-700 font-bold mb-1">رسوم التوصيل الأساسية (ل.س) *</label>
                  <input
                    type="number"
                    step="500"
                    min="0"
                    required
                    value={formData.base_delivery_fee || 5000}
                    onChange={(e) => setFormData({ ...formData, base_delivery_fee: parseFloat(e.target.value) })}
                    className="w-full p-2.5 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:border-blue-500"
                  />
                </div>

                <div>
                  <label className="block text-gray-700 font-bold mb-1">حد الشحن المجاني (ل.س) *</label>
                  <input
                    type="number"
                    step="5000"
                    min="0"
                    required
                    value={formData.free_delivery_threshold || 150000}
                    onChange={(e) => setFormData({ ...formData, free_delivery_threshold: parseFloat(e.target.value) })}
                    className="w-full p-2.5 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:border-blue-500"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-gray-700 font-bold mb-1">زمن الوصول المتعهد به (دقيقة) *</label>
                  <input
                    type="number"
                    min="5"
                    max="180"
                    required
                    value={formData.estimated_minutes || 20}
                    onChange={(e) => setFormData({ ...formData, estimated_minutes: parseInt(e.target.value) })}
                    className="w-full p-2.5 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:border-blue-500"
                  />
                </div>

                <div>
                  <label className="block text-gray-700 font-bold mb-1">رسوم الذروة الإضافية (ل.س)</label>
                  <input
                    type="number"
                    step="500"
                    min="0"
                    value={formData.surge_fee || 2000}
                    onChange={(e) => setFormData({ ...formData, surge_fee: parseFloat(e.target.value) })}
                    className="w-full p-2.5 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:border-blue-500"
                  />
                </div>
              </div>

              <div className="pt-4 border-t border-gray-100 flex items-center justify-end gap-2">
                <button
                  type="button"
                  onClick={() => setIsModalOpen(false)}
                  className="px-4 py-2 bg-gray-100 hover:bg-gray-200 text-gray-700 rounded-xl font-bold transition-colors"
                >
                  إلغاء
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-xl font-bold transition-colors"
                >
                  {editingZone ? 'حفظ التعديلات' : 'إضافة النطاق'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
