import React, { useRef, useState } from 'react';
import { Upload, Camera, Trash2, Star, Video, Image as ImageIcon, ArrowRight, ArrowLeft } from 'lucide-react';

interface MediaUploadManagerProps {
  mediaList: string[];
  onChange: (mediaList: string[]) => void;
  videoUrl?: string;
  onVideoChange?: (videoUrl: string) => void;
  maxFiles?: number;
  label?: string;
}

export const MediaUploadManager: React.FC<MediaUploadManagerProps> = ({
  mediaList,
  onChange,
  videoUrl = '',
  onVideoChange,
  maxFiles = 8,
  label = 'صور ووسائط المنتج',
}) => {
  const fileInputRef = useRef<HTMLInputElement>(null);
  const cameraInputRef = useRef<HTMLInputElement>(null);
  const videoInputRef = useRef<HTMLInputElement>(null);
  const [isProcessing, setIsProcessing] = useState(false);

  // Compress image before saving to state
  const compressImage = (file: File): Promise<string> => {
    return new Promise((resolve) => {
      const reader = new FileReader();
      reader.onload = (event) => {
        const img = new Image();
        img.onload = () => {
          const canvas = document.createElement('canvas');
          let width = img.width;
          let height = img.height;

          // Max dimension 1200px
          const maxDim = 1200;
          if (width > maxDim || height > maxDim) {
            if (width > height) {
              height = Math.round((height * maxDim) / width);
              width = maxDim;
            } else {
              width = Math.round((width * maxDim) / height);
              height = maxDim;
            }
          }

          canvas.width = width;
          canvas.height = height;
          const ctx = canvas.getContext('2d');
          if (ctx) {
            ctx.drawImage(img, 0, 0, width, height);
            resolve(canvas.toDataURL('image/jpeg', 0.85));
          } else {
            resolve(event.target?.result as string);
          }
        };
        img.src = event.target?.result as string;
      };
      reader.readAsDataURL(file);
    });
  };

  const handleFilesSelected = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = e.target.files;
    if (!files || files.length === 0) return;

    setIsProcessing(true);
    const newImages: string[] = [];

    for (let i = 0; i < files.length; i++) {
      if (mediaList.length + newImages.length >= maxFiles) break;
      const file = files[i];
      if (file.type.startsWith('image/')) {
        const compressed = await compressImage(file);
        newImages.push(compressed);
      }
    }

    onChange([...mediaList, ...newImages]);
    setIsProcessing(false);
    if (fileInputRef.current) fileInputRef.current.value = '';
    if (cameraInputRef.current) cameraInputRef.current.value = '';
  };

  const handleVideoSelected = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file || !onVideoChange) return;

    const reader = new FileReader();
    reader.onload = () => {
      if (reader.result) {
        onVideoChange(reader.result as string);
      }
    };
    reader.readAsDataURL(file);
    if (videoInputRef.current) videoInputRef.current.value = '';
  };

  const setPrimaryImage = (index: number) => {
    if (index === 0) return;
    const item = mediaList[index];
    const rest = mediaList.filter((_, i) => i !== index);
    onChange([item, ...rest]);
  };

  const removeMedia = (index: number) => {
    onChange(mediaList.filter((_, i) => i !== index));
  };

  const moveMedia = (fromIndex: number, toIndex: number) => {
    if (toIndex < 0 || toIndex >= mediaList.length) return;
    const updated = [...mediaList];
    const [moved] = updated.splice(fromIndex, 1);
    updated.splice(toIndex, 0, moved);
    onChange(updated);
  };

  return (
    <div className="space-y-3" dir="rtl">
      <div className="flex items-center justify-between">
        <label className="block text-xs font-black text-slate-800">
          {label} ({mediaList.length}/{maxFiles})
        </label>
        <span className="text-[10px] text-slate-400 font-medium">
          الصورة الأولى تعتبر تلقائياً هي الصورة الرئيسية للمنتج ⭐
        </span>
      </div>

      {/* Upload buttons row */}
      <div className="flex flex-wrap items-center gap-2">
        {/* Hidden inputs */}
        <input
          type="file"
          ref={fileInputRef}
          onChange={handleFilesSelected}
          accept="image/*"
          multiple
          className="hidden"
        />
        <input
          type="file"
          ref={cameraInputRef}
          onChange={handleFilesSelected}
          accept="image/*"
          capture="environment"
          className="hidden"
        />
        {onVideoChange && (
          <input
            type="file"
            ref={videoInputRef}
            onChange={handleVideoSelected}
            accept="video/*"
            className="hidden"
          />
        )}

        {/* Upload from device button */}
        <button
          type="button"
          onClick={() => fileInputRef.current?.click()}
          disabled={mediaList.length >= maxFiles || isProcessing}
          className="px-4 py-2 rounded-xl bg-blue-50 hover:bg-blue-100 text-blue-700 border border-blue-200 text-xs font-bold flex items-center gap-2 transition-all cursor-pointer disabled:opacity-50"
        >
          <Upload className="w-4 h-4" />
          <span>رفع صور من الجهاز</span>
        </button>

        {/* Camera capture button */}
        <button
          type="button"
          onClick={() => cameraInputRef.current?.click()}
          disabled={mediaList.length >= maxFiles || isProcessing}
          className="px-4 py-2 rounded-xl bg-emerald-50 hover:bg-emerald-100 text-emerald-700 border border-emerald-200 text-xs font-bold flex items-center gap-2 transition-all cursor-pointer disabled:opacity-50"
        >
          <Camera className="w-4 h-4" />
          <span>التقاط بالكاميرا 📷</span>
        </button>

        {/* Optional video upload */}
        {onVideoChange && (
          <button
            type="button"
            onClick={() => videoInputRef.current?.click()}
            className="px-4 py-2 rounded-xl bg-purple-50 hover:bg-purple-100 text-purple-700 border border-purple-200 text-xs font-bold flex items-center gap-2 transition-all cursor-pointer"
          >
            <Video className="w-4 h-4" />
            <span>{videoUrl ? 'استبدال فيديو المنتج' : 'إضافة فيديو للمنتج 🎬'}</span>
          </button>
        )}
      </div>

      {/* Media Thumbnails Grid */}
      {mediaList.length === 0 ? (
        <div 
          onClick={() => fileInputRef.current?.click()}
          className="py-8 px-4 rounded-2xl border-2 border-dashed border-slate-300 hover:border-blue-400 bg-slate-50/60 hover:bg-blue-50/30 flex flex-col items-center justify-center gap-2 text-center cursor-pointer transition-all"
        >
          <div className="w-12 h-12 rounded-2xl bg-blue-100 text-blue-600 flex items-center justify-center">
            <ImageIcon className="w-6 h-6" />
          </div>
          <div>
            <p className="text-xs font-black text-slate-700">اضغط لرفع صور المنتج من جهازك أو التقاطها فوراً</p>
            <p className="text-[11px] text-slate-400 mt-0.5">يدعم JPG, PNG, WEBP مع ضغط تلقائي ذكي</p>
          </div>
        </div>
      ) : (
        <div className="grid grid-cols-2 sm:grid-cols-4 md:grid-cols-6 gap-3">
          {mediaList.map((img, idx) => (
            <div 
              key={idx} 
              className={`relative rounded-2xl overflow-hidden border-2 group bg-slate-100 aspect-square shadow-xs transition-all ${
                idx === 0 ? 'border-amber-400 ring-2 ring-amber-400/30' : 'border-slate-200'
              }`}
            >
              <img 
                src={img} 
                alt={`Media ${idx + 1}`} 
                className="w-full h-full object-cover" 
              />

              {/* Primary Image Badge */}
              {idx === 0 && (
                <div className="absolute top-1.5 right-1.5 bg-amber-500 text-slate-900 text-[9px] font-black px-1.5 py-0.5 rounded-md flex items-center gap-0.5 shadow-md">
                  <Star className="w-2.5 h-2.5 fill-slate-900" />
                  <span>الرئيسية</span>
                </div>
              )}

              {/* Overlay controls on hover */}
              <div className="absolute inset-0 bg-slate-950/70 opacity-0 group-hover:opacity-100 flex flex-col items-center justify-between p-2 transition-opacity">
                <div className="flex items-center justify-between w-full">
                  {idx !== 0 && (
                    <button
                      type="button"
                      onClick={() => setPrimaryImage(idx)}
                      className="p-1 rounded-md bg-amber-500 hover:bg-amber-600 text-slate-900 text-[10px] font-bold"
                      title="تعيين كصورة رئيسية"
                    >
                      <Star className="w-3 h-3 fill-slate-900" />
                    </button>
                  )}
                  <button
                    type="button"
                    onClick={() => removeMedia(idx)}
                    className="p-1 rounded-md bg-rose-600 hover:bg-rose-700 text-white mr-auto"
                    title="حذف الصورة"
                  >
                    <Trash2 className="w-3 h-3" />
                  </button>
                </div>

                {/* Re-order arrows */}
                <div className="flex items-center gap-1">
                  {idx > 0 && (
                    <button
                      type="button"
                      onClick={() => moveMedia(idx, idx - 1)}
                      className="p-1 rounded-md bg-white/20 hover:bg-white/40 text-white"
                      title="تحريك لليمين"
                    >
                      <ArrowRight className="w-3 h-3" />
                    </button>
                  )}
                  {idx < mediaList.length - 1 && (
                    <button
                      type="button"
                      onClick={() => moveMedia(idx, idx + 1)}
                      className="p-1 rounded-md bg-white/20 hover:bg-white/40 text-white"
                      title="تحريك لليسار"
                    >
                      <ArrowLeft className="w-3 h-3" />
                    </button>
                  )}
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Video Preview If Present */}
      {videoUrl && onVideoChange && (
        <div className="p-3 bg-purple-50 rounded-2xl border border-purple-200 flex items-center justify-between text-xs">
          <div className="flex items-center gap-2">
            <Video className="w-4 h-4 text-purple-600" />
            <span className="font-bold text-purple-900">تم إرفاق فيديو توضيحي للمنتج ✓</span>
          </div>
          <button
            type="button"
            onClick={() => onVideoChange('')}
            className="text-[11px] text-rose-600 font-bold hover:underline"
          >
            إزالة الفيديو
          </button>
        </div>
      )}
    </div>
  );
};
