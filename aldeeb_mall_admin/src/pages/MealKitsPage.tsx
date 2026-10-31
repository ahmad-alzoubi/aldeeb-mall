import React, { useState } from 'react';
import { 
  UtensilsCrossed, 
  ChefHat, 
  Clock, 
  Plus, 
  CheckCircle2, 
  DollarSign, 
  TrendingUp, 
  Calendar, 
  Boxes, 
  ShieldCheck, 
  Layers, 
  Sparkles, 
  X,
  Search,
  Users
} from 'lucide-react';

interface MealKitRecipe {
  id: string;
  title: string;
  cuisine: string;
  chefName: string;
  prepTimeMinutes: number;
  difficulty: 'سهل' | 'متوسط' | 'احترافي';
  basePrice2P: number;
  foodCost: number;
  grossMarginPercent: number;
  stockKitsToday: number;
  assembledToday: number;
  status: 'ACTIVE' | 'SOLD_OUT' | 'SEASONAL';
  subscribersCount: number;
}

interface AssemblyStation {
  id: string;
  name: string;
  operatorName: string;
  temperatureCelsius: number;
  currentTask: string;
  completedUnits: number;
  targetUnits: number;
  status: 'OPTIMAL' | 'BUSY' | 'CLEANING';
}

const initialKits: MealKitRecipe[] = [
  {
    id: 'KIT-001',
    title: 'بوكس كبسة لحم الحاشي الفاخرة مع الأرز العنبر',
    cuisine: 'سعودي وخليجي',
    chefName: 'الشيف نورة',
    prepTimeMinutes: 30,
    difficulty: 'سهل',
    basePrice2P: 54.0,
    foodCost: 22.8,
    grossMarginPercent: 57.8,
    stockKitsToday: 35,
    assembledToday: 140,
    status: 'ACTIVE',
    subscribersCount: 480,
  },
  {
    id: 'KIT-002',
    title: 'بوكس فيليه السالمون النرويجي بالليمون والأعشاب والهليون',
    cuisine: 'أطباق بحرية',
    chefName: 'الشيف كريستيان',
    prepTimeMinutes: 18,
    difficulty: 'سهل',
    basePrice2P: 68.0,
    foodCost: 27.5,
    grossMarginPercent: 59.5,
    stockKitsToday: 18,
    assembledToday: 95,
    status: 'ACTIVE',
    subscribersCount: 320,
  },
  {
    id: 'KIT-003',
    title: 'بوكس فيتوتشيني ألفريدو بالدجاج الفاخر والفطر البري',
    cuisine: 'إيطالي وعالمي',
    chefName: 'الشيف أندريا',
    prepTimeMinutes: 20,
    difficulty: 'سهل',
    basePrice2P: 48.0,
    foodCost: 18.2,
    grossMarginPercent: 62.1,
    stockKitsToday: 24,
    assembledToday: 110,
    status: 'ACTIVE',
    subscribersCount: 290,
  },
  {
    id: 'KIT-004',
    title: 'بوكس مقلوبة الدجاج والخضار المشكلة مع سلطة الزبادي',
    cuisine: 'سعودي وخليجي',
    chefName: 'الشيف نورة',
    prepTimeMinutes: 28,
    difficulty: 'متوسط',
    basePrice2P: 46.0,
    foodCost: 17.5,
    grossMarginPercent: 61.9,
    stockKitsToday: 20,
    assembledToday: 85,
    status: 'ACTIVE',
    subscribersCount: 240,
  },
];

