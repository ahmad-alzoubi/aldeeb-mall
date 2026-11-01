import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/notification_model.dart';
import '../../core/providers/store_settings_provider.dart';
import '../../core/services/supabase_service.dart';

class NotificationsSheet extends StatefulWidget {
  const NotificationsSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NotificationsSheet(),
    );
  }

  @override
  State<NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<NotificationsSheet> {
  List<NotificationItem> _notifications = [
    NotificationItem(
      id: 'n1',
      title: '🎉 خصم حصري 20% على اللحوم والمشاوي',
      body: 'استخدم كوبون ALDEEB10 عند الدفع واستمتع بأشهى قطع اللحوم البلدية الطازجة.',
      timeAgo: 'منذ 15 دقيقة',
      type: 'promo',
      isRead: false,
    ),
    NotificationItem(
      id: 'n2',
      title: '📦 تم تأكيد طلبك بنجاح (#ORD-9481)',
      body: 'المندوب بدأ تجهيز مقاضيك من الهايبرماركت، وقت التوصيل المتوقع خلال 15 دقيقة.',
      timeAgo: 'منذ ساعتين',
      type: 'order',
      isRead: false,
    ),
    NotificationItem(
      id: 'n3',
      title: '⭐ مبروك! حصلت على 50 نقطة ولاء ترحيبية',
      body: 'رصيد نقاطك الحالي أصبح مؤهلاً للترقية إلى الفئة الذهبية (Gold Tier).',
      timeAgo: 'أمس',
      type: 'loyalty',
      isRead: true,
    ),
    NotificationItem(
      id: 'n4',
      title: '🚚 خدمة التوصيل الإكسبريس 15 دقيقة متاحة الآن',
      body: 'طلبك يخرج مباشرة من المستودع الذكي الأقرب لعنوانك بسرعة فائقة.',
      timeAgo: 'قبل يومين',
      type: 'system',
      isRead: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadSupabaseNotifications();
  }

  Future<void> _loadSupabaseNotifications() async {
    final supabase = SupabaseService();
    if (supabase.isConnected && supabase.client != null) {
      try {
        final res = await supabase.client!
            .from('notifications')
            .select()
            .order('created_at', ascending: false)
            .limit(10);
        if (res.isNotEmpty) {
          setState(() {
            _notifications = res.map((e) => NotificationItem.fromJson(e)).toList();
          });
        }
      } catch (_) {}
    }
  }

  void _markAllAsRead() {
    setState(() {
      for (var n in _notifications) {
        n.isRead = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<StoreSettingsProvider>(context);
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 44,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: settings.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.notifications_active_rounded, color: settings.primaryColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'الإشعارات وتنبيهات العروض',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                      ),
                      Text(
                        unreadCount > 0 ? 'لديك $unreadCount إشعار غير مقروء' : 'جميع الإشعارات مقروءة',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (unreadCount > 0)
                  TextButton.icon(
                    onPressed: _markAllAsRead,
                    icon: const Icon(Icons.done_all_rounded, size: 16),
                    label: const Text('قراءة الكل', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Notification List
          Expanded(
            child: _notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.notifications_off_outlined, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'لا توجد إشعارات حالياً',
                          style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: _notifications.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = _notifications[index];
                      return InkWell(
                        onTap: () {
                          setState(() => item.isRead = true);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: item.isRead ? Colors.white : settings.primaryColor.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: item.isRead ? AppColors.border : settings.primaryColor.withValues(alpha: 0.3),
                              width: item.isRead ? 1 : 1.5,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTypeIcon(item.type, settings),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.title,
                                            style: TextStyle(
                                              fontWeight: item.isRead ? FontWeight.bold : FontWeight.w900,
                                              fontSize: 13,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                        if (!item.isRead)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            margin: const EdgeInsets.only(left: 6),
                                            decoration: BoxDecoration(
                                              color: settings.secondaryColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.body,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: item.isRead ? AppColors.textSecondary : AppColors.textPrimary,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      item.timeAgo,
                                      style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeIcon(String type, StoreSettingsProvider settings) {
    IconData icon;
    Color color;

    switch (type) {
      case 'promo':
        icon = Icons.local_offer_rounded;
        color = settings.secondaryColor;
        break;
      case 'order':
        icon = Icons.local_shipping_rounded;
        color = settings.primaryColor;
        break;
      case 'loyalty':
        icon = Icons.stars_rounded;
        color = settings.accentColor;
        break;
      default:
        icon = Icons.info_rounded;
        color = AppColors.info;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
