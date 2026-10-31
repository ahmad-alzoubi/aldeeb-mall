import React, { useState } from 'react';
import { 
  Store, 
  DollarSign, 
  CheckCircle2, 
  Clock, 
  AlertTriangle, 
  Search, 
  Plus, 
  Download, 
  Building, 
  ShieldCheck, 
  FileText, 
  ArrowUpRight, 
  BadgePercent, 
  Percent,
  Check,
  X,
  Send,
  Sparkles,
  HelpCircle
} from 'lucide-react';

export interface MarketplaceVendor {
  id: string;
  name: string;
  crNumber: string;
  taxNumber: string;
  category: string;
  fulfillmentModel: 'FBA' | 'FBM' | 'FARM_DIRECT';
  commissionRate: number; // percentage, e.g. 10
  status: 'ACTIVE' | 'SUSPENDED' | 'UNDER_AUDIT';
  rating: number;
  totalProducts: number;
  monthlyGMV: number;
  pendingBalance: number;
  bankIban: string;
  bankName: string;
  contactPerson: string;
  phone: string;
  slaOnTimeRate: number;
  returnRate: number;
}

export interface VendorPayoutBatch {
  id: string;
  vendorId: string;
  vendorName: string;
  period: string;
  grossSales: number;
  commissionDeducted: number;
  storageFees: number;
  disputeDeduction: number;
  netPayout: number;
  bankIban: string;
  status: 'PROCESSED' | 'PENDING' | 'HELD';
  transferDate?: string;
  referenceNumber?: string;
}

export interface VendorApplication {
  id: string;
  businessName: string;
  ownerName: string;
  phone: string;
  email: string;
  category: string;
  proposedModel: 'FBA' | 'FBM' | 'FARM_DIRECT';
  crNumber: string;
  annualTurnoverEst: string;
  submittedAt: string;
  status: 'PENDING' | 'APPROVED' | 'REJECTED';
}

const initialVendors: MarketplaceVendor[] = [
  {
    id: 'VEND-001',
    name: 'مزارع أسترا الوطنية للمنتجات العضوية',
    crNumber: '1010892341',
    taxNumber: '310928374800003',
    category: 'خضار وفواكه طازجة',
    fulfillmentModel: 'FARM_DIRECT',
    commissionRate: 5.5,
    status: 'ACTIVE',
    rating: 4.9,
    totalProducts: 48,
    monthlyGMV: 185000,
    pendingBalance: 32450,
    bankIban: 'SA4480000201608010192831',
    bankName: 'مصرف الراجحي',
    contactPerson: 'م. فهد القحطاني',
    phone: '+966 50 112 2334',
    slaOnTimeRate: 98.4,
    returnRate: 0.6,
  },
  {
    id: 'VEND-002',
    name: 'مؤسسة نخبة تمور القصيم الفاخرة',
    crNumber: '1131098452',
    taxNumber: '311827465900003',
    category: 'تمور ومكسرات وحلويات',
    fulfillmentModel: 'FBA',
    commissionRate: 9.0,
    status: 'ACTIVE',
    rating: 4.8,
    totalProducts: 32,
    monthlyGMV: 124000,
    pendingBalance: 24800,
    bankIban: 'SA1210000009823471029384',
    bankName: 'البنك الأهلي السعودي (SNB)',
    contactPerson: 'سليمان التويجري',
    phone: '+966 55 443 3221',
    slaOnTimeRate: 99.1,
    returnRate: 0.8,
  },
  {
    id: 'VEND-003',
    name: 'شركة روائع المناحل والعسل البري',
    crNumber: '1010776512',
    taxNumber: '300928374100003',
    category: 'عسل وزيوت طبيعية',
    fulfillmentModel: 'FBA',
    commissionRate: 11.5,
    status: 'ACTIVE',
    rating: 4.7,
    totalProducts: 19,
    monthlyGMV: 92000,
    pendingBalance: 17200,
    bankIban: 'SA9850000001239847102938',
    bankName: 'بنك الرياض',
    contactPerson: 'عبدالله الشهري',
    phone: '+966 54 887 6655',
    slaOnTimeRate: 97.2,
    returnRate: 1.2,
  },
  {
    id: 'VEND-004',
    name: 'مؤسسة بهارات وتوابل الشرق العطرية',
    crNumber: '2050119834',
    taxNumber: '302918273600003',
    category: 'بهارات وعطارة',
    fulfillmentModel: 'FBM',
    commissionRate: 8.0,
    status: 'UNDER_AUDIT',
    rating: 4.3,
    totalProducts: 64,
    monthlyGMV: 56000,
    pendingBalance: 8900,
    bankIban: 'SA6520000004918273645192',
    bankName: 'بنك الإنماء',
    contactPerson: 'طارق باحمدان',
    phone: '+966 56 332 1199',
    slaOnTimeRate: 91.5,
    returnRate: 3.2,
  },
  {
    id: 'VEND-005',
    name: 'مستودعات كابتن المخابز الإيطالية',
    crNumber: '1010654321',
    taxNumber: '301122334400003',
    category: 'مخبوزات ومعجنات مجمدة',
    fulfillmentModel: 'FBA',
    commissionRate: 10.0,
    status: 'ACTIVE',
    rating: 4.9,
    totalProducts: 26,
    monthlyGMV: 115000,
    pendingBalance: 21300,
    bankIban: 'SA3380000100608010293847',
    bankName: 'مصرف الراجحي',
    contactPerson: 'ماريو روسي / هشام السعيد',
    phone: '+966 50 998 7766',
    slaOnTimeRate: 99.5,
    returnRate: 0.4,
  },
];

