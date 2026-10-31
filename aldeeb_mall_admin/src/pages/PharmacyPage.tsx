import React, { useState } from 'react';
import { 
  Pill, 
  HeartPulse, 
  Activity, 
  CheckCircle2, 
  AlertTriangle, 
  Search, 
  FileText, 
  ThermometerSnowflake, 
  ShieldCheck, 
  User, 
  Clock, 
  Sparkles, 
  Printer, 
  Building2,
  Check,
  X,
  Stethoscope,
  Eye,
  FileCheck
} from 'lucide-react';

interface Prescription {
  id: string;
  rxNumber: string;
  patientName: string;
  nationalId: string;
  doctorName: string;
  hospital: string;
  insuranceProvider: string;
  copayAmount: number;
  medications: {
    name: string;
    dosage: string;
    qty: number;
    coldChain: boolean;
    sfdaRsdCode: string;
  }[];
  submittedAt: string;
  status: 'pending_review' | 'approved' | 'dispensed' | 'rejected';
  pharmacistReviewer?: string;
  drugInteractionAlert?: string;
  requiresColdChain: boolean;
}

const mockPrescriptions: Prescription[] = [
  {
    id: 'rx-101',
    rxNumber: 'WASF-9482-KSA',
    patientName: 'سعود بن فهد القحطاني',
    nationalId: '1098234821',
    doctorName: 'د. طارق السليمان (استشاري باطنة وسكري)',
    hospital: 'مدينة الملك فهد الطبية - الرياض',
    insuranceProvider: 'بوبا العربية (Bupa - فئة ذهبية)',
    copayAmount: 0.0,
    medications: [
      {
        name: 'Lantus SoloStar Insulin 100u/ml (أقلام لانتوس)',
        dosage: '20 وحدة تحت الجلد يومياً مساءً',
        qty: 3,
        coldChain: true,
        sfdaRsdCode: '6285038102931',
      },
      {
        name: 'Januvia 100mg (جانوفيا منظم السكر)',
        dosage: 'قرص واحد يومياً مع الإفطار',
        qty: 1,
        coldChain: false,
        sfdaRsdCode: '6285038108472',
      },
    ],
    submittedAt: 'منذ 6 دقائق',
    status: 'pending_review',
    drugInteractionAlert: 'فحص التداخلات: آمن 100% مع جرعة لانتوس الحالية',
    requiresColdChain: true,
  },
  {
    id: 'rx-102',
    rxNumber: 'WASF-8819-KSA',
    patientName: 'منيرة عبدالرحمن الشمري',
    nationalId: '1047291844',
    doctorName: 'د. أحمد المنصور (أمراض القلب والأوعية)',
    hospital: 'مستشفى الدكتور سليمان الحبيب',
    insuranceProvider: 'التعاونية للتأمين (Tawuniya)',
    copayAmount: 15.0,
    medications: [
      {
        name: 'Concor 5mg (كونكور بيسوبرولول)',
        dosage: 'قرص صباحاً لضبط ضربات القلب',
        qty: 1,
        coldChain: false,
        sfdaRsdCode: '6285038199201',
      },
      {
        name: 'Lipitor 20mg (ليبيتور أتورفاستاتين)',
        dosage: 'قرص واحد قبل النوم',
        qty: 1,
        coldChain: false,
        sfdaRsdCode: '6285038144119',
      },
    ],
    submittedAt: 'منذ 14 دقيقة',
    status: 'approved',
    pharmacistReviewer: 'د. سارة الشهري (ترخيص #48190)',
    drugInteractionAlert: 'تم التدقيق: تجنب استهلاك الجريب فروت مع العلاج',
    requiresColdChain: false,
  },
  {
    id: 'rx-103',
    rxNumber: 'WASF-7731-KSA',
    patientName: 'خالد إبراهيم الدوسري',
    nationalId: '1029481729',
    doctorName: 'د. خالد الزهراني (أنف وأذن وحنجرة)',
    hospital: 'المركز الصحي بحي الملقا',
    insuranceProvider: 'وصفتي MoH (تغطية حكومية مجانية)',
    copayAmount: 0.0,
    medications: [
      {
        name: 'Augmentin 1g Tablets (أوجمنتين مضاد حيوي)',
        dosage: 'قرص كل 12 ساعة بعد الأكل لمدة 7 أيام',
        qty: 1,
        coldChain: false,
        sfdaRsdCode: '6285038155234',
      },
      {
        name: 'Flixonase Nasal Spray (بخاخ فليكسونيز)',
        dosage: 'بختان في كل فتحة أنف صباحاً',
        qty: 1,
        coldChain: false,
        sfdaRsdCode: '6285038111902',
      },
    ],
    submittedAt: 'منذ 28 دقيقة',
    status: 'dispensed',
    pharmacistReviewer: 'د. فيصل العتيبي (ترخيص #39102)',
    requiresColdChain: false,
  },
];

