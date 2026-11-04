import React, { useState, useEffect } from 'react';
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
  Filter,
  RefreshCw,
  AlertTriangle,
  Activity,
  Check,
  X,
  Gauge
} from 'lucide-react';
import { DeliveryZone } from '../types';
import { INITIAL_BRANCHES, getActiveBranchId } from '../lib/branchesData';
import { logAuditEvent } from '../lib/auditLogger';
import { deliveryZonesApi, CoverageCheckResponse } from '../lib/deliveryZonesApi';

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
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [isSubmitting, setIsSubmitting] = useState<boolean>(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState<'all' | 'active' | 'inactive'>('all');
  
  // Modal states
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingZone, setEditingZone] = useState<DeliveryZone | null>(null);
  const [toastMessage, setToastMessage] = useState<string | null>(null);

  // Live Server Coverage Checker State
  const [checkCity, setCheckCity] = useState('دمشق');
  const [checkDistrict, setCheckDistrict] = useState('المزة');
  const [checkLat, setCheckLat] = useState('33.5138');
  const [checkLon, setCheckLon] = useState('36.2765');
  const [checkSubtotal, setCheckSubtotal] = useState('75000');
  const [checkLoading, setCheckLoading] = useState(false);
  const [checkResult, setCheckResult] = useState<CoverageCheckResponse | null>(null);
  const [checkError, setCheckError] = useState<string | null>(null);

  // Form state
  const [formData, setFormData] = useState<Partial<DeliveryZone>>({
    zone_name_ar: '',
    zone_name_en: '',
    city: 'دمشق',
    district: '',
    branch_id: 'b-dam-01',
    dark_store_code: 'WH-DAM-HUB',
    center_latitude: 33.5138,
    center_longitude: 36.2765,
    radius_km: 5.0,
    base_delivery_fee: 5000,
    free_delivery_threshold: 150000,
    estimated_minutes: 20,
    is_surge_pricing_active: false,
    surge_fee: 2000,
    is_active: true,
    opening_time: '08:00:00',
    closing_time: '23:59:59',
    max_hourly_capacity: 50,
  });

  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(null), 3500);
  };

  // 1. Fetch authoritative delivery zones from Server on Mount
  const loadServerZones = async () => {
    setIsLoading(true);
    try {
      const serverZones = await deliveryZonesApi.getDeliveryZones();
      if (serverZones && serverZones.length > 0) {
        setZones(serverZones);
      }
    } catch (err: any) {
      console.warn('⚠️ [ZonesPage] Failed to fetch server zones, retaining local state:', err);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    loadServerZones();
  }, []);

  // 2. Toggle Surge Pricing (Server Authoritative)
  const handleToggleSurge = async (zoneId: string) => {
    const target = zones.find(z => z.id === zoneId);
    if (!target) return;
    const newSurgeState = !target.is_surge_pricing_active;
    const newSurgeFee = newSurgeState ? (target.surge_fee > 0 ? target.surge_fee : 2500.0) : 0.0;

    // Optimistic UI
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

    try {
      await deliveryZonesApi.setSurgePricing(zoneId, newSurgeState, newSurgeFee);
      logAuditEvent({
        actor_id: 'admin_usr_01',
        actor_name: 'مدير العمليات اللوجستية',
        actor_role: 'super_admin',
        action: 'UPDATE_SURGE_PRICING',
        target_type: 'DELIVERY_ZONE',
        target_id: zoneId,
        branch_id: target.branch_id || currentBranch.id,
        details: `تحديث تسعير الذروة لنطاق (${target.zone_name_ar}) إلى: ${newSurgeState ? `مفعل (+${newSurgeFee.toLocaleString()} ل.س)` : 'معطل'} في خادم PostgreSQL`,
        category: 'system'
      });
      showToast(`✓ تم ${newSurgeState ? 'تفعيل' : 'تعطيل'} تسعير الذروة لنطاق "${target.zone_name_ar}" وحفظه في الخادم.`);
    } catch (err: any) {
      console.error('Failed to sync surge to server:', err);
      // Revert optimistic update
      setZones((prev) =>
        prev.map((z) => (z.id === zoneId ? target : z))
      );
      showToast(`❌ خطأ في الخادم: ${err.message || 'تعذر تحديث تسعير الذروة'}`);
    }
  };

  // 3. Toggle Zone Active Status (Server Authoritative)
  const handleToggleActive = async (zoneId: string) => {
    const target = zones.find(z => z.id === zoneId);
    if (!target) return;
    const newActiveState = !target.is_active;

    // Optimistic UI
    setZones((prev) =>
      prev.map((z) => (z.id === zoneId ? { ...z, is_active: newActiveState } : z))
    );

    try {
      await deliveryZonesApi.toggleZoneStatus(zoneId, newActiveState);
      logAuditEvent({
        actor_id: 'admin_usr_01',
        actor_name: 'مدير العمليات اللوجستية',
        actor_role: 'super_admin',
        action: 'TOGGLE_ZONE_STATUS',
        target_type: 'DELIVERY_ZONE',
        target_id: zoneId,
        branch_id: target.branch_id || currentBranch.id,
        details: `تغيير حالة نطاق التوصيل (${target.zone_name_ar}) إلى: ${newActiveState ? 'نشط ومغطى' : 'معطل ومستبعد'} في خادم PostgreSQL`,
        category: 'system'
      });
      showToast(`✓ تم ${newActiveState ? 'تفعيل' : 'تعطيل'} النطاق "${target.zone_name_ar}" في الخادم.`);
    } catch (err: any) {
      console.error('Failed to sync active status to server:', err);
      setZones((prev) =>
        prev.map((z) => (z.id === zoneId ? target : z))
      );
      showToast(`❌ خطأ في الخادم: ${err.message || 'تعذر تحديث حالة النطاق'}`);
    }
  };

  const handleOpenAddModal = () => {
    setEditingZone(null);
    setFormData({
      zone_name_ar: '',
      zone_name_en: '',
      city: currentBranch.city || 'دمشق',
      district: '',
      branch_id: currentBranch.id || 'b-dam-01',
      dark_store_code: currentBranch.id === 'branch-2' ? 'WH-DAM-HUB' : 'FC-DR-CITY',
      center_latitude: 33.5138,
      center_longitude: 36.2765,
      radius_km: 5.0,
      base_delivery_fee: 5000,
      free_delivery_threshold: 150000,
      estimated_minutes: 20,
      is_surge_pricing_active: false,
      surge_fee: 2000,
      is_active: true,
      opening_time: '08:00:00',
      closing_time: '23:59:59',
      max_hourly_capacity: 50,
    });
    setIsModalOpen(true);
  };

  const handleOpenEditModal = (zone: DeliveryZone) => {
    setEditingZone(zone);
    setFormData({
      ...zone,
      opening_time: zone.opening_time || '08:00:00',
      closing_time: zone.closing_time || '23:59:59',
      max_hourly_capacity: zone.max_hourly_capacity || 50,
      city: zone.city || (zone.zone_name_ar.includes('حلب') ? 'حلب' : zone.zone_name_ar.includes('درعا') ? 'درعا' : 'دمشق'),
      branch_id: zone.branch_id || currentBranch.id,
      center_latitude: zone.center_latitude || 33.5138,
      center_longitude: zone.center_longitude || 36.2765,
    });
    setIsModalOpen(true);
  };

  // 4. Save Zone to Server (Create or Update)
  const handleSaveZone = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!formData.zone_name_ar) {
      alert('يرجى كتابة اسم النطاق الجغرافي');
      return;
    }

    setIsSubmitting(true);
    const targetId = editingZone ? editingZone.id : `zn-${Date.now()}`;
    const payload: Partial<DeliveryZone> = {
      id: targetId,
      zone_name_ar: formData.zone_name_ar,
      zone_name_en: formData.zone_name_en || '',
      city: formData.city || 'دمشق',
      district: formData.district || '',
      branch_id: formData.branch_id || currentBranch.id,
      dark_store_code: formData.dark_store_code || 'WH-DAM-HUB',
      center_latitude: Number(formData.center_latitude) || 33.5138,
      center_longitude: Number(formData.center_longitude) || 36.2765,
      radius_km: Number(formData.radius_km) || 5.0,
      base_delivery_fee: Number(formData.base_delivery_fee) || 5000,
      free_delivery_threshold: Number(formData.free_delivery_threshold) || 150000,
      estimated_minutes: Number(formData.estimated_minutes) || 20,
      is_surge_pricing_active: !!formData.is_surge_pricing_active,
      surge_fee: Number(formData.surge_fee) || 0,
      is_active: formData.is_active !== undefined ? formData.is_active : true,
      opening_time: formData.opening_time || '08:00:00',
      closing_time: formData.closing_time || '23:59:59',
      max_hourly_capacity: Number(formData.max_hourly_capacity) || 50,
    };

    try {
      const saved = await deliveryZonesApi.saveDeliveryZone(payload);
      if (editingZone) {
        setZones(prev => prev.map(z => z.id === targetId ? saved : z));
        logAuditEvent({
          actor_id: 'admin_usr_01',
          actor_name: 'مدير العمليات اللوجستية',
          actor_role: 'super_admin',
          action: 'UPDATE_ZONE_DETAILS',
          target_type: 'DELIVERY_ZONE',
          target_id: targetId,
          branch_id: saved.branch_id || currentBranch.id,
          details: `تحديث معايير نطاق التوصيل (${saved.zone_name_ar}) في الخادم`,
          category: 'system'
        });
        showToast(`✓ تم تحديث بيانات نطاق "${saved.zone_name_ar}" في الخادم بنجاح!`);
      } else {
        setZones(prev => [saved, ...prev]);
        logAuditEvent({
          actor_id: 'admin_usr_01',
          actor_name: 'مدير العمليات اللوجستية',
          actor_role: 'super_admin',
          action: 'CREATE_DELIVERY_ZONE',
          target_type: 'DELIVERY_ZONE',
          target_id: saved.id,
          branch_id: saved.branch_id || currentBranch.id,
          details: `إضافة نطاق جغرافي جديد (${saved.zone_name_ar}) وحفظه في PostgreSQL`,
          category: 'system'
        });
        showToast(`✓ تمت إضافة نطاق التوصيل "${saved.zone_name_ar}" وحفظه في الخادم بنجاح!`);
      }
      setIsModalOpen(false);
    } catch (err: any) {
      console.error('Error saving zone:', err);
      alert(`تعذر حفظ النطاق في الخادم: ${err.message || 'خطأ غير معروف'}`);
    } finally {
      setIsSubmitting(false);
    }
  };

  // 5. Test Live Server Coverage Check
  const handleTestServerCoverage = async () => {
    setCheckLoading(true);
    setCheckError(null);
    setCheckResult(null);

    try {
      const result = await deliveryZonesApi.checkCoverage({
        latitude: checkLat ? parseFloat(checkLat) : undefined,
        longitude: checkLon ? parseFloat(checkLon) : undefined,
        city: checkCity.trim(),
        district: checkDistrict.trim(),
        subtotal: checkSubtotal ? parseFloat(checkSubtotal) : 0,
      });
      setCheckResult(result);
    } catch (err: any) {
      setCheckError(err.message || 'فشل فحص التغطية في الخادم');
    } finally {
      setCheckLoading(false);
    }
  };

  // Branch filtering
  const filteredByBranch = zones.filter(zone => {
    if (currentBranch.id === 'branch-2') {
      return zone.dark_store_code.includes('DAM') || (zone.city && zone.city.includes('دمشق'));
    } else if (currentBranch.id === 'branch-1') {
      return !zone.dark_store_code.includes('DAM');
    }
    return true;
  });

  // Search & Status filtering
  const displayZones = filteredByBranch.filter(zone => {
    const matchesSearch = zone.zone_name_ar.toLowerCase().includes(searchQuery.toLowerCase()) ||
                          zone.dark_store_code.toLowerCase().includes(searchQuery.toLowerCase()) ||
                          (zone.city && zone.city.toLowerCase().includes(searchQuery.toLowerCase()));
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
            منظومة نطاقات التغطية ورسوم التوصيل الخادمية (PostgreSQL + PostgREST Engine)
          </div>
          <h2 className="text-xl font-black">
            إدارة أقطار التوصيل والحدود وأوقات العمل والسعة ورسوم الذروة
          </h2>
          <p className="text-xs text-slate-300 mt-1 max-w-2xl leading-relaxed">
            البيانات مخزنة وموثقة مباشرة في جدول <code className="text-emerald-300 font-mono">public.delivery_zones</code>. يتم التحقق من العنوان واختيار الفرع وحساب الرسوم والوقت خادمياً عبر دالة <code className="text-emerald-300 font-mono">check_delivery_coverage</code> لمنع التلاعب.
          </p>
          <div className="flex items-center gap-3 mt-3 text-xs text-blue-200">
            <div className="flex items-center gap-1">
              <Building2 className="w-3.5 h-3.5 text-blue-400" />
              <span>الفرع النشط المعروض: <strong className="text-white">{currentBranch.name_ar}</strong></span>
            </div>
            <div className="flex items-center gap-1 bg-white/10 px-2 py-0.5 rounded text-[11px] font-mono text-emerald-300">
              <Activity className="w-3 h-3" />
              <span>إجمالي النطاقات بالخادم: {zones.length}</span>
            </div>
          </div>
        </div>

        <div className="flex flex-col sm:flex-row items-center gap-3 w-full md:w-auto">
          <button
            onClick={loadServerZones}
            disabled={isLoading}
            className="flex items-center justify-center gap-1.5 bg-white/10 hover:bg-white/20 text-white px-3.5 py-2.5 rounded-xl text-xs font-bold transition-all border border-white/15 w-full sm:w-auto"
            title="تحديث البيانات من الخادم"
          >
            <RefreshCw className={`w-3.5 h-3.5 ${isLoading ? 'animate-spin' : ''}`} />
            <span>مزامنة الخادم</span>
          </button>
          <button
            onClick={handleOpenAddModal}
            className="flex items-center justify-center gap-2 bg-blue-600 hover:bg-blue-700 text-white px-4 py-2.5 rounded-xl text-xs font-bold transition-all shadow-sm w-full sm:w-auto"
          >
            <Plus className="w-4 h-4" />
            <span>إضافة نطاق جغرافي جديد</span>
          </button>
        </div>
      </div>

      {/* Live Server Coverage Checker Interactive Panel */}
      <div className="bg-gradient-to-br from-indigo-50/80 via-white to-slate-50 p-5 rounded-2xl border border-indigo-100 shadow-sm space-y-4">
        <div className="flex items-center justify-between border-b border-indigo-100 pb-3">
          <div className="flex items-center gap-2">
            <Gauge className="w-5 h-5 text-indigo-600" />
            <h3 className="font-black text-slate-900 text-sm">
              أداة الفحص الخادمي الفوري للتغطية والرسوم (Live Server Coverage Simulator)
            </h3>
          </div>
          <span className="text-[11px] bg-indigo-100 text-indigo-800 px-2.5 py-1 rounded-full font-bold">
            دالة check_delivery_coverage الذرية
          </span>
        </div>

        {/* Input Controls */}
        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-5 gap-3 text-xs">
          <div>
            <label className="block text-slate-600 font-bold mb-1">المدينة:</label>
            <input
              type="text"
              value={checkCity}
              onChange={(e) => setCheckCity(e.target.value)}
              className="w-full p-2 bg-white border border-slate-200 rounded-lg focus:outline-none focus:border-indigo-500 font-medium"
              placeholder="مثال: دمشق"
            />
          </div>
          <div>
            <label className="block text-slate-600 font-bold mb-1">الحي / المنطقة:</label>
            <input
              type="text"
              value={checkDistrict}
              onChange={(e) => setCheckDistrict(e.target.value)}
              className="w-full p-2 bg-white border border-slate-200 rounded-lg focus:outline-none focus:border-indigo-500 font-medium"
              placeholder="مثال: المزة"
            />
          </div>
          <div>
            <label className="block text-slate-600 font-bold mb-1">خط العرض (Latitude):</label>
            <input
              type="text"
              value={checkLat}
              onChange={(e) => setCheckLat(e.target.value)}
              className="w-full p-2 bg-white border border-slate-200 rounded-lg focus:outline-none focus:border-indigo-500 font-mono"
              placeholder="33.5138"
            />
          </div>
          <div>
            <label className="block text-slate-600 font-bold mb-1">خط الطول (Longitude):</label>
            <input
              type="text"
              value={checkLon}
              onChange={(e) => setCheckLon(e.target.value)}
              className="w-full p-2 bg-white border border-slate-200 rounded-lg focus:outline-none focus:border-indigo-500 font-mono"
              placeholder="36.2765"
            />
          </div>
          <div>
            <label className="block text-slate-600 font-bold mb-1">قيمة السلة (ل.س):</label>
            <div className="flex gap-2">
              <input
                type="number"
                value={checkSubtotal}
                onChange={(e) => setCheckSubtotal(e.target.value)}
                className="w-full p-2 bg-white border border-slate-200 rounded-lg focus:outline-none focus:border-indigo-500 font-mono font-bold"
                placeholder="75000"
              />
              <button
                type="button"
                onClick={handleTestServerCoverage}
                disabled={checkLoading}
                className="bg-indigo-600 hover:bg-indigo-700 text-white px-3 py-2 rounded-lg font-bold transition-all flex items-center justify-center shrink-0 cursor-pointer"
              >
                {checkLoading ? <RefreshCw className="w-4 h-4 animate-spin" /> : 'فحص'}
              </button>
            </div>
          </div>
        </div>

        {/* Quick Presets */}
        <div className="flex flex-wrap items-center gap-2 pt-1 text-[11px]">
          <span className="text-slate-500 font-bold">تجارب سريعة:</span>
          <button
            type="button"
            onClick={() => { setCheckCity('دمشق'); setCheckDistrict('المزة'); setCheckLat('33.5138'); setCheckLon('36.2765'); setCheckSubtotal('75000'); }}
            className="bg-white border border-slate-200 hover:border-indigo-400 px-2.5 py-1 rounded-md text-slate-700 font-medium transition-colors cursor-pointer"
          >
            📍 دمشق المزة (مغطى - عادي)
          </button>
          <button
            type="button"
            onClick={() => { setCheckCity('دمشق'); setCheckDistrict('المزة'); setCheckLat('33.5138'); setCheckLon('36.2765'); setCheckSubtotal('160000'); }}
            className="bg-white border border-slate-200 hover:border-emerald-400 px-2.5 py-1 rounded-md text-slate-700 font-medium transition-colors cursor-pointer"
          >
            🎁 دمشق (فوق حد الشحن المجاني)
          </button>
          <button
            type="button"
            onClick={() => { setCheckCity('درعا'); setCheckDistrict('المحطة'); setCheckLat('32.6250'); setCheckLon('36.1050'); setCheckSubtotal('50000'); }}
            className="bg-white border border-slate-200 hover:border-amber-400 px-2.5 py-1 rounded-md text-slate-700 font-medium transition-colors cursor-pointer"
          >
            ⚠️ درعا المحطة (مستبعدة افتراضياً)
          </button>
          <button
            type="button"
            onClick={() => { setCheckCity('تدمر'); setCheckDistrict('البادية'); setCheckLat('34.5600'); setCheckLon('38.2800'); setCheckSubtotal('50000'); }}
            className="bg-white border border-slate-200 hover:border-rose-400 px-2.5 py-1 rounded-md text-slate-700 font-medium transition-colors cursor-pointer"
          >
            🚫 خارج التغطية (تدمر)
          </button>
        </div>

        {/* Live Result Display */}
        {checkError && (
          <div className="bg-rose-50 border border-rose-200 p-3 rounded-xl text-rose-800 text-xs flex items-center gap-2">
            <AlertTriangle className="w-4 h-4 shrink-0 text-rose-600" />
            <span>{checkError}</span>
          </div>
        )}

        {checkResult && (
          <div className={`p-4 rounded-xl border text-xs space-y-2.5 transition-all ${
            checkResult.is_covered
              ? 'bg-emerald-50/70 border-emerald-200 text-emerald-950'
              : 'bg-rose-50/70 border-rose-200 text-rose-950'
          }`}>
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                {checkResult.is_covered ? (
                  <CheckCircle2 className="w-5 h-5 text-emerald-600 shrink-0" />
                ) : (
                  <AlertTriangle className="w-5 h-5 text-rose-600 shrink-0" />
                )}
                <span className="font-bold text-sm">
                  {checkResult.is_covered ? 'العنوان مشمول بالتغطية اللوجستية ومتاح للطلب' : 'العنوان غير متاح للتوصيل حالياً'}
                </span>
              </div>
              <span className={`px-2.5 py-0.5 rounded-full font-mono font-bold text-[11px] ${
                checkResult.is_covered ? 'bg-emerald-200 text-emerald-900' : 'bg-rose-200 text-rose-900'
              }`}>
                {checkResult.status} {checkResult.rejection_reason ? `(${checkResult.rejection_reason})` : ''}
              </span>
            </div>

            <p className="text-[12px] leading-relaxed">
              <strong>رسالة الخادم:</strong> {checkResult.message}
            </p>

            {checkResult.is_covered && (
              <div className="grid grid-cols-2 md:grid-cols-4 gap-2 pt-2 border-t border-emerald-200/60 font-medium text-[11px]">
                <div className="bg-white/80 p-2 rounded-lg border border-emerald-100">
                  <span className="text-slate-500 block">النطاق والفرع:</span>
                  <span className="font-bold text-slate-900">{checkResult.zone_name_ar}</span>
                  <span className="block text-[10px] text-indigo-700">{checkResult.branch_name_ar}</span>
                </div>
                <div className="bg-white/80 p-2 rounded-lg border border-emerald-100">
                  <span className="text-slate-500 block">رسوم التوصيل المحسوبة:</span>
                  <span className="font-mono font-bold text-slate-900 text-sm">
                    {checkResult.final_delivery_fee === 0 ? 'مجاناً (0 ل.س)' : `${checkResult.final_delivery_fee?.toLocaleString()} ل.س`}
                  </span>
                  {checkResult.surge_applied && (
                    <span className="block text-[10px] text-amber-700 font-bold">+ رسوم ذروة {checkResult.surge_fee?.toLocaleString()} ل.س</span>
                  )}
                </div>
                <div className="bg-white/80 p-2 rounded-lg border border-emerald-100">
                  <span className="text-slate-500 block">وقت التوصيل التقديري:</span>
                  <span className="font-bold text-blue-700 text-sm">{checkResult.estimated_minutes} دقيقة</span>
                  <span className="block text-[10px] text-slate-500">المسافة: {checkResult.distance_km} كم</span>
                </div>
                <div className="bg-white/80 p-2 rounded-lg border border-emerald-100">
                  <span className="text-slate-500 block">أوقات العمل المعتمدة:</span>
                  <span className="font-mono font-bold text-slate-900">{checkResult.opening_time} - {checkResult.closing_time}</span>
                  <span className="block text-[10px] text-emerald-700">شحن مجاني فوق {checkResult.free_delivery_threshold?.toLocaleString()} ل.س</span>
                </div>
              </div>
            )}
          </div>
        )}
      </div>

      {/* Zones Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
        {displayZones.map((zone) => {
          return (
            <div
              key={zone.id}
              className={`bg-white rounded-2xl border transition-all p-5 shadow-sm space-y-4 hover:shadow-md ${
                zone.is_active ? 'border-slate-200' : 'border-slate-200 opacity-70 bg-gray-50/50'
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
                    {zone.zone_name_ar.includes('درعا') && (
                      <span className="text-[10px] bg-amber-50 text-amber-800 border border-amber-300 px-2 py-0.5 rounded-full font-bold">
                        مستبعدة افتراضياً
                      </span>
                    )}
                  </div>
                  <h3 className="font-bold text-slate-900 text-sm mt-1.5">{zone.zone_name_ar}</h3>
                  {zone.city && (
                    <div className="flex items-center gap-1 text-[11px] text-slate-500 mt-0.5">
                      <MapPin className="w-3 h-3 text-slate-400" />
                      <span>{zone.city} {zone.district ? `• ${zone.district}` : ''}</span>
                    </div>
                  )}
                </div>
                <button
                  onClick={() => handleToggleActive(zone.id)}
                  className={`text-xs px-2.5 py-1 rounded-lg font-bold transition-colors cursor-pointer ${
                    zone.is_active
                      ? 'bg-emerald-100 text-emerald-800 hover:bg-emerald-200'
                      : 'bg-rose-100 text-rose-800 hover:bg-rose-200'
                  }`}
                  title={zone.is_active ? 'تعطيل النطاق' : 'تفعيل النطاق استثنائياً'}
                >
                  {zone.is_active ? 'مفعل وجاهز' : 'معطل ومستبعد'}
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
                {zone.opening_time && zone.closing_time && (
                  <div className="flex justify-between text-slate-600 pt-1 border-t border-slate-200/60">
                    <span className="flex items-center gap-1.5 text-[11px]">
                      <Clock className="w-3 h-3 text-slate-400" />
                      أوقات العمل:
                    </span>
                    <span className="font-mono text-[11px] font-bold text-slate-800">{zone.opening_time} - {zone.closing_time}</span>
                  </div>
                )}
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
                    className={`text-xs px-2.5 py-1 rounded-lg font-bold transition-all cursor-pointer ${
                      zone.is_surge_pricing_active
                        ? 'bg-amber-500 text-white shadow-xs'
                        : 'bg-slate-200 text-slate-700 hover:bg-slate-300'
                    }`}
                  >
                    {zone.is_surge_pricing_active ? `مفعل (+${(zone.surge_fee || 2500).toLocaleString()} ل.س)` : 'معطل'}
                  </button>
                </div>
                <p className="text-[11px] text-amber-800 leading-relaxed">
                  {zone.is_surge_pricing_active
                    ? `يتم تطبيق رسوم إضافية ${(zone.surge_fee || 2500).toLocaleString()} ل.س تلقائياً بسبب ذروة الطلبات الحالية.`
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
          <div className="bg-white rounded-2xl shadow-xl w-full max-w-xl max-h-[90vh] overflow-y-auto border border-gray-100">
            <div className="p-5 border-b border-gray-100 flex items-center justify-between bg-slate-50 sticky top-0 z-10">
              <div className="flex items-center gap-2">
                <Compass className="w-5 h-5 text-blue-600" />
                <h3 className="font-bold text-gray-900 text-sm">
                  {editingZone ? 'تعديل نطاق التغطية الجغرافية في الخادم' : 'إضافة نطاق جغرافي جديد إلى خادم PostgreSQL'}
                </h3>
              </div>
              <button
                onClick={() => setIsModalOpen(false)}
                className="text-gray-400 hover:text-gray-600 text-lg font-bold cursor-pointer"
              >
                ×
              </button>
            </div>

            <form onSubmit={handleSaveZone} className="p-5 space-y-4 text-xs">
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-gray-700 font-bold mb-1">اسم المنطقة بالعربية *</label>
                  <input
                    type="text"
                    required
                    placeholder="مثال: دمشق المركزية (المزة)"
                    value={formData.zone_name_ar || ''}
                    onChange={(e) => setFormData({ ...formData, zone_name_ar: e.target.value })}
                    className="w-full p-2.5 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:border-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-gray-700 font-bold mb-1">المدينة *</label>
                  <input
                    type="text"
                    required
                    placeholder="مثال: دمشق"
                    value={formData.city || ''}
                    onChange={(e) => setFormData({ ...formData, city: e.target.value })}
                    className="w-full p-2.5 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:border-blue-500"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-gray-700 font-bold mb-1">الحي / المنطقة الفرعية</label>
                  <input
                    type="text"
                    placeholder="مثال: المزة، أبو رمانة"
                    value={formData.district || ''}
                    onChange={(e) => setFormData({ ...formData, district: e.target.value })}
                    className="w-full p-2.5 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:border-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-gray-700 font-bold mb-1">الفرع المسؤول في الخادم *</label>
                  <select
                    value={formData.branch_id || 'b-dam-01'}
                    onChange={(e) => setFormData({ ...formData, branch_id: e.target.value })}
                    className="w-full p-2.5 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:border-blue-500"
                  >
                    <option value="b-dam-01">فرع دمشق المركزي (b-dam-01)</option>
                    <option value="b-brale01">فرع حلب الشهباء (b-brale01)</option>
                    <option value="b-brtest4871">فرع اللاذقية (b-brtest4871)</option>
                    <option value="b-ruh-01">فرع الرياض المركزي (b-ruh-01)</option>
                    <option value="b-jed-01">فرع جدة الكورنيش (b-jed-01)</option>
                    <option value="b-dmm-01">فرع الدمام الشاطئ (b-dmm-01)</option>
                  </select>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-gray-700 font-bold mb-1">مركز التوزيع / المستودع *</label>
                  <input
                    type="text"
                    required
                    value={formData.dark_store_code || 'WH-DAM-HUB'}
                    onChange={(e) => setFormData({ ...formData, dark_store_code: e.target.value })}
                    className="w-full p-2.5 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:border-blue-500 font-mono"
                  />
                </div>
                <div>
                  <label className="block text-gray-700 font-bold mb-1">نصف القطر بالكيلومتر *</label>
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
                  <label className="block text-gray-700 font-bold mb-1">إحداثي العرض (Center Lat)</label>
                  <input
                    type="number"
                    step="0.0001"
                    value={formData.center_latitude || 33.5138}
                    onChange={(e) => setFormData({ ...formData, center_latitude: parseFloat(e.target.value) })}
                    className="w-full p-2.5 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:border-blue-500 font-mono"
                  />
                </div>
                <div>
                  <label className="block text-gray-700 font-bold mb-1">إحداثي الطول (Center Lon)</label>
                  <input
                    type="number"
                    step="0.0001"
                    value={formData.center_longitude || 36.2765}
                    onChange={(e) => setFormData({ ...formData, center_longitude: parseFloat(e.target.value) })}
                    className="w-full p-2.5 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:border-blue-500 font-mono"
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

              <div className="grid grid-cols-3 gap-3">
                <div>
                  <label className="block text-gray-700 font-bold mb-1">وقت الوصول (دقيقة) *</label>
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
                  <label className="block text-gray-700 font-bold mb-1">وقت فتح الخدمة</label>
                  <input
                    type="text"
                    value={formData.opening_time || '08:00:00'}
                    onChange={(e) => setFormData({ ...formData, opening_time: e.target.value })}
                    className="w-full p-2.5 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:border-blue-500 font-mono"
                    placeholder="08:00:00"
                  />
                </div>
                <div>
                  <label className="block text-gray-700 font-bold mb-1">وقت إغلاق الخدمة</label>
                  <input
                    type="text"
                    value={formData.closing_time || '23:59:59'}
                    onChange={(e) => setFormData({ ...formData, closing_time: e.target.value })}
                    className="w-full p-2.5 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:border-blue-500 font-mono"
                    placeholder="23:59:59"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
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
                <div>
                  <label className="block text-gray-700 font-bold mb-1">السعة القصوى (طلبات/ساعة)</label>
                  <input
                    type="number"
                    min="1"
                    value={formData.max_hourly_capacity || 50}
                    onChange={(e) => setFormData({ ...formData, max_hourly_capacity: parseInt(e.target.value) })}
                    className="w-full p-2.5 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:border-blue-500"
                  />
                </div>
              </div>

              <div className="pt-4 border-t border-gray-100 flex items-center justify-end gap-2">
                <button
                  type="button"
                  onClick={() => setIsModalOpen(false)}
                  disabled={isSubmitting}
                  className="px-4 py-2 bg-gray-100 hover:bg-gray-200 text-gray-700 rounded-xl font-bold transition-colors cursor-pointer"
                >
                  إلغاء
                </button>
                <button
                  type="submit"
                  disabled={isSubmitting}
                  className="px-5 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-xl font-bold transition-colors flex items-center gap-1.5 cursor-pointer"
                >
                  {isSubmitting && <RefreshCw className="w-3.5 h-3.5 animate-spin" />}
                  <span>{editingZone ? 'حفظ التعديلات في الخادم' : 'إضافة النطاق في الخادم'}</span>
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