const initialPayouts: VendorPayoutBatch[] = [
  {
    id: 'PAY-2026-W43-01',
    vendorId: 'VEND-001',
    vendorName: 'مزارع أسترا الوطنية للمنتجات العضوية',
    period: '2026-10-20 إلى 2026-10-27',
    grossSales: 48500,
    commissionDeducted: 2667.5,
    storageFees: 0,
    disputeDeduction: 120,
    netPayout: 45712.5,
    bankIban: 'SA4480000201608010192831',
    status: 'PROCESSED',
    transferDate: '2026-10-28 10:15',
    referenceNumber: 'SARIE-TX-9982410',
  },
  {
    id: 'PAY-2026-W43-02',
    vendorId: 'VEND-002',
    vendorName: 'مؤسسة نخبة تمور القصيم الفاخرة',
    period: '2026-10-20 إلى 2026-10-27',
    grossSales: 31200,
    commissionDeducted: 2808,
    storageFees: 350,
    disputeDeduction: 0,
    netPayout: 28042,
    bankIban: 'SA1210000009823471029384',
    status: 'PENDING',
  },
  {
    id: 'PAY-2026-W43-03',
    vendorId: 'VEND-003',
    vendorName: 'شركة روائع المناحل والعسل البري',
    period: '2026-10-20 إلى 2026-10-27',
    grossSales: 22800,
    commissionDeducted: 2622,
    storageFees: 180,
    disputeDeduction: 0,
    netPayout: 19998,
    bankIban: 'SA9850000001239847102938',
    status: 'PENDING',
  },
];

const initialApplications: VendorApplication[] = [
  {
    id: 'APP-109',
    businessName: 'معاصر زيت الزيتون الجوف الطبيعي',
    ownerName: 'بدر الشمري',
    phone: '+966 53 221 4455',
    email: 'info@joufolive.sa',
    category: 'زيوت طبيعية وعضوية',
    proposedModel: 'FBA',
    crNumber: '3400192837',
    annualTurnoverEst: '1.2M - 2M ل.س',
    submittedAt: 'منذ ساعتين',
    status: 'PENDING',
  },
  {
    id: 'APP-108',
    businessName: 'ألبان ومزارع حائل الريفية',
    ownerName: 'خالد السالم',
    phone: '+966 50 776 5544',
    email: 'contact@haildairy.com',
    category: 'ألبان وأجبان طازجة',
    proposedModel: 'FARM_DIRECT',
    crNumber: '3350182746',
    annualTurnoverEst: '3M - 5M ل.س',
    submittedAt: 'منذ يوم',
    status: 'PENDING',
  },
];