export const PharmacyPage: React.FC = () => {
  const [prescriptions, setPrescriptions] = useState<Prescription[]>(mockPrescriptions);
  const [selectedRx, setSelectedRx] = useState<Prescription | null>(null);
  const [activeTab, setActiveTab] = useState<'queue' | 'interactions' | 'cold_chain'>('queue');
  const [searchQuery, setSearchQuery] = useState('');
  const [filterStatus, setFilterStatus] = useState<string>('all');

  // Handle Approve Dispense
  const handleApprove = (id: string) => {
    setPrescriptions((prev) =>
      prev.map((rx) =>
        rx.id === id
          ? {
              ...rx,
              status: 'approved',
              pharmacistReviewer: 'د. الصيدلي المناوب (أحمد الزعبي - ترخيص #59102)',
            }
          : rx
      )
    );
    if (selectedRx && selectedRx.id === id) {
      setSelectedRx((prev) =>
        prev
          ? {
              ...prev,
              status: 'approved',
              pharmacistReviewer: 'د. الصيدلي المناوب (أحمد الزعبي - ترخيص #59102)',
            }
          : null
      );
    }
  };

  // Handle Mark Dispensed
  const handleDispense = (id: string) => {
    setPrescriptions((prev) =>
      prev.map((rx) => (rx.id === id ? { ...rx, status: 'dispensed' } : rx))
    );
    if (selectedRx && selectedRx.id === id) {
      setSelectedRx((prev) => (prev ? { ...prev, status: 'dispensed' } : null));
    }
  };

  const filteredRx = prescriptions.filter((rx) => {
    const matchesSearch =
      rx.rxNumber.toLowerCase().includes(searchQuery.toLowerCase()) ||
      rx.patientName.includes(searchQuery) ||
      rx.nationalId.includes(searchQuery);
    const matchesStatus = filterStatus === 'all' || rx.status === filterStatus;
    return matchesSearch && matchesStatus;
  });

  return (
    <div className="p-6 space-y-6 max-w-7xl mx-auto text-slate-800" dir="rtl">
      {/* Header Banner */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 bg-gradient-to-l from-emerald-900 via-emerald-800 to-teal-900 p-6 rounded-2xl text-white shadow-xl">
        <div className="flex items-center gap-4">
          <div className="p-3 bg-white/10 backdrop-blur-md rounded-xl border border-white/20">
            <Pill className="w-8 h-8 text-emerald-300" />
          </div>
          <div>
            <div className="flex items-center gap-3">
              <h1 className="text-2xl font-black tracking-tight">صيدلية الديب الذكية ورقابة الغذاء والدواء</h1>
              <span className="px-2.5 py-0.5 rounded-full text-xs font-bold bg-emerald-400/20 text-emerald-300 border border-emerald-400/30">
                SFDA Certified #48291
              </span>
            </div>
            <p className="text-emerald-200 text-sm mt-1">
              إدارة صرف الوصفات الطبية الإلكترونية (وصفتي)، فاحص التداخلات الدوائية، وتتبع سلسلة التبريد الدوائي الحساس
            </p>
          </div>
        </div>

        <div className="flex items-center gap-2">
          <div className="bg-emerald-950/60 px-4 py-2.5 rounded-xl border border-emerald-700/50 flex items-center gap-3">
            <ShieldCheck className="w-5 h-5 text-emerald-400" />
            <div className="text-xs">
              <p className="font-bold text-white">منصة رصد SFDA RSD</p>
              <p className="text-emerald-300">متصل ومتزامن لحظياً (100%)</p>
            </div>
          </div>
        </div>
      </div>

      {/* KPI Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs flex items-center justify-between">
          <div>
            <p className="text-xs font-semibold text-slate-500">إجمالي وصفات اليوم</p>
            <p className="text-2xl font-black text-slate-900 mt-1">184 وصفة</p>
            <p className="text-xs text-emerald-600 font-medium mt-1">↑ +24% نمو أسبوعي</p>
          </div>
          <div className="p-3 bg-emerald-50 rounded-xl">
            <FileText className="w-6 h-6 text-emerald-600" />
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs flex items-center justify-between">
          <div>
            <p className="text-xs font-semibold text-slate-500">بانتظار الاعتماد السريري</p>
            <p className="text-2xl font-black text-amber-600 mt-1">
              {prescriptions.filter((r) => r.status === 'pending_review').length} وصفات
            </p>
            <p className="text-xs text-amber-600 font-medium mt-1">تحتاج مراجعة صيدلي مناوب</p>
          </div>
          <div className="p-3 bg-amber-50 rounded-xl">
            <Clock className="w-6 h-6 text-amber-600" />
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs flex items-center justify-between">
          <div>
            <p className="text-xs font-semibold text-slate-500">متوسط وقت الصرف والتغليف</p>
            <p className="text-2xl font-black text-blue-600 mt-1">8.4 دقيقة</p>
            <p className="text-xs text-slate-500 font-medium mt-1">الهدف SLA: أقل من 12 دقيقة</p>
          </div>
          <div className="p-3 bg-blue-50 rounded-xl">
            <Activity className="w-6 h-6 text-blue-600" />
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs flex items-center justify-between">
          <div>
            <p className="text-xs font-semibold text-slate-500">حرارة صناديق التبريد (IoT)</p>
            <p className="text-2xl font-black text-emerald-600 mt-1">3.4°C</p>
            <p className="text-xs text-emerald-600 font-medium mt-1">مثالي: بين 2°C و 8°C للإنسولين</p>
          </div>
          <div className="p-3 bg-teal-50 rounded-xl">
            <ThermometerSnowflake className="w-6 h-6 text-teal-600" />
          </div>
        </div>
      </div>

      {/* Tabs Control */}
      <div className="flex border-b border-slate-200">
        <button
          onClick={() => setActiveTab('queue')}
          className={`pb-3 px-4 font-bold text-sm flex items-center gap-2 border-b-2 transition-colors ${
            activeTab === 'queue'
              ? 'border-emerald-600 text-emerald-800'
              : 'border-transparent text-slate-500 hover:text-slate-700'
          }`}
        >
          <FileCheck className="w-4 h-4" />
          طابور صرف الوصفات الطبية (وصفتي)
          <span className="bg-emerald-100 text-emerald-800 px-2 py-0.5 rounded-full text-xs">
            {prescriptions.length}
          </span>
        </button>

        <button
          onClick={() => setActiveTab('interactions')}
          className={`pb-3 px-4 font-bold text-sm flex items-center gap-2 border-b-2 transition-colors ${
            activeTab === 'interactions'
              ? 'border-emerald-600 text-emerald-800'
              : 'border-transparent text-slate-500 hover:text-slate-700'
          }`}
        >
          <HeartPulse className="w-4 h-4" />
          فاحص التداخلات الدوائية والغذائية SFDA
        </button>

        <button
          onClick={() => setActiveTab('cold_chain')}
          className={`pb-3 px-4 font-bold text-sm flex items-center gap-2 border-b-2 transition-colors ${
            activeTab === 'cold_chain'
              ? 'border-emerald-600 text-emerald-800'
              : 'border-transparent text-slate-500 hover:text-slate-700'
          }`}
        >
          <ThermometerSnowflake className="w-4 h-4" />
          صناديق التبريد الذكية للأدوية (IoT Tracker)
        </button>
      </div>

      {/* TAB 1: PRESCRIPTIONS QUEUE */}
      {activeTab === 'queue' && (
        <div className="space-y-4">
          {/* Search & Filter Bar */}
          <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-xs flex flex-col md:flex-row gap-4 items-center justify-between">
            <div className="relative w-full md:w-96">
              <Search className="w-4 h-4 text-slate-400 absolute right-3 top-3" />
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="بحث برقم وصفتي، اسم المريض، أو الهوية..."
                className="w-full pr-9 pl-4 py-2 border border-slate-200 rounded-lg text-sm focus:outline-hidden focus:ring-2 focus:ring-emerald-500"
              />
            </div>

            <div className="flex items-center gap-2 w-full md:w-auto">
              <span className="text-xs font-bold text-slate-500">تصفية بالحالة:</span>
              <select
                value={filterStatus}
                onChange={(e) => setFilterStatus(e.target.value)}
                className="border border-slate-200 rounded-lg px-3 py-1.5 text-xs font-semibold focus:outline-hidden focus:ring-2 focus:ring-emerald-500"
              >
                <option value="all">جميع الحالات</option>
                <option value="pending_review">بانتظار المراجعة (6)</option>
                <option value="approved">معتمدة وجارٍ الصرف</option>
                <option value="dispensed">تم الصرف والتسليم</option>
              </select>
            </div>
          </div>

          {/* Prescriptions Table */}
          <div className="bg-white rounded-xl border border-slate-200 shadow-xs overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full text-right text-xs">
                <thead className="bg-slate-50 text-slate-600 font-bold border-b border-slate-200">
                  <tr>
                    <th className="p-3.5">رقم الوصفة (Rx)</th>
                    <th className="p-3.5">المريض والهوية</th>
                    <th className="p-3.5">الطبيب والمستشفى</th>
                    <th className="p-3.5">التأمين / وصفتي</th>
                    <th className="p-3.5">الأدوية الموصوفة</th>
                    <th className="p-3.5">سلسلة التبريد</th>
                    <th className="p-3.5">الحالة</th>
                    <th className="p-3.5 text-center">الإجراءات السريرية</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {filteredRx.map((rx) => (
                    <tr key={rx.id} className="hover:bg-slate-50/80 transition-colors">
                      <td className="p-3.5 font-bold font-mono text-emerald-800">
                        {rx.rxNumber}
                        <span className="block text-[10px] text-slate-400 font-sans font-normal">{rx.submittedAt}</span>
                      </td>
                      <td className="p-3.5">
                        <div className="font-bold text-slate-800">{rx.patientName}</div>
                        <div className="text-[11px] text-slate-500 font-mono">هوية: {rx.nationalId}</div>
                      </td>
                      <td className="p-3.5">
                        <div className="font-medium text-slate-700">{rx.doctorName}</div>
                        <div className="text-[11px] text-slate-400">{rx.hospital}</div>
                      </td>
                      <td className="p-3.5">
                        <span className="inline-block px-2 py-0.5 bg-blue-50 text-blue-700 rounded-md font-bold text-[11px]">
                          {rx.insuranceProvider}
                        </span>
                        <div className="text-[10px] text-slate-500 mt-0.5">تحمل المريض: {rx.copayAmount} ر.س</div>
                      </td>
                      <td className="p-3.5 max-w-xs">
                        <div className="space-y-1">
                          {rx.medications.map((m, idx) => (
                            <div key={idx} className="text-[11px] text-slate-700">
                              <span className="font-bold">• {m.name}</span>
                              <span className="text-slate-400 mr-1">({m.dosage})</span>
                            </div>
                          ))}
                        </div>
                      </td>
                      <td className="p-3.5">
                        {rx.requiresColdChain ? (
                          <span className="inline-flex items-center gap-1 px-2 py-1 bg-cyan-50 text-cyan-700 border border-cyan-200 rounded-md font-bold text-[10px]">
                            <ThermometerSnowflake className="w-3 h-3" />
                            مبرد (2°C - 8°C)
                          </span>
                        ) : (
                          <span className="text-slate-400 text-[11px]">حرارة الغرفة</span>
                        )}
                      </td>
                      <td className="p-3.5">
                        {rx.status === 'pending_review' && (
                          <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-amber-50 text-amber-700 border border-amber-200 font-bold text-[11px]">
                            <Clock className="w-3 h-3" />
                            بانتظار المراجعة
                          </span>
                        )}
                        {rx.status === 'approved' && (
                          <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-emerald-50 text-emerald-700 border border-emerald-200 font-bold text-[11px]">
                            <CheckCircle2 className="w-3 h-3" />
                            معتمدة للصرف
                          </span>
                        )}
                        {rx.status === 'dispensed' && (
                          <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-blue-50 text-blue-700 border border-blue-200 font-bold text-[11px]">
                            <Check className="w-3 h-3" />
                            تم الصرف والتسليم
                          </span>
                        )}
                      </td>
                      <td className="p-3.5 text-center">
                        <div className="flex items-center justify-center gap-1.5">
                          <button
                            onClick={() => setSelectedRx(rx)}
                            className="p-1.5 text-emerald-700 hover:bg-emerald-50 rounded-lg transition-colors"
                            title="معاينة الوصفة"
                          >
                            <Eye className="w-4 h-4" />
                          </button>

                          {rx.status === 'pending_review' && (
                            <button
                              onClick={() => handleApprove(rx.id)}
                              className="px-2.5 py-1 bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg font-bold text-[11px] transition-colors"
                            >
                              اعتماد الصيدلي
                            </button>
                          )}

                          {rx.status === 'approved' && (
                            <button
                              onClick={() => handleDispense(rx.id)}
                              className="px-2.5 py-1 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-bold text-[11px] transition-colors"
                            >
                              تأكيد الصرف
                            </button>
                          )}
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

      {/* TAB 2: SFDA CLINICAL DRUG INTERACTIONS */}
      {activeTab === 'interactions' && (
        <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-xs space-y-6">
          <div className="flex items-start justify-between">
            <div>
              <h2 className="text-lg font-bold text-slate-900">محرك فحص التداخلات الدوائية والغذائية السريري</h2>
              <p className="text-xs text-slate-500 mt-1">
                قاعدة بيانات التداخلات السريرية المعيارية المعتمدة من هيئة الغذاء والدواء السعودية SFDA
              </p>
            </div>
            <span className="px-3 py-1 bg-emerald-50 text-emerald-700 rounded-lg text-xs font-bold border border-emerald-200">
              قاعدة بيانات 2026 المحدثة
            </span>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="p-4 rounded-xl border border-red-200 bg-red-50/50">
              <div className="flex items-center gap-2 text-red-800 font-bold text-sm">
                <AlertTriangle className="w-4 h-4 text-red-600" />
                تداخلات حرجة (ممنوعة تماماً Contraindicated)
              </div>
              <ul className="mt-3 space-y-2 text-xs text-red-950">
                <li className="flex items-start gap-2">
                  <span className="font-bold">• وارفارين (Warfarin) + إيبوبروفين (Ibuprofen):</span>
                  <span>خطر حدوث نزيف هضمي حاد بنسبة تفوق 400% بسبب تآزر تثبيط الصفائح الدموية.</span>
                </li>
                <li className="flex items-start gap-2">
                  <span className="font-bold">• فيفادول (Paracetamol) + أدوية كولد & فلو المركبة:</span>
                  <span>خطر تسمم الكبد الحاد بتجاوز الجرعة القصوى (4,000 ملجم/يوم).</span>
                </li>
                <li className="flex items-start gap-2">
                  <span className="font-bold">• أوجمنتين + ميثوتريكسات:</span>
                  <span>تثبيط إخراج الميثوتريكسات وزيادة سميته في الدم.</span>
                </li>
              </ul>
            </div>

            <div className="p-4 rounded-xl border border-amber-200 bg-amber-50/50">
              <div className="flex items-center gap-2 text-amber-800 font-bold text-sm">
                <Sparkles className="w-4 h-4 text-amber-600" />
                تداخلات دوائية-غذائية شائعة (Food-Drug Interactions)
              </div>
              <ul className="mt-3 space-y-2 text-xs text-amber-950">
                <li className="flex items-start gap-2">
                  <span className="font-bold">• عصير الجريب فروت + ليبيتور (Atorvastatin):</span>
                  <span>تثبيط إنزيم CYP3A4 ورفع تركيز الستاتين في الدم مما يسبب انحلال الربيدات العضلي.</span>
                </li>
                <li className="flex items-start gap-2">
                  <span className="font-bold">• مشتقات الألبان والكالسيوم + مضاد سيبروفلوكساسين:</span>
                  <span>تقليل امتصاص المضاد الحيوي بنسبة 50%؛ يجب الفصل بساعتين على الأقل.</span>
                </li>
                <li className="flex items-start gap-2">
                  <span className="font-bold">• الموز والأطعمة الغنية بالبوتاسيوم + أدوية ضغط ACE Inhibitors:</span>
                  <span>احتمال فرط بوتاسيوم الدم (Hyperkalemia) واضطراب نبض القلب.</span>
                </li>
              </ul>
            </div>
          </div>
        </div>
      )}

      {/* TAB 3: COLD-CHAIN IOT MEDICAL TRACKER */}
      {activeTab === 'cold_chain' && (
        <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-xs space-y-6">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-lg font-bold text-slate-900">مراقبة صناديق التبريد الدوائي الحساس (IoT Boxes)</h2>
              <p className="text-xs text-slate-500 mt-1">
                تتبع درجات الحرارة الحية للأدوية الحساسة كالإنسولين واللقاحات أثناء رحلة التوصيل مع الكوريير
              </p>
            </div>
            <div className="flex items-center gap-2">
              <span className="w-3 h-3 bg-emerald-500 rounded-full animate-ping" />
              <span className="text-xs font-bold text-emerald-700">مستشعرات نشطة على الهواء</span>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="p-4 rounded-xl border border-slate-200 bg-slate-50 flex items-center justify-between">
              <div>
                <span className="text-[10px] font-bold text-slate-400">بوكس رقم #MED-BOX-01</span>
                <h4 className="font-bold text-slate-800 text-sm mt-0.5">مع الكابتن: فيصل الدوسري</h4>
                <p className="text-xs text-slate-500">وجهة التوصيل: حي حطين (طلب #1094)</p>
                <div className="mt-2 inline-flex items-center gap-1.5 px-2 py-0.5 bg-emerald-100 text-emerald-800 rounded-md text-xs font-bold">
                  الحرارة: 3.2°C (ممتاز)
                </div>
              </div>
              <ThermometerSnowflake className="w-8 h-8 text-emerald-600" />
            </div>

            <div className="p-4 rounded-xl border border-slate-200 bg-slate-50 flex items-center justify-between">
              <div>
                <span className="text-[10px] font-bold text-slate-400">بوكس رقم #MED-BOX-02</span>
                <h4 className="font-bold text-slate-800 text-sm mt-0.5">مع الكابتن: ريان الغامدي</h4>
                <p className="text-xs text-slate-500">وجهة التوصيل: حي النرجس (طلب #1102)</p>
                <div className="mt-2 inline-flex items-center gap-1.5 px-2 py-0.5 bg-emerald-100 text-emerald-800 rounded-md text-xs font-bold">
                  الحرارة: 4.1°C (ممتاز)
                </div>
              </div>
              <ThermometerSnowflake className="w-8 h-8 text-emerald-600" />
            </div>

            <div className="p-4 rounded-xl border border-slate-200 bg-slate-50 flex items-center justify-between">
              <div>
                <span className="text-[10px] font-bold text-slate-400">بوكس رقم #MED-BOX-03</span>
                <h4 className="font-bold text-slate-800 text-sm mt-0.5">جاهز في صيدلية الدارك ستور</h4>
                <p className="text-xs text-slate-500">بانتظار استلام الكوريير</p>
                <div className="mt-2 inline-flex items-center gap-1.5 px-2 py-0.5 bg-blue-100 text-blue-800 rounded-md text-xs font-bold">
                  الحرارة: 2.8°C (جاهز)
                </div>
              </div>
              <ThermometerSnowflake className="w-8 h-8 text-blue-600" />
            </div>
          </div>
        </div>
      )}

      {/* PRESCRIPTION DETAIL MODAL */}
      {selectedRx && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-2xl max-w-2xl w-full p-6 space-y-4 shadow-2xl border border-slate-200 animate-in fade-in zoom-in duration-150">
            <div className="flex items-center justify-between border-b pb-3 border-slate-100">
              <div className="flex items-center gap-2">
                <FileCheck className="w-6 h-6 text-emerald-700" />
                <h3 className="font-bold text-lg text-slate-900">
                  تفاصيل الوصفة الطبية ({selectedRx.rxNumber})
                </h3>
              </div>
              <button
                onClick={() => setSelectedRx(null)}
                className="p-1 text-slate-400 hover:text-slate-600 rounded-lg"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="grid grid-cols-2 gap-3 text-xs bg-slate-50 p-3 rounded-xl border border-slate-200">
              <div>
                <span className="text-slate-500">اسم المريض:</span>{' '}
                <span className="font-bold text-slate-900">{selectedRx.patientName}</span>
              </div>
              <div>
                <span className="text-slate-500">الهوية الوطنية:</span>{' '}
                <span className="font-mono font-bold text-slate-900">{selectedRx.nationalId}</span>
              </div>
              <div>
                <span className="text-slate-500">الطبيب المعالج:</span>{' '}
                <span className="font-bold text-slate-900">{selectedRx.doctorName}</span>
              </div>
              <div>
                <span className="text-slate-500">المنشأة الطبية:</span>{' '}
                <span className="font-bold text-slate-900">{selectedRx.hospital}</span>
              </div>
              <div>
                <span className="text-slate-500">برنامج التأمين:</span>{' '}
                <span className="font-bold text-emerald-700">{selectedRx.insuranceProvider}</span>
              </div>
              <div>
                <span className="text-slate-500">حفظ بارد:</span>{' '}
                <span className="font-bold text-cyan-700">
                  {selectedRx.requiresColdChain ? 'نعم (2°C - 8°C)' : 'حرارة الغرفة العادية'}
                </span>
              </div>
            </div>

            <div>
              <h4 className="font-bold text-xs text-slate-700 mb-2">قائمة الأدوية المعتمدة في الوصفة:</h4>
              <div className="space-y-2">
                {selectedRx.medications.map((med, idx) => (
                  <div
                    key={idx}
                    className="p-3 rounded-xl border border-slate-200 bg-white flex items-center justify-between text-xs"
                  >
                    <div>
                      <div className="font-bold text-slate-900">{med.name}</div>
                      <div className="text-slate-500 text-[11px] mt-0.5">تعليمات الجرعة: {med.dosage}</div>
                      <div className="text-[10px] text-slate-400 font-mono mt-0.5">
                        كود رصد SFDA RSD: {med.sfdaRsdCode}
                      </div>
                    </div>
                    <div className="text-left font-bold text-emerald-700">الكمية: {med.qty}</div>
                  </div>
                ))}
              </div>
            </div>

            {selectedRx.drugInteractionAlert && (
              <div className="p-3 bg-emerald-50 border border-emerald-200 rounded-xl text-xs text-emerald-800 flex items-center gap-2">
                <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0" />
                <span>{selectedRx.drugInteractionAlert}</span>
              </div>
            )}

            <div className="flex items-center justify-between pt-3 border-t border-slate-100">
              <button
                onClick={() => {
                  alert(`تمت طباعة ملصق الجرعة والـ QR للوصفة ${selectedRx.rxNumber}`);
                }}
                className="flex items-center gap-1.5 px-3 py-2 border border-slate-200 hover:bg-slate-50 rounded-xl text-xs font-bold text-slate-700 transition-colors"
              >
                <Printer className="w-4 h-4" />
                طباعة ملصق الجرعة والباركود
              </button>

              <div className="flex items-center gap-2">
                {selectedRx.status === 'pending_review' && (
                  <button
                    onClick={() => handleApprove(selectedRx.id)}
                    className="px-4 py-2 bg-emerald-600 hover:bg-emerald-700 text-white rounded-xl text-xs font-bold transition-colors"
                  >
                    اعتماد الصيدلي السريري
                  </button>
                )}
                {selectedRx.status === 'approved' && (
                  <button
                    onClick={() => handleDispense(selectedRx.id)}
                    className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-xl text-xs font-bold transition-colors"
                  >
                    تأكيد الصرف والتغليف
                  </button>
                )}
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