const initialStations: AssemblyStation[] = [
  {
    id: 'ST-01',
    name: 'محطة اللحوم والدواجن المتبلة (Vacuum Sealed Line)',
    operatorName: 'فهد المطيري',
    temperatureCelsius: 2.4,
    currentTask: 'تجهيز وتفريغ هواء 60 كيس لحم حاشي متبل',
    completedUnits: 140,
    targetUnits: 160,
    status: 'OPTIMAL',
  },
  {
    id: 'ST-02',
    name: 'محطة الخضار والأعشاب المغسولة والمعقمة (Prep & Chop)',
    operatorName: 'سعيد بامحرز',
    temperatureCelsius: 4.1,
    currentTask: 'تقطيع وتغليف أعواد الهليون وبطاطس السالمون',
    completedUnits: 115,
    targetUnits: 130,
    status: 'OPTIMAL',
  },
  {
    id: 'ST-03',
    name: 'محطة الصوصات والبهارات الموزونة (Spices & Sauces)',
    operatorName: 'ياسين الشريف',
    temperatureCelsius: 18.0,
    currentTask: 'تعبئة أظرف بهارات الكبسة النجدية والصرار',
    completedUnits: 180,
    targetUnits: 200,
    status: 'OPTIMAL',
  },
  {
    id: 'ST-04',
    name: 'محطة التجميع النهائي والتغليف الحراري (Kit Boxing)',
    operatorName: 'خالد العنزي',
    temperatureCelsius: 3.5,
    currentTask: 'دمج المكونات مع بطاقة الوصفة والختم الحراري',
    completedUnits: 430,
    targetUnits: 500,
    status: 'BUSY',
  },
];

