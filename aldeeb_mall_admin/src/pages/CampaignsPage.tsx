import React, { useState } from 'react';
import { 
  Bell, 
  Send, 
  Plus, 
  Users, 
  TrendingUp, 
  Clock, 
  CheckCircle2, 
  Smartphone,
  Sparkles,
  Target
} from 'lucide-react';
import { MarketingCampaign } from '../types';

interface CampaignsPageProps {
  campaigns: MarketingCampaign[];
  onAddCampaign?: (camp: MarketingCampaign) => void;
}

export const CampaignsPage: React.FC<CampaignsPageProps> = ({
  campaigns: initialCampaigns,
  onAddCampaign,
}) => {
  const [campaigns, setCampaigns] = useState<MarketingCampaign[]>(initialCampaigns);
  const [showModal, setShowModal] = useState<boolean>(false);
  const [title, setTitle] = useState<string>('');
  const [body, setBody] = useState<string>('');
  const [targetAudience, setTargetAudience] = useState<MarketingCampaign['target_audience']>('all');

  const handleCreateCampaign = (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim() || !body.trim()) return;

    const newCamp: MarketingCampaign = {
      id: `cmp-${Date.now()}`,
      title_ar: title,
      body_ar: body,
      target_audience: targetAudience,
      scheduled_at: 'الآن (إرسال فوري)',
      status: 'sent',
      open_rate: 45.0,
      conversion_rate: 19.2,
      sent_count: targetAudience === 'all' ? 15000 : 3500,
    };

    setCampaigns((prev) => [newCamp, ...prev]);
    if (onAddCampaign) onAddCampaign(newCamp);

    setTitle('');
    setBody('');
    setShowModal(false);
  };

  const totalSent = campaigns.reduce((sum, c) => sum + c.sent_count, 0);

  return (
    <div className="space-y-6">
      {/* Top Metrics Grid */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="bg-gradient-to-r from-blue-600 to-indigo-600 text-white p-5 rounded-2xl shadow-sm flex items-center justify-between">
          <div>
            <div className="text-xs font-bold text-blue-100 mb-1">إجمالي الإشعارات المرسلة</div>
            <div className="text-3xl font-black">{totalSent.toLocaleString()} إشعار</div>
            <p className="text-xs text-blue-100 mt-1">✓ عبر منصة Firebase Cloud Messaging (FCM)</p>
          </div>
          <Bell className="w-10 h-10 text-blue-200 fill-blue-200 opacity-80" />
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm flex items-center justify-between">
          <div>
            <div className="text-xs font-bold text-slate-500 mb-1">متوسط نسبة فتح الإشعارات (CTR)</div>
            <div className="text-3xl font-black text-emerald-600">46.8%</div>
            <p className="text-xs text-slate-400 mt-1">معدل نقر وتحويل ممتاز</p>
          </div>
          <TrendingUp className="w-10 h-10 text-emerald-500" />
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm flex flex-col justify-center">
          <button
            onClick={() => setShowModal(true)}
            className="w-full py-3 bg-blue-600 hover:bg-blue-700 text-white font-bold rounded-xl transition-colors flex items-center justify-center gap-2 shadow-sm text-sm"
          >
            <Plus className="w-5 h-5" />
            إطلاق إشعار تسويقي فوري (Push Campaign)
          </button>
        </div>
      </div>

      {/* Campaigns Stream */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
        {campaigns.map((camp) => (
          <div
            key={camp.id}
            className="bg-white rounded-2xl border border-slate-200 shadow-sm p-5 hover:shadow-md transition-all flex flex-col justify-between"
          >
            <div>
              <div className="flex items-start justify-between mb-3">
                <span className="text-xs font-mono font-bold bg-slate-100 text-slate-600 px-2 py-0.5 rounded">
                  {camp.scheduled_at}
                </span>
                <span
                  className={`text-xs font-bold px-2.5 py-0.5 rounded-full ${
                    camp.status === 'sent'
                      ? 'bg-emerald-100 text-emerald-800'
                      : 'bg-blue-100 text-blue-800'
                  }`}
                >
                  {camp.status === 'sent' ? '✓ تم الإرسال' : 'مجدول'}
                </span>
              </div>

              {/* Mobile Push Notification Mock Preview */}
              <div className="bg-slate-50 p-3.5 rounded-xl border border-slate-200 mb-4">
                <div className="flex items-center gap-2 mb-1.5">
                  <div className="w-5 h-5 rounded-full bg-blue-600 flex items-center justify-center">
                    <Smartphone className="w-3 h-3 text-white" />
                  </div>
                  <span className="text-[11px] font-bold text-slate-500">الديب مول • الآن</span>
                </div>
                <h4 className="font-bold text-slate-900 text-xs mb-1">{camp.title_ar}</h4>
                <p className="text-xs text-slate-600 leading-relaxed">{camp.body_ar}</p>
              </div>

              {/* Target Segment Pill */}
              <div className="flex items-center gap-2 text-xs text-slate-500 mb-4">
                <Target className="w-4 h-4 text-blue-600" />
                <span>الجمهور المستهدف: </span>
                <span className="font-bold text-slate-800">
                  {camp.target_audience === 'all' && 'كافة العملاء المسجلين'}
                  {camp.target_audience === 'vip_gold_platinum' && 'أعضاء النادي الذهبي والبلاتيني فقط'}
                  {camp.target_audience === 'cart_abandoners' && 'العملاء أصحاب السلال المعلقة'}
                  {camp.target_audience === 'new_customers' && 'المسجلون الجدد (أول طلب)'}
                </span>
              </div>
            </div>

            {/* Campaign Stats Footer */}
            <div className="grid grid-cols-3 gap-2 pt-3 border-t border-slate-100 text-center text-xs">
              <div className="bg-slate-50 p-2 rounded-lg">
                <div className="font-black text-slate-800 text-sm">{camp.sent_count.toLocaleString()}</div>
                <div className="text-[10px] text-slate-400">المستلمون</div>
              </div>
              <div className="bg-slate-50 p-2 rounded-lg">
                <div className="font-black text-emerald-600 text-sm">%{camp.open_rate}</div>
                <div className="text-[10px] text-slate-400">نسبة الفتح</div>
              </div>
              <div className="bg-slate-50 p-2 rounded-lg">
                <div className="font-black text-blue-600 text-sm">%{camp.conversion_rate}</div>
                <div className="text-[10px] text-slate-400">نسبة الشراء</div>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* New Campaign Modal */}
      {showModal && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl max-w-lg w-full p-6 shadow-2xl border border-slate-200">
            <h3 className="text-lg font-bold text-slate-900 mb-4 flex items-center gap-2">
              <Bell className="w-5 h-5 text-blue-600" />
              إنشاء إشعار فوري (Push Notification Campaign)
            </h3>

            <form onSubmit={handleCreateCampaign} className="space-y-4 text-xs">
              <div>
                <label className="block font-bold text-slate-700 mb-1">الجمهور المستهدف</label>
                <select
                  value={targetAudience}
                  onChange={(e) => setTargetAudience(e.target.value as MarketingCampaign['target_audience'])}
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-300 rounded-xl"
                >
                  <option value="all">كافة العملاء النشطين (15,000+ عميل)</option>
                  <option value="cart_abandoners">أصحاب السلال المتروكة (استرجاع المبيعات)</option>
                  <option value="vip_gold_platinum">أعضاء الديب VIP (الفئة الذهبية والبلاتينية)</option>
                  <option value="new_customers">العملاء الجدد (كود ترحيبي)</option>
                </select>
              </div>

              <div>
                <label className="block font-bold text-slate-700 mb-1">عنوان الإشعار</label>
                <input
                  type="text"
                  placeholder="مثال: ⚡ عروض منتصف الليل بدأت الآن!"
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-300 rounded-xl"
                  required
                />
              </div>

              <div>
                <label className="block font-bold text-slate-700 mb-1">نص الرسالة</label>
                <textarea
                  rows={3}
                  placeholder="مثال: خصم 30% على الألبان والفواكه الطازجة وتوصيل خلال 15 دقيقة لبابك..."
                  value={body}
                  onChange={(e) => setBody(e.target.value)}
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-300 rounded-xl leading-relaxed"
                  required
                />
              </div>

              <div className="flex justify-end gap-2 pt-4 border-t border-slate-100">
                <button
                  type="button"
                  onClick={() => setShowModal(false)}
                  className="px-4 py-2 border border-slate-300 rounded-xl font-bold text-slate-600 hover:bg-slate-50"
                >
                  إلغاء
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 bg-blue-600 hover:bg-blue-700 text-white font-bold rounded-xl shadow-md shadow-blue-600/30 flex items-center gap-1.5"
                >
                  <Send className="w-3.5 h-3.5" />
                  إرسال الإشعار الآن
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
