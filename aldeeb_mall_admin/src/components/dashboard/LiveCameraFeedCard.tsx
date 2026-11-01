import React, { useState, useEffect } from 'react';
import { 
  Camera, 
  Radio, 
  Maximize2, 
  AlertTriangle, 
  Eye, 
  EyeOff, 
  Flame, 
  Volume2, 
  VolumeX, 
  Sliders, 
  CameraOff, 
  Users, 
  ScanLine, 
  Check, 
  ZoomIn, 
  ZoomOut,
  RefreshCw
} from 'lucide-react';
import { StoreCamera } from '../../lib/storeVisionData';

interface LiveCameraFeedCardProps {
  camera: StoreCamera;
  onSelectCamera?: (cam: StoreCamera) => void;
  onOpenIncident?: (incidentId: string) => void;
}

export const LiveCameraFeedCard: React.FC<LiveCameraFeedCardProps> = ({
  camera,
  onSelectCamera,
}) => {
  const [showAiBoxes, setShowAiBoxes] = useState(true);
  const [viewMode, setViewMode] = useState<'rgb' | 'heatmap' | 'night'>('rgb');
  const [zoomLevel, setZoomLevel] = useState(1);
  const [snapshotTaken, setSnapshotTaken] = useState(false);
  const [liveSecond, setLiveSecond] = useState(new Date().toLocaleTimeString('ar-SA'));

  useEffect(() => {
    const timer = setInterval(() => {
      setLiveSecond(new Date().toLocaleTimeString('ar-SA'));
    }, 1000);
    return () => clearInterval(timer);
  }, []);

  const handleSnapshot = (e: React.MouseEvent) => {
    e.stopPropagation();
    setSnapshotTaken(true);
    setTimeout(() => setSnapshotTaken(false), 1500);
  };

  const handleZoom = (delta: number, e: React.MouseEvent) => {
    e.stopPropagation();
    setZoomLevel(prev => Math.min(2, Math.max(1, prev + delta)));
  };

  return (
    <div 
      className={`relative bg-slate-950 rounded-2xl border transition-all overflow-hidden flex flex-col group ${
        camera.status === 'alert'
          ? 'border-rose-500/80 shadow-lg shadow-rose-950/40 ring-1 ring-rose-500/50'
          : 'border-slate-800 hover:border-slate-700 shadow-md'
      }`}
      dir="rtl"
    >
      {/* Top Stream Header Bar */}
      <div className="px-3.5 py-2.5 bg-slate-900/90 border-b border-slate-800 flex items-center justify-between text-xs">
        <div className="flex items-center gap-2">
          <span className={`w-2 h-2 rounded-full ${
            camera.status === 'alert' 
              ? 'bg-rose-500 animate-ping' 
              : 'bg-emerald-500 animate-pulse'
          }`} />
          <span className="font-extrabold text-slate-100 truncate max-w-[160px] sm:max-w-[200px]">
            {camera.name}
          </span>
          <span className="text-[10px] font-mono px-1.5 py-0.5 rounded bg-slate-800 text-slate-400 border border-slate-700">
            {camera.id}
          </span>
        </div>

        <div className="flex items-center gap-2 text-[11px] text-slate-400">
          <span className="hidden sm:inline-block font-mono text-emerald-400">
            {camera.fps} FPS
          </span>
          <span className="bg-slate-800 text-slate-300 px-2 py-0.5 rounded text-[10px] font-bold">
            {camera.resolution}
          </span>
        </div>
      </div>

      {/* Main Video Viewport */}
      <div 
        className="relative aspect-video bg-gradient-to-br from-slate-950 via-slate-900 to-slate-950 overflow-hidden cursor-pointer select-none"
        onClick={() => onSelectCamera && onSelectCamera(camera)}
      >
        {/* Visual Background Simulation with dynamic tone */}
        <div 
          className={`w-full h-full transition-transform duration-300 relative ${
            viewMode === 'heatmap' ? 'filter hue-rotate-90 contrast-150 saturate-200' :
            viewMode === 'night' ? 'filter grayscale contrast-125 brightness-90 sepia-[.3]' : ''
          }`}
          style={{ transform: `scale(${zoomLevel})` }}
        >
          {/* Simulated Supermarket CCTV Background Scene */}
          <div className="absolute inset-0 bg-slate-900/60 backdrop-blur-[0.5px]">
            {/* Visual aisle and shelf perspective grid lines */}
            <div className="absolute inset-0 opacity-15 bg-[radial-gradient(#38bdf8_1px,transparent_1px)] [background-size:16px_16px]" />
            <div className="absolute top-1/4 inset-x-0 h-px bg-slate-700/50" />
            <div className="absolute top-2/3 inset-x-0 h-px bg-slate-700/50" />
            <div className="absolute inset-y-0 left-1/3 w-px bg-slate-700/40" />
            <div className="absolute inset-y-0 right-1/3 w-px bg-slate-700/40" />
          </div>

          {/* Simulated Moving Shoppers / Activity Silhouettes */}
          <div className="absolute inset-0 flex items-center justify-center p-4">
            <div className="text-center space-y-1">
              <span className="inline-block p-3 rounded-2xl bg-slate-800/80 border border-slate-700/60 text-blue-400 shadow-lg">
                <Camera className="w-8 h-8 opacity-80" />
              </span>
              <p className="text-xs font-bold text-slate-300">{camera.location}</p>
              <p className="text-[11px] text-slate-500 font-mono">Edge AI Inference: {camera.aiModel}</p>
            </div>
          </div>

          {/* AI Bounding Box Overlays */}
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
              {/* Corner brackets */}
              <div className="absolute -top-1 -right-1 w-2 h-2 border-t-2 border-r-2 border-white" />
              <div className="absolute -bottom-1 -left-1 w-2 h-2 border-b-2 border-l-2 border-white" />

              {/* Tag Label */}
              <div className={`absolute -top-5 right-0 text-[10px] font-bold px-1.5 py-0.5 rounded shadow whitespace-nowrap ${
                det.type === 'concealment' || det.type === 'unscanned_item'
                  ? 'bg-rose-600 text-white'
                  : det.type === 'queue_overflow'
                  ? 'bg-amber-600 text-white'
                  : 'bg-blue-600/90 text-white'
              }`}>
                {det.label}
              </div>
            </div>
          ))}

          {/* Heatmap overlay glow effect if selected */}
          {viewMode === 'heatmap' && (
            <div className="absolute inset-0 bg-gradient-radial from-red-500/40 via-yellow-400/20 to-transparent pointer-events-none mix-blend-screen" />
          )}
        </div>

        {/* Live HUD Floating Labels */}
        <div className="absolute top-2 right-2 flex items-center gap-1.5 pointer-events-none">
          <span className="flex items-center gap-1 bg-red-600/90 text-white text-[10px] font-bold px-2 py-0.5 rounded shadow">
            <Radio className="w-2.5 h-2.5" />
            مباشر (LIVE)
          </span>
          <span className="bg-black/70 text-slate-200 text-[10px] font-mono px-2 py-0.5 rounded backdrop-blur-sm">
            {liveSecond}
          </span>
        </div>

        {/* Real-time People In Frame Tag */}
        <div className="absolute top-2 left-2 bg-slate-900/80 backdrop-blur-sm text-slate-200 text-[10px] font-bold px-2 py-0.5 rounded border border-slate-700/60 flex items-center gap-1">
          <Users className="w-3 h-3 text-blue-400" />
          <span>{camera.peopleCount} أشخاص بالإطار</span>
        </div>

        {/* Snapshot Flash Overlay */}
        {snapshotTaken && (
          <div className="absolute inset-0 bg-white/90 z-20 flex items-center justify-center animate-out fade-out duration-500">
            <span className="text-slate-950 font-extrabold text-sm flex items-center gap-2">
              <Check className="w-5 h-5 text-emerald-600" />
              تم حفظ لقطة الشاشة في سجل الرقابة
            </span>
          </div>
        )}

        {/* Quick Toolbar on Hover (Bottom of viewport) */}
        <div className="absolute bottom-2 inset-x-2 bg-slate-950/85 backdrop-blur-md rounded-xl p-1.5 border border-slate-800 flex items-center justify-between opacity-90 group-hover:opacity-100 transition-opacity">
          {/* View Mode Controls */}
          <div className="flex items-center gap-1 text-[11px]">
            <button
              onClick={(e) => { e.stopPropagation(); setViewMode('rgb'); }}
              className={`px-2 py-1 rounded-lg font-bold transition-colors ${
                viewMode === 'rgb' ? 'bg-blue-600 text-white' : 'text-slate-400 hover:text-white'
              }`}
            >
              عادي
            </button>
            <button
              onClick={(e) => { e.stopPropagation(); setViewMode('heatmap'); }}
              className={`px-2 py-1 rounded-lg font-bold transition-colors flex items-center gap-1 ${
                viewMode === 'heatmap' ? 'bg-amber-600 text-white' : 'text-slate-400 hover:text-white'
              }`}
            >
              <Flame className="w-3 h-3" />
              حراري
            </button>
            <button
              onClick={(e) => { e.stopPropagation(); setViewMode('night'); }}
              className={`px-2 py-1 rounded-lg font-bold transition-colors ${
                viewMode === 'night' ? 'bg-emerald-600 text-white' : 'text-slate-400 hover:text-white'
              }`}
            >
              ليلي
            </button>
          </div>

          {/* AI Box & PTZ Controls */}
          <div className="flex items-center gap-1">
            <button
              onClick={(e) => { e.stopPropagation(); setShowAiBoxes(!showAiBoxes); }}
              className={`p-1.5 rounded-lg text-xs transition-colors ${
                showAiBoxes ? 'bg-blue-500/20 text-blue-300' : 'text-slate-500 hover:text-slate-300'
              }`}
              title="إظهار/إخفاء مربعات الذكاء الاصطناعي"
            >
              <ScanLine className="w-3.5 h-3.5" />
            </button>
            <button
              onClick={(e) => handleZoom(0.2, e)}
              className="p-1.5 text-slate-400 hover:text-white hover:bg-slate-800 rounded-lg transition-colors"
              title="تقريب عدسة الكاميرا PTZ Zoom In"
            >
              <ZoomIn className="w-3.5 h-3.5" />
            </button>
            <button
              onClick={(e) => handleZoom(-0.2, e)}
              className="p-1.5 text-slate-400 hover:text-white hover:bg-slate-800 rounded-lg transition-colors"
              title="تبعيد عدسة الكاميرا PTZ Zoom Out"
            >
              <ZoomOut className="w-3.5 h-3.5" />
            </button>
            <button
              onClick={handleSnapshot}
              className="p-1.5 text-slate-400 hover:text-emerald-400 hover:bg-slate-800 rounded-lg transition-colors"
              title="أخذ لقطة فورية Snapshot"
            >
              <Camera className="w-3.5 h-3.5" />
            </button>
            <button
              onClick={() => onSelectCamera && onSelectCamera(camera)}
              className="p-1.5 text-slate-400 hover:text-blue-400 hover:bg-slate-800 rounded-lg transition-colors"
              title="تكبير العرض والشاشة الكاملة"
            >
              <Maximize2 className="w-3.5 h-3.5" />
            </button>
          </div>
        </div>
      </div>

      {/* Card Bottom Status Bar */}
      <div className="p-3 bg-slate-900 border-t border-slate-800/80 flex items-center justify-between text-xs">
        <div className="flex items-center gap-1.5">
          <span className="text-slate-400 font-medium">المنطقة:</span>
          <span className="text-slate-200 font-bold">{camera.location}</span>
        </div>

        {camera.lastIncident ? (
          <span className="text-[11px] font-bold text-rose-400 flex items-center gap-1 bg-rose-500/10 px-2 py-0.5 rounded-full border border-rose-500/20">
            <AlertTriangle className="w-3 h-3" />
            {camera.lastIncident}
          </span>
        ) : (
          <span className="text-[11px] font-bold text-emerald-400 flex items-center gap-1">
            <span className="w-1.5 h-1.5 rounded-full bg-emerald-500" />
            حركة طبيعية ومستقرة
          </span>
        )}
      </div>
    </div>
  );
};