export const MarketplaceVendorsPage: React.FC = () => {
  const [vendors, setVendors] = useState<MarketplaceVendor[]>(initialVendors);
  const [payouts, setPayouts] = useState<VendorPayoutBatch[]>(initialPayouts);
  const [applications, setApplications] = useState<VendorApplication[]>(initialApplications);
  const [activeTab, setActiveTab] = useState<'vendors' | 'payouts' | 'applications' | 'matrix'>('vendors');
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedModel, setSelectedModel] = useState<string>('ALL');

  // Modals
  const [showAddVendorModal, setShowAddVendorModal] = useState(false);
  const [showPayoutModal, setShowPayoutModal] = useState(false);
  const [selectedPayout, setSelectedPayout] = useState<VendorPayoutBatch | null>(null);

  // New Vendor Form
  const [newVendorName, setNewVendorName] = useState('');
  const [newVendorCR, setNewVendorCR] = useState('');
  const [newVendorTax, setNewVendorTax] = useState('');
  const [newVendorCategory, setNewVendorCategory] = useState('منتجات عضوية وصحية');
  const [newVendorModel, setNewVendorModel] = useState<'FBA' | 'FBM' | 'FARM_DIRECT'>('FBA');
  const [newVendorCommission, setNewVendorCommission] = useState(10);
  const [newVendorIBAN, setNewVendorIBAN] = useState('SA');
  const [newVendorBank, setNewVendorBank] = useState('مصرف الراجحي');
  const [newVendorContact, setNewVendorContact] = useState('');
  const [newVendorPhone, setNewVendorPhone] = useState('');

  // Metrics
  const totalGMV = vendors.reduce((acc, v) => acc + v.monthlyGMV, 0);
  const totalCommissionEarned = vendors.reduce((acc, v) => acc + (v.monthlyGMV * v.commissionRate) / 100, 0);
  const totalPendingPayouts = vendors.reduce((acc, v) => acc + v.pendingBalance, 0);

  const filteredVendors = vendors.filter((v) => {
    const matchesSearch = v.name.includes(searchQuery) || v.crNumber.includes(searchQuery) || v.category.includes(searchQuery);
    const matchesModel = selectedModel === 'ALL' || v.fulfillmentModel === selectedModel;
    return matchesSearch && matchesModel;
  });

  const handleCreateVendor = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newVendorName || !newVendorCR) return;

    const newV: MarketplaceVendor = {
      id: `VEND-00${vendors.length + 1}`,
      name: newVendorName,
      crNumber: newVendorCR,
      taxNumber: newVendorTax || `3${Math.floor(10000000000000 + Math.random() * 90000000000000)}00003`,
      category: newVendorCategory,
      fulfillmentModel: newVendorModel,
      commissionRate: Number(newVendorCommission),
      status: 'ACTIVE',
      rating: 5.0,
      totalProducts: 1,
      monthlyGMV: 0,
      pendingBalance: 0,
      bankIban: newVendorIBAN,
      bankName: newVendorBank,
      contactPerson: newVendorContact || 'المسؤول التجاري',
      phone: newVendorPhone || '+966 50 000 0000',
      slaOnTimeRate: 100,
      returnRate: 0.0,
    };

    setVendors([newV, ...vendors]);
    setShowAddVendorModal(false);
    resetForm();
  };

  const resetForm = () => {
    setNewVendorName('');
    setNewVendorCR('');
    setNewVendorTax('');
    setNewVendorCommission(10);
    setNewVendorIBAN('SA');
    setNewVendorContact('');
    setNewVendorPhone('');
  };

  const handleProcessSARIETransfer = (payoutId: string) => {
    const txId = `SARIE-TX-${Math.floor(1000000 + Math.random() * 9000000)}`;
    setPayouts(payouts.map(p => {
      if (p.id === payoutId) {
        return {
          ...p,
          status: 'PROCESSED',
          transferDate: new Date().toISOString().replace('T', ' ').slice(0, 16),
          referenceNumber: txId,
        };
      }
      return p;
    }));
    setShowPayoutModal(false);
  };

  const handleApproveApp = (appId: string) => {
    const app = applications.find(a => a.id === appId);
    if (!app) return;

    const newV: MarketplaceVendor = {
      id: `VEND-00${vendors.length + 1}`,
      name: app.businessName,
      crNumber: app.crNumber,
      taxNumber: `310${Math.floor(100000000000 + Math.random() * 900000000000)}00003`,
      category: app.category,
      fulfillmentModel: app.proposedModel,
      commissionRate: app.proposedModel === 'FARM_DIRECT' ? 5.5 : 9.5,
      status: 'ACTIVE',
      rating: 5.0,
      totalProducts: 10,
      monthlyGMV: 15000,
      pendingBalance: 0,
      bankIban: 'SA4480000201608010192831',
      bankName: 'مصرف الراجحي',
      contactPerson: app.ownerName,
      phone: app.phone,
      slaOnTimeRate: 100,
      returnRate: 0.0,
    };

    setVendors([newV, ...vendors]);
    setApplications(applications.map(a => a.id === appId ? { ...a, status: 'APPROVED' } : a));
  };

  const handleRejectApp = (appId: string) => {
    setApplications(applications.map(a => a.id === appId ? { ...a, status: 'REJECTED' } : a));
  };

  const toggleVendorStatus = (vendorId: string) => {
    setVendors(vendors.map(v => {
      if (v.id === vendorId) {
        const nextStatus: MarketplaceVendor['status'] = 
          v.status === 'ACTIVE' ? 'SUSPENDED' : 'ACTIVE';
        return { ...v, status: nextStatus };
      }
      return v;
    }));
  };

  return (
    <div className="space-y-6">
      {/* Top Banner */}
      <div className="bg-gradient-to-r from-slate-900 via-indigo-950 to-slate-900 border border-indigo-900/50 rounded-2xl p-6 text-white shadow-xl flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <div>
          <div className="flex items-center gap-3">
            <div className="p-3 bg-indigo-600/30 border border-indigo-500/40 rounded-xl text-indigo-400">
              <Store className="w-7 h-7" />
            </div>
            <div>
              <h1 className="text-2xl font-bold flex items-center gap-2">
                بوابة تجار الماركت بليس والعمولات (3P Marketplace)
                <span className="text-xs bg-indigo-500/20 text-indigo-300 border border-indigo-500/30 px-2.5 py-0.5 rounded-full font-mono">
                  ZATCA & SARIE Ready
                </span>
              </h1>
              <p className="text-sm text-slate-400 mt-1">
                إدارة شبكة المتاجر الشريكة، عقود التخزين FBA / FBM، تسويات أرباح التجار عبر نظام سريع البنكي
              </p>
            </div>
          </div>
        </div>

        <div className="flex items-center gap-3 w-full md:w-auto">
          <button
            onClick={() => setShowAddVendorModal(true)}
            className="flex-1 md:flex-none flex items-center justify-center gap-2 bg-indigo-600 hover:bg-indigo-700 text-white font-medium px-4 py-2.5 rounded-xl transition shadow-lg shadow-indigo-600/30 text-sm"
          >
            <Plus className="w-4 h-4" />
            تسجيل تاجر شريك جديد
          </button>
        </div>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs flex items-center justify-between">
          <div>
            <p className="text-xs font-medium text-slate-700">التجار المعتمدون</p>
            <h3 className="text-2xl font-extrabold text-slate-900 mt-1">{vendors.length} تاجر</h3>
            <p className="text-xs text-emerald-600 font-medium mt-1 flex items-center gap-1">
              <ShieldCheck className="w-3.5 h-3.5" />
              100% موثقين بالسجل التجاري
            </p>
          </div>
          <div className="p-3 bg-blue-50 text-blue-600 rounded-xl">
            <Building className="w-6 h-6" />
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs flex items-center justify-between">
          <div>
            <p className="text-xs font-medium text-slate-700">مبيعات التجار الشهرية (3P GMV)</p>
            <h3 className="text-2xl font-extrabold text-slate-900 mt-1">{totalGMV.toLocaleString()} ل.س</h3>
            <p className="text-xs text-blue-600 font-medium mt-1 flex items-center gap-1">
              <ArrowUpRight className="w-3.5 h-3.5" />
              +24% نمو الماركت بليس
            </p>
          </div>
          <div className="p-3 bg-emerald-50 text-emerald-600 rounded-xl">
            <DollarSign className="w-6 h-6" />
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs flex items-center justify-between">
          <div>
            <p className="text-xs font-medium text-slate-700">صافي عمولات المول المحصلة</p>
            <h3 className="text-2xl font-extrabold text-indigo-600 mt-1">{totalCommissionEarned.toLocaleString()} ل.س</h3>
            <p className="text-xs text-slate-700 font-medium mt-1">
              متوسط عمولة المنصة 8.4%
            </p>
          </div>
          <div className="p-3 bg-indigo-50 text-indigo-600 rounded-xl">
            <BadgePercent className="w-6 h-6" />
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs flex items-center justify-between">
          <div>
            <p className="text-xs font-medium text-slate-700">أرصدة التسوية البنكية المعلقة</p>
            <h3 className="text-2xl font-extrabold text-amber-600 mt-1">{totalPendingPayouts.toLocaleString()} ل.س</h3>
            <p className="text-xs text-amber-600 font-medium mt-1 flex items-center gap-1">
              <Clock className="w-3.5 h-3.5" />
              جاهزة لدورة تحويل الأربعاء
            </p>
          </div>
          <div className="p-3 bg-amber-50 text-amber-600 rounded-xl">
            <FileText className="w-6 h-6" />
          </div>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex border-b border-slate-200">
        <button
          onClick={() => setActiveTab('vendors')}
          className={`pb-3 px-4 text-sm font-bold border-b-2 flex items-center gap-2 transition ${
            activeTab === 'vendors'
              ? 'border-indigo-600 text-indigo-600'
              : 'border-transparent text-slate-500 hover:text-slate-700'
          }`}
        >
          <Store className="w-4 h-4" />
          شبكة التجار المعتمدين ({vendors.length})
        </button>

        <button
          onClick={() => setActiveTab('payouts')}
          className={`pb-3 px-4 text-sm font-bold border-b-2 flex items-center gap-2 transition ${
            activeTab === 'payouts'
              ? 'border-indigo-600 text-indigo-600'
              : 'border-transparent text-slate-500 hover:text-slate-700'
          }`}
        >
          <DollarSign className="w-4 h-4" />
          دورات التسوية والتحويلات SARIE ({payouts.length})
        </button>

        <button
          onClick={() => setActiveTab('applications')}
          className={`pb-3 px-4 text-sm font-bold border-b-2 flex items-center gap-2 transition ${
            activeTab === 'applications'
              ? 'border-indigo-600 text-indigo-600'
              : 'border-transparent text-slate-500 hover:text-slate-700'
          }`}
        >
          <Clock className="w-4 h-4" />
          طلبات الانضمام الجديدة ({applications.filter(a => a.status === 'PENDING').length})
        </button>

        <button
          onClick={() => setActiveTab('matrix')}
          className={`pb-3 px-4 text-sm font-bold border-b-2 flex items-center gap-2 transition ${
            activeTab === 'matrix'
              ? 'border-indigo-600 text-indigo-600'
              : 'border-transparent text-slate-500 hover:text-slate-700'
          }`}
        >
          <Percent className="w-4 h-4" />
          مصفوفة العمولات ورسوم التخزين FBA
        </button>
      </div>

      {/* TAB 1: VENDORS */}
      {activeTab === 'vendors' && (
        <div className="space-y-4">
          <div className="bg-white p-4 rounded-xl border border-slate-200 flex flex-col md:flex-row gap-4 items-center justify-between">
            <div className="relative w-full md:w-80">
              <Search className="w-4 h-4 text-slate-400 absolute right-3 top-3" />
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="ابحث بالاسم أو السجل التجاري..."
                className="w-full pl-4 pr-9 py-2 bg-slate-50 border border-slate-200 rounded-lg text-sm focus:outline-hidden focus:border-indigo-500"
              />
            </div>

            <div className="flex items-center gap-2 w-full md:w-auto overflow-x-auto pb-1 md:pb-0">
              <span className="text-xs font-medium text-slate-700">نموذج الشحن:</span>
              {(['ALL', 'FBA', 'FBM', 'FARM_DIRECT'] as const).map((model) => (
                <button
                  key={model}
                  onClick={() => setSelectedModel(model)}
                  className={`text-xs px-3 py-1.5 rounded-lg font-medium transition ${
                    selectedModel === model
                      ? 'bg-indigo-600 text-white'
                      : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
                  }`}
                >
                  {model === 'ALL' && 'الكل'}
                  {model === 'FBA' && 'تخزين وشحن الديب (FBA)'}
                  {model === 'FBM' && 'شحن التاجر (FBM)'}
                  {model === 'FARM_DIRECT' && 'مزارع وطنية مباشرة'}
                </button>
              ))}
            </div>
          </div>

          <div className="bg-white rounded-xl border border-slate-200 overflow-hidden shadow-xs">
            <div className="overflow-x-auto">
              <table className="w-full text-right text-sm">
                <thead className="bg-slate-50 text-slate-700 text-xs font-bold border-b border-slate-200">
                  <tr>
                    <th className="p-3.5">التاجر / السجل التجاري</th>
                    <th className="p-3.5">القسم الرئيسي</th>
                    <th className="p-3.5">نموذج التخزين والشحن</th>
                    <th className="p-3.5">العمولة %</th>
                    <th className="p-3.5">المبيعات الشهرية</th>
                    <th className="p-3.5">الرصيد المعلق</th>
                    <th className="p-3.5">التزام الـ SLA</th>
                    <th className="p-3.5">الحالة</th>
                    <th className="p-3.5 text-center">إجراءات</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 text-slate-700">
                  {filteredVendors.map((v) => (
                    <tr key={v.id} className="hover:bg-slate-50 transition">
                      <td className="p-3.5">
                        <div className="font-bold text-slate-900">{v.name}</div>
                        <div className="text-xs text-slate-400 font-mono">
                          س.ت: {v.crNumber} | {v.contactPerson} ({v.phone})
                        </div>
                      </td>
                      <td className="p-3.5">
                        <span className="bg-slate-100 text-slate-700 px-2 py-0.5 rounded text-xs">
                          {v.category}
                        </span>
                      </td>
                      <td className="p-3.5">
                        {v.fulfillmentModel === 'FBA' && (
                          <span className="inline-flex items-center gap-1 bg-blue-50 text-blue-700 font-bold px-2 py-0.5 rounded text-xs border border-blue-200">
                            <Sparkles className="w-3 h-3 text-blue-600" />
                            شحن وتخزين الديب (FBA)
                          </span>
                        )}
                        {v.fulfillmentModel === 'FBM' && (
                          <span className="inline-flex items-center gap-1 bg-amber-50 text-amber-700 font-bold px-2 py-0.5 rounded text-xs border border-amber-200">
                            شحن من مستودع التاجر (FBM)
                          </span>
                        )}
                        {v.fulfillmentModel === 'FARM_DIRECT' && (
                          <span className="inline-flex items-center gap-1 bg-emerald-50 text-emerald-700 font-bold px-2 py-0.5 rounded text-xs border border-emerald-200">
                            مزارع طازجة مباشرة 🇸🇦
                          </span>
                        )}
                      </td>
                      <td className="p-3.5 font-bold text-indigo-600">
                        {v.commissionRate}%
                      </td>
                      <td className="p-3.5 font-bold text-slate-900">
                        {v.monthlyGMV.toLocaleString()} ل.س
                      </td>
                      <td className="p-3.5 font-bold text-amber-600">
                        {v.pendingBalance.toLocaleString()} ل.س
                      </td>
                      <td className="p-3.5">
                        <div className="text-xs font-bold text-emerald-600">{v.slaOnTimeRate}% في الوقت</div>
                        <div className="text-[11px] text-slate-400">مرتجعات: {v.returnRate}%</div>
                      </td>
                      <td className="p-3.5">
                        {v.status === 'ACTIVE' && (
                          <span className="bg-emerald-100 text-emerald-800 font-bold px-2 py-0.5 rounded-full text-xs">
                            نشط معتمد
                          </span>
                        )}
                        {v.status === 'SUSPENDED' && (
                          <span className="bg-rose-100 text-rose-800 font-bold px-2 py-0.5 rounded-full text-xs">
                            موقوف مؤقتاً
                          </span>
                        )}
                        {v.status === 'UNDER_AUDIT' && (
                          <span className="bg-amber-100 text-amber-800 font-bold px-2 py-0.5 rounded-full text-xs">
                            تحت التدقيق الدوري
                          </span>
                        )}
                      </td>
                      <td className="p-3.5 text-center">
                        <div className="flex items-center justify-center gap-2">
                          <button
                            onClick={() => toggleVendorStatus(v.id)}
                            className={`px-2.5 py-1 text-xs font-bold rounded-lg transition ${
                              v.status === 'ACTIVE'
                                ? 'bg-rose-50 text-rose-700 hover:bg-rose-100'
                                : 'bg-emerald-50 text-emerald-700 hover:bg-emerald-100'
                            }`}
                          >
                            {v.status === 'ACTIVE' ? 'إيقاف' : 'تفعيل'}
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

      {/* TAB 2: PAYOUTS */}
      {activeTab === 'payouts' && (
        <div className="space-y-4">
          <div className="bg-amber-50 border border-amber-200 rounded-xl p-4 flex items-center justify-between text-amber-800 text-sm">
            <div className="flex items-center gap-3">
              <Clock className="w-5 h-5 text-amber-600" />
              <div>
                <span className="font-bold">موعد دورة التحويل البنكي الأسبوعية: </span>
                كل يوم أربعاء الساعة 10:00 صباحاً عبر شبكة سريع (SARIE Instant Transfer).
              </div>
            </div>
            <button
              onClick={() => {
                alert('تمت مزامنة جميع فواتير الضريبة والتحقق من حسابات الآيبان بنجاح.');
              }}
              className="bg-amber-600 hover:bg-amber-700 text-white text-xs font-bold px-3 py-1.5 rounded-lg shadow-xs"
            >
              مزامنة فواتير ZATCA
            </button>
          </div>

          <div className="bg-white rounded-xl border border-slate-200 overflow-hidden shadow-xs">
            <div className="overflow-x-auto">
              <table className="w-full text-right text-sm">
                <thead className="bg-slate-50 text-slate-700 text-xs font-bold border-b border-slate-200">
                  <tr>
                    <th className="p-3.5">رقم الدفعة / التاجر</th>
                    <th className="p-3.5">الفترة المحاسبية</th>
                    <th className="p-3.5">إجمالي المبيعات</th>
                    <th className="p-3.5">عمولة المول (-)</th>
                    <th className="p-3.5">رسوم تخزين/نزاعات (-)</th>
                    <th className="p-3.5">صافي المستحق للتحويل</th>
                    <th className="p-3.5">حساب الآيبان (IBAN)</th>
                    <th className="p-3.5">حالة التحويل</th>
                    <th className="p-3.5 text-center">إجراء التحويل</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {payouts.map((p) => (
                    <tr key={p.id} className="hover:bg-slate-50 transition">
                      <td className="p-3.5">
                        <div className="font-bold text-slate-900">{p.vendorName}</div>
                        <div className="text-xs text-slate-400 font-mono">{p.id}</div>
                      </td>
                      <td className="p-3.5 text-xs text-slate-600">
                        {p.period}
                      </td>
                      <td className="p-3.5 font-bold text-slate-900">
                        {p.grossSales.toLocaleString()} ل.س
                      </td>
                      <td className="p-3.5 text-rose-600 font-medium">
                        -{p.commissionDeducted.toLocaleString()} ل.س
                      </td>
                      <td className="p-3.5 text-slate-500">
                        -{(p.storageFees + p.disputeDeduction).toLocaleString()} ل.س
                      </td>
                      <td className="p-3.5 font-extrabold text-emerald-600 text-base">
                        {p.netPayout.toLocaleString()} ل.س
                      </td>
                      <td className="p-3.5 text-xs font-mono text-slate-600">
                        {p.bankIban}
                      </td>
                      <td className="p-3.5">
                        {p.status === 'PROCESSED' ? (
                          <div className="flex flex-col">
                            <span className="bg-emerald-100 text-emerald-800 font-bold px-2 py-0.5 rounded-full text-xs inline-flex items-center gap-1 w-max">
                              <CheckCircle2 className="w-3 h-3" /> تم التحويل بنجاح
                            </span>
                            <span className="text-[10px] text-slate-400 font-mono mt-1">
                              {p.referenceNumber}
                            </span>
                          </div>
                        ) : (
                          <span className="bg-amber-100 text-amber-800 font-bold px-2 py-0.5 rounded-full text-xs">
                            بانتظار التحويل
                          </span>
                        )}
                      </td>
                      <td className="p-3.5 text-center">
                        {p.status === 'PENDING' ? (
                          <button
                            onClick={() => {
                              setSelectedPayout(p);
                              setShowPayoutModal(true);
                            }}
                            className="bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold px-3 py-1.5 rounded-lg flex items-center gap-1 mx-auto transition"
                          >
                            <Send className="w-3 h-3" />
                            تنفيذ عبر SARIE
                          </button>
                        ) : (
                          <button
                            onClick={() => alert(`فاتورة الإشعار الدائن والضريبة لـ ${p.id} متوافقة مع هيئة الزكاة والضريبة ZATCA`)}
                            className="text-indigo-600 hover:text-indigo-800 text-xs font-bold flex items-center gap-1 mx-auto"
                          >
                            <Download className="w-3 h-3" />
                            فاتورة ZATCA
                          </button>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

      {/* TAB 3: APPLICATIONS */}
      {activeTab === 'applications' && (
        <div className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {applications.map((app) => (
              <div
                key={app.id}
                className={`bg-white rounded-xl border p-5 transition shadow-xs ${
                  app.status === 'APPROVED' ? 'border-emerald-200 bg-emerald-50/20' : 'border-slate-200'
                }`}
              >
                <div className="flex items-start justify-between">
                  <div>
                    <h3 className="text-base font-bold text-slate-900">{app.businessName}</h3>
                    <p className="text-xs text-slate-500 mt-0.5">
                      مقدم الطلب: {app.ownerName} | هاتف: {app.phone} | بريد: {app.email}
                    </p>
                  </div>
                  <span className={`text-xs font-bold px-2.5 py-1 rounded-full ${
                    app.status === 'PENDING' ? 'bg-amber-100 text-amber-800' :
                    app.status === 'APPROVED' ? 'bg-emerald-100 text-emerald-800' : 'bg-rose-100 text-rose-800'
                  }`}>
                    {app.status === 'PENDING' && 'قيد المراجعة'}
                    {app.status === 'APPROVED' && 'تم القبول والاعتماد'}
                    {app.status === 'REJECTED' && 'تم الرفض'}
                  </span>
                </div>

                <div className="grid grid-cols-2 gap-2 my-4 text-xs bg-slate-50 p-3 rounded-lg border border-slate-100">
                  <div>
                    <span className="text-slate-400">التصنيف: </span>
                    <span className="font-bold text-slate-700">{app.category}</span>
                  </div>
                  <div>
                    <span className="text-slate-400">السجل التجاري: </span>
                    <span className="font-mono font-bold text-slate-700">{app.crNumber}</span>
                  </div>
                  <div>
                    <span className="text-slate-400">النموذج المقترح: </span>
                    <span className="font-bold text-indigo-600">{app.proposedModel}</span>
                  </div>
                  <div>
                    <span className="text-slate-400">المبيعات المتوقعة: </span>
                    <span className="font-bold text-slate-700">{app.annualTurnoverEst}</span>
                  </div>
                </div>

                {app.status === 'PENDING' && (
                  <div className="flex items-center gap-2 pt-2 border-t border-slate-100">
                    <button
                      onClick={() => handleApproveApp(app.id)}
                      className="flex-1 bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold py-2 rounded-lg flex items-center justify-center gap-1.5 transition"
                    >
                      <Check className="w-3.5 h-3.5" />
                      اعتماد التاجر وتوليد العقد
                    </button>
                    <button
                      onClick={() => handleRejectApp(app.id)}
                      className="bg-rose-50 hover:bg-rose-100 text-rose-700 text-xs font-bold px-4 py-2 rounded-lg flex items-center justify-center gap-1 transition"
                    >
                      <X className="w-3.5 h-3.5" />
                      رفض
                    </button>
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>
      )}

      {/* TAB 4: COMMISSION MATRIX */}
      {activeTab === 'matrix' && (
        <div className="bg-white rounded-xl border border-slate-200 p-6 space-y-6 shadow-xs">
          <div>
            <h3 className="text-lg font-bold text-slate-900">مصفوفة عمولات الأقسام ورسوم خدمات التخزين (FBA)</h3>
            <p className="text-xs text-slate-500 mt-1">
              النسب الرسمية المقتطعة تلقائياً عند إتمام كل طلب لضمان استدامة البنية التحتية، الأسطول، وسلسلة التبريد
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="p-4 rounded-xl border border-blue-200 bg-blue-50/40">
              <div className="flex items-center justify-between mb-2">
                <span className="font-bold text-blue-900">شحن وتخزين الديب (FBA)</span>
                <span className="text-xs bg-blue-200 text-blue-800 font-bold px-2 py-0.5 rounded">الأكثر كفاءة</span>
              </div>
              <p className="text-xs text-slate-600 leading-relaxed">
                التخزين في مستودعات الديب الذكية المبردة، الفرز الآلي، والتوصيل خلال 15 دقيقة لعملاء Noon Minutes.
              </p>
              <div className="mt-4 pt-3 border-t border-blue-200 flex justify-between items-center text-xs">
                <span className="text-slate-500">عمولة المنصة:</span>
                <span className="font-bold text-blue-800 text-base">9% - 12%</span>
              </div>
            </div>

            <div className="p-4 rounded-xl border border-amber-200 bg-amber-50/40">
              <div className="flex items-center justify-between mb-2">
                <span className="font-bold text-amber-900">شحن من مستودع التاجر (FBM)</span>
                <span className="text-xs bg-amber-200 text-amber-800 font-bold px-2 py-0.5 rounded">مباشر</span>
              </div>
              <p className="text-xs text-slate-600 leading-relaxed">
                التاجر يحتفظ بالبضاعة في مستودعه الخاص، ويقوم مندوب الديب باستلامها مجهزة خلال ساعتين من الطلب.
              </p>
              <div className="mt-4 pt-3 border-t border-amber-200 flex justify-between items-center text-xs">
                <span className="text-slate-500">عمولة المنصة:</span>
                <span className="font-bold text-amber-800 text-base">7% - 8.5%</span>
              </div>
            </div>

            <div className="p-4 rounded-xl border border-emerald-200 bg-emerald-50/40">
              <div className="flex items-center justify-between mb-2">
                <span className="font-bold text-emerald-900">مزارع محلية طازجة (Farm Direct)</span>
                <span className="text-xs bg-emerald-200 text-emerald-800 font-bold px-2 py-0.5 rounded">دعم وطني</span>
              </div>
              <p className="text-xs text-slate-600 leading-relaxed">
                برنامج مدعوم لتمكين المزارعين السعوديين بدون وسطاء، استلام فجر كل يوم مباشرة إلى الفروع.
              </p>
              <div className="mt-4 pt-3 border-t border-emerald-200 flex justify-between items-center text-xs">
                <span className="text-slate-500">عمولة المنصة:</span>
                <span className="font-bold text-emerald-800 text-base">5% فقط</span>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* MODAL: ADD NEW VENDOR */}
      {showAddVendorModal && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-xs flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl max-w-lg w-full p-6 shadow-2xl">
            <div className="flex items-center justify-between border-b pb-3 mb-4">
              <h3 className="text-lg font-bold text-slate-900 flex items-center gap-2">
                <Store className="w-5 h-5 text-indigo-600" />
                تسجيل واعتماد تاجر شريك جديد
              </h3>
              <button onClick={() => setShowAddVendorModal(false)} className="text-slate-400 hover:text-slate-600">
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleCreateVendor} className="space-y-4">
              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1">اسم المؤسسة أو التاجر التجاري</label>
                <input
                  type="text"
                  required
                  value={newVendorName}
                  onChange={(e) => setNewVendorName(e.target.value)}
                  placeholder="مثال: شركة تمور الواحة المحدودة"
                  className="w-full px-3 py-2 border rounded-lg text-sm"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">رقم السجل التجاري (CR)</label>
                  <input
                    type="text"
                    required
                    value={newVendorCR}
                    onChange={(e) => setNewVendorCR(e.target.value)}
                    placeholder="1010XXXXXX"
                    className="w-full px-3 py-2 border rounded-lg text-sm font-mono"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">الرقم الضريبي (VAT)</label>
                  <input
                    type="text"
                    value={newVendorTax}
                    onChange={(e) => setNewVendorTax(e.target.value)}
                    placeholder="3XXXXXXXXXXXX03"
                    className="w-full px-3 py-2 border rounded-lg text-sm font-mono"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">نموذج الشحن والتخزين</label>
                  <select
                    value={newVendorModel}
                    onChange={(e) => setNewVendorModel(e.target.value as any)}
                    className="w-full px-3 py-2 border rounded-lg text-sm bg-white"
                  >
                    <option value="FBA">تخزين وشحن الديب (FBA)</option>
                    <option value="FBM">شحن من مستودع التاجر (FBM)</option>
                    <option value="FARM_DIRECT">مزارع وطنية مباشرة (Farm)</option>
                  </select>
                </div>
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">نسبة العمولة المقتطعة (%)</label>
                  <input
                    type="number"
                    step="0.5"
                    min="1"
                    max="30"
                    value={newVendorCommission}
                    onChange={(e) => setNewVendorCommission(Number(e.target.value))}
                    className="w-full px-3 py-2 border rounded-lg text-sm font-bold text-indigo-600"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1">الآيبان البنكي للتحويلات (IBAN)</label>
                <input
                  type="text"
                  required
                  value={newVendorIBAN}
                  onChange={(e) => setNewVendorIBAN(e.target.value)}
                  placeholder="SA4480000..."
                  className="w-full px-3 py-2 border rounded-lg text-sm font-mono"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">اسم الشخص المسؤول</label>
                  <input
                    type="text"
                    value={newVendorContact}
                    onChange={(e) => setNewVendorContact(e.target.value)}
                    placeholder="م. عبدالمحسن"
                    className="w-full px-3 py-2 border rounded-lg text-sm"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">رقم الجوال للتنسيق</label>
                  <input
                    type="text"
                    value={newVendorPhone}
                    onChange={(e) => setNewVendorPhone(e.target.value)}
                    placeholder="+966 50 123 4567"
                    className="w-full px-3 py-2 border rounded-lg text-sm font-mono"
                  />
                </div>
              </div>

              <div className="flex items-center justify-end gap-3 pt-4 border-t">
                <button
                  type="button"
                  onClick={() => setShowAddVendorModal(false)}
                  className="px-4 py-2 border rounded-lg text-sm text-slate-600 hover:bg-slate-50"
                >
                  إلغاء
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg text-sm font-bold shadow-md shadow-indigo-600/30"
                >
                  حفظ واعتماد التاجر
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* MODAL: SARIE WIRE TRANSFER CONFIRMATION */}
      {showPayoutModal && selectedPayout && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-xs flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl max-w-md w-full p-6 shadow-2xl">
            <div className="flex items-center justify-between border-b pb-3 mb-4">
              <h3 className="text-lg font-bold text-slate-900 flex items-center gap-2">
                <Send className="w-5 h-5 text-emerald-600" />
                تأكيد التحويل البنكي الفوري (SARIE)
              </h3>
              <button onClick={() => setShowPayoutModal(false)} className="text-slate-400 hover:text-slate-600">
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="space-y-3 text-sm">
              <div className="p-3 bg-slate-50 rounded-xl space-y-2 border border-slate-200">
                <div className="flex justify-between">
                  <span className="text-slate-500">التاجر المستفيد:</span>
                  <span className="font-bold text-slate-900">{selectedPayout.vendorName}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-500">الآيبان البنكي:</span>
                  <span className="font-mono text-xs text-slate-700">{selectedPayout.bankIban}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-500">الفترة المحاسبية:</span>
                  <span className="text-xs text-slate-700">{selectedPayout.period}</span>
                </div>
                <div className="border-t pt-2 flex justify-between items-center">
                  <span className="font-bold text-slate-900">صافي المبلغ المحول:</span>
                  <span className="font-extrabold text-emerald-600 text-lg">
                    {selectedPayout.netPayout.toLocaleString()} ل.س
                  </span>
                </div>
              </div>

              <p className="text-xs text-slate-500 leading-relaxed">
                سيتم إرسال إشعار فوري إلى الحساب البنكي للتاجر، وتوليد إشعار دائن ضريبي متوافق مع متطلبات هيئة الزكاة والضريبة والجمارك ZATCA المرحلة الثانية.
              </p>
            </div>

            <div className="flex items-center justify-end gap-3 pt-5 mt-4 border-t">
              <button
                type="button"
                onClick={() => setShowPayoutModal(false)}
                className="px-4 py-2 border rounded-lg text-sm text-slate-600 hover:bg-slate-50"
              >
                تراجع
              </button>
              <button
                type="button"
                onClick={() => handleProcessSARIETransfer(selectedPayout.id)}
                className="px-5 py-2 bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg text-sm font-bold shadow-md shadow-emerald-600/30 flex items-center gap-1.5"
              >
                <Check className="w-4 h-4" />
                تأكيد وإرسال الحوالة البنكية الآن
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
