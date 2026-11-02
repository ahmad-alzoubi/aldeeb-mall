import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/supabase_service.dart';
import '../models/support_ticket_model.dart';

class CustomerServiceService {
  static final CustomerServiceService _instance = CustomerServiceService._internal();
  factory CustomerServiceService() => _instance;
  CustomerServiceService._internal();

  static const String _storageKey = 'aldeeb_support_tickets_v1';

  // 1. Direct Hotline Dialer
  Future<bool> callPhone(String phone) async {
    try {
      final clean = phone.replaceAll(RegExp(r'[^\d+]'), '');
      final uri = Uri.parse('tel:$clean');
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('Error calling phone: $e');
    }
    return false;
  }

  // 2. Direct WhatsApp Launcher
  Future<bool> launchWhatsApp(String phone, {String message = ''}) async {
    try {
      // Keep only digits for wa.me
      var clean = phone.replaceAll(RegExp(r'[^\d]'), '');
      if (clean.startsWith('00')) {
        clean = clean.substring(2);
      }
      final encodedMsg = Uri.encodeComponent(message);
      final uri = Uri.parse('https://wa.me/$clean?text=$encodedMsg');
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching WhatsApp: $e');
    }
    return false;
  }

  // 3. Direct Email Composer
  Future<bool> sendEmail(String email, {String subject = '', String body = ''}) async {
    try {
      final uri = Uri.parse(
        'mailto:$email?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
      );
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('Error sending email: $e');
    }
    return false;
  }

  // 4. Default Seed Tickets
  List<SupportTicket> _getDefaultTickets() {
    return [
      SupportTicket(
        id: 'tkt-1',
        ticketNumber: 'TKT-4412',
        customerName: 'فاطمة المنصوري',
        orderNumber: 'DEEB-8843',
        subject: 'طلب إضافة صنف إضافي مع الطلب قبل خروج المندوب',
        category: 'order_issue',
        status: 'open',
        priority: 'high',
        createdAt: 'منذ 10 دقائق',
        lastMessage: 'مرحباً، هل يمكن إضافة عبوة بيض بلدي إلى طلبي إذا كان لا يزال قيد التجهيز؟',
        messages: [
          TicketMessage(
            id: 'm-1',
            sender: 'customer',
            senderName: 'فاطمة المنصوري',
            text: 'مرحباً، هل يمكن إضافة عبوة بيض بلدي إلى طلبي إذا كان لا يزال قيد التجهيز؟',
            timestamp: '10:42 ص',
          ),
          TicketMessage(
            id: 'm-2',
            sender: 'agent',
            senderName: 'فريق خدمة العملاء',
            text: 'أهلاً بك أختي فاطمة! تم التحقق وطلبك لا يزال في مرحلة التجهيز في المستودع المظلم. جاري إضافة الصنف فوراً.',
            timestamp: '10:44 ص',
          ),
        ],
      ),
      SupportTicket(
        id: 'tkt-2',
        ticketNumber: 'TKT-4410',
        customerName: 'خالد السعدي',
        orderNumber: 'DEEB-8844',
        subject: 'استفسار عن موعد وصول الكابتن لبرج مارينا كراون',
        category: 'delivery',
        status: 'in_progress',
        priority: 'medium',
        createdAt: 'منذ 25 دقيقة',
        lastMessage: 'الكابتن محمد في الطريق ويصلك خلال 7 دقائق بالضبط.',
        messages: [
          TicketMessage(
            id: 'm-3',
            sender: 'customer',
            senderName: 'خالد السعدي',
            text: 'السلام عليكم، كم المتبقي على وصول طلب الغداء؟',
            timestamp: '10:15 ص',
          ),
          TicketMessage(
            id: 'm-4',
            sender: 'agent',
            senderName: 'فريق العمليات والدعم',
            text: 'وعليكم السلام ورحمة الله، الكابتن محمد في الطريق وموقعه يبعد 1.2 كم، يصلك خلال 7 دقائق بالضبط.',
            timestamp: '10:18 ص',
          ),
        ],
      ),
      SupportTicket(
        id: 'tkt-3',
        ticketNumber: 'TKT-4401',
        customerName: 'أحمد الزعبي',
        subject: 'استفسار عن تحويل نقاط ولاء العضوية الذهبية لكوبون خصم',
        category: 'general',
        status: 'resolved',
        priority: 'low',
        createdAt: 'أمس',
        lastMessage: 'تم تفعيل كود الخصم في حسابك بقيمة 25 ل.س، تسوق ممتع!',
        messages: [
          TicketMessage(
            id: 'm-5',
            sender: 'customer',
            senderName: 'أحمد الزعبي',
            text: 'كيف يمكنني استبدال رصيد نقاط الولاء برصيد محفظة؟',
            timestamp: 'أمس 04:30 م',
          ),
          TicketMessage(
            id: 'm-6',
            sender: 'agent',
            senderName: 'مشرف الدعم الفني',
            text: 'تم تفعيل كود الخصم في حسابك بقيمة 25 ل.س، تسوق ممتع!',
            timestamp: 'أمس 04:35 م',
          ),
        ],
      ),
    ];
  }

