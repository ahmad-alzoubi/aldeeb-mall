import React, { useState } from 'react';
import { 
  X, 
  ShieldAlert, 
  Clock, 
  MapPin, 
  Camera, 
  Play, 
  Pause, 
  RotateCcw, 
  Maximize2, 
  Volume2, 
  VolumeX, 
  CheckCircle2, 
  AlertTriangle, 
  UserCheck, 
  FileDown, 
  Radio, 
  Sliders,
  DollarSign
} from 'lucide-react';
import { SecurityIncident } from '../../lib/storeVisionData';

interface IncidentReviewModalProps {
  incident: SecurityIncident | null;
  onClose: () => void;
  onUpdateStatus: (incidentId: string, newStatus: SecurityIncident['status'], actionMessage: string) => void;
}

export const IncidentReviewModal: React.FC<IncidentReviewModalProps> = ({
  incident,
  onClose,
  onUpdateStatus,
}) => {
  if (!incident) return null;

  const [isPlaying, setIsPlaying] = useState(true);
  const [playbackTime, setPlaybackTime] = useState(6.4); // seconds in 10s clip
  const [isAudioMuted, setIsAudioMuted] = useState(true);
  const [showAiBoxes, setShowAiBoxes] = useState(true);
  const [feedbackSuccess, setFeedbackSuccess] = useState<string | null>(null);

  const handleAction = (status: SecurityIncident['status'], msg: string) => {
    onUpdateStatus(incident.id, status, msg);
    setFeedbackSuccess(msg);
    setTimeout(() => {
      setFeedbackSuccess(null);
      onClose();
    }, 1200);
  };

  return (
    <div className="fixed inset-0 z-50 bg-slate-950/80 backdrop-blur-md flex items-center justify-center p-4">
      <div 
        className="bg-slate-900 border border-slate-700/80 rounded-3xl max-w-4xl w-full overflow-hidden shadow-2xl text-slate-100 flex flex-col max-h-[92vh] animate-in fade-in zoom-in-95 duration-200"
        dir="rtl"
      >
        {/* Modal Top Header */}
        <div className="px-6 py-4 bg-slate-800/90 border-b border-slate-700/60 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className={`p-2.5 rounded-2xl ${
              incident.severity === 'critical' 
                ? 'bg-rose-500/20 text-rose-400 border border-rose-500/30' 
                : incident.severity === 'warning'
                ? 'bg-amber-500/20 text-amber-400 border border-amber-500/30'
                : 'bg-blue-500/20 text-blue-400 border border-blue-500/30'
            }`}>
              <ShieldAlert className="w-5 h-5" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <span className="font-extrabold text-base text-white">{incident.title}</span>
                <span className="text-[11px] font-mono font-bold bg-slate-800 text-slate-300 px-2 py-0.5 rounded-md border border-slate-700">
                  {incident.id}
                </span>
                <span className="text-xs px-2.5 py-0.5 rounded-full font-bold bg-emerald-500/20 text-emerald-300 border border-emerald-500/30">
                  دقة الذكاء: {incident.confidence}%
                </span>
              </div>
              <div className="flex items-center gap-4 text-xs text-slate-400 mt-1">
                <span className="flex items-center gap-1">
                  <Camera className="w-3.5 h-3.5 text-blue-400" />
                  {incident.cameraName}
                </span>
                <span className="flex items-center gap-1">
                  <MapPin className="w-3.5 h-3.5 text-amber-400" />
                  {incident.location}
                </span>
                <span className="flex items-center gap-1">
                  <Clock className="w-3.5 h-3.5 text-purple-400" />
                  {incident.timestamp}
                </span>
              </div>
            </div>
          </div>

          <button
            onClick={onClose}
            className="p-2 rounded-xl text-slate-400 hover:text-white hover:bg-slate-800 transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Modal Body: Split Screen */}
        <div className="grid grid-cols-1 lg:grid-cols-12 flex-1 overflow-y-auto">
          {/* Video Player Column (7 cols) */}
          <div className="lg:col-span-7 p-6 bg-slate-950 flex flex-col justify-between border-b lg:border-b-0 lg:border-l border-slate-800">
            {/* The Surveillance Player Frame */}
            <div className="relative aspect-video bg-black rounded-2xl overflow-hidden border border-slate-800 shadow-inner group">
              <img 
                src={incident.thumbnailUrl} 
                alt="Security Evidence" 
                className="w-full h-full object-cover opacity-85 group-hover:opacity-95 transition-opacity"
              />

              {/* CCTV Live Simulated HUD */}
              <div className="absolute top-3 right-3 flex items-center gap-2">
                <span className="flex items-center gap-1.5 bg-red-600/90 text-white text-[11px] font-bold px-2.5 py-1 rounded-md shadow-md animate-pulse">
                  <Radio className="w-3 h-3" />
                  تسجيل أمني مسجل (REC REPLAY)
                </span>
                <span className="bg-slate-900/80 text-white text-[11px] font-mono px-2 py-1 rounded-md border border-slate-700">
                  {incident.cameraId}
                </span>
              </div>

              <div className="absolute top-3 left-3 text-[11px] font-mono text-emerald-400 bg-slate-900/85 px-2.5 py-1 rounded-md border border-emerald-500/30">
                1080p 60FPS • BITRATE: 8.4 Mbps
              </div>

              {/* Dynamic AI Bounding Box overlay */}
              {showAiBoxes && (
                <div 
                  className="absolute border-2 border-rose-500 bg-rose-500/20 rounded-lg animate-pulse"
                  style={{ top: '28%', left: '32%', width: '36%', height: '52%' }}
                >
                  <div className="absolute -top-7 right-0 bg-rose-600 text-white text-[11px] font-bold px-2 py-0.5 rounded shadow-lg whitespace-nowrap">
                    ⚠️ {incident.type === 'shoplifting_suspect' ? 'حركة إخفاء مشبوهة' : 'صنف غير ممسوح'} ({incident.confidence}%)
                  </div>
                </div>
              )}

              {/* Player Overlay Controls */}
              <div className="absolute bottom-0 inset-x-0 bg-gradient-to-t from-slate-950 via-slate-950/80 to-transparent p-4">
                {/* Scrub Progress Bar */}
                <div className="relative w-full h-2 bg-slate-800 rounded-full cursor-pointer mb-3">
                  <div 
                    className="absolute top-0 right-0 h-full bg-blue-500 rounded-full"
                    style={{ width: `${(playbackTime / 10) * 100}%` }}
                  />
                  {/* Incident Marker Dot */}
                  <div 
                    className="absolute top-1/2 -translate-y-1/2 w-3.5 h-3.5 bg-rose-500 rounded-full border-2 border-white shadow-lg"
                    style={{ right: '64%' }}
                    title="لحظة وقوع التنبيه"
                  />
                </div>

                <div className="flex items-center justify-between text-xs text-slate-300">
                  <div className="flex items-center gap-3">
                    <button 
                      onClick={() => setIsPlaying(!isPlaying)}
                      className="p-1.5 bg-blue-600 hover:bg-blue-500 text-white rounded-lg transition-colors"
                    >
                      {isPlaying ? <Pause className="w-4 h-4" /> : <Play className="w-4 h-4" />}
                    </button>
                    <button 
                      onClick={() => setPlaybackTime(0)}
                      className="p-1.5 hover:bg-slate-800 rounded-lg text-slate-400 hover:text-white transition-colors"
                      title="إعادة التشغيل"
                    >
                      <RotateCcw className="w-4 h-4" />
                    </button>
                    <span className="font-mono text-xs text-slate-400">
                      00:0{Math.floor(playbackTime)} / 00:10
                    </span>
                  </div>

                  <div className="flex items-center gap-2">
                    <button
                      onClick={() => setShowAiBoxes(!showAiBoxes)}
                      className={`px-2.5 py-1 rounded-md text-[11px] font-bold border transition-colors ${
                        showAiBoxes 
                          ? 'bg-blue-500/20 text-blue-300 border-blue-500/40' 
                          : 'bg-slate-800 text-slate-400 border-slate-700'
                      }`}
                    >
                      محددات الـ AI: {showAiBoxes ? 'مفعلة' : 'مخفية'}
                    </button>
                    <button
                      onClick={() => setIsAudioMuted(!isAudioMuted)}
                      className="p-1.5 hover:bg-slate-800 rounded-lg text-slate-400 hover:text-white"
                    >
                      {isAudioMuted ? <VolumeX className="w-4 h-4" /> : <Volume2 className="w-4 h-4" />}
                    </button>
                  </div>
                </div>
              </div>
            </div>

            {/* Video Metadata Footer */}
            <div className="mt-4 p-3 bg-slate-900/90 rounded-2xl border border-slate-800 text-xs text-slate-400 flex items-center justify-between">
              <span className="flex items-center gap-1.5">
                <span className="w-2 h-2 rounded-full bg-emerald-500" />
                تخزين NVR السحابي: خادم الرياض المركزي (مؤمن بتشفير AES-256)
              </span>
              <button className="flex items-center gap-1 text-blue-400 hover:text-blue-300 font-bold transition-colors">
                <FileDown className="w-3.5 h-3.5" />
                تصدير مقطع الأدلة (MP4)
              </button>
            </div>
          </div>

          {/* Details & Action Decision Column (5 cols) */}
          <div className="lg:col-span-5 p-6 flex flex-col justify-between space-y-6">
            <div className="space-y-5">
              {/* Incident Details Card */}
              <div className="bg-slate-800/60 rounded-2xl p-4 border border-slate-700/60 space-y-3">
                <h4 className="text-xs font-bold text-slate-400 uppercase tracking-wider">تفاصيل التحليل البصري</h4>
                <p className="text-sm font-medium text-slate-200 leading-relaxed">
                  {incident.description}
                </p>

                {incident.potentialLossAmount && (
                  <div className="mt-3 p-3 bg-rose-500/10 border border-rose-500/20 rounded-xl flex items-center justify-between">
                    <span className="text-xs font-bold text-rose-300 flex items-center gap-1">
                      <DollarSign className="w-4 h-4" />
                      قيمة الصنف المهدد بالهدر/الفقد:
                    </span>
                    <span className="text-base font-extrabold text-rose-400 font-mono">
                      {incident.potentialLossAmount.toFixed(2)} ل.س
                    </span>
                  </div>
                )}
              </div>

              {/* Status and Previous Action */}
              <div className="bg-slate-800/40 rounded-2xl p-4 border border-slate-700/40 space-y-2">
                <div className="flex items-center justify-between">
                  <span className="text-xs text-slate-400">الحالة الحالية:</span>
                  <span className={`text-xs font-bold px-2.5 py-0.5 rounded-full ${
                    incident.status === 'active' 
                      ? 'bg-rose-500/20 text-rose-400 border border-rose-500/30' 
                      : incident.status === 'investigating'
                      ? 'bg-amber-500/20 text-amber-400 border border-amber-500/30'
                      : incident.status === 'resolved'
                      ? 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/30'
                      : 'bg-slate-700 text-slate-400'
                  }`}>
                    {incident.status === 'active' ? 'تنبيه نشط يتطلب تدخلاً' : 
                     incident.status === 'investigating' ? 'قيد التحقق الميداني' :
                     incident.status === 'resolved' ? 'تم التعامل بنجاح' : 'إنذار كاذب مستبعد'}
                  </span>
                </div>

                {incident.actionTaken && (
                  <div className="pt-2 border-t border-slate-700/40">
                    <span className="text-[11px] text-slate-400 block mb-0.5">الإجراء المتخذ مسبقاً:</span>
                    <p className="text-xs text-emerald-300 font-medium">{incident.actionTaken}</p>
                  </div>
                )}
              </div>
            </div>

            {/* Success notification banner */}
            {feedbackSuccess && (
              <div className="p-3 bg-emerald-600/20 border border-emerald-500/40 rounded-xl text-emerald-300 text-xs font-bold flex items-center gap-2 animate-in fade-in">
                <CheckCircle2 className="w-4 h-4" />
                {feedbackSuccess}
              </div>
            )}

            {/* Action Buttons */}
            <div className="space-y-2.5 pt-4 border-t border-slate-800">
              <span className="text-xs font-bold text-slate-400 block mb-1">اتخاذ قرار تشغيلي فوري:</span>

              {/* Action 1: Alert Guard / Discreet Chime */}
              <button
                onClick={() => handleAction('investigating', 'تم إرسال إشعار صامت لسماعة رجل أمن ممر 4 والمشرف')}
                className="w-full py-2.5 px-4 bg-rose-600 hover:bg-rose-700 text-white rounded-xl text-xs font-bold transition-all shadow-lg shadow-rose-900/30 flex items-center justify-center gap-2"
              >
                <Radio className="w-4 h-4 animate-pulse" />
                إشعار رجل الأمن الميداني سراً (Discreet Guard Chime)
              </button>

              {/* Action 2: Freeze POS screen or Flag Cashier */}
              {incident.type === 'pos_misscan' && (
                <button
                  onClick={() => handleAction('investigating', 'تم تجميد واجهة الكاشير وإرسال طلب مطابقة الصنف فوراً')}
                  className="w-full py-2.5 px-4 bg-amber-600 hover:bg-amber-700 text-white rounded-xl text-xs font-bold transition-all shadow-md flex items-center justify-center gap-2"
                >
                  <AlertTriangle className="w-4 h-4" />
                  تجميد شاشة الكاشير لمراجعة الصنف (POS Hold)
                </button>
              )}

              {/* Action 3: Resolve / Handled */}
              <button
                onClick={() => handleAction('resolved', 'تم التعامل مع الحالة وتأكيد دفع العميل أو إعادة الصنف')}
                className="w-full py-2 px-4 bg-emerald-600/30 hover:bg-emerald-600/40 text-emerald-300 border border-emerald-500/40 rounded-xl text-xs font-bold transition-all flex items-center justify-center gap-2"
              >
                <CheckCircle2 className="w-4 h-4" />
                تم التعامل وتسوية الحالة بنجاح
              </button>

              {/* Action 4: False Positive */}
              <button
                onClick={() => handleAction('false_alarm', 'تم تصنيف التنبيه كإنذار خاطئ وتدريب نموذج الذكاء')}
                className="w-full py-2 px-4 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-xl text-xs font-bold transition-all flex items-center justify-center gap-2"
              >
                <UserCheck className="w-4 h-4" />
                إنذار كاذب (سلوك طبيعي - تحديث نموذج التعلم)
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
