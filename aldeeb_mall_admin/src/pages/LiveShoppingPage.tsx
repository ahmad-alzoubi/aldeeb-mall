import React, { useState } from 'react';
import { 
  Radio, 
  Video, 
  Users, 
  ShoppingBag, 
  Sparkles, 
  Send, 
  Tag, 
  Eye, 
  TrendingUp, 
  DollarSign, 
  MessageSquare, 
  CheckCircle2, 
  Play, 
  Square, 
  ArrowUpRight, 
  Plus, 
  Trash2,
  Share2,
  Heart
} from 'lucide-react';

interface LiveSession {
  id: string;
  title: string;
  hostName: string;
  hostRole: string;
  status: 'ON_AIR' | 'UPCOMING' | 'ENDED';
  viewers: number;
  peakViewers: number;
  salesGMV: number;
  ordersCount: number;
  likes: number;
  startedAt: string;
  activeProductId: string;
  promoCode: string;
  streamUrl: string;
}

interface StreamProduct {
  id: string;
  name: string;
  category: string;
  originalPrice: number;
  livePrice: number;
  stock: number;
  salesInStream: number;
  imageUrl: string;
}

const initialSession: LiveSession = {
  id: 'LIVE-2026-1031',
  title: 'مطبخ الديب الحي: سر كبسة النعيمي الفاخرة مع خلطة بهارات الديب 👩‍🍳',
  hostName: 'الشيف نورة',
  hostRole: 'شيف معتمد وخبير تذوق',
  status: 'ON_AIR',
  viewers: 1842,
  peakViewers: 2490,
  salesGMV: 68450,
  ordersCount: 312,
  likes: 14200,
  startedAt: 'منذ 34 دقيقة',
  activeProductId: 'LP-001',
  promoCode: 'LIVE30',
  streamUrl: 'rtmp://live.aldeebmall.sa/studio/chef-noura-feed',
};

const initialProducts: StreamProduct[] = [
  {
    id: 'LP-001',
    name: 'كتف خروف نعيمي طازج مقطع كبسة (1.5 كجم)',
    category: 'لحوم طازجة',
    originalPrice: 135.0,
    livePrice: 89.0,
    stock: 18,
    salesInStream: 142,
    imageUrl: 'https://images.unsplash.com/photo-1607623814075-e51df1bdc82f?w=400&q=80',
  },
  {
    id: 'LP-002',
    name: 'أرز بسمتي الشعلان عنبر كلاسيك فاخر (5 كجم)',
    category: 'تموين وبقالة',
    originalPrice: 52.0,
    livePrice: 36.5,
    stock: 45,
    salesInStream: 88,
    imageUrl: 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=400&q=80',
  },
  {
    id: 'LP-003',
    name: 'بهارات الكبسة النجدية الأصلية المطحونة (250غ)',
    category: 'بهارات وتوابل',
    originalPrice: 22.0,
    livePrice: 14.0,
    stock: 30,
    salesInStream: 64,
    imageUrl: 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=400&q=80',
  },
  {
    id: 'LP-004',
    name: 'سمن بقر بري القصيم نقي فاخر (800غ)',
    category: 'زيوت وسمن',
    originalPrice: 65.0,
    livePrice: 42.0,
    stock: 22,
    salesInStream: 51,
    imageUrl: 'https://images.unsplash.com/photo-1628088062854-d1870b4553da?w=400&q=80',
  },
];