export const MealKitsPage: React.FC = () => {
  const [kits, setKits] = useState<MealKitRecipe[]>(initialKits);
  const [stations] = useState<AssemblyStation[]>(initialStations);
  const [activeTab, setActiveTab] = useState<'catalog' | 'stations' | 'subscriptions'>('catalog');
  const [searchQuery, setSearchQuery] = useState('');
  const [showAddModal, setShowAddModal] = useState(false);

  // New kit form
  const [newTitle, setNewTitle] = useState('');
  const [newCuisine, setNewCuisine] = useState('سعودي وخليجي');
  const [newChef, setNewChef] = useState('الشيف نورة');
  const [newPrepTime, setNewPrepTime] = useState(25);
  const [newPrice, setNewPrice] = useState(50);
  const [newFoodCost, setNewFoodCost] = useState(20);

  const totalAssembled = kits.reduce((acc, k) => acc + k.assembledToday, 0);
  const totalSubscribers = kits.reduce((acc, k) => acc + k.subscribersCount, 0);
  const avgMargin = (kits.reduce((acc, k) => acc + k.grossMarginPercent, 0) / kits.length).toFixed(1);

  const filteredKits = kits.filter(k => 
    k.title.includes(searchQuery) || k.cuisine.includes(searchQuery) || k.chefName.includes(searchQuery)
  );

  const handleCreateKit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newTitle) return;

    const margin = Number((((newPrice - newFoodCost) / newPrice) * 100).toFixed(1));
    const newK: MealKitRecipe = {
      id: `KIT-00${kits.length + 1}`,
      title: newTitle,
      cuisine: newCuisine,
      chefName: newChef,
      prepTimeMinutes: Number(newPrepTime),
      difficulty: 'سهل',
      basePrice2P: Number(newPrice),
      foodCost: Number(newFoodCost),
      grossMarginPercent: margin,
      stockKitsToday: 20,
      assembledToday: 0,
      status: 'ACTIVE',
      subscribersCount: 15,
    };

    setKits([newK, ...kits]);
    setShowAddModal(false);
    setNewTitle('');
  };

  return (
    <div className="space-y-6">
      {/* Top Banner */}
      <div className="bg-gradient-to-r from-slate-900 via-amber-950 to-slate-900 border border-amber-900/50 rounded-2xl p-6 text-white shadow-xl flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <div>
          <div className="flex items-center gap-3">
            <div className="p-3 bg-amber-600/30 border border-amber-500/40 rounded-xl text-amber-400">
              <UtensilsCrossed className="w-7 h-7" />
            </div>
            <div>
              <h1 className="text-2xl font-bold flex items-center gap-2">
                إدارة خطوط إنتاج وتجهيز بوكسات الوجبات (Chef Meal Kits BOM)
                <span className="text-xs bg-amber-500/20 text-amber-300 border border-amber-500/30 px-2.5 py-0.5 rounded-full font-mono">
                  HACCP Food Safety
                </span>
              </h1>
              <p className="text-sm text-slate-400 mt-1">
                تخطيط وجبات الطهي السريع الموزونة، مراقبة محطات التجهيز المبردة، واشتراكات الأسر الأسبوعية
              </p>
            </div>
          </div>
        </div>

        <div className="flex items-center gap-3 w-full md:w-auto">
          <button
            onClick={() => setShowAddModal(true)}
            className="flex-1 md:flex-none flex items-center justify-center gap-2 bg-amber-600 hover:bg-amber-700 text-white font-medium px-4 py-2.5 rounded-xl transition shadow-lg shadow-amber-600/30 text-sm"
          >
            <Plus className="w-4 h-4" />
            إضافة بوكس وجبة جديد (BOM)
          </button>
        </div>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs flex items-center justify-between">
          <div>
            <p className="text-xs font-medium text-slate-700">بوكسات مجهزة ومغلفة اليوم</p>
            <h3 className="text-2xl font-extrabold text-amber-600 mt-1">{totalAssembled} بوكس</h3>
            <p className="text-xs text-slate-700 font-medium mt-1 flex items-center gap-1">
              <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600" />
              جاهزة في المستودع المبرد
            </p>
          </div>
          <div className="p-3 bg-amber-50 text-amber-600 rounded-xl">
            <Boxes className="w-6 h-6" />
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs flex items-center justify-between">
          <div>
            <p className="text-xs font-medium text-slate-700">الأسر المشتركة أسبوعياً</p>
            <h3 className="text-2xl font-extrabold text-indigo-600 mt-1">{totalSubscribers.toLocaleString()} أسرة</h3>
            <p className="text-xs text-emerald-600 font-medium mt-1">
              +18% نمو الاشتراكات المتكررة
            </p>
          </div>
          <div className="p-3 bg-indigo-50 text-indigo-600 rounded-xl">
            <Users className="w-6 h-6" />
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs flex items-center justify-between">
          <div>
            <p className="text-xs font-medium text-slate-700">متوسط هامش الربح الإجمالي</p>
            <h3 className="text-2xl font-extrabold text-emerald-600 mt-1">{avgMargin}%</h3>
            <p className="text-xs text-slate-700 font-medium mt-1">
              تكلفة الغذاء المباشرة 41.2%
            </p>
          </div>
          <div className="p-3 bg-emerald-50 text-emerald-600 rounded-xl">
            <DollarSign className="w-6 h-6" />
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs flex items-center justify-between">
          <div>
            <p className="text-xs font-medium text-slate-700">زمن التحضير المنزلي القياسي</p>
            <h3 className="text-2xl font-extrabold text-slate-900 mt-1">22 دقيقة</h3>
            <p className="text-xs text-blue-600 font-medium mt-1 flex items-center gap-1">
              <Clock className="w-3.5 h-3.5" />
              أسرع بـ 65% من الطبخ التقليدي
            </p>
          </div>
          <div className="p-3 bg-blue-50 text-blue-600 rounded-xl">
            <Clock className="w-6 h-6" />
          </div>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex border-b border-slate-200">
        <button
          onClick={() => setActiveTab('catalog')}
          className={`pb-3 px-4 text-sm font-bold border-b-2 flex items-center gap-2 transition ${
            activeTab === 'catalog'
              ? 'border-amber-600 text-amber-600'
              : 'border-transparent text-slate-500 hover:text-slate-700'
          }`}
        >
          <ChefHat className="w-4 h-4" />
          كتالوج بوكسات الوجبات وتكاليفها ({kits.length})
        </button>

        <button
          onClick={() => setActiveTab('stations')}
          className={`pb-3 px-4 text-sm font-bold border-b-2 flex items-center gap-2 transition ${
            activeTab === 'stations'
              ? 'border-amber-600 text-amber-600'
              : 'border-transparent text-slate-500 hover:text-slate-700'
          }`}
        >
          <Layers className="w-4 h-4" />
          محطات التجهيز والتغليف المبردة ({stations.length})
        </button>

        <button
          onClick={() => setActiveTab('subscriptions')}
          className={`pb-3 px-4 text-sm font-bold border-b-2 flex items-center gap-2 transition ${
            activeTab === 'subscriptions'
              ? 'border-amber-600 text-amber-600'
              : 'border-transparent text-slate-500 hover:text-slate-700'
          }`}
        >
          <Calendar className="w-4 h-4" />
          اشتراكات الأسر الأسبوعية والتوصيل المجدول
        </button>
      </div>

      {/* TAB 1: CATALOG */}
      {activeTab === 'catalog' && (
        <div className="space-y-4">
          <div className="bg-white p-4 rounded-xl border border-slate-200 flex flex-col md:flex-row gap-4 items-center justify-between">
            <div className="relative w-full md:w-80">
              <Search className="w-4 h-4 text-slate-400 absolute right-3 top-3" />
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="ابحث باسم الوجبة أو الشيف..."
                className="w-full pl-4 pr-9 py-2 bg-slate-50 border border-slate-200 rounded-lg text-sm focus:outline-hidden"
              />
            </div>
          </div>

          <div className="bg-white rounded-xl border border-slate-200 overflow-hidden shadow-xs">
            <div className="overflow-x-auto">
              <table className="w-full text-right text-sm">
                <thead className="bg-slate-50 text-slate-700 text-xs font-bold border-b border-slate-200">
                  <tr>
                    <th className="p-3.5">اسم بوكس الوجبة / الكود</th>
                    <th className="p-3.5">المطبخ والشيف</th>
                    <th className="p-3.5">زمن الطهي</th>
                    <th className="p-3.5">سعر البيع (شخصين)</th>
                    <th className="p-3.5">تكلفة المقادير (BOM)</th>
                    <th className="p-3.5">هامش الربح %</th>
                    <th className="p-3.5">المجهز اليوم</th>
                    <th className="p-3.5">المشتركون الدائمون</th>
                    <th className="p-3.5">الحالة</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {filteredKits.map((kit) => (
                    <tr key={kit.id} className="hover:bg-slate-50 transition">
                      <td className="p-3.5">
                        <div className="font-bold text-slate-900">{kit.title}</div>
                        <div className="text-xs text-slate-400 font-mono">{kit.id}</div>
                      </td>
                      <td className="p-3.5">
                        <span className="bg-slate-100 text-slate-700 font-medium px-2 py-0.5 rounded text-xs">
                          {kit.cuisine}
                        </span>
                        <div className="text-[11px] text-slate-500 mt-0.5">{kit.chefName}</div>
                      </td>
                      <td className="p-3.5">
                        <div className="flex items-center gap-1 text-xs text-slate-700 font-medium">
                          <Clock className="w-3.5 h-3.5 text-amber-600" />
                          {kit.prepTimeMinutes} دقيقة
                        </div>
                      </td>
                      <td className="p-3.5 font-extrabold text-slate-900 text-sm">
                        {kit.basePrice2P.toFixed(2)} ر.س
                      </td>
                      <td className="p-3.5 text-slate-500 font-mono text-xs">
                        {kit.foodCost.toFixed(2)} ر.س
                      </td>
                      <td className="p-3.5 font-bold text-emerald-600">
                        {kit.grossMarginPercent}%
                      </td>
                      <td className="p-3.5 font-bold text-amber-700">
                        {kit.assembledToday} بوكس
                      </td>
                      <td className="p-3.5 font-medium text-indigo-600 text-xs">
                        {kit.subscribersCount} أسرة
                      </td>
                      <td className="p-3.5">
                        <span className="bg-emerald-100 text-emerald-800 font-bold px-2 py-0.5 rounded-full text-xs">
                          نشط بالكتالوج
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

      {/* TAB 2: ASSEMBLY STATIONS */}
      {activeTab === 'stations' && (
        <div className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {stations.map((st) => (
              <div key={st.id} className="bg-white rounded-xl border border-slate-200 p-5 shadow-xs">
                <div className="flex items-start justify-between">
                  <div>
                    <h4 className="font-bold text-slate-900 text-base">{st.name}</h4>
                    <p className="text-xs text-slate-500 mt-0.5">المسؤول: {st.operatorName}</p>
                  </div>
                  <div className="flex items-center gap-1.5 bg-blue-50 text-blue-700 px-2.5 py-1 rounded-lg text-xs font-mono font-bold">
                    <span>❄️ {st.temperatureCelsius}°C</span>
                  </div>
                </div>

                <div className="mt-4 p-3 bg-slate-50 rounded-xl space-y-2 text-xs">
                  <div className="text-slate-700 font-medium">
                    <span className="text-slate-400">المهمة الجارية: </span>
                    {st.currentTask}
                  </div>
                  <div>
                    <div className="flex justify-between text-slate-500 mb-1">
                      <span>إنجاز الوردية الصباحية:</span>
                      <span className="font-bold text-slate-900">{st.completedUnits} / {st.targetUnits} بوكس</span>
                    </div>
                    <div className="w-full bg-slate-200 h-2 rounded-full overflow-hidden">
                      <div 
                        className="bg-amber-500 h-full rounded-full transition-all"
                        style={{ width: `${(st.completedUnits / st.targetUnits) * 100}%` }}
                      ></div>
                    </div>
                  </div>
                </div>

                <div className="mt-4 flex justify-between items-center text-xs">
                  <span className="flex items-center gap-1 text-emerald-600 font-bold">
                    <CheckCircle2 className="w-4 h-4" /> معايير سلامة الأغذية SFDA مستوفاة 100%
                  </span>
                  <span className="font-mono text-slate-400">{st.id}</span>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* TAB 3: SUBSCRIPTIONS */}
      {activeTab === 'subscriptions' && (
        <div className="bg-white rounded-xl border border-slate-200 p-6 space-y-4 shadow-xs">
          <div>
            <h3 className="text-lg font-bold text-slate-900">برنامج اشتراكات وجبات الأسبوع العائلية (Weekly Meal Box Plan)</h3>
            <p className="text-xs text-slate-500 mt-1">
              جدولة تسليم البوكسات الحرارية المبردة فجر كل سبت وثلاثاء مباشرة لمنازل المشتركين
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-4 pt-2">
            <div className="p-4 rounded-xl border border-amber-200 bg-amber-50/40">
              <span className="text-xs font-bold text-amber-800 bg-amber-200 px-2 py-0.5 rounded">باقة شخصين</span>
              <h4 className="text-base font-bold text-slate-900 mt-2">3 وجبات أسبوعياً (6 حصص)</h4>
              <p className="text-xs text-slate-600 mt-1">توفير 15% مع توصيل مجاني مبرد أسبوعياً</p>
              <div className="mt-4 pt-3 border-t border-amber-200 font-extrabold text-amber-800 text-lg">
                135.00 ر.س / أسبوع
              </div>
            </div>

            <div className="p-4 rounded-xl border border-indigo-200 bg-indigo-50/40">
              <span className="text-xs font-bold text-indigo-800 bg-indigo-200 px-2 py-0.5 rounded">باقة العائلة (الأكثر طلباً)</span>
              <h4 className="text-base font-bold text-slate-900 mt-2">4 وجبات أسبوعياً (16 حصة)</h4>
              <p className="text-xs text-slate-600 mt-1">توفير 22% مع تشكيلة لحوم طازجة وسالمون وباستا</p>
              <div className="mt-4 pt-3 border-t border-indigo-200 font-extrabold text-indigo-800 text-lg">
                298.00 ر.س / أسبوع
              </div>
            </div>

            <div className="p-4 rounded-xl border border-emerald-200 bg-emerald-50/40">
              <span className="text-xs font-bold text-emerald-800 bg-emerald-200 px-2 py-0.5 rounded">باقة كيتو وصحي</span>
              <h4 className="text-base font-bold text-slate-900 mt-2">5 وجبات كيتو عالية البروتين</h4>
              <p className="text-xs text-slate-600 mt-1">خالية من السكر والغلوتين ومحسوبة الماكروز بالجرام</p>
              <div className="mt-4 pt-3 border-t border-emerald-200 font-extrabold text-emerald-800 text-lg">
                320.00 ر.س / أسبوع
              </div>
            </div>
          </div>
        </div>
      )}

      {/* MODAL: ADD MEAL KIT */}
      {showAddModal && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-xs flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl max-w-lg w-full p-6 shadow-2xl">
            <div className="flex items-center justify-between border-b pb-3 mb-4">
              <h3 className="text-lg font-bold text-slate-900 flex items-center gap-2">
                <UtensilsCrossed className="w-5 h-5 text-amber-600" />
                هندسة بوكس وجبة طهي سريع جديد (BOM)
              </h3>
              <button onClick={() => setShowAddModal(false)} className="text-slate-400 hover:text-slate-600">
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleCreateKit} className="space-y-4">
              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1">اسم بوكس الوجبة</label>
                <input
                  type="text"
                  required
                  value={newTitle}
                  onChange={(e) => setNewTitle(e.target.value)}
                  placeholder="مثال: بوكس برياني اللحم الكشميري"
                  className="w-full px-3 py-2 border rounded-lg text-sm"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">نوع المطبخ</label>
                  <select
                    value={newCuisine}
                    onChange={(e) => setNewCuisine(e.target.value)}
                    className="w-full px-3 py-2 border rounded-lg text-sm bg-white"
                  >
                    <option value="سعودي وخليجي">سعودي وخليجي</option>
                    <option value="أطباق بحرية">أطباق بحرية</option>
                    <option value="إيطالي وعالمي">إيطالي وعالمي</option>
                    <option value="صحي وكيتو">صحي وكيتو</option>
                  </select>
                </div>
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">الشيف المشرف</label>
                  <input
                    type="text"
                    value={newChef}
                    onChange={(e) => setNewChef(e.target.value)}
                    className="w-full px-3 py-2 border rounded-lg text-sm"
                  />
                </div>
              </div>

              <div className="grid grid-cols-3 gap-3">
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">زمن الطهي (دقائق)</label>
                  <input
                    type="number"
                    value={newPrepTime}
                    onChange={(e) => setNewPrepTime(Number(e.target.value))}
                    className="w-full px-3 py-2 border rounded-lg text-sm"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">تكلفة المقادير (BOM)</label>
                  <input
                    type="number"
                    step="0.5"
                    value={newFoodCost}
                    onChange={(e) => setNewFoodCost(Number(e.target.value))}
                    className="w-full px-3 py-2 border rounded-lg text-sm"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">سعر البيع (2P)</label>
                  <input
                    type="number"
                    step="0.5"
                    value={newPrice}
                    onChange={(e) => setNewPrice(Number(e.target.value))}
                    className="w-full px-3 py-2 border rounded-lg text-sm font-bold text-emerald-600"
                  />
                </div>
              </div>

              <div className="p-3 bg-amber-50 rounded-xl flex justify-between items-center text-xs">
                <span className="text-amber-900 font-bold">هامش الربح المتوقع:</span>
                <span className="font-extrabold text-emerald-700 text-sm">
                  {newPrice > 0 ? (((newPrice - newFoodCost) / newPrice) * 100).toFixed(1) : 0}%
                </span>
              </div>

              <div className="flex items-center justify-end gap-3 pt-3 border-t">
                <button
                  type="button"
                  onClick={() => setShowAddModal(false)}
                  className="px-4 py-2 border rounded-lg text-sm text-slate-600 hover:bg-slate-50"
                >
                  إلغاء
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 bg-amber-600 hover:bg-amber-700 text-white rounded-lg text-sm font-bold shadow-md shadow-amber-600/30"
                >
                  اعتماد وجدولة البوكس
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
