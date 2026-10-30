import React, { useState } from 'react';
import { Award, Plus, Search, Gift, Star } from 'lucide-react';
import { Customer } from '../types';

interface LoyaltyPageProps {
  customers: Customer[];
  onAddPoints: (customerId: string, points: number) => void;
}

export const LoyaltyPage: React.FC<LoyaltyPageProps> = ({ customers, onAddPoints }) => {
  const [search, setSearch] = useState('');
  const [selectedCustomer, setSelectedCustomer] = useState<Customer | null>(null);
  const [pointsToAdd, setPointsToAdd] = useState<number>(100);

  const filtered = customers.filter(
    (c) =>
      c.full_name.toLowerCase().includes(search.toLowerCase()) ||
      c.email.toLowerCase().includes(search.toLowerCase()) ||
      (c.phone?.includes(search) ?? false)
  );

  const handleGrant = (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedCustomer) return;
    onAddPoints(selectedCustomer.id, pointsToAdd);
    setSelectedCustomer(null);
  };

  return (
    <div className="space-y-6">
      {/* Header Banner */}
      <div className="bg-gradient-to-r from-blue-900 to-indigo-900 text-white p-6 rounded-2xl shadow-sm flex items-center justify-between">
        <div>
          <div className="flex items-center gap-2 mb-2">
            <Award className="w-6 h-6 text-amber-400" />
            <h3 className="text-lg font-extrabold">نادي مكافآت عملاء الديب مول</h3>
          </div>
          <p className="text-xs text-blue-200">
            متابعة أرصدة ولاء العملاء ومنح مكافآت نقاط إضافية أو تعويضات خدمة العملاء
          </p>
        </div>
        <div className="bg-white/10 px-4 py-2.5 rounded-xl border border-white/20 text-center">
          <p className="text-[11px] text-blue-200 font-bold">معادلة الاستبدال الحالية</p>
          <p className="text-sm font-extrabold text-amber-300">100 نقطة = 1.00 د.إ</p>
        </div>
      </div>

      {/* Search Bar */}
      <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-sm flex items-center justify-between">
        <div className="relative w-full md:w-80">
          <input
            type="text"
            placeholder="بحث باسم العميل، البريد، أو رقم الهاتف..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full pr-10 pl-4 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-medium focus:outline-none focus:border-blue-600"
          />
          <Search className="w-4 h-4 text-slate-400 absolute right-3.5 top-2.5" />
        </div>
        <span className="text-xs text-slate-500 font-bold">{filtered.length} عملاء مسجلين</span>
      </div>

      {/* Customers Table */}
      <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
        <table className="w-full text-right text-xs">
          <thead className="bg-slate-50/80 border-b border-slate-200 text-slate-500 font-extrabold">
            <tr>
              <th className="p-4">العميل</th>
              <th className="p-4">الهاتف والبريد</th>
              <th className="p-4">فئة العضوية</th>
              <th className="p-4">رصيد النقاط</th>
              <th className="p-4">القيمة النقدية</th>
              <th className="p-4">إجمالي المشتريات</th>
              <th className="p-4 text-center">مكافأة سريعة</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100 font-medium text-slate-700">
            {filtered.map((c) => (
              <tr key={c.id} className="hover:bg-slate-50/60 transition-colors">
                <td className="p-4 font-extrabold text-slate-900">{c.full_name}</td>
                <td className="p-4 text-slate-500">
                  <p>{c.phone || '-'}</p>
                  <p className="text-[11px] text-slate-400">{c.email}</p>
                </td>
                <td className="p-4">
                  <span
                    className={`px-2.5 py-1 rounded-full text-[11px] font-extrabold inline-flex items-center gap-1 ${
                      c.tier === 'Platinum'
                        ? 'bg-purple-100 text-purple-800'
                        : c.tier === 'Gold'
                        ? 'bg-amber-100 text-amber-800'
                        : 'bg-slate-100 text-slate-700'
                    }`}
                  >
                    <Star className="w-3 h-3 fill-current" />
                    {c.tier}
                  </span>
                </td>
                <td className="p-4 font-black text-amber-600 text-sm">{c.loyalty_points} نقطة</td>
                <td className="p-4 font-bold text-emerald-700">
                  {(c.loyalty_points * 0.01).toFixed(2)} د.إ
                </td>
                <td className="p-4 font-bold text-slate-900">
                  {c.total_spent.toFixed(2)} د.إ ({c.total_orders} طلبات)
                </td>
                <td className="p-4 text-center">
                  <button
                    onClick={() => setSelectedCustomer(c)}
                    className="px-3 py-1.5 bg-blue-50 hover:bg-blue-100 text-blue-700 rounded-lg font-bold text-xs inline-flex items-center gap-1 transition-colors border border-blue-200"
                  >
                    <Gift className="w-3.5 h-3.5" />
                    منح نقاط
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Grant Points Modal */}
      {selectedCustomer && (
        <div className="fixed inset-0 z-50 bg-black/50 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-sm w-full p-6 shadow-2xl space-y-4">
            <h3 className="text-base font-extrabold text-slate-900">
              إضافة نقاط مكافأة إلى {selectedCustomer.full_name}
            </h3>
            <p className="text-xs text-slate-400">
              الرصيد الحالي: {selectedCustomer.loyalty_points} نقطة
            </p>

            <form onSubmit={handleGrant} className="space-y-4 text-xs font-bold text-slate-700">
              <div>
                <label className="block mb-1">عدد النقاط الممنوحة</label>
                <input
                  type="number"
                  min="10"
                  step="10"
                  required
                  value={pointsToAdd}
                  onChange={(e) => setPointsToAdd(Number(e.target.value))}
                  className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-blue-600"
                />
                <p className="text-[11px] text-slate-400 mt-1 font-normal">
                  تعادل خصماً مالياً بقيمة {(pointsToAdd * 0.01).toFixed(2)} د.إ في سلة العميل.
                </p>
              </div>

              <div className="pt-2 flex justify-end gap-2">
                <button
                  type="button"
                  onClick={() => setSelectedCustomer(null)}
                  className="px-3 py-2 bg-slate-100 hover:bg-slate-200 text-slate-600 rounded-xl text-xs font-bold"
                >
                  إلغاء
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-xl text-xs font-bold shadow-md shadow-blue-600/30"
                >
                  تأكيد الإيداع
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