export const LiveShoppingPage: React.FC = () => {
  const [session, setSession] = useState<LiveSession>(initialSession);
  const [products, setProducts] = useState<StreamProduct[]>(initialProducts);
  const [broadcastMessage, setBroadcastMessage] = useState('');
  const [pinnedCoupon, setPinnedCoupon] = useState('LIVE30');
  const [activeTab, setActiveTab] = useState<'control' | 'products' | 'analytics'>('control');

  // Push Product to viewers in real time
  const handlePushProductToStream = (productId: string) => {
    setSession({
      ...session,
      activeProductId: productId,
    });
    alert('تم تثبيت وعرض المنتج على شاشات جميع المشاهدين في تطبيق الديب مول مباشرة!');
  };

  // Broadcast Moderator Announcement
  const handleSendBroadcast = (e: React.FormEvent) => {
    e.preventDefault();
    if (!broadcastMessage.trim()) return;
    alert(`تم بث الرسالة لجميع المشاهدين: "${broadcastMessage}"`);
    setBroadcastMessage('');
  };

  // Toggle Stream Status
  const handleToggleStream = () => {
    const nextStatus = session.status === 'ON_AIR' ? 'ENDED' : 'ON_AIR';
    setSession({
      ...session,
      status: nextStatus,
    });
  };

  return (
    <div className="space-y-6">
      {/* Top Header */}
      <div className="bg-gradient-to-r from-slate-900 via-rose-950 to-slate-900 border border-rose-900/50 rounded-2xl p-6 text-white shadow-xl flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <div>
          <div className="flex items-center gap-3">
            <div className="p-3 bg-rose-600/30 border border-rose-500/40 rounded-xl text-rose-400">
              <Radio className="w-7 h-7" />
            </div>
            <div>
              <h1 className="text-2xl font-bold flex items-center gap-2">
                استوديو الديب لايف والتسوق الحي (Live Video Shopping Studio)
                <span className="text-xs bg-rose-500/20 text-rose-300 border border-rose-500/30 px-2.5 py-0.5 rounded-full font-mono flex items-center gap-1">
                  <span className="w-2 h-2 rounded-full bg-rose-500 animate-pulse"></span>
                  RTMP 1080p60 Live
                </span>
              </h1>
              <p className="text-sm text-slate-400 mt-1">
                إدارة البث التفاعلي، تبديل المنتجات المعروضة على الهواء، إطلاق كوبونات الفلاش والتحكم بالمبيعات اللحظية
              </p>
            </div>
          </div>
        </div>

        <div className="flex items-center gap-3 w-full md:w-auto">
          <button
            onClick={handleToggleStream}
            className={`flex-1 md:flex-none flex items-center justify-center gap-2 font-bold px-4 py-2.5 rounded-xl transition shadow-lg text-sm ${
              session.status === 'ON_AIR'
                ? 'bg-rose-600 hover:bg-rose-700 text-white shadow-rose-600/30'
                : 'bg-emerald-600 hover:bg-emerald-700 text-white shadow-emerald-600/30'
            }`}
          >
            {session.status === 'ON_AIR' ? (
              <>
                <Square className="w-4 h-4 fill-white" />
                إنهاء البث المباشر
              </>
            ) : (
              <>
                <Play className="w-4 h-4 fill-white" />
                بدء البث على الهواء
              </>
            )}
          </button>
        </div>
      </div>

      {/* Real-time KPI Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs flex items-center justify-between">
          <div>
            <p className="text-xs font-medium text-slate-700">المشاهدون المتصلون الآن</p>
            <h3 className="text-2xl font-extrabold text-rose-600 mt-1 flex items-center gap-2">
              <span className="w-2.5 h-2.5 rounded-full bg-rose-600 animate-ping"></span>
              {session.viewers.toLocaleString()} مشاهد
            </h3>
            <p className="text-xs text-slate-700 font-medium mt-1">
              أعلى ذروة: {session.peakViewers.toLocaleString()}
            </p>
          </div>
          <div className="p-3 bg-rose-50 text-rose-600 rounded-xl">
            <Users className="w-6 h-6" />
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs flex items-center justify-between">
          <div>
            <p className="text-xs font-medium text-slate-700">مبيعات البث اللحظية (Live GMV)</p>
            <h3 className="text-2xl font-extrabold text-slate-900 mt-1">{session.salesGMV.toLocaleString()} ل.س</h3>
            <p className="text-xs text-emerald-600 font-medium mt-1 flex items-center gap-1">
              <TrendingUp className="w-3.5 h-3.5" />
              {session.ordersCount} طلب مكتمل خلال البث
            </p>
          </div>
          <div className="p-3 bg-emerald-50 text-emerald-600 rounded-xl">
            <DollarSign className="w-6 h-6" />
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs flex items-center justify-between">
          <div>
            <p className="text-xs font-medium text-slate-700">معدل التحويل للسلة (Live CVR)</p>
            <h3 className="text-2xl font-extrabold text-indigo-600 mt-1">16.9%</h3>
            <p className="text-xs text-slate-700 font-medium mt-1">
              أعلى بـ 4.2x من التصفح العادي
            </p>
          </div>
          <div className="p-3 bg-indigo-50 text-indigo-600 rounded-xl">
            <ArrowUpRight className="w-6 h-6" />
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs flex items-center justify-between">
          <div>
            <p className="text-xs font-medium text-slate-700">التفاعلات والإعجابات (Likes)</p>
            <h3 className="text-2xl font-extrabold text-pink-600 mt-1">{session.likes.toLocaleString()} ❤️</h3>
            <p className="text-xs text-pink-700 font-medium mt-1">
              تفاعل جماهيري استثنائي
            </p>
          </div>
          <div className="p-3 bg-pink-50 text-pink-600 rounded-xl">
            <Heart className="w-6 h-6" />
          </div>
        </div>
      </div>

      {/* Main Studio Console Layout */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left 2 Cols: Live Feed Monitor & Product Switcher */}
        <div className="lg:col-span-2 space-y-6">
          {/* Live Host Video Simulation Monitor */}
          <div className="bg-slate-900 rounded-2xl border border-slate-800 overflow-hidden shadow-xl text-white relative">
            <div className="p-4 bg-slate-950/80 border-b border-slate-800 flex items-center justify-between">
              <div className="flex items-center gap-3">
                <span className="w-3 h-3 rounded-full bg-red-500 animate-pulse"></span>
                <span className="font-bold text-sm">شاشة المراقبة المباشرة (On-Air Program Feed)</span>
              </div>
              <div className="text-xs text-slate-400 font-mono">
                {session.startedAt} | كود: {session.promoCode}
              </div>
            </div>

            <div className="relative aspect-video bg-black flex items-center justify-center overflow-hidden">
              <img
                src="https://images.unsplash.com/photo-1556910103-1c02745aae4d?w=1000&q=80"
                alt="Live Host Stream"
                className="w-full h-full object-cover opacity-80"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-transparent to-black/40"></div>

              {/* Host Overlay Tag */}
              <div className="absolute top-4 right-4 flex items-center gap-2 bg-black/60 backdrop-blur-md px-3 py-1.5 rounded-full border border-white/20">
                <img
                  src="https://images.unsplash.com/photo-1577219491135-ce391730fb2c?w=120&q=80"
                  alt="Chef"
                  className="w-7 h-7 rounded-full object-cover"
                />
                <div className="text-right">
                  <div className="text-xs font-bold text-white">{session.hostName}</div>
                  <div className="text-[10px] text-slate-300">{session.hostRole}</div>
                </div>
              </div>

              {/* Pinned On-Air Product Overlay */}
              {(() => {
                const activeProd = products.find(p => p.id === session.activeProductId);
                if (!activeProd) return null;
                return (
                  <div className="absolute bottom-4 left-4 right-4 bg-white/95 backdrop-blur-md text-slate-900 p-3 rounded-xl shadow-2xl flex items-center justify-between border border-white">
                    <div className="flex items-center gap-3">
                      <span className="bg-red-600 text-white text-[10px] font-bold px-2 py-0.5 rounded">
                        يُعرض الآن
                      </span>
                      <img src={activeProd.imageUrl} alt="" className="w-12 h-12 rounded-lg object-cover" />
                      <div>
                        <h4 className="font-bold text-sm">{activeProd.name}</h4>
                        <div className="flex items-center gap-2 text-xs">
                          <span className="font-extrabold text-emerald-600 text-base">{activeProd.livePrice.toFixed(2)} ل.س</span>
                          <span className="text-slate-400 line-through">{activeProd.originalPrice.toFixed(2)} ل.س</span>
                          <span className="text-slate-500 font-medium">({activeProd.salesInStream} تم شراؤها)</span>
                        </div>
                      </div>
                    </div>
                    <span className="text-xs bg-emerald-100 text-emerald-800 font-bold px-3 py-1.5 rounded-lg">
                      معروض على 1,842 شاشة
                    </span>
                  </div>
                );
              })()}
            </div>
          </div>

          {/* Real-time Product Switcher */}
          <div className="bg-white rounded-2xl border border-slate-200 p-5 space-y-4 shadow-xs">
            <div className="flex items-center justify-between">
              <div>
                <h3 className="text-base font-bold text-slate-900 flex items-center gap-2">
                  <ShoppingBag className="w-5 h-5 text-indigo-600" />
                  مبدّل المنتجات المباشر على الهواء (On-Air Product Switcher)
                </h3>
                <p className="text-xs text-slate-500 mt-0.5">
                  انقر على أي منتج لتثبيته فورياً أسفل شاشة جميع المشاهدين مع زر الشراء السريع
                </p>
              </div>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              {products.map((p) => {
                const isCurrentActive = p.id === session.activeProductId;
                return (
                  <div
                    key={p.id}
                    className={`p-3.5 rounded-xl border transition flex items-center justify-between ${
                      isCurrentActive
                        ? 'border-red-500 bg-red-50/30 ring-2 ring-red-500/20'
                        : 'border-slate-200 hover:border-slate-300 bg-white'
                    }`}
                  >
                    <div className="flex items-center gap-3">
                      <img src={p.imageUrl} alt="" className="w-14 h-14 rounded-lg object-cover" />
                      <div>
                        <div className="font-bold text-xs text-slate-900 max-w-[170px] truncate">{p.name}</div>
                        <div className="text-[11px] text-slate-400 mt-0.5">{p.category}</div>
                        <div className="flex items-center gap-2 mt-1">
                          <span className="font-bold text-emerald-600 text-xs">{p.livePrice} ل.س</span>
                          <span className="text-[10px] text-slate-400 line-through">{p.originalPrice} ل.س</span>
                        </div>
                      </div>
                    </div>

                    <button
                      onClick={() => handlePushProductToStream(p.id)}
                      className={`text-xs font-bold px-3 py-1.5 rounded-lg transition ${
                        isCurrentActive
                          ? 'bg-red-600 text-white shadow-xs'
                          : 'bg-slate-100 hover:bg-slate-200 text-slate-700'
                      }`}
                    >
                      {isCurrentActive ? 'يُعرض الآن' : 'عرض على الهواء'}
                    </button>
                  </div>
                );
              })}
            </div>
          </div>
        </div>

        {/* Right 1 Col: Moderator Controls & Flash Drops */}
        <div className="space-y-6">
          {/* Flash Promo Drops & Broadcast Ticker */}
          <div className="bg-white rounded-2xl border border-slate-200 p-5 space-y-4 shadow-xs">
            <h3 className="text-base font-bold text-slate-900 flex items-center gap-2">
              <Sparkles className="w-5 h-5 text-rose-600" />
              إسقاط كوبونات الفلاش الحية (Flash Drop)
            </h3>
            <p className="text-xs text-slate-500">
              تفعيل كود خصم لحظي يظهر للمشاهدين مع عداد تنازلي لدفع الشراء الفوري
            </p>

            <div className="p-3 bg-rose-50 border border-rose-200 rounded-xl space-y-2">
              <div className="flex justify-between items-center">
                <span className="text-xs text-rose-800 font-bold">الكوبون النشط للبث:</span>
                <span className="font-mono font-bold text-sm bg-rose-200 text-rose-900 px-2 py-0.5 rounded">
                  {pinnedCoupon}
                </span>
              </div>
              <div className="text-[11px] text-rose-700">خصم 30% فوري على سلة البث</div>
            </div>

            <div className="flex gap-2">
              <input
                type="text"
                placeholder="كود جديد مثل LIVE40..."
                className="flex-1 px-3 py-2 bg-slate-50 border border-slate-200 rounded-lg text-xs font-mono uppercase"
                id="newLiveCouponInput"
              />
              <button
                onClick={() => {
                  const input = document.getElementById('newLiveCouponInput') as HTMLInputElement;
                  if (input && input.value) {
                    setPinnedCoupon(input.value.toUpperCase());
                    alert(`تم تنشيط كود الفلاش الجديد ${input.value.toUpperCase()} على جميع المشاهدين!`);
                    input.value = '';
                  }
                }}
                className="bg-slate-900 hover:bg-slate-800 text-white text-xs font-bold px-3 py-2 rounded-lg"
              >
                تحديث الكود
              </button>
            </div>
          </div>

          {/* Producer Broadcast Messages */}
          <div className="bg-white rounded-2xl border border-slate-200 p-5 space-y-4 shadow-xs">
            <h3 className="text-base font-bold text-slate-900 flex items-center gap-2">
              <MessageSquare className="w-5 h-5 text-indigo-600" />
              إعلان المخرج للمشاهدين (Producer Broadcast)
            </h3>
            <p className="text-xs text-slate-500">
              رسالة تظهر بلون مميز في شات البث كرسالة رسمية من إدارة المول
            </p>

            <form onSubmit={handleSendBroadcast} className="space-y-3">
              <textarea
                rows={3}
                value={broadcastMessage}
                onChange={(e) => setBroadcastMessage(e.target.value)}
                placeholder="اكتب إعلاناً للمشاهدين (مثال: باقي 5 حبات فقط من لحم النعيمي!)..."
                className="w-full px-3 py-2 border border-slate-200 rounded-lg text-xs"
              />
              <button
                type="submit"
                className="w-full bg-indigo-600 hover:bg-indigo-700 text-white font-bold py-2 rounded-lg text-xs flex items-center justify-center gap-1.5 shadow-xs"
              >
                <Send className="w-3.5 h-3.5" />
                بث الرسالة في الشات المباشر
              </button>
            </form>
          </div>

          {/* Session Overview */}
          <div className="bg-white rounded-2xl border border-slate-200 p-5 space-y-3 shadow-xs">
            <h3 className="text-base font-bold text-slate-900">بيانات جلسة البث</h3>
            <div className="text-xs space-y-2 text-slate-600">
              <div className="flex justify-between">
                <span>عنوان البث:</span>
                <span className="font-bold text-slate-900">{session.title.slice(0, 30)}...</span>
              </div>
              <div className="flex justify-between">
                <span>مقدمة البرنامج:</span>
                <span className="font-bold text-slate-900">{session.hostName}</span>
              </div>
              <div className="flex justify-between">
                <span>جودة البث:</span>
                <span className="font-mono text-emerald-600 font-bold">1080p @ 60fps</span>
              </div>
              <div className="flex justify-between">
                <span>زمن البث:</span>
                <span className="font-bold text-slate-900">{session.startedAt}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
