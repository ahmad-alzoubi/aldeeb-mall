import React from 'react';
import { Bell, Volume2, VolumeX, RefreshCw, Menu } from 'lucide-react';

interface HeaderProps {
  title: string;
  subtitle?: string;
  soundEnabled: boolean;
  setSoundEnabled: (val: boolean) => void;
  onRefresh: () => void;
  onToggleMobileMenu?: () => void;
}

export const Header: React.FC<HeaderProps> = ({
  title,
  subtitle,
  soundEnabled,
  setSoundEnabled,
  onRefresh,
  onToggleMobileMenu,
}) => {
  return (
    <header className="h-20 bg-white border-b border-slate-200 px-4 md:px-8 flex items-center justify-between shadow-sm sticky top-0 z-30">
      <div className="flex items-center gap-3">
        {onToggleMobileMenu && (
          <button
            onClick={onToggleMobileMenu}
            className="lg:hidden p-2 rounded-xl text-slate-600 hover:bg-slate-100 border border-slate-200"
            title="القائمة"
          >
            <Menu className="w-5 h-5" />
          </button>
        )}
        <div>
          <h2 className="text-lg md:text-xl font-extrabold text-slate-800">{title}</h2>
          {subtitle && <p className="text-xs text-slate-500 font-medium hidden sm:block">{subtitle}</p>}
        </div>
      </div>

      <div className="flex items-center gap-4">
        {/* Audio Ping Toggle */}
        <button
          onClick={() => setSoundEnabled(!soundEnabled)}
          className={`flex items-center gap-2 px-3 py-1.5 rounded-xl border text-xs font-bold transition-all ${
            soundEnabled
              ? 'bg-blue-50 text-blue-700 border-blue-200 hover:bg-blue-100'
              : 'bg-slate-100 text-slate-500 border-slate-200 hover:bg-slate-200'
          }`}
          title="تنبيه صوتي عند وصول طلب جديد"
        >
          {soundEnabled ? <Volume2 className="w-4 h-4 text-blue-600" /> : <VolumeX className="w-4 h-4" />}
          <span>تنبيه الطلبات {soundEnabled ? 'مفعل' : 'صامت'}</span>
        </button>

        {/* Refresh Button */}
        <button
          onClick={onRefresh}
          className="p-2.5 rounded-xl text-slate-600 hover:text-blue-600 hover:bg-slate-100 border border-slate-200 transition-all"
          title="تحديث البيانات"
        >
          <RefreshCw className="w-4 h-4" />
        </button>

        {/* Notifications */}
        <div className="relative">
          <button className="p-2.5 rounded-xl text-slate-600 hover:text-blue-600 hover:bg-slate-100 border border-slate-200 transition-all">
            <Bell className="w-4 h-4" />
            <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-red-500 rounded-full animate-ping" />
          </button>
        </div>

        {/* Live Clock Badge */}
        <div className="bg-slate-100 px-3.5 py-1.5 rounded-xl text-xs font-bold text-slate-600 border border-slate-200">
          تحديث سحابي فوري ⚡ Supabase
        </div>
      </div>
    </header>
  );
};
