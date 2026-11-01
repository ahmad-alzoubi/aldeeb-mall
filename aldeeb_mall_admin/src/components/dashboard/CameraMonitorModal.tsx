import React, { useState, useEffect } from 'react';
import { 
  X, 
  Camera, 
  Radio, 
  ScanLine, 
  Flame, 
  Volume2, 
  VolumeX, 
  ZoomIn, 
  ZoomOut, 
  RotateCcw, 
  Check, 
  Users, 
  ShieldAlert, 
  Sliders, 
  ChevronRight, 
  ChevronLeft,
  Maximize2
} from 'lucide-react';
import { StoreCamera } from '../../lib/storeVisionData';

interface CameraMonitorModalProps {
  camera: StoreCamera | null;
  allCameras: StoreCamera[];
  onClose: () => void;
  onSelectCamera: (cam: StoreCamera) => void;
  onOpenIncident?: (incidentId: string) => void;
}

export const CameraMonitorModal: React.FC<CameraMonitorModalProps> = ({
  camera,
  allCameras,
  onClose,
  onSelectCamera,
}) => {
  if (!camera) return null;

  const [showAiBoxes, setShowAiBoxes] = useState(true);
  const [viewMode, setViewMode] = useState<'rgb' | 'heatmap' | 'night'>('rgb');
  const [zoomLevel, setZoomLevel] = useState(1);
  const [isAudioMuted, setIsAudioMuted] = useState(true);
  const [snapshotTaken, setSnapshotTaken] = useState(false);
  const [liveTimestamp, setLiveTimestamp] = useState(new Date().toLocaleTimeString('ar-SA'));

  useEffect(() => {
    const timer = setInterval(() => {
      setLiveTimestamp(new Date().toLocaleTimeString('ar-SA'));
    }, 1000);
    return () => clearInterval(timer);
  }, []);

  const handleNext = () => {
    const idx = allCameras.findIndex(c => c.id === camera.id);
    const nextIdx = (idx + 1) % allCameras.length;
    onSelectCamera(allCameras[nextIdx]);
  };

  const handlePrev = () => {
    const idx = allCameras.findIndex(c => c.id === camera.id);
    const prevIdx = (idx - 1 + allCameras.length) % allCameras.length;
    onSelectCamera(allCameras[prevIdx]);
  };

  const handleSnapshot = () => {
    setSnapshotTaken(true);
    setTimeout(() => setSnapshotTaken(false), 1500);
  };

  return (
    <div className="fixed inset-0 z-50 bg-black/90 backdrop-blur-md flex items-center justify-center p-3 sm:p-6 select-none" dir="rtl">
      <div className="bg-slate-950 border border-slate-800 rounded-3xl w-full max-w-6xl overflow-hidden shadow-2xl flex flex-col max-h-[95vh] text-slate-100">
        {/* Top Header */}
        <div className="px-6 py-4 bg-slate-900/90 border-b border-slate-800 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <span className={`w-3 h-3 rounded-full ${
              camera.status === 'alert' ? 'bg-rose-500 animate-ping' : 'bg-emerald-500 animate-pulse'
            }`} />
            <div>
              <div className="flex items-center gap-2">
                <h3 className="font-extrabold text-base text-white">{camera.name}</h3>
                <span className="font-mono text-xs bg-slate-800 px-2 py-0.5 rounded text-blue-400 border border-slate-700">
                  {camera.id}
                </span>
                <span className="text-xs bg-emerald-500/20 text-emerald-400 border border-emerald-500/30 px-2 py-0.5 rounded-full font-bold">
                  {camera.resolution} • {camera.fps} FPS
                </span>
              </div>
              <p className="text-xs text-slate-400 mt-0.5">{camera.location}</p>
            </div>
          </div>

          <div className="flex items-center gap-2">
            <button
              onClick={handlePrev}
              className="p-2 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-300 transition-colors"
              title="الكاميرا السابقة"
            >
              <ChevronRight className="w-5 h-5" />
            </button>
            <button
              onClick={handleNext}
              className="p-2 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-300 transition-colors"
              title="الكاميرا التالية"
            >
              <ChevronLeft className="w-5 h-5" />
            </button>
            <button
              onClick={onClose}
              className="p-2 rounded-xl bg-slate-800 hover:bg-rose-600 text-slate-300 hover:text-white transition-colors mr-2"
            >
              <X className="w-5 h-5" />
            </button>
          </div>
        </div>

        {/* Video Canvas Area */}
        <div className="relative aspect-video bg-black flex-1 overflow-hidden group">
          <div 
            className={`w-full h-full transition-transform duration-300 relative ${
              viewMode === 'heatmap' ? 'filter hue-rotate-90 contrast-150 saturate-200' :
              viewMode === 'night' ? 'filter grayscale contrast-125 brightness-90 sepia-[.3]' : ''
            }`}
            style={{ transform: `scale(${zoomLevel})` }}
          >
            {/* Supermarket Interior Simulation */}
            <div className="absolute inset-0 bg-gradient-to-tr from-slate-950 via-slate-900 to-slate-950">
              <div className="absolute inset-0 opacity-20 bg-[radial-gradient(#38bdf8_1px,transparent_1px)] [background-size:24px_24px]" />
              <div className="absolute top-1/3 inset-x-0 h-px bg-slate-700/50" />
              <div className="absolute top-2/3 inset-x-0 h-px bg-slate-700/50" />
            </div>

            {/* Simulated Zone Visual */}
            <div className="absolute inset-0 flex flex-col items-center justify-center space-y-3 pointer-events-none">
              <div className="p-4 rounded-3xl bg-slate-900/90 border border-slate-700/60 text-blue-400 shadow-2xl">
                <Camera className="w-12 h-12" />
              </div>
              <h4 className="text-lg font-extrabold text-slate-200">{camera.name}</h4>
              <p className="text-xs text-slate-400 font-mono">محرك الاستدلال العصبي: {camera.aiModel}</p>
            </div>

            {/* AI Bounding Boxes */}
            {showAiBoxes && camera.detections.map((det, idx) => (
              <div
                key={idx}
                className={`absolute border-2 rounded transition-all duration-300 ${
                  det.type === 'concealment' || det.type === 'unscanned_item'
                    ? 'border-rose-500 bg-rose-500/20 animate-pulse'
                    : det.type === 'queue_overflow'
                    ? 'border-amber-500 bg-amber-500/20'
                    : 'border-blue-400 bg-blue-500/10'
                }`}
                style={{
                  top: `${det.box.y}%`,
                  right: `${det.box.x}%`,
                  width: `${det.box.w}%`,
                  height: `${det.box.h}%`,
                }}
              >
                <div className="absolute -top-1 -right-1 w-2.5 h-2.5 border-t-2 border-r-2 border-white" />
                <div className="absolute -bottom-1 -left-1 w-2.5 h-2.5 border-b-2 border-l-2 border-white" />

                <div className={`absolute -top-7 right-0 text-xs font-bold px-2 py-0.5 rounded shadow whitespace-nowrap ${
                  det.type === 'concealment' || det.type === 'unscanned_item'
                    ? 'bg-rose-600 text-white'
                    : det.type === 'queue_overflow'
                    ? 'bg-amber-600 text-white'
                    : 'bg-blue-600 text-white'
                }`}>
                  {det.label} ({det.confidence}%)
                </div>
              </div>
            ))}
          </div>

          {/* Top Live Banner */}
          <div className="absolute top-4 right-4 flex items-center gap-2 pointer-events-none">
            <span className="flex items-center gap-1.5 bg-red-600 text-white text-xs font-bold px-3 py-1 rounded-lg shadow-lg">
              <Radio className="w-3.5 h-3.5" />
              بث مباشر مشفر (RTSP OVER WEBRTC)
            </span>
            <span className="bg-black/80 text-white text-xs font-mono px-3 py-1 rounded-lg border border-slate-700">
              {liveTimestamp}
            </span>
          </div>

          <div className="absolute top-4 left-4 bg-slate-900/90 text-slate-200 text-xs font-bold px-3 py-1.5 rounded-lg border border-slate-700 flex items-center gap-2">
            <Users className="w-4 h-4 text-blue-400" />
            <span>{camera.peopleCount} متسوقين بالإطار المباشر</span>
          </div>

          {/* Flash Feedback */}
          {snapshotTaken && (
            <div className="absolute inset-0 bg-white/95 z-30 flex items-center justify-center animate-out fade-out duration-500">
              <span className="text-slate-950 font-extrabold text-base flex items-center gap-2">
                <Check className="w-6 h-6 text-emerald-600" />
                تم حفظ اللقطة الأمنية عالية الدقة 4K في سجل الرقابة
              </span>
            </div>
          )}

          {/* Bottom Floating Toolbar */}
          <div className="absolute bottom-4 inset-x-6 bg-slate-950/90 backdrop-blur-md rounded-2xl p-3 border border-slate-800 flex flex-wrap items-center justify-between gap-3">
            {/* Visual Filters */}
            <div className="flex items-center gap-2">
              <span className="text-xs text-slate-400 font-bold">وضع الرؤية:</span>
              <button
                onClick={() => setViewMode('rgb')}
                className={`px-3 py-1.5 rounded-xl text-xs font-bold transition-colors ${
                  viewMode === 'rgb' ? 'bg-blue-600 text-white' : 'bg-slate-900 text-slate-400 hover:text-white'
                }`}
              >
                الألوان الطبيعية
              </button>
              <button
                onClick={() => setViewMode('heatmap')}
                className={`px-3 py-1.5 rounded-xl text-xs font-bold transition-colors flex items-center gap-1 ${
                  viewMode === 'heatmap' ? 'bg-amber-600 text-white' : 'bg-slate-900 text-slate-400 hover:text-white'
                }`}
              >
                <Flame className="w-3.5 h-3.5" />
                خريطة التزاحم الحرارية
              </button>
              <button
                onClick={() => setViewMode('night')}
                className={`px-3 py-1.5 rounded-xl text-xs font-bold transition-colors ${
                  viewMode === 'night' ? 'bg-emerald-600 text-white' : 'bg-slate-900 text-slate-400 hover:text-white'
                }`}
              >
                الرؤية الليلية بالأشعة
              </button>
            </div>

            {/* AI and PTZ Controls */}
            <div className="flex items-center gap-2">
              <button
                onClick={() => setShowAiBoxes(!showAiBoxes)}
                className={`px-3 py-1.5 rounded-xl text-xs font-bold border transition-colors flex items-center gap-1.5 ${
                  showAiBoxes ? 'bg-blue-500/20 text-blue-300 border-blue-500/40' : 'bg-slate-900 text-slate-400 border-slate-700'
                }`}
              >
                <ScanLine className="w-4 h-4" />
                تحليل الذكاء البصري: {showAiBoxes ? 'نشط' : 'معطل'}
              </button>

              <div className="flex items-center gap-1 bg-slate-900 p-1 rounded-xl border border-slate-800">
                <button
                  onClick={() => setZoomLevel(prev => Math.min(2.5, prev + 0.25))}
                  className="p-1.5 text-slate-300 hover:text-white hover:bg-slate-800 rounded-lg"
                  title="تقريب PTZ Zoom In"
                >
                  <ZoomIn className="w-4 h-4" />
                </button>
                <span className="font-mono text-xs px-1 text-slate-400">{zoomLevel.toFixed(1)}x</span>
                <button
                  onClick={() => setZoomLevel(prev => Math.max(1, prev - 0.25))}
                  className="p-1.5 text-slate-300 hover:text-white hover:bg-slate-800 rounded-lg"
                  title="تبعيد PTZ Zoom Out"
                >
                  <ZoomOut className="w-4 h-4" />
                </button>
                <button
                  onClick={() => setZoomLevel(1)}
                  className="p-1.5 text-slate-400 hover:text-white hover:bg-slate-800 rounded-lg text-xs"
                  title="إعادة ضبط"
                >
                  <RotateCcw className="w-3.5 h-3.5" />
                </button>
              </div>

              <button
                onClick={handleSnapshot}
                className="px-3 py-1.5 bg-emerald-600 hover:bg-emerald-500 text-white rounded-xl text-xs font-bold transition-colors flex items-center gap-1.5 shadow"
              >
                <Camera className="w-4 h-4" />
                التقاط صورة 4K
              </button>

              <button
                onClick={() => setIsAudioMuted(!isAudioMuted)}
                className="p-2 bg-slate-900 hover:bg-slate-800 text-slate-300 rounded-xl"
              >
                {isAudioMuted ? <VolumeX className="w-4 h-4" /> : <Volume2 className="w-4 h-4" />}
              </button>
            </div>
          </div>
        </div>

        {/* Bottom Strip: Camera Switcher Thumbnails */}
        <div className="p-4 bg-slate-900 border-t border-slate-800 flex items-center gap-3 overflow-x-auto">
          <span className="text-xs font-bold text-slate-400 shrink-0">تبديل الكاميرا السريع:</span>
          {allCameras.map(c => (
            <button
              key={c.id}
              onClick={() => onSelectCamera(c)}
              className={`px-3 py-2 rounded-xl text-xs font-bold shrink-0 border transition-all flex items-center gap-2 ${
                c.id === camera.id
                  ? 'bg-blue-600 text-white border-blue-400 shadow-md'
                  : 'bg-slate-950 text-slate-400 border-slate-800 hover:text-white hover:bg-slate-800'
              }`}
            >
              <span className={`w-2 h-2 rounded-full ${c.status === 'alert' ? 'bg-rose-500 animate-ping' : 'bg-emerald-400'}`} />
              <span>{c.name}</span>
            </button>
          ))}
        </div>
      </div>
    </div>
  );
};
