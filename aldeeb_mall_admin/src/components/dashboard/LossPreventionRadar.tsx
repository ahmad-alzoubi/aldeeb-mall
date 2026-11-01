import React, { useState } from 'react';
import { 
  ShieldAlert, 
  ShieldCheck, 
  AlertTriangle, 
  Camera, 
  Clock, 
  Search, 
  Filter, 
  ExternalLink, 
  DollarSign, 
  Play, 
  CheckCircle2, 
  UserCheck,
  FileText
} from 'lucide-react';
import { SecurityIncident, INITIAL_INCIDENTS } from '../../lib/storeVisionData';

interface LossPreventionRadarProps {
  onOpenIncidentReview: (incident: SecurityIncident) => void;
  incidents: SecurityIncident[];
}

export const LossPreventionRadar: React.FC<LossPreventionRadarProps> = ({
  onOpenIncidentReview,
  incidents,
}) => {
  const [filterSeverity, setFilterSeverity] = useState<'all' | 'critical' | 'warning' | 'resolved'>('all');
  const [searchTerm, setSearchTerm] = useState('');

  const filteredIncidents = incidents.filter(inc => {
    const matchesSeverity = 
      filterSeverity === 'all' ? true :
      filterSeverity === 'resolved' ? (inc.status === 'resolved' || inc.status === 'false_alarm') :
      inc.severity === filterSeverity && inc.status !== 'resolved' && inc.status !== 'false_alarm';

    const matchesSearch = 
      inc.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
      inc.cameraName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      inc.location.toLowerCase().includes(searchTerm.toLowerCase()) ||
      inc.id.toLowerCase().includes(searchTerm.toLowerCase());

    return matchesSeverity && matchesSearch;
  });

  const totalProtectedLoss = incidents
    .filter(i => i.potentialLossAmount)
    .reduce((sum, i) => sum + (i.potentialLossAmount || 0), 0);

  return (
    <div className="bg-slate-900 border border-slate-800 rounded-3xl p-6 text-slate-100 shadow-xl space-y-6" dir="rtl">
      {/* Top Header */}
      <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <span className="p-2 bg-rose-600/20 text-rose-400 rounded-xl">
              <ShieldAlert className="w-5 h-5" />
            </span>
            <h3 className="text-base font-extrabold text-white">
              رادار مكافحة الخسائر والسرقات وأخطاء الكاشير (AI Loss Prevention Radar)
            </h3>
            <span className="text-[11px] font-bold bg-rose-500/20 text-rose-300 border border-rose-500/30 px-2 py-0.5 rounded-full animate-pulse">
              مراقبة آنية نشطة
            </span>
          </div>
          <p className="text-xs text-slate-400 mt-1">
            كشف تلقائي لحركات الإخفاء المشبوهة، الأصناف غير الممسوحة في نقاط البيع، وحوادث هدر سلسلة التبريد
          </p>
        </div>

        {/* Total Value Protected Card */}
        <div className="p-3 bg-slate-950 rounded-2xl border border-slate-800 flex items-center gap-3">
          <div className="p-2 bg-rose-500/10 text-rose-400 rounded-xl">
            <DollarSign className="w-5 h-5" />
          </div>
          <div>
            <span className="text-[10px] text-slate-400 block font-bold">قيمة الأصناف المحمية من الفقد اليوم:</span>
            <span className="text-base font-extrabold text-rose-400 font-mono">
              {totalProtectedLoss.toFixed(2)} ل.س
            </span>
          </div>
        </div>
      </div>

      {/* Filter and Search Bar */}
      <div className="flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-3">
        {/* Search */}
        <div className="relative flex-1">
          <Search className="w-4 h-4 text-slate-500 absolute right-3 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            placeholder="بحث برقم الحادثة، اسم الكاميرا، أو موقع الممر..."
            className="w-full bg-slate-950 border border-slate-800 rounded-xl pr-9 pl-4 py-2 text-xs text-slate-200 placeholder-slate-500 focus:outline-none focus:border-blue-500"
          />
        </div>

        {/* Severity Tabs */}
        <div className="flex items-center gap-1.5 p-1 bg-slate-950 rounded-xl border border-slate-800 text-xs self-start sm:self-auto">
          <button
            onClick={() => setFilterSeverity('all')}
            className={`px-3 py-1.5 rounded-lg font-bold transition-all ${
              filterSeverity === 'all' ? 'bg-blue-600 text-white' : 'text-slate-400 hover:text-white'
            }`}
          >
            كافة الحوادث ({incidents.length})
          </button>
          <button
            onClick={() => setFilterSeverity('critical')}
            className={`px-3 py-1.5 rounded-lg font-bold transition-all ${
              filterSeverity === 'critical' ? 'bg-rose-600 text-white' : 'text-slate-400 hover:text-white'
            }`}
          >
            حرجة وشبهات سرقة
          </button>
          <button
            onClick={() => setFilterSeverity('warning')}
            className={`px-3 py-1.5 rounded-lg font-bold transition-all ${
              filterSeverity === 'warning' ? 'bg-amber-600 text-white' : 'text-slate-400 hover:text-white'
            }`}
          >
            تنبيهات وأخطاء كاشير
          </button>
          <button
            onClick={() => setFilterSeverity('resolved')}
            className={`px-3 py-1.5 rounded-lg font-bold transition-all ${
              filterSeverity === 'resolved' ? 'bg-emerald-600 text-white' : 'text-slate-400 hover:text-white'
            }`}
          >
            تمت المعالجة
          </button>
        </div>
      </div>

      {/* Incidents List Grid */}
      <div className="space-y-3">
        {filteredIncidents.length === 0 ? (
          <div className="text-center py-12 bg-slate-950/60 rounded-2xl border border-slate-800/80">
            <ShieldCheck className="w-10 h-10 text-emerald-400 mx-auto mb-2 opacity-80" />
            <p className="text-sm font-bold text-slate-300">لا توجد حوادث أمنية مطابقة للفلتر المحدد</p>
            <p className="text-xs text-slate-500 mt-1">الممرات ونقاط البيع تعمل ضمن أعلى معايير الانضباط والأمان</p>
          </div>
        ) : (
          filteredIncidents.map((incident) => {
            const isResolved = incident.status === 'resolved' || incident.status === 'false_alarm';
            return (
              <div
                key={incident.id}
                className={`p-4 rounded-2xl border transition-all flex flex-col md:flex-row items-start md:items-center justify-between gap-4 ${
                  incident.severity === 'critical' && !isResolved
                    ? 'bg-rose-950/20 border-rose-500/40 hover:border-rose-500/70'
                    : incident.severity === 'warning' && !isResolved
                    ? 'bg-amber-950/20 border-amber-500/40 hover:border-amber-500/70'
                    : 'bg-slate-950/60 border-slate-800 hover:border-slate-700'
                }`}
              >
                {/* Right: Thumbnail & Details */}
                <div className="flex items-start sm:items-center gap-3.5 flex-1">
                  <div className="relative w-16 h-16 sm:w-20 sm:h-20 rounded-xl overflow-hidden border border-slate-700 shrink-0 group cursor-pointer"
                    onClick={() => onOpenIncidentReview(incident)}
                  >
                    <img 
                      src={incident.thumbnailUrl} 
                      alt={incident.title} 
                      className="w-full h-full object-cover group-hover:scale-105 transition-transform"
                    />
                    <div className="absolute inset-0 bg-black/40 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity">
                      <Play className="w-5 h-5 text-white fill-white" />
                    </div>
                  </div>

                  <div className="space-y-1">
                    <div className="flex flex-wrap items-center gap-2">
                      <span className="font-extrabold text-sm text-white">{incident.title}</span>
                      <span className="text-[10px] font-mono px-1.5 py-0.5 rounded bg-slate-800 text-slate-400 border border-slate-700">
                        {incident.id}
                      </span>
                      <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${
                        incident.severity === 'critical' 
                          ? 'bg-rose-500/20 text-rose-300 border border-rose-500/30' 
                          : incident.severity === 'warning'
                          ? 'bg-amber-500/20 text-amber-300 border border-amber-500/30'
                          : 'bg-blue-500/20 text-blue-300'
                      }`}>
                        دقة الذكاء: {incident.confidence}%
                      </span>
                    </div>

                    <p className="text-xs text-slate-300 line-clamp-1">
                      {incident.description}
                    </p>

                    <div className="flex flex-wrap items-center gap-3 text-[11px] text-slate-400 pt-0.5">
                      <span className="flex items-center gap-1">
                        <Camera className="w-3 h-3 text-blue-400" />
                        {incident.cameraName}
                      </span>
                      <span className="flex items-center gap-1">
                        <Clock className="w-3 h-3 text-purple-400" />
                        {incident.timestamp}
                      </span>
                      {incident.potentialLossAmount && (
                        <span className="font-bold text-rose-400 font-mono">
                          القيمة: {incident.potentialLossAmount} ل.س
                        </span>
                      )}
                    </div>
                  </div>
                </div>

                {/* Left: Status & Action Button */}
                <div className="flex items-center gap-3 w-full md:w-auto justify-between md:justify-end pt-2 md:pt-0 border-t md:border-t-0 border-slate-800">
                  <div className="text-right">
                    <span className={`text-xs font-bold px-2.5 py-1 rounded-xl block ${
                      incident.status === 'active' 
                        ? 'bg-rose-500/20 text-rose-400 border border-rose-500/30' 
                        : incident.status === 'investigating'
                        ? 'bg-amber-500/20 text-amber-400 border border-amber-500/30'
                        : incident.status === 'resolved'
                        ? 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/30'
                        : 'bg-slate-800 text-slate-400'
                    }`}>
                      {incident.status === 'active' ? 'تنبيه نشط ⚠️' :
                       incident.status === 'investigating' ? 'قيد التحقق 🔍' :
                       incident.status === 'resolved' ? 'تم التعامل ✅' : 'إنذار كاذب مستبعد'}
                    </span>
                  </div>

                  <button
                    onClick={() => onOpenIncidentReview(incident)}
                    className="px-3.5 py-2 bg-blue-600 hover:bg-blue-500 text-white rounded-xl text-xs font-bold transition-all shadow-md flex items-center gap-1.5"
                  >
                    <Play className="w-3.5 h-3.5" />
                    مراجعة التسجيل والأدلة
                  </button>
                </div>
              </div>
            );
          })
        )}
      </div>
    </div>
  );
};