  // 5. Fetch Tickets (Local cache -> LAN API -> Supabase)
  Future<List<SupportTicket>> getTickets() async {
    List<SupportTicket> list = [];

    // Try Local Cache
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final str = prefs.getString(_storageKey);
      if (str != null && str.isNotEmpty) {
        final decoded = jsonDecode(str) as List;
        list = decoded.map((e) => SupportTicket.fromJson(Map<String, dynamic>.from(e))).toList();
      }
    } catch (_) {}

    // Try LAN API
    try {
      final baseHost = kIsWeb ? (Uri.base.host.isNotEmpty ? Uri.base.host : 'localhost') : 'localhost';
      final uri = Uri.parse('http://$baseHost:8080/api/support_tickets');
      final res = await http.get(uri).timeout(const Duration(milliseconds: 1500));
      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final decoded = jsonDecode(res.body);
        if (decoded is List && decoded.isNotEmpty) {
          list = decoded.map((e) => SupportTicket.fromJson(Map<String, dynamic>.from(e))).toList();
          _saveLocal(list);
          return list;
        }
      }
    } catch (_) {}

    // Try Supabase if connected
    final supabase = SupabaseService();
    if (supabase.isConnected && supabase.client != null) {
      try {
        final res = await supabase.client!
            .from('support_tickets')
            .select()
            .order('created_at', ascending: false);
        if (res.isNotEmpty) {
          list = (res as List).map((e) => SupportTicket.fromJson(Map<String, dynamic>.from(e))).toList();
          _saveLocal(list);
          return list;
        }
      } catch (_) {}
    }

    if (list.isEmpty) {
      list = _getDefaultTickets();
      _saveLocal(list);
    }

    return list;
  }

  // 6. Save tickets to local preferences
  Future<void> _saveLocal(List<SupportTicket> tickets) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(tickets.map((t) => t.toJson()).toList());
      await prefs.setString(_storageKey, raw);
    } catch (_) {}
  }

  // 7. Create a new Ticket
  Future<SupportTicket> createTicket({
    required String subject,
    required String category,
    required String message,
    String? orderNumber,
    String customerName = 'عميل الديب مول',
    String customerPhone = '',
    String priority = 'medium',
  }) async {
    final randId = Random().nextInt(9000) + 1000;
    final ticketNumber = 'TKT-$randId';
    final ticketId = 'tkt-${DateTime.now().millisecondsSinceEpoch}';

    final initialMessage = TicketMessage(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      sender: 'customer',
      senderName: customerName,
      text: message,
      timestamp: 'الآن',
    );

    // Initial system auto-acknowledgment
    final ackMessage = TicketMessage(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch + 1}',
      sender: 'bot',
      senderName: 'مساعد الديب الآلي',
      text: 'تم استلام تذكرتك بنجاح برقم $ticketNumber. تم إخطار فريق خدمة العملاء المناوب وسيقوم أحد ممثلينا بالرد الفوري عليك خلال دقائق معدودة.',
      timestamp: 'الآن',
    );

    final newTicket = SupportTicket(
      id: ticketId,
      ticketNumber: ticketNumber,
      customerName: customerName,
      customerPhone: customerPhone,
      orderNumber: orderNumber,
      subject: subject,
      category: category,
      status: 'open',
      priority: priority,
      createdAt: 'الآن',
      lastMessage: message,
      messages: [initialMessage, ackMessage],
    );

    final all = await getTickets();
    all.insert(0, newTicket);
    await _saveLocal(all);

    // Sync to LAN backend
    _syncTicketToApi(newTicket);

    // Sync to Supabase
    _syncTicketToSupabase(newTicket);

    return newTicket;
  }

  // 7.1 Get or Create Live Chat Ticket for Realtime Instant Chat
  Future<SupportTicket> getOrCreateLiveChatTicket({
    String customerName = 'عميل الديب مول',
    String? orderNumber,
  }) async {
    final all = await getTickets();
    final existingIdx = all.indexWhere((t) => t.id == 'tkt-live-chat' || t.category == 'live_chat');
    if (existingIdx != -1) {
      return all[existingIdx];
    }

    final liveTicket = SupportTicket(
      id: 'tkt-live-chat',
      ticketNumber: 'CHAT-1001',
      customerName: customerName,
      customerPhone: '',
      orderNumber: orderNumber,
      subject: 'محادثة حية مباشرة (Live Chat)',
      category: 'live_chat',
      status: 'open',
      priority: 'high',
      createdAt: 'الآن',
      lastMessage: 'بدء جلسة محادثة مباشرة جديدة',
      messages: [
        TicketMessage(
          id: 'welcome-1',
          sender: 'bot',
          senderName: 'مساعد الديب الذكي',
          text: 'مرحباً بك في خدمة عملاء الديب مول 🛒✨\nنحن هنا لخدمتك 24/7. اكتب استفسارك وسيقوم فريق الدعم بالرد الفوري عليك.',
          timestamp: 'الآن',
        ),
      ],
    );

    all.insert(0, liveTicket);
    await _saveLocal(all);
    _syncTicketToApi(liveTicket);
    _syncTicketToSupabase(liveTicket);
    return liveTicket;
  }

  // 8. Add Message to Ticket
  Future<SupportTicket> addMessageToTicket(
    String ticketId,
    String text, {
    String sender = 'customer',
    String senderName = 'العميل',
  }) async {
    final all = await getTickets();
    final idx = all.indexWhere((t) => t.id == ticketId);
    if (idx == -1) return all.first;

    final existing = all[idx];
    final newMsg = TicketMessage(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      sender: sender,
      senderName: senderName,
      text: text,
      timestamp: 'الآن',
    );

    final updatedMessages = List<TicketMessage>.from(existing.messages)..add(newMsg);
    final updatedTicket = existing.copyWith(
      lastMessage: text,
      messages: updatedMessages,
      status: sender == 'agent' ? 'in_progress' : existing.status,
    );

    all[idx] = updatedTicket;
    await _saveLocal(all);

    _syncTicketToApi(updatedTicket);
    _syncTicketToSupabase(updatedTicket);

    return updatedTicket;
  }

  // 9. Sync helpers
  Future<void> _syncTicketToApi(SupportTicket ticket) async {
    try {
      final baseHost = kIsWeb ? (Uri.base.host.isNotEmpty ? Uri.base.host : 'localhost') : 'localhost';
      final uri = Uri.parse('http://$baseHost:8080/api/support_tickets');
      await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(ticket.toJson()),
      ).timeout(const Duration(milliseconds: 1500));
    } catch (_) {}
  }

  Future<void> _syncTicketToSupabase(SupportTicket ticket) async {
    final supabase = SupabaseService();
    if (supabase.isConnected && supabase.client != null) {
      try {
        await supabase.client!.from('support_tickets').upsert(ticket.toJson());
      } catch (_) {}
    }
  }

  // 10. Smart AI Customer Service Responder (Instant Help)
  String getSmartAiResponse(String query, {String? orderNumber}) {
    final lower = query.toLowerCase();

    if (lower.contains('طلب') || lower.contains('كابتن') || lower.contains('مندوب') || lower.contains('وين') || lower.contains('تأخر') || lower.contains('أين')) {
      final ord = orderNumber ?? 'طلبك الأخير';
      return 'أهلاً بك! بالنسبة لـ ($ord)، شحنتك تم فحصها من المستودع المظلم وتخضع للسلسلة الباردة، ومندوب التوصيل في طريقه إليك. وقت الوصول المقدر هو بين 10 إلى 15 دقيقة. يمكنك تتبع مسار المندوب بالخريطة الحية من قسم طلباتي.';
    }

    if (lower.contains('استرجاع') || lower.contains('ترجيع') || lower.contains('تالف') || lower.contains('خربان') || lower.contains('تعويض') || lower.contains('ضمان')) {
      return 'في الديب مول، نلتزم بـ "ضمان الجودة والطزاجة 100%". إذا وصلك أي صنف (خضار، فواكه، لحوم، أو مجمدات) بحالة غير مرضية، يحق لك الاستبدال الفوري أو استرداد المبلغ كرصيد فوري في محفظتك دون أي تعقيد. اضغط على "فتح تذكرة جديدة" مع إرفاق رقم الطلب لتعويضك فوراً.';
    }

    if (lower.contains('توصيل') || lower.contains('شحن') || lower.contains('سريع') || lower.contains('اكسبريس') || lower.contains('موعد')) {
      return 'نوفر خدمة التوصيل الإكسبريس فائق السرعة من أقرب مستودع مظلم إليك خلال 15 إلى 30 دقيقة، مع الحفاظ التام على درجات التبريد للسلسلة الباردة حتى باب منزلك.';
    }

    if (lower.contains('نقاط') || lower.contains('ولاء') || lower.contains('كوبون') || lower.contains('خصم') || lower.contains('رصيد') || lower.contains('محفظة')) {
      return 'برنامج مكافآت الديب يمنحك نقطة لكل ليرة مشتريات. يمكنك تحويل نقاطك في أي لحظة إلى قسائم شراء بنسبة توفير تصل إلى 25% من صفحة "برنامج الولاء" في التطبيق.';
    }

    if (lower.contains('فرع') || lower.contains('موقع') || lower.contains('دوام') || lower.contains('ساعات') || lower.contains('متى')) {
      return 'فروع هايبرماركت الديب مول تفتح أبوابها يومياً من الساعة 07:00 صباحاً وحتى 01:00 بعد منتصف الليل. أما خدمة التوصيل الإكسبريس وخدمة العملاء فهي متوفرة 24/7 على مدار الساعة.';
    }

    return 'شكراً لتواصلك مع خدمة عملاء الديب مول. استفسارك مهم جداً بالنسبة لنا. يمكنك الضغط على "فتح تذكرة جديدة" ليقوم مشرف خدمة العملاء بمتابعة حالتك، أو التحدث المباشر مع موظف الدعم عبر واتساب أو الاتصال الهاتفي السريع.';
  }
}
