import React, { useState } from 'react';
import { 
  Building, 
  Briefcase, 
  CreditCard, 
  Calendar, 
  CheckCircle2, 
  Clock, 
  FileText, 
  Search, 
  ArrowUpRight, 
  ShieldCheck, 
  Truck, 
  DollarSign, 
  Plus,
  Eye,
  FileCheck2,
  Printer
} from 'lucide-react';

interface CorporateAccount {
  id: string;
  companyName: string;
  crNumber: string;
  vatNumber: string;
  contactPerson: string;
  phone: string;
  monthlyCreditLimit: number;
  currentBalance: number;
  paymentTerms: 'Net-15' | 'Net-30' | 'Net-60';
  recurringSchedule: string;
  lastOrderAmount: number;
  status: 'active' | 'pending_kyc' | 'overdue';
  itemsSummary: string;
}

export const CorporateB2BPage: React.FC = () => {
  const [accounts, setAccounts] = useState<CorporateAccount[]>([
    {
      id: 'b2b-01',
      companyName: 'شركة الاتصالات السعودية (STC - المقر الرئيسي)',
      crNumber: '1010150261',
      vatNumber: '300000000000003',
      contactPerson: 'م. فهد السديري (مدير المرافق والإعاشة)',
      phone: '+966 50 112 3456',
      monthlyCreditLimit: 100000,
      currentBalance: 42300,
      paymentTerms: 'Net-30',
      recurringSchedule: 'كل أحد 07:00 صباحاً (شحنة أسبوعية)',
      lastOrderAmount: 14200,
      status: 'active',
      itemsSummary: '20 كرتون بن اسبريسو، 50 كرتون مياه هنا، 15 كرتون حليب، سلال فواكه مكتبية',
    },
    {
      id: 'b2b-02',
      companyName: 'مصرف الراجحي (الإدارة العامة - كافد)',
      crNumber: '1010000096',
      vatNumber: '300000000000005',
      contactPerson: 'أ. ريم الشمري (المشتريات التشغيلية)',
      phone: '+966 55 987 6543',
      monthlyCreditLimit: 75000,
      currentBalance: 28900,
      paymentTerms: 'Net-30',
      recurringSchedule: 'كل ثلاثاء 08:00 صباحاً',
      lastOrderAmount: 9450,
      status: 'active',
      itemsSummary: 'شاي فاخر، قهوة عربي الديب، سناكات صحية ومكسرات للموظفين، مناديل ومستلزمات نظافة',
    },
    {
      id: 'b2b-03',
      companyName: 'الهيئة العامة للمنشآت الصغيرة والمتوسطة (منشآت)',
      crNumber: '1010482910',
      vatNumber: '310928192000003',
      contactPerson: 'أ. ياسر العتيبي (الخدمات المشتركة)',
      phone: '+966 54 332 1199',
      monthlyCreditLimit: 40000,
      currentBalance: 12400,
      paymentTerms: 'Net-15',
      recurringSchedule: 'كل أسبوعين صباح الإثنين',
      lastOrderAmount: 6200,
      status: 'active',
      itemsSummary: 'مياه شرب معبأة، كبسولات نسبريسو متوافقة، سكر وبدائل صحية، أطباق وأكواب ورقية صديقة للبيئة',
    },
    {
      id: 'b2b-04',
      companyName: 'شركة لوسيد موتورز الشرق الأوسط (Lucid Motors)',
      crNumber: '1010928172',
      vatNumber: '310948291000003',
      contactPerson: 'ديفيد كارتر (Country Facilities Lead)',
      phone: '+966 56 441 8822',
      monthlyCreditLimit: 60000,
      currentBalance: 0,
      paymentTerms: 'Net-30',
      recurringSchedule: 'السبت والأربعاء (مرتين أسبوعياً)',
      lastOrderAmount: 8100,
      status: 'active',
      itemsSummary: 'تموين صالات العرض بالرياض: مياه إيفيان، قهوة مختصة، وجبات خفيفة ومشروبات طاقة للمهندسين',
    },
    {
      id: 'b2b-05',
      companyName: 'مجموعة المجدوعي القابضة',
      crNumber: '2050001928',
      vatNumber: '300019281000003',
      contactPerson: 'م. طارق القحطاني',
      phone: '+966 53 771 9900',
      monthlyCreditLimit: 50000,
      currentBalance: 51200,
      paymentTerms: 'Net-30',
      recurringSchedule: 'أول يوم عمل من كل شهر',
      lastOrderAmount: 18500,
      status: 'overdue',
      itemsSummary: 'تموين مستودعات ومكاتب الشحن: تموين إعاشة كامل ومواد تنظيف ومياه للموظفين',
    },
  ]);

  const [selectedAccount, setSelectedAccount] = useState<CorporateAccount | null>(null);
  const [searchQuery, setSearchQuery] = useState('');

  const filteredAccounts = accounts.filter(
    (acc) =>
      acc.companyName.includes(searchQuery) ||
      acc.crNumber.includes(searchQuery) ||
      acc.contactPerson.includes(searchQuery)
  );

  return (
    <div className="p-6 space-y-6 max-w-7xl mx-auto text-slate-800" dir="rtl">
      {/* Header Banner */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 bg-gradient-to-l from-blue-950 via-slate-900 to-indigo-950 p-6 rounded-2xl text-white shadow-xl">
        <div className="flex items-center gap-4">
          <div className="p-3 bg-white/10 backdrop-blur-md rounded-xl border border-white/20">
            <Building className="w-8 h-8 text-blue-300" />
          </div>
          <div>
            <div className="flex items-center gap-3">
              <h1 className="text-2xl font-black tracking-tight">بوابة إعاشة وتوريد الشركات ومبيعات الجملة B2B</h1>
              <span className="px-2.5 py-0.5 rounded-full text-xs font-bold bg-blue-400/20 text-blue-300 border border-blue-400/30">
                Corporate & Office Restock
              </span>
            </div>
            <p className="text-blue-200 text-sm mt-1">
              إدارة حسابات الشركات الكبرى، عقود التوريد الدورية المجدولة، الفواتير الضريبية للأعمال ZATCA، والسداد الآجل Net-30
            </p>
          </div>
        </div>

        <div className="flex items-center gap-2">
          <div className="bg-blue-950/60 px-4 py-2.5 rounded-xl border border-blue-700/50 flex items-center gap-3">
            <ShieldCheck className="w-5 h-5 text-blue-400" />
            <div className="text-xs">
              <p className="font-bold text-white">الفوترة الضريبية ZATCA B2B</p>
              <p className="text-blue-300">متوافق مع المرحلة الثانية (Fatoora API)</p>
            </div>
          </div>
        </div>
      </div>

      {/* KPI Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-xs flex items-center justify-between">
          <div>
            <p className="text-xs font-semibold text-slate-500">الشركات والجهات المشتركة</p>
            <p className="text-2xl font-black text-slate-900 mt-1">{accounts.length} جهة</p>
            <p className="text-xs text-emerald-600 font-medium mt-1">↑ +18% اشتراكات جديدة هذا الشهر</p>
          </div>
          <div className="p-3 bg-blue-50 rounded-xl">
            <Building className="w-6 h-6 text-blue-600" />
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-xs flex items-center justify-between">
          <div>
            <p className="text-xs font-semibold text-slate-500">مبيعات B2B هذا الشهر</p>
            <p className="text-2xl font-black text-emerald-600 mt-1">420,500 ر.س</p>
            <p className="text-xs text-slate-500 font-medium mt-1">تم تحصيل 78% عبر التحويل البنكي</p>
          </div>
          <div className="p-3 bg-emerald-50 rounded-xl">
            <DollarSign className="w-6 h-6 text-emerald-600" />
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-xs flex items-center justify-between">
          <div>
            <p className="text-xs font-semibold text-slate-500">عقود التوريد الدورية المجدولة</p>
            <p className="text-2xl font-black text-indigo-600 mt-1">34 عقد أسبوعي</p>
            <p className="text-xs text-indigo-600 font-medium mt-1">شحنات آلية بدون طلب يدوي</p>
          </div>
          <div className="p-3 bg-indigo-50 rounded-xl">
            <Calendar className="w-6 h-6 text-indigo-600" />
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-xs flex items-center justify-between">
          <div>
            <p className="text-xs font-semibold text-slate-500">متوسط سلة طلب الشركة</p>
            <p className="text-2xl font-black text-slate-900 mt-1">9,480 ر.س</p>
            <p className="text-xs text-emerald-600 font-medium mt-1">خصومات جملة تصل إلى 30%</p>
          </div>
          <div className="p-3 bg-slate-100 rounded-xl">
            <Truck className="w-6 h-6 text-slate-700" />
          </div>
        </div>
      </div>

      {/* Corporate Accounts Table */}
      <div className="bg-white rounded-2xl border border-slate-200 shadow-xs overflow-hidden">
        <div className="p-4 border-b border-slate-100 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
          <div className="relative w-full sm:w-80">
            <Search className="w-4 h-4 text-slate-400 absolute right-3 top-3" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="بحث باسم الشركة، السجل التجاري، أو المسؤول..."
              className="w-full pr-9 pl-4 py-2 border border-slate-200 rounded-lg text-xs focus:outline-hidden focus:ring-2 focus:ring-blue-500"
            />
          </div>

          <button
            onClick={() => alert('فتح نموذج اعتماد حساب شركة جديد مع فحص السجل التجاري في وزارة التجارة')}
            className="px-3.5 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-xl text-xs font-bold transition-colors flex items-center gap-1.5 self-end sm:self-auto"
          >
            <Plus className="w-4 h-4" />
            إضافة حساب شركة جديد
          </button>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-right text-xs">
            <thead className="bg-slate-50 text-slate-600 font-bold border-b border-slate-200">
              <tr>
                <th className="p-3.5">الشركة والسجل التجاري</th>
                <th className="p-3.5">مسؤول المشتريات والتواصل</th>
                <th className="p-3.5">الحد الائتماني وشروط السداد</th>
                <th className="p-3.5">جدول التوريد الدوري</th>
                <th className="p-3.5">آخر طلبية</th>
                <th className="p-3.5">الحالة</th>
                <th className="p-3.5 text-center">الإجراءات</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {filteredAccounts.map((account) => (
                <tr key={account.id} className="hover:bg-slate-50/80 transition-colors">
                  <td className="p-3.5">
                    <div className="font-bold text-slate-900">{account.companyName}</div>
                    <div className="text-[11px] text-slate-500 font-mono">س.ت: {account.crNumber} • ضريبة: {account.vatNumber}</div>
                  </td>
                  <td className="p-3.5">
                    <div className="font-medium text-slate-800">{account.contactPerson}</div>
                    <div className="text-[11px] text-slate-400 font-mono">{account.phone}</div>
                  </td>
                  <td className="p-3.5">
                    <div className="font-bold font-mono text-slate-900">
                      {account.currentBalance.toLocaleString()} / {account.monthlyCreditLimit.toLocaleString()} ر.س
                    </div>
                    <span className="inline-block px-1.5 py-0.5 bg-blue-50 text-blue-700 rounded text-[10px] font-bold mt-0.5">
                      آجل {account.paymentTerms}
                    </span>
                  </td>
                  <td className="p-3.5">
                    <div className="font-medium text-indigo-900">{account.recurringSchedule}</div>
                    <div className="text-[10px] text-slate-400 truncate max-w-xs">{account.itemsSummary}</div>
                  </td>
                  <td className="p-3.5 font-bold font-mono text-emerald-700">
                    {account.lastOrderAmount.toLocaleString()} ر.س
                  </td>
                  <td className="p-3.5">
                    {account.status === 'active' && (
                      <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-emerald-50 text-emerald-700 border border-emerald-200 font-bold text-[11px]">
                        <CheckCircle2 className="w-3 h-3" /> نشط وتوريد ساري
                      </span>
                    )}
                    {account.status === 'overdue' && (
                      <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-red-50 text-red-700 border border-red-200 font-bold text-[11px]">
                        تجاوز الحد الائتماني
                      </span>
                    )}
                  </td>
                  <td className="p-3.5 text-center">
                    <div className="flex items-center justify-center gap-1.5">
                      <button
                        onClick={() => setSelectedAccount(account)}
                        className="p-1.5 text-blue-700 hover:bg-blue-50 rounded-lg transition-colors"
                        title="معاينة عقد الشركة وعروض التوريد"
                      >
                        <Eye className="w-4 h-4" />
                      </button>

                      <button
                        onClick={() => alert(`تم إصدار فاتورة ضريبية ZATCA B2B لشركة ${account.companyName}`)}
                        className="p-1.5 text-slate-600 hover:bg-slate-100 rounded-lg transition-colors"
                        title="إصدار وطباعة فاتورة ضريبية ZATCA B2B"
                      >
                        <Printer className="w-4 h-4" />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Account Details Modal */}
      {selectedAccount && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-2xl max-w-xl w-full p-6 space-y-4 shadow-2xl border border-slate-200 animate-in fade-in zoom-in duration-150">
            <div className="flex items-center justify-between border-b pb-3 border-slate-100">
              <div className="flex items-center gap-2">
                <Building className="w-6 h-6 text-blue-700" />
                <h3 className="font-bold text-base text-slate-900">
                  ملف حساب الشركة ({selectedAccount.companyName})
                </h3>
              </div>
              <button
                onClick={() => setSelectedAccount(null)}
                className="text-slate-400 hover:text-slate-600 p-1"
              >
                ✕
              </button>
            </div>

            <div className="space-y-3 text-xs bg-slate-50 p-4 rounded-xl border border-slate-200">
              <div className="flex justify-between">
                <span className="text-slate-500">السجل التجاري CR:</span>
                <span className="font-mono font-bold text-slate-900">{selectedAccount.crNumber}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-500">الرقم الضريبي VAT:</span>
                <span className="font-mono font-bold text-slate-900">{selectedAccount.vatNumber}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-500">الحد الائتماني الشهري:</span>
                <span className="font-mono font-bold text-blue-700">{selectedAccount.monthlyCreditLimit.toLocaleString()} ر.س</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-500">الرصيد المستحق الحالي:</span>
                <span className="font-mono font-bold text-slate-900">{selectedAccount.currentBalance.toLocaleString()} ر.س</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-500">جدولة التوريد الآلية:</span>
                <span className="font-bold text-indigo-700">{selectedAccount.recurringSchedule}</span>
              </div>
              <div className="pt-2 border-t border-slate-200">
                <span className="text-slate-500 block mb-1">أصناف التموين الأساسية للشركة:</span>
                <span className="font-medium text-slate-800">{selectedAccount.itemsSummary}</span>
              </div>
            </div>

            <div className="flex items-center justify-between pt-2">
              <button
                onClick={() => {
                  alert(`تم إرسال شحنة التوريد الدورية لشركة ${selectedAccount.companyName} عبر أسطول كباتن الديب.`);
                  setSelectedAccount(null);
                }}
                className="px-4 py-2 bg-emerald-600 hover:bg-emerald-700 text-white rounded-xl text-xs font-bold transition-colors flex items-center gap-1.5"
              >
                <Truck className="w-4 h-4" />
                تجهيز وتفويج شحنة هذا الأسبوع الآن
              </button>

              <button
                onClick={() => setSelectedAccount(null)}
                className="px-4 py-2 border border-slate-200 hover:bg-slate-50 text-slate-700 rounded-xl text-xs font-bold transition-colors"
              >
                إغلاق
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
